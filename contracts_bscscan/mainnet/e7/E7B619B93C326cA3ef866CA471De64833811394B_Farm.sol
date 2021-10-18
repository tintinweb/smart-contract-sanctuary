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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./interfaces/IBEP20.sol";
import "./interfaces/IEIP2612.sol";

error ApproveFromZeroAddress(address spender, uint256 amount);
error ApproveToZeroAddress(address owner, uint256 amount);

error MintToZeroAddress(uint256 amount);

error BurnFromZeroAddress(uint256 amount);
error BurnAmountExceedsBalance(address from, uint256 amount, uint256 balance);

error TransferFromZeroAddress(address to, uint256 amount);
error TransferToZeroAddress(address from, uint256 amount);
error TransferAmountExceedsAllowance(address from, address to, uint256 amount, uint256 allowance);
error TransferAmountExceedsBalance(address from, address to, uint256 amount, uint256 balance);

error OnlyOwnerAllowed();

error EIP2612PermissionExpired(uint256 deadline);
error EIP2612InvalidSignature(address owner, address signer);

contract BaseToken is INamedBEP20, IEIP2612 {
    bytes32 public constant EIP_712_DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant PERMIT_TYPE_HASH =
        keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");

    string public override name;
    string public override symbol;
    uint8 public override decimals;
    address public override getOwner;
    string public version;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public override DOMAIN_SEPARATOR;
    mapping(address => uint256) public override nonces;

    constructor() {
        getOwner = msg.sender;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        if (from != msg.sender) {
            uint256 _allowance = allowance[from][msg.sender];
            if (_allowance < amount) {
                revert TransferAmountExceedsAllowance(from, to, amount, _allowance);
            }
        }

        _transfer(from, to, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        if (deadline < block.timestamp) {
            revert EIP2612PermissionExpired(deadline);
        }

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPE_HASH, owner, spender, amount, nonces[owner]++, deadline))
            )
        );
        address signer = ecrecover(hash, v, r, s);
        if (signer != owner) {
            revert EIP2612InvalidSignature(owner, signer);
        }
        _approve(owner, spender, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        if (owner == address(0)) {
            revert ApproveFromZeroAddress(spender, amount);
        }
        if (spender == address(0)) {
            revert ApproveToZeroAddress(owner, amount);
        }

        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        if (to == address(0)) {
            revert MintToZeroAddress(amount);
        }

        balanceOf[to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        if (from == address(0)) {
            revert BurnFromZeroAddress(amount);
        }

        uint256 balance = balanceOf[from];
        if (balance < amount) {
            revert BurnAmountExceedsBalance(from, amount, balance);
        }
        unchecked {
            balanceOf[from] = balance - amount;
        }
        totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            revert TransferFromZeroAddress(to, amount);
        }
        if (to == address(0)) {
            revert TransferToZeroAddress(from, amount);
        }

        uint256 balance = balanceOf[from];
        if (balance < amount) {
            revert TransferAmountExceedsBalance(from, to, amount, balance);
        }
        unchecked {
            balanceOf[from] = balance - amount;
        }
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _updateMetadata(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        string memory _version
    ) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        version = _version;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP_712_DOMAIN_TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.9;

import "./helpers/Ownable.sol";
import "./helpers/ReentrancyGuard.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IFarm.sol";
import "./interfaces/IVault.sol";
import "./libraries/SafeBEP20.sol";
import "./Vault.sol";

error FireDAOVaultAlreadyExists();
error FireDAOAlreadyStarted();

interface IFire is IBEP20 {
    function mint(address dst, uint256 rawAmount) external;

    function seize(address src, uint256 rawAmount) external;
}

contract Farm is IFarm, Ownable, ReentrancyGuarded {
    using SafeBEP20 for IBEP20;
    using SafeBEP20 for IFire;

    struct User {
        uint256 shares;
        uint256 rewardDebt;
    }

    struct Pool {
        IBEP20 token;
        uint256 sharesTotal;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accFirePerShare;
    }

    uint256 public constant FIRE_MAX_SUPPLY = 1650000e18;
    uint256 public constant FIRE_PER_BLOCK = 1909722222222222222;

    IFire public immutable fire;
    IBEP20 public immutable lpToken;

    address public timelock;
    address public harvester;

    mapping(IBEP20 => mapping(IBEP20 => IVault)) public vaults;
    mapping(IVault => bool) public vaultStatuses;
    mapping(IBEP20 => Pool) public pools;
    mapping(IBEP20 => mapping(address => User)) public users;

    uint256 public startBlock;
    uint256 public totalAllocPoint;

    event VaultCreated(IBEP20 indexed underlying, IBEP20 indexed target, IVault vault);
    event Deposit(address indexed user, IBEP20 indexed pool, uint256 amount);
    event Withdraw(address indexed user, IBEP20 indexed pool, uint256 amount);
    event Claim(address indexed user, IBEP20 indexed pool, uint256 amount);

    modifier onlyVaults() {
        require(vaultStatuses[IVault(msg.sender)], "FIREDAO: Only vault allowed");
        _;
    }

    constructor(
        IFire _fire,
        IBEP20 _lpToken,
        address _timelock,
        address _harvester
    ) {
        fire = _fire;
        lpToken = _lpToken;
        timelock = _timelock;
        harvester = _harvester;
    }

    function createVault(INamedBEP20 underlying, INamedBEP20 target) external onlyOwner returns (Vault vault) {
        if (address(vaults[underlying][target]) != address(0)) {
            revert FireDAOVaultAlreadyExists();
        }
        bytes memory creationCode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(underlying, target));
        assembly {
            vault := create2(0, add(creationCode, 32), mload(creationCode), salt)
        }
        vault.transitOwnership(msg.sender, true);
        vault.initialize(underlying, target, timelock, harvester);

        vaults[underlying][target] = vault;
        vaultStatuses[vault] = true;

        emit VaultCreated(underlying, target, vault);
    }

    function addPool(IBEP20 token, uint256 allocPoint) external onlyOwner {
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += allocPoint;
        pools[token] = Pool({
            token: token,
            sharesTotal: 0,
            allocPoint: allocPoint,
            lastRewardBlock: lastRewardBlock,
            accFirePerShare: 0
        });
    }

    function setPool(IBEP20 token, uint256 allocPoint) external onlyOwner {
        totalAllocPoint = totalAllocPoint - pools[token].allocPoint + allocPoint;
        pools[token].allocPoint = allocPoint;
    }

    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) external override onlyVaults {
        withdraw(sender, amount);
        deposit(recipient, amount);
    }

    function claim(IBEP20 token) external {
        updatePool(token);
        Pool memory pool = pools[token];
        User storage user = users[token][msg.sender];

        uint256 pending = ((user.shares * pool.accFirePerShare) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            fire.safeTransfer(msg.sender, pending);
        }

        user.rewardDebt = (user.shares * pool.accFirePerShare) / 1e12;
    }

    function start() external onlyOwner {
        if (startBlock != 0) {
            revert FireDAOAlreadyStarted();
        }

        startBlock = block.number;
    }

    function sweep(IBEP20 token) external onlyOwner {
        require(address(token) != address(fire), "LiquidityMining: sweeping of FIRE token not allowed");
        token.safeTransfer(owner, token.balanceOf(address(this)));
    }

    function pendingFire(IBEP20 token, address account) external view returns (uint256) {
        Pool memory pool = pools[token];
        User memory user = users[token][account];
        uint256 accFirePerShare = pool.accFirePerShare;
        uint256 sharesTotal = pool.sharesTotal;
        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 fireReward = (multiplier * FIRE_PER_BLOCK * pool.allocPoint) / totalAllocPoint;
            accFirePerShare += (fireReward * 1e12) / sharesTotal;
        }
        return ((user.shares * accFirePerShare) / 1e12) - user.rewardDebt;
    }

    function deposit(address account, uint256 amount) public override onlyVaults {
        IVault vault = IVault(msg.sender);
        IBEP20 underlying = vault.underlying();

        updatePool(underlying);
        Pool storage pool = pools[underlying];
        User storage user = users[underlying][account];

        uint256 shares = user.shares;
        if (shares > 0) {
            uint256 pending = ((shares * pool.accFirePerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                fire.safeTransfer(account, pending);
            }
        }

        if (amount > 0) {
            user.shares += amount;
            pool.sharesTotal += amount;
        }

        user.rewardDebt = (user.shares * pool.accFirePerShare) / 1e12;
        emit Deposit(account, underlying, amount);
    }

    function depositLpTokens(uint256 amount) public nonReentrant {
        updatePool(lpToken);
        Pool storage pool = pools[lpToken];
        User storage user = users[lpToken][msg.sender];

        uint256 shares = user.shares;
        if (shares > 0) {
            uint256 pending = ((shares * pool.accFirePerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                fire.safeTransfer(msg.sender, pending);
            }
        }

        if (amount > 0) {
            lpToken.safeTransferFrom(msg.sender, address(this), amount);
            user.shares += amount;
            pool.sharesTotal += amount;
        }

        user.rewardDebt = (user.shares * pool.accFirePerShare) / 1e12;
        emit Deposit(msg.sender, lpToken, amount);
    }

    function withdraw(address account, uint256 amount) public override onlyVaults {
        IVault vault = IVault(msg.sender);
        IBEP20 underlying = vault.underlying();

        updatePool(underlying);
        Pool storage pool = pools[underlying];
        User storage user = users[underlying][account];

        require(user.shares > 0, "user.shares is 0");
        require(pool.sharesTotal > 0, "pool.sharesTotal is 0");

        // Withdraw pending FIRE
        uint256 pending = ((user.shares * pool.accFirePerShare) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            fire.safeTransfer(account, pending);
        }

        if (amount > user.shares) {
            user.shares = 0;
        } else {
            user.shares -= amount;
        }

        if (amount > pool.sharesTotal) {
            pool.sharesTotal = 0;
        } else {
            pool.sharesTotal -= amount;
        }

        user.rewardDebt = (user.shares * pool.accFirePerShare) / 1e12;
        emit Withdraw(account, underlying, amount);
    }

    function withdrawLpTokens(uint256 amount) public nonReentrant {
        updatePool(lpToken);
        Pool memory pool = pools[lpToken];
        User storage user = users[lpToken][msg.sender];

        require(user.shares > 0, "user.shares is 0");
        require(pool.sharesTotal > 0, "pool.sharesTotal is 0");

        // Withdraw pending FIRE
        uint256 pending = ((user.shares * pool.accFirePerShare) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            fire.safeTransfer(msg.sender, pending);
        }

        if (amount > 0) {
            if (amount > user.shares) {
                user.shares = 0;
            } else {
                user.shares -= amount;
            }

            if (amount > pool.sharesTotal) {
                pool.sharesTotal = 0;
            } else {
                pool.sharesTotal -= amount;
            }

            uint256 balance = lpToken.balanceOf(address(this));
            if (balance < amount) {
                amount = balance;
            }
            lpToken.safeTransfer(msg.sender, amount);
        }

        user.rewardDebt = (user.shares * pool.accFirePerShare) / 1e12;
        emit Withdraw(msg.sender, lpToken, amount);
    }

    function updatePool(IBEP20 token) public {
        Pool storage pool = pools[token];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 sharesTotal = pool.sharesTotal;
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (multiplier <= 0) {
            return;
        }
        uint256 fireReward = (multiplier * FIRE_PER_BLOCK * pool.allocPoint) / totalAllocPoint;
        fire.mint(address(this), fireReward);

        pool.accFirePerShare += (fireReward * 1e12) / sharesTotal;
        pool.lastRewardBlock = block.number;
    }

    function getMultiplier(uint256 from, uint256 to) public view returns (uint256) {
        if (fire.totalSupply() >= FIRE_MAX_SUPPLY) {
            return 0;
        }
        return to - from;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./BaseToken.sol";
import "./helpers/Ownable.sol";
import "./helpers/Pausable.sol";
import "./helpers/ReentrancyGuard.sol";
import "./interfaces/IFarm.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";
import "./libraries/Address.sol";
import "./libraries/SafeBEP20.sol";
import "./libraries/SafeCast.sol";

error FireDAOOnlyFarmAllowedToCall();
error FireDAOOnlyEarnerAllowedToCall();
error FireDAOOnlyTimelockAllowedToCall();
error FireDAOTokenNotAllowedToBeSalvaged(IBEP20 token);
error FireDAOAmountExceedsDepositLimit();
error FireDAOMinimumBalanceTooHigh();
error FireDAOOnlyHarvesterAllowedToCall();
error FireDAOTotalSupplyIsZero();
error FireDAODepositZeroAmount();
error FireDAOWithdrawZeroAmount();
error FireDAODistributeZeroAmount();

contract Vault is IVault, AccessControl, BaseToken, Ownable, Pausable, ReentrancyGuarded {
    using Address for address;
    using SafeBEP20 for IBEP20;
    using SafeCast for int256;
    using SafeCast for uint256;

    bytes32 public constant EARNER_ROLE = keccak256("EARNER_ROLE");
    uint256 internal constant POINTS_MULTIPLIER = 2**128;
    uint256 private constant ONE = 100e16;

    IBEP20 public underlying;
    IBEP20 public target;

    IFarm public farm;
    address public timelock;
    address public harvester;
    IStrategy public strategy;

    uint256 public depositLimit = type(uint256).max;
    uint256 public minimumBalance = 10e16; // 10 %

    uint256 internal pointsPerShare;
    mapping(address => int256) internal pointsCorrections;
    mapping(address => uint256) internal claimedDividends;

    event DepositLimitUpdated(uint256 depositLimit, uint256 newDepositLimit);
    event MinimumBalanceUpdated(uint256 minimumBalance, uint256 newMinimumBalance);
    event StrategyUpdated(IStrategy strategy, IStrategy newStrategy);

    event Claimed(address indexed account, uint256 amount);

    modifier onlyHarvester() {
        if (msg.sender != harvester) {
            revert FireDAOOnlyHarvesterAllowedToCall();
        }
        _;
    }

    constructor() {
        farm = IFarm(msg.sender);
    }

    function initialize(
        INamedBEP20 _underlying,
        INamedBEP20 _target,
        address _timelock,
        address _harvester
    ) external {
        if (msg.sender != address(farm)) {
            revert FireDAOOnlyFarmAllowedToCall();
        }

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(EARNER_ROLE, owner);

        underlying = _underlying;
        target = _target;
        timelock = _timelock;
        harvester = _harvester;

        _updateMetadata(
            string(abi.encodePacked("FireDAO ", _underlying.symbol(), " to ", _target.symbol(), " Yield Token")),
            string(abi.encodePacked("fi", _underlying.symbol(), "->", _target.symbol())),
            _underlying.decimals(),
            "1"
        );

        pause();
    }

    function deposit(uint256 amount) external override nonReentrant {
        if (amount == 0) {
            revert FireDAODepositZeroAmount();
        }
        if (totalSupply + amount >= depositLimit) {
            revert FireDAOAmountExceedsDepositLimit();
        }

        underlying.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        farm.deposit(msg.sender, amount);
    }

    function earn() external nonReentrant {
        if (!hasRole(EARNER_ROLE, msg.sender)) {
            revert FireDAOOnlyEarnerAllowedToCall();
        }

        uint256 balance = underlying.balanceOf(address(this));
        uint256 amount = (balance * (ONE - minimumBalance)) / ONE;
        address(strategy).delegateCall(
            abi.encodeWithSelector(IStrategy.invest.selector, underlying, amount),
            "FireDAO: low-level strategy call failed"
        );

        emit Earn(msg.sender, block.timestamp);
    }

    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) {
            revert FireDAOWithdrawZeroAmount();
        }

        _burn(msg.sender, amount);
        uint256 balance = underlying.balanceOf(address(this));
        if (amount > balance) {
            address(strategy).delegateCall(
                abi.encodeWithSelector(IStrategy.divest.selector, underlying, amount - balance),
                "FireDAO: low-level strategy call failed"
            );
        }

        farm.withdraw(msg.sender, amount);
    }

    function setStrategy(IStrategy newStrategy) external {
        if (address(strategy) != address(0)) {
            if (msg.sender != timelock) {
                revert FireDAOOnlyTimelockAllowedToCall();
            }
        } else {
            if (msg.sender != owner) {
                revert OwnableOnlyOwnerAllowedToCall();
            }
            unpause();
        }
        emit StrategyUpdated(strategy, newStrategy);
        strategy = newStrategy;
    }

    function setDepositLimit(uint256 newDepositLimit) external onlyOwner {
        emit DepositLimitUpdated(depositLimit, newDepositLimit);
        depositLimit = newDepositLimit;
    }

    function setMinimumBalance(uint256 newMinimumBalance) external onlyOwner {
        if (newMinimumBalance >= ONE) {
            revert FireDAOMinimumBalanceTooHigh();
        }
        emit MinimumBalanceUpdated(minimumBalance, newMinimumBalance);
        minimumBalance = newMinimumBalance;
    }

    function salvage(IBEP20 token) external onlyOwner {
        if (token == underlying || token == target) {
            revert FireDAOTokenNotAllowedToBeSalvaged(token);
        }
        token.safeTransfer(owner, token.balanceOf(address(this)));
    }

    function harvest() external override onlyHarvester returns (uint256 amount) {
        address(strategy).delegateCall(
            abi.encodeWithSelector(IStrategy.harvest.selector, underlying),
            "FireDAO: low-level strategy call failed"
        );

        amount = underlyingYield();
        address(strategy).delegateCall(
            abi.encodeWithSelector(IStrategy.divest.selector, underlying, amount),
            "FireDAO: low-level strategy call failed"
        );
        underlying.safeTransfer(harvester, amount);
    }

    function distributeDividends(uint256 amount) external override onlyHarvester {
        if (totalSupply == 0) {
            revert FireDAOTotalSupplyIsZero();
        }
        if (amount == 0) {
            revert FireDAODistributeZeroAmount();
        }

        pointsPerShare = pointsPerShare + ((amount * POINTS_MULTIPLIER) / totalSupply);
        target.safeTransferFrom(msg.sender, address(this), amount);
    }

    function strategyValue() external returns (uint256) {
        return strategy.getInvestedAmount(underlying);
    }

    function claim() public override {
        uint256 claimableDividends = unclaimedProfit(msg.sender);

        claimedDividends[msg.sender] = claimedDividends[msg.sender] + claimableDividends;
        target.safeTransfer(msg.sender, claimableDividends);

        emit Claimed(msg.sender, claimableDividends);
    }

    function underlyingYield() public override returns (uint256 yield) {
        bytes memory data = address(strategy).delegateCall(
            abi.encodeWithSelector(IStrategy.estimateTotalValue.selector, underlying),
            "FireDAO: low-level strategy call failed"
        );
        uint256 estimatedTotalValue = abi.decode(data, (uint256));
        yield = estimatedTotalValue + underlying.balanceOf(address(this)) - totalSupply;
    }

    function unclaimedProfit(address account) public view returns (uint256) {
        uint256 accumulativeDividends = ((pointsPerShare * balanceOf[account]).toInt256() +
            pointsCorrections[msg.sender]).toUint256() / POINTS_MULTIPLIER;
        return accumulativeDividends - claimedDividends[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._transfer(from, to, amount);

        int256 pointsCorrection = (pointsPerShare * amount).toInt256();
        pointsCorrections[from] = pointsCorrections[from] + pointsCorrection;
        pointsCorrections[to] = pointsCorrections[to] - pointsCorrection;
    }

    function _mint(address to, uint256 amount) internal override {
        super._mint(to, amount);

        pointsCorrections[to] = pointsCorrections[to] - (pointsPerShare * amount).toInt256();
    }

    function _burn(address from, uint256 amount) internal override {
        super._burn(from, amount);

        pointsCorrections[from] = pointsCorrections[from] + (pointsPerShare * amount).toInt256();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error OwnableOnlyOwnerAllowedToCall();
error OwnableOnlyPendingOwnerAllowedToCall();
error OwnableOwnerZeroAddress();
error OwnableCantOwnItself();

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event PendingOwnershipTransition(address indexed owner, address indexed newOwner);
    event OwnershipTransited(address indexed owner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnableOnlyOwnerAllowedToCall();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
        emit PendingOwnershipTransition(address(0), owner);
        emit OwnershipTransited(address(0), owner);
    }

    function transitOwnership(address newOwner, bool force) public onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableOwnerZeroAddress();
        }
        if (newOwner == address(this)) {
            revert OwnableCantOwnItself();
        }

        pendingOwner = newOwner;
        if (!force) {
            emit PendingOwnershipTransition(owner, newOwner);
        } else {
            owner = newOwner;
            emit OwnershipTransited(owner, newOwner);
        }
    }

    function acceptOwnership() public {
        if (msg.sender != pendingOwner) {
            revert OwnableOnlyPendingOwnerAllowedToCall();
        }

        owner = pendingOwner;
        emit OwnershipTransited(owner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error PausableContractIsPaused();
error PausableContractIsNotPaused();

abstract contract Pausable {
    bool public isPaused;

    event Paused();
    event Unpaused();

    modifier whenNotPaused() {
        if (isPaused) {
            revert PausableContractIsPaused();
        }
        _;
    }

    modifier whenPaused() {
        if (!isPaused) {
            revert PausableContractIsNotPaused();
        }
        _;
    }

    function pause() internal whenNotPaused {
        isPaused = true;
        emit Paused();
    }

    function unpause() internal whenPaused {
        isPaused = false;
        emit Unpaused();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error ReentrancyGuardReentrantCall();

abstract contract ReentrancyGuarded {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private status;

    modifier nonReentrant() {
        if (status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }

    constructor() {
        status = NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBEP20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function getOwner() external view returns (address);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface INamedBEP20 is IBEP20 {
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IBEP20.sol";

interface IEIP2612 is IBEP20 {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFarm {
    function deposit(address account, uint256 amount) external;

    function withdraw(address account, uint256 amount) external;

    function transfer(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IBEP20} from "./../interfaces/IBEP20.sol";

error FireDAOBnbTransferNotAllowed();
error FireDAOStrategyUnsupportedToken(IBEP20 token);

interface IStrategy {
    function invest(IBEP20 token, uint256 amount) external;

    function harvest(IBEP20 token) external;

    function divest(IBEP20 token, uint256 amount) external;

    function getInvestedAmount(IBEP20 token) external returns (uint256 investedAmount);

    function estimateTotalValue(IBEP20 token) external returns (uint256 totalValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IBEP20.sol";

interface IVault is INamedBEP20 {
    event Earn(address indexed by, uint256 timestamp);

    function deposit(uint256 amount) external;

    function earn() external;

    function harvest() external returns (uint256 amount);

    function distributeDividends(uint256 amount) external;

    function claim() external;

    function withdraw(uint256 amount) external;

    function strategyValue() external returns (uint256);

    function underlyingYield() external returns (uint256 yield);

    function unclaimedProfit(address account) external view returns (uint256);

    function underlying() external view returns (IBEP20);

    function target() external view returns (IBEP20);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error CallToNonContract(address target);

library Address {
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.call(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function delegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.delegatecall(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }

        return codeSize > 0;
    }

    function verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returnData;
        } else {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(returnData, 32), returnDataSize)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../interfaces/IBEP20.sol";
import "./Address.sol";

error SafeBEP20NoReturnData();

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    function callWithOptionalReturn(IBEP20 token, bytes memory data) internal {
        address tokenAddress = address(token);

        bytes memory returnData = tokenAddress.functionCall(data, "SafeBEP20: low-level call failed");
        if (returnData.length > 0) {
            if (!abi.decode(returnData, (bool))) {
                revert SafeBEP20NoReturnData();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error CastValueMustBePositive(int256 value);
error CastValueDoesntFit(uint256 value);

library SafeCast {
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert CastValueMustBePositive(value);
        }
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        if (value > uint256(type(int256).max)) {
            revert CastValueDoesntFit(value);
        }
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}