// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Token.sol";

contract CrowdSale {

    using SafeMath for uint256;

    address payable admin;
    Token public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

    constructor(Token _tokenContract, uint256 _tokenPrice) public {
        // whoever deployed is the owner (i.e. admin)
        admin = msg.sender;
        
        // address of the Token contract
        tokenContract = _tokenContract;
        
        // ether cost of token
        tokenPrice = _tokenPrice;
    }

    // mark as payable so Ether may be sent by investors
    function buyTokens(uint256 _numberOfTokens) public payable {
        // msg.value contains the Ether sent by investor
        require(msg.value == _numberOfTokens.mul(tokenPrice), "ether must equal num tokens * token price");
        
        // check Token contract to see Crowd Sale contract's balance is enough
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens, "num tokens requested exceeds supply");
        
        // transfer tokens to msg.sender (investor's address) 
        require(tokenContract.transfer(msg.sender, _numberOfTokens), "failed to send tokens");

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin, "only admin can end sale");
        
        // deposit remaining tokens to admin's account
        require(tokenContract.transfer(
            admin,
            tokenContract.balanceOf(address(this))
        ), "failed to send tokens");

        // transfer Crowd Sale contract's Ether balance to the admin's account
        admin.transfer(address(this).balance);
    }
}