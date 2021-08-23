// SPDX-License-Identifier: UNLICENSED

import "./openzeppelin.sol";

// File: contracts/TestCoin.sol

pragma solidity 0.8.0;




/*
 * Test Coin
 *
 */
contract TestCoin is ERC20PresetMinterPauser {
    using ECDSA for bytes32;

    mapping(address => mapping(uint256 => bool)) public nonceUsed;

    constructor(address vault) ERC20PresetMinterPauser("Test Coin", "TSTC") {
        // We create 18B coins but the token has 18 decimals.
        _mint(vault, 18000000000 * (10**18));
    }
}