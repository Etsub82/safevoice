using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SafeVoice.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAssignmentAgreementReports : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "AgreementAccepted",
                table: "Users",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "AgreementAcceptedAt",
                table: "Users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "AssignedAt",
                table: "Cases",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "AssignedByHeadId",
                table: "Cases",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "AssignedOfficerId",
                table: "Cases",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReferralReason",
                table: "Cases",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReferredAt",
                table: "Cases",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReferredToDepartment",
                table: "Cases",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "OfficerReports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CaseId = table.Column<Guid>(type: "uuid", nullable: false),
                    OfficerId = table.Column<Guid>(type: "uuid", nullable: false),
                    ActionsTaken = table.Column<string>(type: "text", nullable: false),
                    Findings = table.Column<string>(type: "text", nullable: false),
                    Blockers = table.Column<string>(type: "text", nullable: true),
                    RecommendedNextAction = table.Column<string>(type: "text", nullable: true),
                    RequiresAnotherDepartment = table.Column<bool>(type: "boolean", nullable: false),
                    TargetDepartment = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ReviewedByHead = table.Column<bool>(type: "boolean", nullable: false),
                    ReviewedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OfficerReports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OfficerReports_Cases_CaseId",
                        column: x => x.CaseId,
                        principalTable: "Cases",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_OfficerReports_Users_OfficerId",
                        column: x => x.OfficerId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Cases_AssignedOfficerId",
                table: "Cases",
                column: "AssignedOfficerId");

            migrationBuilder.CreateIndex(
                name: "IX_OfficerReports_CaseId",
                table: "OfficerReports",
                column: "CaseId");

            migrationBuilder.CreateIndex(
                name: "IX_OfficerReports_OfficerId",
                table: "OfficerReports",
                column: "OfficerId");

            migrationBuilder.AddForeignKey(
                name: "FK_Cases_Users_AssignedOfficerId",
                table: "Cases",
                column: "AssignedOfficerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Cases_Users_AssignedOfficerId",
                table: "Cases");

            migrationBuilder.DropTable(
                name: "OfficerReports");

            migrationBuilder.DropIndex(
                name: "IX_Cases_AssignedOfficerId",
                table: "Cases");

            migrationBuilder.DropColumn(
                name: "AgreementAccepted",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AgreementAcceptedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AssignedAt",
                table: "Cases");

            migrationBuilder.DropColumn(
                name: "AssignedByHeadId",
                table: "Cases");

            migrationBuilder.DropColumn(
                name: "AssignedOfficerId",
                table: "Cases");

            migrationBuilder.DropColumn(
                name: "ReferralReason",
                table: "Cases");

            migrationBuilder.DropColumn(
                name: "ReferredAt",
                table: "Cases");

            migrationBuilder.DropColumn(
                name: "ReferredToDepartment",
                table: "Cases");
        }
    }
}
