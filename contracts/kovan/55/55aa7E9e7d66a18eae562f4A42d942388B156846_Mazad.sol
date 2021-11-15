// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./EnumerableSet.sol";
import "./Address.sol";
import "./Context.sol";

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

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

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
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address)
    {
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
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

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
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

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
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "./SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

/*
 * Digital Challenges Bootcamp by code.mcit.gov.sa
 * Team #34
 * Author by Faisal Albalwy
 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./Wallet.sol";
import "./Registration.sol";
import "./Property.sol";
import "./SafeMath.sol";

contract Mazad is Ownable, Pausable, AccessControl {
    using SafeMath for uint256;

    enum AUCTION_STATUS {
        NULL,
        CREATED,
        ACTIVATED,
        ENDED
    }

    Registration public registration;
    Property public property;
    Wallet public wallet;

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Offer) public offers;
    mapping(address => uint256[]) public userAuctions;
    mapping(address => uint256[]) public userOffers;

    uint256 public nextAuctionId = 1;
    uint256 public nextOfferId = 1;

    struct Auction {
        uint256 id;
        address seller;
        bytes name;
        bytes description;
        bytes[] pictures;
        uint256 min;
        uint256 end;
        uint256 duration;
        uint256 bestOfferId;
        uint256[] offerIds;
        AUCTION_STATUS status;
        bytes32 propertyHash;
        address appraiser;
        address trigger;
    }

    struct Offer {
        uint256 id;
        uint256 auctionId;
        address buyer;
        uint256 price;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(
            _auctionId > 0 && _auctionId < nextAuctionId,
            "Mazad: auction does not exist"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            registration.hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) == true,
            "Mazad: caller is not the admin"
        );
        _;
    }

    modifier onlyBidder() {
        require(
            registration.hasRole(registration.bidder(), _msgSender()) == true,
            "Mazad: caller is not bidder"
        );
        _;
    }

    modifier onlySeller() {
        require(
            registration.hasRole(registration.seller(), _msgSender()) == true,
            "Mazad: caller is not seller"
        );
        _;
    }

    modifier onlyAppraiser() {
        require(
            registration.hasRole(registration.appraiser(), _msgSender()) ==
                true,
            "Mazad: caller is not appraiser"
        );
        _;
    }

    modifier onlyNotary() {
        require(
            registration.hasRole(keccak256("NOTARY_ROLE"), _msgSender()) ==
                true,
            "Mazad: caller is not notary"
        );
        _;
    }

    event tradeLog(
        uint256 auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 timestamp
    );

    event createAuctionLog(uint256 auctionId, uint256 timestamp);
    event estimatePropertyLog(
        uint256 auctionId,
        address indexed aappraiser,
        uint256 timestamp
    );

    event createOfferLog(
        uint256 auctionId,
        address indexed seller,
        uint256 timestamp
    );

    constructor(
        Registration _registration,
        Property _property,
        Wallet _wallet
    ) public {
        registration = _registration;
        property = _property;
        wallet = _wallet;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _pause() public override(Pausable) whenNotPaused onlyOwner {
        super._pause();
    }

    function _unpause() public override(Pausable) whenPaused onlyOwner {
        super._unpause();
    }

    function createAuction(
        bytes calldata _name,
        bytes calldata _description,
        uint256 _duration,
        bytes[] calldata _pictures,
        bytes32 _propertyHash
    ) external onlySeller whenNotPaused {
        /*require(
            property.getPropertyStatus(_propertyHash) == 
                Property.PROPERTY_STATUS.APPROVED,
            "Mazad: property is not registred or approved yet"
        );

        require(
            _duration > 86400 && _duration < 864000,
            "Mazad: duration must be comprised between 1 to 10 days"
        );*/

        uint256[] memory offerIds = new uint256[](0);

        auctions[nextAuctionId].id = nextAuctionId;
        auctions[nextAuctionId].seller = msg.sender;
        auctions[nextAuctionId].name = _name;
        auctions[nextAuctionId].description = _description;

        for (uint256 i = 0; i < _pictures.length; i++) {
            auctions[nextAuctionId].pictures.push(_pictures[i]);
        }

        auctions[nextAuctionId].duration = _duration;
        auctions[nextAuctionId].offerIds = offerIds;
        auctions[nextAuctionId].status = AUCTION_STATUS.CREATED;
        auctions[nextAuctionId].propertyHash = _propertyHash;
        property.putPropertyOnSale(_propertyHash, msg.sender);

        userAuctions[msg.sender].push(nextAuctionId);

        emit createAuctionLog(nextAuctionId, block.timestamp);
        nextAuctionId++;
    }

    function estimateProperty(uint256 _auctionId, uint256 _averagePrice)
        external
        onlyAppraiser
        auctionExists(_auctionId)
        whenNotPaused
    {
        Auction storage auction = auctions[_auctionId];

        require(
            _averagePrice > 0,
            "Mazad: estimate average price should be > 0"
        );

        require(
            AUCTION_STATUS.CREATED == auction.status,
            "Mazad: auction should be in CREATED status"
        );

        auction.min = _averagePrice;
        auction.status = AUCTION_STATUS.ACTIVATED;
        auction.end = block.timestamp + auction.duration;
        auction.appraiser = msg.sender;

        emit estimatePropertyLog(_auctionId, msg.sender, block.timestamp);
    }

    function createOffer(uint256 _auctionId)
        external
        payable
        onlyBidder
        auctionExists(_auctionId)
        whenNotPaused
    {
        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];
        require(
            AUCTION_STATUS.ACTIVATED == auction.status,
            "Mazad: auction should be in ACTIVATED status"
        );
        require(block.timestamp < auction.end, "Mazad: auction has expired");
        require(
            msg.value >= auction.min && msg.value > bestOffer.price,
            "Mazad: value must be superior to min and bestOffer"
        );
        auction.bestOfferId = nextOfferId;
        auction.offerIds.push(nextOfferId);
        //auction.bestOfferPrice = msg.value ;

        offers[nextOfferId] = Offer(
            nextOfferId,
            _auctionId,
            msg.sender,
            msg.value
        );
        userOffers[msg.sender].push(nextOfferId);
        nextOfferId++;

        wallet.deposit{value: msg.value}(msg.sender);

        emit createOfferLog(_auctionId, auction.seller, block.timestamp);
    }

    function trade(uint256 _auctionId)
        external
        whenNotPaused
        auctionExists(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];
        require(
            block.timestamp > auction.end,
            "Mazad: auction is still active"
        );

        require(
            AUCTION_STATUS.ACTIVATED == auction.status,
            "Mazad: auction should be in ACTIVATED status"
        );

        auction.status = AUCTION_STATUS.ENDED;
        auction.trigger = msg.sender;

        //balance[bestOffer.buyer] = balance[bestOffer.buyer].sub(bestOffer.price);
        //balance[auction.seller] = balance[auction.seller].add(mulScale(bestOffer.price,975,1000));
        //balance[auction.appraiser] = balance[auction.appraiser].add(mulScale(bestOffer.price,625,100000));
        //balance[msg.sender] = balance[msg.sender].add(mulScale(bestOffer.price,625,100000));

        wallet.decressBalance(bestOffer.buyer, bestOffer.price);
        wallet.increaseBalance(
            auction.seller,
            mulScale(bestOffer.price, 975, 1000)
        );
        wallet.increaseBalance(
            auction.appraiser,
            mulScale(bestOffer.price, 625, 100000)
        );
        wallet.increaseBalance(
            msg.sender,
            mulScale(bestOffer.price, 625, 100000)
        );

        emit tradeLog(
            _auctionId,
            auction.seller,
            bestOffer.buyer,
            block.timestamp
        );
    }

    function getAuctionsInfo(uint256 _auctionId)
        public
        view
        returns (
            address _seller,
            uint256 _end,
            uint256 _bestOfferId,
            AUCTION_STATUS _status,
            bytes32 _propertyHash,
            address _appraiser
        )
    {
        _seller = auctions[_auctionId].seller;
        _end = auctions[_auctionId].end;
        _bestOfferId = auctions[_auctionId].bestOfferId;
        _status = auctions[_auctionId].status;
        _propertyHash = auctions[_auctionId].propertyHash;
        _appraiser = auctions[_auctionId].appraiser;
    }

    function updateAuctionsInfo(
        uint256 _auctionId,
        AUCTION_STATUS _status,
        address _trigger
    ) public {
        auctions[_auctionId].status = _status;
        auctions[_auctionId].trigger = _trigger;
    }

    /*function withdraw() public virtual {
        require(balance[msg.sender] >0, "Escrow: balance zero");
        uint256 payment = balance[msg.sender];
        balance[msg.sender] = 0;
        msg.sender.sendValue(payment);
        emit Withdrawn(msg.sender, payment);
    }*/

    function getAuctions2() external view returns (Auction[] memory) {
        Auction[] memory _auctions = new Auction[](nextAuctionId - 1);
        for (uint256 i = 1; i < nextAuctionId; i++) {
            _auctions[i - 1] = auctions[i];
        }
        return _auctions;
    }

    function getOffers() external view returns (Offer[] memory) {
        Offer[] memory _offers = new Offer[](nextOfferId - 1);
        for (uint256 i = 1; i < nextOfferId; i++) {
            _offers[i - 1] = offers[i];
        }
        return _offers;
    }

    function getUserAuctions(address _user)
        external
        view
        returns (Auction[] memory)
    {
        uint256[] storage userAuctionIds = userAuctions[_user];
        Auction[] memory _auctions = new Auction[](userAuctionIds.length);
        for (uint256 i = 0; i < userAuctionIds.length; i++) {
            uint256 auctionId = userAuctionIds[i];
            _auctions[i] = auctions[auctionId];
        }
        return _auctions;
    }

    function getUserOffers(address _user)
        external
        view
        returns (Offer[] memory)
    {
        uint256[] storage userOfferIds = userOffers[_user];
        Offer[] memory _offers = new Offer[](userOfferIds.length);
        for (uint256 i = 0; i < userOfferIds.length; i++) {
            uint256 offerId = userOfferIds[i];
            _offers[i] = offers[offerId];
        }
        return _offers;
    }

    function hashThat(bytes memory _location, bytes32 _city)
        public
        view
        returns (bytes32 hash)
    {
        hash = keccak256(abi.encodePacked(_location, _city));
    }

    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) public pure returns (uint256) {
        uint256 a = x.div(scale);
        uint256 b = x.mod(scale);
        uint256 c = y.div(scale);
        uint256 d = y.mod(scale);

        return
            a.mul(c).mul(scale).add(a.mul(d)).add(b.mul(c)).add(
                b.mul(d).div(scale)
            );
    }
}

