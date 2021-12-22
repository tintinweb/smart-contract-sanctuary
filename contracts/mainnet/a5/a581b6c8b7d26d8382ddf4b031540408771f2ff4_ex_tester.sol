/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IUnkCon {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ex_tester {
    function tokenURI(address target, uint256 tokenId) external view returns (string memory) {
        return IUnkCon(target).tokenURI(tokenId);
    }
}