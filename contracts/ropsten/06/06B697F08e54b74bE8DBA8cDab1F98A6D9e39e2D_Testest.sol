/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Testest  {
    constructor() payable{
        
    }
    address[] adds;
    string[] strarr;
    function pay() public payable returns(bool){
        
    }

    function test_transfer(address addr,address _addr2, uint256 _amount) public payable returns(bool){
        payable(addr).transfer(_amount);
        payable(_addr2).transfer(_amount);
        payable(addr).transfer(_amount);
        payable(_addr2).transfer(_amount);
        return true;
    }

    function  add_addresss(address[] memory  addrs)public returns(bool){
        for (uint i = 1; i <= addrs.length; i++) {
            adds.push(addrs[i]);
        }

        return true;
    }     
    function  add_addresss1(address[] memory  addrs)public returns(bool){
        for (uint i = 1; i <= addrs.length; i++) {
            adds.push(addrs[i]);
        }

        return true;
    } 
}