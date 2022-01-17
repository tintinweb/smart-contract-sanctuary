// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract TestNFT {

    string public name = "Test NFT";
    string public symbol = "TEST";

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == bytes4(0x01ffc9a7) || interfaceId == bytes4(0x80ac58cd) || interfaceId == bytes4(0x5b5e139f) || interfaceId == bytes4(0x780e9d63);
    }

    function totalSupply() external pure returns (uint256) {
        return 10000;
    }

    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        return unicode"💩";
    }
}