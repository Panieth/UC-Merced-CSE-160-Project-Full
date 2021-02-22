//a file for neighbor discovery implementation stuff

//include neccesary files 
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include <Timer.h>
//#include "../../includes/channels.h"

module NeighborDiscoveryP{  
    provides interface NeighborDiscovery;

    //declare interfaces being used
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface Simplesend as Sender;
    uses interface Hashmap<uint16_t> as MapOfNeighbors;
    
}

implementation{
    //code for implementation goes here 

    //two main functions which can be used by other interfaces 
    
    command void NeighborDiscovery.discoveryPacketReceived(pack* message){

    }

    command void NeighborDiscovery.printAllNeighbors(){
        
    }

    //helper functions to assist above two functions
}
