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
public class RequirementsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IWebHostEnvironment _environment;

    public RequirementsController(AppDbContext context, IWebHostEnvironment environment)
    {
        _context = context;
        _environment = environment;
    }

    [HttpPost("upload/{applicationId:guid}")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(20000000)]
    public async Task<IActionResult> Upload(
        Guid applicationId,
        [FromForm] UploadRequirementRequest request)
    {
        var studentId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var application = await _context.EnrollmentApplications
            .FirstOrDefaultAsync(x => x.Id == applicationId && x.StudentId == studentId);

        if (application == null)
            return NotFound(new { message = "Application not found." });

        if (request.File == null || request.File.Length == 0)
            return BadRequest(new { message = "No file uploaded." });

        var allowedTypes = new[]
        {
            "ReportCard",
            "GoodMoral",
            "PSA",
            "TOR",
            "HonorableDismissal",
            "Picture",
            "Clearance"
        };

        if (!allowedTypes.Contains(request.RequirementType))
            return BadRequest(new { message = "Invalid requirement type." });

        var rootPath = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var uploadsPath = Path.Combine(rootPath, "uploads");
        Directory.CreateDirectory(uploadsPath);

        var storedFileName = $"{Guid.NewGuid()}{Path.GetExtension(request.File.FileName)}";
        var fullPath = Path.Combine(uploadsPath, storedFileName);

        await using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await request.File.CopyToAsync(stream);
        }

        var document = new RequirementDocument
        {
            Id = Guid.NewGuid(),
            ApplicationId = applicationId,
            RequirementType = request.RequirementType,
            OriginalFileName = request.File.FileName,
            StoredFileName = storedFileName,
            FilePath = "/uploads/" + storedFileName,
            ContentType = request.File.ContentType,
            FileSize = request.File.Length,
            CreatedAt = DateTime.UtcNow
        };

        _context.RequirementDocuments.Add(document);
        await _context.SaveChangesAsync();

        return Ok(document);
    }
}