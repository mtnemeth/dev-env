# Install WSL Ubuntu distro for development

## Pre-requisites: install WSL and enable PS script execution

In an **Admin** **PowerShell** console, run the following:

If WSL not yet installed:

```PS1
wsl --install

# Restart Windows
```

If installed, update:

```PS1
wsl --update
```

Enable running PS scripts:

```PS1
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
```

## Install the Distro

To get info about install options, run:

```PS1
Get-Help .\install.ps1 -Full
```

Run installer:

```PS1
.\install.ps1 -DistroName dev-tools -InstallDocker
```

## Start the distro

```PS1
wsl -d dev-tools
```
