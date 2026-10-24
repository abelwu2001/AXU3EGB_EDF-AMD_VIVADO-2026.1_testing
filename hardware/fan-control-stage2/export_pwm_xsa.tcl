set stage [file normalize [file dirname [info script]]]
set project [file join $stage project axu3eg_base.xpr]
set ip_repo [file normalize [file join $stage ip_repo]]
set xsa [file join $stage axu3eg_base_pwm_current.xsa]

if {![file exists $project]} { error "Project not found: $project" }
if {![file exists $ip_repo]} { error "PWM IP repository not found: $ip_repo" }
open_project $project
set_property ip_repo_paths [list $ip_repo] [current_project]
update_ip_catalog -rebuild
open_bd_design [get_files [file join $stage project axu3eg_base.srcs sources_1 bd base base.bd]]
validate_bd_design
if {[get_property STATUS [get_runs impl_1]] ne "route_design Complete!"} {
    puts "Implementation run status: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
set bit [file join $stage project axu3eg_base.runs impl_1 base_wrapper.bit]
if {![file exists $bit]} { error "Current implemented bitstream missing: $bit" }
write_hw_platform -fixed -include_bit -force -file $xsa
puts "PWM_CURRENT_XSA: $xsa"
close_project
exit
