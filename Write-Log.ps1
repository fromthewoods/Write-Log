<#
.Synopsis
   Logs the passed "message" to a designated log file.
.DESCRIPTION
   Accepts a string input as a message and outputs it into a log file. If the log file
   doesn't exist, it will create it. If the stamp param is passed it will prefix with
   the time stamp. If debug mode is false it will skip writing to the log. If the log
   gets bigger than 'maxsize' it will rename it and append the current date.
.EXAMPLE
   Write-Log "This is a message" -Stamp
#>
function Write-Log
{
	[cmdletBinding()]
	Param
    (
        [Parameter(Position=0,
                   Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        $Message
    ,
        [switch]$Stamp
    ,
        [switch]$DebugMode
    ,
        [switch]$WhatIf
    ,
        # Size of log to roll over to a new file
        [int]$maxsize = 512000
    )
    
    Begin
    {
        # Check for log array
        If (!$log)
        {
            $log = @{
                Location = "C:\"
                Name = "ERROR" 
                Extension = ".log"
            }
            $Message = "ERROR: Missing 'log' array."
        }
        $logFile = $log.Location + $log.Name + $log.Extension
        #Create log file/dir if it doesn't exist
        If (!(Test-Path $logFile))
        {
            If (!(Test-Path $log.Location)) { mkdir $log.Location | Out-Null }
            New-Item $logFile -ItemType "file" | Out-Null
        }
    }
    Process
    { 
        # Add the time stamp if specified
        If ($Stamp) { $Message = "$(Get-Date) $Message" }
        
        # Write to the log debug mode
        If ($DebugMode -and $isDebug)
        {
            Write-Host "$Message"
            If (!$WhatIf) { Write-Output "$Message" | Out-File -FilePath $logFile -Append }
        } 
        # Write to log in non debug mode
        ElseIf (!($DebugMode))  
        {
            If (!$WhatIf) { Write-Output "$Message" | Out-File -FilePath $logFile -Append }
        }
    }
    End
    {
        # Roll the log over if it gets bigger than maxsize
        $date = Get-Date -UFormat %Y-%m-%d.%H-%M-%S
	    If ((Get-ChildItem $logFile).Length -gt $maxsize)
        {
            Write-Output "Rolling log over because it reached maxsize: $maxsize Bytes" | Out-File -FilePath $logFile -Append
		    Rename-Item -Path $logFile -NewName $($log.Location + $log.Name + "__" + $date + $log.Extension)
	    }
    }
}