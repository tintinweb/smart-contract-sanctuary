/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.9;

contract Faucet {
	event Received(uint amount);
	event Send(uint amount);
	
	uint public fundsToSend = 100000000000000000;
	mapping(address => bool) internal requestors;
	
	receive() external payable {
	    emit Received(msg.value);
	}
	
	function requestFaucet() external {
	    require(! requestors[msg.sender]);
	    require(address(this).balance > fundsToSend);
	    
	    requestors[msg.sender] = true;
	    emit Send(fundsToSend);
	    
	    payable(msg.sender).transfer(fundsToSend);
	}
}