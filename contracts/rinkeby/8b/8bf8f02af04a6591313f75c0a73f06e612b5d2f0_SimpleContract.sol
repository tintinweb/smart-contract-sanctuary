/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract SimpleContract {
    uint public myValue = 50;
    string public myString = "Hello World!";
    
    function setValue(uint _myValue) public {
        myValue = _myValue;
    }
    
    function setString(string memory _myString) public {
        myString = _myString;
    }    
}