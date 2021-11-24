pragma solidity ^0.6.0;

import "./GOONappToken.sol";

contract GOONappTokenSale {
    address payable admin;
    GOONappToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);
    event Bought(uint256 amount);

    constructor (GOONappToken _tokenContract, uint256 _tokenPrice) public payable{
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    receive() external payable {
        if (msg.sender == admin) {
            admin.send(address(this).balance);
        }
        else {
            uint256 amountTobuy = msg.value / tokenPrice;
            uint256 dexBalance = tokenContract.balanceOf(address(this));
            require(amountTobuy > 19999, "Minimal amount to buy is 20000");
            require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
            require(tokenContract.transfer(msg.sender, amountTobuy));
            tokensSold += amountTobuy;
            emit Sell(msg.sender, amountTobuy);
        }
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));
        tokensSold += _numberOfTokens;
        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        selfdestruct(admin);
    }
}