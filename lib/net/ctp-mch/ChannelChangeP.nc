//#include <channelChg.h>

module ChannelChangeP{

provides
{
	interface ChannelChange;
}

uses{	
		interface CC2420Config;

	  	//Timer used for enforcing returning to control channel
		interface Timer<TMilli> as Timer2;

		interface Boot;
		interface AMSend;
		interface Receive;
		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
	}
}
implementation {

	/**********shi**********/

	uint8_t m_roleState;

	//retry count for resending command for switching channel
	//uint8_t m_iRetryCnt;

	bool m_bHopping;

	//count of timeout of staying at data channel
	uint8_t m_iTOutCnt;

	//Count of acknowledgements to channel switching for sending a beacon
	uint8_t m_iAckCnt;
	
	//change role state
	error_t changeRoleState(uint8_t newState);
	//switch to data channel
	void switchToDataChannel(uint8_t newCh);
	//ask neighbours for channel hopping
	bool askForSwitching(am_addr_t nbAddr, uint8_t destCh);
	//return to control channel
	void BackToCtrlCh();

	//void ackDelay();
	inline void iniParameters();
	void changeDataCh();
	/**********shi**********/	

	uint8_t m_channel;
	uint8_t m_iDataCh=CH_DATA;
	int m_iChShift=0;
	message_t m_SendMsg;
	bool m_bChanged=FALSE;
	//A flag indicating to swtich to data channel after a successful sending 
	bool m_bToSwitch=FALSE;
	
	//local buffer of data channel code received from neighbours
	uint8_t m_iRvChannel; 
	uint8_t m_iChTestCnt;
	
	//a flag for indicating whether an ACK needed to be verified.
	bool bACKVerified;
	//Address of the next hop node.
	am_addr_t m_nextHop;
	
	event void Boot.booted() 
	{
		//call DisseminationControl.start();
		iniParameters();
		BackToCtrlCh();
	}
      
	//Change Data channel
	//iReason: 0-unable to send, 1-links are bad. 20170819
	command error_t ChannelChange.changeDC(uint8_t iReason)
	{
		error_t retVal = FAIL;
		switch (iReason)
		{
			case CHCHG_UNABLETOSEND:
				changeDataCh();
				retVal = SUCCESS;
				break ;
			case CHCHG_LINKSBAD:
				if (m_iChTestCnt == 0)
				{
					changeDataCh();
					retVal = SUCCESS;
				}
				else
					retVal = FAIL ;
				if (++m_iChTestCnt > CHCHGTESTCNTLIMIT)	
					m_iChTestCnt = 0;
				break ;
		}
		return retVal;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
	{
		ReportMsg_t* rMsg;	//收到的包
		rMsg = (ReportMsg_t *)payload;

		switch(rMsg->msgCode)
		{
			case 01:
				//Be asked to switch channel
				if(m_roleState==RS_IDLE)
				{
					m_iRvChannel=rMsg->DaCh; 
					//change state first, if sending failed, then reset state to be idle
					changeRoleState(RS_BEACRECEIVER);
					//ackDelay();
					switchToDataChannel(m_iDataCh);
				}
				/* else if((m_roleState==RS_BEACSENDER) && (!m_bChanged))
				{
					//inform the routeEngine about the situation
					signal ChannelChange.beRFS(m_roleState,FALSE,m_nextHop);
					
					atomic{
						changeRoleState(RS_IDLE);
					
						//Shall we change to be a receiver immediatley?
						m_iRvChannel=rMsg->DaCh; 
						changeRoleState(RS_BEACRECEIVER);
					}
					
					//ackDelay();
					switchToDataChannel(m_iDataCh);
				} */
				
				break;
			case 02:
				if(m_roleState==RS_BEACSENDER)
					/**不需要等待收到设定数量的应答吗？**/
					//get response and switch channel
					//should not happen again, and to be obsolete.
					switchToDataChannel(m_iDataCh);
				/* else if(m_roleState==RS_BEACRECEIVER)
				{
					m_iAckCnt++;
				}*/
				break;  
			case 3:
				//change to data channel for sending/receiving data
				if(m_roleState==RS_IDLE)
				{
					m_iRvChannel=rMsg->DaCh; 
			        	
					//change state first, if sending failed, then reset state to be idle
					changeRoleState(RS_DATARECEIVER);
					switchToDataChannel(m_iRvChannel);
				}
				/* else if((m_roleState==RS_BEACSENDER ||m_roleState==RS_DATASENDER) && (!m_bChanged))
				{
					signal ChannelChange.beRFS(m_roleState,FALSE);
					atomic{
						changeRoleState(RS_IDLE);
						m_iRvChannel=rMsg->DaCh; 
						changeRoleState(RS_DATARECEIVER);
					}
					
					switchToDataChannel(m_iRvChannel);
				} */
				break;
			/* case 4:
				//标号4的命令表示什么？
				
				switchToDataChannel(m_iDataCh);
				break; */
            }
			
		return msg;
	}

	//Switch back to control channel	
	command void ChannelChange.closeSending()
	{
		
		BackToCtrlCh();
	}

	command void ChannelChange.receiveDoneHandle(uint8_t msgType)
	{
		if (((msgType == 0)&& (m_roleState==RS_BEACRECEIVER)) ||
			((msgType == 1)&& (m_roleState==RS_DATARECEIVER)))
		{
			/*If timer is running, then stop it*/
			if(call Timer2.isRunning())
				call Timer2.stop();
			//this scheme may be canceled
			/* if(m_iTOutCnt>0)
				m_iTOutCnt--; */
			BackToCtrlCh();
		}	
		
		/* switch (msgType)
		{
			case 0:
				//just received a beacon
				if (m_roleState==RS_BEACRECEIVER)
					BackToCtrlCh();
				break;
			case 1:
				if (m_roleState==RS_DATARECEIVER)
					BackToCtrlCh();
				break;
		} */
	}
	
	//When the timer fires, the node should return to control channel.
	/*Inform the network layer first. 
	*Then aggregate the count of timeouts, and change data channel when necessary.
	*Finally return to control channel.
	*/
	event void Timer2.fired()
	{
		//Signal the timeout event.
		signal ChannelChange.onTimeout(m_roleState);
		//Count times of timeout.
		/* m_iTOutCnt++;
		if(m_iTOutCnt>=V_CHCHG_TH)
		{
			//Only receiver start this timer, so channel hopping should not happen,shi
			//changeDataCh();
			m_iTOutCnt=0;
		} */
		BackToCtrlCh();
	}
	
	event void CC2420Config.syncDone( error_t error )
	{}

         
	event void AMSend.sendDone(message_t *msg, error_t error)
	{
		if(error==SUCCESS)
		{
			/* if(m_bToSwitch==TRUE)
			{ */
				if (m_roleState==RS_BEACSENDER)
					switchToDataChannel(m_iDataCh);
				else if (m_roleState==RS_DATASENDER)
				{
					if (!bACKVerified || (bACKVerified && call PacketAcknowledgements.wasAcked(msg)))
						switchToDataChannel(m_iDataCh);
					else 
					{
						signal ChannelChange.beRFS(m_roleState,ENOACK, m_nextHop);	
						changeRoleState(RS_IDLE);
					}
				}

		}
		else 
		{
			if(m_roleState==RS_BEACSENDER ||m_roleState==RS_DATASENDER)
			{
				signal ChannelChange.beRFS(m_roleState,FAIL, m_nextHop);	
				changeRoleState(RS_IDLE);
			}	
			/* else
				//should not happen.
				changeRoleState(RS_IDLE); */	
		}
	}

	/********Functions*********/

	inline void iniParameters()
	{
		m_iTOutCnt=0;
		m_iChTestCnt = 0;
	}

	
	void switchToDataChannel(uint8_t newCh)
	{
		atomic
		{
			call CC2420Config.setChannel(newCh);
			m_bChanged=TRUE;
			
			if(m_roleState==RS_BEACSENDER||m_roleState==RS_DATASENDER)
			{
				
				signal ChannelChange.beRFS(m_roleState,SUCCESS, m_nextHop);
			}
			else
				call Timer2.startOneShot(V_WAITATDATACH);
		}
	}

	void BackToCtrlCh()
	{
		atomic{
			call CC2420Config.setChannel(CH_CTRL);
			m_bChanged=FALSE;
			changeRoleState(RS_IDLE);
		}
	}
	
	//role state converion control
	error_t changeRoleState(uint8_t newState)
	{
		error_t rtVal;
		if(m_roleState==RS_IDLE ||newState==RS_IDLE)
		{
			m_roleState=newState;
			rtVal= SUCCESS;
		}
		else if(m_roleState==newState)
			rtVal= SUCCESS;
		else
			rtVal=FAIL;
		
		return rtVal;
	}

	//nbAddr: address of neighbour(s), destCh:destination channel
	bool askForSwitching(am_addr_t nbAddr, uint8_t destCh)
	{
		ReportMsg_t* Msg=call Packet.getPayload(&m_SendMsg,2);
		if(nbAddr==AM_BROADCAST_ADDR)
		{
			Msg->msgCode=0x01;

		}
		else
		{
			Msg->msgCode=0x03;
			//m_bToSwitch=TRUE;
		}
		Msg->DaCh=destCh;
		return (call AMSend.send(nbAddr,&m_SendMsg,2) == SUCCESS );	
	}

	//Change data channel
	void changeDataCh()
	{
		atomic
		{
			m_iDataCh += CHCHG_HOPSTEP;
			if(m_iDataCh>25)
			{
				m_iChShift = (m_iChShift + 1) % CHCHG_HOPSTEP;
				m_iDataCh= 10+ m_iDataCh % 25 + m_iChShift;	
			}
		}
	}
	
	command bool ChannelChange.IsBeaconSender()
	{
		return m_roleState==RS_BEACSENDER;
	}
	
	command bool ChannelChange.IsDataSender()
	{
		return m_roleState==RS_DATASENDER;
	}

	command bool ChannelChange.IsIdle()
	{
		return m_roleState==RS_IDLE;
	}
	
	command bool ChannelChange.IsAtDataChannel()
	{
		return m_bChanged;
	}

	command bool ChannelChange.IsAtCtrlChannel()
	{
		return !m_bChanged;
	}
	/*Channel switching logic
	*first, change role of a node to be sender;
	*then, ask neighbour nodes for channel switching (may repeat this step)
	*finally,if neighbour have acknowledged the switching (known from receive.receive event),
	*then the sender switch to data channel, with the flag m_bChanged set to be TRUE.
	*/
	/*Demand to swtich channel to data channel.
	return true if the node is SUCCESSful sending req for switching channel,  return false otherwise.
	*msgType:0-beacon,1-data
	*/
	command bool ChannelChange.prepareToSend(uint8_t msgType,am_addr_t nbrAddr, bool bNew)
	{
		uint8_t newRole;
		bool bDone=FALSE;
		uint8_t retVal;
		
		m_nextHop = nbrAddr;
		bACKVerified = bNew;
		if(msgType==DT_BEACON)
		{
			newRole=RS_BEACSENDER;
		}
		else if(msgType==DT_DATA)
			newRole=RS_DATASENDER;
			
		//Handshake will be carried out only when the node is at idle state.
		if(m_roleState==RS_IDLE)
		{
			atomic
			{
				/**可能出现当前已处于数据信道，又需要准备切换信道的情况？**/
				if(!m_bChanged )
				{
					
					//If the sender node is not at data channel, 
					//then ask its neighbour for channel switching 
					bDone=askForSwitching(nbrAddr,m_iDataCh);
					if(bDone)
						changeRoleState(newRole);
				}
				else
					ADBG(DBG_LEV, "\r\n Status error, being idle at data channel.\r\n");
			}
		}
		/* else if ((m_roleState == newRole))
		{
			bDone= TRUE;
			if (m_bChanged)
				signal ChannelChange.beRFS(m_roleState, SUCCESS);
		} */		
		
		return bDone;
	}
}
