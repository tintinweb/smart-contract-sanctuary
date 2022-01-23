/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/PRNG.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract PRNG {
    int256 public seed;

    /**
        Retrive a new pseudo random number and rotate the seed.

        IMPORTANT:
        As stated in the official solidity 0.8.11 documentation in the first warning
        on top of the following permalink:
        https://docs.soliditylang.org/en/v0.8.11/abi-spec.html#encoding-of-indexed-event-parameters

        """
        If you use keccak256(abi.encodePacked(a, b)) and both a and b are dynamic types, it is easy 
        to craft collisions in the hash value by moving parts of a into b and vice-versa. More 
        specifically, abi.encodePacked("a", "bc") == abi.encodePacked("ab", "c"). If you use 
        abi.encodePacked for signatures, authentication or data integrity, make sure to always use 
        the same types and check that at most one of them is dynamic. Unless there is a compelling 
        reason, abi.encode should be preferred.
        """

        This is why in this PRNG generator we will always use abi.encode
     */
    function rotate() public returns (uint256) {
        // Allow overflow of the seed, what we want here is the possibility for
        // the seed to rotate indiscriminately over all the number in range without
        // ever throwing an error.
        // This give the possibility to call this function every time possible.
        // The seed presence gives also the possibility to call this function subsequently even in
        // the same transaction and receive 2 different outputs
        int256 previousSeed;
        unchecked {
            previousSeed = seed - 1;
            seed++;
        }

        return
            uint256(
                keccak256(
                    // The data encoded into the abi should give enough entropy for an average security but
                    // as solidity's source code is publicly accessible under certain conditions
                    // the value may be partially manipulated by evil actors
                    abi.encode(
                        seed,                                   // can be manipulated calling an arbitrary number of times this method
                        // keccak256(abi.encode(seed)),         // can be manipulated calling an arbitrary number of times this method
                        block.coinbase,                         // can be at least partially manipulated by miners (actual miner address)
                        block.difficulty,                       // defined by the network (cannot be manipulated)
                        block.gaslimit,                         // defined by the network (cannot be manipulated)
                        block.number,                           // can be manipulated by miners
                        block.timestamp,                        // can be at least partially manipulated by miners (+-15s allowed on eth for block acceptance)
                        // blockhash(block.number - 1),         // defined by the network (cannot be manipulated)
                        // blockhash(block.number - 2),         // defined by the network (cannot be manipulated)
                        block.basefee,                          // can be at least partially manipulated by miners
                        block.chainid,                          // defined by the network (cannot be manipulated)
                        gasleft(),                              // can be at least partially manipulated by users
                        // msg.data,                            // not allowed as strongly controlled by users, this can help forging a partially predictable hash
                        msg.sender,                             // can be at least partially manipulated by users (actual caller address)
                        msg.sig,                                // current function identifier (cannot be manipulated)
                        // msg.value,                           // not allowed as strongly controlled by users, this can help forging a partially predictable hash
                        previousSeed                            // can be manipulated calling an arbitrary number of times this method
                        // keccak256(abi.encode(previousSeed))  // can be manipulated calling an arbitrary number of times this method
                    )
                )
            );
    }
}