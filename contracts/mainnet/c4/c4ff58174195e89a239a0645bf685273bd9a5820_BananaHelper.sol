/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Banana Helper v0.9.0
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to 0xc4Ff58174195E89A239A0645BF685273bD9a5820
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
    
    function owners() external view returns(address[] memory ) {
        uint totalSupply = bananas.totalSupply();
        address[] memory result = new address[](totalSupply);
        for (uint tokenId = 0; tokenId < totalSupply; tokenId++) {
            result[tokenId] = bananas.ownerOf(tokenId);
        }
        return result;
    }

    function names() external view returns(string[] memory ) {
        uint totalSupply = bananas.totalSupply();
        string[] memory result = new string[](totalSupply);
        for (uint tokenId = 0; tokenId < totalSupply; tokenId++) {
            result[tokenId] = bananas.bananaNames(tokenId);
        }
        return result;
    }
}