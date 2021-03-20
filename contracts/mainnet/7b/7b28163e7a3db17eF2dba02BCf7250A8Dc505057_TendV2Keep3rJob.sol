// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./V2Keep3rJob.sol";

contract TendV2Keep3rJob is V2Keep3rJob {
    constructor(
        address _mechanicsRegistry,
        address _keep3r,
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age,
        bool _onlyEOA,
        address _keep3rHelper,
        address _slidingOracle,
        address _v2Keeper
    ) public V2Keep3rJob(_mechanicsRegistry, _keep3r, _bond, _minBond, _earned, _age, _onlyEOA, _keep3rHelper, _slidingOracle, _v2Keeper, 0) {}

    function workable(address _strategy) external view override returns (bool) {
        return _workable(_strategy);
    }

    function _workable(address _strategy) internal view override returns (bool) {
        if (!super._workable(_strategy)) return false;
        (, uint256 _ethCallCost) = _getCallCosts(_strategy);
        return IBaseStrategy(_strategy).tendTrigger(_ethCallCost);
    }

    function _work(address _strategy) internal override {
        V2Keeper.tend(_strategy);
    }

    // Keep3r actions
    function work(address _strategy) external override returns (uint256 _credits) {
        return workForBond(_strategy);
    }

    function workForBond(address _strategy) public override notPaused onlyKeeper returns (uint256 _credits) {
        _credits = _workInternal(_strategy, false);
        _paysKeeperAmount(msg.sender, _credits);
    }

    function workForTokens(address _strategy) external override notPaused onlyKeeper returns (uint256 _credits) {
        _credits = _workInternal(_strategy, true);
        _paysKeeperInTokens(msg.sender, _credits);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@lbertenasco/contract-utils/contracts/abstract/MachineryReady.sol";
import "@lbertenasco/contract-utils/interfaces/keep3r/IKeep3rV1Helper.sol";
import "@lbertenasco/contract-utils/contracts/keep3r/Keep3rAbstract.sol";

import "../../interfaces/jobs/v2/IV2Keeper.sol";

import "../../interfaces/jobs/v2/IV2Keep3rJob.sol";
import "../../interfaces/yearn/IBaseStrategy.sol";
import "../../interfaces/keep3r/IUniswapV2SlidingOracle.sol";

abstract contract V2Keep3rJob is MachineryReady, Keep3r, IV2Keep3rJob {
    using SafeMath for uint256;

    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint256 public constant PRECISION = 1_000;
    uint256 public constant MAX_REWARD_MULTIPLIER = 1 * PRECISION; // 1x max reward multiplier
    uint256 public override rewardMultiplier;

    IV2Keeper public V2Keeper;
    address public keep3rHelper;
    address public slidingOracle;

    EnumerableSet.AddressSet internal _availableStrategies;

    mapping(address => uint256) public requiredAmount;
    mapping(address => uint256) public lastWorkAt;

    uint256 public workCooldown;

    constructor(
        address _mechanicsRegistry,
        address _keep3r,
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age,
        bool _onlyEOA,
        address _keep3rHelper,
        address _slidingOracle,
        address _v2Keeper,
        uint256 _workCooldown
    ) public MachineryReady(_mechanicsRegistry) Keep3r(_keep3r) {
        _setKeep3rRequirements(_bond, _minBond, _earned, _age, _onlyEOA);
        V2Keeper = IV2Keeper(_v2Keeper);
        keep3rHelper = _keep3rHelper;
        slidingOracle = _slidingOracle;
        if (_workCooldown > 0) _setWorkCooldown(_workCooldown);
    }

    // Keep3r Setters
    function setKeep3r(address _keep3r) external override onlyGovernor {
        _setKeep3r(_keep3r);
    }

    function setKeep3rRequirements(
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age,
        bool _onlyEOA
    ) external override onlyGovernor {
        _setKeep3rRequirements(_bond, _minBond, _earned, _age, _onlyEOA);
    }

    function setRewardMultiplier(uint256 _rewardMultiplier) external override onlyGovernorOrMechanic {
        _setRewardMultiplier(_rewardMultiplier);
        emit SetRewardMultiplier(_rewardMultiplier);
    }

    function _setRewardMultiplier(uint256 _rewardMultiplier) internal {
        require(_rewardMultiplier <= MAX_REWARD_MULTIPLIER, "CrvStrategyKeep3rJob::set-reward-multiplier:multiplier-exceeds-max");
        rewardMultiplier = _rewardMultiplier;
    }

    // Setters
    function setWorkCooldown(uint256 _workCooldown) external override onlyGovernorOrMechanic {
        _setWorkCooldown(_workCooldown);
    }

    function _setWorkCooldown(uint256 _workCooldown) internal {
        require(_workCooldown > 0, "V2Keep3rJob::set-work-cooldown:should-not-be-zero");
        workCooldown = _workCooldown;
    }

    // Governor
    function addStrategies(address[] calldata _strategies, uint256[] calldata _requiredAmounts) external override onlyGovernorOrMechanic {
        require(_strategies.length == _requiredAmounts.length, "V2Keep3rJob::add-strategies:strategies-required-amounts-different-length");
        for (uint256 i; i < _strategies.length; i++) {
            _addStrategy(_strategies[i], _requiredAmounts[i]);
        }
    }

    function addStrategy(address _strategy, uint256 _requiredAmount) external override onlyGovernorOrMechanic {
        _addStrategy(_strategy, _requiredAmount);
    }

    function _addStrategy(address _strategy, uint256 _requiredAmount) internal {
        require(!_availableStrategies.contains(_strategy), "V2Keep3rJob::add-strategy:strategy-already-added");
        _setRequiredAmount(_strategy, _requiredAmount);
        emit StrategyAdded(_strategy, _requiredAmount);
        _availableStrategies.add(_strategy);
    }

    function updateRequiredAmounts(address[] calldata _strategies, uint256[] calldata _requiredAmounts)
        external
        override
        onlyGovernorOrMechanic
    {
        require(_strategies.length == _requiredAmounts.length, "V2Keep3rJob::update-strategies:strategies-required-amounts-different-length");
        for (uint256 i; i < _strategies.length; i++) {
            _updateRequiredAmount(_strategies[i], _requiredAmounts[i]);
        }
    }

    function updateRequiredAmount(address _strategy, uint256 _requiredAmount) external override onlyGovernorOrMechanic {
        _updateRequiredAmount(_strategy, _requiredAmount);
    }

    function _updateRequiredAmount(address _strategy, uint256 _requiredAmount) internal {
        require(_availableStrategies.contains(_strategy), "V2Keep3rJob::update-required-amount:strategy-not-added");
        _setRequiredAmount(_strategy, _requiredAmount);
        emit StrategyModified(_strategy, _requiredAmount);
    }

    function removeStrategy(address _strategy) external override onlyGovernorOrMechanic {
        require(_availableStrategies.contains(_strategy), "V2Keep3rJob::remove-strategy:strategy-not-added");
        delete requiredAmount[_strategy];
        _availableStrategies.remove(_strategy);
        emit StrategyRemoved(_strategy);
    }

    function _setRequiredAmount(address _strategy, uint256 _requiredAmount) internal {
        requiredAmount[_strategy] = _requiredAmount;
    }

    // Getters
    function strategies() public view override returns (address[] memory _strategies) {
        _strategies = new address[](_availableStrategies.length());
        for (uint256 i; i < _availableStrategies.length(); i++) {
            _strategies[i] = _availableStrategies.at(i);
        }
    }

    // Keeper view actions (internal)
    function _workable(address _strategy) internal view virtual returns (bool) {
        require(_availableStrategies.contains(_strategy), "V2Keep3rJob::workable:strategy-not-added");
        if (workCooldown == 0 || block.timestamp > lastWorkAt[_strategy].add(workCooldown)) return true;
        return false;
    }

    // Get eth costs
    function _getCallCosts(address _strategy) internal view returns (uint256 _kp3rCallCost, uint256 _ethCallCost) {
        if (requiredAmount[_strategy] == 0) return (0, 0);
        _kp3rCallCost = IKeep3rV1Helper(keep3rHelper).getQuoteLimit(requiredAmount[_strategy]);
        _ethCallCost = IUniswapV2SlidingOracle(slidingOracle).current(address(_Keep3r), _kp3rCallCost, WETH);
    }

    // Keep3r actions
    function _workInternal(address _strategy, bool _workForTokens) internal returns (uint256 _credits) {
        uint256 _initialGas = gasleft();
        require(_workable(_strategy), "V2Keep3rJob::work:not-workable");

        _work(_strategy);

        _credits = _calculateCredits(_initialGas);

        emit Worked(_strategy, msg.sender, _credits, _workForTokens);
    }

    function _calculateCredits(uint256 _initialGas) internal view returns (uint256 _credits) {
        // Gets default credits from KP3R_Helper and applies job reward multiplier
        return _getQuoteLimit(_initialGas).mul(rewardMultiplier).div(PRECISION);
    }

    // Mechanics keeper bypass
    function forceWork(address _strategy) external override onlyGovernorOrMechanic {
        _work(_strategy);
        emit ForceWorked(_strategy);
    }

    function _work(address _strategy) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './UtilsReady.sol';
import '../utils/Machinery.sol';

abstract
contract MachineryReady is UtilsReady, Machinery {

  constructor(address _mechanicsRegistry) public Machinery(_mechanicsRegistry) UtilsReady() {
  }

  // Machinery: restricted-access
  function setMechanicsRegistry(address _mechanicsRegistry) external override onlyGovernor {
    _setMechanicsRegistry(_mechanicsRegistry);
  }

  // Machinery: modifiers
  modifier onlyGovernorOrMechanic() {
    require(isGovernor(msg.sender) || isMechanic(msg.sender), "Machinery::onlyGovernorOrMechanic:invalid-msg-sender");
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IKeep3rV1Helper {
    function quote(uint256 eth) external view returns (uint256);

    function getFastGas() external view returns (uint256);

    function bonds(address keeper) external view returns (uint256);

    function getQuoteLimit(uint256 gasUsed) external view returns (uint256);

    function getQuoteLimitFor(address origin, uint256 gasUsed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../../interfaces/keep3r/IKeep3rV1.sol';
import '../../interfaces/keep3r/IKeep3r.sol';

abstract
contract Keep3r is IKeep3r {
  using SafeMath for uint256;

  IKeep3rV1 internal _Keep3r;
  address public bond;
  uint256 public minBond;
  uint256 public earned;
  uint256 public age;
  bool public onlyEOA;

  constructor(address _keep3r) public {
    _setKeep3r(_keep3r);
  }

  // Setters
  function _setKeep3r(address _keep3r) internal {
    _Keep3r = IKeep3rV1(_keep3r);
    emit Keep3rSet(_keep3r);
  }

  function _setKeep3rRequirements(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA) internal {
    bond = _bond;
    minBond = _minBond;
    earned = _earned;
    age = _age;
    onlyEOA = _onlyEOA;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age, _onlyEOA);
  }

  // Modifiers
  // Only checks if caller is a valid keeper, payment should be handled manually
  modifier onlyKeeper() {
    _isKeeper();
    _;
  }

  // view
  function keep3r() external view override returns (address _keep3r) {
    return address(_Keep3r);
  }

  // handles default payment after execution
  modifier paysKeeper() {
    _;
    _paysKeeper(msg.sender);
  }

  // Internal helpers
  function _isKeeper() internal {
    if (onlyEOA) require(msg.sender == tx.origin, "keep3r::isKeeper:keeper-is-not-eoa");
    if (minBond == 0 && earned == 0 && age == 0) {
      // If no custom keeper requirements are set, just evaluate if sender is a registered keeper
      require(_Keep3r.isKeeper(msg.sender), "keep3r::isKeeper:keeper-is-not-registered");
    } else {
      if (bond == address(0)) {
        // Checks for min KP3R, earned and age.
        require(_Keep3r.isMinKeeper(msg.sender, minBond, earned, age), "keep3r::isKeeper:keeper-not-min-requirements");
      } else {
        // Checks for min custom-bond, earned and age.
        require(_Keep3r.isBondedKeeper(msg.sender, bond, minBond, earned, age), "keep3r::isKeeper:keeper-not-custom-min-requirements");
      }
    }
  }

  function _getQuoteLimit(uint256 _gasUsed) internal view returns (uint256 _credits) {
    return _Keep3r.KPRH().getQuoteLimit(_gasUsed.sub(gasleft()));
  }

  // pays in bonded KP3R after execution
  function _paysKeeper(address _keeper) internal {
    _Keep3r.worked(_keeper);
  }
  // pays _amount in KP3R after execution
  function _paysKeeperInTokens(address _keeper, uint256 _amount) internal {
    _Keep3r.receipt(address(_Keep3r), _keeper, _amount);
  }
  // pays _amount in bonded KP3R after execution
  function _paysKeeperAmount(address _keeper, uint256 _amount) internal {
    _Keep3r.workReceipt(_keeper, _amount);
  }
  // pays _amount in _credit after execution
  function _paysKeeperCredit(address _credit, address _keeper, uint256 _amount) internal {
    _Keep3r.receipt(_credit, _keeper, _amount);
  }
  // pays _amount in ETH after execution
  function _paysKeeperEth(address _keeper, uint256 _amount) internal {
    _Keep3r.receiptETH(_keeper, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IV2Keeper {
    // Getters
    function jobs() external view returns (address[] memory);

    event JobAdded(address _job);
    event JobRemoved(address _job);

    // Setters
    function addJobs(address[] calldata _jobs) external;

    function addJob(address _job) external;

    function removeJob(address _job) external;

    // Jobs actions
    function tend(address _strategy) external;

    function harvest(address _strategy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;
import "../IKeep3rJob.sol";

interface IV2Keep3rJob is IKeep3rJob {
    event Keep3rSet(address keep3r);
    event Keep3rHelperSet(address keep3rHelper);
    event SlidingOracleSet(address slidingOracle);

    // Setters
    event StrategyAdded(address _strategy, uint256 _requiredAmount);
    event StrategyModified(address _strategy, uint256 _requiredAmount);
    event StrategyRemoved(address _strategy);

    // Actions by Keeper
    event Worked(address _strategy, address _keeper, uint256 _credits, bool _workForTokens);

    // Actions forced by governor
    event ForceWorked(address _strategy);

    // Getters
    function strategies() external view returns (address[] memory);

    function workable(address _strategy) external view returns (bool);

    // Setters
    function setWorkCooldown(uint256 _workCooldown) external;

    function addStrategies(address[] calldata _strategy, uint256[] calldata _requiredAmount) external;

    function addStrategy(address _strategy, uint256 _requiredAmount) external;

    function updateRequiredAmounts(address[] calldata _strategies, uint256[] calldata _requiredAmounts) external;

    function updateRequiredAmount(address _strategy, uint256 _requiredAmount) external;

    function removeStrategy(address _strategy) external;

    // Keeper actions
    function work(address _strategy) external returns (uint256 _credits);

    function workForBond(address _strategy) external returns (uint256 _credits);

    function workForTokens(address _strategy) external returns (uint256 _credits);

    // Mechanics keeper bypass
    function forceWork(address _strategy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBaseStrategy {
    function vault() external view returns (address _vault);

    function strategist() external view returns (address _strategist);

    function rewards() external view returns (address _rewards);

    function keeper() external view returns (address _keeper);

    function want() external view returns (address _want);

    function name() external view returns (string memory _name);

    // Setters
    function setStrategist(address _strategist) external;

    function setKeeper(address _keeper) external;

    function setRewards(address _rewards) external;

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IUniswapV2SlidingOracle {
    function current(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256);

    function updatePair(address pair) external returns (bool);

    function workable(address pair) external view returns (bool);

    function workForFree() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../utils/Governable.sol';
import '../utils/CollectableDust.sol';
import '../utils/Pausable.sol';

abstract
contract UtilsReady is Governable, CollectableDust, Pausable {

  constructor() public Governable(msg.sender) {
  }

  // Governable: restricted-access
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }

  // Collectable Dust: restricted-access
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override virtual onlyGovernor {
    _sendDust(_to, _token, _amount);
  }

  // Pausable: restricted-access
  function pause(bool _paused) external override onlyGovernor {
    _pause(_paused);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import '../../interfaces/utils/IMachinery.sol';
import '../../interfaces/mechanics/IMechanicsRegistry.sol';

abstract
contract Machinery is IMachinery {
  using EnumerableSet for EnumerableSet.AddressSet;

  IMechanicsRegistry internal MechanicsRegistry;

  constructor(address _mechanicsRegistry) public {
    _setMechanicsRegistry(_mechanicsRegistry);
  }

  function _setMechanicsRegistry(address _mechanicsRegistry) internal {
    MechanicsRegistry = IMechanicsRegistry(_mechanicsRegistry);
  }

  // View helpers
  function mechanicsRegistry() external view override returns (address _mechanicRegistry) {
    return address(MechanicsRegistry);
  }
  function isMechanic(address _mechanic) public view override returns (bool _isMechanic) {
    return MechanicsRegistry.isMechanic(_mechanic);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../../interfaces/utils/IGovernable.sol';

abstract
contract Governable is IGovernable {
  address public override governor;
  address public override pendingGovernor;

  constructor(address _governor) public {
    require(_governor != address(0), 'governable/governor-should-not-be-zero-address');
    governor = _governor;
  }

  function _setPendingGovernor(address _pendingGovernor) internal {
    require(_pendingGovernor != address(0), 'governable/pending-governor-should-not-be-zero-addres');
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(_pendingGovernor);
  }

  function _acceptGovernor() internal {
    governor = pendingGovernor;
    pendingGovernor = address(0);
    emit GovernorAccepted();
  }

  function isGovernor(address _account) public view override returns (bool _isGovernor) {
    return _account == governor;
  }

  modifier onlyGovernor {
    require(isGovernor(msg.sender), 'governable/only-governor');
    _;
  }

  modifier onlyPendingGovernor {
    require(msg.sender == pendingGovernor, 'governable/only-pending-governor');
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import '../../interfaces/utils/ICollectableDust.sol';

abstract
contract CollectableDust is ICollectableDust {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  EnumerableSet.AddressSet internal protocolTokens;

  constructor() public {}

  function _addProtocolToken(address _token) internal {
    require(!protocolTokens.contains(_token), 'collectable-dust/token-is-part-of-the-protocol');
    protocolTokens.add(_token);
  }

  function _removeProtocolToken(address _token) internal {
    require(protocolTokens.contains(_token), 'collectable-dust/token-not-part-of-the-protocol');
    protocolTokens.remove(_token);
  }

  function _sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    require(_to != address(0), 'collectable-dust/cant-send-dust-to-zero-address');
    require(!protocolTokens.contains(_token), 'collectable-dust/token-is-part-of-the-protocol');
    if (_token == ETH_ADDRESS) {
      payable(_to).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
    emit DustSent(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../../interfaces/utils/IPausable.sol';

abstract
contract Pausable is IPausable {
  bool public paused;

  constructor() public {}
  
  modifier notPaused() {
    require(!paused, 'paused');
    _;
  }

  function _pause(bool _paused) internal {
    require(paused != _paused, 'no-change');
    paused = _paused;
    emit Paused(_paused);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IGovernable {
  event PendingGovernorSet(address pendingGovernor);
  event GovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;
  function acceptGovernor() external;

  function governor() external view returns (address _governor);
  function pendingGovernor() external view returns (address _pendingGovernor);

  function isGovernor(address _account) external view returns (bool _isGovernor);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICollectableDust {
  event DustSent(address _to, address token, uint256 amount);

  function sendDust(address _to, address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPausable {
  event Paused(bool _paused);

  function pause(bool _paused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMachinery {
    // View helpers
    function mechanicsRegistry() external view returns (address _mechanicsRegistry);
    function isMechanic(address mechanic) external view returns (bool _isMechanic);

    // Setters
    function setMechanicsRegistry(address _mechanicsRegistry) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMechanicsRegistry {
    event MechanicAdded(address _mechanic);
    event MechanicRemoved(address _mechanic);

    function addMechanic(address _mechanic) external;

    function removeMechanic(address _mechanic) external;

    function mechanics() external view returns (address[] memory _mechanicsList);

    function isMechanic(address mechanic) external view returns (bool _isMechanic);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IKeep3rV1Helper.sol";

interface IKeep3rV1 is IERC20 {
    function name() external returns (string memory);
    function KPRH() external view returns (IKeep3rV1Helper);

    function isKeeper(address _keeper) external returns (bool);
    function isMinKeeper(address _keeper, uint256 _minBond, uint256 _earned, uint256 _age) external returns (bool);
    function isBondedKeeper(address _keeper, address bond, uint256 _minBond, uint256 _earned, uint256 _age) external returns (bool);
    function addKPRCredit(address _job, uint256 _amount) external;
    function addJob(address _job) external;
    function addVotes(address voter, uint256 amount) external;
    function removeVotes(address voter, uint256 amount) external;

    function worked(address _keeper) external;
    function workReceipt(address _keeper, uint256 _amount) external;
    function receipt(address credit, address _keeper, uint256 _amount) external;
    function receiptETH(address _keeper, uint256 _amount) external;

    function addLiquidityToJob(address liquidity, address job, uint amount) external;
    function applyCreditToJob(address provider, address liquidity, address job) external;
    function unbondLiquidityFromJob(address liquidity, address job, uint amount) external;
    function removeLiquidityFromJob(address liquidity, address job) external;

    function credits(address _job, address _credit) external view returns (uint256 _amount);

    function liquidityAccepted(address _liquidity) external view returns (bool);

    function liquidityProvided(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityApplied(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityAmount(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    
    function liquidityUnbonding(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityAmountsUnbonding(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);

    function bond(address bonding, uint256 amount) external;
    function activate(address bonding) external;
    function unbond(address bonding, uint256 amount) external;
    function withdraw(address bonding) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
interface IKeep3r {
    event Keep3rSet(address _keep3r);
    event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA);
    
    function keep3r() external view returns (address _keep3r);

    function setKeep3r(address _keep3r) external;
    function setKeep3rRequirements(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IKeep3rJob {
    event SetRewardMultiplier(uint256 _rewardMultiplier);

    function rewardMultiplier() external view returns (uint256 _rewardMultiplier);

    function setRewardMultiplier(uint256 _rewardMultiplier) external;
}