# Check if Graph PowerShell module is present, install if not
if (!(Get-Module -Name Microsoft.Graph.Intune)) {
    Install-Module -Name Microsoft.Graph.Intune -Scope CurrentUser -Force -Verbose
}

# Connect to Graph
Connect-MSGraph

# Path to CSV File, Example: "C:\TEMP\device_rename.csv"
$CSVFile = "<PATH TO CSV>"
$CSVFilePath = Split-Path $CSVFile -Parent

# Path to logfile
$LogFile = "$CSVFilePath\Intune_Rename_Script\intune_rename_script.log"
$LogDirectory = Split-Path $CSVFile -Parent
$LogDirectoryFullPath = $LogDirectory + "\Intune_Rename_Script\"

# Create the directory if it doesn't exist

if (!(Test-Path $LogDirectoryFullPath)) {
    New-Item -ItemType Directory -Path $LogDirectoryFullPath | Out-Null
}

# Import the CSV file
$DeviceList = Import-Csv $CSVFile -Delimiter ";"

$deviceCounter = 0


# Loop through each device in the list
foreach ($Device in $DeviceList) {
    # Get the device information
    $SerialNumber = $Device.SerialNumber
    $NewDeviceName = $Device.Devicename

    Write-Output $SerialNumber
    Write-Output $NewDeviceName

    # Get the Intune device with matching serial number
    $IntuneDevice = Get-IntuneManagedDevice -Filter "SerialNumber eq '$SerialNumber'"

    # Rename the device if it's found
    if ($IntuneDevice) {
        # Check if the current device name matches the new device name
        if ($IntuneDevice.DeviceName -ne $NewDeviceName) {
            $DeviceId = $IntuneDevice.id
            $Resource = "deviceManagement/managedDevices('$DeviceID')/setDeviceName"
            $GraphApiVersion = "Beta"
            $URI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            $JSONPayload = @"
    {
    deviceName:"$NewDeviceName"
    }
"@
            Write-Output $JSONPayload
            Invoke-MSGraphRequest -HttpMethod POST -Url $uri -Content $JSONPayload -Verbose -ErrorAction Continue

            $deviceCounter++

            Write-Output "$deviceCounter devices has been renamed."
            Write-Output "$deviceCounter devices has been renamed." | Out-File $LogFile -Append
        }
        else {
            Write-Output "Device with serial number $SerialNumber is already named $NewDeviceName."
            Write-Output "Device with serial number $SerialNumber is already named $NewDeviceName." | Out-File $LogFile -Append
        }
    }
    else {
        Write-Output "Device with serial number $SerialNumber was not found."
        Write-Output "Device with serial number $SerialNumber was not found." | Out-File $LogFile -Append
    }
}

Invoke-Item -Path $LogFile