/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

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

// File: contracts/IDomePeak.sol

// contracts/DomePeak.sol

pragma solidity 0.8.11;


interface IDomePeak is IERC20 {
    function upgradeToken(uint256 amount, address tokenHolder) external returns (uint256);
}
// File: contracts/IRToken.sol

// contracts/DomePeak.sol

pragma solidity 0.8.11;


interface IRToken is IERC20 {
    function buy(uint256 minTokensRequested) external payable;
    function sell(uint256 amount) external;
    function quoteAvgPriceForTokens(uint256 amount) external view returns (uint256);
    function updatePhase() external;
    function getPhase() external returns (uint8);
    function mintBonus() external;
    function addApprovedToken(address newToken) external;
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

// File: contracts/DomePeak.sol

// contracts/DomePeak.sol

pragma solidity 0.8.11;





/** @title Dome Peak Contract. */
contract DomePeak is IDomePeak, ERC20 {

    // Declare uniswap V2 router.  External but trusted contract maintained by Uniswap.org
    IUniswapV2Router02 private uniswapRouter;

    // Declare Reserve Token interface
    IRToken private rToken;

    // -- Declare addresses for uniswap router, uniswap pairs, and reserve contract/wallets --
    address private UNISWAP_ROUTER_ADDRESS; // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private PAXG; // 0x45804880De22913dAFE09f4980848ECE6EcbAf78;
    address private WBTC; // 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private RESERVE;
    address private UPGRADE_TOKEN;

    // -- Ratios of coins --
    uint32 private constant R_WBTC = 1;
    uint32 private constant R_ETH = 13;
    uint32 private constant R_PAXG = 27;
    uint32 private constant R_RESERVE = 24327;

    // -- Constants--
    // supply of reserve tokens at the end of phase 1
    uint256 internal constant PHASE_1_END_SUPPLY = 65e6 * 1e18; 
    // supply of reserve tokens at the end of phase 1
    uint256 internal constant PHASE_2_END_SUPPLY = 68333333333333333333333333;
    // maximum buy order size (ether)
    uint256 internal constant MAX_BUY_ORDER = 2000 ether;
    // maximum sell order size (DomePeak)
    uint256 internal constant MAX_SELL_ORDER = 400e3 * 1e18;    

    // -- Track remaining bonus tokens, used in the event of rounding errors --
    uint256 private remAlphaBonus = 7.5e6 * 1e18;
    uint256 private remBetaBonus = 4.5e6 * 1e18;
    uint256 private remGammaBonus = 3e6 * 1e18;
    uint256 private remAlphaRTokens = 6666666666666666666666667;
    uint256 private remBetaRTokens = 6666666666666666666666667;
    uint256 private remGammaRTokens = 6666666666666666666666666;
        
    // -- Declare state variables --
    address private owner;  // Contract owner

    /** @dev DomePeak Token Constructor
     *  @param _reserveToken Address of reserve token
     *  @param _paxg Address of PAXG
     *  @param _wbtc Address of WBTC
     *  @param _uniswapRouter Address of Uniswap V2 Router     
     */
    constructor(address _reserveToken, address _paxg, address _wbtc, address _uniswapRouter) 
        ERC20("DomePeak001", "DPC001") {
        
        // Instantiate uniswap router
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);

        // Instantiate reserve token
        rToken = IRToken(_reserveToken);

        // Assign contract owner
        owner = address(msg.sender);

        UNISWAP_ROUTER_ADDRESS = _uniswapRouter;
        PAXG = _paxg;
        WBTC = _wbtc;
        RESERVE = _reserveToken;
        UPGRADE_TOKEN = msg.sender; // Initially, set the upgrade token address to the owner
    }

