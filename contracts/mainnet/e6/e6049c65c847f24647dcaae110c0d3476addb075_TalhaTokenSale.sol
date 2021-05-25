pragma solidity ^0.5.16;

import "./TalhaToken.sol";

contract TalhaTokenSale {
    address payable auctioneer; 

    uint256 public tokenPrice;
    uint256 public tokensSold;
    TalhaToken public tokenContract;

    event Sell(address _buyer, uint256 _amount);

    constructor(TalhaToken _tokenContract, uint256 _tokenPrice) public {
    	auctioneer = msg.sender;
    	tokenContract = _tokenContract;
    	tokenPrice = _tokenPrice;
    }

    //Taken from DS-Math. [https://github.com/dapphub/ds-math/blob/master/src/math.sol]
    function multiply(uint x, uint y) internal pure returns (uint z) {
    	require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
    	require(msg.value == multiply(_numberOfTokens, tokenPrice));
    	require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
    	require(tokenContract.transfer(msg.sender, _numberOfTokens));

    	tokensSold += _numberOfTokens;

    	emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
    	require(msg.sender == auctioneer);
    	require(tokenContract.transfer(auctioneer, tokenContract.balanceOf(address(this))));

    	auctioneer.transfer(address(this).balance);
    }
}