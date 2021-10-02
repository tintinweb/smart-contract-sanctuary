/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;


/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


interface IExchangeNFTConfiguration {
    event FeeAddressTransferred(
        address indexed nftToken,
        address indexed quoteToken,
        address previousOwner,
        address newOwner
    );
    event SetFee(address indexed nftToken, address indexed quoteToken, address seller, uint256 oldFee, uint256 newFee);
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
    event UpdateSettings(uint256 indexed setting, uint256 proviousValue, uint256 value);

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

    function nftQuoteEnables(address _nftToken, address _quoteToken) external view returns (bool enable);

    function feeBurnables(address _nftToken, address _quoteToken) external view returns (bool enable);

    function feeAddresses(address _nftToken, address _quoteToken) external view returns (address feeAddress);

    function feeValues(address _nftToken, address _quoteToken) external view returns (uint256 feeValue);

    function royaltiesProviders(address _nftToken, address _quoteToken)
        external
        view
        returns (address royaltiesProvider);

    function royaltiesBurnables(address _nftToken, address _quoteToken) external view returns (bool enable);

    function checkEnableTrade(address _nftToken, address _quoteToken) external view;

    function whenSettings(uint256 key, uint256 value) external view;

    function setSettings(uint256[] memory keys, uint256[] memory values) external;

    function nftSettings(address _nftToken, address _quoteToken) external view returns (NftSettings memory);

    function setNftEnables(address _nftToken, bool _enable) external;

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) external;

    function getNftQuotes(address _nftToken) external view returns (address[] memory quotes);

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
    uint256[49] private __gap;
}




contract ExchangeNFTConfiguration is IExchangeNFTConfiguration, OwnableUpgradeable {
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
    mapping(address => mapping(address => bool)) public override nftQuoteEnables;
    // nft => quote => fee burnable
    mapping(address => mapping(address => bool)) public override feeBurnables;
    // nft => quote => fee address
    mapping(address => mapping(address => address)) public override feeAddresses;
    // nft => quote => fee
    mapping(address => mapping(address => uint256)) public override feeValues;
    // nft => quote => royalties provider
    mapping(address => mapping(address => address)) public override royaltiesProviders;
    // nft => quote => royalties burnable
    mapping(address => mapping(address => bool)) public override royaltiesBurnables;
    // nft => quotes
    mapping(address => EnumerableSetUpgradeable.AddressSet) private nftQuotes;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function nftSettings(address _nftToken, address _quoteToken) external view override returns (NftSettings memory) {
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

    function checkEnableTrade(address _nftToken, address _quoteToken) external view override {
        // nft disable
        require(nftEnables[_nftToken], 'nft disable');
        // quote disable
        require(nftQuoteEnables[_nftToken][_quoteToken], 'quote disable');
    }

    function whenSettings(uint256 key, uint256 value) external view override {
        require(settings[key] == value, 'settings err');
    }

    function setSettings(uint256[] memory keys, uint256[] memory values) external override onlyOwner {
        require(keys.length == values.length, 'length err');
        for (uint256 i; i < keys.length; ++i) {
            emit UpdateSettings(keys[i], settings[keys[i]], values[i]);
            settings[keys[i]] = values[i];
        }
    }

    function setNftEnables(address _nftToken, bool _enable) public override onlyOwner {
        nftEnables[_nftToken] = _enable;
    }

    function setNftQuoteEnables(
        address _nftToken,
        address[] memory _quotes,
        bool _enable
    ) public override onlyOwner {
        EnumerableSetUpgradeable.AddressSet storage quotes = nftQuotes[_nftToken];
        for (uint256 i; i < _quotes.length; i++) {
            nftQuoteEnables[_nftToken][_quotes[i]] = _enable;
            if (!quotes.contains(_quotes[i])) {
                quotes.add(_quotes[i]);
            }
        }
    }

    function getNftQuotes(address _nftToken) external view override returns (address[] memory quotes) {
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
        require(_msgSender() == feeAddresses[_nftToken][_quoteToken] || owner() == _msgSender(), 'forbidden');
        emit FeeAddressTransferred(_nftToken, _quoteToken, feeAddresses[_nftToken][_quoteToken], _feeAddress);
        feeAddresses[_nftToken][_quoteToken] = _feeAddress;
    }

    function batchTransferFeeAddress(
        address _nftToken,
        address[] memory _quoteTokens,
        address[] memory _feeAddresses
    ) public override {
        require(_quoteTokens.length == _feeAddresses.length, 'length err');
        for (uint256 i; i < _quoteTokens.length; ++i) {
            transferFeeAddress(_nftToken, _quoteTokens[i], _feeAddresses[i]);
        }
    }

    function setFee(
        address _nftToken,
        address _quoteToken,
        uint256 _feeValue
    ) public override onlyOwner {
        emit SetFee(_nftToken, _quoteToken, _msgSender(), feeValues[_nftToken][_quoteToken], _feeValue);
        feeValues[_nftToken][_quoteToken] = _feeValue;
    }

    function batchSetFee(
        address _nftToken,
        address[] memory _quoteTokens,
        uint256[] memory _feeValues
    ) public override onlyOwner {
        require(_quoteTokens.length == _feeValues.length, 'length err');
        for (uint256 i; i < _quoteTokens.length; ++i) {
            setFee(_nftToken, _quoteTokens[i], _feeValues[i]);
        }
    }

    function setFeeBurnAble(
        address _nftToken,
        address _quoteToken,
        bool _feeBurnable
    ) public override onlyOwner {
        emit SetFeeBurnAble(_nftToken, _quoteToken, _msgSender(), feeBurnables[_nftToken][_quoteToken], _feeBurnable);
        feeBurnables[_nftToken][_quoteToken] = _feeBurnable;
    }

    function batchSetFeeBurnAble(
        address _nftToken,
        address[] memory _quoteTokens,
        bool[] memory _feeBurnables
    ) public override onlyOwner {
        require(_quoteTokens.length == _feeBurnables.length, 'length err');
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
        require(_quoteTokens.length == _royaltiesProviders.length, 'length err');
        for (uint256 i; i < _quoteTokens.length; ++i) {
            setRoyaltiesProvider(_nftToken, _quoteTokens[i], _royaltiesProviders[i]);
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
        require(_quoteTokens.length == _royaltiesBurnables.length, 'length err');
        for (uint256 i; i < _quoteTokens.length; ++i) {
            setRoyaltiesBurnable(_nftToken, _quoteTokens[i], _royaltiesBurnables[i]);
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
            'length err'
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