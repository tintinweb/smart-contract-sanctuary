pragma solidity ^0.4.17;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract SafeBasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length >= size + 4);
     _;
  }
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
    require(_to != address(0));
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract SafeStandardToken is ERC20, SafeBasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    uint256 _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
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
contract LendConnect is SafeStandardToken{
  string public constant name = "LendConnect Token";
  string public constant symbol = "LCT";
  uint256 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 6500000 * (10 ** uint256(decimals));
  function LendConnect(address _ownerAddress) public {
    totalSupply = INITIAL_SUPPLY;
    balances[_ownerAddress] = INITIAL_SUPPLY;
  }
}
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  // The token being sold
  LendConnect public token;
  // start and end timestamps where investments are allowed (both inclusive
  
  uint256 public start_time = 1529408201;//11/22/2017 1511377200  @ 7:00pm (UTC) or 8:00pm (CET)
  uint256 public phase_1_Time = 1560965828;//11/27/2017 @ 7:00pm (UTC) or 8:00pm (CET)
  uint256 public phase_2_Time = 1592523442;//12/02/2017 @ 7:00pm (UTC) or 8:00pm (CET)
  uint256 public phase_3_Time = 1624081052;//12/07/2017 @ 7:00pm (UTC) or 8:00pm (CET)
  uint256 public phase_4_Time = 1655638661;//12/12/2017 @ 7:00pm (UTC) or 8:00pm (CET)
  uint256 public end_Time = 1687196270;//12/14/2017 @ 7:00pm (UTC) or 8:00pm (CET)
  uint256 public phase_1_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_2_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_3_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_4_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_5_remaining_tokens  = 1000000 * (10 ** uint256(18));
  mapping(address => uint256) phase_1_balances;
  mapping(address => uint256) phase_2_balances;
  mapping(address => uint256) phase_3_balances;
  mapping(address => uint256) phase_4_balances;
  mapping(address => uint256) phase_5_balances;
  
  
  // address where funds are collected
  address public wallet;
  // how many token units a buyer gets per wei
  uint256 public rate = 730;
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
  // rate change event
  event RateChanged(address indexed owner, uint256 old_rate, uint256 new_rate);
  
  // constructor
  function Crowdsale(address tokenContractAddress, address _walletAddress) public{
    wallet = _walletAddress;
    token = LendConnect(tokenContractAddress);
  }
  // fallback function can be used to buy tokens
  function () payable public{
    buyTokens(msg.sender);
  }
  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);
    // Check is there are enough token available for current phase and per person  
    require(isTokenAvailable(tokens));
    // update state
    weiRaised = weiRaised.add(weiAmount);
    token.transfer(beneficiary, tokens);
    //decrease phase supply and add user phase balance
    updatePhaseSupplyAndBalance(tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
  // check token availibility for current phase and max allowed token balance
  function isTokenAvailable(uint256 _tokens) internal constant returns (bool){
    uint256 current_time = now;
    uint256 total_expected_tokens = 0;
    if(current_time > start_time && current_time < phase_1_Time){
      total_expected_tokens = _tokens + phase_1_balances[msg.sender];
      return total_expected_tokens <= 10000 * (10 ** uint256(18)) &&
        _tokens <= phase_1_remaining_tokens;
    }
    else if(current_time > phase_1_Time && current_time < phase_2_Time){
      total_expected_tokens = _tokens + phase_2_balances[msg.sender];
      return total_expected_tokens <= 2000 * (10 ** uint256(18)) &&
        _tokens <= phase_2_remaining_tokens;
    }
    else if(current_time > phase_2_Time && current_time < phase_3_Time){
      total_expected_tokens = _tokens + phase_3_balances[msg.sender];
      return total_expected_tokens <= 2000 * (10 ** uint256(18)) &&
        _tokens <= phase_3_remaining_tokens;
    }
    else if(current_time > phase_3_Time && current_time < phase_4_Time){
      total_expected_tokens = _tokens + phase_4_balances[msg.sender];
      return total_expected_tokens <= 3500 * (10 ** uint256(18)) &&
        _tokens <= phase_4_remaining_tokens;
    }
    else{
      total_expected_tokens = _tokens + phase_5_balances[msg.sender];
      return total_expected_tokens <= 3500 * (10 ** uint256(18)) &&
        _tokens <= phase_5_remaining_tokens;
    }
  }
  // decrease phase supply and add user phase balance
  function updatePhaseSupplyAndBalance(uint256 _tokens) internal {
    uint256 current_time = now;
    if(current_time > start_time && current_time < phase_1_Time){
      phase_1_balances[msg.sender] = phase_1_balances[msg.sender].add(_tokens);
      phase_1_remaining_tokens = phase_1_remaining_tokens - _tokens;
    }
    else if(current_time > phase_1_Time && current_time < phase_2_Time){
      phase_2_balances[msg.sender] = phase_2_balances[msg.sender].add(_tokens);
      phase_2_remaining_tokens = phase_2_remaining_tokens - _tokens;
    }
    else if(current_time > phase_2_Time && current_time < phase_3_Time){
      phase_3_balances[msg.sender] = phase_3_balances[msg.sender].add(_tokens);
      phase_3_remaining_tokens = phase_3_remaining_tokens - _tokens;
    }
    else if(current_time > phase_3_Time && current_time < phase_4_Time){
      phase_4_balances[msg.sender] = phase_4_balances[msg.sender].add(_tokens);
      phase_4_remaining_tokens = phase_4_remaining_tokens - _tokens;
    }
    else{
      phase_5_balances[msg.sender] = phase_5_balances[msg.sender].add(_tokens);
      phase_5_remaining_tokens = phase_5_remaining_tokens - _tokens;
    }
  }
  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= start_time && now <= end_Time;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > end_Time;
  }
  // function to transfer token back to owner
  function transferBack(uint256 tokens) onlyOwner public returns (bool){
    token.transfer(owner, tokens);
    return true;
  }
  // function to change rate
  function changeRate(uint256 _rate) onlyOwner public returns (bool){
    RateChanged(msg.sender, rate, _rate);
    rate = _rate;
    return true;
  }
  function tokenBalance() constant public returns (uint256){
    return token.balanceOf(this);
  }
}