/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Zapper Mail implementation, based heavily on Melon Mail from Melonport

pragma solidity ^0.8.0;

contract Zapper_Mail_V1 {
    mapping(bytes32 => bool) usernameHashExists;

    event UserRegistered(bytes32 indexed usernameHash, address indexed addr, string username, string publicKey);
    event EmailSent(address indexed from, address indexed to, string mailHash);
    event ContactsUpdated(bytes32 indexed usernameHash, string fileHash);

    function registerUser(
        bytes32 usernameHash,
        string calldata username,
        string calldata publicKey
    ) external {
        require(usernameHashExists[usernameHash] == false, 'User already exists');
        usernameHashExists[usernameHash] = true;
        emit UserRegistered(usernameHash, msg.sender, username, publicKey);
    }

    function sendEmail(address recipient, string calldata mailHash) external {
        emit EmailSent(tx.origin, recipient, mailHash);
    }

    function updateContacts(bytes32 usernameHash, string calldata fileHash) external {
        emit ContactsUpdated(usernameHash, fileHash);
    }
}