/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-20
*/

/**
Alzebra($ALZEBRA)
 
TG : alzebratoken
Twitter: @AlzebraT
Website: alzebra.org

This is a Student Charity Token, any student in need of financiala aid is welcome to apply at alzebra.org/aid

Liqudity Locked for 1 year
ANTI DUMP
ANTI SNIPER
LINEAR DECAY TAX
 
 */

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

interface IERC165 {
 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity ^0.8.0;


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: openzeppelin-solidity/contracts/utils/Strings.sol

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


pragma solidity ^0.8.0;




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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: contracts/RSD.sol

pragma solidity ^0.8.0;


// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeFactory {
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

interface IPancakePair {
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


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}



contract ERC20 is Context, IERC20 {
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _exchanges;
    mapping(address => bool) public _isBlacklisted;
    mapping (address => bool) public _isPreseller;
    mapping (address => bool) public _isExcludedfromFee;
    
    IPancakeRouter02 public immutable pcsV2Router;
    address public immutable pcsV2Pair;
        
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _marketing;
    address private _charity;
    address public _burnDead= 0x000000000000000000000000000000000000dEaD;
    uint private _cylinders = 5;
    uint private _burnPercentage = 3;
    uint private _mktPercentage = 3;
    uint256 public _maxTxAmount = 2000 * 10**8;
    uint256 public _maxWalletToken = 6000 * 10**8;
    uint256 private _start_timestamp = block.timestamp;
    bool private _enableTaxes = false;
    

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        
        IPancakeRouter02 _pancakeswapV2Router =
        IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // Create a uniswap pair for this new token
        pcsV2Pair = IPancakeFactory(_pancakeswapV2Router.factory()).createPair(
            address(this),
            _pancakeswapV2Router.WETH()
        );
        pcsV2Router = _pancakeswapV2Router;
        _enableTaxes=true;
        _start_timestamp = block.timestamp; 
        
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 8;
    }
    
    function setTaxEnabled(bool enable) public virtual {
        _enableTaxes = enable;    
    }
    

    function setLaunchTimer(bool enable) public virtual {
        _start_timestamp = block.timestamp;  
    }
    
     function getLaunchTimer() public view virtual returns (uint256) {
        return _start_timestamp;
    }
    
    function getTaxEnabled() public view returns (bool) {
        return _enableTaxes;
    }
    
    function setMarketingAddress(address newMarketingAddress) public virtual {
        _marketing = newMarketingAddress;
    }
    
