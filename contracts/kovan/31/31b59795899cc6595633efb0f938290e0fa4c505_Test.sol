/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

contract Test{
    
     uint256 private constant MAX = ~uint256(0);
    
    function showInfo() public pure returns(uint256){
        return MAX;
    }
}