#include "../../includes/packet.h"
#include "../../includes/socket.h"

//An interface for the chat application
interface ChatApp{

    //a function to set up and begin the chat application
    command void begin();

    //a function to connect to the server
    command void serverConnect(uint8_t dest);

    //a function to broadcast a message
    command void broadcast(uint8_t dest, uint8_t* message);

    //a function to unicast a message
    command void unicast(uint8_t dest, uint8_t* message);

    //a function to print the users connected to a server
    command void printUsers(uint8_t dest);

}
