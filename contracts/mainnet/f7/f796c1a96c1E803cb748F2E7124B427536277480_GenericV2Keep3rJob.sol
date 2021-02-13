// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@lbertenasco/contract-utils/contracts/utils/UtilsReady.sol";
import "@lbertenasco/contract-utils/interfaces/keep3r/IKeep3rV1.sol";

import "../sugar-mommy/Keep3rJob.sol";

import "../../interfaces/keep3r/IKeep3rV1Helper.sol";
import "../../interfaces/yearn/IBaseStrategy.sol";
import "../../interfaces/keep3r/IUniswapV2SlidingOracle.sol";
import "../../interfaces/keep3r/IGenericV2Keep3rJob.sol";

contract GenericV2Keep3rJob is UtilsReady, Keep3rJob, IGenericV2Keep3rJob {
    using SafeMath for uint256;

    address public constant KP3R = address(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public keep3r;
    address public keep3rHelper;
    address public slidingOracle;

    EnumerableSet.AddressSet internal _availableStrategies;

    mapping(address => uint256) public requiredHarvest;
    mapping(address => uint256) public requiredTend;

    mapping(address => uint256) public lastHarvestAt;
    mapping(address => uint256) public lastTendAt;

    uint256 public harvestCooldown;
    uint256 public tendCooldown;

    uint256 public usedCredits;
    uint256 public maxCredits;

    constructor(
        address _keep3rSugarMommy,
        address _keep3r,
        address _keep3rHelper,
        address _slidingOracle,
        uint256 _harvestCooldown,
        uint256 _tendCooldown,
        uint256 _maxCredits
    ) public UtilsReady() Keep3rJob(_keep3rSugarMommy) {
        keep3r = _keep3r;
        keep3rHelper = _keep3rHelper;
        slidingOracle = _slidingOracle;
        _setHarvestCooldown(_harvestCooldown);
        _setTendCooldown(_tendCooldown);
        _setMaxCredits(_maxCredits);
    }

    // Setters
    function setHarvestCooldown(uint256 _harvestCooldown) external override onlyGovernor {
        _setHarvestCooldown(_harvestCooldown);
    }

    function _setHarvestCooldown(uint256 _harvestCooldown) internal {
        require(_harvestCooldown > 0, "generic-keep3r-v2::set-harvest-cooldown:should-not-be-zero");
        harvestCooldown = _harvestCooldown;
    }

    function setTendCooldown(uint256 _tendCooldown) external override onlyGovernor {
        _setTendCooldown(_tendCooldown);
    }

    function _setTendCooldown(uint256 _tendCooldown) internal {
        require(_tendCooldown > 0, "generic-keep3r-v2::set-tend-cooldown:should-not-be-zero");
        tendCooldown = _tendCooldown;
    }

    function setMaxCredits(uint256 _maxCredits) external override onlyGovernor {
        _setMaxCredits(_maxCredits);
    }

    function _setMaxCredits(uint256 _maxCredits) internal {
        usedCredits = 0;
        maxCredits = _maxCredits;
    }

    // Unique methods to add a strategy to the system
    // If you don't require harvest, use _requiredHarvest = 0
    // If you don't require tend, use _requiredTend = 0
    function addStrategies(
        address[] calldata _strategies,
        uint256[] calldata _requiredHarvests,
        uint256[] calldata _requiredTends
    ) external override onlyGovernor {
        require(
            _strategies.length == _requiredHarvests.length && _strategies.length == _requiredTends.length,
            "generic-keep3r-v2::add-strategies:strategies-required-harvests-and-tends-different-length"
        );
        for (uint256 i; i < _strategies.length; i++) {
            _addStrategy(_strategies[i], _requiredHarvests[i], _requiredTends[i]);
        }
    }

    function addStrategy(
        address _strategy,
        uint256 _requiredHarvest,
        uint256 _requiredTend
    ) external override onlyGovernor {
        _addStrategy(_strategy, _requiredHarvest, _requiredTend);
    }

    function _addStrategy(
        address _strategy,
        uint256 _requiredHarvest,
        uint256 _requiredTend
    ) internal {
        require(_requiredHarvest > 0 || _requiredTend > 0, "generic-keep3r-v2::add-strategy:should-need-harvest-or-tend");
        if (_requiredHarvest > 0) {
            _addHarvestStrategy(_strategy, _requiredHarvest);
        }

        if (_requiredTend > 0) {
            _addTendStrategy(_strategy, _requiredTend);
        }

        _availableStrategies.add(_strategy);
    }

    function _addHarvestStrategy(address _strategy, uint256 _requiredHarvest) internal {
        require(requiredHarvest[_strategy] == 0, "generic-keep3r-v2::add-harvest-strategy:strategy-already-added");
        _setRequiredHarvest(_strategy, _requiredHarvest);
        emit HarvestStrategyAdded(_strategy, _requiredHarvest);
    }

    function _addTendStrategy(address _strategy, uint256 _requiredTend) internal {
        require(requiredTend[_strategy] == 0, "generic-keep3r-v2::add-tend-strategy:strategy-already-added");
        _setRequiredTend(_strategy, _requiredTend);
        emit TendStrategyAdded(_strategy, _requiredTend);
    }

    function updateRequiredHarvestAmount(address _strategy, uint256 _requiredHarvest) external override onlyGovernor {
        require(requiredHarvest[_strategy] > 0, "generic-keep3r-v2::update-required-harvest:strategy-not-added");
        _setRequiredHarvest(_strategy, _requiredHarvest);
        emit HarvestStrategyModified(_strategy, _requiredHarvest);
    }

    function updateRequiredTendAmount(address _strategy, uint256 _requiredTend) external override onlyGovernor {
        require(requiredTend[_strategy] > 0, "generic-keep3r-v2::update-required-tend:strategy-not-added");
        _setRequiredTend(_strategy, _requiredTend);
        emit TendStrategyModified(_strategy, _requiredTend);
    }

    function removeStrategy(address _strategy) external override onlyGovernor {
        require(requiredHarvest[_strategy] > 0 || requiredTend[_strategy] > 0, "generic-keep3r-v2::remove-strategy:strategy-not-added");
        delete requiredHarvest[_strategy];
        delete requiredTend[_strategy];
        _availableStrategies.remove(_strategy);
        emit StrategyRemoved(_strategy);
    }

    function removeHarvestStrategy(address _strategy) external override onlyGovernor {
        require(requiredHarvest[_strategy] > 0, "generic-keep3r-v2::remove-harvest-strategy:strategy-not-added");
        delete requiredHarvest[_strategy];

        if (requiredTend[_strategy] == 0) {
            _availableStrategies.remove(_strategy);
        }

        emit HarvestStrategyRemoved(_strategy);
    }

    function removeTendStrategy(address _strategy) external override onlyGovernor {
        require(requiredTend[_strategy] > 0, "generic-keep3r-v2::remove-tend-strategy:strategy-not-added");
        delete requiredTend[_strategy];

        if (requiredHarvest[_strategy] == 0) {
            _availableStrategies.remove(_strategy);
        }

        emit TendStrategyRemoved(_strategy);
    }

    function _setRequiredHarvest(address _strategy, uint256 _requiredHarvest) internal {
        require(_requiredHarvest > 0, "generic-keep3r-v2::set-required-harvest:should-not-be-zero");
        requiredHarvest[_strategy] = _requiredHarvest;
    }

    function _setRequiredTend(address _strategy, uint256 _requiredTend) internal {
        require(_requiredTend > 0, "generic-keep3r-v2::set-required-tend:should-not-be-zero");
        requiredTend[_strategy] = _requiredTend;
    }

    // Getters
    function name() external pure override returns (string memory) {
        return "Generic Vault V2 Strategy Keep3r";
    }

    function strategies() public view override returns (address[] memory _strategies) {
        _strategies = new address[](_availableStrategies.length());
        for (uint256 i; i < _availableStrategies.length(); i++) {
            _strategies[i] = _availableStrategies.at(i);
        }
    }

    function harvestable(address _strategy) public view override returns (bool) {
        require(requiredHarvest[_strategy] > 0, "generic-keep3r-v2::harvestable:strategy-not-added");
        require(block.timestamp > lastHarvestAt[_strategy].add(harvestCooldown), "generic-keep3r-v2::harvestable:strategy-harvest-cooldown");

        uint256 kp3rCallCost = IKeep3rV1Helper(keep3rHelper).getQuoteLimit(requiredHarvest[_strategy]);
        uint256 ethCallCost = IUniswapV2SlidingOracle(slidingOracle).current(KP3R, kp3rCallCost, WETH);
        return IBaseStrategy(_strategy).harvestTrigger(ethCallCost);
    }

    function tendable(address _strategy) public view override returns (bool) {
        require(requiredTend[_strategy] > 0, "generic-keep3r-v2::tendable:strategy-not-added");
        require(block.timestamp > lastTendAt[_strategy].add(tendCooldown), "generic-keep3r-v2::tendable:strategy-tend-cooldown");

        uint256 kp3rCallCost = IKeep3rV1Helper(keep3rHelper).getQuoteLimit(requiredTend[_strategy]);
        uint256 ethCallCost = IUniswapV2SlidingOracle(slidingOracle).current(KP3R, kp3rCallCost, WETH);
        return IBaseStrategy(_strategy).tendTrigger(ethCallCost);
    }

    // Keep3r actions
    function harvest(address _strategy) external override updateCredits {
        require(harvestable(_strategy), "generic-keep3r-v2::harvest:not-workable");

        _startJob(msg.sender);
        _harvest(_strategy);
        _endJob(msg.sender);

        emit HarvestedByKeeper(_strategy);
    }

    function tend(address _strategy) external override updateCredits {
        require(tendable(_strategy), "generic-keep3r-v2::tend:not-workable");

        _startJob(msg.sender);
        _tend(_strategy);
        _endJob(msg.sender);

        emit TendedByKeeper(_strategy);
    }

    // Governor keeper bypass
    function forceHarvest(address _strategy) external override onlyGovernor {
        _harvest(_strategy);
        emit HarvestedByGovernor(_strategy);
    }

    function forceTend(address _strategy) external override onlyGovernor {
        _tend(_strategy);
        emit TendedByGovernor(_strategy);
    }

    function _harvest(address _strategy) internal {
        IBaseStrategy(_strategy).harvest();
        lastHarvestAt[_strategy] = block.timestamp;
    }

    function _tend(address _strategy) internal {
        IBaseStrategy(_strategy).tend();
        lastTendAt[_strategy] = block.timestamp;
    }

    modifier updateCredits() {
        uint256 _beforeCredits = IKeep3rV1(keep3r).credits(address(Keep3rSugarMommy), keep3r);
        _;
        uint256 _afterCredits = IKeep3rV1(keep3r).credits(address(Keep3rSugarMommy), keep3r);
        usedCredits = usedCredits.add(_beforeCredits.sub(_afterCredits));
        require(usedCredits <= maxCredits, "generic-keep3r-v2::update-credits:used-credits-exceed-max-credits");
    }
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

pragma solidity >=0.6.8;

import './Governable.sol';
import './CollectableDust.sol';
import './Pausable.sol';
import './Migratable.sol';

abstract
contract UtilsReady is Governable, CollectableDust, Pausable, Migratable {

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

  // Migratable: restricted-access
  function migrate(address _to) external onlyGovernor {
      _migrated(_to);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;
interface IKeep3rV1 {
    function name() external returns (string memory);
    function isKeeper(address _keeper) external returns (bool);
    function isMinKeeper(address _keeper, uint256 _minBond, uint256 _earned, uint256 _age) external returns (bool);
    function isBondedKeeper(address _keeper, address bond, uint256 _minBond, uint256 _earned, uint256 _age) external returns (bool);
    function addKPRCredit(address _job, uint256 _amount) external;
    function addJob(address _job) external;

    function worked(address _keeper) external;
    function workReceipt(address _keeper, uint256 _amount) external;
    function receipt(address credit, address _keeper, uint256 _amount) external;
    function receiptETH(address _keeper, uint256 _amount) external;

    function addLiquidityToJob(address liquidity, address job, uint amount) external;
    function applyCreditToJob(address provider, address liquidity, address job) external;
    function unbondLiquidityFromJob(address liquidity, address job, uint amount) external;
    function removeLiquidityFromJob(address liquidity, address job) external;

    function credits(address _job, address _credit) external view returns (uint256 _amount);

    function liquidityProvided(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityApplied(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityAmount(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    
    function liquidityUnbonding(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityAmountsUnbonding(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@lbertenasco/contract-utils/contracts/utils/UtilsReady.sol";

import "../../interfaces/sugar-mommy/IKeep3rSugarMommy.sol";
import "../../interfaces/sugar-mommy/IKeep3rJob.sol";

abstract contract Keep3rJob is IKeep3rJob {
    using SafeMath for uint256;

    IKeep3rSugarMommy public Keep3rSugarMommy;

    constructor(address _keep3rSugarMommy) public {
        Keep3rSugarMommy = IKeep3rSugarMommy(_keep3rSugarMommy);
    }

    function isKeep3rJob() external pure override returns (bool) {
        return true;
    }

    // Keep3rSugarMommy actions
    function _startJob(address _keeper) internal {
        Keep3rSugarMommy.start(_keeper);
    }

    function _endJob(address _keeper) internal {
        Keep3rSugarMommy.end(_keeper, address(0), 0);
    }

    function _endJob(address _keeper, uint256 _amount) internal {
        Keep3rSugarMommy.end(_keeper, address(0), _amount);
    }

    function _endJob(
        address _keeper,
        address _credit,
        uint256 _amount
    ) internal {
        Keep3rSugarMommy.end(_keeper, _credit, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IKeep3rV1Helper {
    function getQuoteLimit(uint256 gasUsed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBaseStrategy {
    function vault() external view returns (address _vault);
    function strategist() external view returns (address _strategist);
    function rewards() external view returns (address _rewards);
    function keeper() external view returns (address _keeper);
    function want() external view returns (address _want);

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
pragma solidity >=0.6.8;

interface IGenericV2Keep3rJob {
    event Keep3rSet(address keep3r);
    event Keep3rHelperSet(address keep3rHelper);
    event SlidingOracleSet(address slidingOracle);

    // Actions by Keeper
    event HarvestedByKeeper(address _strategy);
    event TendedByKeeper(address _strategy);

    // Actions forced by governance
    event HarvestedByGovernor(address _strategy);
    event TendedByGovernor(address _strategy);

    // Getters
    function strategies() external view returns (address[] memory);

    function harvestable(address _strategy) external view returns (bool);

    function tendable(address _strategy) external view returns (bool);

    // Keep3r actions
    function harvest(address _strategy) external;

    function tend(address _strategy) external;

    // Governor keeper bypass
    function forceHarvest(address _strategy) external;

    function forceTend(address _strategy) external;

    // Name of the Keep3r
    function name() external pure returns (string memory);

    event HarvestStrategyAdded(address _strategy, uint256 _requiredHarvest);
    event TendStrategyAdded(address _strategy, uint256 _requiredTend);

    event HarvestStrategyModified(address _strategy, uint256 _requiredHarvest);
    event TendStrategyModified(address _strategy, uint256 _requiredTend);

    event StrategyRemoved(address _strategy);
    event HarvestStrategyRemoved(address _strategy);
    event TendStrategyRemoved(address _strategy);

    // Setters
    function setHarvestCooldown(uint256 _harvestCooldown) external;

    function setTendCooldown(uint256 _tendCooldown) external;

    function setMaxCredits(uint256 _maxCredits) external;

    function addStrategies(
        address[] calldata _strategy,
        uint256[] calldata _requiredHarvest,
        uint256[] calldata _requiredTend
    ) external;

    function addStrategy(
        address _strategy,
        uint256 _requiredHarvest,
        uint256 _requiredTend
    ) external;

    function updateRequiredHarvestAmount(address _strategy, uint256 _requiredHarvest) external;

    function updateRequiredTendAmount(address _strategy, uint256 _requiredTend) external;

    function removeStrategy(address _strategy) external;

    function removeHarvestStrategy(address _strategy) external;

    function removeTendStrategy(address _strategy) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '../../interfaces/utils/IGovernable.sol';

abstract
contract Governable is IGovernable {
  address public governor;
  address public pendingGovernor;

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

  modifier onlyGovernor {
    require(msg.sender == governor, 'governable/only-governor');
    _;
  }

  modifier onlyPendingGovernor {
    require(msg.sender == pendingGovernor, 'governable/only-pending-governor');
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

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

pragma solidity >=0.6.8;

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

pragma solidity >=0.6.8;

import '../../interfaces/utils/IMigratable.sol';

abstract
contract Migratable is IMigratable {
  address public override migratedTo;

  constructor() public {}
  
  modifier notMigrated() {
    require(migratedTo == address(0), 'migrated');
    _;
  }

  function _migrated(address _to) internal {
    require(migratedTo == address(0), 'already-migrated');
    require(_to != address(0), 'migrate-to-address-0');
    migratedTo = _to;
    emit Migrated(_to);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IGovernable {
  event PendingGovernorSet(address pendingGovernor);
  event GovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;
  function acceptGovernor() external;
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
pragma solidity >=0.6.8;

interface ICollectableDust {
  event DustSent(address _to, address token, uint256 amount);

  function sendDust(address _to, address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IPausable {
  event Paused(bool _paused);

  function pause(bool _paused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IMigratable {
  event Migrated(address _to);

  function migratedTo() external view returns (address _to);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IKeep3rSugarMommy {
    event Keep3rSet(address _keep3r);
    event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA);
    event JobStarted(address _job, address _keeper);
    event JobEnded(address _job, address _keeper);

    function isKeep3rSugarMommy() external pure returns (bool);

    function setKeep3r(address _keep3r) external;

    function setKeep3rRequirements(
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age,
        bool _onlyEOA
    ) external;

    function jobs() external view returns (address[] memory validJobs);

    function start(address _keeper) external;

    function end(
        address _keeper,
        address _credit,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IKeep3rJob {
    function isKeep3rJob() external pure returns (bool);

    // Mock functions
    // function workable() external view returns (bool);
    // function work() external;
    // function forceWork() external;
}