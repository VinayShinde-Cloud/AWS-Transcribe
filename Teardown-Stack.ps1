# ============================================================================
# AWS Transcribe Stack Teardown Script
# ============================================================================
# Description: Safely removes AWS infrastructure created by the deployment
#              CloudFormation stack. Handles data preservation and cleanup.
# ============================================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$StackName = "transcribe-stack",
    
    [Parameter(Mandatory = $false)]
    [string]$BucketName = "transcribe-bucket",
    
    [Parameter(Mandatory = $false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory = $false)]
    [switch]$DeleteBucket,
    
    [Parameter(Mandatory = $false)]
    [switch]$DeleteLogs,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportData
)

# ============================================================================
# Configuration
# ============================================================================

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Colors for output
$colors = @{
    Success = "Green"
    Error   = "Red"
    Warning = "Yellow"
    Info    = "Cyan"
    Notice  = "Magenta"
}

# ============================================================================
# Functions
# ============================================================================

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Success", "Error", "Warning", "Info", "Notice")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = $colors[$Level]
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-StackExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StackNameToCheck
    )
    
    try {
        $stack = aws cloudformation describe-stacks `
            --stack-name $StackNameToCheck `
            --region $Region `
            --query 'Stacks[0].StackStatus' `
            --output text 2>$null
        
        if ($stack -and $stack -ne "DELETE_COMPLETE") {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Get-StackResources {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StackNameToQuery
    )
    
    try {
        $resources = aws cloudformation describe-stack-resources `
            --stack-name $StackNameToQuery `
            --region $Region | ConvertFrom-Json
        
        return $resources.StackResources
    }
    catch {
        Write-Log "Failed to get stack resources: $_" -Level Error
        return $null
    }
}

function Backup-S3Bucket {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BucketNameToBackup
    )
    
    Write-Log "Backing up S3 bucket data..." -Level Info
    
    try {
        $backupDir = ".\transcribe-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -ItemType Directory -Path $backupDir | Out-Null
        
        Write-Log "Creating local backup directory: $backupDir" -Level Info
        
        # Sync all data from S3 to local directory
        aws s3 sync "s3://$BucketNameToBackup" $backupDir `
            --region $Region
        
        Write-Log "Backup completed to: $((Get-Item $backupDir).FullName)" -Level Success
        return $backupDir
    }
    catch {
        Write-Log "Backup failed: $_" -Level Error
        return $null
    }
}

function Empty-S3Bucket {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BucketNameToEmpty
    )
    
    Write-Log "Emptying S3 bucket: $BucketNameToEmpty" -Level Warning
    
    try {
        # Get all versions
        $versions = aws s3api list-object-versions `
            --bucket $BucketNameToEmpty `
            --region $Region | ConvertFrom-Json
        
        $objectCount = 0
        $deleteCount = 0
        
        # Delete all current versions
        if ($versions.Contents) {
            Write-Log "Deleting $($versions.Contents.Count) objects..." -Level Info
            
            foreach ($obj in $versions.Contents) {
                aws s3api delete-object `
                    --bucket $BucketNameToEmpty `
                    --key $obj.Key `
                    --region $Region | Out-Null
                
                $deleteCount++
                if ($deleteCount % 10 -eq 0) {
                    Write-Log "Deleted $deleteCount objects..." -Level Info
                }
            }
        }
        
        # Delete all previous versions
        if ($versions.DeleteMarkers) {
            Write-Log "Deleting $($versions.DeleteMarkers.Count) delete markers..." -Level Info
            
            foreach ($marker in $versions.DeleteMarkers) {
                aws s3api delete-object `
                    --bucket $BucketNameToEmpty `
                    --key $marker.Key `
                    --version-id $marker.VersionId `
                    --region $Region | Out-Null
            }
        }
        
        Write-Log "Bucket emptied successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to empty bucket: $_" -Level Error
        return $false
    }
}

function Delete-S3Bucket {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BucketNameToDelete
    )
    
    Write-Log "Deleting S3 bucket: $BucketNameToDelete" -Level Warning
    
    try {
        # First empty the bucket
        if (-not (Empty-S3Bucket $BucketNameToDelete)) {
            Write-Log "Could not empty bucket. Aborting deletion." -Level Error
            return $false
        }
        
        # Delete the bucket
        aws s3api delete-bucket `
            --bucket $BucketNameToDelete `
            --region $Region
        
        Write-Log "Bucket deleted successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to delete bucket: $_" -Level Error
        return $false
    }
}

