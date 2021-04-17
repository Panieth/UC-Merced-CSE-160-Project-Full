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

}

implementation{


    //socket structure to store state of the socket
    // typedef struct{

    //     //stores the sequence number of the socket
    //     uint16_t sequenceNum;

    //     socket_store_t stateFile; 


    // }socket_t;


    //each node has to contain an array of sockets, one for each connection
    socket_t connections[MAX_NUM_OF_SOCKETS];


    //what to do when the timer is fired
    event void Timer.fired() {
        

    }


    //main functions provided as an interface to other files

    command socket_t Transport.socket(){

        //return NULL; 

    }


    command error_t Transport.bind(socket_t fd, socket_addr_t *addr){


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