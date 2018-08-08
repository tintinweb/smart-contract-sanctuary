pragma solidity ^0.4.11;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {

  uint256 public totalSupply;

  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  function allowance(address owner, address spender) constant returns (uint256);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

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
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

/// @title Proof Presale Token (PROOFP)

contract ProofPresaleToken is ERC20, Ownable {

  using SafeMath for uint256;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  string public name = "Proof Presale Token";
  string public symbol = "PROOFP";
  uint8 public decimals = 18;
  bool public mintingFinished = false;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  function ProofPresaleToken() {}


  // TODO : need to replace throw by 0.4.11 solidity compiler syntax
  function() payable {
    revert();
  }

  function transfer(address _to, uint _value) returns (bool success) {

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);

    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
    
    
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */

  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


/**
 * @title Crowdsale 
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end block, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
 
contract Crowdsale is Pausable {
  using SafeMath for uint256;

  // The token being sold
  ProofPresaleToken public token;

  // address where funds are collected
  address public wallet;

  // amount of raised money in wei
  uint256 public weiRaised;

  // cap above which the crowdsale is ended
  uint256 public cap;

  uint256 public minInvestment;

  uint256 public rate;

  bool public isFinalized;

  string public contactInformation;

  uint256 public tokenDecimals;

  bool private rentrancy_lock = false;

  

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * event for signaling finished crowdsale
   */
  event Finalized();




  function Crowdsale() {

    token = createTokenContract();
    wallet = 0xaCF472DBcfA46cF9E9842e2734bE2b138fB13C41;
    rate = 20;
    tokenDecimals = 18;
    minInvestment = (10**18)/400;  //minimum investment in wei  (=10 ether)
    cap = 295257 * (10**18);  //cap in tokens base units (=295257 tokens)
  }

  // creates the token to be sold. 
  function createTokenContract() internal returns (ProofPresaleToken) {
    return new ProofPresaleToken();
  }


  // fallback function to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable whenNotPaused {
    require(beneficiary != 0x0);
    require(validPurchase());


    uint256 weiAmount = msg.value;
    // compute amount of tokens created
    uint256 tokens = weiAmount.mul(rate);

    // update weiRaised
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {

    uint256 weiAmount = weiRaised.add(msg.value);
    bool notSmallAmount = msg.value >= minInvestment;
    bool withinCap = weiAmount.mul(rate) <= cap;

    return (notSmallAmount && withinCap);
  }

  function finalize() onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    token.finishMinting();
    Finalized();

    isFinalized = true;
  }

  function setContactInformation(string info) onlyOwner {
      contactInformation = info;
  }


  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = (weiRaised.mul(rate) >= cap);
    return capReached;
  }
    
  /**
   * 
   * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="44362129272b0476">[email&#160;protected]</a>π.com>
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  
  // TODO need to set nonReentrant modifier where necessary

  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }


}