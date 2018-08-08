pragma solidity ^0.4.24;

/**
 * @title Utility contract to allow pausing and unpausing of certain functions
 */
contract Pausable {

    event Pause(uint256 _timestammp);
    event Unpause(uint256 _timestamp);

    bool public paused = false;

    /**
    * @notice Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @notice Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

   /**
    * @notice called by the owner to pause, triggers stopped state
    */
    function _pause() internal {
        require(!paused);
        paused = true;
        emit Pause(now);
    }

    /**
    * @notice called by the owner to unpause, returns to normal state
    */
    function _unpause() internal {
        require(paused);
        paused = false;
        emit Unpause(now);
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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

/**
 * @title Interface for the ST20 token standard
 */
contract IST20 is StandardToken, DetailedERC20 {

    // off-chain hash
    string public tokenDetails;

    //transfer, transferFrom must respect use respect the result of verifyTransfer
    function verifyTransfer(address _from, address _to, uint256 _amount) public returns (bool success);

    /**
     * @notice mints new tokens and assigns them to the target _investor.
     * Can only be called by the STO attached to the token (Or by the ST owner if there&#39;s no STO attached yet)
     */
    function mint(address _investor, uint256 _amount) public returns (bool success);

    /**
     * @notice Burn function used to burn the securityToken
     * @param _value No. of token that get burned
     */
    function burn(uint256 _value) public;

    event Minted(address indexed to, uint256 amount);
    event Burnt(address indexed _burner, uint256 _value);

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

/**
 * @title Interface for all security tokens
 */
contract ISecurityToken is IST20, Ownable {

    uint8 public constant PERMISSIONMANAGER_KEY = 1;
    uint8 public constant TRANSFERMANAGER_KEY = 2;
    uint8 public constant STO_KEY = 3;
    uint8 public constant CHECKPOINT_KEY = 4;
    uint256 public granularity;

    // Value of current checkpoint
    uint256 public currentCheckpointId;

    // Total number of non-zero token holders
    uint256 public investorCount;

    // List of token holders
    address[] public investors;

    // Permissions this to a Permission module, which has a key of 1
    // If no Permission return false - note that IModule withPerm will allow ST owner all permissions anyway
    // this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool);

    /**
     * @notice returns module list for a module type
     * @param _moduleType is which type of module we are trying to remove
     * @param _moduleIndex is the index of the module within the chosen type
     */
    function getModule(uint8 _moduleType, uint _moduleIndex) public view returns (bytes32, address);

    /**
     * @notice returns module list for a module name - will return first match
     * @param _moduleType is which type of module we are trying to remove
     * @param _name is the name of the module within the chosen type
     */
    function getModuleByName(uint8 _moduleType, bytes32 _name) public view returns (bytes32, address);

    /**
     * @notice Queries totalSupply as of a defined checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) public view returns(uint256);

    /**
     * @notice Queries balances as of a defined checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) public view returns(uint256);

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() public returns(uint256);

    /**
     * @notice gets length of investors array
     * NB - this length may differ from investorCount if list has not been pruned of zero balance investors
     * @return length
     */
    function getInvestorsLength() public view returns(uint256);

}

/**
 * @title Interface that any module factory contract should implement
 */
contract IModuleFactory is Ownable {

    ERC20 public polyToken;
    uint256 public setupCost;
    uint256 public usageCost;
    uint256 public monthlySubscriptionCost;

    event LogChangeFactorySetupFee(uint256 _oldSetupcost, uint256 _newSetupCost, address _moduleFactory);
    event LogChangeFactoryUsageFee(uint256 _oldUsageCost, uint256 _newUsageCost, address _moduleFactory);
    event LogChangeFactorySubscriptionFee(uint256 _oldSubscriptionCost, uint256 _newMonthlySubscriptionCost, address _moduleFactory);
    event LogGenerateModuleFromFactory(address _module, bytes32 indexed _moduleName, address indexed _moduleFactory, address _creator, uint256 _timestamp);

    /**
     * @notice Constructor
     * @param _polyAddress Address of the polytoken
     */
    constructor (address _polyAddress, uint256 _setupCost, uint256 _usageCost, uint256 _subscriptionCost) public {
      polyToken = ERC20(_polyAddress);
      setupCost = _setupCost;
      usageCost = _usageCost;
      monthlySubscriptionCost = _subscriptionCost;
    }

    //Should create an instance of the Module, or throw
    function deploy(bytes _data) external returns(address);

    /**
     * @notice Type of the Module factory
     */
    function getType() public view returns(uint8);

    /**
     * @notice Get the name of the Module
     */
    function getName() public view returns(bytes32);

    /**
     * @notice Get the description of the Module
     */
    function getDescription() public view returns(string);

    /**
     * @notice Get the title of the Module
     */
    function getTitle() public view returns(string);

    /**
     * @notice Get the Instructions that helped to used the module
     */
    function getInstructions() public view returns (string);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() public view returns (bytes32[]);

    //Pull function sig from _data
    function getSig(bytes _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
    }

    /**
     * @notice used to change the fee of the setup cost
     * @param _newSetupCost new setup cost
     */
    function changeFactorySetupFee(uint256 _newSetupCost) public onlyOwner {
        emit LogChangeFactorySetupFee(setupCost, _newSetupCost, address(this));
        setupCost = _newSetupCost;
    }

    /**
     * @notice used to change the fee of the usage cost
     * @param _newUsageCost new usage cost
     */
    function changeFactoryUsageFee(uint256 _newUsageCost) public onlyOwner {
        emit LogChangeFactoryUsageFee(usageCost, _newUsageCost, address(this));
        usageCost = _newUsageCost;
    }

    /**
     * @notice used to change the fee of the subscription cost
     * @param _newSubscriptionCost new subscription cost
     */
    function changeFactorySubscriptionFee(uint256 _newSubscriptionCost) public onlyOwner {
        emit LogChangeFactorySubscriptionFee(monthlySubscriptionCost, _newSubscriptionCost, address(this));
        monthlySubscriptionCost = _newSubscriptionCost;
        
    }

}

/**
 * @title Interface that any module contract should implement
 */
contract IModule {

    address public factory;

    address public securityToken;

    bytes32 public constant FEE_ADMIN = "FEE_ADMIN";

    ERC20 public polyToken;

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     * @param _polyAddress Address of the polytoken
     */
    constructor (address _securityToken, address _polyAddress) public {
        securityToken = _securityToken;
        factory = msg.sender;
        polyToken = ERC20(_polyAddress);
    }

    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() public pure returns (bytes4);

    //Allows owner, factory or permissioned delegate
    modifier withPerm(bytes32 _perm) {
        bool isOwner = msg.sender == ISecurityToken(securityToken).owner();
        bool isFactory = msg.sender == factory;
        require(isOwner||isFactory||ISecurityToken(securityToken).checkPermission(msg.sender, address(this), _perm), "Permission check failed");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == ISecurityToken(securityToken).owner(), "Sender is not owner");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factory, "Sender is not factory");
        _;
    }

    modifier onlyFactoryOwner {
        require(msg.sender == IModuleFactory(factory).owner(), "Sender is not factory owner");
        _;
    }

    /**
     * @notice Return the permissions flag that are associated with Module
     */
    function getPermissions() public view returns(bytes32[]);

    /**
     * @notice used to withdraw the fee by the factory owner
     */
    function takeFee(uint256 _amount) public withPerm(FEE_ADMIN) returns(bool) {
        require(polyToken.transferFrom(address(this), IModuleFactory(factory).owner(), _amount), "Unable to take fee");
        return true;
    }
}

/**
 * @title Interface to be implemented by all STO modules
 */
contract ISTO is IModule, Pausable {

    using SafeMath for uint256;

    enum FundraiseType { ETH, POLY }
    FundraiseType public fundraiseType;

    // Start time of the STO
    uint256 public startTime;
    // End time of the STO
    uint256 public endTime;

    /**
     * @notice use to verify the investment, whether the investor provide the allowance to the STO or not.
     * @param _beneficiary Ethereum address of the beneficiary, who wants to buy the st-20
     * @param _fundsAmount Amount invested by the beneficiary
     */
    function verifyInvestment(address _beneficiary, uint256 _fundsAmount) public view returns(bool) {
        return polyToken.allowance(_beneficiary, address(this)) >= _fundsAmount;
    }

    /**
     * @notice Return ETH raised by the STO
     */
    function getRaisedEther() public view returns (uint256);

    /**
     * @notice Return POLY raised by the STO
     */
    function getRaisedPOLY() public view returns (uint256);

    /**
     * @notice Return the total no. of investors
     */
    function getNumberInvestors() public view returns (uint256);

    /**
     * @notice pause (overridden function)
     */
    function pause() public onlyOwner {
        require(now < endTime);
        super._pause();
    }

    /**
     * @notice unpause (overridden function)
     */
    function unpause(uint256 _newEndDate) public onlyOwner {
        require(_newEndDate >= endTime);
        super._unpause();
        endTime = _newEndDate;
    }

    /**
    * @notice Reclaim ERC20Basic compatible tokens
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0));
        ERC20Basic token = ERC20Basic(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance));
    }

}

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7604131b15193644">[email&#160;protected]</a>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

/**
 * @title STO module for standard capped crowdsale
 */
contract CappedSTO is ISTO, ReentrancyGuard {
    using SafeMath for uint256;

    // Address where funds are collected and tokens are issued to
    address public wallet;

    // How many token units a buyer gets per wei / base unit of POLY
    uint256 public rate;

    // Amount of funds raised
    uint256 public fundsRaised;

    uint256 public investorCount;

    // Amount of tokens sold
    uint256 public tokensSold;

    //How many tokens this STO will be allowed to sell to investors
    uint256 public cap;

    mapping (address => uint256) public investors;

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (address _securityToken, address _polyAddress) public
    IModule(_securityToken, _polyAddress)
    {
    }

    //////////////////////////////////
    /**
    * @notice fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @notice Function used to intialize the contract variables
     * @param _startTime Unix timestamp at which offering get started
     * @param _endTime Unix timestamp at which offering get ended
     * @param _cap Maximum No. of tokens for sale
     * @param _rate Token units a buyer gets per wei / base unit of POLY
     * @param _fundRaiseType Type of currency used to collect the funds
     * @param _fundsReceiver Ethereum account address to hold the funds
     */
    function configure(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _cap,
        uint256 _rate,
        uint8 _fundRaiseType,
        address _fundsReceiver
    )
    public
    onlyFactory
    {
        require(_rate > 0, "Rate of token should be greater than 0");
        require(_fundsReceiver != address(0), "Zero address is not permitted");
        require(_startTime >= now && _endTime > _startTime, "Date parameters are not valid");
        require(_cap > 0, "Cap should be greater than 0");
        startTime = _startTime;
        endTime = _endTime;
        cap = _cap;
        rate = _rate;
        wallet = _fundsReceiver;
        _check(_fundRaiseType);
    }

    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() public pure returns (bytes4) {
        return bytes4(keccak256("configure(uint256,uint256,uint256,uint256,uint8,address)"));
    }

    /**
      * @notice low level token purchase ***DO NOT OVERRIDE***
      * @param _beneficiary Address performing the token purchase
      */
    function buyTokens(address _beneficiary) public payable nonReentrant {
        require(!paused);
        require(fundraiseType == FundraiseType.ETH, "ETH should be the mode of investment");

        uint256 weiAmount = msg.value;
        _processTx(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    /**
      * @notice low level token purchase
      * @param _investedPOLY Amount of POLY invested
      */
    function buyTokensWithPoly(uint256 _investedPOLY) public nonReentrant{
        require(!paused);
        require(fundraiseType == FundraiseType.POLY, "POLY should be the mode of investment");
        require(verifyInvestment(msg.sender, _investedPOLY), "Not valid Investment");
        _processTx(msg.sender, _investedPOLY);
        _forwardPoly(msg.sender, wallet, _investedPOLY);
        _postValidatePurchase(msg.sender, _investedPOLY);
    }

    /**
    * @notice Checks whether the cap has been reached.
    * @return bool Whether the cap was reached
    */
    function capReached() public view returns (bool) {
        return tokensSold >= cap;
    }

    /**
     * @notice Return ETH raised by the STO
     */
    function getRaisedEther() public view returns (uint256) {
        if (fundraiseType == FundraiseType.ETH)
            return fundsRaised;
        else
            return 0;
    }

    /**
     * @notice Return POLY raised by the STO
     */
    function getRaisedPOLY() public view returns (uint256) {
        if (fundraiseType == FundraiseType.POLY)
            return fundsRaised;
        else
            return 0;
    }

    /**
     * @notice Return the total no. of investors
     */
    function getNumberInvestors() public view returns (uint256) {
        return investorCount;
    }

    /**
     * @notice Return the permissions flag that are associated with STO
     */
    function getPermissions() public view returns(bytes32[]) {
        bytes32[] memory allPermissions = new bytes32[](0);
        return allPermissions;
    }

    /**
     * @notice Return the STO details
     */
    function getSTODetails() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (
            startTime,
            endTime,
            cap,
            rate,
            fundsRaised,
            investorCount,
            tokensSold,
            (fundraiseType == FundraiseType.POLY)
        );
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------
    /**
      * Processing the purchase as well as verify the required validations
      * @param _beneficiary Address performing the token purchase
      * @param _investedAmount Value in wei involved in the purchase
    */
    function _processTx(address _beneficiary, uint256 _investedAmount) internal {

        _preValidatePurchase(_beneficiary, _investedAmount);
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(_investedAmount);

        // update state
        fundsRaised = fundsRaised.add(_investedAmount);
        tokensSold = tokensSold.add(tokens);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, _investedAmount, tokens);

        _updatePurchasingState(_beneficiary, _investedAmount);
    }

    /**
    * @notice Validation of an incoming purchase.
      Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _investedAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _investedAmount) internal view {
        require(_beneficiary != address(0), "Beneficiary address should not be 0x");
        require(_investedAmount != 0, "Amount invested should not be equal to 0");
        require(tokensSold.add(_getTokenAmount(_investedAmount)) <= cap, "Investment more than cap is not allowed");
        require(now >= startTime && now <= endTime, "Offering is closed/Not yet started");
    }

    /**
    * @notice Validation of an executed purchase.
      Observe state and use revert statements to undo rollback when valid conditions are not met.
    */
    function _postValidatePurchase(address /*_beneficiary*/, uint256 /*_investedAmount*/) internal pure {
      // optional override
    }

    /**
    * @notice Source of tokens.
      Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(IST20(securityToken).mint(_beneficiary, _tokenAmount), "Error in minting the tokens");
    }

    /**
    * @notice Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        if (investors[_beneficiary] == 0) {
            investorCount = investorCount + 1;
        }
        investors[_beneficiary] = investors[_beneficiary].add(_tokenAmount);

        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
    * @notice Override for extensions that require an internal state to check for validity
      (current user contributions, etc.)
    */
    function _updatePurchasingState(address /*_beneficiary*/, uint256 /*_investedAmount*/) internal pure {
      // optional override
    }

    /**
    * @notice Override to extend the way in which ether is converted to tokens.
    * @param _investedAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _investedAmount
    */
    function _getTokenAmount(uint256 _investedAmount) internal view returns (uint256) {
        return _investedAmount.mul(rate);
    }

    /**
    * @notice Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /**
     * @notice Internal function used to check the type of fund raise currency
     * @param _fundraiseType Type of currency used to collect the funds
     */
    function _check(uint8 _fundraiseType) internal {
        require(_fundraiseType == 0 || _fundraiseType == 1, "Not a valid fundraise type");
        if (_fundraiseType == 0) {
            fundraiseType = FundraiseType.ETH;
        }
        if (_fundraiseType == 1) {
            require(address(polyToken) != address(0), "Address of the polyToken should not be 0x");
            fundraiseType = FundraiseType.POLY;
        }
    }

    /**
     * @notice Internal function used to forward the POLY raised to beneficiary address
     * @param _beneficiary Address of the funds reciever
     * @param _to Address who wants to ST-20 tokens
     * @param _fundsAmount Amount invested by _to
     */
    function _forwardPoly(address _beneficiary, address _to, uint256 _fundsAmount) internal {
        polyToken.transferFrom(_beneficiary, _to, _fundsAmount);
    }

}