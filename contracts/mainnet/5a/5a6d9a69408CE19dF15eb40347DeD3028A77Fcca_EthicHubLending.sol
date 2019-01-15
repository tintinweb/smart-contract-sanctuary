pragma solidity ^0.4.13;

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

contract EthicHubReputationInterface {
    modifier onlyUsersContract(){_;}
    modifier onlyLendingContract(){_;}
    function burnReputation(uint delayDays)  external;
    function incrementReputation(uint completedProjectsByTier)  external;
    function initLocalNodeReputation(address localNode)  external;
    function initCommunityReputation(address community)  external;
    function getCommunityReputation(address target) public view returns(uint256);
    function getLocalNodeReputation(address target) public view returns(uint256);
}

contract EthicHubStorageInterface {

    //modifier for access in sets and deletes
    modifier onlyEthicHubContracts() {_;}

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string);
    function getBytes(bytes32 _key) external view returns (bytes);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract EthicHubBase {

    uint8 public version;

    EthicHubStorageInterface public ethicHubStorage = EthicHubStorageInterface(0);

    constructor(address _storageAddress) public {
        require(_storageAddress != address(0));
        ethicHubStorage = EthicHubStorageInterface(_storageAddress);
    }

}

contract EthicHubLending is EthicHubBase, Ownable, Pausable {
    using SafeMath for uint256;
    //uint256 public minContribAmount = 0.1 ether;                          // 0.1 ether
    enum LendingState {
        Uninitialized,
        AcceptingContributions,
        ExchangingToFiat,
        AwaitingReturn,
        ProjectNotFunded,
        ContributionReturned,
        Default
    }
    mapping(address => Investor) public investors;
    uint256 public investorCount;
    uint256 public reclaimedContributions;
    uint256 public reclaimedSurpluses;
    uint256 public fundingStartTime;                                     // Start time of contribution period in UNIX time
    uint256 public fundingEndTime;                                       // End time of contribution period in UNIX time
    uint256 public totalContributed;
    bool public capReached;
    LendingState public state;
    uint256 public annualInterest;
    uint256 public totalLendingAmount;
    uint256 public lendingDays;
    uint256 public initialEthPerFiatRate;
    uint256 public totalLendingFiatAmount;
    address public borrower;
    address public localNode;
    address public ethicHubTeam;
    uint256 public borrowerReturnDate;
    uint256 public borrowerReturnEthPerFiatRate;
    uint256 public ethichubFee;
    uint256 public localNodeFee;
    uint256 public tier;
    // interest rate is using base uint 100 and 100% 10000, this means 1% is 100
    // this guarantee we can have a 2 decimal presicion in our calculation
    uint256 public constant interestBaseUint = 100;
    uint256 public constant interestBasePercent = 10000;
    bool public localNodeFeeReclaimed;
    bool public ethicHubTeamFeeReclaimed;
    uint256 public surplusEth;
    uint256 public returnedEth;

    struct Investor {
        uint256 amount;
        bool isCompensated;
        bool surplusEthReclaimed;
    }

    // events
    event onCapReached(uint endTime);
    event onContribution(uint totalContributed, address indexed investor, uint amount, uint investorsCount);
    event onCompensated(address indexed contributor, uint amount);
    event onSurplusSent(uint256 amount);
    event onSurplusReclaimed(address indexed contributor, uint amount);
    event StateChange(uint state);
    event onInitalRateSet(uint rate);
    event onReturnRateSet(uint rate);
    event onReturnAmount(address indexed borrower, uint amount);
    event onBorrowerChanged(address indexed newBorrower);
    event onInvestorChanged(address indexed oldInvestor, address indexed newInvestor);

    // modifiers
    modifier checkProfileRegistered(string profile) {
        bool isRegistered = ethicHubStorage.getBool(keccak256("user", profile, msg.sender));
        require(isRegistered);
        _;
    }

    modifier checkIfArbiter() {
        address arbiter = ethicHubStorage.getAddress(keccak256("arbiter", this));
        require(arbiter == msg.sender);
        _;
    }

    modifier onlyOwnerOrLocalNode() {
        require(localNode == msg.sender || owner == msg.sender);
        _;
    }

    modifier onlyInvestorOrPaymentGateway() {
        bool isInvestor = ethicHubStorage.getBool(keccak256("user", "investor", msg.sender));
        bool isPaymentGateway = ethicHubStorage.getBool(keccak256("user", "paymentGateway", msg.sender));
        require(isPaymentGateway || isInvestor);
        _;
    }

    constructor(
        uint256 _fundingStartTime,
        uint256 _fundingEndTime,
        address _borrower,
        uint256 _annualInterest,
        uint256 _totalLendingAmount,
        uint256 _lendingDays,
        address _storageAddress,
        address _localNode,
        address _ethicHubTeam,
        uint256 _ethichubFee,
        uint256 _localNodeFee
        )
        EthicHubBase(_storageAddress)
        public {
        require(_fundingStartTime > now);
        require(_fundingEndTime > fundingStartTime);
        require(_borrower != address(0));
        require(ethicHubStorage.getBool(keccak256("user", "representative", _borrower)));
        require(_localNode != address(0));
        require(_ethicHubTeam != address(0));
        require(ethicHubStorage.getBool(keccak256("user", "localNode", _localNode)));
        require(_totalLendingAmount > 0);
        require(_lendingDays > 0);
        require(_annualInterest > 0 && _annualInterest < 100);
        version = 4;
        reclaimedContributions = 0;
        reclaimedSurpluses = 0;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        localNode = _localNode;
        ethicHubTeam = _ethicHubTeam;
        borrower = _borrower;
        annualInterest = _annualInterest;
        totalLendingAmount = _totalLendingAmount;
        lendingDays = _lendingDays;
        ethichubFee = _ethichubFee;
        localNodeFee = _localNodeFee;
        state = LendingState.Uninitialized;
    }

    function saveInitialParametersToStorage(uint256 _maxDelayDays, uint256 _tier, uint256 _communityMembers, address _community) external onlyOwnerOrLocalNode {
        require(_maxDelayDays != 0);
        require(state == LendingState.Uninitialized);
        require(_tier > 0);
        require(_communityMembers > 0);
        require(ethicHubStorage.getBool(keccak256("user", "community", _community)));
        ethicHubStorage.setUint(keccak256("lending.maxDelayDays", this), _maxDelayDays);
        ethicHubStorage.setAddress(keccak256("lending.community", this), _community);
        ethicHubStorage.setAddress(keccak256("lending.localNode", this), localNode);
        ethicHubStorage.setUint(keccak256("lending.tier", this), _tier);
        ethicHubStorage.setUint(keccak256("lending.communityMembers", this), _communityMembers);
        tier = _tier;
        state = LendingState.AcceptingContributions;
        emit StateChange(uint(state));

    }

    function setBorrower(address _borrower) external checkIfArbiter {
        require(_borrower != address(0));
        require(ethicHubStorage.getBool(keccak256("user", "representative", _borrower)));
        borrower = _borrower;
        emit onBorrowerChanged(borrower);
    }

    function changeInvestorAddress(address oldInvestor, address newInvestor) external checkIfArbiter {
        require(newInvestor != address(0));
        require(ethicHubStorage.getBool(keccak256("user", "investor", newInvestor)));
        //oldInvestor should have invested in this project
        require(investors[oldInvestor].amount != 0);
        //newInvestor should not have invested anything in this project to not complicate return calculation
        require(investors[newInvestor].amount == 0);
        investors[newInvestor].amount = investors[oldInvestor].amount;
        investors[newInvestor].isCompensated = investors[oldInvestor].isCompensated;
        investors[newInvestor].surplusEthReclaimed = investors[oldInvestor].surplusEthReclaimed;
        delete investors[oldInvestor];
        emit onInvestorChanged(oldInvestor, newInvestor);
    }

    function() public payable whenNotPaused {
        require(state == LendingState.AwaitingReturn || state == LendingState.AcceptingContributions || state == LendingState.ExchangingToFiat);
        if(state == LendingState.AwaitingReturn) {
            returnBorrowedEth();
        } else if (state == LendingState.ExchangingToFiat) {
            // borrower can send surplus eth back to contract to avoid paying interest
            sendBackSurplusEth();
        } else {
            require(ethicHubStorage.getBool(keccak256("user", "investor", msg.sender)));
            contributeWithAddress(msg.sender);
        }
    }

    function sendBackSurplusEth() internal {
        require(state == LendingState.ExchangingToFiat);
        require(msg.sender == borrower);
        surplusEth = surplusEth.add(msg.value);
        require(surplusEth <= totalLendingAmount);
        emit onSurplusSent(msg.value);
    }

    /**
     * After the contribution period ends unsuccesfully, this method enables the contributor
     *  to retrieve their contribution
     */
    function declareProjectNotFunded() external onlyOwnerOrLocalNode {
        require(totalContributed < totalLendingAmount);
        require(state == LendingState.AcceptingContributions);
        require(now > fundingEndTime);
        state = LendingState.ProjectNotFunded;
        emit StateChange(uint(state));
    }

    function declareProjectDefault() external onlyOwnerOrLocalNode {
        require(state == LendingState.AwaitingReturn);
        uint maxDelayDays = getMaxDelayDays();
        require(getDelayDays(now) >= maxDelayDays);
        EthicHubReputationInterface reputation = EthicHubReputationInterface(ethicHubStorage.getAddress(keccak256("contract.name", "reputation")));
        require(reputation != address(0));
        ethicHubStorage.setUint(keccak256("lending.delayDays", this), maxDelayDays);
        reputation.burnReputation(maxDelayDays);
        state = LendingState.Default;
        emit StateChange(uint(state));
    }

    function setBorrowerReturnEthPerFiatRate(uint256 _borrowerReturnEthPerFiatRate) external onlyOwnerOrLocalNode {
        require(state == LendingState.AwaitingReturn);
        borrowerReturnEthPerFiatRate = _borrowerReturnEthPerFiatRate;
        emit onReturnRateSet(borrowerReturnEthPerFiatRate);
    }

    function finishInitialExchangingPeriod(uint256 _initialEthPerFiatRate) external onlyOwnerOrLocalNode {
        require(capReached == true);
        require(state == LendingState.ExchangingToFiat);
        initialEthPerFiatRate = _initialEthPerFiatRate;
        if (surplusEth > 0) {
            totalLendingAmount = totalLendingAmount.sub(surplusEth);
        }
        totalLendingFiatAmount = totalLendingAmount.mul(initialEthPerFiatRate);
        emit onInitalRateSet(initialEthPerFiatRate);
        state = LendingState.AwaitingReturn;
        emit StateChange(uint(state));
    }

    /**
     * Method to reclaim contribution after project is declared default (% of partial funds)
     * @param  beneficiary the contributor
     *
     */
    function reclaimContributionDefault(address beneficiary) external {
        require(state == LendingState.Default);
        require(!investors[beneficiary].isCompensated);
        // contribution = contribution * partial_funds / total_funds
        uint256 contribution = checkInvestorReturns(beneficiary);
        require(contribution > 0);
        investors[beneficiary].isCompensated = true;
        reclaimedContributions = reclaimedContributions.add(1);
        doReclaim(beneficiary, contribution);
    }

    /**
     * Method to reclaim contribution after a project is declared as not funded
     * @param  beneficiary the contributor
     *
     */
    function reclaimContribution(address beneficiary) external {
        require(state == LendingState.ProjectNotFunded);
        require(!investors[beneficiary].isCompensated);
        uint256 contribution = investors[beneficiary].amount;
        require(contribution > 0);
        investors[beneficiary].isCompensated = true;
        reclaimedContributions = reclaimedContributions.add(1);
        doReclaim(beneficiary, contribution);
    }

    function reclaimSurplusEth(address beneficiary) external {
        require(surplusEth > 0);
        // only can be reclaimed after cap reduced
        require(state != LendingState.ExchangingToFiat);
        require(!investors[beneficiary].surplusEthReclaimed);
        uint256 surplusContribution = investors[beneficiary].amount.mul(surplusEth).div(surplusEth.add(totalLendingAmount));
        require(surplusContribution > 0);
        investors[beneficiary].surplusEthReclaimed = true;
        reclaimedSurpluses = reclaimedSurpluses.add(1);
        emit onSurplusReclaimed(beneficiary, surplusContribution);
        doReclaim(beneficiary, surplusContribution);
    }

    function reclaimContributionWithInterest(address beneficiary) external {
        require(state == LendingState.ContributionReturned);
        require(!investors[beneficiary].isCompensated);
        uint256 contribution = checkInvestorReturns(beneficiary);
        require(contribution > 0);
        investors[beneficiary].isCompensated = true;
        reclaimedContributions = reclaimedContributions.add(1);
        doReclaim(beneficiary, contribution);
    }

    function reclaimLocalNodeFee() external {
        require(state == LendingState.ContributionReturned);
        require(localNodeFeeReclaimed == false);
        uint256 fee = totalLendingFiatAmount.mul(localNodeFee).mul(interestBaseUint).div(interestBasePercent).div(borrowerReturnEthPerFiatRate);
        require(fee > 0);
        localNodeFeeReclaimed = true;
        doReclaim(localNode, fee);
    }

    function reclaimEthicHubTeamFee() external {
        require(state == LendingState.ContributionReturned);
        require(ethicHubTeamFeeReclaimed == false);
        uint256 fee = totalLendingFiatAmount.mul(ethichubFee).mul(interestBaseUint).div(interestBasePercent).div(borrowerReturnEthPerFiatRate);
        require(fee > 0);
        ethicHubTeamFeeReclaimed = true;
        doReclaim(ethicHubTeam, fee);
    }

    function reclaimLeftoverEth() external checkIfArbiter {
      require(state == LendingState.ContributionReturned || state == LendingState.Default);
      require(localNodeFeeReclaimed);
      require(ethicHubTeamFeeReclaimed);
      require(investorCount == reclaimedContributions);
      if(surplusEth > 0) {
        require(investorCount == reclaimedSurpluses);
      }
      doReclaim(ethicHubTeam, this.balance);
    }

    function doReclaim(address target, uint256 amount) internal {
      if(this.balance < amount) {
        target.transfer(this.balance);
      } else {
        target.transfer(amount);
      }
    }

    function returnBorrowedEth() internal {
        require(state == LendingState.AwaitingReturn);
        require(msg.sender == borrower);
        require(borrowerReturnEthPerFiatRate > 0);
        bool projectRepayed = false;
        uint excessRepayment = 0;
        uint newReturnedEth = 0;
        emit onReturnAmount(msg.sender, msg.value);
        (newReturnedEth, projectRepayed, excessRepayment) = calculatePaymentGoal(
                                                                                    borrowerReturnAmount(),
                                                                                    returnedEth,
                                                                                    msg.value);
        returnedEth = newReturnedEth;
        if (projectRepayed == true) {
            state = LendingState.ContributionReturned;
            emit StateChange(uint(state));
            updateReputation();
        }
        if (excessRepayment > 0) {
            msg.sender.transfer(excessRepayment);
        }
    }



    // @notice make cotribution throught a paymentGateway
    // @param contributor Address
    function contributeForAddress(address contributor) external checkProfileRegistered(&#39;paymentGateway&#39;) payable whenNotPaused {
        contributeWithAddress(contributor);
    }

    // @notice Function to participate in contribution period
    //  Amounts from the same address should be added up
    //  If cap is reached, end time should be modified
    //  Funds should be transferred into multisig wallet
    // @param contributor Address
    function contributeWithAddress(address contributor) internal whenNotPaused {
        require(state == LendingState.AcceptingContributions);
        //require(msg.value >= minContribAmount);
        require(isContribPeriodRunning());

        uint oldTotalContributed = totalContributed;
        uint newTotalContributed = 0;
        uint excessContribValue = 0;
        (newTotalContributed, capReached, excessContribValue) = calculatePaymentGoal(
                                                                                    totalLendingAmount,
                                                                                    oldTotalContributed,
                                                                                    msg.value);
        totalContributed = newTotalContributed;
        if (capReached) {
            fundingEndTime = now;
            emit onCapReached(fundingEndTime);
        }
        if (investors[contributor].amount == 0) {
            investorCount = investorCount.add(1);
        }
        if (excessContribValue > 0) {
            msg.sender.transfer(excessContribValue);
            investors[contributor].amount = investors[contributor].amount.add(msg.value).sub(excessContribValue);
            emit onContribution(newTotalContributed, contributor, msg.value.sub(excessContribValue), investorCount);
        } else {
            investors[contributor].amount = investors[contributor].amount.add(msg.value);
            emit onContribution(newTotalContributed, contributor, msg.value, investorCount);
        }
    }

    function calculatePaymentGoal(uint goal, uint oldTotal, uint contribValue) internal pure returns(uint, bool, uint) {
        uint newTotal = oldTotal.add(contribValue);
        bool goalReached = false;
        uint excess = 0;
        if (newTotal >= goal && oldTotal < goal) {
            goalReached = true;
            excess = newTotal.sub(goal);
            contribValue = contribValue.sub(excess);
            newTotal = goal;
        }
        return (newTotal, goalReached, excess);
    }

    function sendFundsToBorrower() external onlyOwnerOrLocalNode {
      //Waiting for Exchange
        require(state == LendingState.AcceptingContributions);
        require(capReached);
        state = LendingState.ExchangingToFiat;
        emit StateChange(uint(state));
        borrower.transfer(totalContributed);
    }

    function updateReputation() internal {
        uint delayDays = getDelayDays(now);
        EthicHubReputationInterface reputation = EthicHubReputationInterface(ethicHubStorage.getAddress(keccak256("contract.name", "reputation")));
        require(reputation != address(0));
        if (delayDays > 0) {
            ethicHubStorage.setUint(keccak256("lending.delayDays", this), delayDays);
            reputation.burnReputation(delayDays);
        } else {
            uint completedProjectsByTier  = ethicHubStorage.getUint(keccak256("community.completedProjectsByTier", this, tier)).add(1);
            ethicHubStorage.setUint(keccak256("community.completedProjectsByTier", this, tier), completedProjectsByTier);
            reputation.incrementReputation(completedProjectsByTier);
        }
    }

    function getDelayDays(uint date) public view returns(uint) {
        uint lendingDaysSeconds = lendingDays * 1 days;
        uint defaultTime = fundingEndTime.add(lendingDaysSeconds);
        if (date < defaultTime) {
            return 0;
        } else {
            return date.sub(defaultTime).div(60).div(60).div(24);
        }
    }

    // lendingInterestRate with 2 decimal
    // 15 * (lending days)/ 365 + 4% local node fee + 3% LendingDev fee
    function lendingInterestRatePercentage() public view returns(uint256){
        return annualInterest.mul(interestBaseUint).mul(lendingDays.add(getDelayDays(now))).div(365).add(localNodeFee.mul(interestBaseUint)).add(ethichubFee.mul(interestBaseUint)).add(interestBasePercent);
    }

    // lendingInterestRate with 2 decimal
    function investorInterest() public view returns(uint256){
        return annualInterest.mul(interestBaseUint).mul(lendingDays.add(getDelayDays(now))).div(365).add(interestBasePercent);
    }

    function borrowerReturnFiatAmount() public view returns(uint256) {
        return totalLendingFiatAmount.mul(lendingInterestRatePercentage()).div(interestBasePercent);
    }

    function borrowerReturnAmount() public view returns(uint256) {
        return borrowerReturnFiatAmount().div(borrowerReturnEthPerFiatRate);
    }

    function isContribPeriodRunning() public view returns(bool) {
        return fundingStartTime <= now && fundingEndTime > now && !capReached;
    }

    function checkInvestorContribution(address investor) public view returns(uint256){
        return investors[investor].amount;
    }

    function checkInvestorReturns(address investor) public view returns(uint256) {
        uint256 investorAmount = 0;
        if (state == LendingState.ContributionReturned) {
            investorAmount = investors[investor].amount;
            if (surplusEth > 0){
                investorAmount  = investors[investor].amount.mul(totalLendingAmount).div(totalContributed);
            }
            return investorAmount.mul(initialEthPerFiatRate).mul(investorInterest()).div(borrowerReturnEthPerFiatRate).div(interestBasePercent);
        } else if (state == LendingState.Default){
            investorAmount = investors[investor].amount;
            // contribution = contribution * partial_funds / total_funds
            return investorAmount.mul(returnedEth).div(totalLendingAmount);
        } else {
            return 0;
        }
    }

    function getMaxDelayDays() public view returns(uint256){
        return ethicHubStorage.getUint(keccak256("lending.maxDelayDays", this));
    }

    function getUserContributionReclaimStatus(address userAddress) public view returns(bool isCompensated, bool surplusEthReclaimed){
        isCompensated = investors[userAddress].isCompensated;
        surplusEthReclaimed = investors[userAddress].surplusEthReclaimed;
    }
}