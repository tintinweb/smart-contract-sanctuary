/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Simp{
    uint256 public x = 5;

    function ch(uint256 t) public{
        x=t;
    }

    function vv(uint256 j) public view returns(uint256){
        return x+j;
    }

}