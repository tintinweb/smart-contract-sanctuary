/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IEnsRegistry {
    function resolver(bytes32 node) external view returns (address);
}

interface IEnsResolver {
    function addr(bytes32 node) external view returns (address);
}

contract EnsAddressResolver {
    address public ensRegistryAddress =
        0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    function resolveEnsNodeHash(bytes32 node) public view returns (address) {
        return
            IEnsResolver(IEnsRegistry(ensRegistryAddress).resolver(node)).addr(
                node
            );
    }
}