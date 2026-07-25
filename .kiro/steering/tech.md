# Tech Stack & Build System

## Technology Stack

### Infrastructure & Deployment
- **Infrastructure as Code**: AWS CloudFormation (YAML)
- **Deployment Scripting**: PowerShell 5.1+ (Windows native)
- **AWS CLI**: v2 (command-line interface for AWS)
- **Cloud Provider**: Amazon Web Services (AWS)

### Runtime & Compute
- **Lambda Runtime**: Python 3.12
- **Lambda Memory**: 256 MB (configurable)
- **Lambda Timeout**: 180 seconds
- **Ephemeral Storage**: 512 MB

### AWS Services Used
- **Amazon Transcribe**: Audio-to-text transcription
- **Amazon Transcribe Call Analytics**: Two-channel conversation analysis
- **Amazon S3**: Audio file storage and results delivery
- **AWS Lambda**: Serverless functions for orchestration
- **AWS CloudFormation**: Infrastructure provisioning
- **AWS IAM**: Identity and access management
- **Amazon CloudWatch**: Logging and monitoring

### Configuration & Data
- **Config Format**: JSON (deployment-config.json)
- **Template Format**: YAML (CloudFormation)
- **Lambda Dependencies**: boto3 (AWS SDK - built-in)
- **External Dependencies**: None (Python standard library only)

## Build & Deployment Commands

### Prerequisites Check
```powershell
# Verify AWS CLI is installed
aws --version

# Verify AWS credentials are configured
aws sts get-caller-identity

# Verify PowerShell version (5.1+)
$PSVersionTable.PSVersion
```

### Main Deployment Script
```powershell
# Deploy with defaults (region: us-east-1)
.\Deploy-TranscribeStack.ps1

# Deploy with custom parameters
.\Deploy-TranscribeStack.ps1 `
    -StackName "custom-stack" `
    -BucketName "custom-bucket" `
    -Region "us-east-1" `
    -Operation CREATE

# Validate template only
.\Deploy-TranscribeStack.ps1 -ValidateOnly

# Dry-run (preview without applying)
.\Deploy-TranscribeStack.ps1 -DryRun

# Update existing stack
.\Deploy-TranscribeStack.ps1 -Operation UPDATE

# Delete stack
.\Deploy-TranscribeStack.ps1 -Operation DELETE
```

### Profile-Based Deployment
```powershell
# Deploy using development profile
.\Deploy-WithConfig.ps1 -Profile development

# Deploy using production profile
.\Deploy-WithConfig.ps1 -Profile production

# Show config without deploying
.\Deploy-WithConfig.ps1 -Profile staging -ShowConfig
```

### Quick Start Helpers
```powershell
# Deploy infrastructure
.\Quick-Start.ps1 deploy

# Upload file for standard transcription
.\Quick-Start.ps1 upload-standard -FilePath "C:\audio\recording.mp3"

# Upload file for call analytics
.\Quick-Start.ps1 upload-analytics -FilePath "C:\audio\call.mp3"

# Monitor jobs
.\Quick-Start.ps1 list-jobs
.\Quick-Start.ps1 list-results

# View logs
.\Quick-Start.ps1 view-logs

# Stack status
.\Quick-Start.ps1 stack-status

# Teardown
.\Quick-Start.ps1 delete
```

## Configuration Files

### deployment-config.json
**Purpose**: Environment profiles and deployment settings

**Structure**:
```json
{
  "deploymentProfiles": {
    "development": { /* dev settings */ },
    "staging": { /* staging settings */ },
    "production": { /* prod settings */ }
  },
  "defaultProfile": "development",
  "awsConfig": { /* AWS SDK config */ },
  "lambdaConfig": { /* Lambda settings */ },
  "s3Config": { /* S3 bucket config */ },
  "transcribeConfig": { /* Transcribe service config */ },
  "monitoring": { /* CloudWatch config */ }
}
```

**Key Settings**:
- Stack names (customizable per environment)
- S3 bucket names
- IAM role names
- AWS region
- Input/output S3 prefixes
- Lambda memory, timeout, storage
- Transcribe supported formats
- CloudWatch log retention
- Alarms and thresholds

### transcribe-two-trigger-stack.yaml
**Purpose**: CloudFormation infrastructure template

**Deploys**:
- IAM role for Lambda execution
- IAM managed policy for S3 and Transcribe access
- Lambda function for standard transcription
- Lambda function for call analytics
- S3 event notifications (input/ and analytics/ triggers)

**Parameters**:
- ExistingBucketName
- LambdaExecutionRoleName
- StandardInputPrefix
- StandardOutputPrefix
- AnalyticsInputPrefix
- AnalyticsOutputPrefix
- TranscribeDataAccessRoleName

