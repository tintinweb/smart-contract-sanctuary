/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.7.1;
//SPDX-License-Identifier: UNLICENSED

/* New ERC23 contract interface */

interface IErc223 {
    function totalSupply() external view returns (uint);

    function balanceOf(address who) external view returns (uint);

    function transfer(address to, uint value) external returns (bool ok);
    function transfer(address to, uint value, bytes memory data) external returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/**
* @title Contract that will work with ERC223 tokens.
*/

interface IErc223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes memory _data) external returns (bool ok);
}


interface IErc20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}




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



interface IShyftCacheGraph {
    function getTrustChannelManagerAddress() external view returns(address result);

    function compileCacheGraph(address _identifiedAddress, uint16 _idx) external;

    function getKycCanSend( address _senderIdentifiedAddress,
                            address _receiverIdentifiedAddress,
                            uint256 _amount,
                            uint256 _bip32X_type,
                            bool _requiredConsentFromAllParties,
                            bool _payForDirty) external returns (uint8 result);

    function getActiveConsentedTrustChannelBitFieldForPair( address _senderIdentifiedAddress,
                                                            address _receiverIdentifiedAddress) external returns (uint32 result);

    function getActiveTrustChannelBitFieldForPair(  address _senderIdentifiedAddress,
                                                    address _receiverIdentifiedAddress) external returns (uint32 result);

    function getActiveConsentedTrustChannelRoutePossible(   address _firstAddress,
                                                            address _secondAddress,
                                                            address _trustChannelAddress) external view returns (bool result);

    function getActiveTrustChannelRoutePossible(address _firstAddress,
                                                address _secondAddress,
                                                address _trustChannelAddress) external view returns (bool result);

    function getRelativeTrustLevelOnlyClean(address _senderIdentifiedAddress,
                                            address _receiverIdentifiedAddress,
                                            uint256 _amount,
                                            uint256 _bip32X_type,
                                            bool _requiredConsentFromAllParties,
                                            bool _requiredActive) external returns (int16 relativeTrustLevel, int16 externalTrustLevel);

    function calculateRelativeTrustLevel(   uint32 _trustChannelIndex,
                                            uint256 _foundChannelRulesBitField,
                                            address _senderIdentifiedAddress,
                                            address _receiverIdentifiedAddress,
                                            uint256 _amount,
                                            uint256 _bip32X_type,
                                            bool _requiredConsentFromAllParties,
                                            bool _requiredActive) external returns(int16 relativeTrustLevel, int16 externalTrustLevel);
}



interface IShyftKycContractRegistry  {
    function isShyftKycContract(address _addr) external view returns (bool result);
    function getCurrentContractAddress() external view returns (address);
    function getContractAddressOfVersion(uint _version) external view returns (address);
    function getContractVersionOfAddress(address _address) external view returns (uint256 result);

    function getAllTokenLocations(address _addr, uint256 _bip32X_type) external view returns (bool[] memory resultLocations, uint256 resultNumFound);
    function getAllTokenLocationsAndBalances(address _addr, uint256 _bip32X_type) external view returns (bool[] memory resultLocations, uint256[] memory resultBalances, uint256 resultNumFound, uint256 resultTotalBalance);
}



/// @dev Inheritable constants for token types

contract TokenConstants {

    //@note: reference from https://github.com/satoshilabs/slips/blob/master/slip-0044.md
    // hd chaincodes are 31 bits (max integer value = 2147483647)

    //@note: reference from https://chainid.network/
    // ethereum-compatible chaincodes are 32 bits

    // given these, the final "nativeType" needs to be a mix of both.

    uint256 constant TestNetTokenOffset = 2**128;
    uint256 constant PrivateNetTokenOffset = 2**192;

    uint256 constant ShyftTokenType = 7341;
    uint256 constant EtherTokenType = 60;
    uint256 constant EtherClassicTokenType = 61;
    uint256 constant RootstockTokenType = 30;

    //Shyft Testnets
    uint256 constant BridgeTownTokenType = TestNetTokenOffset + 0;

    //Ethereum Testnets
    uint256 constant GoerliTokenType = 5;
    uint256 constant KovanTokenType = 42;
    uint256 constant RinkebyTokenType = 4;
    uint256 constant RopstenTokenType = 3;

    //Ethereum Classic Testnets
    uint256 constant KottiTokenType = 6;

    //Rootstock Testnets
    uint256 constant RootstockTestnetTokenType = 31;

    //@note:@here:@deploy: need to hardcode test and/or privatenet for deploy on various blockchains
    bool constant IsTestnet = false;
    bool constant IsPrivatenet = false;
}
// pragma experimental ABIEncoderV2;











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


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}









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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}



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











interface IShyftKycContract is IErc20, IErc223ReceivingContract {
    function balanceOf(address tokenOwner) external view override returns (uint balance);
    function totalSupply() external view override returns (uint);
    function transfer(address to, uint tokens) external override returns (bool success);

    function getShyftCacheGraphAddress() external view returns (address result);

    function getNativeTokenType() external view returns (uint256 result);

    function withdrawNative(address payable _to, uint256 _value) external returns (bool ok);
    function withdrawToExternalContract(address _to, uint256 _value, uint256 _gasAmount) external returns (bool ok);
    function withdrawToShyftKycContract(address _shyftKycContractAddress, address _to, uint256 _value) external returns (bool ok);

    function mintBip32X(address _to, uint256 _amount, uint256 _bip32X_type) external;
    function burnFromBip32X(address _account, uint256 _amount, uint256 _bip32X_type) external;

    function migrateFromKycContract(address _to) external payable returns(bool result);
    function updateContract(address _addr) external returns (bool);

    function transferBip32X(address _to, uint256 _value, uint256 _bip32X_type) external returns (bool result);
    function allowanceBip32X(address _tokenOwner, address _spender, uint256 _bip32X_type) external view returns (uint remaining);
    function approveBip32X(address _spender, uint _tokens, uint256 _bip32X_type) external returns (bool success);
    function transferFromBip32X(address _from, address _to, uint _tokens, uint256 _bip32X_type) external returns (bool success);

    function transferFromErc20TokenToBip32X(address _erc20ContractAddress, uint256 _value) external returns (bool ok);
    function withdrawTokenBip32XToErc20(address _erc20ContractAddress, address _to, uint256 _value) external returns (bool ok);

    function getBalanceBip32X(address _identifiedAddress, uint256 _bip32X_type) external view returns (uint256 balance);
    function getTotalSupplyBip32X(uint256 _bip32X_type) external view returns (uint256 balance);

    function getBip32XTypeForContractAddress(address _contractAddress) external view returns (uint256 bip32X_type);

    function kycSend(address _identifiedAddress, uint256 _amount, uint256 _bip32X_type, bool _requiredConsentFromAllParties, bool _payForDirty) external returns (uint8 result);

    function getOnlyAcceptsKycInput(address _identifiedAddress) external view returns (bool result);
    function getOnlyAcceptsKycInputPermanently(address _identifiedAddress) external view returns (bool result);
}



/// @dev | Shyft Core :: Shyft Kyc Contract
///      |
///      | This contract is the nucleus of all of the Shyft stack. This current v1 version has basic functionality for upgrading and connects to the Shyft Cache Graph via Routing for further system expansion.
///      |
///      | It should be noted that all payable functions should utilize revert, as they are dealing with assets.
///      |
///      | "Bip32X" & Synthetics - Here we're using an extension of the Bip32 standard that effectively uses a hash of contract address & "chainId" to allow any erc20/erc223 contract to allow assets to move through Shyft's opt-in compliance rails.
///      | Ex. Ethereum = 60
///      | Shyft Network = 7341
///      |
///      | This contract is built so that when the totalSupply is asked for, much like transfer et al., it only references the ShyftTokenType. For getting the native balance of any specific Bip32X token, you'd call "getTotalSupplyBip32X" with the proper contract address.
///      |
///      | "Auto Migration"
///      | This contract was built with the philosophy that while there needs to be *some* upgrade path, unilaterally changing the existing contract address for Users is a bad idea in practice. Instead, we use a versioning system with the ability for users to set flags to automatically upgrade their liquidity on send into this particular contract, to any other contracts that have been updated so far (in a recursive manner).
///      |
///      | Auto-Migration of assets flow:
///      | 1. registry contract is set up
///      | 2. upgrade is called by registry contract
///      | 3. calls to fallback looks to see if upgrade is set
///      | 4. if so it asks the registry for the current contract address
///      | 5. it then uses the "migrateFromKycContract", which on the receiver's end will update the _to address passed in with the progression and now has the value from the "migrateFromKycContract"'s payable and thus the native fuel, to back the token increase to the _to's account.
///      |
///      |
///      | What's Next (V2 notes):
///      |
///      | "Shyft Safe" - timelocked assets that will work with Byfrost
///      | "Shyft Byfrost" - economic finality bridge infrastructure
///      |
///      | Compliance Channels:
///      | Addresses that only accept kyc input should be able to receive packages by the bridge that are only kyc'd across byfrost.
///      | Ultimate accountability chain could be difficult, though a hash map of critical ipfs resources of chain data could suffice.
///      | This would be the same issue as data accountability by trying to leverage multiple chains for data sales as well.

