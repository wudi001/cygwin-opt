#include "Changechannel.h"

generic configuration ChangechannelC(am_id_t amId) {
  provides {
    interface AMSend;
	interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements as Acks;
    
	interface Receive;
	 }
  uses {
   // interface Receive[uint8_t client];
     // interface Receive as SubReceive;
      interface CtpPacket;
	  interface CtpInfo;
	
  }
}

implementation {
    enum {
    
    CHANNEL_COUNT = 16,
  };
	
	components ChangechannelP as ChChannel;
	     
		 Receive=ChChannel.Receive;
	
	components new AMSenderC(amId) as ChAMSender;

		AMSend = ChChannel.AMSend;
		ChChannel.SubSend -> ChAMSender;
		
		Packet = ChAMSender;
		AMPacket = ChAMSender;
		Acks = ChAMSender;
		ChChannel.SubAcks->ChAMSender;
		ChChannel.AMPacket->ChAMSender;
		ChChannel.CtpPacket=CtpPacket;
		ChChannel.CtpInfo=CtpInfo;
		
	
	components new AMReceiverC(amId) as ChAMReceiver;
		ChChannel.SubReceive ->ChAMReceiver.Receive;
	      
	   //wu process channel AMSenderC	
	
	   //components new CtpForwardingEngineP() as ChChannelFe;
	   
		
	components new PoolC(uint8_t, CHANNEL_COUNT) as ChannelPoolP;
	      ChChannel.ChannelPool -> ChannelPoolP;
		  
	components CC2420ControlC;
	ChChannel.CC2420Config->CC2420ControlC.CC2420Config;
	
	components RandomC;
	ChChannel.Random -> RandomC;
	
	/*components new AMSenderC(TYPE_ACK) as AckSender;
	components new AMReceiverC(TYPE_ACK) as AckReceiver;
	ChChannel.AckAcks->AckSender.Acks;
	ChChannel.AckPacket -> AckSender.Packet;
  	//ChChannel.AckAMPacket->AckSender.AMPacket;
  	ChChannel.AMAckSend -> AckSender.AMSend;
	ChChannel.Ack_Receive -> AckReceiver.Receive;*/
	
	components new QueueC(uint8_t, QUEUE_SIZE) as ChannelQueueP;
    ChChannel.ChannelQueue -> ChannelQueueP;
	
	/*components new TimerMilliC () as Timer0;
	ChChannel.Timer0 ->Timer0;*/

	components ActiveMessageC as AM;
    ChChannel.AMAckSend->AM.AMAckSend[TYPE_ACK];
	ChChannel.AckPacket -> AM.Packet;
	ChChannel.AckAcks->AM.PacketAcknowledgements;
	ChChannel.Ack_Receive -> AM.Receive[TYPE_ACK];

	components CC2420PacketC;
	ChChannel.CC2420PacketBody -> CC2420PacketC;
	
	components CC2420ActiveMessageC_Mac;
	ChChannel.CcaControl->CC2420ActiveMessageC_Mac.CcaControl;
	
	components CC2420ReceiveP;
	ChChannel.CC2420Acksend->CC2420ReceiveP.CC2420Acksend;
	
	}