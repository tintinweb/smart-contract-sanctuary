// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';

contract BTokenOracleConstant is IOracle {

    uint256 public immutable price;

    constructor (uint256 price_) {
        price = price_;
    }

    function getPrice() external view override returns (uint256) {
        return price;
    }

}