/**
 *Submitted for verification at polygonscan.com on 2021-10-02
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface AavegotchiGameFacet 
{
    function interact(uint256[] calldata _tokenIds) external;
}

contract SimpleGotchiPetter
{
    address AAVEGOTCHI_DIAMOND_CONTRACT = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    
    AavegotchiGameFacet private gameFacet = AavegotchiGameFacet(AAVEGOTCHI_DIAMOND_CONTRACT);

    struct PetterData
    {
    uint256[] tokenIds;
    uint256 lastInteracted;
    }
  
    mapping(address => PetterData) petterData;
    
    function setTokens(uint256[] calldata _tokenIds) external
    {
        petterData[msg.sender].tokenIds = _tokenIds;
    }
    
    function getTokens() external view returns (uint256[] memory tokenIds)
    {
        tokenIds = petterData[msg.sender].tokenIds;
    }

    function getLastInteraction() external view returns (uint256 lastInteracted)
    {
        lastInteracted = petterData[msg.sender].lastInteracted;
    }

    event GotchisPetted(uint256[] tokenIds);

    function pet() external 
    {
        require(petterData[msg.sender].tokenIds.length > 0, "No Gotchis to pet");
        require((block.timestamp > petterData[msg.sender].lastInteracted + 12 hours), "Time not elapsed");
        gameFacet.interact(petterData[msg.sender].tokenIds);
        petterData[msg.sender].lastInteracted = block.timestamp;
        emit GotchisPetted(petterData[msg.sender].tokenIds);
    }
}