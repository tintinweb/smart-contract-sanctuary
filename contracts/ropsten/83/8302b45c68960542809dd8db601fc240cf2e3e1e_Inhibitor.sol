/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Inhibitor {
    string str;

    function store(string memory s) public {
        str = s;
    }

    function retrieve() public view returns (string memory){
        return str;
    }
}