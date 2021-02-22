// Configuration file for flooding 

//include necessary files for implementation
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include <Timer.h>

configuration FloodingC{
    //provide the interface necessary to run flooding service 
    provides interface Flooding;
}

implementation{
    components FloodingP;
    Flooding = FloodingP;

    //create wiring for neccesary components 
    components new SimpleSendC(AM_PACK);
    FloodingP.Sender -> SimpleSendC;

    components new HashmapC(uint16_t, 20);
    FloodingP.PacketsSeen -> HashmapC;

}