    /** @dev buyDomePeak exchanges sent Ether for a Dome Peak Token, which represents a basket of tokens
     * @param deadline Deadline after which the transaction will revert if not processed
     * @param priceWBTC Max price (in wei) for one unit of wbtc
     * @param pricePAXG Max price (in wei) for one unit of paxg
     */
    function buyDomePeak(uint256 deadline, uint256 priceWBTC, uint256 pricePAXG) external payable {
        require(deadline >= block.timestamp, "Deadline expired");
        require(msg.value <= MAX_BUY_ORDER, "Buy exceeded the maximum purchase amount");
        
        uint256 PriceOfBase;
        uint256 PriceOfBaseWBTC;
        uint256 PriceOfBasePAXG;
        uint256 PriceOfBaseEth;
        uint256 PriceOfReserve;
        uint256 prevRTokenTotalSupply = rToken.totalSupply();
        uint256 balance = address(this).balance;

        // This is the lowest price (in WEI) of one unit of DomePeak (1e-4 DomePeak)
        (PriceOfBase, PriceOfBaseWBTC, PriceOfBasePAXG, PriceOfBaseEth, PriceOfReserve) = getPriceOfBase();
        
        // Now calculate how many units of DomePeak we can purchase
        require(baseTokensToMint(PriceOfBase) >= 1, "Not enough Ether to purchase .0001 DomePeak");
       
        require(1e4 * PriceOfBaseWBTC / R_WBTC <= priceWBTC, "Maximum wbtc price exceeded.");
        require(1e4 * PriceOfBasePAXG / R_PAXG <= pricePAXG, "Maximum paxg price exceeded.");

        // Transfer 1% of the Base Price to reserve
        payable(RESERVE).transfer(PriceOfBase * baseTokensToMint(PriceOfBase) * 1 / 100);

        // 101/100 send 1% more in case of underflow
        rToken.buy{value: baseTokensToMint(PriceOfBase) * PriceOfReserve * 101 / 100}(reserveTokensToMint(baseTokensToMint(PriceOfBase)));

        // Purchase WBTC
        //   1e4 accounts for 8 decimal places of WBTC, and that minimum purchase by this contract is 1e-4
        uniswapRouter.swapETHForExactTokens{ 
            value: (baseTokensToMint(PriceOfBase) * PriceOfBaseWBTC * 101 / 100) 
            }(baseTokensToMint(PriceOfBase) * R_WBTC * 1e4, getPathForETHtoToken(WBTC), address(this), deadline);

        // Purchase PAXG
        //   (10000 / 9998) to account for the PAXG 0.02% fee
        uniswapRouter.swapETHForExactTokens{ 
            value: (baseTokensToMint(PriceOfBase) * PriceOfBasePAXG * 101 / 100) 
            }(baseTokensToMint(PriceOfBase) * R_PAXG * 1e14 * 10000 / 9998, getPathForETHtoToken(PAXG), address(this), deadline);

        balance = msg.value - (balance - address(this).balance);  // amount of eth left in this transaction

        // Early Buyer Bonus
        if(prevRTokenTotalSupply <= PHASE_1_END_SUPPLY) {
            bool success = rToken.transfer(msg.sender, calcBonusTokens(reserveTokensToMint(baseTokensToMint(PriceOfBase))));
            require(success, "Early buyer bonus transfer failed.");
        }
        
        // Mint the DomePeak Token (basket of coins)
        _mint(msg.sender, baseTokensToMint(PriceOfBase) * 1e14);

        // Refund any leftover ETH that the contract has to the user, minus amount kept for basket.  
        //   This takes care of the ether portion of the basket, as well
        (bool successRefund,) = msg.sender.call{ value: (balance - amountEthInCoin(baseTokensToMint(PriceOfBase), PriceOfBaseEth)) }("");
        require(successRefund, "Refund failed");        
    }

