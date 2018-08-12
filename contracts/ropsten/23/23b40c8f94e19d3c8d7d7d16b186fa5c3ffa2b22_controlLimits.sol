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
		bytes32 nodeID) 
		public 
		onlyOwner 
		returns (bool flag){
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
    	uint8[] parameters ) 
		public 
		returns(bool flag){
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