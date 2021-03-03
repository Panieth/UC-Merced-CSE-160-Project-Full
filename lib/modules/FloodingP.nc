//a file for flooding implementation stuff

//include neccesary files 
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include <Timer.h>
#include "../../includes/channels.h"

module FloodingP{  
    provides interface Flooding;

    //declare interfaces being used
    uses interface Hashmap<uint16_t> as PacketsSeen;
    uses interface SimpleSend as Sender; 
}

implementation{
    //code for implementation goes here 

    //we need own flooding header information, should include:
    // 1. source address of the node initiating the flood
    // 2. monotonically increasing sewuence number to identify packet
    // 3. a TTL field to avoid looping forever 

    //reccomended to add link layer module with source and destination addressess 

    //have a node table, one entry per node

    //cache to store largest sequence number seen from any node's flood 

    //one flood packet per link, send to each neighbor

    //nodes use cache to check for duplicates

    //neighbor discovery 

        //send 1 packet to each neighbor
        //dont send to neighbor you received from

    //declare all necessary variables 

    //a variable to store the package to be initialized and sent
    pack packageToSend;

    //a variable to store the current sequence number to be used for packets
    uint16_t currSequenceNum = 0;

    //function declarations for helper functions 
     void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
     void payloadReceived(pack *message);
    //two main functions which can be used by other interfaces 

    //a function to handle the sending of flooding pings 
    command void Flooding.sendPing(uint16_t destinationNode, uint8_t *payload){

        //make relevant print statements to the debug channel 
        dbg(FLOODING_CHANNEL, "Ping event started\n");
        dbg(FLOODING_CHANNEL, "From sender: %d\n", TOS_NODE_ID);
        dbg(FLOODING_CHANNEL, "To destination: %d\n", destinationNode);
        

        //make a packet for this ping and send it
        makePack(&packageToSend, TOS_NODE_ID, destinationNode, 22, PROTOCOL_PING, currSequenceNum, payload, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(packageToSend, AM_BROADCAST_ADDR);

        //increment the sequence number 
        currSequenceNum++;
    }

    command void Flooding.flood(pack* message){
        //check if the packet has already been seen 
        if(call PacketsSeen.contains(message->src)){    //could also search for the seq key
            //drop the packet
            dbg(FLOODING_CHANNEL, "Packet has been previously seen, Dropping it....\n");
        }else if(message->dest == TOS_NODE_ID){
            //if the destination node is currrent node then the packet has been recieved 
            payloadReceived(message);
        }else if(message->TTL == 0){
            //if the messages time to live has expired print such
            dbg(FLOODING_CHANNEL, "Message TTL has ezxpired...\n");
        }else{
            //at this point the message must be forwarded 

            //decrement the time to live
            message->TTL = message->TTL - 1;

            //insert the packet into the seen list
            call PacketsSeen.insert(message->src, message->seq); //////////////////////

            //resend the packet
            call Sender.send(*message, AM_BROADCAST_ADDR);

            dbg(FLOODING_CHANNEL, "Packet has been forwarded...\n");
        }
    }

    //helper functions to assist above two functions

    //a function to handle a packet when its payload is received at the correct node
    void payloadReceived(pack *message){
        if(message->protocol == PROTOCOL_PING){

            dbg(FLOODING_CHANNEL, "Ping has been received!\n");
            dbg(FLOODING_CHANNEL, "Package Payload: %s\n", message->payload); //added to see payload contents
            //log the packet 
            logPack(message);
            //add the packet to the seen list
            call PacketsSeen.insert(message->src, message->seq);

            //make a new packet and send as ping reply
            makePack(&packageToSend, message->dest, message->src, MAX_TTL, PROTOCOL_PINGREPLY, currSequenceNum++, (uint8_t*)message->payload, PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(packageToSend, AM_BROADCAST_ADDR);
            dbg(FLOODING_CHANNEL, "Sent Pingreply!");

        }else if(message->protocol == PROTOCOL_PINGREPLY){
            dbg(FLOODING_CHANNEL, "Pingreply has been received!\n");
            //log the packet
            logPack(message);
            //add the packet to the seen list
            call PacketsSeen.insert(message->src, message->seq);
        }
    }

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
