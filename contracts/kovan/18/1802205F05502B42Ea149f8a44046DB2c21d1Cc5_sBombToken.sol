// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./pancake-swap/libraries/TransferHelper.sol";

/**
 * @dev Implementation of the sBomb Token.
 *
 * Deflationary token mechanics:
 *
 * When buy/sell on Sushiswap or Pancakeswap:
 *
 * Buy tax: 6%, =
 * 5% Lottery (see below). Need to be converted to ETH or BNB and sent to the lottery contract.
 * 1% SHIBAK buy and burn
 *
 * Sell tax: 20%, =
 * 10% SHIBAK buy and burn
 * 5% to team wallet
 * 5% to sBOMB liquidity pool
 */
contract sBombToken is ERC20, Ownable {
    IUniswapV2Router public dexRouter;
    address public immutable SHIBAKEN;
    address public teamWallet;
    address public lotteryContract;

    //buy/sell taxes for deflationary token
    uint256 public constant LOTTERY_BUY_TAX = 5;
    uint256 public constant SHIBAK_BUY_TAX = 1;
    uint256 public constant SHIBAK_SELL_TAX = 10;
    uint256 public constant TEAM_SELL_TAX = 5;
    uint256 public constant LIQ_SELL_TAX = 5;

    address private constant DEAD_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);

    bool private inSwap;

    event BuyTaxTaken(uint256 toLottery, uint256 toBurn, uint256 total);
    event SellTaxTaken(
        uint256 toBurn,
        uint256 toTeam,
        uint256 toLiquidity,
        uint256 total
    );

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _shibakenToken, IUniswapV2Router _dex)
        ERC20("sBOMB", "SBOMB")
    {
        SHIBAKEN = _shibakenToken;
        dexRouter = _dex;

        uint256 initialSupply = 10**8 * 10**uint256(decimals());
        _mint(_msgSender(), initialSupply);
    }

    receive() external payable {}

    /** @dev Owner function for setting lottery contarct address
     * @param _lottery lottery contract address
     */
    function setLotteryContarct(address _lottery) external onlyOwner {
        require(_lottery != address(0));
        lotteryContract = _lottery;
    }

    /** @dev Owner function for setting team wallet address
     * @param _wallet team wallet address
     */
    function changeTeamWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0));
        teamWallet = _wallet;
    }

    /** @dev Owner function for setting DEX router address
     * @param _dex DEX router address
     */
    function setDexRouter(IUniswapV2Router _dex) external onlyOwner {
        require(address(_dex) != address(0));
        dexRouter = _dex;
    }

    /** @dev Public payable function for adding liquidity in SBOMB-ETH pair without 20% fee
     * @param tokenAmount sBomb token amount
     * @param amountTokenMin min sBomb amount going to pool
     * @param amountETHMin min ETH amount going to pool
     * @param to address for LP-tokens
     */
    function noFeeAddLiquidityETH(
        uint256 tokenAmount,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    ) external payable lockTheSwap {
        require(msg.value > 0 && tokenAmount > 0, "ZERO");
        TransferHelper.safeTransferFrom(address(this), _msgSender(), address(this), tokenAmount);
        _approve(address(this), address(dexRouter), tokenAmount);
        (uint256 token, uint256 eth, ) = dexRouter.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            amountTokenMin,
            amountETHMin,
            to,
            block.timestamp
        );
        if(tokenAmount > token)
            TransferHelper.safeTransfer(address(this), _msgSender(), tokenAmount - token);
        if(msg.value > eth)
            payable(_msgSender()).transfer(msg.value - eth);
    }

    /** @dev Public payable function for adding liquidity in SBOMB-<TOKEN> pair without 20% fee
     * @param token1 another token address
     * @param tokenAmount0 sBomb token amount
     * @param tokenAmount1 another token amount
     * @param amountToken0Min min sBomb amount going to pool
     * @param amountToken0Min min <TOKEN> amount going to pool
     * @param to address for LP-tokens
     */
    function noFeeAddLiquidity(
        address token1,
        uint256 tokenAmount0,
        uint256 tokenAmount1,
        uint256 amountToken0Min,
        uint256 amountToken1Min,
        address to
    ) external lockTheSwap {
        require(tokenAmount0 > 0 && tokenAmount1 > 0, "ZERO");
        TransferHelper.safeTransferFrom(address(this), _msgSender(), address(this), tokenAmount0);
        _approve(address(this), address(dexRouter), tokenAmount0);
        TransferHelper.safeTransferFrom(token1, _msgSender(), address(this), tokenAmount1);
        TransferHelper.safeApprove(token1, address(dexRouter), tokenAmount1);
        (uint256 finalToken0, uint256 finalToken1, ) = dexRouter.addLiquidity(
            address(this),
            token1,
            tokenAmount0,
            tokenAmount1,
            amountToken0Min,
            amountToken1Min,
            to,
            block.timestamp
        );

        if(finalToken0 < tokenAmount0)
            TransferHelper.safeTransfer(address(this), _msgSender(), tokenAmount0 - finalToken0);

        if(finalToken1 < tokenAmount1)
            TransferHelper.safeTransfer(token1, _msgSender(), tokenAmount1 - finalToken1);
    }

    function _swapTokensForEth(
        uint256 tokenAmount,
        address to,
        address[] memory path
    ) internal lockTheSwap {
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function _swapTokensForTokens(
        uint256 tokenAmount,
        address to,
        address[] memory path
    ) internal lockTheSwap {
        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 totalFee;

        if (!inSwap) {
            if (_pairCheck(sender)) {
                uint256 lotteryFee = (LOTTERY_BUY_TAX * amount) / 100;
                uint256 burnFee = (SHIBAK_BUY_TAX * amount) / 100;
                totalFee = lotteryFee + burnFee;

                super._transfer(sender, address(this), totalFee);
                _approve(address(this), address(dexRouter), totalFee);

                //LOTTERY FEE
                if (
                    sender ==
                    address(
                        IUniswapV2Factory(dexRouter.factory()).getPair(
                            address(this),
                            dexRouter.WETH()
                        )
                    )
                ) {
                    address[] memory path = new address[](3);
                    path[0] = address(this);
                    path[1] = SHIBAKEN;
                    path[2] = dexRouter.WETH();

                    if (_pairExisting(path))
                        _swapTokensForEth(lotteryFee, lotteryContract, path);
                } else {
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = dexRouter.WETH();
                    if (_pairExisting(path))
                        _swapTokensForEth(lotteryFee, lotteryContract, path);
                }

                //BURN FEE
                if (
                    sender ==
                    address(
                        IUniswapV2Factory(dexRouter.factory()).getPair(
                            address(this),
                            SHIBAKEN
                        )
                    )
                ) {
                    address[] memory path = new address[](3);
                    path[0] = address(this);
                    path[1] = dexRouter.WETH();
                    path[2] = SHIBAKEN;
                    if (_pairExisting(path))
                        _swapTokensForTokens(burnFee, DEAD_ADDRESS, path);
                } else {
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = SHIBAKEN;
                    if (_pairExisting(path))
                        _swapTokensForTokens(burnFee, DEAD_ADDRESS, path);
                }

                emit BuyTaxTaken(lotteryFee, burnFee, totalFee);
            } else if (
                _pairCheck(recipient) && address(dexRouter) == _msgSender()
            ) {
                uint256 burnFee = (SHIBAK_SELL_TAX * amount) / 100;
                uint256 toTeam = (TEAM_SELL_TAX * amount) / 100;
                uint256 toLiquidity = (LIQ_SELL_TAX * amount) / 100;
                totalFee = burnFee + toTeam + toLiquidity;

                //BURN FEE
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = SHIBAKEN;
                if (_pairExisting(path)) {
                    super._transfer(sender, address(this), burnFee);
                    _approve(address(this), address(dexRouter), burnFee);
                    _swapTokensForTokens(burnFee, DEAD_ADDRESS, path);
                }

                //TEAM FEE
                path[1] = dexRouter.WETH();
                if (_pairExisting(path)) {
                    super._transfer(sender, address(this), toTeam);
                    _approve(address(this), address(dexRouter), toTeam);
                    _swapTokensForEth(toTeam, teamWallet, path);
                }

                //LIQUIDITY FEE
                if (_pairExisting(path)) {
                    super._transfer(sender, address(this), toLiquidity);
                    _approve(address(this), address(dexRouter), toLiquidity);
                    uint256 half = toLiquidity / 2;
                    uint256 anotherHalf = toLiquidity - half;
                    _swapTokensForEth(half, address(this), path);
                    inSwap = true;
                    (uint256 tokenAmount , , ) = dexRouter.addLiquidityETH{value: address(this).balance}(
                        address(this),
                        anotherHalf,
                        0,
                        0,
                        DEAD_ADDRESS,
                        block.timestamp + 15 minutes
                    );
                    if (tokenAmount < anotherHalf)
                        super._transfer(address(this), recipient, anotherHalf - tokenAmount);
                    inSwap = false;
                }

                emit SellTaxTaken(burnFee, toTeam, toLiquidity, totalFee);
            }
        }

        super._transfer(sender, recipient, amount - totalFee);
    }

    function _pairExisting(address[] memory path) internal view returns (bool) {
        uint8 len = uint8(path.length);

        IUniswapV2Factory factory = IUniswapV2Factory(dexRouter.factory());
        address pair;
        uint256 reserve0;
        uint256 reserve1;

        for (uint8 i; i < len - 1; i++) {
            pair = factory.getPair(path[i], path[i + 1]);
            if (pair != address(0)) {
                (reserve0, reserve1, ) = IUniswapV2Pair(pair).getReserves();
                if ((reserve0 == 0 || reserve1 == 0)) return false;
            } else {
                return false;
            }
        }

        return true;
    }

    function _pairCheck(address _token) internal view returns (bool) {
        address token0;
        address token1;

        if (isContract(_token)) {
            try IUniswapV2Pair(_token).token0() returns (address _token0) {
                token0 = _token0;
            } catch {
                return false;
            }

            try IUniswapV2Pair(_token).token1() returns (address _token1) {
                token1 = _token1;
            } catch {
                return false;
            }

            address goodPair = IUniswapV2Factory(
                IUniswapV2Router(dexRouter).factory()
            ).getPair(token0, token1);
            if (goodPair != _token) {
                return false;
            }

            if (token0 == address(this) || token1 == address(this)) return true;
            else return false;
        } else return false;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Router {
    function WETH() external view returns (address);

    function factory() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    /* function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts); */

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}