pragma solidity ^0.4.21;

contract VernamWhiteListDeposit {
	address[] public participants;
	
	address public benecifiary;
	
	mapping (address => bool) public isWhiteList;
	uint256 public constant depositAmount = 10000000000000000 wei;   // 0.01 ETH
	
	uint256 public constant maxWiteList = 9960;					// maximum 10 000 whitelist participant
	
	uint256 public deadLine;
	uint256 public constant whiteListPeriod = 9 days; 			
	
	constructor() public {
		benecifiary = 0x769ef9759B840690a98244D3D1B0384499A69E4F;
		deadLine = block.timestamp + whiteListPeriod;
	}
	
	event WhiteListSuccess(address indexed _whiteListParticipant, uint256 _amount);
	function() public payable {
		require(participants.length <= maxWiteList);               //check does have more than 10 000 whitelist
		require(block.timestamp <= deadLine);					   // check does whitelist period over
		require(msg.value >= depositAmount);					
		require(!isWhiteList[msg.sender]);							// can&#39;t whitelist twice
		
		benecifiary.transfer(msg.value);							// transfer the money
		isWhiteList[msg.sender] = true;								// put participant in witheList
		participants.push(msg.sender);								// put in to arrayy
		emit WhiteListSuccess(msg.sender, msg.value);				// say to the network
	}
	
	function getParticipant() public view returns (address[]) {
		return participants;
	}
	
	function getCounter() public view returns(uint256 _counter) {
		return participants.length;
	}
}