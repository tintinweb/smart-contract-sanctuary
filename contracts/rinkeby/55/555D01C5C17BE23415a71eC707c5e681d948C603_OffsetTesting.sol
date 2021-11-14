// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OffsetTesting {
    uint256 public _offset;
    uint256 public _count;

    constructor() {}

    function setOffset(uint256 offset) public {
        _offset = offset;
    }

    function setCount(uint256 count) public {
        _count = count;
    }

    function getProjectTokenId(uint256 tokenId) public view returns (uint256) {
        return (tokenId + _offset) % _count;
    }

    function getTokenId(uint256 projectTokenId) public view returns (uint256) {
        return
            (projectTokenId - _offset < 0)
                ? (projectTokenId - _offset + _count)
                : projectTokenId - _offset;
    }
}