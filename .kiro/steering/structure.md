# Project Structure & Organization

## Directory Layout

```
Transcribe/
│
├── 📋 Core Deployment Files
│   ├── Deploy-TranscribeStack.ps1        Main parameterized deployment script
│   ├── Deploy-WithConfig.ps1             Profile-based deployment (uses JSON config)
│   ├── Quick-Start.ps1                   Helper script for common operations
│   └── Teardown-Stack.ps1                Stack cleanup and removal script
│
├── 📄 Configuration & Templates
│   ├── deployment-config.json            Environment profiles (dev/staging/prod)
│   ├── transcribe-two-trigger-stack.yaml CloudFormation infrastructure template
│   └── test-event.json                   Sample Lambda test event
│
├── 📚 Documentation
│   ├── README.md                         Product overview and quick start
│   ├── DEPLOYMENT-GUIDE.md               Comprehensive deployment guide
│   ├── SECURITY.md                       Security policies and best practices
│   ├── CHANGELOG.md                      Version history and release notes
│   └── PROJECT-COMPLETE.txt              Project completion checklist
│
├── 🐍 Lambda Functions (Source Code)
│   ├── TranscribeFunction/               Standard transcription Lambda
│   │   └── (Python source - deployed by CloudFormation)
│   │
│   └── TranscribeAnalyticsFunction/      Call analytics Lambda
│       └── (Python source - deployed by CloudFormation)
│
├── 🔊 Sample Audio Files
│   ├── On_Mono_Channel/                  Single-channel audio samples
│   │   ├── transcribe_1.mp3
│   │   ├── transcribe_2.mp4
│   │   ├── transcribe_3.wav
│   │   └── aws                           (sample credential file)
│   │
│   └── On_2_Channels/                    Two-channel audio samples (call recordings)
│       ├── InboundCall.mp3
│       └── InboundRecording.mp3
│
├── ⚙️ Project Metadata
│   ├── .gitignore                        Git exclusions (credentials, secrets)
│   ├── .DS_Store                         macOS metadata (ignore)
│   ├── ReadersAreTheLeaders              (informational file)
│   └── Test_Sniffet                      (test snippet/reference)
│
└── .kiro/
    └── steering/                         Kiro AI guidance documents
        ├── product.md                    Product overview
        ├── tech.md                       Tech stack and build commands
        └── structure.md                  This file
```

## File Descriptions

### Deployment Scripts

**Deploy-TranscribeStack.ps1** (🌟 Primary Script)
- Fully parameterized deployment with no hardcoded values
- Supports CREATE, UPDATE, DELETE operations
- Comprehensive error handling and logging
- Features: dry-run, validation-only, color-coded output
- Best for: Custom deployments with specific naming conventions
- Command: `.\Deploy-TranscribeStack.ps1 -StackName "custom" -BucketName "custom-bucket"`

**Deploy-WithConfig.ps1**
- Profile-based deployment using deployment-config.json
- Simplifies multi-environment deployments
- Pre-configured profiles for dev/staging/prod
- Best for: Teams with standard environment profiles
- Command: `.\Deploy-WithConfig.ps1 -Profile production`

**Quick-Start.ps1**
- High-level helper commands for day-to-day operations
- Simplified subcommands: deploy, upload-standard, upload-analytics, list-jobs, view-logs, delete
- Best for: Operators who don't need to customize parameters
- Command: `.\Quick-Start.ps1 deploy`

**Teardown-Stack.ps1**
- Cleanup and removal of CloudFormation stack
- Removes Lambda functions, IAM roles, and S3 event notifications
- Safe deletion with confirmation prompts
- Command: `.\Teardown-Stack.ps1 -StackName "transcribe-stack"`

### Configuration Files

**deployment-config.json**
- Central configuration for all deployment profiles
- Three built-in profiles: development, staging, production
- Customizable parameters: stack names, bucket names, regions, prefixes
- Lambda configuration: memory (256 MB), timeout (180s), storage (512 MB)
- Transcribe settings: supported formats, language options, channel definitions
- CloudWatch: log retention (7 days), alarm thresholds
- Structure:
  - `deploymentProfiles`: Environment-specific settings
  - `awsConfig`: AWS SDK configuration (retries, timeouts)
  - `lambdaConfig`: Lambda function settings
  - `s3Config`: S3 bucket security and versioning
  - `transcribeConfig`: Transcribe service options
  - `monitoring`: CloudWatch and alarm configuration

**transcribe-two-trigger-stack.yaml**
- AWS CloudFormation template (YAML format)
- Deploys complete infrastructure: Lambda, IAM roles, S3 event notifications
- Fully parameterized (no hardcoded resource names)
- Resources created:
  - `TranscribeExecutionRole`: IAM role for Lambda functions
  - `TranscribeAccessPolicy`: Managed policy with least-privilege permissions
  - `TranscribeFunction`: Lambda for standard transcription
  - `TranscribeAnalyticsFunction`: Lambda for call analytics
  - S3 event notifications for automatic triggering
- Parameters passed from deployment scripts

**test-event.json**
- Sample Lambda invocation event for testing
- Used for manual testing in AWS Console or local environments
- Structure: S3 bucket notification payload

### Documentation Files

**README.md**
- Project overview and value proposition
- Quick start guide (3-4 minute setup)
- Command reference for all scripts
- Supported audio formats (MP3, MP4, WAV, FLAC, OGG, AMR, WebM)
- S3 folder structure explanation
- Architecture diagram
- Troubleshooting common issues
- Cost estimation table
- Configuration management guide

**DEPLOYMENT-GUIDE.md**
- Comprehensive step-by-step deployment instructions
- Prerequisites and prerequisites verification
- Detailed AWS credential setup
- Profile configuration walkthrough
- Monitoring and operations procedures
- Troubleshooting section with common errors
- Best practices for production deployments
- Cost analysis and optimization tips

