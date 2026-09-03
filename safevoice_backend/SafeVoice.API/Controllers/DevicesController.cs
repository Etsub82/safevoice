using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SafeVoice.Core.Interfaces;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/devices")]
[Authorize]
public class DevicesController : ControllerBase
{
    private readonly INotificationService _notification;

    public DevicesController(INotificationService notification) => _notification = notification;

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] DeviceRegistrationDto dto)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await _notification.RegisterDeviceTokenAsync(userId, dto.FcmToken, dto.Platform);
        return Ok();
    }
}

public record DeviceRegistrationDto(string FcmToken, string Platform);
