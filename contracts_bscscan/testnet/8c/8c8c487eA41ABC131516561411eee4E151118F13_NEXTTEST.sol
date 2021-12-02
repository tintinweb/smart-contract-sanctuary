/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: UNLICENSED




// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol



pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol



pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol




pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol



pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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

// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/access/IAccessControl.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


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
    constructor() {
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

// File: @openzeppelin/contracts/access/AccessControl.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;




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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}





//
// $TetraPro proposes an innovative feature in its contract.
//
// DIVIDEND YIELD PAID IN BSW! With the auto-claim feature,
// simply hold$TetraPro and you'll receive BSW automatically in your wallet.
// 
// Hold TetraPro and get rewarded in BSW on every transaction!
//
//
// 📱 Telegram: https://t.me/tetraprotocol
//

pragma solidity ^0.8.0;








contract NEXTTEST is ERC20, AccessControl/*, Pausable*/ {
    // CONFIG START

    uint256 public denominator = 10000;
    
    // TOKEN
    string tokenName = "NEXT14";
    string tokenSymbol = "NEXT14";
    uint256 tokenTotalSupply = 100_000_000 * (10**18);
    
    // ADRESSES
    address devWallet_a;
    address devWallet_b;
    address devWallet_c;
    address devWallet_d;
    address devWallet_e;
    address devWallet_f;
    
    address devOwnerWallet_a;
    address devOwnerWallet_b;
    
    address marketingWallet;
    address buybackWallet;
    
    address router02 = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //testnet
    //address router02 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address owner;

    // TAXes
    uint256 public devTaxBuy        = 300;
    uint256 public devTaxSell       = 300;
    uint256 public ownerDevTaxBuy   = 300;
    uint256 public ownerDevTaxSell  = 300;
    uint256 public marketingTaxBuy  = 400;
    uint256 public marketingTaxSell = 400;
    uint256 public buybackTaxBuy    = 200;
    uint256 public buybackTaxSell   = 200;


    // LIMITS
    uint256 public maxSellTxAmount = 1_000_000 * 10**18 + 1;
    uint256 public maxBuyTxAmount  = 1_000_000 * 10**18 + 1;
    uint256 public maxWalletAmount = 1_000_000 * 10**18 + 1;

    // SWITCH
    bool public exchange = false;

    // CONFIG END

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    
    IUniswapV2Router02 private _UniswapV2Router02;
    IUniswapV2Factory private _UniswapV2Factory;
    IUniswapV2Pair private _UniswapV2Pair;
    
    mapping (address => uint256) private nextBuyBlock;
    
    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isExcludedFromBotProtection;
    //mapping (address => uint256) public balanceOf;

    // Whitelist
    bool public whitelistStatus;
    mapping (address => bool) public isWhitelisted;

    // Blacklist
    bool public blacklistStatus;
    mapping (address => bool) public isBlacklisted;
    
    uint256 private feeTokens;

    uint256 private devTokens;
    uint256 private ownerDevTokens;
    uint256 private marketingTokens;
    uint256 private buybackTokens;

    bool public taxStatus;
    bool public BPStatus;
    bool public buyBackBNB;
    
    using Address for address;

    uint256 totalHolded;

    event LogNum(string, uint256);
    event LogBool(string, bool);
    event LogAddress(string, address);
    event LogString(string, string);
    event LogBytes(string, bytes);
    
    constructor(address _owner, address payable _devWallet_a, address payable _devWallet_b, address payable _devWallet_c, address payable _devWallet_d, address payable _devWallet_e,
                address payable _devWallet_f, address payable _devOwnerWallet_a, address payable _devOwnerWallet_b, address payable _marketingWallet, address payable _buybackWallet) ERC20(tokenName, tokenSymbol) {
        
        owner = _owner;
        
        devWallet_a = _devWallet_a;
        devWallet_b = _devWallet_b;
        devWallet_c = _devWallet_c;
        devWallet_d = _devWallet_d;
        devWallet_e = _devWallet_e;
        devWallet_f = _devWallet_f;        
        devOwnerWallet_a  = _devOwnerWallet_a;
        devOwnerWallet_b  = _devOwnerWallet_b;
        marketingWallet = _marketingWallet;
        buybackWallet   = _buybackWallet;
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, owner);

        _UniswapV2Router02 = IUniswapV2Router02(router02);
        _UniswapV2Factory = IUniswapV2Factory(_UniswapV2Router02.factory());
        _UniswapV2Pair = IUniswapV2Pair(_UniswapV2Factory.createPair(address(this), _UniswapV2Router02.WETH()));
        
        isExcluded[msg.sender] = true;
        isExcluded[address(this)] = true;
        isExcluded[devWallet_a] = true;
        isExcluded[devWallet_b] = true;
        isExcluded[devWallet_c] = true;
        isExcluded[devWallet_d] = true;
        isExcluded[devWallet_e] = true;
        isExcluded[devWallet_f] = true;
        isExcluded[devOwnerWallet_a]  = true;
        isExcluded[devOwnerWallet_b]  = true;
        isExcluded[marketingWallet] = true;
        isExcluded[buybackWallet]   = true;
        
        isExcludedFromBotProtection[address(_UniswapV2Pair)] = true;

        taxStatus = true;
        BPStatus = true;
        buyBackBNB = true;
        
        _mint(owner, tokenTotalSupply);
    }

    bool inTax;
    
    function transferTokens(address tokenAddress, address to, uint256 value) internal {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= value, "HFT: Insufficient token balance");

        try IERC20(tokenAddress).transfer(to, value) {} catch {
            revert("HFT: Transfer failed");
        }
    }
    
    
    function handleFees(address sender, address recipient, uint256 amount) internal returns (uint256 fee) {
        bool isBuy = sender == address(_UniswapV2Pair);
        bool isSell = recipient == address(_UniswapV2Pair);

        uint256 fees;
        uint256 taxSum;

        uint256 distributeFees;
        uint256 devidedOwnerFees;
        
        uint256 devAmount       = 0;
        uint256 ownerDevAmount  = 0;
        uint256 marketingAmount = 0;
        uint256 buybackAmount   = 0;



        if(isBuy) {
            require(amount <= maxBuyTxAmount, "HFT: Max buy tx amount");
            if ((devTaxBuy + ownerDevTaxBuy + marketingTaxBuy + buybackTaxBuy) == 0){
                fees = 0;
            } else {
                fees = amount * 10**18 / denominator * (devTaxBuy + ownerDevTaxBuy + marketingTaxBuy + buybackTaxBuy) / 10**18;
    
                taxSum = devTaxBuy + ownerDevTaxBuy + marketingTaxBuy + buybackTaxBuy;
    
                if (devTaxBuy != 0) devAmount = fees * 10**18 / taxSum * devTaxBuy / 10**18;
                else devAmount = 0;
                
                if (ownerDevTaxBuy != 0) ownerDevAmount = fees * 10**18 / taxSum * ownerDevTaxBuy / 10**18;
                else ownerDevAmount = 0;
                
                if (marketingTaxBuy != 0) marketingAmount = fees * 10**18 / taxSum * marketingTaxBuy / 10**18;
                else marketingAmount = 0;
                
                if (buybackTaxBuy != 0) buybackAmount = fees * 10**18 / taxSum * buybackTaxBuy / 10**18;
                else buybackAmount = 0;
    
                feeTokens += fees;
    
                devTokens += devAmount;
                ownerDevTokens += ownerDevAmount;
                marketingTokens += marketingAmount;
                buybackTokens += buybackAmount;
        
                super._transfer(sender, address(this), fees);
            }
        } else if(isSell) {
            require(amount <= maxSellTxAmount, "HFT: Max sell tx amount");
            if ((devTaxSell + ownerDevTaxSell + marketingTaxSell + buybackTaxSell) == 0) {
                fees = 0;
            } else {
            fees = amount * 10**18 / denominator * (devTaxSell + ownerDevTaxSell + marketingTaxSell + buybackTaxSell) / 10**18;

            taxSum = devTaxSell + ownerDevTaxSell + marketingTaxSell + buybackTaxSell;

            if (devTaxSell != 0) devAmount = fees * 10**18 / taxSum * devTaxSell / 10**18;
            else devAmount = 0;
                
            if (ownerDevTaxSell != 0) ownerDevAmount = fees * 10**18 / taxSum * ownerDevTaxSell / 10**18;
            else ownerDevAmount = 0;
                
            if (marketingTaxSell != 0) marketingAmount = fees * 10**18 / taxSum * marketingTaxSell / 10**18;
            else marketingAmount = 0;
                
            if (buybackTaxSell != 0) buybackAmount = fees * 10**18 / taxSum * buybackTaxSell / 10**18;
            else buybackAmount = 0;

            feeTokens += fees;

            devTokens += devAmount;
            ownerDevTokens += ownerDevAmount;
            marketingTokens += marketingAmount;
            buybackTokens += buybackAmount;

            super._transfer(sender, address(this), fees);
            
        
       
            if(feeTokens > 0 && exchange == true) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _UniswapV2Router02.WETH();
                
                uint256 startBalance = address(this).balance;
                
                //feeTokens = feeTokens - buybackTokens;
                
                _approve(address(this), address(_UniswapV2Router02), feeTokens);

                inTax = true;
                
                _UniswapV2Router02.swapExactTokensForETH(
                    feeTokens,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                
                uint256 ethGained = address(this).balance - startBalance;
                
                distributeFees = devTokens / 6;
                
                devidedOwnerFees = ownerDevTokens / 2;

                Address.sendValue(payable(devWallet_a), distributeFees * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(devWallet_b), distributeFees * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(devWallet_c), distributeFees * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(devWallet_d), distributeFees * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(devWallet_e), distributeFees * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(devWallet_f), distributeFees * 10**18 / feeTokens * ethGained / 10**18);

                
                Address.sendValue(payable(devOwnerWallet_a ), devidedOwnerFees  * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(devOwnerWallet_b ), devidedOwnerFees  * 10**18 / feeTokens * ethGained / 10**18);

                Address.sendValue(payable(marketingWallet), marketingTokens * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(buybackWallet), buybackTokens * 10**18 / feeTokens * ethGained / 10**18);

                inTax = false;

                devTokens        = 0;
                ownerDevTokens   = 0;
                marketingTokens  = 0;
                buybackTokens    = 0;
                distributeFees   = 0;
                feeTokens        = 0;

            } else if (feeTokens > 0 && exchange == false) {
                
                _approve(address(this), address(_UniswapV2Router02), feeTokens);

                inTax = true;
                
                distributeFees = devTokens / 6;

                devidedOwnerFees = ownerDevTokens / 2;

                super._transfer(address(this), devWallet_a, distributeFees);
                super._transfer(address(this), devWallet_b, distributeFees);
                super._transfer(address(this), devWallet_c, distributeFees);
                super._transfer(address(this), devWallet_d, distributeFees);
                super._transfer(address(this), devWallet_e, distributeFees);
                super._transfer(address(this), devWallet_f, distributeFees);
                
                super._transfer(address(this), devOwnerWallet_a, devidedOwnerFees);
                super._transfer(address(this), devOwnerWallet_b, devidedOwnerFees);

                super._transfer(address(this), marketingWallet, marketingTokens);
                

                if (buyBackBNB == true) {
                        address[] memory path = new address[](2);
                        path[0] = address(this);
                        path[1] = _UniswapV2Router02.WETH();
                
                        uint256 startBalance = address(this).balance;
                
                        _approve(address(this), address(_UniswapV2Router02), buybackTokens);

                        inTax = true;
                
                        _UniswapV2Router02.swapExactTokensForETH(
                            buybackTokens,
                            0,
                            path,
                            address(this),
                            block.timestamp
                        );
                
                        uint256 ethGainedBuyBack = address(this).balance - startBalance;
                        Address.sendValue(payable(buybackWallet), ethGainedBuyBack);

                } else {
                        super._transfer(address(this), buybackWallet, buybackTokens);    
                }


                inTax = false;

                devTokens       = 0;
                ownerDevTokens  = 0;
                marketingTokens = 0;
                buybackTokens   = 0;
                distributeFees  = 0;
                feeTokens       = 0;
                
            }
          }
        }

        return fees;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        if(isExcluded[msg.sender] || inTax) { //|| isExcluded[tx.origin] removed
            super._transfer(sender, recipient, amount);
        } else {
            if(!isExcluded[sender] && !isExcluded[recipient]) {
                require(isExcluded[recipient] || recipient == address(_UniswapV2Pair)|| balanceOf(recipient) + amount <= maxWalletAmount, "HFT: Max wallet amount");
                require(!blacklistStatus || (!isBlacklisted[sender] && !isBlacklisted[recipient]), "HFT: Blacklisted");
                require(!whitelistStatus || (isWhitelisted[sender] && isWhitelisted[recipient]), "HFT: Not Whitelisted");

                if(sender == address(_UniswapV2Pair) || recipient == address(_UniswapV2Pair)) {
                    if(sender == address(_UniswapV2Pair)) {
                        require(block.number >= nextBuyBlock[recipient], "HFT: Cooldown");

                        nextBuyBlock[recipient] = block.number + 1;
                    }


                    if(taxStatus) {
                        uint256 fees = handleFees(sender, recipient, amount);
                        amount -= fees; 
                    }            
                }
            }

            if(BPStatus) {
                if(sender == address(_UniswapV2Pair) && !isExcludedFromBotProtection[recipient]) {
                    require(!recipient.isContract(), "HFT: Bot Protection");
                } else if(recipient == address(_UniswapV2Pair) && !isExcludedFromBotProtection[sender]) {
                    require(!sender.isContract(), "HFT: Bot Protection");
                }
            }

            super._transfer(sender, recipient, amount);
        }
    }


    /**
     * General settings
     */


    function setDenominator(uint256 newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != denominator, "HFT: Value already set to that option");

        denominator = newValue;
    }

    function setMaxBuyTxAmount(uint256 newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != maxBuyTxAmount, "HFT: Value already set to that option");

        maxBuyTxAmount = newValue;
    }
    
    
    function setMaxSellTxAmount(uint256 newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != maxSellTxAmount, "HFT: Value already set to that option");

        maxSellTxAmount = newValue;
    }

    function setMaxWalletAmount(uint256 newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != maxWalletAmount, "HFT: Value already set to that option");

        maxWalletAmount = newValue;
    }

    function setOwner(address newOwner) external onlyRole(OWNER_ROLE) {
        owner = newOwner;
    }
    
    function setDevWalletAddress(address payable _devWallet_a, address payable _devWallet_b, address payable _devWallet_c, address payable _devWallet_d, 
                                 address payable _devWallet_e, address payable _devWallet_f) external onlyRole(OWNER_ROLE) {
        devWallet_a = _devWallet_a;
        devWallet_b = _devWallet_b;
        devWallet_c = _devWallet_c;
        devWallet_d = _devWallet_d;
        devWallet_e = _devWallet_e;
        devWallet_f = _devWallet_f;        
    }


    function setOwnerDevWalletAddress(address payable _devOwnerWallet_a, address payable _devOwnerWallet_b) external onlyRole(OWNER_ROLE) {
        devOwnerWallet_a = _devOwnerWallet_a;
        devOwnerWallet_b = _devOwnerWallet_b;
    }


    function setMarketingWalletAddress(address payable _marketingWallet) external onlyRole(OWNER_ROLE) {
        marketingWallet = _marketingWallet;
    }

    function setBuybackWalletAddress(address payable _buybackWallet) external onlyRole(OWNER_ROLE) {
        buybackWallet = _buybackWallet;
    }

    function setExchange(bool newValue) external onlyRole(OWNER_ROLE) {
        require(exchange != newValue, "HFT: Value already set to that option");

        exchange = newValue;
    }


    /**
     * Exclude
     */

    function setExcluded(address account, bool newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != isExcluded[account], "HFT: Value already set to that option");

        isExcluded[account] = newValue;
    }

    function setExcludedFromBotProtection(address account, bool newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != isExcludedFromBotProtection[account], "HFT: Value already set to that option");

        isExcludedFromBotProtection[account] = newValue;
    }

    function massSetExcluded(address[] memory accounts, bool newValue) external onlyRole(OWNER_ROLE) {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isExcluded[accounts[i]], "HFT: Value already set to that option");

            isExcluded[accounts[i]] = newValue;
        }
    }

    function massSetExcludedFromBotProtection(address[] memory accounts, bool newValue) external onlyRole(OWNER_ROLE) {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isExcludedFromBotProtection[accounts[i]], "HFT: Value already set to that option");

            isExcludedFromBotProtection[accounts[i]] = newValue;
        }
    }



    /**
     * Blacklist & whitelist
     */

    function setBlacklistStatus(bool newValue) external onlyRole(OWNER_ROLE) {
        require(blacklistStatus != newValue, "HFT: Value already set to that option");

        blacklistStatus = newValue;
    }

    function setWhitelistStatus(bool newValue) external onlyRole(OWNER_ROLE) {
        require(whitelistStatus != newValue, "HFT: Value already set to that option");

        whitelistStatus = newValue;
    }

    function setBlacklisted(address account, bool newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != isBlacklisted[account], "HFT: Value already set to that option");

        isBlacklisted[account] = newValue;
    }

    function setWhitelisted(address account, bool newValue) external onlyRole(OWNER_ROLE) {
        require(newValue != isWhitelisted[account], "HFT: Value already set to that option");

        isWhitelisted[account] = newValue;
    }

    function massSetBlacklisted(address[] memory accounts, bool newValue) external onlyRole(OWNER_ROLE) {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isBlacklisted[accounts[i]], "HFT: Value already set to that option");

            isBlacklisted[accounts[i]] = newValue;
        }
    }

    function massSetWhitelisted(address[] memory accounts, bool newValue) external onlyRole(OWNER_ROLE) {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isWhitelisted[accounts[i]], "HFT: Value already set to that option");

            isWhitelisted[accounts[i]] = newValue;
        }
    }



    /**
     * Taxes
     */



    function setDevTaxBuy(uint256 newTax) external onlyRole(OWNER_ROLE) {
        devTaxBuy = newTax;
    }

    function setDevTaxSell(uint256 newTax) external onlyRole(OWNER_ROLE) {
        devTaxSell = newTax;
    }

    function setOwnerDevTaxBuy(uint256 newTax) external onlyRole(OWNER_ROLE) {
        ownerDevTaxBuy = newTax;
    }

    function setOwnerDevTaxSell(uint256 newTax) external onlyRole(OWNER_ROLE) {
        ownerDevTaxSell = newTax;
    }

    function setMarketingTaxBuy(uint256 newTax) external onlyRole(OWNER_ROLE) {
        marketingTaxBuy = newTax;
    }

    function setMarketingTaxSell(uint256 newTax) external onlyRole(OWNER_ROLE) {
        marketingTaxSell = newTax;
    }

    function setBuybackTaxBuy(uint256 newTax) external onlyRole(OWNER_ROLE) {
        buybackTaxBuy = newTax;
    }

    function setBuybackTaxSell(uint256 newTax) external onlyRole(OWNER_ROLE) {
        buybackTaxSell = newTax;
    }

    function setBuyBackBNB(bool newValue) external onlyRole(OWNER_ROLE) {
        require(buyBackBNB != newValue, "HFT: Value already set to that option");

        buyBackBNB = newValue;
    }

    function setTaxStatus(bool newValue) external onlyRole(OWNER_ROLE) {
        require(taxStatus != newValue, "HFT: Value already set to that option");

        taxStatus = newValue;
    }

    function setBotProtectionStatus(bool newValue) external onlyRole(OWNER_ROLE) {
        require(BPStatus != newValue, "HFT: Value already set to that option");

        BPStatus = newValue;
    }

    function withdrawETH(address to, uint256 value) external onlyRole(OWNER_ROLE) {
        require(address(this).balance >= value, "HFT: Insufficient ETH balance");

        (bool success,) = to.call{value: value}("");
        require(success, "HFT: Transfer failed");
    }

    function withdrawTokens(address tokenAddress, address to, uint256 value) external onlyRole(OWNER_ROLE) {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= value, "HFT: Insufficient token balance");

        try IERC20(tokenAddress).transfer(to, value) {} catch {
            revert("HFT: Transfer failed");
        }
    }
    
    receive() external payable {}
}