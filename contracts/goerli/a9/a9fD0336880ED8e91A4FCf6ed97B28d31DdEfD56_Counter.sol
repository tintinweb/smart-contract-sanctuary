/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract Counter{

    uint count;
    constructor() {
        count = 1;
    }

    function increaseCounter() external{
        count += 1;
    }

    function getCurrentCount() external view returns(uint){
        return count;
    }
}