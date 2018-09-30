/**
 * Copyright (c) 2018 blockimmo AG <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1b7772787e75687e5b797774787072767674357873">[email&#160;protected]</a>
 * Non-Profit Open Software License 3.0 (NPOSL-3.0)
 * https://opensource.org/licenses/NPOSL-3.0
 */


pragma solidity 0.4.25;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract LandRegistryProxyInterface {
  function owner() public view returns (address);
}


contract TokenizedPropertyInterface {
  function balanceOf(address _who) public view returns (uint256);
  function emitGenericProposal(string _generic) public;
  function lastTransferBlock(address _account) public view returns (uint256);
  function registryProxy() public view returns (LandRegistryProxyInterface);
  function setManagementCompany(string _managementCompany) public;
  function totalSupply() public view returns (uint256);
  function transferOwnership(address _newOwner) public;
  function untokenize() public;
}


/**
 * @title ShareholderDAO
 * @dev A simple DAO attached to a `TokenizedProperty` (ownership of the property is transferred to `this`).
 *
 * The token holders of a property `extend` and `vote` on `Proposal`s which are either executed (over 50% consensus) or rejected.
 * Proposals are `Executed` or `Rejected` at or after their `closingTime`, when a token holder or blockimmo calls `finalize` on the proposal.
 * Generic information related to a proposal can be included in the `_generic` string (ie the configuration details of an outright sale&#39;s `TokenSale`).
 * `Generic` proposals can also be extended. A property&#39;s management company and / or blockimmo will try to take these as suggestions.
 *
 * There are only a few decisions that token holders (investors in a property) can (and need) to make.
 * No need to be general. We keep it simple and minimal here, enabling our users to accomplish the necessary tasks.
 * - nothing more, nothing less.
 *
 * Just like in the real world, for commercial investment properties a `managementCompany` makes all decisions / actions involving a property.
 * Investors only need to `SetManagementCompany` - a suggestion blockimmo will always take (if possible).
 *
 * Aside from that, the only decisions investors need to make are:
 *
 * `TransferOwnership` enables `this` to be easily and reliably upgraded if consensus is reached on this proposal (ie a different form of DAO or a BDFL).
 *
 * Upgrading:
 *   1. A token holder deploys a new `ShareholderDAO`
 *   2. The token holder extends a proposal to `transferOwnership` of `TokenizedProperty` to the new DAO (1).
 *
 * See `TokenizedProperty`&#39;s documentation for info on `Untokenize` and how / why this is used.
 */
