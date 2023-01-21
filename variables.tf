variable "model" {
  description = "Model data."
  type        = any
}

variable "node_id" {
  description = "Node ID."
  type        = number
}

variable "dependencies" {
  description = "This variable can be used to express explicit dependencies between modules."
  type        = list(string)
  default     = []
}
