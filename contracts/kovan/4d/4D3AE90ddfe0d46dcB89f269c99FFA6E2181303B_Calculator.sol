/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;

contract Calculator{
    uint256 public calculateResult;
    address public user;
    uint256 public callAmount;

    event Add(uint256 a, uint256 b);

    function add(uint256 a, uint256 b) public returns (uint256){
        calculateResult = a+b;
        user = msg.sender;
        callAmount = callAmount + 1;
        emit Add(a, b);
        return calculateResult;
    }
}