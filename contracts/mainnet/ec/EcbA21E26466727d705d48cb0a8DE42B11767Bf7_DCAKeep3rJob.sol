// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../utils/Governable.sol';

import '../interfaces/IDCAKeep3rJob.sol';
import '../interfaces/IKeep3rV1.sol';
import '../interfaces/IDCASwapper.sol';

import '../libraries/CommonErrors.sol';

contract DCAKeep3rJob is IDCAKeep3rJob, Governable {
  using EnumerableSet for EnumerableSet.AddressSet;

  IDCAFactory public immutable override factory;
  IDCASwapper public override swapper;
  IKeep3rV1 public override keep3rV1;
  mapping(uint32 => uint32) internal _delay; // swap interval => delay
  EnumerableSet.AddressSet internal _subsidizedPairs;

  constructor(
    address _governor,
    IDCAFactory _factory,
    IKeep3rV1 _keep3rV1,
    IDCASwapper _swapper
  ) Governable(_governor) {
    if (address(_factory) == address(0) || address(_keep3rV1) == address(0) || address(_swapper) == address(0))
      revert CommonErrors.ZeroAddress();
    factory = _factory;
    keep3rV1 = _keep3rV1;
    swapper = _swapper;
  }

  function setKeep3rV1(IKeep3rV1 _keep3rV1) external override onlyGovernor {
    if (address(_keep3rV1) == address(0)) revert CommonErrors.ZeroAddress();
    keep3rV1 = _keep3rV1;
    emit Keep3rV1Set(_keep3rV1);
  }

  function setSwapper(IDCASwapper _swapper) external override onlyGovernor {
    if (address(_swapper) == address(0)) revert CommonErrors.ZeroAddress();
    swapper = _swapper;
    emit SwapperSet(_swapper);
  }

  function startSubsidizingPairs(address[] calldata _pairs) external override onlyGovernor {
    for (uint256 i; i < _pairs.length; i++) {
      if (!factory.isPair(_pairs[i])) revert InvalidPairAddress();
      _subsidizedPairs.add(_pairs[i]);
    }
    emit SubsidizingNewPairs(_pairs);
  }

  function stopSubsidizingPairs(address[] calldata _pairs) external override onlyGovernor {
    for (uint256 i; i < _pairs.length; i++) {
      _subsidizedPairs.remove(_pairs[i]);
    }
    emit StoppedSubsidizingPairs(_pairs);
  }

  function subsidizedPairs() external view override returns (address[] memory _pairs) {
    uint256 _length = _subsidizedPairs.length();
    _pairs = new address[](_length);
    for (uint256 i; i < _length; i++) {
      _pairs[i] = _subsidizedPairs.at(i);
    }
  }

  function setDelay(uint32 _swapInterval, uint32 __delay) external override onlyGovernor {
    _delay[_swapInterval] = __delay;
    emit DelaySet(_swapInterval, __delay);
  }

  function delay(uint32 _swapInterval) external view override returns (uint32 __delay) {
    __delay = _delay[_swapInterval];
    if (__delay == 0) {
      __delay = _swapInterval / 2;
    }
  }

  /**
   * This method isn't a view and it is extremelly expensive and inefficient.
   * DO NOT call this method on-chain, it is for off-chain purposes only.
   */
  function workable() external override returns (IDCASwapper.PairToSwap[] memory _pairs, uint32[] memory _smallestIntervals) {
    uint256 _count;
    // Count how many pairs can be swapped
    uint256 _length = _subsidizedPairs.length();
    for (uint256 i; i < _length; i++) {
      IDCAPair _pair = IDCAPair(_subsidizedPairs.at(i));
      bytes memory _swapPath = swapper.findBestSwap(_pair);
      uint32 _swapInterval = _getSmallestSwapInterval(_pair);
      if (_swapPath.length > 0 && _hasDelayPassedAlready(_pair, _swapInterval)) {
        _count++;
      }
    }
    // Create result array with correct size
    _pairs = new IDCASwapper.PairToSwap[](_count);
    _smallestIntervals = new uint32[](_count);

    // Fill result array
    for (uint256 i; i < _length; i++) {
      IDCAPair _pair = IDCAPair(_subsidizedPairs.at(i));
      bytes memory _swapPath = swapper.findBestSwap(_pair);
      uint32 _swapInterval = _getSmallestSwapInterval(_pair);
      if (_swapPath.length > 0 && _hasDelayPassedAlready(_pair, _swapInterval)) {
        _pairs[--_count] = IDCASwapper.PairToSwap({pair: _pair, swapPath: _swapPath});
        _smallestIntervals[_count] = _swapInterval;
      }
    }
  }

  /**
   * Takes an array of swaps, and executes as many as possible, returning the amount that was swapped
   */
  function work(IDCASwapper.PairToSwap[] calldata _pairsToSwap, uint32[] calldata _smallestIntervals)
    external
    override
    returns (uint256 _amountSwapped)
  {
    if (!keep3rV1.isKeeper(msg.sender)) revert NotAKeeper();
    for (uint256 i; i < _pairsToSwap.length; i++) {
      IDCAPair _pair = _pairsToSwap[i].pair;
      if (!_subsidizedPairs.contains(address(_pair))) {
        revert PairNotSubsidized();
      }
      if (!_hasDelayPassedAlready(_pair, _smallestIntervals[i])) {
        revert MustWaitDelay();
      }
    }
    _amountSwapped = swapper.swapPairs(_pairsToSwap);
    if (_amountSwapped == 0) revert NotWorked();
    keep3rV1.worked(msg.sender);
    emit Worked(_amountSwapped);
  }

  function _hasDelayPassedAlready(IDCAPair _pair, uint32 _swapInterval) internal view returns (bool) {
    uint32 _nextAvailable = _pair.nextSwapAvailable(_swapInterval);
    return _getTimestamp() >= _nextAvailable + this.delay(_swapInterval);
  }

  function _getSmallestSwapInterval(IDCAPair _pair) internal view returns (uint32 _minSwapInterval) {
    IDCAPair.NextSwapInformation memory _nextSwapInfo = _pair.getNextSwapInfo();
    for (uint256 i; i < _nextSwapInfo.amountOfSwaps; i++) {
      if (_minSwapInterval == 0 || _nextSwapInfo.swapsToPerform[i].interval < _minSwapInterval) {
        _minSwapInterval = _nextSwapInfo.swapsToPerform[i].interval;
      }
    }
  }

  function _getTimestamp() internal view virtual returns (uint32) {
    return uint32(block.timestamp);
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;

interface IGovernable {
  event PendingGovernorSet(address _pendingGovernor);
  event PendingGovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;

  function acceptPendingGovernor() external;

  function governor() external view returns (address);

  function pendingGovernor() external view returns (address);

  function isGovernor(address _account) external view returns (bool _isGovernor);

  function isPendingGovernor(address _account) external view returns (bool _isPendingGovernor);
}

abstract contract Governable is IGovernable {
  address private _governor;
  address private _pendingGovernor;

  constructor(address __governor) {
    require(__governor != address(0), 'Governable: zero address');
    _governor = __governor;
  }

  function governor() external view override returns (address) {
    return _governor;
  }

  function pendingGovernor() external view override returns (address) {
    return _pendingGovernor;
  }

  function setPendingGovernor(address __pendingGovernor) external virtual override onlyGovernor {
    _setPendingGovernor(__pendingGovernor);
  }

  function _setPendingGovernor(address __pendingGovernor) internal {
    require(__pendingGovernor != address(0), 'Governable: zero address');
    _pendingGovernor = __pendingGovernor;
    emit PendingGovernorSet(__pendingGovernor);
  }

  function acceptPendingGovernor() external virtual override onlyPendingGovernor {
    _acceptPendingGovernor();
  }

  function _acceptPendingGovernor() internal {
    require(_pendingGovernor != address(0), 'Governable: no pending governor');
    _governor = _pendingGovernor;
    _pendingGovernor = address(0);
    emit PendingGovernorAccepted();
  }

  function isGovernor(address _account) public view override returns (bool _isGovernor) {
    return _account == _governor;
  }

  function isPendingGovernor(address _account) public view override returns (bool _isPendingGovernor) {
    return _account == _pendingGovernor;
  }

  modifier onlyGovernor() {
    require(isGovernor(msg.sender), 'Governable: only governor');
    _;
  }

  modifier onlyPendingGovernor() {
    require(isPendingGovernor(msg.sender), 'Governable: only pending governor');
    _;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import './IDCAFactory.sol';
import './IDCASwapper.sol';
import './IKeep3rV1.sol';

/// @title Keep3r job that executes DCA swaps
/// @notice This contract will allow keep3rs to execute swaps and get paid with credits
interface IDCAKeep3rJob {
  /// @notice Emitted when new pairs are subsidized
  /// @param _pairs The address of the pairs that will now be subsidized
  event SubsidizingNewPairs(address[] _pairs);

  /// @notice Emitted when some pairs stop being subsidized
  /// @param _pairs The address of the pairs that will not be subsidized anymore
  event StoppedSubsidizingPairs(address[] _pairs);

  /// @notice Emitted when a new swapper is used
  /// @param _swapper The new swapper
  event SwapperSet(IDCASwapper _swapper);

  /// @notice Emitted when a keep3r is used
  /// @param _keep3rV1 The new keep3r
  event Keep3rV1Set(IKeep3rV1 _keep3rV1);

  /// @notice Emitted when swaps are executed
  /// @param _amountSwapped The amount of pairs that was swapped
  event Worked(uint256 _amountSwapped);

  /// @notice Emitted when a new delay is configured
  /// @param _swapInterval The swap interval that the delay will affect
  /// @param _delay The actual configured delay
  event DelaySet(uint32 _swapInterval, uint32 _delay);

  /// @notice Thrown when trying to subsidize an address that isn't a DCA pair
  error InvalidPairAddress();

  /// @notice Thrown when trying to work on a pair that is not being subsidized
  error PairNotSubsidized();

  /// @notice Thrown when the caller executing work is not a keeper
  error NotAKeeper();

  /// @notice Thrown when the caller tries to execute work with no pairs
  error NotWorked();

  /// @notice Thrown when a pair can technically be swapped, but the delay doesn't allow it
  error MustWaitDelay();

  /// @notice Returns a list of all the pairs that are currently subsidized
  /// @return _pairs An array with all the subsidized pairs
  function subsidizedPairs() external view returns (address[] memory _pairs);

  /// @notice Returns the Keep3r contract
  /// @return _keeper The Keep3r contract
  function keep3rV1() external view returns (IKeep3rV1 _keeper);

  /// @notice Returns the DCA factory
  /// @return _factory The DCA Factory
  function factory() external view returns (IDCAFactory _factory);

  /// @notice Returns the DCA swapper
  /// @return _swapper The DCA swapper
  function swapper() external view returns (IDCASwapper _swapper);

  /// @notice Returns the configured delay for a given swap interval
  /// @dev If none was configured, then it will return half the given swap interval
  /// @param _swapInterval The swap interval to check
  /// @return _delay The configured delay
  function delay(uint32 _swapInterval) external view returns (uint32 _delay);

  /// @notice Returns a list of pairs to swap, and also the smallest swap interval for each pair. The result should be sent to work
  /// @dev DO NOT call this method on-chain, it is for off-chain purposes only. Is is extremely expensive and innefficient
  /// @return _pairs An array with pairs and their swap path
  /// @return _smallestIntervals The smallest swap interval that can be swapped for each pair
  function workable() external returns (IDCASwapper.PairToSwap[] memory _pairs, uint32[] memory _smallestIntervals);

  /// @notice Sets a new address for the Keep3r contract
  /// @dev Will throw ZeroAddress if the zero address is passed
  /// @param _keep3rV1 The Keep3r contract
  function setKeep3rV1(IKeep3rV1 _keep3rV1) external;

  /// @notice Sets a new address for the swapper contract
  /// @dev Will throw ZeroAddress if the zero address is passed
  /// @param _swapper The swapper contract
  function setSwapper(IDCASwapper _swapper) external;

  /// @notice Adds some new pairs to the list of subsidized pairs
  /// @dev Will throw InvalidPairAddress if any of the given addresses is not a valid DCA pair
  /// @param _pairs The new pairs to add
  function startSubsidizingPairs(address[] calldata _pairs) external;

  /// @notice Removes some pairs from the list of subsidized pairs
  /// @param _pairs The pairs to remove
  function stopSubsidizingPairs(address[] calldata _pairs) external;

  /// @notice Sets a new delay for the given swap interval
  /// @param _swapInterval The swap interval that will be given the new delay
  /// @param _delay The new delay to set
  function setDelay(uint32 _swapInterval, uint32 _delay) external;

  /// @notice Takes a list of pairs to swap, and tries to swap as many as possible
  /// @dev The method checks how much gas is left, and stops before reaching the limit. So the
  /// last pairs in the array are less likely to be swapped. Will revert with:
  /// NotAKeeper if the caller is not a keep3r
  /// PairNotSubsidized if one of the given pairs is not subsidized
  /// MustWaitDelay if one of the given pairs must wait for the delay
  /// NotWorked if the caller tries to execute no pairs
  /// @param _pairs The list of pairs so swap
  /// @param _smallestIntervals The smallest swap interval that can be swapped for each pair
  /// @return _amountSwapped How many pairs were actually swapped
  function work(IDCASwapper.PairToSwap[] calldata _pairs, uint32[] calldata _smallestIntervals) external returns (uint256 _amountSwapped);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title The interface for Keep3r network
interface IKeep3rV1 is IERC20 {
  function name() external returns (string memory);

  // solhint-disable-next-line func-name-mixedcase
  function ETH() external view returns (address);

  function isKeeper(address _keeper) external returns (bool);

  function governance() external view returns (address);

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

  function addCreditETH(address job) external payable;

  function addCredit(
    address credit,
    address job,
    uint256 amount
  ) external;

  function addKPRCredit(address _job, uint256 _amount) external;

  function addJob(address _job) external;

  function removeJob(address _job) external;

  function addVotes(address voter, uint256 amount) external;

  function removeVotes(address voter, uint256 amount) external;

  function revoke(address keeper) external;

  function worked(address _keeper) external;

  function workReceipt(address _keeper, uint256 _amount) external;

  function receipt(
    address credit,
    address _keeper,
    uint256 _amount
  ) external;

  function receiptETH(address _keeper, uint256 _amount) external;

  function addLiquidityToJob(
    address liquidity,
    address job,
    uint256 amount
  ) external;

  function applyCreditToJob(
    address provider,
    address liquidity,
    address job
  ) external;

  function unbondLiquidityFromJob(
    address liquidity,
    address job,
    uint256 amount
  ) external;

  function removeLiquidityFromJob(address liquidity, address job) external;

  function bonds(address _keeper, address _credit) external view returns (uint256 _amount);

  function jobs(address _job) external view returns (bool);

  function jobList(uint256 _index) external view returns (address _job);

  function credits(address _job, address _credit) external view returns (uint256 _amount);

  function liquidityAccepted(address _liquidity) external view returns (bool);

  function liquidityProvided(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256 _amount);

  function liquidityApplied(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256 _amount);

  function liquidityAmount(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256 _amount);

  function liquidityUnbonding(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256 _amount);

  function liquidityAmountsUnbonding(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256 _amount);

  function bond(address bonding, uint256 amount) external;

  function activate(address bonding) external;

  function unbond(address bonding, uint256 amount) external;

  function withdraw(address bonding) external;

  function setGovernance(address _governance) external;

  function acceptGovernance() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import '../interfaces/IDCAPair.sol';
import '../utils/CollectableDust.sol';

/// @title The interface for a contract that can execute DCA swaps
/// @notice This contract will take a DCA swap and execute the opposite trade in a DEX
/// in order to return the expected funds and complete the swap
interface IDCASwapper is ICollectableDust {
  /// @notice A pair to swap
  struct PairToSwap {
    // The pair to swap
    IDCAPair pair;
    // Path to execute the best swap possible
    bytes swapPath;
  }

  /// @notice Emitted when a list of pairs is swapped correctly
  /// @param _pairsToSwap The list of swaps that was attempted to swap
  /// @param _amountSwapped The amount of pairs that was actually swapped
  event Swapped(PairToSwap[] _pairsToSwap, uint256 _amountSwapped);

  /// @notice Emitted when trying to swap an empty list of pairs
  error ZeroPairsToSwap();

  /// @notice Returns whether the swapper is paused or not
  /// @return _isPaused Whether the swapper is paused or not
  function paused() external view returns (bool _isPaused);

  /// @notice Takes a pair and tries to find the best swap for it
  /// @dev DO NOT call this method on-chain, it is for off-chain purposes only. Is is extremely expensive and innefficient
  /// @param _pair The pair to find the best swap for
  /// @return _swapPath The path to execute the best swap for the pair. Should be used when calling swapPairs.
  /// Will be empty (length = 0) if there is no path available and the pair can't be swapped.
  function findBestSwap(IDCAPair _pair) external returns (bytes memory _swapPath);

  /// @notice Takes a list of pairs to swap, and tries to swap as many as possible
  /// @dev The method checks how much gas is left, and stops before reaching the limit. So the
  /// last pairs in the array are less likely to be swapped.
  /// Will revert with ZeroPairsToSwap if _pairsToSwap is empty
  /// Will revert if called when paused
  /// @param _pairsToSwap The list of pairs so swap
  /// @return _amountSwapped How many pairs were actually swapped
  function swapPairs(PairToSwap[] calldata _pairsToSwap) external returns (uint256 _amountSwapped);

  /// @notice Pauses the swapper
  function pause() external;

  /// @notice Unpauses the swapper
  function unpause() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

library CommonErrors {
  error ZeroAddress();
  error Paused();
  error InsufficientLiquidity();
  error LiquidityNotReturned();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import './IDCAGlobalParameters.sol';

/// @title Factory of DCA pairs
/// @notice This is the contract you communicate with to create new pairs or query created ones
/// @dev This factory can return 4 errors for the creation of a pair.
/// PairAlreadyExists if the pair already exists.
/// IdenticalTokens if you send the same tokenA and tokenB.
/// ZeroAddress if tokenA or tokenB is the zero address.
/// PairNotSupported if the oracle does not support the pair.
interface IDCAFactoryPairsHandler {
  /// @notice Thrown when both tokens are equal
  error IdenticalTokens();
  /// @notice Thrown when trying to create a pair that already exists
  error PairAlreadyExists();

  /// @notice Emitted when a pair is created
  /// @param _tokenA The first token of the pair by address sort order
  /// @param _tokenB The second token of the pair by address sort order
  /// @param _pair The address of the created pair
  event PairCreated(address indexed _tokenA, address indexed _tokenB, address _pair);

  /// @notice Returns the global parameters contract
  /// @dev Global parameters has information about swaps and pairs, like swap intervals, fees charged, etc.
  /// @return The Global Parameters contract
  function globalParameters() external view returns (IDCAGlobalParameters);

  /// @notice Gets a pair by a set of tokens
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA first token of the pair
  /// @param _tokenB second token of the pair
  /// @return _pair Address of the pair if found, or zero address if it doesn't exist
  function pairByTokens(address _tokenA, address _tokenB) external view returns (address _pair);

  /// @notice Gets a list of all available pairs
  /// @dev Returns an array of addresses for each pair that is created
  /// @return _pairs Array of pair addresses
  function allPairs() external view returns (address[] memory _pairs);

  /// @notice Checks if address is a pair
  /// @param _address address to test if it is a pair address
  /// @return _isPair True if address is a pair, false if it is not
  function isPair(address _address) external view returns (bool _isPair);

  /// @notice Creates a pair for 2 tokens
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// If the pair already exists, it raises the PairAlreadyExists error.
  /// If both parameters are equal, raises the IdenticalTokens error.
  /// If one of the parameters is the zero address, raises the ZeroAddress error.
  /// If the oracle does not support the pair, raises the PairNotSupported error.
  /// @param _tokenA first token of the pair
  /// @param _tokenB second token of the pair
  /// @return pair Address of the newly created pair
  function createPair(address _tokenA, address _tokenB) external returns (address pair);
}

interface IDCAFactory is IDCAFactoryPairsHandler {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import './ITimeWeightedOracle.sol';
import './IDCATokenDescriptor.sol';

/// @title The interface for handling parameters the affect the whole DCA ecosystem
/// @notice This contract will manage configuration that affects all pairs, swappers, etc
interface IDCAGlobalParameters {
  /// @notice A compilation of all parameters that affect a swap
  struct SwapParameters {
    // The address of the fee recipient
    address feeRecipient;
    // Whether swaps are paused or not
    bool isPaused;
    // The swap fee
    uint32 swapFee;
    // The oracle contract
    ITimeWeightedOracle oracle;
  }

  /// @notice A compilation of all parameters that affect a loan
  struct LoanParameters {
    // The address of the fee recipient
    address feeRecipient;
    // Whether loans are paused or not
    bool isPaused;
    // The loan fee
    uint32 loanFee;
  }

  /// @notice Emitted when a new fee recipient is set
  /// @param _feeRecipient The address of the new fee recipient
  event FeeRecipientSet(address _feeRecipient);

  /// @notice Emitted when a new NFT descriptor is set
  /// @param _descriptor The new NFT descriptor contract
  event NFTDescriptorSet(IDCATokenDescriptor _descriptor);

  /// @notice Emitted when a new oracle is set
  /// @param _oracle The new oracle contract
  event OracleSet(ITimeWeightedOracle _oracle);

  /// @notice Emitted when a new swap fee is set
  /// @param _feeSet The new swap fee
  event SwapFeeSet(uint32 _feeSet);

  /// @notice Emitted when a new loan fee is set
  /// @param _feeSet The new loan fee
  event LoanFeeSet(uint32 _feeSet);

  /// @notice Emitted when new swap intervals are allowed
  /// @param _swapIntervals The new swap intervals
  /// @param _descriptions The descriptions for each swap interval
  event SwapIntervalsAllowed(uint32[] _swapIntervals, string[] _descriptions);

  /// @notice Emitted when some swap intervals are no longer allowed
  /// @param _swapIntervals The swap intervals that are no longer allowed
  event SwapIntervalsForbidden(uint32[] _swapIntervals);

  /// @notice Thrown when trying to set a fee higher than the maximum allowed
  error HighFee();

  /// @notice Thrown when trying to support new swap intervals, but the amount of descriptions doesn't match
  error InvalidParams();

  /// @notice Thrown when trying to support a new swap interval of value zero
  error ZeroInterval();

  /// @notice Thrown when trying a description for a new swap interval is empty
  error EmptyDescription();

  /// @notice Returns the address of the fee recipient
  /// @return _feeRecipient The address of the fee recipient
  function feeRecipient() external view returns (address _feeRecipient);

  /// @notice Returns fee charged on swaps
  /// @return _swapFee The fee itself
  function swapFee() external view returns (uint32 _swapFee);

  /// @notice Returns fee charged on loans
  /// @return _loanFee The fee itself
  function loanFee() external view returns (uint32 _loanFee);

  /// @notice Returns the NFT descriptor contract
  /// @return _nftDescriptor The contract itself
  function nftDescriptor() external view returns (IDCATokenDescriptor _nftDescriptor);

  /// @notice Returns the time-weighted oracle contract
  /// @return _oracle The contract itself
  function oracle() external view returns (ITimeWeightedOracle _oracle);

  /// @notice Returns the precision used for fees
  /// @dev Cannot be modified
  /// @return _precision The precision used for fees
  // solhint-disable-next-line func-name-mixedcase
  function FEE_PRECISION() external view returns (uint24 _precision);

  /// @notice Returns the max fee that can be set for either swap or loans
  /// @dev Cannot be modified
  /// @return _maxFee The maximum possible fee
  // solhint-disable-next-line func-name-mixedcase
  function MAX_FEE() external view returns (uint32 _maxFee);

  /// @notice Returns a list of all the allowed swap intervals
  /// @return _allowedSwapIntervals An array with all allowed swap intervals
  function allowedSwapIntervals() external view returns (uint32[] memory _allowedSwapIntervals);

  /// @notice Returns the description for a given swap interval
  /// @return _description The swap interval's description
  function intervalDescription(uint32 _swapInterval) external view returns (string memory _description);

  /// @notice Returns whether a swap interval is currently allowed
  /// @return _isAllowed Whether the given swap interval is currently allowed
  function isSwapIntervalAllowed(uint32 _swapInterval) external view returns (bool _isAllowed);

  /// @notice Returns whether swaps and loans are currently paused
  /// @return _isPaused Whether swaps and loans are currently paused
  function paused() external view returns (bool _isPaused);

  /// @notice Returns a compilation of all parameters that affect a swap
  /// @return _swapParameters All parameters that affect a swap
  function swapParameters() external view returns (SwapParameters memory _swapParameters);

  /// @notice Returns a compilation of all parameters that affect a loan
  /// @return _loanParameters All parameters that affect a loan
  function loanParameters() external view returns (LoanParameters memory _loanParameters);

  /// @notice Sets a new fee recipient address
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _feeRecipient The new fee recipient address
  function setFeeRecipient(address _feeRecipient) external;

  /// @notice Sets a new swap fee
  /// @dev Will rever with HighFee if the fee is higher than the maximum
  /// @param _fee The new swap fee
  function setSwapFee(uint32 _fee) external;

  /// @notice Sets a new loan fee
  /// @dev Will rever with HighFee if the fee is higher than the maximum
  /// @param _fee The new loan fee
  function setLoanFee(uint32 _fee) external;

  /// @notice Sets a new NFT descriptor
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _descriptor The new descriptor contract
  function setNFTDescriptor(IDCATokenDescriptor _descriptor) external;

  /// @notice Sets a new time-weighted oracle
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _oracle The new oracle contract
  function setOracle(ITimeWeightedOracle _oracle) external;

  /// @notice Adds new swap intervals to the allowed list
  /// @dev Will revert with:
  /// InvalidParams if the amount of swap intervals is different from the amount of descriptions passed
  /// ZeroInterval if any of the swap intervals is zero
  /// EmptyDescription if any of the descriptions is empty
  /// @param _swapIntervals The new swap intervals
  /// @param _descriptions Their descriptions
  function addSwapIntervalsToAllowedList(uint32[] calldata _swapIntervals, string[] calldata _descriptions) external;

  /// @notice Removes some swap intervals from the allowed list
  /// @param _swapIntervals The swap intervals to remove
  function removeSwapIntervalsFromAllowedList(uint32[] calldata _swapIntervals) external;

  /// @notice Pauses all swaps and loans
  function pause() external;

  /// @notice Unpauses all swaps and loans
  function unpause() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

/// @title The interface for an oracle that provies TWAP quotes
/// @notice These methods allow users to add support for pairs, and then ask for quotes
interface ITimeWeightedOracle {
  /// @notice Emitted when the oracle add supports for a new pair
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  event AddedSupportForPair(address _tokenA, address _tokenB);

  /// @notice Returns whether this oracle can support this pair of tokens
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  /// @return _canSupport Whether the given pair of tokens can be supported by the oracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool _canSupport);

  /// @notice Returns a quote, based on the given tokens and amount
  /// @param _tokenIn The token that will be provided
  /// @param _amountIn The amount that will be provided
  /// @param _tokenOut The token we would like to quote
  /// @return _amountOut How much _tokenOut will be returned in exchange for _amountIn amount of _tokenIn
  function quote(
    address _tokenIn,
    uint128 _amountIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut);

  /// @notice Add support for a given pair to the contract. This function will let the oracle take some actions to
  /// configure the pair for future quotes. Could be called more than one in order to let the oracle re-configure for a new context.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function addSupportForPair(address _tokenA, address _tokenB) external;
}

/// @title An implementation of ITimeWeightedOracle that uses Uniswap V3 pool oracles
/// @notice This oracle will attempt to use all fee tiers of the same pair when calculating quotes
interface IUniswapV3OracleAggregator is ITimeWeightedOracle {
  /// @notice Emitted when a new fee tier is added
  /// @return _feeTier The added fee tier
  event AddedFeeTier(uint24 _feeTier);

  /// @notice Emitted when a new period is set
  /// @return _period The new period
  event PeriodChanged(uint32 _period);

  /// @notice Returns the Uniswap V3 Factory
  /// @return _factory The Uniswap V3 Factory
  function factory() external view returns (IUniswapV3Factory _factory);

  /// @notice Returns a list of all supported Uniswap V3 fee tiers
  /// @return _feeTiers An array of all supported fee tiers
  function supportedFeeTiers() external view returns (uint24[] memory _feeTiers);

  /// @notice Returns a list of all Uniswap V3 pools used for a given pair
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @return _pools An array with all pools used for quoting the given pair
  function poolsUsedForPair(address _tokenA, address _tokenB) external view returns (address[] memory _pools);

  /// @notice Returns the period used for the TWAP calculation
  /// @return _period The period used for the TWAP
  function period() external view returns (uint16 _period);

  /// @notice Returns minimum possible period
  /// @dev Cannot be modified
  /// @return The minimum possible period
  // solhint-disable-next-line func-name-mixedcase
  function MINIMUM_PERIOD() external view returns (uint16);

  /// @notice Returns maximum possible period
  /// @dev Cannot be modified
  /// @return The maximum possible period
  // solhint-disable-next-line func-name-mixedcase
  function MAXIMUM_PERIOD() external view returns (uint16);

  /// @notice Returns the minimum liquidity that a pool needs to have in order to be used for a pair's quote
  /// @dev This check is only performed when adding support for a pair. If the pool's liquidity then
  /// goes below the threshold, then it will still be used for the quote calculation
  /// @return The minimum liquidity threshold
  // solhint-disable-next-line func-name-mixedcase
  function MINIMUM_LIQUIDITY_THRESHOLD() external view returns (uint16);

  /// @notice Adds support for a new Uniswap V3 fee tier
  /// @dev Will revert if the provided fee tier is not supported by Uniswap V3
  /// @param _feeTier The new fee tier
  function addFeeTier(uint24 _feeTier) external;

  /// @notice Sets the period to be used for the TWAP calculation
  /// @dev Will revert it is lower than MINIMUM_PERIOD or greater than MAXIMUM_PERIOD
  /// WARNING: increasing the period could cause big problems, because Uniswap V3 pools might not support a TWAP so old.
  /// @param _period The new period
  function setPeriod(uint16 _period) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import './IDCAPair.sol';

/// @title The interface for generating a token's description
/// @notice Contracts that implement this interface must return a base64 JSON with the entire description
interface IDCATokenDescriptor {
  /// @notice Generates a token's description, both the JSON and the image inside
  /// @param _positionHandler The pair where the position was created
  /// @param _tokenId The token/position id
  /// @return _description The position's description
  function tokenURI(IDCAPairPositionHandler _positionHandler, uint256 _tokenId) external view returns (string memory _description);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './IDCAGlobalParameters.sol';

/// @title The interface for all state related queries
/// @notice These methods allow users to read the pair's current values
interface IDCAPairParameters {
  /// @notice Returns the global parameters contract
  /// @dev Global parameters has information about swaps and pairs, like swap intervals, fees charged, etc.
  /// @return The Global Parameters contract
  function globalParameters() external view returns (IDCAGlobalParameters);

  /// @notice Returns the token A contract
  /// @return The contract for token A
  function tokenA() external view returns (IERC20Metadata);

  /// @notice Returns the token B contract
  /// @return The contract for token B
  function tokenB() external view returns (IERC20Metadata);

  /// @notice Returns how much will the amount to swap differ from the previous swap
  /// @dev f.e. if the returned value is -100, then the amount to swap will be 100 less than the swap just before it
  /// @param _swapInterval The swap interval to check
  /// @param _from The 'from' token of the deposits
  /// @param _swap The swap number to check
  /// @return _delta How much will the amount to swap differ, when compared to the swap just before this one
  function swapAmountDelta(
    uint32 _swapInterval,
    address _from,
    uint32 _swap
  ) external view returns (int256 _delta);

  /// @notice Returns if a certain swap interval is active or not
  /// @dev We consider a swap interval to be active if there is at least one active position on that interval
  /// @param _swapInterval The swap interval to check
  /// @return _isActive Whether the given swap interval is currently active
  function isSwapIntervalActive(uint32 _swapInterval) external view returns (bool _isActive);

  /// @notice Returns the amount of swaps executed for a certain interval
  /// @param _swapInterval The swap interval to check
  /// @return _swaps The amount of swaps performed on the given interval
  function performedSwaps(uint32 _swapInterval) external view returns (uint32 _swaps);
}

/// @title The interface for all position related matters in a DCA pair
/// @notice These methods allow users to create, modify and terminate their positions
interface IDCAPairPositionHandler is IDCAPairParameters {
  /// @notice The position of a certain user
  struct UserPosition {
    // The token that the user deposited and will be swapped in exchange for "to"
    IERC20Metadata from;
    // The token that the user will get in exchange for their "from" tokens in each swap
    IERC20Metadata to;
    // How frequently the position's swaps should be executed
    uint32 swapInterval;
    // How many swaps were executed since deposit, last modification, or last withdraw
    uint32 swapsExecuted;
    // How many "to" tokens can currently be withdrawn
    uint256 swapped;
    // How many swaps left the position has to execute
    uint32 swapsLeft;
    // How many "from" tokens there are left to swap
    uint256 remaining;
    // How many "from" tokens need to be traded in each swap
    uint160 rate;
  }

  /// @notice Emitted when a position is terminated
  /// @param _user The address of the user that terminated the position
  /// @param _dcaId The id of the position that was terminated
  /// @param _returnedUnswapped How many "from" tokens were returned to the caller
  /// @param _returnedSwapped How many "to" tokens were returned to the caller
  event Terminated(address indexed _user, uint256 _dcaId, uint256 _returnedUnswapped, uint256 _returnedSwapped);

  /// @notice Emitted when a position is created
  /// @param _user The address of the user that created the position
  /// @param _dcaId The id of the position that was created
  /// @param _fromToken The address of the "from" token
  /// @param _rate How many "from" tokens need to be traded in each swap
  /// @param _startingSwap The number of the swap when the position will be executed for the first time
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _lastSwap The number of the swap when the position will be executed for the last time
  event Deposited(
    address indexed _user,
    uint256 _dcaId,
    address _fromToken,
    uint160 _rate,
    uint32 _startingSwap,
    uint32 _swapInterval,
    uint32 _lastSwap
  );

  /// @notice Emitted when a user withdraws all swapped tokens from a position
  /// @param _user The address of the user that executed the withdraw
  /// @param _dcaId The id of the position that was affected
  /// @param _token The address of the withdrawn tokens. It's the same as the position's "to" token
  /// @param _amount The amount that was withdrawn
  event Withdrew(address indexed _user, uint256 _dcaId, address _token, uint256 _amount);

  /// @notice Emitted when a user withdraws all swapped tokens from many positions
  /// @param _user The address of the user that executed the withdraw
  /// @param _dcaIds The ids of the positions that were affected
  /// @param _swappedTokenA The total amount that was withdrawn in token A
  /// @param _swappedTokenB The total amount that was withdrawn in token B
  event WithdrewMany(address indexed _user, uint256[] _dcaIds, uint256 _swappedTokenA, uint256 _swappedTokenB);

  /// @notice Emitted when a position is modified
  /// @param _user The address of the user that modified the position
  /// @param _dcaId The id of the position that was modified
  /// @param _rate How many "from" tokens need to be traded in each swap
  /// @param _startingSwap The number of the swap when the position will be executed for the first time
  /// @param _lastSwap The number of the swap when the position will be executed for the last time
  event Modified(address indexed _user, uint256 _dcaId, uint160 _rate, uint32 _startingSwap, uint32 _lastSwap);

  /// @notice Thrown when a user tries to create a position with a token that is neither token A nor token B
  error InvalidToken();

  /// @notice Thrown when a user tries to create that a position with an unsupported swap interval
  error InvalidInterval();

  /// @notice Thrown when a user tries operate on a position that doesn't exist (it might have been already terminated)
  error InvalidPosition();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /// @notice Thrown when a user tries to create or modify a position by setting the rate to be zero
  error ZeroRate();

  /// @notice Thrown when a user tries to create a position with zero swaps
  error ZeroSwaps();

  /// @notice Thrown when a user tries to add zero funds to their position
  error ZeroAmount();

  /// @notice Thrown when a user tries to modify the rate of a position that has already been completed
  error PositionCompleted();

  /// @notice Thrown when a user tries to modify a position that has too much swapped balance. This error
  /// is thrown so that the user doesn't lose any funds. The error indicates that the user must perform a withdraw
  /// before modifying their position
  error MandatoryWithdraw();

  /// @notice Returns a DCA position
  /// @param _dcaId The id of the position
  /// @return _position The position itself
  function userPosition(uint256 _dcaId) external view returns (UserPosition memory _position);

  /// @notice Creates a new position
  /// @dev Will revert:
  /// With InvalidToken if _tokenAddress is neither token A nor token B
  /// With ZeroRate if _rate is zero
  /// With ZeroSwaps if _amountOfSwaps is zero
  /// With InvalidInterval if _swapInterval is not a valid swap interval
  /// @param _tokenAddress The address of the token that will be deposited
  /// @param _rate How many "from" tokens need to be traded in each swap
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @return _dcaId The id of the created position
  function deposit(
    address _tokenAddress,
    uint160 _rate,
    uint32 _amountOfSwaps,
    uint32 _swapInterval
  ) external returns (uint256 _dcaId);

  /// @notice Withdraws all swapped tokens from a position
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// @param _dcaId The position's id
  /// @return _swapped How much was withdrawn
  function withdrawSwapped(uint256 _dcaId) external returns (uint256 _swapped);

  /// @notice Withdraws all swapped tokens from many positions
  /// @dev Will revert:
  /// With InvalidPosition if any of the ids in _dcaIds is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to any of the positions in _dcaIds
  /// @param _dcaIds The positions' ids
  /// @return _swappedTokenA How much was withdrawn in token A
  /// @return _swappedTokenB How much was withdrawn in token B
  function withdrawSwappedMany(uint256[] calldata _dcaIds) external returns (uint256 _swappedTokenA, uint256 _swappedTokenB);

  /// @notice Modifies the rate of a position. Could request more funds or return deposited funds
  /// depending on whether the new rate is greater than the previous one.
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With PositionCompleted if position has already been completed
  /// With ZeroRate if _newRate is zero
  /// With MandatoryWithdraw if the user must execute a withdraw before modifying their position
  /// @param _dcaId The position's id
  /// @param _newRate The new rate to set
  function modifyRate(uint256 _dcaId, uint160 _newRate) external;

  /// @notice Modifies the amount of swaps of a position. Could request more funds or return
  /// deposited funds depending on whether the new amount of swaps is greater than the swaps left.
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With MandatoryWithdraw if the user must execute a withdraw before modifying their position
  /// @param _dcaId The position's id
  /// @param _newSwaps The new amount of swaps
  function modifySwaps(uint256 _dcaId, uint32 _newSwaps) external;

  /// @notice Modifies both the rate and amount of swaps of a position. Could request more funds or return
  /// deposited funds depending on whether the new parameters require more or less than the the unswapped funds.
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroRate if _newRate is zero
  /// With MandatoryWithdraw if the user must execute a withdraw before modifying their position
  /// @param _dcaId The position's id
  /// @param _newRate The new rate to set
  /// @param _newSwaps The new amount of swaps
  function modifyRateAndSwaps(
    uint256 _dcaId,
    uint160 _newRate,
    uint32 _newSwaps
  ) external;

  /// @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroAmount if _amount is zero
  /// With ZeroSwaps if _newSwaps is zero
  /// With MandatoryWithdraw if the user must execute a withdraw before modifying their position
  /// @param _dcaId The position's id
  /// @param _amount Amounts of funds to add to the position
  /// @param _newSwaps The new amount of swaps
  function addFundsToPosition(
    uint256 _dcaId,
    uint256 _amount,
    uint32 _newSwaps
  ) external;

  /// @notice Terminates the position and sends all unswapped and swapped balance to the caller
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// @param _dcaId The position's id
  function terminate(uint256 _dcaId) external;
}

/// @title The interface for all swap related matters in a DCA pair
/// @notice These methods allow users to get information about the next swap, and how to execute it
interface IDCAPairSwapHandler {
  /// @notice Information about an available swap for a specific swap interval
  struct SwapInformation {
    // The affected swap interval
    uint32 interval;
    // The number of the swap that will be performed
    uint32 swapToPerform;
    // The amount of token A that needs swapping
    uint256 amountToSwapTokenA;
    // The amount of token B that needs swapping
    uint256 amountToSwapTokenB;
  }

  /// @notice All information about the next swap
  struct NextSwapInformation {
    // All swaps that can be executed
    SwapInformation[] swapsToPerform;
    // How many entries of the swapsToPerform array are valid
    uint8 amountOfSwaps;
    // How much can be borrowed in token A during a flash swap
    uint256 availableToBorrowTokenA;
    // How much can be borrowed in token B during a flash swap
    uint256 availableToBorrowTokenB;
    // How much 10**decimals(tokenB) is when converted to token A
    uint256 ratePerUnitBToA;
    // How much 10**decimals(tokenA) is when converted to token B
    uint256 ratePerUnitAToB;
    // How much token A will be sent to the platform in terms of fee
    uint256 platformFeeTokenA;
    // How much token B will be sent to the platform in terms of fee
    uint256 platformFeeTokenB;
    // The amount of tokens that need to be provided by the swapper
    uint256 amountToBeProvidedBySwapper;
    // The amount of tokens that will be sent to the swapper optimistically
    uint256 amountToRewardSwapperWith;
    // The token that needs to be provided by the swapper
    IERC20Metadata tokenToBeProvidedBySwapper;
    // The token that will be sent to the swapper optimistically
    IERC20Metadata tokenToRewardSwapperWith;
  }

  /// @notice Emitted when a swap is executed
  /// @param _sender The address of the user that initiated the swap
  /// @param _to The address that received the reward + loan
  /// @param _amountBorrowedTokenA How much was borrowed in token A
  /// @param _amountBorrowedTokenB How much was borrowed in token B
  /// @param _fee How much was charged as a swap fee to position owners
  /// @param _nextSwapInformation All information related to the swap
  event Swapped(
    address indexed _sender,
    address indexed _to,
    uint256 _amountBorrowedTokenA,
    uint256 _amountBorrowedTokenB,
    uint32 _fee,
    NextSwapInformation _nextSwapInformation
  );

  /// @notice Thrown when trying to execute a swap, but none is available
  error NoSwapsToExecute();

  /// @notice Returns when the next swap will be available for a given swap interval
  /// @param _swapInterval The swap interval to check
  /// @return _when The moment when the next swap will be available. Take into account that if the swap is already available, this result could
  /// be in the past
  function nextSwapAvailable(uint32 _swapInterval) external view returns (uint32 _when);

  /// @notice Returns the amount of tokens that needed swapping in the last swap, for all positions in the given swap interval that were deposited in the given token
  /// @param _swapInterval The swap interval to check
  /// @param _from The address of the token that all positions used to deposit
  /// @return _amount The amount that needed swapping in the last swap
  function swapAmountAccumulator(uint32 _swapInterval, address _from) external view returns (uint256);

  /// @notice Returns all information related to the next swap
  /// @return _nextSwapInformation The information about the next swap
  function getNextSwapInfo() external view returns (NextSwapInformation memory _nextSwapInformation);

  /// @notice Executes a swap
  /// @dev This method assumes that the required amount has already been sent. Will revert with:
  /// Paused if swaps are paused by protocol
  /// NoSwapsToExecute if there are no swaps to execute
  /// LiquidityNotReturned if the required tokens were not sent before calling the function
  function swap() external;

  /// @notice Executes a flash swap
  /// @dev Will revert with:
  /// Paused if swaps are paused by protocol
  /// NoSwapsToExecute if there are no swaps to execute
  /// InsufficientLiquidity if asked to borrow more than the actual reserves
  /// LiquidityNotReturned if the required tokens were not back during the callback
  /// @param _amountToBorrowTokenA How much to borrow in token A
  /// @param _amountToBorrowTokenB How much to borrow in token B
  /// @param _to Address to send the reward + the borrowed tokens
  /// @param _data Bytes to send to the caller during the callback. If this parameter is empty, the callback won't be executed
  function swap(
    uint256 _amountToBorrowTokenA,
    uint256 _amountToBorrowTokenB,
    address _to,
    bytes calldata _data
  ) external;

  /// @notice Returns how many seconds left until the next swap is available
  /// @return _secondsUntilNextSwap The amount of seconds until next swap. Returns 0 if a swap can already be executed
  function secondsUntilNextSwap() external view returns (uint32 _secondsUntilNextSwap);
}

/// @title The interface for all loan related matters in a DCA pair
/// @notice These methods allow users to ask how much is available for loans, and also to execute them
interface IDCAPairLoanHandler {
  /// @notice Emitted when a flash loan is executed
  /// @param _sender The address of the user that initiated the loan
  /// @param _to The address that received the loan
  /// @param _amountBorrowedTokenA How much was borrowed in token A
  /// @param _amountBorrowedTokenB How much was borrowed in token B
  /// @param _loanFee How much was charged as a fee
  event Loaned(address indexed _sender, address indexed _to, uint256 _amountBorrowedTokenA, uint256 _amountBorrowedTokenB, uint32 _loanFee);

  // @notice Thrown when trying to execute a flash loan but without actually asking for tokens
  error ZeroLoan();

  /// @notice Returns the amount of tokens that can be asked for during a flash loan
  /// @return _amountToBorrowTokenA The amount of token A that is available for borrowing
  /// @return _amountToBorrowTokenB The amount of token B that is available for borrowing
  function availableToBorrow() external view returns (uint256 _amountToBorrowTokenA, uint256 _amountToBorrowTokenB);

  /// @notice Executes a flash loan, sending the required amounts to the specified loan recipient
  /// @dev Will revert:
  /// With ZeroLoan if both _amountToBorrowTokenA & _amountToBorrowTokenB are 0
  /// With Paused if loans are paused by protocol
  /// With InsufficientLiquidity if asked for more that reserves
  /// @param _amountToBorrowTokenA The amount to borrow in token A
  /// @param _amountToBorrowTokenB The amount to borrow in token B
  /// @param _to Address that will receive the loan. This address should be a contract that implements IDCAPairLoanCallee
  /// @param _data Any data that should be passed through to the callback
  function loan(
    uint256 _amountToBorrowTokenA,
    uint256 _amountToBorrowTokenB,
    address _to,
    bytes calldata _data
  ) external;
}

interface IDCAPair is IDCAPairParameters, IDCAPairSwapHandler, IDCAPairPositionHandler, IDCAPairLoanHandler {}

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface ICollectableDust {
  event DustSent(address _to, address token, uint256 amount);

  // solhint-disable-next-line func-name-mixedcase
  function ETH() external view returns (address);

  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external;
}

abstract contract CollectableDust is ICollectableDust {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  address public constant override ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  EnumerableSet.AddressSet internal _protocolTokens;

  function _addProtocolToken(address _token) internal {
    require(!_protocolTokens.contains(_token), 'CollectableDust: token already part of protocol');
    _protocolTokens.add(_token);
  }

  function _removeProtocolToken(address _token) internal {
    require(_protocolTokens.contains(_token), 'CollectableDust: token is not part of protocol');
    _protocolTokens.remove(_token);
  }

  function _sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    require(_to != address(0), 'CollectableDust: zero address');
    require(!_protocolTokens.contains(_token), 'CollectableDust: token is part of protocol');
    if (_token == ETH) {
      payable(_to).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
    emit DustSent(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

