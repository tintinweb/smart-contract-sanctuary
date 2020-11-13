/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./CarefulMath.sol";
import "./Erc20Interface.sol";

/**
 * @title Erc20
 * @author Paul Razvan Berg
 * @notice Implementation of the {Erc20Interface} interface.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of Erc20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the Erc may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {Erc20Interface-approve}.
 *
 * @dev Forked from OpenZeppelin
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/Erc20/Erc20.sol
 */
contract Erc20 is
    CarefulMath, /* no dependency */
    Erc20Interface /* one dependency */
{
    /**
     * @notice All three of these values are immutable: they can only be set once during construction.
     * @param name_ Erc20 name of this token.
     * @param symbol_ Erc20 symbol of this token.
     * @param decimals_ Erc20 decimal precision of this token.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * CONSTANT FUNCTIONS
     */

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    /**
     * @notice Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    /**
     * NON-CONSTANT FUNCTIONS
     */

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * @dev IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     *
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        approveInternal(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {Erc20Interface-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        MathError mathErr;
        uint256 newAllowance;
        (mathErr, newAllowance) = subUInt(allowances[msg.sender][spender], subtractedValue);
        require(mathErr == MathError.NO_ERROR, "ERR_ERC20_DECREASE_ALLOWANCE_UNDERFLOW");
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described above.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        MathError mathErr;
        uint256 newAllowance;
        (mathErr, newAllowance) = addUInt(allowances[msg.sender][spender], addedValue);
        require(mathErr == MathError.NO_ERROR, "ERR_ERC20_INCREASE_ALLOWANCE_OVERFLOW");
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @dev Emits a {Transfer} event.
     *
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - The caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        transferInternal(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice See Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * @dev Emits a {Transfer} event. Emits an {Approval} event indicating the
     * updated allowance. This is not required by the Erc. See the note at the
     * beginning of {Erc20};
     *
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - The caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        transferInternal(sender, recipient, amount);
        MathError mathErr;
        uint256 newAllowance;
        (mathErr, newAllowance) = subUInt(allowances[sender][msg.sender], amount);
        require(mathErr == MathError.NO_ERROR, "ERR_ERC20_TRANSFER_FROM_INSUFFICIENT_ALLOWANCE");
        approveInternal(sender, msg.sender, newAllowance);
        return true;
    }

    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * @dev This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function approveInternal(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0x00), "ERR_ERC20_APPROVE_FROM_ZERO_ADDRESS");
        require(spender != address(0x00), "ERR_ERC20_APPROVE_TO_ZERO_ADDRESS");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Destroys `burnAmount` tokens from `holder`, recuding the token supply.
     *
     * @dev Emits a {Burn} event.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `holder` must have at least `amount` tokens.
     */
    function burnInternal(address holder, uint256 burnAmount) internal {
        MathError mathErr;
        uint256 newHolderBalance;
        uint256 newTotalSupply;

        /* Burn the yTokens. */
        (mathErr, newHolderBalance) = subUInt(balances[holder], burnAmount);
        require(mathErr == MathError.NO_ERROR, "ERR_ERC20_BURN_BALANCE_UNDERFLOW");
        balances[holder] = newHolderBalance;

        /* Reduce the total supply. */
        (mathErr, newTotalSupply) = subUInt(totalSupply, burnAmount);
        require(mathErr == MathError.NO_ERROR, "ERR_ERC20_BURN_TOTAL_SUPPLY_UNDERFLOW");
        totalSupply = newTotalSupply;

        emit Burn(holder, burnAmount);
    }

    /** @notice Prints new tokens into existence and assigns them to `beneficiary`,
     * increasing the total supply.
     *
     * @dev Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - The beneficiary's balance and the total supply cannot overflow.
     */
    function mintInternal(address beneficiary, uint256 mintAmount) internal {
        MathError mathErr;
        uint256 newBeneficiaryBalance;
        uint256 newTotalSupply;

        /* Mint the yTokens. */
        (mathErr, newBeneficiaryBalance) = addUInt(balances[beneficiary], mintAmount);
        require(mathErr == MathError.NO_ERROR, "ERR_ERC20_MINT_BALANCE_OVERFLOW");
        balances[beneficiary] = newBeneficiaryBalance;

        /* Increase the total supply. */
        (mathErr, newTotalSupply) = addUInt(totalSupply, mintAmount);
        require(mathErr == MathError.NO_ERROR, "ERR_ERC20_MINT_TOTAL_SUPPLY_OVERFLOW");
        totalSupply = newTotalSupply;

        emit Mint(beneficiary, mintAmount);
    }

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient`.
     *
     * @dev This is internal function is equivalent to {transfer}, and can be used to
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
    function transferInternal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0x00), "ERR_ERC20_TRANSFER_FROM_ZERO_ADDRESS");
        require(recipient != address(0x00), "ERR_ERC20_TRANSFER_TO_ZERO_ADDRESS");

        MathError mathErr;
        uint256 newSenderBalance;
        uint256 newRecipientBalance;

        (mathErr, newSenderBalance) = subUInt(balances[sender], amount);
        require(mathErr == MathError.NO_ERROR, "ERR_ERC20_TRANSFER_SENDER_BALANCE_UNDERFLOW");
        balances[sender] = newSenderBalance;

        (mathErr, newRecipientBalance) = addUInt(balances[recipient], amount);
        assert(mathErr == MathError.NO_ERROR);
        balances[recipient] = newRecipientBalance;

        emit Transfer(sender, recipient, amount);
    }
}
