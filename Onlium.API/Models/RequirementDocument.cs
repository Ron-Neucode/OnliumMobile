using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Onlium.API.Models;

[Index("ApplicationId", Name = "IX_RequirementDocuments_ApplicationId")]
public partial class RequirementDocument
{
    [Key]
    public Guid Id { get; set; }

    public Guid ApplicationId { get; set; }

    [StringLength(50)]
    public string RequirementType { get; set; } = null!;

    [StringLength(255)]
    public string OriginalFileName { get; set; } = null!;

    [StringLength(255)]
    public string StoredFileName { get; set; } = null!;

    [StringLength(500)]
    public string FilePath { get; set; } = null!;

    [StringLength(100)]
    public string? ContentType { get; set; }

    public long FileSize { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey("ApplicationId")]
    [InverseProperty("RequirementDocuments")]
    public virtual EnrollmentApplication Application { get; set; } = null!;
}
