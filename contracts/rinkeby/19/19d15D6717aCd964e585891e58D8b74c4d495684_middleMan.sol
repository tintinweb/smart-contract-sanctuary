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
}

contract middleMan {
    purchaseAnimal nftContract =
        purchaseAnimal(0x8059EC7cF0491Fb7879813E328c7B4A041B8996b);

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
}