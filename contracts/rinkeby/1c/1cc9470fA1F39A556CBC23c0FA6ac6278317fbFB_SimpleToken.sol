// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "./ERC20.sol";

contract SimpleToken is ERC20 {
    /**
      * @notice SimpleToken is token based on simplified ERC20
      * @dev SimpleToken is simple ERC20 which mint tokens when you deploy this contract
      * @param _name is name
      * @param _symbol is symbol
      */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 100 * 10 ** 18);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/**
 * @title Simplified ERC20 token
 * @notice You can use this contract for only the most basic simulation
 * @dev Shorter version of Openzeppelin ERC20 token.
 * Deleted all unused functions and left the core one.
 * Better to extend Openzeppelin ERC20 token.
 */
contract ERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
    * @notice Constructor to create a new ERC20 token
    * @dev Sets the values for {name} and {symbol}
    * All two of these values are immutable: they can only be set once during
    * construction.
    * @param name_ The name of the creating token
    * @param symbol_ The symbolic which improves usability
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
    * @notice Token name
    * @dev Shows the name of the token
    * @return string name of the token
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
    * @notice Token symbol
    * @dev Shows the symbol of the token
    * @return string symbol of the token
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
    * @notice Total token quantity
    * @dev Shows exist tokens quantity
    * @return uint256 token quantity
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
    * @notice Shows token amount of the account
    * @dev Shows account token balance
    * @param account address
    * @return uint256 token quantity
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
    * @notice Transfer from current user to recipient amount of tokens
    * @dev Direct transfering amount of tokens from function caller to recipient address.
    * @param recipient Address of the receiver
    * @param amount Amount of tokens
    * @return bool flag
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    /**
    * @notice Show total allowance provided by owner to spender
    * @dev Get allowance amount, if owner approved spender to spend some amount of owner's tokens
    * @param owner Address of the token owner
    * @param spender Address of the spender
    * @return uint256 token amount
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
    * @notice Owner approves spender to spend some amount of owner's tokens
    * @dev Owner does not transfer owner's tokens to the spender.
    * @param spender Address of the spender
    * @param amount Token amount
    * @return bool flag
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
    * @notice Transfer amount of tokens from token owner's(sender) to the recipient address
    * @dev Can fail if it didn't approved by sender to the recipient
    * @param sender Address of the owner of tokens
    * @param recipient Address of the recipient
    * @param amount Token amount
    * @return bool flag
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    /**
    * @notice Owner increase approved tokens amount to the spender
    * @dev Owner 
    * @param spender Address of the spender
    * @param addedValue Additional allowed tokens
    * @return bool flag
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
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
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** 
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
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
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
}

{
  "optimizer": {
    "enabled": true,
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
  "libraries": {}
}