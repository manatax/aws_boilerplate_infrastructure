#!/bin/sh

DEFAULT_BRANCH="master"

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

# thirs parameter is owner of the stack
if [[ -z $3 ]]; then
    OWNER="someone"
else
    OWNER=$3
fi

# fourth parameter is full base subdomain
if [[ -z $4 ]]; then
    SUBDOMAIN="api.example.com"
else
    SUBDOMAIN=$4
fi

source ./use_colors.sh

DELETE_STACK() {
    ECHO_GREEN "Pre-Deleting Static Website Bucket"
    # delete a branch specific s3-based static-website deployment
    aws s3 rb s3://${BRANCH}.${ENVIRONMENT}.${SUBDOMAIN} --force

    ECHO_GREEN "Deleting Stack"
    aws cloudformation delete-stack \
        --stack-name stack-${ENVIRONMENT}-${BRANCH}
}

#########################
# Main body starts here #
#########################

DELETE_STACK
