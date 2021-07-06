// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * The TubblySale contract does this and that...
 */

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
  		require(msg.value == multiply(_numberOfTokens, tokenPrice));
		require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
      	require(tokenContract.transfer(msg.sender, _numberOfTokens));

  		tokenSold += _numberOfTokens;
  		emit Sell(msg.sender, _numberOfTokens);
  	}

    function startNewPhase(uint256 _tokenPrice, uint256 tokenAmount) public {
		require(msg.sender == admin, "Can only be inoked by admin");
		require(tokenContract.balanceOf(address(this)) >= tokenAmount);
		saleActive = true;
		tokenPrice = _tokenPrice;

    }

  	function endSale() public {
  		require(msg.sender == admin);
		// require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));

		payable(admin).transfer(address(this).balance);
  		saleActive = false;
  	}
}