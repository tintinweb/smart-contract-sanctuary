pragma solidity ^0.4.23;

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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

  uint256 public totalSupply_;
  
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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

  mapping (address => mapping (address => uint256)) public allowed;


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

/**
 * @title CoinnupCrowdsaleToken
 * @dev ERC20-compliant Token that can be minted.
 */
contract CoinnupToken is StandardToken, Ownable {
  using SafeMath for uint256;

  string public constant name = "Coinnup Coin"; // solium-disable-line uppercase
  string public constant symbol = "PMZ"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  /// @dev store how much in eth users invested to give them a refund in case refund happens
  mapping ( address => uint256 ) public investments;
  /// @dev to have how much one user bought tokens
  mapping ( address => uint256 ) public tokensBought;

  /// @dev event when someone bought tokens by ETH
  event investmentReceived(
    address sender,
    uint weis,
    uint total
  );

  uint256 public maxSupply = 298500000000000000000000000;
  uint256 public allowedToBeSold = 104475000000000000000000000;
  address public founder = address( 0x3abb86C7C1a533Eb0464E9BD870FD1b501C7A8A8 );
  uint256 public rate = 2800;
  uint256 public bonus = 30;
  uint256 public softCap = 1850000000000000000000;

  uint256 public _sold; //eth sold via payable function
  /// @dev in this var we store eth when someone bought tokens
  /// not sending it to smart contract but buying it privately
  uint256 public _soldOutside; //wei sold not via SC
  uint256 public _soldOutsidePMZ; //PMZ tokens sold not via SC

  bool public isPaused;

  struct Round {
    uint256 openingTime;
    uint256 closingTime;
    uint256 allocatedCoins;
    uint256 minPurchase;
    uint256 maxPurchase;
    uint256 soldCoins;
  }

  Round[] public rounds;

  /** @dev Token cunstructor
    */
  constructor () public {
    require(maxSupply > 0);
    require(founder != address(0));
    require(rate > 0);
    require(bonus >= 0 && bonus <= 100); // in percentage
    require(allowedToBeSold > 0 && allowedToBeSold < maxSupply);

    require(softCap > 0);

    for (uint8 i = 0; i < 6; i++) {
      rounds.push( Round(0, 0, 0, 0, 0, 0) );
    }

    // mint tokens which initially belongs to founder
    uint256 _forFounder = maxSupply.sub(allowedToBeSold);
    mint(founder, _forFounder);

    // waiting for admin to set round dates
    // and to unpause by admin
    triggerICOState(true);
  }

  /// @dev in payable we shold keep only forwarding call
  function () public onlyWhileOpen isNotPaused payable {
    require(_buyTokens(msg.sender, msg.value));
  }

  /**
   * @dev gets `_sender` and `_value` as input and sells tokens with bonus
   * throws if not enough tokens after calculation
   * @return isSold bool whether tokens bought
   */
  function _buyTokens(address _sender, uint256 _value) internal isNotPaused returns (bool) {
    uint256 amount = _getTokenAmount(_value, bonus);
    uint256 amount_without_bonus = _getTokenAmount(_value, 0);
    uint8 _currentRound = _getCurrentRound(now);

    require(rounds[_currentRound].allocatedCoins >= amount + rounds[_currentRound].soldCoins);
    require(totalSupply_ + amount <= maxSupply); // if we have enough tokens to be minted

    require(
      rounds[_currentRound].minPurchase <= amount_without_bonus &&
      rounds[_currentRound].maxPurchase >= amount_without_bonus
    );

    _sold = _sold.add(_value); // in wei
    investments[_sender] = investments[_sender].add(_value); // in wei

    // minting tokens for investores
    // after we recorded how much he sent ether and other params
    mint(_sender, amount);
    rounds[_currentRound].soldCoins = rounds[_currentRound].soldCoins.add(amount);
    tokensBought[_sender] = tokensBought[_sender].add(amount);

    emit investmentReceived(
      _sender,
      _value,
      amount_without_bonus
    );

    return true;
  }

  /// @dev system can mint tokens for users if they sent funds to BTC, LTC, etc wallets we allow
  function mintForInvestor(address _to, uint256 _tokens) public onlyOwner onlyWhileOpen {
    uint8 _round = _getCurrentRound(now);

    require(_round >= 0 && _round <= 5);
    require(_to != address(0)); // handling incorrect values from system in addresses
    require(_tokens >= 0); // handling incorrect values from system in tokens calculation
    require(rounds[_currentRound].allocatedCoins >= _tokens + rounds[_currentRound].soldCoins);
    require(maxSupply >= _tokens.add(totalSupply_));
    uint8 _currentRound = _getCurrentRound(now);

    // minting tokens for investors
    mint(_to, _tokens); // _tokens in wei
    rounds[_currentRound].soldCoins = rounds[_currentRound].soldCoins.add(_tokens);
    tokensBought[_to] = tokensBought[_to].add(_tokens); // tokens in wei

    uint256 _soldInETH = _tokens.div( rate );
    _sold = _sold.add(_tokens); // in wei
    _soldOutside = _soldOutside.add(_soldInETH); // eth
    _soldOutsidePMZ = _soldOutsidePMZ.add(_tokens); // in PMZ
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) internal {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(address(this), _to, _amount);
  }

    /**
   * @dev The way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @param _bonus Bonus in percents
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount, uint _bonus) internal view returns (uint256) {
    uint256 _coins_in_wei = rate.mul(_weiAmount);
    uint256 _bonus_value_in_wei = 0;
    uint256 bonusValue = 0;

    _bonus_value_in_wei = (_coins_in_wei.mul(_bonus)).div(100);
    bonusValue = _bonus_value_in_wei;

    uint256 coins = _coins_in_wei;
    uint256 total = coins.add(bonusValue);

    return total;
  }

  /**
   * @dev sets a rate for ico rounds
   * @param _rate Rate for token
   */
  function setRate(uint256 _rate) public {
    require(msg.sender == owner);
    require(_rate > 0);

    rate = _rate;
  }

  /// @dev get total coins sold per current round
  function soldPerCurrentRound() public view returns (uint256) {
    return rounds[_getCurrentRound(now)].soldCoins;
  }

  /// @dev pause and unpause an ICO, only sender allowed to
  function triggerICOState(bool state) public onlyOwner {
    isPaused = state;
  }

  /**
   * @dev changes current bonus rate
   * @param _bonus Bonus to change
   * @return bool - Changed or not
   */
  function setBonus(uint256 _bonus) onlyOwner public {
    require(_bonus >= 0 && _bonus <= 100); //%
    bonus = _bonus;
  }

  /// @dev gets number of current round
  function _getCurrentRound(uint256 _time) public view returns (uint8) {
    for (uint8 i = 0; i < 6; i++) {
      if (rounds[i].openingTime < _time && rounds[i].closingTime > _time) {
        return i;
      }
    }

    return 100; // if using 6 in 5 length array it will throw
  }

  function setRoundParams(
    uint8 _round,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _maxPurchase,
    uint256 _minPurchase,
    uint256 _allocatedCoins
  ) public onlyOwner {
    rounds[_round].openingTime = _openingTime;
    rounds[_round].closingTime = _closingTime;
    rounds[_round].maxPurchase = _maxPurchase;
    rounds[_round].minPurchase = _minPurchase;
    rounds[_round].allocatedCoins = _allocatedCoins;
  }

  /**
   * @dev withdrawing funds to founder&#39;s wallet
   * @return bool Whether success or not
   */
  function withdraw() public {
    // only founder is able to withdraw funds
    require(msg.sender == founder);
    founder.transfer(address(this).balance);
  }

  /**
   * @dev Claims for refund if ICO finished and soft cap not reached
   */
  function refund() public whenICOFinished capNotReached {
    require(investments[msg.sender] > 0);
    msg.sender.transfer(investments[msg.sender]);
    investments[msg.sender] = 0;
  }

  modifier onlyWhileOpen {
    uint8 _round = _getCurrentRound(now);
    require(_round >= 0 && _round <= 5); // we have 6 rounds, other values are invalid
    _;
  }

  /// @dev when ico finishes we can perform other actions
  modifier whenICOFinished {
    uint8 _round = _getCurrentRound(now);
    require(_round < 0 || _round > 5); // if we do not get current valid round number ICO finished
    _;
  }

  /// @dev _sold in weis, softCap in weis
  modifier capNotReached {
    require(softCap > _sold);
    _;
  }

  /// @dev if isPaused true then investments cannot be accepted
  modifier isNotPaused {
    require(!isPaused);
    _;
  }

}