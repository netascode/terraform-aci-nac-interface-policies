output "critical_resources_done" {
  description = "This dummy output can be used to express dependencies between NaC modules using the `dependencies` variable."
  value       = null_resource.critical_resources_done.id != null ? "done" : "done"
}
