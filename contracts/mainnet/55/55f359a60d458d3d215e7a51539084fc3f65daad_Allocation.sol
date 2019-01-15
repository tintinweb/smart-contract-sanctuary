pragma solidity 0.4.24;


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


/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );
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
     * @dev Throws if called by any account other than the specific function owner.
     */
    modifier ownedBy(address _a) {
        require( msg.sender == _a );
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
  
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to. Needs to be accepted by
     * the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnershipAtomic(address _newOwner) public onlyOwner {
        owner = _newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(owner, _newOwner);
    }
  
    /**
     * @dev Completes the ownership transfer by having the new address confirm the transfer.
     */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }
  
    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        newOwner = _newOwner;
        emit OwnershipTransferInitiated(owner, _newOwner);
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require( (allowed[msg.sender][_spender] == 0) || (_value == 0) );
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    // Overflow check: 2700 *1e6 * 1e18 < 10^30 < 2^105 < 2^256
    uint constant public SUPPLY_HARD_CAP = 2700 * 1e6 * 1e18;
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(
        address _to,
        uint256 _amount
    )
        public
        hasMintPermission
        canMint
        returns (bool)
    {
        require( totalSupply_.add(_amount) <= SUPPLY_HARD_CAP );
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}


contract OPUCoin is MintableToken {
    string constant public symbol = "OPU";
    string constant public name = "Opu Coin";
    uint8 constant public decimals = 18;

    // -------------------------------------------
	// Public functions
    // -------------------------------------------
    constructor() public { }
}


contract ColdStorage is Ownable {
    using SafeMath for uint8;
    using SafeMath for uint256;

    ERC20 public token;

    uint public lockupEnds;
    uint public lockupPeriod;
    bool public storageInitialized = false;
    address public founders;

    event StorageInitialized(address _to, uint _tokens);
    event TokensReleased(address _to, uint _tokensReleased);

    constructor(address _token) public {
        require( _token != address(0) );
        token = ERC20(_token);
        uint lockupYears = 2;
        lockupPeriod = lockupYears.mul(365 days);
    }

    function claimTokens() external {
        require( now > lockupEnds );
        require( msg.sender == founders );

        uint tokensToRelease = token.balanceOf(address(this));
        require( token.transfer(msg.sender, tokensToRelease) );
        emit TokensReleased(msg.sender, tokensToRelease);
    }

    function initializeHolding(address _to) public onlyOwner {
        uint tokens = token.balanceOf(address(this));
        require( !storageInitialized );
        require( tokens != 0 );

        lockupEnds = now.add(lockupPeriod);
        founders = _to;
        storageInitialized = true;
        emit StorageInitialized(_to, tokens);
    }
}


