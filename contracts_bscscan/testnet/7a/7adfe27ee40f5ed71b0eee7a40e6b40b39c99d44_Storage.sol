/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract Storage {

    bytes store_bytes;

    function storeBytes() public {
        bytes memory all = "";
        bytes memory a = "aaaaabbbbb";
        for (uint i = 0; i < 30; i++) {
            all = _mergeBytes(all, a);
        }
        store_bytes = all;
    }

    function getBytes() public pure returns (bytes memory){
        bytes memory all = "";
        bytes memory a = "aaaaabbbbb";
        for (uint i = 0; i < 30; i++) {
            all = _mergeBytes(all, a);
        }
        return all;
    }

    function _mergeBytes(bytes memory a, bytes memory b) private pure returns (bytes memory c) {
        uint alen = a.length;
        uint totallen = alen + b.length;
        uint loopsa = (a.length + 31) / 32;
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            mstore(m, totallen)
            for {let i := 0} lt(i, loopsa) {i := add(1, i)} {mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i)))))}
            for {let i := 0} lt(i, loopsb) {i := add(1, i)} {mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i)))))}
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }


}