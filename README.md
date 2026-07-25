# AWS Transcribe Deployment Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![AWS CloudFormation](https://img.shields.io/badge/AWS-CloudFormation-orange)](https://aws.amazon.com/cloudformation/)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://docs.microsoft.com/powershell/)

Automated serverless audio transcription on AWS. Deploy infrastructure in minutes, process unlimited audio files with zero hardcoded configuration.

## Features

- **Dual Transcription Modes**: Standard transcription + Call Analytics
- **Event-Driven**: S3 uploads automatically trigger Lambda functions
- **Multi-Environment**: Development, staging, and production profiles
- **Infrastructure as Code**: CloudFormation templates with no hardcoded values
- **Production Ready**: Error handling, CloudWatch logging, least-privilege IAM

## Quick Start

### 1. Clone Repository

```powershell
git clone https://github.com/VinayShinde-Cloud/AWS-Transcribe.git
cd AWS-Transcribe
```

### 2. Prerequisites

- Windows 10+ with PowerShell 5.1+
- [AWS CLI v2](https://aws.amazon.com/cli/)
- AWS credentials configured
- Supported regions: `us-east-1`, `us-west-2`, `eu-west-1`, `ap-south-1`

### 3. Deploy

```powershell
aws configure  # One-time setup

# Deploy to us-east-1 (recommended for reliability)
.\Deploy-TranscribeStack.ps1 -StackName "my-transcribe" -BucketName "my-bucket" -Region "us-east-1"

# Or deploy to another region
.\Deploy-TranscribeStack.ps1 -StackName "my-transcribe" -BucketName "my-bucket" -Region "us-west-2"
```

### 4. Use It

```powershell
# Upload audio for transcription
aws s3 cp audio.mp3 s3://my-bucket/input/

# Check results
aws s3 ls s3://my-bucket/output/results/

# View logs
aws logs tail /aws/lambda/my-transcribe-transcribe-trigger --follow
```

## Supported Audio Formats

MP3, MP4, WAV, FLAC, OGG, AMR, WebM

## Architecture

```
S3 Upload (input/) → Lambda → Amazon Transcribe → S3 Output (results/)
S3 Upload (analytics/) → Lambda → Call Analytics → S3 Output (analytics/)
```

## Configuration

Edit `deployment-config.json` for environment profiles:
- `development` - Testing environment
- `staging` - Pre-production validation
- `production` - Full-scale operations

## Deployment Methods

| Method | Use Case |
|--------|----------|
| `Deploy-TranscribeStack.ps1` | Custom parameters |
| `Deploy-WithConfig.ps1` | Profile-based deployment |
| `Quick-Start.ps1` | Daily operations |

## Cost Estimation

| Service | Usage | Est. Cost |
|---------|-------|-----------|
| Amazon Transcribe | 100 hrs | $60-$240/mo |
| AWS Lambda | Auto-scaling | <$1/mo |
| Amazon S3 | 10GB | <$5/mo |
| **Total** | | **~$65-$245/mo** |

## Security Considerations

- ✅ Least-privilege IAM roles
- ⚠️ Enable S3 encryption: `aws s3api put-bucket-encryption ...`
- ⚠️ Enable versioning: `aws s3api put-bucket-versioning ...`
- 📝 See [SECURITY.md](SECURITY.md) for production checklist

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Lambda not triggering | Wait 1-2 minutes (S3 event delay) or check logs |
| Permission denied | Verify IAM role has Transcribe permissions |
| S3 bucket not found | Use globally unique bucket name |

## Documentation

- [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) - Detailed setup steps
- [SECURITY.md](SECURITY.md) - Security best practices
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

## Commands Reference

```powershell
# Deploy with defaults
.\Deploy-TranscribeStack.ps1

# Deploy to specific region
.\Deploy-TranscribeStack.ps1 -Region "us-west-2"

# Profile-based deployment
.\Deploy-WithConfig.ps1 -Profile production

# Validate template only
.\Deploy-TranscribeStack.ps1 -ValidateOnly

# Dry run (preview changes)
.\Deploy-TranscribeStack.ps1 -DryRun

# Delete infrastructure
.\Deploy-TranscribeStack.ps1 -Operation DELETE

# Quick operations
.\Quick-Start.ps1 deploy
.\Quick-Start.ps1 upload-standard -FilePath "audio.mp3"
.\Quick-Start.ps1 list-jobs
.\Quick-Start.ps1 view-logs
```

## AWS Services Used

- **Amazon Transcribe** - Speech recognition
- **AWS Lambda** - Serverless compute
- **Amazon S3** - File storage
- **AWS CloudFormation** - Infrastructure automation
- **AWS IAM** - Access control
- **CloudWatch** - Monitoring & logging

## License

MIT License - See [LICENSE](LICENSE) file

## Support

- GitHub Issues: Report bugs and feature requests
- DEPLOYMENT-GUIDE.md: Comprehensive setup documentation
- SECURITY.md: Production security guidelines

---

**Status**: Production Ready ✅  
**Version**: 1.0.0  
**Last Updated**: July 2026  
**Repository**: https://github.com/VinayShinde-Cloud/AWS-Transcribe
