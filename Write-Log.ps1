<#
.Synopsis
   Logs the passed "message" to a designated log file.
.DESCRIPTION
   Accepts a string input as a message and outputs it into a log file. If the log file
   doesn't exist, it will create it. If the stamp param is passed it will prefix with
   the time stamp. If debug mode is false it will skip writing to the log. If the log
   gets bigger than 1MB it will rename it and append the current date.
.EXAMPLE
   Write-Log "This is a message" -Stamp
#>
function Write-Log
{
	[cmdletBinding()]
	Param
    (
        [Parameter(Position=0,
                   ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        $Message
    ,
        [switch]$Stamp
    ,
        [switch]$DebugMode
    )
    
    Begin
    {
        # Check for log variable
        If (!$log) { 
            $log = "C:\ERROR.log" 
            $Message = "ERROR: Missing 'log' variable."
        }
        #Create log file/dir if it doesn't exist
        If (!(Test-Path $log)) { 
            If (!(Test-Path $logLocation)) { mkdir $logLocation | Out-Null }
            New-Item $log -ItemType "file" | Out-Null
        }
    }
    Process
    { 
        If ((!($DebugMode)) -or ($DebugMode -and $isDebug)) {
            # Add the time stamp if specified
            If ($Stamp) { $Message = "$(Get-Date) $Message" }
            # Write to the log
            Write-Host "$Message"
            Write-Output "$Message" | Out-File -FilePath $log -Append
        }
    }
    End
    {
        # Roll the log over if it gets bigger than 1MB
        $date = Get-Date -UFormat -%Y-%m-%d
	    If ((Get-ChildItem $log).Length -gt 1048576) {
		    Rename-Item -Path $log -NewName "$($MyInvocation.MyCommand.Name)-$date.log"
	    }
    }
}