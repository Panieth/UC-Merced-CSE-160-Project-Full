//a file to contain the wiring necessary for Transport

//include necessary files
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include <Timer.h>

//declare configuration for Transport
configuration TransportC{

    provides interface Transport;

}

implementation {

    //declare all components needed to implement DVR
    components TransportP;
    Transport = TransportP;
    
    components RandomC as Random;
    TransportP.Random -> Random;

    components new TimerMilliC() as Timer;
    TransportP.Timer -> Timer;

    components new SimpleSendC(AM_PACK);
    TransportP.Sender -> SimpleSendC;

}