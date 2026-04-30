using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Onlium.API.Models;

[Index("ApplicationId", Name = "IX_Appointments_ApplicationId")]
[Index("StudentId", Name = "IX_Appointments_StudentId")]
public partial class Appointment
{
    [Key]
    public Guid Id { get; set; }

    public Guid StudentId { get; set; }

    public Guid ApplicationId { get; set; }

    public DateTime AppointmentDate { get; set; }

    [StringLength(255)]
    public string? Location { get; set; }

    [StringLength(500)]
    public string? Notes { get; set; }

    [StringLength(20)]
    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey("ApplicationId")]
    [InverseProperty("Appointments")]
    public virtual EnrollmentApplication Application { get; set; } = null!;

    [ForeignKey("StudentId")]
    [InverseProperty("Appointments")]
    public virtual User Student { get; set; } = null!;
}
