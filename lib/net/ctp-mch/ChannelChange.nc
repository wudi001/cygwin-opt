/*
*Interface used to change channel
*2012/12
*/
interface ChannelChange{
	command error_t changeDC(uint8_t iReason);//change data channel

	command void closeSending(); //End sending process and go back to control channel

	//When receive a packet, handle succeeded operation according to current state.
	command void receiveDoneHandle(uint8_t msgType);
	
	//Indicate role state of a node
	command bool IsBeaconSender();
	command bool IsDataSender();
	
	command bool IsIdle();
	
	command bool IsAtDataChannel();
	command bool IsAtCtrlChannel();

	//Demand to swtich channel to data channel
	command bool prepareToSend(uint8_t msgType,am_addr_t nbrAddr, bool bNew);

	//signaled when a node has changed to data channel, and is ready for sending msg
	event void beRFS(uint8_t role, error_t rslt, am_addr_t nextHop);

	//Signaled when timeout occurs as staying at data channel
	event void onTimeout(uint8_t role);

}
