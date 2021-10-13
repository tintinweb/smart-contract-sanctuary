// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './AbstractERC1155Factory.sol';
import './Strings.sol';

contract Liquid is AbstractERC1155Factory {
    uint256 private constant MAX_SUPPLY = 20;
    uint256 private constant MAX_TYPE = 3;

    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;
    }

    function mint(uint256 tokenId, uint256 amount, address to) external onlyOwner {
        require(exists(tokenId), "Mint: tokenId does not exist");
        require(totalSupply(tokenId) + amount <= MAX_SUPPLY, "Mint: Max supply reached");

        _mint(to, tokenId, amount, "");
    }

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _id the planet id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    /**
    * @notice indicates weither any token exist with a given id, or not
    */
    function exists(uint256 tokenId) public pure override returns (bool) {
        return tokenId >= 0 && tokenId < MAX_TYPE;
    }
}