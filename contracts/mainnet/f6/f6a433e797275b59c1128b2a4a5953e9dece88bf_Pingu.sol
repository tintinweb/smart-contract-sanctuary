// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Pingu
 * Pingu - a contract for my non-fungible pingu.
 */
contract Pingu is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Chilly Bits", "CHB", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmR6VU9bk6zrLPEum1YVhiHvHbYWTME2kvrubSxaMjjghw/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmbSLArQhD8Np32Rotin9NRQtJj9AeFuNVmkrniFBj9GnC";
    }
}