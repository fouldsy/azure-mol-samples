configuration nginx {
    Import-DSCResource -Module nx
    Node localhost {
        nxPackagenginx {
            Name ="nginx"
            Ensure = "Present"
            PackageManager = "apt"
        }
    }
}
