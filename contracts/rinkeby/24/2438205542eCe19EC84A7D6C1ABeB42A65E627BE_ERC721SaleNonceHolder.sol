// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract ERC721SaleNonceHolder {
    // keccak256(token, owner, tokenId) => nonce
    mapping(bytes32 => uint256) public nonces;

    // keccak256(token, owner, tokenId, nonce) => completed amount
    mapping(bytes32 => uint256) public completed;

    function getNonce(
        address token,
        uint256 tokenId,
        address owner
    ) public view returns (uint256) {
        return nonces[getNonceKey(token, tokenId, owner)];
    }

    function setNonce(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public {
        nonces[getNonceKey(token, tokenId, owner)] = nonce;
    }

    function getNonceKey(
        address token,
        uint256 tokenId,
        address owner
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner));
    }

    function getCompleted(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public view returns (uint256) {
        return completed[getCompletedKey(token, tokenId, owner, nonce)];
    }

    function setCompleted(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce,
        uint256 _completed
    ) public {
        completed[getCompletedKey(token, tokenId, owner, nonce)] = _completed;
    }

    function getCompletedKey(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner, nonce));
    }
}