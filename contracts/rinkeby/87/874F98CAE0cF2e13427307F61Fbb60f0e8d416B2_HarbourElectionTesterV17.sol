/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: MIT

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

interface ITrackedToken is IERC20 {
  function lastSendBlockOf(address account) external view returns (uint256);
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

abstract contract AdminRole {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _addAdmin(msg.sender);
  }

  modifier onlyAdmin() {
    require(
      isAdmin(msg.sender),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(msg.sender);
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }
}

contract HarbourElection {
  using SafeMath for uint256;
  enum Vote {
    Null,
    Yes,
    No
  }
  struct ProposalVote {
    Vote vote;
    bool processed;
    uint256 voteCount;
    uint256 blockNumber;
  }
  struct Proposal {
    uint256 startTime;
    uint256 endTime;
    string details;
    uint256 voterCount;
    uint256 totalVotes;
    uint256 validatedYesCount;
    uint256 validatedNoCount;
    uint256 invalidCount;
    Vote result;
    bool complete;
    mapping(address => ProposalVote) votesByVoter;
  }
  event SubmitProposal(
    uint256 indexed proposalIndex,
    uint256 indexed startTime,
    uint256 indexed endTime
  );
  event SubmitVote(
    uint256 indexed proposalIndex,
    address indexed voter,
    uint256 voteCount,
    bool yes
  );
  event ValidateVote(
    uint256 indexed proposalIndex,
    address indexed voter,
    uint256 voteCount,
    bool yes
  );
  event ProcessProposal(uint256 indexed proposalIndex, bool yes);

  address payable private _creator;
  ITrackedToken public voteToken;
  mapping(uint256 => Proposal) public proposals;
  uint256 public proposalCount;

  constructor(address token) {
    _creator = payable(msg.sender);
    voteToken = ITrackedToken(token);
  }

  function withdraw(address erc20, uint256 amount) public {
    if (erc20 == address(0)) {
      _creator.transfer(amount);
    } else {
      IERC20(erc20).transfer(_creator, amount);
    }
  }

  function submitProposal(
    uint256 startTime,
    uint256 endTime,
    string calldata details
  ) public returns (uint256) {
    uint256 proposalIndex = proposalCount += 1;
    Proposal storage proposal = proposals[proposalIndex];
    proposal.startTime = startTime;
    proposal.endTime = endTime;
    proposal.details = details;
    emit SubmitProposal(proposalIndex, startTime, endTime);
    return proposalIndex;
  }

  function isVotingActive(uint256 proposalIndex) public view returns (bool) {
    Proposal storage proposal = proposals[proposalIndex];
    bool active = true;
    if (block.timestamp < proposal.startTime) {
      active = false;
    } else if (block.timestamp > proposal.endTime) {
      active = false;
    }
    return active;
  }

  function isVotingComplete(uint256 proposalIndex) public view returns (bool) {
    Proposal storage proposal = proposals[proposalIndex];
    return block.timestamp > proposal.endTime;
  }

  function _addVote(
    uint256 proposalIndex,
    address voter,
    bool yes
  ) internal returns (uint256) {
    Vote vote = yes ? Vote.Yes : Vote.No;
    Proposal storage proposal = proposals[proposalIndex];
    uint256 voteCount = voteToken.balanceOf(voter);

    if (voteCount > 0) {
      ProposalVote storage existing = proposal.votesByVoter[voter];
      if (existing.voteCount == 0) {
        proposal.voterCount += 1;
        proposal.totalVotes += voteCount;
      } else if (existing.voteCount != voteCount) {
        proposal.totalVotes -= existing.voteCount;
        proposal.totalVotes += voteCount;
      }

      proposal.votesByVoter[voter] = ProposalVote(
        vote,
        false,
        voteCount,
        block.number
      );
    }
    return voteCount;
  }

  function submitVote(uint256 proposalIndex, bool yes) public {
    require(isVotingActive(proposalIndex), 'voting_not_active');
    uint256 voteCount = _addVote(proposalIndex, msg.sender, yes);
    require(voteCount > 0, 'zero_balance');
    emit SubmitVote(proposalIndex, msg.sender, voteCount, yes);
  }

  function _validateVote(uint256 proposalIndex, address voter)
    internal
    returns (bool)
  {
    Proposal storage proposal = proposals[proposalIndex];
    ProposalVote storage vote = proposal.votesByVoter[voter];
    if (vote.voteCount > 0 && !vote.processed) {
      uint256 balance = voteToken.balanceOf(voter);
      uint256 lastSendBlock = voteToken.lastSendBlockOf(voter);
      if (lastSendBlock < vote.blockNumber && balance >= vote.voteCount) {
        if (vote.vote == Vote.Yes) {
          proposal.validatedYesCount += vote.voteCount;
          emit ValidateVote(proposalIndex, voter, vote.voteCount, true);
        } else if (vote.vote == Vote.No) {
          proposal.validatedNoCount += vote.voteCount;
          emit ValidateVote(proposalIndex, voter, vote.voteCount, false);
        } else {
          proposal.invalidCount += vote.voteCount;
          emit ValidateVote(proposalIndex, voter, 0, false);
        }
      } else {
        proposal.invalidCount += vote.voteCount;
        emit ValidateVote(proposalIndex, voter, 0, false);
      }
      vote.processed = true;
    }
    return vote.processed;
  }

  function checkVote(uint256 proposalIndex, address voter)
    public
    view
    returns (bool, uint256)
  {
    Proposal storage proposal = proposals[proposalIndex];
    ProposalVote storage vote = proposal.votesByVoter[voter];
    uint256 balance = voteToken.balanceOf(voter);
    uint256 lastSendBlock = voteToken.lastSendBlockOf(voter);
    bool valid = lastSendBlock < vote.blockNumber && balance >= vote.voteCount;
    return (valid, vote.voteCount);
  }

  function validateVote(uint256 proposalIndex, address voter)
    public
    returns (bool)
  {
    require(isVotingComplete(proposalIndex), 'voting_not_closed');
    Proposal storage proposal = proposals[proposalIndex];
    ProposalVote storage vote = proposal.votesByVoter[voter];
    require(vote.voteCount > 0, 'no_votes');
    require(!vote.processed, 'already_processed');
    return _validateVote(proposalIndex, voter);
  }

  function validateVoteList(uint256 proposalIndex, address[] calldata list)
    public
  {
    require(isVotingComplete(proposalIndex), 'voting_not_closed');
    uint256 count = list.length;
    for (uint256 i = 0; i < count; i++) {
      _validateVote(proposalIndex, list[i]);
    }
  }

  function processProposal(uint256 proposalIndex) public returns (Vote) {
    require(isVotingComplete(proposalIndex), 'voting_not_closed');
    Proposal storage proposal = proposals[proposalIndex];
    require(!proposal.complete, 'already_complete');

    uint256 validCount = proposal.totalVotes - proposal.invalidCount;
    require(validCount > 0, 'no_valid_votes');

    Vote result;
    if (proposal.validatedYesCount * 2 > validCount) {
      result = Vote.Yes;
    } else if (proposal.validatedNoCount * 2 > validCount) {
      result = Vote.No;
    } else {
      revert('not_determined');
    }
    proposal.result = result;
    proposal.complete = true;
    emit ProcessProposal(proposalIndex, result == Vote.Yes);
    return proposal.result;
  }

  function getProposalVote(uint256 proposalIndex, address voter)
    public
    view
    returns (ProposalVote memory)
  {
    Proposal storage proposal = proposals[proposalIndex];
    return proposal.votesByVoter[voter];
  }

  function getProposalResult(uint256 proposalIndex) public view returns (Vote) {
    Proposal storage proposal = proposals[proposalIndex];
    return proposal.result;
  }

  function getProposalVoterCount(uint256 proposalIndex)
    public
    view
    returns (uint256)
  {
    Proposal storage proposal = proposals[proposalIndex];
    return proposal.voterCount;
  }
}

contract HarbourElectionTesterV17 is HarbourElection, AdminRole {
  // solhint-disable-next-line
  constructor(address token) HarbourElection(token) {}

  function testAddSingle(
    uint256 proposalIndex,
    bool yes,
    address voter
  ) public onlyAdmin {
    _addVote(proposalIndex, voter, yes);
  }

  function testAddMulti(
    uint256 proposalIndex,
    uint160 startAddress,
    uint160 count,
    bool yes
  ) public onlyAdmin {
    for (uint160 i = 0; i < count; i++) {
      _addVote(proposalIndex, address(startAddress + i), yes);
    }
  }
}