    /** @dev Exchanges your DomePeak Tokens for Ether, by unwrapping the basket 
     * of tokens and selling at market price
     * @param amount Amount of DomePeak Token to exchange for Ether
     * @param deadline Deadline after which the transaction will revert if not processed
     * @param priceWBTC Min price (in wei) for one unit of wbtc
     * @param pricePAXG Min price (in wei) for one unit of paxg     
     */
    function sellDomePeak(uint256 amount, uint256 deadline, uint256 priceWBTC, uint256 pricePAXG) external payable {
        require(balanceOf(msg.sender) >= amount, "Insufficient DomePeak to sell");
        require(deadline >= block.timestamp, "Deadline expired");
        require(amount <= MAX_SELL_ORDER, "Sell exceeded maximum sale amount");

        bool success;

        uint256 amountBaseToken = (amount / 1e14) * 1e14;  // Get floor.  Mimimum amount of DomePeak Tokens to transact is .0001
        require(amountBaseToken >= 1e14, "The minimum sale amount is .0001 token");

        uint256 MinProceedsWBTC;
        uint256 MinProceedsPAXG;
        
        (MinProceedsWBTC, MinProceedsPAXG) = estimateProceeds(amountBaseToken);

        require(1e18 * MinProceedsWBTC / (amountBaseToken * R_WBTC) >= priceWBTC, "Minimum wbtc price not met.");
        require(1e18 * MinProceedsPAXG / (amountBaseToken * R_PAXG) >= pricePAXG, "Minimum paxg price not met.");

        uint256 coinValueStart = address(this).balance;

        // Swap PAXG and WBTC back to ETH
        require(IERC20(WBTC).approve(address(UNISWAP_ROUTER_ADDRESS), 
            amountBaseToken * R_WBTC / 1e10), 'Approve failed');
        uniswapRouter.swapExactTokensForETH(amountBaseToken * R_WBTC / 1e10, MinProceedsWBTC, getPathForTokentoETH(WBTC), address(this), deadline);  // 1e10 accounts for 8 decimal places of WBTC, and that minimum purchase by this contract is 1e-4
        
        require(IERC20(PAXG).approve(address(UNISWAP_ROUTER_ADDRESS), amountBaseToken * R_PAXG), 'Approve failed');
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountBaseToken * R_PAXG, MinProceedsPAXG, getPathForTokentoETH(PAXG), address(this), deadline);

        // If in Phase 3, sell reserve tokens
        if(rToken.getPhase() == 3) {
            rToken.sell(amountBaseToken * R_RESERVE);
        } else {
            // return reserve tokens to seller's wallet
            success = rToken.transfer(msg.sender, amountBaseToken * R_RESERVE);
            require(success, "Early buyer bonus transfer failed.");
        }

        uint coinValueEnd = address(this).balance;
        uint proceedsFromSwap = coinValueEnd - coinValueStart + (amountBaseToken * R_ETH);

        // Transfer 1% transaction fee
        payable(RESERVE).transfer(proceedsFromSwap * 1 / 100); // transfer 1% fee to Reserve Token

        _burn(msg.sender, amountBaseToken);

