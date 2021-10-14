// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Authority {
    address public owner;
    mapping (address => bool) public isAdmin;
    
    constructor() {
        owner = msg.sender;
        setAdmin(owner, true);
    }
    
    modifier onlyOnwer(){
        require(msg.sender == owner, "access denied");
        _;
    }
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || msg.sender == owner, "access denied");
        _;
    }
    
    function changeOwner(address newOwner) public onlyOnwer {
        owner = newOwner;
    }
    
    function setAdmin(address user, bool b) public onlyOnwer {
        isAdmin[user] = b;
    }    
}