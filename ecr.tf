resource "aws_ecr_repository" "html_app" {
  name = "html-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
