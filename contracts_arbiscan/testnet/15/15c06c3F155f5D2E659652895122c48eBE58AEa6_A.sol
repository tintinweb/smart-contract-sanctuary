/**
 *Submitted for verification at arbiscan.io on 2021-11-10
*/

pragma solidity ^0.5.0;

contract A {
    uint256 public aNumber;
    string public aString;
    bool public aBool;
    address public anAddress;
    uint test;
    
    uint256[] public anArrayOfNumber;
    string[] public anArrayOfString;
    bool[] public anArrayOfBool;
    address[] public anArrayOfAddress;

    // basic data types
    function setaNumber(uint256 _a) public {
        aNumber = _a;
    }
    
    function setaString(string memory _a) public {
        aString = _a;
    }

    function setaBool(bool _a) public {
        aBool = _a;
    }

    function setanAddress(address _a) public {
        anAddress = _a;
    }
    // basic datatypes
    
    
    // array datatypes
    function setanArrayOfNumber(uint256[] memory _a) public {
        anArrayOfNumber = _a;
    }
    

    function setanArrayOfBool(bool[] memory _a) public {
        anArrayOfBool = _a;
    }

    function setanArrayOfAddress(address[] memory _a) public {
        anArrayOfAddress = _a;
    }
    // array datatypes
}