/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

//SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.6.0<0.9.0;

contract MappingExe{
    
    mapping(address => mapping(uint8 => identity)) public myStore;
    string name = "naveen";
    
    
    struct identity{
         string firstName;
         string lastName;
       
    }
    
    function addIdentity(uint8 _id, string memory _lastName, string memory _firstName) public {
        myStore[msg.sender][_id] = identity(_firstName,_lastName);
        
    }
    
}