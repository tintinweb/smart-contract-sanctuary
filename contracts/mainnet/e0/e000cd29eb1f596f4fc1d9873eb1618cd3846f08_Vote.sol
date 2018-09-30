pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract Vote {
  using SafeMath for uint256;
  struct Proposal {
    uint deadline;
    mapping(address => uint) votes;
    uint yeas;
    uint nays;
    string reason;
    bytes data;
    address target;
  }
  struct Deposit {
    uint balance;
    uint lockedUntil;
  }

  event Proposed(
    uint proposalId,
    uint deadline,
    address target
  );

  event Executed(
    uint indexed proposalId
  );

  event Vote(
    uint indexed proposalId,
    address indexed voter,
    uint yeas,
    uint nays,
    uint totalYeas,
    uint totalNays
  );

  ERC20 public token;
  uint public proposalDuration;
  Proposal[] public proposals;
  mapping(address => Deposit) public deposits;
  mapping(address => bool) public proposers;

  constructor(address _token) {
    proposers[msg.sender] = true;
    token = ERC20(_token);
    proposalDuration = 5;
    // Start with a passed proposal to increase the duration to 24 hours.
    // Having a short initial proposalDuration makes testing easier, but 24
    // hours is a more reasonable time frame for voting. Having a pre-approved
    // proposal to increase the time means it only has to be executed, and not
    // voted on, as proposing a vote and voting on it within a 5 second
    // duration could be very difficult to accomplish on a main network.
    proposals.push(Proposal({
      deadline: block.timestamp,
      yeas: 1,
      nays: 0,
      reason: "",
      // ABI Encoded setProposalDuration(60*60*24)
      data: hex"7d007ac10000000000000000000000000000000000000000000000000000000000015180",
      target: this
    }));
  }

  // In order to vote on a proposal, voters must deposit tokens in the contract
  function deposit(uint units) public {
    require(token.transferFrom(msg.sender, address(this), units), "Transfer failed");
    deposits[msg.sender].balance = deposits[msg.sender].balance.add(units);
  }

  // Once all proposals a user has voted on have completed, they may withdraw
  // their tokens from the contract.
  function withdraw(uint units) external {
    require(deposits[msg.sender].balance >= units, "Insufficient balance");
    require(deposits[msg.sender].lockedUntil < block.timestamp, "Deposit locked");
    deposits[msg.sender].balance = deposits[msg.sender].balance.sub(units);
    token.transfer(msg.sender, units);
  }

  // A user may cast a number of yea or nay votes equal to the number of tokens
  // they have deposited in the contract. This will lock the user&#39;s deposit
  // until the voting ends for this proposal. Locking deposits ensures the user
  // cannot vote, then transfer tokens away and use them to vote again.
  function vote(uint proposalId, uint yeas, uint nays) public {

    require(
      proposals[proposalId].deadline > block.timestamp,
      "Voting closed"
    );
    if(proposals[proposalId].deadline > deposits[msg.sender].lockedUntil) {
      // The voter&#39;s deposit is locked until the proposal deadline
      deposits[msg.sender].lockedUntil = proposals[proposalId].deadline;
    }
    // Track vote counts to ensure voters can only vote their deposited tokens
    proposals[proposalId].votes[msg.sender] = proposals[proposalId].votes[msg.sender].add(yeas).add(nays);
    require(proposals[proposalId].votes[msg.sender] <= deposits[msg.sender].balance, "Insufficient balance");

    // Presumably only one of these will change.
    proposals[proposalId].yeas = proposals[proposalId].yeas.add(yeas);
    proposals[proposalId].nays = proposals[proposalId].nays.add(nays);

    emit Vote(proposalId, msg.sender, yeas, nays, proposals[proposalId].yeas, proposals[proposalId].nays);
  }

  // depositAndVote allows users to call deposit() and vote() in a single
  // transaction.
  function depositAndVote(uint proposalId, uint yeas, uint nays) external {
    deposit(yeas.add(nays));
    vote(proposalId, yeas, nays);
  }

  // Authorized proposers may issue proposals. They must provide the contract
  // data, the target contract, and a reason for the proposal. The reason will
  // probably be a swarm / ipfs URL with a longer explanation.
  function propose(bytes data, address target, string reason) external {
    require(proposers[msg.sender], "Invalid proposer");
    require(data.length > 0, "Invalid proposal");
    uint proposalId = proposals.push(Proposal({
      deadline: block.timestamp + proposalDuration,
      yeas: 0,
      nays: 0,
      reason: reason,
      data: data,
      target: target
    }));
    emit Proposed(
      proposalId - 1,
      block.timestamp + proposalDuration,
      target
    );
  }

  // If a proposal has passed, it may be executed exactly once. Executed
  // proposals will have the data zeroed out, discounting gas for the submitter
  // and effectively marking the proposal as executed.
  function execute(uint proposalId) external {
    Proposal memory proposal = proposals[proposalId];
    require(
      // Voting is complete when the deadline passes, or a majority of all
      // token holders have voted yea.
      proposal.deadline < block.timestamp || proposal.yeas > (token.totalSupply() / 2),
      "Voting is not complete"
    );
    require(proposal.data.length > 0, "Already executed");
    if(proposal.yeas > proposal.nays) {
      proposal.target.call(proposal.data);
      emit Executed(proposalId);
    }
    // Even if the vote failed, we can still clean out the data
    proposals[proposalId].data = "";
  }

  // As the result of a vote, proposers may be authorized or deauthorized
  function setProposer(address proposer, bool value) public {
    require(msg.sender == address(this), "Setting a proposer requires a vote");
    proposers[proposer] = value;
  }

  // As the result of a vote, the duration of voting on a proposal can be
  // changed
  function setProposalDuration(uint value) public {
    require(msg.sender == address(this), "Setting a duration requires a vote");
    proposalDuration = value;
  }

  function proposalDeadline(uint proposalId) public view returns (uint) {
    return proposals[proposalId].deadline;
  }

  function proposalData(uint proposalId) public view returns (bytes) {
    return proposals[proposalId].data;
  }

  function proposalReason(uint proposalId) public view returns (string) {
    return proposals[proposalId].reason;
  }

  function proposalTarget(uint proposalId) public view returns (address) {
    return proposals[proposalId].target;
  }

  function proposalVotes(uint proposalId) public view returns (uint[]) {
    uint[] memory votes = new uint[](2);
    votes[0] = proposals[proposalId].yeas;
    votes[1] = proposals[proposalId].nays;
    return votes;
  }
}