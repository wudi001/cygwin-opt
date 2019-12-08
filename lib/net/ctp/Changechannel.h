
   enum 
  {
	
    EtxThreshold  = 0x14,
    TYPE_ACK = 0x10,
	NO_FLAG=0x00,
	WAIT_FLAG=0x01,
	INSATANT_FLAG=0x02,
	HOP_FLAG=0x04,	
	CHANNEL_COUNT = 16,
	WASACK=0x01,
	QUEUE_SIZE=16,
	CHANNEL_TABLE_SIZE = 10,
	WAITPERIOD=500,
	//DEFCHANNEL=0x1A
	
   };
  typedef nx_struct AckMsg 
	{nx_uint16_t nodeid;	
	nx_uint8_t FLAG;
	nx_uint8_t channel;
	nx_uint16_t destid;
	//am_addr_t saddr;
	}AckMsg;
	
	
  typedef struct {
    am_addr_t neighbor;
	//am_addr_t parent;
    nx_uint8_t curchannel;
	nx_uint8_t lastchannel;
	//nx_uint8_t Count;
    } channel_info_Table;
	
	
	
	
	
	
	