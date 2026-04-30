using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Onlium.API.Models;

[Index("Email", Name = "UQ_Users_Email", IsUnique = true)]
public partial class User
{
    [Key]
    public Guid Id { get; set; }

    [StringLength(200)]
    public string FullName { get; set; } = null!;

    [StringLength(255)]
    public string Email { get; set; } = null!;

    [StringLength(512)]
    public string PasswordHash { get; set; } = null!;

    [StringLength(20)]
    public string Role { get; set; } = null!;

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [InverseProperty("Student")]
    public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();

    [InverseProperty("CreatedByUser")]
    public virtual ICollection<Bulletin> Bulletins { get; set; } = new List<Bulletin>();

    [InverseProperty("Student")]
    public virtual ICollection<EnrollmentApplication> EnrollmentApplications { get; set; } = new List<EnrollmentApplication>();

    [InverseProperty("CreatedByUser")]
    public virtual ICollection<LmsResource> LmsResources { get; set; } = new List<LmsResource>();

    [InverseProperty("User")]
    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    [InverseProperty("User")]
    public virtual StudentProfile? StudentProfile { get; set; }
}
