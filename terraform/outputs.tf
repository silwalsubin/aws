output "lambda_function_name" {
  value = aws_lambda_function.lambda.function_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}