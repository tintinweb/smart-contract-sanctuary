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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./oracles/OracleAware.sol";
import "./roles/RoleAware.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./roles/DependsOnOracleListener.sol";
import "../interfaces/IOracle.sol";

/// Central hub and router for all oracles
contract OracleRegistry is RoleAware, DependsOracleListener {
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => mapping(address => address)) public tokenOracle;
    mapping(address => mapping(address => EnumerableSet.AddressSet))
        internal _listeners;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(ORACLE_REGISTRY);
    }

    /// Initialize oracle for a specific token
    function setOracleParams(
        address token,
        address pegCurrency,
        address oracle,
        uint256 borrowablePer10k,
        bool primary,
        bytes calldata data
    ) external onlyOwnerExecActivator {
        IOracle(oracle).setOracleParams(
            token,
            pegCurrency,
            borrowablePer10k,
            data
        );

        // only overwrite oracle and update listeners if update is for a primary
        // or there is no pre-existing oracle
        address previousOracle = tokenOracle[token][pegCurrency];
        if (previousOracle == address(0) || primary) {
            tokenOracle[token][pegCurrency] = oracle;

            EnumerableSet.AddressSet storage listeners = _listeners[token][
                pegCurrency
            ];
            for (uint256 i; listeners.length() > i; i++) {
                OracleAware(listeners.at(i)).newCurrentOracle(
                    token,
                    pegCurrency
                );
            }
        }
    }

    /// Which oracle contract is currently responsible for a token is cached
    /// This updates
    function listenForCurrentOracleUpdates(address token, address pegCurrency)
        external
        returns (address)
    {
        require(isOracleListener(msg.sender), "Not allowed to listen");
        _listeners[token][pegCurrency].add(msg.sender);
        return tokenOracle[token][pegCurrency];
    }

    /// View converted value in currently registered oracle
    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public view returns (uint256) {
        return
            IOracle(tokenOracle[token][pegCurrency]).viewAmountInPeg(
                token,
                inAmount,
                pegCurrency
            );
    }

    /// View amounts for an array of tokens
    function viewAmountsInPeg(
        address[] calldata tokens,
        uint256[] calldata inAmounts,
        address pegCurrency
    ) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](inAmounts.length);
        for (uint256 i; inAmounts.length > i; i++) {
            result[i] = viewAmountInPeg(tokens[i], inAmounts[i], pegCurrency);
        }
        return result;
    }

    /// Update converted value in currently registered oracle
    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public returns (uint256) {
        return
            IOracle(tokenOracle[token][pegCurrency]).getAmountInPeg(
                token,
                inAmount,
                pegCurrency
            );
    }

    /// Get amounts for an array of tokens
    function getAmountsInPeg(
        address[] calldata tokens,
        uint256[] calldata inAmounts,
        address pegCurrency
    ) external returns (uint256[] memory) {
        uint256[] memory result = new uint256[](inAmounts.length);
        for (uint256 i; inAmounts.length > i; i++) {
            result[i] = getAmountInPeg(tokens[i], inAmounts[i], pegCurrency);
        }
        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./roles/RoleAware.sol";
import "./TrancheIDService.sol";
import "./roles/DependsOnTrancheIDService.sol";

abstract contract TrancheIDAware is RoleAware, DependsOnTrancheIDService {
    uint256 immutable totalTrancheSlots;

    constructor(address _roles) RoleAware(_roles) {
        totalTrancheSlots = TrancheIDService(
            Roles(_roles).mainCharacters(TRANCHE_ID_SERVICE)
        ).totalTrancheSlots();
    }

    mapping(uint256 => address) _slotTranches;

    function tranche(uint256 trancheId) public view returns (address) {
        uint256 slot = trancheId % totalTrancheSlots;
        address trancheContract = _slotTranches[slot];
        if (trancheContract == address(0)) {
            trancheContract = trancheIdService().slotTranches(slot);
        }

        return trancheContract;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./roles/RoleAware.sol";
import "./roles/DependsOnTranche.sol";

contract TrancheIDService is RoleAware, DependsOnTranche {
    uint256 public constant totalTrancheSlots = 1e8;
    uint256 public nextTrancheSlot = 1;

    struct TrancheSlot {
        uint256 nextTrancheIdRange;
        uint256 trancheSlot;
    }

    mapping(address => TrancheSlot) public trancheSlots;
    mapping(uint256 => address) public slotTranches;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(TRANCHE_ID_SERVICE);
    }

    function getNextTrancheId() external returns (uint256 id) {
        require(isTranche(msg.sender), "Caller not a tranche contract");
        TrancheSlot storage slot = trancheSlots[msg.sender];
        require(slot.trancheSlot != 0, "Caller doesn't have a slot");
        id = slot.nextTrancheIdRange * totalTrancheSlots + slot.trancheSlot;
        slot.nextTrancheIdRange++;
    }

    function setupTrancheSlot() external returns (TrancheSlot memory) {
        require(isTranche(msg.sender), "Caller not a tranche contract");
        require(
            trancheSlots[msg.sender].trancheSlot == 0,
            "Tranche already has a slot"
        );
        trancheSlots[msg.sender] = TrancheSlot({
            nextTrancheIdRange: 1,
            trancheSlot: nextTrancheSlot
        });
        slotTranches[nextTrancheSlot] = msg.sender;
        nextTrancheSlot++;
        return trancheSlots[msg.sender];
    }

    function viewNextTrancheId(address trancheContract)
        external
        view
        returns (uint256)
    {
        TrancheSlot storage slot = trancheSlots[trancheContract];
        return slot.nextTrancheIdRange * totalTrancheSlots + slot.trancheSlot;
    }

    function viewTrancheContractByID(uint256 trancheId)
        external
        view
        returns (address)
    {
        return slotTranches[trancheId % totalTrancheSlots];
    }

    function viewSlotByTrancheContract(address tranche)
        external
        view
        returns (uint256)
    {
        return trancheSlots[tranche].trancheSlot;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IOracle.sol";
import "../roles/RoleAware.sol";
import "../roles/DependsOnOracleRegistry.sol";

/// Abstract base for oracles, concerned with parameter init
abstract contract Oracle is IOracle, RoleAware, DependsOnOracleRegistry {
    mapping(address => uint256) public borrowablePer10ks;

    function setBorrowable(address lpt, uint256 borrowablePer10k)
        external
        onlyOwnerExec
    {
        borrowablePer10ks[lpt] = borrowablePer10k;
    }

    function setOracleParams(
        address token,
        address pegCurrency,
        uint256 borrowablePer10k,
        bytes calldata data
    ) external override {
        require(
            address(oracleRegistry()) == msg.sender,
            "Not authorized to init oracle"
        );
        borrowablePer10ks[token] = borrowablePer10k;
        _setOracleParams(token, pegCurrency, data);
    }

    function _setOracleParams(
        address token,
        address pegCurrency,
        bytes calldata data
    ) internal virtual;

    function viewPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external view override returns (uint256, uint256) {
        return (
            viewAmountInPeg(token, inAmount, pegCurrency),
            borrowablePer10ks[token]
        );
    }

    function getPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external override returns (uint256, uint256) {
        return (
            getAmountInPeg(token, inAmount, pegCurrency),
            borrowablePer10ks[token]
        );
    }

    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public view virtual override returns (uint256);

    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public virtual override returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../TrancheIDAware.sol";
import "../OracleRegistry.sol";
import "../../interfaces/IOracle.sol";
import "../roles/DependsOnOracleRegistry.sol";

/// Mixin for contracts that depend on oracles, caches current oracles
/// resposible for a token pair
abstract contract OracleAware is RoleAware, DependsOnOracleRegistry {
    mapping(address => mapping(address => address)) public _oracleCache;

    constructor() {
        _rolesPlayed.push(ORACLE_LISTENER);
    }

    /// Notify contract to update oracle cache
    function newCurrentOracle(address token, address pegCurrency) external {
        // make sure we don't init cache if we aren't listening
        if (_oracleCache[token][pegCurrency] != address(0)) {
            _oracleCache[token][pegCurrency] = oracleRegistry().tokenOracle(
                token,
                pegCurrency
            );
        }
    }

    /// get current oracle and subscribe to cache updates if necessary
    function _getOracle(address token, address pegCurrency)
        internal
        returns (address oracle)
    {
        oracle = _oracleCache[token][pegCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().listenForCurrentOracleUpdates(
                token,
                pegCurrency
            );
        }
    }

    /// View value of a token amount in value currency
    function _viewValue(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal view virtual returns (uint256 value) {
        address oracle = _oracleCache[token][valueCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().tokenOracle(token, valueCurrency);
        }
        return IOracle(oracle).viewAmountInPeg(token, amount, valueCurrency);
    }

    /// Get value of a token amount in value currency, updating oracle state
    function _getValue(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal virtual returns (uint256 value) {
        address oracle = _oracleCache[token][valueCurrency];
        oracle = _getOracle(token, valueCurrency);

        return IOracle(oracle).getAmountInPeg(token, amount, valueCurrency);
    }

    /// View value and borrowable together
    function _viewValueBorrowable(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal view virtual returns (uint256 value, uint256 borrowablePer10k) {
        address oracle = _oracleCache[token][valueCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().tokenOracle(token, valueCurrency);
        }
        (value, borrowablePer10k) = IOracle(oracle).viewPegAmountAndBorrowable(
            token,
            amount,
            valueCurrency
        );
    }

    /// Retrieve value (updating oracle) as well as borrowable per 10k
    function _getValueBorrowable(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal virtual returns (uint256 value, uint256 borrowablerPer10k) {
        address oracle = _oracleCache[token][valueCurrency];
        oracle = _getOracle(token, valueCurrency);

        (value, borrowablerPer10k) = IOracle(oracle).getPegAmountAndBorrowable(
            token,
            amount,
            valueCurrency
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Oracle.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// Use UniswapV2-compatible pairs to kepp up a twap oracle
/// In all this one must be careful of staleness
contract TwapOracle is Oracle {
    uint256 constant FP112 = 2**112;
    uint256 constant FP56 = 2**56;

    struct TwapOracleState {
        address token0;
        address token1;
        uint256 cumulativePrice0;
        uint256 price0FP;
        uint256 lastUpdated;
        uint256 kLast;
        uint256 totalSupplyLast;
        uint256 kCurrent;
        uint256 totalSupplyCurrent;
    }

    mapping(address => TwapOracleState) public pairState;

    mapping(address => mapping(address => address)) public bestPairByTokens;

    uint256 priceUpdateWindow = 5 minutes;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(TWAP_ORACLE);
    }

    /// View TwapOracleState of pair
    function viewPairState(address pair)
        public
        view
        returns (TwapOracleState memory oracleState)
    {
        oracleState = pairState[pair];

        (, , uint256 pairLastUpdated) = IUniswapV2Pair(pair).getReserves();
        uint256 timeDelta = pairLastUpdated - oracleState.lastUpdated;

        if (timeDelta > priceUpdateWindow) {
            uint256 newCumul0 = IUniswapV2Pair(pair).price0CumulativeLast();
            oracleState.price0FP =
                (newCumul0 - oracleState.cumulativePrice0) /
                timeDelta;
            oracleState.cumulativePrice0 = newCumul0;
            oracleState.lastUpdated = pairLastUpdated;

            oracleState.kLast = oracleState.kCurrent;
            oracleState.totalSupplyLast = oracleState.totalSupplyCurrent;
            oracleState.kCurrent = IUniswapV2Pair(pair).kLast();
            oracleState.totalSupplyCurrent = IUniswapV2Pair(pair).totalSupply();
        }
    }

    /// Retrieve TwapOracleState of pair, updating
    function _getPairState(address pair)
        internal
        returns (TwapOracleState storage oracleState)
    {
        oracleState = pairState[pair];

        (, , uint256 pairLastUpdated) = IUniswapV2Pair(pair).getReserves();
        uint256 timeDelta = pairLastUpdated - oracleState.lastUpdated;

        if (timeDelta > priceUpdateWindow) {
            uint256 newCumul0 = IUniswapV2Pair(pair).price0CumulativeLast();
            oracleState.price0FP =
                (newCumul0 - oracleState.cumulativePrice0) /
                timeDelta;
            oracleState.cumulativePrice0 = newCumul0;
            oracleState.lastUpdated = pairLastUpdated;

            oracleState.kLast = oracleState.kCurrent;
            oracleState.totalSupplyLast = oracleState.totalSupplyCurrent;
            oracleState.kCurrent = IUniswapV2Pair(pair).kLast();
            oracleState.totalSupplyCurrent = IUniswapV2Pair(pair).totalSupply();
        }
    }

    /// Retrieve TwapOracleState of pair, updating
    function getPairState(address pair)
        external
        returns (TwapOracleState memory oracleState)
    {
        return _getPairState(pair);
    }

    /// View amount in peg via twap price
    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public view virtual override returns (uint256) {
        (address token0, address token1) = sortTokens(token, pegCurrency);
        TwapOracleState memory oracleState = viewPairState(
            bestPairByTokens[token0][token1]
        );
        if (token == token0) {
            return (inAmount * oracleState.price0FP) / FP112;
        } else {
            return (inAmount * FP112) / oracleState.price0FP;
        }
    }

    /// Update twap price and get corresponding peg amount
    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public virtual override returns (uint256) {
        (address token0, address token1) = sortTokens(token, pegCurrency);
        TwapOracleState storage oracleState = _getPairState(
            bestPairByTokens[token0][token1]
        );
        if (token == token0) {
            return (inAmount * oracleState.price0FP) / FP112;
        } else {
            return (inAmount * FP112) / oracleState.price0FP;
        }
    }

    /// Init price via reserves
    function initPairState(address pair)
        public
        returns (TwapOracleState memory)
    {
        TwapOracleState storage oracleState = pairState[pair];

        // To avoid sandwich attacks on this activation call getAmountInPeg once more
        // before releasing to public
        if (oracleState.token0 == address(0)) {
            IUniswapV2Pair uniPair = IUniswapV2Pair(pair);

            (
                uint112 reserve0,
                uint112 reserve1,
                uint256 pairLastUpdated
            ) = uniPair.getReserves();

            uint256 kLast = uniPair.kLast();
            uint256 totalSupply = uniPair.totalSupply();
            pairState[pair] = TwapOracleState({
                token0: uniPair.token0(),
                token1: uniPair.token1(),
                cumulativePrice0: uniPair.price0CumulativeLast(),
                price0FP: (FP112 * reserve1) / reserve0,
                lastUpdated: pairLastUpdated,
                kLast: kLast,
                kCurrent: kLast,
                totalSupplyLast: totalSupply,
                totalSupplyCurrent: totalSupply
            });

            return pairState[pair];
        } else {
            return _getPairState(pair);
        }
    }

    /// Time window after which price is updated
    function setPriceUpdateWindow(uint256 window)
        external
        onlyOwnerExecDisabler
    {
        priceUpdateWindow = window;
    }

    /// Update reserves of a pair in a time weighted manner
    function getTwapReserves(address pair)
        external
        returns (
            address token0,
            address token1,
            uint256 res0,
            uint256 res1,
            uint256 kLast,
            uint256 totalSupplyLast
        )
    {
        TwapOracleState storage oracleState = _getPairState(pair);

        (res0, res1) = price0FP2Reserves(
            oracleState.kLast,
            oracleState.price0FP
        );
        token0 = oracleState.token0;
        token1 = oracleState.token1;

        kLast = oracleState.kLast;
        totalSupplyLast = oracleState.totalSupplyLast;
    }

    /// view reserves of a pair in a time weighted manner
    function viewTwapReserves(address pair)
        external
        view
        returns (
            address token0,
            address token1,
            uint256 res0,
            uint256 res1,
            uint256 kLast,
            uint256 totalSupplyLast
        )
    {
        TwapOracleState memory oracleState = viewPairState(pair);

        (res0, res1) = price0FP2Reserves(
            oracleState.kLast,
            oracleState.price0FP
        );
        token0 = oracleState.token0;
        token1 = oracleState.token1;

        kLast = oracleState.kLast;
        totalSupplyLast = oracleState.totalSupplyLast;
    }

    /// Convert price to reserves
    function price0FP2Reserves(uint256 k, uint256 price0FP)
        public
        pure
        returns (uint256 res0, uint256 res1)
    {
        // price0FP ~= FP112 * res1 / res0 and k = res1 * res0
        // => k * price0FP = FP112 * res1 / res0 * res1 * res0
        // => k * price0FP / FP112 = res1^2
        // => res0 = sqrt(k * price1FP / FP112) and price1FP = FP112 * 1 / (price0FP / FP112)
        // => res0 = sqrt(k * FP112 / price0FP)
        if (k > price0FP) {
            res0 = sqrt((((k * FP56) / price0FP) * FP56));
        } else {
            // for small k scale up completely first
            res0 = sqrt((k * FP112) / price0FP);
        }
        res1 = k / res0;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

    /// returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Identical address!");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Zero address!");
    }

    /// Set up oracle based on a pair and whether we prefer this one
    function setOracleSpecificParams(
        address fromToken,
        address toToken,
        address pair,
        bool isBest
    ) external onlyOwnerExec {
        _setOracleSpecificParams(fromToken, toToken, pair, isBest);
    }

    /// Set up pair, initializing pair state
    /// Note: vulnerable to sandwich attack if lending starts immediately
    function _setOracleSpecificParams(
        address fromToken,
        address toToken,
        address pair,
        bool isBest
    ) internal {
        (address token0, address token1) = sortTokens(fromToken, toToken);
        require(
            IUniswapV2Pair(pair).token0() == token0 &&
                IUniswapV2Pair(pair).token1() == token1,
            "Pair does not match tokens"
        );
        initPairState(pair);

        if (isBest) {
            bestPairByTokens[token0][token1] = pair;
        }
    }

    /// Set up the pair for a twap oracle
    function _setOracleParams(
        address fromToken,
        address toToken,
        bytes calldata data
    ) internal override {
        (address pair, bool isBest) = abi.decode(data, (address, bool));
        _setOracleSpecificParams(fromToken, toToken, pair, isBest);
    }

    /// Encode params for initialization
    function encodeAndCheckOracleParams(
        address tokenFrom,
        address tokenTo,
        address pair,
        bool isBest
    ) external view returns (bool, bytes memory) {
        (address token0, address token1) = sortTokens(tokenFrom, tokenTo);
        TwapOracleState storage state = pairState[pair];
        bool matches = state.token0 == token0 && state.token1 == token1;

        if (isBest) {
            matches = matches && bestPairByTokens[token0][token1] == pair;
        }

        return (matches, abi.encode(pair, isBest));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";

/// @title DependentContract.
abstract contract DependentContract {
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    uint256[] public _dependsOnCharacters;
    uint256[] public _dependsOnRoles;

    uint256[] public _charactersPlayed;
    uint256[] public _rolesPlayed;

    /// @dev returns all characters played by this contract (e.g. stable coin, oracle registry)
    function charactersPlayed() public view returns (uint256[] memory) {
        return _charactersPlayed;
    }

    /// @dev returns all roles played by this contract
    function rolesPlayed() public view returns (uint256[] memory) {
        return _rolesPlayed;
    }

    /// @dev returns all the character dependencies like FEE_RECIPIENT
    function dependsOnCharacters() public view returns (uint256[] memory) {
        return _dependsOnCharacters;
    }

    /// @dev returns all the roles dependencies of this contract like FUND_TRANSFERER
    function dependsOnRoles() public view returns (uint256[] memory) {
        return _dependsOnRoles;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOracleListener is DependentContract {
    constructor() {
        _dependsOnRoles.push(ORACLE_LISTENER);
    }

    function isOracleListener(address contr) internal view returns (bool) {
        return roleCache[contr][ORACLE_LISTENER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";
import "../OracleRegistry.sol";

abstract contract DependsOnOracleRegistry is DependentContract {
    constructor() {
        _dependsOnCharacters.push(ORACLE_REGISTRY);
    }

    function oracleRegistry() internal view returns (OracleRegistry) {
        return OracleRegistry(mainCharacterCache[ORACLE_REGISTRY]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOnTranche is DependentContract {
    constructor() {
        _dependsOnRoles.push(TRANCHE);
    }

    function isTranche(address contr) internal view returns (bool) {
        return roleCache[contr][TRANCHE];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";
import "../TrancheIDService.sol";

abstract contract DependsOnTrancheIDService is DependentContract {
    constructor() {
        _dependsOnCharacters.push(TRANCHE_ID_SERVICE);
    }

    function trancheIdService() internal view returns (TrancheIDService) {
        return TrancheIDService(mainCharacterCache[TRANCHE_ID_SERVICE]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./DependentContract.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware is DependentContract {
    Roles public immutable roles;

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Roles(_roles);
    }

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        require(owner() == msg.sender, "Roles: caller is not the owner");
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || executor() == msg.sender,
            "Roles: caller is not the owner or executor"
        );
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor or disabler
    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                disabler() == msg.sender,
            "Caller is not the owner, executor or authorized disabler"
        );
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor or activator
    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                isActivator(msg.sender),
            "Caller is not the owner, executor or authorized activator"
        );
        _;
    }

    /// @dev Updates the role cache for a specific role and address
    function updateRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.roles(contr, role);
    }

    /// @dev Updates the main character cache for a speciic character
    function updateMainCharacterCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    /// @dev returns the owner's address
    function owner() internal view returns (address) {
        return roles.owner();
    }

    /// @dev returns the executor address
    function executor() internal returns (address) {
        return roles.executor();
    }

    /// @dev returns the disabler address
    function disabler() internal view returns (address) {
        return roles.mainCharacters(DISABLER);
    }

    /// @dev checks whether the passed address is activator or not
    function isActivator(address contr) internal view returns (bool) {
        return roles.roles(contr, ACTIVATOR);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IDependencyController.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant FUND_TRANSFERER = 1;
uint256 constant MINTER_BURNER = 2;
uint256 constant TRANCHE = 3;
uint256 constant ORACLE_LISTENER = 4;
uint256 constant LIQUIDATOR = 5;
uint256 constant UNDERWATER_LIQUIDATOR = 6;

uint256 constant FUND = 101;
uint256 constant STABLECOIN = 102;
uint256 constant FEE_RECIPIENT = 103;
uint256 constant STRATEGY_REGISTRY = 104;
uint256 constant TRANCHE_ID_SERVICE = 105;
uint256 constant ORACLE_REGISTRY = 106;
uint256 constant ISOLATED_LENDING = 107;
uint256 constant TWAP_ORACLE = 108;

uint256 constant DISABLER = 1001;
uint256 constant DEPENDENCY_CONTROLLER = 1002;
uint256 constant ACTIVATOR = 1003;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet during
/// beta and will then be transfered to governance
contract Roles is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    event RoleGiven(uint256 indexed role, address player);
    event CharacterAssigned(
        uint256 indexed character,
        address playerBefore,
        address playerNew
    );
    event RoleRemoved(uint256 indexed role, address player);

    constructor(address targetOwner) Ownable() {
        transferOwnership(targetOwner);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                mainCharacters[DEPENDENCY_CONTROLLER] == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    /// @dev assign role to an account
    function giveRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit RoleGiven(role, actor);
        roles[actor][role] = true;
    }

    /// @dev revoke role of a particular account
    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit RoleRemoved(role, actor);
        roles[actor][role] = false;
    }

    /// @dev set main character
    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit CharacterAssigned(role, mainCharacters[role], actor);
        mainCharacters[role] = actor;
    }

    /// @dev returns the current executor
    function executor() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_CONTROLLER];
        if (depController != address(0)) {
            exec = IDependencyController(depController).currentExecutor();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDependencyController {
    function currentExecutor() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOracle {
    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external view returns (uint256);

    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external returns (uint256);

    function viewPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external view returns (uint256, uint256);

    function getPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external returns (uint256, uint256);

    function setOracleParams(
        address token,
        address pegCurrency,
        uint256 borrowable,
        bytes calldata data
    ) external;
}

// TODO: compatible with NFTs