/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract miprimero {
    
    uint num;
    string[] names;
    
    mapping (string => uint) public namenum;
    
    function addcel(string memory _name, uint _numero) public {
        namenum[_name] = _numero;
    }
    
    function getceli(string memory _name) public view returns(uint) {
        return namenum[_name];
    }
    function ad(string memory _names) public {
        names.push(_names);
    }
    
    function inde(uint _index) public view returns(string memory) {
        return names[_index];
    }
    
    function change(uint n) public {
        num = n;
    }

    function get() public view returns(uint) {
        return num;
    }
    
    
}