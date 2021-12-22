/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
contract Username {
    string username = "nicolamaisa";
    function retrieve() public view returns ( string memory){
        return username;
    }
}