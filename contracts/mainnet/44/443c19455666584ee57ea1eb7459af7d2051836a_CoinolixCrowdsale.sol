pragma solidity ^0.4.24;

// File: contracts\zeppelin\ownership\Ownable.sol

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

// File: contracts\zeppelin\math\SafeMath.sol

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

// File: contracts\zeppelin\token\ERC20\ERC20Basic.sol

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

// File: contracts\zeppelin\token\ERC20\BasicToken.sol

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

// File: contracts\zeppelin\token\ERC20\ERC20.sol

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

// File: contracts\zeppelin\token\ERC20\StandardToken.sol

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

// File: contracts\zeppelin\token\ERC20\MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

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
    hasMintPermission
    canMint
    public
    returns (bool)
  {
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
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts\zeppelin\token\ERC20\CappedToken.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
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
    onlyOwner
    canMint
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: contracts\zeppelin\lifecycle\Pausable.sol

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

// File: contracts\zeppelin\token\ERC20\PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

// File: contracts\CoinolixToken.sol

/**
 * @title Coinolix icoToken
 * @dev Coinolix icoToken - Token code for the Coinolix icoProject
 * This is a standard ERC20 token with:
 * - a cap
 * - ability to pause transfers
 */
contract CoinolixToken is CappedToken, PausableToken {

    string public constant name                 = "Coinolix token";
    string public constant symbol               = "CLX";
    uint public constant decimals               = 18;

    constructor(uint256 _totalSupply) 
        CappedToken(_totalSupply) public {
        paused = true;
    }
}

// File: contracts\zeppelin\token\ERC20\SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: contracts\TokenPool.sol

/**
 * @title TokenPool 
 * @dev Token Pool contract used to store tokens for special purposes
 * The pool can receive tokens and can transfer tokens to multiple beneficiaries.
 * It can be used for airdrops or similar cases.
 */
contract TokenPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    ERC20Basic public token;
    uint256 public cap;
    uint256 public totalAllocated;

    /**
     * @dev Contract constructor
     * @param _token address token that will be stored in the pool
     * @param _cap uint256 predefined cap of the pool
     */
    constructor(address _token, uint256 _cap) public {
        token = ERC20Basic(_token);
        cap = _cap;
        totalAllocated = 0;
    }

    /**
     * @dev Transfer different amounts of tokens to multiple beneficiaries 
     * @param _beneficiaries addresses of the beneficiaries
     * @param _amounts uint256[] amounts for each beneficiary
     */
    function allocate(address[] _beneficiaries, uint256[] _amounts) public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i ++) {
            require(totalAllocated.add(_amounts[i]) <= cap);
            token.safeTransfer(_beneficiaries[i], _amounts[i]);
            totalAllocated.add(_amounts[i]);
        }
    }

    /**
     * @dev Transfer the same amount of tokens to multiple beneficiaries 
     * @param _beneficiaries addresses of the beneficiaries
     * @param _amounts uint256[] amounts for each beneficiary
     */
    function allocateEqual(address[] _beneficiaries, uint256 _amounts) public onlyOwner {
        uint256 totalAmount = _amounts.mul(_beneficiaries.length);
        require(totalAllocated.add(totalAmount) <= cap);
        require(token.balanceOf(this) >= totalAmount);

        for (uint256 i = 0; i < _beneficiaries.length; i ++) {
            token.safeTransfer(_beneficiaries[i], _amounts);
            totalAllocated.add(_amounts);
        }
    }
}

// File: contracts\zeppelin\crowdsale\Crowdsale.sol

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
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called CLX
  // 1 wei will give you 1 unit, or 0.001 CLX.
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

// File: contracts\zeppelin\crowdsale\validation\TimedCrowdsale.sol
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

// File: contracts\zeppelin\crowdsale\distribution\FinalizableCrowdsale.sol

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

// File: contracts\zeppelin\crowdsale\distribution\utils\RefundVault.sol

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

// File: contracts\zeppelin\crowdsale\distribution\RefundableCrowdsale.sol

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

// File: contracts\zeppelin\crowdsale\emission\MintedCrowdsale.sol

/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

/**
 * @title AirdropAndAffiliateCrowdsale
 * @dev Extension of AirdropAndAffiliateCrowdsale contract
 */
