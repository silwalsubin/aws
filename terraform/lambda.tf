resource "aws_lambda_function" "lambda" {
  function_name    = "my_lambda_function"
  role            = aws_iam_role.lambda_role.arn
  runtime         = "python3.9"
  handler         = "lambda_function.lambda_handler"
  filename        = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
  vpc_config {
    subnet_ids         = [aws_subnet.public_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}