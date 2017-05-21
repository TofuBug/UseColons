function Use-ColonsForPSDrives
{
    [CmdletBinding()] Param()
    $OldErrorAction = $ErrorActionPreference
    $OldEbug = $DebugPreference
    $oldverbose = $VerbosePreference
    $ErrorActionPreference = 'stop'
    $DebugPreference = 'continue'
    $VerbosePreference = 'continue'
    Write-Verbose "Getting installed PowerShell Providers"
    $Providers = @(Get-PSProvider)
    Write-Verbose "Looping through installed PowerShell Providers"
    $Providers | % `
    {
        Write-Progress `
            -Activity "searching installed PowerShell Providers" `
            -Status "Found installed PowerShell Provider $($_.Name)" `
            -PercentComplete ($Providers.IndexOf($_)/$Providers.Count*100) `
            -Id 1
        Write-Verbose "Found $($_.Name) checking its drives"
        Write-Debug "Drive count = $($_.Drives.count)"
        $_.Drives | Out-GridView
        $Drives = @($_.Drives | ? { (Get-Command | ? Name -eq "$($_.Name):") -eq $null })
        Write-Verbose "Searching for drives in the PowerShell Provider $($_.Name)"
        $Drives | % `
        { 
            Write-Progress `
                -Activity "Creating Colon based Functions" `
                -Status "Creating Colon based function: `"function $($_.Name):() {Set-Location $($_.Name):}`" for drive $($_.Name)" `
                -PercentComplete ($Drives.IndexOf($_)/$Drives.Count*100) `
                -ParentId 1
            Write-Verbose "Setting up: `"function $($_.Name):() {Set-Location $($_.Name):}`""
            if ($Verbose)
            {
                . Invoke-Expression -Command "function $($_.Name):() {Set-Location $($_.Name):}"
            }
            else
            {
                . Invoke-Expression -Command "function $($_.Name):() {Set-Location $($_.Name):}" -ErrorAction SilentlyContinue
            }
            Write-Verbose "Finished with drive $($_.Name)"
        }
    }
    # Cert and WSMan do not show up as providers until you try to naviagte to their drives
    # As a result we will add their functions manually but we will check if they are already set anyways
    if ((Get-Command | ? Name -eq "Cert:") -eq $null) { . Invoke-Expression -Command "function Cert:() {Set-Location Cert:}" }
    if ((Get-Command | ? Name -eq "WSMan:") -eq $null) { . Invoke-Expression -Command "function WSMan:() {Set-Location WSMan:}" }
    $ErrorActionPreference = $OldErrorAction
    $DebugPreference = $OldEbug
    $VerbosePreference = $oldverbose
}

. Use-ColonsForPSDrives