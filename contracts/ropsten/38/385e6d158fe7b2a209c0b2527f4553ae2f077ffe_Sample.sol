pragma solidity ^0.4.0;

contract Sample{
    
    event trigger(uint);
    
    uint value;
    
    function simple() public returns(string){
        emit trigger(1);
        return "faran";
    }
    
    function setValue(uint val) public{
        value = val;
    }
    
    function getValue() public returns(uint){
        emit trigger(value);
        return value;
    }
}