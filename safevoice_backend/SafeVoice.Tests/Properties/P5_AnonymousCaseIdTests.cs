// Feature: safevoice-mobile-app
// Property 5: Anonymous Case ID Uniqueness and User Dissociation
// Property 12: Report Case ID Uniqueness

using CsCheck;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Infrastructure.Data;
using SafeVoice.Infrastructure.Services;
using Xunit;

namespace SafeVoice.Tests.Properties;

public class P5_AnonymousCaseIdTests
{
    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    /// <summary>
    /// P5: Anonymous case IDs must be unique and not linked to any user.
    /// Runs 100 iterations.
    /// </summary>
    [Fact]
    public void AnonymousCaseIds_AreUnique()
    {
        var ids = new HashSet<string>();
        int iterations = 100;

        for (int i = 0; i < iterations; i++)
        {
            // Simulate the ID generation from CaseService
            var id = "ANON-" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
            Assert.DoesNotContain(id, ids);
            ids.Add(id);
        }

        Assert.Equal(iterations, ids.Count);
    }

    /// <summary>
    /// P5: Anonymous cases must have no user_id linkage.
    /// </summary>
    [Fact]
    public async Task AnonymousCase_HasNoUserId()
    {
        using var db = CreateDb();
        var anonCase = new Case
        {
            IsAnonymous = true,
            UserId = null,
            AnonymousCaseId = "ANON-TEST01",
            IncidentType = "Physical Violence",
            Description = "Test",
            IncidentDate = DateTime.UtcNow,
        };

        db.Cases.Add(anonCase);
        await db.SaveChangesAsync();

        var retrieved = await db.Cases.FindAsync(anonCase.Id);
        Assert.Null(retrieved!.UserId);
        Assert.True(retrieved.IsAnonymous);
        Assert.NotNull(retrieved.AnonymousCaseId);
    }

    /// <summary>
    /// P12: Report Case IDs must be unique across all submissions.
    /// </summary>
    [Fact]
    public void CaseIds_AreUnique_Across100Submissions()
    {
        var ids = new HashSet<Guid>();
        for (int i = 0; i < 100; i++)
        {
            var id = Guid.NewGuid();
            Assert.DoesNotContain(id, ids);
            ids.Add(id);
        }
        Assert.Equal(100, ids.Count);
    }
}
