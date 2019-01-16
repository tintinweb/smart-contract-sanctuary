pragma solidity ^0.4.0;

contract HelloWorld{ 
    string private myString = "Hello world!";
    uint private myUint = 6610;
    
    function getString() constant public returns(string){
        return myString;
    }
    
    function getUint() constant public returns(uint){
        return myUint;
    }
    
}