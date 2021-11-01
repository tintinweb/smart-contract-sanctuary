// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/ITroveLinkAccessController.sol";

/**
 * @title contract module that provides a role-jurisdiction-based access control mechanism;
 * This module contains role/jurisdiction/access management methods
 */
contract TroveLinkAccessController is ITroveLinkAccessController, Initializable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    address private _controller;
    bool private _initialized;
    EnumerableSet.Bytes32Set private _jurisdictions;
    EnumerableSet.Bytes32Set private _roles;
    mapping(bytes32 => mapping(bytes32 => mapping(address => bytes32))) private _attachments;
    mapping(bytes32 => mapping(bytes32 => EnumerableSet.AddressSet)) private _jurisdictionMembers;
    mapping(bytes32 => uint256) private _jurisdictionMembersCount;
    mapping(bytes32 => string) private _jurisdictionName;
    mapping(bytes32 => mapping(address => uint256)) private _roleJurisdictionsCount;
    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;
    mapping(bytes32 => string) private _roleName;

    /**
     * @notice Returns controller address
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @notice Returns contract initialization status
     */
    function initialized() public view returns (bool) {
        return _initialized;
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function jurisdictionCount() external view override(ITroveLinkAccessController) returns (uint256) {
        return _jurisdictions.length();
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function roleCount() external view override(ITroveLinkAccessController) returns (uint256) {
        return _roles.length();
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function attachment(
        bytes32 role_,
        bytes32 jurisdiction_,
        address account_
    ) external view override(ITroveLinkAccessController) returns (bytes32) {
        return _attachments[role_][jurisdiction_][account_];
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function hasRole(
        bytes32 role_,
        address account_
    ) external view override(ITroveLinkAccessController) returns (bool) {
        return _roleMembers[role_].contains(account_);
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function hasJurisdiction(
        bytes32 role_,
        bytes32 jurisdiction_,
        address account_
    ) external view override(ITroveLinkAccessController) returns (bool) {
        return _jurisdictionMembers[role_][jurisdiction_].contains(account_);
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function isJurisdiction(bytes32 jurisdiction_) external view override(ITroveLinkAccessController) returns (bool) {
        return _jurisdictions.contains(jurisdiction_);
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function isRole(bytes32 role_) external view override(ITroveLinkAccessController) returns (bool) {
        return _roles.contains(role_);
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function jurisdiction(uint256 index_) external view override(ITroveLinkAccessController) returns (bytes32) {
        return _jurisdictions.at(index_);
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function jurisdictionMember(
        bytes32 role_,
        bytes32 jurisdiction_,
        uint256 index_
    ) external view override(ITroveLinkAccessController) returns (address) {
        return _jurisdictionMembers[role_][jurisdiction_].at(index_);
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function jurisdictionMemberCount(
        bytes32 jurisdiction_
    ) external view override(ITroveLinkAccessController) returns (uint256) {
        return _jurisdictionMembersCount[jurisdiction_];
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function jurisdictionMemberCount(
        bytes32 role_,
        bytes32 jurisdiction_
    ) external view override(ITroveLinkAccessController) returns (uint256) {
        return _jurisdictionMembers[role_][jurisdiction_].length();
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function jurisdictionName(
        bytes32 jurisdiction_
    ) external view override(ITroveLinkAccessController) returns (string memory) {
        return _jurisdictionName[jurisdiction_];
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function role(uint256 index_) external view override(ITroveLinkAccessController) returns (bytes32) {
        return _roles.at(index_);
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function roleJurisdictionsCount(
        address account_, bytes32 role_
    ) external view override(ITroveLinkAccessController) returns (uint256) {
        return _roleJurisdictionsCount[role_][account_];
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function roleMember(
        bytes32 role_,
        uint256 index_
    ) external view override(ITroveLinkAccessController) returns (address) {
        return _roleMembers[role_].at(index_);
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function roleMemberCount(bytes32 role_) external view override(ITroveLinkAccessController) returns (uint256) {
        return _roleMembers[role_].length();
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     */
    function roleName(bytes32 role_) external view override(ITroveLinkAccessController) returns (string memory) {
        return _roleName[role_];
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     * @param name_ Must be not already added
     */
    function addJurisdiction(string memory name_) external override(ITroveLinkAccessController) returns (bool) {
        bytes32 jurisdiction_ = keccak256(abi.encode(name_));
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        require(!_jurisdictions.contains(jurisdiction_), "Jurisdiction already exist");
        _addJurisdiction(jurisdiction_, name_);
        return true;
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     * @param name_ Must be not already added
     */
    function addRole(string memory name_) external override(ITroveLinkAccessController) returns (bool) {
        bytes32 role_ = keccak256(abi.encode(name_));
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        require(!_roles.contains(role_), "Role already exist");
        _addRole(role_, name_);
        return true;
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     * @param role_ Must be an existing role
     * @param jurisdiction_ Must be an existing jurisdiction
     */
    function grantAccess(
        address account_,
        bytes32 role_,
        bytes32 jurisdiction_,
        bytes32 attachment_
    ) external override(ITroveLinkAccessController) returns (bool) {
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        require(_roles.contains(role_), "Role not exist");
        require(_jurisdictions.contains(jurisdiction_), "Jurisdiction not exist");
        _grantAccess(account_, role_, jurisdiction_, attachment_);
        return true;
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     * @param jurisdiction_ Must be an existing jurisdiction
     * @param jurisdiction_ Jurisdiction members count must be equal to 0
     */
    function removeJurisdiction(bytes32 jurisdiction_) external override(ITroveLinkAccessController) returns (bool) {
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        require(_jurisdictions.contains(jurisdiction_), "Jurisdiction not exist");
        require(_jurisdictionMembersCount[jurisdiction_] == 0, "Jurisdiction has members");
        string memory name_ = _jurisdictionName[jurisdiction_];
        _jurisdictions.remove(jurisdiction_);
        delete _jurisdictionName[jurisdiction_];
        emit JurisdictionRemoved(jurisdiction_, name_);
        return true;
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     * @param role_ Must be an existing role
     * @param role_ Role members count must be equal to 0
     */
    function removeRole(bytes32 role_) external override(ITroveLinkAccessController) returns (bool) {
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        require(_roles.contains(role_), "Role not exist");
        require(_roleMembers[role_].length() == 0, "Role has members");
        string memory name_ = _roleName[role_];
        _roles.remove(role_);
        delete _roleName[role_];
        emit RoleRemoved(role_, name_);
        return true;
    }

    /**
     * @inheritdoc ITroveLinkAccessController
     * @param role_ Must be an existing role
     * @param jurisdiction_ Must be an existing jurisdiction
     * @param account_ Must be a role_ jurisdiction_ member
     */
    function revokeAccess(
        address account_,
        bytes32 role_,
        bytes32 jurisdiction_
    ) external override(ITroveLinkAccessController) returns (bool) {
        address sender = msg.sender;
        require(_initialized, "Not initialized");
        require(sender == _controller || sender == account_, "Invalid sender");
        require(_roles.contains(role_), "Role not exist");
        require(_jurisdictions.contains(jurisdiction_), "Jurisdiction not exist");
        require(_jurisdictionMembers[role_][jurisdiction_].contains(account_), "Account not jurisdiction role member");
        uint256 roleJurisdictionsCount_ = _roleJurisdictionsCount[role_][account_].sub(1);
        _jurisdictionMembers[role_][jurisdiction_].remove(account_);
        _jurisdictionMembersCount[jurisdiction_] = _jurisdictionMembersCount[jurisdiction_].sub(1);
        _roleJurisdictionsCount[role_][account_] = roleJurisdictionsCount_;
        _attachments[role_][jurisdiction_][account_] = bytes32(0);
        if (roleJurisdictionsCount_ == 0) _roleMembers[role_].remove(account_);
        emit AccessRevoked(account_, role_, jurisdiction_);
        return true;
    }

    /**
     * @notice Method for contract initializing
     * @dev For success works contract must not be already initialized
     * Member parameters lengths should be equals
     * Can emits a multiple ({RoleAdded}, {JurisdictionAdded}, {AccessGranted}) events
     * @param controller_ Controller address
     * @param controller_ Must not be equal to zero address
     * @param roles_ Initial roles names
     * @param jurisdictions_ Initial jurisdictions names
     * @param members_ Initial members addresses
     * @param memberRoles_ Iniital members roles
     * @param memberJurisdictions_ Initial members jurisdictions
     * @return boolean value indicating whether the operation succeded
     */
    function initialize(
        address controller_,
        string[] memory roles_,
        string[] memory jurisdictions_,
        address[] memory members_,
        bytes32[] memory memberRoles_,
        bytes32[] memory memberJurisdictions_
    ) public initializer() returns (bool) {
        require(!_initialized, "Already initialized");
        require(controller_ != address(0), "Controller is zero address");
        require(
            members_.length == memberRoles_.length && members_.length == memberJurisdictions_.length,
            "Invalid member params length"
        );
        _controller = controller_;
        uint256 iterator;
        for (iterator = 0; iterator < roles_.length; iterator++) {
            _addRole(keccak256(abi.encode(roles_[iterator])), roles_[iterator]);
        }
        for (iterator = 0; iterator < jurisdictions_.length; iterator++) {
            _addJurisdiction(keccak256(abi.encode(jurisdictions_[iterator])), jurisdictions_[iterator]);
        }
        for (iterator = 0; iterator < members_.length; iterator++) {
            bytes32 role_ = memberRoles_[iterator];
            bytes32 jurisdiction_ = memberJurisdictions_[iterator];
            require(_roles.contains(role_), "Role not exist");
            require(_jurisdictions.contains(jurisdiction_), "Jurisdiction not exist");
            _grantAccess(members_[iterator], role_, jurisdiction_, bytes32(0));
        }
        _initialized = true;
        return true;
    }

    /**
     * @dev Private method for adding a Jurisdiction
     * Can emits a {JurisdictionAdded} event
     * @param jurisdiction_ Jurisdiction hash
     * @param jurisdiction_ Must be a non-zero hash
     * @param name_ Jurisdiction name
     */
    function _addJurisdiction(bytes32 jurisdiction_, string memory name_) private {
        require(jurisdiction_ != bytes32(0), "Jurisdiction is zero bytes");
        if (_jurisdictions.add(jurisdiction_)) {
            _jurisdictionName[jurisdiction_] = name_;
            emit JurisdictionAdded(jurisdiction_, name_);
        }
    }

    /**
     * @dev Private method for adding a role
     * Can emits a {RoleAdded} event
     * @param role_ Role hash
     * @param role_ Must be a non-zero hash
     * @param name_ Role name
     */
    function _addRole(bytes32 role_, string memory name_) private {
        require(role_ != bytes32(0), "Role is zero bytes");
        if (_roles.add(role_)) {
            _roleName[role_] = name_;
            emit RoleAdded(role_, name_);
        }
    }

    /**
     * @dev Private method for access granting
     * Emits a {AccessGranted} event
     * @param account_ Account address
     * @param role_ Role hash
     * @param jurisdiction_ Jurisdiction hash
     * @param attachment_ Attachment hash
     */
    function _grantAccess(
        address account_,
        bytes32 role_,
        bytes32 jurisdiction_,
        bytes32 attachment_
    ) private {
        if (!_jurisdictionMembers[role_][jurisdiction_].contains(account_)) {
            _roleMembers[role_].add(account_);
            _jurisdictionMembers[role_][jurisdiction_].add(account_);
            _jurisdictionMembersCount[jurisdiction_] = _jurisdictionMembersCount[jurisdiction_].add(1);
            _roleJurisdictionsCount[role_][account_] = _roleJurisdictionsCount[role_][account_].add(1);
        }
        _attachments[role_][jurisdiction_][account_] = attachment_;
        emit AccessGranted(account_, role_, jurisdiction_, attachment_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ITroveLinkAccessController {
    /* External view functions */

    /**
     * @notice Returns jursidctions count
     */
    function jurisdictionCount() external view returns (uint256);

    /**
     * @notice Returns roles count
     */
    function roleCount() external view returns (uint256);

    /**
     * @notice Returns attachment hash for specific jurisdiction in specific role
     * @param role_ Role hash
     * @param jurisdiction_ Jurisdiction hash
     * @param account_ Account address
     */
    function attachment(bytes32 role_, bytes32 jurisdiction_, address account_) external view returns (bytes32);

    /**
     * @notice Returns boolean value - whether the account has role
     * @param role_ Role hash
     * @param account_ Account address
     */
    function hasRole(bytes32 role_, address account_) external view returns (bool);

    /**
     * @notice Returns boolean value - whether the account has jurisdiction in specific role
     * @param role_ Role hash
     * @param jurisdiction_ Jurisdiction hash
     * @param account_ Account address
     */
    function hasJurisdiction(bytes32 role_, bytes32 jurisdiction_, address account_) external view returns (bool);

    /**
     * @notice Returns boolean value - whether the hash is a jurisdiction
     * @param jurisdiction_ Jurisdiction hash
     */
    function isJurisdiction(bytes32 jurisdiction_) external view returns (bool);

    /**
     * @notice Returns boolean value - whether the hash is a role
     * @param role_ Role hash
     */
    function isRole(bytes32 role_) external view returns (bool);

    /**
     * @notice Returns jurisdiction hash located by index_
     * @param index_ Jurisdiction index
     * @dev For success work index_ value should be less than jurisdictionCount
     */
    function jurisdiction(uint256 index_) external view returns (bytes32);

    /**
     * @notice Returns jurisdiction member address located by index_ in specific role
     * @param role_ Role hash
     * @param jurisdiction_ Jurisdiction hash
     * @param index_ Jurisdiction member index
     * @dev For success work index_ value should be less than jurisdictionMemberCount(role, jurisdiction)
     */
    function jurisdictionMember(bytes32 role_, bytes32 jurisdiction_, uint256 index_) external view returns (address);

    /**
     * @notice Returns jurisdiction members count across all roles
     * @param jurisdiction_ Jurisdiction hash
     */
    function jurisdictionMemberCount(bytes32 jurisdiction_) external view returns (uint256);

    /**
     * @notice Returns jurisdiction members count for specific role
     * @param role_ Role hash
     * @param jurisdiction_ Jurisdiction hash
     */
    function jurisdictionMemberCount(bytes32 role_, bytes32 jurisdiction_) external view returns (uint256);

    /**
     * @notice Returns jurisdiction text name
     * @param jurisdiction_ Jurisdiction hash
     */
    function jurisdictionName(bytes32 jurisdiction_) external view returns (string memory);

    /**
     * @notice Returns role hash located by index_
     * @param index_ Role index
     * @dev For success work index_ value should be less than roleCount
     */
    function role(uint256 index_) external view returns (bytes32);

    /**
     * @notice Returns jurisdictions count for account in specific role
     * @param account_ Account address
     * @param role_ Role hash
     */
    function roleJurisdictionsCount(address account_, bytes32 role_) external view returns (uint256);

    /**
     * @notice Returns role member located by index_
     * @param role_ Role hash
     * @param index_ Role member index
     * @dev For success work index_ value should be less than roleMemberCount
     */
    function roleMember(bytes32 role_, uint256 index_) external view returns (address);

    /**
     * @notice Returns role members count
     * @param role_ Role hash
     */
    function roleMemberCount(bytes32 role_) external view returns (uint256);

    /**
     * @notice Returns role text name
     * @param role_ Role hash
     */
    function roleName(bytes32 role_) external view returns (string memory);

    /* Events */

    /**
     * @dev Emmitted when access is granted
     * @param account_ Account address
     * @param role_ Role that was granted
     * @param jurisdiction_ Jurisdiction that was granted
     * @param attachment_ Attachment hash that associated with this granting 
     */
    event AccessGranted(address account_, bytes32 role_, bytes32 jurisdiction_, bytes32 attachment_);

    /**
     * @dev Emmitted when access is revoked
     * @param account_ Account address
     * @param role_ Role that was revoked
     * @param jurisdiction_ Jurisdiction that was revoked
     */
    event AccessRevoked(address account_, bytes32 role_, bytes32 jurisdiction_);

    /**
     * @dev Emmitted when jurisdiction is added
     * @param jurisdiction_ Jurisdiction hash that was added
     * @param name_ Jurisdiction name that was added
     */
    event JurisdictionAdded(bytes32 jurisdiction_, string name_);

    /**
     * @dev Emmitted when jurisdiction is removed
     * @param jurisdiction_ Jurisdiction hash that was removed
     * @param name_ Jurisdiction name that was removed
     */
    event JurisdictionRemoved(bytes32 jurisdiction_, string name_);

    /**
     * @dev Emmitted when role is added
     * @param role_ Role hash that was added
     * @param name_ Role name that was added
     */
    event RoleAdded(bytes32 role_, string name_);

    /**
     * @dev Emmitted when role is removed
     * @param role_ Role hash that was removed
     * @param name_ Role name that was removed
     */
    event RoleRemoved(bytes32 role_, string name_);

    /* External functions */

    /**
     * @notice Method for adding a jurisdiction
     * @dev For success works:
     *  - can be called only by Controller address that stores in contract
     *  - contract must be already initialized
     * Emits a {JurisdictionAdded} event
     * @param name_ Jurisdiction name to add
     * @return boolean value indicating whether the operation succeded
     */
    function addJurisdiction(string memory name_) external returns (bool);

    /**
     * @notice Method for adding a role
     * @dev For success works:
     *  - can be called only by Controller address that stores in contract
     *  - contract must be already initialized
     * Emits a {RoleAdded} event
     * @param name_ Role name to add
     * @return boolean value indicating whether the operation succeded
     */
    function addRole(string memory name_) external returns (bool);

    /**
     * @notice Method for granting access
     * @dev For success works:
     *  - can be called only by Controller address that stores in contract
     *  - contract must be already initialized
     * Emits a {AccessGranted} event
     * @param account_ Account address
     * @param role_ Role hash
     * @param jurisdiction_ Jurisdiction hash
     * @param attachment_ Attachment hash which need to associate with this granting
     * @return boolean value indicating whether the operation succeded
     */
    function grantAccess(
        address account_,
        bytes32 role_,
        bytes32 jurisdiction_,
        bytes32 attachment_
    ) external returns (bool);

    /**
     * @notice Method for removing a jurisdiction
     * @dev For success works:
     *  - can be called only by Controller address that stores in contract
     *  - contract must be already initialized
     * Emits a {JurisdictionRemoved} event
     * @param jurisdiction_ Jurisdiction hash to remove
     * @return boolean value indicating whether the operation succeded
     */
    function removeJurisdiction(bytes32 jurisdiction_) external returns (bool);

    /**
     * @notice Method for removing a role
     * @dev For success works:
     *  - can be called only by Controller address that stores in contract
     *  - contract must be already initialized
     * Emits a {RoleRemoved} event
     * @param role_ Role hash to remove
     * @return boolean value indicating whether the operation succeded
     */
    function removeRole(bytes32 role_) external returns (bool);

    /**
     * @notice Method for revoking access
     * @dev For success works:
     *  - can be called by Controller address that stores in contract OR by account_
     *  - contract must be already initialized
     * Emits a {AccessRevoked} event
     * @param account_ Account address
     * @param role_ Role hash
     * @param jurisdiction_ Jurisdiction hash
     * @return boolean value indicating whether the operation succeded
     */
    function revokeAccess(address account_, bytes32 role_, bytes32 jurisdiction_) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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