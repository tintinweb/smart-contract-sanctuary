/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity >0.8.0;

contract Test{

    constructor(){
    }

    function time() public view returns(uint256) {
        return block.timestamp;
    }
}