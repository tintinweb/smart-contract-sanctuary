/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Counter {

    mapping(address=>uint256) public callerCount;

    event Called(address user,uint256 count);

    function call() public {
        callerCount[msg.sender]+=1;
        emit Called(msg.sender,callerCount[msg.sender]);
    }
}