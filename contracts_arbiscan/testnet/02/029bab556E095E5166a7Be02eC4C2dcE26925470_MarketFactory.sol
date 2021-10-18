/**
 *Submitted for verification at arbiscan.io on 2021-10-18
*/

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol




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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// File: contracts/interface/IMarket.sol


interface IMarket {
	function authenticate(address _prop, string[] memory _args)
		external
		returns (bool);

	function authenticateFromPropertyFactory(
		address _prop,
		address _author,
		string[] memory _args
	) external returns (bool);

	function authenticatedCallback(address _property, bytes32 _idHash)
		external
		returns (address);

	function deauthenticate(address _metrics) external;

	function name() external view returns (string memory);

	function schema() external view returns (string memory);

	function behavior() external view returns (address);

	function issuedMetrics() external view returns (uint256);

	function enabled() external view returns (bool);

	function votingEndTimestamp() external view returns (uint256);

	function getAuthenticatedProperties()
		external
		view
		returns (address[] memory);

	function toEnable() external;
}

// File: contracts/interface/IMarketBehavior.sol


interface IMarketBehavior {
	function authenticate(
		address _prop,
		string[] memory _args,
		address account
	) external returns (bool);

	function setAssociatedMarket(address _market) external;

	function associatedMarket() external view returns (address);

	function name() external view returns (string memory);

	function schema() external view returns (string memory);

	function getId(address _metrics) external view returns (string memory);

	function getMetrics(string memory _id) external view returns (address);
}

// File: contracts/interface/IMarketFactory.sol


interface IMarketFactory {
	event Create(address indexed _market, address _from);

	function enableMarketList() external view returns (address[] memory);

	function marketsCount() external returns (uint256);

	function create(address _addr) external returns (address);

	function enable(address _addr) external;

	function isMarket(address _addr) external view returns (bool);

	function isPotentialMarket(address _addr) external view returns (bool);
}

// File: contracts/interface/IAddressRegistry.sol


interface IAddressRegistry {
	function setRegistry(string memory _key, address _addr) external;

	function registries(string memory _key) external view returns (address);
}

// File: contracts/src/common/registry/InitializableUsingRegistry.sol





/**
 * Module for using AddressRegistry contracts.
 */