        // Transfer sale of DomePeak Tokens
        (success,) = msg.sender.call{ value: (proceedsFromSwap * 99 / 100)}("");
        require(success, "Payment failed");
    }

    /** @dev reserveTokensToMint calculates the number of reserve tokens to mint
     *  @param domePeakTokensToMint is the amount of base tokens
     */
    function reserveTokensToMint(uint256 domePeakTokensToMint) internal pure returns (uint256) {
        return domePeakTokensToMint * R_RESERVE * 1e14;
    }

    /** @dev baseTokensToMint calculates the number of reserve tokens to mint
     *  @param priceOfBase is the price of the base token in the basket
     */
    function baseTokensToMint(uint256 priceOfBase) internal view returns (uint256) {
        require(priceOfBase > 0, "The price of base token must be greater than zero");
        return msg.value / (101 * priceOfBase / 100);  // 1.01 represents the 1% DomePeak fee
    }    

    /** @dev getPriceOfBase calculates the price (in wei) of the smallest tradable unit of DomePeak.  The smallest
     *  tradable unit is .0001 Token (1e14).
     */
    function getPriceOfBase() internal view returns (uint256, uint256, uint256, uint256, uint256) {
        // We need to find the average cost of each token, assuming we would trade the entire msg.value.
        // This is done to ensure there is sufficient liquidity for the swap.
       
        // Assumes 0.0001 token will cost at least 0.0001 Eth (1e14 wei)
        require(msg.value >= 1e14, "Insufficient ether sent to purchase 0.0001 token");
        
        // Get the amount of tokens received in exchange for msg.value
        uint256 PAXGtoETH = uniswapRouter.getAmountsOut(msg.value, getPathForETHtoToken(PAXG))[1];
        uint256 WBTCtoETH = uniswapRouter.getAmountsOut(msg.value, getPathForETHtoToken(WBTC))[1];

        uint256 PriceOfBasePAXG;
        uint256 PriceOfBaseWBTC;
        uint256 PriceOfBaseEth = 1e14; // base price of Eth

        //*** Handle 3 scenarios in the event of future price changes:
        // 1) getAmountsOut < msg.value
        //    This happens when price of the token is less than 1 Eth.
        // 2) getAmountsOut returns 0
        //    This happens when price of token is much greater than msg.value
        // 3) getAmountsOut returns 1
        //    This happens when the price of the token is very similar to msg.value

        // Process PAXG
        // Calculate the average price (wei) for 0.0001 tokens
        require(PAXGtoETH > 0, "The price of PAXG is too high for this amount of Eth.");
        PriceOfBasePAXG = 1e14 * msg.value / PAXGtoETH;
        require(PriceOfBasePAXG > 0, "The price of PAXG has dropped too low to trade.");
        
        // Process WBTC
        // Calculate the average price (wei) for 0.0001 tokens
        require(WBTCtoETH > 0, "The price of WBTC is too high for this amount of Eth.");
        PriceOfBaseWBTC = 1e4 * msg.value / WBTCtoETH; // 1e4 is required to scale WBTC, since it uses a fewer decimals than Eth.
        require(PriceOfBaseWBTC > 0, "The price of WBTC has dropped to low to trade.");
        
        // Process Reserve Token
        uint256 PriceOfReserveEth = rToken.quoteAvgPriceForTokens(msg.value);

        // Apply ratios of coins
        PriceOfBasePAXG = R_PAXG * PriceOfBasePAXG * 10000 / 9998; // (10000 / 9998) to account for the PAXG 0.02% fee;
        PriceOfBaseEth = R_ETH * PriceOfBaseEth;
        PriceOfBaseWBTC = R_WBTC * PriceOfBaseWBTC;
        PriceOfReserveEth = R_RESERVE * PriceOfReserveEth / 1e4; // Scale to 0.0001 reserve tokens

        // This is the lowest price (in WEI) of one unit of DomePeak
        return (PriceOfBaseWBTC + PriceOfBasePAXG + PriceOfBaseEth + PriceOfReserveEth, PriceOfBaseWBTC, PriceOfBasePAXG, PriceOfBaseEth, PriceOfReserveEth);
    }

    /** @dev estimateProceeds calculates the price (in wei) of the sale proceeds
     *  @param amount Amount of DomePeak Token to exchange for Ether
     */
    function estimateProceeds(uint256 amount) internal view returns (uint256, uint256) {
        // Get the amount of eth received
        uint256 PAXGtoETH = uniswapRouter.getAmountsOut(amount * R_PAXG, getPathForTokentoETH(PAXG))[1];
        uint256 WBTCtoETH = uniswapRouter.getAmountsOut(amount * R_WBTC / 1e10, getPathForTokentoETH(WBTC))[1];

        uint256 PriceOfBasePAXG;
        uint256 PriceOfBaseWBTC;

        // (10000 / 9998) to account for the PAXG 0.02% fee
        PriceOfBasePAXG = PAXGtoETH * 9998 / 10000;
        PriceOfBaseWBTC = WBTCtoETH;

        // This is the lowest price (in WEI) for the amount of DomePeak
        return (PriceOfBaseWBTC, PriceOfBasePAXG);
    }

    function getPathForETHtoToken(address tokenAddress) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = tokenAddress;
        
        return path;
    }
    
    function getPathForTokentoETH(address tokenAddress) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapRouter.WETH();        
        
        return path;
    }

    /** @dev amountEthInCoin multiplies the tokens to mint by the base price of Eth
     *  @param tokensToMint number of DomePeak tokens to mint
     *  @param priceOfBaseEth the price of eth
     *  @return tokensToMint * priceOfBaseEth
     */
    function amountEthInCoin(uint tokensToMint, uint priceOfBaseEth) private pure returns (uint) {
        // Calculate the amount of Ether in the coin
        return tokensToMint * priceOfBaseEth;
    }

    /** @dev calcBonusTokens calculates the number of bonus tokens to send the buyer
     *  @param rTokensToMint amount of new reserve tokens that are minted during the
     *  purchase of DomePeak.
     *  @return total bonus tokens to transfer to the early buyer
     */    
    function calcBonusTokens(uint256 rTokensToMint) private returns (uint256) {
        uint256 alpha = 0;  // Amount of bonus tokens for phase alpha
        uint256 beta = 0;  // Amount of bonus tokens for phase beta
        uint256 gamma = 0;  // Amount of bonus tokens for phase gamma
        uint256 remainder = rTokensToMint;

        // Rounding errors create scenarios where some bonus reserve tokens
        // can get lost.  Iterate through each phase and zero out
        // remaining bonus tokens due to underflow.

        if(remainder > 0 && remAlphaRTokens > 0) {
            if(remainder > remAlphaRTokens) {
                remainder = remainder - remAlphaRTokens;
                remAlphaRTokens = 0;
                alpha = remAlphaBonus;
                remAlphaBonus = 0;
            } else {
                remAlphaRTokens = remAlphaRTokens - remainder;
                alpha = remainder * 1125 / 1000;
                remainder = 0;
                
                if(alpha > remAlphaBonus) {
                    alpha = remAlphaBonus;
                    remAlphaBonus = 0;
                    remAlphaRTokens = 0;
                } else {
                    remAlphaBonus = remAlphaBonus - alpha;
                }
            }
        }
        
        if(remainder > 0 && remBetaRTokens > 0) {
            if(remainder > remBetaRTokens) {
                remainder = remainder - remBetaRTokens;
                remBetaRTokens = 0;
                beta = remBetaBonus;
                remBetaBonus = 0;
            } else {
                remBetaRTokens = remBetaRTokens - remainder;
                beta = remainder * 675 / 1000;
                remainder = 0;
                
                if(beta > remBetaBonus) {
                    beta = remBetaBonus;
                    remBetaBonus = 0;
                    remBetaRTokens = 0;
                } else {
                    remBetaBonus = remBetaBonus - beta;
                }
            }            
        }
        
        if(remainder > 0 && remGammaRTokens > 0) {
            if(remainder > remGammaRTokens) {
                remGammaRTokens = 0;
                gamma = remGammaBonus;
                remGammaBonus = 0;
            } else {
                remGammaRTokens = remGammaRTokens - remainder;
                gamma = remainder * 45 / 100;
                
                if(gamma > remGammaBonus) {
                    gamma = remGammaBonus;
                    remGammaBonus = 0;
                    remGammaRTokens = 0;
                } else {
                    remGammaBonus = remGammaBonus - gamma;
                }
            }
        }
     
        return alpha + beta + gamma;
    }

    /** @dev Mints bonus reserve tokens
      */  
    function mintBonusTokens() external isOwner {
        rToken.mintBonus();
    }

    /** @dev Sets the address of the upgrade token
     *  @param tokenAddress Address of the new token
     */
    function setUpgradeToken(address tokenAddress) external isOwner {
        UPGRADE_TOKEN = tokenAddress;
        rToken.addApprovedToken(tokenAddress);
    }

    /** @dev Exchanges DomePeak tokens for the upgraded token.  This is an opt-in process.
     *  @param amount Amount of DomePeak tokens to upgrade
     *  @return Unwrapped ether (wei)
     */
    function upgradeToken(uint256 amount, address tokenHolder) external override returns (uint256) {
        require(UPGRADE_TOKEN != address(0));
        require(msg.sender == UPGRADE_TOKEN, "Not authorized to upgrade");
        require(balanceOf(tokenHolder) >= amount, "Insufficient DomePeak to upgrade");
        require(amount > 0, "Amount must be greater than zero");
        _burn(tokenHolder, amount); // burn the old token

        // Transfer PAXG, WBTC, Reserve
        require(IERC20(WBTC).transfer(address(msg.sender), amount * R_WBTC / 1e10), "WBTC transfer failed");
        require(IERC20(PAXG).transfer(msg.sender, amount * R_PAXG), "WBTC transfer failed");
        require(rToken.transfer(msg.sender, amount * R_RESERVE), "Reserve token transfer failed");

        // Transfer Ether
        (bool success,) = msg.sender.call{ value: (amount * R_ETH)}("");
        require(success, "Transfer DomePeak ether failed.");

        return (amount * R_ETH);
    }
  
    receive() external payable {
    }
    
    fallback() external payable {
    }
    
    // @dev Modifier to allow a function callable only by the owner.
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
}