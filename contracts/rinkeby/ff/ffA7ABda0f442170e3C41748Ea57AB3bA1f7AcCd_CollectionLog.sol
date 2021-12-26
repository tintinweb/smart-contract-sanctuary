// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract CollectionLog
{
    event LogTransfer(address indexed from, address indexed to, address collection, uint256 tokenId);

    constructor() {
    }

    function logTransfer(address from, address to, address collection, uint256 tokenId) public {
        emit LogTransfer(from, to, collection, tokenId);
    }

}