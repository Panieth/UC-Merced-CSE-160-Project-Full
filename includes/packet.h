//Author: UCM ANDES Lab
//$Author: abeltran2 $
//$LastChangedBy: abeltran2 $

#ifndef PACKET_H
#define PACKET_H


# include "protocol.h"
#include "channels.h"

enum{
	PACKET_HEADER_LENGTH = 8,
	PACKET_MAX_PAYLOAD_SIZE = 28 - PACKET_HEADER_LENGTH,
	MAX_TTL = 22
};


typedef nx_struct pack{
	nx_uint16_t dest;
	nx_uint16_t src;
	nx_uint16_t seq;		//Sequence Number
	nx_uint8_t TTL;		//Time to Live
	nx_uint8_t protocol;
	nx_uint8_t payload[PACKET_MAX_PAYLOAD_SIZE];
}pack;


//enumerate the possible tcp flags
enum tcpFlags{

	//give each flag a corresponding number similar to the regular 
	//packet types
	DATA = 0,
	ACK = 1,
	SYN = 2,
	SYNACK = 3,
	FIN = 4,
	FINACK = 5

};


//a packet for tcp purposes (project 3)
typedef nx_struct tcpPacket{

	nx_uint8_t srcPort; //store associated ports
	nx_uint8_t destPort;

	nx_uint16_t seqNum; //numbers associated to current packet
	nx_uint16_t ackNum;

	nx_uint8_t tcpFlag;
	nx_uint8_t advertisedWindow;
	nx_uint8_t length;

	nx_uint16_t tcpPayload[5]; //payload of the packet


}tcpPacket;


/*
 * logPack
 * 	Sends packet information to the general channel.
 * @param:
 * 		pack *input = pack to be printed.
 */
void logPack(pack *input){
	dbg(GENERAL_CHANNEL, "Src: %hhu Dest: %hhu Seq: %hhu TTL: %hhu Protocol:%hhu  Payload: %s\n",
	input->src, input->dest, input->seq, input->TTL, input->protocol, input->payload);
}

enum{
	AM_PACK=6
};

#endif
