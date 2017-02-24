variable "vol_name" {}
variable "vol_description" { default = ""}
variable "vol_size" {}
variable "vol_tags" {
	 type = "map"
}
variable "vol_type" {default = "san_high_perf"}

resource "openstack_blockstorage_volume_v2" "volume" {
	 name = "${var.vol_name}"
	 size = "${var.vol_size}"
	 volume_type = "${var.vol_type}"
	 metadata = "${var.vol_tags}"
}


output "vol_id" {
       value = "openstack_blockstorage_volume_v2.volume.id"
}