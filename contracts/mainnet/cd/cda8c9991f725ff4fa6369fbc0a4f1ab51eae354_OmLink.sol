/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: AGPL-3.0
// File: contracts\core\SignVerifier.sol

pragma solidity ^0.8.7;

contract SignVerifier {

    struct Message {
        uint256 networkId;
        address token;
        address from;
        address to;
        uint256 amount;
        uint256 nonce;
        bytes signature;
        address signer;
    }

    struct NativeMessage {
        uint256 networkId;
        address from;
        address to;
        uint256 amount;
        uint256 nonce;
        bytes signature;
        address signer;
    }

    /**
     * @dev function that returns the hash of the encoded message
     * @param networkId ID of the network
     * @param token the address of the token's contract
     * @param from the address of the sender
     * @param to the address of the receiver
     * @param amount the amount of tokens
     * @param nonce the nonce of the message
     *
     * @return bytes32 message hash
     */
    function getMessageHash(
        uint256 networkId, 
        address token, 
        address from, 
        address to, 
        uint256 amount, 
        uint256 nonce
    )
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(networkId,token,from,to,amount,nonce));
    }

    function getNativeMessageHash(
        uint256 networkId,
        address from,
        address to,
        uint256 amount,
        uint256 nonce
    )
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(networkId,from,to,amount,nonce));
    }

    /**
     * @dev converts the signed message to the ETH signed message format
     * by appending \x19Ethereum Signed Message:\n32
     * 
     * @param messageHash the hash of the message
     * @return bytes32
     */
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }
    
    /**
     * @dev the function that verifys that a message is indeed signed by the passed signer
     * 
     * @param finalizeMessage a struct that has the message data
     * 
     * @return bool, true if signer is correct, false if not
     *
     */
    function verify(
        Message memory finalizeMessage
    )
        public pure returns (bool)
    {
        bytes32 messageHash_ = getMessageHash(
            finalizeMessage.networkId,
            finalizeMessage.token,
            finalizeMessage.from,
            finalizeMessage.to,
            finalizeMessage.amount,
            finalizeMessage.nonce);
        bytes32 ethSignedMessageHash_ = getEthSignedMessageHash(messageHash_);

        return recoverSigner(ethSignedMessageHash_, finalizeMessage.signature) == finalizeMessage.signer;
    }

    function verifyNative(
        NativeMessage memory finalizeMessage
    )
        public pure returns (bool)
    {
        bytes32 messageHash_ = getNativeMessageHash(
            finalizeMessage.networkId,
            finalizeMessage.from,
            finalizeMessage.to,
            finalizeMessage.amount,
            finalizeMessage.nonce
        );
        bytes32 ethSignedMessageHash_ = getEthSignedMessageHash(messageHash_);

        return recoverSigner(ethSignedMessageHash_,finalizeMessage.signature) == finalizeMessage.signer;
    }

    /**
     * @dev function that recovers the signer of an eth signed message hash from signature
     * 
     * @param ethSignedMessageHash signed message hash
     * @param signature signature
     *
     * @return address of the signer
     */
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }



    /**
     * @dev function that splits the signature
     * 
     * @param sig signature
     * 
     * @return r bytes32
     * @return s bytes32
     * @return v uint8
     */

    function splitSignature(bytes memory sig)
        public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "SignVerifier: invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

    }

}

// File: node_modules\@openzeppelin\contracts\access\IAccessControl.sol



pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol



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

// File: node_modules\@openzeppelin\contracts\utils\Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol



pragma solidity ^0.8.0;

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

// File: node_modules\@openzeppelin\contracts\utils\introspection\ERC165.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin\contracts\access\AccessControl.sol



pragma solidity ^0.8.0;





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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

// File: contracts\abstract\Guarded.sol



pragma solidity ^0.8.7;


/**
 * @dev Guard contract that adds extra functionality to the {AccessControl} contract
 * 
 * Defines `ADMIN_ROLE`, `MINTER_ROLE`, `BURNER_ROLE`
 * adds `onlyOwner`, `onlyAdmin`, `onlyMinter`, `onlyBurner`, `nonPaused`, `paused` modifiers
 * 
 *  */

