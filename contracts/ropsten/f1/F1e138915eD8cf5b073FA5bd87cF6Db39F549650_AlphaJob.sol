// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../interfaces/external/IStrategy.sol';
import '../interfaces/IAlphaJob.sol';
import './Governable.sol';
import './Keep3rJob.sol';
import './Pausable.sol';

contract AlphaJob is IAlphaJob, Governable, Pausable, Keep3rJob {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet internal _strategies;

  constructor(
    address _governor,
    address _keep3r,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) Governable(_governor) Keep3rJob(_keep3r, _bond, _minBond, _earned, _age, _onlyEOA) {}

  function strategies() external view override returns (address[] memory _list) {
    _list = new address[](_strategies.length());
    for (uint256 i; i < _strategies.length(); i++) {
      _list[i] = _strategies.at(i);
    }
  }

  function addStrategy(address _strategy) external override onlyGovernor {
    if (_strategies.contains(_strategy)) revert StrategyAlreadyAdded();

    _strategies.add(_strategy);
    emit StrategyAddition(_strategy);
  }

  function revokeStrategy(address _strategy) external override onlyGovernor {
    if (!_strategies.contains(_strategy)) revert StrategyNotExistent();

    _strategies.remove(_strategy);
    emit StrategyRevokation(_strategy);
  }

  function workable() public view override returns (address _workableStrategy) {
    if (paused) return address(0);

    for (uint256 _i = 0; _i < _strategies.length(); _i++) {
      address _strategy = _strategies.at(_i);
      if (IStrategy(_strategy).shouldRebalance()) {
        return _strategy;
      }
    }
  }

  function workable(address _strategy) public view override returns (bool) {
    return !paused && IStrategy(_strategy).shouldRebalance();
  }

  function work(address _strategy) external override validateAndPayKeeper(msg.sender) {
    if (!workable(_strategy)) revert StrategyNotWorkable();
    IStrategy(_strategy).rebalance();
  }

  function forceWork(address _strategy) external override onlyGovernor {
    IStrategy(_strategy).rebalance();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IStrategy {
  function rebalance() external;

  function shouldRebalance() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';
import './IKeep3rJob.sol';
import './IPausable.sol';

interface IAlphaJob is IGovernable, IPausable, IKeep3rJob {
  // errors
  error StrategyNotWorkable();
  error StrategyNotExistent();
  error StrategyAlreadyAdded();

  // methods
  function strategies() external view returns (address[] memory _strategies);

  function addStrategy(address _strategy) external;

  function revokeStrategy(address _strategy) external;

  function workable() external view returns (address _workableStrategy);

  function workable(address _strategy) external view returns (bool _isWorkable);

  function work(address _strategy) external;

  function forceWork(address _strategy) external;

  // events
  event StrategyAddition(address _strategy);
  event StrategyRevokation(address _strategy);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IGovernable.sol';

abstract contract Governable is IGovernable {
  address public override governor;
  address public override pendingGovernor;

  constructor(address _governor) {
    if (_governor == address(0)) revert NoGovernorZeroAddress();
    governor = _governor;
  }

  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    if (_pendingGovernor == address(0)) revert NoGovernorZeroAddress();
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(governor, pendingGovernor);
  }

  function acceptPendingGovernor() external override onlyPendingGovernor {
    emit PendingGovernorAccepted(governor, pendingGovernor);
    governor = pendingGovernor;
    pendingGovernor = address(0);
  }

  modifier onlyGovernor {
    if (msg.sender != governor) revert OnlyGovernor();
    _;
  }

  modifier onlyPendingGovernor {
    if (msg.sender != pendingGovernor) revert OnlyPendingGovernor();
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import './Governable.sol';
import '../interfaces/IKeep3rJob.sol';
import '../interfaces/external/IKeep3rV1.sol';

abstract contract Keep3rJob is IKeep3rJob, Governable {
  address public override keep3r;
  address public override requiredBond;
  uint256 public override requiredMinBond;
  uint256 public override requiredEarnings;
  uint256 public override requiredAge;
  bool public override requiredEOA;

  constructor(
    address _keep3r,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) {
    keep3r = _keep3r;
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earned;
    requiredAge = _age;
    requiredEOA = _onlyEOA;
  }

  function setKeep3r(address _keep3r) public override onlyGovernor {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) public override onlyGovernor {
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earned;
    requiredAge = _age;
    requiredEOA = _onlyEOA;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age, _onlyEOA);
  }

  modifier validateAndPayKeeper(address _keeper) {
    _isValidKeeper(_keeper);
    _;
    IKeep3rV1(keep3r).worked(_keeper);
  }

  function _isValidKeeper(address _keeper) internal {
    // solhint-disable-next-line avoid-tx-origin
    if (requiredEOA && _keeper != tx.origin) revert KeeperNotEOA();

    if (requiredMinBond == 0 && requiredEarnings == 0 && requiredAge == 0) {
      if (!IKeep3rV1(keep3r).isKeeper(_keeper)) revert KeeperNotRegistered();
    } else {
      if (requiredBond == address(0)) {
        if (!IKeep3rV1(keep3r).isMinKeeper(_keeper, requiredMinBond, requiredEarnings, requiredAge)) revert KeeperNotValid();
      } else {
        if (!IKeep3rV1(keep3r).isBondedKeeper(_keeper, requiredBond, requiredMinBond, requiredEarnings, requiredAge)) revert KeeperNotValid();
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IPausable.sol';
import './Governable.sol';

abstract contract Pausable is IPausable, Governable {
  bool public override paused;

  function pause(bool _paused) external override onlyGovernor {
    if (paused == _paused) revert NoChangeInPause();
    paused = _paused;
    emit PauseChange(_paused);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IGovernable {
  // events
  event PendingGovernorSet(address _governor, address _pendingGovernor);
  event PendingGovernorAccepted(address _previousGovernor, address _newGovernor);

  // errors
  error NoGovernorZeroAddress();
  error OnlyGovernor();
  error OnlyPendingGovernor();

  // variables
  function governor() external view returns (address _governor);

  function pendingGovernor() external view returns (address _pendingGovernor);

  // methods
  function setPendingGovernor(address _pendingGovernor) external;

  function acceptPendingGovernor() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IKeep3rJob is IGovernable {
  // events
  event Keep3rSet(address _keep3r);
  event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA);

  // errors
  error KeeperNotEOA();
  error KeeperNotRegistered();
  error KeeperNotValid();

  // variables
  function keep3r() external view returns (address _keep3r);

  function requiredBond() external view returns (address _requiredBond);

  function requiredMinBond() external view returns (uint256 _requiredMinBond);

  function requiredEarnings() external view returns (uint256 _requiredEarnings);

  function requiredAge() external view returns (uint256 _requiredAge);

  function requiredEOA() external view returns (bool _requiredEOA);

  // methods
  function setKeep3r(address _keep3r) external;

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IPausable is IGovernable {
  // events
  event PauseChange(bool _paused);

  // errors
  error NoChangeInPause();

  // variables
  function paused() external view returns (bool _paused);

  // methods
  function pause(bool _paused) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

// solhint-disable func-name-mixedcase
interface IKeep3rV1 is IERC20, IERC20Metadata {
  // structs
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  // events
  event DelegateChanged(address indexed _delegator, address indexed _fromDelegate, address indexed _toDelegate);
  event DelegateVotesChanged(address indexed _delegate, uint256 _previousBalance, uint256 _newBalance);
  event SubmitJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event ApplyCredit(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event RemoveJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event UnbondJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event JobAdded(address indexed _job, uint256 _block, address _governance);
  event JobRemoved(address indexed _job, uint256 _block, address _governance);
  event KeeperWorked(address indexed _credit, address indexed _job, address indexed _keeper, uint256 _block, uint256 _amount);
  event KeeperBonding(address indexed _keeper, uint256 _block, uint256 _active, uint256 _bond);
  event KeeperBonded(address indexed _keeper, uint256 _block, uint256 _activated, uint256 _bond);
  event KeeperUnbonding(address indexed _keeper, uint256 _block, uint256 _deactive, uint256 _bond);
  event KeeperUnbound(address indexed _keeper, uint256 _block, uint256 _deactivated, uint256 _bond);
  event KeeperSlashed(address indexed _keeper, address indexed _slasher, uint256 _block, uint256 _slash);
  event KeeperDispute(address indexed _keeper, uint256 _block);
  event KeeperResolved(address indexed _keeper, uint256 _block);
  event AddCredit(address indexed _credit, address indexed _job, address indexed _creditor, uint256 _block, uint256 _amount);

  // variables
  function KPRH() external returns (address);

  function delegates(address _delegator) external view returns (address);

  function checkpoints(address _account, uint32 _checkpoint) external view returns (Checkpoint memory);

  function numCheckpoints(address _account) external view returns (uint32);

  function DOMAIN_TYPEHASH() external returns (bytes32);

  function DOMAINSEPARATOR() external returns (bytes32);

  function DELEGATION_TYPEHASH() external returns (bytes32);

  function PERMIT_TYPEHASH() external returns (bytes32);

  function nonces(address _user) external view returns (uint256);

  function BOND() external returns (uint256);

  function UNBOND() external returns (uint256);

  function LIQUIDITYBOND() external returns (uint256);

  function FEE() external returns (uint256);

  function BASE() external returns (uint256);

  function ETH() external returns (address);

  function bondings(address _user, address _bonding) external view returns (uint256);

  function unbondings(address _user, address _bonding) external view returns (uint256);

  function partialUnbonding(address _keeper, address _bonding) external view returns (uint256);

  function pendingbonds(address _keeper, address _bonding) external view returns (uint256);

  function bonds(address _keeper, address _bonding) external view returns (uint256);

  function votes(address _delegator) external view returns (uint256);

  function totalBonded() external returns (uint256);

  function firstSeen(address _keeper) external view returns (uint256);

  function disputes(address _keeper) external view returns (bool);

  function lastJob(address _keeper) external view returns (uint256);

  function workCompleted(address _keeper) external view returns (uint256);

  function jobs(address _job) external view returns (bool);

  function credits(address _job, address _credit) external view returns (uint256);

  function liquidityProvided(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityUnbonding(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityAmountsUnbonding(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function jobProposalDelay(address _job) external view returns (uint256);

  function liquidityApplied(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityAmount(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function keepers(address _keeper) external view returns (bool);

  function blacklist(address _keeper) external view returns (bool);

  function keeperList(uint256 _index) external view returns (address);

  function jobList(uint256 _index) external view returns (address);

  function governance() external returns (address);

  function pendingGovernance() external returns (address);

  function liquidityAccepted(address _liquidity) external view returns (bool);

  function liquidityPairs(uint256 _index) external view returns (address);

  // methods
  function getCurrentVotes(address _account) external view returns (uint256);

  function addCreditETH(address _job) external payable;

  function addCredit(
    address _credit,
    address _job,
    uint256 _amount
  ) external;

  function addVotes(address _voter, uint256 _amount) external;

  function removeVotes(address _voter, uint256 _amount) external;

  function addKPRCredit(address _job, uint256 _amount) external;

  function approveLiquidity(address _liquidity) external;

  function revokeLiquidity(address _liquidity) external;

  function pairs() external view returns (address[] memory);

  function addLiquidityToJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function applyCreditToJob(
    address _provider,
    address _liquidity,
    address _job
  ) external;

  function unbondLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function removeLiquidityFromJob(address _liquidity, address _job) external;

  function mint(uint256 _amount) external;

  function burn(uint256 _amount) external;

  function worked(address _keeper) external;

  function receipt(
    address _credit,
    address _keeper,
    uint256 _amount
  ) external;

  function receiptETH(address _keeper, uint256 _amount) external;

  function addJob(address _job) external;

  function getJobs() external view returns (address[] memory);

  function removeJob(address _job) external;

  function setKeep3rHelper(address _keep3rHelper) external;

  function setGovernance(address _governance) external;

  function acceptGovernance() external;

  function isKeeper(address _keeper) external returns (bool);

  function isMinKeeper(
    address _keeper,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool);

  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool);

  function bond(address _bonding, uint256 _amount) external;

  function getKeepers() external view returns (address[] memory);

  function activate(address _bonding) external;

  function unbond(address _bonding, uint256 _amount) external;

  function slash(
    address _bonded,
    address _keeper,
    uint256 _amount
  ) external;

  function withdraw(address _bonding) external;

  function dispute(address _keeper) external;

  function revoke(address _keeper) external;

  function resolve(address _keeper) external;

  function permit(
    address _owner,
    address _spender,
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

