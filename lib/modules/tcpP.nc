#include "../../includes/DVR.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include <Timer.h>

//this section declares any global constants 

module tcpP{

    //declare interface being provided 
    provides interface tcp;

    //declare any interfaces used 
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface SimpleSend as Sender;
    uses interface NeighborDiscovery as NeighborDiscovery;
    uses interface DistanceVectorRouting as DistanceVectorRouting;
    uses interface Transport as Transport;
    uses interface Hashmap<uint8_t> as ConnectionMapping;

}

implementation{

    //what to do when the timer is fired
    event void Timer.fired(){


    }

    //these are the functions that this interface provides to other services

    //a function to perform a server connection test
    command void tcp.testServer(uint8_t port){

        //print about the listening
        dbg(TRANSPORT_CHANNEL, "   Node %u is now listening on port %u\n", TOS_NODE_ID, port);

        //grab a socket if there is one available 
        // fd = call Transport.socket();

        // //if there was a socket available, create the connection
        // if(*fd != NULL){

        //    //create the address for the socket and set it equal to current node
        //    socket_addr_t socketAddress;
        //    socketAddress.addr = (nx_uint8_t) TOS_NODE_ID; 
        //    socketAddress.port = port;

        //    //bind the socket to that address 
        //    call Transport.bind(fd, socketAddress);

        //    //start the timer 
        //    call TransportTimer.startOneShot(40000);

        // }


    }

    //a function to perform a client connection test
    command void tcp.testClient(uint8_t srcPort, uint8_t destination, uint8_t destPort, uint16_t num_bytes_to_transfer){

        //print about potential connection being created
        dbg(TRANSPORT_CHANNEL, "   Node %u is creating a connection on port %u to port %u on node %u, and will transfer %u bytes\n",TOS_NODE_ID, srcPort, destPort, destination, num_bytes_to_transfer);

        //grab a socket if there is one available
        // fd = call Transport.socket();

        // //if there was a socket available then proceed
        // if(fd != NULL){

        //    //grab the socket adddress to be the current node ID
        //    socket_addr_t socketAddress;
        //    socketAddress->port = (nx_uint8_t) TOS_NODE_ID; 

        //    //bind the socket to the address
        //    call Transport.bind(fd, socketAddress);

        //    socket_addr_t serverAddress = 

        // }

    }

    //a function to close a client connection
    command void tcp.closeClient(uint8_t srcPort, uint8_t destination, uint8_t destPort){

        //print about the impending connection close
        dbg(TRANSPORT_CHANNEL, "  Node %u is closing the connection on port %u to port %u at node %u\n", TOS_NODE_ID, srcPort, destPort, destination);


    }


}