$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleName = 'Write-Log'

Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
Import-Module $here\$moduleName.psd1 -Force

#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
#. "$here\$sut"



Describe 'Write-Log' {
    InModuleScope -ModuleName $moduleName {
    
        It 'creates C:\ERROR.log when Log is undefined' {
            $errorLog = 'C:\ERROR.log'
            If (Test-Path $errorLog -ErrorAction SilentlyContinue)
            {
                Remove-Item -Path $errorLog -Force
            }
            Test-Path $errorLog | Should Be $false
            Write-Log -Message 'test message'
            Test-Path $errorLog | Should Be $true
        }

        Context '#1' {
            It "creates log directory if it doesn't exist" {
                $LogDir = 'TestDrive:\dcinstall\Logs'
                $LogFile  = Join-Path $LogDir 'test.log'
                Test-Path $LogDir | Should Be $false
                Write-Log -Message 'test message' -LogFile $LogFile
                Test-Path $LogDir | Should Be $true
                Test-Path $LogFile | Should Be $true
            }
        }

        Context '#2' {
            function New-TestFile {
                param( [string]$FilePath,[int]$Size )
                $i = 0
                do {
                    $i | Out-File -FilePath $FilePath -Append
                    $i++
                }
                until ((Get-ChildItem $FilePath).Length -ge $Size)
            }

            It 'rolls over the log file after a certain size' {
                $LogDir = 'TestDrive:\'
                $LogFile  = Join-Path $LogDir 'test.log'
                
                # Create test file with garbage data to simulate size
                New-TestFile -FilePath $LogFile -Size 1001
                Test-Path -Path $LogFile | Should Be $true
                (Get-ChildItem -Path $LogDir).Count | Should Be 1

                #The next call should rename the file and the following one will create a new log file.
                Write-Log -Message 'this causes the file to be renamed' -MaxSize 1000 -LogFile $LogFile
                Write-Log -Message 'this creates the new log file yayy' -MaxSize 1000 -LogFile $LogFile
                (Get-ChildItem -Path $LogDir).Count | Should Be 2
            }
        }
    }
}

#Remove-Variable Log -Scope Global
#Remove-Variable logFile -Scope Global
#Remove-Module Write-Log