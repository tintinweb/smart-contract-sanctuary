/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.4.26;
contract Victim_Single3{
	mapping (address=>uint256) public userbalances;
	
	function withdraw() public returns(bool){
	    require(userbalances[msg.sender] > 0,"Insufficient balance");
		uint256 amount = userbalances[msg.sender];
        require(msg.sender.call.value(amount)());
        userbalances[msg.sender] = 0;
		return true;	
	}
	function updateUserBalance(address _attacker,uint256 _bal) public payable returns(bool){
		userbalances[_attacker] = _bal;
	}
	function () external payable{
	    
	}
}