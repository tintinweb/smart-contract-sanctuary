/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library Constants {
    string private constant _name = "POLYSTARTER";
    string private constant _symbol = "POLR";
    uint8 private constant _decimals = 18;
    address private constant _tokenOwner = 0x8a45c34e88d5f59c7C257B4151452689d40B5835;

    function getName() internal pure returns (string memory) {
        return _name;
    }

    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }

    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }

    function getTokenOwner() internal pure returns (address) {
        return _tokenOwner;
    }

}