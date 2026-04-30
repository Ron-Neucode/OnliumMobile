namespace Onlium.API.DTOs;

public class CreateApplicationRequest
{
    public string StudentType { get; set; } = string.Empty; // NewIncoming / Transferee / Continuing
    public string ProgramCode { get; set; } = string.Empty;
    public int YearLevel { get; set; }
    public int Semester { get; set; }
    public string PreferredSchedule { get; set; } = string.Empty;
}

public class RejectApplicationRequest
{
    public string Reason { get; set; } = string.Empty;
}