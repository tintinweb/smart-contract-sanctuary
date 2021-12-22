/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IOpensea1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}


contract test {
    address authOpenseaContract = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;
    function verifyOwler(address account, uint256 tokenid) public view returns (uint256) {
        uint256 trufal = IOpensea1155(authOpenseaContract).balanceOf(account, tokenid);
        return trufal;
    }
}