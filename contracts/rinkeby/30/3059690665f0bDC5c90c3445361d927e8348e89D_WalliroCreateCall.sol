/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Create Call - Allows to use the different create opcodes to deploy a contract
contract WalliroCreateCall {
    event ContractCreation(address newContract);

    function performCreate2(
        uint256 value,
        bytes memory deploymentData,
        bytes32 salt
    ) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(value, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }

    function performCreate(uint256 value, bytes memory deploymentData) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }
}