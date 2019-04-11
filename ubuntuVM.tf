## 1. Generate the token to connect to OpenStack
## curl -X POST http://192.168.64.12:5000/v2.0/tokens -d '{"auth":{"passwordCredentials":{"username":"jjcanada", "password":"PASSWORD"}, "tenantId":"7cbf04cede6d4919991b8bb3b3afa0c0"}}' -H 'Content-type: application/json' > token.json
variable "user_name" {default = "jjcanada"}

## 2. Abrir el archivo token.json generado en la operación curl y copiar el token de acceso

variable "my_token" {
  default = "PASTE_YOUR_TOKEN_HERE"  
}

variable "project_name" {
  default = "jjcanada"     ## Nombre del proyecto en OpenStack / provider tenant_name
}
variable "project_network" {
  default = "jcanada-net"  ## Nombre de la rede en Opentstack / network name
}



# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "${var.user_name}"
  tenant_name = "${var.project_name}"
  token 	  = "${var.my_token}"
  auth_url    = "http://192.168.64.12:5000/v3/"
  region      = "RegionOne"
}


resource "tls_private_key" "deployAnsible" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "openstack"

########################################
# Crear la Virtual Machine
########################################

resource "openstack_compute_instance_v2" "mi_tf_instance" {
  name      = "ub18vm-cnsa"
  availability_zone = "nova"
  image_id  = "9eabea01-c377-4911-9ee0-7276ae4ca820"    ## Ubuntu 18
  flavor_name = "medium"
  key_pair  = "${var.user_name}"
  security_groups = ["default"]
  
  network {
    name = "${var.project_network}"
  }

}

# Crear una IP de mi pool ext-net

resource "openstack_networking_floatingip_v2" "myip" {
  pool = "ext-net"
}

# Asociar la IP
resource "openstack_compute_floatingip_associate_v2" "myip" {
  floating_ip = "${openstack_networking_floatingip_v2.myip.address}"
  instance_id = "${openstack_compute_instance_v2.mi_tf_instance.id}"
}

########################################
# Crear la Virtual Machine: node1
########################################

resource "openstack_compute_instance_v2" "mi_tf_node1" {
  name      = "ub18node1-cnsa"
  availability_zone = "nova"
  image_id  = "9eabea01-c377-4911-9ee0-7276ae4ca820"    ## Ubuntu 18
  flavor_name = "medium"
  key_pair  = "${var.user_name}"  ## comprobar el nombre el Key Pair en OpenStack y cambiar si es necesario
  security_groups = ["default"]
  
  network {
    name = "${var.project_network}"
  }

}

# Crear una IP de mi pool ext-net

resource "openstack_networking_floatingip_v2" "myipnode1" {
  pool = "ext-net"
}

# Asociar la IP
resource "openstack_compute_floatingip_associate_v2" "myipnode1" {
  floating_ip = "${openstack_networking_floatingip_v2.myipnode1.address}"
  instance_id = "${openstack_compute_instance_v2.mi_tf_node1.id}"

   provisioner "file" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key  = "${file("c:/users/joaquin/.ssh/id_rsa")}"
      host = "${azurerm_public_ip.myterraformpublicip.address}"
    }

    source      = "c:/DDatos msi/ansible/ansible_ssh_keypair/id_rsa.pub"
    destination = "/home/ubuntu/.ssh/id_rsa_ansible.pub"
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key  = "${file("c:/users/joaquin/.ssh/id_rsa")}"
      host = "${openstack_networking_floatingip_v2.myipnode1.address}"
    }
    inline = [
       "sudo apt-get update -y",
       "sudo apt-get upgrade -y",
       "sudo apt-get install -y python-minimal",
       "sudo reboot -h now"       
      ]
    on_failure = "continue"
  }
}

########################################
# Crear la Virtual Machine: node2
########################################

resource "openstack_compute_instance_v2" "mi_tf_node2" {
  name      = "ub18node2-cnsa"
  availability_zone = "nova"
  image_id  = "9eabea01-c377-4911-9ee0-7276ae4ca820"    ## Ubuntu 18
  flavor_name = "medium"
  key_pair  = "${var.user_name}"
  security_groups = ["default"]
  
  network {
    name = "${var.project_network}"
  }

}

# Crear una IP de mi pool ext-net

resource "openstack_networking_floatingip_v2" "myipnode2" {
  pool = "ext-net"
}

# Asociar la IP
resource "openstack_compute_floatingip_associate_v2" "myipnode2" {
  floating_ip = "${openstack_networking_floatingip_v2.myipnode2.address}"
  instance_id = "${openstack_compute_instance_v2.mi_tf_node2.id}"
  
   provisioner "file" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key  = "${file("c:/users/joaquin/.ssh/id_rsa")}"
      host = "${azurerm_public_ip.myterraformpublicip.address}"
    }

    source      = "c:/DDatos msi/ansible/ansible_ssh_keypair/id_rsa.pub"
    destination = "/home/ubuntu/.ssh/id_rsa_ansible.pub"
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key  = "${file("c:/users/joaquin/.ssh/id_rsa")}"
      host = "${openstack_networking_floatingip_v2.myipnode2.address}"
    }
    inline = [
       "sudo apt-get update -y",
       "sudo apt-get upgrade -y",
       "sudo apt-get install -y python-minimal",
       "sudo more /home/ubuntu/.ssh/id_rsa_ansible.pub >> /home/ubuntu/.ssh/authorized_keys",
       "sudo reboot -h now"       
      ]
    on_failure = "continue"
  }

}


