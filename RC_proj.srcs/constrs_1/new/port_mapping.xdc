# ============================================================================
# Clock Source (100 MHz)
# ============================================================================
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# ============================================================================
# Reset (Mapped to BTNC - Center Button)
# ============================================================================
set_property PACKAGE_PIN P16 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

set_property PACKAGE_PIN N15 [get_ports btnl]
set_property IOSTANDARD LVCMOS33 [get_ports btnl]

set_property PACKAGE_PIN R18 [get_ports btnr]
set_property IOSTANDARD LVCMOS33 [get_ports btnr]



# ============================================================================
# VGA Output Pins (12-bit color + Sync)
# ============================================================================

# VGA Red [3:0]
set_property PACKAGE_PIN V20 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN U20 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN V19 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN V18 [get_ports {vga_r[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[*]}]

# VGA Green [3:0]
set_property PACKAGE_PIN AB22 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN AA22 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN AB21 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN AA21 [get_ports {vga_g[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[*]}]

# VGA Blue [3:0]
set_property PACKAGE_PIN Y21 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN Y20 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN AB20 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN AB19 [get_ports {vga_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[*]}]

# VGA Sync Signals
set_property PACKAGE_PIN AA19 [get_ports vga_hs]
set_property PACKAGE_PIN Y19 [get_ports vga_vs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs]