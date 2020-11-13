// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


// 
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// 
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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

// 
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

// 
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
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
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

//
abstract contract OwnerRole is AccessControl {

    address private _newOwnerCandidate;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    event OwnerRoleTransferCancelled();
    event OwnerRoleTransferCompleted(address indexed previousOwner, address indexed newOwner);
    event OwnerRoleTransferStarted(address indexed currentOwner, address indexed newOwnerCandidate);


    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), "OwnerRole: caller is not the owner");
        _;
    }

    modifier onlyNewOwnerCandidate() {
        require(_msgSender() == _newOwnerCandidate, "OwnerRole: caller is not the new owner candidate");
        _;
    }

    constructor
    (
        address owner
    )
        internal
    {
        require(owner != address(0), "OwnerRole: owner is the zero address");

        _setupRole(OWNER_ROLE, owner);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    function acceptOwnerRole()
        external
        onlyNewOwnerCandidate
    {
        address previousOwner = getRoleMember(OWNER_ROLE, 0);
        address newOwner = _newOwnerCandidate;

        _setupRole(OWNER_ROLE, newOwner);
        revokeRole(OWNER_ROLE, previousOwner);
        _newOwnerCandidate = address(0);

        emit OwnerRoleTransferCompleted(previousOwner, newOwner);
    }

    function cancelOwnerRoleTransfer()
        external
        onlyOwner
    {
        require(_newOwnerCandidate != address(0), "OwnerRole: ownership transfer is not in-progress");

        _cancelOwnerRoleTransfer();
    }

    function renounceOwnerRole() 
        external
    {
        renounceRole(OWNER_ROLE, _msgSender());
        _cancelOwnerRoleTransfer();
    }

    function transferOwnerRole
    (
        address newOwnerCandidate
    )
        external
        onlyOwner
    {
        require(newOwnerCandidate != address(0), "OwnerRole: newOwnerCandidate is the zero address");

        address currentOwner = getRoleMember(OWNER_ROLE, 0);

        require(currentOwner != newOwnerCandidate, "OwnerRole: newOwnerCandidate is the current owner");

        _cancelOwnerRoleTransfer();
        _newOwnerCandidate = newOwnerCandidate;

        emit OwnerRoleTransferStarted(currentOwner, newOwnerCandidate);
    }

    function _cancelOwnerRoleTransfer()
        private
    {
        if (_newOwnerCandidate != address(0)) {
            _newOwnerCandidate = address(0);
            
            emit OwnerRoleTransferCancelled();
        }
    }
}

//
contract VASPContract is OwnerRole {
    bytes4 private _channels;
    bytes private _transportKey;
    bytes private _messageKey;
    bytes private _signingKey;
    bytes4 private _vaspCode;

    event ChannelsChanged(bytes4 indexed vaspCode, bytes4 previousChannels, bytes4 newChannels);
    event TransportKeyChanged(bytes4 indexed vaspCode, bytes previousTransportKey, bytes newTransportKey);
    event MessageKeyChanged(bytes4 indexed vaspCode, bytes previousMessageKey, bytes newMessageKey);
    event SigningKeyChanged(bytes4 indexed vaspCode, bytes previousSigningKey, bytes newSigningKey);

    constructor
    (
        bytes4 vaspCode,
        address owner,
        bytes4 channels,
        bytes memory transportKey,
        bytes memory messageKey,
        bytes memory signingKey
    )
        public
        OwnerRole(owner)
    {
        require(vaspCode != bytes4(0), "VASPContract: vaspCode is empty");
        require(_isValidKey(transportKey), "VASPContract: transportKey is invalid");
        require(_isValidKey(messageKey), "VASPContract: messageKey is invalid");
        require(_isValidKey(signingKey), "VASPContract: signingKey is invalid");

        _vaspCode = vaspCode;

        _setChannels(channels);
        _setTransportKey(transportKey);
        _setMessageKey(messageKey);
        _setSigningKey(signingKey);
    }

    function setChannels
    (
        bytes4 newChannels
    )
        external
        onlyOwner
    {
        _setChannels(newChannels);
    }

    function setTransportKey
    (
        bytes calldata newTransportKey
    )
        external
        onlyOwner
    {
        require(_isValidKey(newTransportKey), "VASPContract: newTransportKey is invalid");

        _setTransportKey(newTransportKey);
    }

    function setMessageKey
    (
        bytes calldata newMessageKey
    )
        external
        onlyOwner
    {
        require(_isValidKey(newMessageKey), "VASPContract: newMessageKey is invalid");

        _setMessageKey(newMessageKey);
    }

    function setSigningKey
    (
        bytes calldata newSigningKey
    )
        external
        onlyOwner
    {
        require(_isValidKey(newSigningKey), "VASPContract: newSigningKey is invalid");

        _setSigningKey(newSigningKey);
    }

    function channels()
        external view
        returns (bytes4)
    {
        return _channels;
    }

    function transportKey()
        external view
        returns (bytes memory)
    {
        return _transportKey;
    }

    function messageKey()
        external view
        returns (bytes memory)
    {
        return _messageKey;
    }

    function signingKey()
        external view
        returns (bytes memory)
    {
        return _signingKey;
    }

    function vaspCode()
        external view
        returns (bytes4)
    {
        return _vaspCode;
    }

    function _setChannels
    (
        bytes4 newChannels
    )
        private
    {
        if(_channels != newChannels) {
            emit ChannelsChanged(_vaspCode, _channels, newChannels);
            _channels = newChannels;
        }
    }

    function _setTransportKey
    (
        bytes memory newTransportKey
    )
        private
    {
        if(_areNotEqual(_transportKey, newTransportKey)) {
            emit TransportKeyChanged(_vaspCode, _transportKey, newTransportKey);
            _transportKey = newTransportKey;
        }
    }

    function _setMessageKey
    (
        bytes memory newMessageKey
    )
        private
    {
        if(_areNotEqual(_messageKey, newMessageKey)) {
            emit MessageKeyChanged(_vaspCode, _messageKey, newMessageKey);
            _messageKey = newMessageKey;
        }
    }

    function _setSigningKey
    (
        bytes memory newSigningKey
    )
        private
    {
        if(_areNotEqual(_signingKey, newSigningKey)) {
            emit SigningKeyChanged(_vaspCode, _signingKey, newSigningKey);
            _signingKey = newSigningKey;
        }
    }

    function _areNotEqual
    (
        bytes memory left,
        bytes memory right
    )
        private pure
        returns (bool)
    {
        return keccak256(left) != keccak256(right);
    }

    function _isValidKey
    (
        bytes memory key
    )
        private pure
        returns (bool)
    {
        return key.length == 33 && (key[0] == 0x02 || key[0] == 0x03);
    }
}

