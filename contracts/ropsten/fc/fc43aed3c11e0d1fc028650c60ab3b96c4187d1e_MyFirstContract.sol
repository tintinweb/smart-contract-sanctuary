pragma solidity ^0.4.0;

contract MyFirstContract{
    function add(uint _base, uint _value, uint _third) public returns (uint){
        return _base +_value + _third;
    }
}