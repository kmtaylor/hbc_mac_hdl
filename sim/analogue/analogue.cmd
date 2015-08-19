* Model Definitions
.INCLUDE ~/Spice/Models/OPA356.MOD
.INCLUDE ~/Spice/Models/TLV3501.MOD

* NG-Spice Simulation Commands
*.control
*SET XTRTOL=1
*.endc

.OPTIONS RELTOL=.01
*.OPTIONS ABSTOL=1N VNTOL=1M
*.OPTIONS ITL4=500
*.OPTIONS RAMPTIME=10NS
*.OPTIONS METHOD=GEAR
*.OPTIONS ACCURATE=1 GMIN=1e-9

.SAVE v(filter_in) v(filter_out)
.SAVE v(filter_out_100) v(filter_out_200) v(filter_out_300) v(filter_out_400)
.SAVE v(filter_out_400_att) v(filter_out_100_att) v(filter_in_att)
.SAVE v(rx_data)

.TRAN 1n 200u
*.TRAN 1n 2000u
*.AC LIN 100K 5K 500Meg
