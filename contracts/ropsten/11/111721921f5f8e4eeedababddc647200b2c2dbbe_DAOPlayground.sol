pragma solidity ^0.4.24;

contract DAOPlayground {
    string public daoName;
    string public daoNameRestricted;
    address public owner;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor(string _daoName) public {
        daoName = _daoName;
        daoNameRestricted = _daoName;
        owner = msg.sender;
    }
    
    function changeNameByEveryone(string _newName) public returns (bool) {
        daoName = _newName;
        return true;
    }
    
    function changeNameRestricted(string _newName) public onlyOwner returns (bool) {
        daoNameRestricted = _newName;
        return true;
    }
}