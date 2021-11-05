/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    string data;

   
    function store(string memory _data) public {
        data = _data;
    }

    
    function retrieve() public view returns (string memory){
        return data;
    }
}