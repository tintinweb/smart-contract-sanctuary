// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract DummyGacha {
    event MintWithGacha(string rarityName, uint256 basePoint, address to);

    event TokenURI(uint256 tokenId, string newTokenURI);

    function triggerEvent(string calldata rarityName, uint256 basePoint, address to) public {
        emit MintWithGacha(rarityName, basePoint, to);
    }

    function setTokenURI(uint256 tokenId, string memory newTokenURI)
        public
    {
        emit TokenURI(tokenId, newTokenURI);
    }
}