#!/bin/sh

set -e

port_client_id="$INPUT_PORTCLIENTID"
port_client_secret="$INPUT_PORTCLIENTSECRET"
port_run_id="$INPUT_PORTRUNID"
github_token="$INPUT_TOKEN"
blueprint_identifier="$INPUT_BLUEPRINTIDENTIFIER"
repository_name="$INPUT_REPOSITORYNAME"
org_name="$INPUT_ORGANIZATIONNAME"
cookie_cutter_template="$INPUT_COOKIECUTTERTEMPLATE"
port_user_inputs="$INPUT_PORTUSERINPUTS"

access_token=$(curl -s --location --request POST 'https://api.getport.io/v1/auth/access_token' --header 'Content-Type: application/json' --data-raw "{
    \"clientId\": \"$port_client_id\",
    \"clientSecret\": \"$port_client_secret\"
}" | jq -r '.accessToken')

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Creating a new repository: $repository_name 🏃\"
  }"

# Create a new repostiory in github
curl -i -H "Authorization: token $github_token" \
     -d "{ \
        \"name\": \"$repository_name\", \"private\": true
      }" \
    https://api.github.com/orgs/$org_name/repos

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Created a new repository at https://github.com/$org_name/$repository_name 🚀\"
  }"

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Starting templating with cookiecutter 🍪\"
  }"

echo "$port_user_inputs" | grep -o "cookiecutter[^ ]*" | sed 's/cookiecutter//g' >> cookiecutter.json

cookiecutter $cookie_cutter_template --no-input

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Pushing the template into the repository ⬆️\"
  }"

cd "$(ls -td -- */ | head -n 1)"

git config user.name "GitHub Actions Bot"
git config user.email "github-actions[bot]@users.noreply.github.com"
git init
git add .
git commit -m "Initial commit after scaffolding"
git branch -M main
git remote add origin https://oauth2:$github_token@github.com/$org_name/$repository_name.git
git push -u origin main


curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Reporting to Port the new entity created https://github.com/$org_name/$repository_name 🚢\"
  }" 

curl --location "https://api.getport.io/v1/blueprints/$blueprint_identifier/entities?run_id=$port_run_id" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"identifier\": \"$repository_name\",
    \"title\": \"$repository_name\",
    \"properties\": {}
  }"

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --header "User-Agent: github-action/v1.0" \
  --data "{
    \"message\": \"Finshed! visit https://github.com/$org_name/$repository_name 🏁✅\"
  }"