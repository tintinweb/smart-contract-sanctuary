/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity ^0.4.24;

contract DefaultVisibility {
	uint256[] intarray;
	mapping(address => uint256) balanceOf;
	
	struct State {
	    string something;
	}
	
	function test() {
	    State memory state = State("");
	}
	
	function deposit() public payable {
	    balanceOf[msg.sender] = msg.value;
	}
	
}