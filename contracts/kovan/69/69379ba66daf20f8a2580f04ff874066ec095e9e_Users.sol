/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

interface RolesUsers {
    function hasEndUserAdminRights(address addr) external view returns (bool);
}

/// @title Users
contract Users is Ownable {
    mapping(address => bytes32) _walletToUser;

    RolesUsers private _roles;

    event AddedWallet(bytes32 indexed userBytes, address wallet, string user);
    event RemovedWallet(bytes32 indexed userBytes, address wallet);

    modifier onlyEndUserAdmin {
        require(_roles.hasEndUserAdminRights(msg.sender), "Whitelisted: You need to have end user admin rights!");
        _;
    }

    constructor(address roles) public {
        _roles = RolesUsers(roles);
    }

    function changeRolesAddress(address newRoles) public onlyOwner {
        _roles = RolesUsers(newRoles);
    }

    function _addWallet(string memory user, address wallet) private {
        bytes32 userBytes = getUserBytes(user);
        _walletToUser[wallet] = userBytes;
        emit AddedWallet(userBytes, wallet, user);
    }

    function _removeWallet(address wallet) private {
        bytes32 userBytes = getUserBytesFromWallet(wallet);
        delete _walletToUser[wallet];
        emit RemovedWallet(userBytes, wallet);
    }


    /// @notice registers wallet addresses for users
    /// @param users Array of strings that identifies users
    /// @param wallets Array of wallet addresses
    function addWalletList(string[] memory users, address[] memory wallets) public onlyEndUserAdmin {
        require(users.length == wallets.length, "Whitelisted: User and wallet lists must be of same length!");
        for (uint i = 0; i < wallets.length; i++) {
            _addWallet(users[i], wallets[i]);
        }
    }

    /// @notice removes wallets
    /// @param wallets Array of addresses
    function removeWalletList(address[] memory wallets) public onlyEndUserAdmin {
        for (uint i = 0; i < wallets.length; i++) {
            _removeWallet(wallets[i]);
        }
    }

    /// @notice retrieves keccak256 hash of user based on wallet
    /// @param wallet Address of user
    /// @return keccak256 hash
    function getUserBytesFromWallet(address wallet) public view returns (bytes32) {
        return _walletToUser[wallet];
    }

    /// @notice get keccak256 hash of string
    /// @param user User or Certified Partner identifier
    /// @return keccak256 hash
    function getUserBytes(string memory user) public pure returns (bytes32) {
        return keccak256(abi.encode(user));
    }
}