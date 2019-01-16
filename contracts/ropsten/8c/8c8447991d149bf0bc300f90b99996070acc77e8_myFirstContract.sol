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
    
    //public - internal use external use
    //private - only inside this contract
    //internal - inside use or used by other SmartContract
    //external - only from outside like MetaMask
    
    
    function getStringValue() public view returns (string memory) {
        return myStringStorage;
    }
    
    function getIntegerValue() public view returns (uint) {
        return myIntegerStorage;
    }
    
}