#!/bin/bash

################################################################################
# AWS Transcribe Deployment Script (Bash for Linux/Mac)
################################################################################
# Description: Deploys AWS Lambda functions and S3 event notifications for
#              audio transcription using Amazon Transcribe and Call Analytics
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default parameters
STACK_NAME="${1:-transcribe-stack}"
BUCKET_NAME="${2:-transcribe-bucket}"
LAMBDA_ROLE="${3:-TranscribeLambdaExecutionRole}"
REGION="${4:-us-east-1}"
TEMPLATE_FILE="transcribe-two-trigger-stack.yaml"
STANDARD_INPUT_PREFIX="input/"
STANDARD_OUTPUT_PREFIX="output/results/"
ANALYTICS_INPUT_PREFIX="analytics/"
ANALYTICS_OUTPUT_PREFIX="output/results/analytics/"
TRANSCRIBE_ROLE="AmazonTranscribeServiceRole-TranscribeRole"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Display help
show_help() {
    cat << EOF
AWS Transcribe Deployment Script

Usage: ./deploy.sh [STACK_NAME] [BUCKET_NAME] [LAMBDA_ROLE] [REGION]

Parameters:
  STACK_NAME        CloudFormation stack name (default: transcribe-stack)
  BUCKET_NAME       S3 bucket name (default: transcribe-bucket)
  LAMBDA_ROLE       IAM role name (default: TranscribeLambdaExecutionRole)
  REGION            AWS region (default: us-east-1)

Examples:
  # Deploy with defaults
  ./deploy.sh

  # Deploy with custom parameters
  ./deploy.sh my-transcribe my-bucket MyRole us-west-2

  # Deploy to production
  ./deploy.sh audio-transcribe-prod audio-transcribe-prod-bucket AudioTranscribeProdRole us-east-1

Supported Regions:
  us-east-1, us-west-2, eu-west-1, eu-central-1, ap-south-1

EOF
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Install from: https://aws.amazon.com/cli/"
        exit 1
    fi
    log_success "AWS CLI found: $(aws --version)"

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi
    local account=$(aws sts get-caller-identity --query Account --output text)
    local user=$(aws sts get-caller-identity --query Arn --output text)
    log_success "AWS credentials valid. Account: $account, User: $user"

    # Check template file
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi
    log_success "Template file found: $TEMPLATE_FILE"
}

# Validate template
validate_template() {
    log_info "Validating CloudFormation template with AWS..."
    if aws cloudformation validate-template \
        --template-body file://"$TEMPLATE_FILE" \
        --region "$REGION" > /dev/null; then
        log_success "Template validation successful"
    else
        log_error "Template validation failed"
        exit 1
    fi
}

# Check if S3 bucket exists
check_bucket() {
    log_info "Checking if S3 bucket exists: $BUCKET_NAME"
    if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
        log_success "S3 bucket found: $BUCKET_NAME"
        return 0
    else
        log_warning "S3 bucket not found: $BUCKET_NAME"
        return 1
    fi
}

# Create S3 bucket
create_bucket() {
    log_info "Creating S3 bucket: $BUCKET_NAME"
    if [ "$REGION" == "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    log_success "S3 bucket created successfully: $BUCKET_NAME"
}

# Deploy CloudFormation stack
deploy_stack() {
    log_info "Deploying CloudFormation stack: $STACK_NAME"
    
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters \
            ParameterKey=ExistingBucketName,ParameterValue="$BUCKET_NAME" \
            ParameterKey=LambdaExecutionRoleName,ParameterValue="$LAMBDA_ROLE" \
            ParameterKey=StandardInputPrefix,ParameterValue="$STANDARD_INPUT_PREFIX" \
            ParameterKey=StandardOutputPrefix,ParameterValue="$STANDARD_OUTPUT_PREFIX" \
            ParameterKey=AnalyticsInputPrefix,ParameterValue="$ANALYTICS_INPUT_PREFIX" \
            ParameterKey=AnalyticsOutputPrefix,ParameterValue="$ANALYTICS_OUTPUT_PREFIX" \
            ParameterKey=TranscribeDataAccessRoleName,ParameterValue="$TRANSCRIBE_ROLE" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION"
    
    log_info "Stack creation initiated. Waiting for completion..."
    
    # Wait for stack creation
    if aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        --region "$REGION"; then
        log_success "Stack created successfully!"
    else
        log_error "Stack creation failed"
        exit 1
    fi
}

# Get stack outputs
get_outputs() {
    log_info "Retrieving stack outputs..."
    
    local outputs=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs' \
        --output json)
    
    echo -e "${GREEN}Stack Outputs:${NC}"
    echo "$outputs" | jq -r '.[] | "  - \(.OutputKey): \(.OutputValue)"'
}

# Show usage examples
show_examples() {
    echo ""
    echo -e "${BLUE}=== Usage Examples ===${NC}"
    echo ""
    echo "Upload files for standard transcription:"
    echo "  aws s3 cp audio.mp3 s3://$BUCKET_NAME/$STANDARD_INPUT_PREFIX --region $REGION"
    echo ""
    echo "Upload files for call analytics:"
    echo "  aws s3 cp recording.mp3 s3://$BUCKET_NAME/$ANALYTICS_INPUT_PREFIX --region $REGION"
    echo ""
    echo "View stack status:"
    echo "  aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     AWS Transcribe Deployment Suite                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_info "Starting AWS Transcribe Deployment"
    log_info "Stack: $STACK_NAME | Region: $REGION | Bucket: $BUCKET_NAME"
    echo ""
    
    # Execute deployment steps
    check_prerequisites
    validate_template
    
    if ! check_bucket; then
        read -p "Create S3 bucket '$BUCKET_NAME'? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            create_bucket
        else
            log_error "Cannot proceed without S3 bucket"
            exit 1
        fi
    fi
    
    deploy_stack
    get_outputs
    show_examples
    
    log_success "Deployment completed successfully!"
    echo ""
}

# Show help if requested
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
