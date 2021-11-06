// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Shitcoin.sol";

contract ShitcoinPreSale {
    address payable admin;
    Shitcoin public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    uint256 public tokensToSell;
    
    uint256 public investorHardCap;
    mapping(address => uint256) public contributions;
    
    event Sell(address _buyer, uint256 _amount);
    
    constructor (Shitcoin _tokenContract, uint256 _tokenPrice, uint256 _investorHardCap, uint256 _tokensToSell) {
        admin = payable(msg.sender);
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
        investorHardCap = _investorHardCap;
        tokensToSell = _tokensToSell;
    }

    receive () external payable {
        uint256 _numberOfTokens = (msg.value/tokenPrice) - ((msg.value % tokenPrice) / tokenPrice);
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(contributions[msg.sender] + _numberOfTokens <= investorHardCap);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));
        
        tokensSold += _numberOfTokens;
        contributions[msg.sender] += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
        
        if(tokensSold >= tokensToSell) {
            selfdestruct(admin);
        }
    }
    
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    
    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(contributions[msg.sender] + _numberOfTokens <= investorHardCap);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));
        
        tokensSold += _numberOfTokens;
        contributions[msg.sender] += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
        
        if(tokensSold >= tokensToSell) {
            selfdestruct(admin);
        }
    }

    function end() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        selfdestruct(admin);
    }
}