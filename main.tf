#---------------------------------------------------------------------------------------------------------------------
#  VMware RESOURCES
# --------------------------------------------------------------------------------------------------------------------

provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  allow_unverified_ssl = true

}
resource "vsphere_virtual_machine" "linux-vm" {
  count = 1
  name  = "${var.name}-${random_uuid.test.result}"

  resource_pool_id = "${data.vsphere_compute_cluster.compute_cluster.resource_pool_id}"
  folder           = "${vsphere_folder.folder.path}"
  
  num_cpus = "${var.cpu_number}" 
  memory   = "${var.ram_size}"
  guest_id  = "ubuntu64Guest"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
  network_interface {
    network_id = "${data.vsphere_network.network.id}"

  }

  disk {
    label            = "disk1"
    size             = "${var.data_disk_size_gb}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.name}"
        domain    = "${var.vmdomain}"
      }

      network_interface {
        ipv4_address = "${element(var.ipaddress, 0)}"
        ipv4_netmask = "${var.ipv4submask}"
      }
      
      dns_server_list = "${var.vmdns}"
      ipv4_gateway    = "${var.vmgateway}"
    }
  }
  //custom_attributes = "${map(vsphere_custom_attribute.attribute.id, "${var.attributeValue}")}"
}

// Create Folder
resource "vsphere_folder" "folder" {
  path          = "${var.name}-${random_uuid.test.result}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
  //tags          = ["${vsphere_tag.tag.id}"]

  //custom_attributes = "${map(vsphere_custom_attribute.attribute.id, "${var.attributeValue}")}"
}

data "vsphere_datacenter" "dc" {
  name = "${var.dc}"
}
// Datastore
data "vsphere_datastore" "datastore" {
  name          = "${var.datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

// The cluster's id (When you are not deploying to a resource pool or it doesn't exist)
data "vsphere_compute_cluster" "compute_cluster" {
  name          = "${var.cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}


// The vSPhere network being used.
data "vsphere_network" "network" {
  name          = "${var.vnet}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

// The name of the VM Template to use for deployment in a specific datacenter.
data "vsphere_virtual_machine" "template" {
  name          = "${var.vmtemplate}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

#---------------------------------------------------------------------------------------------------------------------
#  RANDOM IDENTIFIER RESOURCES
# --------------------------------------------------------------------------------------------------------------------

### Create Random ID for Identification
resource "random_uuid" "test" {}
