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

    //a function to start the neighbor discovery timer 
    command error_t NeighborDiscovery.begin(){
        //start the timer periodically
        call Timer.startPeriodic((uint16_t) (call Random.rand16() % 1000) + 10000);

        //print its stated using the debug channel 
        dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery has been Started!\n");

    }
    
    command void NeighborDiscovery.discoveryPacketReceived(pack* message){
        
        //at this point a neighbor discovery packet has been recieved 

        //if the packet is valid send a neighbor discovery ping
        if( (message->protocol == PROTOCOL_PING) && (message->TTL > 0) ){
            //update the source node 
            message->src = TOS_NODE_ID;
            //decrease its time to live 
            message->TTL--;
            //set the protocol
            message->protocol = PROTOCOL_PINGREPLY;

            //send the packet 
            call Sender.send(*message, AM_BROADCAST_ADDR);
            //print such in the channel
            dbg(NEIGHBOR_CHANNEL, "Sent Neighbor Discovery PING\n");

        }else if( (message->dest == 0) && (message->protocol == PROTOCOL_PINGREPLY)){
            //if the protocol messsage is already a ping reply then a neighbor has been discovered

            //insert the neighbor into the neighbor map, using time as a key
            call MapOfNeighbors.insert(message->src, call Timer.getNow())

            //print the neighbor that has been found 
            dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery PINGREPLY recieved, discovered neighbor: %d\n", message->src)
        }
    }

    command void NeighborDiscovery.printAllNeighbors(){
        
        //initialize iterator variable 
        uint16_t i = 0;

        //get the list of keys from the neigbor map
        uint32_t* mapKeys = call MapOfNeighbors.getKeys();

        //proceed to print the neighbors 
        dbg(NEIGHBOR_CHANNEL, "Printing all the neigbors...\n");
        for(; i < call MapOfNeighbors.size(); i++){

            //if the key is valid then print the neighbor
            if([mapKeys[i] != 0){
                //print the relevant node 
                dbg(NEIGHBOR_CHANNEL, "    %d is a Neighbor\n ", mapKeys[i]);
            }
        }
    }

    //helper functions to assist above two functions

    //a function to initialize a package with correct values, identical to one found in Node.nc
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
