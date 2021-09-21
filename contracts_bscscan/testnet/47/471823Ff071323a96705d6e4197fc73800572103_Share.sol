// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

import "./IERC20.sol";

import "./IFund.sol";

contract Share is IERC20 {
    uint8 public constant decimals = 18;

    string public name;
    string public symbol;
    uint256 private immutable _tranche;

    IFund public fund;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * _tranche is immutable: it can only be set once during construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address fund_,
        uint256 tranche_
    ) public {
        name = name_;
        symbol = symbol_;
        fund = IFund(fund_);
        _tranche = tranche_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return fund.shareTotalSupply(_tranche);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return fund.shareBalanceOf(_tranche, account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        fund.transfer(_tranche, msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return fund.shareAllowance(_tranche, owner, spender);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        fund.approve(_tranche, msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
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
    ) external override returns (bool) {
        uint256 newAllowance = fund.transferFrom(_tranche, msg.sender, sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        emit Approval(sender, msg.sender, newAllowance);
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        uint256 newAllowance = fund.increaseAllowance(_tranche, msg.sender, spender, addedValue);
        emit Approval(msg.sender, spender, newAllowance);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 newAllowance =
            fund.decreaseAllowance(_tranche, msg.sender, spender, subtractedValue);
        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }
}