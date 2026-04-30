using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Onlium.API.Data;
using Onlium.API.DTOs;
using Onlium.API.Models;

namespace Onlium.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ResourcesController : ControllerBase
{
    private readonly AppDbContext _context;

    public ResourcesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    [Authorize(Roles = "Student,Admin")]
    public async Task<IActionResult> GetAll()
    {
        var resources = await _context.LmsResources
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(resources);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(CreateResourceRequest request)
    {
        var allowedTypes = new[] { "Exam", "Quiz" };

        if (!allowedTypes.Contains(request.ResourceType))
            return BadRequest(new { message = "Invalid resource type." });

        if (string.IsNullOrWhiteSpace(request.Title))
            return BadRequest(new { message = "Title is required." });

        if (string.IsNullOrWhiteSpace(request.Url))
            return BadRequest(new { message = "Url is required." });

        var adminId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var resource = new LmsResource
        {
            Id = Guid.NewGuid(),
            ResourceType = request.ResourceType,
            Title = request.Title,
            Url = request.Url,
            IsActive = true,
            CreatedByUserId = adminId,
            CreatedAt = DateTime.UtcNow
        };

        _context.LmsResources.Add(resource);

        var studentIds = await _context.Users
            .Where(x => x.Role == "Student")
            .Select(x => x.Id)
            .ToListAsync();

        foreach (var studentId in studentIds)
        {
            _context.Notifications.Add(new Notification
            {
                Id = Guid.NewGuid(),
                UserId = studentId,
                NotificationType = "LMS",
                Title = "New LMS Resource",
                Message = $"{request.ResourceType}: {request.Title}",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();

        return Ok(resource);
    }
}