#include "../../includes/DVR.h"
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
        uint8_t dest;
        uint8_t nextHop;
        uint8_t cost;
        uint8_t ttl;
    }Route;

    //a variable to store the number of routes
    uint16_t routeCount = 0;


    //a variable to store the routing table for the given node
    Route initializeTable[MAX_NUM_ROUTES];

    //the package we are trying to route 
    pack packToRoute;

    //a variable to save the cost of the route associated with packet above
    uint16_t routeCost = 0; 

    //declaration for all extra functions not used as interfaces
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, void *payload, uint8_t length);
    void initializeInitializeTable();
    uint8_t findHop(uint8_t destination);
    void addRoute(uint8_t destination, uint8_t nextNode, uint8_t cost, uint8_t ttl);
    void RemoveRoute(uint8_t routeNum);
    void updateTTLS();
    void update();
    void inputNeighbor();
    uint8_t getCost(nx_uint16_t destination);

    //command to begin the DVR process
    command error_t DistanceVectorRouting.begin(){
        
        //initialize the routing table
        initializeInitializeTable();

        //start the timer
        call Timer.startOneShot(40000);
        dbg(ROUTING_CHANNEL, "DVR started for node %u\n", TOS_NODE_ID);
    }
    
    event void Timer.fired() {
        if (call Timer.isOneShot()) {

            // populate starting table with neighbors
            call Timer.startPeriodic(30000 + (uint16_t) (call Random.rand16()%5000));
        } else {

            // Update TTL
            updateTTLS();
            
            // Input neighbors into the routing table, if not there
            inputNeighbor();

            // pass/return the updated table
            update();
        }
    }


    //a function to send a ping using distance vector routing 
    command void DistanceVectorRouting.sendPing(uint16_t destination, uint8_t *payload) {

        //make the package
        makePack(&packToRoute, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);

        //send message to the debug channel
        dbg(ROUTING_CHANNEL, "PING FROM %d TO %d\n", TOS_NODE_ID, destination);

        //logging the sent pack
        logPack(&packToRoute);

        call DistanceVectorRouting.route(&packToRoute);
    }


    //a function to route a packet using the relevant routing data 
    command void DistanceVectorRouting.route(pack* message) {
        //initialize variable to store next destination
        uint8_t nextHop;

        //if destination is correct, print message and return
        if (message->dest == TOS_NODE_ID) {

            //print out info about the packet received 
            dbg(ROUTING_CHANNEL, "Packet has reached destination %d!!!----------------------------------\n", TOS_NODE_ID);
            dbg(ROUTING_CHANNEL, "     From node: %d\n", message->src);
            dbg(ROUTING_CHANNEL, "     Payload: %s\n", message->payload);

            return;
        }

        //if destination is not correct, find the next hop for the message
        nextHop = findHop(message->dest);

        //drop packet if a route cannot be found
        if (nextHop == 0) {

            dbg(ROUTING_CHANNEL, "No route to destination. Dropping packet...\n");

            //log the package 
            logPack(message);

        } else {

            //spit out next node the packet is heading through
            //dbg(ROUTING_CHANNEL, "Node %d routing packet through %d\n", TOS_NODE_ID, nextHop);

            uint16_t cost = getCost(message->dest);
            dbg(ROUTING_CHANNEL, "Routing Packet - src: %d, dest: %d, seq: %d, next hop: %d, cost: %d\n", message->src, message->dest, message->seq, nextHop,  cost);

            //log the package 
            logPack(message);

            //send the package to the designated next hop
            call Sender.send(*message, nextHop);

        }
    }

    //a function that gets the cost for the hop that will lead to the desired desination
    uint8_t getCost(nx_uint16_t destination){
        uint8_t i;

        //iterate over routes in the routing table until the destination is found
        //then return the cost to get to that destination
        for(i = 0; i < routeCount; i++){
            if(initializeTable[i].dest == destination){
                return initializeTable[i].cost;
            }
        }
    }

    // a function to check if updates are needed 
    command void DistanceVectorRouting.checkForUpdates(pack* message) {

        //initializing variables
        uint16_t i, j;
        //bools to store relevant conditions 
        bool routePresent = FALSE, routesAdded = FALSE;
        //routes recieved in an update packet 
        Route* receivedRoutes = (Route*) message->payload;

        // For each of up to 5 routes, process the routes
        for (i = 0; i < 5; i++) {

            // Reached the last route: stop
            if (receivedRoutes[i].dest == 0) { 

                break; 

            }

            //iterate over all the routes 
            for (j = 0; j < routeCount; j++) {

                if (receivedRoutes[i].dest == initializeTable[j].dest) {

                    // If Split Horizon packet do nothing
                    // If sender is the source of table entry update
                    // If more optimal route found update
                    if (receivedRoutes[i].nextHop != 0) {

                        if (initializeTable[j].nextHop == message->src) {

                            initializeTable[j].cost = (receivedRoutes[i].cost + 1 < MAX_COST) ? receivedRoutes[i].cost + 1 : MAX_COST;

                            //debug test statements
                            //dbg(ROUTING_CHANNEL, "Update to route: %d from neighbor: %d with new cost %d\n", initializeTable[i].dest, initializeTable[i].nextHop, initializeTable[i].cost);

                        } else if (receivedRoutes[i].cost + 1 < MAX_COST && receivedRoutes[i].cost + 1 < initializeTable[j].cost) {

                            initializeTable[j].nextHop = message->src;

                            initializeTable[j].cost = receivedRoutes[i].cost + 1;

                            //debug test statements
                            //dbg(ROUTING_CHANNEL, "More optimal route found to dest: %d through %d at cost %d\n", receivedRoutes[i].dest, receivedRoutes[i].nextHop, receivedRoutes[i].cost +1);

                        }

                    }

                    // If route cost not infinite, we should update the TTL
                    if (initializeTable[j].cost != MAX_COST){

                        initializeTable[j].ttl = DVR_TTL;

                    }

                    //a route is present
                    routePresent = TRUE;
                    break;
                }

            }

            // If route is not in table AND there is space AND it is not a split horizon packet AND the route cost is not infinite -> add it
            if (!routePresent && routeCount != MAX_NUM_ROUTES && receivedRoutes[i].nextHop != 0 && receivedRoutes[i].cost != MAX_COST) {

                addRoute(receivedRoutes[i].dest, message->src, receivedRoutes[i].cost + 1, DVR_TTL);
                
                //mark that there is a route to add 
                routesAdded = TRUE;

            }

            //at this point there is no route present
            routePresent = FALSE;

        }

        //if there is a route to add then run the update function
        if (routesAdded) {
            update();
        }

    }

    //a fuction to handle a lost neighbor 
    command void DistanceVectorRouting.lostNeighbor(uint16_t lostNeighbor) {

        // Neighbor lost, update routing table and trigger DV update
        uint16_t i;
        
        //if the neighbor isnt lost, just exit
        if (lostNeighbor == 0) {

            return;

        }
            
        //print the neighbor has been lost, and reconfigure the table
        dbg(ROUTING_CHANNEL, "Neighbor discovery has lost neighbor %u. Distance is now infinite!\n", lostNeighbor);
        for (i = 1; i < routeCount; i++) {

            //when a neighbor is nost the cost has to be set to infinity 
            if (initializeTable[i].dest == lostNeighbor || initializeTable[i].nextHop == lostNeighbor) {

                initializeTable[i].cost = MAX_COST;

            }

        }

        //run the update function to take care of the lost neighbor updates 
        update();
    }

    //a function to handle when a neigbor is found 
    command void DistanceVectorRouting.foundNeighbor() {

       //call to input the neighbors
       inputNeighbor();

    }

    
    //a function to print the parameters of the routing table 
    command void DistanceVectorRouting.printRoutingTable() {

        uint8_t i;

        //anounce table is being printed
        dbg(ROUTING_CHANNEL, "Routing Table at node %d:\n",TOS_NODE_ID);

        //print the routing info headers
        //dbg(ROUTING_CHANNEL, "DEST  HOP  COST  TTL\n");
        dbg(ROUTING_CHANNEL, "DEST  HOP  COST\n");

        //print the table
        for (i = 0; i < routeCount; i++) {

            //dbg(ROUTING_CHANNEL, "%4d%5d%6d%5d\n", initializeTable[i].dest, initializeTable[i].nextHop, initializeTable[i].cost, initializeTable[i].ttl);
            
            dbg(ROUTING_CHANNEL, "%4d%5d%6d\n", initializeTable[i].dest, initializeTable[i].nextHop, initializeTable[i].cost);
        }
    }

    void inputNeighbor(){
         //variable initialization
        uint32_t* neighbors = call NeighborDiscovery.getNeighbors(); //grab neighbor information from neighbor discovery interface 
        uint16_t numNeighbors = call NeighborDiscovery.getNumNeighbors();
        uint8_t i, j;
        bool routeFound = FALSE, newNeighborfound = FALSE;

        //iterate over the entire neighbor list provided 
        for (i = 0; i < numNeighbors; i++) {

            //iterate over the routes
            for (j = 1; j < routeCount; j++) {

                // If the neighbor is found in the table, update the table entry
                if (neighbors[i] == initializeTable[j].dest) {

                    initializeTable[j].nextHop = neighbors[i];
                    initializeTable[j].cost = 1; //since neighbors cost between them is one
                    initializeTable[j].ttl = DVR_TTL;

                    //indicate a new route has been found
                    routeFound = TRUE;

                    break;

                }

            }

            // Add neighbor if it is not already present in the routes, and we have the space for it
            if (!routeFound && routeCount != MAX_NUM_ROUTES) {

                //add and indicate a new neighbor route was found
                addRoute(neighbors[i], neighbors[i], 1, DVR_TTL);   
                newNeighborfound = TRUE;

            } else if (routeCount == MAX_NUM_ROUTES) {

                //if max capacity reached, print error message 
                dbg(ROUTING_CHANNEL, "Routing table full. Cannot add entry for node: %u\n", neighbors[i]);

            }
            //at this point no route has been found
            routeFound = FALSE;

        }

        //if a new neighbor rout was found and needs to be added then
        if (newNeighborfound) {

            //update DVR system
            update();

        }
    }


    //initiailize the initial table
    void initializeInitializeTable() {

        //add the first route to the table 
        addRoute(TOS_NODE_ID, TOS_NODE_ID, 0, DVR_TTL);

    }

    //a function to return the hop to be taken given the destination
    uint8_t findHop(uint8_t dest) {

        uint16_t i;

        //iterate over the routes 
        for (i = 1; i < routeCount; i++) {

            //if the destination at i eqials the destination then return the next hop parameter
            if (initializeTable[i].dest == dest) {

                return (initializeTable[i].cost == MAX_COST) ? 0 : initializeTable[i].nextHop;

            }

        }

        //at this point there is no next hop, return 0
        return 0;

    }

    // Add route to current list
    void addRoute(uint8_t dest, uint8_t nextHop, uint8_t cost, uint8_t ttl) {

        //if there is room to add a route 
        if (routeCount != MAX_NUM_ROUTES) {

            //initialize the route with appropriate parameters and increment the count 
            initializeTable[routeCount].dest = dest;
            initializeTable[routeCount].nextHop = nextHop;
            initializeTable[routeCount].cost = cost;
            initializeTable[routeCount].ttl = ttl;
            routeCount++;

        }

        //debug statements for troubleshooting
        //dbg(ROUTING_CHANNEL, "Added entry in routing table for node: %u\n", dest);
    }

    // a function to remove a given route 
    void RemoveRoute(uint8_t id) {

        uint8_t j;

        // Move other entries left
        for (j = id+1; j < routeCount; j++) {

            initializeTable[j-1].dest = initializeTable[j].dest;
            initializeTable[j-1].nextHop = initializeTable[j].nextHop;
            initializeTable[j-1].cost = initializeTable[j].cost;
            initializeTable[j-1].ttl = initializeTable[j].ttl;

        }

        // Zero the j-1 entry
        initializeTable[j-1].dest = 0;
        initializeTable[j-1].nextHop = 0;
        initializeTable[j-1].cost = MAX_COST;
        initializeTable[j-1].ttl = 0;

        //decrement route count
        routeCount--;        

    }

    //a function to update the TTL's of the table 
    void updateTTLS() {

        //Initialize variables
        uint8_t i;
        uint8_t j;

        //iterate through the routes
        for (i = 1; i < routeCount; i++) {

            // If table entry is valid we should decrease the TTL
            if (initializeTable[i].ttl != 0) {
                
                //decrease the ttl
                initializeTable[i].ttl--;

            }
            // If the TTL is zero remove route
            if (initializeTable[i].ttl == 0) {    

                dbg(ROUTING_CHANNEL, "Route stale, removing: %u\n", initializeTable[i].dest);

                //remove route and update table 
                RemoveRoute(i);
                update();
            }

        }

    }


    
    // Skip the route for split horizon
    // Alter route table for poison reverse, keeping values in temp vars
    // Copy route onto array
    // Restore original route
    // Send packet with copy of partial routing table
    void update() {

        //setting up variables as necessary for the function
        // Send routes to all neighbors one at a time. Use split horizon, poison reverse
        uint32_t* neighbors = call NeighborDiscovery.getNeighbors();
        uint16_t numNeighbors = call NeighborDiscovery.getNumNeighbors();
        uint8_t i = 0, j = 0, tempRouteCounter = 0;
        uint8_t temp;
        //routes to be sent to neighboring nodes 
        Route routesToSend[5];
        bool valuesSwapped = FALSE;

        // Zero out the routes declared above 
        for (i = 0; i < 5; i++) {

                routesToSend[i].dest = 0;
                routesToSend[i].nextHop = 0;
                routesToSend[i].cost = 0;
                routesToSend[i].ttl = 0;

        }

        // Send to every neighbor
        for (i = 0; i < numNeighbors; i++) {

            //while we have space to add routes 
            while (j < routeCount) {

                
                // Split Horizon/Poison Reverse 
                if (neighbors[i] == initializeTable[j].nextHop && STRATEGY == STRATEGY_SPLIT_HORIZON) {

                    //temporarily cache the next hop
                    temp = initializeTable[j].nextHop;

                    //set the real value to zero
                    initializeTable[j].nextHop = 0;

                    //the values are currently swapped
                    valuesSwapped = TRUE;

                } else if (neighbors[i] == initializeTable[j].nextHop && STRATEGY == STRATEGY_POISON_REVERSE) {

                    //temporarilt cache the cost
                    temp = initializeTable[j].cost;

                    //set the real value to max cost
                    initializeTable[j].cost = MAX_COST;
                    
                    //indicate values are swapped
                    valuesSwapped = TRUE;
                }

                // Add route to array to be sent out
                routesToSend[tempRouteCounter].dest = initializeTable[j].dest;
                routesToSend[tempRouteCounter].nextHop = initializeTable[j].nextHop;
                routesToSend[tempRouteCounter].cost = initializeTable[j].cost;
                //increment temp route counter 
                tempRouteCounter++;

                // If our array is full or we have added all routes then we send out packet with routes
                if (tempRouteCounter == 5 || j == routeCount-1) {

                    // make the packet to be sent, the payload being a pointer to the packet routes to be shared with neighbors
                    makePack(&packToRoute, TOS_NODE_ID, neighbors[i], 1, PROTOCOL_DV, 0, &routesToSend, sizeof(routesToSend));

                    // Send out packet
                    call Sender.send(packToRoute, neighbors[i]);

                    // Zero out array
                    while (tempRouteCounter > 0) {

                        //reset all routes to zero as they have been sent already 
                        tempRouteCounter = tempRouteCounter - 1;
                        routesToSend[tempRouteCounter].dest = 0;
                        routesToSend[tempRouteCounter].nextHop = 0;
                        routesToSend[tempRouteCounter].cost = 0;
                    }

                }

                // Restore the table, either cost or hop based on what was initially changed 
                if (valuesSwapped && STRATEGY == STRATEGY_SPLIT_HORIZON) {

                    initializeTable[j].nextHop = temp;

                } else if (valuesSwapped && STRATEGY == STRATEGY_POISON_REVERSE) {

                    initializeTable[j].cost = temp;

                }
                //nothing is swapped anymore
                valuesSwapped = FALSE;
                j++;

            }

            j = 0;

        }

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