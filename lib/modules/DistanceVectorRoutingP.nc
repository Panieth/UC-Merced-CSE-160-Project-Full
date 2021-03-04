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



//Vargas: stragetgy poison reverse is commeneted out on other file. not sure if we need it to make things work 
//but it is referenced in line 500ish inside of update method
//also, you have "start" to be refrenced as "begin", but I wasn't sure if that included things like Timer.startOneshot
//and if they should be changed to Timer.beginOneShot. If so, you might wanna double check those as well



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




//Hey Vargas, just waneted to let you know that i am changing all the 
//"routingTable" variables to "initializeTable". If that's not what it's
//supposed to be according to the note you gave me, now you know what to 
//conrtol + f to look for



    //a variable to store the routing table for the given node
    Route initializeTable[MAX_NUM_ROUTES];

    //the package we are trying to route 
    pack packToRoute;

    //declaration for all extra functions not used as interfaces
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, void *payload, uint8_t length);
    void initializeInitializeTable();
    uint8_t findHop(uint8_t destination);
    void addRoute(uint8_t destination, uint8_t nextNode, uint8_t cost, uint8_t ttl);
    void RemoveRoute(uint8_t routeNum);
    void updateTTLS();
    void update();
    void inputNeighbor();

    //command to begin the DVR process
    command error_t DistanceVectorRouting.begin(){
        
        //initialize the routing table
        initializeInitializeTable();

        //start the timer
        call Timer.startOneShot(40000);
        dbg(ROUTING_CHANNEL, "DVR started for node %u", TOS_NODE_ID);
    }
    
    event void Timer.fired() {
        if (call Timer.isOneShot()) {

            // populate starting table with neighbors
            call Timer.startPeriodic(30000 + (uint16_t) (call Random.rand16()%5000));
        } else {

            // Update TTL
            updateTTLS();

            
            //Vargas, this one (inputNeighbors)interacts with Neighbor discovery, and honestly i dunno how the calls for that work
            //so you might have to edit the input Neighbors function and rename it, or however you want to handle it
            
            

            // Input neighbors into the routing table, if not there
            inputNeighbor();

            // pass/return the updated table
            update();
        }
    }





command void DistanceVectorRouting.sendPing(uint16_t destination, uint8_t *payload) {

        //make the package
        makePack(&packToRoute, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);

        //send message to the debug channel
        dbg(ROUTING_CHANNEL, "PING FROM %d TO %d\n", TOS_NODE_ID, destination);

        //logging the sent pack
        logPack(&packToRoute);

        call DistanceVectorRouting.route(&packToRoute);
    }


    command void DistanceVectorRouting.route(pack* myMsg) {
        //initialize variable to store next destination
        uint8_t nextHop;

        //if destination is correct, print message and return
        if (myMsg->dest == TOS_NODE_ID) {

            dbg(ROUTING_CHANNEL, "Packet has reached destination %d!!!\n", TOS_NODE_ID);

            return;
        }

        //if destination is not correct, find the next hop for the message
        nextHop = findHop(myMsg->dest);

//Hey Vargas, just a suggestion, but maybe use case statements here?
//Case 0 = no route, case default = routing through kind of thing
//i dunno. Just a suggestion  ¯\_(ツ)_/¯

        //drop packet if a route cannot be found
        if (nextHop == 0) {

            dbg(ROUTING_CHANNEL, "No route to destination. Dropping packet...\n");

            logPack(myMsg);

        } else {

            //spit out next node the packet is heading through
            dbg(ROUTING_CHANNEL, "Node %d routing packet through %d\n", TOS_NODE_ID, nextHop);

            logPack(myMsg);

            call Sender.send(*myMsg, nextHop);

        }
    }


