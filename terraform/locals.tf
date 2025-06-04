# --------------------------------------------------------------
# COmmon tags
# --------------------------------------------------------------
locals {
  common_tags = {
    Purpose     = element(var.Purpose, 1)
    Environment = element(var.Environment, 1)
    Deployed-By = element(var.Deployed-by, 1)
  }

  autoscale_tags = merge(
    local.common_tags,
    {
      Name = "Quiva_App_Server"
    }
  )

}