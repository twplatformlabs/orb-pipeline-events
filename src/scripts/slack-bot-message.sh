#!/usr/bin/env bash
#shellcheck disable=SC2086,SC2004
set -eo pipefail

echo "DEBUG: dependent env vars"
echo "CHANNEL=$CHANNEL"
echo "MESSAGE=$MESSAGE"
echo "CUSTOM_MESSAGE=$CUSTOM_MESSAGE"
echo "INCLUDE_LINK=$INCLUDE_LINK"
echo "CIRCLE_BUILD_URL=$CIRCLE_BUILD_URL"
echo "INCLUDE_TAG=$INCLUDE_TAG"

if [[ $INCLUDE_TAG == 0 ]]; then
  msg=$MESSAGE
else
  msg="$MESSAGE $CIRCLE_TAG"
fi

if [[ "$CUSTOM_MESSAGE" != "" ]]; then
  json=$CUSTOM_MESSAGE
else
  if [[ $INCLUDE_LINK == 0 ]]; then
      json=$(cat <<EOF
{"channel": "$CHANNEL","blocks":[{"type":"section","text":{"type":"mrkdwn","text":"$msg"}}]}
EOF
)
  else
      json=$(cat <<EOF
{"channel": "$CHANNEL","blocks": [{"type": "section","text": {"type": "mrkdwn","text": "$msg"}},{"type": "divider"},{"type": "actions","elements": [{"type": "button","text": {"type": "plain_text","text": "go to pipeline","emoji": true},"url": "$CIRCLE_BUILD_URL"}]}]}
EOF
)
  fi
fi
echo $json
curl -H "Content-type: application/json; charset=utf-8" \
      --data "$json" \
      -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
      -X POST https://slack.com/api/chat.postMessage
