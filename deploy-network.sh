#!/bin/sh

DEFAULT_BRANCH="master"
S3_BUCKET_NAME="some-s3bucket-for-cloudformation-templates"
MAIN_HOSTED_ZONE_ID=""

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

# fourth parameter is full base subdomain
if [[ -z $4 ]]; then
    SUBDOMAIN="api.example.com"
else
    SUBDOMAIN=$4
fi

source ./use_colors.sh

REPLACE_TEMPLATES() {
    ECHO_GREEN "Replacing Templates"
    # upload CloudFormation templates to s3
    aws s3 sync ./templates s3://${S3_BUCKET_NAME} --delete
}

DEPLOY_NETWORK() {
    ECHO_GREEN "Deploying Network"
    # create a network for development or production
    aws cloudformation deploy \
        --stack-name network-${ENVIRONMENT} \
        --template-file templates/template-network.yml \
        --s3-bucket ${S3_BUCKET_NAME} \
        --s3-prefix deploy \
        --capabilities CAPABILITY_IAM \
        --no-fail-on-empty-changeset \
        --tags owner=${OWNER} \
        --parameter-overrides Environment=${ENVIRONMENT}

    # The Network-Stack creates a public Namespace to register public services for Service Discovery.
    # The following commands delegate the authority of that environment-based subdomain to the automatically created Hosted Zone
    ECHO_GREEN "Retrieving Hosted Zone"
    HOSTEDZONE=`aws route53 list-hosted-zones-by-name \
        --dns-name ${ENVIRONMENT}.${SUBDOMAIN} \
        --max-items 1 \
        --output json | jq -r '.HostedZones[0].Id'`
    echo "${HOSTEDZONE}"

    ECHO_GREEN "Checking for record-set existance"
    COUNT=`aws route53 list-resource-record-sets --output json \
        --hosted-zone-id "${MAIN_HOSTED_ZONE_ID}" \
        --query "ResourceRecordSets[?Name == '${ENVIRONMENT}.${SUBDOMAIN}']" \
        | jq -r '. | length'`

    if [ "${COUNT}" -eq "0" ]; then
        ECHO_GREEN "Creating New Record JSON structure"
        NEWRECORD=`aws route53 list-resource-record-sets --output json \
            --hosted-zone-id ${HOSTEDZONE} \
            --query "ResourceRecordSets[?Type == 'NS']" \
            | jq -r '.[0] | { Comment: "Delegating subdomain authority", Changes: [{ Action: "CREATE", ResourceRecordSet: { Name: .Name, Type: "NS", TTL: 86400, ResourceRecords: .ResourceRecords }}]}'`
        echo "${NEWRECORD}"

        ECHO_GREEN "Deploying New Record"
        aws route53 change-resource-record-sets \
            --hosted-zone-id "${MAIN_HOSTED_ZONE_ID}" \
            --change-batch "${NEWRECORD}"
    else
        ECHO_YELLOW "Record-set already exists. Skipping creation"
    fi
}

#########################
# Main body starts here #
#########################

REPLACE_TEMPLATES

DEPLOY_NETWORK