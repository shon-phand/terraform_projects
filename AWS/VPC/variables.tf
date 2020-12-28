variable "public-sn" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private-sn" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}