pragma solidity 0.4.24;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

// File: contracts/ParkadeCoin.sol

/**
    @title A dividend-paying ERC20 token,
    @dev Based on https://programtheblockchain.com/posts/2018/02/07/writing-a-simple-dividend-token-contract/
          and https://programtheblockchain.com/posts/2018/02/13/writing-a-robust-dividend-token-contract/
*/
contract ParkadeCoin is StandardToken, Ownable {
  using SafeMath for uint256;
  string public name = "Parkade Coin";
  string public symbol = "PRKC";
  uint8 public decimals = 18;


  /**
    There are a total of 400,000,000 tokens * 10^18 = 4 * 10^26 token units total
    A scaling value of 1e10 means that a deposit of 0.04Eth will increase scaledDividendPerToken by 1.
    A scaling value of 1e10 means that investors must wait until their scaledDividendBalances 
      is at least 1e10 before any withdrawals will credit their account.
  */
  uint256 public scaling = uint256(10) ** 10;

  // Remainder value (in Wei) resulting from deposits
  uint256 public scaledRemainder = 0;

  // Amount of wei credited to an account, but not yet withdrawn
  mapping(address => uint256) public scaledDividendBalances;
  // Cumulative amount of Wei credited to an account, since the contract&#39;s deployment
  mapping(address => uint256) public scaledDividendCreditedTo;
  // Cumulative amount of Wei that each token has been entitled to. Independent of withdrawals
  uint256 public scaledDividendPerToken = 0;

  /**
   * @dev Throws if transaction size is greater than the provided amount
   * This is used to mitigate the Ethereum short address attack as described in https://tinyurl.com/y8jjvh8d
   */
  modifier onlyPayloadSize(uint size) { 
    assert(msg.data.length >= size + 4);
    _;    
  }

  constructor() public {
    // Total INITAL SUPPLY of 400 million tokens 
    totalSupply_ = uint256(400000000) * (uint256(10) ** decimals);
    // Initially assign all tokens to the contract&#39;s creator.
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

  /**
  * @dev Update the dividend balances associated with an account
  * @param account The account address to update
  */
  function update(address account) 
  internal 
  {
    // Calculate the amount "owed" to the account, in units of (wei / token) S
    // Subtract Wei already credited to the account (per token) from the total Wei per token
    uint256 owed = scaledDividendPerToken.sub(scaledDividendCreditedTo[account]);

    // Update the dividends owed to the account (in Wei)
    // # Tokens * (# Wei / token) = # Wei
    scaledDividendBalances[account] = scaledDividendBalances[account].add(balances[account].mul(owed));
    // Update the total (wei / token) amount credited to the account
    scaledDividendCreditedTo[account] = scaledDividendPerToken;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Deposit(uint256 value);
  event Withdraw(uint256 paidOut, address indexed to);

  mapping(address => mapping(address => uint256)) public allowance;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) 
  public 
  onlyPayloadSize(2*32) 
  returns (bool success) 
  {
    require(balances[msg.sender] >= _value);

    // Added to transfer - update the dividend balances for both sender and receiver before transfer of tokens
    update(msg.sender);
    update(_to);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value)
  public
  onlyPayloadSize(3*32)
  returns (bool success)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    // Added to transferFrom - update the dividend balances for both sender and receiver before transfer of tokens
    update(_from);
    update(_to);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
  * @dev deposit Ether into the contract for dividend splitting
  */
  function deposit() 
  public 
  payable 
  onlyOwner 
  {
    // Scale the deposit and add the previous remainder
    uint256 available = (msg.value.mul(scaling)).add(scaledRemainder);

    // Compute amount of Wei per token
    scaledDividendPerToken = scaledDividendPerToken.add(available.div(totalSupply_));

    // Compute the new remainder
    scaledRemainder = available % totalSupply_;

    emit Deposit(msg.value);
  }

  /**
  * @dev withdraw dividends owed to an address
  */
  function withdraw() 
  public 
  {
    // Update the dividend amount associated with the account
    update(msg.sender);

    // Compute amount owed to the investor
    uint256 amount = scaledDividendBalances[msg.sender].div(scaling);
    // Put back any remainder
    scaledDividendBalances[msg.sender] %= scaling;

    // Send investor the Wei dividends
    msg.sender.transfer(amount);

    emit Withdraw(amount, msg.sender);
  }
}

// File: zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

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

  // How many token units a buyer gets per wei
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
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

// File: zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

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
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: zeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol

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

// File: zeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol

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
  function RefundVault(address _wallet) public {
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

// File: zeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol

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
  function RefundableCrowdsale(uint256 _goal) public {
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

// File: zeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol

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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: contracts/ParkadeCoinCrowdsale.sol

contract ParkadeCoinCrowdsale is TimedCrowdsale, RefundableCrowdsale, WhitelistedCrowdsale {
  
  // Discounted Rates. This is the amount of tokens (of the smallest possible denomination ie- 0.0000...0001PRKC) 
  // that a user will receive per Wei contributed to the sale.
  uint256 public firstBonusRate = 1838;
  uint256 public secondBonusRate = 1634;
  uint256 public normalRate = 1470;

  // Timestamp indicating when the crowdsale will open
  // Aug 18, 2018 12:00:00 AM GMT
  uint256 public openingTime = 1534550400;

  // Timestamps indicating when the first and second bonus will end.
  // Aug 25, 2018 11:59:59PM GMT
  uint256 public firstBonusEnds = 1535155200;

  // Sep 8, 2018 11:59:59PM GMT
  uint256 public secondBonusEnds = 1536364800;

  // Timestamp indicating when the crowdsale will close
  // Sep 28, 2018 11:59:59PM GMT
  uint256 public closingTime = 1538179199;

  // A separate Ethereum address which only has the right to add addresses to the whitelist
  // It is not permitted to access any other functionality, or to claim funds
  // This is required for easier administration of the ParkadeCoin Crowdsale
  address public executor;

  // Whether refunds are allowed or not (regardless of if the tokensale&#39;s soft cap has been met)
  // This functionality allows Parkade.IO to refund all investors at the end of the tokensale, even if
  //  the soft cap is not met.
  bool refundsAllowed;

  // Address where unsold tokens will be sent upon finalization of the sale
  address tokenTimelockContract;

  constructor
  (
    uint256 _goal,
    address _owner,
    address _executor,
    address _tokenTimelockContract,
    StandardToken _token
  )
  public 
  Crowdsale(normalRate, _owner, _token) 
  TimedCrowdsale(openingTime, closingTime)
  RefundableCrowdsale(_goal)
  {
    tokenTimelockContract = _tokenTimelockContract;
    executor = _executor;
    refundsAllowed = false;
  }

  /**
   * @dev Throws if called by any account other than the owner OR the executor.
   */
  modifier onlyOwnerOrExecutor() {
    require(msg.sender == owner || msg.sender == executor);
    _;
  }

  /**
  * @dev Public function that allows users to determine the current price (in wei) per token
  * @return Current price per token in wei
  */
  function currentRate() public view returns (uint256) {
    if (block.timestamp < firstBonusEnds)
    {
      return firstBonusRate;
    }
    else if (block.timestamp >= firstBonusEnds && block.timestamp < secondBonusEnds)
    {
      return secondBonusRate;
    }
    else 
    {
      return normalRate;
    }
  }

  /**
   * @dev Function to change the contract&#39;s executor, which can then add addresses to the whitelist
   * @param _newExec Address of new executor
   */
  function changeExecutor(address _newExec) external onlyOwnerOrExecutor {
    require(_newExec != address(0));
    executor = _newExec;
  }

  /**
  * @dev Overriden token value function. Provides functionality for discounted rates in the tokensale
  * @param _weiAmount Value in wei to be converted into tokens
  * @return Number of tokens that can be purchased with the specified _weiAmount
  */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(currentRate());
  }

  /**
  * @dev Adds single address to whitelist.
  * @param _beneficiary Address to be added to the whitelist
  */
  function addToWhitelist(address _beneficiary) external onlyOwnerOrExecutor {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwnerOrExecutor {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwnerOrExecutor {
    whitelist[_beneficiary] = false;
  }


  /**
  * @dev Validation of an incoming purchase. Overridden to ensure that the tokensale contains enough tokens to sell.
  * @param _beneficiary Address performing the token purchase
  * @param _weiAmount Value in wei involved in the purchase
  */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(token.balanceOf(this) > _getTokenAmount(_weiAmount));
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  /**
  * @dev Investors can claim refunds here if crowdsale is unsuccessful (softcap not reached or as specified by owner)
  */
  function claimRefund() public {
    // Cannot refund before tokensale is finished
    require(hasClosed());

    // If the goal has been reached, then double-check that refunds are allowed by owner&#39;s override
    if (goalReached())
    {
      require(refundsAllowed);
    }

    vault.refund(msg.sender);
  }

  /**
  * @dev Allow the tokensale owner to specify that refunds are allowed regardless of soft cap goal
  */
  function allowRefunds() external onlyOwner {
    require(!isFinalized);
    require(hasClosed());
    refundsAllowed = true;
    vault.enableRefunds();
  }

   /**
   * @dev vault finalization task, called when owner calls finalize()
   */
  function finalization() internal {
    require(!refundsAllowed);

    // Send all unsold tokens to the Timelock contract for future vesting
    token.transfer(tokenTimelockContract, token.balanceOf(this));
   
    super.finalization();
  }
}