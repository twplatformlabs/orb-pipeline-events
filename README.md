<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/twplatformlabs/static/master/psk_banner.png" width=800 />
	</p>
  <h1>orb-pipeline-events</h1>
  <h3>bundled set of common pipeline job and commands</h3>
  <a href="https://app.circleci.com/pipelines/github/twplatformlabs/orb-pipeline-events"><img src="https://circleci.com/gh/twplatformlabs/orb-pipeline-events.svg?style=shield"></a> <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</div>
<br />

See [orb registry](https://circleci.com/developer/orbs/orb/twdps/pipeline-events) for detailed usage examples

Available options include:

  **Commands**
  - bash-functions. Write shared bash functions to local file that can be sourced for use.
  - dog. Post events and deployments to datadog
  - gh-release-notes. Generate release notes using GitHub CLI.
  - gren. Generate release notes using github-release-notes npm tool.
  - install. Optionally installing dependent packages.
  - prune-dockerhub. delete specified tags from registry.
  - set-docker-credentials. Validate credentials via login attempt.
  - slack-bot. Post slack-bot message, with optional link back button and custom json override.
  - slack-webhook. Send message to slack via slack-webhook.
  - trigger. Define circleci Scheduled Pipeline.

  **jobs**
  - gh-release. Use GitHub CLI to automatically generate a release.
  - gren-release. Use github-release-notes to automatically generate a release.
  - scheduled-pipeline. Configure a trigger schedule for auomatic pipeline runs.
  - slack. Post slack-bot message.

NOTE: v5.x.x is a breaking change. Review documentation in detail before upgrading.
