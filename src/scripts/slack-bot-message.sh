#!/usr/bin/env bash
#shellcheck disable=SC2086,SC2004
echo "DEBUG: dependent env vars"
echo "CHANNEL=$CHANNEL"
echo "MESSAGE=$MESSAGE"
echo "CUSTOM_MESSAGE=$CUSTOM_MESSAGE"
echo "INCLUDE_LINK=$INCLUDE_LINK"
echo "CIRCLE_BUILD_URL=$CIRCLE_BUILD_URL" 

if [[ "$CUSTOM_MESSAGE" != "" ]]; then
  json=$CUSTOM_MESSAGE
else
  if [[ ! $LINK ]]; then
      json=$(cat <<EOF
'{"channel": "$CHANNEL","blocks": [{"type": "section","text": {"type": "mrkdwn","text": "$MESSAGE"}}]}'
EOF
)
  else
      json=$(cat <<EOF
'{"channel": "$CHANNEL","blocks": [{"type": "section","text": {"type": "mrkdwn","text": "$MESSAGE"}},{"type": "divider"},{"type": "actions","elements": [{"type": "button","text": {"type": "plain_text","text": "go to pipeline","emoji": true},"value": "pipeline","url": "$CIRCLE_BUILD_URL"}]}]}
'
EOF
)
  fi
fi

curl -H "Content-type: application/json" \
      --data $json \
      -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
      -X POST https://slack.com/api/chat.postMessage
