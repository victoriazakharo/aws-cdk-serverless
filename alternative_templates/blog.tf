 variable "app_version" {
   default = "1.0.0"
 }
 
 variable "blog_layer_arn" {
   default = "arn:aws:lambda:us-east-1:312226949769:layer:BlogLayer:1"
 }
 
 variable "lambda_role_arn" {
   default = "arn:aws:iam::312226949769:role/IDTJawsLambdaFullAccessRole"
 }
 
 variable "lambda_s3_bucket" {
   default = "victoria-test"
 }
 
 variable "lambda_runtime" {
   default = "dotnetcore2.1"
 }
 
 variable "dotnet_shared_store" {
   default = "/opt/dotnetcore/store/"
 }
 
 provider "aws" {
   region = "us-east-1"
 }
 
 resource "aws_dynamodb_table" "blog-table" {
  name           = "BlogTable"
  read_capacity  = 3
  write_capacity = 3
  hash_key       = "Id"  
  attribute {
    name = "Id"
    type = "S"
  }
 }

 resource "aws_lambda_function" "get_blogs" {
   function_name = "GetBlogs"
   s3_bucket = var.lambda_s3_bucket
   s3_key    = "v${var.app_version}/GetBlogs.zip"
   handler = "GetBlogs::GetBlogs.Function::GetBlogs"
   runtime = var.lambda_runtime
   description = "Function to get blogs"
   memory_size = 256
   timeout = 30
   role = var.lambda_role_arn
   environment {
    variables = {
      DOTNET_SHARED_STORE = var.dotnet_shared_store
      BlogTable = aws_dynamodb_table.blog-table.name
    }
  }
  layers = [var.blog_layer_arn]
 }
 
 resource "aws_lambda_function" "add_blog" {
   function_name = "AddBlog"
   s3_bucket = var.lambda_s3_bucket
   s3_key    = "v${var.app_version}/AddBlog.zip"
   handler = "AddBlog::AddBlog.Function::AddBlog"
   runtime = var.lambda_runtime
   description = "Function to add a blog"
   memory_size = 256
   timeout = 30
   role = var.lambda_role_arn
   environment {
    variables = {
      DOTNET_SHARED_STORE = var.dotnet_shared_store
      BlogTable = aws_dynamodb_table.blog-table.name
    }
  }
  layers = [var.blog_layer_arn]
 }
 
 resource "aws_api_gateway_rest_api" "blog_api" {
  name        = "Blog Service Terraform"
 } 

 resource "aws_api_gateway_method" "proxy_post" {
   rest_api_id   = aws_api_gateway_rest_api.blog_api.id
   resource_id   = aws_api_gateway_rest_api.blog_api.root_resource_id
   http_method   = "POST"
   authorization = "NONE"
 } 
 
 resource "aws_api_gateway_integration" "lambda_post" {
   rest_api_id = aws_api_gateway_rest_api.blog_api.id
   resource_id = aws_api_gateway_method.proxy_post.resource_id
   http_method = aws_api_gateway_method.proxy_post.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.add_blog.invoke_arn
 }  
 
 resource "aws_api_gateway_method" "proxy_get" {
   rest_api_id   = aws_api_gateway_rest_api.blog_api.id
   resource_id   = aws_api_gateway_rest_api.blog_api.root_resource_id
   http_method   = "GET"
   authorization = "NONE"
 }
 
 resource "aws_api_gateway_integration" "lambda_get" {
   rest_api_id = aws_api_gateway_rest_api.blog_api.id
   resource_id = aws_api_gateway_method.proxy_get.resource_id
   http_method = aws_api_gateway_method.proxy_get.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.get_blogs.invoke_arn
 } 
 
 resource "aws_api_gateway_deployment" "blogs_api_deployment" {
   depends_on = [
     aws_api_gateway_integration.lambda_post,
     aws_api_gateway_integration.lambda_get
   ]

   rest_api_id = aws_api_gateway_rest_api.blog_api.id
   stage_name  = "prod"
 }
 
 resource "aws_lambda_permission" "apigw_get_blogs_permission" {
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.get_blogs.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn = "${aws_api_gateway_rest_api.blog_api.execution_arn}/${aws_api_gateway_deployment.blogs_api_deployment.stage_name}/GET/"
 }
 
 resource "aws_lambda_permission" "apigw_add_blog_permission" {
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.add_blog.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn = "${aws_api_gateway_rest_api.blog_api.execution_arn}/${aws_api_gateway_deployment.blogs_api_deployment.stage_name}/POST/"
 }
 
 resource "aws_lambda_permission" "apigw_get_blogs_permission_test_invoke" {
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.get_blogs.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn = "${aws_api_gateway_rest_api.blog_api.execution_arn}/test-invoke-stage/GET/"
 }
 
 resource "aws_lambda_permission" "apigw_add_blog_permission_test_invoke" {
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.add_blog.function_name
   principal     = "apigateway.amazonaws.com"
   source_arn = "${aws_api_gateway_rest_api.blog_api.execution_arn}/test-invoke-stage/POST/"
 }
 
 output "blogs_rest_api_endpoint" {
  value = aws_api_gateway_deployment.blogs_api_deployment.invoke_url
}