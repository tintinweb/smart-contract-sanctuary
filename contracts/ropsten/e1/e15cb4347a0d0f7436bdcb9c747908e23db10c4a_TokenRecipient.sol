pragma solidity ^0.4.24;

contract TokenRecipient {
    address public lastApprover; 
    address public lastSender;
    
	function receiveApproval(address _from, uint256 _value, address _token, bytes _data) public {
	    lastApprover = msg.sender;
	}
	
	function tokenFallback(address _from, uint256 _value, bytes _data) public {
	    lastSender = msg.sender;
	}
}