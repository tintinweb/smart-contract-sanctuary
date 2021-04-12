/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;



// Part: IMinigameFactoryRegistry

interface IMinigameFactoryRegistry {
    function registerMinigame(string calldata minigameKey, address minigameFactoryAddress) external;

    function getFactory(string calldata minigameKey) external returns (address);
}

// File: MinigameFactoryRegistry.sol

/// @title MinigameFactoryRegistry
/// @author cds95
/// @notice This is the contract where all the minigame factory addresses are registered
contract MinigameFactoryRegistry is IMinigameFactoryRegistry {
    // Mapping from a minigame's key to it's factory's address
    mapping(string => address) public minigameFactories;

    function registerMinigame(string calldata minigameId, address minigameFactoryAddress) external override {
        require(minigameFactories[minigameId] == address(0)); // dev: minigameId already taken
        minigameFactories[minigameId] = minigameFactoryAddress;
    }

    function getFactory(string calldata minigameId) external override returns (address) {
        return minigameFactories[minigameId];
    }
}