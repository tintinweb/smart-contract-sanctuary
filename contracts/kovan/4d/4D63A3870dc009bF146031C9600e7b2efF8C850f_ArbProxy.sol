/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


// 
interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}

contract ArbProxy {

	address public arbMemory;
	address public owner;

	modifier onlyOwner() {
		require(owner == msg.sender, "caller is not the owner");
		_;
	}

	constructor(address arbMemory_) public
	{
		arbMemory = arbMemory_;
		owner = msg.sender;
	}

	function setArbMemory(address arbMemory_)
		external
		onlyOwner
	{
		arbMemory = arbMemory_;
	}

	function transferOwnership(address newOwner_) 
		external 
		onlyOwner 
	{
		require(newOwner_ != address(0), "new owner is the zero address");
		owner = newOwner_;
	}

	function withdrawERC20(address tokenAddress_)
		external
		onlyOwner
	{
		IERC20 _token = IERC20(tokenAddress_);
		uint256 _balance = _token.balanceOf(address(this));
		if (_balance > 0) {
				_token.transfer(msg.sender, _balance);
		}
	}

	function withdrawETH()
		external
		onlyOwner
	{
		uint256 _balance = address(this).balance;
		if (_balance > 0) {
				msg.sender.transfer(_balance);
		}
	}

	receive() external payable {
	}

	function spell(address target_, bytes memory data_) 
		internal 
	{
		require(target_ != address(0), "target-invalid");
		assembly {
			let succeeded := delegatecall(gas(), target_, add(data_, 0x20), mload(data_), 0, 0)

			switch iszero(succeeded)
				case 1 {
					// throw if delegatecall failed
					let size := returndatasize()
					returndatacopy(0x00, 0x00, size)
					revert(0x00, size)
				}
		}
	}
	
	function cast(
		address[] calldata targets_,
		bytes[] calldata datas_
	)
		external
		payable
		onlyOwner
	{
		require(targets_.length == datas_.length , "array-length-invalid");
		for (uint i = 0; i < targets_.length; i++) {
			spell(targets_[i], datas_[i]);
		}
	}

}