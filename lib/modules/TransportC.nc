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

    //declare all components needed to implement Tranpsort
    components TransportP;
    Transport = TransportP;
    
    components RandomC as Random;
    TransportP.Random -> Random;

    components new TimerMilliC() as Timer;
    TransportP.Timer -> Timer;

    components new SimpleSendC(AM_PACK);
    TransportP.Sender -> SimpleSendC;

    components new HashmapC(uint8_t, 20) as SocketMapping;
    TransportP.SocketMapping -> SocketMapping;

    //include stuff needed from previous projects
    components DistanceVectorRoutingC;
    TransportP.DistanceVectorRouting -> DistanceVectorRoutingC;

    components NeighborDiscoveryC;
    TransportP.NeighborDiscovery -> NeighborDiscoveryC;

}