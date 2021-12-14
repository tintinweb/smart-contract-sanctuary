/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: IERC20

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Part: ERC20

contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public override totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    /**
     * @dev Sets the values for name, symbol and decimals.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
     * @param account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    /**
     * @notice Moves 'amount' tokens from the caller's account to 'recipient'.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        address sender = msg.sender;
        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @return The remaining number of tokens that 'spender' will be
     * allowed to spend on behalf of 'owner' through "transferFrom".
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        allowances[owner][spender];
    }

    /**
     * @notice Sets 'amount' as the allowance of 'spender' over the caller's tokens.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        address owner = msg.sender;
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        allowances[owner][spender] += amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    /**
     * @notice Moves 'amount' tokens from 'sender' to 'recipient' using the allowance mechanism.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        address spender = msg.sender;
        uint256 currentAllowance = allowances[sender][spender];
        require(
            currentAllowance >= amount,
            "Transfer amount exceeds allowance"
        );
        // decrease allowance
        allowances[sender][spender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @notice Creates 'amount' tokens and assigns them to 'account', increasing the total supply.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to the zero address");
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Destroys 'amount' tokens from 'account', reducing the total supply.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from the zero address");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice Moves 'amount' of tokens from 'sender' to 'recipient'.
     *
     * This internal function is equivalent to "transfer", and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}

// File: Token.sol

contract Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 decimals,
        address owner,
        uint256 amount // set as totalSupply
    ) ERC20(name, symbol, decimals) {
        _mint(owner, amount);
    }
}