public class CreateApplicationRequest
{
    public string StudentType { get; set; } = string.Empty; // NewIncoming / Transferee / Continuing
    public string ProgramCode { get; set; } = string.Empty;
    public int YearLevel { get; set; }
    public int Semester { get; set; }
    public string PreferredSchedule { get; set; } = string.Empty;
}