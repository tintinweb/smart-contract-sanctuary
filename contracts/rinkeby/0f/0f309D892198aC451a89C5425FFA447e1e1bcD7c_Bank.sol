//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20Accounting.sol";

contract Bank {
    ERC20Accounting public token;
    address public owner;
    address[] public users;

    constructor(ERC20Accounting _token) public {
        owner = msg.sender;
        token = _token;
    }

    function isUser(address user) public returns (bool){
        for (uint i = 0; i < users.length; i++) {
            if (user == users[i]) return true;
        }
        return false;
    }

    function addUser() public returns (bool){
        if (isUser(msg.sender)) return false;
        users.push(msg.sender);
        return true;
    }

    function burn() public {
        require(msg.sender == owner, "NOT ALLOWED");
        token.clearTokens(users);
    }

    function distribute(uint amount) public {
        require(msg.sender == owner, "NOT ALLOWED");
        token.mintTokens();
        for (uint i = 0; i < users.length; i++) {
            token.transfer(users[i], amount);
        }
    }

    function getUsers() public view returns (address[] memory){
        return users;
    }

    function removeAllUsers() public {
        require(msg.sender == owner, "NOT ALLOWED");
        delete users;
    }
}