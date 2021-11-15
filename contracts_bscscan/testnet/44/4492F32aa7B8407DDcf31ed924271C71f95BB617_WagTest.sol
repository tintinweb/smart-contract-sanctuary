//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract WagTest {
    uint256 public n;
    function getTVL() external pure returns(uint256){
        return 249678900000000000000000;
    }

    function addNumber(uint256 _amount) external returns(uint256){
        n = n +_amount;
        return n;
    }
}

