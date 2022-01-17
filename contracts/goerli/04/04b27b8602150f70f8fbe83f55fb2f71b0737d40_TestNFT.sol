/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract TestNFT {

    string public name = "Test NFT";
    string public symbol = "TEST";
    uint256 public totalSupply = 100;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    constructor() { 
        for (uint160 i; i < totalSupply; i++) { 
            // emit Transfer(address(0), address(uint160(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF) - i), i);
            emit Transfer(address(0), address(uint160(uint256(blockhash(block.number - i - 1)))), i);
        }
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == bytes4(0x01ffc9a7) || interfaceId == bytes4(0x80ac58cd) || interfaceId == bytes4(0x5b5e139f) || interfaceId == bytes4(0x780e9d63);
    }

    // TODO update token id 
    function owner() public view returns(address) {
        return IERC721(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85).ownerOf(0);
    }

    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        return unicode"💩";
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}