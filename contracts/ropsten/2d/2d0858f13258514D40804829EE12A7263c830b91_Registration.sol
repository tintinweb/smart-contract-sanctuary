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
        bool isExist;  
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
        require(!_list[msg.sender].isExist, "Only one registration possible");

        _list[msg.sender] = User(_name, position, true);
        position++;
        emit newRegistration(msg.sender);
    }
}