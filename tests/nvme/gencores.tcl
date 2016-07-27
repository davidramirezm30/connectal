set ipdir {cores}
set boardname {vc709}

if {$boardname == {nfsume}} {
    set partname {xc7vx690tffg1761-2}
    set databuswidth 256
}
if {$boardname == {vc709}} {
    set partname {xc7vx690tffg1761-2}
    set databuswidth 256
}
if {$boardname == {miniitx100}} {
    set partname {xc7z100ffg900-2}
    set databuswidth 64
}
puts "partname=$partname"

create_project -name local_synthesized_ip -in_memory -part $partname
if {$boardname == {nfsume}} {
    set_property board_part xilinx.com:vc709:part0:1.0 [current_project]
}
proc fpgamake_ipcore {core_name core_version ip_name params} {
    global ipdir boardname

    set generate_ip 0

    if [file exists $ipdir/$boardname/$ip_name/$ip_name.xci] {
    } else {
	puts "no xci file $ip_name.xci"
	set generate_ip 1
    }
    if [file exists $ipdir/$boardname/$ip_name/vivadoversion.txt] {
	gets [open $ipdir/$boardname/$ip_name/vivadoversion.txt r] generated_version
	set current_version [version -short]
	puts "core was generated by vivado $generated_version, currently running vivado $current_version"
	if {$current_version != $generated_version} {
	    puts "vivado version does not match"
	    set generate_ip 1
	}
    } else {
	puts "no vivado version recorded"
	set generate_ip 1
    }

    ## check requested core version and parameters
    if [file exists $ipdir/$boardname/$ip_name/coreversion.txt] {
	gets [open $ipdir/$boardname/$ip_name/coreversion.txt r] generated_version
	set current_version "$core_name $core_version $params"
	puts "Core generated: $generated_version"
	puts "Core requested: $current_version"
	if {$current_version != $generated_version} {
	    puts "core version or params does not match"
	    set generate_ip 1
	}
    } else {
	puts "no core version recorded"
	set generate_ip 1
    }

    if $generate_ip {
	file delete -force $ipdir/$boardname/$ip_name
	file mkdir $ipdir/$boardname
	create_ip -name $core_name -version $core_version -vendor xilinx.com -library ip -module_name $ip_name -dir $ipdir/$boardname
	if [llength $params] {
	    set_property -dict $params [get_ips $ip_name]
	}
        report_property -file $ipdir/$boardname/$ip_name.properties.log [get_ips $ip_name]
	
	generate_target all [get_files $ipdir/$boardname/$ip_name/$ip_name.xci]

	set versionfd [open $ipdir/$boardname/$ip_name/vivadoversion.txt w]
	puts $versionfd [version -short]
	close $versionfd

	set corefd [open $ipdir/$boardname/$ip_name/coreversion.txt w]
	puts $corefd "$core_name $core_version $params"
	close $corefd
    } else {
	read_ip $ipdir/$boardname/$ip_name/$ip_name.xci
    }
    if [file exists $ipdir/$boardname/$ip_name/$ip_name.dcp] {
    } else {
	synth_ip [get_ips $ip_name]
    }
}

if {$partname != {xc7vx690tffg1761-2}} {
    fpgamake_ipcore axi_pcie 2.7 axi_pcie_rp [list CONFIG.INCLUDE_RC {Root_Port_of_PCI_Express_Root_Complex} CONFIG.NO_OF_LANES {X4} CONFIG.BAR0_SCALE {Gigabytes} CONFIG.INCLUDE_BAROFFSET_REG {false} CONFIG.AXIBAR_0 {0x00000000} CONFIG.AXIBAR_HIGHADDR_0 {0xfFFFFFFF} CONFIG.AXIBAR2PCIEBAR_0 {0x00000000} CONFIG.BASEADDR {0x00000000} CONFIG.HIGHADDR {0xffffffff} CONFIG.XLNX_REF_BOARD {ZC706} CONFIG.shared_logic_in_core {true} CONFIG.MAX_LINK_SPEED {5.0_GT/s} CONFIG.DEVICE_ID {0x7022} CONFIG.BASE_CLASS_MENU {Bridge_device} CONFIG.SUB_CLASS_INTERFACE_MENU {InfiniBand_to_PCI_host_bridge} CONFIG.BAR0_SIZE {1} CONFIG.S_AXI_DATA_WIDTH {128} CONFIG.M_AXI_DATA_WIDTH {128} CONFIG.NUM_MSI_REQ {5} CONFIG.S_AXI_SUPPORTS_NARROW_BURST {true}]
} else {
    fpgamake_ipcore axi_pcie3 2.1 axi_pcie_rp [list CONFIG.mode_selection {Advanced} CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} CONFIG.pcie_blk_locn {X0Y0} CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} CONFIG.SYS_RST_N_BOARD_INTERFACE {Custom} CONFIG.PCIE_BOARD_INTERFACE {Custom} CONFIG.pl_link_cap_max_link_width {X8} CONFIG.axi_data_width {256_bit} CONFIG.plltype {QPLL1} CONFIG.axisten_freq {250} CONFIG.dedicate_perst {false} CONFIG.pf0_device_id {7131} CONFIG.pf0_base_class_menu {Bridge_device} CONFIG.pf0_class_code_base {06} CONFIG.pf0_sub_class_interface_menu {CardBus_bridge} CONFIG.pf0_class_code_sub {07} CONFIG.pf0_class_code {060700} CONFIG.pf0_bar0_size {2} CONFIG.pf0_bar0_scale {Gigabytes} CONFIG.axibar_highaddr_0 {0xffffffffffffffff} ]
}

