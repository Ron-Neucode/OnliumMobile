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
public class NotificationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public NotificationsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("mine")]
    [Authorize(Roles = "Student,Admin")]
    public async Task<IActionResult> GetMine()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var notifications = await _context.Notifications
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(notifications);
    }

    [HttpPost("{id}/read")]
    [Authorize(Roles = "Student,Admin")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var notification = await _context.Notifications
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

        if (notification == null)
            return NotFound(new { message = "Notification not found." });

        notification.IsRead = true;
        notification.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new { message = "Notification marked as read." });
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Send(SendNotificationRequest request)
    {
        var allowedTypes = new[]
        {
            "General",
            "Approval",
            "Rejection",
            "Appointment",
            "Bulletin",
            "LMS"
        };

        if (!allowedTypes.Contains(request.NotificationType))
            return BadRequest(new { message = "Invalid notification type." });

        var user = await _context.Users.FirstOrDefaultAsync(x => x.Id == request.UserId);
        if (user == null)
            return NotFound(new { message = "Target user not found." });

        var notification = new Notification
        {
            Id = Guid.NewGuid(),
            UserId = request.UserId,
            NotificationType = request.NotificationType,
            Title = request.Title,
            Message = request.Message,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Notification sent successfully." });
    }
}