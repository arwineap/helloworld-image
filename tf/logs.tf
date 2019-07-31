resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/app"
  retention_in_days = 30

  tags = {
    Name = "ecs-logs"
  }
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "log-stream"
  log_group_name = "${aws_cloudwatch_log_group.log_group.name}"
}
