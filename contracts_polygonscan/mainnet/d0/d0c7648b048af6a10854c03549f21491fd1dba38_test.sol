/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IOpensea1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract test {
    function verifyOwler(address account, uint256 tokenid) external view {
        IOpensea1155(0x2953399124F0cBB46d2CbACD8A89cF0599974963).balanceOf(account, tokenid);
    }
}