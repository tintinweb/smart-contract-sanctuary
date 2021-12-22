// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IIncentivisedVotingLockup} from "../interfaces/IIncentivisedVotingLockup.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {ISmartWalletChecker} from "../interfaces/ISmartWalletChecker.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {StableMath} from "../libraries/StableMath.sol";
import {Root} from "../libraries/Root.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title  IncentivisedVotingLockup
 * @author Voting Weight tracking & Decay
 *             -> Curve Finance (MIT) - forked & ported to Solidity
 *             -> https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
 *         osolmaz - Research & Reward distributions
 *         alsco77 - Solidity implementation
 * @notice Lockup MTA, receive vMTA (voting weight that decays over time), and earn
 *         rewards based on staticWeight
 * @dev    Supports:
 *            1) Tracking MTA Locked up (LockedBalance)
 *            2) Pull Based Reward allocations based on Lockup (Static Balance)
 *            3) Decaying voting weight lookup through CheckpointedERC20 (balanceOf)
 *            5) Migration of points to v2 (used as multiplier in future) ***** (rewardsPaid)
 *            6) Closure of contract (expire)
 */
contract IncentivisedVotingLockup is
  IIncentivisedVotingLockup,
  Ownable,
  ReentrancyGuard
{
  using StableMath for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /** Shared Events */
  event Deposit(
    address indexed provider,
    uint256 value,
    uint256 locktime,
    LockAction indexed action,
    uint256 ts
  );
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event ContractStopped(bool contractStopped);
  // An event thats emitted when an account changes its delegate
  event DelegateSet(
    address indexed delegator,
    address indexed toDelegate,
    uint96 amount,
    uint96 expireTime
  );
  // An event thats emitted when an account removes its delegate
  event DelegateRemoved(
    address indexed delegator,
    address indexed delegateeToRemove,
    uint256 amtDelegationRemoved
  );

  // RBN Redeemer contract
  address public rbnRedeemer;

  // Checker for whitelisted (smart contract) wallets which are allowed to deposit
  // The goal is to prevent tokenizing the escrow
  address public futureSmartWalletChecker;
  address public smartWalletChecker;

  /** Shared Globals */
  IERC20 public stakingToken;
  uint256 private constant WEEK = 7 days;
  uint256 public constant MAXTIME = 4 * 365 days; // 4 years
  uint256 public END;

  /** Lockup */
  uint256 public globalEpoch;
  uint256 public totalShares;
  uint256 public totalLocked;
  Point[] public pointHistory;
  bool public contractStopped;
  mapping(address => Point[]) public userPointHistory;
  mapping(address => uint256) public userPointEpoch;
  mapping(uint256 => int128) public slopeChanges;
  mapping(address => LockedBalance) public locked;

  /// @notice A record of each accounts delegate
  mapping(address => address) public delegates;

  mapping(address => mapping(uint32 => Boost)) private _boost;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  // The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

  // The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  // A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  // Voting token - Checkpointed view only ERC20
  // EIP-20 token name for this token
  string public constant name = "Staked Ribbon";
  // EIP-20 token symbol for this token
  string public constant symbol = "sRBN";
  // EIP-20 token decimals for this token
  uint8 public constant decimals = 18;

  /** Structs */
  struct Point {
    int128 bias;
    int128 slope;
    uint128 ts;
    uint128 blk;
  }

  struct Boost {
    uint32 nextExpiry;
    uint32 fromBlock;
    uint32 fromTimestamp;
    int128 delegatedSlope;
    int128 receivedSlope;
    uint256 delegatedBias;
    uint256 receivedBias;
  }

  struct LockedBalance {
    int112 amount;
    int112 shares;
    uint32 end;
  }

  enum LockAction {
    CREATE_LOCK,
    INCREASE_LOCK_AMOUNT,
    INCREASE_LOCK_TIME
  }

  /**
   * @dev Constructor
   * @param _stakingToken the staking token to lock
   * @param _owner the owner of the contract
   * @param _rbnRedeemer the contract address with redeeming logic
   */
  constructor(
    address _stakingToken,
    address _owner,
    address _rbnRedeemer
  ) {
    require(_stakingToken != address(0), "!_stakingToken");
    require(_owner != address(0), "!_owner");
    require(_rbnRedeemer != address(0), "!_rbnRedeemer");

    stakingToken = IERC20(_stakingToken);
    Point memory init = Point({
      bias: int128(0),
      slope: int128(0),
      ts: uint128(block.timestamp),
      blk: uint128(block.number)
    });
    pointHistory.push(init);

    transferOwnership(_owner);

    rbnRedeemer = _rbnRedeemer;

    END = block.timestamp + MAXTIME;
  }

  /**
   * @dev Check if the call is from a whitelisted smart contract, revert if not
   * @param _addr address to be checked
   */
  function checkIsWhitelisted(address _addr) internal view {
    address checker = smartWalletChecker;
    require(
      _addr == tx.origin ||
        (checker != address(0) && ISmartWalletChecker(checker).check(_addr)),
      "Smart contract depositors not allowed"
    );
  }

  /**
   * @notice It's stupid to split this out to a different function, but we are trying to save bytecode here
   */
  function checkIsContractStopped() internal view {
    require(!contractStopped, "Contract is stopped");
  }

  /***************************************
                LOCKUP - GETTERS
    ****************************************/

  /**
   * @dev Redeems rbn to redeemer contract in case criterium met (i.e smart contract hack, vaults get rekt)
   * @param _amount amount to withdraw to redeemer contract
   */
  function redeemRBN(uint256 _amount) external {
    address redeemer = rbnRedeemer;
    require(msg.sender == redeemer, "Must be rbn redeemer contract");
    stakingToken.safeTransfer(redeemer, _amount);
    totalLocked -= _amount;
  }

  /**
   * @dev Set an external contract to check for approved smart contract wallets
   * @param _addr amount to withdraw to redeemer contract
   */
  function commitSmartWalletChecker(address _addr) external onlyOwner {
    futureSmartWalletChecker = _addr;
  }

  /**
   * @dev Apply setting external contract to check approved smart contract wallets
   */
  function applySmartWalletChecker() external onlyOwner {
    smartWalletChecker = futureSmartWalletChecker;
  }

  /**
   * @dev Gets the last available user point
   * @param _addr User address
   * @return bias i.e. y
   * @return slope i.e. linear gradient
   * @return ts i.e. time point was logged
   */
  function getLastUserPoint(address _addr)
    external
    view
    override
    returns (
      int128 bias,
      int128 slope,
      uint256 ts
    )
  {
    uint256 uepoch = userPointEpoch[_addr];
    if (uepoch == 0) {
      return (0, 0, 0);
    }
    Point memory point = userPointHistory[_addr][uepoch];
    return (point.bias, point.slope, point.ts);
  }

  /***************************************
                    LOCKUP
    ****************************************/

  /**
   * @dev Records a checkpoint of both individual and global slope
   * @param _addr User address, or address(0) for only global
   * @param _oldLocked Old amount that user had locked, or null for global
   * @param _newLocked new amount that user has locked, or null for global
   */
  function _checkpoint(
    address _addr,
    LockedBalance memory _oldLocked,
    LockedBalance memory _newLocked
  ) internal {
    Point memory userOldPoint;
    Point memory userNewPoint;
    int128 oldSlopeDelta = 0;
    int128 newSlopeDelta = 0;
    uint256 epoch = globalEpoch;

    if (_addr != address(0)) {
      // Calculate slopes and biases
      // Kept at zero when they have to
      if (_oldLocked.end > block.timestamp && _oldLocked.amount > 0) {
        userOldPoint.slope =
          _oldLocked.amount /
          StableMath.toInt112(int256(MAXTIME));
        userOldPoint.bias =
          userOldPoint.slope *
          SafeCast.toInt128(int256(_oldLocked.end - block.timestamp));
      }
      if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
        userNewPoint.slope =
          _newLocked.amount /
          StableMath.toInt112(int256(MAXTIME));
        userNewPoint.bias =
          userNewPoint.slope *
          SafeCast.toInt128(int256(_newLocked.end - block.timestamp));
      }

      // Moved from bottom final if statement to resolve stack too deep err
      // start {
      // Now handle user history
      uint256 uEpoch = userPointEpoch[_addr];
      if (uEpoch == 0) {
        userPointHistory[_addr].push(userOldPoint);
      }

      userPointEpoch[_addr] = uEpoch + 1;
      userNewPoint.ts = uint128(block.timestamp);
      userNewPoint.blk = uint128(block.number);
      userPointHistory[_addr].push(userNewPoint);

      // Read values of scheduled changes in the slope
      // oldLocked.end can be in the past and in the future
      // newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
      oldSlopeDelta = slopeChanges[_oldLocked.end];
      if (_newLocked.end != 0) {
        if (_newLocked.end == _oldLocked.end) {
          newSlopeDelta = oldSlopeDelta;
        } else {
          newSlopeDelta = slopeChanges[_newLocked.end];
        }
      }
    }

    Point memory lastPoint = Point({
      bias: 0,
      slope: 0,
      ts: uint128(block.timestamp),
      blk: uint128(block.number)
    });
    if (epoch > 0) {
      lastPoint = pointHistory[epoch];
    }
    uint256 lastCheckpoint = lastPoint.ts;

    // initialLastPoint is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract
    Point memory initialLastPoint = Point({
      bias: 0,
      slope: 0,
      ts: lastPoint.ts,
      blk: lastPoint.blk
    });
    uint256 blockSlope = 0; // dblock/dt
    if (block.timestamp > lastPoint.ts) {
      blockSlope =
        StableMath.scaleInteger(block.number - lastPoint.blk) /
        (block.timestamp - lastPoint.ts);
    }
    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 iterativeTime = _floorToWeek(lastCheckpoint);
    for (uint256 i = 0; i < 255; i++) {
      // Hopefully it won't happen that this won't get used in 5 years!
      // If it does, users will be able to withdraw but vote weight will be broken
      iterativeTime = iterativeTime + WEEK;
      int128 dSlope = 0;
      if (iterativeTime > block.timestamp) {
        iterativeTime = block.timestamp;
      } else {
        dSlope = slopeChanges[iterativeTime];
      }
      int128 biasDelta = lastPoint.slope *
        SafeCast.toInt128(int256((iterativeTime - lastCheckpoint)));
      lastPoint.bias = lastPoint.bias - biasDelta;
      lastPoint.slope = lastPoint.slope + dSlope;
      // This can happen
      if (lastPoint.bias < 0) {
        lastPoint.bias = 0;
      }
      // This cannot happen - just in case
      if (lastPoint.slope < 0) {
        lastPoint.slope = 0;
      }
      lastCheckpoint = iterativeTime;
      lastPoint.ts = uint128(iterativeTime);
      lastPoint.blk = uint128(
        initialLastPoint.blk +
          blockSlope.mulTruncate(iterativeTime - initialLastPoint.ts)
      );

      // when epoch is incremented, we either push here or after slopes updated below
      epoch = epoch + 1;
      if (iterativeTime == block.timestamp) {
        lastPoint.blk = uint128(block.number);
        break;
      } else {
        pointHistory.push(lastPoint);
      }
    }

    globalEpoch = epoch;
    // Now pointHistory is filled until t=now

    if (_addr != address(0)) {
      // If last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      lastPoint.slope =
        lastPoint.slope +
        userNewPoint.slope -
        userOldPoint.slope;
      lastPoint.bias = lastPoint.bias + userNewPoint.bias - userOldPoint.bias;
      if (lastPoint.slope < 0) {
        lastPoint.slope = 0;
      }
      if (lastPoint.bias < 0) {
        lastPoint.bias = 0;
      }
    }

    // Record the changed point into history
    // pointHistory[epoch] = lastPoint;
    pointHistory.push(lastPoint);

    if (_addr != address(0)) {
      // Schedule the slope changes (slope is going down)
      // We subtract new_user_slope from [new_locked.end]
      // and add old_user_slope to [old_locked.end]
      if (_oldLocked.end > block.timestamp) {
        // oldSlopeDelta was <something> - userOldPoint.slope, so we cancel that
        oldSlopeDelta = oldSlopeDelta + userOldPoint.slope;
        if (_newLocked.end == _oldLocked.end) {
          oldSlopeDelta = oldSlopeDelta - userNewPoint.slope; // It was a new deposit, not extension
        }
        slopeChanges[_oldLocked.end] = oldSlopeDelta;
      }
      if (_newLocked.end > block.timestamp) {
        if (_newLocked.end > _oldLocked.end) {
          newSlopeDelta = newSlopeDelta - userNewPoint.slope; // old slope disappeared at this point
          slopeChanges[_newLocked.end] = newSlopeDelta;
        }
        // else: we recorded it already in oldSlopeDelta
      }
    }
  }

  /**
   * @dev Deposits or creates a stake for a given address
   * @param _addr User address to assign the stake
   * @param _value Total units of StakingToken to lockup
   * @param _unlockTime Time at which the stake should unlock
   * @param _oldLocked Previous amount staked by this user
   * @param _action See LockAction enum
   */
  function _depositFor(
    address _addr,
    uint256 _value,
    uint256 _unlockTime,
    LockedBalance memory _oldLocked,
    LockAction _action
  ) internal {
    LockedBalance memory newLocked = LockedBalance({
      amount: _oldLocked.amount,
      shares: _oldLocked.shares,
      end: _oldLocked.end
    });

    uint256 _newShares;
    uint256 _totalRBN = stakingToken.balanceOf(address(this));
    if (totalShares == 0 || _totalRBN == 0) {
      _newShares = _value;
    } else {
      _newShares = _value.mul(totalShares).div(_totalRBN);
    }

    // Adding to existing lock, or if a lock is expired - creating a new one
    newLocked.amount = newLocked.amount + StableMath.toInt112(int256(_value));
    newLocked.shares =
      newLocked.shares +
      StableMath.toInt112(int256(_newShares));

    totalShares += _newShares;
    totalLocked += _value;

    if (_unlockTime != 0) {
      newLocked.end = SafeCast.toUint32(_unlockTime);
    }
    locked[_addr] = newLocked;

    // Possibilities:
    // Both _oldLocked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // newLocked.end > block.timestamp (always)
    _checkpoint(_addr, _oldLocked, newLocked);

    if (_value != 0) {
      stakingToken.safeTransferFrom(_addr, address(this), _value);
    }
    emit Deposit(_addr, _value, newLocked.end, _action, block.timestamp);
  }

  /**
   * @dev Public function to trigger global checkpoint
   */
  function checkpoint() external {
    LockedBalance memory empty;
    _checkpoint(address(0), empty, empty);
  }

  /**
   * @dev Creates a new lock
   * @param _value Total units of StakingToken to lockup
   * @param _unlockTime Time at which the stake should unlock
   */
  function createLock(uint256 _value, uint256 _unlockTime)
    external
    override
    nonReentrant
  {
    checkIsWhitelisted(msg.sender);
    checkIsContractStopped();

    uint256 unlock_time = _floorToWeek(_unlockTime); // Locktime is rounded down to weeks
    LockedBalance memory locked_ = LockedBalance({
      amount: locked[msg.sender].amount,
      shares: locked[msg.sender].shares,
      end: locked[msg.sender].end
    });

    require(_value > 0, "Must stake non zero amount");
    require(locked_.amount == 0, "Withdraw old tokens first");

    require(
      unlock_time > block.timestamp,
      "Can only lock until time in the future"
    );
    require(
      unlock_time <= block.timestamp + MAXTIME,
      "Voting lock can be 4 years max"
    );

    _depositFor(
      msg.sender,
      _value,
      unlock_time,
      locked_,
      LockAction.CREATE_LOCK
    );
  }

  /**
   * @dev Increases amount of stake thats locked up & resets decay
   * @param _value Additional units of StakingToken to add to exiting stake
   */
  function increaseLockAmount(uint256 _value)
    external
    override
    nonReentrant
  {
    checkIsWhitelisted(msg.sender);
    checkIsContractStopped();

    LockedBalance memory locked_ = LockedBalance({
      amount: locked[msg.sender].amount,
      shares: locked[msg.sender].shares,
      end: locked[msg.sender].end
    });

    require(_value > 0, "Must stake non zero amount");
    require(locked_.amount > 0, "No existing lock found");
    require(
      locked_.end > block.timestamp,
      "Cannot add to expired lock. Withdraw"
    );

    _depositFor(
      msg.sender,
      _value,
      0,
      locked_,
      LockAction.INCREASE_LOCK_AMOUNT
    );
  }

  /**
   * @dev Increases length of lockup & resets decay
   * @param _unlockTime New unlocktime for lockup
   */
  function increaseLockLength(uint256 _unlockTime)
    external
    override
    nonReentrant
  {
    checkIsWhitelisted(msg.sender);
    checkIsContractStopped();

    LockedBalance memory locked_ = LockedBalance({
      amount: locked[msg.sender].amount,
      shares: locked[msg.sender].shares,
      end: locked[msg.sender].end
    });
    uint256 unlock_time = _floorToWeek(_unlockTime); // Locktime is rounded down to weeks

    require(locked_.amount > 0, "Nothing is locked");
    require(locked_.end > block.timestamp, "Lock expired");
    require(unlock_time > locked_.end, "Can only increase lock WEEK");
    require(
      unlock_time <= block.timestamp + MAXTIME,
      "Voting lock can be 4 years max"
    );

    _depositFor(
      msg.sender,
      0,
      unlock_time,
      locked_,
      LockAction.INCREASE_LOCK_TIME
    );
  }

  /**
   * @dev Withdraws all the senders stake, providing lockup is over
   */
  function withdraw() external override nonReentrant {
    address _addr = msg.sender;

    LockedBalance memory oldLock = LockedBalance({
      end: locked[_addr].end,
      shares: locked[_addr].shares,
      amount: locked[_addr].amount
    });
    require(block.timestamp >= oldLock.end, "The lock didn't expire");
    require(oldLock.amount > 0, "Must have something to withdraw");

    uint256 shares = SafeCast.toUint256(oldLock.shares);

    LockedBalance memory currentLock = LockedBalance({
      end: 0,
      shares: 0,
      amount: 0
    });
    locked[_addr] = currentLock;

    // oldLocked can have either expired <= timestamp or zero end
    // currentLock has only 0 end
    // Both can have >= 0 amount
    _checkpoint(_addr, oldLock, currentLock);

    uint256 value = shares.mul(stakingToken.balanceOf(address(this))).div(
      totalShares
    );
    totalShares -= shares;
    totalLocked -= value;

    stakingToken.safeTransfer(_addr, value);

    emit Withdraw(_addr, value, block.timestamp);
  }

  /**
   * @dev Stops the contract.
   * No more staking can happen. Only withdraw.
   * @param _contractStopped whether contract is stopped
   */
  function setContractStopped(bool _contractStopped) external onlyOwner {
    contractStopped = _contractStopped;

    emit ContractStopped(_contractStopped);
  }

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
   * @notice Delegates votes from signatory to `delegatee`
   * @param _delegatee The address to delegate votes to
   * @param _nonce The contract state required to match the signature
   * @param _expiry The time at which to expire the signature
   * @param _v The recovery byte of the signature
   * @param _r Half of the ECDSA signature pair
   * @param _s Half of the ECDSA signature pair
   */
  function delegateBySig(
    address _delegatee,
    uint256 _nonce,
    uint256 _expiry,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        getChainId(),
        address(this)
      )
    );
    bytes32 structHash = keccak256(
      abi.encode(DELEGATION_TYPEHASH, _delegatee, _nonce, _expiry)
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );
    address signatory = ecrecover(digest, _v, _r, _s);
    require(signatory != address(0), "sRBN::delegateBySig: invalid signature");
    require(
      _nonce == nonces[signatory]++,
      "sRBN::delegateBySig: invalid nonce"
    );
    require(
      block.timestamp <= _expiry,
      "sRBN::delegateBySig: signature expired"
    );
    return _delegate(signatory, _delegatee);
  }

  /**
   * @notice Delegates votes from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param delegatee The address to delegate votes to
   */
  function _delegate(address delegator, address delegatee) internal {
    address delegateeStored = delegates[delegator];

    // Requirements
    // a) delegating more to same delegatee as before OR switching delegates
    // b) has existing delegation when cancelling delegation
    // c) cannot delegate to oneself

    require(
      (delegateeStored == address(0) && delegatee != address(0)) ||
        delegateeStored != address(0),
      "Cannot cancel delegation without existing delegation"
    );

    require(delegator != delegatee, "Cannot delegate to oneself");

    uint96 delegatorBalance;
    uint96 boostExpiry;

    // If we are not delegating to zero address (cancelling delegation)
    if (delegatee != address(0)) {
      delegatorBalance = getCurrentVotes(delegator);
      boostExpiry = locked[delegator].end;
    }

    // Change the delegator's delegatee
    if (delegateeStored != delegatee) {
      delegates[delegator] = delegatee;
    }

    _moveDelegates(
      delegator,
      delegatee,
      delegateeStored,
      boostExpiry,
      delegatorBalance
    );

    emit DelegateSet(delegator, delegatee, delegatorBalance, boostExpiry);
  }

  /**
   * @dev Update delegation logic
   * @param _delegator address of the delegator
   * @param _receiver address of the delegatee
   * @param _oldReceiver address of the old delegatee
   * @param _expireTime time when the rbn boost expires
   * @param _amt balance of the
   */
  function _moveDelegates(
    address _delegator,
    address _receiver,
    address _oldReceiver,
    uint256 _expireTime,
    uint256 _amt
  ) internal {
    bool isCancelDelegation = _receiver == address(0);
    // If we are transferring delegations from one EOA to another
    bool isTransferDelegation = !isCancelDelegation &&
      _oldReceiver != address(0) &&
      _receiver != _oldReceiver;

    uint32 nCheckpointsDelegator = numCheckpoints[_delegator];
    uint32 nCheckpointsReceiver = numCheckpoints[_receiver];

    uint128 nextExpiry = nCheckpointsDelegator > 0
      ? _boost[_delegator][nCheckpointsDelegator - 1].nextExpiry
      : 0;

    // Update the next expiry to be _expireTime if we have no current
    // delegation
    if (!isCancelDelegation && nextExpiry == 0) {
      nextExpiry = type(uint128).max;
    }

    require(
      isCancelDelegation || block.timestamp < nextExpiry,
      "Delegated a now expired boost in the past. Please cancel"
    );

    // delegated slope and bias
    uint256 delegatedBias = nCheckpointsDelegator > 0
      ? _boost[_delegator][nCheckpointsDelegator - 1].delegatedBias
      : 0;
    int128 delegatedSlope = nCheckpointsDelegator > 0
      ? _boost[_delegator][nCheckpointsDelegator - 1].delegatedSlope
      : int128(0);

    int128 slope;
    uint256 bias;

    if (!isCancelDelegation) {
      // delegated boost will be positive, if any of circulating boosts are negative
      // we have already reverted
      int256 delegatedBoost = delegatedSlope *
        SafeCast.toInt256(block.timestamp) +
        SafeCast.toInt256(delegatedBias);
      int256 y = SafeCast.toInt256(_amt) -
        (isTransferDelegation ? int256(0) : delegatedBoost);

      require(y > 0, "No boost available");

      uint256 expireTime = (_expireTime / 1 weeks) * 1 weeks;

      (int128 _slope, uint256 _bias) = _calcBiasSlope(
        SafeCast.toInt256(block.timestamp),
        y,
        SafeCast.toInt256(expireTime)
      );

      require(_slope < 0, "invalid slope");

      slope = _slope;
      bias = _bias;

      // increase the expiry of the sRBN boost
      if (expireTime < nextExpiry) {
        nextExpiry = SafeCast.toUint128(expireTime);
      }
    }

    // Cancel the previous delegation if we are transferring
    // delegations
    if (isTransferDelegation) {
      _writeDelegatorCheckpoint(
        _delegator,
        address(0),
        nCheckpointsDelegator,
        slope,
        bias,
        nextExpiry,
        SafeCast.toUint128(block.number),
        SafeCast.toUint128(block.timestamp)
      );

      _writeReceiverCheckpoint(
        _oldReceiver,
        address(0),
        nCheckpointsReceiver,
        delegatedBias,
        delegatedSlope,
        slope,
        bias,
        SafeCast.toUint128(block.number),
        SafeCast.toUint128(block.timestamp)
      );

      nCheckpointsDelegator = numCheckpoints[_delegator];
    }

    // Creating delegation for delegator / receiver of delegation
    _writeDelegatorCheckpoint(
      _delegator,
      _receiver,
      nCheckpointsDelegator,
      slope,
      bias,
      nextExpiry,
      SafeCast.toUint128(block.number),
      SafeCast.toUint128(block.timestamp)
    );

    _writeReceiverCheckpoint(
      _oldReceiver,
      _receiver,
      nCheckpointsReceiver,
      delegatedBias,
      delegatedSlope,
      slope,
      bias,
      SafeCast.toUint128(block.number),
      SafeCast.toUint128(block.timestamp)
    );
  }

  /**
   * @dev Update delegator side delegation logic
   * @param _delegator address of the delegator
   * @param _receiver address of the delegatee
   * @param _nCheckpoints index of next checkpoint
   * @param _slope slope of boost
   * @param _bias bias of boost (y-intercept)
   * @param _nextExpiry expiry of the boost
   * @param _blk current block number
   * @param _ts current timestamp
   */
  function _writeDelegatorCheckpoint(
    address _delegator,
    address _receiver,
    uint32 _nCheckpoints,
    int128 _slope,
    uint256 _bias,
    uint128 _nextExpiry,
    uint128 _blk,
    uint128 _ts
  ) internal {
    bool isCancelDelegation = _receiver == address(0);

    Boost memory addrBoost = _nCheckpoints > 0
      ? _boost[_delegator][_nCheckpoints - 1]
      : Boost(0, 0, 0, 0, 0, 0, 0);

    // If the previous checkpoint is the same block number
    // we will update same checkpoint with new delegation
    // updates
    uint32 currCP = _nCheckpoints > 0 && addrBoost.fromBlock == _blk
      ? _nCheckpoints - 1
      : _nCheckpoints;

    // If we are cancelling delegation, we set delegation
    // slope, bias, and next expiry to 0. Otherwise, we increment
    // the delegated slope, the delegated bias, and update the nextExpiry
    _boost[_delegator][currCP] = Boost({
      delegatedSlope: isCancelDelegation ? int128(0) : addrBoost.delegatedSlope + _slope,
      delegatedBias: uint128(isCancelDelegation ? 0 : addrBoost.delegatedBias + _bias),
      receivedSlope: addrBoost.receivedSlope,
      receivedBias: uint128(addrBoost.receivedBias),
      nextExpiry: uint32(isCancelDelegation ? 0 : _nextExpiry),
      fromBlock: uint32(currCP == _nCheckpoints ? _blk : addrBoost.fromBlock),
      fromTimestamp: uint32(currCP == _nCheckpoints ? _ts : addrBoost.fromTimestamp)
    });

    if (currCP == _nCheckpoints) {
      numCheckpoints[_delegator] = _nCheckpoints + 1;
    }
  }

  /**
   * @dev Update delegatee side delegation logic
   * @param _oldReceiver address of the old delegatee of delegator
   * @param _newReceiver address of the new delegatee of delegatee
   * @param _nCheckpoints index of next checkpoint
   * @param _delegatedBias bias of delegator
   * @param _delegatedSlope slope of delegator
   * @param _slope slope of boost
   * @param _bias bias of boost (y-intercept)
   * @param _blk current block number
   * @param _ts current timestamp
   */
  function _writeReceiverCheckpoint(
    address _oldReceiver,
    address _newReceiver,
    uint32 _nCheckpoints,
    uint256 _delegatedBias,
    int128 _delegatedSlope,
    int128 _slope,
    uint256 _bias,
    uint128 _blk,
    uint128 _ts
  ) internal {
    bool isCancelDelegation = _newReceiver == address(0);
    address receiver = isCancelDelegation ? _oldReceiver : _newReceiver;

    Boost memory addrBoost = _nCheckpoints > 0
      ? _boost[receiver][_nCheckpoints - 1]
      : Boost(0, 0, 0, 0, 0, 0, 0);

    // If this is not the first checkpoint, if it is a
    // cancellation we subtract the delegated bias and
    // slope of this delegator from the delegatee.
    // Otherwise we increment the bias and slope.
    if (_nCheckpoints > 0) {
      if (isCancelDelegation) {
        addrBoost.receivedBias -= _delegatedBias;
        addrBoost.receivedSlope -= _delegatedSlope;
      } else {
        addrBoost.receivedBias += _bias;
        addrBoost.receivedSlope += _slope;
      }
    } else {
      // If we are not cancelling, we set the bias
      // and slope
      if (!isCancelDelegation) {
        addrBoost.receivedSlope = _slope;
        addrBoost.receivedBias = _bias;
      }
    }

    uint32 currCP = _nCheckpoints > 0 && addrBoost.fromBlock == _blk
      ? _nCheckpoints - 1
      : _nCheckpoints;

    _boost[receiver][currCP] = Boost({
      delegatedSlope: addrBoost.delegatedSlope,
      receivedSlope: addrBoost.receivedSlope,
      delegatedBias: addrBoost.delegatedBias,
      receivedBias: addrBoost.receivedBias,
      nextExpiry: addrBoost.nextExpiry,
      fromBlock: currCP == _nCheckpoints ? uint32(_blk) : addrBoost.fromBlock,
      fromTimestamp: currCP == _nCheckpoints ? uint32(_ts) : addrBoost.fromTimestamp
    });

    if (currCP == _nCheckpoints) {
      numCheckpoints[receiver] = _nCheckpoints + 1;
    }
  }

  /***************************************
                    GETTERS
    ****************************************/

  /** @dev Floors a timestamp to the nearest weekly increment */
  function _floorToWeek(uint256 _t) internal pure returns (uint256) {
    return (_t / WEEK) * WEEK;
  }

  /**
   * @dev Uses binarysearch to find the most recent (user) point history preceeding block
   * @param _block Find the most recent point history before this block
   * @param _max Do not search pointHistories past this index
   * @param _addr User for which to search
   */
  function _findBlockEpoch(
    uint256 _block,
    uint256 _max,
    address _addr
  ) internal view returns (uint256) {
    bool isUserBlock = _addr != address(0);
    // Binary search
    uint256 min = 0;
    uint256 max = _max;
    // Will be always enough for 128-bit numbers
    for (uint256 i = 0; i < 128; i++) {
      if (min >= max) break;
      uint256 mid = (min + max + 1) / 2;
      if (
        (
          isUserBlock ? userPointHistory[_addr][mid].blk : pointHistory[mid].blk
        ) <= _block
      ) {
        min = mid;
      } else {
        max = mid - 1;
      }
    }
    return min;
  }

  /**
   * @dev Uses binarysearch to find the most recent user point history delegation preceeding block
   * @param _addr User for which to search
   * @param _block Find the most recent point history before this block
   * @return delegatedBias, delegatedSlope, receivedBias, receivedSlope, nextExpiry, fromTimestamp
   */
  function _findDelegationBlockEpoch(address _addr, uint256 _block)
    internal
    view
    returns (
      uint256,
      int128,
      uint256,
      int128,
      uint128,
      uint128
    )
  {
    require(_block <= block.number, "sRBN::getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[_addr];

    if (nCheckpoints == 0) {
      return (0, 0, 0, 0, 0, 0);
    }

    Boost memory cp;

    // First check most recent balance
    if (_boost[_addr][nCheckpoints - 1].fromBlock <= _block) {
      cp = _boost[_addr][nCheckpoints - 1];

      return (
        cp.delegatedBias,
        cp.delegatedSlope,
        cp.receivedBias,
        cp.receivedSlope,
        cp.nextExpiry,
        cp.fromTimestamp
      );
    }

    // Next check implicit zero balance
    if (_boost[_addr][0].fromBlock > _block) {
      return (0, 0, 0, 0, 0, 0);
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      cp = _boost[_addr][center];
      if (cp.fromBlock == _block) {
        return (
          cp.delegatedBias,
          cp.delegatedSlope,
          cp.receivedBias,
          cp.receivedSlope,
          cp.nextExpiry,
          cp.fromTimestamp
        );
      } else if (cp.fromBlock < _block) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    cp = _boost[_addr][lower];
    return (
      cp.delegatedBias,
      cp.delegatedSlope,
      cp.receivedBias,
      cp.receivedSlope,
      cp.nextExpiry,
      cp.fromTimestamp
    );
  }

  /**
   * @dev Calculates slope and bias using y = mx + b
   * @param _x current timestamp
   * @param _y current boost size
   * @param _expireTime expiry of boost
   * @return slope slope of boost
   * @return bias bias of boost
   */
  function _calcBiasSlope(
    int256 _x,
    int256 _y,
    int256 _expireTime
  ) internal pure returns (int128 slope, uint256 bias) {
    // SLOPE: (y2 - y1) / (x2 - x1)
    // BIAS: y = mx + b -> y - mx = b
    slope = SafeCast.toInt128(-_y / (_expireTime - _x));
    bias = SafeCast.toUint256(_y - slope * _x);
  }

  /**
   * @dev Calculates the boost size, slope, and bias
   * @param _addr address to check boost for
   * @param _isDelegator whether address is delegator or receiver of boost
   * @return boost size, slope, bias
   */
  function checkBoost(address _addr, bool _isDelegator)
    external
    view
    returns (
      uint256,
      int128,
      uint256
    )
  {
    uint32 nCheckpoints = numCheckpoints[_addr];

    // No boost exists
    if (nCheckpoints == 0 || (delegates[_addr] == address(0) && _isDelegator)) {
      return (0, 0, 0);
    }

    Boost memory addrBoost = _boost[_addr][nCheckpoints - 1];

    // No boost exists
    if (addrBoost.nextExpiry == 0 && _isDelegator) {
      return (0, 0, 0);
    }

    uint256 bias = _isDelegator
      ? addrBoost.delegatedBias
      : addrBoost.receivedBias;
    int128 slope = _isDelegator
      ? addrBoost.delegatedSlope
      : addrBoost.receivedSlope;

    int256 balance = slope *
      SafeCast.toInt256(block.timestamp) +
      SafeCast.toInt256(bias);

    // If we are delegator we get abs(balance)
    // If we are receiver we get min(balance, 0) of balance
    if (_isDelegator) {
      return (SafeCast.toUint256(StableMath.abs(balance)), slope, bias);
    } else {
      return (balance > 0 ? SafeCast.toUint256(balance) : 0, slope, bias);
    }
  }

  /**
   * @dev Gets current user voting weight (aka effectiveStake)
   * @param _owner User for which to return the balance
   * @return uint96 Balance of user
   */
  function getCurrentVotes(address _owner) public view returns (uint96) {
    uint256 epoch = userPointEpoch[_owner];
    if (epoch == 0) {
      return 0;
    }
    Point memory lastPoint = userPointHistory[_owner][epoch];
    lastPoint.bias =
      lastPoint.bias -
      (lastPoint.slope *
        SafeCast.toInt128(SafeCast.toInt256(block.timestamp - lastPoint.ts)));
    if (lastPoint.bias < 0) {
      lastPoint.bias = 0;
    }

    return SafeCast.toUint96(SafeCast.toUint256(lastPoint.bias));
  }

  /**
   * @dev Gets current user voting weight (aka effectiveStake) for a specific block
   * @param _owner User for which to return the balance
   * @param _blockNumber Block number to check
   * @return uint96 Balance of user
   */
  function balanceOfAt(address _owner, uint256 _blockNumber)
    public
    view
    returns (uint96)
  {
    require(_blockNumber <= block.number, "Must pass block number in the past");

    // Get most recent user Point to block
    uint256 userEpoch = _findBlockEpoch(
      _blockNumber,
      userPointEpoch[_owner],
      _owner
    );
    if (userEpoch == 0) {
      return 0;
    }
    Point memory upoint = userPointHistory[_owner][userEpoch];

    // Get most recent global Point to block
    uint256 maxEpoch = globalEpoch;
    uint256 epoch = _findBlockEpoch(_blockNumber, maxEpoch, address(0));
    Point memory point0 = pointHistory[epoch];

    // Calculate delta (block & time) between user Point and target block
    // Allowing us to calculate the average seconds per block between
    // the two points
    uint256 dBlock = 0;
    uint256 dTime = 0;
    if (epoch < maxEpoch) {
      Point memory point1 = pointHistory[epoch + 1];
      dBlock = point1.blk - point0.blk;
      dTime = point1.ts - point0.ts;
    } else {
      dBlock = block.number - point0.blk;
      dTime = block.timestamp - point0.ts;
    }
    // (Deterministically) Estimate the time at which block _blockNumber was mined
    uint256 blockTime = point0.ts;
    if (dBlock != 0) {
      blockTime = blockTime + ((dTime * (_blockNumber - point0.blk)) / dBlock);
    }
    // Current Bias = most recent bias - (slope * time since update)
    upoint.bias =
      upoint.bias -
      (upoint.slope * SafeCast.toInt128(int256(blockTime - upoint.ts)));
    if (upoint.bias >= 0) {
      return SafeCast.toUint96(SafeCast.toUint256(upoint.bias));
    } else {
      return 0;
    }
  }

  /**
   * @dev Gets a users votingWeight at a given blockNumber
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param _owner User for which to return the balance
   * @param _blockNumber Block at which to calculate balance
   * @return uint96 Balance of user
   */
  function getPriorVotes(address _owner, uint256 _blockNumber)
    public
    view
    override
    returns (uint96)
  {
    uint96 adjustedBalance = balanceOfAt(_owner, _blockNumber);

    (
      uint256 delegatedBias,
      int128 delegatedSlope,
      uint256 receivedBias,
      int128 receivedSlope,
      uint128 nextExpiry,
      uint128 ts
    ) = _findDelegationBlockEpoch(_owner, _blockNumber);

    if (nextExpiry != 0 && nextExpiry < ts) {
      // if the account has a negative boost in circulation
      // we over penalize by setting their adjusted balance to 0
      // this is because we don't want to iterate to find the real
      // value
      return 0;
    }

    if (delegatedBias != 0) {
      // we take the absolute value, since delegated boost can be negative
      // if any outstanding negative boosts are in circulation
      // this can inflate the vecrv balance of a user
      // taking the absolute value has the effect that it costs
      // a user to negatively impact another's vecrv balance
      adjustedBalance -= SafeCast.toUint96(
        SafeCast.toUint256(
          StableMath.abs(
            delegatedSlope *
              SafeCast.toInt256(block.timestamp) +
              SafeCast.toInt256(delegatedBias)
          )
        )
      );
    }

    if (receivedBias != 0) {
      // similar to delegated boost, our received boost can be negative
      // if any outstanding negative boosts are in our possession
      // However, unlike delegated boost, we do not negatively impact
      // our adjusted balance due to negative boosts. Instead we take
      // whichever is greater between 0 and the value of our received
      // boosts.
      int256 receivedBoost = receivedSlope *
        SafeCast.toInt256(block.timestamp) +
        SafeCast.toInt256(receivedBias);
      adjustedBalance += SafeCast.toUint96(
        uint256((receivedBoost > 0 ? SafeCast.toUint256(receivedBoost) : 0))
      );
    }

    // since we took the absolute value of our delegated boost, it now instead of
    // becoming negative is positive, and will continue to increase ...
    // meaning if we keep a negative outstanding delegated balance for long
    // enought it will not only decrease our vecrv_balance but also our received
    // boost, however we return the maximum between our adjusted balance and 0
    // when delegating boost, received boost isn't used for determining how
    // much we can delegate.

    return adjustedBalance > 0 ? adjustedBalance : 0;
  }

  /**
   * @dev Calculates total supply of votingWeight at a given time _t
   * @param _point Most recent point before time _t
   * @param _t Time at which to calculate supply
   * @return totalSupply at given point in time
   */
  function _supplyAt(Point memory _point, uint256 _t)
    internal
    view
    returns (uint256)
  {
    Point memory lastPoint = _point;
    // Floor the timestamp to weekly interval
    uint256 iterativeTime = _floorToWeek(lastPoint.ts);
    // Iterate through all weeks between _point & _t to account for slope changes
    for (uint256 i = 0; i < 255; i++) {
      iterativeTime = iterativeTime + WEEK;
      int128 dSlope = 0;
      // If week end is after timestamp, then truncate & leave dSlope to 0
      if (iterativeTime > _t) {
        iterativeTime = _t;
      }
      // else get most recent slope change
      else {
        dSlope = slopeChanges[iterativeTime];
      }

      lastPoint.bias =
        lastPoint.bias -
        (lastPoint.slope *
          SafeCast.toInt128(int256(iterativeTime - lastPoint.ts)));
      if (iterativeTime == _t) {
        break;
      }
      lastPoint.slope = lastPoint.slope + dSlope;
      lastPoint.ts = uint128(iterativeTime);
    }

    if (lastPoint.bias < 0) {
      lastPoint.bias = 0;
    }
    return SafeCast.toUint256(lastPoint.bias);
  }

  /**
   * @dev Calculates current total supply of votingWeight
   * @return totalSupply of voting token weight
   */
  function totalSupply() public view returns (uint256) {
    uint256 epoch_ = globalEpoch;
    Point memory lastPoint = pointHistory[epoch_];
    return _supplyAt(lastPoint, block.timestamp);
  }

  /**
   * @dev Calculates total supply of votingWeight at a given blockNumber (optional)
   * @param _blockNumber Block number at which to calculate total supply
   * @return totalSupply of voting token weight at the given blockNumber
   */
  function totalSupplyAt(uint256 _blockNumber) public view returns (uint256) {
    require(_blockNumber <= block.number, "Must pass block number in the past");

    uint256 epoch = globalEpoch;
    uint256 targetEpoch = _findBlockEpoch(_blockNumber, epoch, address(0));

    Point memory point = pointHistory[targetEpoch];

    // If point.blk > _blockNumber that means we got the initial epoch & contract did not yet exist
    if (point.blk > _blockNumber) {
      return 0;
    }

    uint256 dTime = 0;
    if (targetEpoch < epoch) {
      Point memory pointNext = pointHistory[targetEpoch + 1];
      if (point.blk != pointNext.blk) {
        dTime =
          ((_blockNumber - point.blk) * (pointNext.ts - point.ts)) /
          (pointNext.blk - point.blk);
      }
    } else if (point.blk != block.number) {
      dTime =
        ((_blockNumber - point.blk) * (block.timestamp - point.ts)) /
        (block.number - point.blk);
    }
    // Now dTime contains info on how far are we beyond point

    return _supplyAt(point, point.ts + dTime);
  }

  /**
   * @dev Get chain id
   */
  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract IIncentivisedVotingLockup {
  function getLastUserPoint(address _addr)
    external
    view
    virtual
    returns (
      int128 bias,
      int128 slope,
      uint256 ts
    );

  function createLock(uint256 _value, uint256 _unlockTime) external virtual;

  function withdraw() external virtual;

  function increaseLockAmount(uint256 _value) external virtual;

  function increaseLockLength(uint256 _unlockTime) external virtual;

  // Governor bravo methods
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    virtual
    returns (uint96);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
  function decimals() external view returns (uint8);

  function symbol() external view returns (string calldata);

  function name() external view returns (string calldata);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

interface ISmartWalletChecker {
  // Views
  function check(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title   StableMath
 * @author  mStable
 * @notice  A library providing safe mathematical operations to multiply and
 *          divide with standardised precision.
 * @dev     Derives from OpenZeppelin's SafeMath lib and uses generic system
 *          wide variables for managing precision.
 */
library StableMath {
  /**
   * @dev Scaling unit for use in specific calculations,
   * where 1 * 10**18, or 1e18 represents a unit '1'
   */
  uint256 private constant FULL_SCALE = 1e18;

  /**
   * @dev Token Ratios are used when converting between units of bAsset, mAsset and MTA
   * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
   * bAsset ratio unit for use in exact calculations,
   * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
   */
  uint256 private constant RATIO_SCALE = 1e8;

  /**
   * @dev Scales a given integer to the power of the full scale.
   * @param x   Simple uint256 to scale
   * @return    Scaled value a to an exact number
   */
  function scaleInteger(uint256 x) internal pure returns (uint256) {
    return x * FULL_SCALE;
  }

  /***************************************
              PRECISE ARITHMETIC
    ****************************************/

  /**
   * @dev Multiplies two precise units, and then truncates by the full scale
   * @param x     Left hand input to multiplication
   * @param y     Right hand input to multiplication
   * @return      Result after multiplying the two inputs and then dividing by the shared
   *              scale unit
   */
  function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulTruncateScale(x, y, FULL_SCALE);
  }

  /**
   * @dev Multiplies two precise units, and then truncates by the given scale. For example,
   * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
   * @param x     Left hand input to multiplication
   * @param y     Right hand input to multiplication
   * @param scale Scale unit
   * @return      Result after multiplying the two inputs and then dividing by the shared
   *              scale unit
   */
  function mulTruncateScale(
    uint256 x,
    uint256 y,
    uint256 scale
  ) internal pure returns (uint256) {
    // e.g. assume scale = fullScale
    // z = 10e18 * 9e17 = 9e36
    // return 9e36 / 1e18 = 9e18
    return (x * y) / scale;
  }

  /**
   * @dev Returns the downcasted int112 from int256, reverting on
   * overflow (when the input is less than smallest int112 or
   * greater than largest int112).
   *
   * Counterpart to Solidity's `int112` operator.
   *
   * Requirements:
   *
   * - input must fit into 112 bits
   *
   * _Available since v3.1._
   */
  function toInt112(int256 value) internal pure returns (int112) {
    require(
      value >= type(int112).min && value <= type(int112).max,
      "SafeCast: value doesn't fit in 112 bits"
    );
    return int112(value);
  }

  function abs(int256 x) internal pure returns (int256) {
    return x >= 0 ? x : -x;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library Root {
  /**
   * @dev Returns the square root of a given number
   * @param x Input
   * @return y Square root of Input
   */
  function sqrt(uint256 x) internal pure returns (uint256 y) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) {
        xx >>= 128;
        r <<= 64;
      }
      if (xx >= 0x10000000000000000) {
        xx >>= 64;
        r <<= 32;
      }
      if (xx >= 0x100000000) {
        xx >>= 32;
        r <<= 16;
      }
      if (xx >= 0x10000) {
        xx >>= 16;
        r <<= 8;
      }
      if (xx >= 0x100) {
        xx >>= 8;
        r <<= 4;
      }
      if (xx >= 0x10) {
        xx >>= 4;
        r <<= 2;
      }
      if (xx >= 0x8) {
        r <<= 1;
      }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint256(r < r1 ? r : r1);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}