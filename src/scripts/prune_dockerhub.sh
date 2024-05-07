#!/usr/bin/env bash
set -eo pipefail

echo "get bearer token from dtr using login and password"
curl -s -H "Content-Type: application/json" -X POST \
        -d "{\"username\": \"${DOCKER_LOGIN}\", \"password\": \"${DOCKER_PASSWORD}\"}" \
        https://hub.docker.com/v2/users/login/ | jq -r .token > token.jwt


echo "get all tags from specified image repository"
TOKEN=$(cat token.jwt)
PAGE="https://hub.docker.com/v2/repositories/${REPOSITORY}/tags/"
while [[ "$PAGE" != null ]]; do
    curl ${PAGE} \
        -X GET \
        -H "Authorization: JWT ${TOKEN}" \
        > page_images.json
    cat page_images.json >> all_images.json
    PAGE=$(cat page_images.json | jq -r '.next')
done

echo "search image list for desired tags"
cat all_images.json | jq -r '.results | .[] | select(.name | contains ("${TAG_FILTER}")) | .name' > dev_tags

echo "delete results of image search"
TOKEN=$(cat token.jwt)
while read TAG; do
    curl "https://hub.docker.com/v2/repositories/${REPOSITORY}/tags/${TAG}/" \
            -X DELETE \
            -H "Authorization: JWT ${TOKEN}"
done < dev_tags
