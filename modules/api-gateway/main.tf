resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api"
  description = "API Gateway para ${var.project_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "services" {
  for_each = var.services

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_resource" "services_proxy" {
  for_each = var.services

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.services[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "services_proxy" {
  for_each = var.services

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.services_proxy[each.key].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "services_proxy" {
  for_each = var.services

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.services_proxy[each.key].id
  http_method             = aws_api_gateway_method.services_proxy[each.key].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.alb_dns_name}/${each.key}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  timeout_milliseconds = 29000
}

resource "aws_api_gateway_method" "services_root" {
  for_each = var.services

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.services[each.key].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "services_root" {
  for_each = var.services

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.services[each.key].id
  http_method             = aws_api_gateway_method.services_root[each.key].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.alb_dns_name}/${each.key}"

  timeout_milliseconds = 29000
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.main.body,
      aws_api_gateway_resource.services,
      aws_api_gateway_resource.services_proxy,
      aws_api_gateway_method.services_proxy,
      aws_api_gateway_integration.services_proxy,
      aws_api_gateway_method.services_root,
      aws_api_gateway_integration.services_root,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.services_proxy,
    aws_api_gateway_integration.services_root,
  ]
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }

  xray_tracing_enabled = var.enable_xray_tracing

  tags = var.tags
}

resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = var.logging_level
    data_trace_enabled     = var.enable_data_trace
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}

resource "aws_api_gateway_gateway_response" "cors" {
  for_each = toset(["DEFAULT_4XX", "DEFAULT_5XX"])

  rest_api_id   = aws_api_gateway_rest_api.main.id
  response_type = each.key

  response_parameters = var.enable_cors ? {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'*'"
  } : {}
}
