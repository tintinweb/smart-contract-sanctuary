// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestMinusContract {

    uint256 private _substract = 0;

    function latestSubstractValue() external view returns (uint256) {
        return _substract;
    }

    function minus(uint256 a, uint256 b) external {
        require(a > b, "first value should be larger than second value");
        uint256 substract = a - b;

        _substract = substract;
    }
}