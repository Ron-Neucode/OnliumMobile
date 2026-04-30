using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Onlium.API.Models;

[Index("Status", Name = "IX_EnrollmentApplications_Status")]
[Index("StudentId", Name = "IX_EnrollmentApplications_StudentId")]
public partial class EnrollmentApplication
{
    [Key]
    public Guid Id { get; set; }

    public Guid StudentId { get; set; }

    [StringLength(30)]
    public string StudentType { get; set; } = null!;

    [StringLength(50)]
    public string ProgramCode { get; set; } = null!;

    public int YearLevel { get; set; }

    public int Semester { get; set; }

    [StringLength(20)]
    public string PreferredSchedule { get; set; } = null!;

    [StringLength(30)]
    public string Status { get; set; } = null!;

    [StringLength(500)]
    public string? AdminReviewComment { get; set; }

    public DateTime? SubmittedAt { get; set; }

    public DateTime? ReviewedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [InverseProperty("Application")]
    public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();

    [InverseProperty("Application")]
    public virtual ICollection<RequirementDocument> RequirementDocuments { get; set; } = new List<RequirementDocument>();

    [ForeignKey("StudentId")]
    [InverseProperty("EnrollmentApplications")]
    public virtual User Student { get; set; } = null!;
}
