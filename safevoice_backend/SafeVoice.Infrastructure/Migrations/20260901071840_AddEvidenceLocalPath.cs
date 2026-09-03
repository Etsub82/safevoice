using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SafeVoice.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddEvidenceLocalPath : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "LocalPath",
                table: "Evidence",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LocalPath",
                table: "Evidence");
        }
    }
}
