pragma solidity 0.4.17;


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



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @titleVantageICO
 * @dev VantageCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them XVT tokens based
 * on a XVT token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
















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
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


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





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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

/**
 * @title Vantage Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;

  // The token being sold
  MintableToken internal token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 private privateStartTime;
  uint256 private privateEndTime;
  uint256 private publicStartTime;
  uint256 private publicEndTime;
  
  // Bonuses will be calculated here of ICO and Pre-ICO (both inclusive)
  uint256 private privateICOBonus;
  // wallet address where funds will be saved
  address internal wallet;
  // base-rate of a particular Vantage token
  uint256 public rate;
  // amount of raised money in wei
  uint256 internal weiRaised; // internal 
  // total supply of token 
  uint256 private totalSupply = SafeMath.mul(200000000, 1 ether);
  // private supply of token 
  uint256 private privateSupply = SafeMath.mul(40000000, 1 ether);
  // public supply of token 
  uint256 private publicSupply = SafeMath.mul(70000000, 1 ether);
  // Team supply of token 
  uint256 private teamAdvisorSupply = SafeMath.mul(SafeMath.div(totalSupply,100),25);
  // reserve supply of token 
  uint256 private reserveSupply = SafeMath.mul(SafeMath.div(totalSupply,100),20);
  // Time lock or vested period of token for team allocated token
  uint256 public teamTimeLock;
  // Time lock or vested period of token for reserve allocated token
  uint256 public reserveTimeLock;

  /**
   *  @bool checkBurnTokens
   *  @bool grantTeamAdvisorSupply
   *  @bool grantAdvisorSupply     
  */
  bool public checkBurnTokens;
  bool public grantTeamAdvisorSupply;
  bool public grantReserveSupply;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  event TokenLeft(uint256 tokensLeft);

  // Vantage Crowdsale constructor
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    // Vantage token creation 
    token = createTokenContract();

    // Pre-ICO start Time
    privateStartTime = _startTime; // 27 march 2018 8 pm UTC
    
    // Pre-ICO end time
     privateEndTime = 1525219199; // 1st May 2018 11:59:pm UTC 1525219199

    // // ICO start Time
     publicStartTime = 1530403200;  // 1 july 2018 12 am UTC

    // ICO end Time
    publicEndTime = _endTime;  // 20th june 2018 13:pm UTC

    // Base Rate of XVR Token
    rate = _rate;

    // Multi-sig wallet where funds will be saved
    wallet = _wallet;

    /** Calculations of Bonuses in ICO or Pre-ICO */
    privateICOBonus = SafeMath.div(SafeMath.mul(rate,50),100);

    /** Vested Period calculations for team and advisors*/
    teamTimeLock = SafeMath.add(publicEndTime, 3 minutes);
    reserveTimeLock = SafeMath.add(publicEndTime, 3 minutes);

    checkBurnTokens = false;
    grantTeamAdvisorSupply = false;
    grantReserveSupply = false;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);    
  }

  // High level token purchase function
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    // minimum investment should be 0.05 ETH
    require(weiAmount >= 50000000000000000); //50000000000000000
    
    uint256 accessTime = now;
    uint256 tokens = 0;

  // calculating the crowdsale and Pre-crowdsale bonuses on the basis of timing
   require(!((accessTime > privateEndTime) && (accessTime < publicStartTime)));

    if ((accessTime >= privateStartTime) && (accessTime < privateEndTime)) {
        require(privateSupply > 0);

        tokens = SafeMath.add(tokens, weiAmount.mul(privateICOBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        
    } else if ((accessTime >= publicStartTime) && (accessTime <= publicEndTime)) {
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
      } 
    // update state
    weiRaised = weiRaised.add(weiAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    // funds are forwarding
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= privateStartTime && now <= publicEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
      return now > publicEndTime;
  }

  function burnToken() onlyOwner  public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    totalSupply = SafeMath.sub(totalSupply, publicSupply);
    totalSupply = SafeMath.sub(totalSupply,privateSupply);
    privateSupply = 0;
    publicSupply = 0;
    checkBurnTokens = true;
    return true;
  }

  function grantReserveToken(address beneficiary) onlyOwner  public {
    require((!grantReserveSupply) && (now > reserveTimeLock));
    grantReserveSupply = true;
    token.mint(beneficiary,reserveSupply);
    reserveSupply = 0;  
  }

  function grantTeamAdvisorToken(address beneficiary) onlyOwner public {
    require((!grantTeamAdvisorSupply) && (now > teamTimeLock));
    grantTeamAdvisorSupply = true;
    token.mint(beneficiary,teamAdvisorSupply);
    teamAdvisorSupply = 0;
    
  }

 function privateSaleTransfer(address[] recipients, uint256[] values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(privateSupply >= values[i]);
        privateSupply = SafeMath.sub(privateSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
    TokenLeft(privateSupply);
  }

 function publicSaleTransfer(address[] recipients, uint256[] values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(publicSupply >= values[i]);
        publicSupply = SafeMath.sub(publicSupply,values[i]);
        token.mint(recipients[i], values[i]);     
    }
    TokenLeft(publicSupply);
  } 



  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }


}









/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 internal cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}


/**
 * @title VantageToken
 */



contract VantageToken is MintableToken {

  string public constant name = "Vantage Token";
  string public constant symbol = "XVT";
  uint8 public constant decimals = 18;
  uint256 public constant _totalSupply = SafeMath.mul(200000000, 1 ether);

  function VantageToken () {
    totalSupply = _totalSupply;
  }
}













/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale {
  using SafeMath for uint256;

  bool isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalizeCrowdsale() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    
    finalization();
    Finalized();
    
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

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }
  
  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}




/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale&#39;s vault.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 internal goal;
  bool private _goalReached = false;
  // bool public _updateTimeTransfer = false;
  // refund vault used to hold funds while crowdsale is running
  RefundVault private vault;

  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

  // We&#39;re overriding the fund forwarding from Crowdsale.
  // In addition to sending the funds, we want to call
  // the RefundVault deposit function
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (goalReached()) { 
      vault.close();
    } else {
      vault.enableRefunds();
    }
    super.finalization();
  
  }

  function goalReached() public constant returns (bool) {
    if (weiRaised >= goal) {
      _goalReached = true;
      return true;
    } else if (_goalReached) {
      return true;
    } 
    else {
      return false;
    }
  }

  function updateGoalCheck() onlyOwner public {
    _goalReached = true;
  }

  function getVaultAddress() onlyOwner public returns (address) {
    return vault;
  }
}


contract VantageCrowdsale is Crowdsale, CappedCrowdsale, RefundableCrowdsale {
    /** Constructor VantageICO */ 
    function VantageCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, address _wallet)
    CappedCrowdsale(_cap)
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_goal <= _cap);  
    }

    /**VantageToken Contract is generating from here */
    function createTokenContract() internal returns (MintableToken) {
        return new VantageToken();
    }

    
  
}