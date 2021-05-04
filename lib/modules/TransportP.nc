#include "../../includes/DVR.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
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

    //declarations for helper functions to be used by commands
    void initializeSocket(uint8_t fd);
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, void* payload, uint8_t length);
    

    //a constant to store the maximum number of ports 
    #define MAX_NUM_OF_PORTS 256

    //each node has to contain an array of sockets, one for each connection
    socket_store_t connections[MAX_NUM_OF_SOCKETS];

    //an array to store the status of the ports
    uint8_t ports[MAX_NUM_OF_PORTS];

    //a function to set up and begin the Transport layer
    command void Transport.begin(){

        //a variable to iterate over the sockets
        uint8_t i;

        //start the timer but only to go once
        call Timer.startOneShot(1024 * 60);

        //iterate over all of the sockets and initialize them
        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){

            //initialize the current socket + 1;
            initializeSocket(i + 1); //adding +1 due to the shifting of the indices
                                    //which then allow us to use 0 as a fail signal

        }

        //initialize port array to 0
        for(i = 0; i < MAX_NUM_OF_PORTS; i++){

            //set current port to 0
            ports[i] = 0;

        }

    }

    //what to do when the timer is fired
    event void Timer.fired() {
        
        //upon first fired state we are starting tcp
        if(call Timer.isOneShot()){

            //state we began tcp for current node
            dbg(TRANSPORT_CHANNEL, "Starting TCP for %u\n", TOS_NODE_ID);

            //start a timer to go periodically
            call Timer.startPeriodic((uint16_t)(call Random.rand16() % 1000) + 1024);

        }

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



   /**
    * Checks to see if there are socket connections to connect to and
    * if there is one, connect to it.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting an accept. remember, only do on listen. 
    * @side Server
    * @return socket_t - returns a new socket if the connection is
    *    accepted. this socket is a copy of the server socket but with
    *    a destination associated with the destination address and port.
    *    if not return a null socket.
    */
    command socket_t Transport.accept(socket_t fd){

        //a variable to iterate
        uint8_t i;
        uint8_t chosenConnection;

        //once again we will ensure that the socket is valid
        if(fd > MAX_NUM_OF_SOCKETS || fd == 0){

            //if fd is greater than the maximum possible sockets or it is
            //equal to zero then the socket number is not valid
            return 0; //return zero, an invalid socket_t

        }

        //iterate over all the potential sockets
        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){

            //if we find a connection that is not empty then we can proceed to connect
            if(connections[fd - 1].connections[i] != 0){

                //chose the connection found at i
                chosenConnection = connections[fd - 1].connections[i];

                //move the connections in the socket to the left
                for(i = i; i < MAX_NUM_OF_SOCKETS - 1; i++){

                    if(connections[fd - 1].connections[i] == 0){

                        break;

                    }else{

                        connections[fd -1].connections[i - 1] = connections[fd -1].connections[i];

                    }

                }

                //now that we have moved the entries left
                //set the remaining entry to zero
                connections[fd - 1].connections[i - 1] = 0;

                //we can now return the number corresponding to the connection
                return (socket_t) chosenConnection;

            }

        }

        //if no connection was chosen above then we must now return failure
        return 0;

    }



   /**
    * Write to the socket from a buffer. This data will eventually be
    * transmitted through your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a write.
    * @param
    *    uint8_t *buff: the buffer data that you are going to wrte from.
    * @param
    *    uint16_t bufflen: The amount of data that you are trying to
    *       submit.
    * @Side For your project, only client side. This could be both though.
    * @return uint16_t - return the amount of data you are able to write
    *    from the pass buffer. This may be shorter then bufflen
    */
    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){

        //a variable to keep track of the total number of bytes we have written so far
        uint16_t totalBytesWritten = 0; 

        //once again we will ensure that the socket is valid
        if(fd > MAX_NUM_OF_SOCKETS || fd == 0){

            //if the socket is invalid then we cannot write
            return 0;

        }

        //iterate over the potential bytes written 
        while(totalBytesWritten < SOCKET_BUFFER_SIZE){


            //increment the bytes written
            totalBytesWritten++;

        }


        return totalBytesWritten;

    }



   /**
    * This will pass the packet so you can handle it internally. 
    * @param
    *    pack *package: the TCP packet that you are handling.
    * @Side Client/Server 
    * @return uint16_t - return SUCCESS if you are able to handle this
    *    packet or FAIL if there are errors.
    */
    command error_t Transport.receive(pack* package){

        uint8_t fd;

        //turn the ip packet we are receiving into a tcp packet
        tcpPacket* tPack = (tcpPacket*) &package->payload;



        //handle each case depending on the content of the flag 
        switch(tPack->tcpFlag){

            case DATA:

                //find the socket fd that we need to grab associated content
                fd = call SocketMapping.get(tPack->destPort);

                //now we have to go over the possible states 
                

                if(connections[fd - 1].state == SYN_RCVD){

                    //we can print that we have established the connection
                    dbg(TRANSPORT_CHANNEL, "Connection succesfully established...\n");

                    //update the state accordingly 
                    connections[fd - 1].state = ESTABLISHED;

                    //return success
                    return SUCCESS;
                }

                if(connections[fd - 1].state == ESTABLISHED){

                    //we have succeeded
                    return SUCCESS;

                }

                break;

            case ACK:
                
                //find the socket fd that we need to grab associated content
                fd = call SocketMapping.get(tPack->destPort);

                break;

            case SYN:

                //find the socket fd that we need to grab associated content
                fd = call SocketMapping.get(tPack->destPort);

                break;

            case SYNACK:

                //find the socket fd that we need to grab associated content
                fd = call SocketMapping.get(tPack->destPort);

                break;

            case FIN:

                //find the socket fd that we need to grab associated content
                fd = call SocketMapping.get(tPack->destPort);

                break;

            case FINACK:

                //find the socket fd that we need to grab associated content
                fd = call SocketMapping.get(tPack->destPort);

                break;

            default:

                dbg(TRANSPORT_CHANNEL, "Incorrect TCP flag, not supported, ending....\n");
                //at this point we can deem faulure, flag matched no cases  
                return FAIL;
                break;


        }


        


    }



   /**
    * Read from the socket and write this data to the buffer. This data
    * is obtained from your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a read.
    * @param
    *    uint8_t *buff: the buffer that is being written.
    * @param
    *    uint16_t bufflen: the amount of data that can be written to the
    *       buffer.
    * @Side For your project, only server side. This could be both though.
    * @return uint16_t - return the amount of data you are able to read
    *    from the pass buffer. This may be shorter then bufflen
    */
    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){

        uint16_t bytesRead;

        //once again we will ensure that the socket is valid
        if(fd > MAX_NUM_OF_SOCKETS || fd == 0){

            //if fd is greater than the maximum possible sockets or it is
            //equal to zero then the socket number is not valid
            return 0;

        }

        //iterate over buffer length
        while(bytesRead < bufflen){

            //update the last read we did 
            //ensure it is within the range 
            if(connections[fd - 1].lastRead >= SOCKET_BUFFER_SIZE){

                //if it is out of range set last read to 0
                connections[fd - 1].lastRead = 0;

            }

            //if still valid 
            connections[fd - 1].lastRead++;


        }

        //return the bytes we read
        return bytesRead;

    }



   /**
    * Attempts a connection to an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are attempting a connection with. 
    * @param
    *    socket_addr_t *addr: the destination address and port where
    *       you will atempt a connection.
    * @side Client
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a connection with the fd passed, else return FAIL.
    */
    command error_t Transport.connect(socket_t fd, socket_addr_t * addr){

               //once again we will ensure that the socket is valid
        if(fd > MAX_NUM_OF_SOCKETS || fd == 0){

            //if fd is greater than the maximum possible sockets or it is
            //equal to zero then the socket number is not valid
            return FAIL;

        }

        //add the destination address to the socket info
        connections[fd - 1].dest.addr = addr->addr;
        connections[fd - 1].dest.port = addr->port;

        //add socket to the socket map
        call SocketMapping.insert(addr->addr, fd);

        //at this point we have succeeded
        return SUCCESS;

    }



   /**
    * Closes the socket.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are closing. 
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
    command error_t Transport.close(socket_t fd){

        call Transport.release(fd);

        return SUCCESS;

    }



   /**
    * A hard close, which is not graceful. This portion is optional.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing. 
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
    command error_t Transport.release(socket_t fd){

        //once again we will ensure that the socket is valid
        if(fd > MAX_NUM_OF_SOCKETS || fd == 0){

            //if fd is greater than the maximum possible sockets or it is
            //equal to zero then the socket number is not valid
            return FAIL;

        }

        //because our socket is valid, and we want to close in a non 
        //graceful manner, simply initialize the socket again
        initializeSocket(fd);
        return SUCCESS;

    }



   /**
    * Listen to the socket and wait for a connection.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing. 
    * @side Server
    * @return error_t - returns SUCCESS if you are able change the state 
    *   to listen else FAIL.
    */
    command error_t Transport.listen(socket_t fd){

        //once again we will ensure that the socket is valid
        if(fd > MAX_NUM_OF_SOCKETS || fd == 0){

            //if fd is greater than the maximum possible sockets or it is
            //equal to zero then the socket number is not valid
            return FAIL;

        }

        //check to see if the socket is bound
        if(connections[fd - 1].state == BOUND){

            //now we can change the state to listening, since the 
            //socket is bound
            connections[fd - 1].state = LISTEN;

            //because the state was changed to liste, returns success
            return SUCCESS;

        }else{

            //if the state is not already bound then we cannot listen
            //return failure
            return FAIL;

        }

    }


    //helper functions to assist the commands declared above

    //a function to initialize, or reinitialize the given socket 
    void initializeSocket(uint8_t fd){

        //a variable to iterate and store temp numbers
        uint8_t i;

        //set every socket_store_t parameter to zero or to closed state

        //set the flag and state to closed
        connections[fd - 1].flag = 0;
        connections[fd - 1].state = CLOSED;

        //destroy source port and addressess
        connections[fd - 1].src.addr = 0;
        connections[fd - 1].src.port = 0;

        //destroy destination port and addressess
        connections[fd - 1].dest.addr = 0;
        connections[fd - 1].dest.addr = 0;

        //iterate over the size of the socket buffers
        for(i = 0; i < SOCKET_BUFFER_SIZE; i++){

            //set current index of both buffers to zero
            connections[fd - 1].sendBuff[i] = 0;
            connections[fd - 1].rcvdBuff[i] = 0;

        }

        //set the RTT to an arbitrary large number 
        connections[fd - 1].RTT = 750;

        //there is no effective window yet so set it to 0
        connections[fd - 1].effectiveWindow = 0;

        //initialize sender variables
        connections[fd - 1].lastWritten = 0;
        connections[fd - 1].lastAck = 0;
        connections[fd - 1].lastSent = 0;

        //initialize receiver variables
        connections[fd - 1].lastRead = 0;
        connections[fd - 1].lastRcvd = 0;
        connections[fd - 1].nextExpected = 0;


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