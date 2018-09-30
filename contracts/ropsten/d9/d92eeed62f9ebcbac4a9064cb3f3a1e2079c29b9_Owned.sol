pragma solidity ^0.4.24;

contract Owned {
    
    modifier only_owner { if (msg.sender != owner) { return; } _; }
    
    event NewOwner(address indexed old, address indexed current);
    
    function setOwner(address _new) public only_owner {
        emit NewOwner(owner, _new);
        owner = _new;
    }
    
    address public owner = msg.sender;
}