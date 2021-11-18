/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A simple contract on solidity variables and data types
/// @author Ishika Mukerji 

contract MyTypesAndVariables {
    // State Variables
    string public myString = "Hello World!";
    bytes32 public myBytes32 = "Hola World.";
    int public myInt = 1; 
    uint public myUint = 1; 
    uint256 public myUint256 = 2; 
    uint8 public myUint8 = 3;
    address public myAddress = 0x01A49c4f608a80F2D657f6689E30719B1889800d ; 
    
    struct MyStruct {
        uint myInt;
        string myString; 
    }
    
    MyStruct public myIdCard = MyStruct(1, "Ishika, Mukerji"); 
    
    function getValue() public pure returns(uint) {
        uint value = 1;   // Local variable 
        return value; 
    }
}