/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
// Version: 1.0.0
pragma solidity 0.8.10;

// Version: 1.0.0

// Version: 1.0.0

// Version: 1.0.0

interface I_With_DAORole{
    /**
     * DAO_ROLE is able to grant and revoke roles. It can be used when the DAO
     * vote to change some contracts of Windmill.
     */
    function DAO_ROLE() external view returns (bytes32);
}// Version: 1.0.0

abstract contract Base{
}





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

abstract contract With_DAORole is Base, AccessControl, I_With_DAORole{
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    constructor(){
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);
        _setupRole(DAO_ROLE, msg.sender);
    }
}
// Version: 1.0.0



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

// Version: 1.0.0



interface I_With_FundContract is IAccessControl, I_With_DAORole{
    function setFund(address _fund) external;
}// Version: 1.0.0

interface I_Math{
    struct Fraction{
        uint256 numerator;
        uint256 denominator;
    }
}

/**
 * @notice Windmill_Power is the ERC20 token (PWR) representing
 * a share of the fund in the Windmill_Fund contract.
 *
 * There is a primary market that value PWR in the form of
 * mint and burn by the Windmill_Fund contract.
 * In exchange of depositing or withdrawing BUSD from the fund,
 * PWR token are minted to or burned from the user address.
 * The minting/burning value of PWR only depends on the total supply
 * in BUSD in the fund related to the total supply of PWR.
 * This mean that PWR will gain primary value only via
 * Windmill traders performance
 *
 * Also, as PWR is an ERC20 token, it can be freely traded, so secondary
 * markets can exist.
 */
interface I_Windmill_Power is I_Math, IAccessControl, I_With_DAORole, IERC20, I_With_FundContract{
    /**
     * MINTER_ROLE is able to mint PWR to an address.
     *
     * BURNER_ROLE is able to burn PWR from an address.
     *
     * MOVER_ROLE is able to transfer PWR from an address to another.
     */
    function MINTER_ROLE() external view returns (bytes32);
    function BURNER_ROLE() external view returns (bytes32);
    function MOVER_ROLE() external view returns (bytes32);
    
    /**
     * @notice Allow the Windmill_Fund to mint PWR for an address

     * Windmill_Fund can use this method to buy PWR in exchange of BUSD
     * This do not change the PWR price because there is the corresponding amount of BUSD
     * that have been added to the fund.
     *
     * Windmill_Competition, Windmill_stacking and Windmill_Royalties can alsoo mint PWR
     * for their usage (competition and stacking reward, royalties).
     * These minting will decrease the value of PWR from the Windmill_Fund contract.
     */
    function mintTo(address to, uint256 amount) external;

    /**
     * @notice Allow the Windmill_Fund to burn PWR from an address
     * in exchange of withdrawing BUSD from the fund to the address.

     * When Windmill_Fund use this method, this do not change the PWR price
     * because there is the right amount of BUSD that have been removed
     * from the fund.
     */
    function burnFrom(address from, uint256 amount) external;

    /**
     * @notice Allow the Windmill_Fund to transfert PWR from an address
     * to a trade contract

     * Windmill_Stacking and Windmill_Trade_Manager use this method to lock the PWR from
     * direct withdraw. There is two main reason for this to happen :
     *
     * - PWR are locked from user to Windmill_Trade contract by Windmill_Trade_Manager
     * contract when starting a new trade. The corresponding BUSD from Windmill_Fund are also
     * allocated to the trade. These locked PWR are returned at the end of the trade.
     *
     * - PWR are stacked by the user in Windmill_Stacking. These PWR are returned
     * at the end of the stacking period. Note that returned PWR can be still
     * locked in a trade, that will be returned at the end of trade.
     */
    function transferFromTo(address from, address to, uint256 amount) external;
}// Version: 1.0.0



interface I_With_PWRToken is IAccessControl, I_With_DAORole{
    function setPWRToken(I_Windmill_Power token) external;
}

abstract contract With_PWRToken is Base, AccessControl, With_DAORole, I_With_PWRToken{
    I_Windmill_Power public PWRToken;

    function setPWRToken(I_Windmill_Power token) external onlyRole(DAO_ROLE){
        PWRToken = token;
    }
}// Version: 1.0.0


// Version: 1.0.0



interface I_With_BUSDToken is IAccessControl, I_With_DAORole{
    function setBUSDToken(IERC20 token) external;
}

abstract contract With_BUSDToken is Base, AccessControl, With_DAORole, I_With_BUSDToken{
    IERC20 public BUSDToken;

    function setBUSDToken(IERC20 token) external onlyRole(DAO_ROLE){
        BUSDToken = token;
    }
}// Version: 1.0.0


// Version: 1.0.0





/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

interface I_With_WBNBToken is IAccessControl, I_With_DAORole{
    function setWBNBToken(IERC20 token) external;
}

abstract contract With_WBNBToken is Base, AccessControl, With_DAORole, I_With_WBNBToken{
    IERC20 public WBNBToken;

    function setWBNBToken(IERC20 token) external onlyRole(DAO_ROLE){
        WBNBToken = token;
    }
}// Version: 1.0.0


// Version: 1.0.0


interface I_With_TradeManagerRole is I_With_DAORole{
    /**
     * UPDATER_ROLE is able to update contracts.
     */
    function TRADE_MANAGER_ROLE() external view returns (bytes32);
}

