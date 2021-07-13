/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol

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

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol

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

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.4;

contract DomePeak is ERC20 {
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    IUniswapV2Router02 public uniswapRouter;
    address internal constant paxgRop = 0x478640c8D01CAc92Ffcd4a15EaC1408Be52BA47A;
    address internal constant wbtcRop = 0xc3778758D19A654fA6d0bb3593Cf26916fB3d114;
    address internal constant RESERVE_1 = 0x0b2808f10634327076429d3c040879AD6F8cD0F3;
    address internal constant RESERVE_2 = 0xBCcBE7A176416f5a9C122120a5e2837296f5B5Bf;
    
    uint value1;
    uint value2;
    uint value3;
    uint value4;
    uint value5;
    uint value6;
    bool value7;
    event test_value(uint256 indexed value1);
    event test_value2(uint256 indexed value2);
    event test_value3(uint256 indexed value3);
    event test_value4(uint256 indexed value4);
    event test_value5(uint256 indexed value5);
    event test_value6(uint256 indexed value6);
    event test_value7(bool indexed value7);

    constructor() ERC20("DomePeak009", "DPC") {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    }    

    function buyDomePeak() public payable {
        uint deadline = block.timestamp + 15;  // TODO:  pass deadline from frontend
        uint PriceOfBase;
        uint PriceOfBaseWBTC;
        uint PriceOfBasePAXG;
        uint PriceOfBaseEth;
        uint PriceOfReserveEth;
        (PriceOfBase, PriceOfBaseWBTC, PriceOfBasePAXG, PriceOfBaseEth, PriceOfReserveEth) = GetPriceOfBase();  // This is the lowest price (in WEI) of one unit of Cape Coin (1e-4 Cape Coin)
        uint capeCoinsToMint = 0;
        
        require(msg.value > PriceOfBase, "Not enough Ether to purchase .0001 Cape Coin");
        
        // Now calculate how many units of cape coin we can purchase
        capeCoinsToMint = msg.value / (105 * PriceOfBase / 100);  // 1.05 represents the 1% cape coin fee, plus fees for uniswap

        payable(RESERVE_2).transfer(msg.value * 1 / 100); // transfer 1% to reserve 2, ie fee wallet
        
        (bool success,) = RESERVE_1.call{value: (capeCoinsToMint * 12e14)}(abi.encodeWithSignature("addToReserve()")); // 12e14 represents the proportion of ETH going to the reserve
        require(success, "Transfer to reserve coin failed");
        
        emit test_value(capeCoinsToMint);
        emit test_value2(PriceOfBase);
        emit test_value5(address(this).balance);
        
        uint amountETHinCoin = capeCoinsToMint * PriceOfBaseEth;
        
        uniswapRouter.swapETHForExactTokens{ value: (address(this).balance) }(capeCoinsToMint * 1e4, getPathForETHtoToken(wbtcRop), address(this), deadline);  // 1e4 accounts for 8 decimal places of WBTC, and that minimum purchase by this contract is 1e-4
        uniswapRouter.swapETHForExactTokens{ value: (address(this).balance) }(capeCoinsToMint * 16e14, getPathForETHtoToken(paxgRop), address(this), deadline);

        emit test_value6(address(this).balance);
        
        // refund any leftover ETH that the contract has to the user, minus amount kept for basket.  This takes care of the
        // ether portion of the basket, as well
        (success,) = msg.sender.call{ value: (address(this).balance - amountETHinCoin) }("");
        require(success, "refund failed");
        
        // Mint the Cape Coin (basket of coins)
        _mint(msg.sender, capeCoinsToMint * 1e14);
    }
    
    function sellDomePeak(uint amount) public payable {
        uint deadline = block.timestamp + 15;  // TODO:  pass deadline from frontend
        uint amountBaseCapeToken = (amount / 1e14) * 1e14;  // Get floor.  Mimimum amount of Cape Tokens to transact is .0001
        require(amountBaseCapeToken >= 1e14, "The minimum sale amount is .0001 Cape Coin");

        uint coinValueStart = address(this).balance;  // TODO:  is this safe?  Can this be frontrun?
        emit test_value(amountBaseCapeToken);
        emit test_value2(amountBaseCapeToken);
        emit test_value3(coinValueStart);

        // Swap PAXG and WBTC back to ETH
        require(IERC20(wbtcRop).approve(address(UNISWAP_ROUTER_ADDRESS), amountBaseCapeToken / 1e10), 'Approve failed');
        uniswapRouter.swapExactTokensForETH(amountBaseCapeToken / 1e10, 0, getPathForTokentoETH(wbtcRop), address(this), deadline);  // 1e10 accounts for 8 decimal places of WBTC, and that minimum purchase by this contract is 1e-4
        require(IERC20(paxgRop).approve(address(UNISWAP_ROUTER_ADDRESS), amountBaseCapeToken * 16), 'Approve failed');
        uniswapRouter.swapExactTokensForETH(amountBaseCapeToken * 16, 0, getPathForTokentoETH(paxgRop), address(this), deadline);
        
        require(IERC20(RESERVE_1).approve(address(this), amountBaseCapeToken * 12), 'Approve failed');
        (bool success,) = RESERVE_1.call(abi.encodeWithSignature("removeFromReserve(uint256)", amountBaseCapeToken * 12));
        require(success, "Transfer from reserve coin failed");
        emit test_value7(success);

        uint coinValueEnd = address(this).balance;
        uint proceedsFromSwap = coinValueEnd - coinValueStart + (amountBaseCapeToken * 16);

        emit test_value4(coinValueEnd);
        emit test_value5(proceedsFromSwap);

        // Transfer 1% transaction fee
        payable(RESERVE_2).transfer(proceedsFromSwap * 1 / 100); // transfer 1% to reserve 2, ie fee wallet
        
        // Transfer sale of Cape Coin
        (success,) = msg.sender.call{ value: (proceedsFromSwap * 99 / 100)}("");
        require(success, "Payment failed");
        
        _burn(msg.sender, amountBaseCapeToken);
    }
    
    function GetPriceOfBase() public view returns (uint, uint, uint, uint, uint)
    {
        //*** Need to think about exchnage rates.  E.g. What happens if ETH starts to cost more than BTC?
        // 3 scenarios..
        // 1) getAmountsIn returns 1, getAmountsOut returns > 1
        //    This happens when price of the token is less than 1 Eth.
        // 2) getAmountsIn returns > 1, getAmountsOut returns 0
        //    This happens when price of token is greater than 1 Eth.
        // 3) getAmountsIn returns 1, getAmountsOut returns 1
        //    This happens when the price of the token is very similar to 1 Eth.  Rerun both with 1e18.
        
        uint ETHtoPAXG = uniswapRouter.getAmountsIn(1, getPathForETHtoToken(paxgRop))[0];  // Get exchange rate for PAXG (18 decimals)
        uint ETHtoWBTC = uniswapRouter.getAmountsIn(1, getPathForETHtoToken(wbtcRop))[0];  // Get exchange rate for WBTC (8 decimals)
        uint PAXGtoETH = uniswapRouter.getAmountsOut(1, getPathForETHtoToken(paxgRop))[1];
        uint WBTCtoETH = uniswapRouter.getAmountsOut(1, getPathForETHtoToken(wbtcRop))[1];
        uint PriceOfBaseWBTC = 0; // 1e-4 WBTC
        uint PriceOfBasePAXG = 0; // 16e-4 PAXG
        uint PriceOfBaseEth = 1600000000000000;  // 16e-4 ETH, or 1600000000000000 wei
        uint PriceOfReserveEth = 2100000000000000;  // 16e-4 ETH, or 1600000000000000 wei
        // Process WBTC
        if(ETHtoWBTC == 1 && WBTCtoETH > 1) {
            // Price of ETH is more than 1 WBTC
        } else if(ETHtoWBTC > 1 && WBTCtoETH == 0) {
            // Price of WBTC is more than 1 ETH
            PriceOfBaseWBTC = ETHtoWBTC * 1e5; // This represents the cost in wei of the smallest unit of WBTC we are willing to buy (1e-4 wbtc)
        } else {
            
        }

        // Process PAXG
        if(ETHtoPAXG == 1 && PAXGtoETH > 1e5) { // The choice of 1e5 is somewhat arbirary.  If less than 1e5, the two values are close enough that we won't have an overflow if we pass in 1e18 to uniswap
            // Price of ETH is more than 1 PAXG
        } else if(ETHtoPAXG > 1e5 && PAXGtoETH == 0) {
            // Price of PAXG is more than 1 ETH
        } else {
            // This happens when ETHtoPAXG = 1 and PAXGtoETH = 1, or the price of Eth is similar to the price of PAXGtoETH.
            // Rerun with high amounts of ETH
            ETHtoPAXG = uniswapRouter.getAmountsIn(1e18, getPathForETHtoToken(paxgRop))[0];  // Get exchange rate for PAXG (18 decimals)
            PAXGtoETH = uniswapRouter.getAmountsOut(1e18, getPathForETHtoToken(paxgRop))[1];
            PriceOfBasePAXG = uniswapRouter.getAmountsIn(16e14, getPathForETHtoToken(paxgRop))[0];  // This represents the cost in wei of the smallest unit of PAXG we are willing to buy (16e-4 paxg)
        }

        return (PriceOfBaseWBTC + PriceOfBasePAXG + PriceOfBaseEth + PriceOfReserveEth, PriceOfBaseWBTC, PriceOfBasePAXG, PriceOfBaseEth, PriceOfReserveEth);  // This is the lowest price (in WEI) of one unit of Cape Coin        
    }

    function convertEthToToken(uint tokenAmount, address tokenAddress) public payable {
        uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uniswapRouter.swapETHForExactTokens{ value: msg.value }(tokenAmount, getPathForETHtoToken(tokenAddress), msg.sender, deadline);
        
        // refund leftover ETH to user
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
    }
    
    // Example usage:  tokenAmount=1, returns 456363615286,1 for WBTC on Ropsten.  456363615286 represents 45.6363615286 Ether required for 1 WBTC    
    function getEstimatedETHforToken(uint tokenAmount, address tokenAddress) public view returns (uint[] memory) {
        return uniswapRouter.getAmountsIn(tokenAmount, getPathForETHtoToken(tokenAddress));
    }
    
    function getEstimatedTokenForETH(uint ethAmount, address tokenAddress) public view returns (uint[] memory) {
        return uniswapRouter.getAmountsOut(ethAmount, getPathForETHtoToken(tokenAddress));
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

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    fallback() external payable {
    }
    
    event Received(address sender, uint amount);
}