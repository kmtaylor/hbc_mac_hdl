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

* Remove the .SAVE commands when doing a sensitivity analysis
*.SAVE v(filter_in) v(filter_out)
*.SAVE v(filter_out_100) v(filter_out_200) v(filter_out_300) v(filter_out_400)
*.SAVE v(filter_out_400_att) v(filter_out_100_att) v(filter_in_att)
*.SAVE v(rx_data)

* Set V_TX to "external"
* Filter testing
*.TRAN 1n 200u
* Packet testing
*.TRAN 1n 2000u
* Set V_TX to "AC 1.25 DC 1.25"
*.AC LIN 100K 5K 500Meg
.SENS v(filter_out) AC LIN 1000 5K 100Meg
