#include "../../includes/DVR.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include <Timer.h>

//this section declares any global constants 

module TransportP{

    //declare interface being provided 
    provides interface Transport;

    //declare any interfaces used 
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface SimpleSend as Sender;
    uses interface NeighborDiscovery as NeighborDiscovery;
    uses interface DistanceVectorRouting as DistanceVectorRouting;
    uses interface Hashmap<uint8_t> as SocketMapping;

}

implementation{

    //a constant to store the maximum number of ports 
    #define MAX_NUM_OF_PORTS 256

    //each node has to contain an array of sockets, one for each connection
    socket_store_t connections[MAX_NUM_OF_SOCKETS];

    //an array to store the status of the ports
    uint8_t ports[MAX_NUM_OF_PORTS];

    //what to do when the timer is fired
    event void Timer.fired() {
        

    }


    //main functions provided as an interface to other files

   /**
    * Get a socket if there is one available.
    * @Side Client/Server
    * @return
    *    socket_t - return a socket file descriptor which is a number
    *    associated with a socket. If you are unable to allocated
    *    a socket then return a NULL socket_t.
    */
    command socket_t Transport.socket(){

        
        //variavble to iterate
        uint8_t i;

        //iterate over all of the possible connections
        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){

            //look for the first connection that is not in use
            if(connections[i].state == CLOSED){

                //update the state of the connection to open, as we will 
                //now attempt to open a connection
                connections[i].state = OPEN;

                //return the index of the state + 1, this is because,
                //we will return 0 as failure, since we cant return -1,
                //because we are using usnigned ints
                return (socket_t)(i + 1);

            }

        }

        //at this point there is no closed connections we can open, return 0
        return 0;

    }

   /**
    * Bind a socket with an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       you are binding.
    * @param
    *    socket_addr_t *addr: the source port and source address that
    *       you are biding to the socket, fd.
    * @Side Client/Server
    * @return error_t - SUCCESS if you were able to bind this socket, FAIL
    *       if you were unable to bind.
    */
    command error_t Transport.bind(socket_t fd, socket_addr_t *addr){

        //first, check that fd is in correct range,
        //if it is not then we must return a failure
        if(fd > MAX_NUM_OF_SOCKETS || fd == 0){

            //if fd is greater than the maximum possible sockets or it is
            //equal to zero then the socket number is not valid
            return FAIL;

        }

        //ensure that the given socket is open and port not in use 
        if(ports[addr->port] < 1 && connections[fd - 1].state == OPEN){
            
            //now we can bind the parammeters associated with the socket_addr
            //to the given socket fd 
            connections[fd - 1].src.addr = addr->addr;
            connections[fd - 1].src.port = addr->port;
            
            //now we need to update the socket state to bound
            connections[fd - 1].state = BOUND;

            //update the port number as used
            ports[addr->port] = ports[addr->port] + 1;

            //we can now also add the socket to the socket map
            call SocketMapping.insert(addr->addr, fd);

            //we have succesfully bound the socket to a port
            return SUCCESS;

        }else{

            //if the socket was not open or the port was in use then we failed to bind
            return FAIL;

        }   

    }

    command socket_t Transport.accept(socket_t fd){


    }

    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){


    }

    command error_t Transport.receive(pack* package){


    }

    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){


    }

    command error_t Transport.connect(socket_t fd, socket_addr_t * addr){


    }

    command error_t Transport.close(socket_t fd){


    }

    command error_t Transport.release(socket_t fd){


    }

    command error_t Transport.listen(socket_t fd){


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