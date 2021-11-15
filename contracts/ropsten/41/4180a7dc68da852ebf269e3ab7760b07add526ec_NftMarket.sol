/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Like {
    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
    
    function approve(address, uint256) external returns (bool);
}

contract NftMarket {
    address public revenueRecipient;
    uint256 public constant mintFee = 10 * 1e8;
    ERC20Like public token;
    address public tokenaddress;

    constructor(address _tokenaddress){
        tokenaddress = _tokenaddress;
    }
    
    
    function batch(address[] memory toAddr, uint256[] memory value) public returns (bool){
        require(toAddr.length == value.length && toAddr.length >= 1);
        token = ERC20Like(tokenaddress);
        for(uint256 i = 0 ; i < toAddr.length; i++){
            token.transfer(toAddr[i], value[i]);
        }
        return true;
    }

    function onetransfer(address to,uint256 amount) public returns(bool){
        token = ERC20Like(tokenaddress);
        token.transfer(to,amount);
        return true;
    }
    
}