contract AirdropAndAffiliateCrowdsale is MintedCrowdsale {
  uint256 public valueAirDrop;
  uint256 public referrerBonus1;
  uint256 public referrerBonus2;
  mapping (address => uint8) public payedAddress;
  mapping (address => address) public referrers;
  constructor(uint256 _valueAirDrop, uint256 _referrerBonus1, uint256 _referrerBonus2) public {
    valueAirDrop = _valueAirDrop;
	referrerBonus1 = _referrerBonus1;
	referrerBonus2 = _referrerBonus2;
  }
  function bytesToAddress(bytes source) internal pure returns(address) {
    uint result;
    uint mul = 1;
    for(uint i = 20; i > 0; i--) {
      result += uint8(source[i-1])*mul;
      mul = mul*256;
    }
    return address(result);
  }  
  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    address referer1;
    uint256 refererTokens1;
    address referer2;
    uint256 refererTokens2;	
    if (_tokenAmount != 0){ 
	  super._deliverTokens(_beneficiary, _tokenAmount);
      //require(MintableToken(token).mint(_beneficiary, _tokenAmount));
    }
	else{
	  require(payedAddress[_beneficiary] == 0);
      payedAddress[_beneficiary] = 1;  	  
	  super._deliverTokens(_beneficiary, valueAirDrop);
	  _tokenAmount = valueAirDrop;
	}
    //referral system
	if(msg.data.length == 20) {	  
      referer1 = bytesToAddress(bytes(msg.data));
	  referrers[_beneficiary] = referer1;
      if(referer1 != _beneficiary){
	    //add tokens to the referrer1
        refererTokens1 = _tokenAmount.mul(referrerBonus1).div(100);
	    super._deliverTokens(referer1, refererTokens1);
	    referer2 = referrers[referer1];
	    if(referer2 != address(0)){
	      refererTokens2 = _tokenAmount.mul(referrerBonus2).div(100);
	      super._deliverTokens(referer2, refererTokens2);
	    }
	  }
    }	
  }
}

// File: contracts\zeppelin\crowdsale\validation\CappedCrowdsale.sol

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

// File: contracts\zeppelin\crowdsale\validation\WhitelistedCrowdsale.sol

/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    isWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: contracts\zeppelin\token\ERC20\TokenTimelock.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

// File: contracts\CoinolixCrowdsale.sol

/**
 * @title Coinolix ico Crowdsale Contract
 * @dev Coinolix ico Crowdsale Contract
 * The contract is for the crowdsale of the Coinolix icotoken. It is:
 * - With a hard cap in ETH
 * - With a soft cap in ETH
 * - Limited in time (start/end date)
 * - Only for whitelisted participants to purchase tokens
 * - Ether is securely stored in RefundVault until the end of the crowdsale
 * - At the end of the crowdsale if the goal is reached funds can be used
 * ...otherwise the participants can refund their investments
 * - Tokens are minted on each purchase
 * - Sale can be paused if needed by the admin
 */
