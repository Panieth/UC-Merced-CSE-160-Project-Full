//a file to provide the interface for DVR

//include necessary files
#include "../../includes/packet.h"

interface DistanceVectorRouting{
    
    //declare the interfaces provided by DVR
    command error_t begin();
    command void sendPing(uint16_t destinationNode, uint8_t *payload);
    command void route(pack* message);
    command void checkForUpdates(pack* message);
    command void lostNeighbor(uint16_t lostNode);
    command void foundNeighbor();
    command void printRoutingTable();
}