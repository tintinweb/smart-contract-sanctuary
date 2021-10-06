/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
    event CloneCreated(address clone);
    // 0x363d608037635c60da1b3d523d60203d6004601c73${contract.address.split("x")[1].toLowerCase()}5afa3d82803e903d91603657fd5b9050808036608082515af43d82803e903d91604d57fd5bf3
    function clone(address implementation) public returns (address result) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x363d608037635c60da1b3d523d60203d6004601c730000000000000000000000)
            mstore(add(ptr, 0x15), shl(0x60, implementation))
            mstore(add(ptr, 0x29), 0x5afa3d82803e903d91603657fd5b9050808036608082515af43d82803e903d91)
            mstore(add(ptr, 0x49), 0x604d57fd5bf30000000000000000000000000000000000000000000000000000)
            result := create(0, ptr, 0x50)
        }
        emit CloneCreated(result);
    }

    function cloneDeterministic(address implementation, bytes32 salt) public returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x363d608037635c60da1b3d523d60203d6004601c730000000000000000000000)
            mstore(add(ptr, 0x15), shl(0x60, implementation))
            mstore(add(ptr, 0x29), 0x5afa3d82803e903d91603657fd5b9050808036608082515af43d82803e903d91)
            mstore(add(ptr, 0x49), 0x604d57fd5bf30000000000000000000000000000000000000000000000000000)
            instance := create2(0, ptr, 0x50, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
        emit CloneCreated(instance);
    }

    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            // let ptr := mload(0x40)
            // mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            // mstore(add(ptr, 0x14), shl(0x60, implementation))
            // mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            // mstore(add(ptr, 0x38), shl(0x60, deployer))
            // mstore(add(ptr, 0x4c), salt)
            // mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            // predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}