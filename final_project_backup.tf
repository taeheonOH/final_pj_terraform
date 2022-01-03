resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "final-dlm-lifecycle-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name = "final-dlm-lifecycle-policy"
  role = aws_iam_role.dlm_lifecycle_role.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots",
            "ec2:DeleteSnapshot",
            "ec2:DescribeInstances",
            "ec2:DescribeVolumes",
            "ec2:DescribeSnapshots"
         ],
         "Resource": "*"
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateTags"
         ],
         "Resource": "arn:aws:ec2:*::snapshot/*"
      }
   ]
}
EOF
}

resource "aws_dlm_lifecycle_policy" "final-dlm-policy" {
  description        = "final DLM lifecycle policy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "DISABLED" #생성 또는 수정 직후 정책을 활성화할지 여부를 지정

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "oneday-snapshot"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["09:00"]
      }

      retain_rule {
        count = 1
      }
      tags_to_add = {
        SnapshotCreator = "DLM"
      }
      copy_tags = false
    }
    target_tags = {
      Name = "control"
    }
  }
}