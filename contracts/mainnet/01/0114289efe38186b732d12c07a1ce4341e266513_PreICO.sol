pragma solidity ^0.4.18;




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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract MintBurnableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }

}

contract DLH is MintBurnableToken {

  string public constant name = "Depositor-investor L&H";

  string public constant symbol = "DLH";

  uint8 public constant decimals = 18;

}

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }
}

contract Stateful {
  enum State {
  Private,
  PreSale,
  sellIsOver
  }
  State public state = State.Private;

  event StateChanged(State oldState, State newState);

  function setState(State newState) internal {
    State oldState = state;
    state = newState;
    StateChanged(oldState, newState);
  }
}

contract PreICO is ReentrancyGuard, Ownable, Stateful {
  using SafeMath for uint256;

  DLH public token;

  address public wallet;


  uint256 public startPreICOTime;
  uint256 public endPreICOTime;

  // how many token units a buyer gets per cent
  uint256 public rate; //

  uint256 public priceUSD; // wei in one USD

  // amount of raised money in wei
  uint256 public centRaised;

  uint256 public minimumInvest;

  uint256 public softCapPreSale; // IN USD CENT
  uint256 public hardCapPreSale; // IN USD CENT
  uint256 public hardCapPrivate; // IN USD CENT

  address public oracle;
  address public manager;

  // investors => amount of money
  mapping(address => uint) public balances;
  mapping(address => uint) public balancesInCent;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function PreICO(
  address _wallet,
  address _token,
  uint256 _priceUSD,
  uint256 _minimumInvest) public
  {
    require(_priceUSD != 0);
    require(_wallet != address(0));
    require(_token != address(0));
    priceUSD = _priceUSD;
    rate = 250000000000000000; // 0.25 * 1 ether per one cent
    wallet = _wallet;
    token = DLH(_token);
    hardCapPrivate = 40000000;
    minimumInvest = _minimumInvest; // in cents
  }

  modifier saleIsOn() {
    bool withinPeriod = now >= startPreICOTime && now <= endPreICOTime;
    require(withinPeriod && state == State.PreSale || state == State.Private);
    _;
  }

  modifier isUnderHardCap() {
    bool underHardCap;
    if (state == State.Private){
      underHardCap = centRaised < hardCapPrivate;
    }
    else {
      underHardCap = centRaised < hardCapPreSale;
    }
    require(underHardCap);
    _;
  }

  modifier onlyOracle(){
    require(msg.sender == oracle);
    _;
  }

  modifier onlyOwnerOrManager(){
    require(msg.sender == manager || msg.sender == owner);
    _;
  }

  function hasEnded() public view returns (bool) {
    return now > endPreICOTime;
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 centValue) internal view returns(uint256) {
    return centValue.mul(rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds(uint256 value) internal {
    wallet.transfer(value);
  }

  function startPreSale(uint256 _softCapPreSale,
  uint256 _hardCapPreSale,
  uint256 period,
  uint256 _start) public onlyOwner
  {
    startPreICOTime = _start;
    endPreICOTime = startPreICOTime.add(period * 1 days);
    softCapPreSale = _softCapPreSale;
    hardCapPreSale = _hardCapPreSale;
    setState(State.PreSale);
  }

  function finishPreSale() public onlyOwner {
    require(centRaised > softCapPreSale);
    setState(State.sellIsOver);
    token.transferOwnership(owner);
    forwardFunds(this.balance);
  }

  function setOracle(address _oracle) public  onlyOwner {
    require(_oracle != address(0));
    oracle = _oracle;
  }

  // set manager&#39;s address
  function setManager(address _manager) public  onlyOwner {
    require(_manager != address(0));
    manager = _manager;
  }

  //set new rate
  function changePriceUSD(uint256 _priceUSD) public  onlyOracle {
    require(_priceUSD != 0);
    priceUSD = _priceUSD;
  }

  modifier refundAllowed()  {
    require(state != State.Private && centRaised < softCapPreSale && now > endPreICOTime);
    _;
  }

  function refund() public refundAllowed nonReentrant {
    uint valueToReturn = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(valueToReturn);
  }

  function manualTransfer(address _to, uint _valueUSD) public saleIsOn isUnderHardCap onlyOwnerOrManager {
    uint256 centValue = _valueUSD.mul(100);
    uint256 tokensAmount = getTokenAmount(centValue);
    centRaised = centRaised.add(centValue);
    token.mint(_to, tokensAmount);
    balancesInCent[_to] = balancesInCent[_to].add(centValue);
  }

  function buyTokens(address beneficiary) saleIsOn isUnderHardCap nonReentrant public payable {
    require(beneficiary != address(0) && msg.value.div(priceUSD) >= minimumInvest);
    uint256 weiAmount = msg.value;
    uint256 centValue = weiAmount.div(priceUSD);
    uint256 tokens = getTokenAmount(centValue);
    centRaised = centRaised.add(centValue);
    token.mint(beneficiary, tokens);
    balances[msg.sender] = balances[msg.sender].add(weiAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    if (centRaised > softCapPreSale || state == State.Private) {
      forwardFunds(weiAmount);
    }
  }

  function () external payable {
    buyTokens(msg.sender);
  }
}