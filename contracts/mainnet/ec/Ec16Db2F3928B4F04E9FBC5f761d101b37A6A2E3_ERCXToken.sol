// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./IERC20.sol";

import "./Ownable.sol";
import "./ERC223_receiving_contract.sol";


/// @title ERCXToken - Extended ERC20 Token
/// @custom:version 1.0.1
contract ERCXToken is IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    uint8 private _decimals;
    uint256 private _maxSupply;

    /**
     * ERC223 interface extension with additional data argument
     */
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    constructor (
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 tokenTotalSupply,
        uint256 tokenMaxSupply,
        address superOwner,
        address owner,
        address api
    )
    Ownable(superOwner, owner, api)
     {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        _totalSupply = tokenTotalSupply;
	    _maxSupply = tokenMaxSupply;
        _balances[superOwner] = _totalSupply;
        emit Transfer(address(0), superOwner, _totalSupply);

        bytes memory empty;
        emit Transfer(address(0), superOwner, _totalSupply, empty);
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
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
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
    * @dev Transfer token for a specified address (ERC223)
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @param data Transaction metadata.
    */
    function transfer(address to, uint256 value, bytes memory data) public returns (bool) {
        _transfer223(msg.sender, to, value, data);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses (ERC223)
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @param data Transaction metadata to be forwarded to the receiving smart contract.
    */
    function _transfer223(address from, address to, uint256 value, bytes memory data) internal {
        require(value <= _balances[from], "Value must not be higher than sender's balance.");
        require(to != address(0), "Receiver address must be set.");

        uint256 codeLength;
        assembly {
            codeLength := extcodesize(to)
        }

        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;

        if(codeLength > 0) { // receiver is a contract address
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, data);
        }

        emit Transfer(from, to, value);
        emit Transfer(from, to, value, data);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 codeLength;
        bytes memory empty;
        assembly {
             codeLength := extcodesize(recipient)
        }

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        if (codeLength > 0) { // odbiorca jest kontraktem, nie walletem
            ERC223ReceivingContract receiver = ERC223ReceivingContract(recipient);
            receiver.tokenFallback(msg.sender, amount, empty);
        }

        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount, empty);
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(totalSupply() + amount <= maxSupply(), "Maximum token supply exceeded");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        bytes memory empty;
        emit Transfer(account, address(0), amount, empty);
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
    function _approve(address owner, address spender, uint256 amount) internal {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }

    /**
    * @dev Function to mint tokens
    * @param to The address that will receive the minted tokens.
    * @param value The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address to, uint256 value) public onlySuperOwnerOrOwnerOrApiOrContract returns (bool)
    {
        _mint(to, value);
        return true;
    }

    /**
    * @dev Burns a specific amount of tokens.
    * @param value The amount of token to be burned.
    */
    function burn(uint256 value) public onlySuperOwnerOrOwnerOrApiOrContract {
        _burn(msg.sender, value);
    }

   /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowances[account][msg.sender], "Amount must not be higher than allowed balance.");
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowances[account][msg.sender] = _allowances[account][msg.sender] - value;
        _burn(account, value);
    }

    /**
    * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param from address The address which you want to send tokens from
    * @param value uint256 The amount of token to be burned
    */
    function burnFrom(address from, uint256 value) public onlySuperOwnerOrOwnerOrApiOrContract {
        _burnFrom(from, value);
    }

}