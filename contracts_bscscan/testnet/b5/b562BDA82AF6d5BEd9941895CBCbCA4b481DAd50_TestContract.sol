/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


contract TestContract{

    function testUint() public view returns (uint){
        uint a = 0xffff;
        uint b = 0xabc;
        return b ^ a ^ a;
    }


    function testBytes32() public view returns (bytes32 result){
        uint a = 0xffff;
        uint b = 0xabc;
        uint c =  b ^ a ^ a;

        result = bytes32(c);
     }

}