//Vargas, not sure how this one is called. The only time "checkForUpdates" 
//appears is here. Still no idea how nesC works.  ¯\_(ツ)_/¯ If that's not important feel
//free to ignore this 

    // Update the table if needed
    command void DistanceVectorRouting.checkForUpdates(pack* myMsg) {

        //initializing variables
        uint16_t i, j;
        bool routePresent = FALSE, routesAdded = FALSE;
        Route* receivedRoutes = (Route*) myMsg->payload;

        // For each of up to 5 routes, process the routes
        for (i = 0; i < 5; i++) {

            // Reached the last route: stop
            if (receivedRoutes[i].dest == 0) { 

                break; 

            }

            for (j = 0; j < routeCount; j++) {

                if (receivedRoutes[i].dest == initializeTable[j].dest) {

                    // If Split Horizon packet do nothing
                    // If sender is the source of table entry update
                    // If more optimal route found update
                    if (receivedRoutes[i].nextHop != 0) {

                        if (initializeTable[j].nextHop == myMsg->src) {

                            initializeTable[j].cost = (receivedRoutes[i].cost + 1 < MAX_COST) ? receivedRoutes[i].cost + 1 : MAX_COST;

                            //debug test statements
                            //dbg(ROUTING_CHANNEL, "Update to route: %d from neighbor: %d with new cost %d\n", initializeTable[i].dest, initializeTable[i].nextHop, initializeTable[i].cost);

                        } else if (receivedRoutes[i].cost + 1 < MAX_COST && receivedRoutes[i].cost + 1 < initializeTable[j].cost) {

                            initializeTable[j].nextHop = myMsg->src;

                            initializeTable[j].cost = receivedRoutes[i].cost + 1;

                            //debug test statements
                            //dbg(ROUTING_CHANNEL, "More optimal route found to dest: %d through %d at cost %d\n", receivedRoutes[i].dest, receivedRoutes[i].nextHop, receivedRoutes[i].cost +1);

                        }

                    }

                    // If route cost not infinite, we should update the TTL
                    if (initializeTable[j].cost != MAX_COST){

                        initializeTable[j].ttl = DVR_TTL;

                    }

                    routePresent = TRUE;
                    break;
                }

            }

            //Vargas, any idea wtf a split horizon packet is? I don't. Crash course me on it ASAP

            // If route is not in table AND there is space AND it is not a split horizon packet AND the route cost is not infinite -> add it
            if (!routePresent && routeCount != MAX_NUM_ROUTES && receivedRoutes[i].nextHop != 0 && receivedRoutes[i].cost != MAX_COST) {

                addRoute(receivedRoutes[i].dest, myMsg->src, receivedRoutes[i].cost + 1, DVR_TTL);

                routesAdded = TRUE;

            }

            routePresent = FALSE;

        }

        if (routesAdded) {

            update();

        }

    }

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

            if (initializeTable[i].dest == lostNeighbor || initializeTable[i].nextHop == lostNeighbor) {

                initializeTable[i].cost = MAX_COST;

            }

        }

        update();
    }

    //hey vargas, just as a general note, if something doesn't work, check the capitalization. I copied them exactly as you 
    //wrote them in the note. So if something on the note was capitalized, but it's not supposed to be, I capitalized it even
    //if syntax was inconsistent. Found neighbor is an example of this. you wrote it with a capital f but lost neighbor starts
    //with a lowercase l. Just thought I'd let you know. 

    command void DistanceVectorRouting.foundNeighbor() {

        // Neighbor found, update routing table and trigger DV update
        inputNeighbor();

    }


    command void DistanceVectorRouting.printRoutingTable() {

        uint8_t i;

        //print the routing info headers
        dbg(ROUTING_CHANNEL, "DEST  HOP  COST  TTL\n");

        //print the table
        for (i = 0; i < routeCount; i++) {

            dbg(ROUTING_CHANNEL, "%4d%5d%6d%5d\n", initializeTable[i].dest, initializeTable[i].nextHop, initializeTable[i].cost, initializeTable[i].ttl);

        }
    }

    //vargas, this has "initilize" incorrectly spelled (should be "initialize"). No idea if that matters or not, but 
    //if we change it to be correct that's one more thing that's different about our code. Just dont know if changing 
    //it will break anything. Also, i dont see it used anywhere other than here. Once again no idea how NesC works. So
    //if it's never used/called maybe we can just scrap this one?

    //initiailize the initial table
    void initializeInitializeTable() {

        addRoute(TOS_NODE_ID, TOS_NODE_ID, 0, DVR_TTL);

    }

    uint8_t findHop(uint8_t dest) {

        uint16_t i;

        for (i = 1; i < routeCount; i++) {

            if (initializeTable[i].dest == dest) {

                return (initializeTable[i].cost == MAX_COST) ? 0 : initializeTable[i].nextHop;

            }

        }

        return 0;

    }

    // Add route to current list
    void addRoute(uint8_t dest, uint8_t nextHop, uint8_t cost, uint8_t ttl) {

        if (routeCount != MAX_NUM_ROUTES) {

            initializeTable[routeCount].dest = dest;
            initializeTable[routeCount].nextHop = nextHop;
            initializeTable[routeCount].cost = cost;
            initializeTable[routeCount].ttl = ttl;
            routeCount++;

        }

        //debug statements for troubleshooting
        //dbg(ROUTING_CHANNEL, "Added entry in routing table for node: %u\n", dest);
    }

    //vargas i changed "idx" to "id" if this breaks anything this might by why. 
    //also might want to consider changing the comments on this section. I wasn't 
    //sure what to say here

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
        //vargas potential change to --routeCount?
        routeCount--;        

    }

    void updateTTLS() {

        //Initialize variables
        uint8_t i;
        uint8_t j;

        //iterate through the routes
        for (i = 1; i < routeCount; i++) {

            // If table entry is valid we should decrease the TTL
            if (initializeTable[i].ttl != 0) {
                
                //vargas, potential change to --initializeTable[i].ttl?
                initializeTable[i].ttl--;

            }
            // If the TTL is zero remove route
            if (initializeTable[i].ttl == 0) {    

                dbg(ROUTING_CHANNEL, "Route stale, removing: %u\n", initializeTable[i].dest);

                RemoveRoute(i);

                update();
            }

        }

    }


    //vargas this is the less big one but still kinda specific
    void inputNeighbor() {
        
        //variable initialization
        uint32_t* neighbors = call NeighborDiscovery.getNeighbors();
        uint16_t neighborsListSize = call NeighborDiscovery.getNumNeighbors();
        uint8_t i, j;
        bool routeFound = FALSE, newNeighborfound = FALSE;

        for (i = 0; i < neighborsListSize; i++) {

            for (j = 1; j < routeCount; j++) {

                // If the neighbor is found in the table, update the table entry
                if (neighbors[i] == initializeTable[j].dest) {

                    initializeTable[j].nextHop = neighbors[i];
                    initializeTable[j].cost = 1;
                    initializeTable[j].ttl = DVR_TTL;

                    routeFound = TRUE;

                    break;

                }

            }

            // Add neighbor if it is not already present, and we have the space for it
            if (!routeFound && routeCount != MAX_NUM_ROUTES) {

                addRoute(neighbors[i], neighbors[i], 1, DVR_TTL);   

                newNeighborfound = TRUE;

            } else if (routeCount == MAX_NUM_ROUTES) {

                dbg(ROUTING_CHANNEL, "Routing table full. Cannot add entry for node: %u\n", neighbors[i]);

            }

            routeFound = FALSE;

        }
        if (newNeighborfound) {

            update();

        }

    }

    //vargas this the big one. I did minor editing but nothing significant. this is the biggest threat
    //to secure covert operations. 
    
    // Skip the route for split horizon
    // Alter route table for poison reverse, keeping values in temp vars
    // Copy route onto array
    // Restore original route
    // Send packet with copy of partial routing table
    void update() {

        //setting up variables as necessary for the function
        // Send routes to all neighbors one at a time. Use split horizon, poison reverse
        uint32_t* neighbors = call NeighborDiscovery.getNeighbors();
        uint16_t neighborsListSize = call NeighborDiscovery.getNumNeighbors();
        uint8_t i = 0, j = 0, counter = 0;
        uint8_t temp;
        Route packetRoutes[5];
        bool isSwapped = FALSE;

        // Zero out the array
        for (i = 0; i < 5; i++) {

                packetRoutes[i].dest = 0;
                packetRoutes[i].nextHop = 0;
                packetRoutes[i].cost = 0;
                packetRoutes[i].ttl = 0;

        }

        // Send to every neighbor
        for (i = 0; i < neighborsListSize; i++) {

            while (j < routeCount) {

                //vargas no idea wtf this means
                // Split Horizon/Poison Reverse
                if (neighbors[i] == initializeTable[j].nextHop && STRATEGY == STRATEGY_SPLIT_HORIZON) {

                    temp = initializeTable[j].nextHop;

                    initializeTable[j].nextHop = 0;

                    isSwapped = TRUE;

                } else if (neighbors[i] == initializeTable[j].nextHop && STRATEGY == STRATEGY_POISON_REVERSE) {

                    temp = initializeTable[j].cost;

                    initializeTable[j].cost = MAX_COST;

                    isSwapped = TRUE;
                }

                // Add route to array to be sent out
                packetRoutes[counter].dest = initializeTable[j].dest;
                packetRoutes[counter].nextHop = initializeTable[j].nextHop;
                packetRoutes[counter].cost = initializeTable[j].cost;
                counter++;

                // If our array is full or we have added all routes then we send out packet with routes
                if (counter == 5 || j == routeCount-1) {

                    // make the packet to be sent
                    makePack(&packToRoute, TOS_NODE_ID, neighbors[i], 1, PROTOCOL_DV, 0, &packetRoutes, sizeof(packetRoutes));

                    // Send out packet
                    //vargas, this is using sender.send. dont know if that matters. Not sure if that means simple send
                    //or if it uses our flooding send, or a differnet send. 
                    call Sender.send(packToRoute, neighbors[i]);

                    // Zero out array
                    while (counter > 0) {

                        //vargas, possible use of --counter? or counter = counter -1?
                        counter--;
                        packetRoutes[counter].dest = 0;
                        packetRoutes[counter].nextHop = 0;
                        packetRoutes[counter].cost = 0;
                    }

                }

                // Restore the table
                if (isSwapped && STRATEGY == STRATEGY_SPLIT_HORIZON) {

                    initializeTable[j].nextHop = temp;

                } else if (isSwapped && STRATEGY == STRATEGY_POISON_REVERSE) {

                    initializeTable[j].cost = temp;

                }

                isSwapped = FALSE;
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