// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License

/*
    __                    _
   / /   ___  ____  _____(_)________  ____
  / /   / _ \/ __ \/ ___/ / ___/ __ \/ __ \
 / /___/  __/ /_/ / /  / / /__/ /_/ / / / /
/_____/\___/ .___/_/  /_/\___/\____/_/ /_/
          /_/

L3P was born on 17th March, 2021. You can relive its first day by using this link:

https://youtu.be/uvC-dGaUD_I

Lepricon is a player-owned and governed hyper-casual gaming platform with
elements of DeFi powered by its utility token, L3P, itself controlled by this
very contract.

We created L3P because we believe in the inevitable merging of the gaming and
blockchain industries, where game economies and currencies are owned and run
by the players who play them. Check back in 2030, and you will see we were
right.

Josh Galloway - Stephen Browne - Phil Ingram

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