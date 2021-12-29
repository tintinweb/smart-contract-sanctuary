/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Oracle {
    mapping(string => uint256) public prices;
    mapping(string => bool) public supportedIdentifiers;

    function setPrice(string memory _priceIdentifier, uint256 _newPrice) public returns (uint256) {
        require(supportedIdentifiers[_priceIdentifier], "Not supported asset");
        prices[_priceIdentifier] = _newPrice;
        return prices[_priceIdentifier];
    }

    function getPrice(string memory _priceIdentifier) public view returns (uint256) {
        require(supportedIdentifiers[_priceIdentifier], "Not supported asset");
        return prices[_priceIdentifier];
    }

    function addPriceIdentifier(string memory _priceIdentifier) public {
        supportedIdentifiers[_priceIdentifier] = true;
    }

    function isSupportedIdentifier(string memory _priceIdentifier) public view returns(bool) {
        return supportedIdentifiers[_priceIdentifier];
    }
}