pragma solidity ^0.4.25;

contract Storer {
    address public owner;
    string public log;
    
    function Storer() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner)
           throw;
        _;
    }
    
    function store(string _log) onlyOwner() {
        log = _log;
    }

    function Clean() onlyOwner() {
      selfdestruct(owner); }
}