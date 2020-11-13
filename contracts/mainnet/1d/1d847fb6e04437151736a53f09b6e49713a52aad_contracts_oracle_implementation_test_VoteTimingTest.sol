pragma solidity ^0.6.0;

import "../../interfaces/VotingInterface.sol";
import "../VoteTiming.sol";


// Wraps the library VoteTiming for testing purposes.
contract VoteTimingTest {
    using VoteTiming for VoteTiming.Data;

    VoteTiming.Data public voteTiming;

    constructor(uint256 phaseLength) public {
        wrapInit(phaseLength);
    }

    function wrapComputeCurrentRoundId(uint256 currentTime) external view returns (uint256) {
        return voteTiming.computeCurrentRoundId(currentTime);
    }

    function wrapComputeCurrentPhase(uint256 currentTime) external view returns (VotingInterface.Phase) {
        return voteTiming.computeCurrentPhase(currentTime);
    }

    function wrapInit(uint256 phaseLength) public {
        voteTiming.init(phaseLength);
    }
}
