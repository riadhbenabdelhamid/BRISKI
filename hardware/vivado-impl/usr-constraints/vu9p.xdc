# Bitstream configuration
set_property BITSTREAM.GENERAL.COMPRESS true            [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN enable   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8            [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1    [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE yes         [current_design]
set_property CONFIG_VOLTAGE 1.8                         [current_design]

# 125 MHz clock
set_property PACKAGE_PIN AY24 [get_ports {REFCLK_P}]
set_property PACKAGE_PIN AY23 [get_ports {REFCLK_N}]

create_clock -period 8 -name refclk [get_ports {REFCLK_P}]

set_property IOSTANDARD LVDS [get_ports {REFCLK_P}]
set_property IOSTANDARD LVDS [get_ports {REFCLK_N}]
set_property PACKAGE_PIN BB32 [get_ports {DONE_GPIO_LED_0}]

set_false_path -through [get_ports reset]

set_property IOSTANDARD LVCMOS12    [get_ports -filter NAME=~DONE_GPIO_LED_0*]
set_property DRIVE 8                [get_ports -filter NAME=~DONE_GPIO_LED_0*]
set_false_path -to                  [get_ports -filter NAME=~DONE_GPIO_LED_0*]


## Reset 
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS12} [get_ports reset]
