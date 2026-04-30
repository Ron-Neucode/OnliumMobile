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
[Authorize(Roles = "Student")]
public class ApplicationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public ApplicationsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateApplicationRequest request)
    {
        if (request.StudentType != "NewIncoming" &&
            request.StudentType != "Transferee" &&
            request.StudentType != "Continuing")
        {
            return BadRequest(new { message = "Invalid student type." });
        }

        if (request.PreferredSchedule != "Morning" &&
            request.PreferredSchedule != "Afternoon" &&
            request.PreferredSchedule != "Evening")
        {
            return BadRequest(new { message = "Invalid preferred schedule." });
        }

        var studentId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var application = new EnrollmentApplication
        {
            Id = Guid.NewGuid(),
            StudentId = studentId,
            StudentType = request.StudentType,
            ProgramCode = request.ProgramCode,
            YearLevel = request.YearLevel,
            Semester = request.Semester,
            PreferredSchedule = request.PreferredSchedule,
            Status = "Draft",
            CreatedAt = DateTime.UtcNow
        };

        _context.EnrollmentApplications.Add(application);
        await _context.SaveChangesAsync();

        return Ok(application);
    }

    [HttpGet("mine")]
    public async Task<IActionResult> GetMine()
    {
        var studentId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var applications = await _context.EnrollmentApplications
            .Where(x => x.StudentId == studentId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return Ok(applications);
    }

    [HttpPost("{id}/submit")]
    public async Task<IActionResult> Submit(Guid id)
    {
        var studentId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var application = await _context.EnrollmentApplications
            .Include(x => x.RequirementDocuments)
            .FirstOrDefaultAsync(x => x.Id == id && x.StudentId == studentId);

        if (application == null)
            return NotFound(new { message = "Application not found." });

        if (!application.RequirementDocuments.Any())
            return BadRequest(new { message = "Upload requirements first." });

        application.Status = "PendingReview";
        application.SubmittedAt = DateTime.UtcNow;
        application.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new { message = "Application submitted successfully." });
    }
}