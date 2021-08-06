// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20/ERC20.sol";
import "./utils/Ownable.sol";
import "./utils/WooInuUtils.sol";
import "./Interfaces/IWooInuV2.sol";
import "./Interfaces/IUniswapV2Factory.sol";
import "./Interfaces/IUniswapV2Router.sol";

contract WooInuV2 is ERC20("Nature boy inu", "WOOINU"), Ownable, IWooInuV2 {
    /// @dev Burn address and max uint
    address internal constant BURN = 0x000000000000000000000000000000000000dEaD;
    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @dev The woo inu v1 token, for migrations
    IERC20 internal v1Token;

    /// @dev Store the current fees
    Fees internal _currentFees;

    /// @dev Uniswap router, factory and pair
    IuniswapV2Router internal uniswapV2Router;
    IUniswapV2Factory internal uniswapV2Factory;
    address internal uniswapV2Pair;

    /// @dev Mapping of address => is excluded from fees
    mapping(address => bool) internal _isExcluded;

    /// @dev Sets fees, excluded and approves tokens to the uniswap v2 router. And creates a uniswap v2 pair, and sets fees
    constructor() {
        v1Token = IERC20(0xBf820Fbb448c564B456cE376cbFbe341B84d1a58);
        uniswapV2Router = IuniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
        uniswapV2Pair = uniswapV2Factory.createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _isExcluded[address(this)] = true;
        _isExcluded[_msgSender()] = true;
        _isExcluded[address(uniswapV2Router)] = true;
        _approve(address(this), address(uniswapV2Router), MAX);

        _currentFees = Fees(
            3, // Buy dev fee
            7, // Buy PPV fee
            5, // Sell ppv fee
            3, // Sell dev fee
            3, // Sell liquidty fee
            1, // Max sell
            9,
            address(0), // Dev wallet
            address(0) // PPV Wallet
        );
    }

    /**
     * @dev Takes a given amount of fees from a user
     * emits FeesTaken()
     * @param from: Who to take fees from
     * @param amount: The total transaction amount
     * @param devFee: The percemtage of tokens to be sent to the developer wallet
     * @param ppvFee: The percentage of tokens to be sent to the PPV wallet
     * @param liquidityFee: The amount of tokens to add liquidity with
     * @return feeTotal : Total fees taken
     */
    function _takeFees(
        address from,
        uint256 amount,
        uint256 devFee,
        uint256 ppvFee,
        uint256 liquidityFee
    ) internal returns (uint256 feeTotal) {
        if (devFee != 0) {
            uint256 toDevWallet = WooInuUtils.percentageOf(amount, devFee);
            transferNoFee(from, _currentFees.devWallet, toDevWallet);
            feeTotal += toDevWallet;
        }

        if (ppvFee != 0) {
            uint256 toPpvWallet = WooInuUtils.percentageOf(amount, ppvFee);
            transferNoFee(from, _currentFees.ppvWallet, toPpvWallet);
            feeTotal += toPpvWallet;
        }

        if (liquidityFee != 0) {
            uint256 toLiquidity = WooInuUtils.percentageOf(
                amount,
                liquidityFee
            );
            WooInuUtils.swapAndLiquify(uniswapV2Router, toLiquidity, BURN);
            feeTotal += toLiquidity;
        }

        emit FeesTaken(feeTotal);
    }

    /**
     * @dev Takes fees from a transfer, checks if is excluded. and then takes
     * fees depending on if its a buy or sell
     * Calls _takeFee()
     * @param from: The address to take fees from
     * @param to: The address the tokens are going to get sent to
     * @param amount: The total amount of tokens getting transfered
     */
    function takeFees(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        /// @dev Do nothing if is excluded, 0 fees
        if (_isExcluded[from]) {
            return 0;
        }
        require(
            amount <= _currentFees.maxTransfer,
            "WOOINU: Max tranfer limit exceeded"
        );
        if (from == uniswapV2Pair) {
            /// @dev Is a buy
            return
                _takeFees(
                    from,
                    amount,
                    _currentFees.onBuyDevFee,
                    _currentFees.onBuyPPVFee,
                    0
                );
        } else if (to == address(uniswapV2Router)) {
            /// @dev Require that the tokens getting sold are at least 1% of the tokens in the unipair
            require(
                amount <=
                    WooInuUtils.percentageOf(
                        balanceOf(uniswapV2Pair),
                        _currentFees.maxSell
                    ),
                "WOOINU: Max sell limit exceeded"
            );
            /// @dev Is a sell
            return
                _takeFees(
                    from,
                    amount,
                    _currentFees.onSellDevFee,
                    _currentFees.onSellPPVFee,
                    _currentFees.onSellLiquidityFee
                );
        }
        /// @dev If its a normal transfer, fees are none
        return 0;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 totalFee = takeFees(sender, recipient, amount);
        return super._transfer(sender, recipient, amount - totalFee);
    }

    function transferNoFee(
        address from,
        address to,
        uint256 amount
    ) internal {
        return super._transfer(from, to, amount);
    }

    /**
     * @dev Migrates the V1 tokens to the new V2 Woo Inu contract
     * @param amountToMigrate: The amount of tokens to migrate to the new V2 contract
     */
    function migrate(uint256 amountToMigrate) external override {
        require(v1Token.transferFrom(_msgSender(), BURN, amountToMigrate));
        _mint(_msgSender(), amountToMigrate);
    }

    /**
     * @return The current fees, the wallets fees are sent to and the max transfer amounts
     */
    function currentFees() external view override returns (Fees memory) {
        return _currentFees;
    }

    /**
     * @dev Sets the current fees for the contract
     * @param _fees: The fees to change to
     */
    function setFees(Fees memory _fees) external onlyOwner {
        _currentFees = _fees;
    }


    /**
     * @return If an address is excluded from fees / max transfer amounts
     * @param _address: The address to check for
     */
    function isExcluded(address _address) external view override returns (bool) {
        return _isExcluded[_address];
    }

    /**
     * @dev Sets if an address is excluded from fees
     * @param _address: The address to excluded / include
     * @param setTo: Set to is excluded or is not excluded
     */
    function setExcluded(address _address, bool setTo) external onlyOwner {
        _isExcluded[_address] = setTo;
    }

    /**
     * @dev Recieve tokens from the uniswap v2 router
     */
    receive() external payable {
        require(
            _msgSender() == address(uniswapV2Router),
            "WOOINU: Uniswap only"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "./utils/Context.sol";

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

import "../ERC20/utils/Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
import "../Interfaces/IUniswapV2Router.sol";

library WooInuUtils {

    /** 
     * @dev Calculates the percentage of a number
     * @param number: The number to calculate the percentage of
     * @param percentage: The percentage of the number to return
     * @return The percentage of a number
     */
    function percentageOf(uint256 number, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (number * percentage) / 100;
    }

    /**
     * @dev Swaps an amount of tokens for ETH
     * @param uniswapV2Router: The uniswap router to conduct the trade through
     * @param amount: The amount of tokens to swap
     * @param to: The address to send the recieved tokens to
     * @return The amount of ETH recieved
     */
    function swapForETH(
        IuniswapV2Router uniswapV2Router,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        uint256 startingBalance = to.balance;
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );

        return to.balance - startingBalance;
    }

    /**
     * @dev Swaps half of an amount of tokens to eth and adds liquidity to the pair
     * @param uniswapV2Router: The uniswap router to conduct the liquidity add through
     * @param amount: The amount of tokens to add liquidty with
     * @param to: The address to send the recieved LP tokens to
     */
    function swapAndLiquify(
        IuniswapV2Router uniswapV2Router,
        uint256 amount,
        address to
    ) internal {
        swapForETH(uniswapV2Router, amount / 2, address(this));
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            amount / 2,
            0,
            0,
            to,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWooInuV2 /* is ERC20 */{
    event FeesTaken(uint256 feeTotal);

    /**
     * @dev Fees struct to store all contract fees, and max transfer + the wallets fees are sent to
     * @param onSellLiquidityFee: The liquidity fee that will be taken on a sell
     * @param onBuyDevFee: The dev fee that will be taken on a buy
     * @param onBuyPPVFee: The PPV fee that will be taken on a buy
     * @param onSellPPVFee: The PPV fee that will be taken on a sell
     * @param onSellDevFee: The dev fee that will be taken on a sell
     * @param maxSell: The maximum amount of tokens someone can sell
     * @param maxTransfer: The maximum amount of tokens that someone can transfer
     * @param devWallet: The wallet that all dev fees get sent to
     * @param ppvWallet: The wallet that all ppv fees get sent to
     */
    struct Fees {
        uint256 onBuyDevFee;
        uint256 onBuyPPVFee;
        uint256 onSellPPVFee;
        uint256 onSellDevFee;
        uint256 onSellLiquidityFee;
        uint256 maxSell;
        uint256 maxTransfer;
        address devWallet;
        address ppvWallet;
    }

    /**
     * @dev Migrates the V1 tokens to the new V2 Woo Inu contract
     * @param amountToMigrate: The amount of tokens to migrate to the new V2 contract
     */
    function migrate(uint256 amountToMigrate) external;

    /**
     * @return The current fees, the wallets fees are sent to and the max transfer amounts
     */
    function currentFees() external view returns (Fees memory);

    /**
     * @return If an address is excluded from fees / max transfer amounts
     * @param _address: The address to check for
     */
    function isExcluded(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Uniswap v2 factory with only create pair function
 */
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IuniswapV2Router {
    function factory() external pure returns (address);
    
    // solhint-disable-next-line
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}