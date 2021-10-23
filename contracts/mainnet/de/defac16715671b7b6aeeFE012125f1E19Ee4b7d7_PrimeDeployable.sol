// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License

/*
______      __           _
|  _  \    / _|         | |
| | | |___| |_ __ _  ___| |_ ___  _ __
| | | / _ \  _/ _` |/ __| __/ _ \| '__|
| |/ /  __/ || (_| | (__| || (_) | |
|___/ \___|_| \__,_|\___|\__\___/|_|

Defactor provides a gateway for traditional businesses to access the billions
of dollars currently available in Decentralized Finance (DeFi) liquidity pools,
offering a pipeline of real-world assets that can bring enormous value to the
DeFi ecosystem. Defactor will spawn new business models and new financial
products and services based on DeFi.  Defactor will help cement DeFi as a true
competitor to traditional finance.

For more information about the project visit https://www.defactor.com

*/
pragma solidity ^0.6.10;

import "./_PrimeToken.sol";

/**
 * @dev Extended constructor for added user groups and deployment fees.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract PrimeDeployable is PrimeToken {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address owner,
        address bwAdmin,
        address feeAccount,
        uint256 feePercentageTenths,
        address attorney,
        string memory _attorneyEmail
    ) public PrimeToken(_name, _symbol, _decimals, _totalSupply) {
        _addBwAdmin(bwAdmin);
        _addAdmin(owner);
        if (attorney != address(0x0)) {
            _addAttorney(attorney);
        }
        attorneyEmail = _attorneyEmail;

        // Percentage should be in tenths, so 1% would be 10
        if (feePercentageTenths > 0) {
            uint256 fee = totalTokenSupply.mul(feePercentageTenths).div(1000);
            balances[owner] = totalTokenSupply.sub(fee);
            emit Transfer(address(0), owner, balances[owner]);

            balances[feeAccount] = fee;
            emit Transfer(address(0), feeAccount, fee);
        } else {
            balances[owner] = totalTokenSupply;
            emit Transfer(address(0), owner, totalTokenSupply);
        }
    }

    function init(address) internal override {
        // Skip the original init function
    }
}