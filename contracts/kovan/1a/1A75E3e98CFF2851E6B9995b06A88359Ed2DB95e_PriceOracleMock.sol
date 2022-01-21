/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PriceOracleMock {
	int256 internal price;
	uint8 public decimals; 
	
	receive() external payable {
	}
	function kill(address payable beneficiary_)
		external
	{
		selfdestruct(beneficiary_);
	}
	function setPrice(int256 price_)
		external
	{
		price = price_;
	}
	function latestAnswer()
		external
		view
		returns(int256)
	{
		return price;
	}
}