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


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/ITokenAdapter.sol";
import "./interfaces/IProtocolAdapter.sol";
import "./interfaces/IAdapterRegistry.sol";
import "./interfaces/INirnVault.sol";
import "./libraries/ArrayHelper.sol";
import "./libraries/DynamicArrays.sol";


contract AdapterRegistry is Ownable(), IAdapterRegistry {
  using ArrayHelper for address[];
  using ArrayHelper for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.AddressSet;
  using DynamicArrays for address[];
  using DynamicArrays for uint256[];

/* ========== Storage ========== */

  /** @dev Mapping from underlying token to registered vault. */
  mapping(address => address) public override vaultsByUnderlying;

  /** @dev Accounts allowed to register vaults. */
  mapping(address => bool) public override approvedVaultFactories;

  /** @dev List of all registered vaults. */
  EnumerableSet.AddressSet internal vaults;

  /** @dev Number of protocol adapters registered. */
  uint256 public override protocolsCount;

  /** @dev Mapping from protocol IDs to adapter addresses. */
  mapping(uint256 => address) public override protocolAdapters;

  /** @dev Mapping from protocol adapter addresses to protocol IDs. */
  mapping(address => uint256) public override protocolAdapterIds;

  /** @dev Mapping from underlying tokens to lists of adapters. */
  mapping(address => address[]) internal tokenAdapters;

  /** @dev Mapping from wrapper tokens to adapters. */
  mapping(address => TokenAdapter) internal adaptersByWrapperToken;

  /** @dev List of all underlying tokens with registered adapters. */
  EnumerableSet.AddressSet internal supportedTokens;

/* ========== Modifiers ========== */

  modifier onlyProtocolOrOwner {
    require(protocolAdapterIds[msg.sender] > 0 || msg.sender == owner(), "!approved");
    _;
  }

  function getProtocolAdapterId(address protocolAdapter) internal view returns (uint256 id) {
    require((id = protocolAdapterIds[protocolAdapter]) > 0, "!exists");
  }

/* ========== Vault Factory Management ========== */

  function addVaultFactory(address _factory) external override onlyOwner {
    require(_factory != address(0), "null address");
    require(!approvedVaultFactories[_factory], "already approved");
    approvedVaultFactories[_factory] = true;
    emit VaultFactoryAdded(_factory);
  }

  function removeVaultFactory(address _factory) external override onlyOwner {
    require(approvedVaultFactories[_factory], "!approved");
    approvedVaultFactories[_factory] = false;
    emit VaultFactoryRemoved(_factory);
  }

/* ========== Vault Management ========== */

  function addVault(address vault) external override {
    require(approvedVaultFactories[msg.sender], "!approved");
    address underlying = INirnVault(vault).underlying();
    require(vaultsByUnderlying[underlying] == address(0), "exists");
    vaultsByUnderlying[underlying] = vault;
    vaults.add(vault);
    emit VaultAdded(underlying, vault);
  }

  function removeVault(address vault) external override onlyOwner {
    address underlying = INirnVault(vault).underlying();
    require(vaultsByUnderlying[underlying] != address(0), "!exists");
    vaultsByUnderlying[underlying] = address(0);
    vaults.remove(vault);
    emit VaultRemoved(underlying, vault);
  }

/* ========== Protocol Adapter Management ========== */

  function addProtocolAdapter(address protocolAdapter) external override onlyProtocolOrOwner returns (uint256 id) {
    require(protocolAdapter != address(0), "null");
    require(protocolAdapterIds[protocolAdapter] == 0, "exists");
    id = ++protocolsCount;
    protocolAdapterIds[protocolAdapter] = id;
    protocolAdapters[id] = protocolAdapter;
    emit ProtocolAdapterAdded(id, protocolAdapter);
  }

  function removeProtocolAdapter(address protocolAdapter) external override onlyOwner {
    uint256 id = getProtocolAdapterId(protocolAdapter);
    delete protocolAdapterIds[protocolAdapter];
    delete protocolAdapters[id];
    emit ProtocolAdapterRemoved(id);
  }

/* ========== Token Adapter Management ========== */

  function _addTokenAdapter(IErc20Adapter adapter, uint256 id) internal {
    address underlying = adapter.underlying();
    address wrapper = adapter.token();
    require(adaptersByWrapperToken[wrapper].protocolId == 0, "adapter exists");
    if (tokenAdapters[underlying].length == 0) {
      supportedTokens.add(underlying);
      emit TokenSupportAdded(underlying);
    }
    tokenAdapters[underlying].push(address(adapter));
    adaptersByWrapperToken[wrapper] = TokenAdapter(address(adapter), uint96(id));
    emit TokenAdapterAdded(address(adapter), id, underlying, wrapper);
  }

  function addTokenAdapter(address adapter) external override {
    uint256 id = getProtocolAdapterId(msg.sender);
    _addTokenAdapter(IErc20Adapter(adapter), id);
  }

  function addTokenAdapters(address[] calldata adapters) external override {
    uint256 id = getProtocolAdapterId(msg.sender);
    uint256 len = adapters.length;
    for (uint256 i = 0; i < len; i++) {
      IErc20Adapter adapter = IErc20Adapter(adapters[i]);
      _addTokenAdapter(adapter, id);
    }
  }

  function removeTokenAdapter(address adapter) external override {
    address wrapper = IErc20Adapter(adapter).token();
    TokenAdapter memory adapterRecord = adaptersByWrapperToken[wrapper];
    require(adapterRecord.adapter == address(adapter), "wrong adapter");
    uint256 protocolId = adapterRecord.protocolId;
    require(
      msg.sender == owner() ||
      msg.sender == protocolAdapters[protocolId],
      "!authorized"
    );
    delete adaptersByWrapperToken[wrapper];
    address underlying = IErc20Adapter(adapter).underlying();
    address[] storage adapters = tokenAdapters[underlying];
    uint256 index = adapters.indexOf(address(adapter));
    adapters.remove(index);
    if (adapters.length == 0) {
      supportedTokens.remove(underlying);
      emit TokenSupportRemoved(underlying);
    }
    emit TokenAdapterRemoved(address(adapter), protocolId, underlying, wrapper);
  }

/* ========== Vault Queries ========== */

  function getVaultsList() external view override returns (address[] memory) {
    return vaults.toArray();
  }

  function haveVaultFor(address underlying) external view override returns (bool) {
    return vaultsByUnderlying[underlying] != address(0);
  }

/* ========== Protocol Queries ========== */

  function getProtocolAdaptersAndIds() external view override returns (address[] memory adapters, uint256[] memory ids) {
    uint256 len = protocolsCount;
    adapters = DynamicArrays.dynamicAddressArray(len);
    ids = DynamicArrays.dynamicUint256Array(len);
    for (uint256 id = 1; id <= len; id++) {
      address adapter = protocolAdapters[id];
      if (adapter != address(0)) {
        adapters.dynamicPush(adapter);
        ids.dynamicPush(id);
      }
    }
  }

  function getProtocolMetadata(uint256 id) external view override returns (address protocolAdapter, string memory name) {
    protocolAdapter = protocolAdapters[id];
    require(protocolAdapter != address(0), "invalid id");
    name = IProtocolAdapter(protocolAdapter).protocol();
  }

  function getProtocolForTokenAdapter(address adapter) external view override returns (address protocolAdapter) {
    address wrapper = IErc20Adapter(adapter).token();
    TokenAdapter memory adapterRecord = adaptersByWrapperToken[wrapper];
    require(adapterRecord.adapter == adapter, "!approved");
    protocolAdapter = protocolAdapters[adapterRecord.protocolId];
  }

/* ========== Supported Token Queries ========== */

  function isSupported(address underlying) external view override returns (bool) {
    return tokenAdapters[underlying].length > 0;
  }

  function getSupportedTokens() external view override returns (address[] memory list) {
    list = supportedTokens.toArray();
  }

/* ========== Token Adapter Queries ========== */

  function isApprovedAdapter(address adapter) external view override returns (bool) {
    address wrapper = IErc20Adapter(adapter).token();
    TokenAdapter memory adapterRecord = adaptersByWrapperToken[wrapper];
    return adapterRecord.adapter == adapter;
  }

  function getAdaptersList(address underlying) public view override returns (address[] memory list) {
    list = tokenAdapters[underlying];
  }

  function getAdapterForWrapperToken(address wrapperToken) external view override returns (address) {
    return adaptersByWrapperToken[wrapperToken].adapter;
  }

  function getAdaptersCount(address underlying) external view override returns (uint256) {
    return tokenAdapters[underlying].length;
  }

  function getAdaptersSortedByAPR(address underlying)
    public
    view
    override
    returns (address[] memory adapters, uint256[] memory aprs)
  {
    adapters = getAdaptersList(underlying);
    uint256 len = adapters.length;
    aprs = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      try IErc20Adapter(adapters[i]).getAPR() returns (uint256 apr) {
        aprs[i] = apr;
      } catch {
        aprs[i] = 0;
      }
    }
    adapters.sortByDescendingScore(aprs);
  }

  function getAdaptersSortedByAPRWithDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  )
    public
    view
    override
    returns (address[] memory adapters, uint256[] memory aprs)
  {
    adapters = getAdaptersList(underlying);
    uint256 len = adapters.length;
    aprs = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      address adapter = adapters[i];
      if (adapter == excludingAdapter) {
        try IErc20Adapter(adapter).getAPR() returns (uint256 apr) {
          aprs[i] = apr;
        } catch {
          aprs[i] = 0;
        }
      } else {
        try IErc20Adapter(adapter).getHypotheticalAPR(int256(deposit)) returns (uint256 apr) {
          aprs[i] = apr;
        } catch {
          aprs[i] = 0;
        }
      }
    }
    adapters.sortByDescendingScore(aprs);
  }

  function getAdapterWithHighestAPR(address underlying) external view override returns (address adapter, uint256 apr) {
    (address[] memory adapters, uint256[] memory aprs) = getAdaptersSortedByAPR(underlying);
    adapter = adapters[0];
    apr = aprs[0];
  }

  function getAdapterWithHighestAPRForDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  ) external view override returns (address adapter, uint256 apr) {
    (address[] memory adapters, uint256[] memory aprs) = getAdaptersSortedByAPRWithDeposit(
      underlying,
      deposit,
      excludingAdapter
    );
    adapter = adapters[0];
    apr = aprs[0];
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
pragma solidity =0.7.6;

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

/* ========== Liquidity Delta Queries ========== */

  function getCurrentLiquidityDeltas() external view returns (int256[] memory liquidityDeltas);
  
  function getHypotheticalLiquidityDeltas(
    uint256[] calldata proposedWeights
  ) external view returns (int256[] memory liquidityDeltas);
  
  function getHypotheticalLiquidityDeltas(
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) external view returns (int256[] memory liquidityDeltas);

/* ========== APR Queries ========== */

  function getAPR() external view returns (uint256);

  function getAPRs() external view returns (uint256[] memory aprs);

  function getHypotheticalAPR(uint256[] memory proposedWeights) external view returns (uint256);

  function getHypotheticalAPR(
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) external view returns (uint256);

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
pragma solidity >=0.5.10;
import "./IAdapterRegistry.sol";


interface IProtocolAdapter {
  event MarketFrozen(address token);

  event MarketUnfrozen(address token);

  event AdapterFrozen(address adapter);

  event AdapterUnfrozen(address adapter);

  function registry() external view returns (IAdapterRegistry);

  function frozenAdapters(uint256 index) external view returns (address);

  function frozenTokens(uint256 index) external view returns (address);

  function totalMapped() external view returns (uint256);

  function protocol() external view returns (string memory);

  function getUnmapped() external view returns (address[] memory tokens);

  function getUnmappedUpTo(uint256 max) external view returns (address[] memory tokens);

  function map(uint256 max) external;

  function unfreezeAdapter(uint256 index) external;

  function unfreezeToken(uint256 index) external;

  function freezeAdapter(address adapter) external;
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