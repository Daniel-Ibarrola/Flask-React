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

update_service() {
  if [[ $(aws ecs update-service --cluster $cluster --service $service --task-definition $revision | $JQ '.service.taskDefinition') != $revision ]]; then
    echo "Error updating service."
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

# new
echo $CODEBUILD_WEBHOOK_BASE_REF
echo $CODEBUILD_WEBHOOK_HEAD_REF
echo $CODEBUILD_WEBHOOK_TRIGGER
echo $CODEBUILD_WEBHOOK_EVENT

# new
if  [ "$CODEBUILD_WEBHOOK_TRIGGER" == "branch/master" ] && \
    [ "$CODEBUILD_WEBHOOK_HEAD_REF" == "refs/heads/master" ]
then
  echo "Updating ECS."
  configure_aws_cli
  deploy_cluster
fi
