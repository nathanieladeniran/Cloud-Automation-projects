# --------------------------------------------------------------
# COmmon tags
# --------------------------------------------------------------
locals {
  common_tags = {
    Purpose     = var.Purpose
    Environment = var.Environment
    Deployed-By = var.Deployed-by
  }

  autoscale_tags = merge(
    local.common_tags,
    {
      Name = "Quiva_App_Server"
    }
  )

}