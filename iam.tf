resource "aws_iam_user" "codecommit_user" {
  name = "codecommit-user"
}

resource "aws_iam_user_policy_attachment" "codecommit_user_policy" {
  user       = aws_iam_user.codecommit_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitPowerUser"
}

resource "aws_iam_access_key" "codecommit_user_key" {
  user = aws_iam_user.codecommit_user.name
}

output "codecommit_user_access_key_id" {
  description = "Access key ID for CodeCommit user"
  value       = aws_iam_access_key.codecommit_user_key.id
}

output "codecommit_user_secret_access_key" {
  description = "Secret access key for CodeCommit user"
  value       = aws_iam_access_key.codecommit_user_key.secret
  sensitive   = true
}

resource "aws_iam_user_login_profile" "codecommit_user_password" {
  user = aws_iam_user.codecommit_user.name
  password_reset_required = false
}

output "codecommit_user_login_profile" {
  description = "Login profile for CodeCommit user"
  value       = aws_iam_user_login_profile.codecommit_user_password.encrypted_password
  sensitive   = true
}
