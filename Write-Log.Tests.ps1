$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleName = "Write-Log"
Import-Module $here\$moduleName.psd1 -Force

#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
#. "$here\$sut"

#$Global:Log  = @{
#                    Location = "TestDrive:\"
#                    Name = "ERROR" 
#                    Extension = ".log"
#                }

Describe "Write-Log" {
    
    It "creates C:\ERROR.log when Log is undefined" {
        $errorLog = "C:\ERROR.log"
        If (Test-Path $errorLog -ErrorAction SilentlyContinue)
        {
            Remove-Item -Path $errorLog -Force
        }
        Test-Path $errorLog | Should Be $false
        Write-Log -Message "test message" -Verbose
        Test-Path $errorLog | Should Be $true
    }

    It "creates log directory if it doesn't exist" {
        $Global:Log  = @{ Location  = "TestDrive:\dcinstall\Logs\"
                          Name      = "ERROR" 
                          Extension = ".log"
                        }
        Test-Path $Log.Location | Should Be $false
        Write-Log -Message "test message" -Verbose
        Test-Path $Log.Location | Should Be $true
    }
}

Remove-Variable Log -Scope Global
Remove-Variable logFile -Scope Global
#Remove-Module Write-Log