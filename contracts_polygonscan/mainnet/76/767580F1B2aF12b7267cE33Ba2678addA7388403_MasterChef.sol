/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

// File contracts/libs/IERC20.sol

// 

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


// File contracts/libs/IERC20Metadata.sol

// 

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


// File @openzeppelin/contracts/utils/[email protected]

// 

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// 

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/libs/ERC20.sol

// 

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
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File contracts/libs/DarksideToolBox.sol

// 

pragma solidity ^0.8.0;




contract DarksideToolBox {

    IUniswapV2Router02 public immutable darksideSwapRouter;

    uint256 public immutable startBlock;

    /**
     * @notice Constructs the DarksideToken contract.
     */
    constructor(uint256 _startBlock, IUniswapV2Router02 _darksideSwapRouter) public {
        startBlock = _startBlock;
        darksideSwapRouter = _darksideSwapRouter;
    }

    function convertToTargetValueFromPair(IUniswapV2Pair pair, uint256 sourceTokenAmount, address targetAddress) public view returns (uint256) {
        require(pair.token0() == targetAddress || pair.token1() == targetAddress, "one of the pairs must be the targetAddress");
        if (sourceTokenAmount == 0)
            return 0;

        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (res0 == 0 || res1 == 0)
            return 0;

        if (pair.token0() == targetAddress)
            return (res0 * sourceTokenAmount) / res1;
        else
            return (res1 * sourceTokenAmount) / res0;
    }

    function getTokenUSDCValue(uint256 tokenBalance, address token, uint256 tokenType, bool viaMaticUSDC, address usdcAddress) external view returns (uint256) {
        require(tokenType == 0 || tokenType == 1, "invalid token type provided");
        if (token == address(usdcAddress))
            return tokenBalance;

        // lp type
        if (tokenType == 1) {
            IUniswapV2Pair lpToken = IUniswapV2Pair(token);
            if (lpToken.totalSupply() == 0)
                return 0;
            // If lp contains usdc, we can take a short-cut
            if (lpToken.token0() == address(usdcAddress)) {
                return (IERC20(lpToken.token0()).balanceOf(address(lpToken)) * tokenBalance * 2) / lpToken.totalSupply();
            } else if (lpToken.token1() == address(usdcAddress)){
                return (IERC20(lpToken.token1()).balanceOf(address(lpToken)) * tokenBalance * 2) / lpToken.totalSupply();
            }
        }

        // Only used for lp type tokens.
        address lpTokenAddress = token;
        // If token0 or token1 is matic, use that, else use token0.
        if (tokenType == 1) {
            token = IUniswapV2Pair(token).token0() == darksideSwapRouter.WETH() ? darksideSwapRouter.WETH() :
                        (IUniswapV2Pair(token).token1() == darksideSwapRouter.WETH() ? darksideSwapRouter.WETH() : IUniswapV2Pair(token).token0());
        }

        // if it is an LP token we work with all of the reserve in the LP address to scale down later.
        uint256 tokenAmount = (tokenType == 1) ? IERC20(token).balanceOf(lpTokenAddress) : tokenBalance;

        uint256 usdcEquivalentAmount = 0;

        if (viaMaticUSDC) {
            uint256 maticAmount = 0;

            if (token == darksideSwapRouter.WETH()) {
                maticAmount = tokenAmount;
            } else {

                // As we arent working with usdc at this point (early return), this is okay.
                IUniswapV2Pair maticPair = IUniswapV2Pair(IUniswapV2Factory(darksideSwapRouter.factory()).getPair(darksideSwapRouter.WETH(), token));

                if (address(maticPair) == address(0))
                    return 0;

                maticAmount = convertToTargetValueFromPair(maticPair, tokenAmount, darksideSwapRouter.WETH());
            }

            // As we arent working with usdc at this point (early return), this is okay.
            IUniswapV2Pair usdcmaticPair = IUniswapV2Pair(IUniswapV2Factory(darksideSwapRouter.factory()).getPair(darksideSwapRouter.WETH(), address(usdcAddress)));

            if (address(usdcmaticPair) == address(0))
                return 0;

            usdcEquivalentAmount = convertToTargetValueFromPair(usdcmaticPair, maticAmount, usdcAddress);
        } else {
            // As we arent working with usdc at this point (early return), this is okay.
            IUniswapV2Pair usdcPair = IUniswapV2Pair(IUniswapV2Factory(darksideSwapRouter.factory()).getPair(address(usdcAddress), token));

            if (address(usdcPair) == address(0))
                return 0;

            usdcEquivalentAmount = convertToTargetValueFromPair(usdcPair, tokenAmount, usdcAddress);
        }

        // for the tokenType == 1 path usdcEquivalentAmount is the USDC value of all the tokens in the parent LP contract.

        if (tokenType == 1)
            return (usdcEquivalentAmount * tokenBalance * 2) / IUniswapV2Pair(lpTokenAddress).totalSupply();
        else
            return usdcEquivalentAmount;
    }

    function getNumberOfHalvingsSinceStart(uint256 CZDiamondReleaseHalfLife, uint256 _to) public view returns (uint256) {
        if (_to <= startBlock)
            return 0;

        return (_to - startBlock) / CZDiamondReleaseHalfLife;
    }

    function getPreviousCZDiamondHalvingBlock(uint256 CZDiamondReleaseHalfLife, uint256 _block) public view  returns (uint256) {
        // won't revert from getCZDiamondRelease due to bounds check
        require(_block >= startBlock, "can't get previous CZDiamond halving before startBlock");

        uint256 numberOfHalvings = getNumberOfHalvingsSinceStart(CZDiamondReleaseHalfLife, _block);
        return numberOfHalvings * CZDiamondReleaseHalfLife + startBlock;
    }

    function getNextCZDiamondHalvingBlock(uint256 CZDiamondReleaseHalfLife, uint256 _block) public view  returns (uint256) {
        // won't revert from getCZDiamondRelease due to bounds check
        require(_block >= startBlock, "can't get previous CZDiamond halving before startBlock");

        uint256 numberOfHalvings = getNumberOfHalvingsSinceStart(CZDiamondReleaseHalfLife, _block);

        if ((_block - startBlock) % CZDiamondReleaseHalfLife == 0)
            return numberOfHalvings * CZDiamondReleaseHalfLife + startBlock;
        else
            return (numberOfHalvings + 1) * CZDiamondReleaseHalfLife + startBlock;
    }

    function getCZDiamondReleaseForBlockE24(uint256 initialCZDiamondReleaseRate, uint256 CZDiamondReleaseHalfLife, uint256 _block) public view  returns (uint256) {
        if (_block < startBlock)
            return 0;

        uint256 numberOfHalvings = getNumberOfHalvingsSinceStart(CZDiamondReleaseHalfLife, _block);
        return (initialCZDiamondReleaseRate * 1e24) / (2 ** numberOfHalvings);
    }

    // Return CZDIAMOND reward release over the given _from to _to block.
    function getCZDiamondRelease(uint256 initialCZDiamondReleaseRate, uint256 CZDiamondReleaseHalfLife, uint256 _from, uint256 _to) external view returns (uint256) {
        if (_from < startBlock || _to <= _from)
            return 0;

        uint256 releaseDuration = _to - _from;

        uint256 startReleaseE24 = getCZDiamondReleaseForBlockE24(initialCZDiamondReleaseRate, CZDiamondReleaseHalfLife, _from);
        uint256 endReleaseE24 = getCZDiamondReleaseForBlockE24(initialCZDiamondReleaseRate, CZDiamondReleaseHalfLife, _to);

        // If we are all in the same era its a rectangle problem
        if (startReleaseE24 == endReleaseE24)
            return (endReleaseE24 * releaseDuration) / 1e24;

        // The idea here is that if we span multiple halving eras, we can use triangle geometry to take an average.
        uint256 startSkipBlock = getNextCZDiamondHalvingBlock(CZDiamondReleaseHalfLife, _from);
        uint256 endSkipBlock = getPreviousCZDiamondHalvingBlock(CZDiamondReleaseHalfLife, _to);

        // In this case we do span multiple eras (at least 1 complete half-life era)
        if (startSkipBlock != endSkipBlock) {
            uint256 numberOfCompleteHalfLifes = getNumberOfHalvingsSinceStart(CZDiamondReleaseHalfLife, endSkipBlock) - getNumberOfHalvingsSinceStart(CZDiamondReleaseHalfLife, startSkipBlock);
            uint256 partialEndsRelease = startReleaseE24 * (startSkipBlock - _from) + (endReleaseE24 * (_to - endSkipBlock));
            uint256 wholeMiddleRelease = (endReleaseE24 * 2 * CZDiamondReleaseHalfLife) * ((2 ** numberOfCompleteHalfLifes) - 1);
            return (partialEndsRelease + wholeMiddleRelease) / 1e24;
        }

        // In this case we just span across 2 adjacent eras
        return ((endReleaseE24 * releaseDuration) + (startReleaseE24 - endReleaseE24) * (startSkipBlock - _from)) / 1e24;
    }

    function getDarksideEmissionForBlock(uint256 _block, bool isIncreasingGradient, uint256 releaseGradient, uint256 gradientEndBlock, uint256 endEmission) public pure returns (uint256) {
        if (_block >= gradientEndBlock)
            return endEmission;

        if (releaseGradient == 0)
            return endEmission;
        uint256 currentDarksideEmission = endEmission;
        uint256 deltaHeight = (releaseGradient * (gradientEndBlock - _block)) / 1e24;

        if (isIncreasingGradient) {
            // if there is a logical error, we return 0
            if (endEmission >= deltaHeight)
                currentDarksideEmission = endEmission - deltaHeight;
            else
                currentDarksideEmission = 0;
        } else
            currentDarksideEmission = endEmission + deltaHeight;

        return currentDarksideEmission;
    }

    function calcEmissionGradient(uint256 _block, uint256 currentEmission, uint256 gradientEndBlock, uint256 endEmission) external pure returns (uint256) {
        uint256 darksideReleaseGradient;

        // if the gradient is 0 we interpret that as an unchanging 0 gradient.
        if (currentEmission != endEmission && _block < gradientEndBlock) {
            bool isIncreasingGradient = endEmission > currentEmission;
            if (isIncreasingGradient)
                darksideReleaseGradient = ((endEmission - currentEmission) * 1e24) / (gradientEndBlock - _block);
            else
                darksideReleaseGradient = ((currentEmission - endEmission) * 1e24) / (gradientEndBlock - _block);
        } else
            darksideReleaseGradient = 0;

        return darksideReleaseGradient;
    }

    // Return if we are in the normal operation era, no promo
    function isFlatEmission(uint256 _gradientEndBlock, uint256 _blocknum) internal pure returns (bool) {
        return _blocknum >= _gradientEndBlock;
    }

    // Return DARKSIDE reward release over the given _from to _to block.
    function getDarksideRelease(bool isIncreasingGradient, uint256 releaseGradient, uint256 gradientEndBlock, uint256 endEmission, uint256 _from, uint256 _to) external view returns (uint256) {
        if (_to <= _from || _to <= startBlock)
            return 0;
        uint256 clippedFrom = _from < startBlock ? startBlock : _from;
        uint256 totalWidth = _to - clippedFrom;

        if (releaseGradient == 0 || isFlatEmission(gradientEndBlock, clippedFrom))
            return totalWidth * endEmission;

        if (!isFlatEmission(gradientEndBlock, _to)) {
            uint256 heightDelta = releaseGradient * totalWidth;

            uint256 baseEmission;
            if (isIncreasingGradient)
                baseEmission = getDarksideEmissionForBlock(clippedFrom, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            else
                baseEmission = getDarksideEmissionForBlock(_to, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            return totalWidth * baseEmission + (((totalWidth * heightDelta) / 2) / 1e24);
        }

        // Special case when we are transitioning between promo and normal era.
        if (!isFlatEmission(gradientEndBlock, clippedFrom) && isFlatEmission(gradientEndBlock, _to)) {
            uint256 blocksUntilGradientEnd = gradientEndBlock - clippedFrom;
            uint256 heightDelta = releaseGradient * blocksUntilGradientEnd;

            uint256 baseEmission;
            if (isIncreasingGradient)
                baseEmission = getDarksideEmissionForBlock(_to, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);
            else
                baseEmission = getDarksideEmissionForBlock(clippedFrom, isIncreasingGradient, releaseGradient, gradientEndBlock, endEmission);

            return totalWidth * baseEmission - (((blocksUntilGradientEnd * heightDelta) / 2) / 1e24);
        }

        // huh?
        // shouldnt happen, but also don't want to assert false here either.
        return 0;
    }
}


// File contracts/CZDiamondToken.sol

// 

pragma solidity ^0.8.0;




// CZDiamondToken
contract CZDiamondToken is ERC20("CZDiamond", "CZDIAMOND") {

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant usdcSwapThreshold = 20 * (10 ** 6);

    uint256 public pendingUSDC = 0;

    IERC20 public immutable usdcRewardCurrency;

    DarksideToolBox public immutable darksideToolBox;

    IUniswapV2Router02 public darksideSwapRouter;

    uint256 public lastUSDCDistroBlock = type(uint256).max;

    // default to two weeks @ 1600 blocks per hour
    uint256 public distributionTimeFrameBlocks = 1600 * 24 * 14;

    bool public ownershipIsTransferred = false;

    // Events
    event DistributeCZDiamond(address recipient, uint256 CZDiamondAmount);
    event DepositFeeConvertedToUSDC(address indexed inputToken, uint256 inputAmount, uint256 usdcOutput);
    event USDCTransferredToUser(address recipient, uint256 usdcAmount);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event DarksideSwapRouterUpdated(address indexed operator, address indexed router);
    event SetUSDCDistributionTimeFrame(uint256 distributionTimeFrameBlocks);

    // The operator can only update the transfer tax rate
    address public operator;

    modifier onlyOperator() {
        require(operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    /**
     * @notice Constructs the DarksideToken contract.
     */
    constructor(address _usdcCurrency, DarksideToolBox _darksideToolBox) public {
        operator = _msgSender();
        emit OperatorTransferred(address(0), operator);

        darksideToolBox = _darksideToolBox;
        usdcRewardCurrency = IERC20(_usdcCurrency);

        lastUSDCDistroBlock = _darksideToolBox.startBlock();

        // Divvy up CZDiamond supply.
        _mint(0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31, 60 * (10 ** 3) * (10 ** 18));
        _mint(address(this), 40 * (10 ** 3) * (10 ** 18));
    }


    function transferOwnership(address newOwner) public override onlyOwner  {
        require(!ownershipIsTransferred, "!unset");
        super.transferOwnership(newOwner);
        ownershipIsTransferred = true;
    }

    /// @notice Sends `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function distribute(address _to, uint256 _amount) external onlyOwner returns (uint256){
        require(ownershipIsTransferred, "too early!");
        uint256 sendAmount = _amount;
        if (balanceOf(address(this)) < _amount)
            sendAmount = balanceOf(address(this));

        if (sendAmount > 0) {
            IERC20(address(this)).transfer(_to, sendAmount);
            emit DistributeCZDiamond(_to, sendAmount);
        }

        return sendAmount;
    }

    // To receive MATIC from darksideSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev sell all of a current type of token for usdc. and distribute on a drip.
     * Can only be called by the current owner.
     */
    function getUSDCDripRate() external view returns (uint256) {
        return usdcRewardCurrency.balanceOf(address(this)) / distributionTimeFrameBlocks;
    }

    /**
     * @dev sell all of a current type of token for usdc. and distribute on a drip.
     * Can only be called by the current owner.
     */
    function getUSDCDrip() external onlyOwner returns (uint256) {
        uint256 usdcBalance = usdcRewardCurrency.balanceOf(address(this));
        if (pendingUSDC > usdcBalance)
            return 0;

        uint256 usdcAvailable = usdcBalance - pendingUSDC;

        // only provide a drip if there has been some blocks passed since the last drip
        uint256 blockSinceLastDistro = block.number > lastUSDCDistroBlock ? block.number - lastUSDCDistroBlock : 0;

        // We distribute the usdc assuming the old usdc balance wanted to be distributed over distributionTimeFrameBlocks blocks.
        uint256 usdcRelease = (blockSinceLastDistro * usdcAvailable) / distributionTimeFrameBlocks;

        usdcRelease = usdcRelease > usdcAvailable ? usdcAvailable : usdcRelease;

        lastUSDCDistroBlock = block.number;
        pendingUSDC += usdcRelease;

        return usdcRelease;
    }

    /**
     * @dev sell all of a current type of token for usdc.
     */
    function convertDepositFeesToUSDC(address token, uint256 tokenType) public onlyOwner {
        // shouldn't be trying to sell CZDiamond
        if (token == address(this) || token == address(usdcRewardCurrency))
            return;

        // LP tokens aren't destroyed in CZDiamond, but this is so CZDiamond can process
        // already destroyed LP fees sent to it by the DarksideToken contract.
        if (tokenType == 1) {
            convertDepositFeesToUSDC(IUniswapV2Pair(token).token0(), 0);
            convertDepositFeesToUSDC(IUniswapV2Pair(token).token1(), 0);
            return;
        }

        uint256 totalTokenBalance = IERC20(token).balanceOf(address(this));

        uint256 usdcValue = darksideToolBox.getTokenUSDCValue(totalTokenBalance, token, tokenType, false, address(usdcRewardCurrency));

        if (totalTokenBalance == 0)
            return;
        if (usdcValue < usdcSwapThreshold)
            return;

        // generate the darksideSwap pair path of token -> usdc.
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = address(usdcRewardCurrency);

        uint256 usdcPriorBalance = usdcRewardCurrency.balanceOf(address(this));

        require(IERC20(token).approve(address(darksideSwapRouter), totalTokenBalance), 'approval failed');

        try
            // make the swap
            darksideSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                totalTokenBalance,
                0, // accept any amount of USDC
                path,
                address(this),
                block.timestamp
            )
        { /* suceeded */ } catch { /* failed, but we avoided reverting */ }


        uint256 usdcProfit = usdcRewardCurrency.balanceOf(address(this)) - usdcPriorBalance;

        emit DepositFeeConvertedToUSDC(token, totalTokenBalance, usdcProfit);
    }

    /**
     * @dev send usdc to a user
     * Can only be called by the current operator.
     */
    function transferUSDCToUser(address recipient, uint256 amount) external onlyOwner {
       uint256 usdcBalance = usdcRewardCurrency.balanceOf(address(this));
       if (usdcBalance < amount)
           amount = usdcBalance;

       require(usdcRewardCurrency.transfer(recipient, amount), "transfer failed!");

       pendingUSDC -= amount;

        emit USDCTransferredToUser(recipient, amount);
    }

    /**
     * @dev set the number of blocks we should use to calculate the USDC drip rate.
     * Can only be called by the current operator.
     */
    function setUSDCDistributionTimeFrame(uint256 _usdcDistributionTimeFrame) external onlyOperator {
        require(_usdcDistributionTimeFrame > 1600 && _usdcDistributionTimeFrame < 70080000 /* 5 years */, "_usdcDistributionTimeFrame out of range!");

        distributionTimeFrameBlocks = _usdcDistributionTimeFrame;

        emit SetUSDCDistributionTimeFrame(distributionTimeFrameBlocks);
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateDarksideSwapRouter(address _router) external onlyOperator {
        require(_router != address(0), "updateDarksideSwapRouter: new _router is the zero address");
        require(address(darksideSwapRouter) == address(0), "router already set!");

        darksideSwapRouter = IUniswapV2Router02(_router);
        emit DarksideSwapRouterUpdated(msg.sender, address(darksideSwapRouter));
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "transferOperator: new operator is the zero address");

        emit OperatorTransferred(operator, newOperator);

        operator = newOperator;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// 

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


// File contracts/libs/SafeERC20.sol

// 

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/libs/IDarksideReferral.sol

// 

pragma solidity ^0.8.0;

interface IDarksideReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}


// File contracts/DarksideReferral.sol

// 

pragma solidity ^0.8.0;




contract DarksideReferral is IDarksideReferral, Ownable {

    address public operator;

    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions

    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);
    event OperatorUpdated(address indexed operator);

    modifier onlyOperator {
        require(operator == msg.sender, "Operator: caller is not the operator");
        _;
    }

    function recordReferral(address _user, address _referrer) external override onlyOperator {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    function recordReferralCommission(address _referrer, uint256 _commission) external override onlyOperator {
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) external override view returns (address) {
        return referrers[_user];
    }

    // Update the status of the operator
    function updateOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "operator cannot be the 0 address");
        require(operator == address(0), "operator is already set!");

        operator = _operator;

        emit OperatorUpdated(_operator);
    }
}


// File contracts/libs/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File @openzeppelin/contracts/security/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/libs/AddLiquidityHelper.sol

// 

pragma solidity ^0.8.0;





// AddLiquidityHelper, allows anyone to add or remove Darkside liquidity tax free
// Also allows the Darkside Token to do buy backs tax free via an external contract.
contract AddLiquidityHelper is ReentrancyGuard, Ownable {
    using SafeERC20 for ERC20;

    address public darksideAddress;

    IUniswapV2Router02 public immutable darksideSwapRouter;
    // The trading pair
    address public darksideSwapPair;

    // To receive ETH when swapping
    receive() external payable {}

    event SetDarksideAddresses(address darksideAddress, address darksideSwapPair);

    /**
     * @notice Constructs the AddLiquidityHelper contract.
     */
    constructor(address _router) public  {
        require(_router != address(0), "_router is the zero address");
        darksideSwapRouter = IUniswapV2Router02(_router);
    }

    function darksideETHLiquidityWithBuyBack(address lpHolder) external payable nonReentrant {
        require(msg.sender == darksideAddress, "can only be used by the darkside token!");

        (uint256 res0, uint256 res1, ) = IUniswapV2Pair(darksideSwapPair).getReserves();

        if (res0 != 0 && res1 != 0) {
            // making weth res0
            if (IUniswapV2Pair(darksideSwapPair).token0() == darksideAddress)
                (res1, res0) = (res0, res1);

            uint256 contractTokenBalance = ERC20(darksideAddress).balanceOf(address(this));

            // calculate how much eth is needed to use all of contractTokenBalance
            // also boost precision a tad.
            uint256 totalETHNeeded = (res0 * contractTokenBalance) / res1;

            uint256 existingETH = address(this).balance;

            uint256 unmatchedDarkside = 0;

            if (existingETH < totalETHNeeded) {
                // calculate how much darkside will match up with our existing eth.
                uint256 matchedDarkside = (res1 * existingETH) / res0;
                if (contractTokenBalance >= matchedDarkside)
                    unmatchedDarkside = contractTokenBalance - matchedDarkside;
            } else if (existingETH > totalETHNeeded) {
                // use excess eth for darkside buy back
                uint256 excessETH = existingETH - totalETHNeeded;

                if (excessETH / 2 > 0) {
                    // swap half of the excess eth for lp to be balanced
                    swapETHForTokens(excessETH / 2, darksideAddress);
                }
            }

            uint256 unmatchedDarksideToSwap = unmatchedDarkside / 2;

            // swap tokens for ETH
            if (unmatchedDarksideToSwap > 0)
                swapTokensForEth(darksideAddress, unmatchedDarksideToSwap);

            uint256 darksideBalance = ERC20(darksideAddress).balanceOf(address(this));

            // approve token transfer to cover all possible scenarios
            ERC20(darksideAddress).approve(address(darksideSwapRouter), darksideBalance);

            // add the liquidity
            darksideSwapRouter.addLiquidityETH{value: address(this).balance}(
                darksideAddress,
                darksideBalance,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                lpHolder,
                block.timestamp
            );

        }

        if (address(this).balance > 0) {
            // not going to require/check return value of this transfer as reverting behaviour is undesirable.
            payable(address(msg.sender)).call{value: address(this).balance}("");
        }

        if (ERC20(darksideAddress).balanceOf(address(this)) > 0)
            ERC20(darksideAddress).transfer(msg.sender, ERC20(darksideAddress).balanceOf(address(this)));
    }

    function addDarksideETHLiquidity(uint256 nativeAmount) external payable nonReentrant {
        require(msg.value > 0, "!sufficient funds");

        ERC20(darksideAddress).safeTransferFrom(msg.sender, address(this), nativeAmount);

        // approve token transfer to cover all possible scenarios
        ERC20(darksideAddress).approve(address(darksideSwapRouter), nativeAmount);

        // add the liquidity
        darksideSwapRouter.addLiquidityETH{value: msg.value}(
            darksideAddress,
            nativeAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );

        if (address(this).balance > 0) {
            // not going to require/check return value of this transfer as reverting behaviour is undesirable.
            payable(address(msg.sender)).call{value: address(this).balance}("");
        }

        uint256 darksideBalance = ERC20(darksideAddress).balanceOf(address(this));

        if (darksideBalance > 0)
            ERC20(darksideAddress).transfer(msg.sender, darksideBalance);
    }

    function addDarksideLiquidity(address baseTokenAddress, uint256 baseAmount, uint256 nativeAmount) external nonReentrant {
        ERC20(baseTokenAddress).safeTransferFrom(msg.sender, address(this), baseAmount);
        ERC20(darksideAddress).safeTransferFrom(msg.sender, address(this), nativeAmount);

        // approve token transfer to cover all possible scenarios
        ERC20(baseTokenAddress).approve(address(darksideSwapRouter), baseAmount);
        ERC20(darksideAddress).approve(address(darksideSwapRouter), nativeAmount);

        // add the liquidity
        darksideSwapRouter.addLiquidity(
            baseTokenAddress,
            darksideAddress,
            baseAmount,
            nativeAmount ,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );

        if (ERC20(baseTokenAddress).balanceOf(address(this)) > 0)
            ERC20(baseTokenAddress).safeTransfer(msg.sender, ERC20(baseTokenAddress).balanceOf(address(this)));

        if (ERC20(darksideAddress).balanceOf(address(this)) > 0)
            ERC20(darksideAddress).transfer(msg.sender, ERC20(darksideAddress).balanceOf(address(this)));
    }

    function removeDarksideLiquidity(address baseTokenAddress, uint256 liquidity) external nonReentrant {
        address lpTokenAddress = IUniswapV2Factory(darksideSwapRouter.factory()).getPair(baseTokenAddress, darksideAddress);
        require(lpTokenAddress != address(0), "pair hasn't been created yet, so can't remove liquidity!");

        ERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), liquidity);
        // approve token transfer to cover all possible scenarios
        ERC20(lpTokenAddress).approve(address(darksideSwapRouter), liquidity);

        // add the liquidity
        darksideSwapRouter.removeLiquidity(
            baseTokenAddress,
            darksideAddress,
            liquidity,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(address saleTokenAddress, uint256 tokenAmount) internal {
        // generate the darksideSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = saleTokenAddress;
        path[1] = darksideSwapRouter.WETH();

        ERC20(saleTokenAddress).approve(address(darksideSwapRouter), tokenAmount);

        // make the swap
        darksideSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function swapETHForTokens(uint256 ethAmount, address wantedTokenAddress) internal {
        require(address(this).balance >= ethAmount, "insufficient matic provided!");
        require(wantedTokenAddress != address(0), "wanted token address can't be the zero address!");

        // generate the darksideSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = darksideSwapRouter.WETH();
        path[1] = wantedTokenAddress;

        // make the swap
        darksideSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            // cannot send tokens to the token contract of the same type as the output token
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev set the darkside address.
     * Can only be called by the current owner.
     */
    function setDarksideAddress(address _darksideAddress) external onlyOwner {
        require(_darksideAddress != address(0), "_darksideAddress is the zero address");
        require(darksideAddress == address(0), "darksideAddress already set!");

        darksideAddress = _darksideAddress;

        darksideSwapPair = IUniswapV2Factory(darksideSwapRouter.factory()).getPair(darksideAddress, darksideSwapRouter.WETH());

        require(address(darksideSwapPair) != address(0), "matic pair !exist");

        emit SetDarksideAddresses(darksideAddress, darksideSwapPair);
    }
}


// File contracts/DarksideToken.sol

// 

pragma solidity ^0.8.0;







// DarksideToken.
contract DarksideToken is ERC20("Darkcoin", "DARK")  {
    using SafeERC20 for IERC20;

    // Transfer tax rate in basis points. (default 6.66%)
    uint16 public transferTaxRate = 666;
    // Extra transfer tax rate in basis points. (default 10.00%)
    uint16 public extraTransferTaxRate = 1000;
    // Burn rate % of transfer tax. (default 54.95% x 6.66% = 3.660336% of total amount).
    uint32 public constant burnRate = 549549549;
    // Max transfer tax rate: 20.00%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 2000;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public constant usdcCurrencyAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    uint256 public constant usdcSwapThreshold = 20 * (10 ** 6);

    // Min amount to liquify. (default 40 DARKSIDEs)
    uint256 public constant minDarksideAmountToLiquify = 40 * (10 ** 18);
    // Min amount to liquify. (default 100 MATIC)
    uint256 public constant minMaticAmountToLiquify = 100 *  (10 ** 18);

    IUniswapV2Router02 public darksideSwapRouter;
    // The trading pair
    address public darksideSwapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;

    AddLiquidityHelper public immutable addLiquidityHelper;
    DarksideToolBox public immutable darksideToolBox;

    address public immutable CZDiamond;

    bool public ownershipIsTransferred = false;

    mapping(address => bool) public excludeFromMap;
    mapping(address => bool) public excludeToMap;

    mapping(address => bool) public extraFromMap;
    mapping(address => bool) public extraToMap;

    event TransferFeeChanged(uint256 txnFee, uint256 extraTxnFee);
    event UpdateFeeMaps(address indexed _contract, bool fromExcluded, bool toExcluded, bool fromHasExtra, bool toHasExtra);
    event SetDarksideRouter(address darksideSwapRouter, address darksideSwapPair);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    // The operator can only update the transfer tax rate
    address public operator;

    modifier onlyOperator() {
        require(operator == msg.sender, "!operator");
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        uint16 _extraTransferTaxRate = extraTransferTaxRate;
        transferTaxRate = 0;
        extraTransferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
        extraTransferTaxRate = _extraTransferTaxRate;
    }

    /**
     * @notice Constructs the DarksideToken contract.
     */
    constructor(address _CZDiamond, AddLiquidityHelper _addLiquidityHelper, DarksideToolBox _darksideToolBox) public {
        addLiquidityHelper = _addLiquidityHelper;
        darksideToolBox = _darksideToolBox;
        CZDiamond = _CZDiamond;
        operator = _msgSender();

        // pre-mint
        _mint(address(0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31), uint256(325000 * (10 ** 18)));
    }

    function transferOwnership(address newOwner) public override onlyOwner  {
        require(!ownershipIsTransferred, "!unset");
        super.transferOwnership(newOwner);
        ownershipIsTransferred = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) external onlyOwner {
        require(ownershipIsTransferred, "too early!");
        if (_amount > 0)
            _mint(_to, _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of DARKSIDE
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        bool toFromAddLiquidityHelper = (sender == address(addLiquidityHelper) || recipient == address(addLiquidityHelper));
        // swap and liquify
        if (
            _inSwapAndLiquify == false
            && address(darksideSwapRouter) != address(0)
            && !toFromAddLiquidityHelper
            && sender != darksideSwapPair
            && sender != owner()
        ) {
            swapAndLiquify();
        }

        if (toFromAddLiquidityHelper ||
            recipient == BURN_ADDRESS || (transferTaxRate == 0 && extraTransferTaxRate == 0) ||
            excludeFromMap[sender] || excludeToMap[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 6.66% of every transfer, but extra 2% for dumping tax
            uint256 taxAmount = (amount * (transferTaxRate +
                ((extraFromMap[sender] || extraToMap[recipient]) ? extraTransferTaxRate : 0))) / 10000;

            uint256 burnAmount = (taxAmount * burnRate) / 1000000000;
            uint256 liquidityAmount = taxAmount - burnAmount;

            // default 93.34% of transfer sent to recipient
            uint256 sendAmount = amount - taxAmount;

            assert(amount == sendAmount + taxAmount &&
                        taxAmount == burnAmount + liquidityAmount);

            super._transfer(sender, BURN_ADDRESS, burnAmount);
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = ERC20(address(this)).balanceOf(address(this));

        uint256 WETHbalance = IERC20(darksideSwapRouter.WETH()).balanceOf(address(this));

        IWETH(darksideSwapRouter.WETH()).withdraw(WETHbalance);

        if (address(this).balance >= minMaticAmountToLiquify || contractTokenBalance >= minDarksideAmountToLiquify) {

            IERC20(address(this)).safeTransfer(address(addLiquidityHelper), IERC20(address(this)).balanceOf(address(this)));
            // send all tokens to add liquidity with, we are refunded any that aren't used.
            addLiquidityHelper.darksideETHLiquidityWithBuyBack{value: address(this).balance}(BURN_ADDRESS);
        }
    }

    /**
     * @dev unenchant the lp token into its original components.
     * Can only be called by the current operator.
     */
    function swapLpTokensForFee(address token, uint256 amount) internal {
        require(IERC20(token).approve(address(darksideSwapRouter), amount), '!approved');

        IUniswapV2Pair lpToken = IUniswapV2Pair(token);

        uint256 token0BeforeLiquidation = IERC20(lpToken.token0()).balanceOf(address(this));
        uint256 token1BeforeLiquidation = IERC20(lpToken.token1()).balanceOf(address(this));

        // make the swap
        darksideSwapRouter.removeLiquidity(
            lpToken.token0(),
            lpToken.token1(),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 token0FromLiquidation = IERC20(lpToken.token0()).balanceOf(address(this)) - token0BeforeLiquidation;
        uint256 token1FromLiquidation = IERC20(lpToken.token1()).balanceOf(address(this)) - token1BeforeLiquidation;

        address tokenForCZDiamondUSDCReward = lpToken.token0();
        address tokenForDarksideAMMReward = lpToken.token1();

        // If we already have, usdc, save a swap.
       if (lpToken.token1() == usdcCurrencyAddress){

            (tokenForDarksideAMMReward, tokenForCZDiamondUSDCReward) = (tokenForCZDiamondUSDCReward, tokenForDarksideAMMReward);
        } else if (lpToken.token0() == darksideSwapRouter.WETH()){
            // if one is weth already use the other one for czdiamond and
            // the weth for darkside AMM to save a swap.

            (tokenForDarksideAMMReward, tokenForCZDiamondUSDCReward) = (tokenForCZDiamondUSDCReward, tokenForDarksideAMMReward);
        }

        bool czRewardIs0 = tokenForCZDiamondUSDCReward == lpToken.token0();

        // send czdiamond all of 1 half of the LP to be convereted to USDC later.
        IERC20(tokenForCZDiamondUSDCReward).safeTransfer(address(CZDiamond),
            czRewardIs0 ? token0FromLiquidation : token1FromLiquidation);

        // send czdiamond 50% share of the other 50% to give czdiamond 75% in total.
        IERC20(tokenForDarksideAMMReward).safeTransfer(address(CZDiamond),
            (czRewardIs0 ? token1FromLiquidation : token0FromLiquidation)/2);

        swapDepositFeeForWmatic(tokenForDarksideAMMReward, 0);
    }

    /**
     * @dev sell all of a current type of token for weth, to be used in darkside liquidity later.
     * Can only be called by the current operator.
     */
    function swapDepositFeeForETH(address token, uint256 tokenType) external onlyOwner {
        uint256 usdcValue = darksideToolBox.getTokenUSDCValue(IERC20(token).balanceOf(address(this)), token, tokenType, false, usdcCurrencyAddress);

        // If darkside or weth already no need to do anything.
        if (token == address(this) || token == darksideSwapRouter.WETH())
            return;

        // only swap if a certain usdc value
        if (usdcValue < usdcSwapThreshold)
            return;

        swapDepositFeeForWmatic(token, tokenType);
    }

    function swapDepositFeeForWmatic(address token, uint256 tokenType) internal {
        address toToken = darksideSwapRouter.WETH();
        uint256 totalTokenBalance = IERC20(token).balanceOf(address(this));

        // can't trade to darkside inside of darkside anyway
        if (token == toToken || totalTokenBalance == 0 || toToken == address(this))
            return;

        if (tokenType == 1) {
            swapLpTokensForFee(token, totalTokenBalance);
            return;
        }

        require(IERC20(token).approve(address(darksideSwapRouter), totalTokenBalance), "!approved");

        // generate the darksideSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = toToken;

        try
            // make the swap
            darksideSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                totalTokenBalance,
                0, // accept any amount of tokens
                path,
                address(this),
                block.timestamp
            )
        { /* suceeded */ } catch { /* failed, but we avoided reverting */ }

        // Unfortunately can't swap directly to darkside inside of darkside (Uniswap INVALID_TO Assert, boo).
        // Also dont want to add an extra swap here.
        // Will leave as WETH and make the darkside Txn AMM utilise available WETH first.
    }

    // To receive ETH from darksideSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate, uint16 _extraTransferTaxRate) external onlyOperator {
        require(_transferTaxRate + _extraTransferTaxRate  <= MAXIMUM_TRANSFER_TAX_RATE,
            "!valid");
        transferTaxRate = _transferTaxRate;
        extraTransferTaxRate = _extraTransferTaxRate;

        emit TransferFeeChanged(transferTaxRate, extraTransferTaxRate);
    }

    /**
     * @dev Update the excludeFromMap
     * Can only be called by the current operator.
     */
    function updateFeeMaps(address _contract, bool fromExcluded, bool toExcluded, bool fromHasExtra, bool toHasExtra) external onlyOperator {
        excludeFromMap[_contract] = fromExcluded;
        excludeToMap[_contract] = toExcluded;
        extraFromMap[_contract] = fromHasExtra;
        extraToMap[_contract] = toHasExtra;

        emit UpdateFeeMaps(_contract, fromExcluded, toExcluded, fromHasExtra, toHasExtra);
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateDarksideSwapRouter(address _router) external onlyOperator {
        require(_router != address(0), "!!0");
        require(address(darksideSwapRouter) == address(0), "!unset");

        darksideSwapRouter = IUniswapV2Router02(_router);
        darksideSwapPair = IUniswapV2Factory(darksideSwapRouter.factory()).getPair(address(this), darksideSwapRouter.WETH());

        require(address(darksideSwapPair) != address(0), "!matic pair");

        emit SetDarksideRouter(address(darksideSwapRouter), darksideSwapPair);
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "!!0");

        emit OperatorTransferred(operator, newOperator);

        operator = newOperator;
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// 

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/utils/[email protected]

// 

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

// 

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// 

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File contracts/libs/ERC721Wrapper.sol

contract ERC721Wrapper is ERC721{

    // FOR TESTING ONLY NOT FOR AUDIT!!!

    constructor(string memory name_, string memory symbol_) public ERC721(name_, symbol_) {
    }
}


// File hardhat/[email protected]

// 
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}


// File contracts/libs/Multicall.sol

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Multicall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }

    // FOR TESTING ONLY NOT FOR AUDIT!!!

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        console.log("multicall is running!!!");
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            console.log("calling target: %s", calls[i].target);
            console.logBytes(calls[i].callData);
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            console.log("op %d returned", i);
            require(success, "multicall op FAILED");
            returnData[i] = ret;
        }
    }
    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}


// File contracts/Locker.sol

// The locker stores IERC20 tokens and only allows the owner to withdraw them after the UNLOCK_BLOCKNUMBER has been reached.


contract Locker is Ownable {
    using SafeERC20 for IERC20;

    uint256 public immutable UNLOCK_BLOCKNUMBER;

    event Claim(address token, address to);

    // ALREADY AUDITED !!!

    /**
     * @notice Constructs the DarksideToken contract.
     */
    constructor(uint256 blockNumber) public {
        UNLOCK_BLOCKNUMBER = blockNumber;
    }

    // claimToken allows the owner to withdraw tokens sent manually to this contract.
    // It is only callable once UNLOCK_BLOCKNUMBER has passed.
    function claimToken(address token, address to) external onlyOwner {
        require(block.number > UNLOCK_BLOCKNUMBER, "still vesting...");

        IERC20(token).safeTransfer(to, IERC20(token).balanceOf(address(this)));

        emit Claim(token, to);
    }
}


// File @openzeppelin/contracts/utils/structs/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// File contracts/NFTChef.sol

// 

pragma solidity ^0.8.0;






// NFTChef is the keeper of Masterchefs NFTs.
//
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract NFTChef is IERC721Receiver, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // max NFTs a single user can stake in a pool. This is to ensure finite gas usage on emergencyWithdraw.
    uint256 public constant MAX_NFT_COUNT = 32;
    uint256 public constant MAX_MATIC_STAKING_FEE = 1e3 * (1e18);

    // Mapping of NFT contract address to which NFTs a user has staked.
    mapping(address => mapping(address => mapping(uint256 => bool))) public userStakedMap;
    // Mapping of NFT contract address to array of NFT IDs a user has staked.
    mapping(address => mapping(address => EnumerableSet.UintSet)) private userNftIdsMapArray;
    // mapping of NFT contract address to maticFeeAmount
    mapping(address => uint256) public userNftMaticFeeMap;

    // MATIC Polygon (MATIC) address
    address public constant maticCurrencyAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public immutable CZDiamondAddress;
    address public immutable darksideAddress;

    event AddSetPoolNFT(address indexed nftContractAddress, uint256 maticFee);
    event DepositNFT(address indexed user, address indexed nftContractAddress, uint256 nftId);
    event WithdrawNFT(address indexed user, address indexed nftContractAddress, uint256 nftId);
    event EmergencyWithdrawNFT(address indexed user, address indexed nftContractAddress, uint256 nftId);
    event EmergencyNFTWithdrawCompleted(address indexed user, address indexed nftContractAddress, uint256 amountOfNfts);

    constructor(
        address _CZDiamondAddress,
        address _darksideAddress
    ) public {
        CZDiamondAddress = _CZDiamondAddress;
        darksideAddress = _darksideAddress;
    }

    // set NFTs matic deposit Fees.
    function setPoolMaticFee(address nftContractAddress, uint256 maticFee) external onlyOwner {
        IERC721(nftContractAddress).balanceOf(address(this));
        require(maticFee <= MAX_MATIC_STAKING_FEE, "maximum matic fee for nft staking is 1000 matic!");
        userNftMaticFeeMap[nftContractAddress] = maticFee;

        emit AddSetPoolNFT(nftContractAddress, maticFee);
    }

    // Deposit NFTs to NFTChef for DARKSIDE allocation.
    function deposit(address nftContractAddress, address userAddress, uint256 nftId) external payable onlyOwner {
        require(msg.value >= userNftMaticFeeMap[nftContractAddress], "not enough unwrapped matic provided!");
        require(userNftIdsMapArray[nftContractAddress][userAddress].length() < MAX_NFT_COUNT,
            "you have aleady reached the maximum amount of NFTs you can stake in this pool");
        IERC721(nftContractAddress).transferFrom(userAddress, address(this), nftId);

        userStakedMap[nftContractAddress][userAddress][nftId] = true;

        userNftIdsMapArray[nftContractAddress][userAddress].add(nftId);

        uint256 maticBalance = address(this).balance;
        // Wrapping native matic for wmatic.
        if (maticBalance > 0)
            IWETH(maticCurrencyAddress).deposit{value:maticBalance}();

        uint256 wmaticBalance = IERC20(maticCurrencyAddress).balanceOf(address(this));
        uint256 darkSideFee = wmaticBalance/4;

        if (darkSideFee > 0)
            IERC20(maticCurrencyAddress).safeTransferFrom(address(this), darksideAddress, darkSideFee);
        if (wmaticBalance - darkSideFee > 0)
            IERC20(maticCurrencyAddress).safeTransferFrom(address(this), CZDiamondAddress, wmaticBalance - darkSideFee);

        emit DepositNFT(userAddress, nftContractAddress, nftId);
    }

    // Withdraw NFTs from NFTChef.
    function withdraw(address nftContractAddress, address userAddress, uint256 nftId) external onlyOwner {
        require(userStakedMap[nftContractAddress][userAddress][nftId], "nft not staked");

        IERC721(nftContractAddress).transferFrom(address(this), userAddress, nftId);

        userStakedMap[nftContractAddress][userAddress][nftId] = false;

        userNftIdsMapArray[nftContractAddress][userAddress].remove(nftId);

        emit WithdrawNFT(userAddress, nftContractAddress, nftId);
    }

    // Withdraw all NFTs without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address nftContractAddress, address userAddress) external onlyOwner {
        EnumerableSet.UintSet storage nftStakedCollection = userNftIdsMapArray[nftContractAddress][userAddress];

        for (uint256 i = 0;i < nftStakedCollection.length();i++) {
            uint256 nftId = nftStakedCollection.at(i);

            IERC721(nftContractAddress).transferFrom(address(this), userAddress, nftId);

            userStakedMap[nftContractAddress][userAddress][nftId] = false;

            emit EmergencyWithdrawNFT(userAddress, nftContractAddress, nftId);
        }

        emit EmergencyNFTWithdrawCompleted(userAddress, nftContractAddress, nftStakedCollection.length());

        // empty user nft Ids array
        delete userNftIdsMapArray[nftContractAddress][userAddress];
    }

    function viewStakerUserNFTs(address nftContractAddress, address userAddress) public view returns (uint256[] memory){
        EnumerableSet.UintSet storage nftStakedCollection = userNftIdsMapArray[nftContractAddress][userAddress];

        uint256[] memory nftStakedArray = new uint256[](nftStakedCollection.length());

        for (uint256 i = 0;i < nftStakedCollection.length();i++)
           nftStakedArray[i] = nftStakedCollection.at(i);

        return nftStakedArray;
    }

    // To receive MATIC from depositers when depositing NFTs
    receive() external payable {}
}


