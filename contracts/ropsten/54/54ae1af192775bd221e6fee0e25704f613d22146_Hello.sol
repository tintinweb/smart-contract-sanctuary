pragma solidity ^0.4.24;
contract Hello {
    string myString = "Hello You";
    
    function getHello() view public returns (string){
        return myString;
    }
}