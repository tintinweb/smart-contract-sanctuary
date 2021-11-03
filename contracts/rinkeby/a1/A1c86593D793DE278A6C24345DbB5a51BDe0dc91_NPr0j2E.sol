/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

contract NPr0j2E {
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