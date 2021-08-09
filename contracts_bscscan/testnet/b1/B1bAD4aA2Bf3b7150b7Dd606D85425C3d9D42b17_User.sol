// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./SuperAdmin.sol";

contract User is SuperAdmin {
    
    struct UserEntity {
        address public_key; // address in smart contract
        uint user_id; // user id from backend
        string username;  // username from backend
        string email; // email from backend
    }
    UserEntity[] private users;

    // add a new user in smart contract
    function signPublicKey(uint user_id, string memory username, string memory email) public {
        address sender = msg.sender;
        bool isUserExist = false;
        for (uint i = 0; i < users.length; i++) {
            if (users[i].public_key == sender) {
                isUserExist = true;
            }
        }
        if (isUserExist == false) {
            users.push(UserEntity(sender, user_id, username, email));
        } else {
            revert('User exist');
        }
    }

    // get user id by public key
    function getUserId(address sender) public view returns(uint) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i].public_key == sender) {
                return users[i].user_id;
            }
        }
        revert('User ID does not exist');
    }

    // get username by public key
    function getUsername(address sender) public view returns(string memory) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i].public_key == sender) {
                return users[i].username;
            }
        }
        revert('Username does not exist');
    }

    // get user detail
    function getUserDetail(address sender) public view returns(address, uint, string memory, string memory) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i].public_key == sender) {
                return (users[i].public_key, users[i].user_id, users[i].username, users[i].email);
            }
        }
        revert('User does not exist');
    }

    // only admin can change public key of user
    function changePublicKey(uint user_id, address newPublicKey) public onlySuperAdmin returns(bool) {
        for (uint i = 0; i < users.length; i++) {
            if (user_id == users[i].user_id) {
                users[i].public_key = newPublicKey;
                return true;
            }
        }
        revert('Username does not exist');
    }
}