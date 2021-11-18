/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-18
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.2;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}