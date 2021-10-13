// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library ConstantsAF{
    string public constant mintBeforeStart_e ="Attempted to mint before the minting start time";
    string public constant incorrectAmount_e = "Incorrect amount sent";
    string public constant purchaseTooMany_e = "Quantity was greater than 20";
    string public constant noCharacters_e = "Attempted to select a random character, but no characters are available";
    string public constant invalidCharacter_e = "Attempted to mint a card with a non-existent character";
    string public constant lessThanZero_e = "Index less than 0";
    string public constant greaterThanTraitNames_e = "Index larger than the number of trait names";
    string public constant greaterThanTraitIDs_e = "Index larger than the number of trait ids";
    
    // Role managers can add and remove users from roles
    bytes32 public constant ROLE_MANAGER_ROLE = keccak256("ROLE_MANAGER_ROLE");

    // Editors can modify certain properties on the contract
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    // This role enables other contracts to call functions, but not the 
    // general public
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
}