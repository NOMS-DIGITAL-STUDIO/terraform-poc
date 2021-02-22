# Wrapper for obtaining security tokens on MFA enabled accounts.

# https://stackoverflow.com/a/28776166/173062
([[ -n $ZSH_EVAL_CONTEXT && $ZSH_EVAL_CONTEXT =~ :file$ ]] ||
 [[ -n $KSH_VERSION && $(cd "$(dirname -- "$0")" &&
    printf '%s' "${PWD%/}/")$(basename -- "$0") != "${.sh.file}" ]] ||
 [[ -n $BASH_VERSION && $0 != "$BASH_SOURCE" ]]) && sourced=1 || sourced=0

if [ "$sourced" = "0" ]; then
  echo "You probably meant to source this script"
  exit 1
fi

profile=$1

if [ -z $1 ]
  then
    profile=default
fi

echo "Using profile [$profile]"

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

mfa_devices=$(aws iam list-mfa-devices --profile $profile --output json)

if [ $? -ne 0 ]; then
  echo "Failed to find MFA device"
  return 1
fi


mfa_arn=$(echo $mfa_devices | jq -r '.MFADevices[0].SerialNumber')

echo -n "Enter MFA code: "
read mfa_code


json_result=$(aws sts get-session-token --serial-number $mfa_arn --token-code $mfa_code --profile $profile --output json)

if [ $? -eq 0 ]; then
    echo "Session token ok"
else
    echo "Couldn't get session token"
    return 1
fi

export AWS_ACCESS_KEY_ID=$(echo $json_result | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $json_result | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $json_result | jq -r '.Credentials.SessionToken')

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]
then
  echo "FAIL: Environment variables have not been set."
  return 1
else
  echo "Authentication successfully set"
fi
