// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestString {

    function baseTokenURI() public pure returns (string memory) {
        return "https://creatures-api.opensea.io/api/creature/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://creatures-api.opensea.io/contract/opensea-creatures";
    }
}