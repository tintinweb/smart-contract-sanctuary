// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ElectionsPrincipal.sol";

library Elections {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * Finds:
     * - the winning candidate (and the number of votes cast for it),
     * - the number of votes cast for the runner up candidate,
     * - and the total number of votes cast for any candidate but `address(0)`
     *   (such votes are treated as abstained votes)
     * by transforming the set of `voters` (and reading each voter's decision
     * and the number of its votes via `principal`'s interface)
     * into the array of candidates with the sum of votes cast for each candidate,
     * then iterating through this array to find the TOP-2 candidates on the fly.
     *
     * Technical considerations: our experiments show that handling ≈2500 voters
     * with ≈10 unique candidates consumes almost 30M of gas - this is treated
     * as the best-case scenario, and that's why the internal memory arrays
     * are defined with the size of `2500` elements each.
     */
    function findTop2(
        EnumerableSet.AddressSet storage voters,
        ElectionsPrincipal principal
    )
        public
        view
        returns (
            address winningCandidate,
            uint256 winningCandidateVotes,
            uint256 runnerUpCandidateVotes,
            uint256 totalVotes
        )
    {
        (
            address[2500] memory candidatesList,
            uint256[2500] memory candidatesVotes,
            uint256 candidatesCount,
            uint256 totalVotes_
        ) = _convertVotersList(voters, principal);

        require(candidatesCount > 0, "no candidates");

        totalVotes = totalVotes_;

        // iterate thru the list of candidatesVotes making TOP-2 on the fly
        for (uint256 j = 0; j < candidatesCount; j++) {
            uint256 votes = candidatesVotes[j];

            if (votes > winningCandidateVotes) {
                // the winner found within this loop shifts the
                // winner found during previous loops down to the runner up
                runnerUpCandidateVotes = winningCandidateVotes;

                winningCandidate = candidatesList[j];
                winningCandidateVotes = votes;
            } else if (votes > runnerUpCandidateVotes) {
                runnerUpCandidateVotes = votes;
            }
        }
    }

    /**
     * Sums the votes of the `selectedVoters` (reading each voter's decision
     * and the number of its votes via `principal` interface) who cast their
     * votes for the `expectedCandidate`.
     *
     * @param expectedCandidate the candidate whom the votes to be sum where cast for
     * @param selectedVoters the ordered list of voters whose votes cast for the expected candidate should be summed
     * @param principal the interface to read each voter's decision and balance
     */
    function sumVotesFor(
        address expectedCandidate,
        address[] memory selectedVoters,
        ElectionsPrincipal principal
    ) public view returns (uint256 votes) {
        address prevVoter;
        for (uint256 j = 0; j < selectedVoters.length; j++) {
            address voter = selectedVoters[j];
            address candidate = principal.candidateOf(voter);
            if (
                candidate == expectedCandidate &&
                // make sure this list is ordered
                prevVoter < voter
            ) {
                votes += principal.votesOf(voter);
                prevVoter = voter;
            }
        }
    }

    /**
     * Sums the votes of the `selectedVoters` (reading each voter's decision
     * and the number of its votes via `principal` interface) who cast their
     * votes for anyone but `excludedCandidate` and `address(0)`.
     *
     * @param excludedCandidate the candidate whom the votes to not be sum where cast for
     * @param selectedVoters the ordered list of voters whose votes cast for anyone but `excludedCandidate` and `address(0)` should be summed
     * @param principal the interface to read voters' decisions and balances
     */
    function sumVotesExceptZeroAnd(
        address excludedCandidate,
        address[] memory selectedVoters,
        ElectionsPrincipal principal
    ) public view returns (uint256 votes) {
        address prevVoter;
        for (uint256 i = 0; i < selectedVoters.length; i++) {
            address voter = selectedVoters[i];
            address candidate = principal.candidateOf(voter);
            if (
                // exclude unwanted addresses
                candidate != excludedCandidate &&
                candidate != address(0) &&
                // make sure this list is ordered
                prevVoter < voter
            ) {
                votes += principal.votesOf(voter);
                prevVoter = voter;
            }
        }
    }

    /**
     * Determines the consensus. Consensus is reached when the number of `votes`
     * is more than a half of `totalVotes`, otherwise it is broken.
     */
    function calcConsensus(uint256 votes, uint256 totalVotes)
        public
        pure
        returns (bool)
    {
        return votes > (totalVotes / 2);
    }

    /**
     * Internal function to transform the set of `voters` into the array of
     * candidates.
     *
     * This function iterates through the set of `voters`, reading each
     * voter's decision and the number of votes via `principal` interface.
     *  A voter's decision is represented by the address of the candidate he/she
     * decided to cast its votes for;
     * a voter's number of votes is represented by the number of tokens at
     * its balance.
     *
     * Each found candidate is added to the `candidatesList` (only once),
     * and the number of votes given for him are added to the `candidatesVotes`
     * at the same index this candidate has been added to `candidatesList`.
     * Additionally, this function keeps track of the number of found candidates
     * via `candidatesCount` and the total number of votes cast for all
     * candidates (except `address(0)`) via `totalVotes`.
     */
    function _convertVotersList(
        EnumerableSet.AddressSet storage voters,
        ElectionsPrincipal principal
    )
        private
        view
        returns (
            address[2500] memory candidatesList,
            uint256[2500] memory candidatesVotes,
            uint256 candidatesCount,
            uint256 totalVotes
        )
    {
        // each found candidate is added to the candidatesList, and the number
        // of votes given for it are added at the respective index
        // in the candidatesVotes
        for (uint256 i = 0; i < voters.length(); i++) {
            address voter = voters.at(i);
            uint256 voterBalance = principal.votesOf(voter);
            address candidate = principal.candidateOf(voter);

            // a voter must have positive balance, and its candidate
            // must not be address(0)
            if (voterBalance > 0 && candidate != address(0)) {
                totalVotes += voterBalance;

                // this candidate may have been already added to the list,
                // we must look it up
                (bool found, uint256 foundIndex) = _findIndex(
                    candidate,
                    candidatesList,
                    candidatesCount
                );

                if (found) {
                    candidatesVotes[foundIndex] += voterBalance;
                } else {
                    candidatesList[candidatesCount] = candidate;
                    candidatesVotes[candidatesCount] = voterBalance;
                    candidatesCount++;
                }
            }
        }
    }

    /**
     * Internal function that returns the index of the element inside `array`
     * which is equal to `predicate`. If such element is not found, `found` is
     * set to `false`.
     */
    function _findIndex(
        address predicate,
        address[2500] memory array,
        uint256 length
    ) private pure returns (bool found, uint256 index) {
        for (uint256 j = 0; j < length; j++) {
            if (predicate == array[j]) {
                return (true, j);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

/**
 * This interface gives readonly access to ToonToken contract's data
 * needed by the `Elections` library
 */
interface ElectionsPrincipal {
    /**
     * Returns the address of a candidate a tokenholder account left its
     * votes for. In case of `address(0)` a voter is treated as an abstained.
     */
    function candidateOf(address account) external view returns (address);

    /**
     * Returns the number of votes the `account` has.
     */
    function votesOf(address account) external view returns (uint256);
}