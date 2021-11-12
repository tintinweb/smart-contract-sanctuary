// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

library ConstantsAF{
    string public constant mintBeforeStart_e ="Sale not started";
    string public constant incorrectAmount_e = "Incorrect amount sent";
    string public constant purchaseTooMany_e = "Quantity was greater than 20";
    string public constant noCharacters_e = "No characters are available";
    string public constant invalidCharacter_e = "Non-existent character";
    string public constant mainSaleEnded_e = "Main sale has ended";

    // Role managers can add and remove users from roles
    bytes32 public constant ROLE_MANAGER_ROLE = keccak256("ROLE_MANAGER_ROLE");

    // Editors can modify certain properties on the contract
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    // This role enables other contracts to call functions, but not the 
    // general public
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

}