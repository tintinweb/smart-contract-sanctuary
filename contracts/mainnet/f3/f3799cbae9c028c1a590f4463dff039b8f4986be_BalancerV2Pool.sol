/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @author Nicolás Venturo - @nventuro
 */
contract BalancerV2Pool {
    constructor(address vault) {
        // First Pool ever!
        (bool success, ) = vault.call(abi.encodePacked(bytes4(0x09b2760f), bytes32(0x0000000000000000000000000000000000000000000000000000000000000000)));
        require(success);
    }
}