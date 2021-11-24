// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

contract PriceConsumerV3EthUSDT {
    int price = 437264000000;

    function setPrice(int _price) public {
        price = _price;
    }

    function getLatestPrice() public view returns (int) {
        return price;
    }
}