//a file for flooding implementation stuff

module FloodingP{  
    provides interface Flooding;
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

}
