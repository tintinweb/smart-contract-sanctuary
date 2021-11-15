// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0<0.8.0;

contract PayableContract {

	address public owner;
	address public admin;

	event Transfer(address indexed _to, uint256 _value);
	event Receive(address indexed _from, uint256 _value);

	modifier onlyAdmin() {
		require(msg.sender == admin, "Admin privileges only");
		_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Owner privilege only");
		_;
	}

	/**
	* @notice Set the default admin and owner
	* as the address that deploys smart contract  
	*/
	constructor() {
		admin = msg.sender;
		owner = admin;
	}

	/**
	* @param _newOwner is payable address of new owner
	* @return status
	* previous owner can't be new owner
	*/ 
	function transferOwnership(address _newOwner) public onlyAdmin returns(bool status){
		require(_newOwner != address(0));

		address previousOwner = owner;

		require(previousOwner != _newOwner);

		owner = _newOwner;

		return true;
	}

	/**
	* Withdraw all funds
	*/ 
	function withdrawAll() public onlyOwner {
		uint amount = address(this).balance;

		(bool success,) = msg.sender.call{value: amount}("");

		require(success, "withdrawAll: Transfer failed");

		emit Transfer(msg.sender, amount);
	}

	/**
	* @param amount Amount to withdraw in wei
	*/
	function withdrawPartial(uint amount) public onlyOwner {
		(bool success,) = msg.sender.call{value: amount}("");

		require(success, "withdrawPartial: Transfer failed");

		emit Transfer(msg.sender, amount);
	}

	receive() external payable{
		emit Receive(msg.sender, msg.value);
	}

	// function callRevert() public payable {
	// 	triggerRevert(msg.value);
	// }

	// function triggerRevert(uint amount) private pure {
	// 	require(amount % 2e18 == 0, 'Not even');
	// }

	/**
	* @dev Retrive all funds and destroy contract
	* in case of emergency
	*/
	function killSwitch() public onlyAdmin() {
		address payable _owner = payable(owner);

		selfdestruct(_owner);
	} 

}