## AWS CLI Commands Reference

### Verify Setup
```powershell
# Check AWS credentials
aws sts get-caller-identity

# List S3 buckets
aws s3 ls
```

### Manage CloudFormation Stacks
```powershell
# List all stacks
aws cloudformation list-stacks --region us-east-1

# Describe stack
aws cloudformation describe-stacks --stack-name transcribe-stack --region us-east-1

# Validate template
aws cloudformation validate-template --template-body file://transcribe-two-trigger-stack.yaml

# Get stack events (for troubleshooting)
aws cloudformation describe-stack-events --stack-name transcribe-stack --region us-east-1
```

### Manage S3
```powershell
# Upload file
aws s3 cp recording.mp3 s3://bucket-name/input/

# List bucket contents
aws s3 ls s3://bucket-name/ --recursive

# Get file
aws s3 cp s3://bucket-name/output/results/job.json ./

# Enable versioning
aws s3api put-bucket-versioning --bucket bucket-name --versioning-configuration Status=Enabled
```

### Monitor Lambda & Logs
```powershell
# List Lambda functions
aws lambda list-functions --region us-east-1

# Get function details
aws lambda get-function --function-name transcribe-trigger --region us-east-1

# Invoke function (test)
aws lambda invoke --function-name transcribe-trigger --payload '{}' response.json --region us-east-1

# View Lambda logs (real-time)
aws logs tail /aws/lambda/transcribe-stack-transcribe-trigger --follow

# View logs (specific time range)
aws logs filter-log-events --log-group-name /aws/lambda/transcribe-stack-transcribe-trigger --start-time 1640000000000 --end-time 1640100000000
```

### Monitor Transcribe Jobs
```powershell
# List transcription jobs
aws transcribe list-transcription-jobs --region us-east-1

# Get job status
aws transcribe get-transcription-job --transcription-job-name job_recording --region us-east-1

# List call analytics jobs
aws transcribe list-call-analytics-jobs --region us-east-1
```

## Code Standards

### PowerShell
- **Standard**: PowerShell 5.1+ (Core or Desktop edition)
- **Style**: 
  - Verbose output with color-coded logging
  - Proper error handling with try-catch
  - Parameterized inputs (no hardcoded values)
  - Comprehensive comments for complex logic
  - Functions organized by responsibility

### Python (Lambda)
- **Runtime**: Python 3.12
- **Framework**: boto3 (AWS SDK)
- **Style**:
  - No external dependencies (only stdlib + boto3)
  - Proper error handling with try-except
  - Input validation before AWS API calls
  - CloudWatch logging for debugging
  - Environment variable configuration

### YAML (CloudFormation)
- **Format**: AWS CloudFormation 2010-09-09
- **Style**:
  - Parameterized for flexibility
  - Descriptive resource names
  - Clear IAM policies with specific SIDs
  - Proper VPC and security configuration
  - Comments explaining complex sections

### JSON (Configuration)
- **Format**: Standard JSON
- **Style**:
  - Organized by concern (profiles, configs)
  - Descriptive keys
  - Default values provided
  - Comments via adjacent documentation

## No External Dependencies

⚠️ **Important**: This project intentionally avoids external dependencies:
- **PowerShell**: Only AWS CLI + built-in cmdlets
- **Python**: Only boto3 (included in Lambda runtime)
- **No package managers**: No npm, pip, nuget, etc. required

This reduces complexity, security surface, and deployment time.

## Version Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| PowerShell | 5.1+ | Core or Desktop edition |
| AWS CLI | v2 | Must be latest v2 branch |
| Python | 3.12 | Lambda runtime |
| boto3 | Built-in | Included in Lambda runtime |
| AWS Account | Current | Active with appropriate permissions |
| **Default Region** | **us-east-1** | Primary deployment region |

## Development Environment Setup

### Windows Local Machine
```powershell
# 1. Install AWS CLI v2
# Download from: https://aws.amazon.com/cli/

# 2. Configure AWS credentials
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Default region, Output format

# 3. Verify setup
aws sts get-caller-identity

# 4. Clone/download project
# Extract to: C:\Users\<Username>\Desktop\GEN-AI\Transcribe\Transcribe

# 5. Deploy
cd C:\Users\<Username>\Desktop\GEN-AI\Transcribe\Transcribe
.\Deploy-TranscribeStack.ps1
```

### CI/CD Pipeline Considerations
- Use service roles with temporary credentials
- Store AWS credentials in secrets manager (not in code)
- Validate templates before deployment
- Test in non-production first
- Use CloudFormation change sets for safety
- Deploy to us-east-1 by default unless region requirements dictate otherwise
