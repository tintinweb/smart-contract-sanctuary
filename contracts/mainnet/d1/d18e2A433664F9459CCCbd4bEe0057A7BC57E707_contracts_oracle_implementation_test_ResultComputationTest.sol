pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../ResultComputation.sol";
import "../../../common/implementation/FixedPoint.sol";


// Wraps the library ResultComputation for testing purposes.
contract ResultComputationTest {
    using ResultComputation for ResultComputation.Data;

    ResultComputation.Data public data;

    function wrapAddVote(int256 votePrice, uint256 numberTokens) external {
        data.addVote(votePrice, FixedPoint.Unsigned(numberTokens));
    }

    function wrapGetResolvedPrice(uint256 minVoteThreshold) external view returns (bool isResolved, int256 price) {
        return data.getResolvedPrice(FixedPoint.Unsigned(minVoteThreshold));
    }

    function wrapWasVoteCorrect(bytes32 revealHash) external view returns (bool) {
        return data.wasVoteCorrect(revealHash);
    }

    function wrapGetTotalCorrectlyVotedTokens() external view returns (uint256) {
        return data.getTotalCorrectlyVotedTokens().rawValue;
    }
}
