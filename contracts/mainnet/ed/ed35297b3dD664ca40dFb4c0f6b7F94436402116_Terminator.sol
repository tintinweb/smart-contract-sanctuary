// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {Constants} from "./Constants.sol";
import {IUniswapV2Router02} from "./integrations/IUniswapV2Router02.sol";
import {IYVault} from "./integrations/IYVault.sol";

import {ICreditManager} from "./interfaces/ICreditManager.sol";
import {ICreditFilter} from "./interfaces/ICreditFilter.sol";

/// @dev Terminator is an example of smartcontract which is used for liquidation bots
/// Current version gets information from the bot, withdraw all YEARN tokens and then
/// convert everything on Uniswap V2 protocol into underlying asset.
///
/// This is just an example contract, do not use it in productuion.
/// This constract is not audited, use it on your own risk.

contract Terminator is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // List of yearn vaults connected
    address[] public yearn;

    // WETH token address
    address public wethToken;

    // Set or executros. Executors could call liquidate function.
    // This role is design to make parallel liquidations from different liquidaiton
    // without waiting confirmations for your address
    mapping(address => bool) public executors;

    // Parameters for Uniswap V2 which provides information
    struct UniV2Params {
        uint256 amountIn;
        address[] path;
        uint256 amountOutMin;
    }

    modifier executorOnly() {
        require(executors[msg.sender], "For executors only");
        _;
    }

    constructor(address _wethToken) {
        wethToken = _wethToken;
    }

    // Adds an executor to the set
    function allowExecutor(address _executor) external onlyOwner {
        executors[_executor] = true;
    }

    // Removes executor from the set
    function forbidExecutor(address _executor) external onlyOwner {
        executors[_executor] = false;
    }

    // Adds yVault to the list
    function addYearn(address _yearn) external onlyOwner {
        yearn.push(_yearn);
    }

    /// @dev Liquidates account and sell all assets in Uniswap V2
    /// @param _creditManager address of credit manager
    /// @param _borrower address of borrower
    /// (the system finds credit account by these 2 params)
    /// @param _router Address of UniV2 router
    /// @param _paths Data for uniswap - how to swap all assets into underlying one
    function liquidateAndSellOnV2(
        address _creditManager,
        address _borrower,
        address _router,
        UniV2Params[] calldata _paths
    ) external executorOnly {
        // Getting creditManager, creditFilter and underlyingToken
        ICreditManager creditManager = ICreditManager(_creditManager);
        ICreditFilter creditFilter = ICreditFilter(
            creditManager.creditFilter()
        );

        // Provides address of credit account of reverts. It'll revert if someone already liquidate it
        address creditAccount = creditManager.getCreditAccountOrRevert(
            _borrower
        );

        // Gets the quantity of allowed tokens
        uint256 allowedTokenQty = creditFilter.allowedTokensCount();

        // Storing balances, they will not be available after liquidation
        uint256[] memory balancesBefore = new uint256[](allowedTokenQty);

        // Getting enabledTokens - token mask which represents non-zero balances
        uint256 enabledTokens = creditFilter.enabledTokens(creditAccount);

        uint256 tokenMask;

        // Checks that parameters array which provide params for swaping assets has the same size
        require(_paths.length == allowedTokenQty, "Incorrect path length");

        // Before executing liquidation method, we keep all balances of this smart contract to be able to
        // compute how many tokens of each asset we get during liquidation.
        // Terminator keeps different tokens to be able to liquidate different pools, it's why
        // it's crucial to distinguish balance we've already have and how many tokens we get.
        for (uint256 i = 1; i < allowedTokenQty; i++) {
            // Tokenmaks is a but mask which is used for gas saving during iteration for allowed tokens list
            tokenMask = 1 << i;
            if (enabledTokens & tokenMask > 0) {
                address token = creditFilter.allowedTokens(i);
                balancesBefore[i] = IERC20(token).balanceOf(address(this));
            }
        }
        // Providing allowance for creditManager to withdraw liquidation amount
        _provideAllowance(
            address(creditManager),
            creditManager.underlyingToken()
        );

        /**
         * @dev Liquidates credit account
         * - Transfers discounted total credit account value from liquidators account
         * - Pays borrowed funds + interest + fees back to pool, than transfers remaining funds to credit account owner
         * - Transfer all assets from credit account to liquidator ("to") account
         * - Returns credit account to factory
         * - Emits LiquidateCreditAccount event
         *
         * More info: https://dev.gearbox.fi/developers/credit/credit_manager#liquidate-credit-account
         *
         * @param borrower Borrower address
         * @param to Address to transfer all assets from credit account
         * @oaram force For force liquidation (ignore reverts for token transfers)
         */
        creditManager.liquidateCreditAccount(_borrower, address(this), false);

        // At first stage, we just withdraw all yearn assets we got during liquidation
        for (uint256 i = 0; i < yearn.length; i++) {
            if (IERC20(yearn[i]).balanceOf(address(this)) > 1) {
                IYVault(yearn[i]).withdraw();
            }
        }

        // The last thing is to swap all assets into underlying one
        // We compare current balace with stored one, and if it has difference
        // swap it into underlying account
        for (uint256 i = 1; i < allowedTokenQty; i++) {
            tokenMask = 1 << i;
            if (enabledTokens & tokenMask > 0) {
                address token = creditFilter.allowedTokens(i);
                uint256 balance = IERC20(token).balanceOf(address(this));

                if (balance > balancesBefore[i] + 1) {
                    balance = balance - balancesBefore[i] - 1;
                    require(token == _paths[i].path[0], "incorrect path");
                    sellTokensOnV2(_router, balance, _paths[i]);
                }
            }
        }
    }

    /// @dev Internal function which facilitate swap assets on Uniswap V2
    function sellTokensOnV2(
        address _router,
        uint256 amount,
        UniV2Params calldata paths
    ) internal {
        _provideAllowance(_router, paths.path[0]);

        // Computes amountOut based on rate provided as parameter
        uint256 amountOut = paths.amountOutMin.mul(amount).div(paths.amountIn);

        // By design, gearbox transfers eth if credit account has WETH position
        // So, we swap ETH using swapExactETHForTokens
        if (paths.path[0] == wethToken) {
            IUniswapV2Router02(_router).swapExactETHForTokens{value: amount}(
                amountOut,
                paths.path,
                address(this),
                block.timestamp
            );
        } else {
            IUniswapV2Router02(_router).swapExactTokensForTokens(
                amount,
                amountOut,
                paths.path,
                address(this),
                block.timestamp
            );
        }
    }

    /// @dev Sends tokens back to owner. Helps to take the profits back
    function transferToOwner(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /// @dev Provides needed allowance
    function _provideAllowance(address externalContract, address token)
        internal
    {
        if (
            ERC20(token).allowance(address(this), externalContract) <
            Constants.MAX_INT_4
        ) {
            ERC20(token).approve(externalContract, Constants.MAX_INT);
        }
    }

    /// @dev Allows contract to get ETH during liquidation
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) public {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

library Constants {
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // 25% of MAX_INT
    uint256 constant MAX_INT_4 =
        0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external  returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external  returns (uint amountETH);

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
    ) external  payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external override pure returns (address);
    function WETH() external override pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external override
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external override
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external override
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external override
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external override pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external override pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external override pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external override view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external override view returns (uint[] memory amounts);


}

