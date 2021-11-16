/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

/*
    ███████╗ █████╗ ███████╗███████╗ ██████╗  █████╗ ███╗   ███╗███████╗ ██████╗ █████╗ ███████╗██╗  ██╗
    ██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔════╝██╔══██╗██╔════╝██║  ██║
    ███████╗███████║█████╗  █████╗  ██║  ███╗███████║██╔████╔██║█████╗  ██║     ███████║███████╗███████║
    ╚════██║██╔══██║██╔══╝  ██╔══╝  ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██║     ██╔══██║╚════██║██╔══██║
    ███████║██║  ██║██║     ███████╗╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗╚██████╗██║  ██║███████║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// You can use an Ownable contract like this to onclude the roles functions



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

pragma solidity ^0.6.2;

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

pragma solidity ^0.6.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.2;
contract Ownable is Context {
    using SafeMath for uint256;
    using Roles for Roles.Role;
    
    Roles.Role internal CEO;
    Roles.Role internal coreTeam;
    
    bool public ceoSign = false;
    bool public coreMemberSign = false;
    
    
    modifier onlyCEO(){
        require(_owner == _msgSender(), 'Must have CEO role');
        _;
    }
    
    
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
     // Inicializa el contrato estableciendo al implementador como propietario inicial.
    
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


     // Devuelve la dirección del propietario actual.

    function owner() public view virtual returns (address) 
    {
        return _owner;
    }

    // Permite dejar el contrato sin dueño, lo renuncia en el caso que se decida desactivar el token.

    function renounceOwnership() public virtual onlyCEO() 
    {
        emit OwnershipTransferred(_owner, address(0));
        CEO.remove(_owner);
        _owner = address(0);
        
    }

    
    // Transfiere el contrato a una nueva persona, en el caso de ceder derechos a un tercero
    
    function transferOwnership(address newOwner) public virtual onlyCEO()
    {
        require(
            newOwner != address(0),
            "SGC: El nuevo propietario es la direccion 0."
        );
        emit OwnershipTransferred(_owner, newOwner);
        CEO.remove(_owner);
        CEO.add(newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.2;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
    constructor(string memory name_, string memory symbol_) public {
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
        return 9;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * will be to transferred to `to`.
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
}

pragma solidity ^0.6.2;

interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

pragma solidity ^0.6.2;

interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

pragma solidity ^0.6.2;

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(msg.sender);
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

pragma solidity ^0.6.2;

contract SafeGameCash is ERC20, Ownable {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    event TokensAirdropped(address indexed to, uint256 indexed amount);
    
    bool private swapping;    
    
    address public marketingWallet = payable(0xdE3D56dB69Ebf8A8F190f4Ff9e41E12589b77758);
    address public gameWallet = payable(0x9b19d45D4f9Ff88b5B4cF76347eD854637AE0b7d);
    address public airdropWallet = 0x1Ee53fEB01F35EAD1671d96003384CE28f6cb0A5;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address public swapContractAddr;

    DividendTracker public dividendTracker;
    RewardStaker public rewardStaker;

    uint256 public maxSellTransactionAmount = 5 * 10 ** 12 * (10**9);
    uint256 public maxBuyTransactionAmount = 1 * 10 ** 15 * (10**9);
    uint256 public swapTokensAtAmount = 2 * 10 ** 8 * (10**9);

    uint256 public BNBRewardsFee = 2;
    uint256 public liquidityFee = 4;
    uint256 public marketingFee = 2;
    uint256 public gameFee = 2;
    uint256 public burnFee = 1;
    
    uint256 public BNBRewardsFeeOnSell = 3;
    uint256 public liquidityFeeOnSell = 5;
    uint256 public marketingFeeOnSell = 3;
    uint256 public gameFeeOnSell = 3;
    uint256 public burnFeeOnSell = 1;
    
    bool public _bFeePaused = false;
    
    uint256 public marketingTokensAcummulated;
    uint256 public gameTokensAcummulated;
    uint256 public liquidityAcummulated;
    uint256 public distributionAcummulated;
    
    mapping(address => bool) public _isCoreMember;
    
    function signAsCEO() public virtual onlyCEO() {
        ceoSign = true;
    }

    mapping(address => uint256) public _sellLockTimeRefresh;
    mapping(address => uint256) public _sellLockFreqency;

    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 public immutable sellFeeIncreaseFactor = 120; 

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;


    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 public tradingEnabledTimestamp;
    uint256 public deployTimeStamp;
    
    mapping(address => uint256) public _stakingStartTimeForAddress;
    mapping(address => uint256) public _recievedRewardForAddress;
    IterableMapping.Map private _holderMap;
    uint256 public _loopIndexRewardStakerCheck;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    address CEOAddress = 0x7cc381e407402c7d15830BbD23dDA979801aB0Db;
    address coreTeamAddress1 = 0x336233460Ba71f28a867cf633D9530F992b86A7b; 
    address coreTeamAddress2 = 0xc4286DC465dF3Dc0Ee0497E88F0cFf48649D2a13; 
    address coreTeamAddress3 = 0xE294702D1Cb4c26EfBe9a45Aa70EC546e8C13661; 
    address coreTeamAddress4 = 0x9E4C506bC5C428b2b6605B430B520ba4Bf70b33f; 
    address coreTeamAddress5 = 0xc5023Fb8eDC993EF7c625E144f7aa4710F896b59;

    constructor() public ERC20("TEST TOKEN 37", "TST37") {
        CEO.add(msg.sender);
        coreTeam.add(coreTeamAddress1);
        coreTeam.add(coreTeamAddress2);
        coreTeam.add(coreTeamAddress3);
        coreTeam.add(coreTeamAddress4);
        coreTeam.add(coreTeamAddress5);
        


    	dividendTracker = new DividendTracker();
    	rewardStaker = new RewardStaker();
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(airdropWallet));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(_uniswapV2Pair));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        //excludeFromFees(CEOAddress, true);
        excludeFromFees(coreTeamAddress1, true);
        excludeFromFees(coreTeamAddress2, true);
        excludeFromFees(coreTeamAddress3, true);
        excludeFromFees(coreTeamAddress4, true);
        excludeFromFees(coreTeamAddress5, true);
        
        deployTimeStamp = block.timestamp;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        deployTimeStamp = block.timestamp;
        _mint(owner(), 1.8 * 10 ** 15 * (10**9));
        _mint(coreTeamAddress1, 4 * 10 ** 13 * (10**9));
        _mint(coreTeamAddress2, 4 * 10 ** 13 * (10**9));
        _mint(coreTeamAddress3, 4 * 10 ** 13 * (10**9));
        _mint(coreTeamAddress4, 4 * 10 ** 13 * (10**9)); 
        _mint(coreTeamAddress5, 4 * 10 ** 13 * (10**9)); 
    }

    receive() external payable {

  	}
    function excludeFromFees(address account, bool excluded) public onlyCEO {
        require(_isExcludedFromFees[account] != excluded, " Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function updateGasForProcessing(uint256 newValue) public onlyCEO {
        require(newValue >= 200000 && newValue <= 500000, " gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, " Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyCEO {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }
    
    function getHoldTimeFromStakingStart(address addr) external view returns (int256) {
        if (_stakingStartTimeForAddress[addr] == 0){
            return 0;
        } else {
            return (int256)(block.timestamp - _stakingStartTimeForAddress[addr]) / (1 days);
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
	    require(gasleft() >= gas, "Out of gas, please increase gas limit and retry!");
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process{gas:gas}();
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(msg.sender, false);
    }
    
    function setMaxSellAmount(uint256 amount) public onlyCEO {
        maxSellTransactionAmount = amount * 10 ** 9;
    }
    
    function setMaxBuyAmount(uint256 amount) public onlyCEO{
        maxBuyTransactionAmount = amount * 10 ** 9;
    }
    
    function setSwapContractAddress (address addr) public onlyCEO{
        swapContractAddr = addr;
        _isExcludedFromFees[addr] = true;
        dividendTracker.excludeFromDividends(addr);
    }
    
    function setIsCoreMember(address addr, bool bFlag) public onlyCEO{
        _isCoreMember[addr] = bFlag;
    }
    
    // function signAsCEO() public onlyCEO {
    //     ceoSign = true;
    // }
    
    function setBuyFee(uint256 _BNBRewardsFee, uint256 _liquidityFee, uint256 _marketingFee, uint256 _gameFee, uint256 _burnFee) public onlyCEO {
        BNBRewardsFee = _BNBRewardsFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        gameFee = _gameFee;
        burnFee = _burnFee;
    }
    
    function setSellFee(uint256 _BNBRewardsFeeOnSell, uint256 _liquidityFeeOnSell, uint256 _marketingFeeOnSell, uint256 _gameFeeOnSell, uint256 _burnFeeOnSell) public onlyCEO {
        BNBRewardsFeeOnSell = _BNBRewardsFeeOnSell;
        liquidityFeeOnSell = _liquidityFeeOnSell;
        marketingFeeOnSell = _marketingFeeOnSell;
        gameFeeOnSell = _gameFeeOnSell;
        burnFeeOnSell = _burnFeeOnSell;
    }
    
    function deposit() public payable {
        rewardStaker.deposit{value: msg.value};
        //address(rewardStaker).call{value: msg.value}("");
    }
    
    function withdraw (address reciever) public onlyCEO {
        rewardStaker.withdraw(reciever);
    }
    
    function signAsCoreMember() public {
        require(_isCoreMember[msg.sender], "Must sign core member, ask CEO for details!");
        coreMemberSign = true;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getTradingIsEnabled() public view returns (bool) {
        return tradingEnabledTimestamp != 0;
    }
    
    function pauseAllFee() external onlyCEO {
        _bFeePaused = true;
    }
    
    function restoreAllFee() external onlyCEO {
        _bFeePaused = false;
    }
    
    function getStakerCount() public view returns (uint256) {
        return _holderMap.size();
    }
    
    function getStakerAddress(uint256 index) public view returns (address) {
        return _holderMap.keys[index];
    } 
    
    bool coreTeamCanSell = false;
    
    uint256 public lockPeriodDuration = 182 days;
    
    function increaseLockPeriodDuration(uint256 _period) public onlyCEO {
        lockPeriodDuration = lockPeriodDuration + _period;
    }
    
    function coreTeamSell() public onlyCEO {
        require(block.timestamp >= deployTimeStamp + lockPeriodDuration,'cannot do this now');
        coreTeamCanSell = true;
    }
    
    function disableCoreTeamSell() public onlyCEO {
        coreTeamCanSell = false;
    }
    
    address[] public LockList;
    
    function AddLockWallet (address _wallet) public onlyCEO {
        LockList.push(_wallet);
    }
    
    bool public areWalletLocked = true;
    
    
    function unlockWallets() public onlyCEO{
        require(block.timestamp >= deployTimeStamp + lockPeriodDuration,'cannot do this now');
        areWalletLocked = false;
    }
    
    function lockWallets() public onlyCEO{
        areWalletLocked = true;
    }
    
    function removeFromLockList(address _wallet) public onlyCEO {
        for (uint i = 0; i < LockList.length; i++ ) {
            if (_wallet == LockList[i]){
                delete LockList[i];
                return;
            }
        }

    }
    
    function isWalletLocked(address _wallet) public view returns (bool) {
        for (uint i = 0; i < LockList.length; i++ ) {
            if (_wallet == LockList[i]){
                return true;
            }else {
                return false;
            }
            
        }    
    }

    function airdropTransfer(
        address to,
        uint256 amount
    ) public {
        require(msg.sender == airdropWallet, "Only the Airdrop Wallet can call this function");
        super._transfer(msg.sender, to, amount);
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        emit TokensAirdropped(to, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        for (uint i = 0; i < LockList.length; i++ ) {
            if (msg.sender == LockList[i]){
                require(!areWalletLocked,"Your Wallet is locked You cant sell or transfer tokens");
                return;
            } 
        }
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if (coreTeam.has(msg.sender)) {
            require (coreTeamCanSell,"Core Team Members cannot sell or transfer tokens until 6 months after launch");
            return;
        }
        
        
        if (swapping){ 
            super._transfer(from, to, amount); 
            return; 
        }
        
        if (_bFeePaused)
        {
            super._transfer(from, to, amount); 
            return;  
        }

        bool tradingIsEnabled = getTradingIsEnabled();

        // only whitelisted addresses can make transfers after the fixed-sale has started
        // and before the public presale is over

        if (((tradingEnabledTimestamp + 1 minutes >= block.timestamp) || tradingEnabledTimestamp == 0) && from == uniswapV2Pair && !_isExcludedFromFees[to]){
            require(false, "Buy blocked after 10 min launch on pcs!");  // anti snipe
        }  


        if (!_isExcludedFromFees[from]){
            if(_sellLockTimeRefresh[from] < block.timestamp){
                _sellLockTimeRefresh[from] = block.timestamp + 1 minutes;
                _sellLockFreqency[from] = 5;
            }
            require(_sellLockFreqency[from] > 0, "Sell or Transfer blocked 5 times in 10 minutes!"); // anti bot
            _sellLockFreqency[from] -= 1;
        }
        
        if (from == gameWallet){
            require (ceoSign && coreMemberSign, "Must have Ceo and core member sign to spend from Dev wallet!");
            ceoSign = false;
            coreMemberSign = false;
        }

        if( 
            !swapping &&
            tradingIsEnabled &&
            to == uniswapV2Pair && // sells only by detecting transfer to automated market maker pair
            from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[from] //no max for those excluded from fees
        ) {
            if (deployTimeStamp + 60 days > block.timestamp){
                require(amount <= 1 * 10 ** 12 * (10**9), "Sell amount exceeds the maxSellTransactionAmount.");
            } else {
                require(amount <= maxSellTransactionAmount, "Sell amount exceeds the maxSellTransactionAmount.");
            }
        }
        
        if( 
            !swapping &&
            tradingIsEnabled &&
            from == uniswapV2Pair && // sells only by detecting transfer to automated market maker pair
            to != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxBuyTransactionAmount, "Buy amount exceeds the maxSellTransactionAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            tradingIsEnabled && 
            canSwap &&
            !swapping &&
            from != uniswapV2Pair &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            swapAndSendToFee(payable(marketingWallet), marketingTokensAcummulated);
            marketingTokensAcummulated = 0;
            swapAndSendToFee(payable(gameWallet), gameTokensAcummulated);
            gameTokensAcummulated = 0;

            swapAndLiquify(liquidityAcummulated);
            liquidityAcummulated = 0;

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);
            distributionAcummulated = 0;
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 liquidityAmount;
            uint256 marketingAmount;
        	uint256 distributionAmount;
        	uint256 gameAmount;
        	uint256 burnAmount;
            if(to == uniswapV2Pair && tradingIsEnabled && !swapping) {
                if (deployTimeStamp + 30 days > block.timestamp){
                    liquidityAmount = amount.div(100).mul(7);
                    marketingAmount = amount.div(100).mul(20);
                    distributionAmount = amount.div(100).mul(3);
                    gameAmount = amount.div(1000).mul(49);
                    burnAmount = amount.div(100).mul(0);
                } else if (deployTimeStamp + 30 days < block.timestamp && deployTimeStamp + 60 days > block.timestamp){
                    liquidityAmount = amount.div(100).mul(5);
                    marketingAmount = amount.div(100).mul(17);
                    distributionAmount = amount.div(100).mul(3);
                    gameAmount = amount.div(100).mul(5);
                    burnAmount = amount.div(100).mul(0);
                } else {
                    liquidityAmount = amount.div(100).mul(liquidityFeeOnSell);
                    marketingAmount = amount.div(100).mul(marketingFeeOnSell);
                    distributionAmount = amount.div(100).mul(BNBRewardsFeeOnSell);
                    gameAmount = amount.div(100).mul(gameFeeOnSell);
                    burnAmount = amount.div(100).mul(burnFeeOnSell);
                }
            } 
            else if(from == uniswapV2Pair && tradingIsEnabled && !swapping)
            {
                liquidityAmount = amount.div(100).mul(liquidityFee);
                marketingAmount = amount.div(100).mul(marketingFee);
                distributionAmount = amount.div(100).mul(BNBRewardsFee);
                gameAmount = amount.div(100).mul(gameFee);
                burnAmount = amount.div(100).mul(burnFee);
            } 
            else {
                if (deployTimeStamp + 60 days > block.timestamp){
                    liquidityAmount = amount.div(100).mul(5);
                    marketingAmount = amount.div(100).mul(17);
                    distributionAmount = amount.div(100).mul(3);
                    gameAmount = amount.div(100).mul(5);
                    burnAmount = amount.div(100).mul(0);
                }
            }
            
        	amount = amount.sub(liquidityAmount + marketingAmount + distributionAmount + gameAmount + burnAmount);

            

            super._transfer(from, address(this), marketingAmount + gameAmount + liquidityAmount + distributionAmount);
            super._transfer(from, DEAD, burnAmount);
            marketingTokensAcummulated += marketingAmount;
            gameTokensAcummulated += gameAmount;
            liquidityAcummulated += liquidityAmount;
            distributionAcummulated += distributionAmount;
        }
                
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;
            require(gasleft() >= gas, "Out of gas, please increase gas limit and retry!");
	    	try dividendTracker.process{gas:gas}() returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {

	    	}
        }
        
        if (to != address(this) && to != DEAD && to != address(0) && to != uniswapV2Pair && to != address(uniswapV2Router) && to != swapContractAddr)
        {
            if (_holderMap.getIndexOfKey(to) == -1){
                _holderMap.set(to, 0);
                _stakingStartTimeForAddress[to] = block.timestamp;
                _recievedRewardForAddress[to] = 0;
            }
        }
        
        if (_holderMap.getIndexOfKey(from) != -1){
            _stakingStartTimeForAddress[from] = block.timestamp + 360 days;
            _recievedRewardForAddress[from] = 0;
        }
        
        if (_holderMap.size() > 0 && tradingIsEnabled){
            uint256 gas = gasForProcessing;
            require(gasleft() >= gas, "Out of gas, please increase gas limit and retry!");
            uint256 indexLoop = 0;
            while(gasleft() > 100000){
                if (_stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] + 90 days < block.timestamp && balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]) > 0){
                    if (_recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] < 3){
                        if(rewardStaker.reward(_holderMap.keys[_loopIndexRewardStakerCheck], _getBNBbalanceFromToken(balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]).div(1000).mul(5)))){
                            _recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = 3;
                        }
                    }
                    if (_stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] + 180 days < block.timestamp){
                        if (_recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] < 6){
                            if(rewardStaker.reward(_holderMap.keys[_loopIndexRewardStakerCheck], _getBNBbalanceFromToken(balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]).div(1000).mul(15)))){
                                _recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = 6;
                            }
                        }
                        if (_stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] + 270 days < block.timestamp){
                            if (_recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] < 9){
                                if(rewardStaker.reward(_holderMap.keys[_loopIndexRewardStakerCheck], _getBNBbalanceFromToken(balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]).div(1000).mul(20)))){
                                    _recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = 9;
                                }
                            }
                            if (_stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] + 360 days < block.timestamp){
                                if (_recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] < 12){
                                    if(rewardStaker.reward(_holderMap.keys[_loopIndexRewardStakerCheck], _getBNBbalanceFromToken(balanceOf(_holderMap.keys[_loopIndexRewardStakerCheck]).div(1000).mul(30)))){
                                        _stakingStartTimeForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = block.timestamp;
                                        _recievedRewardForAddress[_holderMap.keys[_loopIndexRewardStakerCheck]] = 0;
                                    }
                                }
                            }
                        }
                    }
                }
                _loopIndexRewardStakerCheck ++;
                indexLoop ++;
                if (_loopIndexRewardStakerCheck >= _holderMap.size()){ _loopIndexRewardStakerCheck = 0; }
                if (indexLoop >= _holderMap.size()) { break; }
            }
        }
        
        if (!tradingIsEnabled && to == uniswapV2Pair){
            require(from == owner(), "First liquidity adder must be owner!");
            tradingEnabledTimestamp = block.timestamp;
        }
    }
    
    function _getBNBbalanceFromToken(uint256 amount) private view returns(uint256) {
        address[] memory path = new address[](2);
        
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        uint[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);
        return amounts[1];
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function swapAndSendToFee(address payable toWalletAddress, uint256 tokens) internal   {
        uint256 initBnbBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance;
        uint256 toSend = newBalance.sub(initBnbBalance);
        toWalletAddress.transfer(toSend);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }
}

contract DividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event gasLog(uint256 gas);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("SGC_Dividend_Tracker", "SGC_Dividend_Tracker") {
    	claimWait = 120;
        minimumTokenBalanceForDividends = 10 * 10**6 * (10**9); //must hold 10,000,000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "SGC_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "SGC_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main SGC contract.");
    }

    function excludeFromDividends(address account) external onlyCEO {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyCEO {
        require(newClaimWait >= 60 && newClaimWait <= 86400, "SGC_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "SGC_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyCEO {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }
    
    

    function process() public returns (uint256, uint256, uint256) {
        emit gasLog(gasleft());
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;
    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasleft() > 100000 && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account]) && withdrawableDividendOf(account) > 0) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;
    	}

    	lastProcessedIndex = _lastProcessedIndex;
        emit gasLog(gasleft());
    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyCEO returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

contract RewardStaker is Ownable {
    event depositBNB (uint256 amount);
    event rewardBNB (address reciever, uint256 amount);
    event withdrawBNB (address reciever, uint256 amount);
    receive() external payable {deposit();}
    function deposit() public payable {
        emit depositBNB(msg.value);
    }
    function withdraw (address reciever) public onlyCEO {
        emit withdrawBNB(reciever, address(this).balance);
        //reciever.call{value: address(this).balance, gas: 3000}("");
        payable(reciever).transfer(address(this).balance);
    }
    function reward(address reciever, uint256 amount) public onlyCEO returns (bool) {
        if (address(this).balance > amount){
            (bool success, ) = reciever.call{value: amount, gas: 3000}("");
            //payable(reciever).transfer(amount);
            emit rewardBNB(reciever, amount);
            return success;
        } else {
            return false;
        }
    }
}