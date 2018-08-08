pragma solidity ^0.4.13;

contract StandardContract {
    // allows usage of "require" as a modifier
    modifier requires(bool b) {
        require(b);
        _;
    }

    // require at least one of the two conditions to be true
    modifier requiresOne(bool b1, bool b2) {
        require(b1 || b2);
        _;
    }

    modifier notNull(address a) {
        require(a != 0);
        _;
    }

    modifier notZero(uint256 a) {
        require(a != 0);
        _;
    }
}

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

/*
 * A SingleTokenLocker allows a user to create a locker that can lock a single type of ERC20 token.
 * The token locker should:
 *    - Allow the owner to prove a certain number of their own tokens are locked for until a particular time
 *    - Allow the owner to transfer tokens to a recipient and prove the tokens are locked until a particular time
 *    - Allow the owner to cancel a transfer before a recipient confirms (in case of transfer to an incorrect address)
 *    - Allow the recipient to be certain that they will have access to transferred tokens once the lock expires
 *    - Be re-usable by the owner, so an owner can easily schedule/monitor multiple transfers/locks
 *
 * This class should be reusable for any ERC20 token.  Ideally, this sort of fine grained locking would be available in
 * the token contract itself.  Short of that, the token locker receives tokens (presumably from the locker owner) and
 * can be configured to release them only under certain conditions.
 *
 * Usage:
 *  - The owner creates a token locker for a particular ERC20 token type
 *  - The owner approves the locker up to some number of tokens: token.approve(tokenLockerAddress, tokenAmount)
 *    - Alternately, the owner can send tokens to the locker.  When locking tokens, the locker checks its balance first
 *  - The owner calls "lockup" with a particular recipient, amount, and unlock time.  The recipient will be allowed
 *    to collect the tokens once the lockup period is ended.
 *  - The recipient calls "confirm" which confirms that the recipient&#39;s address is correct and is controlled by the
 *    intended recipient (e.g. not an exchange address).  The assumption is that if the recipient can call "confirm"
 *    they have demonstrated that they will also be able to call "collect" when the tokens are ready.
 *  - Once the lock expires, the recipient calls "collect" and the tokens are transferred from the locker to the
 *    recipient.
 *
 * An owner can lockup his/her own tokens in order to demonstrate the they will not be moved until a particular time.
 * In this case, no separate "confirm" step is needed (confirm happens automatically)
 *
 * The following diagram shows the actual balance of the token locker and how it is tracked internally
 *
 *         +-------------------------------------------------------------+
 *         |                      Actual Locker Balance                  |
 *         |-------------------------------------------------------------|
 *         |                     |                Promised               |
 *  State  |     Uncommitted     +---------------------------------------|
 *         |                     |        Pending            |  Locked   |
 *         |---------------------+---------------------------------------|
 *  Actions| withdraw            |  confirm, cancel, collect | collect   |
 *         |---------------------+---------------------------+-----------|
 *  Field  | balance - promised  | promised - locked         | locked    |
 *         +---------------------+---------------------------+-----------+
 */
