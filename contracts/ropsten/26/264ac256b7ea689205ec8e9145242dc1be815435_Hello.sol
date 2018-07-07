pragma solidity ^0.4.24;
contract Hello {
    string myString;
    
    function getHello() view public returns (string){
        return myString;
    }
    
    function setHello(string x) view public returns (string){
        myString = x;
    }
}