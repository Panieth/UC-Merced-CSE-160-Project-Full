interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer(uint8_t port);
   event void setTestClient(uint8_t srcPort, uint8_t destination, uint8_t destPort, uint16_t num_bytes_to_transfer);
   event void clientClose(uint8_t srcPort, uint8_t destination, uint8_t destPort);
   event void setAppServer();
   event void setAppClient();
   event void printMessage(uint8_t *payload);
   //funtions for client application
   event void chatServerConnect(uint8_t *payload);
   event void chatBroadcast(uint8_t *payload);
   event void chatUnicast(uint8_t *payload);
   event void chatPrintUsers(uint8_t *payload);
}
