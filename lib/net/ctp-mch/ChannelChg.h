	enum
	{
		RS_IDLE =0,
		RS_BEACSENDER=1,	//Beacon sender
		RS_BEACRECEIVER=2,
		RS_DATASENDER=3,	//Data sender
		RS_DATARECEIVER=4
	};
	enum
	{
		DT_BEACON=0,	//beacon type
		DT_DATA=1,		//data type
	};

	enum
	{
		V_RETRYCNT=1,
		V_WAITSWICHACK=1000,
		V_WAITATDATACH=25,	//waiting time allowed to stay at data channel
		V_SYNCRETRY=100,
		V_CHSWACKBKOFF_PERIOD=30,
		V_CHSWACKBKOFF_MIN=10,
		V_CHSWACKCNT_TH=1,	//Threshold of count of ack nodes
		V_CHCHG_TH=5,			//Threshold of count of timeouts
	};

	enum
	{
		CH_CTRL=26,		//Control channel
		CH_DATA=15,		//data channel
	};

	enum
	{
		SYNC_FORNULL=0,		//null
		SYNC_FORDATACH=1,	//Call CC2420Config.sync for switching to data channel
		SYNC_FORCTRLCH=2,		//for switching to Control channel
	};
	
	/* enum
	{
		S_REQREADY =0,
		S_SENDINGBEAC =1,
		S_SENDINGDATA =2,
		S_RCV =3,
		S_REQFAIL =4,
	}; */
	
	enum
	{
		CHCHG_UNABLETOSEND = 0,
		CHCHG_LINKSBAD = 1,
		CHCHGTESTCNTLIMIT =  10,
		CHCHG_HOPSTEP = 3,
	};
	
	typedef nx_struct ReportMsg
	{
		nx_uint8_t msgCode;
		nx_uint8_t DaCh;
		
	}ReportMsg_t;

	
