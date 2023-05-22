<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/thoughtworks_flamingo_wave.png?sanitize=true" width=200 />
    <br />
		<img alt="DPS Title" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/dps_lab_title.png" width=350/>
	</p>
  <h3>orb-pipeline-events</h3>
  <h5>bundled set of common pipeline job and commands</h5>
  <a href="https://app.circleci.com/pipelines/github/ThoughtWorks-DPS/orb-pipeline-events"><img src="https://circleci.com/gh/ThoughtWorks-DPS/orb-pipeline-events.svg?style=shield"></a> <a href="https://badges.circleci.com/orbs/twdps/pipeline-events.svg"><img src="https://badges.circleci.com/orbs/twdps/pipeline-events.svg"></a> <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</div>
<br />

See [orb registry](https://circleci.com/developer/orbs/orb/twdps/pipeline-events) for detailed usage examples

  Available options include:

  **Commands**
  - dd-credentials. Setup datadog credential file  .
  - dd-deploy. Send opinionated deploy event to datadog; for use in marking deployments on time-series widgets.  
  - dd-install. Install datadog cli and (optionally) python3.
  - dd-event. Send fully customizable event to datadog.  
  - prune-dockerhub. delete specified tags from registry.
  - release. Create github release with notes using github-release-notes npm tool. 
  - trigger. Define circleci Scheduled Pipeline .
  - slack-webhook. Send message to slack via slack-webhook.
  - validate-docker-credentials. Validate credentials via login attempt.

  **jobs**
  - release. Use github-release-notes to automatically generate a release.
  - scheduled-pipeline. Configure a trigger schedule for auomatic pipeline runs.
