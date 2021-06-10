// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./utils/EnumerableSet.sol";
import "./interfaces/IAssetAllocation.sol";
import "./interfaces/ITVLManager.sol";
import "./interfaces/IOracleAdapter.sol";
import "./interfaces/IAddressRegistryV2.sol";

/// @title TVL Manager
/// @author APY.Finance
/// @notice Deployed assets can exist across various platforms within the
/// defi ecosystem: pools, accounts, defi protocols, etc. This contract
/// tracks deployed capital by registering the look up functions so that
/// the TVL can be properly computed.
/// @dev It is imperative that this manager has the most up to date asset
/// allocations registered. Any assets in the system that have been deployed,
/// but are not registered can have devastating and catastrophic effects on the TVL.
contract TVLManager is Ownable, ReentrancyGuard, ITVLManager, IAssetAllocation {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Address for address;

    IAddressRegistryV2 public addressRegistry;

    // all registered allocation ids
    EnumerableSet.Bytes32Set private _allocationIds;
    // ids mapped to data
    mapping(bytes32 => Data) private _allocationData;
    // ids mapped to symbol
    mapping(bytes32 => string) private _allocationSymbols;
    // ids mapped to decimals
    mapping(bytes32 => uint256) private _allocationDecimals;

    /// @notice Constructor TVLManager
    /// @param _addressRegistry the address registry to initialize with
    constructor(address _addressRegistry) public {
        setAddressRegistry(_addressRegistry);
    }

    /// @dev Reverts if non-permissed account calls.
    /// Permissioned accounts are: owner, pool manager, and account manager
    modifier onlyPermissioned() {
        require(
            msg.sender == owner() ||
                msg.sender == addressRegistry.poolManagerAddress() ||
                msg.sender == addressRegistry.lpSafeAddress(),
            "PERMISSIONED_ONLY"
        );
        _;
    }

    function lockOracleAdapter() internal {
        IOracleAdapter oracleAdapter =
            IOracleAdapter(addressRegistry.oracleAdapterAddress());
        oracleAdapter.lock();
    }

    /// @notice Registers a new asset allocation
    /// @dev only permissed accounts can call.
    /// New ids are uniquely determined by the provided data struct; no duplicates are allowed
    /// @param data the data struct containing the target address and the bytes lookup data that will be registered
    /// @param symbol the token symbol to register for the asset allocation
    /// @param decimals the decimals to register for the new asset allocation
    function addAssetAllocation(
        Data memory data,
        string calldata symbol,
        uint256 decimals
    ) external override nonReentrant onlyPermissioned {
        require(!isAssetAllocationRegistered(data), "DUPLICATE_DATA_DETECTED");
        bytes32 dataHash = generateDataHash(data);
        _allocationIds.add(dataHash);
        _allocationData[dataHash] = data;
        _allocationSymbols[dataHash] = symbol;
        _allocationDecimals[dataHash] = decimals;
        lockOracleAdapter();
    }

    /// @notice Removes an existing asset allocation
    /// @dev only permissed accounts can call.
    /// @param data the data struct containing the target address and bytes lookup data that will be removed
    function removeAssetAllocation(Data memory data)
        external
        override
        nonReentrant
        onlyPermissioned
    {
        require(isAssetAllocationRegistered(data), "ALLOCATION_DOES_NOT_EXIST");
        bytes32 dataHash = generateDataHash(data);
        _allocationIds.remove(dataHash);
        delete _allocationData[dataHash];
        delete _allocationSymbols[dataHash];
        delete _allocationDecimals[dataHash];
        lockOracleAdapter();
    }

    /// @notice Generates a data hash used for uniquely identifying asset allocations
    /// @param data the data hash containing the target address and the bytes lookup data
    /// @return returns the resulting bytes32 hash of the abi encode packed target address and bytes look up data
    function generateDataHash(Data memory data)
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(data.target, data.data));
    }

    /// @notice determines if a target address and bytes lookup data has already been registered
    /// @param data the data hash containing the target address and the bytes lookup data
    /// @return returns true if the asset allocation is currently registered, otherwise false
    function isAssetAllocationRegistered(Data memory data)
        public
        view
        override
        returns (bool)
    {
        return _isAssetAllocationRegistered(generateDataHash(data));
    }

    /// @notice helper function for isAssetallocationRegistered function
    /// @param data the bytes32 hash
    /// @return returns true if the asset allocation is currently registered, otherwise false
    function _isAssetAllocationRegistered(bytes32 data)
        public
        view
        returns (bool)
    {
        return _allocationIds.contains(data);
    }

    /// @notice Returns a list of all identifiers where asset allocations have been registered
    /// @dev the list contains no duplicate identifiers
    /// @return list of all the registered identifiers
    function getAssetAllocationIds()
        external
        view
        override
        returns (bytes32[] memory)
    {
        uint256 length = _allocationIds.length();
        bytes32[] memory allocationIds = new bytes32[](length);
        for (uint256 i = 0; i < length; i++) {
            allocationIds[i] = _allocationIds.at(i);
        }
        return allocationIds;
    }

    /// @notice Executes the bytes lookup data registered under an id
    /// @dev The balance of an id may be aggregated from multiple contracts
    /// @param allocationId the id to fetch the balance for
    /// @return returns the result of the executed lookup data registered for the provided id
    function balanceOf(bytes32 allocationId)
        external
        view
        override
        returns (uint256)
    {
        require(
            _isAssetAllocationRegistered(allocationId),
            "INVALID_ALLOCATION_ID"
        );
        Data memory data = _allocationData[allocationId];
        bytes memory returnData = executeView(data);

        uint256 _balance;
        assembly {
            _balance := mload(add(returnData, 0x20))
        }

        return _balance;
    }

    /// @notice Returns the token symbol registered under an id
    /// @param allocationId the id to fetch the token for
    /// @return returns the result of the token symbol registered for the provided id
    function symbolOf(bytes32 allocationId)
        external
        view
        override
        returns (string memory)
    {
        return _allocationSymbols[allocationId];
    }

    /// @notice Returns the decimals registered under an id
    /// @param allocationId the id to fetch the decimals for
    /// @return returns the result of the decimal value registered for the provided id
    function decimalsOf(bytes32 allocationId)
        external
        view
        override
        returns (uint256)
    {
        return _allocationDecimals[allocationId];
    }

    /// @notice Executes data's bytes look up data against data's target address
    /// @dev execution is a static call
    /// @param data the data hash containing the target address and the bytes lookup data to execute
    /// @return returnData returns return data from the executed contract
    function executeView(Data memory data)
        public
        view
        returns (bytes memory returnData)
    {
        returnData = data.target.functionStaticCall(data.data);
    }

    /**
     * @notice Sets the address registry
     * @dev only callable by owner
     * @param _addressRegistry the address of the registry
     */
    function setAddressRegistry(address _addressRegistry) public onlyOwner {
        require(Address.isContract(_addressRegistry), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(_addressRegistry);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity 0.6.11;

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

/* solhint-disable */
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

/// @title Interface to Access APY.Finance's Asset Allocations
/// @author APY.Finance
/// @notice Enables 3rd Parties (ie. Chainlink) to pull relevant asset allocations
/// in order to compute the TVL across the entire APY.Finance system.
interface IAssetAllocation {
    /// @notice Returns a list of all identifiers where asset allocations have been registered
    /// @dev the list contains no duplicate identifiers
    /// @return list of all the registered identifiers
    function getAssetAllocationIds() external view returns (bytes32[] memory);

    /// @notice Executes the bytes lookup data registered under an id
    /// @dev The balance of an id may be aggregated from multiple contracts
    /// @param allocationId the id to fetch the balance for
    /// @return returns the result of the executed lookup data registered for the provided id
    function balanceOf(bytes32 allocationId) external view returns (uint256);

    /// @notice Returns the token symbol registered under an id
    /// @param allocationId the id to fetch the token for
    /// @return returns the result of the token symbol registered for the provided id
    function symbolOf(bytes32 allocationId)
        external
        view
        returns (string memory);

    /// @notice Returns the decimals registered under an id
    /// @param allocationId the id to fetch the decimals for
    /// @return returns the result of the decimal value registered for the provided id
    function decimalsOf(bytes32 allocationId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for addition and removal of asset allocations
          for account deployments
 * @author APY.Finance
 * @notice These functions enable external systems to pull necessary info
 *         to compute the TVL of the APY.Finance system.
 */
interface ITVLManager {
    // struct representing a view call execution against a target contract given bytes
    // target is the target contract to execute view calls against
    // bytes data represents the encoded function signature + parameters
    struct Data {
        address target;
        bytes data;
    }

    // struct representing the relevant pieces of data that need to be provided when registering an asset allocation
    // symbol is the symbol of the token that the resulting view call execution will need to be evaluated as
    // decimals is the number of decimals that the resulting view call execution will need to be evaluated as
    // data is the struct representing the view call execution
    struct AssetAllocation {
        string symbol;
        uint256 decimals;
        Data data;
    }

    function addAssetAllocation(
        Data calldata data,
        string calldata symbol,
        uint256 decimals
    ) external;

    function removeAssetAllocation(Data calldata data) external;

    function generateDataHash(Data calldata data)
        external
        pure
        returns (bytes32);

    function isAssetAllocationRegistered(Data calldata data)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

interface IOracleAdapter {
    struct Value {
        uint256 value;
        uint256 periodEnd;
    }

    function setTvl(uint256 value, uint256 period) external;

    function setAssetValue(
        address asset,
        uint256 value,
        uint256 period
    ) external;

    function lock() external;

    function defaultLockPeriod() external returns (uint256 period);

    function setDefaultLockPeriod(uint256 period) external;

    function lockFor(uint256 period) external;

    function unlock() external;

    function getAssetPrice(address asset) external view returns (uint256);

    function getTvl() external view returns (uint256);

    function isLocked() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

/**
 * @title Interface to access APY.Finance's address registry
 * @author APY.Finance
 * @notice The address registry has two important purposes, one which
 *         is fairly concrete and another abstract.
 *
 *         1. The registry enables components of the APY.Finance system
 *         and external systems to retrieve core addresses reliably
 *         even when the functionality may move to a different
 *         address.
 *
 *         2. The registry also makes explicit which contracts serve
 *         as primary entrypoints for interacting with different
 *         components.  Not every contract is registered here, only
 *         the ones properly deserving of an identifier.  This helps
 *         define explicit boundaries between groups of contracts,
 *         each of which is logically cohesive.
 */
interface IAddressRegistryV2 {
    /**
     * @notice Returns the list of identifiers for core components of
     *         the APY.Finance system.
     * @return List of identifiers
     */
    function getIds() external view returns (bytes32[] memory);

    /**
     * @notice Returns the current address represented by an identifier
     *         for a core component.
     * @param id Component identifier
     * @return The current address represented by an identifier
     */
    function getAddress(bytes32 id) external view returns (address);

    function poolManagerAddress() external view returns (address);

    function tvlManagerAddress() external view returns (address);

    function chainlinkRegistryAddress() external view returns (address);

    function daiPoolAddress() external view returns (address);

    function usdcPoolAddress() external view returns (address);

    function usdtPoolAddress() external view returns (address);

    function mAptAddress() external view returns (address);

    function lpSafeAddress() external view returns (address);

    function oracleAdapterAddress() external view returns (address);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}