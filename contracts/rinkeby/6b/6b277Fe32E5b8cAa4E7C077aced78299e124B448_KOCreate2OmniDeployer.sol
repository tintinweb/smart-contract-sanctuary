/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// KnownOrigin's CREATE2 Contract Deployer - can be used in a omni-chain environment which is EVM based
// Based on https://andrecronje.medium.com/multichain-dapp-guide-standards-and-best-practices-8fabe2672c60
contract KOCreate2OmniDeployer {
    event Deployed(address addr, uint256 salt);

    function deploy(bytes memory code, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
    }
}