/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface GovernorAlphaInterface {
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }


    function castVote(uint proposalId, bool support) external;
    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory);
}

contract Proxy {
    /// @notice The name of this contract
    string public constant name = "Proxy Voting Service";
    /// @notice The address of the Compound Protocol Governor
    GovernorAlphaInterface public governor_address;

    event VoteCast(uint proposalId, bool support);
    event NoVote();

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    constructor(address governor_address_) public {
        governor_address = GovernorAlphaInterface(governor_address_);
    }

    function castVote(uint proposalId) public {
        // check here.
        // if the biggest whale has more than 15%, vote against everything
        // if there are no females on the team, vote against

        // if address X votes for, then vote against, and vice-versa
        address nemesis = 0x526cc00B23Ce929aa0b7F90Ae1d6ba9fc494687D;

        bool hasVoted = governor_address.getReceipt(proposalId, nemesis).hasVoted;
        bool support = governor_address.getReceipt(proposalId, nemesis).support;

        if (hasVoted == true  && support == true) {
            governor_address.castVote(proposalId, false);
            emit VoteCast(proposalId, false);
        }
        else if (hasVoted == true  && support == false) {
            governor_address.castVote(proposalId, true);
            emit VoteCast(proposalId, false);
        }
        else {
            emit NoVote();
        }
    }

}