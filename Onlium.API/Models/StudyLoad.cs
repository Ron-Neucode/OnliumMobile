using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Onlium.API.Models;

[Index("ProgramCode", "YearLevel", "Semester", Name = "IX_StudyLoads_Program_Year_Semester")]
public partial class StudyLoad
{
    [Key]
    public Guid Id { get; set; }

    [StringLength(50)]
    public string ProgramCode { get; set; } = null!;

    public int YearLevel { get; set; }

    public int Semester { get; set; }

    [StringLength(50)]
    public string SubjectCode { get; set; } = null!;

    [StringLength(200)]
    public string SubjectTitle { get; set; } = null!;

    [Column(TypeName = "decimal(5, 2)")]
    public decimal LecUnits { get; set; }

    [Column(TypeName = "decimal(5, 2)")]
    public decimal LabUnits { get; set; }

    [Column(TypeName = "decimal(6, 2)")]
    public decimal? TotalUnits { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}
