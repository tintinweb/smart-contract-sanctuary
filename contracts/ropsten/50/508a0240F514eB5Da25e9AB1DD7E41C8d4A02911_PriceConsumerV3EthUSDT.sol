/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;


contract PriceConsumerV3EthUSDT {
    
    int price = 410700000000000;

    function getLatestPrice() public view returns (int) {
        return price;
    }
    
    function setPrice(int _price) public {
        price = _price;
    }
}