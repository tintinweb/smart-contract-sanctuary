/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** 
 * @title Registration
 * @dev Implements Registration list
 */
contract Register {
    
    struct User {
        string userName;  
        uint userPosition; 
        bool exists;  
    }

    uint private position; 

    event newlyRegistered (address indexed userAddress, string userName);

    // Mapping address to User Struct
    mapping (address => User) public _users;

    /**
     * @dev Register a new user
     * @param _name name of user
     */  
    function register (string memory _name) external {
        require(!_users[msg.sender].exists, "Already registered");

        _users[msg.sender] = User(_name, position, true);
        position++;
        emit newlyRegistered(msg.sender, _name);
    }
}