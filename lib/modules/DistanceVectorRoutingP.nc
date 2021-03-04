#include "../../includes/dv_strategy.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include <Timer.h>


//declare constant variables to save important parameters 
#define MAX_NUM_ROUTES 22
#define MAX_COST 17
#define DVR_TTL 4
#define STRATEGY STRATEGY_SPLIT_HORIZON


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

    //a structure to store the parameters for a given route
    typedef struct{
        uint8_t destination;
        uint8_t nextHop;
        uint8_t cost;
        uint8_t ttl;
    }Route;

    //a variable to store the number of routes
    uint16_t routeCount = 0;

    //a variable to store the routing table for the given node
    Route routingTable[MAX_NUM_ROUTES];

    //the package we are trying to route 
    pack packToRoute;

    //declaration for all extra functions not used as interfaces
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, void *payload, uint8_t length);
    void initializeTable();
    uint8_t findHop(uint8_t destination);
    void addRoute(uint8_t destination, uint8_t nextNode, uint8_t cost, uint8_t ttl);
    void removeRoute(uint8_t routeNum);
    void updateTTLS();
    void update();

    //command to begin the DVR process
    command error_t DistanceVectorRouting.begin(){
        //initialize the routing table
        initializeTable();

        //start the timer
        call Timer.startOneShot(40000);
        dbg(ROUTING_CHANNEL, "DVR started for node %u", TOS_NODE_ID);
    }
    
    //a function to make a packet, same as one given for project 1
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, void* payload, uint8_t length) {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    } 

}