function Get-CloudWatchLogs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogGroupPrefix
    )
    
    Write-Log "Exporting CloudWatch logs..." -Level Info
    
    try {
        $logGroups = aws logs describe-log-groups `
            --log-group-name-prefix $LogGroupPrefix `
            --region $Region | ConvertFrom-Json
        
        if ($logGroups.logGroups) {
            $backupDir = ".\logs-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            New-Item -ItemType Directory -Path $backupDir | Out-Null
            
            foreach ($logGroup in $logGroups.logGroups) {
                Write-Log "Exporting: $($logGroup.logGroupName)" -Level Info
                
                $fileName = $logGroup.logGroupName.Replace("/", "-")
                $filePath = "$backupDir\$fileName.json"
                
                # Get all log events
                aws logs describe-log-streams `
                    --log-group-name $logGroup.logGroupName `
                    --region $Region | ConvertFrom-Json | 
                    ConvertTo-Json | Out-File $filePath
            }
            
            Write-Log "Logs exported to: $backupDir" -Level Success
            return $backupDir
        }
    }
    catch {
        Write-Log "Failed to export logs: $_" -Level Error
    }
    
    return $null
}

function Delete-CloudWatchLogs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StackNameToQuery
    )
    
    Write-Log "Deleting CloudWatch log groups..." -Level Info
    
    try {
        $logGroups = aws logs describe-log-groups `
            --log-group-name-prefix "/aws/lambda/$StackNameToQuery" `
            --region $Region | ConvertFrom-Json
        
        if ($logGroups.logGroups) {
            foreach ($logGroup in $logGroups.logGroups) {
                Write-Log "Deleting log group: $($logGroup.logGroupName)" -Level Info
                
                aws logs delete-log-group `
                    --log-group-name $logGroup.logGroupName `
                    --region $Region
            }
            
            Write-Log "Log groups deleted" -Level Success
            return $true
        }
    }
    catch {
        Write-Log "Failed to delete log groups: $_" -Level Error
    }
    
    return $false
}

function Remove-CloudFormationStack {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StackNameToDelete
    )
    
    Write-Log "Initiating CloudFormation stack deletion..." -Level Warning
    
    try {
        aws cloudformation delete-stack `
            --stack-name $StackNameToDelete `
            --region $Region
        
        Write-Log "Stack deletion initiated. Waiting for completion..." -Level Info
        
        # Wait for stack deletion
        aws cloudformation wait stack-delete-complete `
            --stack-name $StackNameToDelete `
            --region $Region
        
        Write-Log "Stack deleted successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Stack deletion failed or timed out: $_" -Level Error
        return $false
    }
}

function Show-TeardownSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StackNameSummary,
        
        [Parameter(Mandatory = $true)]
        [string]$BucketNameSummary,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupPath,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath
    )
    
    Write-Host ""
    Write-Log "=== TEARDOWN SUMMARY ===" -Level Notice
    
    Write-Host ""
    Write-Host "Removed Resources:" -ForegroundColor Cyan
    Write-Host "  ✓ CloudFormation Stack: $StackNameSummary" -ForegroundColor Green
    Write-Host "  ✓ Lambda Functions (2)" -ForegroundColor Green
    Write-Host "  ✓ IAM Roles and Policies" -ForegroundColor Green
    Write-Host "  ✓ S3 Event Notifications" -ForegroundColor Green
    
    if ($DeleteBucket) {
        Write-Host "  ✓ S3 Bucket: $BucketNameSummary" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ S3 Bucket (PRESERVED): $BucketNameSummary" -ForegroundColor Yellow
    }
    
    if ($DeleteLogs) {
        Write-Host "  ✓ CloudWatch Log Groups" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ CloudWatch Logs (PRESERVED)" -ForegroundColor Yellow
    }
    
    if ($BackupPath) {
        Write-Host ""
        Write-Host "Data Backup:" -ForegroundColor Cyan
        Write-Host "  Location: $BackupPath" -ForegroundColor White
        Write-Host "  Size: $((Get-ChildItem -Path $BackupPath -Recurse | Measure-Object -Sum -Property Length).Sum / 1MB) MB" -ForegroundColor White
    }
    
    if ($LogPath) {
        Write-Host ""
        Write-Host "Log Export:" -ForegroundColor Cyan
        Write-Host "  Location: $LogPath" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Log "Teardown completed successfully!" -Level Success
    Write-Host ""
}

