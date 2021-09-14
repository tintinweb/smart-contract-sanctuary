/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.4.23;

contract phi_chat {
	string Message;

	function setMessage (string newMessage) public {
		Message = newMessage;
}

	function getMessage() public constant returns (string) {
		return Message;
}
		
}