contract Vesting is Ownable {
    using SafeMath for uint;
    using SafeMath for uint256;

    ERC20 public token;
    mapping (address => Holding) public holdings;
    address internal founders;

    uint constant internal PERIOD_INTERVAL = 30 days;
    uint constant internal FOUNDERS_HOLDING = 365 days;
    uint constant internal BONUS_HOLDING = 0;
    uint constant internal TOTAL_PERIODS = 12;

    uint public additionalHoldingPool = 0;
    uint internal totalTokensCommitted = 0;

    bool internal vestingStarted = false;
    uint internal vestingStart = 0;

    struct Holding {
        uint tokensCommitted;
        uint tokensRemaining;
        uint batchesClaimed;
        bool updatedForFinalization;
        bool isFounder;
        bool isValue;
    }

    event TokensReleased(address _to, uint _tokensReleased, uint _tokensRemaining);
    event VestingInitialized(address _to, uint _tokens);
    event VestingUpdated(address _to, uint _totalTokens);

    constructor(address _token, address _founders) public {
        require( _token != 0x0);
        require(_founders != 0x0);
        token = ERC20(_token);
        founders = _founders;
    }

    function claimTokens() external {
        require( holdings[msg.sender].isValue );
        require( vestingStarted );
        uint personalVestingStart = 
            (holdings[msg.sender].isFounder) ? (vestingStart.add(FOUNDERS_HOLDING)) : (vestingStart);

        require( now > personalVestingStart );

        uint periodsPassed = now.sub(personalVestingStart).div(PERIOD_INTERVAL);

        uint batchesToClaim = periodsPassed.sub(holdings[msg.sender].batchesClaimed);
        require( batchesToClaim > 0 );

        if (!holdings[msg.sender].updatedForFinalization) {
            holdings[msg.sender].updatedForFinalization = true;
            holdings[msg.sender].tokensRemaining = (holdings[msg.sender].tokensRemaining).add(
                (holdings[msg.sender].tokensCommitted).mul(additionalHoldingPool).div(totalTokensCommitted)
            );
        }

        uint tokensPerBatch = (holdings[msg.sender].tokensRemaining).div(
            TOTAL_PERIODS.sub(holdings[msg.sender].batchesClaimed)
        );
        uint tokensToRelease = 0;

        if (periodsPassed >= TOTAL_PERIODS) {
            tokensToRelease = holdings[msg.sender].tokensRemaining;
            delete holdings[msg.sender];
        } else {
            tokensToRelease = tokensPerBatch.mul(batchesToClaim);
            holdings[msg.sender].tokensRemaining = (holdings[msg.sender].tokensRemaining).sub(tokensToRelease);
            holdings[msg.sender].batchesClaimed = holdings[msg.sender].batchesClaimed.add(batchesToClaim);
        }

        require( token.transfer(msg.sender, tokensToRelease) );
        emit TokensReleased(msg.sender, tokensToRelease, holdings[msg.sender].tokensRemaining);
    }

    function tokensRemainingInHolding(address _user) public view returns (uint) {
        return holdings[_user].tokensRemaining;
    }
    
    function initializeVesting(address _beneficiary, uint _tokens) public onlyOwner {
        bool isFounder = (_beneficiary == founders);
        _initializeVesting(_beneficiary, _tokens, isFounder);
    }

    function finalizeVestingAllocation(uint _holdingPoolTokens) public onlyOwner {
        additionalHoldingPool = _holdingPoolTokens;
        vestingStarted = true;
        vestingStart = now;
    }

    function _initializeVesting(address _to, uint _tokens, bool _isFounder) internal {
        require( !vestingStarted );

        if (!_isFounder) totalTokensCommitted = totalTokensCommitted.add(_tokens);

        if (!holdings[_to].isValue) {
            holdings[_to] = Holding({
                tokensCommitted: _tokens, 
                tokensRemaining: _tokens,
                batchesClaimed: 0, 
                updatedForFinalization: _isFounder, 
                isFounder: _isFounder,
                isValue: true
            });

            emit VestingInitialized(_to, _tokens);
        } else {
            holdings[_to].tokensCommitted = (holdings[_to].tokensCommitted).add(_tokens);
            holdings[_to].tokensRemaining = (holdings[_to].tokensRemaining).add(_tokens);

            emit VestingUpdated(_to, holdings[_to].tokensRemaining);
        }
    }
}


