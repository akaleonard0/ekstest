resource "aws_codecommit_repository" "html_app_repo" {
  repository_name = "html-app-repo"
  description     = "Repository for HTML app"
}
