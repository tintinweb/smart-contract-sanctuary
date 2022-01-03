/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File contracts/CaptchaLimited.sol

pragma solidity 0.8.9;

/**
 * CaptchaLimited Error Codes:
 * - CLE1: Caller is not verified.
 * - CLE2: Address whitelist status is already set as passed vaule.
 * - CLE3: Captcha requirement already set as passed vaule.
 */
contract CaptchaLimited is AccessControl {
    bytes32 public constant CAPTCHA_LIMITED_ADMIN_ROLE = keccak256("CAPTCHA_LIMITED_ADMIN_ROLE");
    bytes32 public constant CAPTCHA_VERIFIER_ROLE = keccak256("CAPTCHA_VERIFIER_ROLE");

    mapping(address => bool) public isCaptchaVerified;
    mapping(address => bool) public isWhitlisted;
    mapping(address => uint256) public accountsNonce;
    bool public isCaptchaRequiered;

    /**
     * @dev Emitted when an address is set as captcha verified.
     */
    event PassedCaptchaVerification(address indexed _captchaVerifiedAddress);

    /**
     * @dev Emitted when an address has used its captcha verification.
     */
    event ExpiredCaptchaVerification(address indexed _captchaVerifiedAddress);

    /**
     * @dev Emitted when the whitelist status of an address is toggled.
     */
    event WhitelistStatusChanged(address indexed _whitlistAddress, bool indexed _isWhitelisted);

    /**
     * @dev Emitted when the captcha requirement is toggled.
     */
    event CaptchaRequiredChanged(bool indexed _isCaptchaRequiered);

    /**
     * @dev Throws if called by an account that is not verified by captcha (while captcha is reequired)
     *      and is not whitelisted.
     */
    modifier onlyCaptchaVerified(address _address) {
        require(
            !isCaptchaRequiered || 
            isCaptchaVerified[_address] || 
            isWhitlisted[_address], 
            "CaptchaLimited: CLE1"
        );
        if (isCaptchaRequiered && !isWhitlisted[_address]) {
            isCaptchaVerified[_address] = false;
            emit ExpiredCaptchaVerification(_address);
        }
        _;
    }

    constructor(address _captchaVerifier) {
        _setRoleAdmin(CAPTCHA_LIMITED_ADMIN_ROLE, CAPTCHA_LIMITED_ADMIN_ROLE);
        _setRoleAdmin(CAPTCHA_VERIFIER_ROLE, CAPTCHA_LIMITED_ADMIN_ROLE);

        // by default the deployer is admin
        _setupRole(CAPTCHA_LIMITED_ADMIN_ROLE, msg.sender);

        // setup captcha verifier role
        _setupRole(CAPTCHA_VERIFIER_ROLE, _captchaVerifier);
    }


    /**
     * @dev Set the captcha verification status of an address. 
     * Whitelisted addressed do not require passing the Captcha check.
     *
     * Emits a {PassedCaptchaVerification} event.
     *
     * Requirements:
     *
     * - the caller must have the 'Captcha Verifier' role.
     */
    function captchaVerified(address _captchaVerifiedAddress) external onlyRole(CAPTCHA_VERIFIER_ROLE) {
        isCaptchaVerified[_captchaVerifiedAddress] = true;
        emit PassedCaptchaVerification(_captchaVerifiedAddress);
    }

    /**
     * @dev Set the captcha verification status of an address,
     * approved by a signature from an account with the 'Captcha Verifier' role.
     * Whitelisted addressed do not require passing the Captcha check.
     *
     * Emits a {PassedCaptchaVerification} event.
     *
     * Requirements:
     *
     * - Signature must be valid, commiting to the account that passed the captcha
     *   and its nonce and come from an account with the 'Captcha Verifier' role.
     * - Nonce must match the current nonce of the account from the accountsNonce mapping.
     */
    function captchaVerifiedBySig(uint256 _nonce, address _account, bytes memory sig) external {
        require(isValidCaptchaSigData(_nonce, _account, sig), "CaptchaLimited: CLEX");
        accountsNonce[_account] += 1;
        isCaptchaVerified[_account] = true;
        emit PassedCaptchaVerification(_account);
    }

    /**
     * @dev Set the whitelist status of an address. 
     * Whitelisted addressed do not require passing the Captcha check.
     *
     * Emits a {WhitelistStatusChanged} event.
     *
     * Requirements:
     *
     * - the caller must have the 'Captcha Limited Admin' role.
     */
    function setIsWhitelisted(address _whitlistAddress, bool _isWhitelisted) external onlyRole(CAPTCHA_LIMITED_ADMIN_ROLE) {
        require(isWhitlisted[_whitlistAddress] != _isWhitelisted, "CaptchaLimited: CLE3");
        isWhitlisted[_whitlistAddress] = _isWhitelisted;
        emit WhitelistStatusChanged(_whitlistAddress, _isWhitelisted);
    }

    /**
     * @dev Sets whetever the captcha check is active or not. 
     * If the captcha chekc is inactive, the onlyVeirfied modifier will always pass.
     *
     * Emits a {CaptchaRequiredChanged} event.
     *
     * Requirements:
     *
     * - the caller must have the 'Captcha Limited Admin' role.
     */
    function setCaptchaRequired(bool _isCaptchaRequiered) external onlyRole(CAPTCHA_LIMITED_ADMIN_ROLE) {
        require(isCaptchaRequiered != _isCaptchaRequiered, "CaptchaLimited: CLE4");
        isCaptchaRequiered = _isCaptchaRequiered;
        emit CaptchaRequiredChanged(_isCaptchaRequiered);
    }

    function isValidCaptchaSigData(uint256 _nonce, address _account, bytes memory sig) public view returns(bool) {
        bytes32 message = keccak256(abi.encodePacked(address(this), _nonce, _account));
        _checkRole(CAPTCHA_VERIFIER_ROLE, recoverSigner(message, sig));
        require(_nonce == accountsNonce[_account], "CaptchaLimited: CLEX");
        return true;
    }

    function recoverSigner(bytes32 message, bytes memory sig) public pure returns(address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns(uint8, bytes32, bytes32) {
        require(sig.length == 65, "CaptchaLimited: CLEX");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }
}


// File contracts/interfaces/IPancakeRouter01.sol

pragma solidity 0.8.9;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    // solhint-disable-next-line func-name-mixedcase
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


// File contracts/interfaces/IPancakeRouter02.sol

pragma solidity 0.8.9;

interface IPancakeRouter02 is IPancakeRouter01 {
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


// File @uniswap/lib/contracts/libraries/[email protected]

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File contracts/CaptchaLimitedRouter.sol

pragma solidity 0.8.9;



// /**
//  * CaptchaLimitedRouter Error Codes:
//  * - CLRE1: Fee must be lower than 100%.
//  */
contract CaptchaLimitedRouter is CaptchaLimited {
    uint256 constant public FEE_PRECISION = 10000;

    IPancakeRouter02 public immutable router;
    // TODO: Make settable by owner
    address public feesCollector;
    uint256 public feeBp;

    constructor(IPancakeRouter02 _router, address _feesCollector, uint256 _feeBp, address _captchaVerifier) CaptchaLimited(_captchaVerifier) {
        require(feeBp < FEE_PRECISION, "CaptchaLimitedRouter: CLRE1");
        router = _router;
        feesCollector = _feesCollector;
        feeBp = _feeBp;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyCaptchaVerified(msg.sender) returns (uint[] memory amounts) {
        prepareTokensForSwap(path[0], amountIn);
        uint256 fee = amountIn * feeBp / FEE_PRECISION;
        TransferHelper.safeTransfer(path[0], feesCollector, fee);
        amounts = router.swapExactTokensForTokens(amountIn - fee, amountOutMin, path, to, deadline);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyCaptchaVerified(msg.sender) returns (uint[] memory amounts) {
        prepareTokensForSwap(path[0], amountInMax);
        uint256 fee = amountInMax * feeBp / FEE_PRECISION;
        TransferHelper.safeTransfer(path[0], feesCollector, fee);
        uint256 amountAfterFee = amountInMax - fee;
        amounts = router.swapTokensForExactTokens(amountOut, amountAfterFee, path, to, deadline);
        if (amountAfterFee > amounts[0]) {
            TransferHelper.safeTransfer(path[0], msg.sender, amountAfterFee - amounts[0]);
        }
        
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable onlyCaptchaVerified(msg.sender) returns (uint[] memory amounts) {
        uint256 fee = msg.value * feeBp / FEE_PRECISION;
        amounts = router.swapExactETHForTokens{value:msg.value - fee}(amountOutMin, path, to, deadline);
        TransferHelper.safeTransferETH(feesCollector, fee);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyCaptchaVerified(msg.sender) returns (uint[] memory amounts) {
        prepareTokensForSwap(path[0], amountInMax);
        uint256 fee = amountInMax * feeBp / FEE_PRECISION;
        TransferHelper.safeTransfer(path[0], feesCollector, fee);
        uint256 amountAfterFee = amountInMax - fee;
        amounts = router.swapTokensForExactETH(amountOut, amountAfterFee, path, to, deadline);
        if (amountAfterFee > amounts[0]) {
            TransferHelper.safeTransfer(path[0], msg.sender, amountAfterFee - amounts[0]);
        }
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyCaptchaVerified(msg.sender) returns (uint[] memory amounts) {
        prepareTokensForSwap(path[0], amountIn);
        uint256 fee = amountIn * feeBp / FEE_PRECISION;
        TransferHelper.safeTransfer(path[0], feesCollector, fee);
        amounts = router.swapExactTokensForETH(amountIn - fee, amountOutMin, path, to, deadline);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyCaptchaVerified(msg.sender) payable returns (uint[] memory amounts) {
        uint256 fee = msg.value * feeBp / FEE_PRECISION;
        amounts = router.swapETHForExactTokens{value:msg.value - fee}(amountOut, path, to, deadline);
        TransferHelper.safeTransferETH(feesCollector, fee);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyCaptchaVerified(msg.sender) {
        prepareTokensForSwap(path[0], amountIn);
        uint256 fee = amountIn * feeBp / FEE_PRECISION;
        TransferHelper.safeTransfer(path[0], feesCollector, fee);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn - fee, amountOutMin, path, to, deadline);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable onlyCaptchaVerified(msg.sender) {
        uint256 fee = msg.value * feeBp / FEE_PRECISION;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value - fee}(amountOutMin, path, to, deadline);
        TransferHelper.safeTransferETH(feesCollector, fee);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyCaptchaVerified(msg.sender) {
        prepareTokensForSwap(path[0], amountIn);
        uint256 fee = amountIn * feeBp / FEE_PRECISION;
        TransferHelper.safeTransfer(path[0], feesCollector, fee);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn - fee, amountOutMin, path, to, deadline);
    }

    function prepareTokensForSwap(address token, uint amountIn) internal {
        TransferHelper.safeTransferFrom(
            token, msg.sender, address(this), amountIn
        );
        TransferHelper.safeApprove(
            token, address(router), amountIn
        );
    }
}