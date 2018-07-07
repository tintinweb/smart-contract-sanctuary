pragma solidity ^0.4.24;
contract Hello {
    string myString = &quot;Hello You 2&quot;;
    
    function getHello() view public returns (string){
        return myString;
    }
}