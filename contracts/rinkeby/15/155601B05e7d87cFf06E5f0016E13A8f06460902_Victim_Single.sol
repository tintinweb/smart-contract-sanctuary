/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.4.26;
contract Victim_Single{
	mapping (address=>uint256) public userbalances;
	
	function withdraw() public returns(bool){
		uint amountToWithdraw = userbalances[msg.sender];
		msg.sender.call.value(amountToWithdraw)();
		userbalances[msg.sender] = 0;
		return true;	
	}
	function updateUserBalance(address _attacker,uint256 _bal) public payable returns(bool){
		userbalances[_attacker] = _bal;
	}
	function () external payable{
	    
	}
}