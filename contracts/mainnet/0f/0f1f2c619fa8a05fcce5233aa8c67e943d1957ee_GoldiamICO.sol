pragma solidity ^0.4.11;
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
 * @title GoldiamICO
 * @dev GoldiamCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them GOL tokens based
 * on a GOL token per ETH rate. Funds collected are forwarded to a wallet
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
    //totalSupply = totalSupply.add(_amount);
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
  function burnTokens(uint256 _unsoldTokens) onlyOwner public returns (bool) {
    totalSupply = SafeMath.sub(totalSupply, _unsoldTokens);
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
 * @title Goldiam Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  // The token being sold
  MintableToken private token;
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public preStartTime;
  uint256 public preEndTime;
  uint256 public preIcoStartTime;
  uint256 public preIcoEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
  // Bonuses will be calculated here of ICO and Pre-ICO (both inclusive)
  uint256 private preSaleBonus;
  uint256 private preICOBonus;
  uint256 private firstWeekBonus;
  uint256 private secondWeekBonus;
  uint256 private thirdWeekBonus;
  
  
  // wallet address where funds will be saved
  address internal wallet;
  
  // base-rate of a particular Goldiam token
  uint256 public rate;
  // amount of raised money in wei
  uint256 internal weiRaised;
  // Weeks in UTC
  // uint256 weekOne;
  // uint256 weekTwo;
  // uint256 weekThree;
  
  uint256 weekOneStart;
  uint256 weekOneEnd;
  uint256 weekTwoStart;
  uint256 weekTwoEnd;
  uint256 weekThreeStart;
  uint256 weekThreeEnd;
  uint256 lastWeekStart;
  uint256 lastWeekEnd;
  // total supply of token 
  uint256 public totalSupply = 32300000 * 1 ether;
  // public supply of token 
  uint256 public publicSupply = 28300000 * 1 ether;
  // reward supply of token 
  uint256 public reserveSupply = 3000000 * 1 ether;
  // bounty supply of token 
  uint256 public bountySupply = 1000000 * 1 ether;
  // preSale supply of the token
  uint256 public preSaleSupply = 8000000 * 1 ether;
  // preICO supply of token 
  uint256 public preicoSupply = 8000000 * 1 ether;
  // ICO supply of token 
  uint256 public icoSupply = 12300000 * 1 ether;
  // Remaining Public Supply of token 
  uint256 public remainingPublicSupply = publicSupply;
  // Remaining Bounty Supply of token 
  uint256 public remainingBountySupply = bountySupply;
  // Remaining company Supply of token 
  uint256 public remainingReserveSupply = reserveSupply;
  /**
   *  @bool checkBurnTokens
   *  @bool upgradeICOSupply
   *  @bool grantCompanySupply
   *  @bool grantAdvisorSupply     
  */
  bool public paused = false;
  bool private checkBurnTokens;
  bool private upgradePreICOSupply;
  bool private upgradeICOSupply;
  bool private grantReserveSupply;
  bool private grantBountySupply;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  // Goldiam Crowdsale constructor
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
    // Goldiam token creation 
    token = createTokenContract();
    // Pre-sale start Time
    preStartTime = _startTime; //1521532800
    
    // Pre-sale end time
     preEndTime = 1522367999;
    // Pre-ICO start time
    preIcoStartTime = 1522396800; 
    // Pre-ICO end time
    preIcoEndTime = 1523231999; 
    // // ICO start Time
     ICOstartTime = 1523260800; 
    // ICO end Time
    ICOEndTime = _endTime;
    // Base Rate of GOL Token
    rate = _rate;
    // Multi-sig wallet where funds will be saved
    wallet = _wallet;
    /** Calculations of Bonuses in ICO or Pre-ICO */
    preSaleBonus = SafeMath.div(SafeMath.mul(rate,30),100); 
    preICOBonus = SafeMath.div(SafeMath.mul(rate,25),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);
    /** ICO bonuses week calculations */
    weekOneStart = 1523260800; 
    weekOneEnd = 1524095999; 
    weekTwoStart = 1524124800;
    weekTwoEnd = 1524916799;
    weekThreeStart = 1524988800; 
    weekThreeEnd = 1525823999;
    lastWeekStart = 1525852800; 
    lastWeekEnd = 1526687999;
    checkBurnTokens = false;
    grantReserveSupply = false;
    grantBountySupply = false;
    upgradePreICOSupply = false;
    upgradeICOSupply = false;
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
modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
    /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
  }
  // High level token purchase function
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
    // minimum investment should be 0.05 ETH 
    require(weiAmount >= 0.05 * 1 ether);
    
    uint256 accessTime = now;
    uint256 tokens = 0;
    uint256 supplyTokens = 0;
    uint256 bonusTokens = 0;
  // calculating the Pre-Sale, Pre-ICO and ICO bonuses on the basis of timing
    if ((accessTime >= preStartTime) && (accessTime < preEndTime)) {
        require(preSaleSupply > 0);
        
        bonusTokens = SafeMath.add(bonusTokens, weiAmount.mul(preSaleBonus));
        supplyTokens = SafeMath.add(supplyTokens, weiAmount.mul(rate));
        tokens = SafeMath.add(bonusTokens, supplyTokens);
        
        require(preSaleSupply >= supplyTokens);
        require(icoSupply >= bonusTokens);
        preSaleSupply = preSaleSupply.sub(supplyTokens);
        icoSupply = icoSupply.sub(bonusTokens);
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    }else if ((accessTime >= preIcoStartTime) && (accessTime < preIcoEndTime)) {
        if (!upgradePreICOSupply) {
          preicoSupply = preicoSupply.add(preSaleSupply);
          upgradePreICOSupply = true;
        }
        require(preicoSupply > 0);
        bonusTokens = SafeMath.add(bonusTokens, weiAmount.mul(preICOBonus));
        supplyTokens = SafeMath.add(supplyTokens, weiAmount.mul(rate));
        tokens = SafeMath.add(bonusTokens, supplyTokens);
        
        require(preicoSupply >= supplyTokens);
        require(icoSupply >= bonusTokens);
        preicoSupply = preicoSupply.sub(supplyTokens);
        icoSupply = icoSupply.sub(bonusTokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) {
        if (!upgradeICOSupply) {
          icoSupply = SafeMath.add(icoSupply,preicoSupply);
          upgradeICOSupply = true;
        }
        require(icoSupply > 0);
        if ( accessTime <= weekOneEnd ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
        } else if (accessTime <= weekTwoEnd) {
            if(accessTime >= weekTwoStart) {
              tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
            }else {
              revert();
            }
        } else if ( accessTime <= weekThreeEnd ) {
            if(accessTime >= weekThreeStart) {
              tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
            }else {
              revert();
            }
        } else if ( accessTime <= lastWeekEnd ) {
            if(accessTime >= lastWeekStart) {
              tokens = 0;
            }else {
              revert();
            }
        }
        
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        icoSupply = icoSupply.sub(tokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    } else {
      revert();
    }
    // update state
    weiRaised = weiRaised.add(weiAmount);
    // tokens are minting here
    token.mint(beneficiary, tokens);
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
    bool withinPeriod = now >= preStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
      return now > ICOEndTime;
  }
  // @return true if burnToken function has ended
  function burnToken() onlyOwner whenNotPaused public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    checkBurnTokens = true;
    token.burnTokens(remainingPublicSupply);
    totalSupply = SafeMath.sub(totalSupply, remainingPublicSupply);
    remainingPublicSupply = 0;
    preSaleSupply = 0;
    preicoSupply = 0;
    icoSupply = 0;
    return true;
  }
  /** 
     * @return true if bountyFunds function has ended
  */
  function bountyFunds() onlyOwner whenNotPaused public { 
    require(!grantBountySupply);
    grantBountySupply = true;
    token.mint(0x4311E7B5a249B8D2CC7CcD98Dc7bE45d8ce94e39, remainingBountySupply);
    
    remainingBountySupply = 0;
  }  
  /**
      @return true if grantRewardToken function has ended  
  */
    function grantReserveToken() onlyOwner whenNotPaused public {
    require(!grantReserveSupply);
    grantReserveSupply = true;
    token.mint(0x4C355A270bC49A18791905c1016603906461977a, remainingReserveSupply);
    
    remainingReserveSupply = 0;
    
  }
