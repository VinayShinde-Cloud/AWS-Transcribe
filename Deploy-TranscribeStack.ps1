# ============================================================================
# AWS Transcribe Deployment Script
# ============================================================================
# Description: Deploys AWS Lambda functions and S3 event notifications for
#              audio transcription using Amazon Transcribe and Call Analytics
# ============================================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$StackName = "transcribe-stack",
    
    [Parameter(Mandatory = $false)]
    [string]$BucketName = "transcribe-bucket",
    
    [Parameter(Mandatory = $false)]
    [string]$LambdaExecutionRoleName = "TranscribeLambdaExecutionRole",
    
    [Parameter(Mandatory = $false)]
    [string]$Region = "ap-south-1",
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateFilePath = "transcribe-two-trigger-stack.yaml",
    
    [Parameter(Mandatory = $false)]
    [string]$StandardInputPrefix = "input/",
    
    [Parameter(Mandatory = $false)]
    [string]$StandardOutputPrefix = "output/results/",
    
    [Parameter(Mandatory = $false)]
    [string]$AnalyticsInputPrefix = "analytics/",
    
    [Parameter(Mandatory = $false)]
    [string]$AnalyticsOutputPrefix = "output/results/analytics/",
    
    [Parameter(Mandatory = $false)]
    [string]$TranscribeDataAccessRoleName = "AmazonTranscribeServiceRole-TranscribeRole",
    
    [Parameter(Mandatory = $false)]
    [switch]$ValidateOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("CREATE", "UPDATE", "DELETE")]
    [string]$Operation = "CREATE"
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
}

# ============================================================================
# Functions
# ============================================================================

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Success", "Error", "Warning", "Info")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = $colors[$Level]
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-PrerequisitesInstalled {
    Write-Log "Checking prerequisites..." -Level Info
    
    # Check AWS CLI
    try {
        $awsVersion = aws --version
        Write-Log "AWS CLI found: $awsVersion" -Level Success
    }
    catch {
        Write-Log "AWS CLI is not installed or not in PATH" -Level Error
        Write-Log "Please install AWS CLI v2 from: https://aws.amazon.com/cli/" -Level Warning
        return $false
    }
    
    # Check AWS credentials
    try {
        $identity = aws sts get-caller-identity --region $Region
        $account = ($identity | ConvertFrom-Json).Account
        $user = ($identity | ConvertFrom-Json).Arn
        Write-Log "AWS credentials valid. Account: $account, User: $user" -Level Success
    }
    catch {
        Write-Log "AWS credentials not configured or invalid" -Level Error
        Write-Log "Run 'aws configure' to set up credentials" -Level Warning
        return $false
    }
    
    return $true
}

function Test-TemplateFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    Write-Log "Validating template file: $FilePath" -Level Info
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "Template file not found: $FilePath" -Level Error
        return $false
    }
    
    return $true
}

function Validate-CloudFormationTemplate {
    Write-Log "Validating CloudFormation template with AWS..." -Level Info
    
    try {
        $validation = aws cloudformation validate-template `
            --template-body "file://$TemplateFilePath" `
            --region $Region
        
        Write-Log "Template validation successful" -Level Success
        return $true
    }
    catch {
        Write-Log "Template validation failed: $_" -Level Error
        return $false
    }
}

function Test-BucketExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BucketNameToCheck
    )
    
    Write-Log "Checking if S3 bucket exists: $BucketNameToCheck" -Level Info
    
    try {
        aws s3api head-bucket --bucket $BucketNameToCheck --region $Region 2>$null
        Write-Log "S3 bucket found: $BucketNameToCheck" -Level Success
        return $true
    }
    catch {
        Write-Log "S3 bucket not found: $BucketNameToCheck" -Level Error
        return $false
    }
}

