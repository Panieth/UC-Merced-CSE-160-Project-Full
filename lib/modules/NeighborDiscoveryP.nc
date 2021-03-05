//a file for neighbor discovery implementation stuff

//include neccesary files 
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include <Timer.h>
#include "../../includes/channels.h"

#define NEIGHBOR_DISCOVERY_TTL 5

module NeighborDiscoveryP{  
    provides interface NeighborDiscovery;

    //declare interfaces being used
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface SimpleSend as Sender;
    uses interface Hashmap<uint16_t> as MapOfNeighbors;

    //additional interface for project 2
    uses interface DistanceVectorRouting as DistanceVectorRouting;
    
}

implementation{
    //code for implementation goes here 

    //declare package to send 
    pack packageToSend;

    //funtion declarations needed 
     void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);


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
            //dbg(NEIGHBOR_CHANNEL, "Sent Neighbor Discovery PING\n");

        }else if( (message->dest == 0) && (message->protocol == PROTOCOL_PINGREPLY)){
            //if the protocol message is already a ping reply then a neighbor has been discovered

            
            //call MapOfNeighbors.insert(message->src, call Timer.getNow());

            //print the neighbor that has been found 
            dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery PINGREPLY recieved, discovered neighbor: %d\n", message->src);

            //changes made for DVR implementation project 2
            //if the neighbor is found then call DVR and let it know a new neighbor has been found
            if(! call MapOfNeighbors.contains(message->src)){
                call DistanceVectorRouting.foundNeighbor();
            }

            //insert the neighbor into the neighbor map, using neighbor discovery TTL as a key
            call MapOfNeighbors.insert(message->src, NEIGHBOR_DISCOVERY_TTL);
        }
    }

    event void Timer.fired(){
        
        //initialize iterator variable 
        uint16_t i = 0;

        //a variable to hold the payload 
        uint8_t payload = 0;

        //get the list of keys from the neigbor map
        uint32_t* mapKeys = call MapOfNeighbors.getKeys();

        //print neighbors 
        call NeighborDiscovery.printAllNeighbors();

        //remove any neighbors that are no longer responsive 
        for(; i < call MapOfNeighbors.size(); i++){
            if(mapKeys[i] == 0){
                continue;
            }
            //if the key is valid then print the neighbor
            if(call MapOfNeighbors.get(mapKeys[i]) == 0 ){
                //remove the neighbor 
                //dbg(NEIGHBOR_CHANNEL, "Removing the neighbor: %d\n ", mapKeys[i]);

                //tell dvr the neighbor has been lost
                call DistanceVectorRouting.lostNeighbor(mapKeys[i]);
                call MapOfNeighbors.remove(mapKeys[i]);
            }else{

                //otherwise insert
                call MapOfNeighbors.insert(mapKeys[i], call MapOfNeighbors.get(mapKeys[i]) - 1);
            }
        }

        //make a new packet and send a discovery packet
        makePack(&packageToSend, TOS_NODE_ID, 0, 1, PROTOCOL_PING, 0, &payload, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(packageToSend, AM_BROADCAST_ADDR);
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
            if(mapKeys[i] != 0){
                //print the relevant node 
                dbg(NEIGHBOR_CHANNEL, "    %d is a Neighbor\n ", mapKeys[i]);
            }
        }
    }

    //new functions to send neighbor inormation for purposes of DVR

    //a function to give the neighbors to DVR
    command uint32_t* NeighborDiscovery.getNeighbors(){
        //return the keys to the neighbor map
        return call MapOfNeighbors.getKeys();
    }

    //a function to give the number of neighbors to DVR
    command uint16_t NeighborDiscovery.getNumNeighbors(){
        //simply return the size of the neighbor list size
        return call MapOfNeighbors.size();
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
