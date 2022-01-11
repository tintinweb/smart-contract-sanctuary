// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {RollCallGovernor} from "./RollCallGovernor.sol";

contract SimpleRollCallGovernor is RollCallGovernor {
    struct Count {
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
    }
    mapping(bytes32 => Count) private _count;

    constructor(
        string memory name_,
        address[] memory sources_,
        bytes32[] memory slots_,
        address bridge_
    ) public RollCallGovernor(name_, sources_, slots_, bridge_) {}

    function quorum(uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
        return 1;
    }

    function votingPeriod() public view override returns (uint256) {
        return 1;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(bytes32) internal view override returns (bool) {
        return true;
    }

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(bytes32 id) internal view override returns (bool) {
        return _count[id].votesFor > _count[id].votesAgainst;
    }

    function _countVote(bytes32 id, uint256[10] memory votes)
        internal
        override
    {
        _count[id].votesAgainst = _count[id].votesAgainst.add(votes[0]);
        _count[id].votesFor = _count[id].votesFor.add(votes[1]);
        _count[id].votesAbstain = _count[id].votesAbstain.add(votes[2]);
    }
}