abstract contract Guarded is AccessControl{

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    address private _owner;
    bool private _paused;

    modifier onlyOwner ()
    {
        require(_owner == _msgSender(), "Guard: not owner");
        _;
    }

    modifier onlyAdmin ()
    {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Guard: not admin");
        _;
    }

    modifier onlyMinter () {
        require(hasRole(MINTER_ROLE, _msgSender()), "Guard: not minter");
        _;
    }

    modifier nonPaused () {
        require(!_paused, "Guard: contract paused");
        _;
    }

    modifier paused () {
        require(_paused, "Guard: contract is not paused");
        _;
    }

    constructor()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _owner = _msgSender();
        _paused = false;
    }

    function pause() public onlyAdmin nonPaused returns (bool) {
        _paused = true;
        emit ContractPaused(block.number,_msgSender());
        return true;
    }

    function unpause() public onlyAdmin paused returns (bool) {
        _paused = false;
        emit ContractUnpaused(block.number,_msgSender());
        return true;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function transferOwner (address owner) public onlyOwner returns (bool) {
        grantRole(DEFAULT_ADMIN_ROLE, owner);
        grantRole(ADMIN_ROLE, owner);

        revokeRole(DEFAULT_ADMIN_ROLE,_owner);
        revokeRole(ADMIN_ROLE,_owner);

        emit OwnerChanged(_owner,owner);

        _owner = owner;

        return true;
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public onlyOwner {
        _setRoleAdmin(role,adminRole);
    }
    
    event ContractPaused(uint256 blockHeight, address admin);
    event ContractUnpaused(uint256 blockHeight, address admin);
    event OwnerChanged(address previousOwner, address currentOwner);

}

// File: contracts\abstract\Blacklistable.sol



pragma solidity ^0.8.7;


/**
 * @dev Blacklist module that allows receivers or transaction senders 
 * to be blacklisted.
 */

abstract contract Blacklistable is Guarded {

    address public _blacklister;

    mapping(address => bool) internal _blacklisted;

    /**
     * @dev Modifier that checks the msg.sender for blacklisting related operations
     */
    modifier onlyBlacklister() {
        require(_blacklister == _msgSender(),"Blacklistable: account is not blacklister");
        _;
    }

    /**
     * @dev Modifier that checks the account is not blacklisted
     * @param account The address to be checked
     */
    modifier notBlacklisted(address account) {
        require(!_blacklisted[account],"Blacklistable: account is blacklisted");
        _;
    }

    /**
     * @dev Function that checks if an address is blacklisted
     * @param account The address to be checked
     * @return bool, true if account is blacklisted, false if not
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    /**
     * @dev Function that blacklists an account
     * Emits {Blacklisted} event.
     * 
     * @notice can only be called by blacklister
     * @param account The address to be blacklisted
     */
    function blacklist(address account) public onlyBlacklister {
        _blacklisted[account] = true;
        emit Blacklisted(account);
    }

    /**
     * @dev Function that removes an address from blacklist
     * Emits {UnBlacklisted} event
     * 
     * @notice can only be called by blacklister
     * @param account to be unblacklisted
     */
    function unBlacklist(address account) public onlyBlacklister {
        _blacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    /**
     * @dev Function that updates the current blacklister account
     * Emits {BlacklisterChanged} event
     * 
     * @notice can only be called by the owner of the contract
     * @param newBlacklister address that will be the new blacklister
     */
    function updateBlacklister(address newBlacklister) external onlyOwner {
        require(
            newBlacklister != address(0),
            "Blacklistable: new blacklister is the zero address"
        );
        _blacklister = newBlacklister;
        emit BlacklisterChanged(newBlacklister);
    }

    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    event BlacklisterChanged(address indexed newBlacklister);
}

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol



pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol



pragma solidity ^0.8.0;



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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /*function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }*/

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\abstract\TokenRecover.sol


pragma solidity ^0.8.7;



abstract contract TokenRecover is Guarded {

    using SafeERC20 for IERC20;

    function recoverERC20(address token, address recipient, uint256 amount) public onlyOwner() returns (bool)
    {
        IERC20(token).safeTransfer(recipient,amount);
        emit ERC20Recovered(token,recipient,amount);
        return true;
    }

    event ERC20Recovered(address token, address recipient, uint256 amount);
}

// File: contracts\includes\Fiber.sol


pragma solidity ^0.8.7;

// Author: Osman Kuzucu
// https://github.com/open-money
// [email protected]




contract Fiber is Guarded, Blacklistable, TokenRecover {

    mapping(address => bool) public _supportedTokens;
    mapping(address => bool) public _isLinkToken;

    mapping (address => bool) internal _verifiedSigners;

    bool private _isSupportedNative = false;

    /**
     * @dev modifier that checks whether the link token is supported or not
     */
    modifier onlySupportedToken(address contractAddress) {
        require(isSupportedToken(contractAddress),"Fiber: token not supported");
        _;
    }

    /** 
     * @dev modifier that checks the signature is from a verified signer
     */
    modifier onlyVerifiedSigner(address signer) {
        require(_verifiedSigners[signer] == true,"Tracked:signer is not verified");
        _;
    }

    modifier isSupportedNative() {
        require(_isSupportedNative,"Fiber: Native not supported");
        _;
    }

    function isVerifiedSigner (address signer) public view returns (bool){
        return _verifiedSigners[signer];
    }

    function isSupportedToken (address contractAddress) public view returns (bool)
    {
        return _supportedTokens[contractAddress];
    }

    /** 
     * @dev function tat adds a new verified signer
     * called only by the owner
     */
    function addVerifiedSigner (address signer) public onlyOwner() returns (bool)
    {
        _verifiedSigners[signer] = true;
        return true;
    }

    /** 
     * @dev function that removes a verified signer
     * called only by the owner
     */
    function removeVerifiedSigner (address signer) public onlyOwner() returns (bool) {
        _verifiedSigners[signer] = false;
        return true;
    }

    /** 
     * @dev function that checks whether the token is LinkToken or not
     */
    function isLinkToken (address contractAddress) public view returns (bool) {
        return _isLinkToken[contractAddress];
    }

    /**
     * @dev function that adds supported token
     */
    function addSupportedToken (address contractAddress, bool isLToken) public onlyOwner returns (bool)
    {
        emit SupportedTokenAdded(contractAddress,isLToken, msg.sender);
        return _addSupportedToken(contractAddress,isLToken);
    }

    /**
     * @dev function that removes supported token
     */
    function removeSupportedToken (address contractAddress) public onlyOwner returns (bool)
    {
        emit SupportedTokenRemoved(contractAddress, msg.sender);
        return _removeSupportedToken (contractAddress);
    }

    /**
     * @dev internal function that adds supported token
     */
    function _addSupportedToken (address contractAddress,bool isLToken) internal virtual returns (bool)
    {
        _supportedTokens[contractAddress] = true;
        _isLinkToken[contractAddress] = isLToken;
        return true;
    }

    /**
     * @dev internal function that removes supported token
     */
    function _removeSupportedToken (address contractAddress) internal virtual returns (bool)
    {
        _supportedTokens[contractAddress] = false;
        _isLinkToken[contractAddress] = false;
        return true;
    }

    function changeNativeSupport(bool newValue) public onlyOwner() returns (bool)
    {
        _isSupportedNative = newValue;
        return true;
    }

    event SupportedTokenAdded(address contractAddress, bool isLToken, address admin);
    event SupportedTokenRemoved(address contractAddress, address admin);

}

// File: contracts\includes\Tracked.sol



pragma solidity ^0.8.7;

/**
 * @title omLink tracking contract 
 *
 * @author Osman Kuzucu - [email protected]
 * https://github.com/nithronium
 * 
 * @dev this contract tracks the nonces and eliminates duplicate minting
 */
contract Tracked {

    /** 
     * 
     * @dev struct for a given nonce with `token` and `nonce`
     *
     */
    struct nonceDataStruct {
        bool _isUsed;
        uint256 _inBlock;
    }

    /** 
     * 
     * @dev struct for the nonces per token address
     *
     */
    struct contractTrackerStruct {
        uint256 _biggestWithdrawNonce;
        uint256 _depositNonce;
        mapping (uint256 => nonceDataStruct) _nonces;
    }

    mapping (address => contractTrackerStruct) internal _tracker;

    contractTrackerStruct _nativeTracker;


    /**
     * @dev modifier that checks whethether a nonce is used or not 
     * 
     * @param token token contract address
     * @param nonce nonce to query
     *
     */
    modifier nonUsedNonce(address token, uint nonce) {
        require(_tracker[token]._nonces[nonce]._isUsed == false, "Tracker: nonce already used");
        _;
    }

    modifier nonUsedNativeNonce(uint nonce) {
        require(_nativeTracker._nonces[nonce]._isUsed == false,"Tracker: native nonce already used");
        _;
    }

    /**
     * @dev function that marks a nonce as used
     *
     * emits {NonceUsed} event
     * 
     * @param token token contract address
     * @param nonce the nonce to be marked as used
     * 
     */
    function useNonce(address token, uint nonce) internal nonUsedNonce(token,nonce) {
        _tracker[token]._nonces[nonce]._isUsed = true;
        _tracker[token]._nonces[nonce]._inBlock = block.number;

        /**
         * Sets the contract's biggest withdraw nonce 
         * if current withdraw nonce is the known biggest one
         * 
         * this is for information purposes only
         */
        if(nonce > _tracker[token]._biggestWithdrawNonce) {
            _tracker[token]._biggestWithdrawNonce = nonce;
        }

        emit NonceUsed(token,nonce,block.number);
    }

    /**
     * @dev gets information about the given withdrawal nonce 
     * of the any given token
     *
     * @param token token contract address
     * @param nonce nonce to be queried
     * 
     * @return (bool,uint256) 
     * 
     */
    function getNonceData(address token, uint256 nonce) public view returns (bool,uint256) {
        return(_tracker[token]._nonces[nonce]._isUsed,_tracker[token]._nonces[nonce]._inBlock);
    }

    /**
     * @dev checks if a withdraw nonce has been used before
     * 
     * @param token token contract address
     * @param nonce nonce to be queried
     * 
     * @return bool
     *
     */
    function isUsedNonce(address token, uint256 nonce) public view returns (bool) {
        return(_tracker[token]._nonces[nonce]._isUsed);
    }

    /**
     * 
     * @dev increments the deposit nonce of the given token
     * 
     * @param token token contract address
     * 
     */
    function depositNonce(address token) internal {
        _tracker[token]._depositNonce+=1;
    }

    /**
     * 
     * @dev gets the current deposit nonce of the given token
     *
     * @param token token contract address
     * 
     * @return uint256
     */
    function getDepositNonce (address token) public view returns (uint256) {
        return _tracker[token]._depositNonce;
    }

    function nativeDepositNonce() internal {
        _nativeTracker._depositNonce+=1;
    }

    function getNativeDepositNonce() public view returns (uint256) {
        return _nativeTracker._depositNonce;
    }

    function isUsedNativeNonce(uint256 nonce) public view returns (bool) {
        return(_nativeTracker._nonces[nonce]._isUsed);
    }

    function useNativeNonce(uint nonce) internal nonUsedNativeNonce(nonce) {
        _nativeTracker._nonces[nonce]._isUsed = true;
        _nativeTracker._nonces[nonce]._inBlock = block.number;

        /**
         * Sets the contract's biggest withdraw nonce 
         * if current withdraw nonce is the known biggest one
         * 
         * this is for information purposes only
         */
        if(nonce > _nativeTracker._biggestWithdrawNonce) {
            _nativeTracker._biggestWithdrawNonce = nonce;
        }

        emit NativeNonceUsed(nonce,block.number);
    }

    event NonceUsed(address token, uint256 nonce, uint256 blockNumber);
    event NativeNonceUsed(uint256 nonce, uint256 blockNumber);
}

// File: contracts\omLink.sol


pragma solidity ^0.8.7;

// Author: Osman Kuzucu
// https://github.com/open-money
// [email protected]






/**
 * @dev required interface for ERC20 compatible tokens
 * @notice the ERC20 is not fully implemented as omLink just requires 4 methods
 *
 */

interface ERC20Tokens {
    function burnFrom(address account, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mintTo(address account, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract OmLink is Fiber, SignVerifier, Tracked
{

    using SafeERC20 for IERC20;

    /**
     * @dev chain ID of the contract where it is deployed
     *
     */
    uint256 public _chainId;

    /**
     * @dev finalizer struct because of the compiler error
     * this struct is used for finalizing the transaction on the target chain
     * 
     */
    struct finalizer {
        uint256 toChain;
        address from;
        address to;
        uint256 amount;
        address tokenAddress;
        uint256 nonce;
        address signer;
        bytes signature;
    }

    /** 
     * @dev set chainId
     * 
     */
    constructor(uint256 chainId) {
        _chainId = chainId;
    }


    /** 
     * @dev deposit function
     * 
     * emits {LinkStarted} event
     * 
     * @param toChain target chain id
     * @param token token contract address
     * @param to receiver address
     * @param amount amount of tokens to be transferred
     *
     * @return bool 
     */
    function deposit(
        uint256 toChain,
        address token,
        address to,
        uint256 amount
    ) public 
        onlySupportedToken(token) 
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        nonPaused()
        returns (bool) {

            /** 
             *
             * @dev Checks whether a token is LinkToken or not,
             * if the token is not LinkToken, it tansfers tokens from the user to the omLink contract
             * 
             */
            if(isLinkToken(token)) {
                require(ERC20Tokens(token).burnFrom(msg.sender,amount),"omLink: cannot burn tokens");
            } else {
                IERC20(token).safeTransferFrom(msg.sender,address(this),amount);
            }

            /**
             * 
             * @dev increment the deposit nonce of the said token so that 
             * backend servers won't reprocess the same events
             * this is required for event handling
             *
             */
            depositNonce(token);


            emit LinkStarted(toChain,token,msg.sender,to,amount,getDepositNonce(token));

            //in case contract is called by another contract later
            return true;
    }

    /**
     * @dev deposit function for native tokens
     * 
     * emits {LinkStarted} event with address(0) as contract address
     * 
     * @param toChain target chain id
     * @param to receiving address
     * @param amount receiving amount
     *
     * @return bool
     *
     */
    function depositNative(
        uint256 toChain,
        address to,
        uint256 amount
    ) payable public 
        isSupportedNative()
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        nonPaused()
        returns (bool) {
            /**
             * @dev checks whether the amount calling the function 
             * is equal with the actual transacted native token
             * reverts if not
             *
             * @notice because the native token deposit is already 
             * credited with the transaction, we don't require 
             * any transfer event
             */
            require(msg.value == amount,"omLink: wrong native amount");

            /**
             * @dev increments the native deposit nonce
             *
             */
            nativeDepositNonce();

            emit LinkStarted(toChain,address(0),msg.sender,to,amount,getNativeDepositNonce());

            return true;
    }

    /**
     *
     * @dev implementation of the link finalizer, this function processes 
     * the coupon provided by the verified signer backend and mints & transfers 
     * the signed amount to the receiving address
     * 
     * Checks for whether the token is supported with `onlySupportedToken` modifier
     * Checks for blacklis with `notBlacklisted` modifier
     * Checks for whether contract is paused with `nonPaused` modifier
     * Checks whether the signature is from a verified signer with `onlyVerifiedSigner` modifier
     * 
     * @param toChain the chainId of the receiving chain
     * @param token the contract address of the token
     * @param from the sender
     * @param to the receiver
     * @param amount the amount of tokens to be minted & transferred from
     * @param nonce the nonce of the transaction coupon
     * @param signature the signed message from the server
     * @param signer the address of the coupon signer
     * 
     * @return bool 
     */
    function finalize(
        uint256 toChain,
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature,
        address signer
    ) public 
        onlySupportedToken(token) 
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        nonPaused()
        onlyVerifiedSigner(signer)
        returns (bool) {


            /** 
             * 
             * @dev makes sure that the coupon is being processed by the correct chain
             * and the nonce is not used before
             */
            require(_chainId == toChain,"omLink:incorrect chain");
            require(!isUsedNonce(token,nonce),"Tracked:used nonce");

            /** 
             * 
             * @dev passing function parameters to the `messageStruct_` element 
             * to solve the Stack too deep error and verifies whether the message is real or not
             *
             * 
             */
            
            Message memory messageStruct_;

            messageStruct_.networkId = toChain;
            messageStruct_.token = token;
            messageStruct_.from = from;
            messageStruct_.to = to;
            messageStruct_.amount = amount;
            messageStruct_.nonce = nonce;
            messageStruct_.signature = signature;
            messageStruct_.signer = signer;

            require(verify(messageStruct_),"omLink: signature cant be verified");

            /** 
             * 
             * @dev uses the nonce on the current token address
             * and mints the token if it's mintable, transfers if not.
             */

            useNonce(token,nonce);

            if( isLinkToken(token) ) {
                ERC20Tokens(token).mintTo(to,amount);
            } else {
                IERC20(token).safeTransfer(to,amount);
            }

            /** 
             * 
             * @dev emits {LinkFinalized} event to make sure the backend 
             * server also processes the coupon as used
             * 
             */
            emit LinkFinalized(
                messageStruct_.networkId,
                messageStruct_.token,
                messageStruct_.from,
                messageStruct_.to,
                messageStruct_.amount,
                messageStruct_.nonce,
                messageStruct_.signer);

            return true;
    }

    /**
     * 
     * @dev implementation of the link finalizer on receiving native currency
     * this function processes the coupon provided by the verified signer and 
     * transfers the amount of native tokens to the receiving address
     *
     * Checks for whether native token bridging is supported on deployed network
     * Checks whether the sending or receiving address is blacklisted
     * Checks for signature provided and signer
     *
     * @param toChain the chainId of the receiving chain
     * @param from the sender
     * @param to the receiver
     * @param amount the amount of tokens to be minted & transferred from
     * @param nonce the nonce of the transaction coupon
     * @param signature the signed message from the server
     * @param signer the address of the coupon signer
     * 
     * @return bool
     * */
    function finalizeNative(
        uint256 toChain,
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature,
        address signer
    ) public 
        isSupportedNative()
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        nonPaused()
        onlyVerifiedSigner(signer)
        returns (bool) {
            require(_chainId == toChain,"omLink:incorrect chain");
            require(!isUsedNativeNonce(nonce),"Tracked:used nonce");

            NativeMessage memory messageStruct_;

            messageStruct_.networkId = toChain;
            messageStruct_.from = from;
            messageStruct_.to = to;
            messageStruct_.amount = amount;
            messageStruct_.nonce = nonce;
            messageStruct_.signature = signature;
            messageStruct_.signer = signer;

            require(verifyNative(messageStruct_),"omLink: message cant be verified");
            require(address(this).balance >= amount,"omLink: not enough native");

            useNativeNonce(nonce);

            address payable receiver = payable(to);
            receiver.transfer(amount);

            emit LinkFinalized(
                messageStruct_.networkId,
                address(0),
                messageStruct_.from,
                messageStruct_.to,
                messageStruct_.amount,
                messageStruct_.nonce,
                messageStruct_.signer
            );

            return true;

        }

    function invalidateNonce(address token, uint256 nonce) public onlyOwner returns (bool) {
        
        require(!isUsedNonce(token,nonce),"Tracked:used nonce");
        useNonce(token,nonce);

        emit NonceInvalidated(_chainId,token,msg.sender,nonce,block.number);
        return true;
    }

    function invalidateNative(uint256 nonce) public onlyOwner returns (bool) {
        require(!isUsedNativeNonce(nonce),"Tracked:used nonce");
        useNativeNonce(nonce);

        emit NativeNonceInvalidated(_chainId,msg.sender,nonce,block.number);
        return true;
    }


    event LinkStarted(uint256 toChain, address tokenAddress, address from, address to, uint256 amount, uint256 indexed depositNonce);
    event LinkFinalized(uint256 chainId, address tokenAddress, address from, address to, uint256 amount, uint256 indexed nonce, address signer);
    
    event NonceInvalidated(uint256 chainId, address tokenAddress, address owner, uint256 indexed nonce, uint atBlock);
    event NativeNonceInvalidated(uint256 chainId, address owner, uint256 indexed nonce, uint atBlock);

}