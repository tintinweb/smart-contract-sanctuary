// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This is a modified implementation of OpenZeppelin's Ownable.sol.
 * The modifications allow the contract to be inherited by a proxy's logic contract.
 * Any owner-only functions on the base implementation will be unusable.
 *
 * By default, the owner account will be a null address which can be set by invoking
 * a function with the `initializer` modifier. The owner can later be changed with
 * {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner. It also makes available the `initializer` modifier, which will set
 * the owner to `msg.sender` the first time the function is invoked, and will
 * revert if the owner has already been set.
 *
 * Note: This contract should only be inherited by proxy implementation contracts
 * where the implementation will only ever be used as the logic address for proxies.
 * The constructor permanently locks the owner of the implementation contract, but the
 * owner of the proxies can be configured by the first caller.
 */
contract OwnableProxyImplementation {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _owner = address(1);
    emit OwnershipTransferred(address(0), address(1));
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner {
    require(_owner == msg.sender, "!owner");
    _;
  }

  /**
   * @dev Initializes the contract setting `initialOwner` as the initial owner.
   * Reverts if owner has already been set.
   */
  modifier initializer(address initialOwner) {
    require(_owner == address(0), "already initialized");
    _owner = initialOwner;
    emit OwnershipTransferred(address(0), initialOwner);
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
    // Modified from OZ contract - sets owner to address(1) to prevent
    // the initializer from being invoked after ownership is revoked.
    emit OwnershipTransferred(_owner, address(1));
    _owner = address(1);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IAdapterRegistry {
/* ========== Events ========== */

  event ProtocolAdapterAdded(uint256 protocolId, address protocolAdapter);

  event ProtocolAdapterRemoved(uint256 protocolId);

  event TokenAdapterAdded(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenAdapterRemoved(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenSupportAdded(address underlying);

  event TokenSupportRemoved(address underlying);

  event VaultFactoryAdded(address factory);

  event VaultFactoryRemoved(address factory);

  event VaultAdded(address underlying, address vault);

  event VaultRemoved(address underlying, address vault);

/* ========== Structs ========== */

  struct TokenAdapter {
    address adapter;
    uint96 protocolId;
  }

/* ========== Storage ========== */

  function protocolsCount() external view returns (uint256);

  function protocolAdapters(uint256 id) external view returns (address protocolAdapter);

  function protocolAdapterIds(address protocolAdapter) external view returns (uint256 id);

  function vaultsByUnderlying(address underlying) external view returns (address vault);

  function approvedVaultFactories(address factory) external view returns (bool approved);

/* ========== Vault Factory Management ========== */

  function addVaultFactory(address _factory) external;

  function removeVaultFactory(address _factory) external;

/* ========== Vault Management ========== */

  function addVault(address vault) external;

  function removeVault(address vault) external;

/* ========== Protocol Adapter Management ========== */

  function addProtocolAdapter(address protocolAdapter) external returns (uint256 id);

  function removeProtocolAdapter(address protocolAdapter) external;

/* ========== Token Adapter Management ========== */

  function addTokenAdapter(address adapter) external;

  function addTokenAdapters(address[] calldata adapters) external;

  function removeTokenAdapter(address adapter) external;

/* ========== Vault Queries ========== */

  function getVaultsList() external view returns (address[] memory);

  function haveVaultFor(address underlying) external view returns (bool);

/* ========== Protocol Queries ========== */

  function getProtocolAdaptersAndIds() external view returns (address[] memory adapters, uint256[] memory ids);

  function getProtocolMetadata(uint256 id) external view returns (address protocolAdapter, string memory name);

  function getProtocolForTokenAdapter(address adapter) external view returns (address protocolAdapter);

/* ========== Supported Token Queries ========== */

  function isSupported(address underlying) external view returns (bool);

  function getSupportedTokens() external view returns (address[] memory list);

/* ========== Token Adapter Queries ========== */

  function isApprovedAdapter(address adapter) external view returns (bool);

  function getAdaptersList(address underlying) external view returns (address[] memory list);

  function getAdapterForWrapperToken(address wrapperToken) external view returns (address);

  function getAdaptersCount(address underlying) external view returns (uint256);

  function getAdaptersSortedByAPR(address underlying)
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdaptersSortedByAPRWithDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  )
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdapterWithHighestAPR(address underlying) external view returns (address adapter, uint256 apr);

  function getAdapterWithHighestAPRForDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  ) external view returns (address adapter, uint256 apr);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}


interface IERC20MetadataBytes32 {
  function name() external view returns (bytes32);
  function symbol() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IAdapterRegistry.sol";
import "./ITokenAdapter.sol";
import "./IRewardsSeller.sol";


interface INirnVault {
/* ========== Events ========== */

  /** @dev Emitted when an adapter is removed and its balance fully withdrawn. */
  event AdapterRemoved(IErc20Adapter adapter);

  /** @dev Emitted when weights or adapters are updated. */
  event AllocationsUpdated(IErc20Adapter[] adapters, uint256[] weights);

  /** @dev Emitted when performance fees are claimed. */
  event FeesClaimed(uint256 underlyingAmount, uint256 sharesMinted);

  /** @dev Emitted when a rebalance happens without allocation changes. */
  event Rebalanced();

  /** @dev Emitted when max underlying is updated. */
  event SetMaximumUnderlying(uint256 maxBalance);

  /** @dev Emitted when fee recipient address is set. */
  event SetFeeRecipient(address feeRecipient);

  /** @dev Emitted when performance fee is set. */
  event SetPerformanceFee(uint256 performanceFee);

  /** @dev Emitted when reserve ratio is set. */
  event SetReserveRatio(uint256 reserveRatio);

  /** @dev Emitted when rewards seller contract is set. */
  event SetRewardsSeller(address rewardsSeller);

  /** @dev Emitted when a deposit is made. */
  event Deposit(uint256 shares, uint256 underlying);

  /** @dev Emitted when a deposit is made. */
  event Withdrawal(uint256 shares, uint256 underlying);

/* ========== Structs ========== */

  struct DistributionParameters {
    IErc20Adapter[] adapters;
    uint256[] weights;
    uint256[] balances;
    int256[] liquidityDeltas;
    uint256 netAPR;
  }

/* ========== Initializer ========== */

  function initialize(
    address _underlying,
    address _rewardsSeller,
    address _feeRecipient,
    address _owner
  ) external;

/* ========== Config Queries ========== */

  function minimumAPRImprovement() external view returns (uint256);

  function registry() external view returns (IAdapterRegistry);

  function eoaSafeCaller() external view returns (address);

  function underlying() external view returns (address);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);  

  function feeRecipient() external view returns (address);

  function rewardsSeller() external view returns (IRewardsSeller);

  function lockedTokens(address) external view returns (bool);

  function maximumUnderlying() external view returns (uint256);

  function performanceFee() external view returns (uint64);

  function reserveRatio() external view returns (uint64);

  function priceAtLastFee() external view returns (uint128);

  function minimumCompositionChangeDelay() external view returns (uint256);

  function canChangeCompositionAfter() external view returns (uint96);

/* ========== Admin Actions ========== */

  function setMaximumUnderlying(uint256 _maximumUnderlying) external;

  function setPerformanceFee(uint64 _performanceFee) external;

  function setFeeRecipient(address _feeRecipient) external;

  function setRewardsSeller(IRewardsSeller _rewardsSeller) external;

  function setReserveRatio(uint64 _reserveRatio) external;

/* ========== Balance Queries ========== */

  function balance() external view returns (uint256 sum);

  function reserveBalance() external view returns (uint256);

/* ========== Fee Queries ========== */

  function getPendingFees() external view returns (uint256);

/* ========== Price Queries ========== */

  function getPricePerFullShare() external view returns (uint256);

  function getPricePerFullShareWithFee() external view returns (uint256);

/* ========== Reward Token Sales ========== */

  function sellRewards(address rewardsToken, bytes calldata params) external;

/* ========== Adapter Queries ========== */

  function getBalances() external view returns (uint256[] memory balances);

  function getAdaptersAndWeights() external view returns (
    IErc20Adapter[] memory adapters,
    uint256[] memory weights
  );

/* ========== Status Queries ========== */

  function getCurrentLiquidityDeltas() external view returns (int256[] memory liquidityDeltas);

  function getAPR() external view returns (uint256);

  function currentDistribution() external view returns (
    DistributionParameters memory params,
    uint256 totalProductiveBalance,
    uint256 _reserveBalance
  );

/* ========== Deposit/Withdraw ========== */

  function deposit(uint256 amount) external returns (uint256 shares);

  function depositTo(uint256 amount, address to) external returns (uint256 shares);

  function withdraw(uint256 shares) external returns (uint256 owed);

  function withdrawUnderlying(uint256 amount) external returns (uint256 shares);

/* ========== Rebalance Actions ========== */

  function rebalance() external;

  function rebalanceWithNewWeights(uint256[] calldata proposedWeights) external;

  function rebalanceWithNewAdapters(
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IRewardsSeller {
  /**
   * @dev Sell `rewardsToken` for `underlyingToken`.
   * Should only be called after `rewardsToken` is transferred.
   * @param sender - Address of account that initially triggered the call. Can be used to restrict who can trigger a sale.
   * @param rewardsToken - Address of the token to sell.
   * @param underlyingToken - Address of the token to buy.
   * @param params - Any additional data that the caller provided.
   */
  function sellRewards(
    address sender,
    address rewardsToken,
    address underlyingToken,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IErc20Adapter {
/* ========== Metadata ========== */

  function underlying() external view returns (address);

  function token() external view returns (address);

  function name() external view returns (string memory);

  function availableLiquidity() external view returns (uint256);

/* ========== Conversion ========== */

  function toUnderlyingAmount(uint256 tokenAmount) external view returns (uint256);

  function toWrappedAmount(uint256 underlyingAmount) external view returns (uint256);

/* ========== Performance Queries ========== */

  function getAPR() external view returns (uint256);

  function getHypotheticalAPR(int256 liquidityDelta) external view returns (uint256);

  function getRevenueBreakdown()
    external
    view
    returns (
      address[] memory assets,
      uint256[] memory aprs
    );

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() external view returns (uint256);

  function balanceUnderlying() external view returns (uint256);

/* ========== Interactions ========== */

  function deposit(uint256 amountUnderlying) external returns (uint256 amountMinted);

  function withdraw(uint256 amountToken) external returns (uint256 amountReceived);

  function withdrawAll() external returns (uint256 amountReceived);

  function withdrawUnderlying(uint256 amountUnderlying) external returns (uint256 amountBurned);

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external returns (uint256 amountReceived);
}

interface IEtherAdapter is IErc20Adapter {
  function depositETH() external payable returns (uint256 amountMinted);

  function withdrawAsETH(uint256 amountToken) external returns (uint256 amountReceived);

  function withdrawAllAsETH() external returns (uint256 amountReceived);

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external returns (uint256 amountBurned); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IAdapterRegistry.sol";
import "../interfaces/ITokenAdapter.sol";
import "../interfaces/IERC20.sol";
import "../libraries/LowGasSafeMath.sol";
import "../libraries/MinimalSignedMath.sol";
import "../libraries/ArrayHelper.sol";
import "../libraries/DynamicArrays.sol";
import "../libraries/Fraction.sol";
import "../libraries/SafeCast.sol";


library AdapterHelper {
  using Fraction for uint256;
  using LowGasSafeMath for uint256;
  using MinimalSignedMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ArrayHelper for address[];
  using ArrayHelper for uint256[];
  using DynamicArrays for uint256[];

  function packAdapterAndWeight(
    IErc20Adapter adapter,
    uint256 weight
  )
    internal
    pure
    returns (bytes32 encoded)
  {
    assembly {
      encoded := or(shl(96, adapter), weight)
    }
  }

  function packAdaptersAndWeights(
    IErc20Adapter[] memory adapters,
    uint256[] memory weights
  )
    internal
    pure
    returns (bytes32[] memory encodedArray)
  {
    uint256 len = adapters.length;
    encodedArray = new bytes32[](len);
    for (uint256 i; i < len; i++) {
      IErc20Adapter adapter = adapters[i];
      uint256 weight = weights[i];
      bytes32 encoded;
      assembly {
        encoded := or(shl(96, adapter), weight)
      }
      encodedArray[i] = encoded;
    }
  }

  function unpackAdapterAndWeight(bytes32 encoded)
    internal
    pure
    returns (
      IErc20Adapter adapter,
      uint256 weight
    )
  {
    assembly {
      adapter := shr(96, encoded)
      weight := and(
        encoded,
        0x0000000000000000000000000000000000000000ffffffffffffffffffffffff
      )
    }
  }

  function unpackAdaptersAndWeights(bytes32[] memory encodedArray)
    internal
    pure
    returns (
      IErc20Adapter[] memory adapters,
      uint256[] memory weights
    )
  {
    uint256 len = encodedArray.length;
    adapters = new IErc20Adapter[](len);
    weights = new uint256[](len);
    for (uint256 i; i < len; i++) {
      bytes32 encoded = encodedArray[i];
      IErc20Adapter adapter;
      uint256 weight;
      assembly {
        adapter := shr(96, encoded)
        weight := and(
          encoded,
          0x0000000000000000000000000000000000000000ffffffffffffffffffffffff
        )
      }
      adapters[i] = adapter;
      weights[i] = weight;
    }
  }

  function getNetAPR(
    IErc20Adapter[] memory adapters,
    uint256[] memory weights,
    int256[] memory liquidityDeltas
  ) internal view returns (uint256 netAPR) {
    uint256 len = adapters.length;
    for (uint256 i; i < len; i++) {
      uint256 weight = weights[i];
      if (weight > 0) {
        netAPR = netAPR.add(
          adapters[i].getHypotheticalAPR(liquidityDeltas[i]).mulFractionE18(weight)
        );
      }
    }
  }

  function getLiquidityDeltas(
    uint256 totalProductiveBalance,
    uint256[] memory balances,
    uint256[] memory weights
  ) internal pure returns (int256[] memory deltas) {
    uint256 len = balances.length;
    deltas = new int256[](len);
    for (uint256 i; i < len; i++) {
      uint256 targetBalance = totalProductiveBalance.mulFractionE18(weights[i]);
      deltas[i] = targetBalance.toInt256().sub(balances[i].toInt256());
    }
  }

  function getBalances(IErc20Adapter[] memory adapters) internal view returns (uint256[] memory balances) {
    uint256 len = adapters.length;
    balances = new uint256[](len);
    for (uint256 i; i < len; i++) balances[i] = adapters[i].balanceUnderlying();
  }

  function getExcludedAdapterIndices(
    IErc20Adapter[] memory oldAdapters,
    IErc20Adapter[] memory newAdapters
  ) internal pure returns (uint256[] memory excludedAdapterIndices) {
    uint256 selfLen = oldAdapters.length;
    uint256 otherLen = newAdapters.length;
    excludedAdapterIndices = DynamicArrays.dynamicUint256Array(selfLen);
    for (uint256 i; i < selfLen; i++) {
      IErc20Adapter element = oldAdapters[i];
      for (uint256 j; j < otherLen; j++) {
        if (element == newAdapters[j]) {
          element = IErc20Adapter(0);
          break;
        }
      }
      if (element != IErc20Adapter(0)) {
        excludedAdapterIndices.dynamicPush(i);
      }
    }
  }

  /**
   * @dev Rebalances the vault by withdrawing tokens from adapters with negative liquidity deltas
   * and depositing to adapters with positive liquidity deltas.
   *
   * Note: This does not necessarily result in a vault composition that matches the assigned weights,
   * as some of the lending markets for adapters with negative deltas may have insufficient liquidity
   * to process withdrawals of the desired amounts. In this case, the vault will withdraw what it can
   * and deposit up to the amount withdrawn to the other markets.
   *
   * Returns an array with indices of the adapters that both have a weight of zero and were able to
   * process a withdrawal of the vault's full balance. This array is used to remove those adapters.
   */
  function rebalance(
    IErc20Adapter[] memory adapters,
    uint256[] memory weights,
    int256[] memory liquidityDeltas,
    uint256 reserveBalance
  ) internal returns (uint256[] memory removedIndices) {
    uint256 len = liquidityDeltas.length;
    removedIndices = DynamicArrays.dynamicUint256Array(len);
    uint256 totalAvailableBalance = reserveBalance;
    // Execute withdrawals first
    for (uint256 i; i < len; i++) {
      int256 delta = liquidityDeltas[i];
      if (delta < 0) {
        uint256 amountToWithdraw = (-delta).toUint256();
        uint256 amountWithdrawn = adapters[i].withdrawUnderlyingUpTo(amountToWithdraw);
        // If the weight is 0, `amountToWithdraw` is the balance of the vault in the adapter
        // and the vault intends to remove the adapter. If the rebalance is able to withdraw
        // the full balance, it will mark the index of the adapter as able to be removed
        // so that it can be deleted by the rebalance function.
        if (weights[i] == 0 && amountWithdrawn == amountToWithdraw) {
          removedIndices.dynamicPush(i);
        }
        totalAvailableBalance = totalAvailableBalance.add(amountWithdrawn);
      }
    }
    // Execute deposits after
    for (uint256 i; i < len; i++) {
      int256 delta = liquidityDeltas[i];
      if (delta > 0) {
        if (totalAvailableBalance == 0) break;
        uint256 amountToDeposit = delta.toUint256();
        if (amountToDeposit >= totalAvailableBalance) {
          IErc20Adapter(adapters[i]).deposit(totalAvailableBalance);
          break;
        }
        IErc20Adapter(adapters[i]).deposit(amountToDeposit);
        totalAvailableBalance = totalAvailableBalance.sub(amountToDeposit);
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../libraries/LowGasSafeMath.sol";
import "../interfaces/ITokenAdapter.sol";


library ArrayHelper {
  using EnumerableSet for EnumerableSet.AddressSet;
  using LowGasSafeMath for uint256;

/* ========== Type Cast ========== */

  /**
   * @dev Cast an enumerable address set as an address array.
   * The enumerable set library stores the values as a bytes32 array, this function
   * casts it as an address array with a pointer assignment.
   */
  function toArray(EnumerableSet.AddressSet storage set) internal view returns (address[] memory arr) {
    bytes32[] memory bytes32Arr = set._inner._values;
    assembly { arr := bytes32Arr }
  }

  /**
   * @dev Cast an array of IErc20Adapter to an array of address using a pointer assignment.
   * Note: The resulting array is the same as the original, so all changes to one will be
   * reflected in the other.
   */
  function toAddressArray(IErc20Adapter[] memory _arr) internal pure returns (address[] memory arr) {
    assembly { arr := _arr }
  }

/* ========== Math ========== */

  /**
   * @dev Computes the sum of a uint256 array.
   */
  function sum(uint256[] memory arr) internal pure returns (uint256 _sum) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) _sum = _sum.add(arr[i]);
  }

/* ========== Removal ========== */

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(uint256[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      uint256 last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(address[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      address last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(IErc20Adapter[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      IErc20Adapter last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function remove(bytes32[] storage arr, uint256 index) internal {
    uint256 len = arr.length;
    if (index == len - 1) {
      arr.pop();
      return;
    }
    bytes32 last = arr[len - 1];
    arr[index] = last;
    arr.pop();
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function remove(address[] storage arr, uint256 index) internal {
    uint256 len = arr.length;
    if (index == len - 1) {
      arr.pop();
      return;
    }
    address last = arr[len - 1];
    arr[index] = last;
    arr.pop();
  }

/* ========== Search ========== */

  /**
   * @dev Find the index of an address in an array.
   * If the address is not found, revert.
   */
  function indexOf(address[] memory arr, address find) internal pure returns (uint256) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return i;
    revert("element not found");
  }

  /**
   * @dev Determine whether an element is included in an array.
   */
  function includes(address[] memory arr, address find) internal pure returns (bool) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return true;
    return false;
  }

/* ========== Sorting ========== */

  /**
   * @dev Given an array of tokens and scores, sort by scores in descending order.
   * Maintains the relationship between elements of each array at the same index.
   */
  function sortByDescendingScore(
    address[] memory addresses,
    uint256[] memory scores
  ) internal pure {
    uint256 len = addresses.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 score = scores[i];
      address _address = addresses[i];
      uint256 j = i - 1;
      while (int(j) >= 0 && scores[j] < score) {
        scores[j + 1] = scores[j];
        addresses[j + 1] = addresses[j];
        j--;
      }
      scores[j + 1] = score;
      addresses[j + 1] = _address;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

/**
 * @dev Library for handling dynamic in-memory arrays.
 *
 * There is a very good reason for Solidity not supporting this by default -- dynamic
 * arrays in memory completely break memory management for Solidity when used improperly;
 * however, they can be created manually in a safe way so long as the maximum size is known
 * beforehand.
 *
 * This applies primarily to situations where a subset is taken from an existing array
 * by some filtering process.
 *
 * This library should not be used to bypass Solidity's lack of dynamic memory array
 * support in any situation where the code could potentially cause the array to exceed
 * the maximum size assigned in the array creation call. Doing so is likely to have
 * unintended and unpredictable side effects.
 */
library DynamicArrays {
  /**
   * @dev Reserves space in memory for an array of length `size`, but sets the length to 0.
   * This can be safely used for a dynamic array so long as the maximum possible size is
   * known beforehand. If the array can exceed `size`, pushing to it will corrupt memory.
   */
  function dynamicAddressArray(uint256 size) internal pure returns (address[] memory arr) {
    arr = new address[](size);
    assembly { mstore(arr, 0) }
  }

  /**
   * @dev Reserves space in memory for an array of length `size`, but sets the length to 0.
   * This can be safely used for a dynamic array so long as the maximum possible size is
   * known beforehand. If the array can exceed length `size`, pushing to it will corrupt memory.
   */
  function dynamicUint256Array(uint256 size) internal pure returns (uint256[] memory arr) {
    arr = new uint256[](size);
    assembly { mstore(arr, 0) }
  }

  /**
   * @dev Pushes an address to an in-memory array by reassigning the array length and storing
   * the element in the position used by solidity for the current array index.
   * Note: This should ONLY be used on an array created with `dynamicAddressArray`. Using it
   * on a typical array created with `new address[]()` will almost certainly have unintended
   * and unpredictable side effects.
   */
  function dynamicPush(address[] memory arr, address element) internal pure {
    assembly {
      let size := mload(arr)
      let ptr := add(
        add(arr, 32),
        mul(size, 32)
      )
      mstore(ptr, element)
      mstore(arr, add(size, 1))
    }
  }

  /**
   * @dev Pushes a uint256 to an in-memory array by reassigning the array length and storing
   * the element in the position used by solidity for the current array index.
   * Note: This should ONLY be used on an array created with `dynamicUint256Array`. Using it
   * on a typical array created with `new uint256[]()` will almost certainly have unintended
   * and unpredictable side effects.
   */
  function dynamicPush(uint256[] memory arr, uint256 element) internal pure {
    assembly {
      let size := mload(arr)
      let ptr := add(
        add(arr, 32),
        mul(size, 32)
      )
      mstore(ptr, element)
      mstore(arr, add(size, 1))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../libraries/LowGasSafeMath.sol";


library Fraction {
  using LowGasSafeMath for uint256;

  uint256 internal constant ONE_E18 = 1e18;

  function mulFractionE18(uint256 a, uint256 fraction) internal pure returns (uint256) {
    return a.mul(fraction) / ONE_E18;
  }

  function mulSubFractionE18(uint256 a, uint256 fraction) internal pure returns (uint256) {
    return a.sub(a.mul(fraction) / ONE_E18);
  }

  function toFractionE18(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(ONE_E18) / b;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/LowGasSafeMath.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash b83fcf497e895ae59b97c9d04e997023f69b5e97.

Subject to the GPL-2.0 license
*************************************************************************************************/


/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }

  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x + y) >= x, errorMessage);
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y <= x);
    z = x - y;
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require(y <= x, errorMessage);
    z = x - y;
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (x == 0) return 0;
    z = x * y;
    require(z / x == y);
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    if (x == 0) return 0;
    z = x * y;
    require(z / x == y, errorMessage);
  }

  /// @notice Returns ceil(x / y)
  /// @param x The numerator
  /// @param y The denominator
  /// @return z The quotient of x and y
  function divCeil(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x % y == 0 ? x / y : (x/y) + 1;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;


library MinimalSignedMath {
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  function add(uint256 a, int256 b) internal pure returns (uint256) {
    require(a < 2**255);
    int256 _a = int256(a);
    int256 c = _a + b;
    require((b >= 0 && c >= _a) || (b < 0 && c < _a));
    if (c < 0) return 0;
    return uint256(c);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IAdapterRegistry.sol";
import "../interfaces/ITokenAdapter.sol";
import "../libraries/LowGasSafeMath.sol";
import "../libraries/Fraction.sol";



library RebalanceValidation {
  using LowGasSafeMath for uint256;
  using Fraction for uint256;

  function validateSufficientImprovement(
    uint256 currentAPR,
    uint256 newAPR,
    uint256 minImprovement
  ) internal pure {
    require(
      newAPR.sub(currentAPR, "!increased").toFractionE18(currentAPR) >= minImprovement,
      "insufficient improvement"
    );
  }

  function validateProposedWeights(
    uint256[] memory currentWeights,
    uint256[] memory proposedWeights
  ) internal pure {
    uint256 len = currentWeights.length;
    require(proposedWeights.length == len, "bad lengths");
    uint256 _sum;
    for (uint256 i; i < len; i++) {
      uint256 weight = proposedWeights[i];
      _sum = _sum.add(weight);
      if (weight == 0) {
        require(currentWeights[i] == 0, "can not set null weight");
      } else {
        require(weight >= 5e16, "weight < 5%");
      }
    }
    require(_sum == 1e18, "weights != 100%");
  }

  function validateAdaptersAndWeights(
    IAdapterRegistry registry,
    address underlying,
    IErc20Adapter[] memory adapters,
    uint256[] memory weights
  ) internal view {
    uint256 len = adapters.length;
    require(weights.length == len, "bad lengths");
    uint256 totalWeight;
    for (uint256 i; i < len; i++) {
      IErc20Adapter adapter = adapters[i];
      require(registry.isApprovedAdapter(address(adapter)), "!approved");
      require(adapter.underlying() == underlying, "bad adapter");
      for (uint256 j = i + 1; j < len; j++) {
        require(address(adapter) != address(adapters[j]), "duplicate adapter");
      }
      uint256 weight = weights[i];
      totalWeight = totalWeight.add(weight);
      require(weight >= 5e16, "weight < 5%");
    }
    require(totalWeight == 1e18, "weights != 100%");
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/SafeCast.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash b83fcf497e895ae59b97c9d04e997023f69b5e97.

Subject to the GPL-2.0 license
*************************************************************************************************/


/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a uint256 to a uint128, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint128
  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  /// @notice Cast a uint256 to a uint96, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint96
  function toUint96(uint256 y) internal pure returns (uint96 z) {
    require((z = uint96(y)) == y);
  }

  /// @notice Cast a int256 to a int128, revert on overflow or underflow
  /// @param y The int256 to be downcasted
  /// @return z The downcasted integer, now type int128
  function toInt128(int256 y) internal pure returns (int128 z) {
    require((z = int128(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = int256(y);
  }

  /// @notice Cast an int256 to a uint256, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint256(int256 y) internal pure returns (uint256 z) {
    require(y >= 0);
    z = uint256(y);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../interfaces/IERC20Metadata.sol";


library SymbolHelper {

  /**
   * @dev Returns the index of the lowest bit set in `self`.
   * Note: Requires that `self != 0`
   */
  function lowestBitSet(uint256 self) internal pure returns (uint256 _z) {
    require (self > 0, "Bits::lowestBitSet: Value 0 has no bits set");
    uint256 _magic = 0x00818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    uint256 val = (self & -self) * _magic >> 248;
    uint256 _y = val >> 5;
    _z = (
      _y < 4
        ? _y < 2
          ? _y == 0
            ? 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            : 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
          : _y == 2
            ? 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            : 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
        : _y < 6
          ? _y == 4
            ? 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            : 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
          : _y == 6
            ? 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            : 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
    );
    _z >>= (val & 0x1f) << 3;
    return _z & 0xff;
  }

  function getSymbol(address token) internal view returns (string memory) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
    if (!success) return "UNKNOWN";
    if (data.length != 32) return abi.decode(data, (string));
    uint256 symbol = abi.decode(data, (uint256));
    if (symbol == 0) return "UNKNOWN";
    uint256 emptyBits = 255 - lowestBitSet(symbol);
    uint256 size = (emptyBits / 8) + (emptyBits % 8 > 0 ? 1 : 0);
    assembly { mstore(data, size) }
    return string(data);
  }

  function getName(address token) internal view returns (string memory) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("name()"));
    if (!success) return "UNKNOWN";
    if (data.length != 32) return abi.decode(data, (string));
    uint256 symbol = abi.decode(data, (uint256));
    if (symbol == 0) return "UNKNOWN";
    uint256 emptyBits = 255 - lowestBitSet(symbol);
    uint256 size = (emptyBits / 8) + (emptyBits % 8 > 0 ? 1 : 0);
    assembly { mstore(data, size) }
    return string(data);
  }

  function getPrefixedSymbol(string memory prefix, address token) internal view returns (string memory prefixedSymbol) {
    prefixedSymbol = string(abi.encodePacked(
      prefix,
      getSymbol(token)
    ));
  }

  function getPrefixedName(string memory prefix, address token) internal view returns (string memory prefixedName) {
    prefixedName = string(abi.encodePacked(
      prefix,
      getName(token)
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash cfedb1f55864dcf8cc0831fdd8ec18eb045b7fd1.

Subject to the MIT license
*************************************************************************************************/


library TransferHelper {
  function safeApproveMax(address token, address to) internal {
    safeApprove(token, to, type(uint256).max);
  }

  function safeUnapprove(address token, address to) internal {
    safeApprove(token, to, 0);
  }

  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:SA");
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:ST");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:STF");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}("");
    require(success, "TH:STE");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../libraries/LowGasSafeMath.sol";
import "../interfaces/IERC20.sol";


contract ERC20 is IERC20 {
  using LowGasSafeMath for uint256;

  mapping(address => uint256) public override balanceOf;

  mapping(address => mapping(address => uint256)) public override allowance;

  uint256 public override totalSupply;

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      allowance[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
    _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
    _approve(
      msg.sender,
      spender,
      allowance[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    balanceOf[sender] = balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    balanceOf[recipient] = balanceOf[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    totalSupply = totalSupply.add(amount);
    balanceOf[account] = balanceOf[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    balanceOf[account] = balanceOf[account].sub(amount, "ERC20: burn amount exceeds balance");
    totalSupply = totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    allowance[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(
      account,
      msg.sender,
      allowance[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance")
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/RebalanceValidation.sol";
import "../libraries/SafeCast.sol";
import "./NirnVaultBase.sol";


contract NirnVault is NirnVaultBase {
  using Fraction for uint256;
  using TransferHelper for address;
  using LowGasSafeMath for uint256;
  using MinimalSignedMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ArrayHelper for uint256[];
  using ArrayHelper for bytes32[];
  using ArrayHelper for IErc20Adapter[];
  using DynamicArrays for uint256[];
  using AdapterHelper for IErc20Adapter[];

/* ========== Constructor ========== */

  constructor(
    address _registry,
    address _eoaSafeCaller
  ) NirnVaultBase(_registry, _eoaSafeCaller) {}

/* ========== Status Queries ========== */

  function getCurrentLiquidityDeltas() external view override returns (int256[] memory liquidityDeltas) {
    (IErc20Adapter[] memory adapters, uint256[] memory weights) = getAdaptersAndWeights();
    BalanceSheet memory balanceSheet = getBalanceSheet(adapters);
    liquidityDeltas = AdapterHelper.getLiquidityDeltas(
      balanceSheet.totalProductiveBalance,
      balanceSheet.balances,
      weights
    );
  }

  function getAPR() external view override returns (uint256) {
    (DistributionParameters memory params,,) = currentDistribution();
    return params.netAPR;
  }

/* ========== Deposit/Withdraw ========== */

  function deposit(uint256 amount) external override returns (uint256 shares) {
    shares = depositTo(amount, msg.sender);
  }

  function depositTo(uint256 amount, address to) public override returns (uint256 shares) {
    uint256 bal = balance();
    uint256 max = maximumUnderlying;
    if (max > 0) {
      require(bal.add(amount) <= max, "maximumUnderlying");
    }
    underlying.safeTransferFrom(msg.sender, address(this), amount);
    uint256 supply = claimFees(bal, totalSupply);
    shares = supply == 0 ? amount : amount.mul(supply) / bal;
    _mint(to, shares);
    emit Deposit(shares, amount);
  }

  function withdraw(uint256 shares) external override returns (uint256 amountOut) {
    (IErc20Adapter[] memory adapters, uint256[] memory weights) = getAdaptersAndWeights();
    BalanceSheet memory balanceSheet = getBalanceSheet(adapters);
    uint256 supply = claimFees(balanceSheet.totalBalance, totalSupply);
    amountOut = shares.mul(balanceSheet.totalBalance) / supply;
    withdrawInternal(
      shares,
      amountOut,
      adapters,
      weights,
      balanceSheet
    );
  }

  function withdrawUnderlying(uint256 amount) external override returns (uint256 shares) {
    (IErc20Adapter[] memory adapters, uint256[] memory weights) = getAdaptersAndWeights();
    BalanceSheet memory balanceSheet = getBalanceSheet(adapters);
    uint256 supply = claimFees(balanceSheet.totalBalance, totalSupply);
    shares = amount.mul(supply) / balanceSheet.totalBalance;
    withdrawInternal(
      shares,
      amount,
      adapters,
      weights,
      balanceSheet
    );
  }

  function withdrawInternal(
    uint256 shares,
    uint256 amountOut,
    IErc20Adapter[] memory adapters,
    uint256[] memory weights,
    BalanceSheet memory balanceSheet
  ) internal {
    _burn(msg.sender, shares);
    emit Withdrawal(shares, amountOut);
    uint256 newReserves = balanceSheet.totalBalance.sub(amountOut).mulFractionE18(reserveRatio);
    withdrawToMatchAmount(
      adapters,
      weights,
      balanceSheet.balances,
      balanceSheet.reserveBalance,
      amountOut,
      newReserves
    );
    _transferOut(msg.sender, amountOut);
  }

  function withdrawToMatchAmount(
    IErc20Adapter[] memory adapters,
    uint256[] memory weights,
    uint256[] memory balances,
    uint256 _reserveBalance,
    uint256 amount,
    uint256 newReserves
  ) internal {
    if (amount > _reserveBalance) {
      uint256 remainder = amount.sub(_reserveBalance);
      uint256 len = balances.length;
      uint256[] memory removeIndices = DynamicArrays.dynamicUint256Array(len);
      for (uint256 i; i < len; i++) {
        uint256 bal = balances[i];
        if (bal == 0) continue;
        // If the balance is sufficient to withdraw both the remainder and the new reserves,
        // withdraw the remainder and the new reserves. Otherwise, withdraw the balance.
        uint256 optimalWithdrawal = remainder.add(newReserves);
        uint256 amountToWithdraw = bal > optimalWithdrawal
          ? optimalWithdrawal
          : bal;
        uint256 amountWithdrawn = adapters[i].withdrawUnderlyingUpTo(amountToWithdraw);
        remainder = remainder >= amountWithdrawn ? remainder - amountWithdrawn : 0;
        if (weights[i] == 0 && amountWithdrawn == bal) {
          removeIndices.dynamicPush(i);
        }
        if (remainder == 0) break;
      }
      require(remainder == 0, "insufficient available balance");
      removeAdapters(removeIndices);
    }
  }

/* ========== Rebalance Actions ========== */

  function rebalance() external override onlyEOA {
    (IErc20Adapter[] memory adapters, uint256[] memory weights) = getAdaptersAndWeights();
    BalanceSheet memory balanceSheet = getBalanceSheet(adapters);
    int256[] memory liquidityDeltas = AdapterHelper.getLiquidityDeltas(balanceSheet.totalProductiveBalance, balanceSheet.balances, weights);
    uint256[] memory removedIndices = AdapterHelper.rebalance(
      adapters,
      weights,
      liquidityDeltas,
      balanceSheet.reserveBalance
    );
    removeAdapters(removedIndices);
    emit Rebalanced();
  }

  function rebalanceWithNewWeights(uint256[] memory proposedWeights) external override onlyEOA changesComposition {
    (
      DistributionParameters memory params,
      uint256 totalProductiveBalance,
      uint256 _reserveBalance
    ) = currentDistribution();
    RebalanceValidation.validateProposedWeights(params.weights, proposedWeights);
    // Get liquidity deltas and APR for new weights
    int256[] memory proposedLiquidityDeltas = AdapterHelper.getLiquidityDeltas(totalProductiveBalance, params.balances, proposedWeights);
    uint256 proposedAPR = AdapterHelper.getNetAPR(params.adapters, proposedWeights, proposedLiquidityDeltas).mulSubFractionE18(reserveRatio);
    // Validate rebalance results in sufficient APR improvement
    RebalanceValidation.validateSufficientImprovement(params.netAPR, proposedAPR, minimumAPRImprovement);
    // Rebalance and remove adapters with 0 weight which the vault could fully exit.
    uint256[] memory removedIndices = AdapterHelper.rebalance(params.adapters, proposedWeights, proposedLiquidityDeltas, _reserveBalance);
    uint256 removeLen = removedIndices.length;
    if (removeLen > 0) {
      for (uint256 i = removeLen; i > 0; i--) {
        uint256 rI = removedIndices[i-1];
        emit AdapterRemoved(params.adapters[rI]);
        params.adapters.mremove(rI);
        proposedWeights.mremove(rI);
      }
    }
    setAdaptersAndWeights(params.adapters, proposedWeights);
  }

  function currentDistribution() public view override returns (
    DistributionParameters memory params,
    uint256 totalProductiveBalance,
    uint256 _reserveBalance
  ) {
    uint256 _reserveRatio = reserveRatio;
    (params.adapters, params.weights) = getAdaptersAndWeights();
    uint256 len = params.adapters.length;
    uint256 netAPR;
    params.balances = params.adapters.getBalances();
    _reserveBalance = reserveBalance();
    totalProductiveBalance = params.balances.sum().add(_reserveBalance).mulSubFractionE18(_reserveRatio);
    params.liquidityDeltas = new int256[](len);
    for (uint256 i; i < len; i++) {
      IErc20Adapter adapter = params.adapters[i];
      uint256 weight = params.weights[i];
      uint256 targetBalance = totalProductiveBalance.mulFractionE18(weight);
      int256 liquidityDelta = targetBalance.toInt256().sub(params.balances[i].toInt256());
      netAPR = netAPR.add(
        adapter.getHypotheticalAPR(liquidityDelta).mulFractionE18(weight)
      );
      params.liquidityDeltas[i] = liquidityDelta;
    }
    params.netAPR = netAPR.mulSubFractionE18(_reserveRatio);
  }

  function processProposedDistribution(
    DistributionParameters memory currentParams,
    uint256 totalProductiveBalance,
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) internal view returns (DistributionParameters memory params) {
    uint256[] memory excludedAdapterIndices = currentParams.adapters.getExcludedAdapterIndices(proposedAdapters);
    uint256 proposedSize = proposedAdapters.length;
    uint256 expandedSize = proposedAdapters.length + excludedAdapterIndices.length;
    params.adapters = new IErc20Adapter[](expandedSize);
    params.weights = new uint256[](expandedSize);
    params.balances = new uint256[](expandedSize);
    params.liquidityDeltas = new int256[](expandedSize);
    uint256 i;
    uint256 netAPR;
    for (; i < proposedSize; i++) {
      IErc20Adapter adapter = proposedAdapters[i];
      params.adapters[i] = adapter;
      uint256 weight = proposedWeights[i];
      params.weights[i] = weight;
      uint256 targetBalance = totalProductiveBalance.mulFractionE18(weight);
      uint256 _balance = adapter.balanceUnderlying();
      params.balances[i] = _balance;
      int256 liquidityDelta = targetBalance.toInt256().sub(_balance.toInt256());
      netAPR = netAPR.add(
        adapter.getHypotheticalAPR(liquidityDelta).mulFractionE18(weight)
      );
      params.liquidityDeltas[i] = liquidityDelta;
    }
    netAPR = netAPR.mulSubFractionE18(reserveRatio);
    RebalanceValidation.validateSufficientImprovement(currentParams.netAPR, netAPR, minimumAPRImprovement);
    for (; i < expandedSize; i++) {
      // i - proposedSize = index in excluded adapter indices array
      // The value in excludedAdapterIndices is the index in the current adapters array
      // for the adapter which is being removed.
      // The lending markets for these adapters may or may not have sufficient liquidity to
      // process a full withdrawal requested by the vault, so we keep those adapters in the
      // adapters list, but set a weight of 0 and a liquidity delta of -balance
      uint256 rI = excludedAdapterIndices[i - proposedSize];
      params.adapters[i] = currentParams.adapters[rI];
      params.weights[i] = 0;
      uint256 _balance = currentParams.balances[rI];
      params.balances[i] = _balance;
      params.liquidityDeltas[i] = -_balance.toInt256();
    }
  }

  function rebalanceWithNewAdapters(
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) external override onlyEOA changesComposition {
    RebalanceValidation.validateAdaptersAndWeights(registry, underlying, proposedAdapters, proposedWeights);
    (
      DistributionParameters memory currentParams,
      uint256 totalProductiveBalance,
      uint256 _reserveBalance
    ) = currentDistribution();
    DistributionParameters memory proposedParams = processProposedDistribution(
      currentParams,
      totalProductiveBalance,
      proposedAdapters,
      proposedWeights
    );
    beforeAddAdapters(proposedParams.adapters);
    uint256[] memory removedIndices = AdapterHelper.rebalance(
      proposedParams.adapters,
      proposedParams.weights,
      proposedParams.liquidityDeltas,
      _reserveBalance
    );
    uint256 removedLen = removedIndices.length;
    if (removedLen > 0) {
      // The indices to remove are necessarily in ascending order, so as long as we remove
      // them in reverse, the removal of elements will not break the other indices.
      for (uint256 i = removedLen; i > 0; i--) {
        uint256 rI = removedIndices[i-1];
        emit AdapterRemoved(proposedParams.adapters[rI]);
        proposedParams.adapters.mremove(rI);
        proposedParams.weights.mremove(rI);
      }
    }
    setAdaptersAndWeights(proposedParams.adapters, proposedParams.weights);
  }

  function _transferOut(address to, uint256 amount) internal {
    underlying.safeTransfer(to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "../OwnableProxyImplementation.sol";
import "../interfaces/IAdapterRegistry.sol";
import "../interfaces/IRewardsSeller.sol";
import "../interfaces/INirnVault.sol";
import "../libraries/LowGasSafeMath.sol";
import "../libraries/SymbolHelper.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/AdapterHelper.sol";
import "./ERC20.sol";


/**
 * @dev Base contract defining the constant and storage variables
 * for NirnVault, as well as basic state queries and setters.
 */
abstract contract NirnVaultBase is ERC20, OwnableProxyImplementation(), INirnVault {
  using SafeCast for uint256;
  using TransferHelper for address;
  using Fraction for uint256;
  using LowGasSafeMath for uint256;
  using MinimalSignedMath for uint256;
  using MinimalSignedMath for int256;
  using ArrayHelper for uint256[];
  using ArrayHelper for address[];
  using ArrayHelper for bytes32[];
  using ArrayHelper for IErc20Adapter[];
  using AdapterHelper for bytes32;
  using AdapterHelper for bytes32[];
  using AdapterHelper for IErc20Adapter[];

/* ========== Constants ========== */

  /**
  * @dev Fraction of the current APR of the vault that a proposed rebalance must improve
  * the net APR by to be accepted, as a fraction of 1e18.
  * 5e16 means newAPR-currentAPR must be greater than or equal to currentAPR*1.05
  */
  uint256 public constant override minimumAPRImprovement = 5e16;

  uint256 public constant override minimumCompositionChangeDelay = 1 hours;

  /** @dev Nirn adapter registry */
  IAdapterRegistry public immutable override registry;

  /** @dev Address of a contract which can only execute specific functions and only allows EOAs to call. */
  address public immutable override eoaSafeCaller;

/* ========== Storage ========== */

  /** @dev Underlying asset for the vault. */
  address public override underlying;

  /** @dev Time at which a changing rebalance can be executed. */
  uint96 public override canChangeCompositionAfter;

  /** @dev ERC20 name */
  string public override name;

  /** @dev ERC20 symbol */
  string public override symbol;

  /** @dev Tokens which can not be sold - wrapper tokens used by the adapters. */
  mapping(address => bool) public override lockedTokens;

  /** @dev Account that receives performance fees. */
  address public override feeRecipient;

  /** @dev Address of contract used to sell rewards. */
  IRewardsSeller public override rewardsSeller;

  /**
   * @dev Maximum underlying balance that can be deposited.
   * If zero, no maximum.
   */
  uint256 public override maximumUnderlying;

  /** @dev Fee taken on profit as a fraction of 1e18. */
  uint64 public override performanceFee;

  /** @dev Ratio of underlying token to keep in the vault for cheap withdrawals as a fraction of 1e18. */
  uint64 public override reserveRatio;

  /** @dev Last price at which fees were taken. */
  uint128 public override priceAtLastFee;

  /** @dev Tightly packed token adapters encoded as (address,uint96). */
  bytes32[] internal packedAdaptersAndWeights;

  function getAdaptersAndWeights() public view override returns (
    IErc20Adapter[] memory adapters,
    uint256[] memory weights
  ) {
    (adapters, weights) = packedAdaptersAndWeights.unpackAdaptersAndWeights();
  }

  function setAdaptersAndWeights(IErc20Adapter[] memory adapters, uint256[] memory weights) internal {
    emit AllocationsUpdated(adapters, weights);
    packedAdaptersAndWeights = AdapterHelper.packAdaptersAndWeights(
      adapters,
      weights
    );
  }

  function removeAdapters(uint256[] memory removeIndices) internal {
    uint256 len = removeIndices.length;
    if (len == 0) return;
    for (uint256 i = len; i > 0; i--) {
      uint256 rI = removeIndices[i - 1];
      (IErc20Adapter adapter,) = packedAdaptersAndWeights[rI].unpackAdapterAndWeight();
      emit AdapterRemoved(adapter);
      packedAdaptersAndWeights.remove(rI);
    }
  }

/* ========== Modifiers ========== */

  /**
   * @dev Prevents calls from arbitrary contracts.
   * Caller must be an EOA account or a pre-approved "EOA-safe" caller,
   * meaning a smart contract which can only be called by an EOA and has
   * a limited set of functions it can call.
   * This prevents griefing via flash loans that force the vault to use
   * adapters with low interest rates.
   */
  modifier onlyEOA {
    require(msg.sender == tx.origin || msg.sender == eoaSafeCaller, "!EOA");
    _;
  }

  /**
   * @dev Prevents composition-changing rebalances from being executed more
   * frequently than the configured minimum delay;
   */
  modifier changesComposition {
    require(block.timestamp >= canChangeCompositionAfter, "too soon");
    canChangeCompositionAfter = block.timestamp.add(minimumCompositionChangeDelay).toUint96();
    _;
  }

/* ========== Constructor ========== */

  constructor(address _registry, address _eoaSafeCaller) {
    registry = IAdapterRegistry(_registry);
    eoaSafeCaller = _eoaSafeCaller;
  }

  function initialize(
    address _underlying,
    address _rewardsSeller,
    address _feeRecipient,
    address _owner
  ) external override initializer(_owner) {
    require(_feeRecipient != address(0), "null address");
    underlying = _underlying;
    feeRecipient = _feeRecipient;
    rewardsSeller = IRewardsSeller(_rewardsSeller);

    (address adapter,) = registry.getAdapterWithHighestAPR(_underlying);
    packedAdaptersAndWeights.push(AdapterHelper.packAdapterAndWeight(IErc20Adapter(adapter), 1e18));
    beforeAddAdapter(IErc20Adapter(adapter));

    name = SymbolHelper.getPrefixedName("Indexed ", _underlying);
    symbol = SymbolHelper.getPrefixedSymbol("n", _underlying);
    performanceFee = 1e17;
    reserveRatio = 1e17;
    priceAtLastFee = 1e18;
  }

/* ========== Configuration Controls ========== */

  function setMaximumUnderlying(uint256 _maximumUnderlying) external override onlyOwner {
    maximumUnderlying = _maximumUnderlying;
    emit SetMaximumUnderlying(_maximumUnderlying);
  }

  function setPerformanceFee(uint64 _performanceFee) external override onlyOwner {
    claimFees(balance(), totalSupply);
    require(_performanceFee <= 2e17, "fee > 20%");
    performanceFee = _performanceFee;
    emit SetPerformanceFee(_performanceFee);
  }

  function setReserveRatio(uint64 _reserveRatio) external override onlyOwner {
    require(_reserveRatio <= 2e17, "reserve > 20%");
    reserveRatio = _reserveRatio;
    emit SetReserveRatio(_reserveRatio);
  }

  function setFeeRecipient(address _feeRecipient) external override onlyOwner {
    require(_feeRecipient != address(0), "null address");
    feeRecipient = _feeRecipient;
    emit SetFeeRecipient(_feeRecipient);
  }

  function setRewardsSeller(IRewardsSeller _rewardsSeller) external override onlyOwner {
    rewardsSeller = _rewardsSeller;
    emit SetRewardsSeller(address(_rewardsSeller));
  }

/* ========== Reward Token Sale ========== */

  function sellRewards(address rewardsToken, bytes calldata params) external override onlyEOA {
    uint256 _balance = IERC20(rewardsToken).balanceOf(address(this));
    require(!lockedTokens[rewardsToken] && rewardsToken != underlying, "token locked");
    IRewardsSeller _rewardsSeller = rewardsSeller;
    require(address(_rewardsSeller) != address(0), "null seller");
    rewardsToken.safeTransfer(address(_rewardsSeller), _balance);
    _rewardsSeller.sellRewards(msg.sender, rewardsToken, underlying, params);
  }

  function withdrawFromUnusedAdapter(IErc20Adapter adapter) external {
    (IErc20Adapter[] memory adapters,) = getAdaptersAndWeights();
    require(
      !adapters.toAddressArray().includes(address(adapter)),
      "!unused"
    );
    require(registry.isApprovedAdapter(address(adapter)), "!approved");
    address wrapper = adapter.token();
    wrapper.safeApproveMax(address(adapter));
    uint256 bal = adapter.balanceUnderlying();
    adapter.withdrawUnderlyingUpTo(bal);
    wrapper.safeUnapprove(address(adapter));
  }

/* ========== Underlying Balance Queries ========== */

  struct BalanceSheet {
    uint256[] balances;
    uint256 reserveBalance;
    uint256 totalBalance;
    uint256 totalProductiveBalance;
  }

  function getBalanceSheet(
    IErc20Adapter[] memory adapters
  ) internal view returns (BalanceSheet memory sheet) {
    sheet.balances = adapters.getBalances();
    sheet.reserveBalance = reserveBalance();
    sheet.totalBalance = sheet.balances.sum().add(sheet.reserveBalance);
    sheet.totalProductiveBalance = sheet.totalBalance.mulSubFractionE18(reserveRatio);
  }

  /**
   * @dev Returns the value in `underlying` of the vault's deposits
   * in each adapter.
   */
  function getBalances() public view override returns (uint256[] memory balances) {
    (IErc20Adapter[] memory adapters,) = getAdaptersAndWeights();
    return adapters.getBalances();
  }

  /**
   * @dev Returns total value of vault in `underlying`
   */
  function balance() public view override returns (uint256 sum) {
    (IErc20Adapter[] memory adapters,) = getAdaptersAndWeights();
    uint256 len = adapters.length;
    for (uint256 i; i < len; i++) {
      sum = sum.add(adapters[i].balanceUnderlying());
    }
    sum = sum.add(reserveBalance());
  }

  /**
   * @dev Returns current "reserve" balance, or balance of `underlying` held by the vault
   */
  function reserveBalance() public view override returns (uint256) {
    return IERC20(underlying).balanceOf(address(this));
  }

/* ========== Fees ========== */

  function calculateFee(uint256 totalBalance, uint256 supply) internal view returns (uint256) {
    uint256 valueAtLastCollectionPrice = supply.mulFractionE18(priceAtLastFee);
    if (totalBalance <= valueAtLastCollectionPrice) return 0;
    uint256 profit = totalBalance.sub(valueAtLastCollectionPrice);
    return profit.mulFractionE18(performanceFee);
  }

  function getPendingFees() external view override returns (uint256) {
    return calculateFee(balance(), totalSupply);
  }

  function claimFees(uint256 totalBalance, uint256 supply) internal returns (uint256 newSupply) {
    uint256 totalFees = calculateFee(totalBalance, supply);
    if (totalFees == 0) return supply;
    uint256 equivalentShares = totalFees.mul(supply) / totalBalance.sub(totalFees);
    emit FeesClaimed(totalFees, equivalentShares);
    _mint(feeRecipient, equivalentShares);
    newSupply = supply.add(equivalentShares);
    priceAtLastFee = totalBalance.toFractionE18(newSupply).toUint128();
  }

  function claimFees() external {
    claimFees(balance(), totalSupply);
  }

/* ========== Price Queries ========== */

  function getPricePerFullShare() external view override returns (uint256) {
    return balance().toFractionE18(totalSupply);
  }

  function getPricePerFullShareWithFee() public view override returns (uint256) {
    uint256 totalBalance = balance();
    uint256 supply = totalSupply;
    uint256 pendingFees = calculateFee(totalBalance, supply);
    if (pendingFees > 0) {
      uint256 equivalentShares = pendingFees.mul(supply) / totalBalance.sub(pendingFees);
      supply = supply.add(equivalentShares);
    }
    return totalBalance.toFractionE18(supply);
  }

/* ========== Update Hooks ========== */

  function beforeAddAdapter(IErc20Adapter adapter) internal {
    address wrapper = adapter.token();
    if (IERC20(wrapper).allowance(address(this), address(adapter)) > 0) return;
    lockedTokens[wrapper] = true;
    underlying.safeApproveMax(address(adapter));
    wrapper.safeApproveMax(address(adapter));
  }

  function beforeAddAdapters(IErc20Adapter[] memory adapters) internal {
    uint256 len = adapters.length;
    for (uint256 i; i < len; i++) beforeAddAdapter(adapters[i]);
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}