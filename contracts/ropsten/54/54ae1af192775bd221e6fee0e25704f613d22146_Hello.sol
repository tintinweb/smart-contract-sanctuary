pragma solidity ^0.4.24;
contract Hello {
    string myString = &quot;Hello You&quot;;
    
    function getHello() view public returns (string){
        return myString;
    }
}