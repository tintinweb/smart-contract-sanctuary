/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

interface Verifier {
    // Checks whether an address is permitted to receive unrestricted stock.
    // For instance, this might verify that the address corresponds to an
    // accredited investor.
    function mayReceive(address _who) external view returns (bool);
}

contract PushoverVerifier is Verifier {
    function mayReceive(address _who) external pure override returns (bool) {
        _who;
        return true;
    }
}