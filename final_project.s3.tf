resource "aws_s3_bucket" "final001-bucket" {
    bucket = "final001-bucket"
}

resource "aws_s3_access_point" "final001" {
  bucket = "final001-bucket"
  name   = "final001"

  # VPC must be specified for S3 on Outposts
  vpc_configuration {
    vpc_id = aws_vpc.final-vpc.id
  }
}

resource "aws_s3_bucket_policy" "final001-bucket-policy" {
  bucket = aws_s3_bucket.final001-bucket.id

 #aws의 버킷정책 json부분
  policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::600734575887:root"
			},
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::final001-bucket/*"
		},
		{
			"Effect": "Allow",
			"Principal": {
				"Service": "delivery.logs.amazonaws.com"
			},
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::final001-bucket/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		},
		{
			"Effect": "Allow",
			"Principal": {
				"Service": "delivery.logs.amazonaws.com"
			},
			"Action": "s3:GetBucketAcl",
			"Resource": "arn:aws:s3:::final001-bucket"
		},
		{
			"Effect": "Allow",
			"Principal": {
				"Service": "logs.ap-northeast-2.amazonaws.com"
			},
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::final001-bucket/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		},
		{
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::600734575887:root"
			},
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::final001-bucket/ec2-logs/*",
			"Condition": {
				"StringEquals": {
					"s3:x-amz-acl": "bucket-owner-full-control"
				}
			}
		},
		{
			"Effect": "Allow",
			"Principal": {
				"Service": "logs.ap-northeast-2.amazonaws.com"
			},
			"Action": "s3:GetBucketAcl",
			"Resource": "arn:aws:s3:::final001-bucket"
		}
	]
}
)
} 

resource "aws_s3_bucket_public_access_block" "access_bucket" {
  bucket = "final001-bucket"

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}