function Create-S3Bucket {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BucketNameToCreate
    )
    
    Write-Log "Creating S3 bucket: $BucketNameToCreate" -Level Info
    
    try {
        if ($Region -eq "us-east-1") {
            aws s3api create-bucket `
                --bucket $BucketNameToCreate `
                --region $Region
        }
        else {
            aws s3api create-bucket `
                --bucket $BucketNameToCreate `
                --region $Region `
                --create-bucket-configuration LocationConstraint=$Region
        }
        
        Write-Log "S3 bucket created successfully: $BucketNameToCreate" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to create S3 bucket: $_" -Level Error
        return $false
    }
}

function Deploy-CloudFormationStack {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StackOperation
    )
    
    Write-Log "Preparing CloudFormation parameters..." -Level Info
    
    # Build parameters for CloudFormation
    $params = @(
        "ParameterKey=ExistingBucketName,ParameterValue=$BucketName"
        "ParameterKey=LambdaExecutionRoleName,ParameterValue=$LambdaExecutionRoleName"
        "ParameterKey=StandardInputPrefix,ParameterValue=$StandardInputPrefix"
        "ParameterKey=StandardOutputPrefix,ParameterValue=$StandardOutputPrefix"
        "ParameterKey=AnalyticsInputPrefix,ParameterValue=$AnalyticsInputPrefix"
        "ParameterKey=AnalyticsOutputPrefix,ParameterValue=$AnalyticsOutputPrefix"
        "ParameterKey=TranscribeDataAccessRoleName,ParameterValue=$TranscribeDataAccessRoleName"
    )
    
    Write-Log "CloudFormation Parameters:" -Level Info
    foreach ($param in $params) {
        Write-Log "  - $param" -Level Info
    }
    
    if ($DryRun) {
        Write-Log "DRY RUN: Skipping actual deployment" -Level Warning
        return $true
    }
    
    try {
        if ($StackOperation -eq "CREATE") {
            Write-Log "Creating CloudFormation stack: $StackName" -Level Info
            
            aws cloudformation create-stack `
                --stack-name $StackName `
                --template-body "file://$TemplateFilePath" `
                --parameters $params `
                --capabilities CAPABILITY_NAMED_IAM `
                --region $Region `
                --on-failure DELETE
            
            Write-Log "Stack creation initiated. Waiting for completion..." -Level Info
            
            # Wait for stack creation
            aws cloudformation wait stack-create-complete `
                --stack-name $StackName `
                --region $Region
            
            Write-Log "Stack created successfully!" -Level Success
        }
        elseif ($StackOperation -eq "UPDATE") {
            Write-Log "Updating CloudFormation stack: $StackName" -Level Info
            
            aws cloudformation update-stack `
                --stack-name $StackName `
                --template-body "file://$TemplateFilePath" `
                --parameters $params `
                --capabilities CAPABILITY_NAMED_IAM `
                --region $Region
            
            Write-Log "Stack update initiated. Waiting for completion..." -Level Info
            
            # Wait for stack update
            aws cloudformation wait stack-update-complete `
                --stack-name $StackName `
                --region $Region
            
            Write-Log "Stack updated successfully!" -Level Success
        }
        elseif ($StackOperation -eq "DELETE") {
            Write-Log "Deleting CloudFormation stack: $StackName" -Level Warning
            
            aws cloudformation delete-stack `
                --stack-name $StackName `
                --region $Region
            
            Write-Log "Stack deletion initiated. Waiting for completion..." -Level Info
            
            # Wait for stack deletion
            aws cloudformation wait stack-delete-complete `
                --stack-name $StackName `
                --region $Region
            
            Write-Log "Stack deleted successfully!" -Level Success
        }
        
        return $true
    }
    catch {
        Write-Log "CloudFormation stack operation failed: $_" -Level Error
        return $false
    }
}

