pragma solidity ^0.4.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address buyer) onlyOwner payable {
    require(state == State.Active);
    deposited[buyer] = deposited[buyer].add(msg.value);
  }

  function close() onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address buyer) {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[buyer];
    deposited[buyer] = 0;
    buyer.transfer(depositedValue);
    Refunded(buyer, depositedValue);
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title CirclesTokenOffering
 * @dev Modified from OpenZeppelin&#39;s Crowdsale.sol, RefundableCrowdsale.sol,
 * CappedCrowdsale.sol, and FinalizableCrowdsale.sol
 * Uses PausableToken rather than MintableToken.
 *
 * Requires that 350m tokens (entire supply minus team&#39;s portion) be deposited.
 */
contract CirclesTokenOffering is Ownable {
  using SafeMath for uint256;

  // Token allocations
  mapping (address => uint256) allocations;

  // manual early close flag
  bool public isFinalized = false;

  // cap for crowdsale in wei
  uint256 public cap;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;

  // The token being sold
  StandardToken public token;

  // start and end timestamps where contributions are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // address to hold team / advisor tokens until vesting complete
  address public safe;

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

  /**
   * event for token redemption logging
   * @param beneficiary who got the tokens
   * @param amount amount of tokens redeemed
   */
  event TokenRedeem(address indexed beneficiary, uint256 amount);

  // termination early or otherwise
  event Finalized();

  function CirclesTokenOffering(address _token, uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, address _wallet) {

    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_cap > 0);
    require(_wallet != 0x0);
    require(_goal > 0);

    vault = new RefundVault(_wallet);
    goal = _goal;
    token = StandardToken(_token);
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    cap = _cap;
    goal = _goal;
    wallet = _wallet;
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  // caution: tokens must be redeemed by beneficiary address
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    // calculate token amount to be purchased
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    // allocate tokens to purchaser
    allocations[beneficiary] = tokens;

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // redeem tokens
  function claimTokens() {
    require(isFinalized);
    require(goalReached());

    // confirm there are tokens remaining
    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    // send tokens to purchaser
    uint256 tokens = allocations[msg.sender];
    allocations[msg.sender] = 0;
    require(token.transfer(msg.sender, tokens));

    TokenRedeem(msg.sender, tokens);
  }

  // redeem tokens (admin fallback)
  function sendTokens(address beneficiary) onlyOwner {
    require(isFinalized);
    require(goalReached());

    // confirm there are tokens remaining
    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    // send tokens to purchaser
    uint256 tokens = allocations[beneficiary];
    allocations[beneficiary] = 0;
    require(token.transfer(beneficiary, tokens));

    TokenRedeem(beneficiary, tokens);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

  // @return true if crowdsale event has ended or cap reached
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    bool passedEndTime = now > endTime;
    return passedEndTime || capReached;
  }

  // if crowdsale is unsuccessful, contributors can claim refunds here
  function claimRefund() {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  function goalReached() public constant returns (bool) {
   return weiRaised >= goal;
  }

    // @dev does not require that crowdsale `hasEnded()` to leave safegaurd
  // in place if ETH rises in price too much during crowdsale.
  // Allows team to close early if cap is exceeded in USD in this event.
  function finalize() onlyOwner {
    require(!isFinalized);
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    Finalized();

    isFinalized = true;
  }

  function unsoldCleanUp() onlyOwner { 
    uint256 amount = token.balanceOf(this);
    if(amount > 0) {
      require(token.transfer(msg.sender, amount));
    } 

  }

}