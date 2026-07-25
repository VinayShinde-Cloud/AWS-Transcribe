# Product Overview

## What is this project?

**AWS Transcribe Deployment Suite** is a fully automated infrastructure-as-code solution for serverless audio transcription on Amazon Web Services.

## Key Purpose

Deploy production-ready audio transcription pipelines without manual AWS console configuration. Upload audio files to S3, trigger Lambda functions automatically, and get transcription results in seconds.

## Core Capabilities

- **Dual Transcription Modes**:
  - Standard Transcription: Convert any audio file to text
  - Call Analytics: Analyze two-channel call recordings (customer/agent conversations)

- **Fully Parameterized Deployment**: No hardcoded values—customize stack names, bucket names, regions, and IAM roles to fit your organization

- **Multi-Environment Support**: Deploy identical infrastructure to development, staging, or production with different configurations

- **Production Ready**: Includes error handling, CloudWatch monitoring, least-privilege IAM, and security best practices

## Use Cases

- Transcribe customer support recordings
- Convert podcasts/webinars to searchable text
- Analyze sales calls for compliance and training
- Process large batches of audio files automatically
- Build AI applications requiring audio-to-text pipelines

## How It Works

1. **User uploads audio** to a specific S3 folder (`input/` or `analytics/`)
2. **S3 event triggers Lambda** function automatically
3. **Lambda starts Transcribe job** on AWS Transcribe service
4. **Results saved to S3** (`output/results/`)
5. **CloudWatch logs** track all activity

## Tech Stack

- **Infrastructure**: AWS CloudFormation (YAML templates)
- **Compute**: AWS Lambda (Python 3.12)
- **Storage**: Amazon S3 with event notifications
- **Transcription**: Amazon Transcribe + Call Analytics
- **Deployment**: PowerShell scripts (Windows-native)
- **Monitoring**: CloudWatch Logs & Alarms

## Deployment Options

- **Quick Deploy**: Single PowerShell command with defaults (us-east-1)
- **Custom Deploy**: Parameterized script for custom naming/configuration and regions
- **Profile-Based**: Development/staging/production profiles in JSON config (all use us-east-1)
- **Dry-Run Mode**: Preview changes before deployment

## Security Model

- **Least-Privilege IAM**: Minimal permissions per role
- **S3 Encryption**: AES256 server-side encryption
- **No Secrets in Code**: All config via parameters/environment variables
- **Audit Logging**: CloudTrail and CloudWatch integration
- **Credential Management**: Uses AWS CLI credentials from ~/.aws/

## Status

✅ **Production Ready** — Fully tested, documented, and deployable
