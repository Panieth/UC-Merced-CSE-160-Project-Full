#include "../../includes/dv_strategy.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include <Timer.h>

module DistanceVectorRoutingP{

    //declare interface Provided
    provides interface DistanceVectorRouting;

    //declare the interfaces used 
    uses interface NeighborDiscovery as NeighborDiscovery;
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface SimpleSend as Sender;

}

implementation {

    

}