/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringUtil {
    function equals(string memory _str1, string memory _str2) public pure returns(bool) {
        if (length(_str1) != length(_str2)) {
            return false;
        }

        if (keccak256(abi.encodePacked(_str1)) != keccak256(abi.encodePacked(_str2))) {
            return false;
        }

        return true;
    }

    function length(string memory _str) public pure returns(uint) {
        bytes memory _bytes = bytes(_str);
        return _bytes.length;
    }
}

contract FirstTest {
    using StringUtil for string;

    function f(string memory _str1, string memory _str2) public pure returns(bool) {
        return _str1.equals(_str2);
    }
}