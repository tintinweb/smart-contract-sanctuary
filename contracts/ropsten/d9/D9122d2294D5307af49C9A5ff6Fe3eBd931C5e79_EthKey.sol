/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract EthKey {
    string flag;

    constructor(string memory _flag) {
        flag = _flag;
    }

    function checkKey(uint key) internal pure returns (bool) {
        return key ** 2 == 60543961;
    }

    function getFlag(uint key) public view returns (string memory) {
        require(checkKey(key));
        return flag;
    }
}