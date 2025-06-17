<#
    .SYNOPSIS
    Installs an Ubuntu WSL Distro for dev work.

    .DESCRIPTION
    Installs an Ubuntu WSL Distro for dev work.

    .PARAMETER TempDir
    Temporary directory used during the installation.

    .PARAMETER WslDistroInstallPath
    Installation directory for the WSL Distro.

    .PARAMETER DistroName
    Name of the WSL Distro. You will run the distro with 'wsl -d <DistroName>'.

    .PARAMETER Cached
    Re-uses previously downloaded image file in the temporary folder.

    .PARAMETER NotEnableSystemD
    The installer enables SystemD by default. Set this to true if you don't want to.

    .PARAMETER InstallDocker
    Installs the Docker engine into the WSL Distro.

    .EXAMPLE
    PS> .\install.ps1 -DistroName dev-tools -InstallDocker

#>

param (
    [string]$TempDir="$env:TEMP\wsl-installer-script-temp",
    [string]$WslDistroInstallPath="C:\dev\wsl\",
    [string]$DistroName="dev-tools",
    [switch]$Cached=$false,
    [switch]$NotEnableSystemD=$false,
    [switch]$InstallDocker=$false
)

$ErrorActionPreference = "Stop"

$InstallDir=Join-Path -Path "$WslDistroInstallPath" -ChildPath "$DistroName"

if ($InstallDocker) {$NotEnableSystemD=$false}

Write-Output "----------------------------------------"
Write-Output "Parameters:"
Write-Output "  TempDir         : $TempDir"
Write-Output "  InstallDir      : $InstallDir"
Write-Output "  DistroName      : $DistroName"
Write-Output "  Cached          : $Cached"
Write-Output "  Enable SystemD  : $(!$NotEnableSystemD)"
Write-Output "  Install Docker  : $InstallDocker"
Write-Output "----------------------------------------"

function Install-Distro {
    $WslUser="eng"
    $WslGroup="engineer"
    $WslPwd="eng"

    Write-Output "Check if distro already installed."
    $distroInstalled = (wsl -l | Where-Object {$_.Replace("`0","") -match $DistroName}) -replace '\x00',''
    if ($distroInstalled -match "$([regex]::escape($DistroName)).*") {
        Write-Output "Distro is already installed. If you continue, the distro will be removed first and then re-installed."
        $choices = [System.Management.Automation.Host.ChoiceDescription[]]@('&Yes', '&No')
        $decision = $Host.UI.PromptForChoice("Confirm '$DistroName' distro re-install", 'Are you sure you want to proceed?', $choices, 1)
        if ($decision -eq 0) {
            Write-Host 'Confirmed'
        } else {
            Write-Host 'Exiting'
            exit
        }
        Write-Output "Removing existing distro."
        wsl --terminate $DistroName
        if (!$?) { throw "WSL terminate failed" }
        wsl --unregister $DistroName
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

    $destFile = "$TempDir\ubuntu.wsl"

    if (!($Cached)) {
        Write-Output "Download Linux root file system image for WSL."
        $maxAttempts = 5
        $attemptCount = 0
        $wc = New-Object net.webclient
        Do {
            Write-Output "> Attempt $attemptCount"
            $attemptCount++
            $wc.Downloadfile("https://cdimages.ubuntu.com/ubuntu-wsl/noble/daily-live/current/noble-wsl-amd64.wsl", $destFile)
        } while (((Test-Path $destFile) -eq $false) -and ($attemptCount -le $maxAttempts))
        if (!(Test-Path $destFile)) {
            throw "Failed to download root file system image."
        }
    }

    Write-Output "Create new WSL distro for Dev Tools by importing the root file system image."
    wsl --import $DistroName $InstallDir $destFile --version 2
    if (!$?) { throw "WSL import failed" }

    Write-Output "Distro name: ($DistroName)"

    Write-Output "Running initial distro setups: create and set non-root default user, etc."
    wsl -d $DistroName -e ./src/initial-distro-setups.sh "$WslGroup" "$WslUser" "$WslPwd"
    if (!$?) { throw "WSL distro initial setups failed" }

    if (!$NotEnableSystemD) {
        wsl -d $DistroName -e "./src/enable-systemd.sh"
    }

    Write-Output "Terminating the distro to force restart."
    wsl --terminate $DistroName
    if (!$?) { throw "WSL distro terminate failed" }

    Write-Output "Running pre-requisites setups"
    wsl -d $DistroName -e ./src/install-prerequisites.sh
    if (!$?) { throw "Pre-req setup failed" }

    if ($InstallDocker) {
        Write-Output "Running Docker engine setup"
        wsl -d $DistroName -e ./src/install-docker.sh
    }

    Write-Output "Terminating the distro to force restart."
    wsl --terminate $DistroName
    if (!$?) { throw "WSL distro terminate failed" }

    Write-Output "Create desktop shortcut for Dev Tools"
    $desktop_path = [Environment]::GetFolderPath('Desktop')
    $target_path = "$desktop_path\Dev-Tools.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($target_path)
    $shortcut.TargetPath = "wsl.exe"
    $shortcut.Arguments = "-d $DistroName"
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
