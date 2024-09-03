# Define the necessary structs and API calls in PowerShell
$source = @"
using System;
using System.Runtime.InteropServices;

public class DeviceControl
{
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        IntPtr lpSecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool DeviceIoControl(
        IntPtr hDevice,
        uint dwIoControlCode,
        byte[] lpInBuffer,
        uint nInBufferSize,
        IntPtr lpOutBuffer,
        uint nOutBufferSize,
        out uint lpBytesReturned,
        IntPtr lpOverlapped);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@

Add-Type -TypeDefinition $source

# Define the device path and IOCTL code
$devicePath = "\\.\inpoutx64"  # The fixed device path
$ioctlCode = [System.BitConverter]::ToUInt32([System.BitConverter]::GetBytes(0x9c402008), 0)  # Convert to UInt32

# Open the device
$GENERIC_WRITE = 0x40000000
$OPEN_EXISTING = 3

$handle = [DeviceControl]::CreateFile($devicePath, $GENERIC_WRITE, 0, [IntPtr]::Zero, $OPEN_EXISTING, 0, [IntPtr]::Zero)

if ($handle -eq [IntPtr]::Zero) {
    Write-Host "Failed to open device: $devicePath" -ForegroundColor Red
    exit 1
}

# Function to send a command
function Send-Command($command) {
    $inBuffer = [byte[]]$command
    $bytesReturned = 0

    $result = [DeviceControl]::DeviceIoControl($handle, $ioctlCode, $inBuffer, $inBuffer.Length, [IntPtr]::Zero, 0, [ref]$bytesReturned, [IntPtr]::Zero)

    if (-not $result) {
        Write-Host "DeviceIoControl failed for command $($command -join ' ')" -ForegroundColor Red
    } else {
        Write-Host "Command sent successfully: $($command -join ' ')" -ForegroundColor Green
    }
}

# List of commands to send
$commands = @(
    @(0x4f, 0x00, 0x11),
    @(0x4e, 0x00, 0x2f),
    @(0x4f, 0x00, 0xc4),
    @(0x4e, 0x00, 0x2e),
    @(0x4f, 0x00, 0x10),
    @(0x4e, 0x00, 0x2f),
    @(0x4f, 0x00, 0xfc),
    @(0x4e, 0x00, 0x2e),
    @(0x4f, 0x00, 0x12),
    @(0x4e, 0x00, 0x2f),
    @(0x4f, 0x00, 0x01)
)

# Send each command
foreach ($cmd in $commands) {
    Send-Command $cmd
}

# Close the device handle
[DeviceControl]::CloseHandle($handle)