pragma solidity ^0.7.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYVault is IERC20 {
    function token() external view returns (address);

    function deposit() external returns (uint256);

    function deposit(uint256 _amount) external returns (uint256);

    function deposit(uint256 _amount, address recipient)
        external
        returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function pricePerShare() external view  returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox.fi, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {IAppCreditManager} from "./app/IAppCreditManager.sol";
import {DataTypes} from "../libraries/Types.sol";

/// @title Credit Manager interface
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager

interface ICreditManager is IAppCreditManager {
    // Emits each time when the credit account is opened
    event OpenCreditAccount(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed creditAccount,
        uint256 amount,
        uint256 borrowAmount,
        uint256 referralCode
    );

    // Emits each time when the credit account is closed
    event CloseCreditAccount(
        address indexed owner,
        address indexed to,
        uint256 remainingFunds
    );

    // Emits each time when the credit account is liquidated
    event LiquidateCreditAccount(
        address indexed owner,
        address indexed liquidator,
        uint256 remainingFunds
    );

    // Emits each time when borrower increases borrowed amount
    event IncreaseBorrowedAmount(address indexed borrower, uint256 amount);

    // Emits each time when borrower adds collateral
    event AddCollateral(
        address indexed onBehalfOf,
        address indexed token,
        uint256 value
    );

    // Emits each time when the credit account is repaid
    event RepayCreditAccount(address indexed owner, address indexed to);

    // Emit each time when financial order is executed
    event ExecuteOrder(address indexed borrower, address indexed target);

    // Emits each time when new fees are set
    event NewParameters(
        uint256 minAmount,
        uint256 maxAmount,
        uint256 maxLeverage,
        uint256 feeSuccess,
        uint256 feeInterest,
        uint256 feeLiquidation,
        uint256 liquidationDiscount
    );

    event TransferAccount(address oldOwner, address newOwner);

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    /**
     * @dev Opens credit account and provides credit funds.
     * - Opens credit account (take it from account factory)
     * - Transfers trader /farmers initial funds to credit account
     * - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
     * - Emits OpenCreditAccount event
     * Function reverts if user has already opened position
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
     *
     * @param amount Borrowers own funds
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param leverageFactor Multiplier to borrowers own funds
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external override;

    /**
     * @dev Closes credit account
     * - Swaps all assets to underlying one using default swap protocol
     * - Pays borrowed amount + interest accrued + fees back to the pool by calling repayCreditAccount
     * - Transfers remaining funds to the trader / farmer
     * - Closes the credit account and return it to account factory
     * - Emits CloseCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#close-credit-account
     *
     * @param to Address to send remaining funds
     * @param paths Exchange type data which provides paths + amountMinOut
     */
    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external
        override;

    /**
     * @dev Liquidates credit account
     * - Transfers discounted total credit account value from liquidators account
     * - Pays borrowed funds + interest + fees back to pool, than transfers remaining funds to credit account owner
     * - Transfer all assets from credit account to liquidator ("to") account
     * - Returns credit account to factory
     * - Emits LiquidateCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#liquidate-credit-account
     *
     * @param borrower Borrower address
     * @param to Address to transfer all assets from credit account
     * @param force If true, use transfer function for transferring tokens instead of safeTransfer
     */
    function liquidateCreditAccount(
        address borrower,
        address to,
        bool force
    ) external;

    /// @dev Repays credit account
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#repay-credit-account
    ///
    /// @param to Address to send credit account assets
    function repayCreditAccount(address to) external override;

    /// @dev Repays credit account with ETH. Restricted to be called by WETH Gateway only
    ///
    /// @param borrower Address of borrower
    /// @param to Address to send credit account assets
    function repayCreditAccountETH(address borrower, address to)
        external
        returns (uint256);

    /// @dev Increases borrowed amount by transferring additional funds from
    /// the pool if after that HealthFactor > minHealth
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrowed-amount
    ///
    /// @param amount Amount to increase borrowed amount
    function increaseBorrowedAmount(uint256 amount) external override;

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external override;

    /// @dev Returns true if the borrower has opened a credit account
    /// @param borrower Borrower account
    function hasOpenedCreditAccount(address borrower)
        external
        view
        override
        returns (bool);

    /// @dev Calculates Repay amount = borrow amount + interest accrued + fee
    ///
    /// More info: https://dev.gearbox.fi/developers/credit/economy#repay
    ///           https://dev.gearbox.fi/developers/credit/economy#liquidate
    ///
    /// @param borrower Borrower address
    /// @param isLiquidated True if calculated repay amount for liquidator
    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        override
        returns (uint256);

    /// @dev Returns minimal amount for open credit account
    function minAmount() external view returns (uint256);

    /// @dev Returns maximum amount for open credit account
    function maxAmount() external view returns (uint256);

    /// @dev Returns maximum leveraged factor allowed for this pool
    function maxLeverageFactor() external view returns (uint256);

    /// @dev Returns underlying token address
    function underlyingToken() external view returns (address);

    /// @dev Returns address of connected pool
    function poolService() external view returns (address);

    /// @dev Returns address of CreditFilter
    function creditFilter() external view returns (ICreditFilter);

    /// @dev Returns address of CreditFilter
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Executes filtered order on credit account which is connected with particular borrowers
    /// @param borrower Borrower address
    /// @param target Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    ) external returns (bytes memory);

    /// @dev Approves token for msg.sender's credit account
    function approve(address targetContract, address token) external;

    /// @dev Approve tokens for credit accounts. Restricted for adapters only
    function provideCreditAccountAllowance(
        address creditAccount,
        address toContract,
        address token
    ) external;

    function transferAccountOwnership(address newOwner) external;

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        override
        returns (address);

    function feeSuccess() external view returns (uint256);

    function feeInterest() external view returns (uint256);

    function feeLiquidation() external view returns (uint256);

    function liquidationDiscount() external view returns (uint256);

    function minHealthFactor() external view returns (uint256);

    function defaultSwapContract() external view override returns (address);
}

// SPDX-License-Identifier: BSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox.fi, 2021
pragma solidity ^0.7.4;

import "./IPriceOracle.sol";

interface ICreditFilter {
    // Emits each time token is allowed or liquidtion threshold changed
    event TokenAllowed(address indexed token, uint256 liquidityThreshold);

    // Emits each time contract is allowed or adapter changed
    event ContractAllowed(address indexed protocol, address indexed adapter);

    // Emits each time contract is forbidden
    event ContractForbidden(address indexed protocol);

    // Emits each time when fast check parameters are updated
    event NewFastCheckParameters(uint256 chiThreshold, uint256 fastCheckDelay);

    //
    // STATE-CHANGING FUNCTIONS
    //

    /// @dev Adds token to the list of allowed tokens
    /// @param token Address of allowed token
    /// @param liquidationThreshold The constant showing the maximum allowable ratio of Loan-To-Value for the i-th asset.
    function allowToken(address token, uint256 liquidationThreshold) external;

    /// @dev Adds contract to the list of allowed contracts
    /// @param targetContract Address of contract to be allowed
    /// @param adapter Adapter contract address
    function allowContract(address targetContract, address adapter) external;

    /// @dev Forbids contract and removes it from the list of allowed contracts
    /// @param targetContract Address of allowed contract
    function forbidContract(address targetContract) external;

    /// @dev Checks financial order and reverts if tokens aren't in list or collateral protection alerts
    /// @param creditAccount Address of credit account
    /// @param tokenIn Address of token In in swap operation
    /// @param tokenOut Address of token Out in swap operation
    /// @param amountIn Amount of tokens in
    /// @param amountOut Amount of tokens out
    function checkCollateralChange(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external;

    function checkMultiTokenCollateral(
        address creditAccount,
        uint256[] memory amountIn,
        uint256[] memory amountOut,
        address[] memory tokenIn,
        address[] memory tokenOut
    ) external;

    /// @dev Connects credit managaer, hecks that all needed price feeds exists and finalize config
    function connectCreditManager(address poolService) external;

    /// @dev Sets collateral protection for new credit accounts
    function initEnabledTokens(address creditAccount) external;

    function checkAndEnableToken(address creditAccount, address token) external;

    //
    // GETTERS
    //

    /// @dev Returns quantity of contracts in allowed list
    function allowedContractsCount() external view returns (uint256);

    /// @dev Returns of contract address from the allowed list by its id
    function allowedContracts(uint256 id) external view returns (address);

    /// @dev Reverts if token isn't in token allowed list
    function revertIfTokenNotAllowed(address token) external view;

    /// @dev Returns true if token is in allowed list otherwise false
    function isTokenAllowed(address token) external view returns (bool);

    /// @dev Returns quantity of tokens in allowed list
    function allowedTokensCount() external view returns (uint256);

    /// @dev Returns of token address from allowed list by its id
    function allowedTokens(uint256 id) external view returns (address);

    /// @dev Calculates total value for provided address
    /// More: https://dev.gearbox.fi/developers/credit/economy#total-value
    ///
    /// @param creditAccount Token creditAccount address
    function calcTotalValue(address creditAccount)
        external
        view
        returns (uint256 total);

    /// @dev Calculates Threshold Weighted Total Value
    /// More: https://dev.gearbox.fi/developers/credit/economy#threshold-weighted-value
    ///
    ///@param creditAccount Credit account address
    function calcThresholdWeightedValue(address creditAccount)
        external
        view
        returns (uint256 total);

    function contractToAdapter(address allowedContract)
        external
        view
        returns (address);

    /// @dev Returns address of underlying token
    function underlyingToken() external view returns (address);

    /// @dev Returns address & balance of token by the id of allowed token in the list
    /// @param creditAccount Credit account address
    /// @param id Id of token in allowed list
    /// @return token Address of token
    /// @return balance Token balance
    function getCreditAccountTokenById(address creditAccount, uint256 id)
        external
        view
        returns (
            address token,
            uint256 balance,
            uint256 tv,
            uint256 twv
        );

    /**
     * @dev Calculates health factor for the credit account
     *
     *         sum(asset[i] * liquidation threshold[i])
     *   Hf = --------------------------------------------
     *             borrowed amount + interest accrued
     *
     *
     * More info: https://dev.gearbox.fi/developers/credit/economy#health-factor
     *
     * @param creditAccount Credit account address
     * @return Health factor in percents (see PERCENTAGE FACTOR in PercentageMath.sol)
     */
    function calcCreditAccountHealthFactor(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Calculates credit account interest accrued
    /// More: https://dev.gearbox.fi/developers/credit/economy#interest-rate-accrued
    ///
    /// @param creditAccount Credit account address
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Return enabled tokens - token masks where each bit is "1" is token is enabled
    function enabledTokens(address creditAccount)
        external
        view
        returns (uint256);

    function liquidationThresholds(address token)
        external
        view
        returns (uint256);

    function priceOracle() external view returns (address);

    function updateUnderlyingTokenLiquidationThreshold() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox.fi, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {DataTypes} from "../../libraries/Types.sol";

/// @title Optimised for front-end credit Manager interface
/// @notice It's optimised for light-weight abi
interface IAppCreditManager {
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external;

    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external;

    function repayCreditAccount(address to) external;

    function increaseBorrowedAmount(uint256 amount) external;

    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external;

    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        returns (uint256);

    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    function hasOpenedCreditAccount(address borrower)
        external
        view
        returns (bool);

    function defaultSwapContract() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox. Generalized protocol that allows to get leverage and use it across various DeFi protocols
// (c) Gearbox.fi, 2021
pragma solidity ^0.7.4;

/// @title DataType library
/// @notice Contains data types used in data compressor.
library DataTypes {
    struct Exchange {
        address[] path;
        uint256 amountOutMin;
    }

    struct TokenBalance {
        address token;
        uint256 balance;
    }

    struct ContractAdapter {
        address allowedContract;
        address adapter;
    }

    struct CreditAccountData {
        address addr;
        address borrower;
        bool inUse;
        address creditManager;
        address underlyingToken;
        uint256 borrowedAmountPlusInterest;
        uint256 totalValue;
        uint256 healthFactor;
        uint256 borrowRate;
        TokenBalance[] balances;
    }

    struct CreditAccountDataExtended {
        address addr;
        address borrower;
        bool inUse;
        address creditManager;
        address underlyingToken;
        uint256 borrowedAmountPlusInterest;
        uint256 totalValue;
        uint256 healthFactor;
        uint256 borrowRate;
        TokenBalance[] balances;
        uint256 repayAmount;
        uint256 liquidationAmount;
        bool canBeClosed;
        uint256 borrowedAmount;
        uint256 cumulativeIndexAtOpen;
        uint256 since;
    }

    struct CreditManagerData {
        address addr;
        bool hasAccount;
        address underlyingToken;
        bool isWETH;
        bool canBorrow;
        uint256 borrowRate;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 maxLeverageFactor;
        uint256 availableLiquidity;
        address[] allowedTokens;
        ContractAdapter[] adapters;
    }

    struct PoolData {
        address addr;
        bool isWETH;
        address underlyingToken;
        address dieselToken;
        uint256 linearCumulativeIndex;
        uint256 availableLiquidity;
        uint256 expectedLiquidity;
        uint256 expectedLiquidityLimit;
        uint256 totalBorrowed;
        uint256 depositAPY_RAY;
        uint256 borrowAPY_RAY;
        uint256 dieselRate_RAY;
        uint256 withdrawFee;
        uint256 cumulativeIndex_RAY;
        uint256 timestampLU;
    }

    struct TokenInfo {
        address addr;
        string symbol;
        uint8 decimals;
    }

    struct AddressProviderData {
        address contractRegister;
        address acl;
        address priceOracle;
        address traderAccountFactory;
        address dataCompressor;
        address farmingFactory;
        address accountMiner;
        address treasuryContract;
        address gearToken;
        address wethToken;
        address wethGateway;
    }
}

// SPDX-License-Identifier: BSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox.fi, 2021
pragma solidity ^0.7.4;

/// @title Price oracle interface
interface IPriceOracle {

    // Emits each time new configurator is set up
    event NewPriceFeed(address indexed token, address indexed priceFeed);

    /**
     * @dev Sets price feed if it doesn't exists
     * If pricefeed exists, it changes nothing
     * This logic is done to protect Gearbox from priceOracle attack
     * when potential attacker can get access to price oracle, change them to fraud ones
     * and then liquidate all funds
     * @param token Address of token
     * @param priceFeedToken Address of chainlink price feed token => Eth
     */
    function addPriceFeed(address token, address priceFeedToken) external;

    /**
     * @dev Converts one asset into another using rate. Reverts if price feed doesn't exist
     *
     * @param amount Amount to convert
     * @param tokenFrom Token address converts from
     * @param tokenTo Token address - converts to
     * @return Amount converted to tokenTo asset
     */
    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    /**
     * @dev Gets token rate with 18 decimals. Reverts if priceFeed doesn't exist
     *
     * @param tokenFrom Converts from token address
     * @param tokenTo Converts to token address
     * @return Rate in WAD format
     */
    function getLastPrice(address tokenFrom, address tokenTo)
        external
        view
        returns (uint256);
}