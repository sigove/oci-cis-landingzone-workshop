terraform {
  required_version = ">= 1.2.0"

  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = ">= 4.80.0"
      configuration_aliases = [oci.home]
    }
  }
}

module "lz" {
  source = "../config"

  region                              = var.region
  tenancy_ocid                        = var.region
  existing_enclosing_compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaxjbavrkhob2ospypahsaoy6nvuwgnrqcspqjaoy2fgkzj7ne2gaa"
  env_advanced_options                = true
  policies_in_root_compartment        = "USE"
  vcn_cidrs                           = ["10.0.1.0/24", "10.0.2.0/24"]
  exacs_vcn_cidrs                     = []
  hub_spoke_architecture              = true
  hs_advanced_options                 = true
  dmz_vcn_cidr                        = "10.0.0.0/24"
  public_src_bastion_cidrs            = []
  public_src_lbr_cidrs                = []
  public_dst_cidrs                    = []
  network_admin_email_endpoints       = ["example@example.com"]
  security_admin_email_endpoints      = ["example@example.com"]
  enable_cloud_guard                  = false
  service_label                       = "seblz01"
}