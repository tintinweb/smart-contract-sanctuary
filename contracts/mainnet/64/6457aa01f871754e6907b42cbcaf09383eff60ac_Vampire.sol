pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.6.0;

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {dhttps://info.etherscan.com/contract-verification-constructor-arguments/ecimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    function _setupDecimals(uint8 decimals_) internal {
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

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

pragma solidity >=0.5.0;


library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity >=0.5.0;

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}


/**
 *Submitted for verification at Etherscan.io on 2020-11-04
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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




pragma solidity >=0.4.25 <0.7.0;

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// SPDX-License-Identifier: MIT


// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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




// bloodVial is a stablecoin that is based on Uniswap and the vampireToken representing the eth collateral backing it. It is a simple erc20 contract that has a rebase fucntionality to manage forced liquidations. 

contract BloodVial is IERC20, Ownable{ // we start from IERC20 since we need to redefine a lot of the basic ERC20
	
	using SafeMath for uint256;
	using Address for address;
	
	uint256 private _dropsOfBloodPerVial; 
	
	// balance are denominated in dropsOfBlood, those poured into value stable bloodVials
	
    mapping (address => uint256) private _balances;  

    mapping (address => mapping (address => uint256)) private _allowances;
	
	uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
	
	address public controller;
	
	// the controller is able to mint and burn tokens. This is to be given to the VampireContract after deployment.
	modifier onlyController() {
	        require(msg.sender == controller, "You are not calling from controller address");
	        _;
	    }
	
    event Rebase(
         uint256 fractionalIncreasePermille 
    );
	
	constructor() public {
		_dropsOfBloodPerVial = 1000;
		_name = "BloodVials";
		_symbol = "Vials";
		_decimals = 18;
	    _mint(msg.sender, 10 * 10**18 );
		controller = msg.sender;
	}
	
	
	// reproduce basic ERC20
	
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
	
    function decimals() public view returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        
		return true;
    }
    
	
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
	
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
	
	// modified ERC20 fucntions. We work in dropsOfBlood and covert user input and displayed output. Otherwise it is standart
	
    function totalSupply() public view override returns (uint256) {
        return _totalSupply.div(_dropsOfBloodPerVial) ;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account].div(_dropsOfBloodPerVial);
    }
	
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

		uint256 numberFragments = amount.mul(_dropsOfBloodPerVial);	

        _totalSupply = _totalSupply.add(numberFragments);
        _balances[account] = _balances[account].add(numberFragments);
        emit Transfer(address(0), account, numberFragments );
    }
	
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

		uint256 numberFragments = amount.mul(_dropsOfBloodPerVial);	
		
        _balances[account] = _balances[account].sub(numberFragments, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(numberFragments);
        emit Transfer(account, address(0), numberFragments);
    }
	
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

		uint256 numberFragments = amount.mul(_dropsOfBloodPerVial);

        _balances[sender] = _balances[sender].sub( numberFragments, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add( numberFragments);
        emit Transfer(sender, recipient,  numberFragments);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount; // approve is directly denominated in coins
        emit Approval(owner, spender, amount);
    }
	
	
	// new fucntionality, all locked to the controlling smart contract
	
    function rebase(uint256 fractionalIncreasePermille) public onlyController returns (bool) { 
           
        _dropsOfBloodPerVial = _dropsOfBloodPerVial.mul(fractionalIncreasePermille).div(1000); 
		  
		emit Rebase(fractionalIncreasePermille);
		return true;
    }
	
    function mint(address account, uint256 amount) public onlyController returns (bool) {
        _mint(account,amount);
		return true;
    }
	
    function burn(address account, uint256 amount) public onlyController returns (bool) {
        _burn(account,amount);
		return true;
    }
	
	// allows the transfer of the contoller by the owner
	
	function setController(address new_controller) public onlyOwner returns (bool) {
		controller = new_controller;
		
	}
	
}


pragma solidity >=0.4.25 <0.7.0;


// this contract controlls the blood and acts in such a way that blood remains close to 1 Dai in value. It is not a hard stablecoin and can deviate somewhat from the peg. But over the time of a few days it should readjust and provide accurate values. 


contract Vampire is ERC20,Ownable {

	
	using SafeMath for uint256;
	using Address for address;
	using FixedPoint for *;
	
	
    uint public constant PERIOD = 1 hours;  // this is the minimal time for the vwap oracle 
	uint public constant EPOCH = 1 days;    // this is reference timescale for the contract
	uint constant MAX_UINT = 2**256 - 1;

    IUniswapV2Pair immutable pairWethDai;
    IUniswapV2Pair immutable pairVampireWeth;
    IUniswapV2Pair immutable pairBloodWeth;
	IUniswapV2Router02 immutable routerV2;
    
    
	address internal constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f ;
	address internal constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
	
	address internal constant tokenWeth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //weth
	// mainnet weth 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
	// kovan weth 0xd0A1E359811322d97991E03f863a0C30C2cF029C
	// ropsten weth 0xc778417E063141139Fce010982780140Aa0cD5Ab
	address internal constant tokenDai = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //dai
	
	// mainnet dai 0x6B175474E89094C44Da98b954EedeAC495271d0F
	// kovan dai 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
	// ropsten dai 0xaD6D458402F60fD3Bd25163575031ACDce07538D
	address internal immutable tokenVampire;
	address internal immutable tokenBlood;
	

    uint    public priceWethCumulativeLast;
    uint    public priceDaiCumulativeLast;
    uint    public priceBloodCumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public priceWethAverage; // price of weth in dai
    FixedPoint.uq112x112 public priceDaiAverage; // price of dai in weth
    FixedPoint.uq112x112 public priceBloodAverage; // price of vial in weth
	
	BloodVial internal bloodVial;
			
	constructor(address bloodVial_) public ERC20("Vampire","Vampires") {
		
		bloodVial = BloodVial(bloodVial_);  
		tokenBlood = bloodVial_;
		tokenVampire = address(this);
	    
		_mint(msg.sender, 1000 * 10**18 ); 
		
        pairWethDai = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenWeth, tokenDai));
		pairVampireWeth = IUniswapV2Pair(UniswapV2Library.pairFor(factory,address(this), tokenWeth)); 
		pairBloodWeth = IUniswapV2Pair(UniswapV2Library.pairFor(factory, bloodVial_, tokenWeth)); 
		routerV2 = IUniswapV2Router02(router);
		bloodVial.approve(router,MAX_UINT); 				// give uniswap the right to excahnge vials
		_approve(address(this),router,MAX_UINT); 			// give uniswap the right to excahnge vampires
		
			
	}
	
    receive() external payable { } // payable fallback function
	
	 
	function activateOracles() public onlyOwner {
        // we initialise the two Uniswap pairs and seed the vwap oracle
			
		uint priceDummy1;
		uint priceDummy2;
		(priceDummy1,priceDummy2,blockTimestampLast) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairBloodWeth));
    	priceBloodCumulativeLast = (tokenBlood < tokenWeth ? priceDummy1 : priceDummy2);
		
		(priceDummy1,priceDummy2,blockTimestampLast) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairWethDai));
		priceWethCumulativeLast = (tokenWeth < tokenDai ? priceDummy1 : priceDummy2);
		priceDaiCumulativeLast = (tokenWeth < tokenDai ? priceDummy2 : priceDummy1);
		
	} 
	 
	    
    function updateOracle() internal returns (uint32){
		// this function updates the vwap oracle
		
		uint priceDummy1;
		uint priceDummy2;
		uint32 blockTimestamp;
		uint32 timeElapsed;
		
		(priceDummy1,priceDummy2,blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairBloodWeth));
    	uint priceBloodCumulative = (tokenBlood < tokenWeth ? priceDummy1 : priceDummy2);
		
		(priceDummy1,priceDummy2,blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairWethDai));
		uint priceWethCumulative = (tokenWeth < tokenDai ? priceDummy1 : priceDummy2);
		uint priceDaiCumulative = (tokenWeth < tokenDai ? priceDummy2 : priceDummy1);
		
		timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
		
        // ensure that at least one full period has passed since the last update
		require(timeElapsed >= PERIOD, 'More time must pass before the next ritual can be held');

        priceWethAverage = FixedPoint.uq112x112(uint224((priceWethCumulative - priceWethCumulativeLast) / timeElapsed));
        priceDaiAverage = FixedPoint.uq112x112(uint224((priceDaiCumulative - priceDaiCumulativeLast) / timeElapsed));
        priceBloodAverage = FixedPoint.uq112x112(uint224((priceBloodCumulative - priceBloodCumulativeLast) / timeElapsed));
        
        priceWethCumulativeLast = priceWethCumulative; //price of token Weth in Dai
        priceDaiCumulativeLast = priceDaiCumulative; //price of token Weth in Dai
        priceBloodCumulativeLast = priceBloodCumulative; //price of token Weth in Dai
        
		blockTimestampLast = blockTimestamp;
		
		return timeElapsed;
    }

    
	function getDarkEnergy() public view returns (uint256 darkEnergy) {	
		// darkEnergy is the fundamental security parameter. It is the ratio of guaranteed value in blood divided by the total collateral.
		// 1000 means that we can exactly gurantee all bloodVials. We aim for 1500 or 50% overcollateralisation 
		
		uint256 ethReserves = address(this).balance;
		uint256 treasury = uint256(priceWethAverage.mul(ethReserves).decode144()); // value of contract eth in dai
		uint256 liabilities = bloodVial.totalSupply();  // fictional value of the blood assuming each vial is worth one dai
		
		darkEnergy = treasury.mul(1000).div(liabilities);
		
	}
	
	
    function darkRitual() internal returns (bool){ 
		// the darkRitual calls a bloodRitual when enough time has passed. Otherwise it does nothing so the calling fucntion can proceed
		
		uint priceDummy1;
		uint priceDummy2;
		uint32 blockTimestamp;
		uint32 timeElapsed;
		
		(priceDummy1,priceDummy2,blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairBloodWeth));	
		timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
		
		if (timeElapsed >= PERIOD) {
			bloodRitual();
		}
		 
		return true;
	}
		
    function bloodRitual() public returns (bool) {
		// the bloodRitual tries to bring the value of a vial back to one dai. To acchieve this the vampires will draw or consume blood. If darkEnergy is too low, they will call a liquidation by rebasing the bloodVials

	  	uint32 timeElapsed = updateOracle(); 
		uint256 darkEnergy = getDarkEnergy();
		
		if (darkEnergy > 1500){
			// Vampires firmly in power, only defend the value of blood 
			fillBloodVials(darkEnergy,timeElapsed);
			
		} else if (darkEnergy > 800){
			// recrout new Vampires to increase darkEnergy. Also defend price of Blood
			recruitVampires(darkEnergy,timeElapsed);
			fillBloodVials(darkEnergy,timeElapsed);
			
			
		} else {
			// here the vampires have lost controll. A liquidation is needed. We rebase bloodVials until we have enough darkPower to back their price. 
			uint256 one = 10**18;
			uint256 price = uint256(priceBloodAverage.mul(one).decode144()); // price of one vial in weth
			uint256 daiPrice = uint256(priceWethAverage.mul(price).decode144()); // price of one vial in dai
			
			if (daiPrice > one){
				// as long as the market price is above one dai we do not rebase. Instead people can just sell and be happy.
				recruitVampires(darkEnergy,timeElapsed);
				
			}
			else {
			// rebase bloodVials
				rebase(); 
				
				// do not use price oracles here as they are outdated after the rebase. This may also affect other fucntions that use  priceBloodAverage. Currently this is never used outside of the bloodRitual so there is no concern. But if in the future there would be callable fucntions relying on it we would need to update it here
			}	
		}
		
		// reward the caller, a bit less than 1% of vampires per year 
		uint256 reward = totalSupply().mul(timeElapsed).div(1000000).div(1 hours);
		_mint(msg.sender,reward);  
		
		return true;
    } 
	 
	 
    function rebase() internal returns (bool) {
		
		uint256 ethReserves = address(this).balance;
		uint256 treasury = uint256(priceWethAverage.mul(ethReserves).decode144()); 
		
		uint256 liabilities = bloodVial.totalSupply();  
		
		uint256 bloodDropIncrease = liabilities.mul(1000).div(treasury);
		// this balances the bloodVials to current backing eth
		// never do more than a 3x in one step
		if (bloodDropIncrease > 3000) {
			bloodDropIncrease = 3000;
		}
		bloodVial.rebase(bloodDropIncrease);
		pairBloodWeth.sync(); // need to update uniswap pool after a rebase
		
		return true;
    } 
	
    function recruitVampires( uint darkEnergy,uint32 timeElapsed) internal returns (bool) {
    	// this function recruits new vampires and sells them to get more eth to bloster darkEnergy
		
		// darkEnergy < 1000: recruit 10% per epoch
		// darkEnergy < 1200: recruit 1% per epoch
		// darkEnergy > 1200: recruit 0.1% per epoch
			
		uint recruitFactor = 1;
		if (darkEnergy < 1000) recruitFactor = 100;
		else if (darkEnergy < 1200) recruitFactor = 10;
		
		uint256 targetRecruitment = recruitFactor.mul(timeElapsed).mul(totalSupply()).div(1000).div(EPOCH); 
		

        uint112 reserve0;
        uint112 reserve1;
		uint32 dummyTime;
        (reserve0, reserve1, dummyTime) = pairVampireWeth.getReserves();
		uint256 reserveVampire = (tokenVampire < tokenWeth? reserve0 : reserve1); 
		
		uint256 maxRecruitment = reserveVampire.mul(3).div(1000); // this is so we do not get too much slippage and can be frontrun 
		uint256 recruitment = (targetRecruitment < maxRecruitment? targetRecruitment: maxRecruitment);
		
		_mint(address(this),recruitment);  
		
		// dump the new recruits on the market and get darkEnergy
		address[] memory path = new address[](2);
		path[0] = tokenVampire;
		path[1] = routerV2.WETH();
		routerV2.swapExactTokensForETH(recruitment, 0, path, address(this), block.timestamp);
		
		return true;
    } 
	
	
    function fillBloodVials(uint darkEnergy,uint32 timeElapsed) internal returns (bool) {
    	// here we draw or consume blood to keep the value stable
		
		uint256 one = 10**18;
		uint256 price = uint256(priceBloodAverage.mul(one).decode144()); // price of one vial in weth
		uint256 daiPrice = uint256(priceWethAverage.mul(price).decode144()); // price of one vial in dai
		
		uint256 reserveWeth;
		uint256 reserveBlood;
		
        { // local scope
		uint112 reserve0;
        uint112 reserve1;
		uint32 dummyTime;
        (reserve0, reserve1, dummyTime) = pairBloodWeth.getReserves();
		
		reserveWeth = (tokenBlood < tokenWeth? reserve1 : reserve0);
		reserveBlood = (tokenBlood < tokenWeth? reserve0 : reserve1);
		}
		
		uint256 bloodVialSupply = bloodVial.totalSupply();
		
		if (daiPrice > one) {
			// draw and sell
			uint256 delta = daiPrice.sub(one).mul(10000).div(one); 
			// delta is fractional price difference, the higher the more we want to draw
			
			uint256 baseRate = 500; // print an extra 5%
			if (darkEnergy < 1000) baseRate = 0; // no extra print if we are not collateralised
			else if (darkEnergy < 1200) baseRate = 100; // print extra 1%
			uint256 epochIssuance = delta.add(baseRate).mul(bloodVialSupply).div(10000); 
			uint256 targetIssuance = epochIssuance.mul(timeElapsed).div(EPOCH);
				
	        
			uint256 maxIssuance = reserveBlood.mul(3).div(1000);
			
			// if live price is far away we can issue even more. We may get frontrun, but if price is good there is no problem
			price = one.mul(reserveWeth).div(reserveBlood);
			daiPrice = uint256(priceWethAverage.mul(price).decode144());
			if (daiPrice > one) {
				delta = daiPrice.sub(one).mul(10000).div(one);
				if (delta > 330){ // more then 3.3% price differnce
					uint256 slip = delta.sub(300); // trade to 3%
					if (slip > 500){slip = 500;} // never slip more than 5%
					maxIssuance = reserveBlood.mul(slip).div(10000);
				
				}
			}
			
			uint256 issuance = (targetIssuance < maxIssuance? targetIssuance: maxIssuance);
			
			bloodVial.mint(address(this),issuance);  
		
			// sell new blood to drop the price
			address[] memory path = new address[](2);
			path[0] = tokenBlood;
			path[1] = routerV2.WETH();
			routerV2.swapExactTokensForETH(issuance, 0, path, address(this), block.timestamp);
						 
		}
		else {
		 	// here price is low, so we want to buy back blood and consume it
			uint256 delta = one.sub(daiPrice).mul(10000).div(one); 
			uint256 epochBurn = delta.mul(bloodVialSupply).div(10000);
			uint256 targetBurn = epochBurn.mul(timeElapsed).div(EPOCH);
			
			uint256 maxBurn = reserveBlood.mul(3).div(1000);  // limit maximum slippage
			
			
			// again check if live price is far too low, then buy even more
			price = one.mul(reserveWeth).div(reserveBlood);
			daiPrice = uint256(priceWethAverage.mul(price).decode144());
			if (daiPrice < one) {
				delta = one.sub(daiPrice).mul(10000).div(one);
				if (delta > 330){ // more then 3.3% price differnce
					uint256 slip = delta.sub(300); // trade to 3%
					if (slip > 500){slip = 500;} // never slip more than 5%
					maxBurn = reserveBlood.mul(slip).div(10000);
				
				}
			}
			
			
			uint256 burn = (targetBurn < maxBurn? targetBurn: maxBurn);
			uint256 ethBurn = uint256(priceBloodAverage.mul(burn).decode144()); 
			uint256 maxEthBurn = address(this).balance.div(2); // never burn more than half the treasury
			if (ethBurn > maxEthBurn) {
				ethBurn = maxEthBurn;
			}
			
			// buy and consume blood
			address[] memory path = new address[](2);
			path[0] = routerV2.WETH();
			path[1] = tokenBlood;
			routerV2.swapExactETHForTokens{value: ethBurn}(0, path, address(this),  block.timestamp );
			
			burn = bloodVial.balanceOf(address(this));
			
			bloodVial.burn(address(this),burn);
			
			
		}
		
	
		return true;
		
    }
	
	
	
	function sliverBullet(uint vampires) public returns (bool) {
		// this kills of your vampires and steals their eth
		
		require(balanceOf(msg.sender) >= vampires,'Cannot kill more vampires than you have found');
		
		darkRitual();
		
		// this is a copy of getDarkEnergy, we call it like this since we need intermediate quantities
		uint256 ethReserves = address(this).balance;
		uint256 treasury = uint256(priceWethAverage.mul(ethReserves).decode144()); 
		uint256 liabilities = bloodVial.totalSupply(); 
		
		uint256 darkEnergy = treasury.mul(1000).div(liabilities);
		
		require(darkEnergy > 2000, 'The Vampires are still hiding in their lairs');
		
		uint256 lootedDai = (treasury.sub(liabilities)).mul(vampires).div(totalSupply()); 
		uint256 targetDarkEnergy = (treasury.sub(lootedDai)).mul(1000).div(liabilities); 
		
		require(targetDarkEnergy > 2000,"Be more careful! Now the vampires are hiding");
			
		// alternatice calculation: (treasury - liabilities)/treasury * ethReserves/supply*vampires (would not require dai oracle)
		uint256 lootedEth = uint256(priceDaiAverage.mul(lootedDai).decode144());
		_burn(msg.sender, vampires );
		msg.sender.transfer(lootedEth);
		
	
		return true;
		
	}
	
	
	function bloodGarlic(uint vampires) public returns (bool) {
		// destroy an equal share of vampires and bloodVials to get a fraction of locked eth
		
		// this curse puts a constraint that the value of vampires and bloodVials must be at least equivalent to the ethreserve. 
		
		require(balanceOf(msg.sender) >= vampires,'Cannot poison more vampires than you have found');
		
		darkRitual(); // if you want to exit, at least update the oracles for us :)
		
		uint256 requiredBloodVials = vampires.mul(bloodVial.totalSupply()).div(totalSupply());
		require(bloodVial.balanceOf(msg.sender) >= requiredBloodVials,'Need more blood to contaminate it with garlic');
		
		uint256 ethReserves = address(this).balance;
		uint256 requestedEth = vampires.mul(ethReserves).div(totalSupply());
		_burn(msg.sender, vampires );
		bloodVial.burn(msg.sender, requiredBloodVials);
		
		msg.sender.transfer(requestedEth);
		
		return true;
		
	}
	
	function etherRitual() public payable returns (bool) {
		// this spell creates both blood and vampires out of ether, leaving the darkPower invariant
		// it can only be allowed if the vampires are strong enough if close to liquidation this otherwise could lead to the paradoxical situation of more Vials being filled 
		// when active it contrains the value of vampires and bloodVials from above
		
		darkRitual(); 
		require (getDarkEnergy() > 1500,'the vampires are too weak to cast this spell');
		// msg.value
		uint256 ethReserves = address(this).balance - msg.value; // ethReserves before the spell
		
		uint256 bloodVials = (msg.value).mul(bloodVial.totalSupply()).div(ethReserves);
		uint256 vampires = (msg.value).mul(totalSupply()).div(ethReserves);

		_mint(msg.sender, vampires );
		bloodVial.mint(msg.sender, bloodVials);
		
		return true;
		
	}

}