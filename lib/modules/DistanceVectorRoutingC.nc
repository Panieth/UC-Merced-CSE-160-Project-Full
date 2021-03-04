//a file to contain the wiring necessary for DVR

//include necessary files
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include <Timer.h>

//declare configuration for DVR
configuration DistanceVectorRoutingC{

    provides interface DistanceVectorRouting;

}

implementation {

    //declare all components needed to implement DVR
    components DistanceVectorRoutingP;
    DistanceVectorRouting = DistanceVectorRoutingP;

    components NeighborDiscoveryC;
    DistanceVectorRoutingP.NeighborDiscovery -> NeighborDiscoveryC;
    
    components RandomC as Random;
    DistanceVectorRoutingP.Random -> Random;

    components new TimerMilliC() as Timer;
    DistanceVectorRoutingP.Timer -> Timer;

    components new SimpleSendC(AM_PACK);
    DistanceVectorRoutingP.Sender -> SimpleSendC;

}