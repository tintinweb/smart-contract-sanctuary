// SPDX-License-Identifier: MIT

// Made for the GotchiWorld's Nursery

// Everything written after "//" is a comment and does not affect the code
// It will be used to explain each line of code

// Version of solidity used
pragma solidity 0.8.7;

// This Interface called "IAavegotchiGameFacet" informs this smart contract that there is another smart contract with this function.
interface IAavegotchiGameFacet {
    // This function called "interact" is the one to call to pet 1 or more gotchis
    function interact(uint256[] calldata _tokenIds) external;
}

// The contract starts here
contract NurseryPetting {
    
    // we create an element called "gameFacet" that will be the interface with Aavegotchi's contract
    IAavegotchiGameFacet private immutable gameFacet;
    
    // A constructor is only called once, when the contract is deployed
    constructor() {
        // We provide to the "gameFacet" element the address of Aavegotchi's contract
        gameFacet = IAavegotchiGameFacet(0x86935F11C86623deC8a25696E1C19a8659CbF95d); // is immutable
    }
    
    // This is the only function of this contract, it is used to call the Aavegotchi fonction to pet
    function petThemAll(uint256[] calldata _gotchiIds) external {
        // In out "gameFacet" element, we call the function "interact", which we know at where address it exists (cf the constructor)
        gameFacet.interact(_gotchiIds);
    }
}

