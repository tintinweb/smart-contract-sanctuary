pragma solidity ^0.4.18;

// File: contracts/flavours/Ownable.sol

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

// File: contracts/commons/SafeMath.sol

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
    uint256 c = a / b;
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

// File: contracts/flavours/Lockable.sol

/**
 * @title Lockable
 * @dev Base contract which allows children to
 *      implement main operations locking mechanism.
 */
contract Lockable is Ownable {
  event Lock();
  event Unlock();

  bool public locked = false;

  /**
   * @dev Modifier to make a function callable
  *       only when the contract is not locked.
   */
  modifier whenNotLocked() {
    require(!locked);
    _;
  }

  /**
   * @dev Modifier to make a function callable
   *      only when the contract is locked.
   */
  modifier whenLocked() {
    require(locked);
    _;
  }

  /**
   * @dev called by the owner to locke, triggers locked state
   */
  function lock() onlyOwner whenNotLocked public {
    locked = true;
    Lock();
  }

  /**
   * @dev called by the owner
   *      to unlock, returns to unlocked state
   */
  function unlock() onlyOwner whenLocked public {
    locked = false;
    Unlock();
  }
}

// File: contracts/base/BaseFixedERC20Token.sol

contract BaseFixedERC20Token is Lockable {
  using SafeMath for uint;

  /// @dev ERC20 Total supply
  uint public totalSupply;

  mapping(address => uint) balances;

  mapping(address => mapping (address => uint)) private allowed;

  /// @dev Fired if Token transfered accourding to ERC20
  event Transfer(address indexed from, address indexed to, uint value);

  /// @dev Fired if Token withdraw is approved accourding to ERC20
  event Approval(address indexed owner, address indexed spender, uint value);

  /**
   * @dev Gets the balance of the specified address.
   * @param owner_ The address to query the the balance of.
   * @return An uint representing the amount owned by the passed address.
   */
  function balanceOf(address owner_) public view returns (uint balance) {
    return balances[owner_];
  }

  /**
   * @dev Transfer token for a specified address
   * @param to_ The address to transfer to.
   * @param value_ The amount to be transferred.
   */
  function transfer(address to_, uint value_) whenNotLocked public returns (bool) {
    require(to_ != address(0) && value_ <= balances[msg.sender]);
    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(value_);
    balances[to_] = balances[to_].add(value_);
    Transfer(msg.sender, to_, value_);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from_ address The address which you want to send tokens from
   * @param to_ address The address which you want to transfer to
   * @param value_ uint the amount of tokens to be transferred
   */
  function transferFrom(address from_, address to_, uint value_) whenNotLocked public returns (bool) {
    require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
    balances[from_] = balances[from_].sub(value_);
    balances[to_] = balances[to_].add(value_);
    allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
    Transfer(from_, to_, value_);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering.
   *
   * To change the approve amount you first have to reduce the addresses
   * allowance to zero by calling `approve(spender_, 0)` if it is not
   * already 0 to mitigate the race condition described in:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param spender_ The address which will spend the funds.
   * @param value_ The amount of tokens to be spent.
   */
  function approve(address spender_, uint value_) whenNotLocked public returns (bool) {
    if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
      revert();
    }
    allowed[msg.sender][spender_] = value_;
    Approval(msg.sender, spender_, value_);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner_ address The address which owns the funds.
   * @param spender_ address The address which will spend the funds.
   * @return A uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner_, address spender_) view public returns (uint) {
    return allowed[owner_][spender_];
  }
}

// File: contracts/base/BaseICOToken.sol

/**
 * @dev Not mintable, ERC20 compilant token, distributed by ICO/Pre-ICO.
 */
contract BaseICOToken is BaseFixedERC20Token {

  /// @dev Available supply of tokens
  uint public availableSupply;

  /// @dev ICO/Pre-ICO smart contract allowed to distribute public funds for this
  address public ico;

  /// @dev Fired if investment for `amount` of tokens performed by `to` address
  event ICOTokensInvested(address indexed to, uint amount);

  /// @dev ICO contract changed for this token
  event ICOChanged(address indexed icoContract);

  /**
   * @dev Not mintable, ERC20 compilant token, distributed by ICO/Pre-ICO.
   * @param totalSupply_ Total tokens supply.
   */
  function BaseICOToken(uint totalSupply_) public {
    locked = true;
    totalSupply = totalSupply_;
    availableSupply = totalSupply_;
  }

  /**
   * @dev Set address of ICO smart-contract which controls token
   * initial token distribution.
   * @param ico_ ICO contract address.
   */
  function changeICO(address ico_) onlyOwner public {
    ico = ico_;
    ICOChanged(ico);
  }

  function isValidICOInvestment(address to_, uint amount_) internal view returns(bool) {
    return msg.sender == ico && to_ != address(0) && amount_ <= availableSupply;
  }

  /**
   * @dev Assign `amount_` of tokens to investor identified by `to_` address.
   * @param to_ Investor address.
   * @param amount_ Number of tokens distributed.
   */
  function icoInvestment(address to_, uint amount_) public returns (uint) {
    require(isValidICOInvestment(to_, amount_));
    availableSupply -= amount_;
    balances[to_] = balances[to_].add(amount_);
    ICOTokensInvested(to_, amount_);
    return amount_;
  }
}

// File: contracts/base/BaseICO.sol

/**
 * @dev Base abstract smart contract for any ICO
 */
contract BaseICO is Ownable {

  /// @dev ICO state
  enum State {
    // ICO is not active and not started
    Inactive,
    // ICO is active, tokens can be distributed among investors.
    // ICO parameters (end date, hard/low caps) cannot be changed.
    Active,
    // ICO is suspended, tokens cannot be distributed among investors.
    // ICO can be resumed to `Active state`.
    // ICO parameters (end date, hard/low caps) may changed.
    Suspended,
    // ICO is termnated by owner, ICO cannot be resumed.
    Terminated,
    // ICO goals are not reached,
    // ICO terminated and cannot be resumed.
    NotCompleted,
    // ICO completed, ICO goals reached successfully,
    // ICO terminated and cannot be resumed.
    Completed
  }

  /// @dev Token which controlled by this ICO
  BaseICOToken public token;

  /// @dev Current ICO state.
  State public state;

  /// @dev ICO start date seconds since epoch.
  uint public startAt;

  /// @dev ICO end date seconds since epoch.
  uint public endAt;

  /// @dev Minimal amount of investments in wei needed for successfull ICO
  uint public lowCapWei;

  /// @dev Maximal amount of investments in wei for this ICO.
  /// If reached ICO will be in `Completed` state.
  uint public hardCapWei;

  /// @dev Minimal amount of investments in wei per investor.
  uint public lowCapTxWei;

  /// @dev Maximal amount of investments in wei per investor.
  uint public hardCapTxWei;

  /// @dev Number of investments collected by this ICO
  uint public collectedWei;

  /// @dev Team wallet used to collect funds
  address public teamWallet;

  /// @dev True if whitelist enabled
  bool public whitelistEnabled = true;

  /// @dev ICO whitelist
  mapping (address => bool) public whitelist;

  // ICO state transition events
  event ICOStarted(uint indexed endAt, uint lowCapWei, uint hardCapWei, uint lowCapTxWei, uint hardCapTxWei);
  event ICOResumed(uint indexed endAt, uint lowCapWei, uint hardCapWei, uint lowCapTxWei, uint hardCapTxWei);
  event ICOSuspended();
  event ICOTerminated();
  event ICONotCompleted();
  event ICOCompleted(uint collectedWei);
  event ICOInvestment(address indexed from, uint investedWei, uint tokens, uint8 bonusPct);
  event ICOWhitelisted(address indexed addr);
  event ICOBlacklisted(address indexed addr);

  modifier isSuspended() {
    require(state == State.Suspended);
    _;
  }

  modifier isActive() {
    require(state == State.Active);
    _;
  }

  /**
   * Add address to ICO whitelist
   * @param address_ Investor address
   */
  function whitelist(address address_) external onlyOwner {
    whitelist[address_] = true;
    ICOWhitelisted(address_);
  }

  /**
   * Remove address from ICO whitelist
   * @param address_ Investor address
   */
  function blacklist(address address_) external onlyOwner {
    delete whitelist[address_];
    ICOBlacklisted(address_);
  }

  /**
   * @dev Returns true if given address in ICO whitelist
   */
  function whitelisted(address address_) public view returns (bool) {
    if (whitelistEnabled) {
      return whitelist[address_];
    } else {
      return true;
    }
  }

  /**
   * @dev Enable whitelisting
   */
  function enableWhitelist() public onlyOwner {
    whitelistEnabled = true;
  }

  /**
   * @dev Disable whitelisting
   */
  function disableWhitelist() public onlyOwner {
    whitelistEnabled = false;
  }

  /**
   * @dev Trigger start of ICO.
   * @param endAt_ ICO end date, seconds since epoch.
   */
  function start(uint endAt_) onlyOwner public {
    require(endAt_ > block.timestamp && state == State.Inactive);
    endAt = endAt_;
    startAt = block.timestamp;
    state = State.Active;
    ICOStarted(endAt, lowCapWei, hardCapWei, lowCapTxWei, hardCapTxWei);
  }

  /**
   * @dev Suspend this ICO.
   * ICO can be activated later by calling `resume()` function.
   * In suspend state, ICO owner can change basic ICO paraneter using `tune()` function,
   * tokens cannot be distributed among investors.
   */
  function suspend() onlyOwner isActive public {
    state = State.Suspended;
    ICOSuspended();
  }

  /**
   * @dev Terminate the ICO.
   * ICO goals are not reached, ICO terminated and cannot be resumed.
   */
  function terminate() onlyOwner public {
    require(state != State.Terminated &&
            state != State.NotCompleted &&
            state != State.Completed);
    state = State.Terminated;
    ICOTerminated();
  }

  /**
   * @dev Change basic ICO paraneters. Can be done only during `Suspended` state.
   * Any provided parameter is used only if it is not zero.
   * @param endAt_ ICO end date seconds since epoch. Used if it is not zero.
   * @param lowCapWei_ ICO low capacity. Used if it is not zero.
   * @param hardCapWei_ ICO hard capacity. Used if it is not zero.
   * @param lowCapTxWei_ Min limit for ICO per transaction
   * @param hardCapTxWei_ Hard limit for ICO per transaction
   */
  function tune(uint endAt_,
                uint lowCapWei_,
                uint hardCapWei_,
                uint lowCapTxWei_,
                uint hardCapTxWei_) onlyOwner isSuspended public {
    if (endAt_ > block.timestamp) {
      endAt = endAt_;
    }
    if (lowCapWei_ > 0) {
      lowCapWei = lowCapWei_;
    }
    if (hardCapWei_ > 0) {
      hardCapWei = hardCapWei_;
    }
    if (lowCapTxWei_ > 0) {
      lowCapTxWei = lowCapTxWei_;
    }
    if (hardCapTxWei_ > 0) {
      hardCapTxWei = hardCapTxWei_;
    }
    require(lowCapWei <= hardCapWei && lowCapTxWei <= hardCapTxWei);
    touch();
  }

  /**
   * @dev Resume a previously suspended ICO.
   */
  function resume() onlyOwner isSuspended public {
    state = State.Active;
    ICOResumed(endAt, lowCapWei, hardCapWei, lowCapTxWei, hardCapTxWei);
    touch();
  }

  /**
   * @dev Send ether to the fund collection wallet
   */
  function forwardFunds() internal {
    teamWallet.transfer(msg.value);
  }

  /**
   * @dev Recalculate ICO state based on current block time.
   * Should be called periodically by ICO owner.
   */
  function touch() public;

  /**
   * @dev Buy tokens
   */
  function buyTokens() public payable;
}

// File: contracts/MDICOStage2.sol

/**
 * @title MD tokens ICO Stage 2 contract.
 */
contract MDICOStage2 is BaseICO {
  using SafeMath for uint;

  /// @dev 18 decimals for token
  uint internal constant ONE_TOKEN = 1e18;

  /// @dev 1e18 WEI == 1ETH == 1000 tokens
  uint public constant ETH_TOKEN_EXCHANGE_RATIO = 1000;

  /// @dev 0% bonus for ICO Stage 2
  uint8 internal constant BONUS = 0; // 0%

  function MDICOStage2(address icoToken_,
                    address teamWallet_,
                    uint lowCapWei_,
                    uint hardCapWei_,
                    uint lowCapTxWei_,
                    uint hardCapTxWei_) public {
    require(icoToken_ != address(0) && teamWallet_ != address(0));
    token = BaseICOToken(icoToken_);
    teamWallet = teamWallet_;
    state = State.Inactive;
    lowCapWei = lowCapWei_;
    hardCapWei = hardCapWei_;
    lowCapTxWei = lowCapTxWei_;
    hardCapTxWei = hardCapTxWei_;
  }

  /**
   * @dev Recalculate ICO state based on current block time.
   * Should be called periodically by ICO owner.
   */
  function touch() public {
    if (state != State.Active && state != State.Suspended) {
      return;
    }
    if (collectedWei >= hardCapWei) {
      state = State.Completed;
      endAt = block.timestamp;
      ICOCompleted(collectedWei);
    } else if (block.timestamp >= endAt) {
      if (collectedWei < lowCapWei) {
        state = State.NotCompleted;
        ICONotCompleted();
      } else {
        state = State.Completed;
        ICOCompleted(collectedWei);
      }
    }
  }

  function buyTokens() public payable {
    require(state == State.Active &&
            block.timestamp <= endAt &&
            msg.value >= lowCapTxWei &&
            msg.value <= hardCapTxWei &&
            collectedWei + msg.value <= hardCapWei &&
            whitelisted(msg.sender));
    uint amountWei = msg.value;
    uint iwei = amountWei.mul(100 + BONUS).div(100);
    uint itokens = iwei * ETH_TOKEN_EXCHANGE_RATIO;
    token.icoInvestment(msg.sender, itokens); // Transfer tokens to investor
    collectedWei = collectedWei.add(amountWei);
    ICOInvestment(msg.sender, amountWei, itokens, BONUS);
    forwardFunds();
    touch();
  }

  /**
   * Accept direct payments
   */
  function() external payable {
    buyTokens();
  }
}