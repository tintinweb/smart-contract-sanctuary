pragma solidity 0.4.24;

contract KyberGreeter {
    
    string helloVaribable;
    
   constructor () public {
    }
    
    function setGreeter(string _helloVaribable) public{
        helloVaribable = _helloVaribable;
    }
    
    function getGreeter() constant public returns (string){
        return helloVaribable;
    }
}