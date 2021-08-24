//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./DinarToken.sol";

contract Bank {
    DinarToken public token;
    address public owner;
    address[] public users;

    constructor(DinarToken _token) public{
        owner = msg.sender;
        token = _token;
    }

    function addUser() public returns (bool){
        for (uint i = 0; i < users.length; i++) {
            if (msg.sender == users[i]) return false;
        }
        users.push(msg.sender);
        return true;
    }

    function reset() public {
        require(msg.sender == owner, "NOT ALLOWED");
        token.reset(users);
    }

    function distribute(uint amount) public {
        require(msg.sender == owner, "NOT ALLOWED");
        for (uint i = 0; i < users.length; i++) {
            token.transfer(users[i], amount);
        }
    }

    function getUsers() public view returns (address[] memory){
        return users;
    }
}