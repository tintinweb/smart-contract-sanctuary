/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT

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



// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// [email protected]

interface TokenInterface {
    function mintTo(address user, uint256 amount) external;
    function burnFrom(address user, uint256 amount) external;
}


// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// [email protected]

library Signer
{
    function recoverSigner(bytes32 dataHash, bytes memory sig) internal pure returns (address)
    {
        require(sig.length == 65, "Signature incorrect length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        return ecrecover(dataHash, v, r, s);
    }

    function recoverPrefixedTxData(bytes memory sig, bytes memory txData) internal pure returns (address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n112";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, txData));
        address signer = recoverSigner(prefixedHash, sig);
        return signer;
    }

    function recover(bytes memory sig, bytes memory txData) internal pure returns (address)
    {
        address signer = recoverSigner(keccak256(txData), sig);
        return signer;
    }
}


// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// [email protected]

library BitShifter
{
    function readUint64(bytes memory buffer, uint offset) internal pure returns (uint64)
    {
        require(buffer.length >= offset + 32, "Uint64 out of range");

        uint256 res;
        assembly {
            res := mload(add(buffer, add(0x20, offset)))
        }

        return uint64(res >> 192);
    }

    function readUint256(bytes memory buffer, uint offset) internal pure returns (uint256)
    {
        require(buffer.length >= offset + 32, "Uint256 out of range");

        uint256 res;
        assembly {
            res := mload(add(buffer, add(0x20, offset)))
        }

        return res;
    }

    function readAddress(bytes memory buffer, uint offset) internal pure returns (address)
    {
        require(buffer.length >= offset + 32, "Address out of range");

        address res;
        assembly {
            res := mload(add(buffer, add(0x20, offset)))
        }

        return res;
    }

    function decompose(bytes memory txData) internal pure returns (uint256, uint64, uint64, uint256, address)
    {
        uint256 numTokens = readUint256(txData, 0);
        uint64 withdrawalBridgeId = readUint64(txData, 32);
        uint64 depositBridgeId = readUint64(txData, 40);
        uint256 nonce = readUint256(txData, 48);
        address user = readAddress(txData, 80);

        return ( numTokens, withdrawalBridgeId, depositBridgeId, nonce, user );
    }
}


// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// [email protected]







// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// [email protected]









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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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


abstract contract SecureContract is AccessControl
{
    event ContractPaused (uint height, address user);
    event ContractUnpaused (uint height, address user);

    bytes32 public constant _ADMIN = keccak256("_ADMIN");

    bool private paused_;

    modifier pause()
    {
        require(!paused_, "Contract is paused");
        _;
    }

    modifier isAdmin()
    {
        require(hasRole(_ADMIN, msg.sender), "Permission denied");
        _;
    }

    constructor()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(_ADMIN, msg.sender);
        paused_ = true;
    }

    function setPaused(bool paused) public isAdmin
    {
        if (paused != paused_)
        {
            paused_ = paused;
            if (paused)
                emit ContractPaused(block.number, msg.sender);
            else 
                emit ContractUnpaused(block.number, msg.sender);
        }
    }

    function queryPaused() public view returns (bool)
    {
        return paused_;
    }
}


contract CiviPortBridge is SecureContract
{
    bytes32 public constant _DEPOSIT = keccak256("_DEPOSIT");

    event Deposit(uint256 indexed nonce, bytes data);
    event Withdraw(uint256 indexed nonce, bytes data);

    mapping(uint256 => bool) private withdrawNonces;
    mapping(uint256 => bool) private depositNonces;

    TokenInterface private token_;
    uint64 private bridgeId_;
    uint8 private numSigners_;

    using BitShifter for bytes;

    constructor(address tokenContract, uint64 bridgeId, uint8 numSigners) SecureContract()
    {
        _setupRole(_DEPOSIT, msg.sender);
        _setRoleAdmin(_DEPOSIT, _ADMIN);
        token_ = TokenInterface(tokenContract);
        bridgeId_ = bridgeId;
        numSigners_ = numSigners;
    }

    function queryWithdrawNonceUsed(bytes memory nonceBytes) public view returns (bool)
    {
        uint256 nonce = nonceBytes.readUint256(0);
        return withdrawNonces[nonce];
    }

    function queryDepositNonceUsed(bytes memory nonceBytes) public view returns (bool)
    {
        uint256 nonce = nonceBytes.readUint256(0);
        return depositNonces[nonce];
    }

    function queryToken() public view returns (TokenInterface)
    {
        return token_;
    }

    function queryBridgeID() public view returns (uint64)
    {
        return bridgeId_;
    }

    function queryConfirmationCount() public view returns (uint8)
    {
        return numSigners_;
    }

    function setConfirmationCount(uint8 count) public isAdmin
    {
        numSigners_ = count;
    }

    function exists(address[] memory array, address entry) private pure returns (bool)
    {
        uint len = array.length;
        for (uint i = 0; i < len; i++)
        {
            if (array[i] == entry)
                return true;
        }

        return false;
    }

    function deposit(bytes memory clientSignature, bytes[] memory serverSignatures, bytes memory transactionData) public pause
    {
        address clientSigner = Signer.recoverPrefixedTxData(clientSignature, transactionData);
        uint8 sigCount = (uint8)(serverSignatures.length);
        require (sigCount >= numSigners_, "Not enough signatures");

        address[] memory usedAddresses = new address[](numSigners_);

        for (uint i = 0; i < numSigners_; i++)
        {
            address serverSigner = Signer.recoverPrefixedTxData(serverSignatures[i], transactionData);
            require (hasRole(_DEPOSIT, serverSigner), "Multisig signer not permitted");
            require (!exists(usedAddresses, serverSigner), "Duplicate multisig signer");
            usedAddresses[i] = serverSigner;
        }

        uint256 numTokens;
        uint64 withdrawalBridgeId;
        uint64 depositBridgeId;
        uint256 nonce;
        address user;

        (numTokens, withdrawalBridgeId, depositBridgeId, nonce, user) = transactionData.decompose();

        require (clientSigner == user, "Not signed by client");
        require (clientSigner == msg.sender, "Not sent by client");
        require (depositBridgeId == bridgeId_, "Incorrect network");
        require (!depositNonces[nonce], "Nonce already used");

        token_.mintTo(user, numTokens);

        depositNonces[nonce] = true;

        emit Deposit(nonce, transactionData);
    }

    function withdraw(bytes memory clientSignature, bytes memory transactionData) public pause
    {
        address signer = Signer.recoverPrefixedTxData(clientSignature, transactionData);

        uint256 numTokens;
        uint64 withdrawalBridgeId;
        uint64 depositBridgeId;
        uint256 nonce;
        address user;

        (numTokens, withdrawalBridgeId, depositBridgeId, nonce, user) = transactionData.decompose();

        require (signer == user, "Not signed by client");
        require (signer == msg.sender, "Not sent by client");
        require (withdrawalBridgeId == bridgeId_, "Incorrect network");
        require (!withdrawNonces[nonce], "Nonce already used");

        token_.burnFrom(user, numTokens);

        withdrawNonces[nonce] = true;

        emit Withdraw(nonce, transactionData);
    }
}