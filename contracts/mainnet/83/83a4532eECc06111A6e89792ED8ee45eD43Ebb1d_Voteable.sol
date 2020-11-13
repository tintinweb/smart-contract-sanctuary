// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './Roleplay.sol';

/// @title Voteable
///
/// @notice This contract covers most functions about
/// proposals and votings
///
/// @dev Inehrit {Roleplay}
///
abstract contract Voteable is Roleplay {
  /// @dev Declare an internal variable of type uint256
  ///
  uint256 internal _minVoteBalance;

  /// @dev Structure declaration of {Proposal} data model
  ///
  struct Proposal {
    address creator;
    string name;
    string metadataURI;
    bool votingEnabled;
    uint256 positiveVote;
    uint256 negativeVote;
    address[] positiveVoters;
    address[] negativeVoters;
  }

  /// @dev Declare a public constant of type bytes32
  ///
  /// @return The bytes32 string of the role
  ///
  bytes32 public constant ROLE_CHAIRPERSON = keccak256("CHAIRPERSON");

  /// @dev Declare an array of {Proposal}
  ///
  Proposal[] proposals;

  /// @dev Verify if the sender have the chairperson role
  /// 
  /// Requirements:
  /// {_hasRole} should be true
  ///
  modifier isChairperson() {
    require(
      hasRole(ROLE_CHAIRPERSON, msg.sender),
      "VC:500"
    );
    _;
  }

  /// @dev Verify if the sender is a valid voter
  ///
  /// Requirements:
  /// {_balance} should be superior to 1
  /// {_voter} should haven't already voted
  ///
  /// @param _id - Represent the proposal index
  /// @param _balance - Represent the sender balance
  ///
  modifier isValidVoter(
    uint256 _id,
    uint256 _balance
  ) {
    require(
      _balance >= (_minVoteBalance * (10**8)),
      "VC:1010"
    );

    bool positiveVote = _checkSenderHasVoted(proposals[_id].positiveVoters, msg.sender);
    bool negativeVote = _checkSenderHasVoted(proposals[_id].negativeVoters, msg.sender);

    require(
      !positiveVote && !negativeVote,
      "VC:1020"
    );
    _;
  }

  /// @dev Verify if the proposal have voting enabled
  ///
  /// Requirements:
  /// {proposals[_id]} should have voting enabled
  ///
  /// @param _id - Represent the proposal index
  ///
  modifier isVoteEnabled(
    uint256 _id
  ) {
    require(
      proposals[_id].votingEnabled,
      "VC:1030"
    );
    _;
  }

  constructor() public {
    _minVoteBalance = 100;
  }

  /// @notice Expose the min balance required to vote
  ///
  /// @return The uint256 value of {_minVoteBalance}
  ///
  function minVoteBalance()
  public view returns (uint256) {
    return _minVoteBalance;
  }

  /// @notice Set the {_minVoteBalance}
  ///
  /// @dev Only owner can use this function
  ///
  /// @param _amount - Represent the requested ratio
  ///
  function setMinVoteBalance(
    uint256 _amount
  ) public virtual onlyOwner() {
    _minVoteBalance = _amount;
  }

  /// @notice Allow a chairperson to create a new {Proposal}
  ///
  /// @dev Sender should be a chairperson
  ///
  /// Requirements:
  /// See {Voteable::isChairperson()}
  ///
  /// @param _name - Represent the Proposal name
  /// @param _uri - Represent the Proposal metadata uri
  /// @param _enable - Represent if vote is enable/disable
  ///
  function createProposal(
    string memory _name,
    string memory _uri,
    bool _enable
  ) public virtual isChairperson() {
    proposals.push(
      Proposal({
        creator: msg.sender,
        name: _name,
        metadataURI: _uri,
        votingEnabled: _enable,
        positiveVote: 0,
        negativeVote: 0,
        positiveVoters: new address[](0),
        negativeVoters: new address[](0)
      })
    );
  }
  
  /// @notice Allow a chairperson to enable/disable voting
  /// for a proposal
  ///
  /// @dev Sender should be a chairperson
  ///
  /// Requirements:
  /// See {Voteable::isChairperson()}
  ///
  /// @param _id - Represent a proposal index
  ///
  function enableProposal(
    uint256 _id
  ) public virtual isChairperson() {
    proposals[_id].votingEnabled ?
    proposals[_id].votingEnabled = false :
    proposals[_id].votingEnabled = true;
  }

  /// @notice Expose all proposals
  ///
  /// @return A tuple of Proposal
  ///
  function exposeProposals()
  public view returns (Proposal[] memory) {
    return proposals;
  }

  /// @notice Verify if the sender have already voted
  /// for a proposal
  ///
  /// @dev The function iterate hover the {_voters}
  /// to know if the sender have already voted
  ///
  /// @param _voters - Represent the positive/negative
  /// voters of a proposal
  ///
  function _checkSenderHasVoted(
    address[] memory _voters,
    address _voter
  ) private pure returns (bool) {
    uint256 i = 0;
    bool voted = false;
    uint256 len = _voters.length;
    while (i < len) {
      if (_voters[i] == _voter) {
        voted = true;
        break;
      }
      i++;
    }

    return voted;
  }
}