//
contract VASPContractFactory {

    function create
    (
        bytes4 vaspCode,
        address owner,
        bytes4 channels,
        bytes memory transportKey,
        bytes memory messageKey,
        bytes memory signingKey
    )
        external
        returns (address)
    {
        VASPContract vaspContract = new VASPContract(vaspCode, owner, channels, transportKey, messageKey, signingKey);
        address vaspAddress = address(vaspContract);

        return vaspAddress;
    }
}

//
contract VASPIndex is Pausable, OwnerRole {
    mapping (bytes4 => address) private _vaspAddresses;
    mapping (address => bytes4) private _vaspCodes;
    VASPContractFactory private _vaspContractFactory;

    event VASPContractCreated(bytes4 indexed vaspCode, address indexed vaspAddress);

    modifier onlyVASPContract() {
        require(_vaspCodes[_msgSender()] == bytes4(0), "VASPIndex: caller is not a VASP contract");
        _;
    }

    constructor
    (
        address owner,
        address vaspContractFactory
    )
        public
        OwnerRole(owner)
    {
        require(vaspContractFactory != address(0), "VASPIndex: vaspContractFactory is the zero address");

        _vaspContractFactory = VASPContractFactory(vaspContractFactory);
    }

    function createVASPContract
    (
        bytes4 vaspCode,
        address owner,
        bytes4 channels,
        bytes calldata transportKey,
        bytes calldata messageKey,
        bytes calldata signingKey
    )
        external
        whenNotPaused
        returns (address)
    {
        require(vaspCode != bytes4(0), "VASPIndex: vaspCode is empty");
        require(_vaspAddresses[vaspCode] == address(0), "VASPIndex: vaspCode is already in use");

        address vaspAddress = _vaspContractFactory.create(vaspCode, owner, channels, transportKey, messageKey, signingKey);

        _vaspCodes[vaspAddress] = vaspCode;
        _vaspAddresses[vaspCode] = vaspAddress;

        emit VASPContractCreated(vaspCode, vaspAddress);

        return vaspAddress;
    }

    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    function terminate
    (
        address payable recipient
    )
        external
        onlyOwner
    {
        selfdestruct(recipient);
    }

    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    function getVASPAddressByCode
    (
        bytes4 vaspCode
    )
        external view
        returns (address)
    {
        return _vaspAddresses[vaspCode];
    }

    function getVASPCodeByAddress
    (
        address vaspAddress
    )
        external view
        returns (bytes4)
    {
        return _vaspCodes[vaspAddress];
    }
}