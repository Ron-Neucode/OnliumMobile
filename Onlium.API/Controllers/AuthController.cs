using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Onlium.API.Data;
using Onlium.API.DTOs;
using Onlium.API.Models;

namespace Onlium.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _configuration;

    public AuthController(AppDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest request)
    {
        var email = request.Email.Trim().ToLower();
        var firstName = request.FirstName.Trim();
        var lastName = request.LastName.Trim();
        var password = request.Password.Trim();

        if (string.IsNullOrWhiteSpace(email))
            return BadRequest(new { message = "Email is required." });

        if (string.IsNullOrWhiteSpace(password))
            return BadRequest(new { message = "Password is required." });

        if (string.IsNullOrWhiteSpace(firstName))
            return BadRequest(new { message = "First name is required." });

        if (string.IsNullOrWhiteSpace(lastName))
            return BadRequest(new { message = "Last name is required." });

        var existingUser = await _context.Users.FirstOrDefaultAsync(x => x.Email == email);
        if (existingUser != null)
            return BadRequest(new { message = "Email already exists." });

        var fullName = $"{firstName} {lastName}".Trim();

        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = fullName,
            Email = email,
            PasswordHash = password, // TEMP ONLY
            Role = "Student",
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var profile = new StudentProfile
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            FirstName = firstName,
            LastName = lastName,
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        _context.StudentProfiles.Add(profile);

        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = "Student registered successfully."
        });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        var email = request.Email.Trim().ToLower();

        var user = await _context.Users.FirstOrDefaultAsync(x => x.Email == email);

        if (user == null)
            return Unauthorized(new { message = "Invalid credentials" });

        // TEMP ONLY
        if (user.PasswordHash != request.Password)
            return Unauthorized(new { message = "Invalid credentials" });

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role)
        };

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!)
        );

        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(2),
            signingCredentials: creds
        );

        return Ok(new LoginResponse
        {
            Token = new JwtSecurityTokenHandler().WriteToken(token),
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role
        });
    }
}