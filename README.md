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

Features include:

- install datadog cli
- post custom datadog event as a command in current job
- post custom datadog event as a separate job
- post standardized deploy event (useful as universal time-series overaly) as a command in current job
- Generate release notes using github-release-notes npm tool

curl --request PATCH \
  --url https://circleci.com/api/v2/schedule/%7Bschedule-id%7D \
  --header 'authorization: Basic REPLACE_BASIC_AUTH' \
  --header 'content-type: application/json' \
  --data '{"description":"string","name":"string","timetable":{"per-hour":0,"hours-of-day":[0],"days-of-week":["TUE"],"days-of-month":[0],"months":["MAR"]},"attribution-actor":"current","parameters":{"deploy_prod":true,"branch":"feature/design-new-api"}}'