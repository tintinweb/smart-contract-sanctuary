/**
 *Submitted for verification at Etherscan.io on 2021-05-22
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
    }

    uint private position; 

    event newRegistration (address userAddress);

    // Mapping owner address to User Struct
    mapping (address => User) public _list;

    /**
     * @dev Registrate a new user
     * @param _name name of user
     */  
    function registrate (string memory _name) external {
        _list[msg.sender] = User(_name, position);
        position++;
        emit newRegistration(msg.sender);
    }
}