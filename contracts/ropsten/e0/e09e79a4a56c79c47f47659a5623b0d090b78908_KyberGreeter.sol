pragma solidity 0.4.23;

contract KyberGreeter {
    string greeter;
    
    constructor () public {

    }
    
    function setGreeter(string _greeter) public{
        greeter = _greeter;
    } 
    function getGreeter() constant public returns (string){
        return greeter;

    }
}