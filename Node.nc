/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/protocol.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   //uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   //add interfaces for fooding and neighbor discovery and DVR
   uses interface Flooding;
   uses interface NeighborDiscovery as NeighborDiscovery;
   uses interface DistanceVectorRouting as DistanceVectorRouting;
   uses interface Transport as Transport; 
}

implementation{
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");

      //begin neighbor discovery
      call NeighborDiscovery.begin();

      //begin distance vector routing
      call DistanceVectorRouting.begin();

      //begin the transport layer service
      call Transport.begin();
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      //first implementation using basic simplesend

      // dbg(GENERAL_CHANNEL, "Packet Received\n");
      // if(len==sizeof(pack)){
      //    pack* myMsg=(pack*) payload;
      //    dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
      //    return msg;
      // }
      // dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      // return msg;
      
      //create the package 
      pack* message = (pack*)payload;

      //if the length does not match the packet then its unknown
      if(len != sizeof(pack)){
         dbg(GENERAL_CHANNEL, "Uknown packet type %d\n");
      }else if(message->dest == 0){
         //if message dest is 0 then run neighbor discovery 
         call NeighborDiscovery.discoveryPacketReceived(message);
      }else if(message->protocol == PROTOCOL_DV){
         
         //if the packet was already routed check for any updates
         call DistanceVectorRouting.checkForUpdates(message);

      }else{
         
         //call Flooding.flood(message);

         //no longer using flooding so commented it out
         //now we will handle the traversal of the packet
         //using distance vector routing 

         call DistanceVectorRouting.route(message);

      }
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      //dbg(GENERAL_CHANNEL, "PING EVENT \n");
      //makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      //call Sender.send(sendPackage, destination);
      //no longer using flooding 
      //call Flooding.sendPing(destination, payload);

      //now use the DVR send ping function instead,
      call DistanceVectorRouting.sendPing(destination, payload);
   }

   event void CommandHandler.printNeighbors(){
      call NeighborDiscovery.printAllNeighbors();
   }

   event void CommandHandler.printRouteTable(){
      //call the print route table from DVR component
      call DistanceVectorRouting.printRoutingTable();
   }

   event void CommandHandler.printMessage(uint8_t *payload) {
         //print the payload 
        dbg(GENERAL_CHANNEL, "%s\n", payload);
    }

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(uint8_t port){

      //grab a socket if there is one available 
      // fd = call Transport.socket();

      // //if there was a socket available, create the connection
      // if(*fd != NULL){

      //    //create the address for the socket and set it equal to current node
      //    socket_addr_t socketAddress;
      //    socketAddress->port = (nx_uint8_t) TOS_NODE_ID; 

      //    //bind the socket to that address 
      //    call Transport.bind(fd, socketAddress);

      //    //start the timer 
      //    call TransportTimer.startOneShot(40000);

      // }

      //print about the listening
      dbg(TRANSPORT_CHANNEL, "   Node %u is now listening on port %u\n", TOS_NODE_ID, port);


   }

   event void CommandHandler.setTestClient(uint8_t srcPort, uint8_t destination, uint8_t destPort, uint16_t num_bytes_to_transfer){

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

      //print about potential connection being created
      dbg(TRANSPORT_CHANNEL, "   Node %u is creating a connection on port %u to port %u on node %u, and will transfer %u bytes\n",TOS_NODE_ID, srcPort, destPort, destination, num_bytes_to_transfer);

      

   }

   event void CommandHandler.clientClose(uint8_t srcPort, uint8_t destination, uint8_t destPort){

      //print about the impending connection close
      dbg(TRANSPORT_CHANNEL, "  Node %u is closing the connection on port %u to port %u at node %u\n", TOS_NODE_ID, srcPort, destPort, destination);


   }

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
