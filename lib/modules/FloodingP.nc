//a file for flooding implementation stuff

//include neccesary files 
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include <Timer.h>
//#include "../../includes/channels.h"

module FloodingP{  
    provides interface Flooding;

    //declare interfaces being used
    uses interface Hashmap<uint16_t> as PacketsSeen;
    uses interface SimpleSend as Sender; 
}

implementation{
    //code for implementation goes here 

    //we need own flooding header information, should include:
    // 1. source address of the node initiating the flood
    // 2. monotonically increasing sewuence number to identify packet
    // 3. a TTL field to avoid looping forever 

    //reccomended to add link layer module with source and destination addressess 

    //have a node table, one entry per node

    //cache to store largest sequence number seen from any node's flood 

    //one flood packet per link, send to each neighbor

    //nodes use cache to check for duplicates

    //neighbor discovery 

        //send 1 packet to each neighbor
        //dont send to neighbor you received from

    

    //two main functions which can be used by other interfaces 
    command void Flooding.sendPing(uint16_t destinationNode, uint8_t *payload){

    }

    command void Flooding.flood(pack* message){

    }

    //helper functions to assist above two functions

}
