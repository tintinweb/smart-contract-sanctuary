pragma solidity ^0.4.0;

contract MyFirstContract{
    
    // variable
    uint private _add = 10;
    
    function add_numbers(uint _number) returns (uint){
        return _number + _add;
    }
    
}