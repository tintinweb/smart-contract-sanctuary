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

contract summaryData is Ownable{
    
    nodeRegistry public nodeRegister;
    
    function summaryData(address _nodeRegAddr) public{
        nodeRegister = nodeRegistry(_nodeRegAddr);
    }
        //	METHOD : STORE SUMMARIZED DATA	//
//	START	//

	struct sumdata{
		bytes32[] soiltempdata;
		bytes32[] soilhumiditydata;
		bytes32[] phdata;
		bytes32[] n2data;
		bytes32[] ambtempdata;
		bytes32[] ambhumiditydata;
		bytes32[] amblightdata;
		uint64[] timestamp;
	}

	mapping (bytes32=> sumdata) sumdatabynode;
	event newsumdata (
	    bytes32 NodeId,
	    bytes32 SoilTempHash,
	    bytes32 SoilHumidityHash,
	    bytes32 SoilPhHash,
	    bytes32 SoilNitrogenHash,
	    bytes32 AmbientTempHash,
	    bytes32 AmbientHumidityHash,
	    bytes32 AmbientLightHash);

	function Storesumdata (
		bytes32 nodeid,
		bytes32 soiltempdata,
		bytes32 soilhumiditydata,
		bytes32 phdata,
		bytes32 n2data,
		bytes32 ambtempdata,
		bytes32 ambhumiditydata,
		bytes32 amblightdata,
		uint64 timestamp) public onlyOwner returns (bool flag){
			if (!nodeRegister.isNodeExist(nodeid)) revert();
			sumdatabynode[nodeid].soiltempdata.push(soiltempdata);
			sumdatabynode[nodeid].soilhumiditydata.push(soilhumiditydata);
			sumdatabynode[nodeid].phdata.push(phdata);
			sumdatabynode[nodeid].n2data.push(n2data);
			sumdatabynode[nodeid].ambtempdata.push(ambtempdata);
			sumdatabynode[nodeid].ambhumiditydata.push(ambhumiditydata);
			sumdatabynode[nodeid].amblightdata.push(amblightdata);
			sumdatabynode[nodeid].timestamp.push(timestamp);
			emit newsumdata(
			    nodeid,
			    soiltempdata,
			    soilhumiditydata,
			    phdata,
			    n2data,
			    ambtempdata,
			    ambhumiditydata,
			    amblightdata);
			flag = true;

		}


//	METHOD : GET SUMMARIZED DATA BY NODEID	//
//	START	//

	function getsumdata1(bytes32 nodeid) public view returns(
		bytes32[] soiltempdata,
		bytes32[] soilhumiditydata,
		bytes32[] phdata,
		bytes32[] n2data){
			(soiltempdata, soilhumiditydata, phdata, n2data) =
				(	sumdatabynode[nodeid].soiltempdata,
					sumdatabynode[nodeid].soilhumiditydata,
					sumdatabynode[nodeid].phdata,
					sumdatabynode[nodeid].n2data
				);
	}

	function getsumdata2(bytes32 nodeid) public view returns(
		bytes32[] ambtempdata,
		bytes32[] ambhumiditydata,
		bytes32[] amblightdata,
		uint64[] timestamp){
			(ambtempdata, ambhumiditydata, amblightdata, timestamp) =
				(	sumdatabynode[nodeid].ambtempdata,
					sumdatabynode[nodeid].ambhumiditydata,
					sumdatabynode[nodeid].amblightdata,
					sumdatabynode[nodeid].timestamp
				);
	}


//  END //
}