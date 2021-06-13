// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TubblyToken.sol";

contract TubblySale {

	address admin;
	TubblyToken public tokenContract;
	uint256 public tokenPrice;
	uint256 public tokenSold;
	bool public saleActive;

	mapping(address => uint256) private ethSend;


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

		// AML KYC if deposits above 5 ETH
		require(ethSend[msg.sender] <= 5*10e18, "No AML KYC limit reached");

  		require(saleActive == true, 'Sale is not active');
  		require(msg.value == multiply(_numberOfTokens, tokenPrice));

		// dont allow sender to buy more tokens that there is on sale
		require(tokenContract.balanceOf(address(this)) >= _numberOfTokens, "There is not so much tokens");
		require(tokenContract.transfer(msg.sender, _numberOfTokens));

  		tokenSold += _numberOfTokens;
  		emit Sell(msg.sender, _numberOfTokens);
		
		// add paid eth to mapping
		ethSend[msg.sender] += _numberOfTokens*tokenPrice;
  	}

	function changeTokenPrice(uint _tokenPrice) public {
		require(msg.sender == admin, 'Must be admin');
		tokenPrice = _tokenPrice;
	}

	function saleActive_() public {
		require(msg.sender == admin, 'Must be admin');
		saleActive = false;
	}

  	function endSale() public {
  		require(msg.sender == admin, 'Must be admin');
  		require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
  	}
}