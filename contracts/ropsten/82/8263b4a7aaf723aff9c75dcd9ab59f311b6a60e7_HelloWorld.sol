pragma solidity ^0.4.25;
contract HelloWorld {
    uint value;
    
    function get() view public returns(uint){
        return value;
    }
    function set(uint _value) public {
        value = _value;
    }
   
}