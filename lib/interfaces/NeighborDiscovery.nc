//a file to provdide the interface for neighbor discovery

#include "../../includes/packet.h" 

interface NeighborDiscovery{
   
   command error_t begin();

   //provide interfaces for main functions of NeighborDiscoveryP.nc
   command void discoveryPacketReceived(pack* message);
   command void printAllNeighbors();

   //interfaces to provide neighbor information to other services such as DVR
   command uint32_t* getNeighbors();
   command uint16_t getNumNeighbors();
}
