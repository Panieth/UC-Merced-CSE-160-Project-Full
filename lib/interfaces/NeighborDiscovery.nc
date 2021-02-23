//a file to provdide the interface for neighbor discovery

#include "../../includes/packet.h" 

interface NeighborDiscovery{
   
   command error_t begin();

   //provide interfaces for main functions of NeighborDiscoveryP.nc
   command void discoveryPacketReceived(pack* message);
   command void printAllNeighbors();

}
