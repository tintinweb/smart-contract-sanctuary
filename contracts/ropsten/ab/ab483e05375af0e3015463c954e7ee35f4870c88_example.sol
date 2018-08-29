pragma solidity ^0.4.24;

contract example{
    
    uint storedData;
    
    
    function set(uint x) public{
        storedData = x;
    }
    
    function get() constant returns(uint){
        return storedData;
    }
    
    
    function sum(uint a, uint b) returns(uint result){
        result = a + b;
    }
    
    
    
}