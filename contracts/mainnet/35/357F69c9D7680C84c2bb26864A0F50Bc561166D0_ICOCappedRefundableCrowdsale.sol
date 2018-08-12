pragma solidity ^0.4.24;

contract INotInitedOwnable {
    
    function init() public;
    
    function transferOwnership(address newOwner) public;
}

contract IOwnableUpgradeableImplementation is INotInitedOwnable {
    
    function transferOwnership(address newOwner) public;
    
    function getOwner() constant public returns(address);
    
    function upgradeImplementation(address _newImpl) public;
    
    function getImplementation() constant public returns(address);
}

contract IHookOperator is IOwnableUpgradeableImplementation {

    event LogSetBalancePercentageLimit(uint256 limit);
    event LogSetOverBalanceLimitHolder(address holderAddress, bool isHolder);
    event LogSetUserManager(address userManagerAddress);
    event LogSetICOToken(address icoTokenAddress);

    event LogOnTransfer(address from, address to, uint tokens);
    event LogOnMint(address to, uint256 amount);
    event LogOnBurn(uint amount);
    event LogOnTaxTransfer(address indexed taxableUser, uint tokensAmount);

    event LogSetKYCVerificationContract(address _kycVerificationContractAddress);
    event LogUpdateUserRatio(uint256 generationRatio, address indexed userContractAddress);

    /**
        Setters
    */
    function setBalancePercentageLimit(uint256 limit) public;
    function getBalancePercentageLimit() public view returns(uint256);
    
    function setOverBalanceLimitHolder(address holderAddress, bool isHolder) public;

    function setUserManager(address userManagerAddress) public;
    function getUserManager() public view returns(address userManagerAddress);
   
    function setICOToken(address icoTokenAddress) public;
    function getICOToken() public view returns(address icoTokenAddress);

    /**
        Main Functions
    */
    function onTransfer(address from, address to, uint256 tokensAmount) public;

    function onMint(address to, uint256 tokensAmount) public;

    function onBurn(uint256 amount) public;

    function onTaxTransfer(address taxableUser, uint256 tokensAmount) public;

    /**
        KYC Verification
    */
    function kycVerification(address from, address to, uint256 tokensAmount) public;

    function setKYCVerificationContract(address _kycVerificationContractAddress) public;

    function getKYCVerificationContractAddress() public view returns(address _kycVerificationContractAddress);
    
    /**
        Helper functions
    */
    function updateUserRatio(uint256 generationRatio, address userContractAddress) public;

    function isOverBalanceLimitHolder(address holderAddress) public view returns(bool);

    function isInBalanceLimit(address userAddress, uint256 tokensAmount) public view returns(bool);
}

