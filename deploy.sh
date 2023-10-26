#!/bin/sh

JQ="jq --raw-output --exit-status"

configure_aws_cli() {
  aws --version
  aws configure set default.region us-east-2
  aws configure set default.output json
  echo "AWS Configured!"
}

register_definition() {
  if revision=$(aws ecs register-task-definition --cli-input-json "$task_def" | $JQ '.taskDefinition.taskDefinitionArn'); then
    echo "Revision: $revision"
  else
    echo "Failed to register task definition"
    return 1
  fi
}

deploy_cluster() {

  # users
  template="ecs_users_taskdefinition.json"
  task_template=$(cat "ecs/$template")
  task_def=$(printf "$task_template" $PRODUCTION_SECRET_KEY $AWS_RDS_URI)
  echo "$task_def"
  register_definition

  # client
  template="ecs_client_taskdefinition.json"
  task_template=$(cat "ecs/$template")
  task_def=$(printf "$task_template")
  echo "$task_def"
  register_definition

}

configure_aws_cli
deploy_cluster