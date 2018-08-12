pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable()
        public
    {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(
        address newOwner
    )
        onlyOwner
        public
    {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract nodeRegistry is Ownable{
    
    function nodeRegistry() public {}
    
    mapping (bytes32 => bool) public isNodeExist;
	bytes32[] public allNodeID;

	event NewNode (bytes32 node_id);

    function RegisterNode(
		bytes32 nodeID) public onlyOwner returns (bool flag){
			if (isNodeExist[nodeID]) revert();
			isNodeExist[nodeID] = true;
			allNodeID.push(nodeID);
			emit NewNode (nodeID);
			flag = true;
	}
	
	function GetAllNode() public view returns (bytes32[] nodeIDs){
        nodeIDs = allNodeID;
    }
}

contract controlLimits is Ownable{

	nodeRegistry public nodeRegister;

    function controlLimits(address _nodeReg) public{
		nodeRegister = nodeRegistry(_nodeReg);
	}

	struct soiltempcl{
		uint32 SOIL_TEMP_UCL;
		uint32 SOIL_TEMP_LCL;
		uint32 SOIL_TEMP_CL;
	}
	soiltempcl public soilTempClStruct;
	mapping (bytes32=> soiltempcl) public soiltempclbynode;

	struct soilhumiditycl{
		uint32 SOIL_HUMDTY_UCL;
		uint32 SOIL_HUMDTY_LCL;
		uint32 SOIL_HUMDTY_CL;
	}
	mapping (bytes32=> soilhumiditycl) public soilhumidityclbynode;


	struct phcl{
	    uint32 PH_UCL;
    	uint32 PH_LCL;
    	uint32 PH_CL;
	}
	mapping (bytes32=> phcl) public phclbynode;

    struct n2cl{
    	uint32 N2_UCL;
    	uint32 N2_LCL;
    	uint32 N2_CL;
    }
    mapping (bytes32=> n2cl) public n2clbynode;

 	
	struct ambienttempcl{
		uint32 AMBIENT_TEMP_UCL;
		uint32 AMBIENT_TEMP_LCL;
		uint32 AMBIENT_TEMP_CL;
	}
	mapping (bytes32=> ambienttempcl) public ambienttempclbynode;

	
	struct ambienthumiditycl{
		uint32 AMBIENT_HUMIDITY_UCL;
		uint32 AMBIENT_HUMIDITY_LCL;
		uint32 AMBIENT_HUMIDITY_CL;
	}
	mapping (bytes32=> ambienthumiditycl) public ambienthumidityclbynode;


	struct ambientlightcl{
		uint32 AMBIENT_LIGHT_UCL;
		uint32 AMBIENT_LIGHT_LCL;
		uint32 AMBIENT_LIGHT_CL;
	}
	mapping (bytes32=> ambientlightcl) public ambientlightclbynode;


    enum parameter{SOIL_TEMP, SOIL_HUMIDITY, PH, NITROGEN, AMBIENT_TEMP, AMBIENT_HUMIDITY, AMBIENT_LIGHT}
	event newLimits(bool flag);

    function setlimits(
        bytes32 nodeid,
    	uint32[] UCL,
    	uint32[] LCL,
    	uint8[] parameters ) public returns(bool flag){
    	    bool existed = nodeRegister.isNodeExist(nodeid);
			if (!existed) revert();
    		for (uint i = 0; i< parameters.length; i++){
    		    if(parameters[i] == 0){
    				soiltempclbynode[nodeid].SOIL_TEMP_UCL = UCL[i];
    				soiltempclbynode[nodeid].SOIL_TEMP_LCL = LCL[i];
    				soiltempclbynode[nodeid].SOIL_TEMP_CL = (UCL[i]+LCL[i])/2;
        		}else if(parameters[i] == 1){
    				soilhumidityclbynode[nodeid].SOIL_HUMDTY_UCL = 	UCL[i];
    				soilhumidityclbynode[nodeid].SOIL_HUMDTY_LCL = LCL[i];
    				soilhumidityclbynode[nodeid].SOIL_HUMDTY_CL = (UCL[i]+LCL[i])/2;
        		}else if(parameters[i] == 2){
    				phclbynode[nodeid].PH_UCL = UCL[i];
    				phclbynode[nodeid].PH_LCL = LCL[i];
    				phclbynode[nodeid].PH_CL = (UCL[i]+LCL[i])/2;
        		}else if(parameters[i] == 3){
    				n2clbynode[nodeid].N2_UCL = UCL[i];
    				n2clbynode[nodeid].N2_LCL = LCL[i];
    				n2clbynode[nodeid].N2_CL = (UCL[i]+LCL[i])/2;
        		}else if(parameters[i] == 4){
    				ambienttempclbynode[nodeid].AMBIENT_TEMP_UCL = UCL[i];
    				ambienttempclbynode[nodeid].AMBIENT_TEMP_LCL = LCL[i];
    				ambienttempclbynode[nodeid].AMBIENT_TEMP_CL = (UCL[i]+LCL[i])/2;	
        		}else if(parameters[i] == 5){
    				ambienthumidityclbynode[nodeid].AMBIENT_HUMIDITY_UCL = UCL[i];
    				ambienthumidityclbynode[nodeid].AMBIENT_HUMIDITY_LCL = LCL[i];
    				ambienthumidityclbynode[nodeid].AMBIENT_HUMIDITY_CL = (UCL[i]+LCL[i])/2;
        		}else if(parameters[i] == 6){
    				ambientlightclbynode[nodeid].AMBIENT_LIGHT_UCL = UCL[i];
    				ambientlightclbynode[nodeid].AMBIENT_LIGHT_LCL = LCL[i];
    				ambientlightclbynode[nodeid].AMBIENT_LIGHT_CL = (UCL[i]+LCL[i])/2;
        		}
    		}
			emit newLimits(true);
    		flag = true;
    	}

	function getSoilTempControlLimits(bytes32 nodeid) public view returns (
		uint32 soil_temp_ucl,
		uint32 soil_temp_lcl,
		uint32 soil_temp_cl){
			(	soil_temp_ucl, soil_temp_lcl, soil_temp_cl ) = 
			    ( 	soiltempclbynode[nodeid].SOIL_TEMP_UCL, 
					soiltempclbynode[nodeid].SOIL_TEMP_LCL, 
					soiltempclbynode[nodeid].SOIL_TEMP_CL );
	}
	
	
	function getSoilHumidityControlLimits(bytes32 nodeid) public view returns(
	    uint32 soil_humidity_ucl,
	    uint32 soil_humidity_lcl,
	    uint32 soil_humidity_cl){
	        ( soil_humidity_ucl, soil_humidity_lcl, soil_humidity_cl ) = 
	            (	soilhumidityclbynode[nodeid].SOIL_HUMDTY_UCL, 
					soilhumidityclbynode[nodeid].SOIL_HUMDTY_LCL, 
					soilhumidityclbynode[nodeid].SOIL_HUMDTY_CL);
	 }
	    
	    function getPhControlLimits(bytes32 nodeid) public view returns(
	    uint32 ph_ucl,
	    uint32 ph_lcl,
	    uint32 ph_cl){
	        ( ph_ucl, ph_lcl, ph_cl ) = 
	            (	phclbynode[nodeid].PH_UCL, 
					phclbynode[nodeid].PH_LCL, 
					phclbynode[nodeid].PH_CL);
	    }
	    
	    function getN2ControlLimits(bytes32 nodeid) public view returns(
	    uint32 n2_ucl,
	    uint32 n2_lcl,
	    uint32 n2_cl){
	        ( n2_ucl, n2_lcl, n2_cl ) = 
	            (	n2clbynode[nodeid].N2_UCL, 
					n2clbynode[nodeid].N2_LCL, 
					n2clbynode[nodeid].N2_CL);
	    }

		function getAmbientTempControlLimits(bytes32 nodeid) public view returns (
		uint32 ambient_temp_ucl,
		uint32 ambient_temp_lcl,
		uint32 ambient_temp_cl){
			(	ambient_temp_ucl, ambient_temp_lcl, ambient_temp_cl ) = 
			    ( 	ambienttempclbynode[nodeid].AMBIENT_TEMP_UCL, 
					ambienttempclbynode[nodeid].AMBIENT_TEMP_LCL, 
					ambienttempclbynode[nodeid].AMBIENT_TEMP_CL );
		}

		function getAmbientHumidityControlLimits(bytes32 nodeid) public view returns(
	    uint32 ambient_humidity_ucl,
	    uint32 ambient_humidity_lcl,
	    uint32 ambient_humidity_cl){
	        ( ambient_humidity_ucl, ambient_humidity_lcl, ambient_humidity_cl ) = 
	            (	ambienthumidityclbynode[nodeid].AMBIENT_HUMIDITY_UCL, 
					ambienthumidityclbynode[nodeid].AMBIENT_HUMIDITY_LCL, 
					ambienthumidityclbynode[nodeid].AMBIENT_HUMIDITY_CL);
	 	}


		function getAmbientLightControlLimits(bytes32 nodeid) public view returns (
		uint32 ambient_light_ucl,
		uint32 ambient_light_lcl,
		uint32 ambient_light_cl){
			(	ambient_light_ucl, ambient_light_lcl, ambient_light_cl ) = 
			    ( 	ambientlightclbynode[nodeid].AMBIENT_LIGHT_UCL, 
					ambientlightclbynode[nodeid].AMBIENT_LIGHT_LCL, 
					ambientlightclbynode[nodeid].AMBIENT_LIGHT_CL );
		}
}

contract exception is Ownable{
    
    controlLimits public controlLimitIns;
    nodeRegistry public nodeRegister;
    
    function exception(
        address _controlLimitAddr,
        address _nodeRegisterAddr) public{
            controlLimitIns = controlLimits(_controlLimitAddr);
            nodeRegister = nodeRegistry(_nodeRegisterAddr);
        }

    enum SOIL_TEMP_STATE { IN_CONTROL, OUT_OF_CONTROL }
	mapping (bytes32 => uint32) prvSoilTempValBynode;

	struct soilTempExp{
		uint64[] timeStamp;
		uint32[] temp_daviation;
		SOIL_TEMP_STATE[] temp_state;
        bytes32[] temphash;
	}

	mapping (bytes32 => soilTempExp) soilTempExpByNode;

	event NewTransactionOnSoilTempException (bytes32 Nodeid, uint32 SoilTemperature);
		
	enum SOIL_HUMDTY_STATE { IN_CONTROL, OUT_OF_CONTROL }
	mapping (bytes32 => uint32) prvSoilHumdtyValBynode;
	
	struct soilHumdtyExp{
		uint64[] timeStamp;
		uint32[] humdty_daviation;
		SOIL_HUMDTY_STATE[] humdty_state;
        bytes32[] humidityhash;
	}

	mapping (bytes32 => soilHumdtyExp) soilHumdtyExpByNode;

	event NewTransactionOnSoilHumdtyException (bytes32 Nodeid, uint32 SoilHumidity);
		
	enum PH_STATE { IN_CONTROL, OUT_OF_CONTROL }
	mapping (bytes32 => uint32) prvPhValBynode;
	
	struct phExp{
		uint64[] timeStamp;
		uint32[] ph_daviation;
		PH_STATE[] ph_state;
        bytes32[] phhash;
	}

	mapping (bytes32 => phExp) phExpByNode;

	event NewTransactionOnPhException (bytes32 Nodeid, uint32 SoilPh);
		
	enum N2_STATE { IN_CONTROL, OUT_OF_CONTROL }
	mapping (bytes32 => uint32) prvN2ValBynode;
	
	struct n2Exp{
		uint64[] timeStamp;
		uint32[] n2_daviation;
		N2_STATE[] n2_state;
        bytes32[] n2hash;
	}

	mapping (bytes32 => n2Exp) n2ExpByNode;

	event NewTransactionOnN2Exception (bytes32 Nodeid, uint32 SoilNitrogen);

	enum AMBIENT_TEMP_STATE { IN_CONTROL, OUT_OF_CONTROL }
	mapping (bytes32 => uint32) prvAmbientTempValBynode;

	struct ambientTempExp{
		uint64[] timeStamp;
		uint32[] temp_daviation;
		AMBIENT_TEMP_STATE[] temp_state;
        bytes32[] temphash;
	}

	mapping (bytes32 => ambientTempExp) ambientTempExpByNode;

	event NewTransactionOnAmbientTempException (bytes32 Nodeid, uint32 AmbientTemperature);

	enum AMBIENT_HUMDTY_STATE { IN_CONTROL, OUT_OF_CONTROL }
	mapping (bytes32 => uint32) prvAmbientHumdtyValBynode;
	
	struct ambientHumdtyExp{
		uint64[] timeStamp;
		uint32[] humdty_daviation;
		AMBIENT_HUMDTY_STATE[] humdty_state;
        bytes32[] humidityhash;
	}

	mapping (bytes32 => ambientHumdtyExp) ambientHumdtyExpByNode;

	event NewTransactionOnAmbientHumdtyException (bytes32 Nodeid, uint32 AmbientHumidity);

	enum AMBIENT_LIGHT_STATE { IN_CONTROL, OUT_OF_CONTROL }
	mapping (bytes32 => uint32) prvAmbientLightValBynode;
	
	struct ambientLightExp{
		uint64[] timeStamp;
		uint32[] light_daviation;
		AMBIENT_HUMDTY_STATE[] light_state;
        bytes32[] lighthash;
	}

	mapping (bytes32 => ambientLightExp) ambientLightExpByNode;

	event NewTransactionOnAmbientLightException (bytes32 Nodeid, uint32 AmbientLight);

	function CheckSoilTempException(
		bytes32 nodeID,
		uint32 temp_val) public view returns (uint32 tempflag, bool isnodeexist) {
		    bool existed = nodeRegister.isNodeExist(nodeID);
			if (existed) {
                isnodeexist = true;
            }
            uint32 ucl;
            uint32 lcl;
            uint32 cl;
            (ucl, lcl, cl) = controlLimitIns.getSoilTempControlLimits(nodeID);
			if (
			    temp_val <= ucl && 
			    temp_val >= lcl){
				if(prvSoilTempValBynode[nodeID] != 0){
					if (prvSoilTempValBynode[nodeID] > ucl || 
					    prvSoilTempValBynode[nodeID] < lcl){
					    tempflag = 1;
					}
				}
				}else if (temp_val > ucl){
					if (prvSoilTempValBynode[nodeID] < ucl || prvSoilTempValBynode[nodeID] == 0){
						tempflag = 2;
					}
				}else if (temp_val < lcl){
					if (prvSoilTempValBynode[nodeID] > lcl || prvSoilTempValBynode[nodeID] == 0){
						tempflag = 2;
					}
				}
	}

	function CheckSoilHumdtyException(
		bytes32 nodeID,
		uint32 humidity_val) public view returns (uint32 humidityflag, bool isnodeexist) {
		    bool existed = nodeRegister.isNodeExist(nodeID);
			if (existed) {
                isnodeexist = true;
            }
            uint32 ucl;
            uint32 lcl;
            uint32 cl;
            (ucl, lcl, cl) = controlLimitIns.getSoilHumidityControlLimits(nodeID);
			if (humidity_val <= ucl && 
			    humidity_val >= lcl){
					if (prvSoilHumdtyValBynode[nodeID] != 0){
						if (prvSoilHumdtyValBynode[nodeID] > ucl || 
						prvSoilHumdtyValBynode[nodeID] < lcl){
							humidityflag = 1;
						}
					}
				}else if (humidity_val > ucl){
					if (prvSoilHumdtyValBynode[nodeID] < ucl || prvSoilHumdtyValBynode[nodeID] == 0){
						humidityflag = 2;
					}
				}else if (humidity_val < lcl){
					if (prvSoilHumdtyValBynode[nodeID] > lcl || prvSoilHumdtyValBynode[nodeID] == 0){
						humidityflag = 2;
					}
				}
	}

	function CheckPhException(
		bytes32 nodeID,
		uint32 ph_val) public view returns (uint32 phflag, bool isnodeexist) {
		    bool existed = nodeRegister.isNodeExist(nodeID);
			if (existed) {
                isnodeexist = true;
            }
            uint32 ucl;
            uint32 lcl;
            uint32 cl;
            (ucl, lcl, cl) = controlLimitIns.getPhControlLimits(nodeID);
			if (ph_val <= ucl && ph_val >= lcl){
					if (prvPhValBynode[nodeID] != 0){
						if (prvPhValBynode[nodeID] > ucl || 
						prvPhValBynode[nodeID] < lcl){
							phflag = 1;
						}
					}
				}else if (ph_val > ucl){
					if (prvPhValBynode[nodeID] < ucl || prvPhValBynode[nodeID] == 0){
						phflag = 2;
					}
				}else if (ph_val < lcl){
					if (prvPhValBynode[nodeID] > lcl || prvPhValBynode[nodeID] == 0){
						phflag = 2;
					}
				}
	}

	function CheckN2Exception(
		bytes32 nodeID,
		uint32 n2_val) public view returns (uint32 n2flag, bool isnodeexist) {
		    bool existed = nodeRegister.isNodeExist(nodeID);
			if (existed) {
                isnodeexist = true;
            }
            uint32 ucl;
            uint32 lcl;
            uint32 cl;
            (ucl, lcl, cl) = controlLimitIns.getN2ControlLimits(nodeID);
			if (n2_val <= ucl && n2_val >= lcl){
					if (prvN2ValBynode[nodeID] != 0){
						if (prvN2ValBynode[nodeID] > ucl || 
						prvN2ValBynode[nodeID] < lcl){
							n2flag = 1;
						}
					}
				    
				}else if (n2_val > ucl){
					if (prvN2ValBynode[nodeID] < ucl || prvN2ValBynode[nodeID] == 0){
						n2flag = 2;
					}
				}else if (n2_val < lcl){
					if (prvN2ValBynode[nodeID] > lcl || prvN2ValBynode[nodeID] == 0){
						n2flag = 2;
					}
				}
	}


	function CheckAmbientTempException(
		bytes32 nodeID,
		uint32 temp_val) public view returns (uint32 ambient_tempflag, bool isnodeexist) {
		    bool existed = nodeRegister.isNodeExist(nodeID);
			if (existed) {
                isnodeexist = true;
            }
            uint32 ucl;
            uint32 lcl;
            uint32 cl;
            (ucl, lcl, cl) = controlLimitIns.getAmbientTempControlLimits(nodeID);
			if (temp_val <= ucl && 
			    temp_val >= lcl){
				if(prvAmbientTempValBynode[nodeID] != 0){
					if (prvAmbientTempValBynode[nodeID] > ucl || 
					    prvAmbientTempValBynode[nodeID] < lcl){
					    ambient_tempflag = 1;
					}
				}
				}else if (temp_val > ucl){
					if (prvAmbientTempValBynode[nodeID] < ucl || prvAmbientTempValBynode[nodeID] == 0){
						ambient_tempflag = 2;
					}
				}else if (temp_val < lcl){
					if (prvAmbientTempValBynode[nodeID] > lcl || prvAmbientTempValBynode[nodeID] == 0){
						ambient_tempflag = 2;
					}
				}
	}

	function CheckAmbientHumdtyException(
		bytes32 nodeID,
		uint32 humidity_val) public view returns (uint32 ambient_humidityflag, bool isnodeexist) {
		    bool existed = nodeRegister.isNodeExist(nodeID);
			if (existed) {
                isnodeexist = true;
            }
            uint32 ucl;
            uint32 lcl;
            uint32 cl;
            (ucl, lcl, cl) = controlLimitIns.getAmbientHumidityControlLimits(nodeID);
			if (humidity_val <= ucl && 
			    humidity_val >= lcl){
					if (prvAmbientHumdtyValBynode[nodeID] != 0){
						if (prvAmbientHumdtyValBynode[nodeID] > ucl || 
						    prvAmbientHumdtyValBynode[nodeID] < lcl){
							ambient_humidityflag = 1;
						}
					}
				}else if (humidity_val > ucl){
					if (prvAmbientHumdtyValBynode[nodeID] < ucl || prvAmbientHumdtyValBynode[nodeID] == 0){
						ambient_humidityflag = 2;
					}
				}else if (humidity_val < lcl){
					if (prvAmbientHumdtyValBynode[nodeID] > lcl || prvAmbientHumdtyValBynode[nodeID] == 0){
						ambient_humidityflag = 2;
					}
				}
	}


	function CheckAmbientLightException(
		bytes32 nodeID,
		uint32 light_val) public view returns (uint32 lightflag, bool isnodeexist) {
		    bool existed = nodeRegister.isNodeExist(nodeID);
			if (existed) {
                isnodeexist = true;
            }
            uint32 ucl;
            uint32 lcl;
            uint32 cl;
            (ucl, lcl, cl) = controlLimitIns.getAmbientLightControlLimits(nodeID);
			if (light_val <= ucl && 
			    light_val >= lcl){
					if (prvAmbientLightValBynode[nodeID] != 0){
						if (prvAmbientLightValBynode[nodeID] > ucl || 
						    prvAmbientLightValBynode[nodeID] < lcl){
							lightflag = 1;
						}
					}
				}else if (light_val > ucl){
					if (prvAmbientLightValBynode[nodeID] < ucl || prvAmbientLightValBynode[nodeID] == 0){
						lightflag = 2;
					}
				}else if (light_val < lcl){
					if (prvAmbientLightValBynode[nodeID] > lcl || prvAmbientLightValBynode[nodeID] == 0){
						lightflag = 2;
					}
				}
	}


//	METHODS : TRANSACTIONS ON EXCEPTION NORMAL AFTER EXCEPTION	//
//	START	//
	
	
	function TransactionOnSoilTempException(
	    bytes32 nodeID,
	    uint64 timestamp,
	    uint32 soil_temp,
	    bytes32 soil_temphash,
	    SOIL_TEMP_STATE temp_state) public onlyOwner returns(bool flag){
	        bool existed = nodeRegister.isNodeExist(nodeID);
	        if (!existed) revert();
	        if (soil_temp != 0){
    			soilTempExpByNode[nodeID].timeStamp.push(timestamp);
    			soilTempExpByNode[nodeID].temphash.push(soil_temphash);
    			if (temp_state == SOIL_TEMP_STATE(1)){
    				prvSoilTempValBynode[nodeID] = soil_temp;
    			}else{
    				prvSoilTempValBynode[nodeID] = 0;
    			}
    			emit NewTransactionOnSoilTempException (nodeID, soil_temp);
            	flag = true;
			}
	}
	
	function TransactionOnSoilHumidityException(
	    bytes32 nodeID,
	    uint64 timestamp,
	    uint32 soil_humidity,
	    bytes32 soil_humidityhash,
	    SOIL_HUMDTY_STATE humdty_state) public onlyOwner returns(bool flag){
	        bool existed = nodeRegister.isNodeExist(nodeID);
	        if (!existed) revert();
	        if (soil_humidity != 0){
    			soilHumdtyExpByNode[nodeID].timeStamp.push(timestamp);
    			soilHumdtyExpByNode[nodeID].humidityhash.push(soil_humidityhash);
    			if (humdty_state == SOIL_HUMDTY_STATE(1)){
    				prvSoilHumdtyValBynode[nodeID] = soil_humidity;
    			}else{
    				prvSoilHumdtyValBynode[nodeID] = 0;
    			}
    			emit NewTransactionOnSoilHumdtyException (nodeID, soil_humidity);
    			flag = true;
			}
	}
	
	function TransactionOnPhException(
	    bytes32 nodeID,
	    uint64 timestamp,
	    uint32 ph,
	    bytes32 phhash,
	    PH_STATE ph_state) public onlyOwner returns(bool flag){
	        bool existed = nodeRegister.isNodeExist(nodeID);
	        if (!existed) revert();
	        if (ph != 0){
    			phExpByNode[nodeID].timeStamp.push(timestamp);
    			phExpByNode[nodeID].phhash.push(phhash);
    			if (ph_state == PH_STATE(1)){
    				prvPhValBynode[nodeID] = ph;
    			}else{
    				prvPhValBynode[nodeID] = 0;
    			}
    			emit NewTransactionOnPhException (nodeID, ph);
    			flag = true;
			}
	}
	
	function TransactionOnN2Exception(
	    bytes32 nodeID,
	    uint64 timestamp,
	    uint32 n2,
	    bytes32 n2hash,
	    N2_STATE n2_state) public onlyOwner returns(bool flag){
	        bool existed = nodeRegister.isNodeExist(nodeID);
	        if (!existed) revert();
	        if (n2 != 0){
    			n2ExpByNode[nodeID].timeStamp.push(timestamp);
    			n2ExpByNode[nodeID].n2hash.push(n2hash); 
    			if (n2_state == N2_STATE(1)){
    				prvN2ValBynode[nodeID] = n2;
    			}else{
    				prvN2ValBynode[nodeID] = 0;
    			}
    			emit NewTransactionOnN2Exception (nodeID, n2);
    			flag = true;
			}
	}
	
	function TransactionOnAmbientTempException(
	    bytes32 nodeID,
	    uint64 timestamp,
	    uint32 ambient_temp,
	    bytes32 ambient_temphash,
	    AMBIENT_TEMP_STATE ambient_temp_state) public onlyOwner returns(bool flag){
	        bool existed = nodeRegister.isNodeExist(nodeID);
	        if (!existed) revert();
	        if (ambient_temp != 0){
    			ambientTempExpByNode[nodeID].timeStamp.push(timestamp);
    			ambientTempExpByNode[nodeID].temphash.push(ambient_temphash);
    			if (ambient_temp_state == AMBIENT_TEMP_STATE(1)){
    				prvAmbientTempValBynode[nodeID] = ambient_temp;
    			}else{
    				prvAmbientTempValBynode[nodeID] = 0;
    			}
    			emit NewTransactionOnAmbientTempException (nodeID, ambient_temp);
            	flag = true;
			}
	}
	
	function TransactionOnAmbientHumidityException(
	    bytes32 nodeID,
	    uint64 timestamp,
	    uint32 ambient_humidity,
	    bytes32 ambient_humidityhash,
	    AMBIENT_HUMDTY_STATE ambient_humidity_state) public onlyOwner returns(bool flag){
	        bool existed = nodeRegister.isNodeExist(nodeID);
	        if (!existed) revert();
	        if (ambient_humidity != 0){
    			ambientHumdtyExpByNode[nodeID].timeStamp.push(timestamp);
    			ambientHumdtyExpByNode[nodeID].humidityhash.push(ambient_humidityhash);
    			if (ambient_humidity_state == AMBIENT_HUMDTY_STATE(1)){
    				prvAmbientHumdtyValBynode[nodeID] = ambient_humidity;
    			}else{
    				prvAmbientHumdtyValBynode[nodeID] = 0;
    			}
    			emit NewTransactionOnAmbientHumdtyException (nodeID, ambient_humidity);
            	flag = true;
			}
	}
	
	
	function TransactionOnAmbientLightException(
	    bytes32 nodeID,
	    uint64 timestamp,
	    uint32 ambient_light,
	    bytes32 ambient_lighthash,
	    AMBIENT_LIGHT_STATE ambient_light_state) public onlyOwner returns(bool flag){
	        bool existed = nodeRegister.isNodeExist(nodeID);
	        if (!existed) revert();
	        if (ambient_light != 0){
    			ambientLightExpByNode[nodeID].timeStamp.push(timestamp);
    			ambientLightExpByNode[nodeID].lighthash.push(ambient_lighthash);
    			if (ambient_light_state == AMBIENT_LIGHT_STATE(1)){
    				prvAmbientLightValBynode[nodeID] = ambient_light;
    			}else{
    				prvAmbientLightValBynode[nodeID] = 0;
    			}
    			emit NewTransactionOnAmbientLightException (nodeID, ambient_light);
            	flag = true;
			}
	}


//	END	//



//	METHODS : GET EXCEPTIONS AND NORMAL AFTER EXCEPTION BY NODEID 	//
//	START	//

	function getSoilTempException(
		bytes32 nodeID) public view returns (
			uint64[] timeStamp, 
			bytes32[] soil_tempexcphash){
				(timeStamp, soil_tempexcphash) = 
					(soilTempExpByNode[nodeID].timeStamp, soilTempExpByNode[nodeID].temphash );
	}
	

	function getSoilHumdtyException(
		bytes32 nodeID) public view returns (
			uint64[] timeStamp, 
			bytes32[] soil_humidityexcphash){
				(timeStamp, soil_humidityexcphash) = 
					(soilHumdtyExpByNode[nodeID].timeStamp, soilHumdtyExpByNode[nodeID].humidityhash);
	}
	

	function getPhException(
		bytes32 nodeID) public view returns (
			uint64[] timeStamp,
			bytes32[] phexcphash){
				(timeStamp, phexcphash) = 
					(phExpByNode[nodeID].timeStamp, phExpByNode[nodeID].phhash);
	}
	

	function getn2Exception(
		bytes32 nodeID) public view returns (
			uint64[] timeStamp, 
			bytes32[] n2excphash){
				(timeStamp, n2excphash) = 
					(n2ExpByNode[nodeID].timeStamp, n2ExpByNode[nodeID].n2hash);
	}
	
	
	function getAmbientTempException(
		bytes32 nodeID) public view returns (
			uint64[] timeStamp, 
			bytes32[] ambient_tempexcphash){
				(timeStamp, ambient_tempexcphash) = 
					(ambientTempExpByNode[nodeID].timeStamp, ambientTempExpByNode[nodeID].temphash );
	}
	
	function getAmbientHumidityException(
		bytes32 nodeID) public view returns (
			uint64[] timeStamp, 
			bytes32[] ambient_humidityexcphash){
				(timeStamp, ambient_humidityexcphash) = 
					(ambientHumdtyExpByNode[nodeID].timeStamp, ambientHumdtyExpByNode[nodeID].humidityhash );
	}

	function getAmbientLightException(
		bytes32 nodeID) public view returns (
			uint64[] timeStamp, 
			bytes32[] ambient_lightexcphash){
				(timeStamp, ambient_lightexcphash) = 
					(ambientLightExpByNode[nodeID].timeStamp, ambientLightExpByNode[nodeID].lighthash );
	}


//	END	//
    
}