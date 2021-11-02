/**
 *Submitted for verification at polygonscan.com on 2021-11-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract TestContract{
    function a(address b) public pure returns(uint160){
        return uint160(b);
    } 
}