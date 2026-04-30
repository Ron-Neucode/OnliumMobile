namespace Onlium.API.DTOs;

public class CreateBulletinRequest
{
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
}

public class CreateResourceRequest
{
    public string ResourceType { get; set; } = string.Empty; // Exam / Quiz
    public string Title { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
}

public class CreateStudyLoadRequest
{
    public string ProgramCode { get; set; } = string.Empty;
    public int YearLevel { get; set; }
    public int Semester { get; set; }
    public string SubjectCode { get; set; } = string.Empty;
    public string SubjectTitle { get; set; } = string.Empty;
    public decimal LecUnits { get; set; }
    public decimal LabUnits { get; set; }
}