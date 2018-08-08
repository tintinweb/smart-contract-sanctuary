pragma solidity ^0.4.18;

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

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

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

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
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
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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

contract AMOCoin is StandardToken, BurnableToken, Ownable {
    using SafeMath for uint256;

    string public constant symbol = "AMO";
    string public constant name = "AMO Coin";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 20000000000 * (10 ** uint256(decimals));
    uint256 public constant TOKEN_SALE_ALLOWANCE = 10000000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE = INITIAL_SUPPLY - TOKEN_SALE_ALLOWANCE;

    // Address of token administrator
    address public adminAddr;

    // Address of token sale contract
    address public tokenSaleAddr;

    // Enable transfer after token sale is completed
    bool public transferEnabled = false;

    // Accounts to be locked for certain period
    mapping(address => uint256) private lockedAccounts;

    /*
     *
     * Permissions when transferEnabled is false :
     *              ContractOwner    Admin    SaleContract    Others
     * transfer            x           v            v           x
     * transferFrom        x           v            v           x
     *
     * Permissions when transferEnabled is true :
     *              ContractOwner    Admin    SaleContract    Others
     * transfer            v           v            v           v
     * transferFrom        v           v            v           v
     *
     */

    /*
     * Check if token transfer is allowed
     * Permission table above is result of this modifier
     */
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled == true
            || msg.sender == adminAddr
            || msg.sender == tokenSaleAddr);
        _;
    }

    /*
     * Check if token sale address is not set
     */
    modifier onlyWhenTokenSaleAddrNotSet() {
        require(tokenSaleAddr == address(0x0));
        _;
    }

    /*
     * Check if token transfer destination is valid
     */
    modifier onlyValidDestination(address to) {
        require(to != address(0x0)
            && to != address(this)
            && to != owner
            && to != adminAddr
            && to != tokenSaleAddr);
        _;
    }

    modifier onlyAllowedAmount(address from, uint256 amount) {
        require(balances[from].sub(amount) >= lockedAccounts[from]);
        _;
    }
    /*
     * The constructor of AMOCoin contract
     *
     * @param _adminAddr: Address of token administrator
     */
    function AMOCoin(address _adminAddr) public {
        totalSupply_ = INITIAL_SUPPLY;

        balances[msg.sender] = totalSupply_;
        Transfer(address(0x0), msg.sender, totalSupply_);

        adminAddr = _adminAddr;
        approve(adminAddr, ADMIN_ALLOWANCE);
    }

    /*
     * Set amount of token sale to approve allowance for sale contract
     *
     * @param _tokenSaleAddr: Address of sale contract
     * @param _amountForSale: Amount of token for sale
     */
    function setTokenSaleAmount(address _tokenSaleAddr, uint256 amountForSale)
        external
        onlyOwner
        onlyWhenTokenSaleAddrNotSet
    {
        require(!transferEnabled);

        uint256 amount = (amountForSale == 0) ? TOKEN_SALE_ALLOWANCE : amountForSale;
        require(amount <= TOKEN_SALE_ALLOWANCE);

        approve(_tokenSaleAddr, amount);
        tokenSaleAddr = _tokenSaleAddr;
    }

    /*
     * Set transferEnabled variable to true
     */
    function enableTransfer() external onlyOwner {
        transferEnabled = true;
        approve(tokenSaleAddr, 0);
    }

    /*
     * Set transferEnabled variable to false
     */
    function disableTransfer() external onlyOwner {
        transferEnabled = false;
    }

    /*
     * Transfer token from message sender to another
     *
     * @param to: Destination address
     * @param value: Amount of AMO token to transfer
     */
    function transfer(address to, uint256 value)
        public
        onlyWhenTransferAllowed
        onlyValidDestination(to)
        onlyAllowedAmount(msg.sender, value)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    /*
     * Transfer token from &#39;from&#39; address to &#39;to&#39; addreess
     *
     * @param from: Origin address
     * @param to: Destination address
     * @param value: Amount of AMO Coin to transfer
     */
    function transferFrom(address from, address to, uint256 value)
        public
        onlyWhenTransferAllowed
        onlyValidDestination(to)
        onlyAllowedAmount(from, value)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    /*
     * Burn token, only owner is allowed
     *
     * @param value: Amount of AMO Coin to burn
     */
    function burn(uint256 value) public onlyOwner {
        require(transferEnabled);
        super.burn(value);
    }

    /*
     * Disable transfering tokens more than allowed amount from certain account
     *
     * @param addr: Account to set allowed amount
     * @param amount: Amount of tokens to allow
     */
    function lockAccount(address addr, uint256 amount)
        external
        onlyOwner
        onlyValidDestination(addr)
    {
        require(amount > 0);
        lockedAccounts[addr] = amount;
    }

    /*
     * Enable transfering tokens of locked account
     *
     * @param addr: Account to unlock
     */

    function unlockAccount(address addr)
        external
        onlyOwner
        onlyValidDestination(addr)
    {
        lockedAccounts[addr] = 0;
    }
}


