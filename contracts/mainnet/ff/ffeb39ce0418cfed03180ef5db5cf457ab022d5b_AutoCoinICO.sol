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
 * @title AutoCoinICO
 * @dev AutoCoinCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them ATC tokens based
 * on a ATC token per ETH rate. Funds collected are forwarded to a wallet
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
 * @title AutoCoin Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.0
 */
contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;
  /**
   *  @MintableToken token - Token Object
   *  @address wallet - Wallet Address
   *  @uint8 rate - Tokens per Ether
   *  @uint256 weiRaised - Total funds raised in Ethers
  */
  MintableToken internal token;
  address internal wallet;
  uint256 public rate;
  uint256 internal weiRaised;
  /**
   *  @uint256 privateSaleStartTime - Private-Sale Start Time
   *  @uint256 privateSaleEndTime - Private-Sale End Time
  */
  uint256 public privateSaleStartTime;
  uint256 public privateSaleEndTime;
  
  /**
   *  @uint privateBonus - Private Bonus
  */
  uint internal privateSaleBonus;
  /**
   *  @uint256 totalSupply - Total supply of tokens 
   *  @uint256 privateSupply - Total Private Supply from Public Supply
  */
  uint256 public totalSupply = SafeMath.mul(400000000, 1 ether);
  uint256 internal privateSaleSupply = SafeMath.mul(SafeMath.div(totalSupply,100),20);
  /**
   *  @bool checkUnsoldTokens - 
  */
  bool internal checkUnsoldTokens;
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value Wei&#39;s paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  /**
   * function Crowdsale - Parameterized Constructor
   * @param _startTime - StartTime of Crowdsale
   * @param _endTime - EndTime of Crowdsale
   * @param _rate - Tokens against Ether
   * @param _wallet - MultiSignature Wallet Address
   */
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) internal {
    
    require(_wallet != 0x0);
    token = createTokenContract();
    privateSaleStartTime = _startTime;
    privateSaleEndTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    privateSaleBonus = SafeMath.div(SafeMath.mul(rate,50),100);
    
  }
  /**
   * function createTokenContract - Mintable Token Created
   */
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
  /**
   * function Fallback - Receives Ethers
   */
  function () payable {
    buyTokens(msg.sender);
  }
    /**
   * function preSaleTokens - Calculate Tokens in PreSale
   */
  function privateSaleTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        
    require(privateSaleSupply > 0);
    tokens = SafeMath.add(tokens, weiAmount.mul(privateSaleBonus));
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    require(privateSaleSupply >= tokens);
    privateSaleSupply = privateSaleSupply.sub(tokens);        
    return tokens;
  }
  /**
  * function buyTokens - Collect Ethers and transfer tokens
  */
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 accessTime = now;
    uint256 tokens = 0;
    uint256 weiAmount = msg.value;
    require((weiAmount >= (100000000000000000)) && (weiAmount <= (20000000000000000000)));
    if ((accessTime >= privateSaleStartTime) && (accessTime < privateSaleEndTime)) {
      tokens = privateSaleTokens(weiAmount, tokens);
    } else {
      revert();
    }
    
    privateSaleSupply = privateSaleSupply.sub(tokens);
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
  /**
   * function forwardFunds - Transfer funds to wallet
   */
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  /**
   * function validPurchase - Checks the purchase is valid or not
   * @return true - Purchase is withPeriod and nonZero
   */
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= privateSaleStartTime && now <= privateSaleEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  /**
   * function hasEnded - Checks the ICO ends or not
   * @return true - ICO Ends
   */
  
  function hasEnded() public constant returns (bool) {
    return now > privateSaleEndTime;
  }
  /** 
   * function getTokenAddress - Get Token Address 
   */
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }
}
/**
 * @title AutoCoin 
 */
 
contract AutoCoinToken is MintableToken {
  /**
   *  @string name - Token Name
   *  @string symbol - Token Symbol
   *  @uint8 decimals - Token Decimals
   *  @uint256 _totalSupply - Token Total Supply
  */
  string public constant name = "Auto Coin";
  string public constant symbol = "Auto Coin";
  uint8 public constant decimals = 18;
  uint256 public constant _totalSupply = 400000000 * 1 ether;
  
/** Constructor AutoCoinToken */
  function AutoCoinToken() {
    totalSupply = _totalSupply;
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
contract CrowdsaleFunctions is Crowdsale {
 /** 
  * function transferAirdropTokens - Transfer private tokens via AirDrop
  * @param beneficiary address where owner wants to transfer tokens
  * @param tokens value of token
  */
  function transferAirdropTokens(address[] beneficiary, uint256[] tokens) onlyOwner public {
    for (uint256 i = 0; i < beneficiary.length; i++) {
      tokens[i] = SafeMath.mul(tokens[i], 1 ether); 
      require(privateSaleSupply >= tokens[i]);
      privateSaleSupply = SafeMath.sub(privateSaleSupply, tokens[i]);
      token.mint(beneficiary[i], tokens[i]);
    }
  }
/** 
 *.function transferTokens - Used to transfer tokens to investors who pays us other than Ethers
 * @param beneficiary - Address where owner wants to transfer tokens
 * @param tokens -  Number of tokens
 */
  function transferTokens(address beneficiary, uint256 tokens) onlyOwner public {
    require(privateSaleSupply > 0);
    tokens = SafeMath.mul(tokens,1 ether);
    require(privateSaleSupply >= tokens);
    privateSaleSupply = SafeMath.sub(privateSaleSupply, tokens);
    token.mint(beneficiary, tokens);
  }
}
contract AutoCoinICO is Crowdsale, CrowdsaleFunctions {
  
    /** Constructor AutoCoinICO */
    function AutoCoinICO(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) 
    Crowdsale(_startTime,_endTime,_rate,_wallet) 
    {
        
    }
    
    /** AutoCoinToken Contract */
    function createTokenContract() internal returns (MintableToken) {
        return new AutoCoinToken();
    }
}