/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** 
 * @title FavoriteFruit
 * @dev Implements Registration list with the favorite fruit
 */
contract FavoriteFruit {
    
    struct User {
        string userName; 
        string fruit;
        uint userPosition; 
        bool isExist;  
    }

    uint private position; 

    event newRegistration (address indexed userAddress, string userName, string fruit);

    // Mapping address to User Struct
    mapping (address => User) public _users;

    /**
     * @dev Registrate a new user
     * @param _name name of user
     */  
    function registrate (string memory _name, string memory _fruit) external {
        require(!_users[msg.sender].isExist, "Already registered");

        _users[msg.sender] = User(_name,_fruit, position, true);
        position++;
        emit newRegistration(msg.sender, _name, _fruit);
    }
}