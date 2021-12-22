/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 *
 * source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
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

/**
 * @title Implementation of the IERC20 interface.
 */
contract ERC20 is IERC20 {
    string public NAME;
    string public SYMBOL;
    uint8 public DECIMALS;
    uint256 private TOTAL_SUPPLY;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev Sets the values for NAME, SYMBOL and DECIMALS.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        NAME = _name;
        SYMBOL = _symbol;
        DECIMALS = _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return TOTAL_SUPPLY;
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
        return _balances[account];
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
        _transfer(msg.sender, recipient, amount);
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
        return _allowances[owner][spender];
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
        _approve(msg.sender, spender, amount);
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
        uint256 currentAllowance = _allowances[sender][spender];
        require(
            currentAllowance >= amount,
            "Transfer amount exceeds allowance"
        );
        // decrease allowance
        _allowances[sender][spender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @notice Increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        _approve(owner, spender, currentAllowance + addedValue);
        return true;
    }

    /**
     * @notice Decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "Decreased allowance below zero"
        );
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    /**
     * @dev Moves 'amount' of tokens from 'sender' to 'recipient'.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Creates 'amount' tokens and assigns them to 'account'
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to the zero address");
        TOTAL_SUPPLY += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys 'amount' tokens from 'account', reducing the total supply.
     */
    function _burn(address account, uint256 amount) internal virtual {
        uint256 accountBalance = _balances[account];
        require(account != address(0), "Burn from the zero address");
        require(accountBalance >= amount, "Burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        TOTAL_SUPPLY -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets 'amount' as the allowance of 'spender' over the 'owner' s tokens.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// File: Token.sol

/**
 * @title Sample token implementation using ERC20.sol
 */
contract Token is ERC20 {
    // /**
    //  * @param name name of the token
    //  * @param symbol symbol of the token
    //  * @param decimals number of decimal places of one token unit, 18 is widely used
    //  * @param totalSupply total supply of tokens in lowest units (depending on decimals)
    //  * @param owner address that gets 100% of token supply
    //  */
    //  string memory name,
    //     string memory symbol,
    //     uint8 decimals,
    //     uint256 totalSupply,
    //     address owner // token owner address

    constructor() ERC20("bitbod", "bb", 18) {
        _mint(msg.sender, 10**21);
    }

    // /**
    //  * @notice Burns 'value' tokens from the caller's account.
    //  * @param value The amount of lowest token units to be burned.
    //  */
    // function burn(uint256 value) public {
    //     _burn(msg.sender, value);
    // }
}