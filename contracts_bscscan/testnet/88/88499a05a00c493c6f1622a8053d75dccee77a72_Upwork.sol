//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "./Address.sol";

contract Upwork{
    string public xxx;

    function add(string memory _xxx) public {
        xxx = _xxx;
    }

    function read() public view returns (string memory){
        return xxx;
    }

}