// File contracts/MasterChef.sol

// 

pragma solidity ^0.8.0;






// MasterChef is the master of Darkside. He can make Darkside and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once DARKSIDE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;


    // Burn address
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // USDC Polygon (MATIC) address
    address public constant usdcCurrencyAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    // Founder 1 address
    address public constant FOUNDER1_ADDRESS = 0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31;
    // Founder 2 address
    address public constant FOUNDER2_ADDRESS = 0x30139dfe2D78aFE7fb539e2F2b765d794fe52cB4;

    uint256 public totalUSDCCollected = 0;

    uint256 public accDepositUSDCRewardPerShare = 0;

    // NFTChef, the keeper of the NFTs!
    NFTChef public nftChef;
    // The CZDIAMOND TOKEN!
    CZDiamondToken public CZDiamond;
    // The DARKSIDE TOKEN!
    DarksideToken public darkside;
    // Darkside's trusty utility belt.
    DarksideToolBox public darksideToolBox;

    uint256 public darksideReleaseGradient;
    uint256 public endDarksideGradientBlock;
    uint256 public endGoalDarksideEmission;
    bool public isIncreasingGradient = false;


    // The amount of time between Rare release rate halvings.
    uint256 public czdReleaseHalfLife;
    // The inital release rate for the rare rewards period.
    uint256 public initialCZDReleaseRate;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 darksideRewardDebt;     // Reward debt. See explanation below.
        uint256 CZDiamondRewardDebt;     // Reward debt. See explanation below.
        uint256 usdcRewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DARKSIDEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDarksidePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDarksidePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. DARKSIDEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that DARKSIDEs distribution occurs.
        uint256 accDarksidePerShare;   // Accumulated DARKSIDEs per share, times 1e24. See below.
        uint256 accCZDiamondPerShare;   // Accumulated CZDIAMONDs per share, times 1e24. See below.
        uint256 depositFeeBPOrNFTMaticFee;      // Deposit fee in basis points
        uint256 tokenType;          // 0=Token, 1=LP Token, 2=NFT
        uint256 totalLocked;      // total units locked in the pool
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when normal DARKSIDE mining starts.
    uint256 public startBlock;


    // The last checked balance of DARKSIDE in the burn waller
    uint256 public lastDarksideBurnBalance = 0;
    // How much of burn do CZDiamond stakers get out of 10000
    uint256 public CZDiamondShareOfBurn = 8197;

    // Darkside referral contract address.
    IDarksideReferral darksideReferral;
    // Referral commission rate in basis points.
    // This is split into 2 halves 3% for the referrer and 3% for the referee.
    uint16 public constant referralCommissionRate = 600;

    // removed to save some space..
    // uint256 public constant CZDiamondPID = 0;

    event AddPool(uint256 indexed pid, uint256 tokenType, uint256 allocPoint, address lpToken, uint256 depositFeeBPOrNFTMaticFee);
    event SetPool(uint256 indexed pid, uint256 allocPoint, uint256 depositFeeBPOrNFTMaticFee);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event GradientUpdated(uint256 newEndGoalDarksideEmmission, uint256 newEndDarksideEmmissionBlock);
    event SetDarksideReferral(address darksideAddress);

    constructor(
        NFTChef _nftChef,
        CZDiamondToken _CZDiamond,
        DarksideToken _darkside,
        DarksideToolBox _darksideToolBox,
        uint256 _startBlock,
        uint256 _czdReleaseHalfLife,
        uint256 _initialCZDReleaseRate,
        uint256 _beginningDarksideEmission,
        uint256 _endDarksideEmission,
        uint256 _gradient1EndBlock
    ) public {
        require(_beginningDarksideEmission < 80 ether, "too high");
        require(_endDarksideEmission < 80 ether, "too high");

        nftChef = _nftChef;
        CZDiamond = _CZDiamond;
        darkside = _darkside;
        darksideToolBox = _darksideToolBox;

        startBlock = _startBlock;

        require(_startBlock < _gradient1EndBlock + 40, "!grad");

        isIncreasingGradient = _endDarksideEmission > _beginningDarksideEmission;

        czdReleaseHalfLife = _czdReleaseHalfLife;
        initialCZDReleaseRate = _initialCZDReleaseRate;

        endDarksideGradientBlock = _gradient1EndBlock;
        endGoalDarksideEmission = _endDarksideEmission;

        darksideReleaseGradient = _darksideToolBox.calcEmissionGradient(
            _startBlock, _beginningDarksideEmission, endDarksideGradientBlock, endGoalDarksideEmission);

        add(0, 10000, address(_CZDiamond), 0, false);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(address => bool) public poolExistence;
    modifier nonDuplicated(address _lpToken) {
        require(poolExistence[_lpToken] == false, "dup-pool");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _tokenType, uint256 _allocPoint, address _lpToken, uint256 _depositFeeBPOrNFTMaticFee, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(_tokenType == 0 || _tokenType == 1 || _tokenType == 2, "!token-type");

        // Make sure the provided token is ERC20/ERC721
        if (_tokenType == 2)
            nftChef.setPoolMaticFee(_lpToken, _depositFeeBPOrNFTMaticFee);
        else {
            ERC20(_lpToken).balanceOf(address(this));
            require(_depositFeeBPOrNFTMaticFee <= 401, "!feeBP");
        }

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolExistence[_lpToken] = true;

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accDarksidePerShare: 0,
            accCZDiamondPerShare: 0,
            depositFeeBPOrNFTMaticFee: _depositFeeBPOrNFTMaticFee,
            tokenType: _tokenType,
            totalLocked: 0
        }));

        emit AddPool(poolInfo.length - 1, _tokenType, _allocPoint, address(_lpToken), _depositFeeBPOrNFTMaticFee);
    }

    // Update the given pool's DARKSIDE allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFeeBPOrNFTMaticFee, bool _withUpdate) external onlyOwner {
        if (poolInfo[_pid].tokenType == 2)
            nftChef.setPoolMaticFee(poolInfo[_pid].lpToken, _depositFeeBPOrNFTMaticFee);
        else
            require(_depositFeeBPOrNFTMaticFee <= 401);

        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBPOrNFTMaticFee = _depositFeeBPOrNFTMaticFee;
        //poolInfo[_pid].tokenType = _tokenType;
        //poolInfo[_pid].totalLocked = poolInfo[_pid].totalLocked;

        emit SetPool(_pid, _allocPoint, _depositFeeBPOrNFTMaticFee);
    }

    // View function to see pending USDCs on frontend.
    function pendingUSDC(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[0][_user];

        return ((user.amount * accDepositUSDCRewardPerShare) / (1e24)) - user.usdcRewardDebt;
    }

    // View function to see pending DARKSIDEs on frontend.
    function pendingDarkside(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDarksidePerShare = pool.accDarksidePerShare;

        uint256 lpSupply = pool.totalLocked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && totalAllocPoint != 0) {
            uint256 release = darksideToolBox.getDarksideRelease(isIncreasingGradient, darksideReleaseGradient, endDarksideGradientBlock, endGoalDarksideEmission, pool.lastRewardBlock, block.number);
            uint256 darksideReward = (release * pool.allocPoint) / totalAllocPoint;
            accDarksidePerShare = accDarksidePerShare + ((darksideReward * 1e24) / lpSupply);
        }
        return ((user.amount * accDarksidePerShare) / 1e24) - user.darksideRewardDebt;
    }

    // View function to see pending CZDiamond on frontend.
    function pendingCZDiamond(uint256 _pid, address _user) external view returns (uint256) {
        // CZDiamond pool never gets any more CZDiamond.
        if (_pid == 0)
            return 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCZDiamondPerShare = pool.accCZDiamondPerShare;

        uint256 lpSupply = pool.totalLocked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && totalAllocPoint > poolInfo[0].allocPoint) {
            uint256 release = darksideToolBox.getCZDiamondRelease(initialCZDReleaseRate, czdReleaseHalfLife, pool.lastRewardBlock, block.number);
            uint256 CZDiamondReward = (release * pool.allocPoint) / (totalAllocPoint - poolInfo[0].allocPoint);
            accCZDiamondPerShare = accCZDiamondPerShare + ((CZDiamondReward * 1e24) / lpSupply);
        }

        return ((user.amount * accCZDiamondPerShare) / 1e24) - user.CZDiamondRewardDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            updatePool(pid);
        }
    }

    // Transfers any excess coins gained through reflection
    // to DARKSIDE and CZDIAMOND
    function skimPool(uint256 poolId) internal {
        PoolInfo storage pool = poolInfo[poolId];
        // cannot skim any tokens we use for staking rewards.
        if (pool.tokenType == 2 || isNativeToken(address(pool.lpToken)))
            return;

        uint256 trueBalance = ERC20(pool.lpToken).balanceOf(address(this));

        uint256 skim = trueBalance > pool.totalLocked ?
                            trueBalance - pool.totalLocked :
                            0;

        if (skim > 1e4) {
            uint256 CZDiamondShare = skim / 2;
            uint256 darksideShare = skim - CZDiamondShare;
            IERC20(pool.lpToken).safeTransfer(address(CZDiamond), CZDiamondShare);
            IERC20(pool.lpToken).safeTransfer(address(darkside), darksideShare);
        }
    }

    // Updates darkside release goal and phase change duration
    function updateDarksideRelease(uint256 endBlock, uint256 endDarksideEmission) external onlyOwner {
        require(endDarksideEmission < 80 ether, "too high");
        // give some buffer as to stop extrememly large gradients
        require(block.number + 4 < endBlock, "late!");

        // this will be called infrequently
        // and deployed on a cheap gas network POLYGON (MATIC)
        massUpdatePools();

        uint256 currentDarksideEmission = darksideToolBox.getDarksideEmissionForBlock(block.number,
            isIncreasingGradient, darksideReleaseGradient, endDarksideGradientBlock, endGoalDarksideEmission);

        isIncreasingGradient = endDarksideEmission > currentDarksideEmission;
        darksideReleaseGradient = darksideToolBox.calcEmissionGradient(block.number,
            currentDarksideEmission, endBlock, endDarksideEmission);

        endDarksideGradientBlock = endBlock;
        endGoalDarksideEmission = endDarksideEmission;

        emit GradientUpdated(endGoalDarksideEmission, endDarksideGradientBlock);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock)
            return;

        uint256 lpSupply = pool.totalLocked;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // CZDiamond pool is always pool 0.
        if (poolInfo[0].totalLocked > 0) {
            uint256 usdcRelease = CZDiamond.getUSDCDrip();

            accDepositUSDCRewardPerShare = accDepositUSDCRewardPerShare + ((usdcRelease * 1e24) / poolInfo[0].totalLocked);
            totalUSDCCollected = totalUSDCCollected + usdcRelease;
        }

        uint256 darksideRelease = darksideToolBox.getDarksideRelease(isIncreasingGradient, darksideReleaseGradient, endDarksideGradientBlock, endGoalDarksideEmission, pool.lastRewardBlock, block.number);
        uint256 darksideReward = (darksideRelease * pool.allocPoint) / totalAllocPoint;

        // Darkside Txn fees ONLY for CZDiamond stakers.
        if (_pid == 0) {
            uint256 burnBalance = darkside.balanceOf(BURN_ADDRESS);
            darksideReward = darksideReward + (((burnBalance - lastDarksideBurnBalance) * CZDiamondShareOfBurn) / 10000);

            lastDarksideBurnBalance = burnBalance;
        }

        darkside.mint(address(this), darksideReward);

        if (_pid != 0 && totalAllocPoint > poolInfo[0].allocPoint) {

            uint256 CZDiamondRelease = darksideToolBox.getCZDiamondRelease(initialCZDReleaseRate, czdReleaseHalfLife, pool.lastRewardBlock, block.number);

            if (CZDiamondRelease > 0) {
                uint256 CZDiamondReward = ((CZDiamondRelease * pool.allocPoint) / (totalAllocPoint - poolInfo[0].allocPoint));

                // Getting CZDiamond allocated specificlly for initial distribution.
                CZDiamondReward = CZDiamond.distribute(address(this), CZDiamondReward);

                pool.accCZDiamondPerShare = pool.accCZDiamondPerShare + ((CZDiamondReward * 1e24) / lpSupply);
            }
        }

        pool.accDarksidePerShare = pool.accDarksidePerShare + ((darksideReward * 1e24) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Return if address is a founder address.
    function isFounder(address addr) public pure returns (bool) {
        return addr == FOUNDER1_ADDRESS || addr == FOUNDER2_ADDRESS;
    }

    // Return if address is a founder address.
    function isNativeToken(address addr) public view returns (bool) {
        return addr == address(CZDiamond) || addr == address(darkside);
    }

    // Deposit LP tokens to MasterChef for DARKSIDE allocation.
    function deposit(uint256 _pid, uint256 _amountOrId, bool isNFTHarvest, address _referrer) external payable nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if ((pool.tokenType == 2 || _amountOrId > 0) && address(darksideReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            darksideReferral.recordReferral(msg.sender, _referrer);
        }

        payPendingCZDiamondDarkside(_pid);
        if (_pid == 0)
            payPendingUSDCReward();

        if (!isNFTHarvest && pool.tokenType == 2) {
            // I don't think we need to verify we recieved the NFT as safeTransferFrom checks this sufficiently.
            nftChef.deposit{value: address(this).balance}(pool.lpToken, address(msg.sender), _amountOrId);

            user.amount = user.amount + 1;
            pool.totalLocked = pool.totalLocked + 1;
        } else if (pool.tokenType != 2 && _amountOrId > 0) {
            // Accept the balance of coins we recieve (useful for coins which take fees).
            uint256 previousBalance = ERC20(pool.lpToken).balanceOf(address(this));
            IERC20(pool.lpToken).safeTransferFrom(address(msg.sender), address(this), _amountOrId);
            _amountOrId = ERC20(pool.lpToken).balanceOf(address(this)) - previousBalance;
            require(_amountOrId > 0, "0 recieved");

            if (pool.depositFeeBPOrNFTMaticFee > 0 && !isNativeToken(address(pool.lpToken))) {
                uint256 depositFee = ((_amountOrId * pool.depositFeeBPOrNFTMaticFee) / 10000);
                // For LPs darkside handles it 100%, destroys and distributes
                uint256 darksideDepositFee = pool.tokenType == 1 ? depositFee : (depositFee / 4);
                IERC20(pool.lpToken).safeTransfer(address(darkside), darksideDepositFee);
                // darkside handles all LP type tokens
                darkside.swapDepositFeeForETH(address(pool.lpToken), pool.tokenType);

                if (pool.tokenType == 0)
                    IERC20(pool.lpToken).safeTransfer(address(CZDiamond), depositFee - darksideDepositFee);

                CZDiamond.convertDepositFeesToUSDC(address(pool.lpToken), pool.tokenType);

                user.amount = (user.amount + _amountOrId) - depositFee;
                pool.totalLocked = (pool.totalLocked + _amountOrId) - depositFee;
            } else {
                user.amount = user.amount + _amountOrId;

                pool.totalLocked = pool.totalLocked + _amountOrId;
            }
        }

        user.darksideRewardDebt = ((user.amount * pool.accDarksidePerShare) / 1e24);
        user.CZDiamondRewardDebt = ((user.amount * pool.accCZDiamondPerShare) / 1e24);

        if (_pid == 0)
            user.usdcRewardDebt = ((user.amount * accDepositUSDCRewardPerShare) / 1e24);

        skimPool(_pid);

        emit Deposit(msg.sender, _pid, _amountOrId);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amountOrId) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.tokenType == 2 || user.amount >= _amountOrId, "!withdraw");

        require(!(_pid == 0 && isFounder(msg.sender)) || block.number > startBlock + (60 * 43200),
                "early!");

        updatePool(_pid);

        payPendingCZDiamondDarkside(_pid);
        if (_pid == 0)
            payPendingUSDCReward();

        uint256 withdrawQuantity = 0;

        if (pool.tokenType == 2) {
            nftChef.withdraw(pool.lpToken, address(msg.sender), _amountOrId);

            withdrawQuantity = 1;
        } else if (_amountOrId > 0) {
            IERC20(pool.lpToken).safeTransfer(address(msg.sender), _amountOrId);

            withdrawQuantity = _amountOrId;
        }

        user.amount = user.amount - withdrawQuantity;
        pool.totalLocked = pool.totalLocked - withdrawQuantity;

        user.darksideRewardDebt = ((user.amount * pool.accDarksidePerShare) / 1e24);
        user.CZDiamondRewardDebt = ((user.amount * pool.accCZDiamondPerShare) / 1e24);

        if (_pid == 0)
            user.usdcRewardDebt = ((user.amount * accDepositUSDCRewardPerShare) / 1e24);

        skimPool(_pid);

        emit Withdraw(msg.sender, _pid, _amountOrId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;

        require(!(_pid == 0 && isFounder(msg.sender)) || block.number > startBlock + (60 * 43200),
                "early!");

        if (pool.tokenType == 2)
            nftChef.emergencyWithdraw(pool.lpToken, address(msg.sender));
        else
            IERC20(pool.lpToken).safeTransfer(address(msg.sender), amount);

        user.amount = 0;
        user.darksideRewardDebt = 0;
        user.CZDiamondRewardDebt = 0;
        user.usdcRewardDebt = 0;

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.totalLocked >=  amount)
            pool.totalLocked = pool.totalLocked - amount;
        else
            pool.totalLocked = 0;

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay pending DARKSIDEs & CZDIAMONDs.
    function payPendingCZDiamondDarkside(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 darksidePending = ((user.amount * pool.accDarksidePerShare) / 1e24) - user.darksideRewardDebt;
        uint256 CZDiamondPending = ((user.amount * pool.accCZDiamondPerShare) / 1e24) - user.CZDiamondRewardDebt;

        if (darksidePending > 0) {
            // burn founders darkside harvest, without triggering CZD re-mint distro.
            if (isFounder(msg.sender))
                safeTokenDarksideBurn(darksidePending);
            else {
                // send rewards
                safeTokenTransfer(address(darkside), msg.sender, darksidePending);
                payReferralCommission(msg.sender, darksidePending);
            }
        }
        if (CZDiamondPending > 0) {
            // send rewards
            if (isFounder(msg.sender))
                safeTokenTransfer(address(CZDiamond), BURN_ADDRESS, CZDiamondPending);
            else
                safeTokenTransfer(address(CZDiamond), msg.sender, CZDiamondPending);
        }
    }

    // Pay pending USDC from the CZDiamond staking reward scheme.
    function payPendingUSDCReward() internal {
        UserInfo storage user = userInfo[0][msg.sender];

        uint256 usdcPending = ((user.amount * accDepositUSDCRewardPerShare) / 1e24) - user.usdcRewardDebt;

        if (usdcPending > 0) {
            // send rewards
            CZDiamond.transferUSDCToUser(msg.sender, usdcPending);
        }
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough DARKSIDEs.
    function safeTokenDarksideBurn(uint256 _amount) internal {
        uint256 darksideBalance = darkside.balanceOf(address(this));
        if (_amount > darksideBalance) {
            darkside.burn(darksideBalance);
        } else {
            darkside.burn(_amount);
        }
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough DARKSIDEs.
    function safeTokenTransfer(address token, address _to, uint256 _amount) internal {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if (_amount > tokenBal) {
            IERC20(token).safeTransfer(_to, tokenBal);
        } else {
            IERC20(token).safeTransfer(_to, _amount);
        }
    }

    // To receive MATIC from depositers when depositing NFTs
    receive() external payable {}

    // Update the darkside referral contract address by the owner
    function setDarksideReferral(IDarksideReferral _darksideReferral) external onlyOwner {
        require(address(_darksideReferral) != address(0), "!0 address");
        require(address(darksideReferral) == address(0), "!unset");
        darksideReferral = _darksideReferral;

        emit SetDarksideReferral(address(darksideReferral));
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(darksideReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = darksideReferral.getReferrer(_user);
            uint256 commissionAmount = ((_pending * referralCommissionRate) / 10000);

            if (referrer != address(0) && commissionAmount > 0) {
                darkside.mint(referrer, commissionAmount / 2);
                darkside.mint(_user, commissionAmount - (commissionAmount / 2));
                darksideReferral.recordReferralCommission(referrer, commissionAmount);
            }
        }
    }
}


// File contracts/presale/L3ArcSwap.sol

pragma solidity ^0.8.0;


contract L3ArcSwap is Ownable, ReentrancyGuard {

    address public constant feeAddress = 0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31;

    address public constant arcadiumAddress = 0x3F374ed3C8e61A0d250f275609be2219005c021e;
    address public immutable preCZDiamondAddress;
    address public immutable preDarksideAddress;

    uint256 public constant arcSwapPresaleSize = 834686 * (10 ** 18);

    uint256 public preCZDiamondSaleINVPriceE35 = 1543664 * (10 ** 27);
    uint256 public preDarksideSaleINVPriceE35 = 12863864 * (10 ** 27);

    uint256 public preCZDiamondMaximumAvailable = (arcSwapPresaleSize * preCZDiamondSaleINVPriceE35) / 1e35;
    uint256 public preDarksideMaximumAvailable = (arcSwapPresaleSize * preDarksideSaleINVPriceE35) / 1e35;

    // We use a counter to defend against people sending pre{CZDiamond,Darkside} back
    uint256 public preCZDiamondRemaining = preCZDiamondMaximumAvailable;
    uint256 public preDarksideRemaining = preDarksideMaximumAvailable;

    uint256 public constant oneHourMatic = 1500;
    uint256 public constant presaleDuration = 71999;

    uint256 public startBlock;
    uint256 public endBlock = startBlock + presaleDuration;

    event PrePurchased(address sender, uint256 arcadiumSpent, uint256 preCZDiamondReceived, uint256 preDarksideReceived);
    event RetrieveDepreciatedArcTokens(address feeAddress, uint256 tokenAmount);
    event SaleINVPricesE35Changed(uint256 newCZDiamondSaleINVPriceE35, uint256 newDarksideSaleINVPriceE35);
    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);

    constructor(uint256 _startBlock, address _preCZDiamondAddress, address _preDarksideAddress) {
        require(block.number < _startBlock, "cannot set start block in the past!");
        require(arcadiumAddress != _preCZDiamondAddress, "arcadiumAddress cannot be equal to preCZDiamond");
        require(_preCZDiamondAddress != _preDarksideAddress, "preCZDiamond cannot be equal to preDarkside");
        require(_preCZDiamondAddress != address(0), "_preCZDiamondAddress cannot be the zero address");
        require(_preDarksideAddress != address(0), "_preDarksideAddress cannot be the zero address");

        startBlock = _startBlock;
        endBlock   = _startBlock + presaleDuration;

        preCZDiamondAddress = _preCZDiamondAddress;
        preDarksideAddress = _preDarksideAddress;
    }

    function swapArcForPresaleTokensL3(uint256 arcadiumToSwap) external nonReentrant {
        require(msg.sender != feeAddress, "fee address cannot partake in presale");
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(preCZDiamondRemaining > 0 && preDarksideRemaining > 0, "No more presale tokens remaining! Come back next time!");
        require(IERC20(preCZDiamondAddress).balanceOf(address(this)) > 0, "No more PreCZDiamond left! Come back next time!");
        require(IERC20(preDarksideAddress).balanceOf(address(this)) > 0, "No more PreDarkside left! Come back next time!");
        require(arcadiumToSwap > 1e6, "not enough arcadium provided");

        uint256 originalPreCZDiamondAmount = (arcadiumToSwap * preCZDiamondSaleINVPriceE35) / 1e35;
        uint256 originalPreDarksideAmount = (arcadiumToSwap * preDarksideSaleINVPriceE35) / 1e35;

        uint256 preCZDiamondPurchaseAmount = originalPreCZDiamondAmount;
        uint256 preDarksidePurchaseAmount = originalPreDarksideAmount;

        // if we dont have enough left, give them the rest.
        if (preCZDiamondRemaining < preCZDiamondPurchaseAmount)
            preCZDiamondPurchaseAmount = preCZDiamondRemaining;

        if (preDarksideRemaining < preDarksidePurchaseAmount)
            preDarksidePurchaseAmount = preDarksideRemaining;


        require(preCZDiamondPurchaseAmount > 0, "user cannot purchase 0 preCZDiamond");
        require(preDarksidePurchaseAmount > 0, "user cannot purchase 0 preDarkside");

        // shouldn't be possible to fail these asserts.
        assert(preCZDiamondPurchaseAmount <= preCZDiamondRemaining);
        assert(preCZDiamondPurchaseAmount <= IERC20(preCZDiamondAddress).balanceOf(address(this)));

        assert(preDarksidePurchaseAmount <= preDarksideRemaining);
        assert(preDarksidePurchaseAmount <= IERC20(preDarksideAddress).balanceOf(address(this)));


        require(IERC20(preCZDiamondAddress).transfer(msg.sender, preCZDiamondPurchaseAmount), "failed sending preCZDiamond");
        require(IERC20(preDarksideAddress).transfer(msg.sender, preDarksidePurchaseAmount), "failed sending preDarkside");

        preCZDiamondRemaining = preCZDiamondRemaining - preCZDiamondPurchaseAmount;
        preDarksideRemaining = preDarksideRemaining - preDarksidePurchaseAmount;

        require(IERC20(arcadiumAddress).transferFrom(msg.sender, address(this), arcadiumToSwap), "failed to collect arcadium from user");

        emit PrePurchased(msg.sender, arcadiumToSwap, preCZDiamondPurchaseAmount, preDarksidePurchaseAmount);
    }


    function sendDepreciatedArcToFeeAddress() external onlyOwner {
        require(block.number > endBlock, "can only retrieve excess tokens after arcadium swap has ended");

        uint256 arcadiumInContract = IERC20(arcadiumAddress).balanceOf(address(this));

        if (arcadiumInContract > 0)
            IERC20(arcadiumAddress).transfer(feeAddress, arcadiumInContract);

        emit RetrieveDepreciatedArcTokens(feeAddress, arcadiumInContract);
    }

    function setSaleINVPriceE35(uint256 _newPreCZDiamondSaleINVPriceE35, uint256 _newPreDarksideSaleINVPriceE35) external onlyOwner {
        require(block.number < startBlock - (oneHourMatic * 4), "cannot change price 4 hours before start block");
        require(_newPreCZDiamondSaleINVPriceE35 >= 1 * (10 ** 32), "new CZD price is to high!");
        require(_newPreCZDiamondSaleINVPriceE35 <= 1 * (10 ** 34), "new CZD price is too low!");

        require(_newPreDarksideSaleINVPriceE35 >= 9 * (10 ** 32), "new Darkside price is to high!");
        require(_newPreDarksideSaleINVPriceE35 <= 9 * (10 ** 34), "new Darkside price is too low!");

        preCZDiamondSaleINVPriceE35 = _newPreCZDiamondSaleINVPriceE35;
        preDarksideSaleINVPriceE35 = _newPreDarksideSaleINVPriceE35;

        preCZDiamondMaximumAvailable = (arcSwapPresaleSize * preCZDiamondSaleINVPriceE35) / 1e35;
        preDarksideMaximumAvailable  = (arcSwapPresaleSize * preDarksideSaleINVPriceE35) / 1e35;

        preCZDiamondRemaining = preCZDiamondMaximumAvailable;
        preDarksideRemaining = preDarksideMaximumAvailable;

        emit SaleINVPricesE35Changed(preCZDiamondSaleINVPriceE35, preDarksideSaleINVPriceE35);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
    }
}


