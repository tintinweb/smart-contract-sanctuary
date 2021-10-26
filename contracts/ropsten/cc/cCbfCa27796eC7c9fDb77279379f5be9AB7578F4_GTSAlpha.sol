/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GTSAlpha{
    

    // Events
    event titleTransfer(bytes32 indexed _hash1, bytes32 indexed _hash2, bytes32 indexed _address, string ipfs);
    event ownerTransfer(address indexed oldOwner, address indexed newOwner);
    event adminAssigned(address indexed admin);
    event adminRevoked(address indexed admin);

    address private owner; // Address of current owner
    mapping(address => bool) admin; // Mapping for admin accounts

    // Make a function accessible only by owner
    modifier isOwner(){
        require(msg.sender==owner,"You are not the owner");
        _;
    }

    // Make a function accessible only by an admin or the owner
    modifier isAdmin(){
        require(msg.sender==owner||admin[msg.sender],"You are not an admin/owner");
        _;
    }

    // Create contract and assign ownership
    constructor(){
        owner=0xc54C5B3fe426012380531585511BD77291cD413E; // Address of first owner
    }

    function transferOwnership(address _newOwner)public isOwner(){
        address oldOwner=owner;
        owner=_newOwner;
        emit ownerTransfer(oldOwner,_newOwner);
    }

    // Assign an admin role
    function assignAdmin(address _Admin)public isOwner(){
        require(_Admin!=owner,"Owner cannot be an admin.");
        require(!admin[_Admin],"User is already an admin");
        admin[_Admin]=true;
        emit adminAssigned(_Admin);
    }

    // Remove an admin role
    function revokeAdmin(address _Admin)public isOwner(){
        require(admin[_Admin],"User is not an admin");
        admin[_Admin]=false;
        emit adminRevoked(_Admin);
    }

    // Record a title transfer
    function logTitle(bytes32 hash_1,bytes32 hash_2,bytes32 hash_a,string memory ipfs)public isAdmin(){
        emit titleTransfer(hash_1,hash_2,hash_a,ipfs);
    }
}