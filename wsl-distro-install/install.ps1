<#
    .SYNOPSIS
    Installs a WSL Linux Distro for dev work.

    .DESCRIPTION
    Installs a WSL Linux Distro for dev work.

    .PARAMETER TempDir
    Temporary directory used during the installation.

    .PARAMETER WslDistroInstallPath
    Installation directory for the WSL Distro.

    .PARAMETER WslDistroName
    Name of the WSL Distro. You will run the distro with 'wsl -d <WslDistroName>'.

    .PARAMETER LinuxDistro
    The Linux distribution to install. Valid values are 'debian' and 'ubuntu'.

    .PARAMETER Cached
    Re-uses previously downloaded image file in the temporary folder.

    .PARAMETER NotEnableSystemD
    The installer enables SystemD by default. Set this to true if you don't want to.

    .PARAMETER InstallDocker
    Installs the Docker engine into the WSL Distro.

    .PARAMETER InstallDevTools
    Installs development tools into the WSL Distro.

    .EXAMPLE
    PS> .\install.ps1 -WslDistroName dev-tools -InstallDocker -InstallDevTools

#>

param (
    [string]$TempDir="$env:TEMP\wsl-installer-script-temp",
    [string]$WslDistroInstallPath="$env:USERPROFILE\dev\wsl\",
    [string]$WslDistroName="dev-tools",
    [string][ValidateSet('debian','ubuntu') ]$LinuxDistro="debian",
    [switch]$Cached=$false,
    [switch]$NotEnableSystemD=$false,
    [switch]$InstallDocker=$false,
    [switch]$InstallDevTools=$false
)

$ErrorActionPreference = "Stop"

$InstallDir=Join-Path -Path "$WslDistroInstallPath" -ChildPath "$WslDistroName"

if ($InstallDocker) {$NotEnableSystemD=$false}

Write-Output "----------------------------------------"
Write-Output "Parameters:"
Write-Output "  TempDir         : $TempDir"
Write-Output "  InstallDir      : $InstallDir"
Write-Output "  WslDistroName   : $WslDistroName"
Write-Output "  Cached          : $Cached"
Write-Output "  Enable SystemD  : $(!$NotEnableSystemD)"
Write-Output "  Install Docker  : $InstallDocker"
Write-Output "----------------------------------------"

function Install-Distro {
    $WslUser="eng"
    $WslGroup="engineer"
    $WslPwd="eng"

    Write-Output "Check if distro already installed."
    $distroInstalled = (wsl -l | Where-Object {$_.Replace("`0","") -match $WslDistroName}) -replace '\x00',''
    if ($distroInstalled -match "$([regex]::escape($WslDistroName)).*") {
        Write-Output "Distro is already installed. If you continue, the distro will be removed first and then re-installed."
        $choices = [System.Management.Automation.Host.ChoiceDescription[]]@('&Yes', '&No')
        $decision = $Host.UI.PromptForChoice("Confirm '$WslDistroName' distro re-install", 'Are you sure you want to proceed?', $choices, 1)
        if ($decision -eq 0) {
            Write-Host 'Confirmed'
        } else {
            Write-Host 'Exiting'
            exit
        }
        Write-Output "Removing existing distro."
        wsl --terminate $WslDistroName
        if (!$?) { throw "WSL terminate failed" }
        wsl --unregister $WslDistroName
        if (!$?) { throw "WSL unregister failed" }
    } else {
        Write-Output "Distro not installed."
    }

    Write-Output "Delete temporary and install directories."
    $foldersToDelete = @($InstallDir)
    if (!($Cached)) {
        Write-Output "  (Cached$Cached = false) - deleting temp directory as well."
        $foldersToDelete += $TempDir
    }
    foreach ($path in $foldersToDelete) {
        if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Verbose -Recurse -Force
        if (!$?) { throw "Failed to delete path: $path" }
        } else {
        "Path doesn't exist: $path"
        }
    }

    Write-Output "Create temporary and install directories."
    if (!($Cached)) {
        New-Item -Path "$TempDir" -ItemType Directory | Out-Null
    }
    New-Item -Path $InstallDir -ItemType Directory | Out-Null

    $destFile = "$TempDir\linux-dev-tools.wsl"

    if (!($Cached)) {
        Write-Output "Download Linux root file system image for WSL."
        $maxAttempts = 5
        $attemptCount = 0
        $wc = New-Object net.webclient
        Do {
            Write-Output "> Attempt $attemptCount"
            $attemptCount++
            if ($LinuxDistro -eq "ubuntu") {
                $rootfsUrl = "https://cdimages.ubuntu.com/ubuntu-wsl/noble/daily-live/current/noble-wsl-amd64.wsl"
            } elseif ($LinuxDistro -eq "debian") {
                $rootfsUrl = "https://salsa.debian.org/debian/WSL/-/raw/master/x64/install.tar.gz"
            }
            $wc.Downloadfile($rootfsUrl, $destFile)
        } while (((Test-Path $destFile) -eq $false) -and ($attemptCount -le $maxAttempts))
        if (!(Test-Path $destFile)) {
            throw "Failed to download root file system image."
        }
    }

    Write-Output "Create new WSL distro for Dev Tools by importing the root file system image."
    wsl --import $WslDistroName $InstallDir $destFile --version 2
    if (!$?) { throw "WSL import failed" }

    Write-Output "Distro name: ($WslDistroName)"

    Write-Output "Running initial distro setups: create and set non-root default user, etc."
    wsl -d $WslDistroName -e ./src/initial-distro-setups.sh "$WslGroup" "$WslUser" "$WslPwd"
    if (!$?) { throw "WSL distro initial setups failed" }

    if (!$NotEnableSystemD) {
        wsl -d $WslDistroName -e "./src/enable-systemd.sh"
    }

    Write-Output "Terminating the distro to force restart."
    wsl --terminate $WslDistroName
    if (!$?) { throw "WSL distro terminate failed" }

    if ($InstallDocker) {
        Write-Output "Running Docker engine setup"
        wsl -d $WslDistroName -e ./src/install-docker.sh
    }

    if ($InstallDevTools) {
        Write-Output "Running Dev Tools setup"
        wsl -d $WslDistroName -e ../devtools-all/install.sh
    }

    Write-Output "Terminating the distro to force restart."
    wsl --terminate $WslDistroName
    if (!$?) { throw "WSL distro terminate failed" }

    Write-Output "Create desktop shortcut for Dev Tools"
    $desktop_path = [Environment]::GetFolderPath('Desktop')
    $target_path = "$desktop_path\Dev-Tools.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($target_path)
    $shortcut.TargetPath = "wsl.exe"
    $shortcut.Arguments = "-d $WslDistroName"
    $shortcut.Save()

    Write-Output "Install complete."

}

try{
    Push-Location $PSScriptRoot
    Install-Distro
}
finally {
    Pop-Location
}