// File contracts/presale/L3MFSwap.sol

pragma solidity ^0.8.0;


contract L3MFSwap is Ownable, ReentrancyGuard {

    address public constant feeAddress = 0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31;

    address public constant myFriendsAddress = 0xa509Da749745Ac07E9Ae47E7a092eAd2648B47f2;
    address public immutable preCZDiamondAddress;
    address public immutable preDarksideAddress;

    uint256 public constant mfSwapPresaleSize = 66800 * (10 ** 18);

    uint256 public preCZDiamondSaleINVPriceE35 = 25621640 * (10 ** 27);
    uint256 public preDarksideSaleINVPriceE35 = 213513666 * (10 ** 27);

    uint256 public preCZDiamondMaximumAvailable = (mfSwapPresaleSize * preCZDiamondSaleINVPriceE35) / 1e35;
    uint256 public preDarksideMaximumAvailable = (mfSwapPresaleSize * preDarksideSaleINVPriceE35) / 1e35;

    // We use a counter to defend against people sending pre{CZDiamond,Darkside} back
    uint256 public preCZDiamondRemaining = preCZDiamondMaximumAvailable;
    uint256 public preDarksideRemaining = preDarksideMaximumAvailable;

    uint256 public constant oneHourMatic = 1500;
    uint256 public constant presaleDuration = 71999;

    uint256 public startBlock;
    uint256 public endBlock = startBlock + presaleDuration;

    event PrePurchased(address sender, uint256 myFriendsSpent, uint256 preCZDiamondReceived, uint256 preDarksideReceived);
    event RetrieveDepreciatedMFTokens(address feeAddress, uint256 tokenAmount);
    event SaleINVPricesE35Changed(uint256 newCZDiamondSaleINVPriceE35, uint256 newDarksideSaleINVPriceE35);
    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);

    constructor(uint256 _startBlock, address _preCZDiamondAddress, address _preDarksideAddress) {
        require(block.number < _startBlock, "cannot set start block in the past!");
        require(myFriendsAddress != _preCZDiamondAddress, "myFriendsAddress cannot be equal to preCZDiamond");
        require(_preCZDiamondAddress != _preDarksideAddress, "preCZDiamond cannot be equal to preDarkside");
        require(_preCZDiamondAddress != address(0), "_preCZDiamondAddress cannot be the zero address");
        require(_preDarksideAddress != address(0), "_preDarksideAddress cannot be the zero address");

        startBlock = _startBlock;
        endBlock   = _startBlock + presaleDuration;

        preCZDiamondAddress = _preCZDiamondAddress;
        preDarksideAddress = _preDarksideAddress;
    }

    function swapMFForPresaleTokensL3(uint256 myFriendsToSwap) external nonReentrant {
        require(msg.sender != feeAddress, "fee address cannot partake in presale");
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(preCZDiamondRemaining > 0 && preDarksideRemaining > 0, "No more presale tokens remaining! Come back next time!");
        require(IERC20(preCZDiamondAddress).balanceOf(address(this)) > 0, "No more PreCZDiamond left! Come back next time!");
        require(IERC20(preDarksideAddress).balanceOf(address(this)) > 0, "No more PreDarkside left! Come back next time!");
        require(myFriendsToSwap > 1e6, "not enough MyFriends provided");

        uint256 originalPreCZDiamondAmount = (myFriendsToSwap * preCZDiamondSaleINVPriceE35) / 1e35;
        uint256 originalPreDarksideAmount = (myFriendsToSwap * preDarksideSaleINVPriceE35) / 1e35;

        uint256 preCZDiamondPurchaseAmount = originalPreCZDiamondAmount;
        uint256 preDarksidePurchaseAmount = originalPreDarksideAmount;

        // if we dont have enough left, give them the rest.
        if (preCZDiamondRemaining < preCZDiamondPurchaseAmount)
            preCZDiamondPurchaseAmount = preCZDiamondRemaining;

        if (preDarksideRemaining < preDarksidePurchaseAmount)
            preDarksidePurchaseAmount = preDarksideRemaining;


        require(preCZDiamondPurchaseAmount > 0, "user cannot purchase 0 preCZDiamond");
        require(preDarksidePurchaseAmount > 0, "user cannot purchase 0 preDarkside");

        // shouldn't be possible to fail these asserts.
        assert(preCZDiamondPurchaseAmount <= preCZDiamondRemaining);
        assert(preCZDiamondPurchaseAmount <= IERC20(preCZDiamondAddress).balanceOf(address(this)));

        assert(preDarksidePurchaseAmount <= preDarksideRemaining);
        assert(preDarksidePurchaseAmount <= IERC20(preDarksideAddress).balanceOf(address(this)));


        require(IERC20(preCZDiamondAddress).transfer(msg.sender, preCZDiamondPurchaseAmount), "failed sending preCZDiamond");
        require(IERC20(preDarksideAddress).transfer(msg.sender, preDarksidePurchaseAmount), "failed sending preDarkside");

        preCZDiamondRemaining = preCZDiamondRemaining - preCZDiamondPurchaseAmount;
        preDarksideRemaining = preDarksideRemaining - preDarksidePurchaseAmount;

        require(IERC20(myFriendsAddress).transferFrom(msg.sender, address(this), myFriendsToSwap), "failed to collect myFriends from user");

        emit PrePurchased(msg.sender, myFriendsToSwap, preCZDiamondPurchaseAmount, preDarksidePurchaseAmount);
    }


    function sendDepreciatedMFToFeeAddress() external onlyOwner {
        require(block.number > endBlock, "can only retrieve excess tokens after myfriends swap has ended");

        uint256 myFriendsInContract = IERC20(myFriendsAddress).balanceOf(address(this));

        if (myFriendsInContract > 0)
            IERC20(myFriendsAddress).transfer(feeAddress, myFriendsInContract);

        emit RetrieveDepreciatedMFTokens(feeAddress, myFriendsInContract);
    }

    function setSaleINVPriceE35(uint256 _newPreCZDiamondSaleINVPriceE35, uint256 _newPreDarksideSaleINVPriceE35) external onlyOwner {
        require(block.number < startBlock - (oneHourMatic * 4), "cannot change price 4 hours before start block");
        require(_newPreCZDiamondSaleINVPriceE35 >= 2 * (10 ** 33), "new myfriends price is to high!");
        require(_newPreCZDiamondSaleINVPriceE35 <= 28 * (10 ** 34), "new myfriends price is too low!");

        require(_newPreDarksideSaleINVPriceE35 >= 2 * (10 ** 34), "new darkside price is to high!");
        require(_newPreDarksideSaleINVPriceE35 <= 23 * (10 ** 35), "new darkside price is too low!");

        preCZDiamondSaleINVPriceE35 = _newPreCZDiamondSaleINVPriceE35;
        preDarksideSaleINVPriceE35 = _newPreDarksideSaleINVPriceE35;

        preCZDiamondMaximumAvailable = (mfSwapPresaleSize * preCZDiamondSaleINVPriceE35) / 1e35;
        preDarksideMaximumAvailable  = (mfSwapPresaleSize * preDarksideSaleINVPriceE35) / 1e35;

        preCZDiamondRemaining = preCZDiamondMaximumAvailable;
        preDarksideRemaining = preDarksideMaximumAvailable;

        emit SaleINVPricesE35Changed(preCZDiamondSaleINVPriceE35, preDarksideSaleINVPriceE35);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
    }
}


