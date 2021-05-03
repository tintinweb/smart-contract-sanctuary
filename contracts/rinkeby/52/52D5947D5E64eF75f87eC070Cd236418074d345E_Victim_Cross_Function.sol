/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity 0.4.25;
contract Victim_Cross_Function{
	mapping (address=>uint256) public userbalances;
	function transfer(address to, uint amount) public returns(bool){
		if(userbalances[msg.sender] >= amount){
		userbalances[to] += amount;
		userbalances[msg.sender] -= amount;
		}
		return true;
	}
	
	function withdrawBalance() public returns(bool){
		uint amountToWithdraw = userbalances[msg.sender];
		msg.sender.call.value(amountToWithdraw)();
		userbalances[msg.sender] =0;
		return true;	
	}
	function updateUserBalance(address _attacker,uint256 _bal) public returns(uint){
		userbalances[_attacker] = _bal;
	}
	function deposit(address _attacker)public payable returns(bool){
		userbalances[_attacker] = msg.value;
		return true;
	}
	function getbalance() public view returns(uint){
		return address(this).balance;
	}
}