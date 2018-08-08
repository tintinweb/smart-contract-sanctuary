pragma solidity ^0.4.11;
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
/*
 * Haltable
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted;
  modifier stopInEmergency {
    require(!halted);
    _;
  }
  modifier stopNonOwnersInEmergency {
    require(!halted && msg.sender == owner);
    _;
  }
  modifier onlyInEmergency {
    require(halted);
    _;
  }
  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }
  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
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
  function deposit(address investor) onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }
  function close() onlyOwner payable {
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
  function refund(address investor) payable {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
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
 * @title Harbor token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract HarborToken is StandardToken, Ownable {
  //define HarborToken
  string public constant name = "HarborToken";
  string public constant symbol = "HBR";
  uint8 public constant decimals = 18;
   /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;
  event Mint(address indexed to, uint256 amount);
  event MintOpened();
  event MintFinished();
  event MintingAgentChanged(address addr, bool state  );
  event BurnToken(address addr,uint256 amount);
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    require(mintAgents[msg.sender]);
    _;
  }
  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyMintAgent canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }
  /**
   * @dev Function to burn down tokens
   * @param _addr The address that will burn the tokens.
   * @param  _amount The amount of tokens to burn.
   * @return A boolean that indicates if the burn up was successful.
   */
  function burn(address _addr,uint256 _amount) onlyMintAgent canMint  returns (bool) {
    require(_amount > 0);
    totalSupply = totalSupply.sub(_amount);
    balances[_addr] = balances[_addr].sub(_amount);
    BurnToken(_addr,_amount);
    return true;
  }
  /**
   * @dev Function to resume minting new tokens.
   * @return True if the operation was successful.
   */
  function openMinting() onlyOwner returns (bool) {
    mintingFinished = false;
    MintOpened();
     return true;
  }
 /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}
/**
 * @title HarborPresale 
 */
contract HarborPresale is Haltable {
  using SafeMath for uint256;
  // The token being sold
  HarborToken public token;
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;
  // address where funds are excutionFunds
  address public wallet;
  // how many token units a buyer gets per wei
  uint256 public rate;
  // amount of raised money in wei
  uint256 public weiRaised;
  
  //max amount of funds raised
  uint256 public cap;
  //is crowdsale end
  bool public isFinalized = false;
   // minimum amount of funds to be raised in weis
  uint256 public minimumFundingGoal;
  // minimum amount of funds for once 
  uint256 public minSend;
  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;
  //How many tokens were Minted
  uint public tokensMinted;
  //presale buyers
  mapping (address => uint256) public tokenDeposited;
  //event for crowdsale end
  event Finalized();
 //event for presale mint
  event TokenMinted(uint count);
  // We distributed tokens to an investor
  event Distributed(address investor, uint tokenAmount);
  //presale period is Changed
  event PeriodChanged(uint256 starttm,uint256 endtm);
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param investor who participate presale
   * @param value weis paid for purchase
   */ 
  event TokenPurchase(address indexed purchaser, address indexed investor, uint256 value);
  function HarborPresale(address _token, uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap, uint256 _minimumFundingGoal, uint256 _minSend) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
    require(_cap > 0);
    require(_minimumFundingGoal > 0);
    
    token = HarborToken(_token);
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    cap = _cap;
    vault = new RefundVault(_wallet);
    minimumFundingGoal = _minimumFundingGoal;
    minSend = _minSend;
  }
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }
  // low level token purchase function
  function buyTokens(address investor) payable stopInEmergency {
    require(investor != 0x0);
    require(validPurchase());
    require(minSend <= msg.value);
    uint256 weiAmount = msg.value;
    
    // update state
    weiRaised = weiRaised.add(weiAmount);
    //save for distribution HBR
    tokenDeposited[investor] = tokenDeposited[investor].add(weiAmount);
    //valut save for refund
    vault.deposit.value(msg.value)(msg.sender);
    TokenPurchase(msg.sender, investor, weiAmount);
  }
  /**
   * Load funds to the crowdsale for all investors.
   */
  function mintForEverybody() onlyOwner public {
    uint256 allTokenAmount = weiRaised.mul(rate);
    //for project amount (investor token *2/3)
    uint256 projectAmount = allTokenAmount.mul(2);
    projectAmount = projectAmount.div(3);
    //mint for investor;
    token.mint(address(this),allTokenAmount);
    //mint for project share
    token.mint(wallet,projectAmount);
    // Record how many tokens we got
    tokensMinted = allTokenAmount.add(projectAmount);
    TokenMinted(tokensMinted);
  }
  //get claim of token byself
  function claimToken() payable stopInEmergency{
    claimTokenAddress(msg.sender);
  }
  //get claim of token by address
  function claimTokenAddress(address investor) payable stopInEmergency returns(uint256){
     require(isFinalized);
     require(tokenDeposited[investor] != 0);
    
    uint256 depositedValue = tokenDeposited[investor];
    tokenDeposited[investor] = 0;
    uint256 tokenAmount = depositedValue * rate;
    //send token to investor
    token.transfer(investor,tokenAmount);
    Distributed(investor, tokenAmount);
    return tokenAmount;
  }
  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    bool withinCap = weiRaised <= cap;
    return withinPeriod && nonZeroPurchase && withinCap;
  }
  // @return true if HarborPresale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return (now > endTime) || capReached ;
  }
   /**
   *  called after Presale ends
   */
  function finalize() onlyOwner stopInEmergency{
    require(!isFinalized);
    require(hasEnded());
    finalization();
    Finalized();
    
    isFinalized = true;
  }
  /**
   *  finalization  refund or excute funds.
   */
  function finalization() internal {
    if (minFundingGoalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }
   // if presale is unsuccessful, investors can claim refunds here
  function claimRefund() stopInEmergency payable {
    require(isFinalized);
    require(!minFundingGoalReached());
    vault.refund(msg.sender);
  }
  function minFundingGoalReached() public constant returns (bool) {
    return weiRaised >= minimumFundingGoal;
  }
  //change presale preiod 
  function setPeriod(uint256 _startTime,uint256 _endTime) onlyOwner {
    require(now <= _endTime);
    startTime = _startTime;
    endTime = _endTime;
    PeriodChanged(startTime,endTime);
  }
  
  //withdrow for manual distribution
  function withdrawFund() onlyOwner payable{
    require(isFinalized);
    require(minFundingGoalReached());
    uint256 tokenAmount = token.balanceOf(address(this));
    token.transfer(wallet, tokenAmount);
  }
}