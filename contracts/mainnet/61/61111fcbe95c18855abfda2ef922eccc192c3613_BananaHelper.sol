/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Banana Helper v0.9.2
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to 0x61111FcbE95c18855AbfdA2eF922EcCc192C3613
//
// SPDX-License-Identifier: MIT
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2021. The MIT Licence.
// ----------------------------------------------------------------------------

interface IBanana {
    function bananaNames(uint tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint);
    function ownerOf(uint tokenId) external view returns (address);
}


contract BananaHelper {
    IBanana public constant bananas = IBanana(0xB9aB19454ccb145F9643214616c5571B8a4EF4f2);
    
    function totalSupply() external view returns(uint) {
        return bananas.totalSupply();
    }

    function owners(uint from, uint to) external view returns(address[] memory) {
        require(from < to && to < bananas.totalSupply());
        address[] memory results = new address[](to - from);
        uint i = 0;
        for (uint tokenId = from; tokenId < to; tokenId++) {
            results[i++] = bananas.ownerOf(tokenId);
        }
        return results;
    }

    function names(uint from, uint to) external view returns(string[] memory) {
        require(from < to && to < bananas.totalSupply());
        string[] memory results = new string[](to - from);
        uint i = 0;
        for (uint tokenId = from; tokenId < to; tokenId++) {
            results[i++] = bananas.bananaNames(tokenId);
        }
        return results;
    }
}