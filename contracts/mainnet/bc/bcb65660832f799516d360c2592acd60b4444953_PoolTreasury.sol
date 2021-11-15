// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IUniswapV2Router02.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract DevTreasury is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Developer wallet
    address payable public devWallet;

    /// @dev SDVD contract address
    address public sdvd;

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev Uniswap factory
    IUniswapV2Factory uniswapFactory;

    /// @dev WETH address
    address weth;

    /// @dev Uniswap LP address
    address public pairAddress;

    /// @notice Release balance every 1 hour to dev wallet
    uint256 public releaseThreshold = 1 hours;

    /// @dev Last release timestamp
    uint256 public releaseTime;

    constructor (address _uniswapRouter, address _sdvd) public {
        // Set dev wallet
        devWallet = msg.sender;
        // Set uniswap router
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        // Set uniswap factory
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        // Get weth address
        weth = uniswapRouter.WETH();
        // Set SDVD address
        sdvd = _sdvd;
        // Approve uniswap router to spend sdvd
        IERC20(sdvd).approve(_uniswapRouter, uint256(- 1));
        // Set initial release time
        releaseTime = block.timestamp;
    }

    /* ========== Owner Only ========== */

    function init() external onlyOwner {
        // Get pair address after init because we wait until pair created in lord of coin
        pairAddress = uniswapFactory.getPair(sdvd, weth);
        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Mutative ========== */

    /// @notice Release SDVD to market regardless the price so dev doesn't own any SDVD from 0.5% fee.
    /// This is to protect SDVD holders.
    function release() external {
        _release();
    }

    /* ========== Internal ========== */

    function _release() internal {
        if (releaseTime.add(releaseThreshold) <= block.timestamp) {
            // Update release time
            releaseTime = block.timestamp;

            // Get SDVD balance
            uint256 sdvdBalance = IERC20(sdvd).balanceOf(address(this));

            // If there is SDVD in this contract
            // and there is enough liquidity to swap
            if (sdvdBalance > 0 && IERC20(sdvd).balanceOf(pairAddress) >= sdvdBalance) {
                address[] memory path = new address[](2);
                path[0] = sdvd;
                path[1] = weth;

                // Swap SDVD to ETH on uniswap
                // uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
                uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    sdvdBalance,
                    0,
                    path,
                    devWallet,
                    block.timestamp.add(30 minutes)
                );
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: Unlicensed

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

// SPDX-License-Identifier: Unlicensed

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IWETH.sol";
import "./interfaces/ILordOfCoin.sol";
import "./interfaces/IBPool.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract TradingTreasury is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Received(address indexed from, uint256 amount);

    /// @dev Lord of coin address
    address public controller;

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev Uniswap factory
    IUniswapV2Factory uniswapFactory;

    /// @dev Balancer pool WETH-MUSD
    address balancerPool;

    /// @dev WETH address
    address weth;

    /// @dev mUSD contract address
    address musd;

    /// @dev SDVD contract address
    address public sdvd;

    /// @dev Uniswap LP address
    address public pairAddress;

    /// @notice Release balance as sharing pool profit every 1 hour
    uint256 public releaseThreshold = 1 hours;

    /// @dev Last release timestamp
    uint256 public releaseTime;

    constructor (address _uniswapRouter, address _balancerPool, address _sdvd, address _musd) public {
        // Set uniswap router
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        // Set uniswap factory
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        // Get weth address
        weth = uniswapRouter.WETH();
        // Set balancer pool
        balancerPool = _balancerPool;
        // Set SDVD address
        sdvd = _sdvd;
        // Set mUSD address
        musd = _musd;
        // Approve uniswap to spend SDVD
        IERC20(sdvd).approve(_uniswapRouter, uint256(- 1));
        // Approve balancer to spend WETH
        IERC20(weth).approve(balancerPool, uint256(- 1));
        // Set initial release time
        releaseTime = block.timestamp;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /* ========== Owner Only ========== */

    function init(address _controller) external onlyOwner {
        // Set Lord of coin address
        controller = _controller;
        // Get pair address
        pairAddress = ILordOfCoin(controller).sdvdEthPairAddress();
        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Mutative ========== */

    /// @notice Release SDVD to be added as profit
    function release() external {
        _release();
    }

    /* ========== Internal ========== */

    function _release() internal {
        if (releaseTime.add(releaseThreshold) <= block.timestamp) {
            // Update release time
            releaseTime = block.timestamp;

            // Get SDVD balance
            uint256 sdvdBalance = IERC20(sdvd).balanceOf(address(this));

            // If there is SDVD in this contract
            // and there is enough liquidity to swap
            if (sdvdBalance > 0 && IERC20(sdvd).balanceOf(pairAddress) >= sdvdBalance) {
                // Use uniswap since this contract is registered as no fee address for swapping SDVD to ETH
                // Swap path
                address[] memory path = new address[](2);
                path[0] = sdvd;
                path[1] = weth;

                // Swap SDVD to ETH on uniswap
                // uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
                uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    sdvdBalance,
                    0,
                    path,
                    address(this),
                    block.timestamp.add(30 minutes)
                );

                // Get all ETH in this contract
                uint256 ethAmount = address(this).balance;

                // Convert ETH to WETH
                IWETH(weth).deposit{ value: ethAmount }();
                // Swap WETH to mUSD
                (uint256 musdAmount,) = IBPool(balancerPool).swapExactAmountIn(weth, ethAmount, musd, 0, uint256(-1));
                // Send it to Lord of Coin
                IERC20(musd).safeTransfer(controller, musdAmount);
                // Deposit profit
                ILordOfCoin(controller).depositTradingProfit(musdAmount);
            }
        }
    }

}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ILordOfCoin {

    function marketOpenTime() external view returns (uint256);

    function dvd() external view returns (address);

    function sdvd() external view returns (address);

    function sdvdEthPairAddress() external view returns (address);

    function buy(uint256 musdAmount) external returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function buyTo(address recipient, uint256 musdAmount) external returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function buyFromETH() payable external returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function sell(uint256 dvdAmount) external returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function sellTo(address recipient, uint256 dvdAmount) external returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function sellToETH(uint256 dvdAmount) external returns (uint256 returnedETH, uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function claimDividend() external returns (uint256 net, uint256 fee);

    function claimDividendTo(address recipient) external returns (uint256 net, uint256 fee);

    function claimDividendETH() external returns (uint256 net, uint256 fee, uint256 receivedETH);

    function checkSnapshot() external;

    function releaseTreasury() external;

    function depositTradingProfit(uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBPool {

    function isPublicSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint);

    function getTotalDenormalizedWeight() external view returns (uint);

    function getNormalizedWeight(address token) external view returns (uint);

    function getBalance(address token) external view returns (uint);

    function getSwapFee() external view returns (uint);

    function getController() external view returns (address);

    function setSwapFee(uint swapFee) external;

    function setController(address manager) external;

    function setPublicSwap(bool public_) external;

    function finalize() external;

    function bind(address token, uint balance, uint denorm) external;

    function rebind(address token, uint balance, uint denorm) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint spotPrice);

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    ) external returns (uint tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    ) external returns (uint tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    ) external returns (uint poolAmountIn);

    function totalSupply() external view returns (uint);

    function balanceOf(address whom) external view returns (uint);

    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);

    function transfer(address dst, uint amt) external returns (bool);

    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);

    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    ) external returns (uint spotPrice);

    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    ) external returns (uint tokenAmountOut);

    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    ) external returns (uint tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    ) external returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    ) external returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    ) external returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    ) external returns (uint poolAmountIn);

}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IWETH.sol";
import './interfaces/IERC20Snapshot.sol';
import './interfaces/ITreasury.sol';
import './interfaces/IVault.sol';
import './interfaces/IMasset.sol';
import './interfaces/IDvd.sol';
import './interfaces/ISDvd.sol';
import './interfaces/IPool.sol';
import './interfaces/IBPool.sol';
import './utils/MathUtils.sol';

