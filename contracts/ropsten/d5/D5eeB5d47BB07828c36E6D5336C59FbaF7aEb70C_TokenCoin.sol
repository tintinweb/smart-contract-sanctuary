/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity ^0.4.19;
contract TokenCoin{
	address _owner;
	mapping(address=>uint256) balances;
	function TokenCoin(){
		_owner = msg.sender; 
	}

	function deposit(uint256 amount) public payable{
		balances[msg.sender] += amount;
	}
	
	function withdraw(uint256 amount) public payable{
		require(balances[msg.sender] >= amount);
		require(this.balance >= amount);
		
		msg.sender.call.value(amount)();
		balances[msg.sender]  -= amount;
	}
	function AccountBalance(address addr) returns(uint256){
		return balances[addr];
	}
	function ContractBalance() returns(uint256){
		return this.balance;
	}
}