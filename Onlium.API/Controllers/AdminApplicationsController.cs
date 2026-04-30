using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Onlium.API.Data;
using Onlium.API.DTOs;
using Onlium.API.Models;

namespace Onlium.API.Controllers;

[ApiController]
[Route("api/admin/applications")]
[Authorize(Roles = "Admin")]
public class AdminApplicationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminApplicationsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetPending()
    {
        var data = await _context.EnrollmentApplications
            .Where(x => x.Status == "PendingReview")
            .OrderByDescending(x => x.SubmittedAt)
            .ToListAsync();

        return Ok(data);
    }

    [HttpPost("{id}/approve")]
    public async Task<IActionResult> Approve(Guid id)
    {
        var application = await _context.EnrollmentApplications
            .FirstOrDefaultAsync(x => x.Id == id);

        if (application == null)
            return NotFound(new { message = "Application not found" });

        application.Status = "Approved";
        application.ReviewedAt = DateTime.UtcNow;
        application.UpdatedAt = DateTime.UtcNow;
        application.AdminReviewComment = null;

        _context.Notifications.Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = application.StudentId,
            NotificationType = "Approval",
            Title = "Enrollment Approved",
            Message = "Your enrollment requirements were approved. Please wait for your payment appointment.",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();

        return Ok(new { message = "Application approved" });
    }

    [HttpPost("{id}/reject")]
    public async Task<IActionResult> Reject(Guid id, RejectApplicationRequest request)
    {
        var application = await _context.EnrollmentApplications
            .FirstOrDefaultAsync(x => x.Id == id);

        if (application == null)
            return NotFound(new { message = "Application not found" });

        if (string.IsNullOrWhiteSpace(request.Reason))
            return BadRequest(new { message = "Reason is required." });

        application.Status = "Rejected";
        application.ReviewedAt = DateTime.UtcNow;
        application.UpdatedAt = DateTime.UtcNow;
        application.AdminReviewComment = request.Reason;

        _context.Notifications.Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = application.StudentId,
            NotificationType = "Rejection",
            Title = "Enrollment Rejected",
            Message = "Your enrollment was rejected. Reason: " + request.Reason,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();

        return Ok(new { message = "Application rejected" });
    }
}