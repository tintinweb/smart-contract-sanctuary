// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./erc721.sol";

contract Exchange{
    
    uint256 price = 100000000 gwei;
    ERC721 token;
    
    constructor(address _token) public{
        token = ERC721(_token);
    }
    
    function buy() external payable{
        uint256 fee = token.getFee();
        payable(address(token)).transfer(fee + price);
        token.transferFrom();
    }
    
    function getTotalPrice() external view returns(uint256){
        uint256 fee = token.getFee();
        return (fee + price);
    }
}