function Get-StackOutputs {
    Write-Log "Retrieving stack outputs..." -Level Info
    
    try {
        $stackInfo = aws cloudformation describe-stacks `
            --stack-name $StackName `
            --region $Region | ConvertFrom-Json
        
        $outputs = $stackInfo.Stacks[0].Outputs
        
        if ($outputs) {
            Write-Log "Stack Outputs:" -Level Success
            foreach ($output in $outputs) {
                Write-Host "  - $($output.OutputKey): $($output.OutputValue)" -ForegroundColor Green
            }
        }
        else {
            Write-Log "No outputs found for stack" -Level Warning
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to retrieve stack outputs: $_" -Level Error
        return $false
    }
}

function Test-LambdaFunctions {
    Write-Log "Testing Lambda functions..." -Level Info
    
    try {
        # Get Lambda functions from stack
        $resources = aws cloudformation describe-stack-resources `
            --stack-name $StackName `
            --region $Region | ConvertFrom-Json
        
        $lambdas = $resources.StackResources | Where-Object { $_.ResourceType -eq "AWS::Lambda::Function" }
        
        if ($lambdas) {
            Write-Log "Found $($lambdas.Count) Lambda functions" -Level Success
            foreach ($lambda in $lambdas) {
                Write-Log "  - $($lambda.LogicalResourceId): $($lambda.PhysicalResourceId)" -Level Info
            }
        }
        else {
            Write-Log "No Lambda functions found" -Level Warning
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to test Lambda functions: $_" -Level Error
        return $false
    }
}

function Show-DeploymentSummary {
    Write-Log "=== Deployment Summary ===" -Level Info
    Write-Host ""
    Write-Host "Stack Configuration:" -ForegroundColor Cyan
    Write-Host "  Stack Name:                    $StackName" -ForegroundColor White
    Write-Host "  Region:                        $Region" -ForegroundColor White
    Write-Host "  S3 Bucket:                     $BucketName" -ForegroundColor White
    Write-Host "  Lambda Role:                   $LambdaExecutionRoleName" -ForegroundColor White
    Write-Host ""
    Write-Host "Folder Prefixes:" -ForegroundColor Cyan
    Write-Host "  Standard Input:                $StandardInputPrefix" -ForegroundColor White
    Write-Host "  Standard Output:               $StandardOutputPrefix" -ForegroundColor White
    Write-Host "  Analytics Input:               $AnalyticsInputPrefix" -ForegroundColor White
    Write-Host "  Analytics Output:              $AnalyticsOutputPrefix" -ForegroundColor White
    Write-Host ""
}

function Show-UsageExamples {
    Write-Log "=== Usage Examples ===" -Level Info
    Write-Host ""
    Write-Host "Upload files for standard transcription:" -ForegroundColor Cyan
    Write-Host "  aws s3 cp audio.mp3 s3://$BucketName/$StandardInputPrefix --region $Region" -ForegroundColor White
    Write-Host ""
    Write-Host "Upload files for call analytics:" -ForegroundColor Cyan
    Write-Host "  aws s3 cp recording.mp3 s3://$BucketName/$AnalyticsInputPrefix --region $Region" -ForegroundColor White
    Write-Host ""
    Write-Host "View stack status:" -ForegroundColor Cyan
    Write-Host "  aws cloudformation describe-stacks --stack-name $StackName --region $Region" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# Main Execution
# ============================================================================

function Main {
    Write-Host ""
    Write-Log "Starting AWS Transcribe Deployment" -Level Info
    Write-Log "Operation: $Operation" -Level Info
    
    Show-DeploymentSummary
    
    # Validate template file exists
    if (-not (Test-TemplateFile $TemplateFilePath)) {
        Write-Log "Cannot proceed without valid template file" -Level Error
        exit 1
    }
    
    # Check prerequisites
    if (-not (Test-PrerequisitesInstalled)) {
        Write-Log "Cannot proceed without required prerequisites" -Level Error
        exit 1
    }
    
    # Validate template
    if (-not (Validate-CloudFormationTemplate)) {
        Write-Log "Cannot proceed with invalid template" -Level Error
        exit 1
    }
    
    # Only check bucket for CREATE/UPDATE operations
    if ($Operation -ne "DELETE") {
        # Check if bucket exists
        if (-not (Test-BucketExists $BucketName)) {
            Write-Log "S3 bucket does not exist. Would you like to create it?" -Level Warning
            
            if (-not $DryRun) {
                $createBucket = Read-Host "Create bucket '$BucketName'? (yes/no)"
                
                if ($createBucket -eq "yes") {
                    if (-not (Create-S3Bucket $BucketName)) {
                        Write-Log "Failed to create bucket. Exiting." -Level Error
                        exit 1
                    }
                }
                else {
                    Write-Log "Cannot proceed without S3 bucket" -Level Error
                    exit 1
                }
            }
        }
    }
    
    # If validation only, exit here
    if ($ValidateOnly) {
        Write-Log "Template validation completed successfully. Use -ValidateOnly flag to skip deployment." -Level Success
        exit 0
    }
    
    # Deploy CloudFormation stack
    if (-not (Deploy-CloudFormationStack $Operation)) {
        Write-Log "Stack deployment failed" -Level Error
        exit 1
    }
    
    # Get stack outputs and test functions
    if ($Operation -ne "DELETE") {
        Get-StackOutputs
        Test-LambdaFunctions
        Show-UsageExamples
    }
    
    Write-Log "Deployment completed successfully!" -Level Success
    Write-Host ""
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
