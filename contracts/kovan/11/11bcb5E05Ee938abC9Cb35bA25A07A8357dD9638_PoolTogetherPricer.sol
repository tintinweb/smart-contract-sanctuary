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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IsaLPPricer {
    /**
     * @notice It returns the exchange rate of the single asset liquidity provider token.
     * @param saLPToken address of the single asset liquidity provider token.
     * @return Exchange rate for 1 saLP token in the underlying asset.
     */
    function getRateFor(address saLPToken) external view returns (uint256);

    /**
     * @notice It calculates the value of the protocol token amount into the underlying asset.
     * @param saLPToken address of the single asset liquidity provider token
     * @param amount Amount of the token to convert into the underlying asset.
     * @return Value of the saLP token in the underlying asset.
     */
    function getValueOf(address saLPToken, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @notice It calculates the balance of the underlying asset for {account}.
     * @param saLPToken Address of the single asset liquidity provider token.
     * @param account Address of the account to get the balance of.
     * @return Balance of the underlying asset.
     */
    function getBalanceOfUnderlying(address saLPToken, address account)
        external
        returns (uint256);

    /**
     * @notice Gets the underlying asset address for the {saLPToken}.
     * @param saLPToken address of the single asset liquidity provider token.
     * @return Address of the underlying asset.
     */
    function getUnderlying(address saLPToken) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import { IsaLPPricer } from "../IsaLPPricer.sol";
import {
    PrizePoolInterface
} from "../../shared/interfaces/pooltogether/PrizePoolInterface.sol";
import {
    IControlledToken
} from "../../shared/interfaces/pooltogether/IControlledToken.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PoolTogetherPricer is IsaLPPricer {
    // TODO: not currently being used
    /**
     * @notice It returns the exchange rate of the aToken to the underlying asset.
     * @dev The exchange ratio for Aave tokens is always 1:1, however the token balance is compounded silently
     *  using an index at the time of their last deposit. See {AavePricer.getBalanceOfUnderlying}
     * @param saLPToken address of the single asset liquidity provider token.
     * @return Exchange rate for 1 saLP token in the underlying asset.
     */
    function getRateFor(address saLPToken)
        public
        view
        override
        returns (uint256)
    {
        return 0;
    }

    // TODO: not currently being used
    /**
     * @notice It calculates the value of the protocol token amount into the underlying asset.
     * @dev The value of an Aave token is always the same as the underlying asset amount. See {AavePricer.getRateFor}
     * @param saLPToken address of the single asset liquidity provider token
     * @param amount Amount of the token to convert into the underlying asset.
     * @return Value of the saLP token in the underlying asset.
     */
    function getValueOf(address saLPToken, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        return 0;
    }

    /**
     * @notice It calculates the balance of the underlying asset for {account}.
     * @param saLPToken Address of the single asset liquidity provider token.
     * @param account Address of the account to get the balance of.
     * @return Balance of the underlying asset.
     */
    function getBalanceOfUnderlying(address saLPToken, address account)
        external
        override
        returns (uint256)
    {
        return _getPrizePool(saLPToken).balanceOfCredit(account, saLPToken);
    }

    /**
     * @notice Gets the underlying asset address for the Compound token.
     * @dev cETH is the only Compound token that does not support the {underlying} function.
     * @param saLPToken address of the Compound token.
     * @return address of the underlying saLPToken asset.
     */
    function getUnderlying(address saLPToken)
        public
        view
        override
        returns (address)
    {
        return _getPrizePool(saLPToken).token();
    }

    function _getPrizePool(address saLPToken)
        private
        view
        returns (PrizePoolInterface)
    {
        return IControlledToken(saLPToken).controller();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import { PrizePoolInterface } from "./PrizePoolInterface.sol";

interface IControlledToken {
    function controller() external view returns (PrizePoolInterface);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Escrows assets and deposits them into a yield source.  Exposes interest to Prize Strategy.  Users deposit and withdraw from this contract to participate in Prize Pool.
/// @notice Accounting is managed using Controlled Tokens, whose mint and burn functions can only be called by this contract.
/// @dev Must be inherited to provide specific yield-bearing asset control, such as Compound cTokens
interface PrizePoolInterface {
    /// @notice Deposit assets into the Prize Pool in exchange for tokens
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    /// @param controlledToken The address of the type of token the user is minting
    /// @param referrer The referrer of the deposit
    function depositTo(
        address to,
        uint256 amount,
        address controlledToken,
        address referrer
    ) external;

    /// @notice Withdraw assets from the Prize Pool instantly.  A fairness fee may be charged for an early exit.
    /// @param from The address to redeem tokens from.
    /// @param amount The amount of tokens to redeem for assets.
    /// @param controlledToken The address of the token to redeem (i.e. ticket or sponsorship)
    /// @param maximumExitFee The maximum exit fee the caller is willing to pay.  This should be pre-calculated by the calculateExitFee() fxn.
    /// @return The actual exit fee paid
    function withdrawInstantlyFrom(
        address from,
        uint256 amount,
        address controlledToken,
        uint256 maximumExitFee
    ) external returns (uint256);

    /// @notice Returns the balance that is available to award.
    /// @dev captureAwardBalance() should be called first
    /// @return The total amount of assets to be awarded for the current prize
    function awardBalance() external view returns (uint256);

    /// @notice Calculates the early exit fee for the given amount
    /// @param from The user who is withdrawing
    /// @param controlledToken The type of collateral being withdrawn
    /// @param amount The amount of collateral to be withdrawn
    /// @return exitFee The exit fee
    /// @return burnedCredit The user's credit that was burned
    function calculateEarlyExitFee(
        address from,
        address controlledToken,
        uint256 amount
    ) external returns (uint256 exitFee, uint256 burnedCredit);

    /// @notice Estimates the amount of time it will take for a given amount of funds to accrue the given amount of credit.
    /// @param _principal The principal amount on which interest is accruing
    /// @param _interest The amount of interest that must accrue
    /// @return durationSeconds The duration of time it will take to accrue the given amount of interest, in seconds.
    function estimateCreditAccrualTime(
        address _controlledToken,
        uint256 _principal,
        uint256 _interest
    ) external view returns (uint256 durationSeconds);

    /// @notice Returns the credit balance for a given user.  Not that this includes both minted credit and pending credit.
    /// @param user The user whose credit balance should be returned
    /// @return The balance of the users credit
    function balanceOfCredit(address user, address controlledToken)
        external
        returns (uint256);

    /// @notice Returns the credit rate of a controlled token
    /// @param controlledToken The controlled token to retrieve the credit rates for
    /// @return creditLimitMantissa The credit limit fraction.  This number is used to calculate both the credit limit and early exit fee.
    /// @return creditRateMantissa The credit rate. This is the amount of tokens that accrue per second.
    function creditPlanOf(address controlledToken)
        external
        view
        returns (uint128 creditLimitMantissa, uint128 creditRateMantissa);

    /// @dev Returns the address of the underlying ERC20 asset
    /// @return The address of the asset
    function token() external view returns (address);

    /// @notice An array of the Tokens controlled by the Prize Pool (ie. Tickets, Sponsorship)
    /// @return An array of controlled token addresses
    function tokens() external view returns (address[] memory);

    /// @notice The total of all controlled tokens and timelock.
    /// @return The current total of all tokens and timelock.
    function accountedBalance() external view returns (uint256);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}