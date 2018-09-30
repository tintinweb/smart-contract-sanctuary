pragma solidity ^0.4.24;

contract HelloWorld  {
    string public yourName;  // data
    
    /* Simple Hola Mundo */
   constructor() public {
        yourName = "Hello World";
    } 
    
    function set(string name)public {
        yourName = name;
    }
    
    function hello() constant public returns (string) {
        return yourName;
    }
}