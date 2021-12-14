/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// ENS Registry Contract
interface ENS {
    function resolver(bytes32 node) external view returns (Resolver);
}

// Chainlink Resolver
interface Resolver {
    function addr(bytes32 node) external view returns (address);
}

// Consumer contract
contract ENSConsumer {
    ENS ens;

    // ENS registry address: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
    constructor(address ensAddress) {
        ens = ENS(ensAddress);
    }
    
    // Use ID Hash instead of readable name
    // ETH / USD hash: 0xf599f4cd075a34b92169cf57271da65a7a936c35e3f31e854447fbb3e7eb736d
    function resolve(bytes32 node) public view returns(address) {
        Resolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }
}