contract SingleTokenLocker is Claimable, ReentrancyGuard, StandardContract, HasNoEther {

  using SafeMath for uint256;

  // the type of token this locker is used for
  ERC20 public token;

  // A counter to generate unique Ids for promises
  uint256 public nextPromiseId;

  // promise storage
  mapping(uint256 => TokenPromise) public promises;

  // The total amount of tokens locked or pending lock (in the non-fractional units, like wei)
  uint256 public promisedTokenBalance;

  // The total amount of tokens actually locked (recipients have confirmed)
  uint256 public lockedTokenBalance;

  // promise states
  //  none: The default state.  Never explicitly assigned.
  //  pending: The owner has initiated a promise, but it has not been claimed
  //  confirmed: The recipient has confirmed the promise
  //  executed: The promise has completed (after the required lockup)
  //  canceled: The promise was canceled (only from pending state)
  //  failed: The promise could not be fulfilled due to an error
  enum PromiseState { none, pending, confirmed, executed, canceled, failed }

  // a matrix designating the legal state transitions for a promise (see constructor)
  mapping (uint => mapping(uint => bool)) stateTransitionMatrix;

  // true if the contract has been initialized
  bool initialized;

  struct TokenPromise {
    uint256 promiseId;
    address recipient;
    uint256 amount;
    uint256 lockedUntil;
    PromiseState state;
  }

  event logPromiseCreated(uint256 promiseId, address recipient, uint256 amount, uint256 lockedUntil);
  event logPromiseConfirmed(uint256 promiseId);
  event logPromiseCanceled(uint256 promiseId);
  event logPromiseFulfilled(uint256 promiseId);
  event logPromiseUnfulfillable(uint256 promiseId, address recipient, uint256 amount);

  /**
   * Guards actions that only the intended recipient should be able to perform
   */
  modifier onlyRecipient(uint256 promiseId) {
    require(msg.sender == promises[promiseId].recipient);
    _;
  }

  /**
   * Ensures the promiseId as actually in use.
   */
  modifier promiseExists(uint promiseId) {
    require(promiseId < nextPromiseId);
    _;
  }

  /**
   * Ensure state consistency after modifying lockedTokenBalance or promisedTokenBalance
   */
  modifier thenAssertState() {
    _;
    uint256 balance = tokenBalance();
    assert(lockedTokenBalance <= promisedTokenBalance);
    assert(promisedTokenBalance <= balance);
  }

  // Constructor
  function SingleTokenLocker(address tokenAddress) {
    token = ERC20(tokenAddress);

    allowTransition(PromiseState.pending, PromiseState.canceled);
    allowTransition(PromiseState.pending, PromiseState.executed);
    allowTransition(PromiseState.pending, PromiseState.confirmed);
    allowTransition(PromiseState.confirmed, PromiseState.executed);
    allowTransition(PromiseState.executed, PromiseState.failed);
    initialized = true;
  }

  /**
   * Initiates the request to lockup the given number of tokens until the given block.timestamp occurs.
   * This contract will attempt to acquire tokens from the Token contract from the owner if its balance
   * is not sufficient.  Therefore, the locker owner may call token.approve(locker.address, amount) one time
   * and then initiate many smaller transfers to individuals.
   *
   * Note 1: lockup is not guaranteed until the recipient confirms.
   * Note 2: Assumes the owner has already given approval for the TokenLocker to take out the tokens
   *         or that the locker&#39;s balance is sufficient
   */
  function lockup(address recipient, uint256 amount, uint256 lockedUntil)
    onlyOwner
    notNull(recipient)
    notZero(amount)
    nonReentrant
    external
  {
    // if the locker does not have sufficient unlocked tokens, assume it has enough
    // approved by the owner to make up the difference
    ensureTokensAvailable(amount);

    // setup a promise that allow transfer to the recipient after the lock expires
    TokenPromise storage promise = createPromise(recipient, amount, lockedUntil);

    // auto-confirm if the recipient is the owner
    if (recipient == owner) {
      doConfirm(promise);
    }
  }

  /***
   * @dev Cancels the pending transaction as long as the caller has permissions and the transaction has not already
   * been confirmed.  Allowing *any* transaction to be canceled would mean no lockup could ever be guaranteed.
   */
  function cancel(uint256 promiseId)
    promiseExists(promiseId)
    requires(promises[promiseId].state == PromiseState.pending)
    requiresOne(
      msg.sender == owner,
      msg.sender == promises[promiseId].recipient
    )
    nonReentrant
    external
  {
    TokenPromise storage promise = promises[promiseId];
    unlockTokens(promise, PromiseState.canceled);
    logPromiseCanceled(promise.promiseId);
  }

  // @dev Allows the recipient to confirm their address.  If this fails (or they cannot send from the specified address)
  // the owner of the TokenLocker can cancel the promise and initiate a new one
  function confirm(uint256 promiseId)
    promiseExists(promiseId)
    onlyRecipient(promiseId)
    requires(promises[promiseId].state == PromiseState.pending)
    nonReentrant
    external
  {
    doConfirm(promises[promiseId]);
  }

  /***
   * Called by the recipient after the lock has expired.
   */
  function collect(uint256 promiseId)
    promiseExists(promiseId)
    onlyRecipient(promiseId)
    requires(block.timestamp >= promises[promiseId].lockedUntil)
    requiresOne(
      promises[promiseId].state == PromiseState.pending,
      promises[promiseId].state == PromiseState.confirmed
    )
    nonReentrant
    external
  {
    TokenPromise storage promise = promises[promiseId];

    unlockTokens(promise, PromiseState.executed);
    if (token.transfer(promise.recipient, promise.amount)) {
      logPromiseFulfilled(promise.promiseId);
    }
    else {
      // everything looked good, but the transfer failed.  :(  Now what?
      // There is no reason to think it will work the next time, so
      // reverting probably won&#39;t help here; the tokens would remain locked
      // forever.  Our only hope is that the token owner will resolve the
      // issue in the real world.  Since the amount has been deducted from the
      // locked and pending totals, it has effectively been returned to the owner.
      transition(promise, PromiseState.failed);
      logPromiseUnfulfillable(promiseId, promise.recipient, promise.amount);
    }
  }

  /***
   * Withdraws the given number of tokens from the locker as long as they are not already locked or promised
   */
  function withdrawUncommittedTokens(uint amount)
    onlyOwner
    requires(amount <= uncommittedTokenBalance())
    nonReentrant
    external
  {
    token.transfer(owner, amount);
  }

  /***
   * Withdraw all tokens from the wallet that are not locked or promised
   */
  function withdrawAllUncommittedTokens()
    onlyOwner
    nonReentrant
    external
  {
    // not using withdrawUncommittedTokens(uncommittedTokenBalance())
    // to have stronger guarantee on nonReentrant+external
    token.transfer(owner, uncommittedTokenBalance());
  }

  // tokens can be transferred out by the owner if either
  //  1: The tokens are not the type that are governed by this contract (accidentally sent here, most likely)
  //  2: The tokens are not already promised to a recipient (either pending or confirmed)
  //
  // If neither of these conditions are true, then allowing the owner to transfer the tokens
  // out would violate the purpose of the token locker, which is to prove that the tokens
  // cannot be moved.
  function salvageTokensFromContract(address tokenAddress, address to, uint amount)
    onlyOwner
    requiresOne(
      tokenAddress != address(token),
      amount <= uncommittedTokenBalance()
    )
    nonReentrant
    external
  {
    ERC20(tokenAddress).transfer(to, amount);
  }

  /***
   * Returns true if the given promise has been confirmed by the recipient
   */
  function isConfirmed(uint256 promiseId)
    constant
    returns(bool)
  {
    return promises[promiseId].state == PromiseState.confirmed;
  }

  /***
   * Returns true if the give promise can been collected by the recipient
   */
  function canCollect(uint256 promiseId)
    constant
    returns(bool)
  {
    return (promises[promiseId].state == PromiseState.confirmed || promises[promiseId].state == PromiseState.pending)
      && block.timestamp >= promises[promiseId].lockedUntil;
  }

  // @dev returns the total amount of tokens that are eligible to be collected
  function collectableTokenBalance()
    constant
    returns(uint256 collectable)
  {
    collectable = 0;
    for (uint i=0; i<nextPromiseId; i++) {
      if (canCollect(i)) {
        collectable = collectable.add(promises[i].amount);
      }
    }
    return collectable;
  }

  /***
   * Return the number of transactions that meet the given criteria.  To be used in conjunction with
   * getPromiseIds()
   *
   * recipient: the recipients address to use for filtering, or 0x0 to return all
   * includeCompleted: true if the list should include transactions that are already executed or canceled
   */
  function getPromiseCount(address recipient, bool includeCompleted)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<nextPromiseId; i++) {
      if (recipient != 0x0 && recipient != promises[i].recipient)
        continue;

        if (includeCompleted
            || promises[i].state == PromiseState.pending
            || promises[i].state == PromiseState.confirmed)
      count += 1;
    }
  }

  /***
   * Return a list of promiseIds that match the given criteria
   *
   * recipient: the recipients address to use for filtering, or 0x0 to return all
   * includeCompleted: true if the list should include transactions that are already executed or canceled
   */
  function getPromiseIds(uint from, uint to, address recipient, bool includeCompleted)
    public
    constant
    returns (uint[] promiseIds)
  {
    uint[] memory promiseIdsTemp = new uint[](nextPromiseId);
    uint count = 0;
    uint i;
    for (i=0; i<nextPromiseId && count < to; i++) {
      if (recipient != 0x0 && recipient != promises[i].recipient)
        continue;

      if (includeCompleted
        || promises[i].state == PromiseState.pending
        || promises[i].state == PromiseState.confirmed)
      {
        promiseIdsTemp[count] = i;
        count += 1;
      }
    }
    promiseIds = new uint[](to - from);
    for (i=from; i<to; i++)
      promiseIds[i - from] = promiseIdsTemp[i];
  }

  /***
   * returns the number of tokens held by the token locker (some might be promised or locked)
   */
  function tokenBalance()
    constant
    returns(uint256)
  {
    return token.balanceOf(address(this));
  }

  /***
   * returns the number of tokens that are not promised or locked
   */
  function uncommittedTokenBalance()
    constant
    returns(uint256)
  {
    return tokenBalance() - promisedTokenBalance;
  }

  /***
   * returns the number of tokens that a promised by have not been locked (pending confirmation from recipient)
   */
  function pendingTokenBalance()
    constant
    returns(uint256)
  {
    return promisedTokenBalance - lockedTokenBalance;
  }

  // ------------------ internal methods ------------------ //

  // @dev moves the promise to the new state and updates the locked/pending totals accordingly
  function unlockTokens(TokenPromise storage promise, PromiseState newState)
    internal
  {
    promisedTokenBalance = promisedTokenBalance.sub(promise.amount);
    if (promise.state == PromiseState.confirmed) {
      lockedTokenBalance = lockedTokenBalance.sub(promise.amount);
    }
    transition(promise, newState);
  }

  // @dev add a new state transition to the state transition matrix
  function allowTransition(PromiseState from, PromiseState to)
    requires(!initialized)
    internal
  {
    stateTransitionMatrix[uint(from)][uint(to)] = true;
  }

  // @dev moves the promise to the new state as long as it&#39;s permitted by the state transition matrix
  function transition(TokenPromise storage promise, PromiseState newState)
    internal
  {
    assert(stateTransitionMatrix[uint(promise.state)][uint(newState)]);
    promise.state = newState;
  }

  // @dev moves the promise to the confirmed state and updates the locked token total
  function doConfirm(TokenPromise storage promise)
    thenAssertState
    internal
  {
    transition(promise, PromiseState.confirmed);
    lockedTokenBalance = lockedTokenBalance.add(promise.amount);
    logPromiseConfirmed(promise.promiseId);
  }

  /***
   * @dev creates and stores a new promise object, updates the promisedTokenBalance
   */
  function createPromise(address recipient, uint256 amount, uint256 lockedUntil)
    requires(amount <= uncommittedTokenBalance())
    thenAssertState
    internal
    returns(TokenPromise storage promise)
  {
    uint256 promiseId = nextPromiseId++;
    promise = promises[promiseId];
    promise.promiseId = promiseId;
    promise.recipient = recipient;
    promise.amount = amount;
    promise.lockedUntil = lockedUntil;
    promise.state = PromiseState.pending;

    promisedTokenBalance = promisedTokenBalance.add(promise.amount);

    logPromiseCreated(promiseId, recipient, amount, lockedUntil);

    return promise;
  }

  /**
   * @dev Checks the uncommitted balance to ensure there the locker has enough tokens to guarantee the
   * amount given can be promised.  If the locker&#39;s balance is not enough, the locker will attempt to transfer
   * tokens from the owner.
   */
  function ensureTokensAvailable(uint256 amount)
    onlyOwner
    internal
  {
    uint256 uncommittedBalance = uncommittedTokenBalance();
    if (uncommittedBalance < amount) {
      token.transferFrom(owner, this, amount.sub(uncommittedBalance));

      // Just assert that the condition we really care about holds, rather
      // than relying on the return value.  see GavCoin and all the tokens copy/pasted therefrom.
      assert(uncommittedTokenBalance() >= amount);
    }
  }
}