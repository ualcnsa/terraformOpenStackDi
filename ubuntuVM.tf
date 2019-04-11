## 1. Generate the token to connect to OpenStack
## curl -X POST http://192.168.64.12:5000/v2.0/tokens -d '{"auth":{"passwordCredentials":{"username":"jjcanada", "password":"PASSWORD"}, "tenantId":"7cbf04cede6d4919991b8bb3b3afa0c0"}}' -H 'Content-type: application/json' > token.json
variable "user_name" {default = "jjcanada"}

## 2. Abrir el archivo token.json generado en la operación curl y copiar el token de acceso

variable "my_token" {
  default = "gAAAAABcr2g3WfCzxtxpwlBtCu4DigqegVm40rXg_l-og_9gLD4RBwImR_--zx5MbsZw7rUJ9fXq2k6V71CP5ro16KRJBrDFhpxduSMhEed4vYenEeDZBW9i7kJykkTqf4sPUK8EjcUjag76EbQHbsPaiFJkQhKzgQkF32juVXb5X5ZJRmxrQlw"  
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


########################################
# Crear la Virtual Machine
########################################

resource "openstack_compute_instance_v2" "mi_tf_instance" {
  name      = "ansible-dev"
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
resource "openstack_compute_floatingip_associate_v2" "myip_as" {
  floating_ip = "${openstack_networking_floatingip_v2.myip.address}"
  instance_id = "${openstack_compute_instance_v2.mi_tf_instance.id}"

  provisioner "file" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key  = "${file("c:/users/joaquin/.ssh/id_rsa")}"
      host = "${openstack_networking_floatingip_v2.myip.address}"
    }

    // En una carpeta local tengo creado un par de claves (especifico) para ansible.
    source      = "c:/DDatos msi/ansible/ansible_ssh_keypair/"    ## copia todos los archivos de la carpeta
    destination = "/home/ubuntu/.ssh"
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key  = "${file("c:/users/joaquin/.ssh/id_rsa")}"
      host = "${openstack_networking_floatingip_v2.myip.address}"
    }
    inline = [
      "sudo apt-get update -y",
 ##     "sudo apt-get upgrade -y",
      "sudo apt-get install -y python-minimal",
      "sudo more /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys",  ## inyecto la clave publica en authorized_keys
      "sudo apt-get install -y software-properties-common", 
      "sudo apt-add-repository --yes --update ppa:ansible/ansible", 
      "sudo apt-get install -y ansible"
      ]
    on_failure = "continue"
  }

}

