# AWS Transcribe Deployment Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://docs.microsoft.com/en-us/powershell/)
[![AWS CLI v2](https://img.shields.io/badge/AWS%20CLI-v2-orange)](https://aws.amazon.com/cli/)
[![Status: Production Ready](https://img.shields.io/badge/Status-Production%20Ready-green)](README.md)

Fully automated AWS infrastructure deployment for serverless audio transcription using Amazon Transcribe and Call Analytics. Deploy in seconds, process unlimited audio files with zero hardcoded configuration.

## Overview

This project provides a complete PowerShell-based deployment solution for:
- ✅ AWS Lambda functions that trigger on S3 file uploads
- ✅ Amazon Transcribe for standard audio transcription
- ✅ Amazon Transcribe Call Analytics for conversation analysis
- ✅ Automatic S3 event notifications and folder management
- ✅ IAM roles with least-privilege security model
- ✅ Multi-region and multi-environment support

## Key Features

- **Zero Hardcoded Values**: All configurations are parameterized (fully project-customizable)
- **Multiple Deployment Modes**: Create, update, or delete infrastructure
- **Profile-Based Configuration**: Development, staging, and production profiles
- **Dry-Run Support**: Preview changes before applying
- **Validation Mode**: Validate templates without deployment
- **Quick Start Helpers**: Convenient shortcuts for common operations
- **Comprehensive Logging**: Detailed output for troubleshooting
- **Production Ready**: Includes error handling, retry logic, and monitoring

## Project Structure

```
Transcribe/
├── 📄 Deploy-TranscribeStack.ps1        ⭐ Main deployment script (parameterized, no hardcoded names)
├── 📄 Deploy-WithConfig.ps1             Profile-based deployment using JSON config
├── 📄 Quick-Start.ps1                   Convenient shortcuts for common tasks
├── 📄 deployment-config.json            Environment profiles and configuration
├── 📄 transcribe-two-trigger-stack.yaml CloudFormation infrastructure template
├── 📄 DEPLOYMENT-GUIDE.md               Comprehensive deployment documentation
├── 📄 README.md                         This file
│
├── TranscribeFunction                   Lambda source for standard transcription
├── TranscribeAnalyticsFunction          Lambda source for call analytics
│
├── On_Mono_Channel/                     Sample audio files (mono)
│   ├── transcribe_1.mp3
│   ├── transcribe_2.mp4
│   └── transcribe_3.wav
│
└── On_2_Channels/                       Sample audio files (stereo/two channels)
    ├── InboundCall.mp3
    └── InboundRecording.mp3
```

## Quick Start

### 0. Clone the Repository

```powershell
git clone https://github.com/VinayShinde-Cloud/AWS-Transcribe.git
cd AWS-Transcribe
```

### 1. Prerequisites

- Windows 10+ or PowerShell 5.1+
- [AWS CLI v2](https://aws.amazon.com/cli/)
- AWS account with appropriate permissions

### 2. Configure AWS Credentials

```powershell
aws configure
# Enter your AWS Access Key ID, Secret Key, region, and output format
```

### 3. Deploy with Default Settings

```powershell
cd "C:\Users\<YourUsername>\Desktop\GEN-AI\Transcribe\Transcribe"

# Deploy to AWS
.\Deploy-TranscribeStack.ps1

# Or with custom parameters
.\Deploy-TranscribeStack.ps1 -BucketName "my-audio-bucket" -Region "us-west-2"
```

### 4. Start Using It

```powershell
# Upload file for standard transcription
aws s3 cp recording.mp3 s3://transcribe-bucket/input/

# Or use the quick start helper
.\Quick-Start.ps1 upload-standard -FilePath "C:\audio\recording.mp3"

# Check transcription status
.\Quick-Start.ps1 list-jobs
```

## Deployment Methods

### Method 1: Direct Deployment (Simplest)

```powershell
# Deploy with all defaults
.\Deploy-TranscribeStack.ps1

# Deploy with custom parameters
.\Deploy-TranscribeStack.ps1 `
    -StackName "my-transcribe-stack" `
    -BucketName "my-audio-bucket" `
    -Region "us-west-2"
```

### Method 2: Profile-Based Deployment (Recommended for Teams)

```powershell
# Deploy using development profile
.\Deploy-WithConfig.ps1 -Profile development

# Deploy using production profile
.\Deploy-WithConfig.ps1 -Profile production

# Show configuration without deploying
.\Deploy-WithConfig.ps1 -Profile staging -ShowConfig

# Deploy with parameter override
.\Deploy-WithConfig.ps1 -Profile development -Overrides @{ Region = "eu-west-1" }
```

### Method 3: Quick Start Helpers (Day-to-Day)

```powershell
# Deploy infrastructure
.\Quick-Start.ps1 deploy

# Upload files
.\Quick-Start.ps1 upload-standard -FilePath "C:\audio\recording.mp3"
.\Quick-Start.ps1 upload-analytics -FilePath "C:\audio\call.mp3"

# Monitor
.\Quick-Start.ps1 list-jobs
.\Quick-Start.ps1 view-logs
.\Quick-Start.ps1 stack-status
```

## Command Reference

### Deploy-TranscribeStack.ps1 (Main Script)

**Core Parameters:**
- `-StackName <string>` - CloudFormation stack name (default: "transcribe-stack")
- `-BucketName <string>` - S3 bucket name (default: "transcribe-bucket")
- `-LambdaExecutionRoleName <string>` - IAM role for Lambda (default: "TranscribeLambdaExecutionRole")
- `-Region <string>` - AWS region (default: "us-east-1")

**Operational Parameters:**
- `-Operation <CREATE|UPDATE|DELETE>` - Stack operation (default: CREATE)
- `-ValidateOnly` - Validate template without deployment
- `-DryRun` - Preview changes without applying

**Prefix Parameters:**
- `-StandardInputPrefix <string>` - Input folder for standard transcription (default: "input/")
- `-StandardOutputPrefix <string>` - Output folder (default: "output/results/")
- `-AnalyticsInputPrefix <string>` - Input folder for call analytics (default: "analytics/")
- `-AnalyticsOutputPrefix <string>` - Output folder (default: "output/results/analytics/")

**Examples:**
```powershell
# Basic deployment
.\Deploy-TranscribeStack.ps1

# Custom naming - use your own project names
.\Deploy-TranscribeStack.ps1 `
    -StackName "myproject-transcribe" `
    -BucketName "myproject-audio-2024" `
    -LambdaExecutionRoleName "MyProjectTranscribeRole" `
    -Region "us-west-2"

# Validate only
.\Deploy-TranscribeStack.ps1 -ValidateOnly

# Update existing stack
.\Deploy-TranscribeStack.ps1 -StackName "acme-transcribe" -Operation UPDATE

# Delete stack
.\Deploy-TranscribeStack.ps1 -StackName "acme-transcribe" -Operation DELETE -DryRun
```

### Quick-Start.ps1 (Day-to-Day Operations)

```powershell
# Deploy
.\Quick-Start.ps1 deploy

# Upload files
.\Quick-Start.ps1 upload-standard -FilePath "C:\audio\recording.mp3"
.\Quick-Start.ps1 upload-analytics -FilePath "C:\audio\call.mp3"

# Monitor jobs
.\Quick-Start.ps1 list-jobs
.\Quick-Start.ps1 list-results
.\Quick-Start.ps1 view-logs

# Stack management
.\Quick-Start.ps1 stack-status
.\Quick-Start.ps1 delete

# Help
.\Quick-Start.ps1 help
```

## Supported Audio Formats

### Standard Transcription
- MP3, MP4, WAV, FLAC, OGG, AMR, WebM

### Call Analytics
- MP3, MP4, WAV, FLAC, OGG, AMR, WebM
- Auto-detected languages: en-US, en-GB, es-US, fr-FR

## S3 Folder Structure

After deployment, your S3 bucket will contain:

```
s3://transcribe-bucket/
├── input/                          # Upload files here for standard transcription
│   └── recording.mp3
├── analytics/                      # Upload files here for call analytics
│   └── call-recording.mp3
└── output/
    ├── results/
    │   ├── job_recording.json      # Standard transcription output
    │   └── analytics/
    │       └── analytics_call.json # Call analytics output
```

## Troubleshooting

### Issue: "S3 bucket already exists"

**Solution**: Use a globally unique bucket name
```powershell
.\Deploy-TranscribeStack.ps1 -BucketName "my-unique-bucket-$(Get-Random 10000 99999)"
```

### Issue: "Insufficient permissions"

**Solution**: Verify IAM permissions
```powershell
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name $(aws iam get-user --query 'User.UserName' --output text)
```

### Issue: Lambda functions not triggering

**Solution**: Check S3 event notifications
```powershell
aws s3api get-bucket-notification-configuration --bucket transcribe-bucket
aws logs tail /aws/lambda/transcribe-stack-transcribe-trigger --follow
```

### Issue: Transcription jobs failing

**Solution**: Check job details and logs
```powershell
aws transcribe list-transcription-jobs --region us-east-1
aws logs tail /aws/lambda/transcribe-stack-transcribe-trigger --follow
```

See **DEPLOYMENT-GUIDE.md** for comprehensive troubleshooting.

## Cost Estimation

### Typical Monthly Cost (100 hours of transcription)

| Service | Usage | Cost |
|---------|-------|------|
| Amazon Transcribe | 100 hours | ~$60-$240 |
| AWS Lambda | 1,000 invocations | <$1 |
| Amazon S3 | 10GB storage | <$5 |
| **Total** | | **~$65-$245** |

See DEPLOYMENT-GUIDE.md for detailed pricing information.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Account                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │         Amazon S3 Bucket                             │    │
│  │  ┌────────────────────────────────────────────────┐  │    │
│  │  │ input/          → Standard Transcription       │  │    │
│  │  │ analytics/      → Call Analytics               │  │    │
│  │  │ output/results/ ← Transcription Results        │  │    │
│  │  └────────────────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────────────────┘    │
│         ↑                              ↓                       │
│         │ S3 Events                   S3 Output               │
│         │                                                     │
│  ┌──────────────────┐        ┌──────────────────┐            │
│  │  Lambda:         │        │  Lambda:         │            │
│  │  Standard        │        │  Call Analytics  │            │
│  │  Transcription   │        │  Transcription   │            │
│  └──────────────────┘        └──────────────────┘            │
│         │                             │                       │
│         └──────────────┬──────────────┘                       │
│                        ↓                                       │
│         ┌──────────────────────────────┐                      │
│         │  Amazon Transcribe Service   │                      │
│         │  (Standard & Call Analytics) │                      │
│         └──────────────────────────────┘                      │
│                        ↓                                       │
│         Results returned to S3 output folder                  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Management

### Deployment Profiles (deployment-config.json)

```json
{
  "deploymentProfiles": {
    "development": { ... },    // Dev environment settings
    "staging": { ... },         // Pre-prod settings
    "production": { ... }       // Prod settings
  }
}
```

### Customize Profiles

Edit `deployment-config.json` to add your own profiles:

```json
{
  "deploymentProfiles": {
    "mycompany": {
      "stackName": "mycompany-transcribe",
      "bucketName": "mycompany-audio",
      "lambdaExecutionRoleName": "MyCompanyTranscribeRole",
      "region": "us-west-2",
      ...
    }
  }
}
```

Then deploy:
```powershell
.\Deploy-WithConfig.ps1 -Profile mycompany
```

## Monitoring & Operations

### View Lambda Logs

```powershell
# Real-time logs
aws logs tail /aws/lambda/transcribe-stack-transcribe-trigger --follow

# Last 100 lines
aws logs tail /aws/lambda/transcribe-stack-transcribe-trigger --max-items 100
```

### Check Transcription Jobs

```powershell
# List running jobs
aws transcribe list-transcription-jobs --region us-east-1

# Get job details
aws transcribe get-transcription-job --transcription-job-name job_recording --region us-east-1
```

### Monitor Costs

```powershell
# Get billing information
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 ...
```

## Security Best Practices

1. **Enable S3 Versioning**
   ```powershell
   aws s3api put-bucket-versioning --bucket transcribe-bucket --versioning-configuration Status=Enabled
   ```

2. **Enable S3 Encryption**
   ```powershell
   aws s3api put-bucket-encryption --bucket transcribe-bucket --server-side-encryption-configuration '...'
   ```

3. **Set Lifecycle Policies** for old files
4. **Enable CloudTrail** for audit logging
5. **Use IAM Roles** with least-privilege access
6. **Monitor CloudWatch Alarms** for failures

## Support & Resources

- **AWS Transcribe Docs**: https://docs.aws.amazon.com/transcribe/
- **AWS CLI Reference**: https://docs.aws.amazon.com/cli/
- **CloudFormation Docs**: https://docs.aws.amazon.com/cloudformation/
- **Lambda Documentation**: https://docs.aws.amazon.com/lambda/
- **Security Guide**: See [SECURITY.md](SECURITY.md) for security best practices
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
- **Changelog**: See [CHANGELOG.md](CHANGELOG.md) for version history

## Important Notes

### Fully Parameterized - No Vendor Names ✅

All scripts are fully customizable. You can name:
- Stack, bucket, roles with your own project names
- All values are configuration-driven
- Clean, professional naming conventions

### Example - Customizing Everything

```powershell
# Deploy with YOUR naming conventions
.\Deploy-TranscribeStack.ps1 `
    -StackName "acme-audio-processor" `
    -BucketName "acme-recordings-2024" `
    -LambdaExecutionRoleName "AcmeAudioProcessorRole" `
    -Region "eu-west-1"
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Jan 2024 | Initial release - fully parameterized, no hardcoded values |

## License

This project is provided as-is for AWS infrastructure deployment.

---

**Last Updated**: January 2024  
**Author**: Deployment Suite  
**Status**: Production Ready ✅
