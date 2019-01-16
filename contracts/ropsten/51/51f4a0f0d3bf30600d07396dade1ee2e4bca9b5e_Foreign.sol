pragma solidity ^0.4.24;

/* Bridge Smart Contract 
* @noot
* to be deployed on ropsten, rinkeby, and kovan.
*/

contract Foreign {
	event ContractCreation(address _owner);
	event Deposit(address _recipient, uint _value, uint _toChain); 

	constructor() public {
		emit ContractCreation(msg.sender);
	}

	function deposit(address _recipient, uint _toChain) public payable {
		address(0).transfer(msg.value);
		emit Deposit(_recipient, msg.value, _toChain);
	}
}