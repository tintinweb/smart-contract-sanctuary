/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract demotoken{
    
    event messgae(string);
    uint public age;
    event ageCaller (uint);
    function setage(uint _age) public  returns(uint){
        age = _age;
        emit ageCaller(age);
        return age;
    }
    
    function getage() public view returns(uint){
        return age;
        
    }
}