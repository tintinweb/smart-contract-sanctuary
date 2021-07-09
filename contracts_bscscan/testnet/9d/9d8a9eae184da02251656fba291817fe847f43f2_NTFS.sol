/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NTFS{
    mapping (uint => string) pic;
    uint256 x=100000;

    function put(string memory s) public returns (uint256) {
        pic[x++] = s;
        return x;
    }
    function get(uint i) public view returns (string memory){
        return pic[i];
    }
}