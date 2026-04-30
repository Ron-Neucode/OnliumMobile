using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Onlium.API.Models;

public partial class Bulletin
{
    [Key]
    public Guid Id { get; set; }

    [StringLength(200)]
    public string Title { get; set; } = null!;

    public string Content { get; set; } = null!;

    public bool IsPublished { get; set; }

    public Guid CreatedByUserId { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey("CreatedByUserId")]
    [InverseProperty("Bulletins")]
    public virtual User CreatedByUser { get; set; } = null!;
}
