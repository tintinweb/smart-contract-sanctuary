/**
 *Submitted for verification at polygonscan.com on 2021-10-25
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IStakeMirrorNFT is IERC721 {


    function getStakeInfo(
        uint256 stakeId
    )
        external
        returns (uint256, uint256, uint256);

    function getStakeTokenIds(
        address account
    )
        external
        returns (uint256[] memory);

    function isHolder(address account) external view returns (bool);

    function stakes(uint256 id) external view returns (uint256 amount, uint256 multiplier, uint256 depositedAt);

    function stakerIds(address account, uint256 id) external view returns (uint256);

    function addOperator(address account) external;

    function removeOperator(address account) external;

    function checkOperator(address account) external view returns (bool);
}

/**
 * Voting contract that offers multiple options to voters.
 */
contract MultipleVotingMirror is Ownable, AccessControl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    Counters.Counter public pollIds;
    IStakeMirrorNFT[] private _stakePools;

    /* EVENTS  */
    event VoteCasted(address indexed voter, uint256 pollID, uint256 vote, uint256 weight);
	event PollCreated(address indexed creator, uint256 pollID, uint256 votingTimeInDays);
	event PollEnded(uint256 pollID, uint256 winningOptionID);

    /* POLL */
    struct Poll {
		uint256 startTime; // poll start timestamp
		uint256 endTime; // poll end timestamp
        uint256 minimumStakeTimeInDays; // number of days that implies how long stakers should remain staked in StakePools to be able to vote
        uint256 winningOptionId; // poll result, starts from 1
		string description; // poll description
        string[] options; // poll option string, first option string is default empty ('')
		bool isEnded; // poll status
		address creator; // poll creator address
		address[] voters; // poll voter address array
	}

    /* VOTER */
    struct Voter {
        uint256 vote; // vote option index, `0` implies he/she did not cast vote
        uint256 weight; // voter's voting weight (derived from StakePool)
    }

    // poll id => poll info
    mapping(uint256 => Poll) private _polls;
    // poll id => voter address => voter info
    mapping(uint256 => mapping(address => Voter)) private _voters;
    // poll id => option id => vote cast number
    mapping(uint256 => mapping(uint256 => uint256)) private _votes;

    constructor(
        address[] memory stakePools_
    )
    {
        for (uint256 i = 0; i < stakePools_.length; i++) {
            require(stakePools_[i] != address(0), "MultipleVoting#constructor: STAKE_POOL_ADDRESS_INVALID");
            _stakePools.push(IStakeMirrorNFT(stakePools_[i]));
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    /***********************|
    |          Role         |
    |______________________*/

    /**
     * @dev Restricted to members of the admin role.
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MultipleVoting#onlyAdmin: CALLER_NO_ADMIN_ROLE");
        _;
    }

    /**
     * @dev Restricted to members of the operator role.
     */
    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "MultipleVoting#onlyOperator: CALLER_NO_OPERATOR_ROLE");
        _;
    }

    /**
     * @dev Add an account to the operator role.
     * @param account address
     */
    function addOperator(
        address account
    )
        public
        onlyAdmin
    {
        require(!hasRole(OPERATOR_ROLE, account), "MultipleVoting#addOperator: ALREADY_OERATOR_ROLE");
        grantRole(OPERATOR_ROLE, account);
    }

    /**
     * @dev Remove an account from the operator role.
     * @param account address
     */
    function removeOperator(
        address account
    )
        public
        onlyAdmin
    {
        require(hasRole(OPERATOR_ROLE, account), "MultipleVoting#removeOperator: NO_OPERATOR_ROLE");
        revokeRole(OPERATOR_ROLE, account);
    }

    /**
     * @dev Check if an account is operator.
     * @param account address
     */
    function checkOperator(
        address account
    )
        public
        view
        returns (bool)
    {
        return hasRole(OPERATOR_ROLE, account);
    }

    /*****************************|
    |          Stake Pool         |
    |____________________________*/

    /**
     * @dev Add a new stake pool.
     * @param _sPool new stake pool address.
     */
    function addStakePool(
        address _sPool
    )
        external
        onlyOperator
    {
        require(_sPool != address(0), "MultipleVoting#addStakePool: STAKE_POOL_ADDRESS_INVALID");
        for (uint256 i = 0; i < _stakePools.length; i++) {
            require(address(_stakePools[i]) != _sPool, "MultipleVoting#addStakePool: STAKE_POOL_ADDRESS_ALREADY_FOUND");
        }
        _stakePools.push(IStakeMirrorNFT(_sPool));
    }

    /**
     * @dev Remove from stake pool addresses.
     * @param _sPool stake pool address.
     */
    function removeStakePool(
        address _sPool
    )
        external
        onlyOperator
    {
        bool isDeleted;
        require(_sPool != address(0), "MultipleVoting#removeStakePool: STAKE_POOL_ADDRESS_INVALID");
        for (uint256 i = 0; i < _stakePools.length; i++) {
            if (address(_stakePools[i]) == _sPool) {
                if (i != _stakePools.length - 1) {
                    _stakePools[i] = _stakePools[_stakePools.length - 1];
                }
                _stakePools.pop();
                isDeleted = true;
                break;
            }
        }
        require(isDeleted, "MultipleVoting#removeStakePool: STAKE_POOL_ADDRESS_NOT_FOUND");
    }

    /**
     * @dev Return array of stake pool address.
     */
    function getStakePools()
        external
        view
        returns (address[] memory)
    {
        address[] memory sPoolAddrs = new address[](_stakePools.length);
        for (uint256 i = 0; i < _stakePools.length; i++) {
            sPoolAddrs[i] = address(_stakePools[i]);
        }
        return sPoolAddrs;
    }

    /***********************|
    |          Poll         |
    |______________________*/

    /*
	 * Modifier that checks for a valid poll ID.
	 */
	modifier validPoll(
        uint256 _pollId
    )
	{
		require(_pollId > 0 && _pollId <= pollIds.current(), "MultipleVoting#validPoll: POLL_ID_INVALID");
		_;
	}

    /* GETTERS */

    /**
     * @dev Return poll general info.
     * Except for voting result.
     *
     * @param _pollId poll id
     * @return description string, option string array, poll startTime, endTime, minimumStakeTimeInDays, status(ENDED), creator address, voter address array
     */
    function getPollInfo(
        uint256 _pollId
    )
        public
        view
        validPoll(_pollId)
        returns (string memory, string[] memory, uint256, uint256, uint256, bool, address, address[] memory)
    {
        Poll memory poll = _polls[_pollId];
        return (poll.description, poll.options, poll.startTime, poll.endTime, poll.minimumStakeTimeInDays, poll.isEnded, poll.creator, poll.voters);
    }

    /**
     * @dev Return poll voting info.
     * If poll is not ended, operators can call.
     * After ended, any user can call.
     * @param _pollId poll id
     * @return poll votes detail (first element is default 0), poll winning option id (`0` implies poll is not ended)
     */
    function getPollVotingInfo(
        uint256 _pollId
    )
        public
        view
        validPoll(_pollId)
        returns (uint256[] memory, uint256)
    {
        Poll memory poll = _polls[_pollId];
        require(poll.isEnded || checkOperator(_msgSender()), "MultipleVoting#getPollVotingInfo: POLL_NOT_ENDED__CALLER_NO_OPERATOR");
        uint256[] memory votes = new uint256[](poll.options.length);
        for (uint256 i = 0; i < votes.length; i++) {
            votes[i] = _votes[_pollId][i];
        }
        return (votes, poll.winningOptionId);
    }

    /**
     * @dev Return `_voter` info for `_pollId` poll.
     * If poll is not ended, operators can call.
     * After ended, any user can call.
     *
     * @param _pollId poll id
     * @param _voter address of voter
     * @return voting option index (`0` implies he/she did not cast vote), voting weight
     */
    function getVoterInfo(
        uint256 _pollId,
        address _voter
    )
        public
        view
        validPoll(_pollId)
        returns (uint256, uint256)
    {
        require(_polls[_pollId].isEnded || checkOperator(_msgSender()), "MultipleVoting#getVoterInfo: POLL_NOT_ENDED__CALLER_NO_OPERATOR");
        return (_voters[_pollId][_voter].vote, _voters[_pollId][_voter].weight);
    }

    /**
	 * @dev Create a new poll.
     *
     * @param _description poll description.
     * @param _durationTimeInDays poll duration time.
     * @param _minimumStakeTimeInDays minimum stake duration time for poll voters.
	 */
    function createPoll(
        string memory _description,
        string[] memory _options,
        uint256 _durationTimeInDays,
        uint256 _minimumStakeTimeInDays
    )
        external
        onlyOperator
        returns (uint256)
    {
        require(bytes(_description).length > 0, "MultipleVoting#createPoll: DESCRIPTION_INVALID");
        require(_options.length > 1, "MultipleVoting#createPoll: OPTIONS_INVALID");
        require(_durationTimeInDays > 0, "MultipleVoting#createPoll: DURATION_TIME_INVALID");

        pollIds.increment();
        Poll storage poll = _polls[pollIds.current()];
        poll.startTime = block.timestamp;
        poll.endTime = block.timestamp.add(_durationTimeInDays.mul(1 days));
        poll.minimumStakeTimeInDays = _minimumStakeTimeInDays;
        poll.description = _description;
        poll.options.push('');
        for (uint256 i = 0; i < _options.length; i++) {
            poll.options.push(_options[i]);
        }
        poll.creator = _msgSender();

        emit PollCreated(_msgSender(), pollIds.current(),_durationTimeInDays);
        return pollIds.current();
    }

    /**
	 * @dev End `_pollId` poll.
     *
     * @param _pollId poll id.
	 */
    function endPoll(
        uint256 _pollId
    )
        external
        onlyOperator
        validPoll(_pollId)
    {
        uint256 winningOptionId;
        uint256 maxVotes;
        Poll storage poll = _polls[_pollId];
        require(block.timestamp >= poll.endTime, "MultipleVoting#endPoll: VOTING_PERIOD_NOT_EXPIRED");
        require(poll.isEnded == false, "MultipleVoting#endPoll: POLL_ALREADY_ENDED");
        poll.isEnded = true;
        // decide winning option
        for (uint256 i = 1; i < poll.options.length; i++) {
            if (maxVotes < _votes[_pollId][i]) {
                maxVotes = _votes[_pollId][i];
                winningOptionId = i;
            }
        }
        poll.winningOptionId = winningOptionId;

        emit PollEnded(_pollId, winningOptionId);
    }

    /**
	 * @dev Check if `_account` already voted for `_pollId`.
     *
     * @param _pollId poll id.
     * @param _account user.
	 */
    function checkIfVoted(
        uint256 _pollId,
        address _account
    )
        public
        view
        validPoll(_pollId)
        returns (bool)
    {
        return _voters[_pollId][_account].vote != 0;
    }

    /***********************|
    |          Vote         |
    |______________________*/

    /**
	 * @dev User vote `_vote` for `_pollId`.
     *
     * @param _pollId poll id.
     * @param _optionId voting option id.
	 */
    function castVote(
        uint256 _pollId,
        uint256 _optionId
    )
        external
        validPoll(_pollId)
    {
        require(_optionId > 0, "MultipleVoting#castVote: INVALID_VOTE_OPTION_ID");
        Poll memory poll = _polls[_pollId];
        require(poll.isEnded == false, "MultipleVoting#castVote: POLL_ALREADY_ENDED");
        require(block.timestamp < poll.endTime, "MultipleVoting#castVote: VOTING_PERIOD_EXPIRED");
        require(!checkIfVoted(_pollId, _msgSender()), "MultipleVoting#castVote: USER_ALREADY_VOTED");

        uint256 w = getWeight(_pollId, _msgSender());
        _votes[_pollId][_optionId] += w;

        Voter storage voter = _voters[_pollId][_msgSender()];
        voter.vote = _optionId;
        voter.weight = w;

        emit VoteCasted(_msgSender(), _pollId, _optionId, w);
    }

    /*****************************|
    |          StakeToken         |
    |____________________________*/

    /**
	 * @dev Get `_account` weight for `_pollId`.
     *
     * @param _pollId poll id.
     * @param _account.
	 */
    function getWeight(
        uint256 _pollId,
        address _account
    )
        public
        validPoll(_pollId)
        returns (uint256)
    {
        require(_account != address(0), "MultipleVoting#getWeight: ACCOUNT_INVALID");
        uint256 w = 0; // total weight
        Poll memory poll = _polls[_pollId];
        require(poll.isEnded == false, "MultipleVoting#getWeight: POLL_ALREADY_ENDED");

        for (uint256 i = 0; i < _stakePools.length; i++) {
            IStakeMirrorNFT sPool = _stakePools[i];
            uint256[] memory sTokenIds = sPool.getStakeTokenIds(_account);
            require(sTokenIds.length > 0, "MultipleVoting#getStakeTokenIds: NO_VALID_VOTING_NFTS_PRESENT");
            for (uint256 j = 0; j < sTokenIds.length; j++) {
                (uint256 amount, , uint256 depositedAt) = sPool.getStakeInfo(sTokenIds[j]);
                if (depositedAt < poll.startTime.sub(poll.minimumStakeTimeInDays.mul(1 days))) {
                    w = w.add(amount);
                }
            }
        }
        return w;
    }
}