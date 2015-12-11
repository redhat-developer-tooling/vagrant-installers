<#
.SYNOPSIS
    Installs Vagrant from a substrate package.

.DESCRIPTION
    Installs Vagrant from a substrate package.

    This script requires administrative privileges.

    You can run this script from an old-style cmd.exe prompt using the
    following:

      powershell.exe -ExecutionPolicy Unrestricted -NoLogo -NoProfile -Command "& '.\package.ps1'"

.PARAMETER SubstrateDir
    Path to the substrate folder.

.PARAMETER VagrantRevision
    The commit revision of Vagrant to install.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SubstrateDir,

    [Parameter(Mandatory=$true)]
    [string]$VagrantRevision,

    [string]$VagrantSourceBaseURL="https://github.com/mitchellh/vagrant/archive/"
)

# Exit if there are any exceptions
$ErrorActionPreference = "Stop"

# Put this in a variable to make things easy later
$UpgradeCode = "1a672674-6722-4e3a-9061-8f539a8b0ed6"

# Get the directory to this script
$Dir = Split-Path $script:MyInvocation.MyCommand.Path

#--------------------------------------------------------------------
# Helper Functions
#--------------------------------------------------------------------
function Expand-ZipFile($file, $destination) {
    $shell = New-Object -ComObject "Shell.Application"
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item)
    }
}

#--------------------------------------------------------------------
# Install Vagrant
#--------------------------------------------------------------------
$VagrantTmpDir = [System.IO.Path]::GetTempPath()
$VagrantTmpDir = [System.IO.Path]::Combine(
    $VagrantTmpDir, [System.IO.Path]::GetRandomFileName())
[System.IO.Directory]::CreateDirectory($VagrantTmpDir) | Out-Null
Write-Host "Vagrant temp dir: $($VagrantTmpDir)"

$VagrantSourceURL = "$($VagrantSourceBaseURL)/v$($VagrantRevision).zip"
$VagrantDest      = "$($VagrantTmpDir)\vagrant.zip"

# Download
Write-Host "Downloading Vagrant: $($VagrantRevision)"
$client = New-Object System.Net.WebClient
$client.DownloadFile($VagrantSourceURL, $VagrantDest)

# Unzip
Write-Host "Unzipping Vagrant"
Expand-ZipFile -file $VagrantDest -destination $VagrantTmpDir

# Set the full path to where Vagrant is
$VagrantSourceDir = "$($VagrantTmpDir)\vagrant-$($VagrantRevision)"

# Build gem
Write-Host "Building Vagrant Gem"
Push-Location $VagrantSourceDir
&"$($SubstrateDir)\embedded\bin\gem.bat" build vagrant.gemspec
Copy-Item vagrant-*.gem -Destination vagrant.gem
Pop-Location

# Determine the version
$VagrantVersionFile = Join-Path $VagrantSourceDir version.txt
if (-Not (Test-Path $VagrantVersionFile)) {
    "0.1.0" | Out-File -FilePath $VagrantVersionFile
}
$VagrantVersion=$((Get-Content $VagrantVersionFile) -creplace '\.[^0-9]+(\.[0-9]+)?$', '$1')
Write-Host "Vagrant version: $VagrantVersion"

# Install gem. We do this in a sub-shell so we don't have to worry
# about restoring environmental variables.
$env:SubstrateDir     = $SubstrateDir
$env:VagrantSourceDir = $VagrantSourceDir
powershell {
    $ErrorActionPreference = "Stop"

    Set-Location $env:VagrantSourceDir
    $EmbeddedDir  = "$($env:SubstrateDir)\embedded"
    $env:GEM_PATH = "$($EmbeddedDir)\gems"
    $env:GEM_HOME = $env:GEM_PATH
    $env:GEMRC    = "$($EmbeddedDir)\etc\gemrc"
    $env:CPPFLAGS = "-I$($EmbeddedDir)\include"
    $env:LDFLAGS  = "-L$($EmbeddedDir)\lib"
    $env:Path     ="$($EmbeddedDir)\bin;$($env:Path)"
    $env:SSL_CERT_FILE = "$($EmbeddedDir)\cacert.pem"
    &"$($EmbeddedDir)\bin\gem.bat" install vagrant.gem --no-ri --no-rdoc

    # Extensions
    &"$($EmbeddedDir)\bin\gem.bat" install vagrant-share --no-ri --no-rdoc --source "http://gems.hashicorp.com"
}
Remove-Item Env:SubstrateDir
Remove-Item Env:VagrantSourceDir

#--------------------------------------------------------------------
# System Plugins
#--------------------------------------------------------------------
$contents = @"
{
    "version": "1",
    "installed": {
        "vagrant-share": {
            "ruby_version": "0",
            "vagrant_version": "$($VagrantVersion)"
        }
    }
}
"@
$contents | Out-File `
    -Encoding ASCII `
    -FilePath "$($SubstrateDir)\embedded\plugins.json"

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------
Remove-Item -Recurse -Force $VagrantTmpDir