contract Allocation is Ownable {
    using SafeMath for uint256;

    address public backend;
    address public team;
    address public partners;
    address public toSendFromStorage;
    OPUCoin public token;
    Vesting public vesting;
    ColdStorage public coldStorage;

    bool public emergencyPaused = false;
    bool public finalizedHoldingsAndTeamTokens = false;
    bool public mintingFinished = false;

    // All the numbers on the following 8 lines are lower than 10^30
    // Which is in turn lower than 2^105, which is lower than 2^256
    // So, no overflows are possible, the operations are safe.
    uint constant internal MIL = 1e6 * 1e18;
    // Token distribution table, all values in millions of tokens
    uint constant internal ICO_DISTRIBUTION    = 1350 * MIL;
    uint constant internal TEAM_TOKENS         = 675  * MIL;
    uint constant internal COLD_STORAGE_TOKENS = 189  * MIL;
    uint constant internal PARTNERS_TOKENS     = 297  * MIL; 
    uint constant internal REWARDS_POOL        = 189  * MIL;

    uint internal totalTokensSold = 0;
    uint internal totalTokensRewarded = 0;

    event TokensAllocated(address _buyer, uint _tokens);
    event TokensAllocatedIntoHolding(address _buyer, uint _tokens);
    event TokensMintedForRedemption(address _to, uint _tokens);
    event TokensSentIntoVesting(address _vesting, address _to, uint _tokens);
    event TokensSentIntoHolding(address _vesting, address _to, uint _tokens);
    event HoldingAndTeamTokensFinalized();
    event BackendUpdated(address oldBackend, address newBackend);
    event TeamUpdated(address oldTeam, address newTeam);
    event PartnersUpdated(address oldPartners, address newPartners);
    event ToSendFromStorageUpdated(address oldToSendFromStorage, address newToSendFromStorage);

    // Human interaction (only accepted from the address that launched the contract)
    constructor(
        address _backend, 
        address _team, 
        address _partners, 
        address _toSendFromStorage
    ) 
        public 
    {
        require( _backend           != address(0) );
        require( _team              != address(0) );
        require( _partners          != address(0) );
        require( _toSendFromStorage != address(0) );

        backend           = _backend;
        team              = _team;
        partners          = _partners;
        toSendFromStorage = _toSendFromStorage;

        token       = new OPUCoin();
        vesting     = new Vesting(address(token), team);
        coldStorage = new ColdStorage(address(token));
    }

    function emergencyPause() public onlyOwner unpaused { emergencyPaused = true; }

    function emergencyUnpause() public onlyOwner paused { emergencyPaused = false; }

    function allocate(
        address _buyer, 
        uint _tokensWithStageBonuses, 
        uint _rewardsBonusTokens
    ) 
        public 
        ownedBy(backend) 
        mintingEnabled
    {
        uint tokensAllocated = _allocateTokens(_buyer, _tokensWithStageBonuses, _rewardsBonusTokens);
        emit TokensAllocated(_buyer, tokensAllocated);
    }

    function allocateIntoHolding(
        address _buyer, 
        uint _tokensWithStageBonuses, 
        uint _rewardsBonusTokens
    ) 
        public 
        ownedBy(backend) 
        mintingEnabled
    {
        uint tokensAllocated = _allocateTokens(
            address(vesting), 
            _tokensWithStageBonuses, 
            _rewardsBonusTokens
        );
        vesting.initializeVesting(_buyer, tokensAllocated);
        emit TokensAllocatedIntoHolding(_buyer, tokensAllocated);
    }

    function finalizeHoldingAndTeamTokens(
        uint _holdingPoolTokens
    ) 
        public 
        ownedBy(backend) 
        unpaused 
    {
        require( !finalizedHoldingsAndTeamTokens );

        finalizedHoldingsAndTeamTokens = true;

        vestTokens(team, TEAM_TOKENS);
        holdTokens(toSendFromStorage, COLD_STORAGE_TOKENS);
        token.mint(partners, PARTNERS_TOKENS);

        // Can exceed ICO token cap
        token.mint(address(vesting), _holdingPoolTokens);
        vesting.finalizeVestingAllocation(_holdingPoolTokens);

        mintingFinished = true;
        token.finishMinting();

        emit HoldingAndTeamTokensFinalized();
    }

    function optAddressIntoHolding(
        address _holder, 
        uint _tokens
    ) 
        public 
        ownedBy(backend) 
    {
        require( !finalizedHoldingsAndTeamTokens );

        require( token.mint(address(vesting), _tokens) );

        vesting.initializeVesting(_holder, _tokens);
        emit TokensSentIntoHolding(address(vesting), _holder, _tokens);
    }

    function _allocateTokens(
        address _to, 
        uint _tokensWithStageBonuses, 
        uint _rewardsBonusTokens
    ) 
        internal 
        unpaused 
        returns (uint)
    {
        require( _to != address(0) );

        checkCapsAndUpdate(_tokensWithStageBonuses, _rewardsBonusTokens);

        // Calculate the total token sum to allocate
        uint tokensToAllocate = _tokensWithStageBonuses.add(_rewardsBonusTokens);

        // Mint the tokens
        require( token.mint(_to, tokensToAllocate) );
        return tokensToAllocate;
    }

    function checkCapsAndUpdate(uint _tokensToSell, uint _tokensToReward) internal {
        uint newTotalTokensSold = totalTokensSold.add(_tokensToSell);
        require( newTotalTokensSold <= ICO_DISTRIBUTION );
        totalTokensSold = newTotalTokensSold;

        uint newTotalTokensRewarded = totalTokensRewarded.add(_tokensToReward);
        require( newTotalTokensRewarded <= REWARDS_POOL );
        totalTokensRewarded = newTotalTokensRewarded;
    }

    function vestTokens(address _to, uint _tokens) internal {
        require( token.mint(address(vesting), _tokens) );
        vesting.initializeVesting( _to, _tokens );
        emit TokensSentIntoVesting(address(vesting), _to, _tokens);
    }

    function holdTokens(address _to, uint _tokens) internal {
        require( token.mint(address(coldStorage), _tokens) );
        coldStorage.initializeHolding(_to);
        emit TokensSentIntoHolding(address(coldStorage), _to, _tokens);
    }

    function updateBackend(address _newBackend) public onlyOwner {
        require(_newBackend != address(0));
        backend = _newBackend;
        emit BackendUpdated(backend, _newBackend);
    }

    function updateTeam(address _newTeam) public onlyOwner {
        require(_newTeam != address(0));
        team = _newTeam;
        emit TeamUpdated(team, _newTeam);
    }

    function updatePartners(address _newPartners) public onlyOwner {
        require(_newPartners != address(0));
        partners = _newPartners;
        emit PartnersUpdated(partners, _newPartners);
    }

    function updateToSendFromStorage(address _newToSendFromStorage) public onlyOwner {
        require(_newToSendFromStorage != address(0));
        toSendFromStorage = _newToSendFromStorage;
        emit ToSendFromStorageUpdated(toSendFromStorage, _newToSendFromStorage);
    }

    modifier unpaused() {
        require( !emergencyPaused );
        _;
    }

    modifier paused() {
        require( emergencyPaused );
        _;
    }

    modifier mintingEnabled() {
        require( !mintingFinished );
        _;
    }
}