abstract contract With_TradeManagerRole is Base, AccessControl, With_DAORole, I_With_TradeManagerRole{
    bytes32 public constant TRADE_MANAGER_ROLE = keccak256("TRADE_MANAGER_ROLE");

    constructor(){
        _setRoleAdmin(TRADE_MANAGER_ROLE, DAO_ROLE);
    }
}// Version: 1.0.0


// Version: 1.0.0


interface I_With_TradeRole is I_With_DAORole, I_With_TradeManagerRole{
    function TRADE_ROLE() external view returns (bytes32);
}

abstract contract With_TradeRole is Base, AccessControl, With_DAORole, With_TradeManagerRole, I_With_TradeRole{
    bytes32 public constant TRADE_ROLE = keccak256("TRADE_ROLE");

    constructor(){
        _setRoleAdmin(TRADE_ROLE, TRADE_MANAGER_ROLE);
    }
}// Version: 1.0.0


// Version: 1.0.0


interface I_With_UpdaterRole is I_With_DAORole{
    /**
     * UPDATER_ROLE is able to update contracts.
     */
    function UPDATER_ROLE() external view returns (bytes32);
}

abstract contract With_UpdaterRole is Base, AccessControl, With_DAORole, I_With_UpdaterRole{
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    constructor(){
        _setRoleAdmin(UPDATER_ROLE, DAO_ROLE);
    }
}// Version: 1.0.0


// Version: 1.0.0



interface IPancakeRouter01 {
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

interface PancakeRouter is IPancakeRouter01 {
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

interface I_With_PancakeRouter is IAccessControl, I_With_DAORole{
    function setPancakeRouter(PancakeRouter token) external;
}


abstract contract With_PancakeRouter is Base, AccessControl, With_DAORole, I_With_PancakeRouter{
    PancakeRouter public pancakeRouter;

    function setPancakeRouter(PancakeRouter addr) external onlyRole(DAO_ROLE){
        pancakeRouter = addr;
    }
}// Version: 1.0.0


// Version: 1.0.0

// Version: 1.0.0



interface I_With_DAOAddress is IAccessControl, I_With_DAORole{
    function setDAOAddress(address _DAOAddress) external;
}// Version: 1.0.0



interface I_With_UpdaterContract is IAccessControl, I_With_DAORole{
    function setUpdater(address _updater) external;
}// Version: 1.0.0

// Version: 1.0.0

// Version: 1.0.0



interface I_With_WithdrawerContract is IAccessControl, I_With_DAORole{
    function setWithdrawer(address _withdrawer) external;
}// Version: 1.0.0



interface I_With_TradeManagerContract is IAccessControl, I_With_DAORole{
    function setTradeManager(address _tradeManager) external;
}// Version: 1.0.0



interface I_With_CompetitionContract is IAccessControl, I_With_DAORole{
    function setCompetition(address _competition) external;
}

interface I_Windmill_Trade_Abstract is I_Math, IAccessControl, I_With_DAORole, I_With_UpdaterRole, I_With_TradeManagerRole,
									   I_With_BUSDToken, I_With_FundContract, I_With_TradeManagerContract, I_With_WithdrawerContract, I_With_CompetitionContract{
	
	function getTradeProfit() external view returns(Fraction memory);
	
	function initTrade(address _owner, address _manager, address _fund, address _updater, address _withdrawer, address _competition) external;
	
	function setTradeId(uint256 _tradeId) external;
	
	function setMaxStopLoss(Fraction memory _maxStopLoss) external;
	
	function setMaxDuration(uint256 _maxDurationNbBlock) external;
	
	function setInitBUSDBalance(uint256 _initBUSDBalance) external;
	
	function forceEndTrade() external;
	
	function endTrade() external;
	
	function updateNeeded() external view returns (bool);
	
	function endTradeNeeded() external view returns (bool);
	
	function update() external;
	
	function getInitBUSDBalance() external view returns (uint256);
	
	function estimateBUSDBalance() external view returns (uint256);
	
	function getPnL() external view returns (Fraction memory);
}// Version: 1.0.0

interface I_Initializable{
    function isInitialized(uint256 id) external view returns(bool);
}


interface I_Windmill_Trade_Deployer_Abstract is I_Initializable, IAccessControl, I_With_DAORole, I_With_UpdaterRole, I_With_TradeManagerRole, I_With_BUSDToken{
	function name() external returns (string memory);
	
	function deployNewTrade(address owner, address manager, address fund, address updater, address withdrawer, address competition) external returns (I_Windmill_Trade_Abstract);
	
	function checkProposal(uint256 id, uint256 paramsUint256, address paramsAddress) external view returns (bool);
	
	function applyProposal(uint256 id, uint256 paramsUint256, address paramsAddress) external;
}// Version: 1.0.0



interface I_Terminatable is I_With_DAORole{
    function terminate() external;
    
