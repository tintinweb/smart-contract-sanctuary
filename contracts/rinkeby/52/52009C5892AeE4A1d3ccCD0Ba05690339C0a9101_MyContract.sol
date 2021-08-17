/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

contract MyContract {
    address owner;
    uint256 tokenPrice;
    constructor () {
        owner = msg.sender;
    }
    function setTokenprice(uint256 price) public {
        require(owner == msg.sender, "only owner can call this function");
        tokenPrice = price;
    }
    function getTokenprice() public view returns (uint256) {
        return tokenPrice;
    }
}