/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File contracts/middleMan.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface interfaceAA {
    function ownerOf(uint256 tokenId) external returns (address);

    function transferFrom(
        address owner,
        address to,
        uint256 tokenId
    ) external;

    function mint(address to) external;
}

contract middleMan {
    interfaceAA ERC721Contract =
        interfaceAA(0x17b31A3f23E24537F3DF57C0aEc63a7cF452c605);

    function changeInterfaceContract(address newContract) public {
        require(msg.sender == 0xF23B5533c3E71A456c9247Cd25C722560871c8A2);
        ERC721Contract = interfaceAA(newContract);
    }

    function facilitateSale(uint256 tokenId, uint256 price) public payable {
        require(msg.value >= (price * 10e18));

        address ownerAdd = ERC721Contract.ownerOf(tokenId);
        (bool success, ) = ownerAdd.call{value: msg.value}("");
        require(success);

        ERC721Contract.transferFrom(ownerAdd, msg.sender, tokenId);
    }

    function purchaseMultipleTokens(uint256 quantity) public payable {
        require(msg.value >= quantity * 1);

        // Send ethers to developer
        address developer = 0xF23B5533c3E71A456c9247Cd25C722560871c8A2;
        (bool success, ) = developer.call{value: msg.value}("");
        require(success);

        // Mint NFT (using external call)
        for (uint256 i = 0; i < quantity; i++) {
            ERC721Contract.mint(msg.sender);
        }
    }
}