    function isTerminated() external view returns(bool);
}


interface I_Windmill_Trade_Manager is I_Math, IAccessControl, I_With_DAORole, I_Terminatable, I_With_UpdaterContract, I_With_CompetitionContract,
                                      I_With_FundContract, I_With_DAOAddress, I_With_BUSDToken, I_With_WithdrawerContract{
    
    event StartTrade(uint256 deployerId, uint256 tradeId, address owner);
    event EndTrade(uint256 tradeId);
    
    struct DeployerData{
        I_Windmill_Trade_Deployer_Abstract deployer;
        bool enabled;
    }
    
    struct TradeData{
        I_Windmill_Trade_Abstract trade;
        address owner;
        uint256 energy;
        bool isActive;
        uint256 percentPWRLockedNumerator;
        uint256 blockStart;
    }
    
    function setBaseEnergyBonusRatio(uint256 numerator, uint256 denominator) external;
    
    function getMaxEnergy(address addr) external view returns (uint256);
    
    function setMaxLeverage(uint256 numerator, uint256 denominator) external;
    
    function setMaxTradeStopLoss(uint256 numerator, uint256 denominator) external;
    
    function setMaxTradeDurationNbBlock(uint256 _maxTradeDurationNbBlock) external;
    
    function setMinimumBUSDToTrade(uint256 _minimumBUSDToTrade) external;
    
    function setTraderLevel(address addr, uint8 level) external;
    
    function addTradeDeployer(I_Windmill_Trade_Deployer_Abstract trade) external;
    
    function disableTradeDeployer(uint256 deployerId) external;
    
    function getNbTradeDeployers() external view returns (uint256);
    
    function getTrade(uint256 id) external view returns (TradeData memory);
    
    function getNbOpenTrades() external view returns (uint256);
    
    function getNbTrades() external view returns (uint256);
    
    function getOpenTrade(uint openId) external view returns (TradeData memory, uint256);
    
    function getTradeDeployer(uint256 id) external view returns (DeployerData memory);
    
    function endTrade(uint256 tradeId) external;
    
    function forceEndTrade(uint256 tradeId) external;
}

abstract contract With_TradeManagerContract is Base, AccessControl, With_DAORole, I_With_TradeManagerContract{
    I_Windmill_Trade_Manager public tradeManager;

    function setTradeManager(address _tradeManager) public onlyRole(DAO_ROLE){
        tradeManager = I_Windmill_Trade_Manager(_tradeManager);
    }
}// Version: 1.0.0

// Version: 1.0.0

interface I_Payable{
    receive() external payable;
}

abstract contract Payable is Base, I_Payable{
    receive() external payable {}
}
// Version: 1.0.0


abstract contract Adressable is Base{
    address payable immutable internal thisAddr;

    constructor(){
        thisAddr = payable(address(this));
    }
}
// Version: 1.0.0



abstract contract Math is Base, I_Math{
    /**
     * @notice Compute the number of digits in an uint256 number.
     *
     * Node that if number = 0, it returns 0.
     */
    function numDigits(uint256 number) internal pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }
    
    function _min(uint256 a, uint256 b) internal pure returns (uint256){
        return (a<b ? a : b);
    }
}
// Version: 1.0.0



abstract contract Terminatable is Base, With_DAORole, I_Terminatable{
    bool internal terminated;
    
    modifier onlyNotTerminated() {
        require(!terminated, "Terminatable: already terminated");
        _;
    }
    
    function terminate() external onlyRole(DAO_ROLE){
        terminated = true;
    }
    
    function isTerminated() external view returns(bool){
        return terminated;
    }
}
// Version: 1.0.0


// Version: 1.0.0



interface I_With_DAOContract is IAccessControl, I_With_DAORole{
    function setDAO(address _DAO) external;
}// Version: 1.0.0

// Version: 1.0.0



/**
 * @notice Windmill_Fund is the contract that store and manage the BUSD used for
 * Windmill activities.
 *
 * The features of this contract are :
 * - Mint/burn PWR in exchange of depositing/withdrawing BUSD.
 * - Send BUSD to a Windmill_Contract trade.
 */
interface I_Windmill_Fund is I_Math, I_Payable, IAccessControl, I_With_DAORole, I_Terminatable, I_With_UpdaterRole, I_With_TradeManagerRole, I_With_TradeRole,
                             I_With_PWRToken, I_With_BUSDToken, I_With_WBNBToken, I_With_PancakeRouter, I_With_TradeManagerContract, I_With_DAOContract{
        
    event MarketData(uint256 PWRPrice, uint256 PWRSupply);
    struct LockData{
        uint256 startBlock;
        Fraction factor;
    }
    
    struct FeeData{
        uint256 startBlock;
        uint256 startDynamicFeesNumerator;
    }
    
    function PWR_TOKEN_ROLE() external view returns (bytes32);
    
    function WITHDRAWER_ROLE() external view returns (bytes32);
    
    function beforePWRTransfer(address from, address to, uint256 amount) external;
    
    function setUpdaterAddress(address addr) external;
    
    function setBaseWithdrawFees(uint256 numerator, uint256 denominator) external;
    
    function setDynamicFeesDurationNbBlocks(uint256 _dynamicFeesDurationNbBlocks) external;
    
    function updateWithdrawFees(Fraction memory tradeProfit) external;
    
    function getWithdrawFees() external view returns(uint256);
    
    function getDataPWRLock(address addr) external view returns (uint256, uint256, uint256, uint256, uint256[2][] memory);

    function removeLockedPWRTokens(address addr, uint256 amountPWR) external;

    function getBNBForGasRefund(uint256 amountBNB) external;

    /**
     * Compute the BUSD hold buy Windmill contracts.
     */
    function getFundBUSD() external view returns (uint256);

    /**
     * Compute the BUSD hold buy Windmill contracts.
     */
    function getAvailableBUSD() external view returns (uint256);
    
    function sendBUSDToTrade(I_Windmill_Trade_Abstract trade, uint256 nbBUSD) external;
    
    /**
     * Compute the PWR total supply.
     */
    function getTotalPWR() external view returns (uint256);

    /**
     * Compute The number of PWR that corresponds to "amountBUSD" BUSD.
     */
    function getPWRAmountFromBUSD(uint256 amountBUSD) external view returns (uint256);

    /**
     * Compute The number of BUSD that corresponds to "amountPWR" PWR.
     */
    function getBUSDAmountFromPWR(uint256 amountPWR) external view returns (uint256);

    /**
     * Allow an address to buy PWR at the contract price for "amountBUSD" BUSD.
     * Node that the address must approve the transfer before calling this function.
     */
    function buyPWR(uint256 amountBUSD) external;

    /**
     * Allow an address to sell "amountPWR" PWR at the contract price for BUSD.
     */
    function sellPWR(uint256 amountPWR) external;
    
    function updatePWRPrice() external;
}// Version: 1.0.0




/**
 * @notice Windmill_Royalties
 */
interface I_Windmill_Royalty is I_Math, IAccessControl, I_With_DAORole, I_With_UpdaterRole, IERC20, I_With_PWRToken, I_With_FundContract{
    function percentPWRRoyaltyMint() external view returns (uint256, uint256);