contract IUserContract {
    event LogNewExchangeUserCreate(uint256 _KYCStatus);
    event LogNewUserCreate(uint256 _KYCStatus);
    
    event LogGenerationRatioUpdate(uint256 _generationRatio);
    event LogKYCStatusUpdate(uint256 _KYCStatus);
    event LogLastTransactionTimeUpdate(uint256 _lastTransactionTime);
    event LogUserPolicyUpdate(bool _termsAndConditions, bool _AML, bool _constitution, bool _CLA);

    event LogAsFounderMark();
    event LogUserBlacklistedStatusSet(bool _blacklistedStatus);
    event LogUserBan();

    event LogDailyTransactionVolumeSendingIncrease(uint256 _currentDay, uint256 _transactionVolume);
    event LogDailyTransactionVolumeReceivingIncrease(uint256 _currentDay, uint256 _transactionVolume);

    event LogWeeklyTransactionVolumeSendingIncrease(uint256 _currentWeek, uint256 _transactionVolume);
    event LogWeeklyTransactionVolumeReceivingIncrease(uint256 _currentWeek, uint256 _transactionVolume);
    
    event LogMonthlyTransactionVolumeSendingIncrease(uint256 _currentMonth, uint256 _transactionVolume);
    event LogMonthlyTransactionVolumeReceivingIncrease(uint256 _currentMonth, uint256 _transactionVolume);

    /**
        Main Functions
    */
    function initExchangeUser(uint256 _KYCStatus) external;

    function initKYCUser(uint256 _KYCStatus) external;

    function initUser(uint256 _KYCStatus) internal;

    function isValidUser() external view returns(bool);

    function getUserData() external view returns
    (
        uint256 _generationRatio, 
        uint256 _KYCStatus, 
        uint256 _lastTransactionTime, 
        bool _isBlacklistedUser,
        bool _termsAndConditionsAcceptance,
        bool _AMLAcceptance,
        bool _constitutionSign,
        bool _commonLicenseAgreementSign,
        bool _isFounder
    ); 

    function isExchangeUser() public view returns(bool);

    function updateUserPolicy(bool _termsAndConditions, bool _AML, bool _constitution, bool _CLA) external;

    function isUserPolicyAccepted() public view returns(bool);

    function updateGenerationRatio(uint256 _generationRatio) external;
    
    function updateKYCStatus(uint256 _newKYCStatus) external;

    function updateLastTransactionTime(uint256 _lastTransactionTime) external;

    /**
        Founder - User
    */
    function markAsFounder() external;

    function isFounderUser() external view returns(bool);

    /**
        Blacklisted - User
    */
    function setUserBlacklistedStatus(bool _shouldBeBlacklisted) external;

    function isUserBlacklisted() external view returns(bool _isBlacklisted);
    /**
        Banned - User
    */
    function banUser() external;

    function isUserBanned() external view returns(bool _isBanned);

    /**
        Daily transaction volume
    */
    function increaseDailyTransactionVolumeSending(uint256 _transactionVolume) external;

    function getDailyTransactionVolumeSending() external view returns(uint256 _dailyTransactionVolume);

    /**
        Daily transaction volume - Receiving
    */
    function increaseDailyTransactionVolumeReceiving(uint256 _transactionVolume) external;

    function getDailyTransactionVolumeReceiving() external view returns(uint256 _dailyTransactionVolume);

    /**
        Weekly transaction volume
    */
    function increaseWeeklyTransactionVolumeSending(uint256 _transactionVolume) external;

    function getWeeklyTransactionVolumeSending() external view returns(uint256 _weeklyTransactionVolume);

    /**
        Weekly transaction volume - Receiving
    */
    function increaseWeeklyTransactionVolumeReceiving(uint256 _transactionVolume) external;

    function getWeeklyTransactionVolumeReceiving() external view returns(uint256 _weeklyTransactionVolume);

    /**
        Monthly transaction volume
    */
    function increaseMonthlyTransactionVolumeSending(uint256 _transactionVolume) external;

    function getMonthlyTransactionVolumeSending() external view returns(uint256 _monthlyTransactionVolume);

    /**
        Monthly transaction volume - Receiving
    */
    function increaseMonthlyTransactionVolumeReceiving(uint256 _transactionVolume) external;

    function getMonthlyTransactionVolumeReceiving() external view returns(uint256 _monthlyTransactionVolume);
}

