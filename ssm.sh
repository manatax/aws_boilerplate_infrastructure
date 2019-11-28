#!/bin/sh

# exit when any command fails
set -e

if [[ -z $1 ]]; then
    ENVIRONMENT="development"
else
    ENVIRONMENT=$1
fi

# Use .env files to store the secrets
source ".env-$ENVIRONMENT"

SET_SSM_PARAM() {
    aws ssm put-parameter \
        --name "$1" \
        --description "$2" \
        --value "$3" \
        --type "SecureString" \
        --overwrite \
        --tier Standard
        # tags and overwrite can't be used together.
}

# Service Keys
SET_SSM_PARAM "/${ENVIRONMENT}/tokens/SOME_TOKEN" "Keys for enveloper to use on the services" "${SOME_TOKEN}"
SET_SSM_PARAM "/${ENVIRONMENT}/sslKey/Private" "sslKey Private" "${SSL_PRIVATE_KEY}"
SET_SSM_PARAM "/${ENVIRONMENT}/sslKey/Public" "sslKey Public" "${SSL_PUBLIC_KEY}"