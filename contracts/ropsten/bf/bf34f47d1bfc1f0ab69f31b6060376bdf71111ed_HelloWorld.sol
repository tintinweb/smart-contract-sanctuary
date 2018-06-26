pragma solidity ^0.4.24;

contract HelloWorld {

    mapping(address => address[]) accounts;

    function account(string name) public returns (address output) {
        address newAccount = new Account(name);
        accounts[msg.sender].push(newAccount);
        return newAccount;
    }
    
    function getAccounts() public constant returns (address[] _accounts) {
        return accounts[msg.sender];
    }
}


contract Account {
    string name;

    constructor(string _name) public {
        name = _name;
    }

    function getName() public constant returns (string output) {
        return name;
    }
}