/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.6.0;

contract ContractHash {
    function getContractHash(address a) public view returns (bytes32 hash) {
        assembly {
            hash := extcodehash(a)
        }
    }
}