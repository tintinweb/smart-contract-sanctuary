/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

// Interface for pet functionality in AavegotchiGameFacet contract
interface IAavegotchiGameFacet {
    function interact(uint256[] calldata _tokenIds) external;
}

// Pet Contract
contract AavegotchiCaregiver {
    IAavegotchiGameFacet private immutable gameFacet;
    address private petterAddress;

    // Set address of Aavegotchi Diamond Contract
    constructor() {
        gameFacet = IAavegotchiGameFacet(0x86935F11C86623deC8a25696E1C19a8659CbF95d);
        petterAddress = 0x4b89f6075EeF5B4381065ee62A78D9CbF649D081;
    }

    // Petting Functions
    function pet(uint256[] calldata _gotchiIDs) external {
        require(msg.sender == petterAddress, "Only the petter address may pet");
        gameFacet.interact(_gotchiIDs);
    }

    function hug(uint256[] calldata _gotchiIDs) external {
        require(msg.sender == petterAddress, "Only the petter address may hug");
        gameFacet.interact(_gotchiIDs);
    }

    function groom(uint256[] calldata _gotchiIDs) external {
        require(msg.sender == petterAddress, "Only the petter address may groom");
        gameFacet.interact(_gotchiIDs);
    }

    function snuggle(uint256[] calldata _gotchiIDs) external {
        require(msg.sender == petterAddress, "Only the petter address may snuggle");
        gameFacet.interact(_gotchiIDs);
    }

    function cuddle(uint256[] calldata _gotchiIDs) external {
        require(msg.sender == petterAddress, "Only the petter address may cuddle");
        gameFacet.interact(_gotchiIDs);
    }
}