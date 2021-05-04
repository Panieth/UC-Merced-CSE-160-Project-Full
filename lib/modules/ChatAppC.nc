//a file to contain the wiring necessary for the Chat Application

//include necessary files
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include <Timer.h>

//declare configuration for the Chat Application
configuration ChatAppC{

    provides interface ChatApp;

}

implementation {

    //declare all components needed to implement the Chat Application
    components ChatAppP;
    ChatApp = ChatAppP;
    
    components RandomC as Random;
    ChatAppP.Random -> Random;

    components new TimerMilliC() as Timer;
    ChatAppP.Timer -> Timer;

    components new SimpleSendC(AM_PACK);
    ChatAppP.Sender -> SimpleSendC;

    components new HashmapC(uint8_t, 20) as userMap;
    ChatAppP.userMap -> userMap;

    //include stuff needed from previous projects
    components DistanceVectorRoutingC;
    ChatAppP.DistanceVectorRouting -> DistanceVectorRoutingC;

    components NeighborDiscoveryC;
    ChatAppP.NeighborDiscovery -> NeighborDiscoveryC;

}