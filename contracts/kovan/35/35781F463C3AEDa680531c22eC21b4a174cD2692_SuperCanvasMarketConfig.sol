// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ISuperCanvasMarketConfig.sol";

contract SuperCanvasMarketConfig is Ownable, ISuperCanvasMarketConfig {
    using EnumerableSet for EnumerableSet.AddressSet;

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
    EnumerableSet.AddressSet private nftEnables;
    // nft => quote => is enable
    mapping(address => mapping(address => bool)) public override nftQuoteEnables;
    // nft => fee address
    mapping(address => address) public override feeAddresses;
    // nft => quote => fee for platform
    mapping(address => mapping(address => uint256)) public override feeValues;
    // nft => royalties provider
    mapping(address => address) public override royaltiesAddresses;
    // nft => quote => fee for project
    mapping(address => mapping(address => uint256)) public override royaltiesValues;
    // nft => quotes
    mapping(address => EnumerableSet.AddressSet) private nftQuotes;

    constructor() {}
    
    function nftSettings(address _nftToken, address _quoteToken) external override view returns (NftSettings memory) {
        return
            NftSettings({
                enable: checkNftEnables(_nftToken),
                nftQuoteEnable: nftQuoteEnables[_nftToken][_quoteToken],
                feeAddress: feeAddresses[_nftToken],
                feeValue: feeValues[_nftToken][_quoteToken],
                royaltiesAddress: royaltiesAddresses[_nftToken],
                royaltiesValue: royaltiesValues[_nftToken][_quoteToken]
            });
    }

    function whenSettings(uint256 key, uint256 value) external override view {
        require(settings[key] == value, "settings err");
    }

    function setSettings(uint256[] memory keys, uint256[] memory values) external override onlyOwner {
        require(keys.length == values.length, "length err");
        for (uint256 i; i < keys.length; i++) {
            emit UpdateSettings(keys[i], settings[keys[i]], values[i]);
            settings[keys[i]] = values[i];
        }
    }
    
    function checkEnableTrade(address _nftToken, address _quoteToken) external override view {
        // nft disable
        require(checkNftEnables(_nftToken), "nft disable");
        // quote disable
        require(nftQuoteEnables[_nftToken][_quoteToken], "quote disable");
    }

    function setNftEnables(address _nftToken, bool _enable) public override onlyOwner {
        if (_enable) {
            nftEnables.add(_nftToken);
        }
        else {
            require(checkNftEnables(_nftToken), "add the token first");
            nftEnables.remove(_nftToken);
        }
    }

    function getNftEnables() external override view returns (address[] memory nftTokens) {
        nftTokens = new address[](nftEnables.length());
        for (uint256 i; i < nftEnables.length(); i++) {
            nftTokens[i] = nftEnables.at(i);
        }
    }

    function checkNftEnables(address _nftToken) public override view returns (bool enable) {
        enable = nftEnables.contains(_nftToken);
    }

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) public override onlyOwner {
        EnumerableSet.AddressSet storage quotes = nftQuotes[_nftToken];
        for (uint256 i; i < _quotes.length; i++) {
            nftQuoteEnables[_nftToken][_quotes[i]] = _enable;
            if (!quotes.contains(_quotes[i])) {
                quotes.add(_quotes[i]);
            }
        }
    }

    function getNftQuotes(address _nftToken) external override view returns (address[] memory quotes) {
        quotes = new address[](nftQuotes[_nftToken].length());
        for (uint256 i = 0; i < nftQuotes[_nftToken].length(); i++) {
            quotes[i] = nftQuotes[_nftToken].at(i);
        }
    }

    function setTransferFeeAddress(
        address _nftToken,
        address _feeAddress
    ) public override onlyOwner{
        require(_msgSender() == feeAddresses[_nftToken]|| owner() == _msgSender(), "forbidden");
        emit FeeAddressTransferred(_nftToken, feeAddresses[_nftToken], _feeAddress);
        feeAddresses[_nftToken] = _feeAddress;
    }

    function setFee(
        address _nftToken,
        address _quoteToken,
        uint256 _feeValue
    ) public override onlyOwner {
        emit SetFee(_nftToken, _quoteToken, feeValues[_nftToken][_quoteToken], _feeValue);
        feeValues[_nftToken][_quoteToken] = _feeValue;
    }

    function batchSetFee(
        address _nftToken,
        address[] memory _quoteTokens,
        uint256[] memory _feeValues
    ) public override onlyOwner {
        require(_quoteTokens.length == _feeValues.length, "length err");
        for (uint256 i; i < _quoteTokens.length; i++) {
            setFee(_nftToken, _quoteTokens[i], _feeValues[i]);
        }
    }

    function setRoyaltiesAddress(
        address _nftToken,
        address _royaltiesAddress
    ) public override onlyOwner {
        emit SetRoyaltiesAddress(
            _nftToken,
            royaltiesAddresses[_nftToken],
            _royaltiesAddress
        );
        royaltiesAddresses[_nftToken] = _royaltiesAddress;
    }

    function setRoyalties(
        address _nftToken,
        address _quoteToken,
        uint256 _royaltiesValue
    ) public override onlyOwner {
        emit SetRoyalties(_nftToken, _quoteToken, royaltiesValues[_nftToken][_quoteToken], _royaltiesValue);
        royaltiesValues[_nftToken][_quoteToken] = _royaltiesValue;
    }

    function batchSetRoyalties(
        address _nftToken,
        address[] memory _quoteTokens,
        uint256[] memory _royaltiesValues
    ) public override onlyOwner {
        require(_quoteTokens.length == _royaltiesValues.length, "length err");
        for (uint256 i; i < _quoteTokens.length; i++) {
            setRoyalties(_nftToken, _quoteTokens[i], _royaltiesValues[i]);
        }
    }

    function addNft(
        address _nftToken,
        bool _enable,
        address[] memory _quotes,
        address _feeAddress,
        uint256[] memory _feeValues,
        address _royaltiesAddress,
        uint256[] memory _royaltiesValues
    ) external override onlyOwner {
        require(
            _quotes.length == _feeValues.length &&
            _feeValues.length == _royaltiesValues.length,
            "length err"
        );
        setNftEnables(_nftToken, _enable);
        setNftQuoteEnables(_nftToken, _quotes, true);
        setTransferFeeAddress(_nftToken, _feeAddress);
        batchSetFee(_nftToken, _quotes, _feeValues);
        setRoyaltiesAddress(_nftToken, _royaltiesAddress);
        batchSetRoyalties(_nftToken, _quotes, _royaltiesValues);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ISuperCanvasMarketConfig {
    event FeeAddressTransferred(
        address indexed nftToken,
        address oldAddr,
        address newAddr
    );
    event SetFee(address indexed nftToken, address indexed quoteToken, uint256 oldFee, uint256 newFee);
    event SetRoyaltiesAddress(
        address indexed nftToken,
        address oldRoyaltiesAddress,
        address newRoyaltiesAddress
    );
    event SetRoyalties(
        address indexed nftToken,
        address indexed quoteToken,
        uint256 oldRoyalties,
        uint256 newRoyalties
    );
    event UpdateSettings(uint256 indexed setting, uint256 oldValue, uint256 newValue);

    struct NftSettings {
        bool enable;
        bool nftQuoteEnable;
        address feeAddress;
        uint256 feeValue;
        address royaltiesAddress;
        uint256 royaltiesValue;
    }

    function settings(uint256 _key) external view returns (uint256 value);

    function nftQuoteEnables(address _nftToken, address _quoteToken) external view returns (bool enable);

    function feeAddresses(address _nftToken) external view returns (address feeAddress);

    function feeValues(address _nftToken, address _quoteToken) external view returns (uint256 feeValue);

    function royaltiesAddresses(address _nftToken) external view returns (address royaltiesAddress);

    function royaltiesValues(address _nftToken, address _quoteToken) external view returns (uint256 royaltiesValue);

    function nftSettings(address _nftToken, address _quoteToken) external view returns (NftSettings memory);

    function whenSettings(uint256 key, uint256 value) external view;

    function setSettings(uint256[] memory keys, uint256[] memory values) external;

    function checkEnableTrade(address _nftToken, address _quoteToken) external view;

    function setNftEnables(address _nftToken, bool _enable) external;

    function getNftEnables() external view returns (address[] memory nftTokens);

    function checkNftEnables(address _nftToken) external view returns (bool enable);

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) external;

    function getNftQuotes(address _nftToken) external view returns (address[] memory quotes);

    function setTransferFeeAddress(
        address _nftToken,
        address _feeAddress
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

    function setRoyaltiesAddress(
        address _nftToken,
        address _royaltiesAddress
    ) external;

    function setRoyalties(
        address _nftToken,
        address _quoteToken,
        uint256 _royaltiesValue
    ) external;

    function batchSetRoyalties(
        address _nftToken,
        address[] memory _quoteTokens,
        uint256[] memory _royaltiesValues
    ) external;

    function addNft(
        address _nftToken,
        bool _enable,
        address[] memory _quotes,
        address _feeAddress,
        uint256[] memory _feeValues,
        address _royaltiesAddress,
        uint256[] memory _royaltiesValues
    ) external;
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
}

