pragma solidity ^0.4.0;

contract Add{
    
    uint private _add = 10;
    
    function add_number(uint _number) public returns (uint){
        return _number + _add;
    }
    
}