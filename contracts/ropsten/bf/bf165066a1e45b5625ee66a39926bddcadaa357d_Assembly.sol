pragma solidity ^0.4.17;

// File: zeppelin/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/Managed.sol

/**
 * @title Managed
 * @dev The Managed is similar to Ownable, except that the manager is changed by the
 * owner, instead of the manager, making them a second tier role.
 */
contract Managed is Ownable {
  address public manager;

  /**
   * @dev Throws if called by any account other than the manager.
   */
  modifier onlyManager() {
    require(msg.sender == manager);
    _;
  }

  modifier onlyAdministrators() {
    bool isOwner = msg.sender == owner;
    bool isManager = msg.sender == manager;

    bool hasManager = manager != address(0x0);
    bool isManagerOwner = hasManager && msg.sender == Ownable(manager).owner();

    require(isOwner || isManager || isManagerOwner);
    _;
  }


  /**
   * @dev Allows the current owner to set the manager.
   * @param newManager The address to transfer ownership to.
   */
  function setManager(address newManager) onlyOwner public {
    manager = newManager;
  }

}

// File: zeppelin/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/StablePrice.sol

contract StablePrice is Managed {
  using SafeMath for uint256;

  uint8 public priceInUSD;

  // ETHUSD
  uint32 public exchangeRate = 100000;

  function StablePrice(uint8 _priceInUSD) {
    priceInUSD = _priceInUSD;
  }

  function setPrice(uint8 newPriceInUSD) public onlyOwner {
    priceInUSD = newPriceInUSD;
  }

  function setExchangeRate(uint32 newExchangeRate) public onlyAdministrators returns (bool) {
    exchangeRate = newExchangeRate;
  }

  function getPrice() public view returns (uint256) {
    uint256 exchangeRateInWei = SafeMath.div(1 ether, exchangeRate);
    return exchangeRateInWei.mul(priceInUSD);
  }

}

// File: contracts/Whitelisted.sol

contract Whitelisted is Managed {

  mapping (address => bool) whitelist;

  modifier onlyWhitelisted() {
    require(whitelist[msg.sender] || msg.sender == manager);
    _;
  }

  function setWhitelisted(address addr, bool isWhitelisted) public onlyAdministrators {
    whitelist[addr] = isWhitelisted;
  }

  function isWhitelisted(address addr) public view returns (bool) {
    return whitelist[addr] || addr == manager;
  }

}