contract ShyftKycContract is IShyftKycContract, TokenConstants, AccessControl {
    /// @dev Event for migration to another shyft kyc contract (of higher or equal version).
    event EVT_migrateToKycContract(address indexed updatedShyftKycContractAddress, uint256 updatedContractBalance, address indexed kycContractAddress, address indexed to, uint256 _amount);
    /// @dev Event for migration to another shyft kyc contract (from lower or equal version).
    event EVT_migrateFromContract(address indexed sendingKycContract, uint256 totalSupplyBip32X, uint256 msgValue, uint256 thisBalance);

    /// @dev Event for receipt of native assets.
    event EVT_receivedNativeBalance(address indexed _from, uint256 _value);

    /// @dev Event for withdraw to address.
    event EVT_WithdrawToAddress(address _from, address _to, uint256 _value);
    /// @dev Event for withdraw to external contract (w/ Erc223 fallbacks).
    event EVT_WithdrawToExternalContract(address _from, address _to, uint256 _value);
    /// @dev Event for withdraw to a specific shyft smart contract.
    event EVT_WithdrawToShyftKycContract(address _from, address _to, uint256 _value);

    /// @dev Event for transfer and minting of Bip32X type assets.
    event EVT_TransferAndMintBip32X(address contractAddress, address msgSender, uint256 value, uint256 indexed bip32X_type);

    /// @dev Event for transfer and burning of Bip32X type assets.
    event EVT_TransferAndBurnBip32X(address contractAddress, address msgSender, address to, uint256 value, uint256 indexed bip32X_type);

    /// @dev Event for transfer of Bip32X type.
    event EVT_TransferBip32X(address indexed from, address indexed to, uint256 tokens, uint256 indexed bip32X_type);

    /// @dev Event for approval of Bip32X type.
    event EVT_ApprovalBip32X(address indexed tokenOwner, address indexed spender, uint256 tokens, uint256 indexed bip32X_type);

    /* ERC223 events */
    /// @dev Event for Erc223-based Token Fallback.
    event EVT_Erc223TokenFallback(address _from, uint256 _value, bytes _data);

    /* v1 Upgrade events */
    /// @dev Event for setting of emergency responder.
    event EVT_setV1EmergencyResponder(address _emergencyResponder);

    /// @dev Event for redemption of incorrectly sent assets.
    event EVT_redeemIncorrectlySentAsset(address indexed _destination, uint256 _amount);

    /// @dev Event for upgrading of assets from the v1 Contract
    event EVT_UpgradeFromV1(address indexed _originAddress, address indexed _userAddress, uint256 _value);

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Mapping of total supply specific bip32x assets.
    mapping(uint256 => uint256) totalSupplyBip32X;
    /// @dev Mapping of users to their balances of specific bip32x assets.
    mapping(address => mapping(uint256 => uint256)) balances;
    /// @dev Mapping of users to users with amount of allowance set for specific bip32x assets.
    mapping(address => mapping(address => mapping(uint256 => uint256))) allowed;

    /// @dev Mapping of users to whether they have set auto-upgrade enabled.
    mapping(address => bool) autoUpgradeEnabled;
    /// @dev Mapping of users to whether they Accepts Kyc Input only.
    mapping(address => bool) onlyAcceptsKycInput;
    /// @dev Mapping of users to whether their Accepts Kyc Input option is locked permanently.
    mapping(address => bool) lockOnlyAcceptsKycInputPermanently;

    /// @dev mutex lock, prevent recursion in functions that use external function calls
    bool locked;

    /// @dev Whether there has been an upgrade from this contract.
    bool public hasBeenUpdated;
    /// @dev The address of the next upgraded Shyft Kyc Contract.
    address public updatedShyftKycContractAddress;
    /// @dev The address of the Shyft Kyc Registry contract.
    address public shyftKycContractRegistryAddress;

    /// @dev The address of the Shyft Cache Graph contract.
    address public shyftCacheGraphAddress = address(0);

    /// @dev The signature for triggering 'tokenFallback' in erc223 receiver contracts.
    bytes4 constant shyftKycContractSig = bytes4(keccak256("fromShyftKycContract(address,address,uint256,uint256)")); // function signature

    /// @dev The origin of the Byfrost link, if this contract is used as such. follows chainId.
    bool public byfrostOrigin;
    /// @dev Flag for whether the Byfrost state has been set.
    bool public setByfrostOrigin;

    /// @dev The owner of this contract.
    address public owner;
    /// @dev The native Bip32X type of this network. Ethereum is 60, Shyft is 7341, etc.
    uint256 nativeBip32X_type;

    /// @dev The name of the minter role for implementing AccessControl
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    //@note:@v1Upgrade:
    /// @dev total number of SHFT tokens that have been upgraded from v1.
    uint256 public v1TotalUpgradeAmount;

    /// @dev emergency responder address - able to **only** send back tokens incorrectly sent via the erc20-based transfer(address,uint256) vs the erc223-based (actual "migration" of the SHFT tokens) to the v1 contract address.
    address public emergencyResponder;

    /// @dev "Machine" (autonomous smart contract) Consent Helper address - this is the one that is able to set specific contracts to accept only kyc input

    address public machineConsentHelperAddress;

    /// @param _nativeBip32X_type The native Bip32X type of this network. Ethereum is 60, Shyft is 7341, etc.
    /// @dev Invoke the constructor for ShyftSafe, which sets the owner and nativeBip32X_type class variables

    /// @dev This contract uses the AccessControl library (for minting tokens only by designated minter).
    /// @dev The account that deploys the contract will be granted the default admin role
    /// @dev which will let it grant minter roles to other accounts.
    /// @dev After deploying the contract, the the deployer should grant the minter role to a desired address
    /// @dev by calling `grantRole(bytes32 role, address account)`
    /// @dev Revoking the role is done by calling `revokeRole(bytes32 role, address account)`

    constructor(uint256 _nativeBip32X_type) {
        owner = msg.sender;

        nativeBip32X_type = _nativeBip32X_type;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Gets the native bip32x token (should correspond to "chainid")
    /// @return result the native bip32x token (should correspond to "chainid")

    function getNativeTokenType() public override view returns (uint256 result) {
        return nativeBip32X_type;
    }

    /// @param _tokenAmount The amount of tokens to be allocated.
    /// @param _bip32X_type The Bip32X type that represents the synthetic tokens that will be allocated.
    /// @param _distributionContract The public address of the distribution contract, that the tokens are allocated for.
    /// @dev Set by the owner, this functions sets it such that this contract was deployed on a Byfrost arm of the Shyft Network (on Ethereum for example). With this is a token grant that this contract should make to a specific distribution contract (ie. in the case of the initial Shyft Network launch, we have a small allocation originating on the Ethereum network).
    /// @notice | for created kyc contracts on other chains, they can be instantiated with specific bip32X_type amounts
    ///         | (for example, the shyft distribution contract on eth vs. shyft native)
    ///         |  '  uint256 bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, _erc20ContractAddress)));
    ///         |  '  bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, msg.sender)));
    ///         | the bip32X_type is formed by the hash of the native bip32x type (which is unique per-platform, as it depends on
    ///         | the deployed contract address) - byfrost only touches non-replay networks.
    ///         | so the formula for the bip32X_type would be HASH [ byfrost main chain bip32X_type ] & [ byfrost main chain kyc contract address ]
    ///         | these minted tokens are given to the distribution contract for further distribution. This is all this contract
    ///         | needs to know about the distribution contract.
    /// @return result
    ///    | 2 = set byfrost as origin
    ///    | 1 = already set byfrost origin
    ///    | 0 = not owner

    function setByfrostNetwork(uint256 _tokenAmount, uint256 _bip32X_type, address _distributionContract) public returns (uint8 result) {
        if (msg.sender == owner) {
            if (setByfrostOrigin == false) {
                byfrostOrigin = true;
                setByfrostOrigin = true;

                balances[_distributionContract][_bip32X_type] = balances[_distributionContract][_bip32X_type].add(_tokenAmount);
                totalSupplyBip32X[_bip32X_type] = totalSupplyBip32X[_bip32X_type].add(_tokenAmount);

                //set byfrost as origin
                return 2;
            } else {
                //already set
                return 1;
            }
        } else {
            //not owner
            return 0;
        }
    }

    /// @dev Set by the owner, this function sets it such that this contract was deployed on the primary Shyft Network. No further calls to setByfrostNetwork may be made.
    /// @return result
    ///    | 2 = set primary network
    ///    | 1 = already set byfrost origin
    ///    | 0 = not owner

    function setPrimaryNetwork() public returns (uint8 result) {
        if (msg.sender == owner) {
            if (setByfrostOrigin == false) {
                setByfrostOrigin = true;

                //set primary network
                return 2;
            } else {
                //already set byfrost origin
                return 1;
            }
        } else {
            //not owner
            return 0;
        }
    }

    /// @dev Removes the owner (creator of this contract)'s control completely. Functions such as linking the registry & cachegraph (& shyftSafe's setBridge), and importantly initializing this as a byfrost contract, are triggered by the owner, and as such a setting phase and afterwards triggering this function could be seen as a completely appropriate workflow.
    /// @return true if the owner is removed successfully
    function removeOwner() public returns (bool) {
        require(msg.sender == owner, "not owner");

        owner = address(0);
        return true;
    }

    /// @param _shyftCacheGraphAddress The smart contract address for the Shyft CacheGraph that should be linked.
    /// @dev Links Shyft CacheGraph to this contract's function flow.
    /// @return result
    ///    | 0: not owner
    ///    | 1: set shyft cache graph address

    function setShyftCacheGraphAddress(address _shyftCacheGraphAddress) public returns (uint8 result) {
        require(_shyftCacheGraphAddress != address(0), "address cannot be zero");
        if (owner == msg.sender) {
            shyftCacheGraphAddress = _shyftCacheGraphAddress;

            //cacheGraph contract address set
            return 1;
        } else {
            //not owner
            return 0;
        }
    }

    function getShyftCacheGraphAddress() public view override returns (address result) {
        return shyftCacheGraphAddress;
    }

    //---------------- Cache Graph Utilization ----------------//

    /// @param _identifiedAddress The public address for the recipient to send assets (tokens) to.
    /// @param _amount The amount of assets that will be sent.
    /// @param _bip32X_type The bip32X type of the assets that will be sent. These are synthetic (wrapped) assets, based on atomic locking.
    /// @param _requiredConsentFromAllParties Whether to match the routing algorithm on the "consented" layer which indicates 2 way buy in of counterparty's attestation(s)
    /// @param _payForDirty Whether the sender will pay the additional cost to unify a cachegraph's relationships (if not, it will not complete).
    /// @dev | Performs a "kyc send", which is an automatic search between addresses for counterparty relationships within Trust Channels (whos rules dictate accessibility for auditing/enforcement/jurisdiction/etc.). If there is a match, the designated amount of assets is sent to the recipient.
    ///      | As there are accessor methods to check whether or not the counterparty's cachegraph is "dirty", there is little need to pass a "true" unless the transaction is critical (eg. DeFi atomic flash wrap) and there is a chance that there will need to be a unification pass before the transaction can pass with full assurety.
    /// @notice | If the recipient has flags set to indicate that they *only* want to receive assets from kyc sources, *all* of the regular transfer functions will block except this one, and this one only passes on success.
    /// @return result
    ///    | 0 = not enough balance to send
    ///    | 1 = consent required
    ///    | 2 = transfer cannot be processed due to transfer rules
    ///    | 3 = successful transfer

    function kycSend(address _identifiedAddress, uint256 _amount, uint256 _bip32X_type, bool _requiredConsentFromAllParties, bool _payForDirty) public override returns (uint8 result) {
        if (balances[msg.sender][_bip32X_type] >= _amount) {
            if (onlyAcceptsKycInput[_identifiedAddress] == false || (onlyAcceptsKycInput[_identifiedAddress] == true && _requiredConsentFromAllParties == true)) {
                IShyftCacheGraph shyftCacheGraph = IShyftCacheGraph(shyftCacheGraphAddress);

                uint8 kycCanSendResult = shyftCacheGraph.getKycCanSend(msg.sender, _identifiedAddress, _amount, _bip32X_type, _requiredConsentFromAllParties, _payForDirty);

                //getKycCanSend return 3 = can transfer successfully
                if (kycCanSendResult == 3) {
                    balances[msg.sender][_bip32X_type] = balances[msg.sender][_bip32X_type].sub(_amount);
                    balances[_identifiedAddress][_bip32X_type] = balances[_identifiedAddress][_bip32X_type].add(_amount);

                    //successful transfer
                    return 3;
                } else {
                    //transfer cannot be processed due to transfer rules
                    return 2;
                }
            } else {
                //consent required
                return 1;
            }
        } else {
            //not enough balance to send
            return 0;
        }
    }

    //---------------- Shyft KYC balances, fallback, send, receive, and withdrawal ----------------//


    /// @dev mutex locks transactions ordering so that multiple chained calls cannot complete out of order.

    modifier mutex() {
        require(locked == false, "mutex failed :: already locked");

        locked = true;
        _;
        locked = false;
    }

    /// @param _addr The Shyft Kyc Contract Registry address to set to.
    /// @dev Upgrades the contract. Can only be called by a pre-set Shyft Kyc Contract Registry contract. Can only be called once.
    /// @return returns true if the function passes, otherwise reverts if the message sender is not the shyft kyc registry contract.

    function updateContract(address _addr) public override returns (bool) {
        require(msg.sender == shyftKycContractRegistryAddress, "message sender must by registry contract");
        require(hasBeenUpdated == false, "contract has already been updated");
        require(_addr != address(0), "new kyc contract address cannot equal zero");

        hasBeenUpdated = true;
        updatedShyftKycContractAddress = _addr;
        return true;
    }

    /// @param _addr The Shyft Kyc Contract Registry address to set to.
    /// @dev Sets the Shyft Kyc Contract Registry address, so this contract can be upgraded.
    /// @return returns true if the function passes, otherwise reverts if the message sender is not the owner (deployer) of this contract, or the registry is zero, or the registry has already been set.

    function setShyftKycContractRegistryAddress(address _addr) public returns (bool) {
        require(msg.sender == owner, "not owner");
        require(_addr != address(0), "kyc registry address cannot equal zero");
        require(shyftKycContractRegistryAddress == address(0), "kyc registry address must not have already been set");

        shyftKycContractRegistryAddress = _addr;
        return true;
    }

    /// @param _to The destination address to withdraw to.
    /// @dev Withdraws all assets of this User to a specific address (only native assets, ie. Ether on Ethereum, Shyft on Shyft Network).
    /// @return balance the number of tokens of that specific bip32x type in the user's account

    function withdrawAllNative(address payable _to) public returns (uint) {
        uint _bal = balances[msg.sender][nativeBip32X_type];
        withdrawNative(_to, _bal);
        return _bal;
    }

    /// @param _identifiedAddress The address of the User.
    /// @param _bip32X_type The Bip32X type to check.
    /// @dev Gets balance for Shyft KYC token type & synthetics for a specfic user.
    /// @return balance the number of tokens of that specific bip32x type in the user's account

    function getBalanceBip32X(address _identifiedAddress, uint256 _bip32X_type) public view override returns (uint256 balance) {
        return balances[_identifiedAddress][_bip32X_type];
    }

    /// @param _bip32X_type The Bip32X type to check.
    /// @dev Gets the total supply for a specific bip32x token.
    /// @return balance the number of tokens of that specific bip32x type in this contract

    function getTotalSupplyBip32X(uint256 _bip32X_type) public view override returns (uint256 balance) {
        return totalSupplyBip32X[_bip32X_type];
    }

    /// @param _contractAddress The contract address to get the bip32x type from.
    /// @dev Gets the Bip32X Type for a specific contract address.
    /// @notice Doesn't check for contract status on the address (bytecode in contract) as that is super expensive for this form of call, so this *will* return a result for a regular non-contract address as well.
    /// @return bip32X_type the bip32x type for this specific contract

    function getBip32XTypeForContractAddress(address _contractAddress) public view override returns (uint256 bip32X_type) {
        return uint256(keccak256(abi.encodePacked(nativeBip32X_type, _contractAddress)));
    }

    /// @dev This fallback function applies value to nativeBip32X_type Token (Ether on Ethereum, Shyft on Shyft Network, etc). It also uses auto-upgrade logic so that users can automatically have their coins in the latest wallet (if everything is opted in across all contracts by the user).

    receive() external payable {
        //@note: this is the auto-upgrade path, which is an opt-in service to the users to be able to send any or all tokens
        // to an upgraded kycContract.
        if (hasBeenUpdated && autoUpgradeEnabled[msg.sender]) {
            //@note: to prevent tokens from ever getting "stuck", this contract can only send to itself in a very
            // specific manner.
            //
            // for example, the "withdrawNative" function will output native fuel to a destination.
            // If it was sent to this contract, this function will trigger and know that the msg.sender is
            // the originating kycContract.

            if (msg.sender != address(this)) {
                // stop the process if the message sender has set a flag that only allows kyc input
                require(onlyAcceptsKycInput[msg.sender] == false, "must send to recipient via trust channel");

                // burn tokens in this contract
                uint256 existingSenderBalance = balances[msg.sender][nativeBip32X_type];

                balances[msg.sender][nativeBip32X_type] = 0;
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(existingSenderBalance);

                //~70k gas for the contract "call"
                //and 90k gas for the value transfer within this.
                // total = ~160k+checks gas to perform this transaction.
                bool didTransferSender = migrateToKycContract(updatedShyftKycContractAddress, msg.sender, existingSenderBalance.add(msg.value));

                if (didTransferSender == true) {

                } else {
                    //@note: reverts since a transactional event has occurred.
                    revert("error in migration to kyc contract [user-origin]");
                }
            } else {
                //****************************************************************************************************//
                //@note: This *must* be the only route where tx.origin has to matter.
                //****************************************************************************************************//

                // duplicating the logic here for higher deploy cost vs. lower transactional costs (consider user costs
                // where all users would want to migrate)

                // burn tokens in this contract
                uint256 existingOriginBalance = balances[tx.origin][nativeBip32X_type];

                balances[tx.origin][nativeBip32X_type] = 0;
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(existingOriginBalance);

                //~70k gas for the contract "call"
                //and 90k gas for the value transfer within this.
                // total = ~160k+checks gas to perform this transaction.

                bool didTransferOrigin = migrateToKycContract(updatedShyftKycContractAddress, tx.origin, existingOriginBalance.add(msg.value));

                if (didTransferOrigin == true) {

                } else {
                    //@note: reverts since a transactional event has occurred.
                    revert("error in migration to updated contract [self-origin]");
                }
            }
        } else {
            //@note: never accept this contract sending raw value to this fallback function, unless explicit cases
            // have been met.
            //@note: public addresses do not count as kyc'd addresses
            if (msg.sender != address(this) && onlyAcceptsKycInput[msg.sender] == true) {
                revert("must send to recipient via trust channel");
            }

            balances[msg.sender][nativeBip32X_type] = balances[msg.sender][nativeBip32X_type].add(msg.value);
            totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].add(msg.value);

            emit EVT_receivedNativeBalance(msg.sender, msg.value);
        }
    }

    /// @param _kycContractAddress The Shyft Kyc Contract to migrate to.
    /// @param _to The user's address to migrate to
    /// @param _amount The amount of tokens to migrate.
    /// @dev Internal function to migrates the user's assets to another Shyft Kyc Contract. This function is called from the fallback to allocate tokens properly to the upgraded contract.
    /// @return result
    ///    | true = transfer complete
    ///    | false = transfer did not complete

    function migrateToKycContract(address _kycContractAddress, address _to, uint256 _amount) internal returns (bool result) {

        // call upgraded contract so that tokens are forwarded to the new contract under _to's account.
        IShyftKycContract updatedKycContract = IShyftKycContract(updatedShyftKycContractAddress);

        emit EVT_migrateToKycContract(updatedShyftKycContractAddress, address(updatedShyftKycContractAddress).balance, _kycContractAddress, _to, _amount);

        // sending to ShyftKycContracts only; migrateFromKycContract uses ~75830 - 21000 gas to execute,
        // with a registry lookup, so adding in a bit more for future contracts.
        bool transferResult = updatedKycContract.migrateFromKycContract{value: _amount, gas: 100000}(_to);

        if (transferResult == true) {
            //transfer complete
            return true;
        } else {
            //transfer did not complete
            return false;
        }
    }

    /// @param _to The user's address to migrate to.
    /// @dev | Migrates the user's assets from another Shyft Kyc Contract. The following conditions have to pass:
    ///      | a) message sender is a shyft kyc contract,
    ///      | b) sending shyft kyc contract is not of a later version than this one
    ///      | c) user on this shyft kyc contract have no restrictions on only accepting KYC input (will ease in v2)
    /// @return result
    ///    | true = migration completed successfully
    ///    | [revert] = reverts on any situation that fails on the above parameters

    function migrateFromKycContract(address _to) public payable override returns (bool result) {
        //@note: doing a very strict check to make sure no unwanted additional tokens can be created.
        // the way this work is that this.balance is updated *before* this code runs.
        // thus, as long as we've always updated totalSupplyBip32X when we've created or destroyed tokens, we'll
        // always be able to check against this.balance.

        //regarding an issue found:
        //"Smart contracts, though they may not expect it, can receive ether forcibly, or could be deployed at an
        // address that already received some ether."
        // from:
        // "require(totalSupplyBip32X[nativeBip32X_type].add(msg.value) == address(this).balance);"
        //
        // the worst case scenario in some non-atomic calls (without going through withdrawToShyftKycContract for example)
        // is that someone self-destructs a contract and forcibly sends ether to this address, before this is triggered by
        // someone using it.

        // solution:
        // we cannot do a simple equality check for address(this).balance. instead, we use an less-than-or-equal-to, as
        // when the worst case above occurs, the total supply of this synthetic will be less than the balance within this
        // contract.

        require(totalSupplyBip32X[nativeBip32X_type].add(msg.value) <= address(this).balance, "could not migrate funds due to insufficient backing balance");

        bool doContinue = true;

        IShyftKycContractRegistry contractRegistry = IShyftKycContractRegistry(shyftKycContractRegistryAddress);

        // check if only using a known kyc contract communication cycle, then verify the message sender is a kyc contract.
        if (contractRegistry.isShyftKycContract(address(msg.sender)) == false) {
            doContinue = false;
        } else {
            // only allow migration from equal or older versions of Shyft Kyc Contracts, via registry lookup.
            if (contractRegistry.getContractVersionOfAddress(address(msg.sender)) > contractRegistry.getContractVersionOfAddress(address(this))) {
                doContinue = false;
            }
        }

        // block transfers if the recipient only allows kyc input
        if (onlyAcceptsKycInput[_to] == true) {
            doContinue = false;
        }

        if (doContinue == true) {
            emit EVT_migrateFromContract(msg.sender, totalSupplyBip32X[nativeBip32X_type], msg.value, address(this).balance);

            balances[_to][nativeBip32X_type] = balances[_to][nativeBip32X_type].add(msg.value);
            totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].add(msg.value);

            //transfer complete
            return true;
        } else {
            //kyc contract not in registry
            //@note: transactional event has occurred, so revert() is necessary
            revert("kyc contract is not in registry, or must use trust channels");
            //return false;
        }
    }

    /// @param _onlyAcceptsKycInputValue Whether to accept only Kyc Input.
    /// @dev Sets whether to accept only Kyc Input in the future.
    /// @return result
    ///    | true = updated onlyAcceptsKycInput
    ///    | false = cannot modify onlyAcceptsKycInput, as it is locked permanently by user

    function setOnlyAcceptsKycInput(bool _onlyAcceptsKycInputValue) public returns (bool result) {
        if (lockOnlyAcceptsKycInputPermanently[msg.sender] == false) {
            onlyAcceptsKycInput[msg.sender] = _onlyAcceptsKycInputValue;

            //updated onlyAcceptsKycInput
            return true;
        } else {

            //cannot modify onlyAcceptsKycInput, as it is locked permanently by user
            return false;
        }
    }

    /// @dev Gets whether the user has set Accepts Kyc Input.
    /// @return result
    ///    | true = set lock for onlyAcceptsKycInput
    ///    | false = already set lock for onlyAcceptsKycInput

    function setLockOnlyAcceptsKycInputPermanently() public returns (bool result) {
        if (lockOnlyAcceptsKycInputPermanently[msg.sender] == false) {
            lockOnlyAcceptsKycInputPermanently[msg.sender] = true;
            //set lock for onlyAcceptsKycInput
            return true;
        } else {
            //already set lock for onlyAcceptsKycInput
            return false;
        }
    }

    /// @param _machineConsentHelperAddress The address of the Machine Consent Helper.
    /// @dev Sets the Machine Consent Helper address. This address can lock kyc inputs for contracts permanently, for use in compliant DeFi pools.
    /// @return result
    ///    | true = set machine consent helper address
    ///    | false = cannot set machine consent helper address, either not the Owner, the address input is 0x0, or the machine helper address has already been set by the Owner.

    function setMachineConsentHelperAddress(address _machineConsentHelperAddress) public returns (bool result) {
        require(msg.sender == owner, "not owner");
        require(_machineConsentHelperAddress != address(0), "machine consent helper address cannot equal zero");
        require(machineConsentHelperAddress == address(0), "machine consent helper address must not have already been set");

        machineConsentHelperAddress = _machineConsentHelperAddress;

        // set machine consent helper address
        return true;
    }

    /// @param _contractAddress The contract address to lock only accepts kyc input permanently
    /// @dev Sets the Machine Consent Helper address. This address can lock kyc inputs for contracts permanently, for use in compliant DeFi pools.
    /// @return result
    ///    | true = set only accepts kyc input permanently for the contract
    ///    | false = not a contract address, or no machine (autonomous smart contract) consent helper found

    function lockContractToOnlyAcceptsKycInputPermanently(address _contractAddress) public returns (bool result) {
        // check for machine consent helper as the sender.
        if (msg.sender == machineConsentHelperAddress) {
            // make sure this is a contract address (has code in it)
            if (isContractAddress(_contractAddress)) {
                // forces only accepting KYC input from this point on.
                onlyAcceptsKycInput[_contractAddress] = true;
                lockOnlyAcceptsKycInputPermanently[_contractAddress] = true;

                // set only accepts kyc input permanently for the contract
                return true;
            } else {
                // not a contract address
                return false;
            }
        } else {
            // no machine consent helper found
            return false;
        }
    }

    /// @param _identifiedAddress The public address to check.
    /// @dev Gets whether the user has set Accepts Kyc Input.
    /// @return result whether the user has set Accepts Kyc Input

    function getOnlyAcceptsKycInput(address _identifiedAddress) public view override returns (bool result) {
        return onlyAcceptsKycInput[_identifiedAddress];
    }

    /// @param _identifiedAddress The public address to check.
    /// @dev Gets whether the user has set Accepts Kyc Input permanently (whether on or off).
    /// @return result whether the user has set Accepts Kyc Input permanently (whether on or off)

    function getOnlyAcceptsKycInputPermanently(address _identifiedAddress) public view override returns (bool result) {
        return lockOnlyAcceptsKycInputPermanently[_identifiedAddress];
    }

    //---------------- Token Upgrades ----------------//


    //****************************************************************************************************************//
    //@note: instead of explicitly returning, assign return value to variable allows the code after the _;
    // in the mutex modifier to be run!
    //****************************************************************************************************************//

    /// @param _value The amount of tokens to upgrade.
    /// @dev Upgrades the user's tokens by sending them to the next contract (which will do the same). Sets auto upgrade for the user as well.
    /// @return result
    ///    | 3 = withdrew correctly
    ///    | 2 = could not withdraw
    ///    | 1 = not enough balance
    ///    | 0 = contract has not been updated

    function upgradeNativeTokens(uint256 _value) mutex public returns (uint256 result) {
        //check if it's been updated
        if (hasBeenUpdated == true) {
            //make sure the msg.sender has enough synthetic fuel to transfer
            if (balances[msg.sender][nativeBip32X_type] >= _value) {
                autoUpgradeEnabled[msg.sender] = true;

                //then proceed to send to address(this) to initiate the autoUpgrade
                // to the new contract.
                bool withdrawResult = _withdrawToShyftKycContract(updatedShyftKycContractAddress, msg.sender, _value);
                if (withdrawResult == true) {
                    //withdrew correctly
                    result = 3;
                } else {
                    //could not withdraw
                    result = 2;
                }
            } else {
                //not enough balance
                result = 1;
            }
        } else {
            //contract has not been updated
            result = 0;
        }
    }

    /// @param _autoUpgrade Whether the tokens should be automatically upgraded when sent to this contract.
    /// @dev Sets auto upgrade for the message sender, for fallback functionality to upgrade tokens on receipt. The only reason a user would want to call this function is to modify behaviour *after* this contract has been updated, thus allowing choice.

    function setAutoUpgrade(bool _autoUpgrade) public {
        autoUpgradeEnabled[msg.sender] = _autoUpgrade;
    }

    function isContractAddress(address _potentialContractAddress) internal returns (bool result) {
        uint codeLength;

        //retrieve the size of the code on target address, this needs assembly
        assembly {
            codeLength := extcodesize(_potentialContractAddress)
        }

        //check to see if there's any code (contract) or not.
        if (codeLength == 0) {
            return false;
        } else {
            return true;
        }
    }

    //---------------- Native withdrawal / transfer functions ----------------//

    /// @param _to The destination payable address to send to.
    /// @param _value The amount of tokens to transfer.
    /// @dev Transfers native tokens (based on the current native Bip32X type, ex Shyft = 7341, Ethereum = 1) to the user's wallet.
    /// @notice 30k gas limit for transfers.
    /// @return ok
    ///    | true = native tokens withdrawn properly
    ///    | false = the user does not have enough balance, or found a smart contract address instead of a payable address.

    function withdrawNative(address payable _to, uint256 _value) mutex public override returns (bool ok) {
        if (balances[msg.sender][nativeBip32X_type] >= _value) {
            //makes sure it's sending to a native (non-contract) address
            if (isContractAddress(_to) == false) {
                balances[msg.sender][nativeBip32X_type] = balances[msg.sender][nativeBip32X_type].sub(_value);
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(_value);

                //@note: this is going to a regular account. the existing balance has already been reduced,
                // and as such the only thing to do is to send the actual Shyft fuel (or Ether, etc) to the
                // target address.

                _to.transfer(_value);

                emit EVT_WithdrawToAddress(msg.sender, _to, _value);
                ok = true;
            } else {
                ok = false;
            }
        } else {
            ok = false;
        }
    }

    /// @param _to The destination smart contract address to send to.
    /// @param _value The amount of tokens to transfer.
    /// @param _gasAmount The amount of gas for the transfer (>30k is a different receiver gas type beyond normal accounting + 1 event)
    /// @dev Transfers SHFT tokens to another external contract.
    /// @notice 30k gas limit for transfers should be used unless there are specific reasons otherwise.
    /// @return ok
    ///    | true = tokens withdrawn properly to another contract
    ///    | false = the user does not have enough balance, or not a contract address

    function withdrawToExternalContract(address _to, uint256 _value, uint256 _gasAmount) mutex public override returns (bool ok) {
        if (balances[msg.sender][nativeBip32X_type] >= _value) {
            if (isContractAddress(_to)) {
                balances[msg.sender][nativeBip32X_type] = balances[msg.sender][nativeBip32X_type].sub(_value);
                totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(_value);

                //this will fail when sending to contracts with fallback functions that consume more than 20000 gas

                (bool success, ) = _to.call{value: _value, gas: _gasAmount}("");

                if (success == true) {
                    emit EVT_WithdrawToExternalContract(msg.sender, _to, _value);

                    // tokens withdrawn properly to another contract
                    ok = true;
                } else {
                    //@note:@here: needs revert() due to asset transactions already having occurred
                    revert("could not withdraw to an external contract");
                    //ok = false;
                }
            } else {
                // not a contract address
                ok = false;
            }
        } else {
            // user does not have enough balance
            ok = false;
        }
    }

    /// @param _shyftKycContractAddress The address of the Shyft Kyc Contract that is being send to.
    /// @param _to The destination address to send to.
    /// @param _value The amount of tokens to transfer.
    /// @dev Transfers SHFT tokens to another Shyft Kyc contract.
    /// @notice 120k gas limit for transfers.
    /// @return ok
    ///    | true = tokens withdrawn properly to another Kyc Contract.
    ///    | false = the user does not have enough balance, not a valid ShyftKycContract via registry lookup, or not a correct shyft contract address, or receiver only accepts kyc input.

    function withdrawToShyftKycContract(address _shyftKycContractAddress, address _to, uint256 _value) mutex public override returns (bool ok) {
        return _withdrawToShyftKycContract(_shyftKycContractAddress, _to, _value);
    }

    function _withdrawToShyftKycContract(address _shyftKycContractAddress, address _to, uint256 _value) internal returns (bool ok) {
        if (balances[msg.sender][nativeBip32X_type] >= _value) {
            if (isContractAddress(_shyftKycContractAddress) == true) {
                IShyftKycContractRegistry contractRegistry = IShyftKycContractRegistry(shyftKycContractRegistryAddress);

                // check if only using a known kyc contract communication cycle, then verify the message sender is a kyc contract.
                if (contractRegistry.isShyftKycContract(_shyftKycContractAddress) == true) {
                    IShyftKycContract receivingShyftKycContract = IShyftKycContract(_shyftKycContractAddress);

                    if (receivingShyftKycContract.getOnlyAcceptsKycInput(_to) == false) {
                        balances[msg.sender][nativeBip32X_type] = balances[msg.sender][nativeBip32X_type].sub(_value);
                        totalSupplyBip32X[nativeBip32X_type] = totalSupplyBip32X[nativeBip32X_type].sub(_value);

                        // sending to ShyftKycContracts only; migrateFromKycContract uses ~75830 - 21000 gas to execute,
                        // with a registry lookup. Adding 50k more just in case there are other checks in the v2.
                        if (receivingShyftKycContract.migrateFromKycContract{gas: 120000, value: _value}(_to) == false) {
                            revert("could not migrate from shyft kyc contract");
                        }

                        emit EVT_WithdrawToShyftKycContract(msg.sender, _to, _value);

                        ok = true;
                    } else {
                        // receiver only accepts kyc input
                        ok = false;
                    }
                } else {
                    // is not a valid ShyftKycContract via registry lookup.
                    ok = false;
                }
            } else {
                // not a smart contract
                ok = false;
            }
        } else {
            ok = false;
        }
    }

    //---------------- ERC 223 receiver ----------------//

    /// @param _from The address of the origin.
    /// @param _value The address of the recipient.
    /// @param _data The bytes data of any ERC223 transfer function.
    /// @dev Token fallback method to receive assets. ERC223 functionality. This version does allow for one specific (origin) contract to transfer tokens to it.
    /// @return ok returns true if the checks pass and there are enough allowed + actual tokens to transfer to the recipient.

    function tokenFallback(address _from, uint _value, bytes memory _data) mutex public override returns (bool ok) {
        // block transfers if the recipient only allows kyc input, check other factors
        require(onlyAcceptsKycInput[_from] == false, "recipient address must not require only kyc'd input");

        IShyftKycContractRegistry contractRegistry = IShyftKycContractRegistry(shyftKycContractRegistryAddress);

        // if kyc registry exists, check if only using a known kyc contract communication cycle, then verify the message
        // sender is a kyc contract.
        if (shyftKycContractRegistryAddress != address(0) && contractRegistry.isShyftKycContract(address(msg.sender)) == true) {
            if (contractRegistry.getContractVersionOfAddress(address(msg.sender)) == 0) {
                // 1: the msg.sender will be the smart contract of origin.
                // 2: the sender has sent to this address.
                // 3: the only data we have is the "from" that is unique, this is the initial msg.sender of the transaction chain.
                // 4: consider the main purpose of the send to be upgrading anyhow
                // 5: this contract will now have a balance in the other one, which it never needs to move (very important if there were issues with the act of person<->person transfer).
                // 6: this contract will then *mint* the balance into being, into the sender's account.

                bytes4 tokenSig;

                //make sure we have enough bytes to determine a signature
                if (_data.length >= 4) {
                    tokenSig = bytes4(uint32(bytes4(bytes1(_data[3])) >> 24) + uint32(bytes4(bytes1(_data[2])) >> 16) + uint32(bytes4(bytes1(_data[1])) >> 8) + uint32(bytes4(bytes1(_data[0]))));
                }

                // reject the transaction if the token signature is a "withdrawToExternalContract" event from the v0 contract.
                // as this update has zero issues
                if (tokenSig != shyftKycContractSig) {
                    balances[_from][ShyftTokenType] = balances[_from][ShyftTokenType].add(_value);
                    totalSupplyBip32X[ShyftTokenType] = totalSupplyBip32X[ShyftTokenType].add(_value);

                    v1TotalUpgradeAmount = v1TotalUpgradeAmount.add(_value);

                    emit EVT_TransferAndMintBip32X(msg.sender, _from, _value, ShyftTokenType);
                    emit EVT_UpgradeFromV1(msg.sender, _from, _value);

                    ok = true;
                } else {
                    revert("cannot process a withdrawToExternalContract event from the v0 contract.");
                }

            } else {
                revert("cannot process fallback from Shyft Kyc Contract of a revision not equal to 0, in this version of Shyft Core");
            }
        }
    }

    //---------------- ERC 20 ----------------//

    /// @param _who The address of the user.
    /// @dev Gets the balance for the SHFT token type for a specific user.
    /// @return the balance of the SHFT token type for the user

    function balanceOf(address _who) public view override returns (uint) {
        return balances[_who][ShyftTokenType];
    }

    /// @dev Gets the name of the token.
    /// @return _name of the token.

    function name() public pure returns (string memory _name) {
        return "Shyft [ Wrapped ]";
    }

    /// @dev Gets the symbol of the token.
    /// @return _symbol the symbol of the token

    function symbol() public pure returns (string memory _symbol) {
        //@note: "SFT" is the 3 letter variant
        return "SHFT";
    }

    /// @dev Gets the number of decimals of the token.
    /// @return _decimals number of decimals of the token.

    function decimals() public pure returns (uint8 _decimals) {
        return 18;
    }

    /// @dev Gets the number of SHFT tokens available.
    /// @return result total supply of SHFT tokens

    function totalSupply() public view override returns (uint256 result) {
        return getTotalSupplyBip32X(ShyftTokenType);
    }

    /// @param _to The address of the origin.
    /// @param _value The address of the recipient.
    /// @dev Transfers assets to destination, with ERC20 functionality. (basic ERC20 functionality, but blocks transactions if Only Accepts Kyc Input is set to true.)
    /// @return ok returns true if the checks pass and there are enough allowed + actual tokens to transfer to the recipient.

    function transfer(address _to, uint256 _value) public override returns (bool ok) {
        // block transfers if the recipient only allows kyc input, check other factors
        if (onlyAcceptsKycInput[_to] == false && balances[msg.sender][ShyftTokenType] >= _value) {
            balances[msg.sender][ShyftTokenType] = balances[msg.sender][ShyftTokenType].sub(_value);

            balances[_to][ShyftTokenType] = balances[_to][ShyftTokenType].add(_value);

            emit Transfer(msg.sender, _to, _value);

            return true;
        } else {
            return false;
        }
    }

    /// @param _tokenOwner The address of the origin.
    /// @param _spender The address of the recipient.
    /// @dev Get the current allowance for the basic Shyft token type. (basic ERC20 functionality)
    /// @return remaining the current allowance for the basic Shyft token type for a specific user

    function allowance(address _tokenOwner, address _spender) public view override returns (uint remaining) {
       return allowed[_tokenOwner][_spender][ShyftTokenType];
    }


    /// @param _spender The address of the recipient.
    /// @param _tokens The amount of tokens to transfer.
    /// @dev Allows pre-approving assets to be sent to a participant. (basic ERC20 functionality)
    /// @notice This (standard) function known to have an issue.
    /// @return success whether the approve function completed successfully

    function approve(address _spender, uint _tokens) public override returns (bool success) {
        allowed[msg.sender][_spender][ShyftTokenType] = _tokens;

        //example of issue:
        //user a has 20 tokens allowed from zero :: no incentive to frontrun
        //user a has +2 tokens allowed from 20 :: frontrunning would deplete 20 and add 2 :: incentive there.

        emit Approval(msg.sender, _spender, _tokens);

        return true;
    }

    /// @param _from The address of the origin.
    /// @param _to The address of the recipient.
    /// @param _tokens The amount of tokens to transfer.
    /// @dev Performs the withdrawal of pre-approved assets. (basic ERC20 functionality, but blocks transactions if Only Accepts Kyc Input is set to true.)
    /// @return success returns true if the checks pass and there are enough allowed + actual tokens to transfer to the recipient.

    function transferFrom(address _from, address _to, uint _tokens) public override returns (bool success) {
        // block transfers if the recipient only allows kyc input, check other factors
        if (onlyAcceptsKycInput[_to] == false && allowed[_from][msg.sender][ShyftTokenType] >= _tokens && balances[_from][ShyftTokenType] >= _tokens) {
            allowed[_from][msg.sender][ShyftTokenType] = allowed[_from][msg.sender][ShyftTokenType].sub(_tokens);

            balances[_from][ShyftTokenType] = balances[_from][ShyftTokenType].sub(_tokens);
            balances[_to][ShyftTokenType] = balances[_to][ShyftTokenType].add(_tokens);

            emit Transfer(_from, _to, _tokens);
            emit Approval(_from, msg.sender, allowed[_from][msg.sender][ShyftTokenType]);

            return true;
        } else {
            return false;
        }
    }

    //---------------- ERC20 Burnable/Mintable ----------------//

    /// @param _to The address of the receiver of minted tokens.
    /// @param _amount The amount of minted tokens.
    /// @dev Mints tokens to a specific address. Called only by an account with a minter role.
    /// @notice Has Shyft Opt-in Compliance feature-sets for expansion/mvp capabilities.

    function mint(address _to, uint256 _amount) public {
        require(_to != address(0), "ShyftKycContract: mint to the zero address");
        require(hasRole(MINTER_ROLE, msg.sender), "ShyftKycContract: must have minter role to mint");

        // @note: for the initial deploy we'll be able to provide an mvp implementation, and I've made it quite difficult
        // for the user to constrain themselves to kyc-only mode, especially before we have custom interfaces.

        // checks for Shyft opt-in compliance feature-sets to enforce kyc trust channel groupings.
        if (onlyAcceptsKycInput[_to] == true) {
            //make sure that there is a cache graph linked, otherwise revert.
            if (shyftCacheGraphAddress != address(0)) {
                IShyftCacheGraph shyftCacheGraph = IShyftCacheGraph(shyftCacheGraphAddress);

                //checks on consent-driven trust channels that the end user and the relayer have in common
                uint8 kycCanSendResult = shyftCacheGraph.getKycCanSend(msg.sender, _to, _amount, ShyftTokenType, true, false);

                //if there are any matches
                if (kycCanSendResult == 3) {
                    // continue on
                } else {
                    // or revert if there are no matches found.
                    revert("ShyftKycContract: mint to KYC only address within Trust Channel groupings");
                }
            } else {
                revert("ShyftKycContract: mint to KYC only address within Trust Channel groupings");
            }
        }

        totalSupplyBip32X[ShyftTokenType] = totalSupplyBip32X[ShyftTokenType].add(_amount);
        balances[_to][ShyftTokenType] = balances[_to][ShyftTokenType].add(_amount);

        emit Transfer(address(0), _to, _amount);
    }

    /// @param _account The address from which to burn tokens tokens.
    /// @param _amount The amount of burned tokens.
    /// @dev Burns tokens from a specific address, deducting from the caller's allowance.
    /// @dev The caller must have allowance for `accounts`'s tokens of at least `amount`.

    function burnFrom(address _account, uint256 _amount) public {
        require(_account != address(0), "ShyftKycContract: burn from the zero address");
        uint256 currentAllowance = allowed[_account][msg.sender][ShyftTokenType];
        require(currentAllowance >= _amount, "ShyftKycContract: burn amount exceeds allowance");
        uint256 accountBalance = balances[_account][ShyftTokenType];
        require(accountBalance >= _amount, "ShyftKycContract: burn amount exceeds balance");

        allowed[_account][msg.sender][ShyftTokenType] = currentAllowance.sub(_amount);

        emit Approval(_account, msg.sender, allowed[_account][msg.sender][ShyftTokenType]);

        balances[_account][ShyftTokenType] = accountBalance.sub(_amount);
        totalSupplyBip32X[ShyftTokenType] = totalSupplyBip32X[ShyftTokenType].sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    //---------------- Bip32X Burnable/Mintable ----------------//

    /// @param _to The address of the receiver of minted tokens.
    /// @param _amount The amount of minted tokens.
    /// @param _bip32X_type The Bip32X type of the token.
    /// @dev Mints tokens to a specific address. Called only by an account with a minter role.
    /// @notice Has Shyft Opt-in Compliance feature-sets for expansion/mvp capabilities.

    function mintBip32X(address _to, uint256 _amount, uint256 _bip32X_type) public override {
        require(_to != address(0), "ShyftKycContract: mint to the zero address");
        require(hasRole(MINTER_ROLE, msg.sender), "ShyftKycContract: must have minter role to mint");

        // @note: for the initial deploy we'll be able to provide an mvp implementation, and I've made it quite difficult
        // for the user to constrain themselves to kyc-only mode, especially before we have custom interfaces.

        // checks for Shyft opt-in compliance feature-sets to enforce kyc trust channel groupings.
        if (onlyAcceptsKycInput[_to] == true) {
            //make sure that there is a cache graph linked, otherwise revert.
            if (shyftCacheGraphAddress != address(0)) {
                IShyftCacheGraph shyftCacheGraph = IShyftCacheGraph(shyftCacheGraphAddress);

                //checks on consent-driven trust channels that the end user and the relayer have in common
                uint8 kycCanSendResult = shyftCacheGraph.getKycCanSend(msg.sender, _to, _amount, _bip32X_type, true, false);

                //if there are any matches
                if (kycCanSendResult == 3) {
                    // continue on
                } else {
                    // or revert if there are no matches found.
                    revert("ShyftKycContract: mint to KYC only address within Trust Channel groupings");
                }
            } else {
                revert("ShyftKycContract: mint to KYC only address within Trust Channel groupings");
            }
        }

        totalSupplyBip32X[_bip32X_type] = totalSupplyBip32X[_bip32X_type].add(_amount);
        balances[_to][_bip32X_type] = balances[_to][_bip32X_type].add(_amount);


        emit EVT_TransferBip32X(address(0), _to, _amount, _bip32X_type);
    }

    /// @param _account The address from which to burn tokens tokens.
    /// @param _amount The amount of burned tokens.
    /// @param _bip32X_type The Bip32X type of the token.
    /// @dev Burns tokens from a specific address, deducting from the caller's allowance.
    /// @dev The caller must have allowance for `accounts`'s tokens of at least `amount`.

    function burnFromBip32X(address _account, uint256 _amount, uint256 _bip32X_type) public override {
        require(_account != address(0), "ShyftKycContract: burn from the zero address");
        uint256 currentAllowance = allowed[_account][msg.sender][_bip32X_type];
        require(currentAllowance >= _amount, "ShyftKycContract: burn amount exceeds allowance");
        uint256 accountBalance = balances[_account][_bip32X_type];
        require(accountBalance >= _amount, "ShyftKycContract: burn amount exceeds balance");

        allowed[_account][msg.sender][_bip32X_type] = currentAllowance.sub(_amount);

        emit EVT_ApprovalBip32X(_account, msg.sender, allowed[_account][msg.sender][_bip32X_type], _bip32X_type);

        balances[_account][_bip32X_type] = accountBalance.sub(_amount);
        totalSupplyBip32X[_bip32X_type] = totalSupplyBip32X[_bip32X_type].sub(_amount);

        emit EVT_TransferBip32X(_account, address(0), _amount, _bip32X_type);
    }

    //---------------- Shyft Token Transfer / Approval [KycContract] ----------------//

    /// @param _to The address of the recipient.
    /// @param _value The amount of tokens to transfer.
    /// @param _bip32X_type The Bip32X type of the asset to transfer.
    /// @dev | Transfers assets from one Shyft user to another, with restrictions on the transfer if the recipient has enabled Only Accept KYC Input.
    /// @return result returns true if the transaction completes, reverts if it does not.

    function transferBip32X(address _to, uint256 _value, uint256 _bip32X_type) public override returns (bool result) {
        // block transfers if the recipient only allows kyc input
        require(onlyAcceptsKycInput[_to] == false, "recipient must not only accept kyc'd input");
        require(balances[msg.sender][_bip32X_type] >= _value, "not enough balance");

        balances[msg.sender][_bip32X_type] = balances[msg.sender][_bip32X_type].sub(_value);
        balances[_to][_bip32X_type] = balances[_to][_bip32X_type].add(_value);

        emit EVT_TransferBip32X(msg.sender, _to, _value, _bip32X_type);
        return true;
    }

    /// @param _tokenOwner The address of the origin.
    /// @param _spender The address of the recipient.
    /// @param _bip32X_type The Bip32X type of the token.
    /// @dev Get the current allowance for the basic Shyft token type. (basic ERC20 functionality, Bip32X assets)
    /// @return remaining the current allowance for the basic Shyft token type for a specific user

    function allowanceBip32X(address _tokenOwner, address _spender, uint256 _bip32X_type) public view override returns (uint remaining) {
        return allowed[_tokenOwner][_spender][_bip32X_type];
    }


    /// @param _spender The address of the recipient.
    /// @param _tokens The amount of tokens to transfer.
    /// @param _bip32X_type The Bip32X type of the token.
    /// @dev Allows pre-approving assets to be sent to a participant. (basic ERC20 functionality, Bip32X assets)
    /// @notice This (standard) function known to have an issue.
    /// @return success whether the approve function completed successfully

    function approveBip32X(address _spender, uint _tokens, uint256 _bip32X_type) public override returns (bool success) {
        allowed[msg.sender][_spender][_bip32X_type] = _tokens;

        //example of issue:
        //user a has 20 tokens allowed from zero :: no incentive to frontrun
        //user a has +2 tokens allowed from 20 :: frontrunning would deplete 20 and add 2 :: incentive there.

        emit EVT_ApprovalBip32X(msg.sender, _spender, _tokens, _bip32X_type);

        return true;
    }

    /// @param _from The address of the origin.
    /// @param _to The address of the recipient.
    /// @param _tokens The amount of tokens to transfer.
    /// @param _bip32X_type The Bip32X type of the token.
    /// @dev Performs the withdrawal of pre-approved assets. (basic ERC20 functionality, but blocks transactions if Only Accepts Kyc Input is set to true, Bip32X assets)
    /// @return success returns true if the checks pass and there are enough allowed + actual tokens to transfer to the recipient.

    function transferFromBip32X(address _from, address _to, uint _tokens, uint256 _bip32X_type) public override returns (bool success) {
        // block transfers if the recipient only allows kyc input, check other factors
        if (onlyAcceptsKycInput[_to] == false && allowed[_from][msg.sender][_bip32X_type] >= _tokens && balances[_from][ShyftTokenType] >= _tokens) {
            allowed[_from][msg.sender][_bip32X_type] = allowed[_from][msg.sender][_bip32X_type].sub(_tokens);

            balances[_from][_bip32X_type] = balances[_from][_bip32X_type].sub(_tokens);
            balances[_to][_bip32X_type] = balances[_to][_bip32X_type].add(_tokens);

            emit EVT_TransferBip32X(_from, _to, _tokens, _bip32X_type);
            emit EVT_ApprovalBip32X(_from, msg.sender, allowed[_from][msg.sender][_bip32X_type], _bip32X_type);

            return true;
        } else {
            return false;
        }
    }

    //---------------- Shyft Token Transfer [Erc20] ----------------//

    /// @param _erc20ContractAddress The address of the ERC20 contract.
    /// @param _value The amount of tokens to transfer.
    /// @dev | Transfers assets from any Erc20 contract to a Bip32X type Shyft synthetic asset. Mints the current synthetic balance.
    /// @return ok returns true if the transaction completes, reverts if it does not

    function transferFromErc20TokenToBip32X(address _erc20ContractAddress, uint256 _value) mutex public override returns (bool ok) {
        require(_erc20ContractAddress != address(this), "cannot transfer from this contract");

        // block transfers if the recipient only allows kyc input, check other factors
        require(onlyAcceptsKycInput[msg.sender] == false, "recipient must not only accept kyc'd input");

        IERC20 erc20Contract = IERC20(_erc20ContractAddress);

        if (erc20Contract.allowance(msg.sender, address(this)) >= _value) {
            erc20Contract.safeTransferFrom(msg.sender, address(this), _value);
            //@note: using _erc20ContractAddress in the keccak hash since _erc20ContractAddress will be where
            // the tokens are created and managed.
            //
            // thus, this fallback will not function properly with abstracted synthetics (including this contract)
            // hence the initial require() check above to prevent this behaviour.

            uint256 bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, _erc20ContractAddress)));
            balances[msg.sender][bip32X_type] = balances[msg.sender][bip32X_type].add(_value);
            totalSupplyBip32X[bip32X_type] = totalSupplyBip32X[bip32X_type].add(_value);

            emit EVT_TransferAndMintBip32X(_erc20ContractAddress, msg.sender, _value, bip32X_type);

            //transfer successful
            ok = true;
        } else {
            //not enough allowance
        }
    }

    /// @param _erc20ContractAddress The address of the ERC20 contract that
    /// @param _to The address of the recipient.
    /// @param _value The amount of tokens to transfer.
    /// @dev | Withdraws a Bip32X type Shyft synthetic asset into its origin ERC20 contract. Burns the current synthetic balance.
    ///      | Cannot withdraw Bip32X type into an incorrect destination contract (as the hash will not match).
    /// @return ok returns true if the transaction completes, reverts if it does not

    function withdrawTokenBip32XToErc20(address _erc20ContractAddress, address _to, uint256 _value) mutex public override returns (bool ok) {
        uint256 bip32X_type = uint256(keccak256(abi.encodePacked(nativeBip32X_type, _erc20ContractAddress)));

        require(balances[msg.sender][bip32X_type] >= _value, "not enough balance");

        balances[msg.sender][bip32X_type] = balances[msg.sender][bip32X_type].sub(_value);
        totalSupplyBip32X[bip32X_type] = totalSupplyBip32X[bip32X_type].sub(_value);

        IERC20 erc20Contract = IERC20(_erc20ContractAddress);

        erc20Contract.safeTransfer(_to, _value);

        emit EVT_TransferAndBurnBip32X(_erc20ContractAddress, msg.sender, _to, _value, bip32X_type);

        ok = true;
    }

    //@note:@v1Upgrade:
    //---------------- Emergency Upgrade Requirements ----------------//

    // issue with the ethereum-based march 26th launch was that the transfer() function is the only way to move tokens,
    // **but** the function naming convention of erc223 (which allows this functionality with a specific receiver built
    // into this) is also "transfer" with the caveat that the function signature is:
    // [erc20] transfer(address,uint256) vs [erc223] transfer(address,uint256,bytes).
    //
    // given this, there is a high likelihood that a subset of users will incorrectly trigger this upgrade function,
    // leaving their coins isolated in the ERC20-ish mechanism vs being properly upgraded.
    //
    // as such, we're introducing an administrator-triggered differentiation into a "spendable" address for these tokens,
    // with the obvious caveat that this maneuver costs ETH on the redemption side.


    /// @param _emergencyResponder The address of the v1 emergency responder.
    /// @dev Sets the emergency responder (address responsible for sending back incorrectly-sent transfer functions)
    /// @return result
    ///    | 1 = set emergency responder correctly
    ///    | 0 = not owner

    function setV1EmergencyErc20RedemptionResponder(address _emergencyResponder) public returns(uint8 result) {
        if (msg.sender == owner) {
            emergencyResponder = _emergencyResponder;

            emit EVT_setV1EmergencyResponder(_emergencyResponder);
            // set emergency responder correctly
            return 1;
        } else {
            // not owner
            return 0;
        }
    }

    /// @dev Gets the incorrectly-sent erc20 balance (the difference between what has been associated to this contract via the upgrade function vs the erc20-based "transfer(address,uint256)" function.
    /// @return result
    ///    | [amount] = incorrectly sent asset balance.
    ///    | 0 = registry not set up properly, or 0 balance.

    function getIncorrectlySentAssetsBalance() public view returns(uint256 result) {
        IShyftKycContractRegistry contractRegistry = IShyftKycContractRegistry(shyftKycContractRegistryAddress);

        address ethMarch26KycContractAddress = contractRegistry.getContractAddressOfVersion(0);

        if (ethMarch26KycContractAddress != address(0)) {

            IERC20 march26Erc20 = IERC20(ethMarch26KycContractAddress);

            uint256 currentBalance = march26Erc20.balanceOf(address(this));

            uint256 incorrectlySentAssetBalance = currentBalance.sub(v1TotalUpgradeAmount);

            return incorrectlySentAssetBalance;
        } else {
            //registry not set up properly
            return 0;
        }
    }

    /// @param _destination The destination for the redeemed assets.
    /// @param _amount The amount of the assets to redeem.
    /// @dev Redeems assets to specific destinations. As there is no tracking functionality that will not break the gas expectations, there is an external mechanism to redeem assets correctly off-chain based on the transaction receipts.
    /// @return result
    ///    | 4 = redeemed assets correctly
    ///    | [revert] = erc20-based "transfer(address,uint256" function did not return okay
    ///    | 2 = did not have enough tokens in incorrectly-sent balance account to redeem
    ///    | 1 = registry not set up properly
    ///    | 0 = not responder

    function responderRedeemIncorrectlySentAssets(address _destination, uint256 _amount) public returns(uint8 result) {
        if (msg.sender == emergencyResponder) {
            IShyftKycContractRegistry contractRegistry = IShyftKycContractRegistry(shyftKycContractRegistryAddress);

            address ethMarch26KycContractAddress = contractRegistry.getContractAddressOfVersion(0);

            if (ethMarch26KycContractAddress != address(0)) {
                IERC20 march26Erc20 = IERC20(ethMarch26KycContractAddress);

                uint256 currentBalance = march26Erc20.balanceOf(address(this));

                uint256 incorrectlySentAssetBalance = currentBalance.sub(v1TotalUpgradeAmount);

                if (_amount <= incorrectlySentAssetBalance) {
                    bool success = march26Erc20.transfer(_destination, _amount);

                    if (success == true) {
                        emit EVT_redeemIncorrectlySentAsset(_destination, _amount);

                        //redeemed assets correctly
                        return 4;
                    } else {
                        //must revert since transactional action has occurred
                        revert("erc20 transfer event did not succeed");
                        //                    return 3;
                    }
                } else {
                    //did not have enough tokens in incorrectly-sent balance account to redeem
                    return 2;
                }
            } else {
                //registry not set up properly
                return 1;
            }
        } else {
            //not responder
            return 0;
        }
    }
}