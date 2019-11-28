#!/bin/sh

DEFAULT_BRANCH="master"
S3_BUCKET_NAME="some-s3bucket-for-cloudformation-templates"
ACM_CERTIFICATE_ARN="arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# exit when any command fails
set -e

# first parameter is environment
# defaults to development
if [[ -z $1 ]]; then
    ENVIRONMENT="development"
else
    ENVIRONMENT=$1
fi

# second parametr is git branch name
if [[ -z $2 ]]; then
    BRANCH=${DEFAULT_BRANCH}
else
    BRANCH=$2
fi

# third parameter is owner of the stack
if [[ -z $3 ]]; then
    OWNER="Someone"
else
    OWNER=$3
fi

# fourth parameter is domain name
if [[ -z $4 ]]; then
    DOMAIN="example.com"
else
    DOMAIN=$4
fi

source ./use_colors.sh

REPLACE_TEMPLATES() {
    ECHO_GREEN "Replacing Templates"
    # upload CloudFormation templates to s3
    aws s3 sync ./templates s3://${S3_BUCKET_NAME} --delete
}

CHECK_TAGS() {
    TEST=$( aws ecr describe-images \
        --repository-name=$1 \
        --query "imageDetails[*].imageTags[?contains(@, \`${BRANCH}\`) == \`true\`]" )
    if [[ -z $TEST ]]; then
        echo "${1}:${DEFAULT_BRANCH}"
    else
        echo "${1}:${BRANCH}"
    fi
}

DEPLOY_STACK() {
    ECHO_GREEN "Deploying Stack"
    # create a branch specific deployment
    aws cloudformation deploy \
        --capabilities CAPABILITY_AUTO_EXPAND \
        --stack-name stack-${ENVIRONMENT}-${BRANCH} \
        --template-file templates/template-stack.yml \
        --s3-bucket "${S3_BUCKET_NAME}" \
        --s3-prefix "deploy_bin" \
        --tags owner=${OWNER} \
        --parameter-overrides Environment=${ENVIRONMENT} BranchName=${BRANCH} \
            RepoImageSomePublic="$( CHECK_TAGS somepublic )" \
            RepoImageSomePrivate="$( CHECK_TAGS someprivate )" \
            AcmCertificateArn="${ACM_CERTIFICATE_ARN}" \
            DomainName="${DOMAIN}" \
            S3BucketForTemplates="${S3_BUCKET_NAME}"
    #       RepoImageSomeservice="$( CHECK_TAGS someservice )"
    # RepoImage values are the 'name:tag' of the ECR images for the services
}

#########################
# Main body starts here #
#########################

REPLACE_TEMPLATES

DEPLOY_STACK
