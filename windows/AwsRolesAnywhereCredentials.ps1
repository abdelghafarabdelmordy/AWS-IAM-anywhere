<#
.SYNOPSIS
    AWS Roles Anywhere credential updater with scheduled task
.DESCRIPTION
    Fetches temporary AWS credentials using IAM Roles Anywhere and creates a scheduled task
    to run every 11 hours for automatic credential renewal
#>

# Configuration
$ROLE_ARN = "arn:aws:iam::147997145395:role/anywhere-s3-full-role"
$PROFILE_ARN = "arn:aws:rolesanywhere:us-east-1:1*********5:profile/25f3ab09-5ee4-4e3e-b423-b2****2b0395"
$TRUST_ANCHOR_ARN = "arn:aws:rolesanywhere:us-east-1:1*********5:trust-anchor/a70864db-816d-4b60-bbc6-77*****dd362"
$CERT = "cloudlyy01-client.crt"
$KEY = "cloudlyy01-client.key"
$SESSION_DURATION = 39600  # 11 hours in seconds
$AWS_PROFILE_NAME = "rolesanywhere-temp"
$CRED_FILE = "$env:TEMP\aws_creds.log"
$TASK_NAME = "AWS Roles Anywhere Credential Update"
$SCRIPT_NAME = $MyInvocation.MyCommand.Name
$SCRIPT_PATH = $MyInvocation.MyCommand.Path

function Update-AwsCredentials {
    [CmdletBinding()]
    param()
    
    try {
        Write-Verbose "Starting credential update process..." -Verbose
        
        # File verification
        if (-not (Test-Path $CERT)) { 
            throw "Certificate file not found at: $CERT"
        }
        if (-not (Test-Path $KEY)) { 
            throw "Private key file not found at: $KEY"
        }

        # Credential generation
        $helperCommand = ".\aws_signing_helper credential-process " +
            "--certificate `"$CERT`" " +
            "--private-key `"$KEY`" " +
            "--role-arn `"$ROLE_ARN`" " +
            "--profile-arn `"$PROFILE_ARN`" " +
            "--trust-anchor-arn `"$TRUST_ANCHOR_ARN`" " +
            "--session-duration $SESSION_DURATION"
        
        Write-Verbose "Executing: $helperCommand" -Verbose
        $credProcess = Invoke-Expression $helperCommand 2>&1 | Out-String
        
        if ($LASTEXITCODE -ne 0) {
            throw "Credential generation failed with output: $credProcess"
        }
        
        $credProcess | Out-File -FilePath "$CRED_FILE" -Force

        # Parse and update credentials
        $creds = Get-Content "$CRED_FILE" | ConvertFrom-Json
        $awsDir = Join-Path $env:USERPROFILE ".aws"
        
        if (-not (Test-Path $awsDir)) {
            New-Item -ItemType Directory -Path $awsDir | Out-Null
        }

        $credFilePath = Join-Path $awsDir "credentials"
        $profileBlock = "[$AWS_PROFILE_NAME]`n" +
            "aws_access_key_id = $($creds.AccessKeyId)`n" +
            "aws_secret_access_key = $($creds.SecretAccessKey)`n" +
            "aws_session_token = $($creds.SessionToken)"

        if (Test-Path $credFilePath) {
            $content = Get-Content $credFilePath -Raw
            if ($content -match "(?m)^\[$AWS_PROFILE_NAME\]") {
                $content = $content -replace "(?ms)^\[$AWS_PROFILE_NAME\].*?(?=\n\[|\z)", $profileBlock
            } else {
                $content += "`n$profileBlock`n"
            }
        } else {
            $content = $profileBlock
        }

        Set-Content -Path $credFilePath -Value $content.Trim()
        return $true
    }
    catch {
        Write-Verbose "ERROR: $_" -Verbose
        Write-Verbose "STACK TRACE: $($_.ScriptStackTrace)" -Verbose
        return $false
    }
}

function Create-ScheduledTask {
    [CmdletBinding()]
    param()
    
    try {
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            Write-Verbose "Updating existing scheduled task..." -Verbose
            Unregister-ScheduledTask -TaskName $TASK_NAME -Confirm:$false | Out-Null
        }

        # Create action
        $action = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$SCRIPT_PATH`""

        # Create trigger (every 11 hours)
        $trigger = New-ScheduledTaskTrigger `
            -Once `
            -At (Get-Date) `
            -RepetitionInterval (New-TimeSpan -Hours 11)

        # Create settings
        $settings = New-ScheduledTaskSettingsSet `
            -StartWhenAvailable `
            -DontStopOnIdleEnd `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -WakeToRun

        # Register task
        Register-ScheduledTask `
            -TaskName $TASK_NAME `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -RunLevel Highest `
            -Force | Out-Null

        Write-Host "SUCCESS: Scheduled task '$TASK_NAME' created to run every 11 hours" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERROR: Failed to create scheduled task: $_" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    # First update credentials
    $credSuccess = Update-AwsCredentials
    
    if ($credSuccess) {
        Write-Host "SUCCESS: Credentials updated successfully" -ForegroundColor Green
        
        # Then create/update scheduled task (requires admin)
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host "WARNING: Run as Administrator to create scheduled task" -ForegroundColor Yellow
        }
        else {
            $taskSuccess = Create-ScheduledTask
            if (-not $taskSuccess) {
                Write-Host "WARNING: Credentials updated but task scheduling failed" -ForegroundColor Yellow
            }
        }
    }
    else {
        Write-Host "ERROR: Credential update failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "CRITICAL ERROR in main execution: $_" -ForegroundColor Red
}

# Cleanup
if (Test-Path $CRED_FILE) {
    Remove-Item $CRED_FILE -Force -ErrorAction SilentlyContinue
}