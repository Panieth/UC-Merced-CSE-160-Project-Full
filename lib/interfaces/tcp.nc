//a file to provdide the interface for tcp

#include "../../includes/packet.h" 
#include "../../includes/socket.h"

interface tcp{
   
   //these are the functions that will be called to run server commands
   command void testServer(uint8_t port);
   command void testClient(uint8_t srcPort, uint8_t destination, uint8_t destPort, uint16_t num_bytes_to_transfer);
   command void closeClient(uint8_t srcPort, uint8_t destination, uint8_t destPort);
   
}
