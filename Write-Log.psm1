function Write-Log
{
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
.PARAMETER Message
    A string or array of strings that will be written to the log.
.PARAMETER MaxSize
    The maximum size in bytes that the log can be before the function rolls the log into a
    new file.
.PARAMETER LogLevel
    Level 0 - Writes out to the screen via Write-Output
    Level 1 - Writes out to a file
    Level 2 - Writes to both the screen and file
#>
	[cmdletBinding()]
	Param
    (
        [Parameter(Position=0,
                   Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Message
    ,
        [Parameter(Position=1,
                   Mandatory=$false,
                   ValueFromPipeline=$false)]
        [string]$LogFile = 'C:\ERROR.log'
    ,
        [Parameter(Position=2,
                   Mandatory=$false,
                   ValueFromPipeline=$false)]
        [int]$MaxSize = 512000
    ,
        [Parameter(Position=3,
                   Mandatory=$false,
                   ValueFromPipeline=$false)]
        [ValidateSet('0','1','2')]
        [int]$LogLevel = 0
    )
    
    Begin
    {
        Try
        {
            If ($LogFile -eq 'C:\ERROR.log')
            {
                $LogDir = 'C:\'
                Write-Verbose "Logfile: $LogFile"
                Write-Verbose "LogDir: $LogDir"
            }
            Else
            {
                $LogDir = $LogFile.Substring(0,$(($LogFile.LastIndexOf('\'))+1))
                Write-Verbose "Logfile: $LogFile"
                Write-Verbose "LogDir: $LogDir"
            }
            
            If (!(Test-Path -Path $LogFile))
            {
                Write-Verbose "Part of the LogFile path doesn't exist."
                If (!(Test-Path -Path $LogDir ))
                {
                    Write-Verbose "The LogDir doesn't exist."
                    New-Item -Path $LogDir -ItemType Directory | Out-Null
                }
                Write-Verbose "Log file does not exist. Creating..."
                New-Item $LogFile -ItemType File | Out-Null
            }
            
            # Roll the log over if it gets bigger than maxsize
            $Log = Get-Item -Path $LogFile
	        If ($Log.Length -gt $MaxSize)
            {
                Write-Verbose "The LogFile is larger than $MaxSize bytes. Rolling over..."
                $date = Get-Date -UFormat %Y-%m-%d.%H-%M-%S
                $newName = $Log.BaseName + '__' + $date + $Log.Extension
                Write-Output "Rolling log over because it reached maxsize: $MaxSize Bytes" | Out-File -FilePath $LogFile -Append
		        Rename-Item -Path $LogFile -NewName $newName 
	        }
        }
        Catch
        {
            Write-Error "ERROR: $($_.Exception.Message)"
            Write-Error "ERROR: $($_.InvocationInfo.PositionMessage.Split('+')[0])"
            Exit 1
        }
    }
    Process
    {
        Foreach ($m in $Message)
        {
            # Add the time stamp
            $m = "$(Get-Date) $m"
            Try
            {
            	switch ($LogLevel)
                {
                    0 { Write-Host $m }
                    1 { Out-File -InputObject $m -FilePath $LogFile -Append }
                    2 { Out-File -InputObject $m -FilePath $LogFile -Append; Write-Host $m }
                }
            }
            Catch
            {
                Write-Error "ERROR: $($_.Exception.Message)"
                Write-Error "ERROR: $($_.InvocationInfo.PositionMessage.Split('+')[0])"
                Exit 1
            } 
        }
    }
    End
    {
    }
}