/*
    function trade(uint256 _auctionId)
        external
        whenNotPaused
        auctionExists(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];
        require(
            block.timestamp > auction.end,
            "Mazad: auction is still active"
        );
        
        require(
            AUCTION_STATUS.ACTIVATED == auction.status,
            "Mazad: auction should be in ACTIVATED status"
        );
        
        auction.status = AUCTION_STATUS.ENDED;
        auction.trigger = msg.sender;

        for (uint256 i = 0; i < auction.offerIds.length; i++) {
            uint256 offerId = auction.offerIds[i];
            
            if (offerId != auction.bestOfferId) {
                Offer storage offer = offers[offerId];
                //offer.buyer.transfer(offer.price);
                balance[offer.buyer] = balance[offer.buyer] + offer.price;
            }
        }
        
        uint256 amount = bestOffer.price;
        address buyer = bestOffer.buyer;
        bestOffer.price = 0;
        //balance[bestOffer.buyer] = balance[bestOffer.buyer].mul(amount);
        
        escrow.decressBalance(bestOffer.buyer,amount);
        escrow.increaseBalance(auction.seller,mulScale(amount,975,1000));
        escrow.increaseBalance(auction.appraiser,mulScale(amount,625,100000));
        escrow.increaseBalance(msg.sender,mulScale(amount,625,100000));
        
        //transferPropertyOwnership(auction.id);
        

        emit tradeLog(
            _auctionId,
            auction.seller,
            bestOffer.buyer,
            block.timestamp
        );
    }
    
     function transferPropertyOwnership(uint256 _auctionId) public {
           
        bytes32 oraclizeID = provable_query(
            "URL",
            string(
                abi.encodePacked(registration.notarialServer(), _auctionId)
            ));
        resultId[oraclizeID] = _auctionId;
    }
    
    
    bytes public r;
    
     function __callback(bytes32 _oraclizeID, string memory _result)
        public
        override
    {
        
        r =  bytes(_result);
        require(
            properties[resultId[_oraclizeID]].status == PROPERTY_STATUS.PENDING,
            "Property: property not registred before"
        );

        bytes memory result = bytes(_result);

        if (
            keccak256(abi.encode(_result)) == keccak256(abi.encode("404")) ||
            keccak256(abi.encode(_result)) == keccak256(abi.encode("error"))
        ) {
            properties[resultId[_oraclizeID]].status = PROPERTY_STATUS
                .APPROVED_FAILD;
            properties[resultId[_oraclizeID]].dbRef = result;
            emit approvePropertyLog(resultId[_oraclizeID], block.timestamp);
        } else {
            properties[resultId[_oraclizeID]].status = PROPERTY_STATUS.APPROVED;
            properties[resultId[_oraclizeID]].dbRef = result;

            emit approvePropertyLog(resultId[_oraclizeID], block.timestamp);
        }
    }
    
    

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes32[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes32[i / 2] >> 4);

            bytesArray[i] = toByte(_f);
            i = i + 1;
            bytesArray[i] = toByte(_l);
        }
        return string(bytesArray);
    }

    function toByte(uint8 _uint8) public pure returns (bytes1) {
        if (_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }
    
        function mulScale (uint x, uint y, uint128 scale) public pure returns (uint) {
      uint a = x.div(scale);
      uint b = x.mod(scale);
      uint c = y.div(scale);
      uint d = y.mod(scale);
      
      return a.mul(c).mul(scale).add(a.mul(d)).add(b.mul(c)).add(b.mul(d).div(scale));
  }

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";

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
    constructor() internal {
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
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() public virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() public virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/*
 * Digital Challenges Bootcamp by code.mcit.gov.sa
 * Team #34
 * Author by Faisal Albalwy
 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Registration.sol";

contract Property is Ownable, Pausable, AccessControl {
    using Strings for *;

    enum PROPERTY_STATUS {
        NULL,
        PENDING,
        APPROVED,
        ON_SALE,
        APPROVED_FAILD
    }

    Registration public registration;
    mapping(bytes32 => PropertyInfo) public properties;
    mapping(bytes32 => bytes32) public resultId;

    bytes32[] private propertiesIds;

    struct PropertyInfo {
        bytes32 propertyHash;
        address owner;
        bytes document;
        PROPERTY_STATUS status;
        bytes32 city;
        bytes location;
        uint256 documentId;
        bytes dbRef;
    }

    event registerPropertyLog(bytes32 propertyHash, uint256 timestamp);

    event approvePropertyLog(bytes32 propertyHash, uint256 timestamp);

    event transferPropertyOwnershipLog(
        bytes32 propertyHash,
        address indexed oldOwner,
        uint256 auctionId,
        uint256 timestamp
    );

    modifier onlyAdmin() {
        require(
            registration.hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) == true,
            "Property: caller is not the admin"
        );
        _;
    }

    modifier onlyActiveBidder() {
        (
            bytes32 dbRef,
            Registration.USER_STATUS status,
            bytes32 role
        ) = registration.users(_msgSender());

        require(
            status == Registration.USER_STATUS.APPROVED,
            "Property: bidder must be in APPROVED status"
        );
        _;
    }

    modifier onlyActiveSeller() {
        (
            bytes32 dbRef,
            Registration.USER_STATUS status,
            bytes32 role
        ) = registration.users(_msgSender());

        require(
            status == Registration.USER_STATUS.APPROVED,
            "Property: seller must be in APPROVED status"
        );
        _;
    }

    constructor(Registration _registration) public {
        require(
            address(_registration) != address(0),
            "Please provide Registration contract address"
        );

        registration = _registration;
    }

    function hashThat(bytes memory _location, bytes32 _city)
        public
        view
        returns (bytes32 hash)
    {
        hash = keccak256(abi.encodePacked(_location, _city));
    }

    function putPropertyOnSale(bytes32 _propertyHash, address _sender) public {
        require(
            properties[_propertyHash].status == PROPERTY_STATUS.APPROVED,
            "Property: property should be APPROVED"
        );

        require(
            properties[_propertyHash].owner == _sender,
            "Property: seller must be owner"
        );

        properties[_propertyHash].status = PROPERTY_STATUS.ON_SALE;
    }

    function registerProperty(
        bytes memory _document,
        bytes memory _location,
        bytes32 _city,
        uint256 _documentId
    ) public payable onlyActiveSeller {
        bytes32 propertyHash = hashThat(_location, _city);

        require(
            properties[propertyHash].status == PROPERTY_STATUS.NULL,
            "Property: property registred before"
        );

        properties[propertyHash].propertyHash = propertyHash;
        properties[propertyHash].owner = msg.sender;
        properties[propertyHash].document = _document;
        properties[propertyHash].status = PROPERTY_STATUS.PENDING;
        properties[propertyHash].city = _city;
        properties[propertyHash].location = _location;
        properties[propertyHash].documentId = _documentId;

        propertiesIds.push(propertyHash);

        //approveProperty2(propertyHash);

        emit registerPropertyLog(propertyHash, block.timestamp);
    }

    function storePropertyDbRef(bytes32 _propertyHash, bytes memory _result)
        public
    {
        require(
            properties[_propertyHash].status == PROPERTY_STATUS.PENDING,
            "Property: property not registred before"
        );

        if (
            keccak256(abi.encode(_result)) == keccak256(abi.encode("404")) ||
            keccak256(abi.encode(_result)) == keccak256(abi.encode("error"))
        ) {
            properties[_propertyHash].status = PROPERTY_STATUS.APPROVED_FAILD;
            properties[_propertyHash].dbRef = _result;
            emit approvePropertyLog(_propertyHash, block.timestamp);
        } else {
            properties[_propertyHash].status = PROPERTY_STATUS.APPROVED;
            properties[_propertyHash].dbRef = _result;

            emit approvePropertyLog(_propertyHash, block.timestamp);
        }
    }

    /*function approveProperty2(bytes32 _propertyHash) public {
           
        bytes32 oraclizeID = provable_query(
            "URL",
            "http://35.225.46.206:4002");
        resultId[oraclizeID] = _propertyHash;
    }

    function approveProperty(bytes32 _propertyHash) public {
        bytes32 oraclizeID = provable_query(
            "URL",
            "http://35.225.46.206:4002"
        );
        bytes32 oraclizeID = provable_query(
            "URL",
            
            
            string(
                abi.encodePacked(registration.notarialServer(),bytes("/verifyDocument/"), bytes32ToString(_propertyHash))
            )
        );
        resultId[oraclizeID] = _propertyHash;
    }

    function __callback(bytes32 _oraclizeID, string memory _result)
        public
        override
    {
        require(
            properties[resultId[_oraclizeID]].status == PROPERTY_STATUS.PENDING,
            "Property: property not registred before"
        );

        bytes memory result = bytes(_result);

        if (
            keccak256(abi.encode(_result)) == keccak256(abi.encode("404")) ||
            keccak256(abi.encode(_result)) == keccak256(abi.encode("error"))
        ) {
            properties[resultId[_oraclizeID]].status = PROPERTY_STATUS
                .APPROVED_FAILD;
            properties[resultId[_oraclizeID]].dbRef = result;
            emit approvePropertyLog(resultId[_oraclizeID], block.timestamp);
        } else {
            properties[resultId[_oraclizeID]].status = PROPERTY_STATUS.APPROVED;
            properties[resultId[_oraclizeID]].dbRef = result;

            emit approvePropertyLog(resultId[_oraclizeID], block.timestamp);
        }
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes32[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes32[i / 2] >> 4);

            bytesArray[i] = toByte(_f);
            i = i + 1;
            bytesArray[i] = toByte(_l);
        }
        return string(bytesArray);
    }

    function toByte(uint8 _uint8) public pure returns (bytes1) {
        if (_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }*/

    function transferPropertyOwnership(
        bytes32 _propertyHash,
        address _newOwner,
        bytes memory _newDocument,
        uint256 _auctionId
    ) public {
        require(
            properties[_propertyHash].status == PROPERTY_STATUS.ON_SALE,
            "Property: property not on sale"
        );

        require(
            properties[_propertyHash].owner != _newOwner,
            "Property: can't transfer to same owner "
        );

        properties[_propertyHash].owner = _newOwner;
        properties[_propertyHash].document = _newDocument;
        properties[_propertyHash].status = PROPERTY_STATUS.APPROVED;

        emit transferPropertyOwnershipLog(
            _propertyHash,
            properties[_propertyHash].owner,
            _auctionId,
            block.timestamp
        );
    }

    function getProperty(bytes32 _propertyHash)
        public
        view
        returns (PropertyInfo memory)
    {
        return properties[_propertyHash];
    }

    function getProperties()
        public
        view
        returns (
            bytes32[] memory,
            address[] memory,
            bytes[] memory,
            PROPERTY_STATUS[] memory,
            bytes32[] memory,
            bytes[] memory,
            uint256[] memory,
            bytes[] memory
        )
    {
        bytes32[] memory _propertyHash = new bytes32[](propertiesIds.length);
        address[] memory _owner = new address[](propertiesIds.length);
        bytes[] memory _document = new bytes[](propertiesIds.length);
        PROPERTY_STATUS[] memory _status = new PROPERTY_STATUS[](
            propertiesIds.length
        );
        bytes32[] memory _city = new bytes32[](propertiesIds.length);
        bytes[] memory _location = new bytes[](propertiesIds.length);
        uint256[] memory _documentId = new uint256[](propertiesIds.length);
        bytes[] memory _dbRef = new bytes[](propertiesIds.length);

        for (uint256 i = 0; i < propertiesIds.length; i++) {
            _propertyHash[i] = properties[propertiesIds[i]].propertyHash;
            _owner[i] = properties[propertiesIds[i]].owner;
            _document[i] = properties[propertiesIds[i]].document;
            _status[i] = properties[propertiesIds[i]].status;
            _city[i] = properties[propertiesIds[i]].city;
            _location[i] = properties[propertiesIds[i]].location;
            _documentId[i] = properties[propertiesIds[i]].documentId;
            _dbRef[i] = properties[propertiesIds[i]].dbRef;
        }

        return (
            _propertyHash,
            _owner,
            _document,
            _status,
            _city,
            _location,
            _documentId,
            _dbRef
        );
    }

    function getPropertyStatus(bytes32 _propertyHash)
        public
        view
        returns (PROPERTY_STATUS status)
    {
        return properties[_propertyHash].status;
    }

    function getPropertyCity(bytes32 _propertyHash)
        public
        view
        returns (bytes32)
    {
        return properties[_propertyHash].city;
    }

    function getPropertyLocation(bytes32 _propertyHash)
        public
        view
        returns (bytes memory)
    {
        return properties[_propertyHash].location;
    }

    function _pause() public override(Pausable) onlyOwner {
        super._pause();
    }

    function _unpause() public override(Pausable) onlyOwner {
        super._unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

/*
 * Digital Challenges Bootcamp by code.mcit.gov.sa
 * Team #34
 * Author by Faisal Albalwy
 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract Registration is Ownable, Pausable, AccessControl {
    enum USER_STATUS {
        NULL,
        PENDING,
        APPROVED
    }

    bytes32 public seller =
        0x359bb5e6756947e4656c26833a5300814e0e700f7e4a1483ba5f7526772dad17;
    bytes32 public bidder =
        0xec5a63db64b88660c968f48831eca6e3e2377bd4c652081c86a14953f21484ea;
    bytes32 public appraiser =
        0xa7c989b39d0637707f326937126316dfd6a2f838936ec16b3e739b4e5f5c8f78;

    mapping(address => User) public users;
    address[] private usersIds;

    struct User {
        bytes32 dbRef;
        USER_STATUS status;
        bytes32 role;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) == true,
            "Registration: caller is not the owner"
        );
        _;
    }

    event registerUserLog(
        address user,
        bytes32 role,
        USER_STATUS status,
        uint256 timestamp
    );

    event approveUserLog(
        address user,
        bytes32 role,
        USER_STATUS status,
        uint256 timestamp
    );

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function registerUser(bytes32 _dbRef, bytes32 _role) public whenNotPaused {
        require(
            users[_msgSender()].status == USER_STATUS.NULL,
            "Registration: user must be in NULL status"
        );
        users[_msgSender()].status = USER_STATUS.PENDING;
        users[_msgSender()].dbRef = _dbRef;
        users[_msgSender()].role = keccak256(abi.encodePacked(_role));

        usersIds.push(_msgSender());

        emit registerUserLog(
            _msgSender(),
            users[_msgSender()].role,
            USER_STATUS.PENDING,
            block.timestamp
        );
    }

    function _pause() public override(Pausable) whenNotPaused onlyOwner {
        super._pause();
    }

    function _unpause() public override(Pausable) whenPaused onlyOwner {
        super._unpause();
    }

    function approveUser(address _user) public whenNotPaused onlyAdmin {
        require(
            users[_user].status == USER_STATUS.PENDING,
            "Registration: user must be in PENDING status"
        );
        users[_user].status = USER_STATUS.APPROVED;
        grantRole(users[_user].role, _user);

        emit approveUserLog(
            _user,
            users[_user].role,
            USER_STATUS.APPROVED,
            block.timestamp
        );
    }

    function func(bytes32 _input) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_input));
    }

    function getUsers()
        public
        view
        returns (
            address[] memory,
            bytes32[] memory,
            USER_STATUS[] memory,
            bytes32[] memory
        )
    {
        address[] memory _wallet = new address[](usersIds.length);
        bytes32[] memory _dbRef = new bytes32[](usersIds.length);
        USER_STATUS[] memory _status = new USER_STATUS[](usersIds.length);
        bytes32[] memory _role = new bytes32[](usersIds.length);

        for (uint256 i = 0; i < usersIds.length; i++) {
            _wallet[i] = usersIds[i];
            _dbRef[i] = users[usersIds[i]].dbRef;
            _status[i] = users[usersIds[i]].status;
            _role[i] = users[usersIds[i]].role;
        }

        return (_wallet, _dbRef, _status, _role);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

/*
 * Digital Challenges Bootcamp by code.mcit.gov.sa
 * Team #34
 * Author by Faisal Albalwy
 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract Wallet is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;

    event Deposited(address indexed _payee, uint256 weiAmount);
    event Withdrawn(address indexed _payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function escrowBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function depositsOf(address _payee) public view returns (uint256) {
        return _deposits[_payee];
    }

    function deposit(address _payee) public payable virtual nonReentrant {
        uint256 amount = msg.value;
        _deposits[_payee] = _deposits[_payee].add(amount);
        emit Deposited(_payee, amount);
    }

    function increaseBalance(address _payee, uint256 _amount) public {
        _deposits[_payee] = _deposits[_payee].add(_amount);
    }

    function decressBalance(address _payee, uint256 _amount) public {
        _deposits[_payee] = _deposits[_payee].sub(_amount);
    }

    function withdraw() public virtual nonReentrant {
        require(_deposits[msg.sender] > 0, "Escrow: balance zero");
        uint256 payment = _deposits[msg.sender];
        _deposits[msg.sender] = 0;
        msg.sender.sendValue(payment);
        emit Withdrawn(msg.sender, payment);
    }

    function _withdraw() public virtual nonReentrant onlyOwner {
        msg.sender.sendValue(address(this).balance);
        emit Withdrawn(msg.sender, address(this).balance);
    }
}

