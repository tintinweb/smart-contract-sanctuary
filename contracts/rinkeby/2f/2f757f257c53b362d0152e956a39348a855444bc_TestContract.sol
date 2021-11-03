/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract TestContract{
    function a(address b) public pure returns(uint160){
        return uint160(b);
    } 
}