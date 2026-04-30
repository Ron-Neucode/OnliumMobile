namespace Onlium.API.DTOs;

public class UploadRequirementRequest
{
    public string RequirementType { get; set; } = string.Empty;
    public IFormFile File { get; set; } = default!;
}