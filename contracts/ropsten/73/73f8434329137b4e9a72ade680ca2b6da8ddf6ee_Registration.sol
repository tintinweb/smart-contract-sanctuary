/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** 
 * @title Registration
 * @dev Implements Registration list
 */
contract Registration {
    
    struct User {
        string userName;  
        uint userPosition; 
        bool isExist;  
    }

    uint private position; 

    event newRegistration (address indexed userAddress, string userName);

    // Mapping address to User Struct
    mapping (address => User) public _users;

    /**
     * @dev Registrate a new user
     * @param _name name of user
     */  
    function registrate (string memory _name) external {
        require(!_users[msg.sender].isExist, "Already registered");

        _users[msg.sender] = User(_name, position, true);
        position++;
        emit newRegistration(msg.sender, _name);
    }
}