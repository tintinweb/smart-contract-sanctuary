// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title '{EUR}Vouchers'
 * Used for purchasing all types of goods and services in FlyingAtom companies (including crypto in FAPL).
 * www.flyingatom.pl
*/

contract EURVoucher is ERC721Tradable {
    
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("EURVoucher ", "EURV", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://blockenomy.com/wp-content/API/EURVouchers/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://blockenomy.com/wp-content/API/EURVouchers/collection.json";
    }
}