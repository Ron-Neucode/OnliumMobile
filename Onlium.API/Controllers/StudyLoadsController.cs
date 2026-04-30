using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Onlium.API.Data;
using Onlium.API.DTOs;
using Onlium.API.Models;

namespace Onlium.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StudyLoadsController : ControllerBase
{
    private readonly AppDbContext _context;

    public StudyLoadsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    [Authorize(Roles = "Student,Admin")]
    public async Task<IActionResult> Get(
        [FromQuery] string? programCode,
        [FromQuery] int? yearLevel,
        [FromQuery] int? semester)
    {
        var query = _context.StudyLoads.AsQueryable();

        if (!string.IsNullOrWhiteSpace(programCode))
            query = query.Where(x => x.ProgramCode == programCode);

        if (yearLevel.HasValue)
            query = query.Where(x => x.YearLevel == yearLevel.Value);

        if (semester.HasValue)
            query = query.Where(x => x.Semester == semester.Value);

        var studyLoads = await query
            .OrderBy(x => x.ProgramCode)
            .ThenBy(x => x.YearLevel)
            .ThenBy(x => x.Semester)
            .ThenBy(x => x.SubjectCode)
            .ToListAsync();

        return Ok(studyLoads);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(CreateStudyLoadRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.ProgramCode))
            return BadRequest(new { message = "ProgramCode is required." });

        if (request.YearLevel < 1 || request.YearLevel > 6)
            return BadRequest(new { message = "Invalid year level." });

        if (request.Semester < 1 || request.Semester > 3)
            return BadRequest(new { message = "Invalid semester." });

        if (string.IsNullOrWhiteSpace(request.SubjectCode))
            return BadRequest(new { message = "SubjectCode is required." });

        if (string.IsNullOrWhiteSpace(request.SubjectTitle))
            return BadRequest(new { message = "SubjectTitle is required." });

        var studyLoad = new StudyLoad
        {
            Id = Guid.NewGuid(),
            ProgramCode = request.ProgramCode,
            YearLevel = request.YearLevel,
            Semester = request.Semester,
            SubjectCode = request.SubjectCode,
            SubjectTitle = request.SubjectTitle,
            LecUnits = request.LecUnits,
            LabUnits = request.LabUnits,
            CreatedAt = DateTime.UtcNow
        };

        _context.StudyLoads.Add(studyLoad);
        await _context.SaveChangesAsync();

        return Ok(studyLoad);
    }
}