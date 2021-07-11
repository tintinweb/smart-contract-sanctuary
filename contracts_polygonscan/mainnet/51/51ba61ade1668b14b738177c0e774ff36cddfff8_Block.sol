/**
 *Submitted for verification at polygonscan.com on 2021-07-11
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

contract Block {
    function getBlockNum() public view returns (uint256) {
       return block.number;
    }    

}