//a file to provdide the interface for flooding

#include "../../includes/packet.h" 

interface Flooding{
   
   //provide interfaces to the two main functions to be used from floodingP.nc
   command void sendPing(uint16_t destinationNode, uint8_t *payload);
   command void flood(pack* message);
}
