pragma solidity 0.4.24;

contract KyberGreeter {
    string bla;
    
    constructor () public {
        
    }
    
    function setBla(string value) public{
        bla = value;   
    }
    
    function getBla() constant public returns (string){
        return bla;
    }
}