// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./P365ERC721T.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract p365ERCToken is P365ERC721T {
    constructor(address _proxyRegistryAddress)
        P365ERC721T("Creature", "OSC", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://webar.perfect365.com/nft/creature/"; 
    }

    function contractURI() public pure returns (string memory) {
        return "https://creatures-api.opensea.io/contract/opensea-creatures";
    }
}