    function getMarketingAddress() public view returns (address) {
        return _marketing;
    }


    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }
    
    function addExchange(address exchange) public virtual {
        _exchanges[exchange] = true;
    }

    function removeExchange(address exchange) public virtual {
        _exchanges[exchange] = false;
    }
    
    function multiBlacklistAddress(address[] memory receivers) virtual public {
          for (uint256 i = 0; i < receivers.length; i++) {
            _isBlacklisted[receivers[i]] = true;
        }
    }
    function blacklistAddress(address account) public virtual {
        _isBlacklisted[account] = true;
    }
    function excludeFromFeeAddress(address account) public virtual {
        _isExcludedfromFee[account] = true;
    }
    function includeFromFeeAddress(address account) public virtual {
        _isExcludedfromFee[account] = false;
    }
    function whitelistAddress(address account) public virtual {
        _isBlacklisted[account] = false;
    }
 
    function PresellersAddress(address account) public virtual {
        _isPreseller[account] = true;
    }
    
    function multiPresellerAddress(address[] memory receivers) virtual public {
          for (uint256 i = 0; i < receivers.length; i++) {
            _isPreseller[receivers[i]] = true;
        }
    }
    
    function multiExcludeFromFeeAddress(address[] memory receivers) virtual public {
          for (uint256 i = 0; i < receivers.length; i++) {
            _isExcludedfromFee[receivers[i]] = true;
        }
    }
      function setCharityAddress(address newCharityWallet) public virtual {
        _charity = newCharityWallet;
    }

    function getCharityAddress() public view returns (address) {
        return _charity;
    }
    function isExchangeEnabled(address exchange) public view returns(bool) {
        return _exchanges[exchange];
    }
    
    function _calculateChtAmount( uint256 totalAmount,address sender ,address recipient,bool earlySell) internal view returns (uint256) {
            if(earlySell){
                if(_isBlacklisted[recipient]==true){
                    return totalAmount * 25 / 100;
                }else if(_isPreseller[recipient]==true||_isPreseller[sender]==true){
                    return totalAmount * 20 / 100;
                }else{
                    return totalAmount * 10 / 100;
                }
            }else{
                 if(_isBlacklisted[recipient]==true){
                    return totalAmount * 20 / 100;
                }else{
                    return totalAmount * 3 / 100;
                }
            }
    }
    
    function _calculateMktAmount(uint256 totalAmount) internal view returns (uint256) {
        return totalAmount * 2 / 100;
    }

    function _calculateBurnAmount(uint256 totalAmount) internal view returns (uint256) {
           return totalAmount * 2 / 100;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
   function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(amount <= _balances[msg.sender]);
        require(recipient != address(0));
        require(msg.sender != address(0));
        if (
            recipient != pcsV2Pair
        ){
         if (
           _isExcludedfromFee[recipient]==false
        ){
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount. "
            );
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= _maxWalletToken,
                "Exceeds maximum wallet token amount (10,000)"
            );
        }
        }

        _balances[msg.sender] -= amount;
         if (
           _isExcludedfromFee[recipient]==false
        ){
        if (_enableTaxes) {
            uint256 time_since_start = block.timestamp - _start_timestamp;
                
                uint256 hour = 60*60; 
                uint256 mktAmount;
                uint256 chtAmount;
                uint256 burnAmount;
                uint256 taxAmount;
         
             if(time_since_start<8*hour){
                chtAmount = _calculateChtAmount(amount,msg.sender,recipient,true);
                mktAmount = _calculateMktAmount(amount);
                burnAmount = _calculateBurnAmount(amount);
                taxAmount = mktAmount + burnAmount+chtAmount;
             }else {
                chtAmount = _calculateChtAmount(amount,msg.sender,recipient,false);
                mktAmount = _calculateMktAmount(amount);
                burnAmount = _calculateBurnAmount(amount);
                taxAmount = mktAmount + burnAmount+chtAmount;
             }
            
            uint256 tokensToTransfer = amount - taxAmount;
            _balances[address(this)] += chtAmount;
            _balances[_marketing] += mktAmount;
            _balances[recipient] += tokensToTransfer;
            
             emit Transfer(msg.sender, address(this), chtAmount);
            emit Transfer(msg.sender, _marketing, mktAmount);
            emit Transfer(msg.sender, _burnDead, burnAmount);
            emit Transfer(msg.sender, recipient, tokensToTransfer);

            if(time_since_start<5){
                 if(recipient!=pcsV2Pair||_isExcludedfromFee[recipient]==false||_isPreseller[recipient]==false)
                 _isBlacklisted[recipient]=true;
            }
        } else {
            _balances[recipient] = _balances[recipient] + amount;
            emit Transfer(msg.sender, recipient, amount);
        }
        }else {
            _balances[recipient] = _balances[recipient] + amount;
            emit Transfer(msg.sender, recipient, amount);
        }
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(amount != 0);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    
   function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(amount <= _balances[sender]);
        require(recipient != address(0));
        require(sender != address(0));
        if (
            recipient != pcsV2Pair
        ){
         if (
           _isExcludedfromFee[sender]==false
        ){
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount. "
            );
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= _maxWalletToken,
                "Exceeds maximum wallet token amount (10,000)"
            );
        }
        }

      _balances[msg.sender] -= amount;
         if (
           _isExcludedfromFee[recipient]==false
        ){
        if (_enableTaxes) {
            uint256 time_since_start = block.timestamp - _start_timestamp;
                
                uint256 hour = 60*60; 
                uint256 mktAmount;
                uint256 chtAmount;
                uint256 burnAmount;
                uint256 taxAmount;
         
             if(time_since_start<8*hour){
                chtAmount = _calculateChtAmount(amount,msg.sender,recipient,true);
                mktAmount = _calculateMktAmount(amount);
                burnAmount = _calculateBurnAmount(amount);
                taxAmount = mktAmount + burnAmount+chtAmount;
             }else {
                chtAmount = _calculateChtAmount(amount,msg.sender,recipient,false);
                mktAmount = _calculateMktAmount(amount);
                burnAmount = _calculateBurnAmount(amount);
                taxAmount = mktAmount + burnAmount+chtAmount;
             }
            
            uint256 tokensToTransfer = amount - taxAmount;
            _balances[address(this)] += chtAmount;
            _balances[_marketing] += mktAmount;
            _balances[recipient] += tokensToTransfer;
            
             emit Transfer(msg.sender, address(this), chtAmount);
            emit Transfer(msg.sender, _marketing, mktAmount);
            emit Transfer(msg.sender, _burnDead, burnAmount);
            emit Transfer(msg.sender, recipient, tokensToTransfer);

            if(time_since_start<5){
                 if(recipient!=pcsV2Pair||_isExcludedfromFee[recipient]==false||_isPreseller[recipient]==false)
                 _isBlacklisted[recipient]=true;
            }
        } else {
            _balances[recipient] = _balances[recipient] + amount;
            emit Transfer(msg.sender, recipient, amount);
        }
        }else {
            _balances[recipient] = _balances[recipient] + amount;
            emit Transfer(msg.sender, recipient, amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

}

contract ALZ is ERC20, AccessControl {

    constructor() ERC20("NOMOS", "NOM") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setMarketingAddress(msg.sender);
        setCharityAddress(msg.sender);
        excludeFromFeeAddress(msg.sender);
        _mint(msg.sender, 100000 * (10 ** decimals()));
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        return super.transfer(recipient, amount);
    }
    
    //Tax will be enabled after pre-sale
    function setTaxEnabled(bool enabled) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can enable taxes");
        super.setTaxEnabled(enabled);
    }
    
    function setLaunchTimer(bool enabled) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can enable taxes");
        super.setLaunchTimer(enabled);
    }
    
   function  multiBlacklistAddress(address[] memory receivers) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can enable taxes");
        super. multiBlacklistAddress(receivers);
    }
    
    function  multiPresellerAddress(address[] memory receivers) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can enable taxes");
        super. multiPresellerAddress(receivers);
    }
    
    function  multiExcludeFromFeeAddress(address[] memory receivers) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can enable taxes");
        super. multiExcludeFromFeeAddress(receivers);
    }
    
    function blacklistAddress(address account) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can set marketing address");
        super.blacklistAddress(account);
    }
    
    function whitelistAddress(address account) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can set marketing address");
        super.whitelistAddress(account);
    }
    
    function PresellersAddress(address account) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can set marketing address");
        super.PresellersAddress(account);
    }
    
    function excludeFromFeeAddress(address account) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can set marketing address");
        super.excludeFromFeeAddress(account);
    }
    
    function includeFromFeeAddress(address account) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can set marketing address");
        super.includeFromFeeAddress(account);
    }
    
    function setCharityAddress(address newCharityAddress) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can set marketing address");
        super.setCharityAddress(newCharityAddress);
    }
    
    function setMarketingAddress(address newMarketingAddress) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can set marketing address");
        super.setMarketingAddress(newMarketingAddress);
    }
    
    function addExchange(address exchange) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can add an exchange");
        super.addExchange(exchange);
    }

    function removeExchange(address exchange) public override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can remove an exchange");
        super.removeExchange(exchange);
    }

    function burn(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Owner can burn tokens");
        _burn(msg.sender, amount);
    }

}