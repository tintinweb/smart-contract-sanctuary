//Solidity Version
pragma solidity ^0.5.0;

//contract Declaration
contract myFirstContract {
    
    //variables Declaration
    string myStringStorage;
    uint myIntegerStorage;
    
    //constructor allows to define default values
    constructor() public {
        myStringStorage = "someData";
        myIntegerStorage = 0;
    }
    
    
    function getStringValue() public view returns (string memory) {
        return myStringStorage;
    }
    
    function getIntegerValue() public view returns (uint) {
        return myIntegerStorage;
    }
    
    function setIntegerValue(uint _newValue) public {
        myIntegerStorage = _newValue;
    }
    
    function setStringValue(string memory _newValue) public {
        myStringStorage = _newValue;
    }
    
}