contract ShareholderDAO {
  using SafeMath for uint256;

  enum Actions { SetManagementCompany, TransferOwnership, Untokenize, Generic }
  enum Outcomes { Pend, Accept, Reject }
  enum ProposalStatus { Null, Executed, Open, Rejected }
  enum VoteStatus { Null, For, Against}

  struct Vote {
    VoteStatus status;
    uint256 clout;
  }

  struct Proposal {
    Actions action;
    uint256 closingTime;

    string managementCompany;
    address owner;
    string generic;

    address proposer;

    ProposalStatus status;
    uint256 tallyFor;
    uint256 tallyAgainst;
    uint256 blockNumber;

    mapping (address => Vote) voters;
  }

  mapping(bytes32 => Proposal) private proposals;
  TokenizedPropertyInterface public property;

  event ProposalRejected(bytes32 indexed proposal);
  event ProposalExecuted(bytes32 indexed proposal);
  event ProposalExtended(bytes32 indexed proposal, Actions indexed action, uint256 closingTime, string managementCompany, address owner, string generic, address indexed proposer);

  event Voted(bytes32 indexed proposal, address indexed voter, uint256 clout);
  event VoteRescinded(bytes32 indexed proposal, address indexed voter, uint256 clout);

  constructor(TokenizedPropertyInterface _property) public {
    property = _property;
  }

  modifier isAuthorized {
    require(getClout(msg.sender) > 0 || msg.sender == property.registryProxy().owner(), "must be blockimmo or tokenholder to perform this action");  // allow blockimmo to extend proposals for all properties
    _;
  }

  function extendProposal(Actions _action, uint256 _closingTime, string _managementCompany, address _owner, string _description) public isAuthorized {
    require(block.timestamp < _closingTime, "_closingTime must be in the future");

    bytes32 hash = keccak256(abi.encodePacked(_action, _closingTime, _managementCompany, _description, _owner));
    require(proposals[hash].status == ProposalStatus.Null, "proposal is not unique");

    proposals[hash] = Proposal(_action, _closingTime, _managementCompany, _owner, _description, msg.sender, ProposalStatus.Open, 0, 0, block.number);
    emit ProposalExtended(hash, _action, _closingTime, _managementCompany, _owner, _description, msg.sender);
  }

  function vote(bytes32 _hash, bool _isFor) public isAuthorized {
    Proposal storage p = proposals[_hash];
    Vote storage v = p.voters[msg.sender];

    require(p.status == ProposalStatus.Open, "vote requires proposal is open");
    require(block.timestamp < p.closingTime, "vote requires proposal voting period is open");
    require(p.voters[msg.sender].status == VoteStatus.Null, "voter has voted");
    require(p.blockNumber > property.lastTransferBlock(msg.sender), "voter ineligible due to transfer in voting period");

    uint256 clout = getClout(msg.sender);
    v.clout = clout;
    if (_isFor) {
      v.status = VoteStatus.For;
      p.tallyFor = p.tallyFor.add(clout);
    } else {
      v.status = VoteStatus.Against;
      p.tallyAgainst = p.tallyAgainst.add(clout);
    }

    emit Voted(_hash, msg.sender, clout);
  }

  function rescindVote(bytes32 _hash) public isAuthorized {
    Proposal storage p = proposals[_hash];
    Vote storage v = p.voters[msg.sender];

    require(p.status == ProposalStatus.Open, "rescindVote requires proposal is open");
    require(block.timestamp < p.closingTime, "rescindVote requires proposal voting period is open");
    require(v.status != VoteStatus.Null, "voter has not voted");

    uint256 clout = v.clout;
    if (v.status == VoteStatus.For) {
      p.tallyFor = p.tallyFor.sub(clout);
    } else if (v.status == VoteStatus.Against) {
      p.tallyAgainst = p.tallyAgainst.sub(clout);
    }

    v.status = VoteStatus.Null;
    v.clout = 0;

    emit VoteRescinded(_hash, msg.sender, clout);
  }

  function finalize(bytes32 _hash) public isAuthorized {
    Proposal storage p = proposals[_hash];

    require(p.status == ProposalStatus.Open, "finalize requires proposal is open");
    require(block.timestamp >= p.closingTime, "finalize requires proposal voting period is closed");

    Outcomes outcome = tallyVotes(p.tallyFor);
    if (outcome == Outcomes.Accept) {
      executeProposal(_hash);
    } else if (outcome == Outcomes.Reject) {
      p.status = ProposalStatus.Rejected;
      emit ProposalRejected(_hash);
    }
  }

  function getClout(address _who) internal view returns (uint256 clout) {
    clout = property.balanceOf(_who);
  }

  function tallyVotes(uint256 _tallyFor) internal view returns (Outcomes outcome) {
    if (_tallyFor > property.totalSupply() / 2) {
      outcome = Outcomes.Accept;
    } else {
      outcome = Outcomes.Reject;
    }
  }

  function executeProposal(bytes32 _hash) internal {
    Proposal storage p = proposals[_hash];

    if (p.action == Actions.SetManagementCompany) {
      property.setManagementCompany(p.managementCompany);
    } else if (p.action == Actions.TransferOwnership) {
      property.transferOwnership(p.owner);
    } else if (p.action == Actions.Untokenize) {
      property.untokenize();
    } else if (p.action == Actions.Generic) {
      property.emitGenericProposal(p.generic);
    }

    p.status = ProposalStatus.Executed;
    emit ProposalExecuted(_hash);
  }
}