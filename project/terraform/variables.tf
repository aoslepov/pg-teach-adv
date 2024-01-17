

# disk
data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}




variable "zone_a_hostnames" {

    default = {
        "etcd01" = {
            "name" = "etcd-01",
            "cores" = 2,
            "mem" = 2
        },

        "citus-coord-01" = {
            "name" = "citus-coord-01",
            "cores" = 2,
            "mem" = 2
        },

        "citus-worker-01" = {
            "name" = "citus-worker-01",
            "cores" = 2,
            "mem" = 4
        },

        "citus-worker-02" = {
            "name" = "citus-worker-02",
            "cores" = 2,
            "mem" = 4
        },

        "haproxy-01" = {
            "name" = "haproxy-01",
            "cores" = 2,
            "mem" = 2
        },
        "monitoring" = {
            "name" = "monitoring",
            "cores" = 2,
            "mem" = 2
        }
    }
}



variable "zone_b_hostnames" {

    default = {
        "etcd02" = {
            "name" = "etcd-02",
            "cores" = 2,
            "mem" = 2
        },

        "citus-coord-02" = {
            "name" = "citus-coord-02",
            "cores" = 2,
            "mem" = 2
        },

        "citus-worker-03" = {
            "name" = "citus-worker-03",
            "cores" = 2,
            "mem" = 4
        },

        "citus-worker-04" = {
            "name" = "citus-worker-04",
            "cores" = 2,
            "mem" = 4
        },


        "haproxy-02" = {
            "name" = "haproxy-02",
            "cores" = 2,
            "mem" = 2
        }

    }
}


variable "zone_c_hostnames" {

    default = {
        "etcd03" = {
            "name" = "etcd-03",
            "cores" = 2,
            "mem" = 2
        }


    }
}


