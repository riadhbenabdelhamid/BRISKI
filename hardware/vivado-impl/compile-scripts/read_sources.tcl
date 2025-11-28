read_verilog -sv [glob ${RTL_SOURCE_DIR}/*.sv]

read_xdc $USR_CONSTR_DIR/$PINOUT_FILE

#read_xdc $USR_CONSTR_DIR/V80.xdc
#read_xdc $USR_CONSTR_DIR/nexys-a7.xdc
#read_xdc $USR_CONSTR_DIR/VCU118.xdc


