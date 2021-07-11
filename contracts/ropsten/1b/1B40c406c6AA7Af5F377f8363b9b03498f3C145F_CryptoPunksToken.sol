// SPDX-License-Identifier: MIT

pragma solidity ^0.4.8;

import "./CryptoPunksMarket.sol";


/**
 * @title ERC721Mock
 * This mock just provides a public safeMint, mint, and burn functions for testing purposes
 */
contract CryptoPunksToken is CryptoPunksMarket {

    /* function init() {
      CryptoPunksMarket();
      getPunk(0);
    } */
    /* using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);

    constructor(string memory symbol, string memory name) ERC721(name, symbol) {}

    function baseURI() public view returns (string memory) {
      return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
      return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public {
      _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public {
      _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
      _safeMint(to, tokenId, _data);
    }

    function burn(uint256 tokenId) public {
      _burn(tokenId);
    }

    function giveMe(address toAddress) public returns (uint256){
      _tokenIds.increment();
      uint256 newTokenId = _tokenIds.current();
      this.mint(toAddress, newTokenId);
      return newTokenId;
    }

    event Log1(address from, address to, uint index);

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) public {
        address sender = msg.sender;
        require(this.ownerOf(punkIndex) == sender, ">Owner must be sender.");
        emit Log1(sender,to, punkIndex);
        this.transferFrom(sender, to, punkIndex);
        emit PunkTransfer(sender, to, punkIndex);
        emit Transfer(sender, to, 1); // Note this is not the same as ERC721 where last parameter is Token Id
    } */
}