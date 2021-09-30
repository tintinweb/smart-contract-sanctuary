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


    function toBytes(uint _num) internal pure returns (bytes memory _ret) {
        assembly {
            _ret := mload(0x10)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _num)
        }
    }

    function testBytes32() public view returns (bytes32 result){
        bytes memory timestamp =  toBytes(block.timestamp);
        result = keccak256(timestamp);
     }

    uint private mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function generateMask() public {
        bytes32 _mask= keccak256(toBytes(block.timestamp));
        mask=uint(_mask);
    }

    function getMask() public view returns (bytes32){
        return bytes32(mask);
    }

}