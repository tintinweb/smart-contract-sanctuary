pragma solidity 0.4.18;

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/StandardToken.sol

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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

// File: zeppelin-solidity/contracts/token/PausableToken.sol

/**
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

// File: contracts/EthixToken.sol

contract EthixToken is PausableToken {
  string public constant name = "EthixToken";
  string public constant symbol = "ETHIX";
  uint8 public constant decimals = 18;

  //TODO set this
  uint256 public constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));
  uint256 public totalSupply;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  function EthixToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[owner] = totalSupply;
    Transfer(0x0, owner, INITIAL_SUPPLY);
  }

}

// File: contracts/crowdsale/CompositeCrowdsale.sol

/**
 * @title CompositeCrowdsale
 * @dev CompositeCrowdsale is a base contract for managing a token crowdsale.
 * Contrary to a classic crowdsale, it favours composition over inheritance.
 *
 * Crowdsale behaviour can be modified by specifying TokenDistributionStrategy
 * which is a dedicated smart contract that delegates all of the logic managing
 * token distribution.
 *
 */
contract CompositeCrowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  TokenDistributionStrategy public tokenDistribution;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

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


  function CompositeCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, TokenDistributionStrategy _tokenDistribution) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != 0x0);
    require(address(_tokenDistribution) != address(0));

    startTime = _startTime;
    endTime = _endTime;

    tokenDistribution = _tokenDistribution;
    tokenDistribution.initializeDistribution(this);

    wallet = _wallet;
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = tokenDistribution.calculateTokenAmount(weiAmount, beneficiary);
    // update state
    weiRaised = weiRaised.add(weiAmount);

    tokenDistribution.distributeTokens(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

// File: contracts/crowdsale/TokenDistributionStrategy.sol

/**
 * @title TokenDistributionStrategy
 * @dev Base abstract contract defining methods that control token distribution
 */
contract TokenDistributionStrategy {
  using SafeMath for uint256;

  CompositeCrowdsale crowdsale;
  uint256 rate;

  modifier onlyCrowdsale() {
    require(msg.sender == address(crowdsale));
    _;
  }

  function TokenDistributionStrategy(uint256 _rate) {
    require(_rate > 0);
    rate = _rate;
  }

  function initializeDistribution(CompositeCrowdsale _crowdsale) {
    require(crowdsale == address(0));
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

  function returnUnsoldTokens(address _wallet) onlyCrowdsale {
    
  }

  function distributeTokens(address beneficiary, uint amount);

  function calculateTokenAmount(uint256 _weiAmount, address beneficiary) view returns (uint256 amount);

  function getToken() view returns(ERC20);

  

}

// File: contracts/crowdsale/FixedPoolWithBonusTokenDistributionStrategy.sol

/**
 * @title FixedPoolWithBonusTokenDistributionStrategy 
 * @dev Strategy that distributes a fixed number of tokens among the contributors,
 * with a percentage depending in when the contribution is made, defined by periods.
 * It's done in two steps. First, it registers all of the contributions while the sale is active.
 * After the crowdsale has ended the contract compensate buyers proportionally to their contributions.
 * This class is abstract, the intervals have to be defined by subclassing
 */
contract FixedPoolWithBonusTokenDistributionStrategy is TokenDistributionStrategy {
  using SafeMath for uint256;
  uint256 constant MAX_DISCOUNT = 100;

  // Definition of the interval when the bonus is applicable
  struct BonusInterval {
    //end timestamp
    uint256 endPeriod;
    // percentage
    uint256 bonus;
  }
  BonusInterval[] bonusIntervals;
  bool intervalsConfigured = false;

  // The token being sold
  ERC20 token;
  mapping(address => uint256) contributions;
  uint256 totalContributed;
  //mapping(uint256 => BonusInterval) bonusIntervals;

  function FixedPoolWithBonusTokenDistributionStrategy(ERC20 _token, uint256 _rate)
           TokenDistributionStrategy(_rate) public
  {
    token = _token;
  }


  // First period will go from crowdsale.start_date to bonusIntervals[0].end
  // Next intervals have to end after the previous ones
  // Last interval must end when the crowdsale ends
  // All intervals must have a positive bonus (penalizations are not contemplated)
  modifier validateIntervals {
    _;
    require(intervalsConfigured == false);
    intervalsConfigured = true;
    require(bonusIntervals.length > 0);
    for(uint i = 0; i < bonusIntervals.length; ++i) {
      require(bonusIntervals[i].bonus <= MAX_DISCOUNT);
      require(bonusIntervals[i].bonus >= 0);
      require(crowdsale.startTime() < bonusIntervals[i].endPeriod);
      require(bonusIntervals[i].endPeriod <= crowdsale.endTime());
      if (i != 0) {
        require(bonusIntervals[i-1].endPeriod < bonusIntervals[i].endPeriod);
      }
    }
  }

  // Init intervals
  function initIntervals() validateIntervals {
  }

  function calculateTokenAmount(uint256 _weiAmount, address beneficiary) view returns (uint256 tokens) {
    // calculate bonus in function of the time
    for (uint i = 0; i < bonusIntervals.length; i++) {
      if (now <= bonusIntervals[i].endPeriod) {
        // calculate token amount to be created
        tokens = _weiAmount.mul(rate);
        // OP : tokens + ((tokens * bonusIntervals[i].bonus) / 100)
        // BE CAREFULLY with decimals
        return tokens.add(tokens.mul(bonusIntervals[i].bonus).div(100));
      }
    }
    return _weiAmount.mul(rate);
  }

  function distributeTokens(address _beneficiary, uint256 _tokenAmount) onlyCrowdsale {
    contributions[_beneficiary] = contributions[_beneficiary].add(_tokenAmount);
    totalContributed = totalContributed.add(_tokenAmount);
    require(totalContributed <= token.balanceOf(this));
  }

  function compensate(address _beneficiary) {
    require(crowdsale.hasEnded());
    if (token.transfer(_beneficiary, contributions[_beneficiary])) {
      contributions[_beneficiary] = 0;
    }
  }

  function getToken() view returns(ERC20) {
    return token;
  }

  function getIntervals() view returns (uint256[] _endPeriods, uint256[] _bonuss) {
    uint256[] memory endPeriods = new uint256[](bonusIntervals.length);
    uint256[] memory bonuss = new uint256[](bonusIntervals.length);
    for (uint256 i=0; i<bonusIntervals.length; i++) {
      endPeriods[i] = bonusIntervals[i].endPeriod;
      bonuss[i] = bonusIntervals[i].bonus;
    }
    return (endPeriods, bonuss);
  }

}

// File: contracts/crowdsale/VestedTokenDistributionStrategy.sol

/**
 * @title VestedTokenDistributionStrategy
 * @dev Strategy that distributes a fixed number of tokens among the contributors.
 * It's done in two steps. First, it registers all of the contributions while the sale is active.
 * After the crowdsale has ended the contract compensate buyers proportionally to their contributions.
 */
contract VestedTokenDistributionStrategy is Ownable, FixedPoolWithBonusTokenDistributionStrategy {


  event Released(address indexed beneficiary, uint256 indexed amount);

  //Time after which is allowed to compensates
  uint256 public vestingStart;
  bool public vestingConfigured = false;
  uint256 public vestingDuration;

  mapping (address => uint256) public released;

  modifier vestingPeriodStarted {
    require(crowdsale.hasEnded());
    require(vestingConfigured == true);
    require(now > vestingStart);
    _;
  }

  function VestedTokenDistributionStrategy(ERC20 _token, uint256 _rate)
            Ownable()
            FixedPoolWithBonusTokenDistributionStrategy(_token, _rate) {

  }

  /**
   * set the parameters for the compensation. Required to call before compensation
   * @dev WARNING, ONE TIME OPERATION
   * @param _vestingStart we start allowing  the return of tokens after this
   * @param _vestingDuration percent each day (1 is 1% each day, 2 is % each 2 days, max 100)
   */
  function configureVesting(uint256 _vestingStart, uint256 _vestingDuration) onlyOwner {
    require(vestingConfigured == false);
    require(_vestingStart > crowdsale.endTime());
    require(_vestingDuration > 0);
    vestingStart = _vestingStart;
    vestingDuration = _vestingDuration;
    vestingConfigured = true;
  }

  /**
   * Will transfer the tokens vested until now to the beneficiary, if the vestingPeriodStarted
   * and there is an amount left to transfer
   * @param  _beneficiary crowdsale contributor
   */
   function compensate(address _beneficiary) public vestingPeriodStarted {
     require(msg.sender == owner || msg.sender == _beneficiary);
     uint256 unreleased = releasableAmount(_beneficiary);

     require(unreleased > 0);

     released[_beneficiary] = released[_beneficiary].add(unreleased);

     require(token.transfer(_beneficiary, unreleased));
     Released(_beneficiary,unreleased);

   }

  /**
   * Calculates how many tokens the beneficiary should get taking in account already
   * released
   * @param  _beneficiary the contributor
   * @return token number
   */
   function releasableAmount(address _beneficiary) public view returns (uint256) {
     return vestedAmount(_beneficiary).sub(released[_beneficiary]);
   }

  /**
   * Calculates how many tokens the beneficiary have vested
   * vested = how many does she have according to the time
   * @param  _beneficiary address of the contributor that needs the tokens
   * @return amount of tokens
   */
  function vestedAmount(address _beneficiary) public view returns (uint256) {
    uint256 totalBalance = contributions[_beneficiary];
    //Duration("after",vestingStart.add(vestingDuration));
    if (now < vestingStart || vestingConfigured == false) {
      return 0;
    } else if (now >= vestingStart.add(vestingDuration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(vestingStart)).div(vestingDuration);
    }
  }

  function getReleased(address _beneficiary) public view returns (uint256) {
    return released[_beneficiary];
  }

}

// File: contracts/crowdsale/WhitelistedDistributionStrategy.sol

/**
 * @title WhitelistedDistributionStrategy
 * @dev This is an extension to add whitelist to a token distributionStrategy
 *
 */
contract WhitelistedDistributionStrategy is Ownable, VestedTokenDistributionStrategy {
    uint256 public constant maximumBidAllowed = 500 ether;

    uint256 rate_for_investor;
    mapping(address=>uint) public registeredAmount;

    event RegistrationStatusChanged(address target, bool isRegistered);

    function WhitelistedDistributionStrategy(ERC20 _token, uint256 _rate, uint256 _whitelisted_rate)
              VestedTokenDistributionStrategy(_token,_rate){
        rate_for_investor = _whitelisted_rate;
    }

    /**
     * @dev Changes registration status of an address for participation.
     * @param target Address that will be registered/deregistered.
     * @param amount the amount of eht to invest for a investor bonus.
     */
    function changeRegistrationStatus(address target, uint256 amount)
        public
        onlyOwner
    {
        require(amount <= maximumBidAllowed);
        registeredAmount[target] = amount;
        if (amount > 0){
            RegistrationStatusChanged(target, true);
        }else{
            RegistrationStatusChanged(target, false);
        }
    }

    /**
     * @dev Changes registration statuses of addresses for participation.
     * @param targets Addresses that will be registered/deregistered.
     * @param amounts the list of amounts of eth for every investor to invest for a investor bonus.
     */
    function changeRegistrationStatuses(address[] targets, uint256[] amounts)
        public
        onlyOwner
    {
        require(targets.length == amounts.length);
        for (uint i = 0; i < targets.length; i++) {
            changeRegistrationStatus(targets[i], amounts[i]);
        }
    }

    /**
     * @dev overriding calculateTokenAmount for whilelist investors
     * @return bonus rate if it applies for the investor,
     * otherwise, return token amount according to super class
     */

    function calculateTokenAmount(uint256 _weiAmount, address beneficiary) view returns (uint256 tokens) {
        if (_weiAmount >= registeredAmount[beneficiary] && registeredAmount[beneficiary] > 0 ){
            tokens = _weiAmount.mul(rate_for_investor);
        } else{
            tokens = super.calculateTokenAmount(_weiAmount, beneficiary);
        }
    }
}

// File: contracts/EthicHubTokenDistributionStrategy.sol

/**
 * @title EthicHubTokenDistributionStrategy
 * @dev Strategy that distributes a fixed number of tokens among the contributors,
 * with a percentage deppending in when the contribution is made, defined by periods.
 * It's done in two steps. First, it registers all of the contributions while the sale is active.
 * After the crowdsale has ended the contract compensate buyers proportionally to their contributions.
 * Contributors registered to the whitelist will have better rates
 */
contract EthicHubTokenDistributionStrategy is Ownable, WhitelistedDistributionStrategy {
  
  event UnsoldTokensReturned(address indexed destination, uint256 amount);


  function EthicHubTokenDistributionStrategy(EthixToken _token, uint256 _rate, uint256 _rateForWhitelisted)
           WhitelistedDistributionStrategy(_token, _rate, _rateForWhitelisted)
           public
  {

  }


  // Init intervals
  function initIntervals() onlyOwner validateIntervals  {

    //For extra security, we check the owner of the crowdsale is the same of the owner of the distribution
    require(owner == crowdsale.owner());

    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 1 days,10));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 2 days,8));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 3 days,6));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 4 days,4));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 5 days,2));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 6 days,0));
  }

  function returnUnsoldTokens(address _wallet) onlyCrowdsale {
    require(crowdsale.endTime() <= now);
    if (token.balanceOf(this) == 0) {
      UnsoldTokensReturned(_wallet,0);
      return;
    }
    
    uint256 balance = token.balanceOf(this).sub(totalContributed);
    require(balance > 0);

    if(token.transfer(_wallet, balance)) {
      UnsoldTokensReturned(_wallet, balance);
    }
    
  }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}