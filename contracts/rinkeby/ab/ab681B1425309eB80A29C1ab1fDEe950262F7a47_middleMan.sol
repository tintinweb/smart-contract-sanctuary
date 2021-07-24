/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File contracts/middleMan.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface purchaseAnimal {
    function ownerOf(uint256 tokenId) external returns (address);

    function transferFrom(
        address owner,
        address to,
        uint256 tokenId
    ) external;

    function mint(address to) external;
}

contract middleMan {
    purchaseAnimal nftContract =
        purchaseAnimal(0xACE5a55fA347c43cdc4271b8931D1338211C8644);

    function facilitateSale(uint256 tokenId) public payable {
        require(msg.value >= ((1.1 * 10) ^ 18));

        address ownerAdd = nftContract.ownerOf(tokenId);
        (bool success, ) = ownerAdd.call{value: msg.value}("");
        require(success);

        nftContract.transferFrom(
            nftContract.ownerOf(tokenId),
            msg.sender,
            tokenId
        );
    }

    function purchaseMultipleTokens(uint256 quantity) public payable {
        require(msg.value >= quantity * 1);

        // Send ethers to developer
        address developer = 0xF23B5533c3E71A456c9247Cd25C722560871c8A2;
        (bool success, ) = developer.call{value: msg.value}("");
        require(success);

        // Mint NFT (using external call)
        for (uint256 i = 0; i < quantity; i++) {
            nftContract.mint(msg.sender);
        }
    }
}