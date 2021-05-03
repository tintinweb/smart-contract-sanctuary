/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity ^0.4.25;
contract Victim_Single_Function{
	mapping (address=>uint256) public userbalances;
	
	function withdraw() public returns(bool){
		uint amountToWithdraw = userbalances[msg.sender];
		msg.sender.call.value(amountToWithdraw)();
		userbalances[msg.sender] = 0;
		return true;	
	}
	function updateUserBalance(address _attacker,uint256 _bal) public returns(bool){
		userbalances[_attacker] = _bal;
	}
	function () external payable{
	    
	}
}