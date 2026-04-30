using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Onlium.API.Models;

public partial class LmsResource
{
    [Key]
    public Guid Id { get; set; }

    [StringLength(20)]
    public string ResourceType { get; set; } = null!;

    [StringLength(200)]
    public string Title { get; set; } = null!;

    [StringLength(1000)]
    public string Url { get; set; } = null!;

    public bool IsActive { get; set; }

    public Guid CreatedByUserId { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey("CreatedByUserId")]
    [InverseProperty("LmsResources")]
    public virtual User CreatedByUser { get; set; } = null!;
}
