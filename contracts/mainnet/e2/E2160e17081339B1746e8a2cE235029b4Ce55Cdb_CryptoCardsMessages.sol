// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

contract CryptoCardsMessages {
    string public notAvailable = "Feature not currently available";
    string public mintAmount = "Mint Amount";
    string public exceedsSupply = "Supply exceeded";
    string public exceedsDeckSupply = "Deck supply exceeded";
    string public fiveCardsRequired = "Five cards required";
    string public zeroAddress = "Zero address";
    string public mustBeOwner = "Must be owner";
    string public notEnoughFunds = "Not enough funds";
    string public existingModifier = "Modifier exists";
    string public nameRequired = "Name required";
    string public modifierUsage = "Modifier usage exceeded";
    string public modifierNotFound = "Modifier not found";
    string public erc721InvalidTokenId = "URI query for nonexistent token";
    string public symbolInUse = "Symbol already exists";
    string public symbolNotFound = "Symbol not found";
    string public missingShuffledDeck = "Missing shuffled deck for symbol";
    string public modifierDataFull = "The card cannot accept further modifiers";
    string public modifierNameAlreadyInUse =
        "The specified name is already in use";
    string public dataLengthExceeded = "Data length (256 bytes) exceeded";
}