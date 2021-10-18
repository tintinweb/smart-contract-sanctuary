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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./helpers/Ownable.sol";
import "./interfaces/IVault.sol";
import "./libraries/SafeBEP20.sol";
import {IBEP20} from "./interfaces/IBEP20.sol";
import {PancakeSwap} from "./libraries/PancakeSwap.sol";

error FireDAOOnlyHarvesterAllowedToCall();
error FireDAOTreasuryZeroAddress();
error FireDAOFeesTooHigh();

contract Harvester is AccessControl, Ownable {
    using SafeBEP20 for IBEP20;
    using PancakeSwap for IBEP20;

    bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");
    uint256 private constant ONE = 100e16;

    IBEP20 public immutable fire;

    address public treasury;

    uint256 public performanceFee = 10e16; // 10 %
    uint256 public fireBuyBack = 10e16; // 10 %

    mapping(IVault => uint256) public lastHarvestAt;
    mapping(IVault => uint256) public ratePerToken;

    event TreasuryUpdated(address treasury, address newTreasury);
    event PerformanceFeeUpdated(uint256 performanceFee, uint256 newPerformanceFee);
    event FireBuyBackUpdated(uint256 fireBuyBack, uint256 newFireBuyBack);
    event Harvest(IVault indexed vault, uint256 timestamp, uint256 amount);

    constructor(IBEP20 _fire, address _treasury) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(HARVESTER_ROLE, msg.sender);

        fire = _fire;
        treasury = _treasury;
    }

    function harvestVault(IVault vault) external {
        if (!hasRole(HARVESTER_ROLE, msg.sender)) {
            revert FireDAOOnlyHarvesterAllowedToCall();
        }

        IBEP20 from = vault.underlying();
        uint256 amount = vault.harvest();
        uint256 afterFee = amount - ((amount * (performanceFee + fireBuyBack)) / ONE);
        uint256 durationSinceLastHarvest = block.timestamp - lastHarvestAt[vault];
        ratePerToken[vault] =
            (afterFee * (10**(36 - from.decimals()))) /
            vault.totalSupply() /
            durationSinceLastHarvest;
        lastHarvestAt[vault] = block.timestamp;

        IBEP20 to = vault.target();
        if (from != to) {
            amount = from.swap(
                to,
                amount,
                PancakeSwap.SENSIBLE_DEFAULT_SLIPPAGE_TOLERANCE,
                PancakeSwap.SENSIBLE_DEFAULT_SWAP_DEADLINE
            );
        }

        afterFee = amount;
        if (fireBuyBack > 0) {
            uint256 fee = (amount * fireBuyBack) / ONE;
            to.swap(
                fire,
                fee,
                PancakeSwap.SENSIBLE_DEFAULT_SLIPPAGE_TOLERANCE,
                PancakeSwap.SENSIBLE_DEFAULT_SWAP_DEADLINE
            );
            afterFee -= fee;
        }
        if (performanceFee > 0) {
            uint256 fee = (amount * performanceFee) / ONE;
            afterFee -= fee;
            to.safeTransfer(treasury, fee);
        }

        to.approve(address(vault), afterFee);
        vault.distributeDividends(afterFee);

        emit Harvest(vault, amount, block.timestamp);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) {
            revert FireDAOTreasuryZeroAddress();
        }

        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }

    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        if (newPerformanceFee + fireBuyBack > ONE) {
            revert FireDAOFeesTooHigh();
        }

        emit PerformanceFeeUpdated(performanceFee, newPerformanceFee);
        performanceFee = newPerformanceFee;
    }

    function setFireBuyBack(uint256 newFireBuyBack) external onlyOwner {
        if (performanceFee + newFireBuyBack > ONE) {
            revert FireDAOFeesTooHigh();
        }

        emit FireBuyBackUpdated(fireBuyBack, newFireBuyBack);
        fireBuyBack = newFireBuyBack;
    }

    function salvage(IBEP20 token) external onlyOwner {
        token.safeTransfer(owner, token.balanceOf(address(this)));
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
import "./../libraries/SafeBEP20.sol";

interface IPancakeSwapRouter {
    function addLiquidity(
        IBEP20 tokenA,
        IBEP20 tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IBEP20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, IBEP20[] calldata path) external view returns (uint256[] memory amounts);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (IBEP20);
}

library PancakeSwap {
    using SafeBEP20 for IBEP20;

    IPancakeSwapRouter internal constant ROUTER = IPancakeSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uint256 internal constant SENSIBLE_DEFAULT_SLIPPAGE_TOLERANCE = 5e15; // 0.5 %
    uint256 internal constant SENSIBLE_DEFAULT_SWAP_DEADLINE = 20 minutes;
    uint256 private constant ONE = 100e16;

    function swap(
        IBEP20 from,
        IBEP20 to,
        uint256 amount,
        uint256 slippageTolerance,
        uint256 swapDeadline
    ) internal returns (uint256 swappedAmount) {
        from.approve(address(ROUTER), amount);

        (IBEP20[] memory path, uint256 estimatedSwapAmount) = estimateSwap(from, to, amount);
        uint256[] memory amounts = ROUTER.swapExactTokensForTokens(
            amount,
            (estimatedSwapAmount * (ONE - slippageTolerance)) / ONE,
            path,
            address(this),
            block.timestamp + swapDeadline
        );
        swappedAmount = amounts[amounts.length - 1];
    }

    function estimateSwap(
        IBEP20 from,
        IBEP20 to,
        uint256 amount
    ) internal view returns (IBEP20[] memory path, uint256 estimatedSwappedAmount) {
        IBEP20 wrappedBnb = ROUTER.WETH();

        bool isDirectSwap = (from == wrappedBnb || to == wrappedBnb);
        path = new IBEP20[](isDirectSwap ? 2 : 3);
        path[0] = from;
        path[path.length - 1] = to;
        if (!isDirectSwap) {
            path[1] = wrappedBnb;
        }

        uint256[] memory amounts = ROUTER.getAmountsOut(amount, path);
        estimatedSwappedAmount = amounts[amounts.length - 1];
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