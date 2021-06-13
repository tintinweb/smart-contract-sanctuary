// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TubblyToken.sol";

contract TubblySale {

	address admin;
	TubblyToken public tokenContract;
	uint256 public tokenPrice;
	uint256 public tokenSold;
	bool saleActive;

	event Sell(
		address  _buyer,
		uint256 _amount
	);

	constructor(TubblyToken _tokenContract, uint256 _tokenPrice) {
		admin = msg.sender;
		tokenContract = _tokenContract;
    	tokenPrice = _tokenPrice;
    	saleActive = true;
  	}

  	function multiply(uint x, uint y) internal pure returns (uint z) {
  		require(y == 0 || (z = x * y) / y == x);
 	  }

  	function buyTokens(uint256 _numberOfTokens) public payable {
  		require(saleActive == true);
		require(_numberOfTokens < 10e19);
  		require(msg.value == multiply(_numberOfTokens, tokenPrice));
		require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
    	require(tokenContract.transfer(msg.sender, _numberOfTokens));

  		tokenSold += _numberOfTokens;
  		emit Sell(msg.sender, _numberOfTokens);
  	}

  	function endSale() public {
  		require(msg.sender == admin);
  		require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
  	}
}