// File: zeppelin/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin/contracts/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/MinutemanToken.sol

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract MinutemanToken is ERC20, Ownable, Managed, Whitelisted, StablePrice(10) {
  using SafeMath for uint256;

  string public symbol = "MMT";
  string public name = "Minuteman Token";
  uint8 public decimals = 0;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  function MinutemanToken() public {
    totalSupply = 0;
  }

  event Approval(address indexed holder, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Mint(address indexed receiver, uint256 value);

  /**
   * @dev Users can purchase tokens by sending Ether to the contract address. Any change from
   * the transaction will be returned to the sender.
   */
  function() public payable onlyWhitelisted {
    uint price = getPrice();
    uint tokens = msg.value.div(price);
    balances[msg.sender] = balances[msg.sender].add(tokens);
    msg.sender.transfer(msg.value % price);
    Mint(msg.sender, tokens);
  }

  /**
   * @dev Transfer tokens from one address to another. Standard token holders can transfer
   * allowed tokens to any eligible receiver, while the owner can transfer any tokens to any
   * address.
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(isWhitelisted(to));

    uint256 _allowance = allowed[from][msg.sender];

    // Check is not needed because sub(_allowance, value) will already throw if this condition is not met
    // require (value <= _allowance);

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = _allowance.sub(value);
    Transfer(from, to, value);
    return true;
  }


  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(isWhitelisted(spender));
    allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) public constant returns (uint256 remaining) {
    return allowed[owner][spender];
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param who The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address who) public constant returns (uint256) {
    return balances[who];
  }

  /**
   * @dev transfer token for a specified address
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public returns (bool) {
    require(isWhitelisted(to));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev The owner can mint new tokens, stored in the owner&#39;s wallet.
   * @param amount The number of tokens to mint.
   */
  function mint(uint256 amount) onlyManager public returns (bool){
    totalSupply = totalSupply.add(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);
    Mint(msg.sender, amount);
    return true;
  }

  /**
   * @dev The owner can withdraw the contract&#39;s Ether to their wallet.
   * @param amount The amount of Ether to withdraw.
   */
  function withdraw(uint256 amount) onlyOwner public returns (bool){
    owner.transfer(amount);
    return true;
  }

  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

}

// File: contracts/Manager.sol

contract Manager is Ownable {
  using SafeMath for uint256;

  mapping (uint152 => uint256) balances;

  MinutemanToken token;

  function Manager(address tokenAddress) public {
    token = MinutemanToken(tokenAddress);
  }

  event Withdraw(uint152 indexed from, address indexed to, uint256 value);
  event Deposit(address indexed from, uint152 indexed to, uint256 value);
  event Transfer(uint152 indexed from, uint152 indexed to, uint256 value);
  event Purchase(uint152 indexed user, uint256 value);

  /**
   * @dev Gets the balance of the specified wallet.
   * @param who The wallet to query the the balance of.
   * @return An uint256 representing the amount owned by the passed wallet.
   */
  function balanceOf(uint152 who) public constant returns (uint256) {
    return balances[who];
  }

  /**
   * @dev transfer token for a specified wallet
   * @param to The wallet to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(uint152 from, uint152 to, uint256 value) onlyOwner public returns (bool) {

    // SafeMath.sub will throw if there is not enough balance.
    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    Transfer(from, to, value);
    return true;
  }

  /**
   * @dev The owner can mint new tokens, stored in the owner&#39;s wallet.
   * @param amount The number of tokens to mint.
   */
  function purchase(uint152 user, uint256 amount) onlyOwner public returns (bool) {
    token.mint(amount);
    balances[user] = balances[user].add(amount);

    Purchase(user, amount);
    return true;
  }

  /**
   * @dev The owner can withdraw the contract&#39;s Ether to their wallet.
   * @param amount The amount of Ether to withdraw.
   */
  function withdraw(uint152 from, address to, uint256 amount) onlyOwner public returns (bool){
    balances[from] = balances[from].sub(amount);
    token.transfer(to, amount);
    Withdraw(from, to, amount);
    return true;
  }

  function deposit(address from, uint152 to) onlyOwner public returns (bool) {
    uint256 numberOfTokens = token.allowance(from, this);
    require(numberOfTokens > 0);
    token.transferFrom(from, this, numberOfTokens);
    balances[to] = balances[to].add(numberOfTokens);
    Deposit(from, to, numberOfTokens);
    return true;
  }

  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

}

// File: contracts/assembly/Allocations.sol

library Allocations {

  uint constant NUM_ALLOCATIONS = 5;

  struct Allocation {
    bytes16 name;
    uint8 percent;
  }

  /**
    * Packs an Investment struct into a 32-byte array
    * AAAASSEEHHHHHHHHHHHHHHHHHHHHHHHH
    * A = amount
    * S = Start time, compressed as days since January 1, 2018
    * S = End time, compressed as days since January 1, 2018
    * H = holding
    */
  function packAllocation(uint8[NUM_ALLOCATIONS] allocations) internal pure returns (bytes32) {
    bytes32 result;
    uint8 total;
    for (uint i = 0; i < NUM_ALLOCATIONS; i++) {
      result = (result << 8) | bytes32(allocations[i]);
      total += allocations[i];
    }
    require(total == 100);
    return result;
  }

  function unpackAllocation(bytes32 packedAllocation) internal pure returns (uint8[NUM_ALLOCATIONS] result) {
    for (uint i = 0; i < NUM_ALLOCATIONS; i++) {
      result[i] = uint8(bytes32(0xFF) & (packedAllocation >> ((NUM_ALLOCATIONS - (i + 1)) * 8)));
    }
  }
}

// File: contracts/assembly/Investments.sol

library Investments {

  uint constant DAYS_FROM_UNIX_TO_JAN1_2018 = 17532;
  uint constant BYTE = 8;

  struct Investment {
    uint32 amount;
    bytes24 holding;
    uint start;
    uint end;
  }

  /**
    * Packs an Investment struct into a 32-byte array
    * AAAASSEEHHHHHHHHHHHHHHHHHHHHHHHH
    * A = amount
    * S = Start time, compressed as days since January 1, 2018
    * S = End time, compressed as days since January 1, 2018
    * H = holding
    */
  function packInvestment(Investment investment) internal pure returns (bytes32) {
    bytes32 result = bytes32(investment.amount);

    bytes32 startDays = bytes32((investment.start / 1 days) - DAYS_FROM_UNIX_TO_JAN1_2018);
    result = (result << (2 * BYTE)) | startDays;

    bytes32 endDays = bytes32((investment.end / 1 days) - DAYS_FROM_UNIX_TO_JAN1_2018);
    result = (result << (2 * BYTE)) | endDays;

    result = (result << (24 * BYTE)) | (bytes32(investment.holding) >> (8 * BYTE));

    return result;
  }

  function unpackInvestment(bytes32 packedInvestment) internal pure returns (Investment result) {
    bytes32 holdingMask = bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) << (8 * BYTE);
    result.holding = bytes24((packedInvestment << (8 * BYTE)) & holdingMask);
    packedInvestment = packedInvestment >> (24 * BYTE);

    result.end = (uint(packedInvestment & 0xFFFF) + DAYS_FROM_UNIX_TO_JAN1_2018) * 1 days;
    packedInvestment = packedInvestment >> (2 * BYTE);

    result.start = (uint(packedInvestment & 0xFFFF) + DAYS_FROM_UNIX_TO_JAN1_2018) * 1 days;
    packedInvestment = packedInvestment >> (2 * BYTE);

    result.amount = uint32(packedInvestment & 0xFFFFFFFF);
  }
}