    function mintTo(address to, uint256 amount) external;

    function setRoyaltyRatio(uint256 numerator, uint256 denominator) external;

    /**
     * @notice The loop length have a maximum of ROY supply (in ether)
     */
    function processRoyalties() external;

}// Version: 1.0.0



/**
 * @notice Windmill_Stacking
 */
interface I_Windmill_Stacking is I_Math, IAccessControl, I_With_DAORole, I_Terminatable, I_With_UpdaterRole, I_With_PWRToken, I_With_FundContract{
    struct StackingGroup{
        uint256 nbPWR;
        uint256 nbSPWR;
        uint256 startCycle;
        uint256 currentCycle;
        uint256 endCycle;
        bool stacked;
        address userAddr;
    }

    struct CycleData{
        uint256 sPWRSupply;
        uint256 totalPWRMinted;
    }

    function setStackingRewardRatio(uint256 numerator, uint256 denominator) external;

    function setStackingBonusRatio(uint256 numerator, uint256 denominator) external;

    function setEarlyUnstackingFeesPercent(uint256 numerator, uint256 denominator) external;

    function updateCycle(uint256 cycleId) external;

    function updateStackingNeeded() external view returns (bool);
    
    function updateOneStackingNeeded(uint256 groupId) external view returns (bool);

    function updateOneStacking(uint256 groupId) external;

    function updateStacking() external;

}// Version: 1.0.0

// Version: 1.0.0


interface I_Gas_Refundable is I_Math{
    struct RefundData{
        uint256 usedGas;
        uint256 refundLastBlock;
    }

    function refundBNBBonusRatio() external view returns (uint256, uint256);