contract AMOCoinSale is Pausable {
    using SafeMath for uint256;

    // Start time of sale
    uint256 public startTime;
    // End time of sale
    uint256 public endTime;
    // Address to collect fund
    address private fundAddr;
    // Token contract instance
    AMOCoin public token;
    // Amount of raised in Wei (1 ether)
    uint256 public totalWeiRaised;
    // Base hard cap for each round in ether
    uint256 public constant BASE_HARD_CAP_PER_ROUND = 12000 * 1 ether;

    uint256 public constant UINT256_MAX = ~uint256(0);
    // Base AMO to Ether rate
    uint256 public constant BASE_AMO_TO_ETH_RATE = 200000;
    // Base minimum contribution
    uint256 public constant BASE_MIN_CONTRIBUTION = 0.1 * 1 ether;
    // Whitelisted addresses
    mapping(address => bool) public whitelist;
    // Whitelisted users&#39; contributions per round
    mapping(address => mapping(uint8 => uint256)) public contPerRound;

    // For each round, there are three stages.
    enum Stages {
        SetUp,
        Started,
        Ended
    }
    // The current stage of the sale
    Stages public stage;

    // There are three rounds in sale
    enum SaleRounds {
        EarlyInvestment,
        PreSale,
        CrowdSale
    }
    // The current round of the sale
    SaleRounds public round;

    // Each round has different information
    struct RoundInfo {
        uint256 minContribution;
        uint256 maxContribution;
        uint256 hardCap;
        uint256 rate;
        uint256 weiRaised;
    }

    // SaleRounds(key) : RoundInfo(value) map
    // Since solidity does not support enum as key of map, converted enum to uint8
    mapping(uint8 => RoundInfo) public roundInfos;

    struct AllocationInfo {
        bool isAllowed;
        uint256 allowedAmount;
    }

    // List of users who will be allocated tokens and their allowed amount
    mapping(address => AllocationInfo) private allocationList;

    /*
     * Event for sale start logging
     *
     * @param startTime: Start date of sale
     * @param endTime: End date of sale
     * @param round: Round of sale started
     */
    event SaleStarted(uint256 startTime, uint256 endTime, SaleRounds round);

    /*
     * Event for sale end logging
     *
     * @param endTime: End date of sale
     * @param totalWeiRaised: Total amount of raised in Wei after sale ended
     * @param round: Round of sale ended
     */
    event SaleEnded(uint256 endTime, uint256 totalWeiRaised, SaleRounds round);

    /*
     * Event for token purchase
     *
     * @param purchaser: Who paid for the tokens
     * @param value: Amount in Wei paid for purchase
     * @param amount: Amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    /*
     * Modifier to check current stage is same as expected stage
     *
     * @param expectedStage: Expected current stage
     */
    modifier atStage(Stages expectedStage) {
        require(stage == expectedStage);
        _;
    }

    /*
     * Modifier to check current round is sane as expected round
     *
     * @param expectedRound: Expected current round
     */
    modifier atRound(SaleRounds expectedRound) {
        require(round == expectedRound);
        _;
    }

    /*
     * Modifier to check purchase is valid
     *
     * 1. Current round must be smaller than CrowdSale
     * 2. Current time must be within sale period
     * 3. Purchaser must be enrolled to whitelist
     * 4. Purchaser address must be correct
     * 5. Contribution must be bigger than minimum contribution for current round
     * 6. Sum of contributions must be smaller than max contribution for current round
     * 7. Total funds raised in current round must be smaller than hard cap for current round
     */
    modifier onlyValidPurchase() {
        require(round <= SaleRounds.CrowdSale);
        require(now >= startTime && now <= endTime);

        uint256 contributionInWei = msg.value;
        address purchaser = msg.sender;

        require(whitelist[purchaser]);
        require(purchaser != address(0));
        require(contributionInWei >= roundInfos[uint8(round)].minContribution);
        require(
            contPerRound[purchaser][uint8(round)].add(contributionInWei)
            <= roundInfos[uint8(round)].maxContribution
        );
        require(
            roundInfos[uint8(round)].weiRaised.add(contributionInWei)
            <= roundInfos[uint8(round)].hardCap
        );
        _;
    }

    /*
     * Constructor for AMOCoinSale contract
     *
     * @param AMOToEtherRate: Number of AMO tokens per Ether
     * @param fundAddress: Address where funds are collected
     * @param tokenAddress: Address of AMO Token Contract
     */
    function AMOCoinSale(
        address fundAddress,
        address tokenAddress
    )
        public
    {
        require(fundAddress != address(0));
        require(tokenAddress != address(0));

        token = AMOCoin(tokenAddress);
        fundAddr = fundAddress;
        stage = Stages.Ended;
        round = SaleRounds.EarlyInvestment;
        uint8 roundIndex = uint8(round);

        roundInfos[roundIndex].minContribution = BASE_MIN_CONTRIBUTION;
        roundInfos[roundIndex].maxContribution = UINT256_MAX;
        roundInfos[roundIndex].hardCap = BASE_HARD_CAP_PER_ROUND;
        roundInfos[roundIndex].weiRaised = 0;
        roundInfos[roundIndex].rate = BASE_AMO_TO_ETH_RATE;
    }

    /*
     * Fallback function to buy AMO tokens
     */
    function () public payable {
        buy();
    }

    /*
     * Withdraw ethers to fund address
     */
    function withdraw() external onlyOwner {
        fundAddr.transfer(this.balance);
    }

    /*
     * Add users to whitelist
     * Whitelisted users are accumulated on each round
     *
     * @param users: Addresses of users who passed KYC
     */
    function addManyToWhitelist(address[] users) external onlyOwner {
        for (uint32 i = 0; i < users.length; i++) {
            addToWhitelist(users[i]);
        }
    }

    /*
     * Add one user to whitelist
     *
     * @param user: Address of user who passed KYC
     */
    function addToWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
    }

    /*
     * Remove users from whitelist
     *
     * @param users: Addresses of users who should not belong to whitelist
     */
    function removeManyFromWhitelist(address[] users) external onlyOwner {
        for (uint32 i = 0; i < users.length; i++) {
            removeFromWhitelist(users[i]);
        }
    }

    /*
     * Remove users from whitelist
     *
     * @param users: Addresses of users who should not belong to whitelist
     */
    function removeFromWhitelist(address user) public onlyOwner {
        whitelist[user] = false;
    }

    /*
     * Set minimum contribution for round
     * User have to send more ether than minimum contribution
     *
     * @param _round: Round to set
     * @param _minContribution: Minimum contribution in wei
     */
    function setMinContributionForRound(
        SaleRounds _round,
        uint256 _minContribution
    )
        public
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(round <= _round);
        roundInfos[uint8(_round)].minContribution =
            (_minContribution == 0) ? BASE_MIN_CONTRIBUTION : _minContribution;
    }

    /*
     * Set max contribution for round
     * User can&#39;t send more ether than the max contributions in round
     *
     * @param _round: Round to set
     * @param _maxContribution: Max contribution in wei
     */
    function setMaxContributionForRound(
        SaleRounds _round,
        uint256 _maxContribution
    )
        public
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(round <= _round);
        roundInfos[uint8(_round)].maxContribution =
            (_maxContribution == 0) ? UINT256_MAX : _maxContribution;
    }

    /*
     * Set hard cap for round
     * Total wei raised in round should be smaller than hard cap
     *
     * @param _round: Round to set
     * @param _hardCap: Hard cap in wei
     */
    function setHardCapForRound(
        SaleRounds _round,
        uint256 _hardCap
    )
        public
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(round <= _round);
        roundInfos[uint8(_round)].hardCap =
            (_hardCap == 0) ? BASE_HARD_CAP_PER_ROUND : _hardCap;
    }

    /*
     * Set AMO to Ether rate for round
     *
     * @param _round: Round to set
     * @param _rate: AMO to Ether _rate
     */
    function setRateForRound(
        SaleRounds _round,
        uint256 _rate
    )
        public
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(round <= _round);
        roundInfos[uint8(_round)].rate =
            (_rate == 0) ? BASE_AMO_TO_ETH_RATE : _rate;
    }

    /*
     * Set up several information for next round
     * Only owner can call this method
     */
    function setUpSale(
        SaleRounds _round,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _hardCap,
        uint256 _rate
    )
        external
        onlyOwner
        atStage(Stages.Ended)
    {
        require(round <= _round);
        stage = Stages.SetUp;
        round = _round;
        setMinContributionForRound(_round, _minContribution);
        setMaxContributionForRound(_round, _maxContribution);
        setHardCapForRound(_round, _hardCap);
        setRateForRound(_round, _rate);
    }

    /*
     * Start sale in current round
     */
    function startSale(uint256 durationInSeconds)
        external
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(roundInfos[uint8(round)].minContribution > 0
            && roundInfos[uint8(round)].hardCap > 0);
        stage = Stages.Started;
        startTime = now;
        endTime = startTime.add(durationInSeconds);
        SaleStarted(startTime, endTime, round);
    }

    /*
     * End sale in crrent round
     */
    function endSale() external onlyOwner atStage(Stages.Started) {
        endTime = now;
        stage = Stages.Ended;

        SaleEnded(endTime, totalWeiRaised, round);
    }

    function buy()
        public
        payable
        whenNotPaused
        atStage(Stages.Started)
        onlyValidPurchase()
        returns (bool)
    {
        address purchaser = msg.sender;
        uint256 contributionInWei = msg.value;
        uint256 tokenAmount = contributionInWei.mul(roundInfos[uint8(round)].rate);

        if (!token.transferFrom(token.owner(), purchaser, tokenAmount)) {
            revert();
        }

        totalWeiRaised = totalWeiRaised.add(contributionInWei);
        roundInfos[uint8(round)].weiRaised =
            roundInfos[uint8(round)].weiRaised.add(contributionInWei);

        contPerRound[purchaser][uint8(round)] =
            contPerRound[purchaser][uint8(round)].add(contributionInWei);

        // Transfer contributions to fund address
        fundAddr.transfer(contributionInWei);
        TokenPurchase(msg.sender, contributionInWei, tokenAmount);

        return true;
    }

    /*
     * Add user and his allowed amount to allocation list
     *
     * @param user: Address of user to be allocated tokens
     * @param amount: Allowed allocation amount of user
     */
    function addToAllocationList(address user, uint256 amount)
        public
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
    {
        allocationList[user].isAllowed = true;
        allocationList[user].allowedAmount = amount;
    }

    /*
     * Add users and their allowed amount to allocation list
     *
     * @param users: List of Address to be allocated tokens
     * @param amount: List of allowed allocation amount of each user
     */
    function addManyToAllocationList(address[] users, uint256[] amounts)
        external
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
    {
        require(users.length == amounts.length);

        for (uint32 i = 0; i < users.length; i++) {
            addToAllocationList(users[i], amounts[i]);
        }
    }

    /*
     * Remove user from allocation list
     *
     * @param user: Address of user to be removed
     */
    function removeFromAllocationList(address user)
        public
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
    {
        allocationList[user].isAllowed = false;
    }

    /*
     * Remove users from allocation list
     *
     * @param user: Address list of users to be removed
     */
    function removeManyFromAllocationList(address[] users)
        external
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
    {
        for (uint32 i = 0; i < users.length; i++) {
            removeFromAllocationList(users[i]);
        }
    }


    /*
     * Allocate  tokens to user
     * Only avaliable on early investment
     *
     * @param to: Address of user to be allocated tokens
     * @param tokenAmount: Amount of tokens to be allocated
     */
    function allocateTokens(address to, uint256 tokenAmount)
        public
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
        returns (bool)
    {
        require(allocationList[to].isAllowed
            && tokenAmount <= allocationList[to].allowedAmount);

        if (!token.transferFrom(token.owner(), to, tokenAmount)) {
            revert();
        }
        return true;
    }

    /*
     * Allocate  tokens to user
     * Only avaliable on early investment
     *
     * @param toList: List of addresses to be allocated tokens
     * @param tokenAmountList: List of token amount to be allocated to each address
     */
    function allocateTokensToMany(address[] toList, uint256[] tokenAmountList)
        external
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
        returns (bool)
    {
        require(toList.length == tokenAmountList.length);

        for (uint32 i = 0; i < toList.length; i++) {
            allocateTokens(toList[i], tokenAmountList[i]);
        }
        return true;
    }
}