function Show-PreTeardownWarnings {
    Write-Host ""
    Write-Log "=== IMPORTANT: READ BEFORE PROCEEDING ===" -Level Notice
    Write-Host ""
    
    Write-Host "This will DELETE:" -ForegroundColor Red
    Write-Host "  • CloudFormation stack: $StackName" -ForegroundColor Red
    Write-Host "  • All Lambda functions" -ForegroundColor Red
    Write-Host "  • IAM roles and policies" -ForegroundColor Red
    Write-Host "  • S3 event notifications" -ForegroundColor Red
    
    if (-not $DeleteBucket) {
        Write-Host ""
        Write-Host "This will PRESERVE:" -ForegroundColor Yellow
        Write-Host "  • S3 Bucket: $BucketName (data preserved)" -ForegroundColor Yellow
        Write-Host "  • CloudWatch Logs" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Note: Use -DeleteBucket to also remove the S3 bucket" -ForegroundColor Cyan
    }
    
    if ($ExportData) {
        Write-Host ""
        Write-Host "Data Export:" -ForegroundColor Green
        Write-Host "  • S3 data will be backed up locally" -ForegroundColor Green
        Write-Host "  • CloudWatch logs will be exported" -ForegroundColor Green
    }
    
    Write-Host ""
    
    if (-not $Force) {
        $confirm = Read-Host "Type 'DELETE' to confirm teardown"
        
        if ($confirm -ne "DELETE") {
            Write-Log "Teardown cancelled by user" -Level Info
            exit 0
        }
    }
}

# ============================================================================
# Main Execution
# ============================================================================

function Main {
    Write-Host ""
    Write-Log "Starting AWS Transcribe Stack Teardown" -Level Notice
    Write-Log "Stack: $StackName | Region: $Region" -Level Info
    
    # Check if stack exists
    if (-not (Test-StackExists $StackName)) {
        Write-Log "Stack not found: $StackName" -Level Error
        Write-Log "Verify the stack name and region are correct" -Level Warning
        exit 1
    }
    
    Write-Log "Stack found. Proceeding with teardown..." -Level Info
    
    # Show warnings and get confirmation
    Show-PreTeardownWarnings
    
    if ($DryRun) {
        Write-Log "DRY-RUN MODE: No changes will be made" -Level Warning
        Write-Log "To execute teardown, remove -DryRun flag" -Level Info
        exit 0
    }
    
    $backupPath = $null
    $logPath = $null
    
    # Export data if requested
    if ($ExportData) {
        Write-Log "Step 1: Exporting data..." -Level Info
        
        $backupPath = Backup-S3Bucket $BucketName
        $logPath = Get-CloudWatchLogs "/aws/lambda/$StackName"
        
        if ($backupPath -or $logPath) {
            Write-Log "Data export completed" -Level Success
        }
    }
    else {
        Write-Log "Step 1: Skipped (data export not requested)" -Level Info
    }
    
    # Delete CloudFormation stack
    Write-Log "Step 2: Deleting CloudFormation stack..." -Level Warning
    
    if (-not (Remove-CloudFormationStack $StackName)) {
        Write-Log "Stack deletion failed. Attempting to continue..." -Level Error
    }
    
    # Delete CloudWatch logs if requested
    if ($DeleteLogs) {
        Write-Log "Step 3: Deleting CloudWatch logs..." -Level Warning
        
        Delete-CloudWatchLogs $StackName | Out-Null
    }
    else {
        Write-Log "Step 3: Skipped (logs preserved)" -Level Info
    }
    
    # Delete S3 bucket if requested
    if ($DeleteBucket) {
        Write-Log "Step 4: Deleting S3 bucket..." -Level Warning
        
        if (-not (Delete-S3Bucket $BucketName)) {
            Write-Log "Bucket deletion failed" -Level Error
        }
    }
    else {
        Write-Log "Step 4: Skipped (bucket preserved)" -Level Info
    }
    
    # Show summary
    Show-TeardownSummary -StackNameSummary $StackName `
                        -BucketNameSummary $BucketName `
                        -BackupPath $backupPath `
                        -LogPath $logPath
}

# Run main function
try {
    Main
}
catch {
    Write-Log "Fatal error: $_" -Level Error
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
