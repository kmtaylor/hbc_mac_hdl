cat ../transceiver_ise/toplevel.syr | grep WARNING | sort -u | sed \
    '/of sequential type is unconnected in block/d' | sed \
    '/This unconnected signal will be trimmed during the optimization process/d' | sed \
    '/This port will be preserved and left unconnected if it belongs/d' | sed \
    '/Maxfanout/d' | sed \
    '/constant value of 0/d' | sed \
    '/No primary, secondary unit/d' | sed \
    '/internal tristates are replaced/d' | sed \
    '/Instantiating black box module/d' | sed \
    '/not supported by the current software release/d' | sed \
    '/ddr2/d'
