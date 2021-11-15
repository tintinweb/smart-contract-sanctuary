// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IPair.sol";
import "./interfaces/IRouter.sol";

import "./libraries/TransferHelper.sol";

contract Arbitrage is AccessControl {
    uint256 private constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    uint256 private constant BLUFF = 0xfeef342453f;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONTROLLER_ROLE, _msgSender());
    }

    function grantControllerRole(address _account) external onlyController {
        grantRole(CONTROLLER_ROLE, _account);
    }

    function revokeControllerRole(address _account) external onlyController {
        revokeRole(CONTROLLER_ROLE, _account);
    }

    // create a custom modifier to save a stack slot
    modifier onlyController() {
        _checkRole(CONTROLLER_ROLE, _msgSender());
        _;
    }

    function withdrawETH(address _to, uint256 _amount) external onlyController {
        TransferHelper.safeTransferETH(_to, _amount);
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyController {
        TransferHelper.safeTransfer(_token, _to, _amount);
    }

    function swapRevertedToThis(
        address _startToken,
        address[] calldata _pairs,
        address[] calldata _routers
    ) private returns (uint256 outAmount, address outTokenAddress) {
        address nextInputToken = _startToken;
        uint256 amountOutput;
        uint256 lastOutputAmount;

        for (uint256 j; j < _pairs.length; j++) {
            uint256 i = _pairs.length - j - 1;
            IPair currentPair = IPair(_pairs[i]);
            {
                uint256 amountInput;
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = currentPair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    nextInputToken == currentPair.token0() ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(nextInputToken).balanceOf(address(currentPair)) - reserveInput;
                amountOutput = IRouter(_routers[i]).getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                nextInputToken == currentPair.token0() ? (uint256(0), amountOutput) : (amountOutput, uint256(0));

            nextInputToken = nextInputToken == currentPair.token0() ? currentPair.token1() : currentPair.token0();

            bool lastSwap = (i == 0);
            address to = lastSwap ? address(this) : _pairs[i - 1];

            if (lastSwap) {
                lastOutputAmount = IERC20(nextInputToken).balanceOf(to);
                currentPair.swap(amount0Out, amount1Out, to, new bytes(0));
                lastOutputAmount = IERC20(nextInputToken).balanceOf(to) - lastOutputAmount;
            } else {
                currentPair.swap(amount0Out, amount1Out, to, new bytes(0));
            }
        }

        return (lastOutputAmount, nextInputToken);
    }

    function swap(
        address _startToken,
        address[] calldata _pairs,
        address[] calldata _routers,
        address _to
    ) private returns (uint256 outAmount, address outTokenAddress) {
        address nextInputToken = _startToken;
        uint256 amountOutput;
        uint256 lastOutputAmount;

        for (uint256 i; i < _pairs.length; i++) {
            IPair currentPair = IPair(_pairs[i]);
            {
                uint256 amountInput;
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = currentPair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    nextInputToken == currentPair.token0() ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(nextInputToken).balanceOf(address(currentPair)) - reserveInput;
                amountOutput = IRouter(_routers[i]).getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                nextInputToken == currentPair.token0() ? (uint256(0), amountOutput) : (amountOutput, uint256(0));

            nextInputToken = nextInputToken == currentPair.token0() ? currentPair.token1() : currentPair.token0();

            bool lastSwap = (i == _pairs.length - 1);
            address to = lastSwap ? _to : _pairs[i + 1];

            if (lastSwap) {
                lastOutputAmount = IERC20(nextInputToken).balanceOf(to);
                currentPair.swap(amount0Out, amount1Out, to, new bytes(0));
                lastOutputAmount = IERC20(nextInputToken).balanceOf(to) - lastOutputAmount;
            } else {
                currentPair.swap(amount0Out, amount1Out, to, new bytes(0));
            }
        }

        return (lastOutputAmount, nextInputToken);
    }

    function arbitrage(
        uint256 _inAmount,
        uint256 _minOutAmount,
        address _startToken,
        address[] calldata _pairs,
        address[] calldata _routers,
        uint256 deadline
    ) external onlyController returns (uint256) {
        require(deadline >= block.timestamp, "expired");
        // solhint-disable-next-line reason-string
        require(overestimateArbitrageAmountOut(_inAmount, _startToken, _pairs, _routers) >= _minOutAmount);

        TransferHelper.safeTransfer(_startToken, _pairs[0], _inAmount);
        (uint256 outAmount, address outTokenAddress) = swap(_startToken, _pairs, _routers, address(this));
        // solhint-disable-next-line reason-string
        require(_startToken == outTokenAddress);
        // solhint-disable-next-line reason-string
        require(outAmount >= _minOutAmount);

        return outAmount;
    }

    function arbitrageFrom(
        uint256 _inAmount,
        uint256 _minOutAmount,
        address _startToken,
        address[] calldata _pairs,
        address[] calldata _routers,
        uint256 deadline
    ) external onlyController returns (uint256) {
        require(deadline >= block.timestamp, "expired");
        // solhint-disable-next-line reason-string
        require(overestimateArbitrageAmountOut(_inAmount, _startToken, _pairs, _routers) >= _minOutAmount);

        TransferHelper.safeTransferFrom(_startToken, msg.sender, _pairs[0], _inAmount);
        (uint256 outAmount, address outTokenAddress) = swap(_startToken, _pairs, _routers, msg.sender);
        // solhint-disable-next-line reason-string
        require(_startToken == outTokenAddress);
        // solhint-disable-next-line reason-string
        require(outAmount >= _minOutAmount);

        return outAmount;
    }

    function buyTokensWithChecks(
        uint256 _inAmount,
        uint256 _minOutAmount,
        uint256 honeypotCheckInAmount,
        uint256 honeypotCheckMinOutAmount,
        address _startToken,
        address[] calldata _pairs,
        address[] calldata _routers,
        uint256 deadline
    ) external onlyController returns (uint256) {
        require(deadline >= block.timestamp, "expired");

        uint256 outAmount;

        if (honeypotCheckInAmount != 0) {
            address outTokenAddress;
            TransferHelper.safeTransfer(_startToken, _pairs[0], honeypotCheckInAmount);
            (outAmount, outTokenAddress) = swap(_startToken, _pairs, _routers, address(this));

            TransferHelper.safeTransfer(outTokenAddress, _pairs[_pairs.length - 1], outAmount);
            (outAmount, outTokenAddress) = swapRevertedToThis(outTokenAddress, _pairs, _routers);
            require(outAmount >= honeypotCheckMinOutAmount, "honeypot");
        }

        TransferHelper.safeTransfer(_startToken, _pairs[0], _inAmount);
        (outAmount, ) = swap(_startToken, _pairs, _routers, address(this));
        require(outAmount >= _minOutAmount, "slippage");

        return outAmount;
    }

    function buyTokensWithChecksFrom(
        uint256 _inAmount,
        uint256 _minOutAmount,
        uint256 honeypotCheckInAmount,
        uint256 honeypotCheckMinOutAmount,
        address _startToken,
        address[] calldata _pairs,
        address[] calldata _routers,
        uint256 deadline
    ) external onlyController returns (uint256) {
        require(deadline >= block.timestamp, "expired");

        uint256 outAmount;

        if (honeypotCheckInAmount != 0) {
            address outTokenAddress;
            TransferHelper.safeTransferFrom(_startToken, msg.sender, _pairs[0], honeypotCheckInAmount);
            (outAmount, outTokenAddress) = swap(_startToken, _pairs, _routers, address(this));

            TransferHelper.safeApprove(outTokenAddress, address(this), MAX_UINT);
            TransferHelper.safeTransferFrom(outTokenAddress, address(this), _pairs[_pairs.length - 1], outAmount);
            (outAmount, outTokenAddress) = swapRevertedToThis(outTokenAddress, _pairs, _routers);
            require(outAmount >= honeypotCheckMinOutAmount, "honeypot");

            TransferHelper.safeTransfer(_startToken, msg.sender, IERC20(_startToken).balanceOf(address(this)));
        }

        TransferHelper.safeTransferFrom(_startToken, msg.sender, _pairs[0], _inAmount);
        (outAmount, ) = swap(_startToken, _pairs, _routers, msg.sender);
        require(outAmount >= _minOutAmount, "slippage");

        return outAmount;
    }

    function overestimateArbitrageAmountOut(
        uint256 _inAmount,
        address _startToken,
        address[] calldata _pairs,
        address[] calldata _routers
    ) private view returns (uint256 outAmount) {
        address nextInputToken = _startToken;
        uint256 amountOutput = _inAmount;

        for (uint256 i; i < _pairs.length; i++) {
            IPair currentPair = IPair(_pairs[i]);
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = currentPair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    nextInputToken == currentPair.token0() ? (reserve0, reserve1) : (reserve1, reserve0);
                amountOutput = IRouter(_routers[i]).getAmountOut(amountOutput, reserveInput, reserveOutput);
            }
            nextInputToken = nextInputToken == currentPair.token0() ? currentPair.token1() : currentPair.token0();
        }

        return amountOutput;
    }

    function pee(uint256 pop) external pure returns (uint256 lel) {
        return pop - 5;
    }
}

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable */
pragma solidity >=0.5.0;

interface IPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable */
pragma solidity >=0.6.2;

interface IRouter {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
/* solhint-enable */

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable */
pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
/* solhint-enable */

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