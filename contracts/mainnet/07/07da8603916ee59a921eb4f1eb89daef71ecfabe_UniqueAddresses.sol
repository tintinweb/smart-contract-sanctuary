/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.4.23;

/**
 * This file is part of the 1st Solidity Gas Golfing Contest.
 *
 * Author: Zachary Williamson
 *
 * This work is licensed under Creative Commons Attribution ShareAlike 3.0.
 * https://creativecommons.org/licenses/by-sa/3.0/
 */

library UniqueAddresses {
    function uniquify(address[]) external view returns(address[]) {
        assembly {
            // first, let's check there's actually some data to operate on
            0x24 calldataload 0x01 lt has_data jumpi
            calldatacopy(0, 0x04, calldatasize)
            return(0x00, sub(calldatasize, 0x04))
        has_data:
            0x44
            dup1 calldataload
            dup2 0x20 add calldataload
        test_run:
            lt input_is_ordered jumpi
            jump(maybe_has_non_trivial_structure)
        input_is_ordered:
            0x20 add
            dup1 calldataload
            dup2 0x20 add calldataload
            0x140 calldatasize sub dup4 lt test_run jumpi
        calldatacopy(0, 0x04, calldatasize)
        return(0x00, sub(calldatasize, 0x04))

        maybe_has_non_trivial_structure:
            pop
            0x44
            dup1 calldataload
            dup2 0x20 add calldataload
        test_reverse_run:
            gt input_is_reverse_ordered jumpi
            jump(probably_has_non_trivial_structure)
        input_is_reverse_ordered:
            0x20 add
            dup1 calldataload
            dup2 0x20 add calldataload
            0x140 calldatasize sub dup4 lt test_reverse_run jumpi
        calldatacopy(0, 0x04, calldatasize)
        return(0x00, sub(calldatasize, 0x04))

        probably_has_non_trivial_structure:
        pop
        0x64 0x44 calldataload         // prev index
        test_identical_loop:
            dup2 calldataload              // current prev index
            dup1 swap2                     // prev current current index
            eq iszero somewhat_likely_has_non_trivial_structure jumpi         // prev index        
            swap1 0x20 add swap1           // prev i'
            dup2 0x140 gt test_identical_loop jumpi
            0x20 0x00 mstore
            0x01 0x20 mstore
            0x44 calldataload 0x40 mstore
        return(0x00, 0x60) // hey, everything is the same!

        somewhat_likely_has_non_trivial_structure:
        pop pop
        0x44 0x44 calldataload
        test_pairs_outer_loop:
            swap1 0x20 add swap1            // prev i'
            dup2 calldataload               // current prev index
            dup1 swap2                      // prev current current index
            eq test_pairs_outer_loop jumpi  // current index
            // ok, now we have two unique elements  // a index
            0x44 calldataload                   // b a index
            test_pairs_inner_loop:
                swap2 0x20 add swap2            // b a index
                dup2                        // a b a index
                dup4 calldataload           // x a b a index
                dup3 dup2                   // x b x a b a index
                eq                          // (x=b?) x a b a
                swap2 eq or                 // (x=a|b) b a index
                iszero definitely_has_non_trivial_structure jumpi   // b a index
                dup3 0x140 calldatasize sub gt test_pairs_inner_loop jumpi
                // hey! There are only two elements!
                0x20 0x00 mstore
                0x02 0x20 mstore
                0x40 mstore
                0x60 mstore
                0x80 0x00 return


        definitely_has_non_trivial_structure:
            pop pop pop
            // Ok, at this point we have some interesting data to work on and this is where the algorithm really begins.
            // Push the calldata pointer onto the stack. First array element will be at index 0x44
            0x44
            // Create the hash table: converts a 8-bit key into a 256-bit
            // value. Only one bit is set high and there are 256 unique
            // permutations in the lookup table
            1 0x0 mstore
            2 0x20 mstore
            4 0x40 mstore
            8 0x60 mstore
            16 0x80 mstore
            32 0xa0 mstore
            64 0xc0 mstore
            128 0xe0 mstore

            // We want to use 'msize' as our pointer to the next element in our
            // output array. It's self-incrementing, so we don't need to call
            // '0x20 add' every iteration. It also costs 2 gas, as opposed to
            // duplicating a stack-based pointer which costs 3 gas.
            // Reducing the stack depth also removes the need for 1 swap op (3 gas),
            // as we would otherwise need to increment both the output array pointer
            // and the calldata pointer, which requires a swap
            // Total gas saving: 10 gas per iteration

            // in order to do this, we store data in a word that is one word after the
            // reserved bloom filter memory.
            // We use the memory from 0x100 to 0x900 to store our bloom filter,
            // which is 64 machine words. Having a value that is a power of 2 allows for
            // very cheap indexing in our main loop, which is worth the extra gas costs of a larger filter
            0x01 0x500 mstore
    // ### MAIN LOOP
    // We know there's at least one array element, so fall into the loop
        loop_start:
            dup1 calldataload           // stack state: v
            0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47 mul // stack state: h s
            dup1 0x3e0 and 0x100 add    // stack state: i h s
            swap1 28 byte mload         // stack state: b i s
            dup2 mload dup2 and skip_add_to_set jumpi
                dup3 calldataload msize mstore
                dup2 mload or           // stack state: r i s
                swap1 mstore            // stack state: s
                0x20 add                // stack state: s'

        // 2nd iteration
            dup1 calldataload           // stack state: v
            0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47 mul // stack state: h s
            dup1 0x3e0 and 0x100 add    // stack state: i h s
            swap1 28 byte mload         // stack state: b i s
            dup2 mload dup2 and skip_add_to_set jumpi
                dup3 calldataload msize mstore
                dup2 mload or           // stack state: r i s
                swap1 mstore            // stack state: s
                0x20 add                // stack state: s'

            calldatasize dup2 lt loop_start jumpi

            0x20 0x4e0 mstore          // stack state: s
            0x520 msize sub            // stack state: l s
            0x20 dup2 div 0x500 mstore // stack state: l s
            0x40 add 0x4e0 return

            skip_add_to_set:
                pop pop
                0x20 add
                calldatasize dup2 lt loop_start jumpi
            0x20 0x4e0 mstore          // stack state:
            0x520 msize sub            // stack state: l
            0x20 dup2 div 0x500 mstore // stack state: l
            0x40 add 0x4e0 return

            // the variable number of 'pop' instructions in the main loop upsets the compiler, poor thing
            // pop a stack variable to prevent it from throwing errors
            pop
        }
    }
}