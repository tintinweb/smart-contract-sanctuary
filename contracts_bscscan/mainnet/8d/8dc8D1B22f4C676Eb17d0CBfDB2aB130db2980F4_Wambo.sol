/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// Wambo [https://wambocoin.io] - Platinum Apes 2021

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

contract Wambo is ERC20, Ownable {
	address constant UniswapRouterV2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	address constant DAI = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

	//
	constructor() ERC20("Wambo", "WAMBO") {
		excludeFromDividendsAndFees(address(this), true);

		_mint(owner(), 1000000000 * 10 ** decimals()); // 1B fixed supply fully minted

		setUniswapV2RouterAddress(UniswapRouterV2);

		// set default fee structure
		fees.dividend = 3;
		fees.lottery = 2;
		fees.liquidity = 2;
		fees.marketing = 1;
	}

	receive() external payable {} // accept BNB on contract address

	// Router v2
	IUniswapV2Router02 internal _uniswap_router;

	event UniswapV2RouterAddressUpdated(address router_address, address wambo_wbnb_pair);

	function setUniswapV2RouterAddress(address router_address) onlyOwner public {
		require(router_address != address(_uniswap_router), "WAMBO: UniswapV2 router already set to this address");

		_uniswap_router = IUniswapV2Router02(router_address);
		excludeFromDividends(router_address, true);

		address wambo_wbnb_pair = IUniswapV2Factory(_uniswap_router.factory()).createPair(address(this), _uniswap_router.WETH());
		flagAsPairContractAddress(wambo_wbnb_pair, true);

		emit UniswapV2RouterAddressUpdated(router_address, wambo_wbnb_pair);
	}

	// fee structure
	struct Fees { // 4B
		uint8 dividend; // 3
		uint8 lottery; // 2
		uint8 liquidity; // 2
		uint8 marketing; // 1
	}

	Fees public fees;

	function feesTotal() public view returns(uint8) { return fees.dividend + fees.lottery + fees.liquidity + fees.marketing; }

	function setDividendFee(uint8 fee) onlyOwner public { fees.dividend = fee; }
	function setLotteryFee(uint8 fee) onlyOwner public { fees.lottery = fee; }
	function setLiquidityFee(uint8 fee) onlyOwner public { fees.liquidity = fee; }
	function setMarketingFee(uint8 fee) onlyOwner public { fees.marketing = fee; }

	bool public enable_fees = false;

	function setEnableFees(bool enable) onlyOwner public { enable_fees = enable; }

	// wallets
	address payable private _marketing_wallet = payable(0xE4c7C123e0E3229bCe55C8D88A2E47E909006265); // receives ETH
	address payable private _lottery_wallet = payable(0x833a24ddD47302b3501F79D885ac1ad9306fe28A); // receives DAI
	address payable private _dust_wallet = payable(0xB29cc36C48d47a6795258248a8BF769251042BD5); // receives all ETH excedents

	function setMarketingWallet(address payable wallet) onlyOwner public { _marketing_wallet = wallet; }
	function setLotteryWallet(address payable wallet) onlyOwner public { _lottery_wallet = wallet; }
	function setDustWallet(address payable wallet) onlyOwner public { _dust_wallet = wallet; }

	// holders
	mapping(address => uint8) private _address_flags; // track states associated with an address

	mapping(address => uint32) private _holder_idx; // uint32 is a problem if half the Earth population ever holds this token
	address[] private _holders = [address(0)]; // index 0 is reserved and means the adress was not inserted

	uint8 constant address_has_sent_wambo = (1 << 0);
	uint8 constant address_is_excluded_from_fees = (1 << 1);
	uint8 constant address_is_excluded_from_dividends = (1 << 2);
	uint8 constant address_is_pair_contract = (1 << 4);

	function _addHolder(address holder) internal {
		if (_holder_idx[holder] == 0) {
			_holder_idx[holder] = uint32(_holders.length);
			_holders.push(holder);
		}
	}

	function getHolderCount() onlyOwner public view returns (uint32) { return uint32(_holders.length - 1); }

	function excludeFromFees(address addr, bool enable) onlyOwner public {
		enable ? _address_flags[addr] |= address_is_excluded_from_fees :
				 _address_flags[addr] &= ~address_is_excluded_from_fees;
	}

	function isExcludedFromFees(address addr) public view returns(bool) { return (_address_flags[addr] & address_is_excluded_from_fees) != 0; }

	function excludeFromDividends(address addr, bool enable) onlyOwner public {
		enable ? _address_flags[addr] |= address_is_excluded_from_dividends :
				 _address_flags[addr] &= ~address_is_excluded_from_dividends;
	}

	function isExcludedFromDividends(address addr) public view returns(bool) { return (_address_flags[addr] & (address_is_excluded_from_dividends | address_is_pair_contract)) != 0; }

	function flagAsPairContractAddress(address addr, bool flag) onlyOwner public {
		flag ? _address_flags[addr] |= address_is_pair_contract :
			   _address_flags[addr] &= ~address_is_pair_contract;
	}

	function isPairContractAddress(address addr) public view returns(bool) { return (_address_flags[addr] & address_is_pair_contract) != 0; }

	// Flag an address as an automated market maker pair contract and exclude it from fees and dividends
	function excludeFromDividendsAndFees(address pair, bool enable) onlyOwner public {
		excludeFromFees(pair, enable);
		excludeFromDividends(pair, enable);
	}

	/*
		Return holder informations for the lottery.

		Note: This function intentionally wraps the provided index so that you can feed it a
			  32-bit number to select a random candidate without risking a race condition.
	*/
	function getHolderInfo(uint32 idx) public view returns (address, uint256, bool) {
		address holder = _holders[(idx % getHolderCount()) + 1];
		return (holder, balanceOf(holder), _address_flags[holder] & address_has_sent_wambo != 0);
	}

	// dividends
	event DividendsDistributed(uint256 amount);
	event DividendWithdrawn(address receiver, uint256 amount);

	mapping(address => int256) internal _magnified_dividend_corrections;
	mapping(address => uint256) internal _withdrawn_dividends;

	uint256 internal _magnified_dividend_per_token;
	uint256 constant internal _fixed_point_precision = 2**128;

	uint256 private _minimum_holder_balance_for_dividends_withdrawal = 200000 * 10 ** decimals(); // defaults to 200K token

	// Set the minimum balance required for a holder to receive dividends.
	function setMinimumHolderBalanceForDividendsWithdrawal(uint256 amount) onlyOwner public {
		_minimum_holder_balance_for_dividends_withdrawal = amount;
	}

	uint256 public total_dividends_distributed;

	function _distributeDividends(uint256 amount) internal {
		require(totalSupply() > 0);

		total_dividends_distributed += amount;

		if (amount > 0)
			_magnified_dividend_per_token += (amount * _fixed_point_precision) / totalSupply();

		emit DividendsDistributed(amount);
	}

	function _totalDividendOf(address holder) internal view returns(int256) {
		int256 total_dividend = int256(balanceOf(holder) * _magnified_dividend_per_token) + _magnified_dividend_corrections[holder];
		return total_dividend / int256(_fixed_point_precision);
	}

	function _withdrawableDividendOf(address holder) internal view returns(int256) {
		return _totalDividendOf(holder) - int256(_withdrawn_dividends[holder]);
	}

	function _withdrawnDividendOf(address holder) internal view returns(uint256) {
		return _withdrawn_dividends[holder];
	}

	function _withdrawDividendToHolder(address holder) internal {
		int256 withdrawable_dividend = _withdrawableDividendOf(holder);

		if (withdrawable_dividend > 0) {
			_withdrawn_dividends[holder] += uint256(withdrawable_dividend); // dividends are either withdrawn or forfeited

			if (!isExcludedFromDividends(holder))
				if (balanceOf(holder) >= _minimum_holder_balance_for_dividends_withdrawal) {
					payable(holder).transfer(uint256(withdrawable_dividend)); // transfer from contract coin balance to holder wallet
					emit DividendWithdrawn(holder, uint256(withdrawable_dividend));
				}
		}
	}

	// swap
	function _swapWamboToDAI(uint256 wambo_amount, address recipient) internal {
		address[] memory path = new address[](3); // Wambo->WETH->DAI
		path[0] = address(this);
		path[1] = _uniswap_router.WETH();
		path[2] = DAI;

		_approve(address(this), address(_uniswap_router), wambo_amount);
		_uniswap_router.swapExactTokensForTokensSupportingFeeOnTransferTokens(wambo_amount, 0, path, recipient, block.timestamp);
	}

	function _swapWamboToETH(uint256 wambo_amount, address recipient) internal returns(uint256) {
		uint256 eth_amount = recipient.balance;

		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _uniswap_router.WETH();

		_approve(address(this), address(_uniswap_router), wambo_amount);
		_uniswap_router.swapExactTokensForETHSupportingFeeOnTransferTokens(wambo_amount, 0, path, recipient, block.timestamp);

		return recipient.balance - eth_amount;
	}

	event LiquidityAdded(uint256 wambo_amount, uint256 eth_amount);

	function _sendWamboToLiquidityPool(uint256 wambo_amount) internal {
		uint256 wambo_amount_to_swap = wambo_amount / 2;
		wambo_amount -= wambo_amount_to_swap;

		uint256 eth_amount = _swapWamboToETH(wambo_amount_to_swap, address(this));

		_approve(address(this), address(_uniswap_router), wambo_amount);
		_uniswap_router.addLiquidityETH{value: eth_amount}(address(this), wambo_amount, 0, 0, address(0), block.timestamp);

		emit LiquidityAdded(wambo_amount, eth_amount);
	}

	function _sendWamboToLotteryWallet(uint256 wambo_amount) internal {
		if (_lottery_wallet != address(0))
			_swapWamboToDAI(wambo_amount, _lottery_wallet);
	}

	function _sendWamboToMarketingWallet(uint256 wambo_amount) internal {
		if (_marketing_wallet != address(0))
			_swapWamboToETH(wambo_amount, _marketing_wallet);
	}

	function _transferContractETHToDustWallet() internal {
		if (_dust_wallet != address(0))
			_dust_wallet.transfer(address(this).balance);
	}

	// fee tokens processing
	event ProcessFeesStarted(uint256 wambo_amount);
	event WithdrawnDividendsToHolders(uint256 holder_count, uint256 gas_consumed);
	event ProcessFeesEnded();

	bool internal _processing_fees; // 1B

	uint8 public fee_cycle_stage; // 1B
	Fees internal _fee_cycle_fees; // 4B

	uint32 public fee_processing_gas_limit = 200000; // defaults to 200 Kwei
	uint64 private _next_holder_idx_to_withdraw;

	uint256 public fee_cycle_wambo_amount;
	uint256 public minimum_wambo_to_start_fee_cycle = 2000000 * 10 ** decimals();

	// Set the maximum amount of gas to be used for fee tokens processing
	function setFeeProcessingGasLimit(uint256 limit) onlyOwner public {
		require(limit >= 200000 && limit <= 600000, "WAMBO: Fee processing gas limit must be between 200 and 600 Kwei");
		fee_processing_gas_limit = uint32(limit);
	}

	// Once the accumulated wambo on the contract address reach this threshold the withdraw cycle starts
	function setMinimumWamboToStartFeeCycle(uint256 amount) onlyOwner public { minimum_wambo_to_start_fee_cycle = amount; }

	function _cycleFeesTotal() internal view returns(uint8) {
		return _fee_cycle_fees.dividend + _fee_cycle_fees.liquidity + _fee_cycle_fees.lottery + _fee_cycle_fees.marketing;
	}

	function _execFeeCycle(bool sender_is_pair) internal {
		_processing_fees = true;

		if (fee_cycle_stage == 0) {
			_fee_cycle_fees = fees; // store cycle invariant

			if (_cycleFeesTotal() > 0) {
				fee_cycle_wambo_amount = balanceOf(address(this)); // store cycle invariant

				if (fee_cycle_wambo_amount >= minimum_wambo_to_start_fee_cycle) {
					emit ProcessFeesStarted(fee_cycle_wambo_amount);
					_transferContractETHToDustWallet(); // transfer ETH that was sent to the contract to the dust wallet
					++fee_cycle_stage;
				}
			}
		} else if (fee_cycle_stage == 1) {
			if (!sender_is_pair) {
				_sendWamboToLiquidityPool((fee_cycle_wambo_amount * _fee_cycle_fees.liquidity) / _cycleFeesTotal());
				++fee_cycle_stage;
			}
		} else if (fee_cycle_stage == 2) {
			if (!sender_is_pair) {
				_sendWamboToLotteryWallet((fee_cycle_wambo_amount * _fee_cycle_fees.lottery) / _cycleFeesTotal());
				++fee_cycle_stage;
			}
		} else if (fee_cycle_stage == 3) {
			if (!sender_is_pair) {
				_sendWamboToMarketingWallet((fee_cycle_wambo_amount * _fee_cycle_fees.marketing) / _cycleFeesTotal());
				++fee_cycle_stage;
			}
		} else if (fee_cycle_stage == 4) {
			if (!sender_is_pair) {
				// swap tokens to ETH on the contract address to distribute to holders
				uint256 eth_amount = _swapWamboToETH((fee_cycle_wambo_amount * _fee_cycle_fees.dividend) / _cycleFeesTotal(), address(this)); // note: any wambo dust is left for the next cycle to deal with
				_distributeDividends(eth_amount);
				_next_holder_idx_to_withdraw = 1; // holder 0 is reserved
				++fee_cycle_stage;
			}
		} else if (fee_cycle_stage == 5) {
			uint16 holder_processed = 0;

			// withdraw holder dividends until we hit our gas limit
			uint256 gas_consumed = 0;
			uint256 ref_gasleft = gasleft();

			while (fee_cycle_stage == 5) {
				gas_consumed = ref_gasleft - gasleft();
				if (gas_consumed >= fee_processing_gas_limit)
					break; // enforce gas limit

				_withdrawDividendToHolder(_holders[_next_holder_idx_to_withdraw]);

				++_next_holder_idx_to_withdraw;
				++holder_processed;

				if (_next_holder_idx_to_withdraw == _holders.length) {
					fee_cycle_stage = 0;
					emit ProcessFeesEnded();
				}
			}

			emit WithdrawnDividendsToHolders(holder_processed, gas_consumed);
		}

		_processing_fees = false;
	}

	event WamboFeesTransferredToContract(uint256 amount);

	function _transferWamboFeesToContract(address sender, uint256 wambo_amount) internal returns (uint256) {
		uint256 fees_in_wambo = (wambo_amount * feesTotal()) / 100;
		super._transfer(sender, address(this), fees_in_wambo);
		emit WamboFeesTransferredToContract(fees_in_wambo);
		return fees_in_wambo;
	}

	uint256 public buy_limit; // prevent whales from buying too much of the supply on launch

	function setBuyLimit(uint256 limit) onlyOwner public { buy_limit = limit; }

	function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
		bool sender_is_pair_contract = isPairContractAddress(sender);

		// buy limit
		require(!sender_is_pair_contract || buy_limit == 0 || amount <= buy_limit, 'WAMBO: Buy limit in effect, try a lower amount');

		// flag sender
		_address_flags[sender] |= address_has_sent_wambo;

		// fees
		if (!_processing_fees) {
			bool take_fees = enable_fees && !isExcludedFromFees(sender) && !isExcludedFromFees(recipient);

			if (take_fees)
				amount -= _transferWamboFeesToContract(sender, amount);

			_execFeeCycle(sender_is_pair_contract); // some operations cannot be carried out if the sender is a liquidity pair contract
		}

		// send remaining wambo to the recipient
		super._transfer(sender, recipient, amount);

		// recipient becomes a holder (if we're not doing a swap)
		if (!_processing_fees)
			_addHolder(recipient);

		// update dividend correction terms so that _totalDividendOf remains constant despite the sender and receiver balances changing
		int256 magnified_correction_term = int256(_magnified_dividend_per_token * amount);
		_magnified_dividend_corrections[sender] += magnified_correction_term;
		_magnified_dividend_corrections[recipient] -= magnified_correction_term;
	}
}