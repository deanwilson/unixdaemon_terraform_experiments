
############ Admin users
####################################

resource "aws_iam_policy" "admin_policy" {
    name = "admin-policy"
    description = "Admin policy: full access"

    policy = "${file("projects/base_infrastructure/resources/files/full-admin-policy.json")}"
}

module "admins" {
    source = "github.com/deanwilson/tf_user_accounts"

    group_name     = "admin"
    group_iam_path = "/admin/"

    # and here we use the ARN from the policy we created above.
    policy_document_arn = "${aws_iam_policy.admin_policy.arn}"

    user_iam_path = "/admin-users/"
    user_names    = "${var.admin_users}"
}

############ Read only users
####################################

resource "aws_iam_policy" "read_only_policy" {
    name = "readonly-policy"
    description = "Read Only policy: viewing only"

    policy = "${file("projects/base_infrastructure/resources/files/read-only-policy.json")}"
}

module "readonly" {
    source = "github.com/deanwilson/tf_user_accounts"

    group_name     = "read-only"
    group_iam_path = "/read-only/"

    policy_document_arn = "${aws_iam_policy.read_only_policy.arn}"

    user_iam_path = "/read-only-users/"
    user_names    = "${var.read_only_users}"
}
