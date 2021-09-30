/**
 *Submitted for verification at polygonscan.com on 2021-09-30
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Sto{
    string public name;
    
    function set(string memory _name) public{
        name=_name;
    }
    
    function get() public view returns(string memory){
        return name;
    }
}