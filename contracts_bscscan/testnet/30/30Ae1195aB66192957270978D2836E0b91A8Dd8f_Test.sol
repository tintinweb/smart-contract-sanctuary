/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Test {
    
    

    function getBlockTime() external view returns(uint256) {

        return block.timestamp;
    }

}