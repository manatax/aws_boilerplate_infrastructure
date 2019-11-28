#!/bin/sh

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

# fourth parameter is full base subdomain
if [[ -z $2 ]]; then
    SUBDOMAIN="api.example.com."
else
    SUBDOMAIN=$2
fi

source ./use_colors.sh

DELETE_STACK() {
    ECHO_GREEN "Pre-Deleting Route53 Authority Delegation for Public Namespace"

    ECHO_GREEN "Creating Record JSON structure"
    RECORD=`aws route53 list-resource-record-sets --output json \
        --hosted-zone-id ${MAIN_HOSTED_ZONE_ID} \
        --query "ResourceRecordSets[?Type == 'NS' && Name == '${ENVIRONMENT}.${SUBDOMAIN}']" \
        | jq -r '.[0] | { Comment: "Removing delegation of subdomain authority", Changes: [{ Action: "DELETE", ResourceRecordSet: { Name: .Name, Type: "NS", TTL: 86400, ResourceRecords: .ResourceRecords }}]}'`

    aws route53 change-resource-record-sets \
        --hosted-zone-id ${MAIN_HOSTED_ZONE_ID} \
        --change-batch "${RECORD}"

    ECHO_GREEN "Deleting Stack"
    aws cloudformation delete-stack \
        --stack-name network-${ENVIRONMENT}
}

#########################
# Main body starts here #
#########################
MAIN_HOSTED_ZONE_ID="Z1UTU3FZOG2E1N"
DELETE_STACK