/** 
   * Function transferToken works to transfer tokens to the specified address on the
     call of owner within the crowdsale timestamp.
   * @param beneficiary address where owner wants to transfer tokens
   * @param tokens value of token
 */
  function transferToken(address beneficiary, uint256 tokens) onlyOwner whenNotPaused public {
    require(ICOEndTime > now);
    tokens = SafeMath.mul(tokens,1 ether);
    require(remainingPublicSupply >= tokens);
    remainingPublicSupply = SafeMath.sub(remainingPublicSupply,tokens);
    token.mint(beneficiary, tokens);
  }
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }
  function getPublicSupply() onlyOwner public returns (uint256) {
    return remainingPublicSupply;
  }
}
/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
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
  function finalize() onlyOwner public {
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
  uint256 public goal;
  bool private _goalReached = false;
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
/**
 * @title GoldiamToken
 */
contract GoldiamToken is MintableToken {
  string public constant name = "Goldiam";
  string public constant symbol = "GOL";
  uint256 public constant decimals = 18;
  uint256 public constant _totalSupply = 32300000 * 1 ether;
  
/** Constructor GoldiamToken */
  function GoldiamToken() {
    totalSupply = _totalSupply;
  }
}
contract GoldiamICO is Crowdsale, CappedCrowdsale, RefundableCrowdsale {
    uint256 _startTime = 1521532800;
    uint256 _endTime = 1526687999; 
    uint256 _rate = 1300;
    uint256 _goal = 2000 * 1 ether;
    uint256 _cap = 17000 * 1 ether;
    address _wallet  = 0x2fdDc70C97b11496d3183F014166BC0849C119d6;   
    /** Constructor GoldiamICO */
    function GoldiamICO() 
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime,_endTime,_rate,_wallet) {
        
    }
    /** GoldiamToken Contract is generating from here */
    function createTokenContract() internal returns (MintableToken) {
        return new GoldiamToken();
    }
}