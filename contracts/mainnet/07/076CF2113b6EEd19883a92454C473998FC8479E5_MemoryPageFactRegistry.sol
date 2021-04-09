/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.5.2;

import "FactRegistry.sol";

contract MemoryPageFactRegistryConstants {
    // A page based on a list of pairs (address, value).
    // In this case, memoryHash = hash(address, value, address, value, address, value, ...).
    uint256 internal constant REGULAR_PAGE = 0;
    // A page based on adjacent memory cells, starting from a given address.
    // In this case, memoryHash = hash(value, value, value, ...).
    uint256 internal constant CONTINUOUS_PAGE = 1;
}

/*
  A fact registry for the claim:
    I know n pairs (addr, value) for which the hash of the pairs is memoryHash, and the cumulative
    product: \prod_i( z - (addr_i + alpha * value_i) ) is prod.
  The exact format of the hash depends on the type of the page
  (see MemoryPageFactRegistryConstants).
  The fact consists of (pageType, prime, n, z, alpha, prod, memoryHash, address).
  Note that address is only available for CONTINUOUS_PAGE, and otherwise it is 0.
*/
contract MemoryPageFactRegistry is FactRegistry, MemoryPageFactRegistryConstants {
    event LogMemoryPageFactRegular(bytes32 factHash, uint256 memoryHash, uint256 prod);
    event LogMemoryPageFactContinuous(bytes32 factHash, uint256 memoryHash, uint256 prod);

    /*
      Registers a fact based of the given memory (address, value) pairs (REGULAR_PAGE).
    */
    function registerRegularMemoryPage(
        uint256[] calldata memoryPairs, uint256 z, uint256 alpha, uint256 prime)
        external returns (bytes32 factHash, uint256 memoryHash, uint256 prod)
    {
        require(memoryPairs.length < 2**20, "Too many memory values.");
        require(memoryPairs.length % 2 == 0, "Size of memoryPairs must be even.");
        require(z < prime, "Invalid value of z.");
        require(alpha < prime, "Invalid value of alpha.");
        (factHash, memoryHash, prod) = computeFactHash(memoryPairs, z, alpha, prime);
        emit LogMemoryPageFactRegular(factHash, memoryHash, prod);

        registerFact(factHash);
    }

    function computeFactHash(
        uint256[] memory memoryPairs, uint256 z, uint256 alpha, uint256 prime)
        internal pure returns (bytes32 factHash, uint256 memoryHash, uint256 prod) {
        uint256 memorySize = memoryPairs.length / 2;

        prod = 1;

        assembly {
            let memoryPtr := add(memoryPairs, 0x20)

            // Each value of memoryPairs is a pair: (address, value).
            let lastPtr := add(memoryPtr, mul(memorySize, 0x40))
            for { let ptr := memoryPtr } lt(ptr, lastPtr) { ptr := add(ptr, 0x40) } {
                // Compute address + alpha * value.
                let address_value_lin_comb := addmod(
                    /*address*/ mload(ptr),
                    mulmod(/*value*/ mload(add(ptr, 0x20)), alpha, prime),
                    prime)
                prod := mulmod(prod, add(z, sub(prime, address_value_lin_comb)), prime)
            }

            memoryHash := keccak256(memoryPtr, mul(/*0x20 * 2*/ 0x40, memorySize))
        }

        factHash = keccak256(
            abi.encodePacked(
                REGULAR_PAGE, prime, memorySize, z, alpha, prod, memoryHash, uint256(0))
        );
    }

    /*
      Registers a fact based on the given values, assuming continuous addresses.
      values should be [value at startAddr, value at (startAddr + 1), ...].
    */
    function registerContinuousMemoryPage(  // NOLINT: external-function.
        uint256 startAddr, uint256[] memory values, uint256 z, uint256 alpha, uint256 prime)
        public returns (bytes32 factHash, uint256 memoryHash, uint256 prod)
    {
        require(values.length < 2**20, "Too many memory values.");
        require(prime < 2**254, "prime is too big for the optimizations in this function.");
        require(z < prime, "Invalid value of z.");
        require(alpha < prime, "Invalid value of alpha.");
        require(startAddr < 2**64 && startAddr < prime, "Invalid value of startAddr.");

        uint256 nValues = values.length;

        assembly {
            // Initialize prod to 1.
            prod := 1
            // Initialize valuesPtr to point to the first value in the array.
            let valuesPtr := add(values, 0x20)

            let minus_z := mod(sub(prime, z), prime)

            // Start by processing full batches of 8 cells, addr represents the last address in each
            // batch.
            let addr := add(startAddr, 7)
            let lastAddr := add(startAddr, nValues)
            for {} lt(addr, lastAddr) { addr := add(addr, 8) } {
                // Compute the product of (lin_comb - z) instead of (z - lin_comb), since we're
                // doing an even number of iterations, the result is the same.
                prod :=
                    mulmod(prod,
                    mulmod(add(add(sub(addr, 7), mulmod(
                        mload(valuesPtr), alpha, prime)), minus_z),
                    add(add(sub(addr, 6), mulmod(
                        mload(add(valuesPtr, 0x20)), alpha, prime)), minus_z),
                    prime), prime)

                prod :=
                    mulmod(prod,
                    mulmod(add(add(sub(addr, 5), mulmod(
                        mload(add(valuesPtr, 0x40)), alpha, prime)), minus_z),
                    add(add(sub(addr, 4), mulmod(
                        mload(add(valuesPtr, 0x60)), alpha, prime)), minus_z),
                    prime), prime)

                prod :=
                    mulmod(prod,
                    mulmod(add(add(sub(addr, 3), mulmod(
                        mload(add(valuesPtr, 0x80)), alpha, prime)), minus_z),
                    add(add(sub(addr, 2), mulmod(
                        mload(add(valuesPtr, 0xa0)), alpha, prime)), minus_z),
                    prime), prime)

                prod :=
                    mulmod(prod,
                    mulmod(add(add(sub(addr, 1), mulmod(
                        mload(add(valuesPtr, 0xc0)), alpha, prime)), minus_z),
                    add(add(addr, mulmod(
                        mload(add(valuesPtr, 0xe0)), alpha, prime)), minus_z),
                    prime), prime)

                valuesPtr := add(valuesPtr, 0x100)
            }

            // Handle leftover.
            // Translate addr to the beginning of the last incomplete batch.
            addr := sub(addr, 7)
            for {} lt(addr, lastAddr) { addr := add(addr, 1) } {
                let address_value_lin_comb := addmod(
                    addr, mulmod(mload(valuesPtr), alpha, prime), prime)
                prod := mulmod(prod, add(z, sub(prime, address_value_lin_comb)), prime)
                valuesPtr := add(valuesPtr, 0x20)
            }

            memoryHash := keccak256(add(values, 0x20), mul(0x20, nValues))
        }

        factHash = keccak256(
            abi.encodePacked(
                CONTINUOUS_PAGE, prime, nValues, z, alpha, prod, memoryHash, startAddr)
        );

        emit LogMemoryPageFactContinuous(factHash, memoryHash, prod);

        registerFact(factHash);
    }
}