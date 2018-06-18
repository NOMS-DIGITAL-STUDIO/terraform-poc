variable "newnomis-apps" {
  default = [
    "arn:aws:elasticbeanstalk:eu-west-2:589133037702:application/keyworker-api",
    "arn:aws:elasticbeanstalk:eu-west-2:589133037702:application/omic-ui",
    "arn:aws:elasticbeanstalk:eu-west-2:589133037702:applicationversion/keyworker-api/*",
    "arn:aws:elasticbeanstalk:eu-west-2:589133037702:applicationversion/omic-ui/*",
    "arn:aws:elasticbeanstalk:eu-west-2:589133037702:configurationtemplate/keyworker-api/*",
    "arn:aws:elasticbeanstalk:eu-west-2:589133037702:configurationtemplate/omic-ui/*",
    "arn:aws:elasticbeanstalk:eu-west-2:589133037702:environment/keyworker-api/*",
    "arn:aws:elasticbeanstalk:eu-west-2:589133037702:environment/omic-ui/*"
  ]
}

locals {
  newnomis_apps_list = "${join("\",\"",var.newnomis-apps)}"
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = false
  allow_users_to_change_password = true
}

resource "aws_iam_group" "webops" {
  name = "WebOps"
}

resource "aws_iam_group" "newnomis-developers" {
  name = "NewNOMIS-Devs"
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query {
    vault                     = "${var.vault-name}"
    users-webops              = "webops"
    users-newnomis-developers = "newnomis-developers"
  }
}

locals {
  aws_users_webops              = "${compact(split(",",data.external.vault.result.users-webops))}"
  aws_users_newnomis_developers = "${compact(split(",",data.external.vault.result.users-newnomis-developers))}"

  all_users = "${concat(local.aws_users_webops,local.aws_users_newnomis_developers)}"
}

resource "aws_iam_user" "user" {
  count = "${length(local.all_users)}"
  name  = "${element(local.all_users, count.index)}"

  provisioner "local-exec" {
    interpreter = ["bash", "-e", "-c"]

    command = <<SHELL
    password=$(pwgen 20 1)
    echo Initial Password: "$password"
    aws iam create-login-profile \
      --user-name "${element(local.all_users, count.index)}" \
      --password "$password" \
      --password-reset-required
SHELL
  }

  # For deletion first use
  # aws iam delete-login-profile --user-name XXXX
}

resource "aws_iam_group_membership" "webops_group_membership" {
  name  = "webops-group-membership"
  users = ["${local.aws_users_webops}"]
  group = "${aws_iam_group.webops.name}"
}

resource "aws_iam_group_membership" "newnomis_developers_group_membership" {
  name  = "newnomis-developers-group-membership"
  users = ["${local.aws_users_newnomis_developers}"]
  group = "${aws_iam_group.newnomis-developers.name}"
}

data "template_file" "enable_mfa_policy" {
  template = "${file("../policies/enable-mfa-policy.json")}"

  vars {
    aws_account_id = "${var.aws_account_id}"
  }
}

data "template_file" "devs-elasticbeanstalk-deploy-policy" {
  template = "${file("../policies/devs-elasticbeanstalk-deploy-policy.json")}"

  vars {
    aws_account_id       = "${var.aws_account_id}"
    aws_application_name = "${local.newnomis_apps_list}"
  }
}

resource "aws_iam_policy" "enable-mfa" {
  name        = "enable-mfa"
  description = "Enable MFA on user accounts"
  policy      = "${data.template_file.enable_mfa_policy.rendered}"
}

resource "aws_iam_policy" "devs-elasticbeanstalk-deploy" {
  name        = "devs-elasticbeanstalk-deploy"
  description = "Allow devs to deploy Elasticbeanstalk apps"
  policy      = "${data.template_file.devs-elasticbeanstalk-deploy-policy.rendered}"
}

resource "aws_iam_group_policy_attachment" "webops-attach-enable-mfa" {
  group      = "${aws_iam_group.webops.name}"
  policy_arn = "${aws_iam_policy.enable-mfa.arn}"
}

resource "aws_iam_group_policy_attachment" "newnomis-developers-attach-enable-mfa" {
  group      = "${aws_iam_group.newnomis-developers.name}"
  policy_arn = "${aws_iam_policy.enable-mfa.arn}"
}

resource "aws_iam_group_policy_attachment" "devs-elasticbeanstalk-deploy" {
  group      = "${aws_iam_group.newnomis-developers.name}"
  policy_arn = "${aws_iam_policy.devs-elasticbeanstalk-deploy.arn}"
}

resource "aws_iam_group_policy_attachment" "webops-attach-iam-password-change" {
  group      = "${aws_iam_group.webops.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_group_policy_attachment" "developers-attach-iam-password-change" {
  group      = "${aws_iam_group.newnomis-developers.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_group_policy_attachment" "webops-attach-administrator-access" {
  group      = "${aws_iam_group.webops.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
