// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract ProxyTest{

    uint256 public count;

    function increaseCount(uint256 number) external {
        count += 1;
    }
}