contract CoinolixCrowdsale is 
    AirdropAndAffiliateCrowdsale,
	//MintedCrowdsale,
    CappedCrowdsale,
    TimedCrowdsale,
    FinalizableCrowdsale,
    WhitelistedCrowdsale, 
    RefundableCrowdsale,
    Pausable {
    using SafeMath for uint256;

    // Initial distribution
    uint256 public constant PUBLIC_TOKENS  = 50; // 50% from totalSupply CROWDSALE + PRESALE
    uint256 public constant PVT_INV_TOKENS = 15; // 15% from totalSupply PRIVATE SALE INVESTOR


    uint256 public constant TEAM_TOKENS    = 20; // 20% from totalSupply FOUNDERS
    uint256 public constant ADV_TEAM_TOKENS = 10;  // 10% from totalSupply ADVISORS

    uint256 public constant BOUNTY_TOKENS   = 2; // 2% from totalSupply BOUNTY
    uint256 public constant REFF_TOKENS     = 3;  // 3% from totalSupply REFFERALS

    uint256 public constant TEAM_LOCK_TIME    = 31540000; // 1 year in seconds
    uint256 public constant ADV_TEAM_LOCK_TIME = 15770000; // 6 months in seconds

    // Rate bonuses
    uint256 public initialRate;
    uint256[4] public bonuses = [20,10,5,0];
    uint256[4] public stages = [
    1541635200, // 1st two week of crowdsale -> 20% Bonus
    1542844800, // 3rd week of crowdsale -> 10% Bonus
    1543449600, // 4th week of crowdsale -> 5% Bonus
    1544054400  // 5th week of crowdsale -> 0% Bonus
    ];
    
    // Min investment
    uint256 public minInvestmentInWei;
    // Max individual investment
    uint256 public maxInvestmentInWei;
    
    mapping (address => uint256) internal invested;

    TokenTimelock public teamWallet;
    TokenTimelock public advteamPool;
    TokenPool public reffalPool;
    TokenPool public pvt_inv_Pool;

    // Events for this contract

    /**
     * Event triggered when changing the current rate on different stages
     * @param rate new rate
     */
    event CurrentRateChange(uint256 rate);

    /**
     * @dev Contract constructor
     * @param _cap uint256 hard cap of the crowdsale
     * @param _goal uint256 soft cap of the crowdsale
     * @param _openingTime uint256 crowdsale start date/time
     * @param _closingTime uint256 crowdsale end date/time
     * @param _rate uint256 initial rate CLX for 1 ETH
     * @param _minInvestmentInWei uint256 minimum investment amount
     * @param _maxInvestmentInWei uint256 maximum individual investment amount
     * @param _wallet address address where the collected funds will be transferred
     * @param _token CoinolixToken our token
     */
    constructor(
        uint256 _cap, 
        uint256 _goal, 
        uint256 _openingTime, 
        uint256 _closingTime, 
        uint256 _rate, 
        uint256 _minInvestmentInWei,
        uint256 _maxInvestmentInWei,
        address _wallet,
        CoinolixToken _token,
        uint256 _valueAirDrop, 
        uint256 _referrerBonus1, 
        uint256 _referrerBonus2) 
        Crowdsale(_rate, _wallet, _token)
        CappedCrowdsale(_cap)
        AirdropAndAffiliateCrowdsale(_valueAirDrop, _referrerBonus1, _referrerBonus2)
        TimedCrowdsale(_openingTime, _closingTime)
        RefundableCrowdsale(_goal) public {
        require(_goal <= _cap);
        initialRate = _rate;
        minInvestmentInWei = _minInvestmentInWei;
        maxInvestmentInWei = _maxInvestmentInWei;
    }

    /**
     * @dev Perform the initial token distribution according to the Coinolix icocrowdsale rules
     * @param _teamAddress address address for the team tokens
     * @param _bountyPoolAddress address address for the prize pool
     * @param _advisorPoolAdddress address address for the reserve pool
     */
    function doInitialDistribution(
        address _teamAddress,
        address _bountyPoolAddress,
        address _advisorPoolAdddress) external onlyOwner {

        // Create locks for team and visor pools        
        teamWallet = new TokenTimelock(token, _teamAddress, closingTime.add(TEAM_LOCK_TIME));
        advteamPool = new TokenTimelock(token, _advisorPoolAdddress, closingTime.add(ADV_TEAM_LOCK_TIME));
        
        // Perform initial distribution
        uint256 tokenCap = CappedToken(token).cap();

        //private investor pool
        pvt_inv_Pool= new TokenPool(token, tokenCap.mul(PVT_INV_TOKENS).div(100));
        //airdrop,bounty and reffalPool
        reffalPool = new TokenPool(token, tokenCap.mul(REFF_TOKENS).div(100));

        // Distribute tokens to pools
        MintableToken(token).mint(teamWallet, tokenCap.mul(TEAM_TOKENS).div(100));
        MintableToken(token).mint(_bountyPoolAddress, tokenCap.mul(BOUNTY_TOKENS).div(100));
        MintableToken(token).mint(pvt_inv_Pool, tokenCap.mul(PVT_INV_TOKENS).div(100));
        MintableToken(token).mint(reffalPool, tokenCap.mul(REFF_TOKENS).div(100));
        MintableToken(token).mint(advteamPool, tokenCap.mul(ADV_TEAM_TOKENS).div(100));

        // Ensure that only sale tokens left
        assert(tokenCap.sub(token.totalSupply()) == tokenCap.mul(PUBLIC_TOKENS).div(100));
    }

    /**
    * @dev Update the current rate based on the scheme
    * 1st of Sep - 30rd of Sep -> 30% Bonus
    * 1st of Oct - 31st of Oct -> 20% Bonus
    * 1st of Nov - 30rd of Oct -> 10% Bonus
    * 1st of Dec - 31st of Dec -> 0% Bonus
    */
    function updateRate() external onlyOwner {
        uint256 i = stages.length;
        while (i-- > 0) {
            if (block.timestamp >= stages[i]) {
                rate = initialRate.add(initialRate.mul(bonuses[i]).div(100));
                emit CurrentRateChange(rate);
                break;
            }
        }
    }

        //update rate function by owner to keep stable rate in USD

    function updateInitialRate(uint256 _rate) external onlyOwner {
        initialRate = _rate;
        uint256 i = stages.length;
        while (i-- > 0) {
            if (block.timestamp >= stages[i]) {
                rate = initialRate.add(initialRate.mul(bonuses[i]).div(100));
                emit CurrentRateChange(rate);
                break;
            }
        }
    }

    /**
    * @dev Perform an airdrop from the airdrop pool to multiple beneficiaries
    * @param _beneficiaries address[] list of beneficiaries
    * @param _amount uint256 amount to airdrop
    */
    function airdropTokens(address[] _beneficiaries, uint256 _amount) external onlyOwner {
        PausableToken(token).unpause();
        reffalPool.allocateEqual(_beneficiaries, _amount);
        PausableToken(token).pause();
    }

    /**
    * @dev Transfer tokens to advisors and private investor from the  pool
    * @param _beneficiaries address[] list of beneficiaries
    * @param _amounts uint256[] amounts 
    */
    function allocatePVT_InvTokens(address[] _beneficiaries, uint256[] _amounts) external onlyOwner {
        PausableToken(token).unpause();
        pvt_inv_Pool.allocate(_beneficiaries, _amounts);
        PausableToken(token).pause();
    }

    /**
    * @dev Transfer the ownership of the token conctract 
    * @param _newOwner address the new owner of the token
    */
    function transferTokenOwnership(address _newOwner) onlyOwner public { 
        Ownable(token).transferOwnership(_newOwner);
    }

    /**
    * @dev Validate min and max amounts and other purchase conditions
    * @param _beneficiary address token purchaser
    * @param _weiAmount uint256 amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_weiAmount >= minInvestmentInWei);
        require(invested[_beneficiary].add(_weiAmount) <= maxInvestmentInWei);
        require(!paused);
    }

    /**
    * @dev Update invested amount
    * @param _beneficiary address receiving the tokens
    * @param _weiAmount uint256 value in wei involved in the purchase
    */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        super._updatePurchasingState(_beneficiary, _weiAmount);
        invested[_beneficiary] = invested[_beneficiary].add(_weiAmount);
    }

     /**
    * @dev Perform crowdsale finalization. 
    * - Finish token minting
    * - Enable transfers
    * - Give back the token ownership to the admin
    */
    function finalization() internal {
        CoinolixToken clxToken = CoinolixToken(token);
        clxToken.finishMinting();
        clxToken.unpause();
        super.finalization();
        transferTokenOwnership(owner);
        reffalPool.transferOwnership(owner);
        pvt_inv_Pool.transferOwnership(owner);
    }
}

