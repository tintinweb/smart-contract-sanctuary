// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract LendingPoolAddressesProviderMock {
    address internal pool;
    address internal core;

    constructor(address _pool) {
        pool = _pool;
    }

    function getLendingPool() external view returns (address) {
        return pool;
    }
}