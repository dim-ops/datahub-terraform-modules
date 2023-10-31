locals {
  datahub = {
    url       = "https://<your-company>.acryl.io/gms"
    queue_url = "https://sqs.us-east-1.amazonaws.com/111111111111/xxx"
    queue_arn = "arn:aws:sqs:us-east-1:11111111111:xxx"
  }
}

module "example" {
  source = "../"

  cluster_name = "remote-ingestion-executor-example"

  create_tasks_iam_role = true
  tasks_iam_role_policies = {
    SQS_Policy = aws_iam_policy.sqs-policy.arn
  }

  create_task_exec_iam_role = true
  task_exec_secret_arns = [
    aws_secretsmanager_secret.datahub_access_token.arn,
  ]

  datahub = local.datahub

  secrets = [
    {
      name      = "DATAHUB_ACCESS_TOKEN"
      valueFrom = aws_secretsmanager_secret.datahub_access_token.arn
    },
  ]

  subnet_ids = ["subnet-XXX"]

  assign_public_ip = true

  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    },
  }
}

resource "aws_secretsmanager_secret" "datahub_access_token" {
  name = "datahub_access_token"
}

resource "aws_secretsmanager_secret_version" "service_user" {
  secret_id     = aws_secretsmanager_secret.datahub_access_token.id
  secret_string = "XXX"
}

resource "aws_iam_policy" "sqs-policy" {
  name   = "remote-ingestion-executor-example-sqs"
  path   = "/"
  policy = data.aws_iam_policy_document.sqs-policy-document.json
}

data "aws_iam_policy_document" "sqs-policy-document" {
  statement {
    sid = "Allow"

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueUrl",
    ]

    resources = [
      local.datahub.queue_arn,
    ]
  }
}
