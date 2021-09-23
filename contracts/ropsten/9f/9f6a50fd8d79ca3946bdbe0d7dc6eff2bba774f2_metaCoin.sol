/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity >=0.4.22 <0.6.0;

contract metaCoin {	
	mapping (address => uint) balances;
	constructor() public {
		balances[msg.sender] = 10000;
	}
	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
		if (balances[msg.sender] < amount) return false;
		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		return true;
	}
}