//Solidity Version
pragma solidity ^0.5.0;

//contract Declaration
contract myFirstContract {
    
    //variables Declaration
    string myStringStorage;
    uint myIntegerStorage;
    
    //constructor allows to define default values
    constructor() public {
        myStringStorage = "someDate";
        myIntegerStorage = 0;
    }
    
    //public - internal use external use
    //private - only inside this Contract
    //internal - incide use of used by other Smart contract
    //external - only from outside like MetaMask
    
    function getStringValue() public view returns(string memory){
        return myStringStorage;
    }
    
    function getIntegerVaule() public view returns (uint) {
        return myIntegerStorage;
    }   
    function setIntegerVaule(uint _newValue) public {
        myIntegerStorage = _newValue;
    }
    
    function setStringVaule(string memory _newValue) public {
        myStringStorage = _newValue;
    }
}