    function refundGas() external;
}// Version: 1.0.0



interface I_With_StackingContract is IAccessControl, I_With_DAORole{
    function setStacking(I_Windmill_Stacking _stacking) external;
}// Version: 1.0.0



interface I_With_RoyaltyContract is IAccessControl, I_With_DAORole{
    function setRoyalty(I_Windmill_Royalty _royalty) external;
}

interface I_Windmill_Updater is I_Payable, I_Gas_Refundable, IAccessControl, I_With_DAORole, I_With_DAOContract, I_With_FundContract,
                                I_With_StackingContract, I_With_RoyaltyContract, I_With_CompetitionContract, I_With_TradeManagerContract{
    function init() external;
    
    function setDAOCycleDuration(uint256 duration) external;

    function setStackingCycleDuration(uint256 duration) external;

    function setRoyaltyCycleDuration(uint256 duration) external;

    function setCompetitionCycleDuration(uint256 duration) external;
    
    function setUserGovernorStatus(address user, bool isGovernor) external;
    
    function setRefundGasDefaultPrice(uint256 val) external;
    
    function setRefundNbBlockDelay(uint256 val) external;
    
    function setRefundBNBBonusRatio(uint256 numerator) external;
    
    function setRefundNbBNBMin(uint256 val) external;
}



/**
 * @notice Windmill_DAO is the contract that manage de DAO of Windmill.
 *
 * It can modify all the parameters of Windmill, and update the Windmill contracts
 */
interface I_Windmill_DAO is IAccessControl, I_With_DAORole, I_Terminatable, I_With_UpdaterRole, I_With_FundContract,
                            I_With_StackingContract, I_With_RoyaltyContract, I_With_CompetitionContract, I_With_TradeManagerContract,
                            I_With_UpdaterContract, I_With_PWRToken{
    /**
     * @notice Define an address capability about the DAO
     *
     * level -> Determines what the address is able to
     * - 0 (anonymous) -> This address can only buy, sell and stake PWR
     * - 1 (junior trader) -> This address can also make trade with limited sizing
     * - 2 (senior trader) -> This address can also make trade with full sizing
     * - 3 (governor) -> This address can also make proposals on the DAO
     *
     * nbProposalsDone -> How many proposals have been made in the lastProposalCycle cycle
     * lastProposalDAOCycle -> Last cycle where the address have made a proposal
     */
    struct DAOLevel{
        uint256 lastProposalDAOCycle;
        uint8 level;
        uint16 nbProposalsDone;
        string username;
    }
    
    struct VoteLevelData{
        uint256 quorum;
        uint256 majorityPercent;
        uint256 blockDuration;
        uint256 quorumTrigger;
    }

    /**
     * @notice Define a proposal.
     *
     * id -> Identifiant of the proposal
     * paramsUint256 -> parameter of type uint256 associated with the proposal
     * paramsAddress -> parameter of type address associated with the proposal
     * - 0 -> Change the number of proposals per user per cycle
     *      (uint256) [1, 100] -> Number of proposals
     * - 1 -> Change the duration of vote
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 2 -> Change the quorum
     *      (uint256) [1, 100] -> Number of vote
     * - 3 -> Change the max number of open proposals
     *      (uint256) [10, 1000] -> Number of open proposals
     * - 4 -> Change the vote majority percent
     *      (uint256) [50, 100] -> Percent of yes votes
     * - 5 -> Change the duration of a super vote
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 6 -> Change the quorum of a super vote
     *      (uint256) [1, 100] -> Number of vote
     * - 7 -> Change the vote majority percent of a super vote
     *      (uint256) [50, 100] -> Percent of yes votes
     * - 8 -> define a vote as super status
     *      (uint256) [0, nbProposals] -> Vote id
     * - 9 -> define a vote as normal status
     *      (uint256) [0, nbProposals] -> Vote id
     * - 10 -> update trade max stop loss
     *      (uint256) [0, 1000] -> stop loss (per 1000 ratio -> 10 = 0.1% / 100 = 1%)
     * - 11 -> set the ratio of PWR supply mint edper competition cycle
     *      (uint256) [0, 10000] -> PWR ratio (per 10000 ratio -> 10 = 0.01% / 100 = 0.1%)
     * - 12 -> Change the DAO cycle duration
     *      (uint256) [201600 (7 days), 10512000 (1 year)] -> Number of block
     * - 13 -> Change the gas refund price
     *      (uint256) [0, 100000000000 (100 gwei)] -> Gas price in Wei
     * - 14 -> Change the refund minimum BNB quantity
     *      (uint256) [0, inf] -> Minimum BNB quantity to refund
     * - 15 -> Change the refund bonus
     *      (uint256) [100, 200] -> 100 + Percent of bonus
     * - 16 -> Promote a user to junior trader (set it level 2 if <2) - It cannot demote a user
     *      (address) -> user address
     * - 17 -> Promote a user to senior trader (set it level 3 if <3) - It cannot demote a user
     *      (address) -> user address
     * - 18 -> Promote a user to governor (set it level 4)
     *      (address) -> user address
     * - 19 -> Demote user privilege (set it level 0)
     *      (address) -> user address
     * - 20 -> Change the minimum delay between two user refund
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 21 -> Change the royalty minting ratio
     *      (uint256) [25, 1000] -> ratio (per 10.000 ratio -> 100 = 1%)
     * - 22 -> Change the dynamic fees duration
     *      (uint256) [0, 10512000 (1 year)] -> Number of block
     * - 23 -> Change the Royalty cycle duration
     *      (uint256) [28800 (1 day), 201600 (1 week)] -> Number of block
     * - 24 -> Change the Stacking cycle duration
     *      (uint256) [28800 (1 day), 10512000 (1 year)] -> Number of block
     * - 25 -> Change the Stacking reward minting ratio
     *      (uint256) [0, 1000] -> ratio (per 10.000 ratio -> 100 = 1%)
     * - 26 -> Change the Stacking bonus factor per cycle lock
     *      (uint256) [10000, 30000] -> ratio (per 10.000 ratio -> 100000 = 0% / 10100 = 1%)
     * - 27 -> Change the early unstacking fees per remaining cycle
     *      (uint256) [0, 10000] -> ratio (per 10.000 ratio -> 100 = 1%)
     * - 28 -> Change the fund PWR sell base fees
     *      (uint256) [0, 2500] -> ratio (per 10.000 ratio -> 100 = 1%)
     * - 29 -> Trade deployer proposal
     *      (uint16) [0, 65536] -> Deployer id in Windmill_Trade_Manaager
     *      (uint8) [0, 255] -> Deployer proposal id
     *      (uint232) -> Parameter of type integer
     *      (address) -> Parameter of type address
     * - 30 -> Add deployer
     *      (address) -> Deployer address
     * - 31 -> Change the max fund trading leverage
     *      (uint256) [0, 100] -> ratio (per 100 ratio -> 1 = 1%)
     * - 32 -> Change the maximum trade duration
     *      (uint256) [28800 (1 day), 10512000 (1 year)] -> Number of blocks
     * - 33 -> Change the minimum BUSD to enter a trade
     *      (uint256) -> number of BUSD (in wei -> 1e18 = 1 BUSD)
     * - 34 -> Change the energy ratio bonus/malus of trade energy for +-100% profit
     *      (uint256) [0, 10000] -> energy bonus/malus ratio (per 10.000 ratio -> 100 = 1%)
     * - 35 -> Change the Competition cycle duration
     *      (uint256) [28800 (1 day), 10512000 (1 year)] -> Number of block
     * - 36 -> Change the duration of a security vote
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 37 -> Change the quorum of a security vote
     *      (uint256) [1, 100] -> Number of vote
     * - 38 -> Change the vote majority percent of a security vote
     *      (uint256) [50, 100] -> Percent of yes votes
     * - 39 -> define a vote as security status
     *      (uint256) [0, nbProposals] -> Vote id
     * - 40 -> Change the trigger quorum of a security vote (don't wait duration if trigger quorum reached)
     *      (uint256) [0, 100] -> Number of vote (0 disabled this functionality)
     * - 41 -> Terminate windmill
     * - 42 -> Delete stuck proposal
     *      (uint256) -> Proposal id
     * - 43 -> Force end a trade (try to get the funds then close the trade)
     *      (uint256) -> Trade id
     * - 44 -> Promote a user to investor (set it level 1 if <1) - It cannot demote a user
     *      (address) -> user address
     * - 45 -> Enable investor whitelist
     * - 46 -> Disable investor whitelist
     *
     * startBlock -> Voting is allowed since this block number
     * endBlock -> Voting is terminated since this block number
     * nbYesVotes -> Number of yes vote
     * nbNoVotes -> Number of no vote
     * done -> Proposal is closed
     *
     * status -> Proposal status
     * - 0: Vote period not terminated
     * - 1: Not applied because quorum is not reached
     * - 2: Not applies because "no" majority
     * - 3: Applied
     */
    struct Proposal{
        uint256 paramsUint256;
        address paramsAddress;
        uint256 startBlock;
        uint256 endBlock;
        uint256 quorumTrigger;
        uint64 nbYesVotes;
        uint64 nbNoVotes;
        uint16 id;
        uint16 status;
        bool done;
    }

    /**
     *            uint256 _nbProposalPerUserPerCycle,
     *            uint256 _maxNbOpenProposals,
     *            uint256 _voteBlockDuration,
     *            uint256 _quorum,
     *            uint256 _voteMajorityPercent,
     *            uint256 _superVoteBlockDuration,
     *            uint256 _superQuorum,
     *            uint256 _superVoteMajorityPercent,
     *            uint256 _DAOcycleDurationNbBlock,
     *            uint256 _royaltyCycleDurationNbBlock,
     *            uint256 _stackingCycleDurationNbBlock,
     *            uint256 _competitionCycleDurationNbBlock,
     *            uint256 _securityVoteBlockDuration,
     *            uint256 _securityQuorum,
     *            uint256 _securityVoteMajorityPercent,
     *            uint256 _securityTriggerQuorum
     *
     */
    function init(uint256[16] calldata data,
                  uint256[] calldata _proposalLevel) external;

    function setDAOCycle(uint256 cycle) external;
    
    function getNbOpenProposalIds() external view returns (uint256);
    
    function updateOpenProposalNeeded(uint256 i) external view returns (bool);
    
    function updateOneOpenProposal(uint256 i) external;
    
    function investorWhitelistEnabled() external returns(bool);
    
    /**
     * @notice Add a user with capability on the DAO (used only at DAO contract initialization).
     */
    function addUser(address addr, uint8 level) external;
    
    function getUserData(address addr) external view returns (DAOLevel memory);
}


abstract contract With_DAOContract is Base, AccessControl, With_DAORole, I_With_DAOContract{
    I_Windmill_DAO public DAO;

    function setDAO(address _DAO) external onlyRole(DAO_ROLE){
        DAO = I_Windmill_DAO(_DAO);
    }
}


contract Windmill_Fund is Base, Adressable, Math, Payable, AccessControl, With_DAORole, Terminatable, With_UpdaterRole, With_TradeManagerRole, With_TradeRole,
                          With_PWRToken, With_BUSDToken, With_WBNBToken, With_PancakeRouter, With_TradeManagerContract, With_DAOContract, I_Windmill_Fund{
    ////
    ////
    ////
    //////////////// Public variables ////////////////
    bytes32 public constant PWR_TOKEN_ROLE = keccak256("PWR_TOKEN_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    
    Fraction public baseWithdrawFees;
    uint256 public dynamicFeesDurationNbBlocks;
    
    FeeData public dynamicFees;
    
    address public updaterAddress;
    
    uint256 public startBlock;

    ////
    ////
    ////
    //////////////// Private variables ////////////////
    mapping(address=>LockData) internal userLockData;

    ////
    ////
    ////
    //////////////// Constructor & Modifiers ////////////////
    constructor() {
        _setRoleAdmin(PWR_TOKEN_ROLE, DAO_ROLE);
        _setRoleAdmin(WITHDRAWER_ROLE, DAO_ROLE);
        
        baseWithdrawFees.numerator = 100;
        baseWithdrawFees.denominator = 10000;
        
        dynamicFeesDurationNbBlocks = 864000;
        
        startBlock = block.number;
    }

    ////
    ////
    ////
    //////////////// Public functions ////////////////
    function setUpdaterAddress(address addr) external onlyRole(DAO_ROLE){
        updaterAddress = addr;
    }
    
    function setBaseWithdrawFees(uint256 numerator, uint256 denominator) external onlyRole(DAO_ROLE){
        require(denominator>0, "Windmill_Fund: Denominator cannot be null");
        baseWithdrawFees.numerator = numerator;
        baseWithdrawFees.denominator = denominator;
    }
    
    function setDynamicFeesDurationNbBlocks(uint256 _dynamicFeesDurationNbBlocks) external onlyRole(DAO_ROLE){
        dynamicFeesDurationNbBlocks = _dynamicFeesDurationNbBlocks;
    }

    function getWithdrawFees() public view returns(uint256){
        if (terminated){
            return 0;
        }
        
        Fraction storage baseFees = baseWithdrawFees;
        
        uint256 currentFeesNumerator = (baseFees.numerator * 1e10) / (baseFees.denominator);
        
        currentFeesNumerator += _getDynamicFees();
        
        return currentFeesNumerator;
    }
    
    function updateWithdrawFees(Fraction memory tradeProfit) external onlyRole(TRADE_ROLE){
        if (tradeProfit.numerator > tradeProfit.denominator){
            dynamicFees.startDynamicFeesNumerator = _getDynamicFees();
            dynamicFees.startDynamicFeesNumerator += ((tradeProfit.numerator -  tradeProfit.denominator) * 1e10) / tradeProfit.denominator;
            
            dynamicFees.startBlock = block.number;
        }
    }
    
    function getBNBForGasRefund(uint256 amountBNB) external onlyRole(UPDATER_ROLE){
        address[] memory path = new  address[](2);
        path[0] = address(BUSDToken);
        path[1] = address(WBNBToken);

        uint256 amountBUSD = pancakeRouter.getAmountsIn(amountBNB, path)[0];

        require(BUSDToken.balanceOf(thisAddr) >= amountBUSD, "Windmill_Fund: BUSD reserve too small");

        BUSDToken.approve(address(pancakeRouter), amountBUSD);
        pancakeRouter.swapTokensForExactETH(amountBNB, amountBUSD, path, thisAddr, block.timestamp);

        payable(updaterAddress).transfer(amountBNB);
    }

    function getFundBUSD() public view returns (uint256){
        uint256 nbBUSD = BUSDToken.balanceOf(thisAddr);
        
        uint256 l = tradeManager.getNbOpenTrades();
        for(uint256 i=0; i<l; i++){
            (I_Windmill_Trade_Manager.TradeData memory data,) = tradeManager.getOpenTrade(i);
            nbBUSD += data.trade.getInitBUSDBalance();
        }

        return nbBUSD;
    }

    function sendBUSDToTrade(I_Windmill_Trade_Abstract trade, uint256 nbBUSD) external onlyRole(TRADE_MANAGER_ROLE){
        address addr = address(trade);
        BUSDToken.transfer(addr, nbBUSD);
    }
    
    function getAvailableBUSD() public view returns (uint256){
        uint256 nbBUSD = BUSDToken.balanceOf(thisAddr);

        return nbBUSD;
    }
    
    function getTotalPWR() public view returns (uint256){
        return PWRToken.totalSupply();
    }

    function getPWRAmountFromBUSD(uint256 amountBUSD) public view returns (uint256){
        uint256 nbBUSD = getFundBUSD();
        uint256 PWRSupply = getTotalPWR();

        uint256 nbPWRToGet = amountBUSD;
        if (PWRSupply > 0 && nbBUSD > 0){
            nbPWRToGet = amountBUSD * PWRSupply / nbBUSD;
        }

        return nbPWRToGet;
    }

    function getBUSDAmountFromPWR(uint256 amountPWR) public view returns (uint256){
        uint256 nbBUSD = getFundBUSD();
        uint256 PWRSupply = getTotalPWR();

        uint256 nbBUSDToGet = 0;
        if (PWRSupply > 0 && nbBUSD > 0){
            nbBUSDToGet = amountPWR * nbBUSD / PWRSupply;
        }

        return nbBUSDToGet;
    }

    function getBUSDAmountFromPWRWithFees(uint256 amountPWR) external view returns (uint256){
        uint256 feesNumerator = getWithdrawFees();
        
        uint256 feesPWR = (amountPWR * feesNumerator) / 1e10;
        uint256 PWRToWithdraw = amountPWR - feesPWR;
        
        return getBUSDAmountFromPWR(PWRToWithdraw);
    }
    
    function buyPWR(uint256 amountBUSD) external onlyNotTerminated{
        require(BUSDToken.balanceOf(msg.sender) >= amountBUSD, "Windmill_Fund: Not enough BUSD");
        
        if (DAO.investorWhitelistEnabled()){
            require(DAO.getUserData(msg.sender).level >= 1, "Windmill_Fund: Investors have to be whitelisted");
        }
        
        uint256 nbPWRToMint = getPWRAmountFromBUSD(amountBUSD);

        require(nbPWRToMint > 0, "Windmill_Fund: Too small amount of BUSD sent");

        (uint256 nbFreePwr, uint256 nbLockedPwr, uint256 flatLockPercentNumerator,,) = getDataPWRLock(msg.sender);
        _updateLockedPWR(msg.sender, nbLockedPwr, nbFreePwr + nbLockedPwr + nbPWRToMint, flatLockPercentNumerator);
        
        BUSDToken.transferFrom(msg.sender, thisAddr, amountBUSD);
        PWRToken.mintTo(msg.sender, nbPWRToMint);
    }
    
    function beforePWRTransfer(address from, address to, uint256 amount) external onlyRole(PWR_TOKEN_ROLE){
        (uint256 nbFreePwrFrom, uint256 nbLockedPwrFrom, uint256 flatLockPercentNumeratorFrom,,) = getDataPWRLock(from);
        
        require(nbFreePwrFrom >= amount, "Windmill_Fund: Cannot transfer locked PWR tokens.");
        
        (uint256 nbFreePwrTo, uint256 nbLockedPwrTo, uint256 flatLockPercentNumeratorTo,,) = getDataPWRLock(to);
        
        
        _updateLockedPWR(from, nbLockedPwrFrom, nbFreePwrFrom + nbLockedPwrFrom - amount, flatLockPercentNumeratorFrom);
        _updateLockedPWR(to, nbLockedPwrTo, nbFreePwrTo + nbLockedPwrTo + amount, flatLockPercentNumeratorTo);
    }
    
    function getFreePWR(address addr) external view returns(uint256){
        (uint256 nbFreePWR,,,,) = getDataPWRLock(addr);
        
        return nbFreePWR;
    }
    
    function getLockedPWR(address addr) external view returns(uint256){
        (, uint256 nbLockedPWR,,,) = getDataPWRLock(addr);
        
        return nbLockedPWR;
    }
    
    
    function sellPWR(uint256 amountPWR) external{
        (uint256 nbFreePwr, uint256 nbLockedPwr, uint256 flatLockPercentNumerator,,) = getDataPWRLock(msg.sender);
        
        require(nbFreePwr >= amountPWR, "Windmill_Fund: Not enough PWR.");

        uint256 feesNumerator = getWithdrawFees();
        
        
        uint256 feesPWR = (amountPWR * feesNumerator) / 1e10;
        uint256 PWRToWithdraw = amountPWR - feesPWR;

        if (feesPWR > 0){
            PWRToken.burnFrom(msg.sender, feesPWR);
        }
        
        uint256 nbBUSDTowithdraw = getBUSDAmountFromPWR(PWRToWithdraw);

        require(nbBUSDTowithdraw > 0, "Windmill_Fund: Too small amount of PWR sent.");
        require(nbBUSDTowithdraw <= BUSDToken.balanceOf(thisAddr), "Windmill_Fund: All BUSD are locked in trades.");
        
        _updateLockedPWR(msg.sender, nbLockedPwr, nbFreePwr + nbLockedPwr - amountPWR, flatLockPercentNumerator);

        PWRToken.burnFrom(msg.sender, PWRToWithdraw);
        BUSDToken.transfer(msg.sender, nbBUSDTowithdraw);
        
        updatePWRPrice();
    }
    
    function removeLockedPWRTokens(address addr, uint256 amountPWR) external onlyRole(WITHDRAWER_ROLE){
        (uint256 nbFreePwr, uint256 nbLockedPwr, uint256 flatLockPercentNumerator,,) = getDataPWRLock(addr);
        
        require(nbLockedPwr >= amountPWR, "Windmill_Fund: Not enough locked PWR.");
        require(nbFreePwr + nbLockedPwr >= amountPWR, "Windmill_Fund: Not enough total PWR.");
        
        _updateLockedPWR(addr, nbLockedPwr - amountPWR, nbFreePwr + nbLockedPwr - amountPWR, flatLockPercentNumerator);
    }
    
    function updatePWRPrice() public{
        uint256 nbBUSD = getFundBUSD();
        uint256 PWRSupply = getTotalPWR();

        uint256 BUSDPrice = 1e18;
        if (PWRSupply > 0 && nbBUSD > 0){
            BUSDPrice = 1e18 * nbBUSD / PWRSupply;
        }
        
        emit MarketData(BUSDPrice, PWRSupply);
    }
    
    function getDataPWRLock(address addr) public view returns (uint256, uint256, uint256, uint256, uint256[2][] memory){
        uint256 nbPWRUser = PWRToken.balanceOf(addr);
        
        LockData storage dataLock = userLockData[addr];
        uint256 lockPercentNumerator;
        uint256 flatLockPercentNumerator;
        
        uint256 l = tradeManager.getNbOpenTrades();
        
        uint256[2][] memory lockDatas = new uint256[2][](l);
        
        for(uint256 i=0; i<l; i++){
            (I_Windmill_Trade_Manager.TradeData memory data, uint256 id) = tradeManager.getOpenTrade(i);
            
            flatLockPercentNumerator += data.percentPWRLockedNumerator;
            
            uint256 n;
            if (data.blockStart >= dataLock.startBlock){
                n = data.percentPWRLockedNumerator;
            }else if (dataLock.factor.denominator != 0){
                n = (data.percentPWRLockedNumerator * dataLock.factor.numerator) / dataLock.factor.denominator;
            }
            
            lockDatas[i][0] = n;
            lockDatas[i][1] = id;
            lockPercentNumerator += n;
        }
        
        uint256 nbLockedPWR = (nbPWRUser * lockPercentNumerator) / 1e20;
        uint256 nbFreePWR = 0;
        
        if (nbPWRUser >= nbLockedPWR){
            nbFreePWR = nbPWRUser - nbLockedPWR;
        }else{
            nbLockedPWR = nbPWRUser;
        }
        
        return (nbFreePWR, nbLockedPWR, flatLockPercentNumerator, lockPercentNumerator, lockDatas);
    }

    
    
    ////
    ////
    ////
    //////////////// Private functions ////////////////
    function _getDynamicFees() internal view returns(uint256){
        uint256 deltaBlock = block.number - dynamicFees.startBlock;
        if (deltaBlock < dynamicFeesDurationNbBlocks){
            return (dynamicFees.startDynamicFeesNumerator * (dynamicFeesDurationNbBlocks - deltaBlock)) / dynamicFeesDurationNbBlocks;
        }
        return 0;
    }
    
    
    function _updateLockedPWR(address addr, uint256 prevNbLockedPWR, uint256 currNbPWR, uint256 flatLockPercentNumerator) internal{
        LockData storage dataLock = userLockData[addr];
        
        if (currNbPWR == 0 || prevNbLockedPWR == 0){
            dataLock.factor.numerator = 0;
            dataLock.factor.denominator = 0;
        }else{
            uint256 currLockPercentNumerator = ((prevNbLockedPWR+1) * 1e20) / currNbPWR;
            
            dataLock.factor.numerator = currLockPercentNumerator;
            dataLock.factor.denominator = flatLockPercentNumerator;
        }
        
        dataLock.startBlock = block.number;
    }
}