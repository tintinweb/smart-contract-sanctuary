/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.7;

contract ContractDeployer {

    event ContractDeployed(bytes32 salt, address addr);

    /**
     * deploy contract by salt, contract bytecode and constructor args.
     */
    function deployContract(bytes32 salt, bytes memory contractBytecode, bytes memory constructorArgs) public {
        // deploy contracts with constructor (address):
        bytes memory payload = abi.encodePacked(contractBytecode, constructorArgs);

        address addr;
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        emit ContractDeployed(salt, addr);
    }
}