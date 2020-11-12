// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './Voteable.sol';
import './CreationEngineDApp.sol';

/// @title CreationEngineDAO
///
/// @notice This contract covers everything related
/// to the organization of Creation Engine
///
/// @dev Inehrit {Voteable} and {CreationEngineToken}
///
abstract contract CreationEngineDAO is Voteable, CreationEngineToken {
  
  /// @notice ROLE_CHAIRPERSON is granted to the
  /// original contract deployer
  ///
  /// @dev See {Roleplay::grantRole()}
  ///
  constructor() public {
    grantRole(ROLE_CHAIRPERSON, msg.sender);
  }

  /// @notice This function allows the sender to vote
  /// for a proposal, the vote can be positive or negative.
  /// The sender has to complete the requirements to be
  /// able to vote for a proposal.
  ///
  /// @dev Depending on the value of {_isPositiveVote}, add a
  /// *positive/negative* vote to the proposal, identified
  /// by its {_id}, then push the sender address into the
  /// voters pool of the proposal
  ///
  /// Requirements:
  /// See {Voteable::isValidVoter()} 
  /// See {Voteable::isVoteEnabled()} 
  ///
  /// @param _id - Represent the proposal id
  /// @param _isPositiveVote - Represent the vote type
  ///
  function voteForProposal(
    uint256 _id,
    bool _isPositiveVote
  ) public virtual isValidVoter(
    _id,
    balanceOf(msg.sender)
  ) isVoteEnabled(
    _id
  ) {
    if (_isPositiveVote) {
      proposals[_id].positiveVote += 1;
      proposals[_id].positiveVoters.push(msg.sender);
    }

    if (!_isPositiveVote) {
      proposals[_id].negativeVote += 1;
      proposals[_id].negativeVoters.push(msg.sender);
    }
  }
}