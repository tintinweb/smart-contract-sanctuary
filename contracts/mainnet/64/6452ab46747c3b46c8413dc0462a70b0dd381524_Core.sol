/*
Please note, there are 3 native components to this token design. Token, Router, and Core. 
Each component is deployed separately as an external contract.

This is the main code of a mutable token contract.
The Router component is the mutable part and it can be re-routed should there be any code updates.
Any other contract is also external and it must be additionally registered and routed within the native components.
The main idea of this design was to follow the adjusted Proxy and the MVC design patterns.
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.7 .0;

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

}

abstract contract Context {
	function _msgSender() internal view virtual returns(address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes memory) {
		this;
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns(address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

interface IERC20 {

	function currentTokenContract() external view returns(address routerAddress);

	function currentRouterContract() external view returns(address routerAddress);

	function transfer(address[2] memory addressArr, uint[2] memory uintArr) external returns(bool success);

	function approve(address[2] memory addressArr, uint[2] memory uintArr) external returns(bool success);

	function transferFrom(address[3] memory addressArr, uint[3] memory uintArr) external returns(bool success);

	function increaseAllowance(address[2] memory addressArr, uint[2] memory uintArr) external returns(bool success);

	function decreaseAllowance(address[2] memory addressArr, uint[2] memory uintArr) external returns(bool success);

	function mint(address[2] memory addressArr, uint[2] memory uintArr) external returns(bool success);

	function burn(address[2] memory addressArr, uint[2] memory uintArr) external returns(bool success);
	
	function updateTotalSupply(uint[2] memory uintArr) external returns(bool success);
		    
	function updateCurrentSupply(uint[2] memory uintArr) external returns(bool success);
	
	function updateJointSupply(uint[2] memory uintArr) external returns(bool success);

}

abstract contract Token {
	function balanceOf(address account) external view virtual returns(uint256 data);

	function allowance(address owner, address spender) external view virtual returns(uint256 data);
	
	function updateTotalSupply(uint newTotalSupply) external virtual returns(bool success);
	
	function updateCurrentSupply(uint newCurrentSupply) external virtual returns(bool success);
	
	function updateJointSupply(uint newCurrentSupply) external virtual returns(bool success);

	function emitTransfer(address fromAddress, address toAddress, uint amount, bool affectTotalSupply) external virtual returns(bool success);

	function emitApproval(address fromAddress, address toAddress, uint amount) external virtual returns(bool success);

}

//============================================================================================
// MAIN CONTRACT 
//============================================================================================

contract Core is IERC20, Ownable {

	using SafeMath
	for uint256;

	address public tokenContract;
	address public routerContract;
	Token private token;

	function currentTokenContract() override external view virtual returns(address tokenAddress) {
		return tokenContract;
	}

	function currentRouterContract() override external view virtual returns(address routerAddress) {
		return routerContract;
	}

	function setNewTokenContract(address newTokenAddress) onlyOwner public virtual returns(bool success) {
		tokenContract = newTokenAddress;
		token = Token(newTokenAddress);
		return true;
	}

	function setNewRouterContract(address newRouterAddress) onlyOwner public virtual returns(bool success) {
		routerContract = newRouterAddress;
		return true;
	}

	//============== NATIVE FUNCTIONS START HERE ==================================================
	//These functions should never change when introducing a new version of a router.
	//Router is expected to constantly change, and the code should be written under 
	//the "NON-CORE FUNCTIONS TO BE CODED BELOW".

	function transfer(address[2] memory addressArr, uint[2] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: transfer | message: Must be called by the registered Router contract");
		_transfer(addressArr, uintArr);
		return true;
	}

	function _transfer(address[2] memory addressArr, uint[2] memory uintArr) private returns(bool success) {
		address fromAddress = addressArr[0];
		address toAddress = addressArr[1];

		require(fromAddress != address(0), "at: core.sol | contract: Core | function: _transfer | message: Sender cannot be address(0)");

		uint amount = uintArr[0];

		require(amount <= token.balanceOf(fromAddress), "at: core.sol | contract: Core | function: _transfer | message: Insufficient amount");

		token.emitTransfer(fromAddress, toAddress, amount, false);
		return true;
	}

	function approve(address[2] memory addressArr, uint[2] memory uintArr) override external returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: approve | message: Must be called by the registered Router contract");
		_approve(addressArr, uintArr);
		return true;
	}

	function _approve(address[2] memory addressArr, uint[2] memory uintArr) private returns(bool success) {
		address owner = addressArr[0];
		address spender = addressArr[1];
		uint amount = uintArr[0];

		require(owner != address(0), "at: core.sol | contract: Core | function: _approve | message: ERC20: approve from the zero address");
		require(spender != address(0), "at: core.sol | contract: Core | function: _approve | message: ERC20: approve to the zero address");

		token.emitApproval(owner, spender, amount);

		return true;
	}

	function transferFrom(address[3] memory addressArr, uint[3] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: transferFrom | message: Must be called by the registered Router contract");
		uint allowance = token.allowance(addressArr[1], addressArr[0]);
		require(allowance >= uintArr[0], "at: core.sol | contract: Core | function: transferFrom | message: Insufficient amount");

		address[2] memory tmpAddresses1 = [addressArr[1], addressArr[2]];
		address[2] memory tmpAddresses2 = [addressArr[1], addressArr[0]];

		uint[2] memory tmpUint = [uintArr[0], uintArr[1]];

		
		_transfer(tmpAddresses1, tmpUint);
		
		tmpUint = [allowance.sub(uintArr[0]), uintArr[1]];
		_approve(tmpAddresses2, tmpUint);

		return true;
	}

	function increaseAllowance(address[2] memory addressArr, uint[2] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: increaseAllowance | message: Must be called by the registered Router contract");
		uint newAllowance = token.allowance(addressArr[0], addressArr[1]).add(uintArr[0]);
		uintArr[0] = newAllowance;
		_approve(addressArr, uintArr);
		return true;
	}

	function decreaseAllowance(address[2] memory addressArr, uint[2] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: decreaseAllowance | message: Must be called by the registered Router contract");
		uint newAllowance = token.allowance(addressArr[0], addressArr[1]).sub(uintArr[0], "at: core.sol | contract: Core | function: decreaseAllowance | message: Decreases allowance below zero");
		uintArr[0] = newAllowance;
		_approve(addressArr, uintArr);
		return true;

	}

	//============== NATIVE FUNCTIONS END HERE ==================================================


	//=============== NON-NATIVE FUNCTIONS TO BE CODED BELOW ====================================
	// This code is a subject to a change, should we decide to alter anything.
	// We can also design another external contract, possibilities are infinite.

	function mint(address[2] memory addressArr, uint[2] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: mint | message: Must be called by the registered Router contract");
		address fromAddress = address(0);
		address toAddress = addressArr[1];
		uint amount = uintArr[0];
		token.emitTransfer(fromAddress, toAddress, amount, false);
		return true;
	}

	function burn(address[2] memory addressArr, uint[2] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: burn | message: Must be called by the registered Router contract");
		address fromAddress = addressArr[0];
		address toAddress = address(0);
		uint amount = uintArr[0];
		token.emitTransfer(fromAddress, toAddress, amount,false);
		return true;
	}
	
	function updateTotalSupply(uint[2] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: updateTotalSupply | message: Must be called by the registered Router contract");
		uint amount = uintArr[0];
		token.updateTotalSupply(amount);
		return true;
	}
	
	function updateCurrentSupply(uint[2] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: updateCurrentSupply | message: Must be called by the registered Router contract");
		uint amount = uintArr[0];
		token.updateCurrentSupply(amount);
		return true;
	}
	
	function updateJointSupply(uint[2] memory uintArr) override external virtual returns(bool success) {
		require(msg.sender == routerContract, "at: core.sol | contract: Core | function: updateCurrentSupply | message: Must be called by the registered Router contract");
		uint amount = uintArr[0];
		token.updateJointSupply(amount);
		return true;
	}
	
}