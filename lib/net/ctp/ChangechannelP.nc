//#include <Changechannel.h>
#include "CC2420.h"
#include "crc.h"
#include "message.h"

#include "CC2430_CSP.h"
module ChangechannelP{
    provides {
    	
	interface ProChannel;
	interface AMSend;
	interface Receive;
	
    }
	
	uses {
	//interface Timer<TMilli> as Timer0;
	
	interface UnicastNameFreeRouting;
	
    interface AMSend as SubSend;
	interface PacketAcknowledgements as SubAcks;
	interface AMPacket;
	interface CtpPacket;
	interface Receive as SubReceive;
	interface Pool<uint8_t> as ChannelPool;
	interface CC2420Config;
	interface Random;
	interface CtpInfo;
	
	/*interface AMPacket as AckAMPacket;*/
	//interface AMSend as AMAckSend;
	interface AMAckSend;
	
	interface Receive as Ack_Receive;
	
	interface Packet as AckPacket;
	interface PacketAcknowledgements as AckAcks;
	interface Queue<uint8_t> as ChannelQueue;
	
	interface CC2420PacketBody;
	interface CcaControl[am_id_t amId];
	interface CC2420Acksend;
  }
}
implementation{
	

	uint8_t usechal=DEFCHANNEL;
	
	bool busy;
	bool stopcca=FALSE;
	bool changecca;
	uint8_t flag=1;
	uint8_t blacklist[16]={0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
	
	int n = sizeof(blacklist) / sizeof(blacklist[0]);
	uint8_t Selectchannel();
	message_t pkt;
	
	channel_info_Table channelTable[CHANNEL_TABLE_SIZE];
	uint8_t proability(uint8_t val);
	void immechange(uint8_t channel);
	//void savechannel(uint8_t channel);
	message_t* Ackmsg;
	uint8_t Acklen;

	
	//task void CoordinateChannelTask(message_t* msg,uint8_t len);
	void CoordinateChannel(message_t* msg,uint8_t len);
	//void acksendcca( message_t *cca_msg, bool cca );
	/*task void CoordinateChannelTask(msg, len)
	{
		CoordinateChannel(msg,len);
	}*/
	
	
	void immechange(uint8_t channel){
		call CC2420Config.setChannel(channel);
	
	}
	
	
		
	uint8_t proability(uint8_t val){
		 uint16_t curval;
		 uint16_t inval;
		 uint16_t r2;
		 uint16_t r3;
		 r2 = call Random.rand16();
		 r3=r2>>8;
		 curval=(usechal-0x0A)*0x10;
		 inval=(val+1)*0x10-curval;
		 //r3=r3+1-inval;
		 if (r3+1>=inval)
		 {
		   return Selectchannel();
		 }
		 else{
		     return val;
		 }
	 }
	 /*---选择信道---*/
	uint8_t  Selectchannel(){
		uint8_t i;
        uint8_t arrnum;		
		uint8_t  r1;
		uint16_t  r;
		
		uint8_t arr[]={0x0B,0x0C,0x0D,0x0E,0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A};
		/*uint8_t lastchal;
		uint8_t llastchal;
		uint8_t testnum;
		uint8_t num;
		uint8_t* tain;
		uint8_t* obtain;*/
		//uint16_t r = call Random.rand16();
		//uint8_t channel=(int)(r>>12);
		//call ChannelPool.put(&channel);
		//call ChannelQueue.enqueue(&channel);
		/*for (i=1;i<=16;i++){
		    obtain=call ChannelPool.get();
			obtain=&arr[i];
			call ChannelPool.put(obtain);
		}
		//num=call ChannelPool.size();
		tain=call ChannelPool.get();
		num=*tain;*/
		/* 输出全部转换为0 */
		//return channel+0x0B;
		/*return num;
		//num可能输出数组中以外的东西来比如00.09.05.08*/
		
		for (i=1;i<=n;i++)
		{   
			call ChannelQueue.enqueue(arr[i]);
		}
		r = call Random.rand16();
		r1=r>>12;
		// usechal=call ChannelQueue.element(r1);
		 /*----BlackQueue ----*/
		arrnum=0;
		 for (i=0;i<n;i++) {
			if (blacklist[i] != 0) {
				arrnum++;
			}
		}
		while (arrnum >= n - 6) {
			for (i = 0; i <=n- 6; i++) {
			  if (i < n - 6) {
				blacklist[i] = blacklist[i + 1];
			    }
				else {
				blacklist[i] = 0;
			    }
			}
			arrnum -=1;			
		}
		for (i=0;i<n;i++)
		   { 		   
		   if (blacklist[i]==r1){
			  return Selectchannel();
			  // ADBG(100, "1 is %i\r\n", ADBG_N(sizeof(blacklist)));
			 }
		    }
		blacklist[arrnum] = r1;
		
		usechal=call ChannelQueue.element(proability(r1));
		
		/*testnum=0;
		if (usechal<0x0B || usechal>0x1A||usechal==llastchal||usechal==lastchal)
		     {
			 return Selectchannel();
	          }
			  blacklist[j]=usechal;
			  testnum=j;*/
		if (usechal<0x0B || usechal>0x1A)
		     {
			 return Selectchannel();
	          }
		
		return usechal;
		//num可能输出数组中以外的东西来比如00.09.05.08
	}
		
		
	command void ProChannel.setchannel(){
	   
		
		
	}

     command void ProChannel.getChannel(){
		
	 
	 }
	 command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	    /*uint8_t re_channel;
		uint8_t i;
		uint8_t testlen1;
		error_t subsendResult;
		bool sbusy=FALSE;
		  if ( flag==1 )
		  	{   
				subsendResult=call SubSend.send(addr, msg, len);
				testlen1=(call CC2420PacketBody.getHeader(msg))->dsn;
				call Timer0.startOneShot(WAITPERIOD);
				return subsendResult;
					
			}
			
			else{
			 for (i=1;i<=call CtpInfo.numNeighbors();i++){
				   if ( call UnicastNameFreeRouting.nextHop()==call CtpInfo.getNeighborAddr(i)){
				   re_channel=channelTable[i].curchannel;
			       }
			   }
				call CC2420Config.setChannel(re_channel);
				subsendResult=
				call Timer0.startOneShot(WAITPERIOD);
				return subsendResult;
				
			}*/
			call SubSend.send(addr, msg, len);
			 
       }
	/*event void Timer0.fired(){
		}*/
    event void SubSend.sendDone(message_t* msg, error_t error ) {
	  /*uint8_t re_channel;
		uint8_t i;
	       if ( call SubAcks.wasAcked(msg)==WASACK){
					flag=1;
					}
			else{
				for (i=1;i<=call CtpInfo.numNeighbors();i++){
				   if ( call UnicastNameFreeRouting.nextHop()==call CtpInfo.getNeighborAddr(i)){
				   re_channel=channelTable[i].lastchannel;
			       }
			   }
			   call CC2420Config.setChannel(re_channel);
			   
			}*/
			
     signal AMSend.sendDone(msg, error);
    }

     // cascade the calls down
    command uint8_t AMSend.cancel(message_t* msg) {
      return call SubSend.cancel(msg);
     }

    command uint8_t AMSend.maxPayloadLength() {
     return call SubSend.maxPayloadLength();
     }

    command void* AMSend.getPayload(message_t* msg, uint8_t len) {
       return call SubSend.getPayload(msg, len);
       }
	 event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
		/*Ackmsg=msg;
	    Acklen=len;
		//post CoordinateChannelTask(msg,len);
		CoordinateChannel(msg,len);*/
		signal Receive.receive(msg,payload,len);
	 }
	 event void CC2420Acksend.NeedAcksend(message_t*  msg, uint8_t len){
	     CoordinateChannel(msg,len);
  }
	 
	 void CoordinateChannel(message_t* msg,uint8_t len){
		uint8_t i;
		uint8_t Count=0;
		uint8_t Pending=0;
		uint8_t testdsn;
		uint8_t u8_channel=DEFCHANNEL;
		uint8_t u8_jumpchnel=DEFCHANNEL;
		uint8_t u8_numNeighbors;
		uint8_t u8_countNebors=1;
		
		channel_info_Table* channelEntry;
		am_addr_t desaddr;
		am_addr_t Neighboraddr;
		
		u8_numNeighbors=12;/*call CtpInfo.numNeighbors();*/
		
		if (!busy){
				AckMsg* Ackpkt = (AckMsg*)( call  AckPacket.getPayload(&pkt, sizeof(AckMsg)));
				Ackpkt->nodeid = TOS_NODE_ID;
				if (u8_numNeighbors==1){
				  Ackpkt->FLAG=INSATANT_FLAG;
				 }
				 else{
				  Ackpkt->FLAG=WAIT_FLAG;
				 }
				//Ackpkt->len =call  AckPacket.payloadLength(&pkt);
				Ackpkt->channel=u8_channel;
				desaddr=call AMPacket.source(msg);//发送该消息的目的地址
				Ackpkt->destid=desaddr;
				(call CC2420PacketBody.getHeader(&pkt))->dsn=(call CC2420PacketBody.getHeader(msg))->dsn;
				if (call AMAckSend.send(desaddr, &pkt, sizeof(AckMsg)) == SUCCESS) 
				{
					busy = TRUE;
					
			    }
		
		/*for (i=1;i<=u8_numNeighbors;i++){
		  channelTable[i].curchannel=u8_channel;
		}
		
		if (call CtpPacket.getEtx(msg)>EtxThreshold){
		//EtxThreshold=20
		   Count++;
		}
		//AckMsg* Ackpkt = (AckMsg*)( call  AckPacket.getPayload(&pkt, sizeof(AckMsg)));
		
		//链路质量退化
		if (Count>3 && Pending==0){
			//u8_channel=Selectchannel();
			u8_channel=0x0B;
			u8_jumpchnel=u8_channel;
			if (!busy){
				AckMsg* Ackpkt = (AckMsg*)( call  AckPacket.getPayload(&pkt, sizeof(AckMsg)));
				Ackpkt->nodeid = TOS_NODE_ID;
				if (u8_numNeighbors==1){
				  Ackpkt->FLAG=INSATANT_FLAG;
				 }
				 else{
				  Ackpkt->FLAG=WAIT_FLAG;
				 }
				//Ackpkt->len =call  AckPacket.payloadLength(&pkt);
				Ackpkt->channel=u8_channel;
				desaddr=call AMPacket.source(msg);//发送该消息的目的地址
				Ackpkt->destid=desaddr;
				(call CC2420PacketBody.getHeader(&pkt))->dsn=(call CC2420PacketBody.getHeader(msg))->dsn;
				if (call AMAckSend.send(desaddr, &pkt, sizeof(AckMsg)) == SUCCESS) 
				{
					busy = TRUE;
					
			    }
				if (u8_numNeighbors==1){
					  immechange(u8_channel);
					  //channelTable[0].parent = call UnicastNameFreeRouting.nextHop();
					  channelTable[0].neighbor=desaddr;
					  channelTable[0].lastchannel=channelTable[u8_countNebors].curchannel;
					  channelTable[0].curchannel=u8_channel;}
		        else{
					  
					  //savechannel(u8_channel);//还应该要增加一个参数换信道
					  Pending=1;
					  for (i=1;i<=u8_numNeighbors;i++) {    
					            
								Neighboraddr=call CtpInfo.getNeighborAddr(i);
								if ( Neighboraddr!=desaddr ) {
									u8_countNebors++;
								}
						}
					
					  channelTable[u8_countNebors].neighbor=desaddr;
					  channelTable[u8_countNebors].lastchannel=channelTable[u8_countNebors].curchannel;
					  channelTable[u8_countNebors].curchannel=u8_channel;
			  }
			}
		 
		
		
		}
		//遍历邻居邻居pending==1
		else if (Pending==1){
			//最后一个邻居pending=0
			    desaddr=call AMPacket.source(msg);
				u8_countNebors=1;
				for (i=1;i<=u8_numNeighbors;i++) {
								Neighboraddr=call CtpInfo.getNeighborAddr(i);
								if ( Neighboraddr!=desaddr ) {
									u8_countNebors++;
								}
							}
			    if (!busy){
				AckMsg* Ackpkt = (AckMsg*)( call  AckPacket.getPayload(&pkt, sizeof(AckMsg)));
				Ackpkt->nodeid = TOS_NODE_ID;
			//遍历邻居pending=1******?发送以后加1是不是不对，若重复邻居呢
				if (u8_countNebors<u8_numNeighbors){
				Ackpkt->FLAG=WAIT_FLAG;
				}
				else{
				Ackpkt->FLAG=HOP_FLAG;
				}
				Ackpkt->channel=u8_jumpchnel;
				Ackpkt->destid=desaddr;
				(call CC2420PacketBody.getHeader(&pkt))->dsn=(call CC2420PacketBody.getHeader(msg))->dsn;  
				if (call AMAckSend.send(desaddr, &pkt, sizeof(AckMsg)) == SUCCESS ) 
					{
					busy = TRUE;
					}
					if (u8_countNebors==u8_numNeighbors){
						immechange(u8_jumpchnel);//还应该要增加一个参数等待换信道
						u8_countNebors=0;
						Pending=0;
						}
					else{
						channelTable[u8_countNebors].neighbor=desaddr;
					    channelTable[u8_countNebors].lastchannel=channelTable[u8_countNebors].curchannel;
					    channelTable[u8_countNebors].curchannel=channelTable[u8_countNebors-1].curchannel;
						
						}
					
			        
			   }
			
		}
		//链路质量没有退化
		else{
			if (!busy){
				AckMsg* Ackpkt = (AckMsg*)( call  AckPacket.getPayload(&pkt, sizeof(AckMsg)));
				Ackpkt->nodeid = TOS_NODE_ID;
				Ackpkt->FLAG=NO_FLAG;
				Ackpkt->channel=u8_channel;//链路质量不改变，默认当前链路
				desaddr=call AMPacket.source(msg);
				Ackpkt->destid=desaddr;
				(call CC2420PacketBody.getHeader(&pkt))->dsn=(call CC2420PacketBody.getHeader(msg))->dsn;  
				if (call AMAckSend.send(desaddr, &pkt, sizeof(AckMsg)) == SUCCESS) 
					{
					busy = TRUE;
			        }
			   }
		
		
		 }*/
		testdsn=(call CC2420PacketBody.getHeader(&pkt))->dsn;
		
		   }
		}
	 event void AMAckSend.sendDone(message_t* msg, error_t erro)
		{
			if (&pkt == msg)
			  busy = FALSE;
		    
        }
	 event message_t* Ack_Receive.receive(message_t* msg, void* payload, uint8_t len) {
			uint8_t hopflag;
			uint8_t u8_nechannel;
			    if (len == sizeof(AckMsg)){
				AckMsg* repkt = (AckMsg*)payload;
				hopflag=repkt->FLAG;
				if (hopflag==INSATANT_FLAG||hopflag==HOP_FLAG){
				  u8_nechannel=repkt->channel;
				  immechange(u8_nechannel);
				  flag=1;
				  }
				else{
				  //u8_nechannel=repkt->channel;
				  //savechannel(u8_nechannel);
				  flag=0;				  
				}
				
			} 
	 }
	  
		 
		 event void CC2420Config.syncDone( error_t error ){
		 
		 } 
		 event void UnicastNameFreeRouting.routeFound() {
		 }
		 event void UnicastNameFreeRouting.noRoute() {
		 }

		async event uint16_t CcaControl.getInitialBackoff[am_id_t amId](message_t * msg, uint16_t defaultBackoff) {
		return defaultBackoff;
		}

		async event uint16_t CcaControl.getCongestionBackoff[am_id_t amId](message_t * msg, uint16_t defaultBackoff) {
		return defaultBackoff;
		}

		async event bool CcaControl.getCca[am_id_t amId](message_t * msg, bool defaultValue) {
		changecca=stopcca;
		return defaultValue=stopcca;
		//return defaultValue;
		}

	}
   