**SECURITY.md**
- Data security policies (S3 encryption, versioning, public access blocking)
- IAM security best practices (least-privilege, credential rotation)
- Compliance considerations (GDPR, HIPAA, PCI-DSS)
- Audit logging setup (CloudTrail)
- Network security and VPC considerations
- Lambda security practices and code review
- Secrets management recommendations
- Dependency security and validation
- Disaster recovery procedures
- Post-deployment security checklist

**CHANGELOG.md**
- Version history and release notes
- Breaking changes documented
- New features and improvements per version
- Bug fixes and patches
- Upgrade instructions

**PROJECT-COMPLETE.txt**
- Project completion checklist
- Verification steps
- Sign-off documentation

### Lambda Functions

**TranscribeFunction/** (Standard Transcription)
- Triggered by S3 uploads to `input/` folder
- Processes single-channel or multi-channel audio
- Calls Amazon Transcribe StartTranscriptionJob
- Returns JSON results to `output/results/` folder
- Logs activity to CloudWatch
- Environment variables:
  - `BUCKET_NAME`: S3 bucket for I/O
  - `OUTPUT_PREFIX`: Where to store results
  - `TRANSCRIBE_ROLE`: IAM role ARN for Transcribe service

**TranscribeAnalyticsFunction/** (Call Analytics)
- Triggered by S3 uploads to `analytics/` folder
- Analyzes two-channel call recordings (customer/agent)
- Calls Amazon Transcribe StartCallAnalyticsJob
- Returns analysis JSON to `output/results/analytics/` folder
- Detects sentiment, sentiment trends, call categories
- Logs activity to CloudWatch
- Environment variables:
  - `BUCKET_NAME`: S3 bucket for I/O
  - `OUTPUT_PREFIX`: Where to store results
  - `TRANSCRIBE_ROLE`: IAM role ARN for Transcribe service

### Sample Audio Files

**On_Mono_Channel/**
- `transcribe_1.mp3`: Sample MP3 (mono)
- `transcribe_2.mp4`: Sample MP4 (mono)
- `transcribe_3.wav`: Sample WAV (mono)
- `aws`: Reference credential file (example only, not real credentials)
- Purpose: Testing standard transcription Lambda

**On_2_Channels/**
- `InboundCall.mp3`: Sample two-channel call (MP3)
- `InboundRecording.mp3`: Sample two-channel recording (MP3)
- Purpose: Testing call analytics Lambda
- Use case: Customer service or sales call recordings

### Project Metadata

**.gitignore**
- Excludes AWS credentials and secrets
- Ignores local test files and logs
- Common ignore patterns: `*.env`, `.aws/`, `credentials`, `secrets`

**.DS_Store**
- macOS metadata file (automatically generated)
- Safe to ignore, added to .gitignore

**ReadersAreTheLeaders**
- Project philosophy or informational document

**Test_Sniffet**
- Testing reference code or snippet

**.kiro/** (AI Guidance Directory)
- `product.md`: Product overview for AI context
- `tech.md`: Technical stack and commands
- `structure.md`: This file, project organization

## Configuration Flow

```
User Input
    ↓
Deploy-TranscribeStack.ps1 (parameters)
    ↓
    ├─→ Validates template
    ├─→ Checks AWS credentials
    ├─→ Creates/updates S3 bucket
    ├─→ Deploys CloudFormation stack (transcribe-two-trigger-stack.yaml)
    └─→ Returns stack outputs
        ↓
    AWS CloudFormation creates:
        ├─→ Lambda: TranscribeFunction
        ├─→ Lambda: TranscribeAnalyticsFunction
        ├─→ IAM Role: TranscribeExecutionRole
        ├─→ IAM Policy: TranscribeAccessPolicy
        └─→ S3 Event Notifications: input/ and analytics/ triggers
```

## Data Flow

```
User's Audio Files
    ↓
Upload to S3
    ├─→ s3://bucket/input/ → triggers TranscribeFunction
    └─→ s3://bucket/analytics/ → triggers TranscribeAnalyticsFunction
    ↓
Lambda Function (Python)
    ↓
Amazon Transcribe Service
    ↓
Results to S3
    ├─→ s3://bucket/output/results/job_*.json (standard)
    └─→ s3://bucket/output/results/analytics/*.json (call analytics)
    ↓
CloudWatch Logs
    └─→ /aws/lambda/transcribe-stack-*
```

## Common Operations Workflow

### Initial Setup
```
1. aws configure (one-time credential setup)
2. .\Deploy-TranscribeStack.ps1 (one-time infrastructure deployment)
3. Verify stack in AWS Console
```

### Daily Operations
```
1. Upload audio: aws s3 cp file.mp3 s3://bucket/input/
2. Wait for Lambda trigger (automatic)
3. Check results: aws s3 ls s3://bucket/output/results/
4. View logs: aws logs tail /aws/lambda/transcribe-stack-transcribe-trigger
```

### Scaling
```
1. Change Lambda memory/timeout in deployment-config.json
2. .\Deploy-WithConfig.ps1 -Profile production -Operation UPDATE
```

### Cleanup
```
1. .\Teardown-Stack.ps1 -StackName "transcribe-stack"
2. (Or manually delete via AWS Console)
```

## Key Conventions

- **Naming**: All resources use project-specific prefixes (no generic "test" or "demo")
- **Parameterization**: No hardcoded AWS account IDs, regions, or resource names
- **Logging**: Verbose output with timestamps and color coding
- **Error Handling**: Comprehensive validation and helpful error messages
- **Security**: Least-privilege IAM, encrypted S3, no secrets in code
- **Documentation**: Every script and configuration is well-commented