/// @title Lord of Coin
/// @notice Lord of Coin finds the money, for you - to spend it.
/// @author Lord Nami
// Special thanks to TRIB as inspiration.
// Special thanks to Lord Nami mods @AspieJames, @defimoon, @tectumor, @downsin, @ghost, @LordFes, @converge, @cryptycreepy, @cryptpower, @jonsnow
// and everyone else who support this project by spreading the words on social media.
contract LordOfCoin is ReentrancyGuard {
    using SafeMath for uint256;
    using MathUtils for uint256;
    using SafeERC20 for IERC20;

    event Bought(address indexed sender, address indexed recipient, uint256 musdAmount, uint256 dvdReceived);
    event Sold(address indexed sender, address indexed recipient, uint256 dvdAmount, uint256 musdReceived);
    event SoldToETH(address indexed sender, address indexed recipient, uint256 dvdAmount, uint256 ethReceived);

    event DividendClaimed(address indexed recipient, uint256 musdReceived);
    event DividendClaimedETH(address indexed recipient, uint256 ethReceived);
    event Received(address indexed from, uint256 amount);

    /// @notice Applied to every buy or sale of DVD.
    /// @dev Tax denominator
    uint256 public constant CURVE_TAX_DENOMINATOR = 10;

    /// @notice Applied to every buy of DVD before bonding curve tax.
    /// @dev Tax denominator
    uint256 public constant BUY_TAX_DENOMINATOR = 20;

    /// @notice Applied to every sale of DVD after bonding curve tax.
    /// @dev Tax denominator
    uint256 public constant SELL_TAX_DENOMINATOR = 10;

    /// @notice The slope of the bonding curve.
    uint256 public constant DIVIDER = 1000000; // 1 / multiplier 0.000001 (so that we don't deal with decimals)

    /// @notice Address in which DVD are sent to be burned.
    /// These DVD can't be redeemed by the reserve.
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev WETH token address
    address weth;

    /// @dev Balancer pool WETH-MUSD
    address balancerPool;

    /// @dev mUSD token mStable address.
    address musd;

    /// @notice Dvd token instance.
    address public dvd;

    /// @notice SDvd token instance.
    address public sdvd;

    /// @notice Pair address for SDVD-ETH on uniswap
    address public sdvdEthPairAddress;

    /// @notice SDVD-ETH farming pool.
    address public sdvdEthPool;

    /// @notice DVD farming pool.
    address public dvdPool;

    /// @notice Dev treasury.
    address public devTreasury;

    /// @notice Pool treasury.
    address public poolTreasury;

    /// @notice Trading treasury.
    address public tradingTreasury;

    /// @notice Total dividend earned since the contract deployment.
    uint256 public totalDividendClaimed;

    /// @notice Total reserve value that backs all DVD in circulation.
    /// @dev Area below the bonding curve.
    uint256 public totalReserve;

    /// @notice Interface for integration with mStable.
    address public vault;

    /// @notice Current state of the application.
    /// Either already open (true) or not yet (false).
    bool public isMarketOpen = false;

    /// @notice Market will be open on this timestamp
    uint256 public marketOpenTime;

    /// @notice Current snapshot id
    /// Can be thought as week index, since snapshot is increased per week
    uint256 public snapshotId;

    /// @notice Snapshot timestamp.
    uint256 public snapshotTime;

    /// @notice Snapshot duration.
    uint256 public SNAPSHOT_DURATION = 1 weeks;

    /// @dev Total profits on each snapshot id.
    mapping(uint256 => uint256) private _totalProfitSnapshots;

    /// @dev Dividend paying SDVD supply on each snapshot id.
    mapping(uint256 => uint256) private _dividendPayingSDVDSupplySnapshots;

    /// @dev Flag to determine if account has claim their dividend on each snapshot id.
    mapping(address => mapping(uint256 => bool)) private _isDividendClaimedSnapshots;

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    constructor(
        address _vault,
        address _uniswapRouter,
        address _balancerPool,
        address _dvd,
        address _sdvd,
        address _sdvdEthPool,
        address _dvdPool,
        address _devTreasury,
        address _poolTreasury,
        address _tradingTreasury,
        uint256 _marketOpenTime
    ) public {
        // Set vault
        vault = _vault;
        // mUSD instance
        musd = IVault(vault).musd();
        // Approve vault to manage mUSD in this contract
        _approveMax(musd, vault);

        // Set uniswap router
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        // Set balancer pool
        balancerPool = _balancerPool;

        // Set weth address
        weth = uniswapRouter.WETH();

        // Approve balancer pool to manage mUSD in this contract
        _approveMax(musd, balancerPool);
        // Approve balancer pool to manage WETH in this contract
        _approveMax(weth, balancerPool);
        // Approve self to spend mUSD in this contract (used to buy from ETH / sell to ETH)
        _approveMax(musd, address(this));

        dvd = _dvd;
        sdvd = _sdvd;
        sdvdEthPool = _sdvdEthPool;
        dvdPool = _dvdPool;
        devTreasury = _devTreasury;
        poolTreasury = _poolTreasury;
        tradingTreasury = _tradingTreasury;

        // Create SDVD ETH pair
        sdvdEthPairAddress = IUniswapV2Factory(uniswapRouter.factory()).createPair(sdvd, weth);

        // Set open time
        marketOpenTime = _marketOpenTime;
        // Set initial snapshot timestamp
        snapshotTime = _marketOpenTime;
    }

    /* ========== Modifier ========== */

    modifier marketOpen() {
        require(isMarketOpen, 'Market not open');
        _;
    }

    modifier onlyTradingTreasury() {
        require(msg.sender == tradingTreasury, 'Only treasury');
        _;
    }

    /* ========== Trading Treasury Only ========== */

    /// @notice Deposit trading profit to vault
    function depositTradingProfit(uint256 amount) external onlyTradingTreasury {
        // Deposit mUSD to vault
        IVault(vault).deposit(amount);
    }

    /* ========== Mutative ========== */

    /// @notice Exchanges mUSD to DVD.
    /// @dev mUSD to be exchanged needs to be approved first.
    /// @param musdAmount mUSD amount to be exchanged.
    function buy(uint256 musdAmount) external nonReentrant returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _buy(msg.sender, msg.sender, musdAmount);
    }

    /// @notice Exchanges mUSD to DVD.
    /// @dev mUSD to be exchanged needs to be approved first.
    /// @param recipient Recipient of DVD token.
    /// @param musdAmount mUSD amount to be exchanged.
    function buyTo(address recipient, uint256 musdAmount) external nonReentrant returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _buy(msg.sender, recipient, musdAmount);
    }

    /// @notice Exchanges ETH to DVD.
    function buyFromETH() payable external nonReentrant returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _buy(address(this), msg.sender, _swapETHToMUSD(address(this), msg.value));
    }

    /// @notice Exchanges DVD to mUSD.
    /// @param dvdAmount DVD amount to be exchanged.
    function sell(uint256 dvdAmount) external nonReentrant marketOpen returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _sell(msg.sender, msg.sender, dvdAmount);
    }

    /// @notice Exchanges DVD to mUSD.
    /// @param recipient Recipient of mUSD.
    /// @param dvdAmount DVD amount to be exchanged.
    function sellTo(address recipient, uint256 dvdAmount) external nonReentrant marketOpen returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        return _sell(msg.sender, recipient, dvdAmount);
    }

    /// @notice Exchanges DVD to ETH.
    /// @param dvdAmount DVD amount to be exchanged.
    function sellToETH(uint256 dvdAmount) external nonReentrant marketOpen returns (uint256 returnedETH, uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        // Sell DVD and receive mUSD in this contract
        (returnedMUSD, marketTax, curveTax, taxedDVD) = _sell(msg.sender, address(this), dvdAmount);
        // Swap received mUSD dividend for ether and send it back to sender
        returnedETH = _swapMUSDToETH(msg.sender, returnedMUSD);

        emit SoldToETH(msg.sender, msg.sender, dvdAmount, returnedETH);
    }

    /// @notice Claim dividend in mUSD.
    function claimDividend() external nonReentrant marketOpen returns (uint256 dividend) {
        return _claimDividend(msg.sender, msg.sender);
    }

    /// @notice Claim dividend in mUSD.
    /// @param recipient Recipient of mUSD.
    function claimDividendTo(address recipient) external nonReentrant marketOpen returns (uint256 dividend) {
        return _claimDividend(msg.sender, recipient);
    }

    /// @notice Claim dividend in ETH.
    function claimDividendETH() external nonReentrant marketOpen returns (uint256 dividend, uint256 receivedETH) {
        // Claim dividend to this contract
        dividend = _claimDividend(msg.sender, address(this));
        // Swap received mUSD dividend for ether and send it back to sender
        receivedETH = _swapMUSDToETH(msg.sender, dividend);

        emit DividendClaimedETH(msg.sender, receivedETH);
    }

    /// @notice Check if we need to create new snapshot.
    function checkSnapshot() public {
        if (isMarketOpen) {
            // If time has passed for 1 week since last snapshot
            // and market is open
            if (snapshotTime.add(SNAPSHOT_DURATION) <= block.timestamp) {
                // Update snapshot timestamp
                snapshotTime = block.timestamp;
                // Take new snapshot
                snapshotId = ISDvd(sdvd).snapshot();
                // Save the interest
                _totalProfitSnapshots[snapshotId] = totalProfit();
                // Save dividend paying supply
                _dividendPayingSDVDSupplySnapshots[snapshotId] = dividendPayingSDVDSupply();
            }
            // If something wrong / there is no interest, lets try again.
            if (snapshotId > 0 && _totalProfitSnapshots[snapshotId] == 0) {
                _totalProfitSnapshots[snapshotId] = totalProfit();
            }
        }
    }

    /// @notice Release treasury.
    function releaseTreasury() public {
        if (isMarketOpen) {
            ITreasury(devTreasury).release();
            ITreasury(poolTreasury).release();
            ITreasury(tradingTreasury).release();
        }
    }

    /* ========== View ========== */

    /// @notice Get claimable dividend for address.
    /// @param account Account address.
    /// @return dividend Dividend in mUSD.
    function claimableDividend(address account) public view returns (uint256 dividend) {
        // If there is no snapshot or already claimed
        if (snapshotId == 0 || isDividendClaimedAt(account, snapshotId)) {
            return 0;
        }

        // Get sdvd balance at snapshot
        uint256 sdvdBalance = IERC20Snapshot(sdvd).balanceOfAt(account, snapshotId);
        if (sdvdBalance == 0) {
            return 0;
        }

        // Get dividend in mUSD based on SDVD balance
        dividend = sdvdBalance
        .mul(claimableProfitAt(snapshotId))
        .div(dividendPayingSDVDSupplyAt(snapshotId));
    }

    /// @notice Total mUSD that is now forever locked in the protocol.
    function totalLockedReserve() external view returns (uint256) {
        return _calculateReserveFromSupply(dvdBurnedAmount());
    }

    /// @notice Total claimable profit.
    /// @return Total claimable profit in mUSD.
    function claimableProfit() public view returns (uint256) {
        return totalProfit().div(2);
    }

    /// @notice Total claimable profit in snapshot.
    /// @return Total claimable profit in mUSD.
    function claimableProfitAt(uint256 _snapshotId) public view returns (uint256) {
        return totalProfitAt(_snapshotId).div(2);
    }

    /// @notice Total profit.
    /// @return Total profit in MUSD.
    function totalProfit() public view returns (uint256) {
        uint256 vaultBalance = IVault(vault).getBalance();
        // Sometimes mStable returns a value lower than the
        // deposit because their exchange rate gets updated after the deposit.
        if (vaultBalance < totalReserve) {
            vaultBalance = totalReserve;
        }
        return vaultBalance.sub(totalReserve);
    }

    /// @notice Total profit in snapshot.
    /// @param _snapshotId Snapshot id.
    /// @return Total profit in MUSD.
    function totalProfitAt(uint256 _snapshotId) public view returns (uint256) {
        return _totalProfitSnapshots[_snapshotId];
    }

    /// @notice Check if dividend already claimed by account.
    /// @return Is dividend claimed.
    function isDividendClaimedAt(address account, uint256 _snapshotId) public view returns (bool) {
        return _isDividendClaimedSnapshots[account][_snapshotId];
    }

    /// @notice Total supply of DVD. This includes burned DVD.
    /// @return Total supply of DVD in wei.
    function dvdTotalSupply() public view returns (uint256) {
        return IERC20(dvd).totalSupply();
    }

    /// @notice Total DVD that have been burned.
    /// @dev These DVD are still in circulation therefore they
    /// are still considered on the bonding curve formula.
    /// @return Total burned DVD in wei.
    function dvdBurnedAmount() public view returns (uint256) {
        return IERC20(dvd).balanceOf(BURN_ADDRESS);
    }

    /// @notice DVD price in wei according to the bonding curve formula.
    /// @return Current DVD price in wei.
    function dvdPrice() external view returns (uint256) {
        // price = supply * multiplier
        return dvdTotalSupply().roundedDiv(DIVIDER);
    }

    /// @notice DVD price floor in wei according to the bonding curve formula.
    /// @return Current DVD price floor in wei.
    function dvdPriceFloor() external view returns (uint256) {
        return dvdBurnedAmount().roundedDiv(DIVIDER);
    }

    /// @notice Total supply of Dividend-paying SDVD.
    /// @return Total supply of SDVD in wei.
    function dividendPayingSDVDSupply() public view returns (uint256) {
        // Get total supply
        return IERC20(sdvd).totalSupply()
        // Get sdvd in uniswap pair balance
        .sub(IERC20(sdvd).balanceOf(sdvdEthPairAddress))
        // Get sdvd in SDVD-ETH pool
        .sub(IERC20(sdvd).balanceOf(sdvdEthPool))
        // Get sdvd in DVD pool
        .sub(IERC20(sdvd).balanceOf(dvdPool))
        // Get sdvd in pool treasury
        .sub(IERC20(sdvd).balanceOf(poolTreasury))
        // Get sdvd in dev treasury
        .sub(IERC20(sdvd).balanceOf(devTreasury))
        // Get sdvd in trading treasury
        .sub(IERC20(sdvd).balanceOf(tradingTreasury));
    }

    /// @notice Total supply of Dividend-paying SDVD in snapshot.
    /// @return Total supply of SDVD in wei.
    function dividendPayingSDVDSupplyAt(uint256 _snapshotId) public view returns (uint256) {
        return _dividendPayingSDVDSupplySnapshots[_snapshotId];
    }

    /// @notice Calculates the amount of DVD in exchange for reserve after applying bonding curve tax.
    /// @param reserveAmount Reserve value in wei to use in the conversion.
    /// @return Token amount in wei after the 10% tax has been applied.
    function reserveToDVDTaxed(uint256 reserveAmount) external view returns (uint256) {
        if (reserveAmount == 0) {
            return 0;
        }
        uint256 tax = reserveAmount.div(CURVE_TAX_DENOMINATOR);
        uint256 totalDVD = reserveToDVD(reserveAmount);
        uint256 taxedDVD = reserveToDVD(tax);
        return totalDVD.sub(taxedDVD);
    }

    /// @notice Calculates the amount of reserve in exchange for DVD after applying bonding curve tax.
    /// @param tokenAmount Token value in wei to use in the conversion.
    /// @return Reserve amount in wei after the 10% tax has been applied.
    function dvdToReserveTaxed(uint256 tokenAmount) external view returns (uint256) {
        if (tokenAmount == 0) {
            return 0;
        }
        uint256 reserveAmount = dvdToReserve(tokenAmount);
        uint256 tax = reserveAmount.div(CURVE_TAX_DENOMINATOR);
        return reserveAmount.sub(tax);
    }

    /// @notice Calculates the amount of DVD in exchange for reserve.
    /// @param reserveAmount Reserve value in wei to use in the conversion.
    /// @return Token amount in wei.
    function reserveToDVD(uint256 reserveAmount) public view returns (uint256) {
        return _calculateReserveToDVD(reserveAmount, totalReserve, dvdTotalSupply());
    }

    /// @notice Calculates the amount of reserve in exchange for DVD.
    /// @param tokenAmount Token value in wei to use in the conversion.
    /// @return Reserve amount in wei.
    function dvdToReserve(uint256 tokenAmount) public view returns (uint256) {
        return _calculateDVDToReserve(tokenAmount, dvdTotalSupply(), totalReserve);
    }

    /* ========== Internal ========== */

    /// @notice Check if market can be opened
    function _checkOpenMarket() internal {
        require(marketOpenTime <= block.timestamp, 'Market not open');
        if (!isMarketOpen) {
            // Set flag
            isMarketOpen = true;
        }
    }

    /// @notice Exchanges mUSD to DVD.
    /// @dev mUSD to be exchanged needs to be approved first.
    /// @param sender Address that has mUSD token.
    /// @param recipient Address that will receive DVD token.
    /// @param musdAmount mUSD amount to be exchanged.
    function _buy(address sender, address recipient, uint256 musdAmount) internal returns (uint256 returnedDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        _checkOpenMarket();
        checkSnapshot();
        releaseTreasury();

        require(musdAmount > 0, 'Cannot buy 0');

        // Tax to be included as profit
        marketTax = musdAmount.div(BUY_TAX_DENOMINATOR);
        // Get amount after market tax
        uint256 inAmount = musdAmount.sub(marketTax);

        // Calculate bonding curve tax in mUSD
        curveTax = inAmount.div(CURVE_TAX_DENOMINATOR);

        // Convert mUSD amount to DVD amount
        uint256 totalDVD = reserveToDVD(inAmount);
        // Convert tax to DVD amount
        taxedDVD = reserveToDVD(curveTax);
        // Calculate DVD for recipient
        returnedDVD = totalDVD.sub(taxedDVD);

        // Transfer mUSD from sender to this contract
        IERC20(musd).safeTransferFrom(sender, address(this), musdAmount);

        // Deposit mUSD to vault
        IVault(vault).deposit(musdAmount);
        // Increase mUSD total reserve
        totalReserve = totalReserve.add(inAmount);

        // Send taxed DVD to burn address
        IDvd(dvd).mint(BURN_ADDRESS, taxedDVD);
        // Increase recipient DVD balance
        IDvd(dvd).mint(recipient, returnedDVD);
        // Increase user DVD Shareholder point
        IDvd(dvd).increaseShareholderPoint(recipient, returnedDVD);

        emit Bought(sender, recipient, musdAmount, returnedDVD);
    }

    /// @notice Exchanges DVD to mUSD.
    /// @param sender Address that has DVD token.
    /// @param recipient Address that will receive mUSD token.
    /// @param dvdAmount DVD amount to be exchanged.
    function _sell(address sender, address recipient, uint256 dvdAmount) internal returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD) {
        checkSnapshot();
        releaseTreasury();

        require(dvdAmount <= IERC20(dvd).balanceOf(sender), 'Insufficient balance');
        require(dvdAmount > 0, 'Cannot sell 0');
        require(IDvd(dvd).shareholderPointOf(sender) >= dvdAmount, 'Insufficient shareholder points');

        // Convert number of DVD amount that user want to sell to mUSD amount
        uint256 reserveAmount = dvdToReserve(dvdAmount);
        // Calculate tax in mUSD
        curveTax = reserveAmount.div(CURVE_TAX_DENOMINATOR);
        // Make sure fee is enough
        require(curveTax >= 1, 'Insufficient tax');

        // Get net amount
        uint256 net = reserveAmount.sub(curveTax);

        // Calculate taxed DVD
        taxedDVD = _calculateReserveToDVD(
            curveTax,
            totalReserve.sub(reserveAmount),
            dvdTotalSupply().sub(dvdAmount)
        );

        // Tax to be included as profit
        marketTax = net.div(SELL_TAX_DENOMINATOR);
        // Get musd amount for recipient
        returnedMUSD = net.sub(marketTax);

        // Decrease total reserve
        totalReserve = totalReserve.sub(net);

        // Reduce user DVD balance
        IDvd(dvd).burn(sender, dvdAmount);
        // Send taxed DVD to burn address
        IDvd(dvd).mint(BURN_ADDRESS, taxedDVD);
        // Decrease sender DVD Shareholder point
        IDvd(dvd).decreaseShareholderPoint(sender, dvdAmount);

        // Redeem mUSD from vault
        IVault(vault).redeem(returnedMUSD);
        // Send mUSD to recipient
        IERC20(musd).safeTransfer(recipient, returnedMUSD);

        emit Sold(sender, recipient, dvdAmount, returnedMUSD);
    }

    /// @notice Claim dividend in mUSD.
    /// @param sender Address that has SDVD token.
    /// @param recipient Address that will receive mUSD dividend.
    function _claimDividend(address sender, address recipient) internal returns (uint256 dividend) {
        checkSnapshot();
        releaseTreasury();

        // Get dividend in mUSD based on SDVD balance
        dividend = claimableDividend(sender);
        require(dividend > 0, 'No dividend');

        // Set dividend as claimed
        _isDividendClaimedSnapshots[sender][snapshotId] = true;

        // Redeem mUSD from vault
        IVault(vault).redeem(dividend);
        // Send dividend mUSD to user
        IERC20(musd).safeTransfer(recipient, dividend);

        emit DividendClaimed(recipient, dividend);
    }

    /// @notice Swap ETH to mUSD in this contract.
    /// @param amount ETH amount.
    /// @return musdAmount returned mUSD amount.
    function _swapETHToMUSD(address recipient, uint256 amount) internal returns (uint256 musdAmount) {
        // Convert ETH to WETH
        IWETH(weth).deposit{ value: amount }();
        // Swap WETH to mUSD
        (musdAmount,) = IBPool(balancerPool).swapExactAmountIn(weth, amount, musd, 0, uint256(-1));
        // Send mUSD
        if (recipient != address(this)) {
            IERC20(musd).safeTransfer(recipient, musdAmount);
        }
    }

    /// @notice Swap mUSD to ETH in this contract.
    /// @param amount mUSD Amount.
    /// @return ethAmount returned ETH amount.
    function _swapMUSDToETH(address recipient, uint256 amount) internal returns (uint256 ethAmount) {
        // Swap mUSD to WETH
        (ethAmount,) = IBPool(balancerPool).swapExactAmountIn(musd, amount, weth, 0, uint256(-1));
        // Convert WETH to ETH
        IWETH(weth).withdraw(ethAmount);
        // Send ETH
        if (recipient != address(this)) {
            payable(recipient).transfer(ethAmount);
        }
    }

    /// @notice Approve maximum value to spender
    function _approveMax(address tkn, address spender) internal {
        uint256 max = uint256(- 1);
        IERC20(tkn).safeApprove(spender, max);
    }

    /**
     * Supply (s), reserve (r) and token price (p) are in a relationship defined by the bonding curve:
     *      p = m * s
     * The reserve equals to the area below the bonding curve
     *      r = s^2 / 2
     * The formula for the supply becomes
     *      s = sqrt(2 * r / m)
     *
     * In solidity computations, we are using divider instead of multiplier (because its an integer).
     * All values are decimals with 18 decimals (represented as uints), which needs to be compensated for in
     * multiplications and divisions
     */

    /// @notice Computes the increased supply given an amount of reserve.
    /// @param _reserveDelta The amount of reserve in wei to be used in the calculation.
    /// @param _totalReserve The current reserve state to be used in the calculation.
    /// @param _supply The current supply state to be used in the calculation.
    /// @return _supplyDelta token amount in wei.
    function _calculateReserveToDVD(
        uint256 _reserveDelta,
        uint256 _totalReserve,
        uint256 _supply
    ) internal pure returns (uint256 _supplyDelta) {
        uint256 _reserve = _totalReserve;
        uint256 _newReserve = _reserve.add(_reserveDelta);
        // s = sqrt(2 * r / m)
        uint256 _newSupply = MathUtils.sqrt(
            _newReserve
            .mul(2)
            .mul(DIVIDER) // inverse the operation (Divider instead of multiplier)
            .mul(1e18) // compensation for the squared unit
        );

        _supplyDelta = _newSupply.sub(_supply);
    }

    /// @notice Computes the decrease in reserve given an amount of DVD.
    /// @param _supplyDelta The amount of DVD in wei to be used in the calculation.
    /// @param _supply The current supply state to be used in the calculation.
    /// @param _totalReserve The current reserve state to be used in the calculation.
    /// @return _reserveDelta Reserve amount in wei.
    function _calculateDVDToReserve(
        uint256 _supplyDelta,
        uint256 _supply,
        uint256 _totalReserve
    ) internal pure returns (uint256 _reserveDelta) {
        require(_supplyDelta <= _supply, 'Token amount must be less than the supply');

        uint256 _newSupply = _supply.sub(_supplyDelta);
        uint256 _newReserve = _calculateReserveFromSupply(_newSupply);
        _reserveDelta = _totalReserve.sub(_newReserve);
    }

    /// @notice Calculates reserve given a specific supply.
    /// @param _supply The token supply in wei to be used in the calculation.
    /// @return _reserve Reserve amount in wei.
    function _calculateReserveFromSupply(uint256 _supply) internal pure returns (uint256 _reserve) {
        // r = s^2 * m / 2
        _reserve = _supply
        .mul(_supply)
        .div(DIVIDER) // inverse the operation (Divider instead of multiplier)
        .div(2)
        .roundedDiv(1e18);
        // correction of the squared unit
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20Snapshot {

    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ITreasury {

    function release() external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IVault {

    function savingsContract() external view returns (address);

    function musd() external view returns (address);

    function deposit(uint256) external;

    function redeem(uint256) external;

    function getBalance() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { MassetStructs } from "./MassetStructs.sol";

///
/// @title IMasset
/// @dev   (Internal) Interface for interacting with Masset
///       VERSION: 1.0
///       DATE:    2020-05-05

interface IMasset is MassetStructs {

    /// @dev Calc interest
    function collectInterest() external returns (uint256 massetMinted, uint256 newTotalSupply);

    /// @dev Minting
    function mint(address _basset, uint256 _bassetQuantity)
        external returns (uint256 massetMinted);
    function mintTo(address _basset, uint256 _bassetQuantity, address _recipient)
        external returns (uint256 massetMinted);
    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantity, address _recipient)
        external returns (uint256 massetMinted);

    /// @dev Swapping
    function swap( address _input, address _output, uint256 _quantity, address _recipient)
        external returns (uint256 output);
    function getSwapOutput( address _input, address _output, uint256 _quantity)
        external view returns (bool, string memory, uint256 output);

    /// @dev Redeeming
    function redeem(address _basset, uint256 _bassetQuantity)
        external returns (uint256 massetRedeemed);
    function redeemTo(address _basset, uint256 _bassetQuantity, address _recipient)
        external returns (uint256 massetRedeemed);
    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantities, address _recipient)
        external returns (uint256 massetRedeemed);
    function redeemMasset(uint256 _mAssetQuantity, address _recipient) external;

    /// @dev Setters for the Manager or Gov to update module info
    function upgradeForgeValidator(address _newForgeValidator) external;

    /// @dev Setters for Gov to set system params
    function setSwapFee(uint256 _swapFee) external;

    /// @dev Getters
    function getBasketManager() external view returns(address);
    function forgeValidator() external view returns (address);
    function totalSupply() external view returns (uint256);
    function swapFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDvd is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function increaseShareholderPoint(address account, uint256 amount) external;

    function decreaseShareholderPoint(address account, uint256 amount) external;

    function shareholderPointOf(address account) external view returns (uint256);

    function totalShareholderPoint() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISDvd is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function setMinter(address account, bool value) external;

    function setNoFeeAddress(address account, bool value) external;

    function setPairAddress(address _pairAddress) external;

    function snapshot() external returns (uint256);

    function syncPairTokenTotalSupply() external returns (bool isPairTokenBurned);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPool {

    function openFarm() external;

    function distributeBonusRewards(uint256 amount) external;

    function stake(uint256 amount) external;

    function stakeTo(address recipient, uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawTo(address recipient, uint256 amount) external;

    function claimReward() external;

    function claimRewardTo(address recipient) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

library MathUtils {
    using SafeMath for uint256;

    /// @notice Calculates the square root of a given value.
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }

    /// @notice Rounds a division result.
    function roundedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'div by 0');

        uint256 halfB = (b.mod(2) == 0) ? (b.div(2)) : (b.div(2).add(1));
        return (a.mod(b) >= halfB) ? (a.div(b).add(1)) : (a.div(b));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//
// @title   MassetStructs
// @author  Stability Labs Pty. Ltd.
// @notice  Structs used in the Masset contract and associated Libs

interface MassetStructs {

    // Stores high level basket info
    struct Basket {

        // Array of Bassets currently active
        Basset[] bassets;

        // Max number of bAssets that can be present in any Basket
        uint8 maxBassets;

        // Some bAsset is undergoing re-collateralisation
        bool undergoingRecol;

        //
        // In the event that we do not raise enough funds from the auctioning of a failed Basset,
        // The Basket is deemed as failed, and is undercollateralised to a certain degree.
        // The collateralisation ratio is used to calc Masset burn rate.
        
        bool failed;
        uint256 collateralisationRatio;

    }

    // Stores bAsset info. The struct takes 5 storage slots per Basset
    struct Basset {

        // Address of the bAsset
        address addr;

        // Status of the basset, 
        BassetStatus status; // takes uint8 datatype (1 byte) in storage

        // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
        bool isTransferFeeCharged; // takes a byte in storage

        //
        // 1 Basset * ratio / ratioScale == x Masset (relative value)
        //      If ratio == 10e8 then 1 bAsset = 10 mAssets
        //      A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
        
        uint256 ratio;

        // Target weights of the Basset (100% == 1e18)
        uint256 maxWeight;

        // Amount of the Basset that is held in Collateral
        uint256 vaultBalance;

    }

    // Status of the Basset - has it broken its peg?
    enum BassetStatus {
        Default,
        Normal,
        BrokenBelowPeg,
        BrokenAbovePeg,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }

    // Internal details on Basset
    struct BassetDetails {
        Basset bAsset;
        address integrator;
        uint8 index;
    }

    // All details needed to Forge with multiple bAssets
    struct ForgePropsMulti {
        bool isValid; // Flag to signify that forge bAssets have passed validity check
        Basset[] bAssets;
        address[] integrators;
        uint8[] indexes;
    }

    // All details needed for proportionate Redemption
    struct RedeemPropsMulti {
        uint256 colRatio;
        Basset[] bAssets;
        address[] integrators;
        uint8[] indexes;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import './MathUtils.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

library LordLib {

    using SafeMath for uint256;
    using MathUtils for uint256;

    /// @notice The slope of the bonding curve.
    uint256 public constant DIVIDER = 1000000; // 1 / multiplier 0.000001 (so that we don't deal with decimals)

    /**
     * Supply (s), reserve (r) and token price (p) are in a relationship defined by the bonding curve:
     *      p = m * s
     * The reserve equals to the area below the bonding curve
     *      r = s^2 / 2
     * The formula for the supply becomes
     *      s = sqrt(2 * r / m)
     *
     * In solidity computations, we are using divider instead of multiplier (because its an integer).
     * All values are decimals with 18 decimals (represented as uints), which needs to be compensated for in
     * multiplications and divisions
     */

    /// @notice Computes the increased supply given an amount of reserve.
    /// @param _reserveDelta The amount of reserve in wei to be used in the calculation.
    /// @param _totalReserve The current reserve state to be used in the calculation.
    /// @param _supply The current supply state to be used in the calculation.
    /// @return token amount in wei.
    function calculateReserveToTokens(
        uint256 _reserveDelta,
        uint256 _totalReserve,
        uint256 _supply
    ) internal pure returns (uint256) {
        uint256 _reserve = _totalReserve;
        uint256 _newReserve = _reserve.add(_reserveDelta);
        // s = sqrt(2 * r / m)
        uint256 _newSupply = MathUtils.sqrt(
            _newReserve
            .mul(2)
            .mul(DIVIDER) // inverse the operation (Divider instead of multiplier)
            .mul(1e18) // compensation for the squared unit
        );

        uint256 _supplyDelta = _newSupply.sub(_supply);
        return _supplyDelta;
    }

    /// @notice Computes the decrease in reserve given an amount of tokens.
    /// @param _supplyDelta The amount of tokens in wei to be used in the calculation.
    /// @param _supply The current supply state to be used in the calculation.
    /// @param _totalReserve The current reserve state to be used in the calculation.
    /// @return Reserve amount in wei.
    function calculateTokensToReserve(
        uint256 _supplyDelta,
        uint256 _supply,
        uint256 _totalReserve
    ) internal pure returns (uint256) {
        require(_supplyDelta <= _supply, 'Token amount must be less than the supply');

        uint256 _newSupply = _supply.sub(_supplyDelta);

        uint256 _newReserve = calculateReserveFromSupply(_newSupply);

        uint256 _reserveDelta = _totalReserve.sub(_newReserve);

        return _reserveDelta;
    }

    /// @notice Calculates reserve given a specific supply.
    /// @param _supply The token supply in wei to be used in the calculation.
    /// @return Reserve amount in wei.
    function calculateReserveFromSupply(uint256 _supply) internal pure returns (uint256) {
        // r = s^2 * m / 2
        uint256 _reserve = _supply
        .mul(_supply)
        .div(DIVIDER) // inverse the operation (Divider instead of multiplier)
        .div(2);

        return _reserve.roundedDiv(1e18);
        // correction of the squared unit
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import './interfaces/IVault.sol';
import './interfaces/IMStable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract Vault is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event FundMigration(uint256 value);

    /// @notice mStable governance proxy contract.
    /// It should not change.
    address public nexusGovernance;

    /// @notice mStable savingsContract contract.
    /// It can be changed through governance.
    address public savingsContract;

    /// @notice mUSD address.
    address public musd;

    /// @notice LoC address
    address public controller;

    constructor(address _musd, address _nexus) public {
        // Set mUSD address
        musd = _musd;
        // Set nexus governance address
        nexusGovernance = _nexus;
        // Get mStable savings contract
        savingsContract = _fetchMStableSavings();
        // Approve savings contract to spend mUSD on this contract
        _approveMax(musd, savingsContract);
    }

    /* ========== Modifiers ========== */

    modifier onlyController {
        require(msg.sender == controller, 'Controller only');
        _;
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately.
    function init(address _controller) external onlyOwner {
        // Set Lord of coin
        controller = _controller;

        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Controller Only ========== */

    /// @notice Deposits reserve into savingsAccount.
    /// @dev It is part of Vault's interface.
    /// @param amount Value to be deposited.
    function deposit(uint256 amount) external onlyController {
        require(amount > 0, 'Cannot deposit 0');

        // Transfer mUSD from sender to this contract
        IERC20(musd).safeTransferFrom(msg.sender, address(this), amount);
        // Send to savings account
        IMStable(savingsContract).depositSavings(amount);
    }

    /// @notice Redeems reserve from savingsAccount.
    /// @dev It is part of Vault's interface.
    /// @param amount Value to be redeemed.
    function redeem(uint256 amount) external onlyController {
        require(amount > 0, 'Cannot redeem 0');

        // Redeem the amount in credits
        uint256 credited = IMStable(savingsContract).redeem(_getRedeemInput(amount));
        // Send credited amount to sender
        IERC20(musd).safeTransfer(msg.sender, credited);
    }

    /* ========== View ========== */

    /// @notice Returns balance in reserve from the savings contract.
    /// @dev It is part of Vault's interface.
    /// @return balance Reserve amount in the savings contract.
    function getBalance() public view returns (uint256 balance) {
        // Get balance in credits amount
        balance = IMStable(savingsContract).creditBalances(address(this));
        // Convert credits to reserve amount
        if (balance > 0) {
            balance = balance.mul(IMStable(savingsContract).exchangeRate()).div(1e18);
        }
    }

    /* ========== Mutative ========== */

    /// @notice Allows anyone to migrate all reserve to new savings contract.
    /// @dev Only use if the savingsContract has been changed by governance.
    function migrateSavings() external {
        address currentSavingsContract = _fetchMStableSavings();
        require(currentSavingsContract != savingsContract, 'Already on latest contract');
        _swapSavingsContract();
    }

    /* ========== Internal ========== */

    /// @notice Convert amount to mStable credits amount for redeem.
    function _getRedeemInput(uint256 amount) internal view returns (uint256 credits) {
        // Add 1 because the amounts always round down
        // e.g. i have 51 credits, e4 10 = 20.4
        // to withdraw 20 i need 20*10/4 = 50 + 1
        credits = amount.mul(1e18).div(IMStable(savingsContract).exchangeRate()).add(1);
    }

    /// @notice Approve spender to max.
    function _approveMax(address token, address spender) internal {
        uint256 max = uint256(- 1);
        IERC20(token).safeApprove(spender, max);
    }

    /// @notice Gets the current mStable Savings Contract address.
    /// @return address of mStable Savings Contract.
    function _fetchMStableSavings() internal view returns (address) {
        address manager = IMStable(nexusGovernance).getModule(keccak256('SavingsManager'));
        return IMStable(manager).savingsContracts(musd);
    }

    /// @notice Worker function that swaps the reserve to a new savings contract.
    function _swapSavingsContract() internal {
        // Get all savings balance
        uint256 balance = getBalance();
        // Redeem the amount in credits
        uint256 credited = IMStable(savingsContract).redeem(_getRedeemInput(balance));

        // Get new savings contract
        savingsContract = _fetchMStableSavings();
        // Approve new savings contract as mUSD spender
        _approveMax(musd, savingsContract);

        // Send to new savings account
        IMStable(savingsContract).depositSavings(credited);

        // Emit event
        emit FundMigration(balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IMStable {
    // Nexus
    function getModule(bytes32) external view returns (address);

    // Savings Manager
    function savingsContracts(address) external view returns (address);

    // Savings Contract
    function exchangeRate() external view returns (uint256);

    function creditBalances(address) external view returns (uint256);

    function depositSavings(uint256) external;

    function redeem(uint256) external returns (uint256);

    function depositInterest(uint256) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./interfaces/ILordOfCoin.sol";
import "./interfaces/ITreasury.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract SDvd is ERC20Snapshot, Ownable {

    using SafeMath for uint256;

    /// @notice Minter address. DVD-ETH Pool, DVD Pool.
    mapping(address => bool) public minters;
    /// @dev No fee address. SDVD-ETH Pool, DVD Pool.
    mapping(address => bool) public noFeeAddresses;
    /// @notice Lord of Coin
    address public controller;

    address public devTreasury;
    address public poolTreasury;
    address public tradingTreasury;

    /// @dev SDVD-ETH pair address
    address public pairAddress;
    /// @dev SDVD-ETH pair token
    IUniswapV2Pair pairToken;
    /// @dev Used to check LP removal
    uint256 lastPairTokenTotalSupply;

    constructor() public ERC20('Stock dvd.finance', 'SDVD') {
    }

    /* ========== Modifiers ========== */

    modifier onlyMinter {
        require(minters[msg.sender], 'Minter only');
        _;
    }

    modifier onlyController {
        require(msg.sender == controller, 'Controller only');
        _;
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately
    function init(
        address _controller,
        address _pairAddress,
        address _sdvdEthPool,
        address _dvdPool,
        address _devTreasury,
        address _poolTreasury,
        address _tradingTreasury
    ) external onlyOwner {
        controller = _controller;

        // Create uniswap pair for SDVD-ETH pool
        pairAddress = _pairAddress;
        // Set pair token
        pairToken = IUniswapV2Pair(pairAddress);

        devTreasury = _devTreasury;
        poolTreasury = _poolTreasury;
        tradingTreasury = _tradingTreasury;

        // Add pools as SDVD minter
        _setMinter(_sdvdEthPool, true);
        _setMinter(_dvdPool, true);

        // Add no fees address
        _setNoFeeAddress(_sdvdEthPool, true);
        _setNoFeeAddress(_dvdPool, true);
        _setNoFeeAddress(devTreasury, true);
        _setNoFeeAddress(poolTreasury, true);
        _setNoFeeAddress(tradingTreasury, true);

        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Minter Only ========== */

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    /* ========== Controller Only ========== */

    function snapshot() external onlyController returns (uint256) {
        return _snapshot();
    }

    /* ========== Public ========== */

    function syncPairTokenTotalSupply() public returns (bool isPairTokenBurned) {
        // Get LP token total supply
        uint256 pairTokenTotalSupply = pairToken.totalSupply();
        // If last total supply > current total supply,
        // It means LP token is burned by uniswap, which means someone removing liquidity
        isPairTokenBurned = lastPairTokenTotalSupply > pairTokenTotalSupply;
        // Save total supply
        lastPairTokenTotalSupply = pairTokenTotalSupply;
    }

    /* ========== Internal ========== */

    function _setMinter(address account, bool value) internal {
        minters[account] = value;
    }

    function _setNoFeeAddress(address account, bool value) internal {
        noFeeAddresses[account] = value;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        // Check uniswap liquidity removal
        _checkUniswapLiquidityRemoval(sender);

        if (noFeeAddresses[sender] || noFeeAddresses[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            // 0.5% for dev
            uint256 devFee = amount.div(200);
            // 1% for farmers in pool
            uint256 poolFee = devFee.mul(2);
            // 1% to goes as sharing profit
            uint256 tradingFee = poolFee;

            // Get net amount
            uint256 net = amount
            .sub(devFee)
            .sub(poolFee)
            .sub(tradingFee);

            super._transfer(sender, recipient, net);
            super._transfer(sender, devTreasury, devFee);
            super._transfer(sender, poolTreasury, poolFee);
            super._transfer(sender, tradingTreasury, tradingFee);
        }
    }

    function _checkUniswapLiquidityRemoval(address sender) internal {
        bool isPairTokenBurned = syncPairTokenTotalSupply();

        // If from uniswap LP address
        if (sender == pairAddress) {
            // Check if liquidity removed
            require(isPairTokenBurned == false, 'LP removal disabled');
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../math/SafeMath.sol";
import "../../utils/Arrays.sol";
import "../../utils/Counters.sol";
import "./ERC20.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: Unlicensed

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILordOfCoin.sol";
import "./interfaces/IDvd.sol";
import "./interfaces/ISDvd.sol";
import "./interfaces/ITreasury.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
abstract contract Pool is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Staked(address indexed sender, address indexed recipient, uint256 amount);
    event Withdrawn(address indexed sender, address indexed recipient, uint256 amount);
    event Claimed(address indexed sender, address indexed recipient, uint256 net, uint256 tax, uint256 total);
    event Halving(uint256 amount);

    /// @dev Token will be DVD or SDVD-ETH UNI-V2
    address public stakedToken;
    ISDvd public sdvd;

    /// @notice Flag to determine if farm is open
    bool public isFarmOpen = false;
    /// @notice Farming will be open on this timestamp
    uint256 public farmOpenTime;

    uint256 public rewardAllocation;
    uint256 public rewardRate;
    uint256 public rewardDuration = 1460 days;  // halving per 4 years
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public finishTime;

    uint256 public bonusRewardAllocation;
    uint256 public bonusRewardRate;
    uint256 public bonusRewardDuration = 1 days; //  Reward bonus distributed every day, must be the same value with pool treasury release threshold
    uint256 public bonusLastUpdateTime;
    uint256 public bonusRewardPerTokenStored;
    uint256 public bonusRewardFinishTime;

    struct AccountInfo {
        // Staked token balance
        uint256 balance;
        // Normal farming reward
        uint256 reward;
        uint256 rewardPerTokenPaid;
        // Bonus reward from transaction fee
        uint256 bonusReward;
        uint256 bonusRewardPerTokenPaid;
    }

    /// @dev Account info
    mapping(address => AccountInfo) public accountInfos;

    /// @dev Total supply of staked tokens
    uint256 private _totalSupply;

    /// @notice Total rewards minted from this pool
    uint256 public totalRewardMinted;

    // @dev Lord of Coin
    address controller;

    // @dev Pool treasury
    address poolTreasury;

    constructor(address _poolTreasury, uint256 _farmOpenTime) public {
        poolTreasury = _poolTreasury;
        farmOpenTime = _farmOpenTime;
    }

    /* ========== Modifiers ========== */

    modifier onlyController {
        require(msg.sender == controller, 'Controller only');
        _;
    }

    modifier onlyPoolTreasury {
        require(msg.sender == poolTreasury, 'Treasury only');
        _;
    }

    modifier farmOpen {
        require(isFarmOpen, 'Farm not open');
        _;
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately
    function init(address _controller, address _stakedToken) external onlyOwner {
        controller = _controller;
        stakedToken = _stakedToken;
        sdvd = ISDvd(ILordOfCoin(_controller).sdvd());

        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Pool Treasury Only ========== */

    /// @notice Distribute bonus rewards to farmers
    /// @dev Can only be called by pool treasury
    function distributeBonusRewards(uint256 amount) external onlyPoolTreasury {
        // Set bonus reward allocation
        bonusRewardAllocation = amount;
        // Calculate bonus reward rate
        bonusRewardRate = bonusRewardAllocation.div(bonusRewardDuration);
        // Set finish time
        bonusRewardFinishTime = block.timestamp.add(bonusRewardDuration);
        // Set last update time
        bonusLastUpdateTime = block.timestamp;
    }

    /* ========== Mutative ========== */

    /// @notice Stake token.
    /// @dev Need to approve staked token first.
    /// @param amount Token amount.
    function stake(uint256 amount) external nonReentrant {
        _stake(msg.sender, msg.sender, amount);
    }

    /// @notice Stake token.
    /// @dev Need to approve staked token first.
    /// @param recipient Address who receive staked token balance.
    /// @param amount Token amount.
    function stakeTo(address recipient, uint256 amount) external nonReentrant {
        _stake(msg.sender, recipient, amount);
    }

    /// @notice Withdraw token.
    /// @param amount Token amount.
    function withdraw(uint256 amount) external nonReentrant farmOpen {
        _withdraw(msg.sender, msg.sender, amount);
    }

    /// @notice Withdraw token.
    /// @param recipient Address who receive staked token.
    /// @param amount Token amount.
    function withdrawTo(address recipient, uint256 amount) external nonReentrant farmOpen {
        _withdraw(msg.sender, recipient, amount);
    }

    /// @notice Claim SDVD reward
    /// @return Reward net amount
    /// @return Reward tax amount
    /// @return Total Reward amount
    function claimReward() external nonReentrant farmOpen returns(uint256, uint256, uint256) {
        return _claimReward(msg.sender, msg.sender);
    }

    /// @notice Claim SDVD reward
    /// @param recipient Address who receive reward.
    /// @return Reward net amount
    /// @return Reward tax amount
    /// @return Total Reward amount
    function claimRewardTo(address recipient) external nonReentrant farmOpen returns(uint256, uint256, uint256) {
        return _claimReward(msg.sender, recipient);
    }

    /* ========== Internal ========== */

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            accountInfos[account].reward = earned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    function _updateBonusReward(address account) internal {
        bonusRewardPerTokenStored = bonusRewardPerToken();
        bonusLastUpdateTime = lastTimeBonusRewardApplicable();
        if (account != address(0)) {
            accountInfos[account].bonusReward = bonusEarned(account);
            accountInfos[account].bonusRewardPerTokenPaid = bonusRewardPerTokenStored;
        }
    }

    /// @notice Stake staked token
    /// @param sender address. Address who have the token.
    /// @param recipient address. Address who receive staked token balance.
    function _stake(address sender, address recipient, uint256 amount) internal virtual {
        _checkOpenFarm();
        _checkHalving();
        _updateReward(recipient);
        _updateBonusReward(recipient);
        _notifyController();

        require(amount > 0, 'Cannot stake 0');

        IERC20(stakedToken).safeTransferFrom(sender, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        accountInfos[recipient].balance = accountInfos[recipient].balance.add(amount);

        emit Staked(sender, recipient, amount);
    }

    /// @notice Withdraw staked token
    /// @param sender address. Address who have stake the token.
    /// @param recipient address. Address who receive the staked token.
    function _withdraw(address sender, address recipient, uint256 amount) internal virtual {
        _checkHalving();
        _updateReward(sender);
        _updateBonusReward(sender);
        _notifyController();

        require(amount > 0, 'Cannot withdraw 0');
        require(accountInfos[sender].balance >= amount, 'Insufficient balance');

        _totalSupply = _totalSupply.sub(amount);
        accountInfos[sender].balance = accountInfos[sender].balance.sub(amount);
        IERC20(stakedToken).safeTransfer(recipient, amount);

        emit Withdrawn(sender, recipient, amount);
    }

    /// @notice Claim reward
    /// @param sender address. Address who have stake the token.
    /// @param recipient address. Address who receive the reward.
    /// @return totalNetReward Total net SDVD reward.
    /// @return totalTaxReward Total taxed SDVD reward.
    /// @return totalReward Total SDVD reward.
    function _claimReward(address sender, address recipient) internal virtual returns(uint256 totalNetReward, uint256 totalTaxReward, uint256 totalReward) {
        _checkHalving();
        _updateReward(sender);
        _updateBonusReward(sender);
        _notifyController();

        uint256 reward = accountInfos[sender].reward;
        uint256 bonusReward = accountInfos[sender].bonusReward;
        totalReward = reward.add(bonusReward);
        require(totalReward > 0, 'No reward to claim');
        if (reward > 0) {
            // Reduce reward first
            accountInfos[sender].reward = 0;

            // Apply tax
            uint256 tax = reward.div(claimRewardTaxDenominator());
            uint256 net = reward.sub(tax);

            // Mint SDVD as reward to recipient
            sdvd.mint(recipient, net);
            // Mint SDVD tax to pool treasury
            sdvd.mint(address(poolTreasury), tax);

            // Increase total
            totalNetReward = totalNetReward.add(net);
            totalTaxReward = totalTaxReward.add(tax);
            // Set stats
            totalRewardMinted = totalRewardMinted.add(reward);
        }
        if (bonusReward > 0) {
            // Reduce bonus reward first
            accountInfos[sender].bonusReward = 0;
            // Get balance and check so we doesn't overrun
            uint256 balance = sdvd.balanceOf(address(this));
            if (bonusReward > balance) {
                bonusReward = balance;
            }

            // Apply tax
            uint256 tax = bonusReward.div(claimRewardTaxDenominator());
            uint256 net = bonusReward.sub(tax);

            // Send bonus reward to recipient
            IERC20(sdvd).safeTransfer(recipient, net);
            // Send tax to treasury
            IERC20(sdvd).safeTransfer(address(poolTreasury), tax);

            // Increase total
            totalNetReward = totalNetReward.add(net);
            totalTaxReward = totalTaxReward.add(tax);
        }
        if (totalReward > 0) {
            emit Claimed(sender, recipient, totalNetReward, totalTaxReward, totalReward);
        }
    }

    /// @notice Check if farm can be open
    function _checkOpenFarm() internal {
        require(farmOpenTime <= block.timestamp, 'Farm not open');
        if (!isFarmOpen) {
            // Set flag
            isFarmOpen = true;

            // Initialize
            lastUpdateTime = block.timestamp;
            finishTime = block.timestamp.add(rewardDuration);
            rewardRate = rewardAllocation.div(rewardDuration);

            // Initialize bonus
            bonusLastUpdateTime = block.timestamp;
            bonusRewardFinishTime = block.timestamp.add(bonusRewardDuration);
            bonusRewardRate = bonusRewardAllocation.div(bonusRewardDuration);
        }
    }

    /// @notice Check and do halving when finish time reached
    function _checkHalving() internal {
        if (block.timestamp >= finishTime) {
            // Halving reward
            rewardAllocation = rewardAllocation.div(2);
            // Calculate reward rate
            rewardRate = rewardAllocation.div(rewardDuration);
            // Set finish time
            finishTime = block.timestamp.add(rewardDuration);
            // Set last update time
            lastUpdateTime = block.timestamp;
            // Emit event
            emit Halving(rewardAllocation);
        }
    }

    /// @notice Check if need to increase snapshot in lord of coin
    function _notifyController() internal {
        ILordOfCoin(controller).checkSnapshot();
        ILordOfCoin(controller).releaseTreasury();
    }

    /* ========== View ========== */

    /// @notice Get staked token total supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get staked token balance
    function balanceOf(address account) external view returns (uint256) {
        return accountInfos[account].balance;
    }

    /// @notice Get full earned amount and bonus
    /// @dev Combine earned
    function fullEarned(address account) external view returns (uint256) {
        return earned(account).add(bonusEarned(account));
    }

    /// @notice Get full reward rate
    /// @dev Combine reward rate
    function fullRewardRate() external view returns (uint256) {
        return rewardRate.add(bonusRewardRate);
    }

    /// @notice Get claim reward tax
    function claimRewardTaxDenominator() public view returns (uint256) {
        if (block.timestamp < farmOpenTime.add(365 days)) {
            // 50% tax
            return 2;
        } else if (block.timestamp < farmOpenTime.add(730 days)) {
            // 33% tax
            return 3;
        } else if (block.timestamp < farmOpenTime.add(1095 days)) {
            // 25% tax
            return 4;
        } else if (block.timestamp < farmOpenTime.add(1460 days)) {
            // 20% tax
            return 5;
        } else {
            // 10% tax
            return 10;
        }
    }

    /// Normal rewards

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, finishTime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            rewardPerToken().sub(accountInfos[account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].reward);
    }

    /// Bonus

    function lastTimeBonusRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, bonusRewardFinishTime);
    }

    function bonusRewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return bonusRewardPerTokenStored;
        }
        return bonusRewardPerTokenStored.add(
            lastTimeBonusRewardApplicable().sub(bonusLastUpdateTime).mul(bonusRewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function bonusEarned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            bonusRewardPerToken().sub(accountInfos[account].bonusRewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].bonusReward);
    }

}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IDvd.sol";
import "./Pool.sol";

contract SDvdEthPool is Pool {

    event StakedETH(address indexed account, uint256 amount);
    event ClaimedAndStaked(address indexed account, uint256 amount);

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev Uniswap factory
    IUniswapV2Factory uniswapFactory;

    /// @dev WETH address
    address weth;

    /// @notice LGE state
    bool public isLGEActive = true;

    /// @notice Max initial deposit cap
    uint256 public LGE_INITIAL_DEPOSIT_CAP = 5 ether;

    /// @notice Amount in SDVD. After hard cap reached, stake ETH will function as normal staking.
    uint256 public LGE_HARD_CAP = 200 ether;

    /// @dev Initial price multiplier
    uint256 public LGE_INITIAL_PRICE_MULTIPLIER = 2;

    constructor(address _poolTreasury, address _uniswapRouter, uint256 _farmOpenTime) public Pool(_poolTreasury, _farmOpenTime) {
        rewardAllocation = 240000 * 1e18;
        rewardAllocation = rewardAllocation.sub(LGE_HARD_CAP.div(2));
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        weth = uniswapRouter.WETH();
    }

    /// @dev Added to receive ETH when swapping on Uniswap
    receive() external payable {
    }

    /// @notice Stake token using ETH conveniently.
    function stakeETH() external payable nonReentrant {
        _stakeETH(msg.value);
    }

    /// @notice Stake token using SDVD and ETH conveniently.
    /// @dev User must approve SDVD first
    function stakeSDVD(uint256 amountToken) external payable nonReentrant farmOpen {
        require(isLGEActive == false, 'LGE still active');

        uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);
        uint256 pairETHBalance = IERC20(weth).balanceOf(stakedToken);
        uint256 amountETH = amountToken.mul(pairETHBalance).div(pairSDVDBalance);

        // Make sure received eth is enough
        require(msg.value >= amountETH, 'Not enough ETH');
        // Check if there is excess eth
        uint256 excessETH = msg.value.sub(amountETH);
        // Send back excess eth
        if (excessETH > 0) {
            msg.sender.transfer(excessETH);
        }

        // Transfer sdvd from sender to this contract
        IERC20(sdvd).safeTransferFrom(msg.sender, address(this), amountToken);

        // Approve uniswap router to spend SDVD
        IERC20(sdvd).approve(address(uniswapRouter), amountToken);
        // Add liquidity
        (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountToken, 0, 0, address(this), block.timestamp.add(30 minutes));

        // Approve self
        IERC20(stakedToken).approve(address(this), liquidity);
        // Stake LP token for sender
        _stake(address(this), msg.sender, liquidity);
    }

    /// @notice Claim reward and re-stake conveniently.
    function claimRewardAndStake() external nonReentrant farmOpen {
        require(isLGEActive == false, 'LGE still active');

        // Claim SDVD reward to this address
        (uint256 totalNetReward,,) = _claimReward(msg.sender, address(this));

        // Split total reward to be swapped
        uint256 swapAmountSDVD = totalNetReward.div(2);

        // Swap path
        address[] memory path = new address[](2);
        path[0] = address(sdvd);
        path[1] = weth;

        // Approve uniswap router to spend sdvd
        IERC20(sdvd).approve(address(uniswapRouter), swapAmountSDVD);
        // Swap SDVD to ETH
        // Param: uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(swapAmountSDVD, 0, path, address(this), block.timestamp.add(30 minutes));
        // Get received ETH amount from swap
        uint256 amountETHReceived = amounts[1];

        // Get pair address and balance
        uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);
        uint256 pairETHBalance = IERC20(weth).balanceOf(stakedToken);

        // Get available SDVD
        uint256 amountSDVD = totalNetReward.sub(swapAmountSDVD);
        // Calculate how much ETH needed to provide liquidity
        uint256 amountETH = amountSDVD.mul(pairETHBalance).div(pairSDVDBalance);

        // If required ETH amount to add liquidity is bigger than what we have
        // Then we need to reduce SDVD amount
        if (amountETH > amountETHReceived) {
            // Set ETH amount
            amountETH = amountETHReceived;
            // Get amount SDVD needed to add liquidity
            uint256 amountSDVDRequired = amountETH.mul(pairSDVDBalance).div(pairETHBalance);
            // Send dust
            if (amountSDVD > amountSDVDRequired) {
                IERC20(sdvd).safeTransfer(msg.sender, amountSDVD.sub(amountSDVDRequired));
            }
            // Set SDVD amount
            amountSDVD = amountSDVDRequired;
        }
        // Else if we have too much ETH
        else if (amountETHReceived > amountETH) {
            // Send excess
            msg.sender.transfer(amountETHReceived.sub(amountETH));
        }

        // Approve uniswap router to spend SDVD
        IERC20(sdvd).approve(address(uniswapRouter), amountSDVD);
        // Add liquidity
        (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountSDVD, 0, 0, address(this), block.timestamp.add(30 minutes));

        // Approve self
        IERC20(stakedToken).approve(address(this), liquidity);
        // Stake LP token for sender
        _stake(address(this), msg.sender, liquidity);

        emit ClaimedAndStaked(msg.sender, liquidity);
    }

    /* ========== Internal ========== */

    /// @notice Stake ETH
    /// @param value Value in ETH
    function _stakeETH(uint256 value) internal {
        // If in LGE
        if (isLGEActive) {
            // SDVD-ETH pair address
            uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);

            if (pairSDVDBalance == 0) {
                require(msg.value <= LGE_INITIAL_DEPOSIT_CAP, 'Initial deposit cap reached');
            }

            uint256 pairETHBalance = IERC20(weth).balanceOf(stakedToken);
            uint256 amountETH = msg.value;

            // If SDVD balance = 0 then set initial price
            uint256 amountSDVD = pairSDVDBalance == 0 ? amountETH.mul(LGE_INITIAL_PRICE_MULTIPLIER) : amountETH.mul(pairSDVDBalance).div(pairETHBalance);

            uint256 excessETH = 0;
            // If amount token to be minted pass the hard cap
            if (pairSDVDBalance.add(amountSDVD) > LGE_HARD_CAP) {
                // Get excess token
                uint256 excessToken = pairSDVDBalance.add(amountSDVD).sub(LGE_HARD_CAP);
                // Reduce it
                amountSDVD = amountSDVD.sub(excessToken);
                // Get excess ether
                excessETH = excessToken.mul(pairETHBalance).div(pairSDVDBalance);
                // Reduce amount ETH to be put on uniswap liquidity
                amountETH = amountETH.sub(excessETH);
            }

            // Mint LGE SDVD
            ISDvd(sdvd).mint(address(this), amountSDVD);

            // Add liquidity in uniswap and send the LP token to this contract
            IERC20(sdvd).approve(address(uniswapRouter), amountSDVD);
            (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountSDVD, 0, 0, address(this), block.timestamp.add(30 minutes));

            // Recheck the SDVD in pair address
            pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);
            // Set LGE active state
            isLGEActive = pairSDVDBalance < LGE_HARD_CAP;

            // Approve self
            IERC20(stakedToken).approve(address(this), liquidity);
            // Stake LP token for sender
            _stake(address(this), msg.sender, liquidity);

            // If there is excess ETH
            if (excessETH > 0) {
                _stakeETH(excessETH);
            }
        } else {
            // Split ETH sent
            uint256 amountETH = value.div(2);

            // Swap path
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = address(sdvd);

            // Swap ETH to SDVD using uniswap
            // Param: uint amountOutMin, address[] calldata path, address to, uint deadline
            uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value : amountETH}(
                0,
                path,
                address(this),
                block.timestamp.add(30 minutes)
            );
            // Get SDVD amount
            uint256 amountSDVDReceived = amounts[1];

            // Get pair address balance
            uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);
            uint256 pairETHBalance = IERC20(weth).balanceOf(stakedToken);

            // Get available ETH
            amountETH = value.sub(amountETH);
            // Calculate amount of SDVD needed to add liquidity
            uint256 amountSDVD = amountETH.mul(pairSDVDBalance).div(pairETHBalance);

            // If required SDVD amount to add liquidity is bigger than what we have
            // Then we need to reduce ETH amount
            if (amountSDVD > amountSDVDReceived) {
                // Set SDVD amount
                amountSDVD = amountSDVDReceived;
                // Get amount ETH needed to add liquidity
                uint256 amountETHRequired = amountSDVD.mul(pairETHBalance).div(pairSDVDBalance);
                // Send dust back to sender
                if (amountETH > amountETHRequired) {
                    msg.sender.transfer(amountETH.sub(amountETHRequired));
                }
                // Set ETH amount
                amountETH = amountETHRequired;
            }
            // Else if we have too much SDVD
            else if (amountSDVDReceived > amountSDVD) {
                // Send dust
                IERC20(sdvd).transfer(msg.sender, amountSDVDReceived.sub(amountSDVD));
            }

            // Approve uniswap router to spend SDVD
            IERC20(sdvd).approve(address(uniswapRouter), amountSDVD);
            // Add liquidity
            (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountSDVD, 0, 0, address(this), block.timestamp.add(30 minutes));
            // Sync total token supply
            ISDvd(sdvd).syncPairTokenTotalSupply();

            // Approve self
            IERC20(stakedToken).approve(address(this), liquidity);
            // Stake LP token for sender
            _stake(address(this), msg.sender, liquidity);
        }

        emit StakedETH(msg.sender, msg.value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Mock is IERC20 {

    function mint(address account, uint256 amount) external;

    function mockMint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function mockBurn(address account, uint256 amount) external;

}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./interfaces/IPool.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract PoolTreasury is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev SDVD ETH pool address
    address public sdvdEthPool;

    /// @dev DVD pool address
    address public dvdPool;

    /// @dev SDVD contract address
    address public sdvd;

    /// @dev Distribute reward every 1 day to pool
    uint256 public releaseThreshold = 1 days;

    /// @dev Last release timestamp
    uint256 public releaseTime;

    /// @notice Swap reward distribution numerator when this time reached
    uint256 public numeratorSwapTime;

    /// @notice How long we should wait before swap numerator
    uint256 public NUMERATOR_SWAP_WAIT = 4383 days;  // 12 normal years + 3 leap days;

    constructor(address _sdvd) public {
        sdvd = _sdvd;
        releaseTime = block.timestamp;
        numeratorSwapTime = block.timestamp.add(NUMERATOR_SWAP_WAIT);
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately
    function init(address _sdvdEthPool, address _dvdPool) external onlyOwner {
        sdvdEthPool = _sdvdEthPool;
        dvdPool = _dvdPool;

        // Renounce ownership after init
        renounceOwnership();
    }

    /* ========== Mutative ========== */

    /// @notice Release pool treasury to pool and give rewards for farmers.
    function release() external {
        _release();
    }

    /* ========== Internal ========== */

    /// @notice Release pool treasury to pool
    function _release() internal {
        if (releaseTime.add(releaseThreshold) <= block.timestamp) {
            // Update release time
            releaseTime = block.timestamp;
            // Check balance
            uint256 balance = IERC20(sdvd).balanceOf(address(this));

            // If there is balance
            if (balance > 0) {
                // Get numerator
                uint256 numerator = block.timestamp <= numeratorSwapTime ? 4 : 6;

                // Distribute reward to pools
                uint dvdPoolReward = balance.div(10).mul(numerator);
                IERC20(sdvd).transfer(dvdPool, dvdPoolReward);
                IPool(dvdPool).distributeBonusRewards(dvdPoolReward);

                uint256 sdvdEthPoolReward = balance.sub(dvdPoolReward);
                IERC20(sdvd).transfer(sdvdEthPool, sdvdEthPoolReward);
                IPool(sdvdEthPool).distributeBonusRewards(sdvdEthPoolReward);
            }
        }
    }

}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IDvd.sol";
import "./interfaces/IPool.sol";
import "./Pool.sol";

contract DvdPool is Pool {

    event StakedETH(address indexed account, uint256 amount);
    event WithdrawnETH(address indexed account, uint256 amount);
    event ClaimedAndStaked(address indexed account, uint256 amount);

    /// @dev mUSD instance
    address public musd;

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev Uniswap factory
    IUniswapV2Factory uniswapFactory;

    /// @dev WETH address
    address weth;

    /// @dev SDVD ETH pool address
    address public sdvdEthPool;

    constructor(address _poolTreasury, address _musd, address _uniswapRouter, address _sdvdEthPool, uint256 _farmOpenTime) public Pool(_poolTreasury, _farmOpenTime) {
        rewardAllocation = 360000 * 1e18;
        musd = _musd;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        weth = uniswapRouter.WETH();
        sdvdEthPool = _sdvdEthPool;
    }

    /// @dev Added to receive ETH when swapping on Uniswap
    receive() external payable {
    }

    /// @notice Stake token using ETH conveniently.
    function stakeETH() external payable nonReentrant {
        // Buy DVD using ETH
        (uint256 dvdAmount,,,) = ILordOfCoin(controller).buyFromETH{value : msg.value}();

        // Approve self
        IERC20(stakedToken).approve(address(this), dvdAmount);
        // Stake user DVD
        _stake(address(this), msg.sender, dvdAmount);

        emit StakedETH(msg.sender, msg.value);
    }

    /// @notice Withdraw token to ETH conveniently.
    /// @param amount Number of staked DVD token.
    /// @dev Need to approve DVD token first.
    function withdrawETH(uint256 amount) external nonReentrant farmOpen {
        // Call withdraw to this address
        _withdraw(msg.sender, address(this), amount);
        // Approve LoC to spend DVD
        IERC20(stakedToken).approve(controller, amount);
        // Sell received DVD to ETH
        (uint256 receivedETH,,,,) = ILordOfCoin(controller).sellToETH(amount);
        // Send received ETH to sender
        msg.sender.transfer(receivedETH);

        emit WithdrawnETH(msg.sender, receivedETH);
    }

    /// @notice Claim reward and re-stake conveniently.
    function claimRewardAndStake() external nonReentrant farmOpen {
        // Claim SDVD reward to this address
        (uint256 totalNetReward,,) = _claimReward(msg.sender, address(this));

        // Split total reward to be swapped
        uint256 swapAmountSDVD = totalNetReward.div(2);

        // Swap path
        address[] memory path = new address[](2);
        path[0] = address(sdvd);
        path[1] = weth;

        // Approve uniswap router to spend sdvd
        IERC20(sdvd).approve(address(uniswapRouter), swapAmountSDVD);
        // Swap SDVD to ETH
        // Param: uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(swapAmountSDVD, 0, path, address(this), block.timestamp.add(30 minutes));
        // Get received ETH amount from swap
        uint256 amountETHReceived = amounts[1];

        // Get pair address and balance
        address pairAddress = uniswapFactory.getPair(address(sdvd), weth);
        uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(pairAddress);
        uint256 pairETHBalance = IERC20(weth).balanceOf(pairAddress);

        // Get available SDVD
        uint256 amountSDVD = totalNetReward.sub(swapAmountSDVD);
        // Calculate how much ETH needed to provide liquidity
        uint256 amountETH = amountSDVD.mul(pairETHBalance).div(pairSDVDBalance);

        // If required ETH amount to add liquidity is bigger than what we have
        // Then we need to reduce SDVD amount
        if (amountETH > amountETHReceived) {
            // Set ETH amount
            amountETH = amountETHReceived;
            // Get amount SDVD needed to add liquidity
            uint256 amountSDVDRequired = amountETH.mul(pairSDVDBalance).div(pairETHBalance);
            // Send dust
            if (amountSDVD > amountSDVDRequired) {
                IERC20(sdvd).safeTransfer(msg.sender, amountSDVD.sub(amountSDVDRequired));
            }
            // Set SDVD amount
            amountSDVD = amountSDVDRequired;
        }
        // Else if we have too much ETH
        else if (amountETHReceived > amountETH) {
            // Send dust
            msg.sender.transfer(amountETHReceived.sub(amountETH));
        }

        // Approve uniswap router to spend SDVD
        IERC20(sdvd).approve(address(uniswapRouter), amountSDVD);
        // Add liquidity
        (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountSDVD, 0, 0, address(this), block.timestamp.add(30 minutes));

        // Approve SDVD ETH pool to spend LP token
        IERC20(pairAddress).approve(sdvdEthPool, liquidity);
        // Stake LP token for sender
        IPool(sdvdEthPool).stakeTo(msg.sender, liquidity);

        emit ClaimedAndStaked(msg.sender, liquidity);
    }

    /* ========== Internal ========== */

    /// @notice Override stake function to check shareholder points
    /// @param amount Number of DVD token to be staked.
    function _stake(address sender, address recipient, uint256 amount) internal virtual override {
        require(IDvd(stakedToken).shareholderPointOf(sender) >= amount, 'Insufficient shareholder points');
        super._stake(sender, recipient, amount);
    }

}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './DvdShareholderPoint.sol';

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract Dvd is ERC20, DvdShareholderPoint, Ownable {

    /// @notice Minter for DVD token. This value will be Lord of Coin address.
    address public minter;
    /// @notice Controller. This value will be Lord of Coin address.
    address public controller;
    /// @dev DVD pool address.
    address public dvdPool;

    constructor() public ERC20('Dvd.finance', 'DVD') {
    }

    /* ========== Modifiers ========== */

    modifier onlyMinter {
        require(msg.sender == minter, 'Minter only');
        _;
    }

    modifier onlyController {
        require(msg.sender == controller, 'Controller only');
        _;
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately
    function init(address _controller, address _dvdPool) external onlyOwner {
        controller = _controller;
        minter = _controller;
        dvdPool = _dvdPool;

        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Minter Only ========== */

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    /* ========== Controller Only ========== */

    /// @notice Increase shareholder point.
    /// @dev Can only be called by the LoC contract.
    /// @param account Account address
    /// @param amount The amount to increase.
    function increaseShareholderPoint(address account, uint256 amount) external onlyController {
        _increaseShareholderPoint(account, amount);
    }

    /// @notice Decrease shareholder point.
    /// @dev Can only be called by the LoC contract.
    /// @param account Account address
    /// @param amount The amount to decrease.
    function decreaseShareholderPoint(address account, uint256 amount) external onlyController {
        _decreaseShareholderPoint(account, amount);
    }

    /* ========== Internal ========== */

    /// @notice ERC20 Before token transfer hook
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // If transfer between two accounts
        if (from != address(0) && to != address(0)) {
            // Remove shareholder point from account
            _decreaseShareholderPoint(from, Math.min(amount, shareholderPointOf(from)));
        }
        // If transfer is from DVD pool (This occurs when user withdraw their stake, or using convenient stake ETH)
        // Give back their shareholder point.
        if (from == dvdPool) {
            _increaseShareholderPoint(to, amount);
        }
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract DvdShareholderPoint {

    using SafeMath for uint256;

    event ShareholderPointIncreased(address indexed account, uint256 amount, uint256 totalShareholderPoint);
    event ShareholderPointDecreased(address indexed account, uint256 amount, uint256 totalShareholderPoint);

    /// @dev Our shareholder point tracker
    /// Shareholder point will determine how much token one account can use to farm SDVD
    /// This point can only be increased/decreased by LoC buy/sell function to prevent people trading DVD on exchange and don't pay their taxes
    mapping(address => uint256) private _shareholderPoints;
    uint256 private _totalShareholderPoint;

    /// @notice Get shareholder point of an account
    /// @param account address.
    function shareholderPointOf(address account) public view returns (uint256) {
        return _shareholderPoints[account];
    }

    /// @notice Get total shareholder points
    function totalShareholderPoint() public view returns (uint256) {
        return _totalShareholderPoint;
    }

    /// @notice Increase shareholder point
    /// @param amount The amount to increase.
    function _increaseShareholderPoint(address account, uint256 amount) internal {
        // If account is burn address then skip
        if (account != address(0)) {
            _totalShareholderPoint = _totalShareholderPoint.add(amount);
            _shareholderPoints[account] = _shareholderPoints[account].add(amount);

            emit ShareholderPointIncreased(account, amount, _shareholderPoints[account]);
        }
    }

    /// @notice Decrease shareholder point.
    /// @param amount The amount to decrease.
    function _decreaseShareholderPoint(address account, uint256 amount) internal {
        // If account is burn address then skip
        if (account != address(0)) {
            _totalShareholderPoint = _totalShareholderPoint.sub(amount);
            _shareholderPoints[account] = _shareholderPoints[account] > amount ? _shareholderPoints[account].sub(amount) : 0;

            emit ShareholderPointDecreased(account, amount, _shareholderPoints[account]);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16 <0.7.0;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

/**
 * @title   StableMath
 * @author  Stability Labs Pty. Ltd.
 * @notice  A library providing safe mathematical operations to multiply and
 *          divide with standardised precision.
 * @dev     Derives from OpenZeppelin's SafeMath lib and uses generic system
 *          wide variables for managing precision.
 */
library StableMath {
    using SafeMath for uint256;

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Token Ratios are used when converting between units of bAsset, mAsset and MTA
     * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
     * @dev bAsset ratio unit for use in exact calculations,
     * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
     */
    uint256 private constant RATIO_SCALE = 1e8;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Provides an interface to the ratio unit
     * @return Ratio scale unit (1e8 or 1 * 10**8)
     */
    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x.mul(FULL_SCALE);
    }

    /***************************************
                PRECISE ARITHMETIC
      ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x.mul(y);
        // return 9e38 / 1e18 = 9e18
        return z.div(scale);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x.mul(y);
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil.div(FULL_SCALE);
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x.mul(FULL_SCALE);
        // e.g. 8e36 / 10e18 = 8e17
        return z.div(y);
    }

    /***************************************
                    RATIO FUNCS
      ****************************************/

    /**
     * @dev Multiplies and truncates a token ratio, essentially flooring the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand operand to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the two inputs and then dividing by the ratio scale
     */
    function mulRatioTruncate(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    /**
     * @dev Multiplies and truncates a token ratio, rounding up the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand input to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              ratio scale, rounded up to the closest base unit.
     */
    function mulRatioTruncateCeil(uint256 x, uint256 ratio) internal pure returns (uint256) {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x.mul(ratio);
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled.add(RATIO_SCALE.sub(1));
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil.div(RATIO_SCALE);
    }

    /**
     * @dev Precisely divides two ratioed units, by first scaling the left hand operand
     *      i.e. How much bAsset is this mAsset worth?
     * @param x     Left hand operand in division
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divRatioPrecisely(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        // e.g. 1e14 * 1e8 = 1e22
        uint256 y = x.mul(RATIO_SCALE);
        // return 1e22 / 1e12 = 1e10
        return y.div(ratio);
    }

    /***************************************
                      HELPERS
      ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
}

