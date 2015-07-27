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
        [string[]]$Message
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
        Try
        {
            Get-Variable -Name Log -Scope Global | Out-Null
            $Global:logFile = $Global:Log.Location + $Global:Log.Name + $Global:Log.Extension

        }
        Catch
        {
            $Global:Log  = @{
                                Location = "C:\"
                                Name = "ERROR" 
                                Extension = ".log"
                            }
            Write-Host $_.Exception.Message
            $Global:logFile = $Global:Log.Location + $Global:Log.Name + $Global:Log.Extension
            Write-Host "Error log location: $Global:logFile"
        }
        
        #Create log file/dir if it doesn't exist
        If (!(Test-Path $Global:logFile))
        {
            If (!(Test-Path $Global:Log.Location))
            {
                Write-Host "Creating $($Global:Log.Location)"
                mkdir $Global:Log.Location | Out-Null
            }
            Write-Host "Creating $Global:logFile"
            New-Item $Global:logFile -ItemType "file" | Out-Null
        }
    }
    Process
    {
        Foreach ($m in $Message)
        {
            # Add the time stamp
            $m = "$(Get-Date) $m"

            Write-Host "$m"
            If (!$WhatIf)
            {
                Out-File -InputObject $m -FilePath $Global:logFile -Append
            }
        }
    }
    End
    {
        # Roll the log over if it gets bigger than maxsize
        $date = Get-Date -UFormat %Y-%m-%d.%H-%M-%S
	    If ((Get-ChildItem $Global:logFile).Length -gt $maxsize)
        {
            Write-Output "Rolling log over because it reached maxsize: $maxsize Bytes" | Out-File -FilePath $Global:logFile -Append
		    Rename-Item -Path $Global:logFile `
                        -NewName $($Global:Log.Location + $Global:Log.Name + "__" + $date + $Global:Log.Extension)
	    }
    }
}