// File: contracts/assembly/Portfolio.sol

contract Portfolio {
  using SafeMath for uint256;

  uint constant NUM_ALLOCATIONS = 5;

  Allocations.Allocation[NUM_ALLOCATIONS] allocations;
  Investments.Investment[] investments;

  address assemblyAddress;

  event AllocationsChanged();
  event InvestmentAdded(uint index);

  function Portfolio(address _assembly) public {
    assemblyAddress = _assembly;

    allocations[0] = Allocations.Allocation("Tactical Capital", 48);
    allocations[1] = Allocations.Allocation("Safety Net", 20);
    allocations[2] = Allocations.Allocation("Options", 20);
    allocations[3] = Allocations.Allocation("Non-Profit", 10);
    allocations[4] = Allocations.Allocation("Management", 2);
  }

  function getAllocation(uint index) public view returns (bytes16, uint8) {
    return (allocations[index].name, allocations[index].percent);
  }

  function setAllocations(bytes32 newAllocations) public onlyAssembly {
    uint8[NUM_ALLOCATIONS] memory percents = Allocations.unpackAllocation(newAllocations);
    for (uint i = 0; i < NUM_ALLOCATIONS; i++) {
      allocations[i].percent = percents[i];
    }
    assertCorrectAllocations();
    AllocationsChanged();
  }

  function getNumInvestments() public view returns (uint) {
    return investments.length;
  }

  function getInvestment(uint index) public view returns (uint32, bytes24, uint, uint) {
    return (investments[index].amount, investments[index].holding,
      investments[index].start, investments[index].end);
  }

  function addInvestment(bytes32 newInvestment) public onlyAssembly {
    Investments.Investment memory investment = Investments.unpackInvestment(newInvestment);
    investment.start = now;
    investments.push(investment);
    InvestmentAdded(investments.length - 1);
  }

  function assertCorrectAllocations() private {
    uint8 total = 0;
    for (uint8 i = 0; i < NUM_ALLOCATIONS; i++) {
      total += allocations[i].percent;
    }
    require(total == 100);
  }

  modifier onlyAssembly() {
    require(msg.sender == assemblyAddress);
    _;
  }
}

// File: contracts/assembly/Assembly.sol

