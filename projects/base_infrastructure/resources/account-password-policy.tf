
resource "aws_iam_account_password_policy" "basic" {
    minimum_password_length = 12
    require_lowercase_characters = true
    require_numbers = true
    require_symbols = true
    allow_users_to_change_password = true
}