abstract contract InitializableUsingRegistry is Initializable {
	address private _registry;

	/**
	 * Initialize the argument as AddressRegistry address.
	 */
	/* solhint-disable func-name-mixedcase */
	function __UsingRegistry_init(address _addressRegistry)
		internal
		initializer
	{
		_registry = _addressRegistry;
	}

	/**
	 * Returns the latest AddressRegistry instance.
	 */
	function registry() internal view returns (IAddressRegistry) {
		return IAddressRegistry(_registry);
	}

	/**
	 * Returns the AddressRegistry address.
	 */
	function registryAddress() external view returns (address) {
		return _registry;
	}
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


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

// File: contracts/interface/IProperty.sol


interface IProperty {
	event ChangeAuthor(address _old, address _new);
	event ChangeName(string _old, string _new);
	event ChangeSymbol(string _old, string _new);

	function author() external view returns (address);

	function changeAuthor(address _nextAuthor) external;

	function changeName(string memory _name) external;

	function changeSymbol(string memory _symbol) external;

	function withdraw(address _sender, uint256 _value) external;
}

// File: contracts/interface/IPolicy.sol


interface IPolicy {
	function rewards(uint256 _lockups, uint256 _assets)
		external
		view
		returns (uint256);

	function holdersShare(uint256 _amount, uint256 _lockups)
		external
		view
		returns (uint256);

	function authenticationFee(uint256 _assets, uint256 _propertyAssets)
		external
		view
		returns (uint256);

	function marketVotingSeconds() external view returns (uint256);

	function policyVotingSeconds() external view returns (uint256);

	function shareOfTreasury(uint256 _supply) external view returns (uint256);
}

// File: contracts/interface/IMetrics.sol


interface IMetrics {
	function market() external view returns (address);

	function property() external view returns (address);
}

// File: contracts/interface/IMetricsFactory.sol


interface IMetricsFactory {
	event Create(
		address indexed _market,
		address indexed _property,
		address _metrics
	);
	event Destroy(
		address indexed _market,
		address indexed _property,
		address _metrics
	);

	function create(address _property) external returns (address);

	function destroy(address _metrics) external;

	function isMetrics(address _addr) external view returns (bool);

	function metricsCount() external view returns (uint256);

	function metricsCountPerProperty(address _addr)
		external
		view
		returns (uint256);

	function metricsOfProperty(address _property)
		external
		view
		returns (address[] memory);

	function hasAssets(address _property) external view returns (bool);

	function authenticatedPropertiesCount() external view returns (uint256);
}

// File: contracts/interface/ILockup.sol


interface ILockup {
	struct RewardPrices {
		uint256 reward;
		uint256 holders;
		uint256 interest;
		uint256 holdersCap;
	}

	struct LockedupProperty {
		address property;
		uint256 value;
	}

	event Lockedup(
		address indexed _from,
		address indexed _property,
		uint256 _value,
		uint256 _tokenId
	);
	event Withdrew(
		address indexed _from,
		address indexed _property,
		uint256 _value,
		uint256 _reward,
		uint256 _tokenId
	);

	event UpdateCap(uint256 _cap);

	function depositToProperty(address _property, uint256 _amount)
		external
		returns (uint256);

	function depositToPosition(uint256 _tokenId, uint256 _amount)
		external
		returns (bool);

	function getLockedupProperties()
		external
		view
		returns (LockedupProperty[] memory);

	function update() external;

	function withdrawByPosition(uint256 _tokenId, uint256 _amount)
		external
		returns (bool);

	function calculateCumulativeRewardPrices()
		external
		view
		returns (
			uint256 _reward,
			uint256 _holders,
			uint256 _interest,
			uint256 _holdersCap
		);

	function calculateRewardAmount(address _property)
		external
		view
		returns (uint256, uint256);

	function totalLockedForProperty(address _property)
		external
		view
		returns (uint256);

	function totalLocked() external view returns (uint256);

	function calculateWithdrawableInterestAmountByPosition(uint256 _tokenId)
		external
		view
		returns (uint256);

	function cap() external view returns (uint256);

	function updateCap(uint256 _cap) external;
}

// File: contracts/interface/IDev.sol


interface IDev {
	// solhint-disable-next-line func-name-mixedcase
	function MINTER_ROLE() external returns (bytes32);

	// solhint-disable-next-line func-name-mixedcase
	function BURNER_ROLE() external returns (bytes32);

	function mint(address _account, uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;
}

// File: contracts/interface/IDevBridge.sol

interface IDevBridge {
	function mint(address _account, uint256 _amount) external returns (bool);

	function burn(address _account, uint256 _amount) external returns (bool);

	function renounceMinter() external;

	function renounceBurner() external;
}

// File: contracts/src/common/registry/UsingRegistry.sol


/**
 * Module for using AddressRegistry contracts.
 */
abstract contract UsingRegistry {
	address private _registry;

	/**
	 * Initialize the argument as AddressRegistry address.
	 */
	constructor(address _addressRegistry) {
		_registry = _addressRegistry;
	}

	/**
	 * Returns the latest AddressRegistry instance.
	 */
	function registry() internal view returns (IAddressRegistry) {
		return IAddressRegistry(_registry);
	}

	/**
	 * Returns the AddressRegistry address.
	 */
	function registryAddress() external view returns (address) {
		return _registry;
	}
}

// File: contracts/src/market/Market.sol












/**
 * A user-proposable contract for authenticating and associating assets with Property.
 * A user deploys a contract that inherits IMarketBehavior and creates this Market contract with the MarketFactory contract.
 */
contract Market is UsingRegistry, IMarket {
	EnumerableSet.AddressSet private authenticatedProperties;
	bool public override enabled;
	address public override behavior;
	uint256 public override votingEndTimestamp;
	mapping(bytes32 => bool) private idMap;
	mapping(address => bytes32) private idHashMetricsMap;

	using EnumerableSet for EnumerableSet.AddressSet;

	/**
	 * Initialize the passed address as AddressRegistry address and user-proposed contract.
	 */
	constructor(address _registry, address _behavior) UsingRegistry(_registry) {
		/**
		 * Validates the sender is MarketFactory contract.
		 */
		require(
			msg.sender == registry().registries("MarketFactory"),
			"this is illegal address"
		);

		/**
		 * Stores the contract address proposed by a user as an internal variable.
		 */
		behavior = _behavior;

		/**
		 * By default this contract is disabled.
		 */
		enabled = false;

		/**
		 * Sets the period during which voting by voters can be accepted.
		 * This period is determined by `Policy.marketVotingSeconds`.
		 */
		uint256 marketVotingSeconds = IPolicy(registry().registries("Policy"))
			.marketVotingSeconds();
		votingEndTimestamp = block.timestamp + marketVotingSeconds;
	}

	/**
	 * Validates the sender is the passed Property's author.
	 */
	function propertyValidation(address _prop) private view {
		require(
			msg.sender == IProperty(_prop).author(),
			"this is illegal address"
		);
		require(enabled, "market is not enabled");
	}

	/**
	 * Modifier for validates the sender is the passed Property's author.
	 */
	modifier onlyPropertyAuthor(address _prop) {
		propertyValidation(_prop);
		_;
	}

	/**
	 * Modifier for validates the sender is the author of the Property associated with the passed Metrics contract.
	 */
	modifier onlyLinkedPropertyAuthor(address _metrics) {
		address _prop = IMetrics(_metrics).property();
		propertyValidation(_prop);
		_;
	}

	/**
	 * Activates this Market.
	 * Called from MarketFactory contract.
	 */
	function toEnable() external override {
		require(
			msg.sender == registry().registries("MarketFactory"),
			"this is illegal address"
		);
		require(isDuringVotingPeriod(), "deadline is over");
		enabled = true;
	}

	/**
	 * Authenticates the new asset and proves that the Property author is the owner of the asset.
	 */
	function authenticate(address _prop, string[] memory _args)
		public
		override
		onlyPropertyAuthor(_prop)
		returns (bool)
	{
		return _authenticate(_prop, msg.sender, _args);
	}

	/**
	 * Authenticates the new asset and proves that the Property author is the owner of the asset.
	 */
	function authenticateFromPropertyFactory(
		address _prop,
		address _author,
		string[] memory _args
	) external override returns (bool) {
		/**
		 * Validates the sender is PropertyFactory.
		 */
		require(
			msg.sender == registry().registries("PropertyFactory"),
			"this is illegal address"
		);

		/**
		 * Validates this Market is already enabled..
		 */
		require(enabled, "market is not enabled");

		return _authenticate(_prop, _author, _args);
	}

	/**
	 * Bypass to IMarketBehavior.authenticate.
	 * Authenticates the new asset and proves that the Property author is the owner of the asset.
	 */
	function _authenticate(
		address _prop,
		address _author,
		string[] memory _args
	) private returns (bool) {
		return IMarketBehavior(behavior).authenticate(_prop, _args, _author);
	}

	/**
	 * Returns the authentication fee.
	 * Calculates by gets the staking amount of the Property to be authenticated
	 * and the total number of authenticated assets on the protocol, and calling `Policy.authenticationFee`.
	 */
	function getAuthenticationFee(address _property)
		private
		view
		returns (uint256)
	{
		uint256 tokenValue = ILockup(registry().registries("Lockup"))
			.totalLockedForProperty(_property);
		IPolicy policy = IPolicy(registry().registries("Policy"));
		IMetricsFactory metricsFactory = IMetricsFactory(
			registry().registries("MetricsFactory")
		);
		return
			policy.authenticationFee(metricsFactory.metricsCount(), tokenValue);
	}

	/**
	 * A function that will be called back when the asset is successfully authenticated.
	 * There are cases where oracle is required for the authentication process, so the function is used callback style.
	 */
	function authenticatedCallback(address _property, bytes32 _idHash)
		external
		override
		returns (address)
	{
		/**
		 * Validates the sender is the saved IMarketBehavior address.
		 */
		require(msg.sender == behavior, "this is illegal address");
		require(enabled, "market is not enabled");

		/**
		 * Validates the assets are not double authenticated.
		 */
		require(idMap[_idHash] == false, "id is duplicated");
		idMap[_idHash] = true;

		/**
		 * Gets the Property author address.
		 */
		address sender = IProperty(_property).author();

		/**
		 * Publishes a new Metrics contract and associate the Property with the asset.
		 */
		IMetricsFactory metricsFactory = IMetricsFactory(
			registry().registries("MetricsFactory")
		);
		address metrics = metricsFactory.create(_property);
		idHashMetricsMap[metrics] = _idHash;

		/**
		 * Burn as a authentication fee.
		 */
		uint256 authenticationFee = getAuthenticationFee(_property);
		require(
			IDevBridge(registry().registries("DevBridge")).burn(
				sender,
				authenticationFee
			),
			"dev fee failed"
		);

		/**
		 * Adds the number of authenticated assets in this Market.
		 */
		authenticatedProperties.add(_property);
		return metrics;
	}

	/**
	 * Release the authenticated asset.
	 */
	function deauthenticate(address _metrics)
		external
		override
		onlyLinkedPropertyAuthor(_metrics)
	{
		/**
		 * Validates the passed Metrics address is authenticated in this Market.
		 */
		bytes32 idHash = idHashMetricsMap[_metrics];
		require(idMap[idHash], "not authenticated");

		/**
		 * Removes the authentication status from local variables.
		 */
		idMap[idHash] = false;
		idHashMetricsMap[_metrics] = bytes32(0);

		/**
		 * Removes the passed Metrics contract from the Metrics address set.
		 */
		IMetricsFactory metricsFactory = IMetricsFactory(
			registry().registries("MetricsFactory")
		);
		metricsFactory.destroy(_metrics);

		/**
		 * Subtracts the number of authenticated assets in this Market.
		 */
		address property = IMetrics(_metrics).property();
		authenticatedProperties.remove(property);
	}

	/**
	 * Bypass to IMarketBehavior.name.
	 */
	function name() external view override returns (string memory) {
		return IMarketBehavior(behavior).name();
	}

	/**
	 * Bypass to IMarketBehavior.schema.
	 */
	function schema() external view override returns (string memory) {
		return IMarketBehavior(behavior).schema();
	}

	/**
	 * get issued metrics count
	 */
	function issuedMetrics() external view returns (uint256) {
		return authenticatedProperties.length();
	}

	/**
	 * get authentivated properties
	 */
	function getAuthenticatedProperties()
		external
		view
		returns (address[] memory)
	{
		return authenticatedProperties.values();
	}

	function isDuringVotingPeriod() private view returns (bool) {
		return block.timestamp < votingEndTimestamp;
	}
}

// File: contracts/src/market/MarketFactory.sol






/**
 * A factory contract that creates a new Market contract.
 */
contract MarketFactory is
	InitializableUsingRegistry,
	OwnableUpgradeable,
	IMarketFactory
{
	uint256 public override marketsCount;
	address[] public enabledMarkets;
	mapping(address => bool) public override isMarket;
	mapping(address => bool) public override isPotentialMarket;

	/**
	 * Initialize the passed address as AddressRegistry address.
	 */
	function initialize(address _registry) external initializer {
		__Ownable_init();
		__UsingRegistry_init(_registry);
	}

	/**
	 * Creates a new Market contract.
	 */
	function create(address _addr) external override returns (address) {
		/**
		 * Validates the passed address is not 0 address.
		 */
		require(_addr != address(0), "this is illegal address");

		/**
		 * Creates a new Market contract with the passed address as the IMarketBehavior.
		 */
		Market market = new Market(address(registry()), _addr);

		/**
		 * Adds the created Market contract to the Market address set.
		 */
		address marketAddr = address(market);
		isPotentialMarket[marketAddr] = true;

		/**
		 * set associated market address to behavior
		 */
		IMarketBehavior(_addr).setAssociatedMarket(marketAddr);

		/**
		 * For the first Market contract, it will be activated immediately.
		 * If not, the Market contract will be activated after a vote by the voters.
		 */
		if (marketsCount == 0) {
			_enable(marketAddr);
		}

		emit Create(marketAddr, msg.sender);
		return marketAddr;
	}

	/**
	 * Creates a new Market contract.
	 */
	function enable(address _addr) external override onlyOwner {
		_enable(_addr);
	}

	function enableMarketList() external view returns (address[] memory) {
		return enabledMarkets;
	}

	function _enable(address _addr) internal {
		/**
		 * Validates the passed address is not 0 address.
		 */
		require(isPotentialMarket[_addr], "this is illegal address");

		_addMarket(_addr);

		/**
		 * Market will be enable.
		 */
		IMarket market = IMarket(_addr);
		require(market.enabled() == false, "already enabled");

		market.toEnable();
		enabledMarkets.push(_addr);
	}

	function _addMarket(address _addr) internal {
		isMarket[_addr] = true;
		_addCount();
	}

	function _addCount() internal {
		marketsCount = marketsCount + 1;
	}
}