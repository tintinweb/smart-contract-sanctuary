// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./lib/Misc.sol";
import "./tokens/DERC20.sol";

contract DecimalBridge is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    // 1 - DEL, 2 - ETH, 3 - BSC
    uint256 public immutable chainId;

    // the list of all registered tokens
    address[] tokenList;

    // tokenBySymbol[Symbol] = tokenAddress
    mapping(string => address) public tokenBySymbol;

    // chainList[chainId] = enabled
    mapping(uint256 => bool) public chainList;

    // swaps[hashedMsg] = SwapData
    mapping(bytes32 => SwapData) public swaps;

    // Struct of swap
    struct SwapData {
        uint256 transaction; // transaction number
        State state;
    }

    // Status of swap
    enum State {
        Empty,
        Initialized,
        Redeemed
    }

    /**
     * @dev Emitted when swap to Decimal chain created
     *
     */
    event SwapToDecimalInitialized(
        uint256 timestamp,
        address indexed initiator,
        string recipient,
        uint256 amount,
        string tokenSymbol,
        uint256 chainTo,
        uint256 nonce
    );

    /**
     * @dev Emitted when swap to other chain created
     *
     */
    event SwapInitialized(
        uint256 timestamp,
        address indexed initiator,
        address recipient,
        uint256 amount,
        string tokenSymbol,
        uint256 chainTo,
        uint256 nonce
    );

    /**
     * @dev Emitted when swap redeemed.
     */
    event SwapRedeemed(
        address indexed initiator,
        uint256 timestamp,
        uint256 nonce
    );

    /**
     * @dev Emitted when new token added
     */
    event TokenAdded(address token, string symbol);

    constructor(uint256 _chainId) {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        // Sets `ADMIN_ROLE` as `VALIDATOR_ROLE`'s admin role.
        _setRoleAdmin(VALIDATOR_ROLE, ADMIN_ROLE);
        // Sets `ADMIN_ROLE` as `MINTER_ROLE`'s admin role.
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        // Sets `ADMIN_ROLE` as `BURNER_ROLE`'s admin role.
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        // Sets `ADMIN_ROLE` as `PAUSER_ROLE`'s admin role.
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);

        chainId = _chainId; // 1 - DEL, 2 - ETH, 3 - BSC
    }

    /**
     * @dev Returned list of registered tokens
     */
    function getTokenList() public view returns (address[] memory) {
        return tokenList;
    }

    /**
     * @dev Creates new swap.
     *
     * Emits a {SwapInitialized} event
     *
     * Arguments
     *
     * - `amount` amount of tokens
     * - `nonce` number of transaction
     * - `recipient` recipient address in another network
     * - `chainTo` destination chain id
     * - `tokenSymbol` - symbol of token
     */
    function swap(
        uint256 amount,
        uint256 nonce,
        address recipient,
        uint256 chainTo,
        string memory tokenSymbol
    ) external {
        require(chainTo != chainId, "DecimalBridge: Invalid chainTo id");
        require(chainList[chainTo], "DecimalBridge: ChainTo id is not allowed");
        address tokenAddress = tokenBySymbol[tokenSymbol];
        require(
            tokenAddress != address(0),
            "DecimalBridge: Token is not registered"
        );
        bytes32 hashedMsg = keccak256(
            abi.encodePacked(
                nonce,
                amount,
                tokenSymbol,
                recipient,
                chainId,
                chainTo
            )
        );

        require(
            swaps[hashedMsg].state == State.Empty,
            "DecimalBridge: Swap is not empty state or duplicate tx"
        );

        swaps[hashedMsg] = SwapData({
            transaction: nonce,
            state: State.Initialized
        });

        DERC20(tokenAddress).burn(msg.sender, amount);

        emit SwapInitialized(
            block.timestamp,
            msg.sender,
            recipient,
            amount,
            tokenSymbol,
            chainTo,
            nonce
        );
    }

    /**
     * @dev Creates new swap to decimal chain
     *
     * Emits a {SwapInitialized} event.
     *
     * Arguments
     *
     * - `amount` amount of tokens
     * - `nonce` number of transaction
     * - `recipient` recipient address in decimal network
     * - `tokenSymbol` symbol of token
     */
    function swapToDecimal(
        uint256 amount,
        uint256 nonce,
        string memory recipient,
        string memory tokenSymbol
    ) external {
        address tokenAddress = tokenBySymbol[tokenSymbol];
        require(
            tokenAddress != address(0),
            "DecimalBridge: Token is not registered"
        );
        require(
            bytes(recipient).length == 41,
            "DecimalBridge: Recipient must be 41 symbols long"
        );
        bytes32 hashedMsg = keccak256(
            abi.encodePacked(
                nonce,
                amount,
                tokenSymbol,
                recipient,
                chainId,
                uint256(1)
            )
        );

        require(
            swaps[hashedMsg].state == State.Empty,
            "DecimalBridge: Swap is not empty state or duplicate tx"
        );

        swaps[hashedMsg] = SwapData({
            transaction: nonce,
            state: State.Initialized
        });

        DERC20(tokenAddress).burn(msg.sender, amount);

        emit SwapToDecimalInitialized(
            block.timestamp,
            msg.sender,
            recipient,
            amount,
            tokenSymbol,
            1,
            nonce
        );
    }

    /**
     * @dev Execute redeem.
     *
     * Emits a {SwapRedeemed} event.
     * Emits a {TokenAdded} event when new token sended
     *
     * Arguments:
     *
     * - `amount` amount of transaction.
     * - `recipient` recipient address in target network.
     * - `nonce` number of transaction.
     * - `chainFrom` source chain id
     * - `_v` v of signature.
     * - `_r` r of signature.
     * - `_s` s of signature.
     * - `tokenSymbol` symbol of token
     */
    function redeem(
        uint256 amount,
        address recipient,
        uint256 nonce,
        uint256 chainFrom,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        string memory tokenSymbol
    ) external {
        require(chainFrom != chainId, "DecimalBridge: Invalid chainFrom id");
        require(
            chainList[chainFrom],
            "DecimalBridge: ChainFrom id not allowed"
        );
        require(
            bytes(tokenSymbol).length > 0,
            "DecimalBridge: Symbol length should be greater than 0"
        );
        address tokenAddress = tokenBySymbol[tokenSymbol];
        if (tokenAddress == address(0)) {
            tokenAddress = address(new DERC20(tokenSymbol));
            tokenBySymbol[tokenSymbol] = tokenAddress;
            tokenList.push(tokenAddress);
            emit TokenAdded(tokenAddress, tokenSymbol);
        }
        bytes32 message = keccak256(
            abi.encodePacked(
                nonce,
                amount,
                tokenSymbol,
                recipient,
                chainFrom,
                chainId
            )
        );
        require(
            swaps[message].state == State.Empty,
            "DecimalBridge: Swap is not empty state or duplicate tx"
        );

        bytes32 hashedMsg = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        address signer = Misc.recover(hashedMsg, _v, _r, _s);
        require(
            hasRole(VALIDATOR_ROLE, signer),
            "DecimalBridge: Validator address is invalid"
        );

        swaps[message] = SwapData({transaction: nonce, state: State.Redeemed});

        DERC20(tokenAddress).mint(recipient, amount);

        emit SwapRedeemed(msg.sender, block.timestamp, nonce);
    }

    /**
     * @dev Returns swap state.
     *
     * Arguments
     *
     * - `hashedSecret` hash of swap.
     */
    function getSwapState(bytes32 hashedSecret)
        external
        view
        returns (State state)
    {
        return swaps[hashedSecret].state;
    }

    /**
     * @dev Add a new token
     *
     * Emits a {TokenAdded} event.
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     */
    function addToken(string memory symbol) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        require(
            bytes(symbol).length > 0,
            "DecimalBridge: Symbol length should be greater than 0"
        );
        address tokenAddress = tokenBySymbol[symbol];
        require(
            tokenAddress == address(0),
            "DecimalBridge: Token is already registered"
        );

        tokenAddress = address(new DERC20(symbol));
        tokenBySymbol[symbol] = tokenAddress;
        tokenList.push(tokenAddress);
        emit TokenAdded(tokenAddress, symbol);
    }

    /**
     * @dev Update a token address
     *
     * Arguments
     *
     * - `symbol` symbol of a token.
     * - `newToken` new address of a token
     */
    function updateToken(string memory symbol, address newToken) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        tokenBySymbol[symbol] = newToken;
    }

    /**
     * @dev Manually mint token by symbol
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     * - `to` recipient address.
     * - `amount` amount of tokens.
     */
    function mintToken(
        string memory symbol,
        address to,
        uint256 amount
    ) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "DecimalBridge: Caller is not a minter"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).mint(to, amount);
    }

    /**
     * @dev Manually burn token by symbol
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     * - `from` address of user.
     * - `amount` amount of tokens.
     */
    function burnToken(
        string memory symbol,
        address from,
        uint256 amount
    ) external {
        require(
            hasRole(BURNER_ROLE, msg.sender),
            "DecimalBridge: Caller is not a burner"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).burn(from, amount);
    }

    /**
     * @dev Grant role for token by symbol
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     * - `role` role constant.
     * - `user` address of user.
     */
    function grantRoleToken(
        string memory symbol,
        bytes32 role,
        address user
    ) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).grantRole(role, user);
    }

    /**
     * @dev Add enabled chain direction to bridge
     *
     * Arguments
     *
     * - `_chainId` id of chain.
     * - `enabled` true - enable chain, false - disable chain.
     */
    function updateChain(uint256 _chainId, bool enabled) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        chainList[_chainId] = enabled;
    }

    /**
     * @dev Update name of token
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     * - `name` name of token
     */
    function updateTokenName(string memory symbol, string memory name)
        external
    {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).updateName(name);
    }

    /**
     * @dev Pause token
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     */
    function pauseToken(string memory symbol) external {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "DecimalBridge: Caller is not a pauser"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).pause();
    }

    /**
     * @dev Unpause token
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     */
    function unpauseToken(string memory symbol) external {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "DecimalBridge: Caller is not a pauser"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

library Misc {
    function recover(
        bytes32 hashedMsg,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
        address signer = ecrecover(hashedMsg, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DERC20 is ERC20Pausable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private owner;
    string private _name;

    mapping(address => bool) public isBlockListed;

    event AddedBlockList(address user);
    event RemovedBlockList(address user);

    constructor(string memory symbol) ERC20("", symbol) {
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
    }

    /**
     * @dev Returns the owner of the token.
     * Binance Smart Chain BEP20 compatibility
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Mint token
     *
     * Requirements
     *
     * - `to` recipient address.
     * - `amount` amount of tokens.
     */
    function mint(address to, uint256 amount) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "You should have a minter role"
        );
        _mint(to, amount);
    }

    /**
     * @dev Burn token
     *
     * Requirements
     *
     * - `from` address of user.
     * - `amount` amount of tokens.
     */
    function burn(address from, uint256 amount) external {
        require(
            hasRole(BURNER_ROLE, msg.sender),
            "You should have a burner role"
        );
        _burn(from, amount);
    }

    /**
     * @dev Pause token
     */
    function pause() external {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "You should have a pauser role"
        );
        super._pause();
    }

    /**
     * @dev Pause token
     */
    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "You should have a pauser role"
        );
        super._unpause();
    }

    /**
     * @dev Add user address to blocklist
     *
     * Requirements
     *
     * - `user` address of user.
     */
    function addBlockList(address user) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You should have an admin role"
        );
        isBlockListed[user] = true;
        emit AddedBlockList(user);
    }

    /**
     * @dev Remove user address from blocklist
     *
     * Requirements
     *
     * - `user` address of user.
     */
    function removeBlockList(address user) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You should have an admin role"
        );
        isBlockListed[user] = false;

        emit RemovedBlockList(user);
    }

    /**
     * @dev Update name of token
     *
     * Requirements
     *
     * - `name_` name of token
     */
    function updateName(string memory name_) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You should have an admin role"
        );
        _name = name_;
    }

    /**
     * @dev check blocklist when token minted, burned or transfered
     *
     * Requirements
     *
     * - `from` source address
     * - `to` destination address
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
        require(isBlockListed[from] == false, "Address from is blocklisted");
        require(isBlockListed[to] == false, "Address to is blocklisted");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
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
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

