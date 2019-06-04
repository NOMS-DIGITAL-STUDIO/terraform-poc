#!/usr/bin/env bash

set -e

VERSION=$3
ENV=$2
APP=$1
DEVTEST_ACCOUNT_ID="429061350814"
PROD_ACCOUNT_ID="589133037702"
DEVTEST_S3_BUCKET="elasticbeanstalk-eu-west-2-${DEVTEST_ACCOUNT_ID}"
PROD_S3_BUCKET="elasticbeanstalk-eu-west-2-${PROD_ACCOUNT_ID}"
LOGGED_IN=$(aws sts get-caller-identity --output text --query 'Account')

display_usage() {
  echo -e "\nUsage: $0 [app] [dev|stage|preprod|prod] [version]\n"
}

check_app_exists() {
  aws elasticbeanstalk describe-applications --query Applications[*].[ApplicationName] --output text | grep -q "^${APP}$"
  return $?
}

check_for_existing_version() {
  aws elasticbeanstalk describe-application-versions --application-name ${APP} --query ApplicationVersions[*].[VersionLabel] --output text | grep -q "^${VERSION}$"
  return $?
}

deploy_to_devtest() {
  # Check logged in to correct account.
  [[ "${LOGGED_IN}" = "${DEVTEST_ACCOUNT_ID}" ]] || (echo "You are not logged into the devtest AWS account. Fail :(" && exit 1)

  # Check if app version already exists. If not, create app version json, upload to s3, and create eb app version.
  if !(check_for_existing_version); then
    # Build a deployment file
    generate_version_json ${APP} ${VERSION}
    echo $APP_VERSION_JSON | aws s3 cp - s3://${DEVTEST_S3_BUCKET}/${APP}/${VERSION}.json 
    aws elasticbeanstalk create-application-version --application-name="${APP}" --version-label="${VERSION}" --source-bundle="{\"S3Bucket\": \"${DEVTEST_S3_BUCKET}\",\"S3Key\": \"${APP}/${VERSION}.json\"}" --auto-create-application
  fi

  # Deploy app version to eb environment.
  aws elasticbeanstalk update-environment --environment-name $(generate_app_environment) --version-label ${VERSION}

}

# This function relies on being able to reach back into the devtest S3 bucket and copy the release artifact into
# the prod s3 bucket, the bucket access policy in devtest needed to be modified to allow read only access.
promote_to_preprod() {
  [[ "${LOGGED_IN}" = "${PROD_ACCOUNT_ID}" ]] || (echo "You are not logged into the prod AWS account. Fail :(" && exit 1)
  echo "Promoting release to preprod, .json or .zip app versions"
  aws s3 cp s3://${DEVTEST_S3_BUCKET}/${APP}/ s3://${PROD_S3_BUCKET}/${APP}/ --recursive --exclude "*" --include "${VERSION}.*"
  
  # Check if app version already exists, then create the eb app version if not.
  if !(check_for_existing_version); then
    aws elasticbeanstalk create-application-version --application-name="${APP}" --version-label="${VERSION}" --source-bundle="{\"S3Bucket\": \"${DEVTEST_S3_BUCKET}\",\"S3Key\": \"${APP}/${VERSION}.json\"}"
  fi

  # Deploy the app version to the preprod environment
  aws elasticbeanstalk update-environment --environment-name $(generate_app_environment) --version-label ${VERSION}

}

promote_to_prod() {
  [[ "${LOGGED_IN}" = "${PROD_ACCOUNT_ID}" ]] || (echo "You are not logged into the prod AWS account. Fail :(" && exit 1)
  echo "Promoting release to prod"
  if !(check_for_existing_version); then
    echo "No application version found, please make sure the this release has been successfully applied to preprod first."
    exit 1
  fi
  aws elasticbeanstalk update-environment --environment-name $(generate_app_environment) --version-label ${VERSION}
}

generate_version_json() {
  # This is a hack to cover the different container ports used by each
  # app we should standardise the port.
  containerport="3000"
  containerimage=$APP
  case "$APP" in
    ("notm") containerimage="new-nomis-ui" ;;
    ("keyworker-api") containerport="8080" ;;
    ("licences-pdf") containerport="8080" ;;
  esac

  APP_VERSION_JSON="
{
  \"AWSEBDockerrunVersion\": \"1\",
  \"Image\": {
    \"Name\": \"mojdigitalstudio/${containerimage}:${VERSION}\",
    \"Update\": \"true\"
  },
  \"Ports\": [
    {\"ContainerPort\": \"${containerport}\"}
  ]
}\"
"
 echo "Generated app version json:"
 echo $APP_VERSION_JSON
}

generate_app_environment() {
    if [[ ${APP} != "omic-ui" ]]; then
        echo "${APP}-${ENV}"
    else
        echo "omic-${ENV}"
    fi
}

# if less than three arguments supplied, display usage
if [  $# -le 2 ]
then
  display_usage
  exit 1
fi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $# == "--help") ||  $# == "-h" ]]
then
  display_usage
  exit 0
fi

if !(check_app_exists); then
  echo "No elasticbeanstalk application found with name: ${APP}"
  exit 1
fi

if [[ "$ENV" =~ ^(dev|stage)$ ]]; then
    echo "Deploying: APP=${APP}, ENV=${ENV}, VERSION=${VERSION}"
    deploy_to_devtest 
elif [[ "$ENV" =~ ^(preprod)$ ]]; then
    echo "Deploying: APP=${APP}, ENV=${ENV}, VERSION=${VERSION}"
    promote_to_preprod
elif [[ "$ENV" =~ ^(prod)$ ]]; then
    echo "Deploying: APP=${APP}, ENV=${ENV}, VERSION=${VERSION}"
    promote_to_prod
else
    echo "$ENV is not a valid environment"
fi

