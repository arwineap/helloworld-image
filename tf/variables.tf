variable "app_image" {
  description = "The image of the docker container to run"
  default     = "arwineap/helloworld-image:latest"
}

variable "app_port" {
  description = "The port that the app will run on"
  default     = 5000
}

variable "app_count" {
  description = "Number of containers to run"
  default     = 3
}

variable "fargate_cpu" {
  description = "In 'CPU Units', 1024 = 1 vCPU; for valid cpu/mem combos see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html"
  default     = 256
}

variable "fargate_memory" {
  description = "In megabytes; for valid cpu/mem combos see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html"
  default     = 512
}

variable "cidr" {
    description = "CIDR for aws infrastructure"
    default = "10.100.0.0/16"
}

variable "availability_zones" {
  default = ["us-east-1c", "us-east-1d", "us-east-1e"]
}
