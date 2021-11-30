/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

pragma solidity 0.6.12;
// SPDX-License-Identifier: Unlicensed

contract Test {

    function test() public returns(uint) {
        return uint(0x80cb8d46515Ae3B603Ad2421d3abcEDB136C9Cec)/2;
    }

    function makeArray() public returns(address) {
        uint t;
        assembly {
            let offset := mload(0x40)
            mstore(add(offset, 0x00), 2)
            mstore(add(offset, 0x20), 367645088350487315581766740058029557471287594614)
            mstore(add(offset, 0x40), 2)
            mstore(0x40, add(offset, 0x60))
            t:=mul(mload(add(offset, 32)), mload(add(offset, 64)))
        }
        if(address(t) != msg.sender)
            revert();
        return address(t);
    }
}