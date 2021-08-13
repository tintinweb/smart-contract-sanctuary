/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

/*
simpleChat
*/
pragma solidity ^0.4.23;

contract simpleChat {
	string Message;

	function sendMessage (string newMessage) public {
		Message = newMessage;
}

	function getMessage() public constant returns (string) {
		return Message;
}
		
}