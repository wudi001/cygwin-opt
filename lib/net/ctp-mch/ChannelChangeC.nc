#include <channelChg.h>

configuration ChannelChangeC{
provides {
interface ChannelChange;
}

}
implementation{
	components ChannelChangeP;
	components CC2420ControlC;

	components MainC;
	ChannelChangeP.Boot->MainC;

	ChannelChange=ChannelChangeP;
	ChannelChangeP.CC2420Config->CC2420ControlC;

	components new TimerMilliC() as Timer2;
	ChannelChangeP.Timer2 -> Timer2;

	components ActiveMessageC as AM;

	components new AMSenderC(130) ;
	components new AMReceiverC(130) ;
	ChannelChangeP.AMSend->AMSenderC;
	ChannelChangeP.Receive->AMReceiverC;
	ChannelChangeP.Packet->AM;
	ChannelChangeP.AMPacket->AM;
	ChannelChangeP.PacketAcknowledgements->AMSenderC;

}
