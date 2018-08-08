pragma solidity ^0.4.21;

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/external/KYCWhitelist.sol

/**
 * @title KYCWhitelist
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract KYCWhitelist is Claimable {

   mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Does a "require" check if _beneficiary address is approved
   * @param _beneficiary Token beneficiary
   */
  function validateWhitelisted(address _beneficiary) internal view {
    require(whitelist[_beneficiary]);
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }
  
  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing. 
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist. 
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  
}

// File: contracts/external/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Claimable {
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/PrivatePreSale.sol

/**
 * @title PrivatePreSale
 * 
 * Private Pre-sale contract for Energis tokens
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
contract PrivatePreSale is Claimable, KYCWhitelist, Pausable {
  using SafeMath for uint256;

  
  // Wallet Address for funds
  address public constant FUNDS_WALLET = 0xDc17D222Bc3f28ecE7FCef42EDe0037C739cf28f;
  // Token Wallet Address
  address public constant TOKEN_WALLET = 0x1EF91464240BB6E0FdE7a73E0a6f3843D3E07601;
  // Token adderss being sold
  address public constant TOKEN_ADDRESS = 0x14121EEe7995FFDF47ED23cfFD0B5da49cbD6EB3;
  // Token being sold
  ERC20 public constant TOKEN = ERC20(TOKEN_ADDRESS);
  // Conversion Rate (Eth cost of 1 NRG) (Testing uses ETH price of $10 000)
  uint256 public constant TOKENS_PER_ETH = 6740;
  // Max NRG tokens to sell
  uint256 public constant MAX_TOKENS = 20000000 * (10**18);
  // Min investment in Tokens
  uint256 public constant MIN_TOKEN_INVEST = 300000 * (10**18);
  // Token sale start date
  uint256 public START_DATE = 1525176000;

  // -----------------------------------------
  // State Variables
  // -----------------------------------------

  // Amount of wei raised
  uint256 public weiRaised;
  // Amount of tokens issued
  uint256 public tokensIssued;
  // If the pre-sale has ended
  bool public closed;

  // -----------------------------------------
  // Events
  // -----------------------------------------

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  // -----------------------------------------
  // Constructor
  // -----------------------------------------


  function PrivatePreSale() public {
    require(TOKENS_PER_ETH > 0);
    require(FUNDS_WALLET != address(0));
    require(TOKEN_WALLET != address(0));
    require(TOKEN_ADDRESS != address(0));
    require(MAX_TOKENS > 0);
    require(MIN_TOKEN_INVEST >= 0);
  }

  // -----------------------------------------
  // Private PreSale external Interface
  // -----------------------------------------

  /**
   * @dev Checks whether the cap has been reached. 
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return tokensIssued >= MAX_TOKENS;
  }

  /**
   * @dev Closes the sale, can only be called once. Once closed can not be opened again.
   */
  function closeSale() public onlyOwner {
    require(!closed);
    closed = true;
  }

  /**
   * @dev Returns the amount of tokens given for the amount in Wei
   * @param _weiAmount Value in wei
   */
  function getTokenAmount(uint256 _weiAmount) public pure returns (uint256) {
    // Amount in wei (10**18 wei == 1 eth) and the token is 18 decimal places
    return _weiAmount.mul(TOKENS_PER_ETH);
  }

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  // -----------------------------------------
  // Private PreSale internal
  // -----------------------------------------

   /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) internal whenNotPaused {
    
    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokenAmount = getTokenAmount(weiAmount);

    // Validation Checks
    preValidateChecks(_beneficiary, weiAmount, tokenAmount);
    
    // update state
    tokensIssued = tokensIssued.add(tokenAmount);
    weiRaised = weiRaised.add(weiAmount);

    // Send tokens from token wallet
    TOKEN.transferFrom(TOKEN_WALLET, _beneficiary, tokenAmount);

    // Forward the funds to wallet
    FUNDS_WALLET.transfer(msg.value);

    // Event trigger
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
  }

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   * @param _tokenAmount Amount of token to purchase
   */
  function preValidateChecks(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal view {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(now >= START_DATE);
    require(!closed);

    // KYC Check
    validateWhitelisted(_beneficiary);

    // Test Min Investment
    require(_tokenAmount >= MIN_TOKEN_INVEST);

    // Test hard cap
    require(tokensIssued.add(_tokenAmount) <= MAX_TOKENS);
  }
}