contract IUserManager is IOwnableUpgradeableImplementation {
    event LogSetDataContract(address _dataContractAddress);
    event LogSetTaxPercentage(uint256 _taxPercentage);
    event LogSetTaxationPeriod(uint256 _taxationPeriod);

    event LogSetUserFactoryContract(address _userFactoryContract);
    event LogSetHookOperatorContract(address _HookOperatorContract);

    event LogUpdateGenerationRatio(uint256 _generationRatio, address userContractAddress);
    event LogUpdateLastTransactionTime(address _userAddress);

    event LogUserAsFounderMark(address userAddress);

    /**
        Data Contract
    */
    function setDataContract(address _dataContractAddress) public;

    function getDataContractAddress() public view returns(address _dataContractAddress);

    function setTaxPercentage(uint256 _taxPercentage) public;

    function setTaxationPeriod(uint256 _taxationPeriod) public;

    /**
        User Factory
    */
    function setUserFactoryContract(address _userFactoryContract) public;

    function getUserFactoryContractAddress() public view returns(address _userFactoryContractAddress);
    /**
        Hook Operator
    */
    function setHookOperatorContract(address _HookOperatorContract) public;

    function getHookOperatorContractAddress() public view returns(address _HookOperatorContractAddress);
    
    /**
        Users Functions
    */

    function isUserKYCVerified(address _userAddress) public view returns(uint256 KYCStatus);

    function isBlacklisted(address _userAddress) public view returns(bool _isBlacklisted);

    function isBannedUser(address userAddress) public view returns(bool _isBannedUser);

    function updateGenerationRatio(uint256 _generationRatio, address userContractAddress) public;

    function updateLastTransactionTime(address _userAddress) public;

    function getUserContractAddress(address _userAddress) public view returns(IUserContract _userContract);

    function isValidUser(address userAddress) public view returns(bool);

    function setCrowdsaleContract(address crowdsaleInstance) external;

    function getCrowdsaleContract() external view returns(address);

    function markUserAsFounder(address userAddress) external;
}

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

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

contract RefundVault is Ownable {
    using SafeMath for uint256;

    /* 
        To cover the costs for paying investor related functions by ourself as: 
            "add investor in the whitelist" and etc.

        We are getting 3% of the investor&#39;s deposit only if the soft cap
        is not reached and the investor refund his contribution
    */
    uint256 public constant DEDUCTION = 3;
    uint256 public totalDeductedValue;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    constructor(address _wallet) public {
        require(_wallet != address(0));
        
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner external payable {
        require(state == State.Active);

        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner external {
        require(state == State.Active);
        
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
    }

    function enableRefunds() external onlyOwner {
        require(state == State.Active);

        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) external {
        require(state == State.Refunding);

        uint256 depositedValue = deposited[investor];
        uint256 deductedValue = depositedValue.mul(DEDUCTION).div(100);
        
        deposited[investor] = 0;

        wallet.transfer(deductedValue);
        investor.transfer(depositedValue.sub(deductedValue));
        
        totalDeductedValue = totalDeductedValue.add(deductedValue);

        emit Refunded(investor, depositedValue);
    }
}

contract WhitelistedCrowdsale is Ownable {

    /*
        We need a count limit for the users array, 
        which is passed to setMultiple functions

        Without the limit, the set could be so big that the transaction required gas is over the block maximum gas
        The count is calculated on:
            How much gas it costs to process one user
            The maximum gas is 5 000 000
    */
    uint public constant MAX_INPUT_USERS_COUNT = 200;

    mapping(address => uint) public preSalesSpecialUsers;

    mapping(address => bool) public publicSalesSpecialUsers;

    address public lister;

    event LogPresalesSpecialUserSet(address userAddress, uint userRate);
    event LogMultiplePresalesSpecialUsersSet(address[] userAddresses, uint userRate);
    event LogPublicsalesSpecialUserAdd(address addedUser);
    event LogMultiplePublicsalesSpecialUsersSet(address[] userAddresses);
    event LogPublicsalesSpecialUserRemove(address removedUser);
    event LogListerSet(address listerAddress);

    modifier onlyLister() {
        require(msg.sender == lister);
        
        _;
    }

    modifier notZeroAddress(address addressForValidation) {
        require(addressForValidation != address(0));

        _;
    }

    function setPreSalesSpecialUser(address user, uint userRate) external onlyLister notZeroAddress(user) {
        preSalesSpecialUsers[user] = userRate;

        emit LogPresalesSpecialUserSet(user, userRate);
    }

    function setMultiplePreSalesSpecialUsers(address[] users, uint userRate) external onlyLister {
        require(users.length <= MAX_INPUT_USERS_COUNT);

        for(uint i = 0; i < users.length; i++) { 
            preSalesSpecialUsers[users[i]] = userRate;
        }

        emit LogMultiplePresalesSpecialUsersSet(users, userRate);
    }

    function addPublicSalesSpecialUser(address user) external onlyLister notZeroAddress(user) {
        publicSalesSpecialUsers[user] = true;

        emit LogPublicsalesSpecialUserAdd(user);
    }

    function addMultiplePublicSalesSpecialUser(address[] users) external onlyLister {
        require(users.length <= MAX_INPUT_USERS_COUNT);

        for(uint i = 0; i < users.length; i++) { 
            publicSalesSpecialUsers[users[i]] = true;
        }

        emit LogMultiplePublicsalesSpecialUsersSet(users);
    }

    function removePublicSalesSpecialUser(address user) external onlyLister notZeroAddress(user) {
        publicSalesSpecialUsers[user] = false;

        emit LogPublicsalesSpecialUserRemove(user);
    }

    function setLister(address newLister) external onlyOwner notZeroAddress(newLister) {
        lister = newLister;

        emit LogListerSet(newLister);
    }
}

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }
}

contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    uint256 public goal;

    RefundVault public vault;

    constructor(uint256 _goal) public {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    function claimRefund() external {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    function finalization() internal {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        super.finalization();
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }
}

contract ICOCrowdsale is Ownable, FinalizableCrowdsale, WhitelistedCrowdsale {
    using SafeMath for uint256;

    IUserManager public userManagerContract;

    uint256 public preSalesEndDate;
    uint256 public totalMintedBountyTokens;
    bool public isPresalesNotEndedInAdvance = true;

    uint256 public constant MIN_CONTRIBUTION_AMOUNT = 50 finney; // 0.05 ETH
    uint256 public constant MAX_BOUNTYTOKENS_AMOUNT = 100000 * (10**18); // 100 000 tokens
    uint256 public constant MAX_FUNDS_RAISED_DURING_PRESALE = 20000 ether;
    
    /*
        The limit below allows a user to have maximum tokens balance of 2%(400 000 tokens) of the hard cap(167 000 ethers)
        It only applies through crowdsale period
    */
    uint256 public constant MAX_USER_TOKENS_BALANCE = 400000 * (10**18); // 400 000 tokens

    // 0.01 eth = 1 token
    uint256 public constant REGULAR_RATE = 100;
    uint256 public constant PUBLIC_SALES_SPECIAL_USERS_RATE = 120; // 20% bonus

    uint256 public constant DEFAULT_PRESALES_DURATION = 7 weeks;
    uint256 public constant MAX_PRESALES_EXTENSION= 12 weeks;

    /*
        The public sales periods ends:
            PUBLIC_SALES_1_PERIOD_END = 1 weeks / Public sales 1 period starts from private sales period and expires one week after the private sales end
            PUBLIC_SALES_2_PERIOD_END = 2 weeks / Public sales 2 period starts from public sales 1 period and expires on the 2-nd week after the private sales end
            PUBLIC_SALES_3_PERIOD_END = 3 weeks / Public sales 3 period starts from public sales 2 period and expires on the 3-th week after the private sales end
    */
    uint256 public constant PUBLIC_SALES_1_PERIOD_END = 1 weeks;
    uint256 public constant PUBLIC_SALES_2_PERIOD_END = 2 weeks;
    uint256 public constant PUBLIC_SALES_3_PERIOD_END = 3 weeks;

    uint256 public constant PUBLIC_SALES_1_RATE = 115; // 15% bonus
    uint256 public constant PUBLIC_SALES_2_RATE = 110; // 10% bonus
    uint256 public constant PUBLIC_SALES_3_RATE = 105; // 5% bonus

    event LogBountyTokenMinted(address minter, address beneficiary, uint256 amount);
    event LogPrivatesaleExtend(uint extensionTime);

    constructor(uint256 startTime, uint256 endTime, address wallet, address hookOperatorAddress) public
        FinalizableCrowdsale()
        Crowdsale(startTime, endTime, REGULAR_RATE, wallet)
    {
        // Set default presales end date
        preSalesEndDate = startTime.add(DEFAULT_PRESALES_DURATION);
        

        ICOTokenExtended icoToken = ICOTokenExtended(token);
        icoToken.setHookOperator(hookOperatorAddress);
    }

    function createTokenContract() internal returns (MintableToken) {

        ICOTokenExtended icoToken = new ICOTokenExtended();

        icoToken.pause();

        return icoToken;
    }

    function finalization() internal {
        super.finalization();

        ICOTokenExtended icoToken = ICOTokenExtended(token);

        icoToken.transferOwnership(owner);
    }

    // The extensionTime is in seconds
    function extendPreSalesPeriodWith(uint extensionTime) public onlyOwner {
        require(extensionTime <= MAX_PRESALES_EXTENSION);
        
        preSalesEndDate = preSalesEndDate.add(extensionTime);
        endTime = endTime.add(extensionTime);

        emit LogPrivatesaleExtend(extensionTime);
    }

    function buyTokens(address beneficiary) public payable {
        require(msg.value >= MIN_CONTRIBUTION_AMOUNT);
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount, beneficiary);

        // Check for maximum user&#39;s tokens amount overflow
        uint256 beneficiaryBalance = token.balanceOf(beneficiary);
        require(beneficiaryBalance.add(tokens) <= MAX_USER_TOKENS_BALANCE);

        // // update state
        weiRaised = weiRaised.add(weiAmount);

        if(weiRaised >= MAX_FUNDS_RAISED_DURING_PRESALE && isPresalesNotEndedInAdvance){
            preSalesEndDate = now;
            isPresalesNotEndedInAdvance = false;
        }

        token.mint(beneficiary, tokens);

        userManagerContract.markUserAsFounder(beneficiary);

        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function getTokenAmount(uint256 weiAmount, address beneficiaryAddress) internal view returns(uint256 tokenAmount) {
        uint256 crowdsaleRate = getRate(beneficiaryAddress);

        return weiAmount.mul(crowdsaleRate);
    }

    function getRate(address beneficiary) internal view returns(uint256) {

        if(now <= preSalesEndDate && weiRaised < MAX_FUNDS_RAISED_DURING_PRESALE){
            if(preSalesSpecialUsers[beneficiary] > 0){
                return preSalesSpecialUsers[beneficiary];
            }

            return REGULAR_RATE;
        }

        if(publicSalesSpecialUsers[beneficiary]){
            return PUBLIC_SALES_SPECIAL_USERS_RATE;
        }

        if(now <= preSalesEndDate.add(PUBLIC_SALES_1_PERIOD_END)) {
            return PUBLIC_SALES_1_RATE;
        }

        if(now <= preSalesEndDate.add(PUBLIC_SALES_2_PERIOD_END)) {
            return PUBLIC_SALES_2_RATE;
        }

        if(now <= preSalesEndDate.add(PUBLIC_SALES_3_PERIOD_END)) {
            return PUBLIC_SALES_3_RATE;
        }

        return REGULAR_RATE;
    }

    function createBountyToken(address beneficiary, uint256 amount) public onlyOwner returns(bool) {
        require(!hasEnded());
        require(totalMintedBountyTokens.add(amount) <= MAX_BOUNTYTOKENS_AMOUNT);

        totalMintedBountyTokens = totalMintedBountyTokens.add(amount);
        token.mint(beneficiary, amount);
        emit LogBountyTokenMinted(msg.sender, beneficiary, amount);

        return true;
    }

    function setUserManagerContract(address userManagerInstance) public onlyOwner {
        require(userManagerInstance != address(0));

        userManagerContract = IUserManager(userManagerInstance);
    }
}

contract ICOCappedRefundableCrowdsale is CappedCrowdsale, ICOCrowdsale, RefundableCrowdsale {

    constructor(uint256 startTime, uint256 endTime, uint256 hardCap, uint256 softCap, address wallet, address HookOperatorContractAddress) public
        FinalizableCrowdsale()
        ICOCrowdsale(startTime, endTime, wallet, HookOperatorContractAddress)
        CappedCrowdsale(hardCap)
        RefundableCrowdsale(softCap)
    {
        require(softCap <= hardCap);
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

contract ExchangeOracle is Ownable, Pausable {

    using SafeMath for uint;

    bool public isIrisOracle = true;

    uint public rate = 0;
    uint public minWeiAmount = 1000; 

    event LogRateChanged(uint oldRate, uint newRate, address changer);
    event LogMinWeiAmountChanged(uint oldMinWeiAmount, uint newMinWeiAmount, address changer);

    constructor(uint initialRate) public {
        require(initialRate > 0);
        rate = initialRate;
    }

    function rate() external view whenNotPaused returns(uint) {
        return rate;
    }

    /*
        The new rate has to be passed in format:
            100 rate = 100 000 passed rate ( 1 ether = 100 tokens )
            1 rate = 1 000 passed rate ( 1 ether = 1 token )
            0.01 rate = 10 passed rate ( 100 ethers = 1 token )
    **/
    function setRate(uint newRate) external onlyOwner whenNotPaused returns(bool) {
        require(newRate > 0);
        
        uint oldRate = rate;
        rate = newRate;

        emit LogRateChanged(oldRate, newRate, msg.sender);

        return true;
    }

    /*
        By default minWeiAmount = 1000
        With min wei amount we can set the rate to be a float number

        We use it as a multiplier because we can not pass float numbers in ethereum
        If the token price becomes bigger than ether one, for example -> 1 token = 10 ethers
        We will pass 100 as rate and this will be relevant to 0.1 token = 1 ether
    **/
    function setMinWeiAmount(uint newMinWeiAmount) external onlyOwner whenNotPaused returns(bool) {
        require(newMinWeiAmount > 0);
        require(newMinWeiAmount % 10 == 0); 

        uint oldMinWeiAmount = minWeiAmount;
        minWeiAmount = newMinWeiAmount;

        emit LogMinWeiAmountChanged(oldMinWeiAmount, minWeiAmount, msg.sender);

        return true;
    }

    function convertTokensAmountInWeiAtRate(uint tokensAmount, uint convertRate) external whenNotPaused view returns(uint) {

        uint weiAmount = tokensAmount.mul(minWeiAmount);
        weiAmount = weiAmount.div(convertRate);

        if ((tokensAmount % convertRate) != 0) {
            weiAmount++;
        } 

        return weiAmount;
    }

    function calcWeiForTokensAmount(uint tokensAmount) external view whenNotPaused returns(uint) {
        
        uint weiAmount = tokensAmount.mul(minWeiAmount);
        weiAmount = weiAmount.div(rate);

        if ((tokensAmount % rate) != 0) {
            weiAmount++;
        } 

        return weiAmount;
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract ICOToken is BurnableToken, MintableToken, PausableToken {

    string public constant name = "AIUR Token";
    string public constant symbol = "AIUR";
    uint8 public constant decimals = 18;
}

contract ICOTokenExtended is ICOToken {

    address public refunder;

    IHookOperator public hookOperator;
    ExchangeOracle public aiurExchangeOracle;

    mapping(address => bool) public minters;

    uint256 public constant MIN_REFUND_RATE_DELIMITER = 2; // Refund rate has to be minimum 50% of the AIUR ExchangeOracle rate

    event LogRefunderSet(address refunderAddress);
    event LogTransferOverFunds(address from, address to, uint ethersAmount, uint tokensAmount);
    event LogTaxTransfer(address from, address to, uint amount);
    event LogMinterAdd(address addedMinter);
    event LogMinterRemove(address removedMinter);

    modifier onlyMinter(){
        require(minters[msg.sender]);
        
        _;
    }

    modifier onlyCurrentHookOperator() {
        require(msg.sender == address(hookOperator));

        _;
    }

    modifier nonZeroAddress(address inputAddress) {
        require(inputAddress != address(0));

        _;
    }

    modifier onlyRefunder() {
        require(msg.sender == refunder);

        _;
    }

    constructor() public {
        minters[msg.sender] = true;
    }

    function setRefunder(address refunderAddress) external onlyOwner nonZeroAddress(refunderAddress) {
        refunder = refunderAddress;

        emit LogRefunderSet(refunderAddress);
    }

    // Set the exchange oracle after crowdsale 
    function setExchangeOracle(address exchangeOracleAddress) external onlyOwner nonZeroAddress(exchangeOracleAddress) {
        aiurExchangeOracle = ExchangeOracle(exchangeOracleAddress);
    }

    function setHookOperator(address hookOperatorAddress) external onlyOwner nonZeroAddress(hookOperatorAddress) {
        hookOperator = IHookOperator(hookOperatorAddress);
    }

    function addMinter(address minterAddress) external onlyOwner nonZeroAddress(minterAddress) {
        minters[minterAddress] = true;    

        emit LogMinterAdd(minterAddress);
    }

    function removeMinter(address minterAddress) external onlyOwner nonZeroAddress(minterAddress) {
        minters[minterAddress] = false;    

        emit LogMinterRemove(minterAddress);
    }

    function mint(address to, uint256 tokensAmount) public onlyMinter canMint nonZeroAddress(to) returns(bool) {
        hookOperator.onMint(to, tokensAmount);

        totalSupply = totalSupply.add(tokensAmount);
        balances[to] = balances[to].add(tokensAmount);

        emit Mint(to, tokensAmount);
        emit Transfer(address(0), to, tokensAmount);
        return true;
    } 

    function burn(uint tokensAmount) public {
        hookOperator.onBurn(tokensAmount);       

        super.burn(tokensAmount);  
    } 

    function transfer(address to, uint tokensAmount) public nonZeroAddress(to) returns(bool) {
        hookOperator.onTransfer(msg.sender, to, tokensAmount);

        return super.transfer(to, tokensAmount);
    }
    
    function transferFrom(address from, address to, uint tokensAmount) public nonZeroAddress(from) nonZeroAddress(to) returns(bool) {
        hookOperator.onTransfer(from, to, tokensAmount);
        
        return super.transferFrom(from, to, tokensAmount);
    }

    /*
        This function is used for taxation purposes and will be used after pre-defined requirement are met
    */
    function taxTransfer(address from, address to, uint tokensAmount) external onlyCurrentHookOperator nonZeroAddress(from) nonZeroAddress(to) returns(bool) {  
        require(balances[from] >= tokensAmount);

        transferDirectly(from, to, tokensAmount);

        hookOperator.onTaxTransfer(from, tokensAmount);
        emit LogTaxTransfer(from, to, tokensAmount);

        return true;
    }

    function transferOverBalanceFunds(address from, address to, uint rate) external payable onlyRefunder nonZeroAddress(from) nonZeroAddress(to) returns(bool) {
        require(!hookOperator.isOverBalanceLimitHolder(from));

        uint256 oracleRate = aiurExchangeOracle.rate();
        require(rate <= oracleRate.add(oracleRate.div(MIN_REFUND_RATE_DELIMITER)));

        uint256 fromBalance = balanceOf(from);
        
        // Calculate percentage limit in tokens
        uint256 maxTokensBalance = totalSupply.mul(hookOperator.getBalancePercentageLimit()).div(100);

        require(fromBalance > maxTokensBalance);

        uint256 tokensToTake = fromBalance.sub(maxTokensBalance);
        uint256 weiToRefund = aiurExchangeOracle.convertTokensAmountInWeiAtRate(tokensToTake, rate);

        require(hookOperator.isInBalanceLimit(to, tokensToTake));
        require(msg.value == weiToRefund);

        transferDirectly(from, to, tokensToTake);
        from.transfer(msg.value);

        emit LogTransferOverFunds(from, to, weiToRefund, tokensToTake);

        return true;
    }

    function transferDirectly(address from, address to, uint tokensAmount) private {
        balances[from] = balances[from].sub(tokensAmount);
        balances[to] = balances[to].add(tokensAmount);
    }
}