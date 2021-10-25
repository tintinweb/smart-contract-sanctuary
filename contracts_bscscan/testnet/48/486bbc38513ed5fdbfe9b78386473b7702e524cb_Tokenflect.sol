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
            /// @title Dividend-Paying Token Optional Interface
        /// @author Roger Wu (https://github.com/roger-wu)
        /// @dev OPTIONAL functions for a dividend-paying token contract.
    interface IDividendPayingTokenOptional {
          /// @notice View the amount of dividend in wei that an address can withdraw.
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` can withdraw.
          function withdrawableDividendOfPart(address _owner) external view returns(uint256);
          function withdrawableDividendOfHolder(address _owner) external view returns(uint256);
          /// @notice View the amount of dividend in wei that an address has withdrawn.
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` has withdrawn.
          function withdrawnDividendOfHolder(address _owner) external view returns(uint256);
          function withdrawnDividendOfPart(address _owner) external view returns(uint256);
        
          /// @notice View the amount of dividend in wei that an address has earned in total.
          /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` has earned in total.
          function accumulativeDividendOfHolders(address _owner) external view returns(uint256);
          function accumulativeDividendOfPart(address _owner) external view returns(uint256);
        }
        
        /// @title Dividend-Paying Token Interface
        /// @author Roger Wu (https://github.com/roger-wu)
        /// @dev An interface for a dividend-paying token contract.
    interface IDividendPayingToken {
          /// @notice View the amount of dividend in wei that an address can withdraw.
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` can withdraw.
          function dividendOfHolder(address _owner) external view returns(uint256);
          function dividendOfPart(address _owner) external view returns(uint256);
        
          /// @notice Distributes ether to token holders as dividends.
          /// @dev SHOULD distribute the paid ether to token holders as dividends.
          ///  SHOULD NOT directly transfer ether to token holders in this function.
          ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
          function distributeDividends() external payable;
        
          /// @notice Withdraws the ether distributed to the sender.
          /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
          ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
          function withdrawDividendOfPart() external;
          function withdrawDividendOfHolder() external;
        
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
        
        /// @title Dividend-Paying Token
        /// @author Roger Wu (https://github.com/roger-wu)
        /// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
        ///  to token holders as dividends and allows token holders to withdraw their dividends.
        ///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
    contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional {
          using SafeMath for uint256;
          using SafeMathUint for uint256;
          using SafeMathInt for int256;
        
          // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
          // For more discussion about choosing the value of `magnitude`,
          //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
          uint256 constant internal magnitude = 2**128;
        
          uint256 internal magnifiedDividendPerShareHolders;
          uint256 internal magnifiedDividendPerSharePart;
          uint256 internal lastAmount;
        
          address public immutable BUSD = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); //BUSD TESTNET
          //address public immutable BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        
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
        
          constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
        
          receive() external payable {}
        
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
            uint256 supply_parts    = (totalSupply().mul(2)).div(3);
            uint256 supply_holders  = totalSupply().div(3);
        
            uint256 amount_parts    = (msg.value.mul(2)).div(3);
            uint256 amount_holders  = msg.value.div(3);
        
            if (msg.value > 0) {
              magnifiedDividendPerShareHolders = magnifiedDividendPerShareHolders.add(
                (amount_holders).mul(magnitude) / supply_holders
              );
              magnifiedDividendPerSharePart    = magnifiedDividendPerSharePart.add(
                (amount_parts).mul(magnitude) / supply_parts
              );
        
              emit DividendsDistributed(msg.sender, msg.value);
        
              totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
            }
          }
        
        
          function distributeBusdDividends(uint256 amount, bool _isPart) public {
            require(totalSupply() > 0);
            uint256 supply_parts    = (totalSupply().mul(2)).div(3);
            uint256 supply_holders  = totalSupply().div(3);
        
            uint256 amount_parts    = (amount.mul(2)).div(3);
            uint256 amount_holders  = amount.div(3);
        
            if (amount > 0) {
                if(_isPart){
                    magnifiedDividendPerSharePart = magnifiedDividendPerSharePart.add(
                    (amount_parts).mul(magnitude) / supply_parts
                    );
                }else {
                    magnifiedDividendPerShareHolders = magnifiedDividendPerShareHolders.add(
                    (amount_holders).mul(magnitude) / supply_holders
                    );
                }
        
              emit DividendsDistributed(msg.sender, amount);
        
              totalDividendsDistributed = totalDividendsDistributed.add(amount);
            }
          }
        
          /// @notice Withdraws the ether distributed to the sender.
          /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
          function withdrawDividendOfHolder() public virtual override {
            _withdrawDividendOfHolder(_msgSender());
          }
        
          /// @notice Withdraws the ether distributed to the sender.
          /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
          function _withdrawDividendOfHolder(address payable user) internal returns (uint256) {
            uint256 _withdrawableDividend = withdrawableDividendOfHolder(user);
            if (_withdrawableDividend > 0) {
              withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
              emit DividendWithdrawn(user, _withdrawableDividend);
              bool success = ERC20(BUSD).transfer(user, _withdrawableDividend);
        
              if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
              }
        
              return _withdrawableDividend;
            }
        
            return 0;
          }
        
          /// @notice Withdraws the ether distributed to the sender.
          /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
          function withdrawDividendOfPart() public virtual override {
            _withdrawDividendOfPart(_msgSender());
          }
        
          /// @notice Withdraws the ether distributed to the sender.
          /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
          function _withdrawDividendOfPart(address payable user) internal returns (uint256) {
            uint256 _withdrawableDividend = withdrawableDividendOfPart(user);
            if (_withdrawableDividend > 0) {
              withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
              emit DividendWithdrawn(user, _withdrawableDividend);
              bool success = ERC20(BUSD).transfer(user, _withdrawableDividend);
        
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
          function dividendOfHolder(address _owner) public view override returns(uint256) {
            return withdrawableDividendOfHolder(_owner);
          }
        
        /// @notice View the amount of dividend in wei that an address can withdraw.
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` can withdraw.
          function dividendOfPart(address _owner) public view override returns(uint256) {
            return withdrawableDividendOfPart(_owner);
          }
        
          /// @notice View the amount of dividend in wei that an address can withdraw.
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` can withdraw.
          function withdrawableDividendOfHolder(address _owner) public view override returns(uint256) {
            return accumulativeDividendOfHolders(_owner).sub(withdrawnDividends[_owner]);
          }
        
          /// @notice View the amount of dividend in wei that an address has withdrawn.
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` has withdrawn.
          function withdrawnDividendOfHolder(address _owner) public view override returns(uint256) {
            return withdrawnDividends[_owner];
          }
        
            /// @notice View the amount of dividend in wei that an address can withdraw.
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` can withdraw.
          function withdrawableDividendOfPart(address _owner) public view override returns(uint256) {
            return accumulativeDividendOfPart(_owner).sub(withdrawnDividends[_owner]);
          }
        
          /// @notice View the amount of dividend in wei that an address has withdrawn.
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` has withdrawn.
          function withdrawnDividendOfPart(address _owner) public view override returns(uint256) {
            return withdrawnDividends[_owner];
          }
        
          /// @notice View the amount of dividend in wei that an address has earned in total.
          /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
          /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
          /// @param _owner The address of a token holder.
          /// @return The amount of dividend in wei that `_owner` has earned in total.
          function accumulativeDividendOfHolders(address _owner) public view override returns(uint256) {
            return magnifiedDividendPerShareHolders.mul(balanceOf(_owner)).toInt256Safe()
              .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
          }
        
          function accumulativeDividendOfPart(address _owner) public view override returns(uint256) {
            return magnifiedDividendPerSharePart.mul(balanceOf(_owner)).toInt256Safe()
              .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
          }
          /// @dev Internal function that transfer tokens from one address to another.
          /// Update magnifiedDividendCorrections to keep dividends unchanged.
          /// @param from The address to transfer from.
          /// @param to The address to transfer to.
          /// @param value The amount to be transferred.
          function _transfer(address from, address to, uint256 value) internal virtual override {
            require(false);
        
            int256 _magCorrection = (magnifiedDividendPerShareHolders.add(magnifiedDividendPerSharePart)).mul(value).toInt256Safe();
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
              .sub( (magnifiedDividendPerShareHolders.add(magnifiedDividendPerSharePart).mul(value)).toInt256Safe() );
          }
        
          /// @dev Internal function that burns an amount of the token of a given account.
          /// Update magnifiedDividendCorrections to keep dividends unchanged.
          /// @param account The account whose tokens will be burnt.
          /// @param value The amount that will be burnt.
          function _burn(address account, uint256 value) internal override {
            super._burn(account, value);
        
            magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
              .add( (magnifiedDividendPerShareHolders.add(magnifiedDividendPerSharePart).mul(value)).toInt256Safe() );
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
    
    contract BUSDDividendTracker is DividendPayingToken, Ownable {
            using SafeMath for uint256;
            using SafeMathInt for int256;
            using IterableMapping for IterableMapping.Map;
        
            IterableMapping.Map private tokenHoldersMap;
            IterableMapping.Map private tokenPartMap;
        
            uint256 public lastProcessedIndex;
        
            mapping (address => bool) public excludedFromDividends;
        
            mapping (address => uint256) public lastClaimTimes;
        
            uint256 public claimWait;
            uint256 public immutable minimumTokenBalanceForDividends;
        
            event ExcludeFromDividends(address indexed account);
            event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
        
            event Claim(address indexed account, uint256 amount, bool indexed automatic);
        
            constructor()  DividendPayingToken("BUSD_Dividend_Tracker", "BUSD_Dividend_Tracker") {
              claimWait = 3600;
                minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
            }
        
            function _transfer(address, address, uint256) internal pure override {
                require(false, "BUSD_Dividend_Tracker: No transfers allowed");
            }
        
            function withdrawDividendOfPart() public pure override {
                require(false, "BUSD_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BUSD contract.");
            }
            function withdrawDividendOfHolder() public pure override {
                require(false, "BUSD_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BUSD contract.");
            }
        
            function excludeFromDividends(address account, bool _isPart) external onlyOwner {
              require(!excludedFromDividends[account]);
              excludedFromDividends[account] = true;
        
              _setBalance(account, 0);
        
              if(_isPart){
                  tokenPartMap.remove(account);
              }else {
                  tokenHoldersMap.remove(account);
              }
        
              emit ExcludeFromDividends(account);
            }
        
            function updateClaimWait(uint256 newClaimWait) external onlyOwner {
                require(newClaimWait >= 3600 && newClaimWait <= 86400, "BUSD_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
                require(newClaimWait != claimWait, "BUSD_Dividend_Tracker: Cannot update claimWait to same value");
                emit ClaimWaitUpdated(newClaimWait, claimWait);
                claimWait = newClaimWait;
            }
        
            function getLastProcessedIndex() external view returns(uint256) {
              return lastProcessedIndex;
            }
        
            function getNumberOfTokenHolders() external view returns(uint256) {
                return tokenHoldersMap.keys.length;
            }
        
            function getNumberOfTokenPart() external view returns(uint256) {
                return tokenPartMap.keys.length;
            }
        
            function getAccountHolder(address _account)
                private view returns (
                    address account,
                    int256 index,
                    int256 iterationsUntilProcessed,
                    uint256 withdrawableDividends,
                    uint256 totalDividends,
                    uint256 lastClaimTime,
                    uint256 nextClaimTime,
                    uint256 secondsUntilAutoClaimAvailable) {
        
                    index = tokenHoldersMap.getIndexOfKey(_account);
        
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
        
        
                    withdrawableDividends = withdrawableDividendOfHolder(account);
                    totalDividends = accumulativeDividendOfHolders(account);
        
                    lastClaimTime = lastClaimTimes[account];
        
                    nextClaimTime = lastClaimTime > 0 ?
                                                lastClaimTime.add(claimWait) :
                                                0;
        
                    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                                nextClaimTime.sub(block.timestamp) :
                                                                0;
            }
        
            function getAccountPart(address _account)
                private view returns (
                    address account,
                    int256 index,
                    int256 iterationsUntilProcessed,
                    uint256 withdrawableDividends,
                    uint256 totalDividends,
                    uint256 lastClaimTime,
                    uint256 nextClaimTime,
                    uint256 secondsUntilAutoClaimAvailable) {
        
                    index = tokenPartMap.getIndexOfKey(_account);
        
                    iterationsUntilProcessed = -1;
        
                    if(index >= 0) {
                        if(uint256(index) > lastProcessedIndex) {
                            iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
                        }
                        else {
                            uint256 processesUntilEndOfArray = tokenPartMap.keys.length > lastProcessedIndex ?
                                                                    tokenPartMap.keys.length.sub(lastProcessedIndex) :
                                                                    0;
        
        
                            iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
                        }
                    }
        
        
                    withdrawableDividends = withdrawableDividendOfPart(account);
                    totalDividends = accumulativeDividendOfPart(account);
        
                    lastClaimTime = lastClaimTimes[account];
        
                    nextClaimTime = lastClaimTime > 0 ?
                                                lastClaimTime.add(claimWait) :
                                                0;
        
                    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                                nextClaimTime.sub(block.timestamp) :
                                                                0;
            }
        
            function getAccountAtIndex(uint256 index, bool _isPart)
                public view returns (
                    address,
                    int256,
                    int256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256) {
        
              if(_isPart){
                  if(index >= tokenPartMap.size()) {
                        return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
                    }
        
                    address account = tokenPartMap.getKeyAtIndex(index);
                    return getAccountPart(account);
        
              } else{
                  if(index >= tokenHoldersMap.size()) {
                    return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
                }
        
                    address account = tokenHoldersMap.getKeyAtIndex(index);
                    return getAccountHolder(account);
              }
            }
        
            function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
              if(lastClaimTime > block.timestamp)  {
                return false;
              }
        
              return block.timestamp.sub(lastClaimTime) >= claimWait;
            }
        
            function setBalance(address payable account, uint256 newBalance, bool _isPart) external onlyOwner {
              if(excludedFromDividends[account]) {
                return;
              }
        
              if(newBalance >= minimumTokenBalanceForDividends) {
                    _setBalance(account, newBalance);
                    if(_isPart){
                        tokenPartMap.set(account, newBalance);
                    }else {
                        tokenHoldersMap.set(account, newBalance);
                    }
              }
              else {
                    _setBalance(account, 0);
                    if(_isPart){
                        tokenPartMap.remove(account);
                    }else {
                        tokenHoldersMap.remove(account);
                    }
              }
                if(_isPart) processAccount(account, true, true);
                else processAccount(account, true, false);
        
            }
        
            function processHolders(uint256 gas) public returns (uint256, uint256, uint256) {
              uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
        
              if(numberOfTokenHolders == 0) {
                return (0, 0, lastProcessedIndex);
              }
        
              uint256 _lastProcessedIndex = lastProcessedIndex;
        
              uint256 gasUsed = 0;
        
              uint256 gasLeft = gasleft();
        
              uint256 iterations = 0;
              uint256 claims = 0;
        
              while(gasUsed < gas && iterations < numberOfTokenHolders) {
                _lastProcessedIndex++;
        
                if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                  _lastProcessedIndex = 0;
                }
        
                address account = tokenHoldersMap.keys[_lastProcessedIndex];
        
                if(canAutoClaim(lastClaimTimes[account])) {
                  if(processAccount(payable(account), true, false)) {
                    claims++;
                  }
                }
        
                iterations++;
        
                uint256 newGasLeft = gasleft();
        
                if(gasLeft > newGasLeft) {
                  gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
                }
        
                gasLeft = newGasLeft;
              }
        
              lastProcessedIndex = _lastProcessedIndex;
        
              return (iterations, claims, lastProcessedIndex);
            }
        
            function processPart(uint256 gas) public returns (uint256, uint256, uint256) {
              uint256 numberOfTokenPart = tokenPartMap.keys.length;
        
              if(numberOfTokenPart == 0) {
                return (0, 0, lastProcessedIndex);
              }
        
              uint256 _lastProcessedIndex = lastProcessedIndex;
        
              uint256 gasUsed = 0;
        
              uint256 gasLeft = gasleft();
        
              uint256 iterations = 0;
              uint256 claims = 0;
        
              while(gasUsed < gas && iterations < numberOfTokenPart) {
                _lastProcessedIndex++;
        
                if(_lastProcessedIndex >= tokenPartMap.keys.length) {
                  _lastProcessedIndex = 0;
                }
        
                address account = tokenPartMap.keys[_lastProcessedIndex];
        
                if(canAutoClaim(lastClaimTimes[account])) {
                  if(processAccount(payable(account), true, true)) {
                    claims++;
                  }
                }
        
                iterations++;
        
                uint256 newGasLeft = gasleft();
        
                if(gasLeft > newGasLeft) {
                  gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
                }
        
                gasLeft = newGasLeft;
              }
        
              lastProcessedIndex = _lastProcessedIndex;
        
              return (iterations, claims, lastProcessedIndex);
            }
        
            function processAccount(address payable account, bool automatic, bool _isPart) public onlyOwner returns (bool) {
                uint256 amount;
                if(_isPart){
                    amount = _withdrawDividendOfPart(account);
                } else {
                    amount = _withdrawDividendOfHolder(account);
                }
              if(amount > 0) {
                lastClaimTimes[account] = block.timestamp;
                    emit Claim(account, amount, automatic);
                return true;
              }
        
              return false;
            }
    }
    
    contract Tokenflect is IBEP20, Ownable {
        using SafeMath for uint256;
        
        // General Info
        string  private _NAME     = "Test";
        string  private _SYMBOL   = "TEST";
        uint8 private _DECIMALS = 18;

        IUniswapV2Router02 public uniswapV2Router;
        address public uniswapV2Pair;

        bool private swapping;
    
        bool public canChangeFees = true;
        bool public canChangeMarketingWallet = true;
        bool public canBlacklist = true;
    
        BUSDDividendTracker public dividendTracker;
    
        //address public constant BUSD                 = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD
        address public constant BUSD                   = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); //BUSD TESTNET
        
    
        uint256 public constant swapTokensAtAmount = 2000000 * (10**18);
    
        mapping (address => uint256) private _rOwned;
        mapping (address => uint256) private _tOwned;
        mapping (address => mapping (address => uint256)) private _allowances;
    
        mapping (address => bool) private _isExcludedFromFee;
    
        mapping (address => bool) private _isExcluded;
        address[] private _excluded;
    
        uint256 private constant MAX = ~uint256(0);
        uint256 private _tTotal = 1000000000 * 10**6 * 10**18;
        uint256 private _rTotal = (MAX - (MAX % _tTotal));
        uint256 private _totalReflections; // Total reflections
        
        // NOSTA original feature: members and influencers addresses
        mapping (address => uint256) private _partners;
        mapping (address => address) private _holders;
        mapping (address => bool)    private _isPartner;
        
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
        
        uint256 private _algoPool                  = 0;   // How many reflections are in the algo pool
    
        // addresses
        address payable public _burnWalletAddress      = payable(0x000000000000000000000000000000000000dEaD); // Burn address used to burn a portion of tokens
        address payable public _supplyWalletAddress    = payable(0x683f5C7a783a6C621094689a9b234Cf22aDCBdd7); // Wallet Supply-team (là où nous enverrons les tokens à la création du smartcontract avant d'airdrop la v2)
        address payable public _partWalletAddress      = payable(0xbFc9B7F6352C4f684c93d09e049b006f203DBbF5); // Wallet Partenaires "générique" (quand nous n'avons pas add influenceur un acheteur pour le link à un partenaire, pour les 1,5% partenaires en BUSD et 1,5% partenaires en Nosta)
        address payable public _teamWalletAddress      = payable(0x580229A61fA58291ee518d54B7e82Df259bB0020); // Wallet Team (pour les 1% de transaction fees "Team"
        address payable public _algoWalletAddress      = payable(0x301a2372486c9E70c61E750E7962f876Ec66156F); // Wallet Algo (pour les 7% transaction fees sur price impact > 2%)
        
        uint256 public blacklistDeadline = 2 days; 
        mapping(address => bool) public isBlacklisted;
        mapping(address => uint) public isBlacklistedTo;
        
        bool public tradingReady = false;
    
    
        // use by default 300,000 gas to process auto-claiming dividends
        uint256 public gasForProcessing = 300000;
    
        // exlcude from fees and max transaction amount
        mapping (address => bool) private _isExcludedFromFees;
    
    
        // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
        // could be subject to a maximum transfer amount
        mapping (address => bool) public automatedMarketMakerPairs;
    
        event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
        event ExcludeFromFees(address indexed account, bool isExcluded);
        event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
        event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
        event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
        event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    
        event PrepForLaunch(uint256 blocktime);
    
        event DisabledFeeChanging(bool disabled);
        event DisabledBlacklistAbility(bool disabled);
        event DisabledMarketingWalletChanges(bool disabled);
    
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
        
        event Watch1(address _from, address _to);
        event Watch2(address _from, address _to);
        event Watch3(string _msg, address _from, address _to, uint256 _amount);
        event Watch4(string _msg);
        event Watch5(address[] _path);
        event Watch6(string _msg, uint256 tax);
        event Watch7(string _msg, bool _isTrue);
        
        constructor() {
            // Mint the total reflection balance to the deployer of this contract
            _rOwned[_msgSender()] = _rTotal;
            
            dividendTracker = new BUSDDividendTracker();
            
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
            // Create a uniswap pair for this new token
            address _uniswapV2Pair = IUniswapV2Factory(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc)
            .createPair(address(this), address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7));
    
            uniswapV2Router = _uniswapV2Router;
            uniswapV2Pair = _uniswapV2Pair;
    
            _setAutomatedMarketMakerPair(uniswapV2Pair, true);
    
            // exclude from receiving dividends
            // TODO : add isPart 
            dividendTracker.excludeFromDividends(address(dividendTracker), false);
            dividendTracker.excludeFromDividends(address(this), false);
            dividendTracker.excludeFromDividends(owner(), false);
            dividendTracker.excludeFromDividends(_supplyWalletAddress, false);
            dividendTracker.excludeFromDividends(_partWalletAddress, true);
            dividendTracker.excludeFromDividends(_teamWalletAddress, false);
            dividendTracker.excludeFromDividends(_algoWalletAddress, false);
            dividendTracker.excludeFromDividends(_burnWalletAddress, false);
            dividendTracker.excludeFromDividends(address(_uniswapV2Router), false);
    
            // exclude from paying fees or having max transaction amount
            excludeFromFees(owner(), true);
            excludeFromFees(address(this), true);
            excludeFromFees(_supplyWalletAddress, true);
            excludeFromFees(_partWalletAddress, true);
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
    
        function withdrawBNB(uint256 amount) public onlyOwner() {
            if(amount == 0) payable(owner()).transfer(address(this).balance);
            else payable(owner()).transfer(amount);
        }
        
        function withdrawForeignToken(address token) public onlyOwner() {
            require(address(this) != address(token), "Cannot withdraw native token");
            IBEP20(address(token)).transfer(msg.sender, IBEP20(token).balanceOf(address(this)));
        }
        
        function transferBNBToAddress(address payable recipient, uint256 amount) private {
            recipient.transfer(amount);
        }
    
        function prepForLaunch() public onlyOwner {
            require(!tradingReady, "ADAFlect: Contract has already been prepped for trading.");
            
            tradingReady = true; 
            /*
            //Init list of known frontrunner & flashbots for blacklisting
            // List of bots from t.me/FairLaunchCalls
            blacklistAddress(address(0xA39C50bf86e15391180240938F469a7bF4fDAe9a), true, blacklistDeadline);
            blacklistAddress(address(0xFFFFF6E70842330948Ca47254F2bE673B1cb0dB7), true, blacklistDeadline);
            blacklistAddress(address(0xD334C5392eD4863C81576422B968C6FB90EE9f79), true);
            blacklistAddress(address(0x20f6fCd6B8813c4f98c0fFbD88C87c0255040Aa3), true);
            blacklistAddress(address(0xC6bF34596f74eb22e066a878848DfB9fC1CF4C65), true);
            blacklistAddress(address(0x231DC6af3C66741f6Cf618884B953DF0e83C1A2A), true);
            blacklistAddress(address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40), true);
            blacklistAddress(address(0x42d4C197036BD9984cA652303e07dD29fA6bdB37), true);
            blacklistAddress(address(0x22246F9BCa9921Bfa9A3f8df5baBc5Bc8ee73850), true);
            blacklistAddress(address(0xbCb05a3F85d34f0194C70d5914d5C4E28f11Cc02), true);
            blacklistAddress(address(0x5B83A351500B631cc2a20a665ee17f0dC66e3dB7), true);
            blacklistAddress(address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b), true);
            blacklistAddress(address(0x136F4B5b6A306091b280E3F251fa0E21b1280Cd5), true);
            blacklistAddress(address(0x4aEB32e16DcaC00B092596ADc6CD4955EfdEE290), true);
            blacklistAddress(address(0xe986d48EfeE9ec1B8F66CD0b0aE8e3D18F091bDF), true);
            blacklistAddress(address(0x59341Bc6b4f3Ace878574b05914f43309dd678c7), true);
            blacklistAddress(address(0xc496D84215d5018f6F53E7F6f12E45c9b5e8e8A9), true);
            blacklistAddress(address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b), true);
            blacklistAddress(address(0xfe9d99ef02E905127239E85A611c29ad32c31c2F), true);
            blacklistAddress(address(0x9eDD647D7d6Eceae6bB61D7785Ef66c5055A9bEE), true);
            blacklistAddress(address(0x72b30cDc1583224381132D379A052A6B10725415), true);
            blacklistAddress(address(0x7100e690554B1c2FD01E8648db88bE235C1E6514), true);
            blacklistAddress(address(0x000000917de6037d52b1F0a306eeCD208405f7cd), true);
            blacklistAddress(address(0x59903993Ae67Bf48F10832E9BE28935FEE04d6F6), true);
            blacklistAddress(address(0x00000000000003441d59DdE9A90BFfb1CD3fABf1), true);
            blacklistAddress(address(0x0000000000007673393729D5618DC555FD13f9aA), true);
            blacklistAddress(address(0xA3b0e79935815730d942A444A84d4Bd14A339553), true);
            blacklistAddress(address(0x000000005804B22091aa9830E50459A15E7C9241), true);
            blacklistAddress(address(0x323b7F37d382A68B0195b873aF17CeA5B67cd595), true);
            blacklistAddress(address(0x6dA4bEa09C3aA0761b09b19837D9105a52254303), true);
            blacklistAddress(address(0x000000000000084e91743124a982076C59f10084), true);
            blacklistAddress(address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d), true);
            blacklistAddress(address(0xfad95B6089c53A0D1d861eabFaadd8901b0F8533), true);
            blacklistAddress(address(0x9282dc5c422FA91Ff2F6fF3a0b45B7BF97CF78E7), true);
            blacklistAddress(address(0x45fD07C63e5c316540F14b2002B085aEE78E3881), true);
            blacklistAddress(address(0xDC81a3450817A58D00f45C86d0368290088db848), true);
            blacklistAddress(address(0xFe76f05dc59fEC04184fA0245AD0C3CF9a57b964), true);
            blacklistAddress(address(0xd7d3EE77D35D0a56F91542D4905b1a2b1CD7cF95), true);
            blacklistAddress(address(0xa1ceC245c456dD1bd9F2815a6955fEf44Eb4191b), true);
            blacklistAddress(address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345), true);
            blacklistAddress(address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce), true);
            blacklistAddress(address(0x65A67DF75CCbF57828185c7C050e34De64d859d0), true);
            blacklistAddress(address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345), true);
            blacklistAddress(address(0x7589319ED0fD750017159fb4E4d96C63966173C1), true);
            blacklistAddress(address(0x0000000099cB7fC48a935BcEb9f05BbaE54e8987), true);
            blacklistAddress(address(0x03BB05BBa541842400541142d20e9C128Ba3d17c), true);
            */
            emit PrepForLaunch(block.timestamp);
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
        
        function _setAutomatedMarketMakerPair(address pair, bool value) private {
            require(automatedMarketMakerPairs[pair] != value, "ADAFlect: Automated market maker pair is already set to that value");
            automatedMarketMakerPairs[pair] = value;
    
            if(value) {
                dividendTracker.excludeFromDividends(pair, false);
            }
    
            emit SetAutomatedMarketMakerPair(pair, value);
        }
        
        function setRouterAddress(address router) public onlyOwner() {
            // Connect to the new router
            IUniswapV2Router02 newPancakeSwapRouter = IUniswapV2Router02(router);
            
            // Grab an existing pair, or create one if it doesnt exist
            address newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).getPair(address(this), address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7));
            if(newPair == address(0)){
                newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).createPair(address(this), address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7));
            }
            uniswapV2Pair = newPair;
            uniswapV2Router = newPancakeSwapRouter;
            
            dividendTracker.excludeFromDividends(uniswapV2Pair, false);
        }
    
        function setTrading(bool _enabled) public onlyOwner {
            tradingReady = _enabled;
        }
    
        function blacklistAddress(address account, bool value, uint256 deadline) public onlyOwner{
            require(canBlacklist == true, "The ability to blacklist / amnesty accounts has been disabled.");
            if (value) {
                require(block.timestamp < deadline, " The ability to blacklist accounts has been disabled.");
            }
            isBlacklisted[account]   = value;
            isBlacklistedTo[account] = deadline;
        }
        
        function blacklistMultipleAccounts(address[] calldata accounts, bool[] calldata value, uint256[] calldata deadlines) public onlyOwner {
            require(canBlacklist == true, "The ability to blacklist / amnesty accounts has been disabled.");
            require(accounts.length == value.length && value.length == deadlines.length, "Should be the same length.");
            
            for(uint256 i = 0; i < accounts.length; i++) {
                if (value[i]) {
                require(block.timestamp < deadlines[i], "The ability to blacklist accounts has been disabled.");
                }
                isBlacklisted[accounts[i]]   = value[i];
                isBlacklistedTo[accounts[i]] = deadlines[i];
            }
        }

        function whitelistAddress(address account) public onlyOwner{
            isBlacklisted[account]   = true;
            isBlacklistedTo[account] = 0;
        }
    
        function disableBlacklist() external onlyOwner {
            canBlacklist = false;
            emit DisabledBlacklistAbility(true);
        }
    
        function disableFeeChanging() external onlyOwner {
            canChangeFees = false;
            emit DisabledFeeChanging(true);
        }
    
        function disableWalletChanging() external onlyOwner {
            canChangeMarketingWallet = false;
            emit DisabledMarketingWalletChanges(true);
        }
    
        function updateGasForProcessing(uint256 newValue) public onlyOwner {
            require(newValue >= 200000 && newValue <= 500000, "ADAFlect: gasForProcessing must be between 200,000 and 500,000");
            require(newValue != gasForProcessing, "ADAFlect: Cannot update gasForProcessing to same value");
            emit GasForProcessingUpdated(newValue, gasForProcessing);
            gasForProcessing = newValue;
        }
    
        function withdrawableDividendOfPart(address account) public view returns(uint256) {
            return dividendTracker.withdrawableDividendOfPart(account);
        }
        
        function withdrawableDividendOfHolder(address account) public view returns(uint256) {
            return dividendTracker.withdrawableDividendOfHolder(account);
        }
    
        function dividendTokenBalanceOf(address account) external view returns (uint256) {
            return dividendTracker.balanceOf(account);
        }
    
        function excludeFromDividends(address account, bool  isPart) external onlyOwner{
            dividendTracker.excludeFromDividends(account, isPart);
        }
    
        function updateClaimWait(uint256 claimWait) external onlyOwner {
            dividendTracker.updateClaimWait(claimWait);
        }
    
        function getClaimWait() external view returns(uint256) {
            return dividendTracker.claimWait();
        }
    
        function getTotalDividendsDistributed() external view returns (uint256) {
            return dividendTracker.totalDividendsDistributed();
        }
    
        function isExcludedFromFees(address account) public view returns(bool) {
            return _isExcludedFromFees[account];
        }
    
        function getNumberOfDividendTokenPartners() external view returns(uint256) {
            return dividendTracker.getNumberOfTokenPart();
        }
        
        function getNumberOfDividendTokenHolders() external view returns(uint256) {
            return dividendTracker.getNumberOfTokenHolders();
        }
        
        function processDividendTrackerPartner(uint256 gas) external {
            (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.processPart(gas);
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
        }
    
        function processDividendTrackerHolder(uint256 gas) external {
            (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.processHolders(gas);
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
        }
        
        function claim() external {
            dividendTracker.processAccount(_msgSender(), false, _isPartner[_msgSender()]);
        }
    
        function getLastProcessedIndex() external view returns(uint256) {
            return dividendTracker.getLastProcessedIndex();
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
    
        function calculateTaxFee(uint256 _amount) private view returns (uint256) {
            return _amount.mul(totalFees).div(
                10**2
            );
        }
    
        function _reflectFee(uint256 rFee, uint256 tFee) private {
            _rTotal = _rTotal.sub(rFee);
            _totalReflections = _totalReflections.add(tFee);
        }
        
        function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
            return _amount.mul(liquidityFee).div(
                10**2
            );
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
        
        function _transfer(
            address from,
            address to,
            uint256 amount
        ) private {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "ERC20: transfer amount must be greater than zero");
            require(!isBlacklisted[from] && !isBlacklisted[to], 'Blacklisted address');
    
            if(from != owner() && to != owner()) {
                require(tradingReady , "Is trading Disabled.");
            }
            
            emit Watch3("_transfer : ", from, to, amount);
            
            uint256 contractTokenBalance = balanceOf(address(this));
            
            bool isTaxed = false;
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
    
            if( canSwap &&
                !swapping &&
                !automatedMarketMakerPairs[from] &&
                from != owner() &&
                to != owner()
            ) {
                swapping = true;
                emit Watch4("isSwapping ");

                // 2% liquidity
                uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
                swapAndLiquify(swapTokens);
                emit Watch6("isSwapping - swap tokens = ", swapTokens);
                
                // 2% dividendTracker BUSD rewards for partners and holders
                uint256 dividendTokens = contractTokenBalance.mul(reflectionFee).div(totalFees);
                swapAndSendDividends(dividendTokens);
                emit Watch6("isSwapping -  swapAndSendDividends = ", dividendTokens);
                
                // 1 % team 
                uint256 teamTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
                swapAndSendToFee(teamTokens);
                emit Watch6("isSwapping - swap teamTokens = ", teamTokens);

                // 7% algo
                uint256 sellTokens = contractTokenBalance.mul(sellFee).div(totalFees);
                swapAndSendToAlgo(sellTokens);
                emit Watch6("isSwapping - swap sellTokens = ", sellTokens);
               
                swapping = false;
            }
    
    
            bool takeFee = !swapping;
    
            // if any account belongs to _isExcludedFromFee account then remove the fee
            if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                takeFee = false;
                emit Watch7("takeFee = ", takeFee);
            }
    
            // Remove fees completely from the transfer if either wallet are excluded
            if (!takeFee) {
                removeAllFees();
                emit Watch7("takeFee removeAllFees = ", takeFee);
            }
            
            // if sell 
            if (takeFee && to == uniswapV2Pair) {
                // check price impact 
                if(_priceImpactTax(amount)){
                    totalFees = totalFees.add(sellFee);
                    isTaxed   = true;
                    
                    emit Watch7("isTaxed = ", isTaxed);
                }
                // blacklist for 2 days 
                isBlacklisted[_msgSender()] = true; 
                isBlacklistedTo[_msgSender()] = block.timestamp.add(blacklistDeadline);
                
                emit Watch7("isBlacklisted = ", isBlacklisted[_msgSender()]);
            }
            
            //transfer amount, it will take tax, burn, liquidity fee
            emit Watch7("isTaxed before tokenTransfer = ", isTaxed);
            emit Watch6("total fees = ", totalFees);
            
            _tokenTransfer(from, to, amount, isTaxed); // TODO more tax
            
            // If we removed the fees for this transaction, then restore them for future transactions
            if (!takeFee) {
                restoreAllFees();
                emit Watch4("Restore fees");
            }
            
            // If this transaction was a sell, and we took a fee, restore the fee amount back to the original buy amount
            if (takeFee && to == uniswapV2Pair) {
                totalFees = origin_totalFees;
                emit Watch4("Restore fees");
                emit Watch6("total fees = ", totalFees);
            }
    
            try dividendTracker.setBalance(payable(from), balanceOf(from), _isPartner[from]) {} catch {}
            try dividendTracker.setBalance(payable(to), balanceOf(to), _isPartner[to]) {} catch {}
    
            if(!swapping) {
                emit Watch4("_transfer !currentlySwapping : 2220");
    
                uint256 gas = gasForProcessing;
                
                try dividendTracker.processHolders(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                  emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                }
                catch {
            
                }
            
                try dividendTracker.processPart(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                  emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                }
                catch {
            
                }
                
            }
        }
        
        //this method is responsible for taking all fee, if takeFee is true
        function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool isTaxed) private {
            // Calculate the values required to execute a transfer
            (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
            (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, _getRate());
            
            emit Watch6("tFee = ", tFee);
            emit Watch6("tTransferAmount = ", tTransferAmount);
            
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
                emit Watch6("tPortion = ", tPortion);
                
                // Burn some of the taxed tokens 
                _burnTokens(tPortion);
                
                // Reflect some of the taxed tokens 
        		_reflectTokens(tPortion.mul(2));
                
                // Take the rest of the taxed tokens for the other functions
                _takeTokens(tFee.sub(tPortion).sub(tPortion).sub(tPortion), tPortion, isTaxed);
    		}
                
            // Emit an event 
            emit Transfer(sender, recipient, tTransferAmount);
        }
    
        function _burnTokens(uint256 tFee) private {
            emit Watch4("is burning ");
            uint256 rFee = tFee.mul(_getRate());
            _rOwned[_burnWalletAddress] = _rOwned[_burnWalletAddress].add(rFee);
            if(_isExcludedFromFees[_burnWalletAddress]) {
                _tOwned[_burnWalletAddress] = _tOwned[_burnWalletAddress].add(tFee);
            }
        }
    
        function _reflectTokens(uint256 tFee) private {
            emit Watch4("is reflecting ");
            uint256 rFee = tFee.mul(_getRate());
            _rTotal = _rTotal.sub(rFee);
            _totalReflections = _totalReflections.add(tFee);
            
            emit Watch6("_totalReflections = ", _totalReflections);
        }
    
        function _takeTokens(uint256 tTakeAmount, uint256 tPortion, bool isTaxed) private {
            emit Watch6("tTakeAmount = ", tTakeAmount);
            emit Watch6("tPortion = ", tPortion);
            emit Watch7("isTaxed = ", isTaxed);
            
            uint256 currentRate = _getRate();
            uint256 rTakeAmount = tTakeAmount.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rTakeAmount);
            if(_isExcluded[address(this)]) {
                _tOwned[address(this)] = _tOwned[address(this)].add(tTakeAmount);
            }
            
            // Add a portion to the algo pool to be sent to 
            if(isTaxed){
                uint256 rAlgo = tPortion.mul(7).mul(currentRate);
                _algoPool = _algoPool.add(rAlgo);
                
                emit Watch6("Algo = ", _algoPool);
            }
        }
    
        function swapAndSendToFee(uint256 tokens) private  {
            uint256 initialBUSDBalance = IBEP20(BUSD).balanceOf(address(this));

            swapTokensForBUSD(tokens);
            uint256 newBalance = (IBEP20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);
            IBEP20(BUSD).transfer(_teamWalletAddress, newBalance);
        }
        
        function swapAndSendToAlgo(uint256 tokens) private  {
            uint256 initialBUSDBalance = IBEP20(BUSD).balanceOf(address(this));

            swapTokensForBUSD(tokens);
            uint256 newBalance = (IBEP20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);

            IBEP20(BUSD).transfer(_algoWalletAddress, newBalance);
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
            swapTokensForEth(half);
    
            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
    
            // add liquidity to uniswap
            if (newBalance > 0) {
                addLiquidity(otherHalf, newBalance);
                emit SwapAndLiquify(half, newBalance, otherHalf);
            }
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
    
        function swapTokensForBUSD(uint256 tokenAmount) private {
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            path[2] = BUSD;
    
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
        
        function reflect(uint256 tAmount) public {
            require(!_isExcludedFromFees[_msgSender()], "Excluded addresses cannot call this function");
            (uint256 rAmount,,,,) = _getValues(tAmount);
            _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
            _rTotal = _rTotal.sub(rAmount);
            _totalReflections = _totalReflections.add(tAmount);
        }
        
        function swapAndSendDividends(uint256 tokens) private{
            swapTokensForBUSD(tokens);
            uint256 dividends = IBEP20(BUSD).balanceOf(address(this));
            
            uint256 dividendsPartners = dividends.div(4).mul(3);
            uint256 dividendsHolders  = dividends.div(4);
            
            bool successPartners = IBEP20(BUSD).transfer(address(dividendTracker), dividendsPartners);
            bool successHolders  = IBEP20(BUSD).transfer(address(dividendTracker), dividendsHolders);
    
            if (successPartners) {
                dividendTracker.distributeBusdDividends(dividendsPartners, true);
                emit SendDividends(tokens, dividendsPartners);
            }
            if (successHolders) {
                dividendTracker.distributeBusdDividends(dividendsHolders, false);
                emit SendDividends(tokens, dividendsHolders);
            }
        }
        
        // Check for price impact before doing transfer
        function _priceImpactTax(uint256 amount) public returns(bool) { 
            (uint256 _reserveA, uint256 _reserveB, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
            uint256 _constant = IUniswapV2Pair(uniswapV2Pair).kLast();
            uint256 _market_price = _reserveA.div(_reserveB);
     
            uint256 _reserveA_new = _reserveA.sub(amount);
            uint256 _reserveB_new = _constant.div(_reserveA_new);
            uint256 receivedBUSD = _reserveB_new.sub(_reserveB);
            
            uint256 _new_price    = (amount.div(receivedBUSD)).mul(10**18);
            uint256 _delta_price  = _new_price.div(_market_price);
            uint256 _portion      = uint256(1).mul(10**18);
            uint256 _price_impact = _portion.sub(_delta_price); 
            uint256 _price_impact_percent =  _price_impact.mul(100);
            
            emit Watch4("_priceImpactTax");
            
            return (_price_impact_percent > uint256(200).mul(10**18));
        }
    }