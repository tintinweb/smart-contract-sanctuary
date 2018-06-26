pragma solidity 0.4.24;

// File: contracts/flavours/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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

// File: contracts/flavours/Whitelisted.sol

contract Whitelisted is Ownable {

    /// @dev True if whitelist enabled
    bool public whitelistEnabled = true;

    /// @dev ICO whitelist
    mapping(address => bool) public whitelist;

    event ICOWhitelisted(address indexed addr);
    event ICOBlacklisted(address indexed addr);

    modifier onlyWhitelisted {
        require(!whitelistEnabled || whitelist[msg.sender]);
        _;
    }

    /**
     * Add address to ICO whitelist
     * @param address_ Investor address
     */
    function whitelist(address address_) external onlyOwner {
        whitelist[address_] = true;
        emit ICOWhitelisted(address_);
    }

    /**
     * Remove address from ICO whitelist
     * @param address_ Investor address
     */
    function blacklist(address address_) external onlyOwner {
        delete whitelist[address_];
        emit ICOBlacklisted(address_);
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
     * @dev Called before lock/unlock completed
     */
    modifier preLockUnlock() {
      _;
    }

    /**
     * @dev called by the owner to locke, triggers locked state
     */
    function lock() public onlyOwner whenNotLocked preLockUnlock {
        locked = true;
        emit Lock();
    }

    /**
     * @dev called by the owner
     *      to unlock, returns to unlocked state
     */
    function unlock() public onlyOwner whenLocked preLockUnlock {
        locked = false;
        emit Unlock();
    }
}

// File: contracts/base/BaseFixedERC20Token.sol

contract BaseFixedERC20Token is Lockable {
    using SafeMath for uint;

    /// @dev ERC20 Total supply
    uint public totalSupply;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) private allowed;

    /// @dev Fired if token is transferred according to ERC20 spec
    event Transfer(address indexed from, address indexed to, uint value);

    /// @dev Fired if token withdrawal is approved according to ERC20 spec
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Gets the balance of the specified address
     * @param owner_ The address to query the the balance of
     * @return An uint representing the amount owned by the passed address
     */
    function balanceOf(address owner_) public view returns (uint balance) {
        return balances[owner_];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to_ The address to transfer to.
     * @param value_ The amount to be transferred.
     */
    function transfer(address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[msg.sender]);
        // SafeMath.sub will throw an exception if there is not enough balance
        balances[msg.sender] = balances[msg.sender].sub(value_);
        balances[to_] = balances[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from_ address The address which you want to send tokens from
     * @param to_ address The address which you want to transfer to
     * @param value_ uint the amount of tokens to be transferred
     */
    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
        balances[from_] = balances[from_].sub(value_);
        balances[to_] = balances[to_].add(value_);
        allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
        emit Transfer(from_, to_, value_);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering
     *
     * To change the approve amount you first have to reduce the addresses
     * allowance to zero by calling `approve(spender_, 0)` if it is not
     * already 0 to mitigate the race condition described in:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param spender_ The address which will spend the funds.
     * @param value_ The amount of tokens to be spent.
     */
    function approve(address spender_, uint value_) public whenNotLocked returns (bool) {
        if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
            revert();
        }
        allowed[msg.sender][spender_] = value_;
        emit Approval(msg.sender, spender_, value_);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     * @param owner_ address The address which owns the funds
     * @param spender_ address The address which will spend the funds
     * @return A uint specifying the amount of tokens still available for the spender
     */
    function allowance(address owner_, address spender_) public view returns (uint) {
        return allowed[owner_][spender_];
    }
}

// File: contracts/base/BaseICOToken.sol

/**
 * @dev Not mintable, ERC20 compliant token, distributed by ICO/Pre-ICO.
 */
contract BaseICOToken is BaseFixedERC20Token {

    /// @dev Available supply of tokens
    uint public availableSupply;

    /// @dev ICO/Pre-ICO smart contract allowed to distribute public funds for this
    address public ico;

    /// @dev Token/ETH exchange ratio
    uint public ethTokenExchangeRatio;

    /// @dev Fired if investment for `amount` of tokens performed by `to` address
    event ICOTokensInvested(address indexed to, uint amount);

    /// @dev ICO contract changed for this token
    event ICOChanged(address indexed icoContract);

    modifier onlyICO() {
        require(msg.sender == ico);
        _;
    }

    /**
     * @dev Not mintable, ERC20 compliant token, distributed by ICO/Pre-ICO.
     * @param totalSupply_ Total tokens supply.
     */
    constructor(uint totalSupply_) public {
        locked = true;
        totalSupply = totalSupply_;
        availableSupply = totalSupply_;
    }

    /**
     * @dev Set address of ICO smart-contract which controls token
     * initial token distribution.
     * @param ico_ ICO contract address.
     */
    function changeICO(address ico_) public onlyOwner {
        ico = ico_;
        emit ICOChanged(ico);
    }

    function isValidICOInvestment(address to_, uint amount_) internal view returns (bool) {
        return to_ != address(0) && amount_ <= availableSupply;
    }

    /**
     * @dev Assign `amountWei_` of wei converted into tokens to investor identified by `to_` address.
     * @param to_ Investor address.
     * @param amountWei_ Number of wei invested
     * @return Amount of invested tokens
     */
    function icoInvestmentWei(address to_, uint amountWei_) public returns (uint);
}

// File: contracts/base/BaseICO.sol

/**
 * @dev Base abstract smart contract for any ICO
 */
contract BaseICO is Ownable, Whitelisted {

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

  /// @dev Minimal amount of investments in tokens needed for successful ICO
  uint public lowCapTokens;

  /// @dev Maximal amount of investments in tokens for this ICO.
  /// If reached ICO will be in `Completed` state.
  uint public hardCapTokens;

  /// @dev Minimal amount of investments in wei per investor.
  uint public lowCapTxWei;

  /// @dev Maximal amount of investments in wei per investor.
  uint public hardCapTxWei;

  /// @dev Team wallet used to collect funds
  address public teamWallet;

  // ICO state transition events
  event ICOStarted(uint indexed endAt, uint lowCapTokens, uint hardCapTokens, uint lowCapTxWei, uint hardCapTxWei);
  event ICOResumed(uint indexed endAt, uint lowCapTokens, uint hardCapTokens, uint lowCapTxWei, uint hardCapTxWei);
  event ICOSuspended();
  event ICOTerminated();
  event ICONotCompleted();
  event ICOCompleted(uint collectedTokens);
  event ICOInvestment(address indexed from, uint investedWei, uint tokens, uint8 bonusPct);

  modifier isSuspended() {
    require(state == State.Suspended);
    _;
  }
  modifier isActive() {
    require(state == State.Active);
    _;
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
    emit ICOStarted(endAt, lowCapTokens, hardCapTokens, lowCapTxWei, hardCapTxWei);
  }

  /**
   * @dev Suspend this ICO.
   * ICO can be activated later by calling `resume()` function.
   * In suspend state, ICO owner can change basic ICO parameter using `tune()` function,
   * tokens cannot be distributed among investors.
   */
  function suspend() onlyOwner isActive public {
    state = State.Suspended;
    emit ICOSuspended();
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
    emit ICOTerminated();
  }

  /**
   * @dev Change basic ICO parameters. Can be done only during `Suspended` state.
   * Any provided parameter is used only if it is not zero.
   * @param endAt_ ICO end date seconds since epoch. Used if it is not zero.
   * @param lowCapTokens_ ICO low capacity. Used if it is not zero.
   * @param hardCapTokens_ ICO hard capacity. Used if it is not zero.
   * @param lowCapTxWei_ Min limit for ICO per transaction
   * @param hardCapTxWei_ Hard limit for ICO per transaction
   */
  function tune(uint endAt_,
                uint lowCapTokens_,
                uint hardCapTokens_,
                uint lowCapTxWei_,
                uint hardCapTxWei_) onlyOwner isSuspended public {
    if (endAt_ > block.timestamp) {
      require(endAtCheck(endAt_));
      endAt = endAt_;
    }
    if (lowCapTokens_ > 0) {
      lowCapTokens = lowCapTokens_;
    }
    if (hardCapTokens_ > 0) {
      hardCapTokens = hardCapTokens_;
    }
    if (lowCapTxWei_ > 0) {
      lowCapTxWei = lowCapTxWei_;
    }
    if (hardCapTxWei_ > 0) {
      hardCapTxWei = hardCapTxWei_;
    }
    require(lowCapTokens <= hardCapTokens && lowCapTxWei <= hardCapTxWei);
    touch();
  }

  /**
   * @dev Additional limitations for new endAt value
   */
  function endAtCheck(uint) internal returns (bool) {
    // dummy
    return true;
  }

  /**
   * @dev Resume a previously suspended ICO.
   */
  function resume() onlyOwner isSuspended public {
    state = State.Active;
    emit ICOResumed(endAt, lowCapTokens, hardCapTokens, lowCapTxWei, hardCapTxWei);
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

// File: contracts/ESRTICO.sol

contract ESRTICO is BaseICO {
  using SafeMath for uint;

  /// @dev Total number of invested wei
  uint public collectedWei;

  /// @dev Total number of assigned tokens
  uint public collectedTokens;

  bool internal lowCapChecked = false;

  uint public lastStageStartAt = 1554076800; //  2019-04-01T00:00:00.000Z

  constructor(address icoToken_,
              address teamWallet_) public {
    require(icoToken_ != address(0) && teamWallet_ != address(0));
    token = BaseICOToken(icoToken_);
    teamWallet = teamWallet_;
    hardCapTokens = 60e24; // 60M Tokens
    lowCapTokens = 15e23;  // 1.5M Tokens
    hardCapTxWei = 1e30;  // practically infinite
    lowCapTxWei = 5e16;   // 0.05 ETH
  }

  /**
   * Accept direct payments
   */
  function() external payable {
    buyTokens();
  }

  /**
   * @dev Recalculate ICO state based on current block time.
   * Should be called periodically by ICO owner.
   */
  function touch() public {
    if (state != State.Active && state != State.Suspended) {
      return;
    }
    if (collectedTokens >= hardCapTokens) {
      state = State.Completed;
      endAt = block.timestamp;
      emit ICOCompleted(collectedTokens);
    } else if (!lowCapChecked && block.timestamp >= lastStageStartAt) {
      lowCapChecked = true;
      if (collectedTokens < lowCapTokens) {
        state = State.NotCompleted;
        emit ICONotCompleted();
      }
    } else if (block.timestamp >= endAt) {
        state = State.Completed;
        emit ICOCompleted(collectedTokens);
    }
  }

  /**
   * @dev Change ICO bonus 0 stage start date. Can be done only during `Suspended` state.
   * @param lastStageStartAt_ seconds since epoch. Used if it is not zero.
   */
  function tuneLastStageStartAt(uint lastStageStartAt_) onlyOwner isSuspended public {
    if (lastStageStartAt_ > block.timestamp) {
      // New value must be less than current
      require(lastStageStartAt_ < lastStageStartAt);
      lastStageStartAt = lastStageStartAt_;
    }
    touch();
  }

  /**
   * @dev Additional limitations for new endAt value
   */
  function endAtCheck(uint endAt_) internal returns (bool) {
    // New value must be less than current
    return endAt_ < endAt;
  }

  function computeBonus() internal view returns (uint8) {
    if (block.timestamp < 1538352000) { // 2018-10-01T00:00:00.000Z
      return 20;
    } else if (block.timestamp < 1546300800) { // 2019-01-01T00:00:00.000Z
      return 10;
    } else if (block.timestamp < lastStageStartAt) {
      return 5;
    } else {
      return 0;
    }
  }

  function buyTokens() public payable {

    require(state == State.Active &&
            block.timestamp < endAt &&
            msg.value >= lowCapTxWei &&
            msg.value <= hardCapTxWei &&
            whitelisted(msg.sender));

    uint8 bonus = computeBonus();
    uint amountWei = msg.value;
    uint iwei = amountWei.mul(100 + bonus).div(100);
    uint itokens = token.icoInvestmentWei(msg.sender, iwei);

    require(collectedTokens + itokens <= hardCapTokens);
    collectedTokens = collectedTokens.add(itokens);
    collectedWei = collectedWei.add(amountWei);

    emit ICOInvestment(msg.sender, amountWei, itokens, bonus);
    forwardFunds();
    touch();
  }
}