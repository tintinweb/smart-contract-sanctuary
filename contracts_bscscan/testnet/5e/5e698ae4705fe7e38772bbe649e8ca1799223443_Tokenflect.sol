/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// Fair Launch: 8pm UTC, Sept 3rd 2021
// 15%~ Slippage required: 8% ADA Auto-reflect /5% Dev & Marketing Wallet/2% Auto-LP


    // SPDX-License-Identifier: MIT
    
    pragma solidity 0.8.7;

    // IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
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
    
    // IUniswapV2Pair interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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
    
    // IUniswapV2Router01 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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
    
    // IUniswapV2Router02 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
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
    
    abstract contract Context {
        function _msgSender() internal view virtual returns (address payable) {
            return payable(msg.sender);
        }
    
        function _msgData() internal view virtual returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }

    contract Ownable is Context {
        address private _owner;
    
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
        /**
         * @dev Initializes the contract setting the deployer as the initial owner.
         */
        constructor() {
            _owner = _msgSender();
            _transferOwnership(_msgSender());
        }
    
        /**
         * @dev Returns the address of the current owner.
         */
        function owner() public view virtual returns (address) {
            return _owner;
        }
    
        /**
         * @dev Throws if called by any account other than the owner.
         */
        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
    
        /**
         * @dev Leaves the contract without owner. It will not be possible to call
         * `onlyOwner` functions anymore. Can only be called by the current owner.
         *
         * NOTE: Renouncing ownership will leave the contract without an owner,
         * thereby removing any functionality that is only available to the owner.
         */
        function renounceOwnership() public virtual onlyOwner {
            _transferOwnership(address(0));
        }
    
        /**
         * @dev Transfers ownership of the contract to a new account (`newOwner`).
         * Can only be called by the current owner.
         */
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            _transferOwnership(newOwner);
        }
    
        /**
         * @dev Transfers ownership of the contract to a new account (`newOwner`).
         * Internal function without access restriction.
         */
        function _transferOwnership(address newOwner) internal virtual {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }

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
    
    library SafeMathInt {
      function mul(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when multiplying INT256_MIN with -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
    
        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
      }
    
      function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing INT256_MIN by -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && (b > 0));
    
        return a / b;
      }
    
      function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
    
        return a - b;
      }
    
      function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
      }
    
      function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
      }
    }
    
    library SafeMathUint {
      function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
      }
    }
    
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

    interface IBEP20 {
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
    
    contract ERC20 is Context, IBEP20 {
        using SafeMath for uint256;
    
        mapping (address => uint256) private _balances;
    
        mapping (address => mapping (address => uint256)) private _allowances;
    
        uint256 private _totalSupply;
    
        string private _name;
        string private _symbol;
        uint8 private _decimals;
    
        /**
         * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
         * a default value of 18.
         *
         * To select a different value for {decimals}, use {_setupDecimals}.
         *
         * All three of these values are immutable: they can only be set once during
         * construction.
         */
        constructor (string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
            _decimals = 18;
        }
    
        /**
         * @dev Returns the name of the token.
         */
        function name() public view virtual returns (string memory) {
            return _name;
        }
    
        /**
         * @dev Returns the symbol of the token, usually a shorter version of the
         * name.
         */
        function symbol() public view virtual returns (string memory) {
            return _symbol;
        }
    
        /**
         * @dev Returns the number of decimals used to get its user representation.
         * For example, if `decimals` equals `2`, a balance of `505` tokens should
         * be displayed to a user as `5,05` (`505 / 10 ** 2`).
         *
         * Tokens usually opt for a value of 18, imitating the relationship between
         * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
         * called.
         *
         * NOTE: This information is only used for _display_ purposes: it in
         * no way affects any of the arithmetic of the contract, including
         * {IERC20-balanceOf} and {IERC20-transfer}.
         */
        function decimals() public view virtual returns (uint8) {
            return _decimals;
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
        function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
         * - `to` cannot be the zero address.
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
        function _approve(address owner, address spender, uint256 amount) internal virtual {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
    
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    
        /**
         * @dev Sets {decimals} to a value other than the default one of 18.
         *
         * WARNING: This function should only be called from the constructor. Most
         * applications that interact with token contracts will not expect
         * {decimals} to ever change, and may work incorrectly if it does.
         */
        function _setupDecimals(uint8 decimals_) internal virtual {
            _decimals = decimals_;
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
    
    contract Tokenflect is IBEP20, Ownable {
        using SafeMath for uint256;
        
        // General Info
        string  private _NAME     = "Test";
        string  private _SYMBOL   = "TEST";
        uint8   private _DECIMALS = 18;

        IUniswapV2Router02 public uniswapV2Router;
        address public uniswapV2Pair; 

        address public constant TUSDT = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); //BUSD TESTNET
    
        mapping (address => uint256) private _rOwned;
        mapping (address => uint256) private _tOwned;
        mapping (address => mapping (address => uint256)) private _allowances;
    
        mapping (address => bool) private _isExcludedFromFees;
        mapping (address => bool) private _isExcluded;
        address[] private _excluded;
    
        uint256 private constant MAX = ~uint256(0);
        uint256 private _tTotal = 1000000000 * 10**6 * 10**18;
        uint256 private _rTotal = (MAX - (MAX % _tTotal));
        uint256 private _totalReflections;    // Total reflections
        uint256 public  swapTokensAtAmount = 20 * (10**18);
        
        // Test original feature: members and influencers addresses
        mapping (address => int)     private _partners;
        mapping (address => bool)    private _isPartner;
        mapping (address => address) private _holders;
        
        // Token taxes 
        uint256 public rewardsFee                  = 2;
        uint256 public reflectionFee               = 2;
        uint256 public liquidityFee                = 2;
        uint256 public marketingFee                = 1;
        uint256 public burnFee                     = 1;
        uint256 public totalFees                   = 8;
        uint256 public sellFee                     = 7;
        
        uint256 private origin_rewardsFee          = rewardsFee;
        uint256 private origin_reflectionFee       = reflectionFee;
        uint256 private origin_liquidityFee        = liquidityFee;
        uint256 private origin_marketingFee        = marketingFee;
        uint256 private origin_burnFee             = burnFee;
        uint256 private origin_totalFees           = totalFees;
        uint256 private origin_sellFee             = sellFee;
    
        // addresses
        address payable public _burnWalletAddress      = payable(0x000000000000000000000000000000000000dEaD); // Burn address used to burn a portion of tokens
        address payable public _supplyWalletAddress    = payable(0x5407Da105D55828D2Ca2d0b6C1589eB14be93eea); // Wallet Supply-team (là où nous enverrons les tokens à la création du smartcontract avant d'airdrop la v2)
        address payable public _partnerWalletAddress   = payable(0x353d157171876c5CA1C985523A01618E476e6A4A); // Wallet Partenaires "générique" (quand nous n'avons pas add influenceur un acheteur pour le link à un partenaire, pour les 1,5% partenaires en BUSD et 1,5% partenaires en token)
        address payable public _teamWalletAddress      = payable(0x8eD9888A266704d6E01Ccc2381E62DA873b99A34); // Wallet Team (pour les 1% de transaction fees "Team"
        address payable public _algoWalletAddress      = payable(0xf5D5B22Bb7DDed4453c90744B66471d6602F1b3E); // Wallet Algo (pour les 7% transaction fees sur price impact > 2%)
        
        uint256 public blacklistDeadline = 2 days; 
        mapping(address => bool) public isBlacklisted;
        mapping(address => uint) public isBlacklistedTo;
        
        bool public tradingEnabled;
        bool public swapAndLiquifyEnabled;
        bool public currentlySwapping;
    
    
        // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
        // could be subject to a maximum transfer amount
        mapping (address => bool) public automatedMarketMakerPairs;
    
        event ExcludeFromFees(address indexed account, bool isExcluded);
        event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
        event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
        event SwapAndLiquifyEnabledUpdated(bool enabled);
        event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
        event SwapAndSendDividends(address to, uint256 tokens);
        event SwapAndSendToTeam(address to, uint256 tokens);
        event SwapAndSendToAlgo(address to, uint256 tokens);
        event Watch2(string _msg, uint256 tax);
        event Watch3(string _msg, bool _isTrue);

        modifier lockSwapping {
            currentlySwapping = true;
            _;
            currentlySwapping = false;
        }
        
        constructor() {
            // Mint the total reflection balance to the deployer of this contract
            _rOwned[_msgSender()] = _rTotal;
            

            IUniswapV2Router02 _uniswapV2Router =  IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

            // Create a uniswap pair for this new token
            address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), TUSDT);
            
            uniswapV2Router = _uniswapV2Router;
            uniswapV2Pair = _uniswapV2Pair;
            
            automatedMarketMakerPairs[uniswapV2Pair] = true;
            tradingEnabled = true;
    
            // exclude from paying fees or having max transaction amount
            excludeFromFees(owner(), true);
            excludeFromFees(address(this), true);
            excludeFromFees(_supplyWalletAddress, true);
            excludeFromFees(_partnerWalletAddress, true);
            excludeFromFees(_teamWalletAddress, true);
            excludeFromFees(_algoWalletAddress, true);
            
            emit Transfer(address(0), _msgSender(), _tTotal);
        }
    
        function name() public view returns (string memory) {
            return _NAME;
        }
        
        function symbol() public view returns (string memory) {
            return _SYMBOL;
        }
        
        function decimals() public view returns (uint8) {
            return _DECIMALS;
        }
        
        function totalSupply() public view override returns (uint256) {
            return _tTotal;
        }
        
        function balanceOf(address account) public view override returns (uint256) {
            if (_isExcluded[account]) return _tOwned[account];
            return tokenFromReflection(_rOwned[account]);
        }
        
        function transfer(address recipient, uint256 amount) public override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        
        function allowance(address owner, address spender) public view override returns (uint256) {
            return _allowances[owner][spender];
        }
        
        function approve(address spender, uint256 amount) public override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }
        
        function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TOKEN20: transfer amount exceeds allowance"));
            return true;
        }
        
        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
            return true;
        }
        
        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TOKEN20: decreased allowance below zero"));
            return true;
        }

        function isExcludedFromReward(address account) public view returns (bool) {
            return _isExcluded[account];
        }
    
        function deliver(uint256 tAmount) public {
            address sender = _msgSender();
            require(!_isExcluded[sender], "Excluded addresses cannot call this function");
            (uint256 rAmount,,,,) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rTotal = _rTotal.sub(rAmount);
            _totalReflections = _totalReflections.add(tAmount);
        }
        
        function getTotalReflections() external view returns (uint256) {
            return _totalReflections;
        }
    
        function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
            require(tAmount <= _tTotal, "Amount must be less than supply");
            if (!deductTransferFee) {
                (uint256 rAmount,,,,) = _getValues(tAmount);
                return rAmount;
            } else {
                (,uint256 rTransferAmount,,,) = _getValues(tAmount);
                return rTransferAmount;
            }
        }
    
        receive() external payable {}
    
        function withdrawBNB(uint256 amount) public onlyOwner {
            if(amount == 0) payable(owner()).transfer(address(this).balance);
            else payable(owner()).transfer(amount);
        }
        
        function withdrawForeignToken(address token) public onlyOwner {
            require(address(this) != address(token), "Cannot withdraw native token");
            IBEP20(address(token)).transfer(msg.sender, IBEP20(token).balanceOf(address(this)));
        }
        
        function transferBNBToAddress(address payable recipient, uint256 amount) private {
            recipient.transfer(amount);
        }
    
        function excludeFromFees(address account, bool excluded) public onlyOwner {
            require(_isExcludedFromFees[account] != excluded, "ADAFlect: Account is already the value of 'excluded'");
            _isExcludedFromFees[account] = excluded;
    
            emit ExcludeFromFees(account, excluded);
        }
    
        function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
            for(uint256 i = 0; i < accounts.length; i++) {
                _isExcludedFromFees[accounts[i]] = excluded;
            }
    
            emit ExcludeMultipleAccountsFromFees(accounts, excluded);
        }
        
        function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
            require(pair != uniswapV2Pair, "ADAFlect: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
    
            _setAutomatedMarketMakerPair(pair, value);
        }
        
        function setTrading(bool _enabled) public onlyOwner {
            tradingEnabled = _enabled;
        }
        
        function setTokenToSwap(uint256 _swapTokensAtAmount) external onlyOwner {
            swapTokensAtAmount = _swapTokensAtAmount;
        }
    
        function blacklistAddress(address account, bool value, uint256 deadline) public onlyOwner{
            if (value) {
                require(block.timestamp < deadline, " The ability to blacklist accounts has been disabled.");
            }
            isBlacklisted[account]   = value;
            isBlacklistedTo[account] = deadline;
        }
        
        function blacklistMultipleAccounts(address[] calldata accounts, bool[] calldata value, uint256[] calldata deadlines) public onlyOwner {
            require(accounts.length == value.length && value.length == deadlines.length, "Should be the same length.");
            
            for(uint256 i = 0; i < accounts.length; i++) {
                if (value[i]) {
                require(block.timestamp < deadlines[i], "The ability to blacklist accounts has been disabled.");
                }
                isBlacklisted[accounts[i]]   = value[i];
                isBlacklistedTo[accounts[i]] = deadlines[i];
            }
        }

        function whitelistAddress(address account) public onlyOwner {
            isBlacklisted[account]   = false;
            isBlacklistedTo[account] = 0;
        }
    
        function updateUniswapV2Router(address newAddress) public onlyOwner {
            require(newAddress != address(uniswapV2Router), "The router already has that address");
            uniswapV2Router = IUniswapV2Router02(newAddress);
            address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
            uniswapV2Pair = _uniswapV2Pair;
        }

        function _setAutomatedMarketMakerPair(address pair, bool value) private {
            require(automatedMarketMakerPairs[pair] != value, "ADAFlect: Automated market maker pair is already set to that value");
            automatedMarketMakerPairs[pair] = value;
    
            emit SetAutomatedMarketMakerPair(pair, value);
        }
    
        function isExcludedFromFees(address account) public view returns(bool) {
            return _isExcludedFromFees[account];
        }
 
        function _approve(address owner, address spender, uint256 amount) private {
            require(owner != address(0), "TOKEN20: approve from the zero address");
            require(spender != address(0), "TOKEN20: approve to the zero address");
        
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
        
        function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
            (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
            return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
        }
    
        function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
            uint256 tFee = tAmount.mul(totalFees).div(100);
            uint256 tTransferAmount = tAmount.sub(tFee);
            return (tTransferAmount, tFee);
        }
    
        function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
            uint256 rAmount = tAmount.mul(currentRate);
            uint256 rFee = tFee.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rFee);
            return (rAmount, rTransferAmount, rFee);
        }
    
        function _getRate() private view returns(uint256) {
            (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
            return rSupply.div(tSupply);
        }
    
        function _getCurrentSupply() private view returns(uint256, uint256) {
            uint256 rSupply = _rTotal;
            uint256 tSupply = _tTotal;      
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
                rSupply = rSupply.sub(_rOwned[_excluded[i]]);
                tSupply = tSupply.sub(_tOwned[_excluded[i]]);
            }
            if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
            return (rSupply, tSupply);
        }
        
        function _takeLiquidity(uint256 tLiquidity) private {
            uint256 currentRate =  _getRate();
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }

        function _reflectFee(uint256 rFee, uint256 tFee) private {
            _rTotal = _rTotal.sub(rFee);
            _totalReflections = _totalReflections.add(tFee);
        }
        
        function _checkBlacklist(address _blacklisted) private {
            if(isBlacklisted[_blacklisted] && isBlacklistedTo[_blacklisted] < block.timestamp && isBlacklistedTo[_blacklisted] != 0){
                isBlacklisted[_blacklisted] = false;
                isBlacklistedTo[_blacklisted] = 0;
            } 
        }
        
        function updateFee(uint256 _rewardsFee, uint256 _reflectionFee, uint256 _liquidityFee, uint256 _marketingFee, uint256 _burnFee, uint256 _sellFee) onlyOwner() public{
            rewardsFee                  = _rewardsFee;
            reflectionFee               = _reflectionFee;
            liquidityFee                = _liquidityFee;
            marketingFee                = _marketingFee;
            burnFee                     = _burnFee;
            sellFee                     = _sellFee;
    
            totalFees                   = rewardsFee.add(reflectionFee).add(liquidityFee).add(marketingFee).add(burnFee);
        
            origin_rewardsFee          = rewardsFee;
            origin_reflectionFee       = reflectionFee;
            origin_liquidityFee        = liquidityFee;
            origin_marketingFee        = marketingFee;
            origin_burnFee             = burnFee;
            origin_totalFees           = totalFees;
            origin_sellFee             = sellFee;
        }
        
        function removeAllFees() private {
            if(rewardsFee == 0 && reflectionFee ==  0 && liquidityFee ==  0 && marketingFee == 0 && burnFee ==  0 && sellFee ==  0 && totalFees == 0) return;
        
            origin_rewardsFee          = rewardsFee;
            origin_reflectionFee       = reflectionFee;
            origin_liquidityFee        = liquidityFee;
            origin_marketingFee        = marketingFee;
            origin_burnFee             = burnFee;
            origin_totalFees           = totalFees;
            origin_sellFee             = sellFee;
        
            rewardsFee                 = 0;
            reflectionFee              = 0;
            liquidityFee               = 0;
            marketingFee               = 0;
            burnFee                    = 0;
            totalFees                  = 0;
            sellFee                    = 0;
        }
        
        function restoreAllFees() private {
            rewardsFee                  = origin_rewardsFee;
            reflectionFee               = origin_reflectionFee;
            liquidityFee                = origin_liquidityFee;
            marketingFee                = origin_marketingFee;
            burnFee                     = origin_burnFee;
            sellFee                     = origin_sellFee;
            totalFees                   = origin_totalFees;
        }
        
        function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
            require(rAmount <= _rTotal, "Amount must be less than total reflections");
            uint256 currentRate =  _getRate();
            return rAmount.div(currentRate);
        }
        
        function excludeFromReward(address account) external onlyOwner() {
            require(!_isExcludedFromFees[account], "Account is already excluded");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcludedFromFees[account] = true;
            _excluded.push(account);
        }

        function includeInReward(address account) external onlyOwner() {
            require(_isExcludedFromFees[account], "Account is already included");
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOwned[account] = 0;
                    _isExcludedFromFees[account] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
        
        function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
            swapAndLiquifyEnabled = _enabled;
            emit SwapAndLiquifyEnabledUpdated(_enabled);
        }
    
        function _transfer(
            address from,
            address to,
            uint256 amount
        ) internal {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "ERC20: transfer amount must be greater than zero");
            require(!isBlacklisted[from] && !isBlacklisted[to], "Is blacklisted");
            
            if(from != owner() && to != owner()) {
                require(tradingEnabled , "Is trading Disabled.");
            }
            
            // Buy
            if(from == uniswapV2Pair){
                _checkBlacklist(to);
                _checkBlacklist(from);
            }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if( canSwap && 
                !currentlySwapping &&
                !automatedMarketMakerPairs[from] &&
                from != owner() &&
                to != owner() &&
                swapAndLiquifyEnabled) 
            {
                // 2% liquidity
                uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
                swapAndLiquify(swapTokens);
                emit Watch2("isSwapping - swap tokens = ", swapTokens);
                
                // 2% BUSD rewards for partners and holders
                uint256 dividendTokens = contractTokenBalance.mul(reflectionFee).div(totalFees);
                swapAndSendDividends(dividendTokens);
                emit Watch2("isSwapping -  swapAndSendDividends = ", dividendTokens);
                
                // 1 % team 
                uint256 teamTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
                swapAndSendToFee(teamTokens);
                emit Watch2("isSwapping - swap teamTokens = ", teamTokens);

                // 7% algo
                uint256 sellTokens = contractTokenBalance.mul(sellFee).div(totalFees);
                swapAndSendToAlgo(sellTokens);
                emit Watch2("isSwapping - swap sellTokens = ", sellTokens);
            }  
            
            // if any account belongs to _isExcludedFromFee account then remove the fee
            bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);
            emit Watch3("takeFee = ", takeFee);

            
            // Remove fees completely from the transfer if either wallet are excluded
            if (!takeFee) {
                removeAllFees();
                emit Watch3("takeFee removeAllFees = ", takeFee);
            }
            
            // if sell 
            bool isTaxed = false;
            if (takeFee && to == uniswapV2Pair) {
                if(_priceImpactTax(amount)){
                    totalFees = totalFees.add(sellFee);
                    isTaxed   = true;
                    
                    emit Watch3("isTaxed = ", isTaxed);
                }
                    
                // blacklist for 2 days 
                isBlacklisted[from] = true; 
                isBlacklistedTo[from] = block.timestamp.add(blacklistDeadline);
                    
                 emit Watch3("isBlacklisted = ", isBlacklisted[from]);
            }
            
            //transfer amount, it will take tax, burn, liquidity fee
            emit Watch2("total fees = ", totalFees);
            
            _tokenTransfer(from, to, amount, isTaxed);
 
            // If we removed the fees for this transaction, then restore them for future transactions
            if (!takeFee) {
                restoreAllFees();
            }
            
            // If this transaction was a sell, and we took a fee, restore the fee amount back to the original buy amount
            if (takeFee && automatedMarketMakerPairs[to]) {
                totalFees = origin_totalFees;
                emit Watch2("total fees = ", totalFees);
            }
        }
        
        //this method is responsible for taking all fee, if takeFee is true
        function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool isTaxed) private {
            // Calculate the values required to execute a transfer
            (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
            (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, _getRate());
            
            emit Watch2("tFee = ", tFee);
            emit Watch2("tTransferAmount = ", tTransferAmount);
            
            // Transfer from sender to recipient
    		if (_isExcluded[sender]) {
    		    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    		}
    		_rOwned[sender] = _rOwned[sender].sub(rAmount);
    		
    		if (_isExcluded[recipient]) {
                _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    		}
    		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
    		
    		if (tFee > 0) {
    	    	uint256 tPortion = tFee.div(totalFees);
    	    	uint256 tDemiPortion = tPortion.div(2);
    	    	
                emit Watch2("tPortion = ", tPortion);
                
                // Burn some of the taxed tokens 
                _burnTokens(tPortion);
                
                // Reflect some of the taxed tokens 
                _sendToPartner(tPortion.add(tDemiPortion), sender);
                _sendToHolder(tDemiPortion, sender);
        		_reflectTokens(tPortion.mul(2));
                
                // Take the rest of the taxed tokens for the other functions
                _takeTokens(tFee.sub(tPortion).sub(tPortion).sub(tPortion), isTaxed);
    		}
                
            // Emit an event 
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function burn(uint256 _value) external onlyOwner() {
    		uint256 rFee = _value.mul(_getRate());
            _rOwned[_burnWalletAddress] = _rOwned[_burnWalletAddress].add(rFee);
            if(_isExcludedFromFees[_burnWalletAddress]) {
                _tOwned[_burnWalletAddress] = _tOwned[_burnWalletAddress].add(_value);
            }
    	}
    
        function _burnTokens(uint256 tFee) private {
            uint256 rFee = tFee.mul(_getRate());
            _rOwned[_burnWalletAddress] = _rOwned[_burnWalletAddress].add(rFee);
            if(_isExcludedFromFees[_burnWalletAddress]) {
                _tOwned[_burnWalletAddress] = _tOwned[_burnWalletAddress].add(tFee);
            }
            
            emit Transfer(tx.origin, _burnWalletAddress, tFee);
        }
    
        function _reflectTokens(uint256 tFee) private {
            uint256 rFee = tFee.mul(_getRate());
            _rTotal = _rTotal.sub(rFee);
            _totalReflections = _totalReflections.add(tFee);
            
            emit Watch2("_totalReflections = ", _totalReflections);
        }
        
        function _sendToPartner(uint256 tPartner, address sender) private {
            uint256 currentRate = _getRate();
            uint256 rPartner = tPartner.mul(currentRate);
        
            //NOSTA: if user is a member, send fees to patner - else, send to partner wallet
            address feesReceiver = _partnerWalletAddress;
            if (isMember(tx.origin)) feesReceiver = _holders[tx.origin];
            
            _rOwned[feesReceiver] = _rOwned[feesReceiver].add(rPartner);
            _tOwned[feesReceiver] = _tOwned[feesReceiver].add(tPartner);
            
            emit Transfer(sender, feesReceiver, tPartner);
        }
        
        function _sendToHolder(uint256 tHolder, address sender) private {
            uint256 currentRate = _getRate();
            uint256 rHolder = tHolder.mul(currentRate);
            
            _rOwned[sender] = _rOwned[sender].add(rHolder);
            _tOwned[sender] = _tOwned[sender].add(tHolder);
            
            emit Transfer(sender, sender, tHolder);
        }
        
        function reflect(uint256 tAmount) public {
            require(!_isExcludedFromFees[_msgSender()], "Excluded addresses cannot call this function");
            (uint256 rAmount,,,,) = _getValues(tAmount);
            _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
            _rTotal = _rTotal.sub(rAmount);
            _totalReflections = _totalReflections.add(tAmount);
        }
        
        function _takeTokens(uint256 tTakeAmount, bool isTaxed) private {
            emit Watch3("isTaxed = ", isTaxed);
            
            uint256 currentRate = _getRate();
            uint256 rTakeAmount = tTakeAmount.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rTakeAmount);
            if(_isExcluded[address(this)]) {
                _tOwned[address(this)] = _tOwned[address(this)].add(tTakeAmount);
            }

            emit Transfer(tx.origin, address(this), tTakeAmount);
        }
        
        function swapAndLiquify() public onlyOwner lockSwapping {
            uint256 contractTokenBalance = balanceOf(address(this));
            
            // 2% liquidity
            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);
    
            // 2% dividendTracker BUSD rewards for partners and holders
            uint256 dividendTokens = contractTokenBalance.mul(reflectionFee).div(totalFees);
            swapAndSendDividends(dividendTokens);
    
            // 1 % team 
            uint256 teamTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(teamTokens);
    
            // 7% algo
            uint256 sellTokens = contractTokenBalance.mul(sellFee).div(totalFees);
            swapAndSendToAlgo(sellTokens);
        }
        
        function swapAndSendDividends(uint256 tokens) private lockSwapping {
            uint256 initialBUSDBalance = IBEP20(TUSDT).balanceOf(address(this));

            swapTokensForBUSD(tokens);
            
            uint256 newBalance = (IBEP20(TUSDT).balanceOf(address(this))).sub(initialBUSDBalance);
            bool success = IBEP20(TUSDT).transfer(address(_partnerWalletAddress), newBalance);
            
            if(success) emit SwapAndSendDividends(_partnerWalletAddress, newBalance);
        }
        
        function swapAndSendToFee(uint256 tokens) private  lockSwapping {
            uint256 initialBUSDBalance = IBEP20(TUSDT).balanceOf(address(this));

            swapTokensForBUSD(tokens);
            
            uint256 newBalance = (IBEP20(TUSDT).balanceOf(address(this))).sub(initialBUSDBalance);
            bool success = IBEP20(TUSDT).transfer(_teamWalletAddress, newBalance);
            
            if(success) emit SwapAndSendToTeam(_teamWalletAddress, newBalance);
        }
        
        function swapAndSendToAlgo(uint256 tokens) private  lockSwapping {
            uint256 initialBUSDBalance = IBEP20(TUSDT).balanceOf(address(this));

            swapTokensForBUSD(tokens);
            
            uint256 newBalance = (IBEP20(TUSDT).balanceOf(address(this))).sub(initialBUSDBalance);
            bool success = IBEP20(TUSDT).transfer(_algoWalletAddress, newBalance);
            
            if(success) emit SwapAndSendToAlgo(_algoWalletAddress, newBalance);
        }
        
        function swapAndLiquify(uint256 tokens) private lockSwapping {
            // split the contract balance into halves
            uint256 half = tokens.div(2);
            uint256 otherHalf = tokens.sub(half);
    
            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;
    
            // swap tokens for BNB
            swapTokensForBNB(half);
    
            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
    
            // add liquidity to uniswap
            if (newBalance > 0) {
                addLiquidity(otherHalf, newBalance);
                emit SwapAndLiquify(half, newBalance, otherHalf);
            }
        }
        
        /**
         * @notice Swap tokens for BNB storing the resulting BNB in the contract
         */
        function swapTokensForBNB(uint256 tokenAmount) private lockSwapping {
            // Generate the Pancakeswap pair for token/WBNB
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH(); // WETH = WBNB on BSC
    
            _approve(address(this), address(uniswapV2Router), tokenAmount);
    
            // Execute the swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // Accept any amount of BNB
                path,
                address(this),
                block.timestamp.add(300)
            );
        }
        
        /**
         * @notice Swaps BNB for tokens and immedietely burns them
         */
        function swapBNBForTokens(uint256 amount) private lockSwapping {
            // generate the uniswap pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(this);
    
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                0, // Accept any amount of RAINBOW
                path,
                _burnWalletAddress, // Burn address
                block.timestamp.add(300)
            );
        }
    
        /**
         * @notice Adds liquidity to the PancakeSwap V2 LP
         */
        function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
            // Approve token transfer to cover all possible scenarios
            _approve(address(this), address(uniswapV2Router), tokenAmount);
    
            // Adds the liquidity and gives the LP tokens to the owner of this contract
            // The LP tokens need to be manually locked
            uniswapV2Router.addLiquidityETH{value: bnbAmount}(
                address(this),
                tokenAmount,
                0, // Take any amount of tokens (ratio varies)
                0, // Take any amount of BNB (ratio varies)
                owner(),
                block.timestamp.add(300)
            );
        }
        
        function swapTokensForBUSD(uint256 tokenAmount) private lockSwapping {
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            path[2] = TUSDT;
    
            _approve(address(this), address(uniswapV2Router), tokenAmount);
    
            // make the swap
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        
        // returns sorted token addresses, used to handle return values from pairs sorted in this order
        function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
            require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
            (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
            require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
        }

        // fetches and sorts the reserves for a pair
        function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
            (address token0,) = sortTokens(tokenA, tokenB);
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
            (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        }
    
        // Check for price impact before doing transfer
        function _priceImpactTax(uint256 amount) private returns (bool) { 
            (uint _reserveA, uint _reserveB) = getReserves(address(this), TUSDT);
            uint256 _constant = IUniswapV2Pair(uniswapV2Pair).kLast();
            uint256 _market_price = _reserveA.div(_reserveB);

            if (_reserveA == 0 && _reserveB == 0){
                return false;
            }else {
                if(amount >= _reserveA) return false;
                
                uint256 _reserveA_new = _reserveA.sub(amount);
                uint256 _reserveB_new = _constant.div(_reserveA_new);
                
                if(_reserveB >= _reserveB_new) return false;
                uint256 receivedBUSD = _reserveB_new.sub(_reserveB);
            
                uint256 _new_price    = (amount.div(receivedBUSD)).mul(10**18);
                uint256 _delta_price  = _new_price.div(_market_price);

                emit Watch2("_priceImpactTax _delta_price = ", _delta_price);
                return (_delta_price <= 980000000000000000); // 2% de variation
            }
        }
        
        
        /**
         *
         * 
         * addPartner: reference a partner by the owner
         * registerMember: for member to register with their partner address in parameter -> burn amount will be divided by 2 (see changes in function _getTBasics)
         * registerMemberByOwner: owner can register a member in case member has trouble doing it by himself
         * totalMembersForPartner: returns the number of members referenced by a partner address in parameter
         * isMember: checks if address is member, for internal calls
         * getPartnerForMember: returns the partner address for a member sent in parameter
         * 
         * 
         */
        
        function addPartner(address _partner) external onlyOwner {
            require(!_isPartner[_partner], "Address is already registered as partner");
            _isPartner[_partner] = true;
            _holders[_partner] = _partner;
            _partners[_partner] += 1;
        }
        
        function registerMember(address _partner) external {
            require(_isPartner[_partner], "Address is not registered as partner");
            require(!isMember(_msgSender()), "Member already registered");
            _holders[_msgSender()] = _partner;
            _partners[_partner] += 1;
        }
        
        function registerMemberByOwner(address _member, address _partner) external onlyOwner {
            require(_isPartner[_partner], "Address is not registered as partner");
            require(!isMember(_member), "Member already registered");
            _holders[_member] = _partner;
            _partners[_partner] += 1;
        }
        
        function totalMembersForPartner(address _partner) external view returns (int) {
            return _partners[_partner];
        }
    
        function isMember(address _member) private view returns (bool) {
            if (_holders[_member] == address(0)) return false;
            return true;
        }
    
        function getPartnerForMember(address _member) external view returns (address) {
            return _holders[_member];
        }
    	
    }