/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: GPL-3.0
// simple solidity program with setter and getters 

pragma solidity ^0.6.0;



contract AfricaDataSchool {
    
    // variables decalaration
    string private username = "Jordan";
    string message = "";
    uint private age;
    
    // Hello Africa!
    // key words
    // memory --> reserve storage
    // public --> can be accessed publicly by anyone
    
    // setters username, message, age
    function setUsername(string memory newUsername) public {
        username = newUsername;
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function setAge(uint newAge) public {
        age = newAge;
    }
    
    // getters username, message, age
    function getUsername() public view returns (string memory) {
        return username;
    }
    
    function getMessage() public view returns (string memory) {
      return message;  
    }

    function getAge() public view returns (uint) {
        return age;
    }
}