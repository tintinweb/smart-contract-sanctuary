/// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

library ConstantsAF {
    /// Error messages
    string public constant MINT_BEFORE_START = "Sale not started";
    string public constant INCORRECT_AMOUNT = "Incorrect amount sent";
    string public constant PURCHACE_TOO_MANY = "Quantity was greater than 20";
    string public constant NO_CHARACTERS = "No characters are available";
    string public constant INVALID_CHARACTER = "Non-existent character";
    string public constant MAIN_SALE_ENDED = "Main sale has ended";

    /// Role managers can add and remove users from roles
    bytes32 public constant ROLE_MANAGER_ROLE = keccak256("ROLE_MANAGER_ROLE");

    /// Editors can modify certain properties on the contract
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    /// This role enables other contracts to call functions, but not the general public
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
}