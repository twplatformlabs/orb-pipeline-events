<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/thoughtworks_flamingo_wave.png?sanitize=true" width=200 />
    <br />
		<img alt="DPS Title" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/EMPCPlatformStarterKitsImage.png" width=350/>
	</p>
  <h3>orb-pipeline-events</h3>
  <h5>bundled set of common pipeline job and commands</h5>
  <a href="https://app.circleci.com/pipelines/github/ThoughtWorks-DPS/orb-pipeline-events"><img src="https://circleci.com/gh/ThoughtWorks-DPS/orb-pipeline-events.svg?style=shield"></a> <a href="https://badges.circleci.com/orbs/twdps/pipeline-events.svg"><img src="https://badges.circleci.com/orbs/twdps/pipeline-events.svg"></a> <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</div>
<br />

See [orb registry](https://circleci.com/developer/orbs/orb/twdps/pipeline-events) for detailed usage examples

Available options include:

  **Commands**
  - install. Manage installing dependent packages.
  - set-docker-credentials. Validate credentials via login attempt.
  - release. Create github release with notes using github-release-notes npm tool.
  - slack-bot. Post slack-bot message, with optional link back button and custom json override.
  - slack-webhook. Send message to slack via slack-webhook.
  - prune-dockerhub. delete specified tags from registry.
  - dog. Post events and deployments to datadog
  - trigger. Define circleci Scheduled Pipeline.

  **jobs**
  - release. Use github-release-notes to automatically generate a release.
  - scheduled-pipeline. Configure a trigger schedule for auomatic pipeline runs.
  - slack. Post slack-bot message.

NOTE: v4.x.x is a breaking change. Review documentation in detail before upgrading.