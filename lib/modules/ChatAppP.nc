#include "../../includes/DVR.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include <Timer.h>

//this section declares any global constants 

module ChatAppP{

    //declare interface being provided 
    provides interface ChatApp;

    //declare any interfaces used 
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface SimpleSend as Sender;
    uses interface NeighborDiscovery as NeighborDiscovery;
    uses interface DistanceVectorRouting as DistanceVectorRouting;
    uses interface Hashmap<uint8_t> as userMap;

}

implementation{

    //declarations for helper functions to be used by commands
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, void* payload, uint8_t length);
    

    //a function to set up and begin the Transport layer
    command void ChatApp.begin(){

        // start the timer 
        call Timer.startOneShot(1024 * 60);

    }

    //what to do when the timer is fired
    event void Timer.fired() {
        
        //whenever the timer is fired just restart it 
        call Timer.startOneShot(1024 * 60);

    }


    //main functions provided as an interface to other files

    //a function to connect to the server
    command void ChatApp.serverConnect(uint8_t dest){

        //the server will always start on node 1, thus we will establish two connections
        //to node 1
        


    }

    //a function to broadcast a message
    command void ChatApp.broadcast(uint8_t dest, uint8_t *message){

        //variables to iterate 
        uint16_t i;

        //a variable to store number of users
        uint16_t numUsers;

        //this is the packet we will send to every user
        tcpPack messagePack;
        
        //stores the current user we are on
        uint16_t currentUserId;

        //to broadcast the message we have to first get the keys to the user map
        //this will result in a list of users 
        uint32_t* users = call userMap.getKeys(); 

        //also get the number of users from the usermap
        numUsers = call userMap.size();

        //configure the source of the packet
        messagePack.srcPort = TOS_NODE_ID;

        //copy the message we want to send into the packet
        memcpy(messagePack.tcpPayload, message, 225);


        //now iterate over every single user and send them the message
        for(i = 0; i < numUsers; i++){

            //get the current user destination id from the userMap
            currentUserId = call userMap.get(users[i]);

            //configure the destination of the packet
            messagePack.destPort = currentUserId;

            //now we can send this tcp packet to the relevant user
            call commandHandler.ping(currentUserId, messagePack);

        }

    }

    //a function to unicast a message
    command void ChatApp.unicast(uint8_t dest, uint8_t *message){

        //this is the packet we will send to every user
        tcpPack messagePack;
        
        //stores the id of the user we will unicast to
        uint16_t userId;

        //configure the source of the packet
        messagePack.srcPort = TOS_NODE_ID;

        //copy the message we want to send into the packet
        memcpy(messagePack.tcpPayload, message, 225);
        
        //get the current user destination id from the userMap
        currentUserId = call userMap.get(dest);

        //configure the destination of the packet
        messagePack.destPort = currentUserId;

        //now we can send this tcp packet to the relevant user
        call commandHandler.ping(currentUserId, messagePack);

    }

    //a function to print the users connected to a server
    command void ChatApp.printUsers(uint8_t dest){

        //in order to grab the users we will take the keys from the user map
        uint32_t* users = call userMap.getKeys(); 

        /*
        //a packet to send the users to the client that requested them
        tcpPack userPacketToSend;

        //set the source and dest to the correct values
        userPacketToSend.destPort = dest;
        userPacketToSend.srcPort = TOS_NODE_ID;

        //now set the payload to be the user list we got
        memcpy(userPacketToSend.tcpPayload, users, 225); //since this is the number of connections


        //send the packet containing the user information
        sendPing(dest, userPacketToSend);

        dbg(TRANSPORT_CHANNEL, "Sending users\n");

        */

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