contract Assembly {
  using SafeMath for uint256;

  uint constant NUM_ALLOCATIONS = 5;

  enum VoteValue { ABSTAIN, OPPOSE, SUPPORT }
  enum ProposalType { PORTFOLIO_ALLOCATION, INVESTMENT }

  struct Proposal {
    bytes32 body;
    ProposalType proposalType;
    uint160 creator;
    bool isManaged;
    bool executed;
    bool isTopDown;
    bool isVetoed;
    uint closes;
    Vote[] votes;
  }

  struct Vote {
    uint160 owner;
    VoteValue isSupporting;
    bool isManaged;
  }

  Proposal[] proposals;

  MinutemanToken token;
  Portfolio public portfolio;

  event ProposalAdded(uint index, ProposalType proposalType);
  event VoteChange(uint160 owner, bool isManaged, bool isSupporting);
  event ProposalExecuted(uint index);

  function Assembly(address _token) public {
    token = MinutemanToken(_token);
    portfolio = new Portfolio(this);
  }

  function getNumProposals() public view returns (uint) {
    return proposals.length;
  }

  /**
    * Returns common information about a proposal
    * [type, creator, isManaged, executed, isTopDown, closes, numVotes]
    */
  function getProposal(uint index) public view returns (ProposalType, uint160, bool, bool, bool, uint, uint) {
    Proposal memory proposal = proposals[index];
    return (proposal.proposalType, proposal.creator, proposal.isManaged, proposal.executed,
      proposal.isTopDown, proposal.closes, proposal.votes.length);
  }

  function getAllocationProposal(uint index) public view returns (uint8[NUM_ALLOCATIONS]) {
    require(proposals[index].proposalType == ProposalType.PORTFOLIO_ALLOCATION);
    return Allocations.unpackAllocation(proposals[index].body);
  }

  function addAllocationProposal(uint8[NUM_ALLOCATIONS] allocations) public returns (uint) {
    uint160 user = getUser(msg.sender);

    bytes32 body = Allocations.packAllocation(allocations);
    Proposal storage proposal = createProposal(body, ProposalType.PORTFOLIO_ALLOCATION, user);
    proposal.isTopDown = (msg.sender == token.owner());

    return (proposals.length - 1);
  }

  function addManagedAllocationProposal(uint8[NUM_ALLOCATIONS] allocations, uint152 wallet) returns (uint) {
    uint160 user = getWalletUser(wallet);

    bytes32 body = Allocations.packAllocation(allocations);
    Proposal storage proposal = createProposal(body, ProposalType.PORTFOLIO_ALLOCATION, user);
    proposal.isManaged = true;

    return (proposals.length - 1);
  }

  function getInvestmentProposal(uint index) public view returns (uint32, bytes24, uint, uint) {
    require(proposals[index].proposalType == ProposalType.INVESTMENT);
    Investments.Investment memory investment = Investments.unpackInvestment(proposals[index].body);
    return (investment.amount, investment.holding, investment.start, investment.end);
  }

  function addInvestmentProposal(uint32 amount, bytes24 holding, uint end) public returns (uint) {
    uint160 user = getUser(msg.sender);

    Investments.Investment memory investment = Investments.Investment(amount, holding, now + 30 minutes, end);
    bytes32 body = Investments.packInvestment(investment);

    Proposal storage proposal = createProposal(body, ProposalType.INVESTMENT, user);
    proposal.isTopDown = (msg.sender == token.owner());

    return (proposals.length - 1);
  }

  function addManagedInvestmentProposal(uint32 amount, bytes24 holding, uint end, uint152 wallet) returns (uint) {
    uint160 user = getWalletUser(wallet);

    Investments.Investment memory investment = Investments.Investment(amount, holding, now + 30 minutes, end);
    bytes32 body = Investments.packInvestment(investment);

    Proposal storage proposal = createProposal(body, ProposalType.INVESTMENT, user);
    proposal.isManaged = true;

    return (proposals.length - 1);
  }

  function createProposal(bytes32 body, ProposalType proposalType, uint160 creator) private returns (Proposal storage) {
    uint proposalId = proposals.length++;
    Proposal storage proposal = proposals[proposalId];
    proposal.proposalType = proposalType;
    proposal.body = body;
    proposal.creator = creator;
    proposal.closes = now + 30 minutes;

    emit ProposalAdded(proposalId, ProposalType.PORTFOLIO_ALLOCATION);
    return proposal;
  }

  function getVote(uint proposalIndex, uint voteIndex) public view returns (bool, bool, uint160, bool) {
    Proposal memory proposal = proposals[proposalIndex];

    bool isSupporting = proposal.votes[voteIndex].isSupporting == VoteValue.SUPPORT;
    bool hasVoted = proposal.votes[voteIndex].isSupporting != VoteValue.ABSTAIN;
    return (isSupporting, hasVoted, proposal.votes[voteIndex].owner, proposal.votes[voteIndex].isManaged);
  }

  /** Returns (userDidVote, isSupporting)
    * Supporting: (true, true) Opposing: (true, false) Abstain: (false, fasle);
    */
  function getUserVote(uint proposalIndex, uint160 owner, bool isManaged) public view returns (bool, bool) {
    Proposal memory votingProposal = proposals[proposalIndex];

    for (uint i = 0; i < votingProposal.votes.length; i++) {
      if (votingProposal.votes[i].owner == owner && votingProposal.votes[i].isManaged == isManaged) {
        bool isSupporting = votingProposal.votes[i].isSupporting == VoteValue.SUPPORT;
        return (true, isSupporting);
      }
    }
    return (false, false);
  }

  function setVote(uint proposalIndex, bool isSupporting) public {
    uint160 user = getUser(msg.sender);

    setVoteInternal(proposalIndex, user, false, isSupporting);
  }

  function setManagedVote(uint proposalIndex, uint152 wallet, bool isSupporting) public {
    uint160 user = getWalletUser(wallet);

    setVoteInternal(proposalIndex, user, true, isSupporting);
  }

  function setVoteInternal(uint proposalIndex, uint160 user, bool isManaged, bool isSupporting) private {
    require(proposalIndex < proposals.length);
    Proposal storage votingProposal = proposals[proposalIndex];
    require(votingProposal.closes > now);

    VoteValue voteVal = isSupporting ? VoteValue.SUPPORT : VoteValue.OPPOSE;
    for (uint i = 0; i < votingProposal.votes.length; i++) {
      Vote storage vote = votingProposal.votes[i];
      if (vote.owner == user && vote.isManaged == isManaged) {
        vote.isSupporting = voteVal;
        emit VoteChange(user, isManaged, isSupporting);
        return;
      }
    }

    votingProposal.votes.push(Vote(user, voteVal, isManaged));
    emit VoteChange(user, isManaged, isSupporting);
  }

  function setVeto(uint proposalIndex, bool isVetoed) public {
    require(msg.sender == token.owner());
    require(proposalIndex < proposals.length);
    proposals[proposalIndex].isVetoed = isVetoed;
  }

  function tallyVotes(uint proposalIndex) public view returns (uint support, uint oppose) {
    Proposal memory votingProposal = proposals[proposalIndex];

    for (uint i = 0; i < votingProposal.votes.length; i++) {
      if (votingProposal.votes[i].isSupporting == VoteValue.SUPPORT) {
        support += getNumTokens(votingProposal.votes[i]);
      } else if (votingProposal.votes[i].isSupporting == VoteValue.OPPOSE) {
        oppose += getNumTokens(votingProposal.votes[i]);
      }
    }
  }

  function votePassed(uint proposalIndex) public view returns (bool) {
    if (proposals[proposalIndex].isVetoed) {
      return false;
    }

    var (support, oppose) = tallyVotes(proposalIndex);

    if (proposals[proposalIndex].isTopDown) {
      return !(oppose > (token.totalSupply() / 2));
    }

    return support > (token.totalSupply() / 2);
  }

  function executeProposal(uint proposalId) public {
    require(proposalId < proposals.length);
    Proposal storage proposal = proposals[proposalId];

    require(proposal.closes < now);
    require(!proposal.executed);
    require(votePassed(proposalId));

    if (proposal.proposalType == ProposalType.PORTFOLIO_ALLOCATION) {
      portfolio.setAllocations(proposal.body);
    } else if (proposal.proposalType == ProposalType.INVESTMENT) {
      portfolio.addInvestment(proposal.body);
    }

    proposal.executed = true;
    ProposalExecuted(proposalId);
  }

  function getNumTokens(Vote vote) internal view returns (uint) {
    if (vote.isManaged) {
      Manager manager = Manager(token.manager());
      return manager.balanceOf(uint152(vote.owner));
    }

    return token.balanceOf(address(vote.owner));
  }

  function getWalletUser(uint152 wallet) private view returns (uint160) {
    Manager manager = Manager(token.manager());
    require(manager.balanceOf(wallet) > 0);
    return uint160(wallet);
  }

  function getUser(address sender) private view returns (uint160) {
    require(token.balanceOf(sender) > 0);

    return uint160(sender);
  }
}