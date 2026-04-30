namespace Onlium.API.DTOs;

public class CreateAppointmentRequest
{
    public Guid ApplicationId { get; set; }
    public DateTime AppointmentDate { get; set; }
    public string? Location { get; set; }
    public string? Notes { get; set; }
}

public class SendNotificationRequest
{
    public Guid UserId { get; set; }
    public string NotificationType { get; set; } = string.Empty; // General / Approval / Rejection / Appointment / Bulletin / LMS
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}