// File contracts/presale/L3TokenRedeem.sol

pragma solidity ^0.8.0;



contract L3TokenRedeem is Ownable, ReentrancyGuard {

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public constant feeAddress = 0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31;

    address public immutable preCZDiamond;
    address public immutable preDarksideAddress;

    address public immutable CZDiamondAddress;
    address public immutable darksideAddress;

    L3ArcSwap public immutable l3ArcSwap;
    L3MFSwap public immutable l3MFSwap;

    uint256 public startBlock;

    bool public hasRetrievedUnsoldPresale = false;

    event CZDiamondSwap(address sender, uint256 amount);
    event DarksideSwap(address sender, uint256 amount);
    event RetrieveUnclaimedTokens(uint256 CZDiamondAmount, uint256 Darksidemount);
    event StartBlockChanged(uint256 newStartBlock);

    constructor(uint256 _startBlock, L3ArcSwap _l3ArcSwap, L3MFSwap _l3MFSwap, address _preCZDiamondAddress, address _preDarksideAddress, address _CZDiamondAddress, address _darksideAddress) {
        require(block.number < _startBlock, "cannot set start block in the past!");
        require(_preCZDiamondAddress != _preDarksideAddress, "preCZDiamond cannot be equal to preDarkside");
        require(_CZDiamondAddress != _darksideAddress, "preCZDiamond cannot be equal to preDarkside");
        require(_preCZDiamondAddress != address(0), "_preCZDiamondAddress cannot be the zero address");
        require(_CZDiamondAddress != address(0), "_CZDiamondAddress cannot be the zero address");

        startBlock = _startBlock;

        l3ArcSwap = _l3ArcSwap;
        l3MFSwap = _l3MFSwap;

        preCZDiamond = _preCZDiamondAddress;
        preDarksideAddress = _preDarksideAddress;
        CZDiamondAddress = _CZDiamondAddress;
        darksideAddress = _darksideAddress;
    }

    function swapPreCZDiamondForCZDiamond(uint256 CZDiamondSwapAmount) external nonReentrant {
        require(block.number >= startBlock, "token redemption hasn't started yet, good things come to those that wait");
        require(IERC20(CZDiamondAddress).balanceOf(address(this)) >= CZDiamondSwapAmount, "Not Enough tokens in contract for swap");

        IERC20(preCZDiamond).transferFrom(msg.sender, BURN_ADDRESS, CZDiamondSwapAmount);
        IERC20(CZDiamondAddress).transfer(msg.sender, CZDiamondSwapAmount);

        emit CZDiamondSwap(msg.sender, CZDiamondSwapAmount);
    }

    function swapPreDarksideForDarkside(uint256 darksideSwapAmount) external nonReentrant {
        require(block.number >= startBlock, "token redemption hasn't started yet, good things come to those that wait");
        require(IERC20(darksideAddress).balanceOf(address(this)) >= darksideSwapAmount, "Not Enough tokens in contract for swap");

        IERC20(preDarksideAddress).transferFrom(msg.sender, BURN_ADDRESS, darksideSwapAmount);
        IERC20(darksideAddress).transfer(msg.sender, darksideSwapAmount);

        emit DarksideSwap(msg.sender, darksideSwapAmount);
    }

    function sendUnclaimedsToFeeAddress() external onlyOwner {
        require(block.number > l3ArcSwap.endBlock(), "can only retrieve excess tokens after arc swap has ended");
        require(block.number > l3MFSwap.endBlock(), "can only retrieve excess tokens after myfriends swap has ended");
        require(!hasRetrievedUnsoldPresale, "can only burn unsold presale once!");

        uint256 wastedPreCZDiamondTokend = l3ArcSwap.preCZDiamondRemaining() + l3MFSwap.preCZDiamondRemaining();
        uint256 wastedPreDarksideTokens = l3ArcSwap.preDarksideRemaining() + l3MFSwap.preDarksideRemaining();

        require(wastedPreCZDiamondTokend <= IERC20(CZDiamondAddress).balanceOf(address(this)),
            "retreiving too much preCZDiamond, has this been setup properly?");

        require(wastedPreDarksideTokens <= IERC20(darksideAddress).balanceOf(address(this)),
            "retreiving too much preDarkside, has this been setup properly?");

        if (wastedPreCZDiamondTokend > 0)
            IERC20(CZDiamondAddress).transfer(feeAddress, wastedPreCZDiamondTokend);

        if (wastedPreDarksideTokens > 0)
            IERC20(darksideAddress).transfer(feeAddress, wastedPreDarksideTokens);

        hasRetrievedUnsoldPresale = true;

        emit RetrieveUnclaimedTokens(wastedPreCZDiamondTokend, wastedPreDarksideTokens);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit StartBlockChanged(_newStartBlock);
    }
}


// File contracts/presale/PreCZDiamond.sol

pragma solidity ^0.8.0;


// PreCZDiamond
contract PreCZDiamond is ERC20('PCZDIAMOND', 'PCZDIAMOND') {
    constructor() {
        _mint(address(0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31), uint256(30000 * (10 ** 18)));
    }
}


// File contracts/presale/PreDarkside.sol

pragma solidity ^0.8.0;


// PreDarkside
contract PreDarkside is ERC20('PDARKCOIN', 'PDARK') {
    constructor() {
        _mint(address(0x3a1D1114269d7a786C154FE5278bF5b1e3e20d31), uint256(250000 * (10 ** 18)));
    }
}