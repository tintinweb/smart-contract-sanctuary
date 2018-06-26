pragma solidity ^0.4.20;
contract SimpleStorage {
    uint public data;
    
    event Set(address indexed _from, uint value);
    
    function set(uint x) public {
        data = x;
        Set(msg.sender, x);
    }
}