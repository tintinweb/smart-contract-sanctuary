pragma solidity ^0.4.13;

contract ERC20Interface {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract PoolAndSaleInterface {
    address public tokenSaleAddr;
    address public votingAddr;
    address public votingTokenAddr;
    uint256 public tap;
    uint256 public initialTap;
    uint256 public initialRelease;

    function setTokenSaleContract(address _tokenSaleAddr) external;
    function startProject() external;
}

contract DaicoPool is PoolAndSaleInterface, Ownable {
    using SafeMath for uint256;

    address public tokenSaleAddr;
    address public votingAddr;
    address public votingTokenAddr;
    uint256 public tap;
    uint256 public initialTap;
    uint256 public initialRelease;
    uint256 public releasedBalance;
    uint256 public withdrawnBalance;
    uint256 public lastUpdatedTime;
    uint256 public fundRaised;
    uint256 public closingRelease = 30 days;

    /* The unit of this variable is [10^-9 wei / token], intending to minimize rouding errors */
    uint256 public refundRateNano = 0;
  
    enum Status {
        Initializing,
        ProjectInProgress,
        Destructed
    }
  
    Status public status;

    event TapHistory(uint256 new_tap);
    event WithdrawalHistory(string token, uint256 amount);
    event Refund(address receiver, uint256 amount);

    modifier onlyTokenSaleContract {
        require(msg.sender == tokenSaleAddr);
        _;
    }

    modifier onlyVoting {
        require(msg.sender == votingAddr);
        _;
    }

    modifier poolInitializing {
        require(status == Status.Initializing);
        _;
    }

    modifier poolDestructed {
        require(status == Status.Destructed);
        _;
    }

    constructor(address _votingTokenAddr, uint256 tap_amount, uint256 _initialRelease) public {
        require(_votingTokenAddr != 0x0);
        require(tap_amount > 0);

        initialTap = tap_amount;
        votingTokenAddr = _votingTokenAddr;
        status = Status.Initializing;
        initialRelease = _initialRelease;
 
        votingAddr = new Voting(ERC20Interface(_votingTokenAddr), address(this));
    }

    function () external payable {}

    function setTokenSaleContract(address _tokenSaleAddr) external {
        /* Can be set only once */
        require(tokenSaleAddr == address(0x0));
        require(_tokenSaleAddr != address(0x0));
        tokenSaleAddr = _tokenSaleAddr;
    }

    function startProject() external onlyTokenSaleContract {
        require(status == Status.Initializing);
        status = Status.ProjectInProgress;
        lastUpdatedTime = block.timestamp;
        releasedBalance = initialRelease;
        updateTap(initialTap);
        fundRaised = address(this).balance;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        uint256 amount = _amount;

        updateReleasedBalance();
        uint256 available_balance = getAvailableBalance();
        if (amount > available_balance) {
            amount = available_balance;
        }

        withdrawnBalance = withdrawnBalance.add(amount);
        owner.transfer(amount);

        emit WithdrawalHistory("ETH", amount);
    }

    function raiseTap(uint256 tapMultiplierRate) external onlyVoting {
        updateReleasedBalance();
        updateTap(tap.mul(tapMultiplierRate).div(100));
    }

    function selfDestruction() external onlyVoting {
        status = Status.Destructed;
        updateReleasedBalance();
        releasedBalance = releasedBalance.add(closingRelease.mul(tap));
        updateTap(0);

        uint256 _totalSupply = ERC20Interface(votingTokenAddr).totalSupply(); 
        refundRateNano = address(this).balance.sub(getAvailableBalance()).mul(10**9).div(_totalSupply);
    }

    function refund(uint256 tokenAmount) external poolDestructed {
        require(ERC20Interface(votingTokenAddr).transferFrom(msg.sender, this, tokenAmount));

        uint256 refundingEther = tokenAmount.mul(refundRateNano).div(10**9);
        emit Refund(msg.sender, tokenAmount);
        msg.sender.transfer(refundingEther);
    }

    function getReleasedBalance() public view returns(uint256) {
        uint256 time_elapsed = block.timestamp.sub(lastUpdatedTime);
        return releasedBalance.add(time_elapsed.mul(tap));
    }
 
    function getAvailableBalance() public view returns(uint256) {
        uint256 available_balance = getReleasedBalance().sub(withdrawnBalance);

        if (available_balance > address(this).balance) {
            available_balance = address(this).balance;
        }

        return available_balance;
    }

    function isStateInitializing() public view returns(bool) {
        return (status == Status.Initializing); 
    }

    function isStateProjectInProgress() public view returns(bool) {
        return (status == Status.ProjectInProgress); 
    }

    function isStateDestructed() public view returns(bool) {
        return (status == Status.Destructed); 
    }

    function updateReleasedBalance() internal {
        releasedBalance = getReleasedBalance();
        lastUpdatedTime = block.timestamp;
    }

    function updateTap(uint256 new_tap) private {
        tap = new_tap;
        emit TapHistory(new_tap);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Voting{
    using SafeMath for uint256;

    address public votingTokenAddr;
    address public poolAddr;
    mapping (uint256 => mapping(address => uint256)) public deposits;
    mapping (uint => bool) public queued;

    uint256 proposalCostWei = 1 * 10**18;

    uint256 public constant VOTING_PERIOD = 14 days;

    struct Proposal {
        uint256 start_time;
        uint256 end_time;
        Subject subject;
        string reason;
        mapping (bool => uint256) votes; 
        uint256 voter_count;
        bool isFinalized;
        uint256 tapMultiplierRate;
    }

    Proposal[] public proposals;
    uint public constant PROPOSAL_EMPTY = 0;

    enum Subject {
        RaiseTap,
        Destruction
    }

    event Vote(
        address indexed voter,
        uint256 amount
    );

    event ReturnDeposit(
        address indexed voter,
        uint256 amount
    );

    event ProposalRaised(
        address indexed proposer,
        string subject 
    );

    /// @dev Constructor.
    /// @param _votingTokenAddr The contract address of ERC20 
    /// @param _poolAddr The contract address of DaicoPool
    /// @return 
    constructor (
        address _votingTokenAddr,
        address _poolAddr
    ) public {
        require(_votingTokenAddr != address(0x0));
        require(_poolAddr != address(0x0));
        votingTokenAddr = _votingTokenAddr;
        poolAddr = _poolAddr;

        // Insert an empty proposal as the header in order to make index 0 to be missing number.
        Proposal memory proposal;
        proposal.subject = Subject.RaiseTap;
        proposal.reason = "PROPOSAL_HEADER";
        proposal.start_time = block.timestamp -1;
        proposal.end_time = block.timestamp -1;
        proposal.voter_count = 0;
        proposal.isFinalized = true;

        proposals.push(proposal);
        assert(proposals.length == 1);
    }

    /// @dev Make a TAP raising proposal. It costs certain amount of ETH.
    /// @param _reason The reason to raise the TAP. This field can be an URL of a WEB site.
    /// @param _tapMultiplierRate TAP increase rate. From 101 to 200. i.e. 150 = 150% .
    /// @return 
    function addRaiseTapProposal (
        string _reason,
        uint256 _tapMultiplierRate
    ) external payable returns(uint256) {
        require(!queued[uint(Subject.RaiseTap)]);
        require(100 < _tapMultiplierRate && _tapMultiplierRate <= 200);

        uint256 newID = addProposal(Subject.RaiseTap, _reason);
        proposals[newID].tapMultiplierRate = _tapMultiplierRate;

        queued[uint(Subject.RaiseTap)] = true;
        emit ProposalRaised(msg.sender, "RaiseTap");
    }

    /// @dev Make a self destruction proposal. It costs certain amount of ETH.
    /// @param _reason The reason to destruct the pool. This field can be an URL of a WEB site.
    /// @return 
    function addDestructionProposal (string _reason) external payable returns(uint256) {
        require(!queued[uint(Subject.Destruction)]);

        addProposal(Subject.Destruction, _reason);

        queued[uint(Subject.Destruction)] = true;
        emit ProposalRaised(msg.sender, "SelfDestruction");
    }

    /// @dev Vote yes or no to current proposal.
    /// @param amount Token amount to be voted.
    /// @return 
    function vote (bool agree, uint256 amount) external {
        require(ERC20Interface(votingTokenAddr).transferFrom(msg.sender, this, amount));
        uint256 pid = this.getCurrentVoting();
        require(pid != PROPOSAL_EMPTY);

        require(proposals[pid].start_time <= block.timestamp);
        require(proposals[pid].end_time >= block.timestamp);

        if (deposits[pid][msg.sender] == 0) {
            proposals[pid].voter_count = proposals[pid].voter_count.add(1);
        }

        deposits[pid][msg.sender] = deposits[pid][msg.sender].add(amount);
        proposals[pid].votes[agree] = proposals[pid].votes[agree].add(amount);
        emit Vote(msg.sender, amount);
    }

    /// @dev Finalize the current voting. It can be invoked when the end time past.
    /// @dev Anyone can invoke this function.
    /// @return 
    function finalizeVoting () external {
        uint256 pid = this.getCurrentVoting();
        require(pid != PROPOSAL_EMPTY);
        require(proposals[pid].end_time <= block.timestamp);
        require(!proposals[pid].isFinalized);

        proposals[pid].isFinalized = true;

        if (isSubjectRaiseTap(pid)) {
            queued[uint(Subject.RaiseTap)] = false;
            if (isPassed(pid)) {
                DaicoPool(poolAddr).raiseTap(proposals[pid].tapMultiplierRate);
            }

        } else if (isSubjectDestruction(pid)) {
            queued[uint(Subject.Destruction)] = false;
            if (isPassed(pid)) {
                DaicoPool(poolAddr).selfDestruction();
            }
        }
    }

    /// @dev Return all tokens which specific account used to vote so far.
    /// @param account An address that deposited tokens. It also be the receiver.
    /// @return 
    function returnToken (address account) external returns(bool) {
        uint256 amount = 0;
    
        for (uint256 pid = 0; pid < proposals.length; pid++) {
            if(!proposals[pid].isFinalized){
              break;
            }
            amount = amount.add(deposits[pid][account]);
            deposits[pid][account] = 0;
        }

        if(amount <= 0){
           return false;
        }

        require(ERC20Interface(votingTokenAddr).transfer(account, amount));
        emit ReturnDeposit(account, amount);
 
        return true;
    }

    /// @dev Return tokens to multiple addresses.
    /// @param accounts Addresses that deposited tokens. They also be the receivers.
    /// @return 
    function returnTokenMulti (address[] accounts) external {
        for(uint256 i = 0; i < accounts.length; i++){
            this.returnToken(accounts[i]);
        }
    }

    /// @dev Return the index of on going voting.
    /// @return The index of voting. 
    function getCurrentVoting () public view returns(uint256) {
        for (uint256 i = 0; i < proposals.length; i++) {
            if (!proposals[i].isFinalized) {
                return i;
            }
        }
        return PROPOSAL_EMPTY;
    }

    /// @dev Check if a proposal has been agreed or not.
    /// @param pid Index of a proposal.
    /// @return True if the proposal passed. False otherwise. 
    function isPassed (uint256 pid) public view returns(bool) {
        require(proposals[pid].isFinalized);
        uint256 ayes = getAyes(pid);
        uint256 nays = getNays(pid);
        uint256 absent = ERC20Interface(votingTokenAddr).totalSupply().sub(ayes).sub(nays);
        return (ayes > nays.add(absent.div(6)));
    }

    /// @dev Check if a voting has started or not.
    /// @param pid Index of a proposal.
    /// @return True if the voting already started. False otherwise. 
    function isStarted (uint256 pid) public view returns(bool) {
        if (pid > proposals.length) {
            return false;
        } else if (block.timestamp >= proposals[pid].start_time) {
            return true;
        }
        return false;
    }

    /// @dev Check if a voting has ended or not.
    /// @param pid Index of a proposal.
    /// @return True if the voting already ended. False otherwise. 
    function isEnded (uint256 pid) public view returns(bool) {
        if (pid > proposals.length) {
            return false;
        } else if (block.timestamp >= proposals[pid].end_time) {
            return true;
        }
        return false;
    }

    /// @dev Return the reason of a proposal.
    /// @param pid Index of a proposal.
    /// @return Text of the reason that is set when the proposal made. 
    function getReason (uint256 pid) external view returns(string) {
        require(pid < proposals.length);
        return proposals[pid].reason;
    }

    /// @dev Check if a proposal is about TAP raising or not.
    /// @param pid Index of a proposal.
    /// @return True if it&#39;s TAP raising. False otherwise.
    function isSubjectRaiseTap (uint256 pid) public view returns(bool) {
        require(pid < proposals.length);
        return proposals[pid].subject == Subject.RaiseTap;
    }

    /// @dev Check if a proposal is about self destruction or not.
    /// @param pid Index of a proposal.
    /// @return True if it&#39;s self destruction. False otherwise.
    function isSubjectDestruction (uint256 pid) public view returns(bool) {
        require(pid < proposals.length);
        return proposals[pid].subject == Subject.Destruction;
    }

    /// @dev Return the number of voters take part in a specific voting.
    /// @param pid Index of a proposal.
    /// @return The number of voters.
    function getVoterCount (uint256 pid) external view returns(uint256) {
        require(pid < proposals.length);
        return proposals[pid].voter_count;
    }

    /// @dev Return the number of votes that agrees the proposal.
    /// @param pid Index of a proposal.
    /// @return The number of votes that agrees the proposal.
    function getAyes (uint256 pid) public view returns(uint256) {
        require(pid < proposals.length);
        require(proposals[pid].isFinalized);
        return proposals[pid].votes[true];
    }

    /// @dev Return the number of votes that disagrees the proposal.
    /// @param pid Index of a proposal.
    /// @return The number of votes that disagrees the proposal.
    function getNays (uint256 pid) public view returns(uint256) {
        require(pid < proposals.length);
        require(proposals[pid].isFinalized);
        return proposals[pid].votes[false];
    }

    /// @dev Internal function to add a proposal into the voting queue.
    /// @param _subject Subject of the proposal. Can be TAP raising or self destruction.
    /// @param _reason Reason of the proposal. This field can be an URL of a WEB site.
    /// @return Index of the proposal.
    function addProposal (Subject _subject, string _reason) internal returns(uint256) {
        require(msg.value == proposalCostWei);
        require(DaicoPool(poolAddr).isStateProjectInProgress());
        poolAddr.transfer(msg.value);

        Proposal memory proposal;
        proposal.subject = _subject;
        proposal.reason = _reason;
        proposal.start_time = block.timestamp;
        proposal.end_time = block.timestamp + VOTING_PERIOD;
        proposal.voter_count = 0;
        proposal.isFinalized = false;

        proposals.push(proposal);
        uint256 newID = proposals.length - 1;
        return newID;
    }
}