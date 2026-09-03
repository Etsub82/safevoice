using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;

namespace SafeVoice.Infrastructure.Data;

/// <summary>
/// Seeds essential portal users on first startup.
/// Only runs if no SystemAdmin user exists.
/// </summary>
public static class DbSeeder
{
    public static async Task SeedAsync(AppDbContext db)
    {
        // ── Always reset/repair portal seed accounts ──────────────────────
        // This is idempotent: updates existing accounts if they already exist.
        await EnsurePortalUsersAsync(db);

        // ── Demo mobile accounts (idempotent) ─────────────────────────────
        var demoPhonesNeeded = new[] { "+251911000001", "+251911000002", "+251911000003" };
        foreach (var phone in demoPhonesNeeded)
        {
            if (!await db.Users.AnyAsync(u => u.PhoneNumber == phone))
            {
                var (pin, role, name) = phone switch
                {
                    "+251911000001" => ("000001", UserRole.Victim,          "[DEMO] Victim"),
                    "+251911000002" => ("000002", UserRole.Officer,         "[DEMO] Officer"),
                    _               => ("000003", UserRole.HeadOfDepartment,"[DEMO] Department Head"),
                };
                db.Users.Add(MakeDemoVictim(phone, pin, role, name));
            }
        }

        await db.SaveChangesAsync();
    }

    private static async Task EnsurePortalUsersAsync(AppDbContext db)
    {
        var accounts = new[]
        {
            ("admin",         "Admin@123",      UserRole.SystemAdmin,       "SafeVoice HQ",       "National"),
            ("auditor",       "Audit@123",      UserRole.SecurityAuditor,   "SafeVoice HQ",       "National"),
            ("head1",         "Head@123",        UserRole.HeadOfDepartment, "Addis Ababa Police", "Addis Ababa"),
            ("supervisor1",   "Supervisor@123", UserRole.Supervisor,        "Addis Ababa Police", "Addis Ababa"),
            ("officer1",      "Officer@123",    UserRole.Officer,           "Addis Ababa Police", "Addis Ababa"),
            ("officer2",      "Officer2@123",   UserRole.Officer,           "Addis Ababa Police", "Addis Ababa"),
            ("prosecutor1",   "Prosecutor@123", UserRole.Prosecutor,        "Federal Prosecutor", "Federal"),
            ("lawyer1",       "Lawyer@123",     UserRole.Lawyer,            "Legal Aid Ethiopia", "Addis Ababa"),
            ("socialworker1", "Social@123",     UserRole.SocialWorker,      "Ministry of Women",  "Addis Ababa"),
        };

        foreach (var (username, password, role, org, jurisdiction) in accounts)
        {
            var existing = await db.Users.FirstOrDefaultAsync(u => u.Username == username);
            if (existing == null)
            {
                db.Users.Add(new User
                {
                    Username      = username,
                    PhoneNumber   = null,
                    PasswordHash  = BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12),
                    Role          = role,
                    Organization  = org,
                    Jurisdiction  = jurisdiction,
                    IsActive      = true,
                    IsLocked      = false,
                    FailedLoginAttempts = 0,
                    DisplayName   = username,
                });
            }
            else
            {
                // Always repair: re-hash password, unlock, reactivate
                existing.PasswordHash        = BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12);
                existing.IsActive            = true;
                existing.IsLocked            = false;
                existing.LockedUntil         = null;
                existing.FailedLoginAttempts = 0;
                existing.Organization        = org;
                existing.Jurisdiction        = jurisdiction;
            }
        }
    }

    private static User MakeDemoVictim(string phone, string pin, UserRole role, string displayName) =>
        new()
        {
            PhoneNumber = phone,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(pin, workFactor: 12),
            Role = role,
            DisplayName = displayName,
            IsActive = true,
        };
}
