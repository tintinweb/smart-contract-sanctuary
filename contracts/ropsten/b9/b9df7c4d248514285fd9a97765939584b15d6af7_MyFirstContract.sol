pragma solidity ^0.4.0;

contract MyFirstContract{
    
    uint private add = 10;
    
    function add_number(uint _number) returns(uint){
        return _number + add;
    }
    
}