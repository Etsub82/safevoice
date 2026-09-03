namespace SafeVoice.Core.Entities;

public enum UserRole
{
    // Victim-side roles (mobile app)
    Victim, Guardian, Witness,

    // Portal roles — law enforcement
    Officer, Investigator, Supervisor, HeadOfDepartment,
    WomensProtection, ChildProtection, EmergencyResponse,
    RegionalAuthority, FederalAuthority,

    // Portal roles — justice
    Prosecutor, PublicProsecutor, CourtClerk, Judge,

    // Portal roles — legal
    Lawyer, LegalAid,

    // Portal roles — support
    SocialWorker, ChildProtectionOrg, Shelter,
    HealthcareReferral, PsychosocialSupport, NGO,

    // Portal roles — administration
    InstitutionalAdmin, SystemAdmin, SecurityAuditor,

    // Legacy
    Admin
}

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string? PhoneNumber { get; set; }        // Nullable — portal users may not have a phone number
    public string? Username { get; set; }           // Portal users log in with username
    public string PasswordHash { get; set; } = string.Empty;
    public UserRole Role { get; set; } = UserRole.Victim;
    public string? DisplayName { get; set; }
    public string PreferredLanguage { get; set; } = "en";
    public string? Organization { get; set; }       // Portal users belong to an org
    public string? Jurisdiction { get; set; }       // Portal users have a jurisdiction
    public bool IsActive { get; set; } = false;
    public bool IsLocked { get; set; } = false;
    public DateTime? LockedUntil { get; set; }
    public int FailedLoginAttempts { get; set; } = 0;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Guardian fields
    public string? GuardianChildName { get; set; }
    public string? GuardianRelationship { get; set; }

    // Stakeholder agreement/consent
    public bool? AgreementAccepted { get; set; }
    public DateTime? AgreementAcceptedAt { get; set; }

    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    public ICollection<EmergencyContact> EmergencyContacts { get; set; } = new List<EmergencyContact>();
    public ICollection<Case> Cases { get; set; } = new List<Case>();
    public ICollection<DeviceToken> DeviceTokens { get; set; } = new List<DeviceToken>();
    public ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
}
