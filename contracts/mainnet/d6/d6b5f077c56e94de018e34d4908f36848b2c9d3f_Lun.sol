/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT

// The following code is based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.1/contracts/token/ERC20
// With custom modifications
pragma solidity ^0.8.0;

contract Lun {
    /// @notice EIP-20 token symbol
    string private _symbol = "LUN";
    /// @notice EIP-20 token name
    string private _name = "LunDAO";
    /// @notice Total number of tokens
    uint256 private _totalSupply;

    /// @notice Token balances for each account
    mapping(address => uint256) private _balances;
    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Construct a new Lun token
    constructor() {
        _mint(msg.sender, 1_000_000e18);
    }

    /// @notice Returns the name of EIP-20 token
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of EIP-20 token
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the decimals of EIP-20 token
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @notice Returns the totalsupply of EIP-20 token
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Get the number of tokens owned by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens owned
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param recipient The address of the receiver account, cannot be the address(0).
     * @param amount The number of tokens to transfer, the caller must have a balance of at least `amount`.
     * @return Whether or not the transfer succeeded
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param owner The address of the account holding the tokens
     * @param spender The address of the account spending the tokens
     * @return The number of tokens approved
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `msg.sender`
     * @param spender The address of the account which may transfer tokens, cannot be the address(0).
     * @param amount The number of tokens that are approved
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `sender` to `recipient`
     * @param sender The address of the sender account, cannot be the address(0), must have a balance of at least `amount`.
     * @param recipient The address of the receiver account, cannot be the address(0)
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     * Requirements:
     * - msg.sender must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param sender The address of sender account, cannot be the address(0).
     * @param recipient The address of the receiver account, cannot be the address(0).
     * @param amount The number of tokens to transfer, the `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice Create `amount` tokens and transfer them to `account`, and increasing the total supply.
     * @param account The address of the receiver account, cannot be the address(0).
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Destroy `amount` tokens from `account`, and decreasing the total supply.
     * @param account The address of the tokens to burn. 
     * @param amount The number of tokens to burn.
     * 
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `owner`
     * @param owner The address of the account who own the tokens, cannot be the address(0).
     * @param spender The address of the account which may transfer tokens, cannot be the address(0).
     * @param amount The number of tokens that are approved
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
     * @notice Destroy `amount` tokens from `msg.sender`, and decreasing the total supply.
     * @param amount The number of tokens to burn.
     * 
     * Requirements:
     * - `msg.sender` must have at least `amount` tokens.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Destroy `amount` tokens from `account`, and decreasing the total supply.
     * @param account The address of the tokens to burn. 
     * @param amount The number of tokens to burn.
     * 
     * Requirements:
     * - msg.sender must have allowance for `account`'s tokens of at least `amount` tokens.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }
}