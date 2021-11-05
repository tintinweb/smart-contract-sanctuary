// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IExchangeNFTConfiguration.sol";

contract ExchangeNFTConfiguration is
    IExchangeNFTConfiguration,
    OwnableUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
      global settings
      settings[0] = 0; // enable readyToSellToken
      settings[1] = 0; // enable setCurrentPrice
      settings[2] = 0; // enable buyToken
      settings[3] = 0; // enable cancelSellToken
      settings[4] = 0; // enable bidToken
      settings[5] = 0; // enable updateBidPrice
      settings[6] = 0; // enable sellTokenTo
      settings[7] = 0; // enable cancelBidToken
    */
    mapping(uint256 => uint256) public override settings;
    // nft => is enable
    mapping(address => bool) public override nftEnables;
    // nft => quote => is enable
    mapping(address => mapping(address => bool))
        public
        override nftQuoteEnables;
    // nft => quote => fee burnable
    mapping(address => mapping(address => bool)) public override feeBurnables;
    // nft => quote => fee address
    mapping(address => mapping(address => address))
        public
        override feeAddresses;
    // nft => quote => fee
    mapping(address => mapping(address => uint256)) public override feeValues;
    // nft => quote => royalties provider
    mapping(address => mapping(address => address))
        public
        override royaltiesProviders;
    // nft => quote => royalties burnable
    mapping(address => mapping(address => bool))
        public
        override royaltiesBurnables;
    // nft => quotes
    mapping(address => EnumerableSetUpgradeable.AddressSet) private nftQuotes;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function nftSettings(address _nftToken, address _quoteToken)
        external
        view
        override
        returns (NftSettings memory)
    {
        return
            NftSettings({
                enable: nftEnables[_nftToken],
                nftQuoteEnable: nftQuoteEnables[_nftToken][_quoteToken],
                feeAddress: feeAddresses[_nftToken][_quoteToken],
                feeBurnAble: feeBurnables[_nftToken][_quoteToken],
                feeValue: feeValues[_nftToken][_quoteToken],
                royaltiesProvider: royaltiesProviders[_nftToken][_quoteToken],
                royaltiesBurnable: royaltiesBurnables[_nftToken][_quoteToken]
            });
    }

    function checkEnableTrade(address _nftToken, address _quoteToken)
        external
        view
        override
    {
        // nft disable
        require(nftEnables[_nftToken], "nft disable");
        // quote disable
        require(nftQuoteEnables[_nftToken][_quoteToken], "quote disable");
    }

    function whenSettings(uint256 key, uint256 value) external view override {
        require(settings[key] == value, "settings err");
    }

    function setSettings(uint256[] memory keys, uint256[] memory values)
        external
        override
        onlyOwner
    {
        require(keys.length == values.length, "length err");
        for (uint256 i; i < keys.length; ++i) {
            emit UpdateSettings(keys[i], settings[keys[i]], values[i]);
            settings[keys[i]] = values[i];
        }
    }

    function setNftEnables(address _nftToken, bool _enable)
        public
        override
        onlyOwner
    {
        nftEnables[_nftToken] = _enable;
    }

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) public override onlyOwner {
        EnumerableSetUpgradeable.AddressSet storage quotes = nftQuotes[
            _nftToken
        ];
        for (uint256 i; i < _quotes.length; i++) {
            nftQuoteEnables[_nftToken][_quotes[i]] = _enable;
            if (!quotes.contains(_quotes[i])) {
                quotes.add(_quotes[i]);
            }
        }
    }

    function getNftQuotes(address _nftToken)
        external
        view
        override
        returns (address[] memory quotes)
    {
        quotes = new address[](nftQuotes[_nftToken].length());
        for (uint256 i = 0; i < nftQuotes[_nftToken].length(); ++i) {
            quotes[i] = nftQuotes[_nftToken].at(i);
        }
    }

    function transferFeeAddress(
        address _nftToken,
        address _quoteToken,
        address _feeAddress
    ) public override {
        require(
            _msgSender() == feeAddresses[_nftToken][_quoteToken] ||
                owner() == _msgSender(),
            "forbidden"
        );
        emit FeeAddressTransferred(
            _nftToken,
            _quoteToken,
            feeAddresses[_nftToken][_quoteToken],
            _feeAddress
        );
        feeAddresses[_nftToken][_quoteToken] = _feeAddress;
    }

    function batchTransferFeeAddress(
        address _nftToken,
        address[] memory _quoteTokens,
        address[] memory _feeAddresses
    ) public override {
        require(_quoteTokens.length == _feeAddresses.length, "length err");
        for (uint256 i; i < _quoteTokens.length; ++i) {
            transferFeeAddress(_nftToken, _quoteTokens[i], _feeAddresses[i]);
        }
    }

    function setFee(
        address _nftToken,
        address _quoteToken,
        uint256 _feeValue
    ) public override onlyOwner {
        emit SetFee(
            _nftToken,
            _quoteToken,
            _msgSender(),
            feeValues[_nftToken][_quoteToken],
            _feeValue
        );
        feeValues[_nftToken][_quoteToken] = _feeValue;
    }

    function batchSetFee(
        address _nftToken,
        address[] memory _quoteTokens,
        uint256[] memory _feeValues
    ) public override onlyOwner {
        require(_quoteTokens.length == _feeValues.length, "length err");
        for (uint256 i; i < _quoteTokens.length; ++i) {
            setFee(_nftToken, _quoteTokens[i], _feeValues[i]);
        }
    }

    function setFeeBurnAble(
        address _nftToken,
        address _quoteToken,
        bool _feeBurnable
    ) public override onlyOwner {
        emit SetFeeBurnAble(
            _nftToken,
            _quoteToken,
            _msgSender(),
            feeBurnables[_nftToken][_quoteToken],
            _feeBurnable
        );
        feeBurnables[_nftToken][_quoteToken] = _feeBurnable;
    }

    function batchSetFeeBurnAble(
        address _nftToken,
        address[] memory _quoteTokens,
        bool[] memory _feeBurnables
    ) public override onlyOwner {
        require(_quoteTokens.length == _feeBurnables.length, "length err");
        for (uint256 i; i < _quoteTokens.length; ++i) {
            setFeeBurnAble(_nftToken, _quoteTokens[i], _feeBurnables[i]);
        }
    }

    function setRoyaltiesProvider(
        address _nftToken,
        address _quoteToken,
        address _royaltiesProvider
    ) public override onlyOwner {
        emit SetRoyaltiesProvider(
            _nftToken,
            _quoteToken,
            _msgSender(),
            royaltiesProviders[_nftToken][_quoteToken],
            _royaltiesProvider
        );
        royaltiesProviders[_nftToken][_quoteToken] = _royaltiesProvider;
    }

    function batchSetRoyaltiesProviders(
        address _nftToken,
        address[] memory _quoteTokens,
        address[] memory _royaltiesProviders
    ) public override onlyOwner {
        require(
            _quoteTokens.length == _royaltiesProviders.length,
            "length err"
        );
        for (uint256 i; i < _quoteTokens.length; ++i) {
            setRoyaltiesProvider(
                _nftToken,
                _quoteTokens[i],
                _royaltiesProviders[i]
            );
        }
    }

    function setRoyaltiesBurnable(
        address _nftToken,
        address _quoteToken,
        bool _royaltiesBurnable
    ) public override onlyOwner {
        emit SetRoyaltiesBurnable(
            _nftToken,
            _quoteToken,
            _msgSender(),
            royaltiesBurnables[_nftToken][_quoteToken],
            _royaltiesBurnable
        );
        royaltiesBurnables[_nftToken][_quoteToken] = _royaltiesBurnable;
    }

    function batchSetRoyaltiesBurnable(
        address _nftToken,
        address[] memory _quoteTokens,
        bool[] memory _royaltiesBurnables
    ) public override onlyOwner {
        require(
            _quoteTokens.length == _royaltiesBurnables.length,
            "length err"
        );
        for (uint256 i; i < _quoteTokens.length; ++i) {
            setRoyaltiesBurnable(
                _nftToken,
                _quoteTokens[i],
                _royaltiesBurnables[i]
            );
        }
    }

    function addNft(
        address _nftToken,
        bool _enable,
        address[] memory _quotes,
        address[] memory _feeAddresses,
        uint256[] memory _feeValues,
        bool[] memory _feeBurnAbles,
        address[] memory _royaltiesProviders,
        bool[] memory _royaltiesBurnables
    ) external override onlyOwner {
        require(
            _quotes.length == _feeAddresses.length &&
                _feeAddresses.length == _feeValues.length &&
                _feeValues.length == _feeBurnAbles.length &&
                _feeBurnAbles.length == _royaltiesProviders.length &&
                _royaltiesProviders.length == _royaltiesBurnables.length,
            "length err"
        );
        setNftEnables(_nftToken, _enable);
        setNftQuoteEnables(_nftToken, _quotes, true);
        batchTransferFeeAddress(_nftToken, _quotes, _feeAddresses);
        batchSetFee(_nftToken, _quotes, _feeValues);
        batchSetFeeBurnAble(_nftToken, _quotes, _feeBurnAbles);
        batchSetRoyaltiesProviders(_nftToken, _quotes, _royaltiesProviders);
        batchSetRoyaltiesBurnable(_nftToken, _quotes, _royaltiesBurnables);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IExchangeNFTConfiguration {
    event FeeAddressTransferred(
        address indexed nftToken,
        address indexed quoteToken,
        address previousOwner,
        address newOwner
    );
    event SetFee(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        uint256 oldFee,
        uint256 newFee
    );
    event SetFeeBurnAble(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        bool oldFeeBurnable,
        bool newFeeBurnable
    );
    event SetRoyaltiesProvider(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        address oldRoyaltiesProvider,
        address newRoyaltiesProvider
    );
    event SetRoyaltiesBurnable(
        address indexed nftToken,
        address indexed quoteToken,
        address seller,
        bool oldRoyaltiesBurnable,
        bool newFeeRoyaltiesBurnable
    );
    event UpdateSettings(
        uint256 indexed setting,
        uint256 proviousValue,
        uint256 value
    );

    struct NftSettings {
        bool enable;
        bool nftQuoteEnable;
        address feeAddress;
        bool feeBurnAble;
        uint256 feeValue;
        address royaltiesProvider;
        bool royaltiesBurnable;
    }

    function settings(uint256 _key) external view returns (uint256 value);

    function nftEnables(address _nftToken) external view returns (bool enable);

    function nftQuoteEnables(address _nftToken, address _quoteToken)
        external
        view
        returns (bool enable);

    function feeBurnables(address _nftToken, address _quoteToken)
        external
        view
        returns (bool enable);

    function feeAddresses(address _nftToken, address _quoteToken)
        external
        view
        returns (address feeAddress);

    function feeValues(address _nftToken, address _quoteToken)
        external
        view
        returns (uint256 feeValue);

    function royaltiesProviders(address _nftToken, address _quoteToken)
        external
        view
        returns (address royaltiesProvider);

    function royaltiesBurnables(address _nftToken, address _quoteToken)
        external
        view
        returns (bool enable);

    function checkEnableTrade(address _nftToken, address _quoteToken)
        external
        view;

    function whenSettings(uint256 key, uint256 value) external view;

    function setSettings(uint256[] memory keys, uint256[] memory values)
        external;

    function nftSettings(address _nftToken, address _quoteToken)
        external
        view
        returns (NftSettings memory);

    function setNftEnables(address _nftToken, bool _enable) external;

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) external;

    function getNftQuotes(address _nftToken)
        external
        view
        returns (address[] memory quotes);

    function transferFeeAddress(
        address _nftToken,
        address _quoteToken,
        address _feeAddress
    ) external;

    function batchTransferFeeAddress(
        address _nftToken,
        address[] memory _quoteTokens,
        address[] memory _feeAddresses
    ) external;

    function setFee(
        address _nftToken,
        address _quoteToken,
        uint256 _feeValue
    ) external;

    function batchSetFee(
        address _nftToken,
        address[] memory _quoteTokens,
        uint256[] memory _feeValues
    ) external;

    function setFeeBurnAble(
        address _nftToken,
        address _quoteToken,
        bool _feeBurnable
    ) external;

    function batchSetFeeBurnAble(
        address _nftToken,
        address[] memory _quoteTokens,
        bool[] memory _feeBurnables
    ) external;

    function setRoyaltiesProvider(
        address _nftToken,
        address _quoteToken,
        address _royaltiesProvider
    ) external;

    function batchSetRoyaltiesProviders(
        address _nftToken,
        address[] memory _quoteTokens,
        address[] memory _royaltiesProviders
    ) external;

    function setRoyaltiesBurnable(
        address _nftToken,
        address _quoteToken,
        bool _royaltiesBurnable
    ) external;

    function batchSetRoyaltiesBurnable(
        address _nftToken,
        address[] memory _quoteTokens,
        bool[] memory _royaltiesBurnables
    ) external;

    function addNft(
        address _nftToken,
        bool _enable,
        address[] memory _quotes,
        address[] memory _feeAddresses,
        uint256[] memory _feeValues,
        bool[] memory _feeBurnAbles,
        address[] memory _royaltiesProviders,
        bool[] memory _royaltiesBurnables
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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