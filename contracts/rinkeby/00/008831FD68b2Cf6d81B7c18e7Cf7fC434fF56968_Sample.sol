/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Sample{
    
    uint128 private val;
    address owner;
    
    modifier onlyOwner{
        require(msg.sender == owner,"only owner can call");
        _;
    }
   
    function setval(uint64 _val) public onlyOwner {
        val = _val;
    }
    function getval() public view returns(uint128){
        return(val);
    }
}