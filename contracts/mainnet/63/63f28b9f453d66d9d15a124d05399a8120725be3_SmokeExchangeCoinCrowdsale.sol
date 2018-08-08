pragma solidity ^0.4.11;


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
    require(newOwner != address(0));      
    owner = newOwner;
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
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

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
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
    /*
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until 
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
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

contract SmokeExchangeCoin is StandardToken {
  string public name = "Smoke Exchange Token";
  string public symbol = "SMX";
  uint256 public decimals = 18;  
  address public ownerAddress;
    
  event Distribute(address indexed to, uint256 value);
  
  function SmokeExchangeCoin(uint256 _totalSupply, address _ownerAddress, address smxTeamAddress, uint256 allocCrowdsale, uint256 allocAdvBounties, uint256 allocTeam) {
    ownerAddress = _ownerAddress;
    totalSupply = _totalSupply;
    balances[ownerAddress] += allocCrowdsale;
    balances[ownerAddress] += allocAdvBounties;
    balances[smxTeamAddress] += allocTeam;
  }
  
  function distribute(address _to, uint256 _value) returns (bool) {
    require(balances[ownerAddress] >= _value);
    balances[ownerAddress] = balances[ownerAddress].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Distribute(_to, _value);
    return true;
  }
}

contract SmokeExchangeCoinCrowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  SmokeExchangeCoin public token;
  
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;
  uint256 public privateStartTime;
  uint256 public privateEndTime;

  // address where funds are collected
  address public wallet;

  // amount of raised money in wei
  uint256 public weiRaised;
  
  uint private constant DECIMALS = 1000000000000000000;
  //PRICES
  uint public constant TOTAL_SUPPLY = 28500000 * DECIMALS; //28.5 millions
  uint public constant BASIC_RATE = 300; //300 tokens per 1 eth
  uint public constant PRICE_STANDARD    = BASIC_RATE * DECIMALS; 
  uint public constant PRICE_PREBUY = PRICE_STANDARD * 150/100;
  uint public constant PRICE_STAGE_ONE   = PRICE_STANDARD * 125/100;
  uint public constant PRICE_STAGE_TWO   = PRICE_STANDARD * 115/100;
  uint public constant PRICE_STAGE_THREE   = PRICE_STANDARD * 107/100;
  uint public constant PRICE_STAGE_FOUR = PRICE_STANDARD;
  
  uint public constant PRICE_PREBUY_BONUS = PRICE_STANDARD * 165/100;
  uint public constant PRICE_STAGE_ONE_BONUS = PRICE_STANDARD * 145/100;
  uint public constant PRICE_STAGE_TWO_BONUS = PRICE_STANDARD * 125/100;
  uint public constant PRICE_STAGE_THREE_BONUS = PRICE_STANDARD * 115/100;
  uint public constant PRICE_STAGE_FOUR_BONUS = PRICE_STANDARD;
  
  //uint public constant PRICE_WHITELIST_BONUS = PRICE_STANDARD * 165/100;
  
  //TIME LIMITS
  uint public constant STAGE_ONE_TIME_END = 1 weeks;
  uint public constant STAGE_TWO_TIME_END = 2 weeks;
  uint public constant STAGE_THREE_TIME_END = 3 weeks;
  uint public constant STAGE_FOUR_TIME_END = 4 weeks;
  
  uint public constant ALLOC_CROWDSALE = TOTAL_SUPPLY * 75/100;
  uint public constant ALLOC_TEAM = TOTAL_SUPPLY * 15/100;  
  uint public constant ALLOC_ADVISORS_BOUNTIES = TOTAL_SUPPLY * 10/100;
  
  uint256 public smxSold = 0;
  
  address public ownerAddress;
  address public smxTeamAddress;
  
  //active = false/not active = true
  bool public halted;
  
  //in wei
  uint public cap; 
  
  //in wei, prebuy hardcap
  uint public privateCap;
  
  uint256 public bonusThresholdWei;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  /**
  * Modifier to run function only if contract is active (not halted)
  */
  modifier isNotHalted() {
    require(!halted);
    _;
  }
  
  /**
  * Constructor for SmokeExchageCoinCrowdsale
  * @param _privateStartTime start time for presale
  * @param _startTime start time for public sale
  * @param _ethWallet all incoming eth transfered here. Use multisig wallet
  * @param _privateWeiCap hard cap for presale
  * @param _weiCap hard cap in wei for the crowdsale
  * @param _bonusThresholdWei in wei. Minimum amount of wei required for bonus
  * @param _smxTeamAddress team address 
  */
  function SmokeExchangeCoinCrowdsale(uint256 _privateStartTime, uint256 _startTime, address _ethWallet, uint256 _privateWeiCap, uint256 _weiCap, uint256 _bonusThresholdWei, address _smxTeamAddress) {
    require(_privateStartTime >= now);
    require(_ethWallet != 0x0);    
    require(_smxTeamAddress != 0x0);    
    
    privateStartTime = _privateStartTime;
    //presale 10 days
    privateEndTime = privateStartTime + 10 days;    
    startTime = _startTime;
    
    //ICO start time after presale end
    require(_startTime >= privateEndTime);
    
    endTime = _startTime + STAGE_FOUR_TIME_END;
    
    wallet = _ethWallet;   
    smxTeamAddress = _smxTeamAddress;
    ownerAddress = msg.sender;
    
    cap = _weiCap;    
    privateCap = _privateWeiCap;
    bonusThresholdWei = _bonusThresholdWei;
                 
    token = new SmokeExchangeCoin(TOTAL_SUPPLY, ownerAddress, smxTeamAddress, ALLOC_CROWDSALE, ALLOC_ADVISORS_BOUNTIES, ALLOC_TEAM);
  }
  
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }
  
  // @return true if investors can buy at the moment
  function validPurchase() internal constant returns (bool) {
    bool privatePeriod = now >= privateStartTime && now < privateEndTime;
    bool withinPeriod = (now >= startTime && now <= endTime) || (privatePeriod);
    bool nonZeroPurchase = (msg.value != 0);
    //cap depends on stage.
    bool withinCap = privatePeriod ? (weiRaised.add(msg.value) <= privateCap) : (weiRaised.add(msg.value) <= cap);
    // check if there are smx token left
    bool smxAvailable = (ALLOC_CROWDSALE - smxSold > 0); 
    return withinPeriod && nonZeroPurchase && withinCap && smxAvailable;
    //return true;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    bool tokenSold = ALLOC_CROWDSALE - smxSold == 0;
    bool timeEnded = now > endTime;
    return timeEnded || capReached || tokenSold;
  }  
  
  /**
  * Main function for buying tokens
  * @param beneficiary purchased tokens go to this address
  */
  function buyTokens(address beneficiary) payable isNotHalted {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be distributed
    uint256 tokens = SafeMath.div(SafeMath.mul(weiAmount, getCurrentRate(weiAmount)), 1 ether);
    //require that there are more or equal tokens available for sell
    require(ALLOC_CROWDSALE - smxSold >= tokens);

    //update total weiRaised
    weiRaised = weiRaised.add(weiAmount);
    //updated total smxSold
    smxSold = smxSold.add(tokens);
    
    //add token to beneficiary and subtract from ownerAddress balance
    token.distribute(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    //forward eth received to walletEth
    forwardFunds();
  }
  
  // send ether to the fund collection wallet  
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
  /**
  * Get rate. Depends on current time
  *
  */
  function getCurrentRate(uint256 _weiAmount) constant returns (uint256) {  
      
      bool hasBonus = _weiAmount >= bonusThresholdWei;
  
      if (now < startTime) {
        return hasBonus ? PRICE_PREBUY_BONUS : PRICE_PREBUY;
      }
      uint delta = SafeMath.sub(now, startTime);

      //3+weeks from start
      if (delta > STAGE_THREE_TIME_END) {
        return hasBonus ? PRICE_STAGE_FOUR_BONUS : PRICE_STAGE_FOUR;
      }
      //2+weeks from start
      if (delta > STAGE_TWO_TIME_END) {
        return hasBonus ? PRICE_STAGE_THREE_BONUS : PRICE_STAGE_THREE;
      }
      //1+week from start
      if (delta > STAGE_ONE_TIME_END) {
        return hasBonus ? PRICE_STAGE_TWO_BONUS : PRICE_STAGE_TWO;
      }

      //less than 1 week from start
      return hasBonus ? PRICE_STAGE_ONE_BONUS : PRICE_STAGE_ONE;
  }
  
  /**
  * Enable/disable halted
  */
  function toggleHalt(bool _halted) onlyOwner {
    halted = _halted;
  }
}