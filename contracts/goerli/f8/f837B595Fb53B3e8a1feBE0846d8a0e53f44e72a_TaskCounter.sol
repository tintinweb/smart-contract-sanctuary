/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

//SPDX-License-Identifier: UNLISCENCED
pragma solidity ^0.8.4;

contract TaskCounter {
    uint numberOfTasks;
    function newTask() public {
        numberOfTasks = numberOfTasks + 1;
    }
    function taskCount() public view returns (uint) {
        return numberOfTasks;
    }
}