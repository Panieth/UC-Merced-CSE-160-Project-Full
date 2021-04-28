//a file to contain the wiring necessary for tcp

//include necessary files
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include <Timer.h>

//declare configuration for tcp
configuration tcpC{

    provides interface tcp;

}

implementation {

    //declare all components needed to implement tcp
    components tcpP;
    tcp = tcpP;
    
    components RandomC as Random;
    tcpP.Random -> Random;

    components new TimerMilliC() as Timer;
    tcpP.Timer -> Timer;

    components new SimpleSendC(AM_PACK);
    tcpP.Sender -> SimpleSendC;

    components new HashmapC(uint8_t, 20) as ConnectionMapping;
    tcpP.ConnectionMapping -> ConnectionMapping;

    //include stuff needed from previous projects
    components DistanceVectorRoutingC;
    tcpP.DistanceVectorRouting -> DistanceVectorRoutingC;

    components NeighborDiscoveryC;
    tcpP.NeighborDiscovery -> NeighborDiscoveryC;

    components TransportC;
    tcpP.Transport -> TransportC;

}