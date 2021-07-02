/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;

contract Calculator{
    uint256 public calculateResult;
    address public user;
    uint256 public callAmount = 0;

    event Add(uint256 a, uint256 b);

    function add(uint256 a, uint256 b) public returns (uint256){
        calculateResult = a+b;
        callAmount ++;

        emit Add(a, b);
        user = msg.sender;
        
        return calculateResult;
    }
}