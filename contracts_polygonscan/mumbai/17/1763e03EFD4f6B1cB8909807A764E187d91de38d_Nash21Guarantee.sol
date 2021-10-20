// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/AccessControlProxyPausable.sol";
import "./interfaces/INash21Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Nash21Guarantee is AccessControlProxyPausable {
    
    mapping(uint256=>uint256) public paid;
    mapping(uint256=>uint256) public received;

    address private _factory;
    address private _token;

    event Claim(uint256 id, address account, uint256 amount);
    event Pay(uint256 id, address account, uint256 amount);
    event Split(uint256 id, address account, uint block_, uint256 left, uint256 right);

    function claim(uint256 id) public whenNotPaused {
        INash21Factory factoryInterface = INash21Factory(_factory);
        address account = factoryInterface.ownerOf(id);
        uint256 amount = claimable(id);
        require(amount > 0, "Nash21Guarantee: nothing to claim");
        paid[id] += amount;
        IERC20 tokenInterface = IERC20(_token);
        require(tokenInterface.transfer(account, amount), "Nash21Guarantee: transfer failed");
        emit Claim(id, account, amount);
    }

    function claimable(uint256 id) public view returns (uint256) {
        return released(id) - paid[id];
    }

    function released(uint256 id) public view returns (uint256) {
        INash21Factory factoryInterface = INash21Factory(_factory);
        uint startBlock = factoryInterface.getFrom(id);
        uint endBlock = factoryInterface.getTo(id);
        if(startBlock > block.number) {
            return 0;
        } else {
            uint blocks = endBlock > block.number ? block.number - startBlock : endBlock - startBlock;
            return factoryInterface.getReleasePerBlock(id) * blocks;
        }
    }

    function pending(uint256 id) public view returns (uint256) {
        INash21Factory factoryInterface = INash21Factory(_factory);
        return factoryInterface.getValue(id) - released(id);
    }

    function fullyPaid(uint256 id) public view returns (bool) {
        INash21Factory factoryInterface = INash21Factory(_factory);
        return received[id] == factoryInterface.getValue(id);
    }

    function pay(uint256 id, uint256 amount) public whenNotPaused {
        INash21Factory factoryInterface = INash21Factory(_factory);
        require(received[id] + amount <= factoryInterface.getValue(id), "Nash21Guarantee: cant exceed value of the contract");
        address account = msg.sender;
        IERC20 tokenInterface = IERC20(_token);
        received[id] += amount;
        require(tokenInterface.transferFrom(account, address(this), amount), "Nash21Guarantee: transfer failed");
        emit Pay(id, account, amount);
    }

    function paidBlocks(uint256 id) public view returns (uint) {
        if (received[id] > released(id)) {
            INash21Factory factoryInterface = INash21Factory(_factory);
            return (received[id] - released(id)) / factoryInterface.getReleasePerBlock(id);
        } else {
            return 0;
        }
    }

    function unpaidBlocks(uint256 id) public view returns (uint) {
        if (received[id] < released(id)) {
            INash21Factory factoryInterface = INash21Factory(_factory);
            return (released(id) - received[id]) / factoryInterface.getReleasePerBlock(id);
        } else {
            return 0;
        }
    }

    function overBalanceToken(uint256 id) public view returns (uint256) {
        INash21Factory factoryInterface = INash21Factory(_factory);
        uint256 releasePerBlock = factoryInterface.getReleasePerBlock(id);
        uint256 positive = paidBlocks(id) * releasePerBlock;
        uint256 negative = unpaidBlocks(id) * releasePerBlock;
        if(positive > negative) {
            return positive - negative;
        } else {
            return 0;
        }
    }

    function underBalanceToken(uint256 id) public view returns (uint256) {
        INash21Factory factoryInterface = INash21Factory(_factory);
        uint256 releasePerBlock = factoryInterface.getReleasePerBlock(id);
        uint256 positive = paidBlocks(id) * releasePerBlock;
        uint256 negative = unpaidBlocks(id) * releasePerBlock;
        if(positive > negative) {
            return 0;
        } else {
            return negative - positive;
        }
    }

    function overBalanceBatch() public view returns (uint256) {
        INash21Factory factoryInterface = INash21Factory(_factory);
        uint256 tokens = factoryInterface.total();
        uint256 positive = 0;
        uint256 negative = 0;
        for(uint256 i=0; i<tokens; i++) {
            uint256 id = i;
            uint256 releasePerBlock = factoryInterface.getReleasePerBlock(id);
            positive += paidBlocks(id) * releasePerBlock;
            negative += unpaidBlocks(id) * releasePerBlock;
        }
        if(positive > negative) {
            return positive - negative;
        } else {
            return 0;
        }
    }

    function underBalanceBatch() public view returns (uint256) {
        INash21Factory factoryInterface = INash21Factory(_factory);
        uint256 tokens = factoryInterface.total();
        uint256 positive = 0;
        uint256 negative = 0;
        for(uint256 i=0; i<tokens; i++) {
            uint256 id = i;
            uint256 releasePerBlock = factoryInterface.getReleasePerBlock(id);
            positive += paidBlocks(id) * releasePerBlock;
            negative += unpaidBlocks(id) * releasePerBlock;
        }
        if(positive > negative) {
            return 0;
        } else {
            return negative - positive;
        }
    }

    function split(uint256 id, uint block_) public returns (uint256, uint256) {
        address account = msg.sender;
        INash21Factory factoryInterface = INash21Factory(_factory);
        (uint256 id1, uint256 id2) = factoryInterface.split(account, id, block_);
        uint256 value1 = factoryInterface.getValue(id1);
        if(paid[id] > value1) {
            paid[id1] = value1;
            paid[id2] = paid[id] - value1;
        } else {
            paid[id1] = paid[id];
        }

        if(received[id] > value1) {
            received[id1] = value1;
            received[id2] = received[id] - value1;
        } else {
            received[id1] = received[id];
        }

        emit Split(id, account, block_, id1, id2);
        return (id1, id2);
    }

    function updateToken(address token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _token = token;
    }

    function updateFactory(address factory) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _factory = factory;
    }

    constructor (address token, address factory, address rolemanager) {
        __Nash21Guarantee_init(token, factory, rolemanager);
    }

    function __Nash21Guarantee_init(address token, address factory, address rolemanager) internal initializer {
        __AccessControlProxyPausable_init(rolemanager);
        __Nash21Guarantee_init_unchained(token, factory);
    }

    function __Nash21Guarantee_init_unchained(address token, address factory) internal initializer {
        updateToken(token);
        updateFactory(factory);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

abstract contract AccessControlProxyPausable is PausableUpgradeable {

    address private _manager;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyRole(bytes32 role) {
        address account = msg.sender;
        require(hasRole(role, account), string(
                    abi.encodePacked(
                        "AccessControlProxyPausable: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                ));
        _;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        IAccessControlUpgradeable manager = IAccessControlUpgradeable(_manager);
        return manager.hasRole(role, account);
    }

    function __AccessControlProxyPausable_init(address manager) internal initializer {
        __Pausable_init();
        __AccessControlProxyPausable_init_unchained(manager);
    }

    function __AccessControlProxyPausable_init_unchained(address manager) internal initializer {
        _manager = manager;
    }

    function pause() public onlyRole(PAUSER_ROLE){
        _pause();
    }
    
    function unpause() public onlyRole(PAUSER_ROLE){
        _unpause();
    }

    function updateManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _manager = manager;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INash21Factory {

    event Authorize(address account, uint256 id, uint256 releasePerBlock, uint from, uint to);
    event Unauthorize(uint256 id);
    event Create(address account, uint256 id);
    event Split(address account, uint256 original, uint256 left, uint256 right);

    function total() external view returns (uint256);

    // Gets address of authorized {id}
    function authorized(uint256 id) external view returns (address);

    // Gets origin of {id}
    function getOrigin(uint256 id) external view returns (uint256);

    // Gets {from} from {id}
    function getFrom(uint256 id) external view returns(uint);

    // Gets {to} from {id}
    function getTo(uint256 id) external view returns(uint);

    // Gets {releasePerBlock} from {id}
    function getReleasePerBlock(uint256 id) external view returns(uint256);

    // Gets total value of {id}
    function getValue(uint256 id) external view returns (uint256);

    // Gets blocks of {id}
    function getBlocks(uint256 id) external view returns (uint);

    // Authorize an account to create {id} that represents a non-fungible token with claimable {releasePerBlock} tokens per block from block {from} to block {to}, returns the token id where JSON must be loaded
    function authorize(address account, uint256 releasePerBlock, uint from, uint to) external returns(uint256);
    
    // Unapproves the creation of {id}
    function unauthorize(uint256 id) external;

    // Creates {id} if it is authorized
    function create(uint256 id) external;

    // Splits {id} in two non-fungible tokens, burning {id} and minting (id1) and (id2)
    function split(address account, uint256 id, uint block_) external returns (uint256, uint256);

    // Sets base URI
    function setUri(string memory uri) external;

    // Initializes the contract
    function initialize(string memory name_, string memory symbol_) external;

    // Gets owner of {id}
    function ownerOf(uint256 id) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function transfer(address account, uint256 tokenId) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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