// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract ProxyTest{

    uint256 public count;
    
    function increaseCount() external {
        count += 1;
    }
}