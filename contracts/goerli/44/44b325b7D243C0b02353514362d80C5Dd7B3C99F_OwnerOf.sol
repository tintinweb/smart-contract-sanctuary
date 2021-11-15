// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnerOf {
    mapping(uint256 => address) owners;

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return owners[tokenId];
    }

    function setOwner(uint256 tokenId) external {
        owners[tokenId] = msg.sender;
    }
}

