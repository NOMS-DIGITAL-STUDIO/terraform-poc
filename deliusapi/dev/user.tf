resource "aws_iam_user" "deployer" {
    name = "${var.app-name}-deployer"
}
resource "aws_iam_group_membership" "ci" {
    name = aws_iam_user.deployer.name
    users = [aws_iam_user.deployer.name]
    group = "ElasticbeanstalkDeployers"
}

resource "aws_iam_user_policy" "deployer" {
    name = "${var.app-name}-deployer"
    user = aws_iam_user.deployer.name
    # Based on https://gist.github.com/magnetikonline/5034bdbb049181a96ac9
    # and https://gist.github.com/jakubholynet/0055cf69b5b2a9554af67a11828209a5
    policy = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "elasticbeanstalk:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:elasticbeanstalk:*::solutionstack/*",
                "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:application/${aws_elastic_beanstalk_application.app.name}",
                "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:applicationversion/${aws_elastic_beanstalk_application.app.name}/*",
                "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:environment/${aws_elastic_beanstalk_application.app.name}/*",
                "arn:aws:elasticbeanstalk:${var.aws_region}:${var.aws_account_id}:template/${aws_elastic_beanstalk_application.app.name}/*"
            ]
        }
    ]
}
JSON
}

resource "aws_iam_access_key" "deployer" {
    user = aws_iam_user.deployer.name
}
