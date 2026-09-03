using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;

namespace SafeVoice.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<OtpRequest> OtpRequests => Set<OtpRequest>();
    public DbSet<Case> Cases => Set<Case>();
    public DbSet<CaseStatusHistory> CaseStatusHistories => Set<CaseStatusHistory>();
    public DbSet<Evidence> Evidence => Set<Evidence>();
    public DbSet<LocationPing> LocationPings => Set<LocationPing>();
    public DbSet<EmergencyContact> EmergencyContacts => Set<EmergencyContact>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<InvestigationNote> InvestigationNotes => Set<InvestigationNote>();
    public DbSet<OfficerReport> OfficerReports => Set<OfficerReport>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // User
        modelBuilder.Entity<User>(e =>
        {
            e.HasKey(u => u.Id);
            // PhoneNumber is nullable for portal-only users; unique only when not null
            e.HasIndex(u => u.PhoneNumber).IsUnique().HasFilter("\"PhoneNumber\" IS NOT NULL");
            e.Property(u => u.PhoneNumber).HasMaxLength(20);
            e.Property(u => u.PasswordHash).IsRequired();
            e.Property(u => u.Role).HasConversion<string>();
        });

        // RefreshToken
        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.HasKey(r => r.Id);
            e.HasIndex(r => r.TokenHash).IsUnique();
            e.HasOne(r => r.User).WithMany(u => u.RefreshTokens)
                .HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // OtpRequest
        modelBuilder.Entity<OtpRequest>(e =>
        {
            e.HasKey(o => o.Id);
            e.HasIndex(o => o.PhoneNumber);
        });

        // Case — assignment navigation
        modelBuilder.Entity<Case>(e =>
        {
            e.HasKey(c => c.Id);
            e.Property(c => c.Status).HasConversion<string>();
            e.Property(c => c.RiskLevel).HasConversion<string>();
            e.HasOne(c => c.User).WithMany(u => u.Cases)
                .HasForeignKey(c => c.UserId).OnDelete(DeleteBehavior.SetNull);
            e.HasOne(c => c.AssignedOfficer).WithMany()
                .HasForeignKey(c => c.AssignedOfficerId).OnDelete(DeleteBehavior.SetNull);
        });

        // CaseStatusHistory
        modelBuilder.Entity<CaseStatusHistory>(e =>
        {
            e.HasKey(h => h.Id);
            e.HasOne(h => h.Case).WithMany(c => c.StatusHistory)
                .HasForeignKey(h => h.CaseId).OnDelete(DeleteBehavior.Cascade);
        });

        // Evidence
        modelBuilder.Entity<Evidence>(e =>
        {
            e.HasKey(ev => ev.Id);
            e.HasOne(ev => ev.Case).WithMany(c => c.Evidence)
                .HasForeignKey(ev => ev.CaseId).OnDelete(DeleteBehavior.Cascade);
        });

        // LocationPing
        modelBuilder.Entity<LocationPing>(e =>
        {
            e.HasKey(l => l.Id);
            e.HasOne(l => l.Case).WithMany(c => c.LocationPings)
                .HasForeignKey(l => l.CaseId).OnDelete(DeleteBehavior.Cascade);
        });

        // EmergencyContact
        modelBuilder.Entity<EmergencyContact>(e =>
        {
            e.HasKey(ec => ec.Id);
            e.HasOne(ec => ec.User).WithMany(u => u.EmergencyContacts)
                .HasForeignKey(ec => ec.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // DeviceToken
        modelBuilder.Entity<DeviceToken>(e =>
        {
            e.HasKey(d => d.Id);
            e.HasOne(d => d.User).WithMany(u => u.DeviceTokens)
                .HasForeignKey(d => d.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // AuditLog
        modelBuilder.Entity<AuditLog>(e =>
        {
            e.HasKey(a => a.Id);
            e.HasOne(a => a.User).WithMany(u => u.AuditLogs)
                .HasForeignKey(a => a.UserId).OnDelete(DeleteBehavior.SetNull);
        });

        // InvestigationNote
        modelBuilder.Entity<InvestigationNote>(e =>
        {
            e.HasKey(n => n.Id);
            e.HasOne(n => n.Case).WithMany(c => c.InvestigationNotes)
                .HasForeignKey(n => n.CaseId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(n => n.Author).WithMany()
                .HasForeignKey(n => n.AuthorId).OnDelete(DeleteBehavior.Restrict);
        });

        // User — add Username index
        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(u => u.Username).IsUnique().HasFilter("\"Username\" IS NOT NULL");
        });

        // OfficerReport
        modelBuilder.Entity<OfficerReport>(e =>
        {
            e.HasKey(r => r.Id);
            e.HasOne(r => r.Case).WithMany()
                .HasForeignKey(r => r.CaseId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(r => r.Officer).WithMany()
                .HasForeignKey(r => r.OfficerId).OnDelete(DeleteBehavior.Restrict);
        });
    }
}
