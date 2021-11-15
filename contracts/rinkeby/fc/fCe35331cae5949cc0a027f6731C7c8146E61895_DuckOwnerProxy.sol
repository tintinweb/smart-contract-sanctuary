// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface OpenStoreContract {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

contract DuckOwnerProxy {
    address public openStoreNFTAddress;

    constructor(address _openStoreNFTAddress) {
        openStoreNFTAddress = _openStoreNFTAddress;
    }

    function checkIfDuckOwner(uint256 duckID) public view returns (bool) {
        OpenStoreContract nft = OpenStoreContract(openStoreNFTAddress);
        return nft.balanceOf(msg.sender, duckID) > 0;
    }

    function openStoreBalanceForOwner(address owner, uint256 tokenID) public view returns (uint256) {
        OpenStoreContract nft = OpenStoreContract(openStoreNFTAddress);
        return nft.balanceOf(owner, tokenID);
    }
}

