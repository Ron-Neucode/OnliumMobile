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
public class AppointmentsController : ControllerBase
{
    private readonly AppDbContext _context;

    public AppointmentsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(CreateAppointmentRequest request)
    {
        var application = await _context.EnrollmentApplications
            .FirstOrDefaultAsync(x => x.Id == request.ApplicationId);

        if (application == null)
            return NotFound(new { message = "Application not found." });

        if (application.Status != "Approved")
            return BadRequest(new { message = "Appointment can only be created for approved applications." });

        var appointment = new Appointment
        {
            Id = Guid.NewGuid(),
            StudentId = application.StudentId,
            ApplicationId = application.Id,
            AppointmentDate = request.AppointmentDate,
            Location = request.Location,
            Notes = request.Notes,
            Status = "Scheduled",
            CreatedAt = DateTime.UtcNow
        };

        _context.Appointments.Add(appointment);

        _context.Notifications.Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = application.StudentId,
            NotificationType = "Appointment",
            Title = "Payment Appointment Scheduled",
            Message = "Your walk-in payment appointment has been scheduled. Please check your appointment tab.",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();

        return Ok(appointment);
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var appointments = await _context.Appointments
            .OrderByDescending(x => x.AppointmentDate)
            .ToListAsync();

        return Ok(appointments);
    }

    [HttpGet("mine")]
    [Authorize(Roles = "Student")]
    public async Task<IActionResult> GetMine()
    {
        var studentId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var appointments = await _context.Appointments
            .Where(x => x.StudentId == studentId)
            .OrderByDescending(x => x.AppointmentDate)
            .ToListAsync();

        return Ok(appointments);
    }
}