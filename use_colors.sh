ECHO_GREEN() {
    GREEN='\033[1;32m'
    NO_COLOR='\033[0m'
    echo "${GREEN}${1}${NO_COLOR}"
}

ECHO_YELLOW() {
    YELLOW='\033[1;33m'
    NO_COLOR='\033[0m'
    echo "${YELLOW}${1}${NO_COLOR}"
}

ECHO_RED() {
    RED='\033[1;31m'
    NO_COLOR='\033[0m'
    echo "${RED}${1}${NO_COLOR}"
}
