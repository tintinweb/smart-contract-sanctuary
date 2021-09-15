/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

contract Upwork{
    string public xxx;

    function add(string memory _xxx) public {
        xxx = _xxx;
    }

    function read() public view returns (string memory){
        return xxx;
    }

}