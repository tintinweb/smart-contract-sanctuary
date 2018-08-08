pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract Lending is Ownable, Pausable {
    using SafeMath for uint256;
    uint256 public minContribAmount = 0.1 ether;                          // 0.01 ether
    enum LendingState {AcceptingContributions, AwaitingReturn, ProjectNotFunded, ContributionReturned}

    mapping(address => Investor) public investors;
    uint256 public fundingStartTime;                                     // Start time of contribution period in UNIX time
    uint256 public fundingEndTime;                                       // End time of contribution period in UNIX time
    uint256 public totalContributed;
    bool public capReached;
    LendingState public state;
    address[] public investorsKeys;

    uint256 public lendingInterestRatePercentage;
    uint256 public totalLendingAmount;
    uint256 public lendingDays;
    uint256 public initialFiatPerEthRate;
    uint256 public totalLendingFiatAmount;
    address public borrower;
    uint256 public borrowerReturnDate;
    uint256 public borrowerReturnFiatAmount;
    uint256 public borrowerReturnFiatPerEthRate;
    uint256 public borrowerReturnAmount;

    struct Investor {
        uint amount;
        bool isCompensated;
    }

    // events
    event onCapReached(uint endTime);
    event onContribution(uint totalContributed, address indexed investor, uint amount, uint investorsCount);
    event onCompensated(address indexed contributor, uint amount);
    event excessContributionReturned(address indexed contributor, uint amount);
    event StateChange(uint state);

    function Lending(uint _fundingStartTime, uint _fundingEndTime, address _borrower, uint _lendingInterestRatePercentage, uint _totalLendingAmount, uint256 _lendingDays) public {
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        borrower = _borrower;
        // 115
        lendingInterestRatePercentage = _lendingInterestRatePercentage;
        totalLendingAmount = _totalLendingAmount;
        //90 days for version 0.1
        lendingDays = _lendingDays;
        state = LendingState.AcceptingContributions;
        StateChange(uint(state));
    }

    function() public payable whenNotPaused {
        if(state == LendingState.AwaitingReturn){
            returnBorroweedEth();
        } else{
            contributeWithAddress(msg.sender);
        }
    }

    function isContribPeriodRunning() public constant returns(bool){
        return fundingStartTime <= now && fundingEndTime > now && !capReached;
    }

    // @notice Function to participate in contribution period
    //  Amounts from the same address should be added up
    //  If cap is reached, end time should be modified
    //  Funds should be transferred into multisig wallet
    // @param contributor Address
    function contributeWithAddress(address contributor) public payable whenNotPaused {
        require(msg.value >= minContribAmount);
        require(isContribPeriodRunning());

        uint contribValue = msg.value;
        uint excessContribValue = 0;

        uint oldTotalContributed = totalContributed;

        totalContributed = oldTotalContributed.add(contribValue);

        uint newTotalContributed = totalContributed;

        // cap was reached
        if (newTotalContributed >=  totalLendingAmount &&
            oldTotalContributed < totalLendingAmount)
        {
            capReached = true;
            fundingEndTime = now;
            onCapReached(fundingEndTime);

            // Everything above hard cap will be sent back to contributor
            excessContribValue = newTotalContributed.sub(totalLendingAmount);
            contribValue = contribValue.sub(excessContribValue);

            totalContributed = totalLendingAmount;
        }

        if (investors[contributor].amount == 0) {
            investorsKeys.push(contributor);
        }

        investors[contributor].amount = investors[contributor].amount.add(contribValue);

        if (excessContribValue > 0) {
            msg.sender.transfer(excessContribValue);
            excessContributionReturned(msg.sender, excessContribValue);
        }
        onContribution(newTotalContributed, contributor, contribValue, investorsKeys.length);
    }

    function enableReturnContribution() external onlyOwner {
        require(totalContributed < totalLendingAmount);
        require(now > fundingEndTime);
        state = LendingState.ProjectNotFunded;
        StateChange(uint(state));
    }

    // @notice Function to participate in contribution period
    //  Amounts from the same address should be added up
    //  If cap is reached, end time should be modified
    //  Funds should be transferred into multisig wallet
    // @param contributor Address
    function finishContributionPeriod(uint256 _initialFiatPerEthRate) onlyOwner {
        require(capReached == true);
        initialFiatPerEthRate = _initialFiatPerEthRate;
        borrower.transfer(totalContributed);
        state = LendingState.AwaitingReturn;
        StateChange(uint(state));
        totalLendingFiatAmount = totalLendingAmount.mul(initialFiatPerEthRate);
        borrowerReturnFiatAmount = totalLendingFiatAmount.mul(lendingInterestRatePercentage).div(100);
    }

    function reclaimContribution(address beneficiary) external {
        require(state == LendingState.ProjectNotFunded);
        uint contribution = investors[beneficiary].amount;
        require(contribution > 0);
        beneficiary.transfer(contribution);
    }

    function establishBorrowerReturnFiatPerEthRate(uint256 _borrowerReturnFiatPerEthRate) external onlyOwner{
        require(state == LendingState.AwaitingReturn);
        borrowerReturnFiatPerEthRate = _borrowerReturnFiatPerEthRate;
        borrowerReturnAmount = borrowerReturnFiatAmount.div(borrowerReturnFiatPerEthRate);
    }

    function returnBorroweedEth() payable public {
        require(state == LendingState.AwaitingReturn);
        require(borrowerReturnFiatPerEthRate > 0);
        require(msg.value == borrowerReturnAmount);
        state = LendingState.ContributionReturned;
        StateChange(uint(state));
    }

    function reclaimContributionWithInterest(address beneficiary) external {
        require(state == LendingState.ContributionReturned);
        uint contribution = investors[beneficiary].amount.mul(initialFiatPerEthRate).mul(lendingInterestRatePercentage).div(borrowerReturnFiatPerEthRate).div(100);
        require(contribution > 0);
        beneficiary.transfer(contribution);
    }

    function selfKill() external onlyOwner {
        selfdestruct(owner);
    }
}