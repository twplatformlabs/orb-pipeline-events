#!/usr/bin/env bash
#shellcheck disable=SC2086,SC2004
set -eo pipefail

PROJECTAPI_URL="https://circleci.com/api/v2/project/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/schedule"
echo "$PROJECTAPI_URL"
EXISTING_SCHEDULED_PIPELINES=$(curl --request GET --url $PROJECTAPI_URL --header "Circle-Token: $CIRCLE_TOKEN")
echo "$EXISTING_SCHEDULED_PIPELINES"
NUM_SCHEDULED_PIPELINES=$(echo $EXISTING_SCHEDULED_PIPELINES | jq '.items | length')
echo "$NUM_SCHEDULED_PIPELINES"
SCHEDULED_PIPELINE_ID=""

JSON_BODY=$(cat <<EOF
{
    "name": "$SCHEDULED_PIPELINE_NAME",
    "timetable": {
        "per-hour": $PER_HOUR,
        "hours-of-day": $HOURS_OF_DAY,
        "days-of-week": $DAYS_OF_WEEK,
        "days-of-month": $DAYS_OF_MONTH,
        "months": $MONTHS
    },
    "attribution-actor": "$ATTRIBUTION_ACTOR",
    "parameters": $PIPELINE_PARAMETERS,
    "description": "$SCHEDULED_PIPELINE_DESCRIPTION"
}
EOF
)

echo "PROJECTAPI_URL=$PROJECTAPI_URL"
echo "NUM_SCHEDULED_PIPELINES=$NUM_SCHEDULED_PIPELINES"
echo "JSON_BODY=$JSON_BODY"

echo "Find scheduled pipeline id if schedule $SCHEDULED_PIPELINE_NAME already exists"
if [[ $NUM_SCHEDULED_PIPELINES -gt 0 ]]; then
    for (( schedule=0 ; schedule<$NUM_SCHEDULED_PIPELINES ; schedule++ )); do
        THIS_ID=$(echo $EXISTING_SCHEDULED_PIPELINES | jq -r --argjson SCHEDULE $schedule '.items[$SCHEDULE].name')
        if [[ "$THIS_ID" = "$SCHEDULED_PIPELINE_NAME" ]]; then
            SCHEDULED_PIPELINE_ID=$(echo $EXISTING_SCHEDULED_PIPELINES | jq -r --argjson SCHEDULE $schedule '.items[$SCHEDULE].id')
        fi
    done
fi

if [[ $SCHEDULED_PIPELINE_ID ]]; then
    echo "$SCHEDULED_PIPELINE_NAME exists ($SCHEDULED_PIPELINE_ID), patching for modified parameters"
    PROJECTAPI_URL="https://circleci.com/api/v2/schedule/$SCHEDULED_PIPELINE_ID"
    RESULT=$(curl --location --request PATCH $PROJECTAPI_URL \
                  --header 'Content-Type: application/json' \
                  --header "Circle-Token: $CIRCLE_TOKEN" \
                  --data "$JSON_BODY")
    ERROR_MESSAGE=$(echo $RESULT | jq '.message')
    if [[ $ERROR_MESSAGE != "null" ]]; then
        echo "Error: $ERROR_MESSAGE"
        exit 1
    fi
else
    echo "create new schedule"
    RESULT=$(curl --location $PROJECTAPI_URL \
         --header 'Content-Type: application/json' \
         --header "Circle-Token: $CIRCLE_TOKEN" \
         --data "$JSON_BODY")
    ERROR_MESSAGE=$(echo $RESULT | jq '.message')
    if [[ $ERROR_MESSAGE != "null" ]]; then
        echo "Error: $ERROR_MESSAGE"
        exit 1
    else
        echo $RESULT
    fi
fi
