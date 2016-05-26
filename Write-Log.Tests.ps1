$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleName = 'Write-Log'

Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
Import-Module $here\$moduleName.psd1 -Force

#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
#. "$here\$sut"



InModuleScope -ModuleName $moduleName {
    Describe 'Write-Log' {
        It 'should exist' {
            Get-Command -Name Write-Log\Write-Log -ErrorAction SilentlyContinue | Should Be $true
        }
        
        It 'creates C:\ERROR.log when Log is undefined' {
            $errorLog = 'C:\ERROR.log'
            If (Test-Path $errorLog -ErrorAction SilentlyContinue) {
                Remove-Item -Path $errorLog
            }
            Test-Path $errorLog | Should Be $false
            Write-Log -Message 'test message' -LogLevel 1
            $errorLog | Should Contain 'test message'
        }
        
        Context 'No existing directory or log file' {
            $LogDir = 'TestDrive:\dcinstall\Logs'
            $LogFile  = Join-Path $LogDir 'test.log'
            $PSDefaultParameterValues = @{ 'Write-Log:logFile' = $LogFile }
                                           
            It -Skip 'should not create a log file: LogLevel 0: Write-Host' {
                Test-Path $LogDir | Should Be $false
                Write-Log -Message 'Write-Host message' -LogLevel 0 | Should BeNullOrEmpty
                Test-Path $LogDir | Should Be $false
                Test-Path $LogFile | Should Be $false
            }
            
            It 'should not create a log file: LogLevel 3: Write-Verbose -Verbose' {
                Test-Path $LogDir | Should Be $false
                #Write-Log -Message 'Write-Verbose message' -LogLevel 3 | Should BeNullOrEmpty
                Write-Log -Message 'Write-Verbose message' -LogLevel 3 4>&1 | Should Match 'verbose'
                Test-Path $LogDir | Should Be $false
                Test-Path $LogFile | Should Be $false
            }

            It 'should create the log directory and file: LogLevel 1: Out-File' {
                Test-Path $LogDir | Should Be $false
                Write-Log -Message 'test message' -LogLevel 1 | Should BeNullOrEmpty
                Test-Path $LogDir | Should Be $true
                Test-Path $LogFile | Should Be $true
                $LogFile | Should Contain 'test message'
            }
            
            # Creating function to fatten up the log file
            function New-TestFile {
                param( [string]$FilePath,[int]$Size )
                $i = 0
                do {
                    '0' | Out-File -FilePath $FilePath -Append
                    $i++
                }
                until ((Get-ChildItem $FilePath).Length -ge $Size -or $i -gt 200)
                #Microsoft.PowerShell.Utility\Write-Host $i
            }

            # update test file with garbage data to simulate size
            New-TestFile -FilePath $LogFile -Size 1001
            
            It 'should roll over the log file after a certain size' {
                Test-Path -Path $LogFile | Should Be $true
                (Get-ChildItem -Path $LogDir).Count | Should Be 1
                Write-Log -Message 'this causes the file to roll over' -MaxSize 1000 -LogLevel 1
                (Get-ChildItem -Path $LogDir).Count | Should Be 2
                $LogFile | Should Contain 'this causes the file to roll over'
            }
        }
        Context 'Existing directory and log file' {
            $LogDir = 'TestDrive:\dcinstall\Logs'
            $LogFile  = Join-Path $LogDir 'test.log'
            $PSDefaultParameterValues = @{ 'Write-Log:logFile' = $LogFile }
            
            New-Item -Path $LogDir -ItemType Directory
            Out-File -FilePath $LogFile -InputObject 'derp'
            
            It 'should append to the log file: LogLevel 1 (default)' {
                $LogFile | Should Contain 'derp'
                Write-Log -Message 'things' | Should BeNullOrEmpty
            }
            
            It 'should accept -Verbose for the default loglevel' {
                $LogFile | Should Not Contain 'verbosity'
                Write-Log 'test verbosity' -Verbose 4>&1 | Should Match 'verbosity'
                $LogFile | Should Contain 'verbosity'
            }
            
            It 'should accept pipeline input' {
                Write-Verbose 'verbioso' -Verbose 4>&1 | Write-Log 
                $LogFile | Should Contain 'verbioso'
            }
        }
    }
}

#Remove-Variable Log -Scope Global
#Remove-Variable logFile -Scope Global
#Remove-Module Write-Log