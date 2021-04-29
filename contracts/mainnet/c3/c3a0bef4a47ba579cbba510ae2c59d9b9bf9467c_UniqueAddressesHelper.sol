/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity 0.8.2;

/**
 * This file is part of the 1st Solidity Gas Golfing Contest.
 *
 * This work is licensed under Creative Commons Attribution ShareAlike 3.0.
 * https://creativecommons.org/licenses/by-sa/3.0/
 *
 * Author: Greg Hysen (hyszeth.eth)
 * Date: June 2018
 * Description: A simple hash table with open-addressing and linear probing
 *              is used to filter out duplicate array elements. The unique
 *              array is generated in-place, with distinct elements overwriting
 *              duplicates. At the end of the algorithm, these values are
 *              transposed to a separate array with a length equal to the number
 *              of unique elements.
 */
contract UniqueAddressesHelper {
    // Convert uint256 > address
    function toUint(address val) internal pure returns (uint256 addr) {
        assembly {
            addr := add(val, 32)
        }
    }

    // Convert address > uint256
    function toAddr(uint256 val) internal pure returns (address addr) {
        assembly {
            addr := add(val, 32)
        }
    }

    // Hash table size.
    // - Size should be prime for a good average distribution.
    // - Space is preallocated, for efficiency.
    // - Specific value was selected based on gas and average # of collisions.
    uint256 constant HASH_TABLE_SIZE = 313;

    // A randomly generated offset that is added to each entry in the hash table.
    // Rather than storing additional information on occupancy, we add this offset to each entry.
    // Since the table is initially zeroed out, we consider `0` to mean unoccupied.
    uint256 constant RAND_OFFSET =
        0x613c12789c3f663a544355053c9e1e25d50176d60796a155f553aa0f8445ee66;

    function uniqueAddresses(address[] memory input)
        public
        pure
        returns (address[] memory ret)
    {
        // Base cases
        uint256 inputLength = input.length;
        if (inputLength == 0 || inputLength == 1) return input;

        // Fast forward to second unique character, if one exists.
        uint256 firstCharacter = toUint(input[0]);
        uint256 i = 1;
        while (toUint(input[i]) == firstCharacter) {
            if (++i != inputLength) continue;
            // The entire array was composed of a single value.
            ret = createUniqueArray(input, 1);
            return ret;
        }

        // Run uniquify on remaining elements.
        // `i` is the index of the first mismatch.
        ret = uniquifyPrivate(input, inputLength, firstCharacter, i);
        return ret;
    }

    /**
     * @dev A simple hash table with open-addressing and linear probing
     *      is used to filter out duplicate array elements. The unique
     *      array is generated in-place, with distinct elements overwriting
     *      duplicates. At the end of the algorithm, these values are
     *      transposed to a separate array with a length equal to the number
     *      of unqiue elements.
     *
     * @param input The list of integers to uniquify.
     * @param inputLength The length of `input`.
     * @param current First element in `input`.
     * @param i Where to start search.
     * @return The input list, with any duplicate elements removed.
     */
    function uniquifyPrivate(
        address[] memory input,
        uint256 inputLength,
        uint256 current,
        uint256 i
    ) private pure returns (address[] memory) {
        // Create hash table; initialized to all zeroes.
        uint256[HASH_TABLE_SIZE] memory hashTable;
        // Record first element in `hashTable`
        uint256 hashKey = current % HASH_TABLE_SIZE;
        uint256 hashValue = current + RAND_OFFSET;
        hashTable[hashKey] = hashValue;
        // Unique elements overwrite duplicates in `input`.
        uint256 uniqueIndex = 1;
        // Holds the current hash value while searching the hash table.
        uint256 queriedHashValue;

        // Create unique list.
        while (i != inputLength) {
            // One the right side of `==`, `current` resolves
            // to the value it had on the previous loop iteration.
            if ((current = toUint(input[i])) == current) {
                ++i;
                continue;
            }

            // Check if current `input` element is unique.
            hashValue = current + RAND_OFFSET;
            if (
                (queriedHashValue = hashTable[
                    (hashKey = current % HASH_TABLE_SIZE)
                ]) == 0
            ) {
                // Current element is unique.
                // Move value to its correct position in `input` and record in hash table.
                if (uniqueIndex != i++) input[uniqueIndex] = toAddr(current);
                uniqueIndex++;
                hashTable[hashKey] = hashValue;
                continue;
            }

            // We know `hashKey` exists in `hashTable`, meaning this value
            // is either a duplcicate or we have a hash collision.
            while (queriedHashValue != hashValue) {
                // Calculate next key
                hashKey = (hashKey + 1) % HASH_TABLE_SIZE;
                // If non-zero, keep searching.
                if ((queriedHashValue = hashTable[(hashKey)]) != 0) {
                    continue;
                }
                // False positive, this element is unique.
                // Move value to its correct position in `input` and record in hash table.
                if (uniqueIndex != i) input[uniqueIndex] = toAddr(current);
                uniqueIndex++;
                hashTable[hashKey] = hashValue;
                break;
            }

            // We found a duplicate element. Increment index into `input`.
            ++i;
        }

        // If all elements were unique, simply return `input`.
        // Otherwise, transpose the unique list to its own array.
        if (i == uniqueIndex) return input;
        return createUniqueArray(input, uniqueIndex);
    }

    function createUniqueArray(address[] memory input, uint256 uniqueLength)
        private
        pure
        returns (address[] memory ret)
    {
        // Copy in groups of 10 to save gas.
        ret = new address[](uniqueLength);
        uint256 max = (uniqueLength / 10) * 10;
        uint256 i;
        while (i != max) {
            ret[i++] = input[i];
            ret[i++] = input[i];
            ret[i++] = input[i];
            ret[i++] = input[i];
            ret[i++] = input[i];
            ret[i++] = input[i];
            ret[i++] = input[i];
            ret[i++] = input[i];
            ret[i++] = input[i];
            ret[i++] = input[i];
        }
        while (i != uniqueLength) ret[i++] = input[i];
        return ret;
    }
}