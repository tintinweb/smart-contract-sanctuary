/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

contract SimpleStorage {
    bytes y;
    string x;

    function write(string memory _x) public {
        x = _x;
    }

    function read() public view returns (string memory) {
        return x;
    }

    function writeByte(bytes memory _y) public {
        y = _y;
    }

    function readBytes() public view returns (bytes memory) {
        return y;
    }
}