pragma solidity ^0.6.0;

import "../../common/implementation/FixedPoint.sol";


/**
 * @title Computes vote results.
 * @dev The result is the mode of the added votes. Otherwise, the vote is unresolved.
 */
library ResultComputation {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *   INTERNAL LIBRARY DATA STRUCTURE    *
     ****************************************/

    struct Data {
        // Maps price to number of tokens that voted for that price.
        mapping(int256 => FixedPoint.Unsigned) voteFrequency;
        // The total votes that have been added.
        FixedPoint.Unsigned totalVotes;
        // The price that is the current mode, i.e., the price with the highest frequency in `voteFrequency`.
        int256 currentMode;
    }

    /****************************************
     *            VOTING FUNCTIONS          *
     ****************************************/

    /**
     * @notice Adds a new vote to be used when computing the result.
     * @param data contains information to which the vote is applied.
     * @param votePrice value specified in the vote for the given `numberTokens`.
     * @param numberTokens number of tokens that voted on the `votePrice`.
     */
    function addVote(
        Data storage data,
        int256 votePrice,
        FixedPoint.Unsigned memory numberTokens
    ) internal {
        data.totalVotes = data.totalVotes.add(numberTokens);
        data.voteFrequency[votePrice] = data.voteFrequency[votePrice].add(numberTokens);
        if (
            votePrice != data.currentMode &&
            data.voteFrequency[votePrice].isGreaterThan(data.voteFrequency[data.currentMode])
        ) {
            data.currentMode = votePrice;
        }
    }

    /****************************************
     *        VOTING STATE GETTERS          *
     ****************************************/

    /**
     * @notice Returns whether the result is resolved, and if so, what value it resolved to.
     * @dev `price` should be ignored if `isResolved` is false.
     * @param data contains information against which the `minVoteThreshold` is applied.
     * @param minVoteThreshold min (exclusive) number of tokens that must have voted for the result to be valid. Can be
     * used to enforce a minimum voter participation rate, regardless of how the votes are distributed.
     * @return isResolved indicates if the price has been resolved correctly.
     * @return price the price that the dvm resolved to.
     */
    function getResolvedPrice(Data storage data, FixedPoint.Unsigned memory minVoteThreshold)
        internal
        view
        returns (bool isResolved, int256 price)
    {
        FixedPoint.Unsigned memory modeThreshold = FixedPoint.fromUnscaledUint(50).div(100);

        if (
            data.totalVotes.isGreaterThan(minVoteThreshold) &&
            data.voteFrequency[data.currentMode].div(data.totalVotes).isGreaterThan(modeThreshold)
        ) {
            // `modeThreshold` and `minVoteThreshold` are exceeded, so the current mode is the resolved price.
            isResolved = true;
            price = data.currentMode;
        } else {
            isResolved = false;
        }
    }

    /**
     * @notice Checks whether a `voteHash` is considered correct.
     * @dev Should only be called after a vote is resolved, i.e., via `getResolvedPrice`.
     * @param data contains information against which the `voteHash` is checked.
     * @param voteHash committed hash submitted by the voter.
     * @return bool true if the vote was correct.
     */
    function wasVoteCorrect(Data storage data, bytes32 voteHash) internal view returns (bool) {
        return voteHash == keccak256(abi.encode(data.currentMode));
    }

    /**
     * @notice Gets the total number of tokens whose votes are considered correct.
     * @dev Should only be called after a vote is resolved, i.e., via `getResolvedPrice`.
     * @param data contains all votes against which the correctly voted tokens are counted.
     * @return FixedPoint.Unsigned which indicates the frequency of the correctly voted tokens.
     */
    function getTotalCorrectlyVotedTokens(Data storage data) internal view returns (FixedPoint.Unsigned memory) {
        return data.voteFrequency[data.currentMode];
    }
}
