// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

/**
 * @dev Forked from
 * https://github.com/xtokenmarket/xaave/blob/master/contracts/mock/MockGovernanceV2.sol
 */
contract MockAaveGovernanceV2 {
    mapping(address => mapping(uint256 => bool)) public voteByVoter;

    function submitVote(uint256 proposalId, bool support) external {
        voteByVoter[msg.sender][proposalId] = support;
    }

    function getVoteByVoter(address voter, uint256 proposalId)
        public
        view
        returns (bool)
    {
        return voteByVoter[voter][proposalId];
    }
}