// File: contracts\CoinolixPresale.sol

/**
 * @title Coinolix icoPresale Contract
 * @dev Coinolix icoPresale Contract
 * The contract is for the private sale of the Coinolix icotoken. It is:
 * - With a hard cap in ETH
 * - Limited in time (start/end date)
 * - Only for whitelisted participants to purchase tokens
 * - Tokens are minted on each purchase
 */
contract CoinolixPresale is 
    AirdropAndAffiliateCrowdsale,
    //MintedCrowdsale,
    CappedCrowdsale,
    TimedCrowdsale,
    WhitelistedCrowdsale {
    using SafeMath for uint256;

    // Min investment
            uint256 public presaleRate;
    uint256 public minInvestmentInWei;
        event CurrentRateChange(uint256 rate);

    // Investments
    mapping (address => uint256) internal invested;

    /**
     * @dev Contract constructor
     * @param _cap uint256 hard cap of the crowdsale
     * @param _openingTime uint256 crowdsale start date/time
     * @param _closingTime uint256 crowdsale end date/time
     * @param _rate uint256 initial rate CLX for 1 ETH
     * @param _wallet address address where the collected funds will be transferred
     * @param _token CoinolixToken our token
     */
    constructor(
        uint256 _cap, 
        uint256 _openingTime, 
        uint256 _closingTime, 
        uint256 _rate, 
        uint256 _minInvestmentInWei,
        address _wallet, 
        CoinolixToken _token,
        uint256 _valueAirDrop, 
        uint256 _referrerBonus1, 
        uint256 _referrerBonus2) 
        Crowdsale(_rate, _wallet, _token)
        AirdropAndAffiliateCrowdsale(_valueAirDrop, _referrerBonus1, _referrerBonus2)
        CappedCrowdsale(_cap)
        TimedCrowdsale(_openingTime, _closingTime) public {
        minInvestmentInWei = _minInvestmentInWei;
        presaleRate = _rate;

     }
        //update rate function by owner to keep stable rate in USD
      function updatepresaleRate(uint256 _rate) external onlyOwner {
    presaleRate = _rate;
    rate = presaleRate;
      }
  
    /**
    * @dev Validate min investment amount
    * @param _beneficiary address token purchaser
    * @param _weiAmount uint256 amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_weiAmount >= minInvestmentInWei);
    }

    /**
    * @dev Transfer the ownership of the token conctract 
    * @param _newOwner address the new owner of the token
    */
    function transferTokenOwnership(address _newOwner) onlyOwner public { 
        Ownable(token).transferOwnership(_newOwner);
    }
}