/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    Just for experimental, ERC721I (ERC721 0xInuarashi Edition)
    Mainly created as a learning experience and an attempt to try to exercise
    Gas saving practices
*/

contract ERC721 {
    // init the contract name and symbol with constructor
    string public name; string public symbol;
    constructor(string memory name_, string memory symbol_) { name = name_; symbol = symbol_; }

    uint16 public totalSupply; // ERC721I65535
    mapping(uint16 => address) public ownerOf; // ERC721I65535
    mapping(address => uint16[]) public addressToTokens; // ERC721I65535Enumerable
    mapping(address => mapping(uint16 => uint16)) public addressToTokenIndex; // ERC721I65535Enumerable

    // // internal write functions
    // mint
    function __mint(address to_, uint16 tokenId_) internal virtual {
        require(ownerOf[tokenId_] == address(0x0), "TE");

        // ERC721I65535 Starts Here
        ownerOf[tokenId_] = to_; 
        totalSupply++; 
        // ERC72165535 Ends Here

        // ERC721I65535Enumerable Starts Here
        addressToTokens[to_].push(tokenId_); 
        addressToTokenIndex[to_][tokenId_] = uint16(addressToTokens[to_].length) - 1;
        // ERC721I65535Enumerable Ends Here
    }

    // transfer
    function __transfer(address from_, address to_, uint16 tokenId_) internal virtual {
        require(from_ == ownerOf[tokenId_], "OX");

        // ERC721I65535 Starts Here
        ownerOf[tokenId_] = to_; 
        // ERC72165535 Ends Here

        // // ERC721I65535Enumerable Starts Here
        // Remove Token & Index from Old Address
        uint16 _indexFrom = addressToTokenIndex[from_][tokenId_];
        uint16 _maxIndexFrom = uint16(addressToTokens[from_].length) - 1;
        if (_indexFrom != _maxIndexFrom) {
            addressToTokens[from_][_indexFrom] = addressToTokens[from_][_maxIndexFrom];
        } addressToTokens[from_].pop(); delete addressToTokenIndex[from_][tokenId_];

        // Add Token & Index to New Address
        addressToTokens[to_].push(tokenId_);
        addressToTokenIndex[to_][tokenId_] = uint16(addressToTokens[to_].length) - 1;
        // ERC721I65535Enumerable Ends Here
    }

    // // public write functions
    function transferFrom(address from_, address to_, uint16 tokenId_) public {
        __transfer(from_, to_, tokenId_);
    }

    // // public view functions
    function balanceOf(address address_) public view returns (uint256) {
        return addressToTokens[address_].length;
    }
    function walletOfOwner(address address_) public virtual view returns (uint16[] memory) {
        return addressToTokens[address_];
    }
}

contract testNFT is ERC721 {
    constructor() ERC721("TESTNFT", "TEST") {}
    function mint(uint qty_) public {
        for (uint i = 0; i < qty_; i++) {
            __mint(msg.sender, totalSupply);
        }
    }
}