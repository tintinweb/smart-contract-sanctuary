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

contract summaryData is Ownable{
    
    nodeRegistry public nodeRegister;
	mapping (bytes32=> sumdata) sumdatabynode;
    
    function summaryData(address _nodeRegAddr) public{
        nodeRegister = nodeRegistry(_nodeRegAddr);
    }

	struct sumdata{
		bytes32[] summerizedDataHash;
		uint64[] timestamp;
	}
	
	event newsumdata (
	    bytes32 NodeId,
		bytes32 SummerizedDataHash,
		uint64 Timestamp
	);

	function Storesumdata (
		bytes32 nodeid,
		bytes32 summerizedDataHash,
		uint64 timestamp) 
		public 
		onlyOwner 
		returns (bool flag){
			if (!nodeRegister.isNodeExist(nodeid)) revert();
			sumdatabynode[nodeid].summerizedDataHash.push(summerizedDataHash);
			sumdatabynode[nodeid].timestamp.push(timestamp);
			emit newsumdata(
			    nodeid,
				summerizedDataHash,
				timestamp);
			flag = true;
	}
	
	function getSumData(
	    bytes32 nodeid) 
	    public 
	    view 
	    returns (
	        bytes32[] summerizedDataHash,
	        uint64[] timestamp
	        ){
	            summerizedDataHash = sumdatabynode[nodeid].summerizedDataHash;
	            timestamp = sumdatabynode[nodeid].timestamp;
    }

}