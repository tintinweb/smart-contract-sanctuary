/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract GreenNFT {
    event Mint(address indexed _to, uint256 indexed _tokenId, bytes32 _ipfsHash);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    uint256 tokenCounter = 1;
    mapping(uint256 => address) internal idToOwner;

    function mint(address _to, bytes32 _ipfsHash) public {
        uint256 _tokenId = tokenCounter;
        idToOwner[_tokenId] = _to;
        tokenCounter++;
        emit Mint(_to, _tokenId, _ipfsHash);
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(msg.sender == idToOwner[_tokenId]);
        idToOwner[_tokenId] = _to;
        emit Transfer(msg.sender, _to, _tokenId);
    }
}