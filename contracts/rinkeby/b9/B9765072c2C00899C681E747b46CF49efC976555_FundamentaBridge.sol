// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.8.9;

// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// [email protected]

import "./include/SecureContract.sol";
import "./include/TokenInterface.sol";

struct TokenInfo {
    uint256 id;
    bool isWrappedToken;
    uint256 numSigners;
    bool canWithdraw;
    bool canDeposit;
    TokenInterface token;
}

struct TokenData {
    TokenInfo info;
    mapping(uint256 => bool) withdrawNonces;
    mapping(uint256 => bool) depositNonces;
    uint256 fee;
    uint256 accumulatedFee;
}

contract FundamentaBridge is SecureContract
{
    bytes32 public constant _DEPOSIT = keccak256("_DEPOSIT");

    event Initialized();

    event Deposit(uint256 indexed nonce, address sender, uint256 indexed sourceNetwork, uint256 destinationNetwork, uint256 indexed sourceToken, uint256 destinationToken, uint256 amount);
    event Withdraw(uint256 indexed nonce, address sender, uint256 sourceNetwork, uint256 indexed destinationNetwork, uint256 sourceToken, uint256 indexed destinationToken, uint256 amount);
    event CanWithdrawChanged(address sender, uint256 tokenId, bool newValue);
    event CanDepositChanged(address sender, uint256 tokenId, bool newValue);
    event numSignersChanged(address sender, uint256 tokenId, uint256 newValue);
    event TokenAdded(address sender, uint256 tokenId, bool isWrappedToken, uint256 numSigners, address tokenAddress);
    event FeeChanged(address sender, uint256 tokenId, uint256 oldFee, uint256 newFee);

    event FeeWithdraw(address indexed user, uint256 tokenId, uint256 amount);

    uint256 private id_;

    mapping(uint256 => TokenData) private tokens_;

    constructor() {}

    function initialize() public initializer
    {
        SecureContract.init();
        
        _setRoleAdmin(_DEPOSIT, _ADMIN);
        id_ = block.chainid;

        emit Initialized();
    }

    function queryID() public view returns (uint256) { return id_; }

    function queryToken(uint256 tokenId) public view returns (TokenInfo memory) { return tokens_[tokenId].info; }

    function queryWithdrawNonceUsed(uint256 tokenId, uint256 nonce) public view returns (bool) { return tokens_[tokenId].withdrawNonces[nonce]; }

    function queryDepositNonceUsed(uint256 tokenId, uint256 nonce) public view returns (bool) { return tokens_[tokenId].depositNonces[nonce]; }

    function queryFee(uint256 tokenId) public view returns (uint256) { return tokens_[tokenId].fee; }

    function queryAccumulatedFee(uint256 tokenId) public view returns (uint256) { return tokens_[tokenId].accumulatedFee; }

    function calculateFee(uint256 tokenId, uint256 amount) public view returns (uint256) { return (amount / 10000) * tokens_[tokenId].fee; }

    function addToken(uint256 id, bool isWrappedToken, uint256 numSigners, address tokenAddress) public isAdmin
    {
        require(tokenAddress != address(0), "Bridge: Token may not be empty");
        require (tokens_[id].info.token == TokenInterface(address(0)), "Bridge: Token already registered");

        tokens_[id].info = TokenInfo(id, isWrappedToken, numSigners, false, false, TokenInterface(tokenAddress));
        tokens_[id].fee = 0;
        tokens_[id].accumulatedFee = 0;

        emit TokenAdded(msg.sender, id, isWrappedToken, numSigners, tokenAddress);
    }

    function setTokenCanWithdraw(uint256 id, bool canWithdraw) public isAdmin
    {
        require(tokens_[id].info.token != TokenInterface(address(0)), "Bridge: Token not registered");
        require (tokens_[id].info.canWithdraw != canWithdraw, "Bridge: No action required");

        tokens_[id].info.canWithdraw = canWithdraw;

        emit CanWithdrawChanged(msg.sender, id, canWithdraw);
    }

    function setTokenCanDeposit(uint256 id, bool canDeposit) public isAdmin
    {
        require(tokens_[id].info.token != TokenInterface(address(0)), "Bridge: Token not registered");
        require (tokens_[id].info.canDeposit != canDeposit, "Bridge: No action required");

        tokens_[id].info.canDeposit = canDeposit;

        emit CanDepositChanged(msg.sender, id, canDeposit);
    }

    function setTokenNumSigners(uint256 id, uint256 numSigners) public isAdmin
    {
        require(tokens_[id].info.token != TokenInterface(address(0)), "Bridge: Token not registered");
        require (tokens_[id].info.numSigners != numSigners, "Bridge: No action required");

        tokens_[id].info.numSigners = numSigners;

        emit numSignersChanged(msg.sender, id, numSigners);
    }

    function setFee(uint256 id, uint256 fee) public isAdmin
    {
        require(tokens_[id].info.token != TokenInterface(address(0)), "Bridge: Token not registered");
        require(tokens_[id].fee != fee, "Bridge: No action required");

        uint256 oldFee = tokens_[id].fee;
        tokens_[id].fee = fee;

        emit FeeChanged(msg.sender, id, oldFee, fee);
    }

    function verifyDeposit(bytes memory clientSignature, bytes[] memory serverSignatures, bytes memory transactionData) public view
        returns(address, uint256, uint256, uint256, uint256)
    {
        address sender;

        assembly {
            sender := mload(add(transactionData, add(0x20, 44)))
        }
        
        bytes32 dataHash = keccak256(transactionData);
        address signer = recoverSigner(dataHash, clientSignature);
        require (signer == msg.sender, "Not sent by client");
        require (signer == sender, "Not signed by client");

        uint256 destToken;

        assembly {
            destToken := mload(add(transactionData, add(0x20, 42)))
        }

        destToken = destToken >> 240;
        
        TokenData storage token = tokens_[destToken];
        require(token.info.token != TokenInterface(address(0)), "Bridge: Token not registered");
        require(token.info.canDeposit, "Bridge: Deposits disabled for this token");
        require (serverSignatures.length >= token.info.numSigners, "Not enough signatures");

        address[] memory usedAddresses = new address[](token.info.numSigners);

        for (uint i = 0; i < token.info.numSigners; i++)
        {
            signer = recoverSigner(dataHash, serverSignatures[i]);
            require (hasRole(_DEPOSIT, signer), "Multisig signer not permitted");
            require (!exists(usedAddresses, signer), "Duplicate multisig signer");
            usedAddresses[i] = signer;
        }

        uint256 destNetwork;
        uint256 nonce;
        uint256 amount;

        assembly {
            amount := mload(add(transactionData, add(0x20, 0)))
            destNetwork := mload(add(transactionData, add(0x20, 36)))
            nonce := mload(add(transactionData, add(0x20, 76)))
        }

        destNetwork = destNetwork >> 224;

        require (destNetwork == id_, "Incorrect network");
        require (!token.depositNonces[nonce], "Nonce already used");

        return (sender, nonce, destNetwork, destToken, amount);
    }

    function verifyWithdraw(bytes memory clientSignature, bytes memory transactionData) public view
        returns(address, uint256, uint256, uint256, uint256)
    {
        address sender;

        assembly {
            sender := mload(add(transactionData, add(0x20, 44)))
        }

        bytes32 dataHash = keccak256(transactionData);
        address signer = recoverSigner(dataHash, clientSignature);
        require (signer == msg.sender, "Not sent by client");
        require (signer == sender, "Not signed by client");

        uint256 srcToken;

        assembly {
            srcToken := mload(add(transactionData, add(0x20, 40)))
        }

        srcToken = srcToken >> 240;

        TokenData storage token = tokens_[srcToken];
        require(token.info.token != TokenInterface(address(0)), "Bridge: Token not registered");
        require(token.info.canWithdraw, "Bridge: Withdrawals disabled for this token");

        uint256 srcNetwork;
        uint256 nonce;
        uint256 amount;

        assembly {
            amount := mload(add(transactionData, add(0x20, 0)))
            srcNetwork := mload(add(transactionData, add(0x20, 32)))
            nonce := mload(add(transactionData, add(0x20, 76)))
        }

        srcNetwork = srcNetwork >> 224;

        require (srcNetwork == id_, "Incorrect network");
        require (!token.withdrawNonces[nonce], "Nonce already used");

        return (sender, nonce, srcNetwork, srcToken, amount);
    }

    function deposit(bytes memory clientSignature, bytes[] memory serverSignatures, bytes memory transactionData) public pause
    {
        address sender;
        uint256 nonce;
        uint256 destNetwork;
        uint256 destToken;
        uint256 amount;
        (sender, nonce, destNetwork, destToken, amount) = verifyDeposit(clientSignature, serverSignatures, transactionData);

        TokenData storage token = tokens_[destToken];

        uint256 fee = calculateFee(destToken, amount);

        token.depositNonces[nonce] = true;
        token.info.token.mintTo(sender, amount - fee);
        token.accumulatedFee += fee;

        uint256 srcNetwork;
        uint256 srcToken;

        assembly {
            srcNetwork := mload(add(transactionData, add(0x20, 32)))
            srcToken := mload(add(transactionData, add(0x20, 40)))
        }

        srcNetwork = srcNetwork >> 224;
        srcToken = srcToken >> 240;

        emit Deposit(nonce, sender, srcNetwork, destNetwork, srcToken, destToken, amount);
    }

    function withdraw(bytes memory clientSignature, bytes memory transactionData) public pause
    {
        address sender;
        uint256 nonce;
        uint256 srcNetwork;
        uint256 srcToken;
        uint256 amount;
        (sender, nonce, srcNetwork, srcToken, amount) = verifyWithdraw(clientSignature, transactionData);

        TokenData storage token = tokens_[srcToken];

        token.withdrawNonces[nonce] = true;
        token.info.token.burnFrom(sender, amount);

        uint256 destNetwork;
        uint256 destToken;

        assembly {
            destNetwork := mload(add(transactionData, add(0x20, 36)))
            destToken := mload(add(transactionData, add(0x20, 42)))
        }

        destNetwork = destNetwork >> 224;
        destToken = destToken >> 240;
        
        emit Withdraw(nonce, sender, srcNetwork, destNetwork, srcToken, destToken, amount);
    }

    function depositAndUnwrap(bytes memory clientSignature, bytes[] memory serverSignatures, bytes memory transactionData) public pause
    {
        address sender;
        uint256 nonce;
        uint256 destNetwork;
        uint256 destToken;
        uint256 amount;
        (sender, nonce, destNetwork, destToken, amount) = verifyDeposit(clientSignature, serverSignatures, transactionData);

        TokenData storage token = tokens_[destToken];
        require(token.info.isWrappedToken, "Token is not a wrapped token");

        uint256 fee = calculateFee(destToken, amount);
        
        token.depositNonces[nonce] = true;
        token.info.token.transferBackingTokenTo(sender, amount, fee);

        //don't increment accumulated fee here as it is incremented in the wrapped token

        uint256 srcNetwork;
        uint256 srcToken;

        assembly {
            srcNetwork := mload(add(transactionData, add(0x20, 32)))
            srcToken := mload(add(transactionData, add(0x20, 40)))
        }

        srcNetwork = srcNetwork >> 224;
        srcToken = srcToken >> 240;
        
        emit Deposit(nonce, sender, srcNetwork, destNetwork, srcToken, destToken, amount);
    }

    function wrapAndWithdraw(bytes memory clientSignature, bytes memory transactionData) public pause
    {
        address sender;
        uint256 nonce;
        uint256 srcNetwork;
        uint256 srcToken;
        uint256 amount;
        (sender, nonce, srcNetwork, srcToken, amount) = verifyWithdraw(clientSignature, transactionData);

        TokenData storage token = tokens_[srcToken];
        require(token.info.isWrappedToken, "Token is not a wrapped token");
        
        token.withdrawNonces[nonce] = true;
        token.info.token.transferBackingTokenFrom(sender, amount);
        
        uint256 destNetwork;
        uint256 destToken;

        assembly {
            destNetwork := mload(add(transactionData, add(0x20, 36)))
            destToken := mload(add(transactionData, add(0x20, 42)))
        }

        destNetwork = destNetwork >> 224;
        destToken = destToken >> 240;
        
        emit Withdraw(nonce, sender, srcNetwork, destNetwork, srcToken, destToken, amount);
    }

    function withdrawAccumulatedFee(uint256 tokenId, address to) public isAdmin
    {
        require(tokens_[tokenId].accumulatedFee > 0, "bridge: Accumulated fee = 0");
        tokens_[tokenId].info.token.mintTo(to, tokens_[tokenId].accumulatedFee);

        uint256 temp = tokens_[tokenId].accumulatedFee;
        tokens_[tokenId].accumulatedFee = 0;

        emit FeeWithdraw(to, tokenId, temp);
    }

    //Private functions

    function exists(address[] memory array, address entry) private pure returns (bool)
    {
        for (uint i = 0; i < array.length; i++)
        {
            if (array[i] == entry)
                return true;
        }

        return false;
    }

    function recoverSigner(bytes32 dataHash, bytes memory sig) private pure returns (address)
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
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.8.9;

// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// [email protected]

interface TokenInterface {
    function mintTo(address user, uint256 amount) external;
    function burnFrom(address user, uint256 amount) external;
    function transferBackingTokenFrom(address user, uint256 amount) external;
    function transferBackingTokenTo(address user, uint256 amount, uint256 fee) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.8.9;

// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// [email protected]

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract SecureContract is AccessControl, Initializable
{
    event ContractPaused (uint height, address user);
    event ContractUnpaused (uint height, address user);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event TokensRecovered (address token, address user, uint256 numTokens);

    bytes32 public constant _ADMIN = keccak256("_ADMIN");

    bool private paused_;
    address private owner_;

    modifier pause()
    {
        require(!paused_, "SecureContract: Contract is paused");
        _;
    }

    modifier isAdmin()
    {
        require(hasRole(_ADMIN, msg.sender), "SecureContract: Not admin - Permission denied");
        _;
    }

    modifier isOwner()
    {
        require(msg.sender == owner_, "SecureContract: Not owner - Permission denied");
        _;
    }

    constructor() {}

    function init() public initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(_ADMIN, msg.sender);
        paused_ = true;
        owner_ = msg.sender;
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

    function queryOwner() public view returns (address)
    {
        return owner_;
    }

    function transferOwnership(address newOwner) public isOwner
    {
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        grantRole(_ADMIN, newOwner);

        revokeRole(_ADMIN, owner_);
        revokeRole(DEFAULT_ADMIN_ROLE, owner_);

        address oldOwner = owner_;
        owner_ = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /*function recoverTokens(address token, address user, uint256 numTokens) public isAdmin
    {
        IERC20(token).safeTransfer(user, numTokens);
        emit TokensRecovered(token, user, numTokens);
    }*/
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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