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
public class BulletinsController : ControllerBase
{
    private readonly AppDbContext _context;

    public BulletinsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    [Authorize(Roles = "Student,Admin")]
    public async Task<IActionResult> GetAll()
    {
        var bulletins = await _context.Bulletins
            .Where(x => x.IsPublished)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(bulletins);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(CreateBulletinRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title))
            return BadRequest(new { message = "Title is required." });

        if (string.IsNullOrWhiteSpace(request.Content))
            return BadRequest(new { message = "Content is required." });

        var adminId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var bulletin = new Bulletin
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Content = request.Content,
            IsPublished = true,
            CreatedByUserId = adminId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Bulletins.Add(bulletin);

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
                NotificationType = "Bulletin",
                Title = "New Bulletin",
                Message = request.Title,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();

        return Ok(bulletin);
    }
}