// Configuration file for neighbor discovery 

//include necessary files for implementation
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include <Timer.h>

configuration NeighborDiscoveryC{
   provides interface NeighborDiscovery;
}

implementation{
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP;

    // create wiring for necessary components 
    components RandomC as Random;
    NeighborDiscoveryP.Random -> Random;

    components new TimerMilliC() as Timer;
    NeighborDiscoveryP.Timer -> Timer;

    components new SimpleSendC(AM_PACK);
    NeighborDiscoveryP.Sender -> SimpleSendC;

    components new HashmapC(uint16_t, 20);
    NeighborDiscoveryP.MapOfNeighbors -> HashmapC;

    //add components necessary for project 2
    components DistanceVectorRoutingC;
    NeighborDiscoveryP.DistanceVectorRouting -> DistanceVectorRoutingC;

}
