# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  cg_target_name = "${var.service_label}-cloud-guard-root-target"

  all_cloud_guard_target_defined_tags = null
  all_cloud_guard_target_freeform_tags = null

  #### DON'T THOUCH THE LINES BELOW ####
  default_cloud_guard_target_defined_tags = null
  default_cloud_guard_target_freeform_tags = local.landing_zone_tags
  
  cloud_guard_target_defined_tags = local.all_cloud_guard_target_defined_tags != null ? merge(local.all_cloud_guard_target_defined_tags, local.default_cloud_guard_target_defined_tags)  : local.default_cloud_guard_target_defined_tags
  cloud_guard_target_freeform_tags = local.all_cloud_guard_target_freeform_tags != null ? merge(local.all_cloud_guard_target_freeform_tags, local.default_cloud_guard_target_freeform_tags) : local.default_cloud_guard_target_freeform_tags

}

/* module "lz_cloud_guard" {
  count                 = var.cloud_guard_configuration_status ? 1 : 0
  depends_on            = [null_resource.wait_on_services_policy]
  source                = "../modules/monitoring/cloud-guard"
  providers             = { oci = oci.home }
  compartment_id        = var.tenancy_ocid
  reporting_region      = var.cloud_guard_reporting_region != null ? var.cloud_guard_reporting_region : local.regions_map[local.home_region_key]
  enable_cloud_guard    = var.cloud_guard_configuration_status
  self_manage_resources = false
  target_id             = var.tenancy_ocid
  target_name           = local.cg_target_name
  defined_tags          = local.cloud_guard_target_defined_tags
  freeform_tags         = local.cloud_guard_target_freeform_tags
} */

module "lz_cloud_guard" {
  count                 = var.cloud_guard_configuration_status ? 1 : 0
  depends_on            = [null_resource.wait_on_services_policy]
  source                = "github.com/andrecorreaneto/terraform-oci-cis-landing-zone-cloud-guard"
  providers             = { oci = oci.home }
  tenancy_id            = var.tenancy_ocid
  compartment_id        = var.tenancy_ocid
  target_resource_id    = var.tenancy_ocid
  reporting_region      = var.cloud_guard_reporting_region != null ? var.cloud_guard_reporting_region : local.regions_map[local.home_region_key]
  enable_cloud_guard    = var.cloud_guard_configuration_status
  name_prefix           = var.service_label
  defined_tags          = local.cloud_guard_target_defined_tags
  freeform_tags         = local.cloud_guard_target_freeform_tags
}