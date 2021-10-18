/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.9;

contract Faucet {
	event Received(uint amount);
	event Send(uint amount);
	event RequestForFriend(address requestor, address friend);
	
	uint public fundsToSend = 0.1 * 10 ** 18;
	uint public fundsToSendForFriends = 0.001 * 10 ** 18;
	mapping(address => bool) internal requestors;
	mapping(address => bool) internal requestorsFriends;
	
	receive() external payable {
	    emit Received(msg.value);
	}
	
	function requestFaucetFor(address payable friendsAddr) external {
	    require(! requestorsFriends[friendsAddr]);
	    require(address(this).balance > fundsToSendForFriends);
	    
	    requestorsFriends[friendsAddr] = true;
	    emit Send(fundsToSendForFriends);
	    emit RequestForFriend(msg.sender, friendsAddr);
	    
	    friendsAddr.transfer(fundsToSendForFriends);
	}
	
	function requestFaucet() external {
	    require(! requestors[msg.sender]);
	    require(address(this).balance > fundsToSend);
	    
	    requestors[msg.sender] = true;
	    emit Send(fundsToSend);
	    
	    payable(msg.sender).transfer(fundsToSend);
	}
}