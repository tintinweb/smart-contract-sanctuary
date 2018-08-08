pragma solidity ^0.4.13;


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
    if (msg.sender != owner) {
      throw;
    }
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


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
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
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


contract GenesisToken is StandardToken, Ownable {
  using SafeMath for uint256;

  // metadata
  string public constant name = &#39;Genesis&#39;;
  string public constant symbol = &#39;GNS&#39;;
  uint256 public constant decimals = 18;
  string public version = &#39;0.0.1&#39;;

  // events
  event EarnedGNS(address indexed contributor, uint256 amount);
  event TransferredGNS(address indexed from, address indexed to, uint256 value);

  // constructor
  function GenesisToken(
    address _owner,
    uint256 initialBalance)
  {
    owner = _owner;
    totalSupply = initialBalance;
    balances[_owner] = initialBalance;
    EarnedGNS(_owner, initialBalance);
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function giveTokens(address _to, uint256 _amount) onlyOwner returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    EarnedGNS(_to, _amount);
    return true;
  }
}

/**
 * This contract holds all the revenues generated by the DAO, and pays out to
 * token holders on a periodic basis.
 */
contract CrowdWallet is Ownable {
  using SafeMath for uint;

  struct Deposit {
    uint amount;
    uint block;
  }

  struct Payout {
    uint amount;
    uint block;
  }

  // Genesis Tokens determine the payout for each contributor.
  GenesisToken public token;

  // Track deposits/payouts by address
  mapping (address => Deposit[]) public deposits;
  mapping (address => Payout[]) public payouts;

  // Track the sum of all payouts & deposits ever made to this contract.
  uint public lifetimeDeposits;
  uint public lifetimePayouts;

  // Time between pay periods are defined as a number of blocks.
  uint public blocksPerPayPeriod = 172800; // ~30 days
  uint public previousPayoutBlock;
  uint public nextPayoutBlock;

  // The balance at the end of each period is saved here and allocated to token
  // holders from the previous period.
  uint public payoutPool;

  // For doing division. Numerator should be multiplied by this.
  uint multiplier = 10**18;

  // Set a minimum that a user must have earned in order to withdraw it.
  uint public minWithdrawalThreshold = 100000000000000000; // 0.1 ETH in wei

  // Events
  event onDeposit(address indexed _from, uint _amount);
  event onPayout(address indexed _to, uint _amount);
  event onPayoutFailure(address indexed _to, uint amount);

  /**
   * Constructor - set the GNS token address and the initial number of blocks
   * in-between each pay period.
   */
  function CrowdWallet(address _gns, address _owner, uint _blocksPerPayPeriod) {
    token = GenesisToken(_gns);
    owner = _owner;
    blocksPerPayPeriod = _blocksPerPayPeriod;
    nextPayoutBlock = now.add(blocksPerPayPeriod);
  }

  function setMinimumWithdrawal(uint _weiAmount) onlyOwner {
    minWithdrawalThreshold = _weiAmount;
  }

  function setBlocksPerPayPeriod(uint _blocksPerPayPeriod) onlyOwner {
    blocksPerPayPeriod = _blocksPerPayPeriod;
  }

  /**
   * To prevent cheating, when a withdrawal is made, the tokens for that address
   * become immediately locked until the next period. Otherwise, they could send
   * their tokens to another wallet and withdraw again.
   */
  function withdraw() {
    require(previousPayoutBlock > 0);

    // Ensure the user has not already made a withdrawal this period.
    require(!isAddressLocked(msg.sender));

    uint payoutAmount = calculatePayoutForAddress(msg.sender);

    // Ensure user&#39;s payout is above the minimum threshold for withdrawals.
    require(payoutAmount > minWithdrawalThreshold);

    // User qualifies. Save the transaction with the current block number,
    // effectively locking their tokens until the next payout date.
    payouts[msg.sender].push(Payout({ amount: payoutAmount, block: now }));

    require(this.balance >= payoutAmount);

    onPayout(msg.sender, payoutAmount);

    lifetimePayouts += payoutAmount;

    msg.sender.transfer(payoutAmount);
  }

  /**
   * Once a user gets paid out for a period, we lock up the tokens they own
   * until the next period. Otherwise, they can send their tokens to a fresh
   * address and then double dip.
   */
  function isAddressLocked(address contributor) constant returns(bool) {
    var paymentHistory = payouts[contributor];

    if (paymentHistory.length == 0) {
      return false;
    }

    var lastPayment = paymentHistory[paymentHistory.length - 1];

    return (lastPayment.block >= previousPayoutBlock) && (lastPayment.block < nextPayoutBlock);
  }

  /**
   * Check if we are in a new payout cycle.
   */
  function isNewPayoutPeriod() constant returns(bool) {
    return now >= nextPayoutBlock;
  }

  /**
   * Start a new payout cycle
   */
  function startNewPayoutPeriod() {
    require(isNewPayoutPeriod());

    previousPayoutBlock = nextPayoutBlock;
    nextPayoutBlock = nextPayoutBlock.add(blocksPerPayPeriod);
    payoutPool = this.balance;
  }

  /**
   * Determine the amount that should be paid out.
   */
  function calculatePayoutForAddress(address payee) constant returns(uint) {
    uint ownedAmount = token.balanceOf(payee);
    uint totalSupply = token.totalSupply();
    uint percentage = (ownedAmount * multiplier) / totalSupply;
    uint payout = (payoutPool * percentage) / multiplier;

    return payout;
  }

  /**
   * Check the contract&#39;s ETH balance.
   */
  function ethBalance() constant returns(uint) {
    return this.balance;
  }

  /**
   * Income should go here.
   */
  function deposit() payable {
    onDeposit(msg.sender, msg.value);
    lifetimeDeposits += msg.value;
    deposits[msg.sender].push(Deposit({ amount: msg.value, block: now }));
  }

  function () payable {
    deposit();
  }
}