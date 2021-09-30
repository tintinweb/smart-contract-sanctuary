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

    function toBytes(uint x) public view returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function testBytes32() public view returns (bytes memory result){
        uint a = 0xffff;
        uint b = 0xabc;
        uint c =  b ^ a ^ a;

        result = toBytes(c);
     }

}