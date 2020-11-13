/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


contract ConstOracle {
    uint256 public tokenPrice;

    constructor(uint256 _price) public {
        tokenPrice = _price;
    }

    function getPrice() external view returns (uint256) {
        return tokenPrice;
    }
}