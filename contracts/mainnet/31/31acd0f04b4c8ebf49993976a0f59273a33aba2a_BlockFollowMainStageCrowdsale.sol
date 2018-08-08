pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

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

// File: contracts/crowdsale/StageCrowdsale.sol

contract StageCrowdsale is FinalizableCrowdsale {
    bool public previousStageIsFinalized = false;
    StageCrowdsale public previousStage;

    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        uint256 _closingTime,
        StageCrowdsale _previousStage
    )
        public
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        previousStage = _previousStage;
        if (_previousStage == address(0)) {
            previousStageIsFinalized = true;
        }
    }

    modifier isNotFinalized() {
        require(!isFinalized, "Call on finalized.");
        _;
    }

    modifier previousIsFinalized() {
        require(isPreviousStageFinalized(), "Call on previous stage finalized.");
        _;
    }

    function finalizeStage() public onlyOwner isNotFinalized {
        _finalizeStage();
    }

    function proxyBuyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        // solium-disable-next-line security/no-tx-origin
        emit TokenPurchase(tx.origin, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    function isPreviousStageFinalized() public returns (bool) {
        if (previousStageIsFinalized) {
            return true;
        }
        if (previousStage.isFinalized()) {
            previousStageIsFinalized = true;
        }
        return previousStageIsFinalized;
    }

    function _finalizeStage() internal isNotFinalized {
        finalization();
        emit Finalized();
        isFinalized = true;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isNotFinalized previousIsFinalized {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

// File: openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

// File: contracts/crowdsale/CappedStageCrowdsale.sol

contract CappedStageCrowdsale is CappedCrowdsale, StageCrowdsale {
    using SafeMath for uint256;

    /**
     * @dev Returns value left to reaching crowdsale&#39;s cap.
     * @return Wei to cap
     */
    function weiToCap() public view returns (uint256) {
        return cap.sub(weiRaised);
    }

    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._postValidatePurchase(_beneficiary, _weiAmount);
        if (weiRaised >= cap) {
            _finalizeStage();
        }
    }
}

// File: contracts/crowdsale/LimitedMinPurchaseCrowdsale.sol

/**
 * @title LimitedMinPurchaseCrowdsale
 * @dev Crowdsale with a lower limit to the value of a purchase.
 */
contract LimitedMinPurchaseCrowdsale is Crowdsale {
    using SafeMath for uint256;

    // Lower limit to the value of a purchase in wei.
    uint256 public minPurchase;

    /**
     * @param _minPurchase Minimal value of tokens that can be bought
     */
    constructor(uint256 _minPurchase) public {
        require(
            _minPurchase > 0,
            "Call with insufficient _minPurchase."
        );
        minPurchase = _minPurchase;
    }

    modifier overMinPurchaseLimit(uint256 _weiAmount) {
        require(
            _weiAmount >= minPurchase,
            "Call with insufficient _weiAmount."
        );
        _;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding&#39;s lower cap.
     * @param _beneficiary Token beneficiary
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal overMinPurchaseLimit(_weiAmount) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

// File: contracts/crowdsale/TokensSoldCountingCrowdsale.sol

contract TokensSoldCountingCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public tokensSoldCount;

    /**
    * @dev Update tokensSoldCount.
    * @param _beneficiary Address receiving the tokens
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        uint256 tokens = _getTokenAmount(_weiAmount);
        tokensSoldCount = tokensSoldCount.add(tokens);
    }
}

// File: contracts/crowdsale/ManualTokenDistributionCrowdsale.sol

/**
 * @title ManualTokenDistributionCrowdsale
 * @dev Crowdsale with a functionality of manual assignment of tokens
 */
contract ManualTokenDistributionCrowdsale is Crowdsale, Ownable, TokensSoldCountingCrowdsale {
    
    using SafeMath for uint256;

    /**
    * Event for manual token assignment
    * @param beneficiary who got the tokens
    * @param amount amount of tokens purchased
    */
    event TokenAssignment(address indexed beneficiary, uint256 amount);


    /**
    * @dev Manual send tokens to the specified address.
    * @param _beneficiary The address of a investor.
    * @param _tokensAmount Amount of tokens.
    */
    function manualSendTokens(address _beneficiary, uint256 _tokensAmount) public  onlyOwner {
        require(_beneficiary != address(0));
        require(_tokensAmount > 0);

        super._deliverTokens(_beneficiary, _tokensAmount);
        tokensSoldCount = tokensSoldCount.add(_tokensAmount);
        emit TokenAssignment(_beneficiary, _tokensAmount);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: contracts/crowdsale/PausableCrowdsale.sol

contract PausableCrowdsale is Crowdsale, Pausable {
    /**
     * @dev Extend parent behavior requiring purchase to respect paused state.
     * @param _beneficiary Token beneficiary
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

// File: openzeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @param _wallet Vault address
   */
  constructor(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol

/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale&#39;s vault.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;

  /**
   * @dev Constructor, creates RefundVault.
   * @param _goal Funding goal
   */
  constructor(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  /**
   * @dev Checks whether funding goal was reached.
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

  /**
   * @dev vault finalization task, called when owner calls finalize()
   */
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
   */
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

}

// File: contracts/crowdsale/RefundableStageCrowdsale.sol

contract RefundableStageCrowdsale is RefundableCrowdsale {
    /**
    * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
    */
    function _forwardFunds() internal {
        // solium-disable-next-line security/no-tx-origin
        vault.deposit.value(msg.value)(tx.origin);
    }
}

// File: openzeppelin-solidity/contracts/ownership/rbac/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

// File: openzeppelin-solidity/contracts/ownership/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: openzeppelin-solidity/contracts/ownership/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }

}

// File: contracts/crowdsale/WhitelistedCrowdsale.sol

contract WhitelistedCrowdsale is Crowdsale, Ownable {
    Whitelist public whitelist;

    constructor (Whitelist _whitelist) public {
        require(_whitelist != address(0));
        whitelist = _whitelist;
    }

    /**
    * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
    */
    modifier onlyWhitelisted(address _beneficiary) {
        require(whitelist.whitelist(_beneficiary));
        _;
    }

    function isWhitelisted(address _beneficiary) public view returns(bool) {
        return whitelist.whitelist(_beneficiary);
    }

    function changeWhitelist(Whitelist _whitelist) public onlyOwner {
        whitelist = _whitelist;
    }

    /**
    * @dev Extend parent behavior requiring beneficiary to be in whitelist.
    * @param _beneficiary Token beneficiary
    * @param _weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhitelisted(_beneficiary) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

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
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: contracts/BlockFollowMainStageCrowdsale.sol

contract BlockFollowMainStageCrowdsale is StageCrowdsale, CappedStageCrowdsale, LimitedMinPurchaseCrowdsale,
    ManualTokenDistributionCrowdsale, PausableCrowdsale, RefundableStageCrowdsale, WhitelistedCrowdsale {
    using SafeMath for uint256;

    mapping (address => bool) public claimedBonus;
    uint256 public ratePerEth;

    uint256 public bonusTokensPool;
    uint256 public burnPercentage;
    uint256 public totalTokensSold;
    uint256 purchasableTokenSupply;

    constructor(
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        StageCrowdsale _previousStage,
        uint256 _ratePerEth,
        uint256 _minPurchase,
        uint256 _minCap,
        uint256 _maxCap,
        uint256 _burnPercentage,
        uint256 _purchasableTokenSupply,
        Whitelist _whitelist
    )
        public
        CappedCrowdsale(_maxCap)
        LimitedMinPurchaseCrowdsale(_minPurchase)
        StageCrowdsale(_ratePerEth, _wallet, _token, _openingTime, _openingTime + 4 weeks, _previousStage)
        RefundableCrowdsale(_minCap)
        WhitelistedCrowdsale(_whitelist)
    {
        require(_ratePerEth > 0, "Rate per ETH cannot be null");
        require(_burnPercentage > 0, "Burn percenatage cannot be null");
        require(_purchasableTokenSupply > 0, "Purchasable token supply cannot be null");
        ratePerEth = _ratePerEth;
        burnPercentage = _burnPercentage;
        purchasableTokenSupply = _purchasableTokenSupply;
    }

    /**
     * @dev Only allow if the crowdsale has been finalized, it is 2 weeks after it closed, contributor have not already
     * claimed bonus tokens and if purchases have been made at all.
     */
    modifier canClaimBonus() {
        require(isFinalized, "Cannot claim bonus when stage is not yet finalized");
        // solium-disable-next-line security/no-block-members
        require(now < openingTime + 6 weeks, "Cannot claim bonus tokens too soon");
        require(!claimedBonus[msg.sender], "Cannot claim bonus tokens repeatedly");
        require(totalTokensSold > 0, "Cannot claim bonus tokens when no purchase have been made");
        _;
    }

    /**
     * @dev Allows contributor to claim part of the tokens remaining after crowdsale stage finalizes. The part is
     * determined in proportion to the value of their current contribution(s).
     */
    function claimBonusTokens() public canClaimBonus {
        uint256 senderBalance = token.balanceOf(msg.sender);
        uint256 purchasedProportion = senderBalance.mul(1e18).div(totalTokensSold);
        uint256 bonusForSender = bonusTokensPool.mul(purchasedProportion).div(1e18);
        token.transfer(msg.sender, bonusForSender);
        claimedBonus[msg.sender] = true;
    }

    /**
     * @dev Allows owner to claim the remaining tokens.
     */
    function claimRemainingTokens() public onlyOwner {
        uint256 balance = token.balanceOf(this);
        manualSendTokens(msg.sender, balance);
    }

    /**
     * @dev Erases 75% of the remaining token balance when owner calls finalize() or crowdsale reaches the max cap.
     */
    function finalization() internal {
        super.finalization();

        uint256 balance = token.balanceOf(address(this));
        totalTokensSold = purchasableTokenSupply.sub(balance);

        uint256 balanceToBurn = balance.mul(burnPercentage).div(100);
        BurnableToken(address(token)).burn(balanceToBurn);

        uint256 bonusPercentage = 100 - burnPercentage;
        bonusTokensPool = balance.mul(100).mul(bonusPercentage).div(1e4);
    }


   /**
    * @dev Defines the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.div(1e10).mul(ratePerEth);
    }
}