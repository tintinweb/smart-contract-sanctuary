// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./_PrimeToken.sol";

/**
 * @dev Extended constructor for deploying on alternate chains.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract CrosschainPrime is PrimeToken {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address owner,
        address bwAdmin
    ) PrimeToken(_name, _symbol, _decimals, _totalSupply) {
        _addBwAdmin(bwAdmin);
        _addAdmin(owner);

        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function init(address) internal override {
        // Skip the original init function
    }
}