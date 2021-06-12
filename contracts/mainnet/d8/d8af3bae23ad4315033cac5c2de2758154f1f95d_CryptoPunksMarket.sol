/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract CryptoPunksMarket {
    mapping(uint256 => address) public punkIndexToAddress;
}

/**
 *
 * @dev Proxy contract that retuns CryptoPunk owner via standard ERC-721 ownerOf() function
 * Written by Ryley Ohlsen, 06.11.2021.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ownerOf_punks {
    address public CRYPTOPUNKS_CONTRACT =
        0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    CryptoPunksMarket CryptoPunks;

    constructor() public {
        CryptoPunks = CryptoPunksMarket(CRYPTOPUNKS_CONTRACT);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 punkIndex) public view returns (address) {
        require(punkIndex < 10000, "Punk index too high. Punk does not exist");
        address owner = CryptoPunks.punkIndexToAddress(punkIndex);
        return owner;
    }
}