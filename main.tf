resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

resource "aws_route53_record" "ses_verification_record" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.this.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.this.verification_token]
}

resource "aws_route53_record" "mx" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.this.name}.amazonaws.com"]
}

resource "aws_ses_domain_identity_verification" "this" {
  domain = aws_ses_domain_identity.this.id

  depends_on = [aws_route53_record.ses_verification_record]
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "ses_dkim_record" {
  count = 3

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_ses_receipt_rule_set" "this" {
  rule_set_name = "email-auto-reply-rules"
}

resource "aws_ses_active_receipt_rule_set" "this" {
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
}

resource "aws_ses_receipt_rule" "this" {
  name          = "email-auto-reply"
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
  recipients    = var.recipients
  enabled       = true
  scan_enabled  = var.scan_enabled

  lambda_action {
    function_arn    = aws_lambda_function.this.arn
    invocation_type = "Event"
    position        = 1
  }
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_function.output_path
  function_name    = "email-auto-reply-function"
  role             = aws_iam_role.lambda.arn
  handler          = "main.handler"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  timeout = 30
  runtime = "nodejs14.x"

  environment {
    variables = {
      REPLY_FROM = var.reply_from
    }
  }
}

resource "aws_lambda_permission" "ses" {
  statement_id  = "AllowSESToInvokeLambdaFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "ses.amazonaws.com"
}

resource "aws_iam_role" "lambda" {
  name = "email-auto-reply-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda" {
  name = "email-auto-reply-lambda-policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SESAccess",
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail"
      ],
      "Resource": [
        aws_ses_domain_identity.this.arn
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}
