/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract MintBurnNFTFacet {

    /// @notice Construct the MintBurnNFT for the corresponding NFTClubModel
    /// @param _NFTClubAddr The address of NFTClubModel
    constructor(
        address _NFTClubAddr
    ) {
    }

    /// @notice Locks the user's token within the contract
    /// @param amount Quantity of DAI the user wishes to lock in the contract
    function stake(uint256 amount) public {
    }

    
    /// @notice Mint NFT to the recipient
    /// @param _to The address of the recipient
    /// @param _tokenId of the NFT to be minted by the msg.sender.
    function mintNFT(address _to, uint256 _tokenId) public {
    }

    /// @notice Burn the NFT
    /// @param _tokenId of the NFT to be burned
    function burnNFT(uint256 _tokenId) external {
        //s.transfer(msg.sender, address(0), _tokenId);
    }
}