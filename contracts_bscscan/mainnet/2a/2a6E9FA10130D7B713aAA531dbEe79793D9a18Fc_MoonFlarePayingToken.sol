/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT

/** 
* Crazeblade & the team presents
* 
* @title Moon-Flare-Paying-Token v1.0
* 
* ███╗░░░███╗░█████╗░░█████╗░███╗░░██╗  ███████╗██╗░░░░░░█████╗░██████╗░███████╗
* ████╗░████║██╔══██╗██╔══██╗████╗░██║  ██╔════╝██║░░░░░██╔══██╗██╔══██╗██╔════╝
* ██╔████╔██║██║░░██║██║░░██║██╔██╗██║  █████╗░░██║░░░░░███████║██████╔╝█████╗░░
* ██║╚██╔╝██║██║░░██║██║░░██║██║╚████║  ██╔══╝░░██║░░░░░██╔══██║██╔══██╗██╔══╝░░
* ██║░╚═╝░██║╚█████╔╝╚█████╔╝██║░╚███║  ██║░░░░░███████╗██║░░██║██║░░██║███████╗
* ╚═╝░░░░░╚═╝░╚════╝░░╚════╝░╚═╝░░╚══╝  ╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝
* 
* ██████╗░░█████╗░██╗░░░██╗██╗███╗░░██╗░██████╗░  ████████╗░█████╗░██╗░░██╗███████╗███╗░░██╗
* ██╔══██╗██╔══██╗╚██╗░██╔╝██║████╗░██║██╔════╝░  ╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝████╗░██║
* ██████╔╝███████║░╚████╔╝░██║██╔██╗██║██║░░██╗░  ░░░██║░░░██║░░██║█████═╝░█████╗░░██╔██╗██║
* ██╔═══╝░██╔══██║░░╚██╔╝░░██║██║╚████║██║░░╚██╗  ░░░██║░░░██║░░██║██╔═██╗░██╔══╝░░██║╚████║
* ██║░░░░░██║░░██║░░░██║░░░██║██║░╚███║╚██████╔╝  ░░░██║░░░╚█████╔╝██║░╚██╗███████╗██║░╚███║
* ╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝╚═╝░░╚══╝░╚═════╝░  ░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝
* 
* 
* Official website: https://moonflare.io
* 
**/

pragma solidity 0.8.1;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor (string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
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

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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


interface IPayingToken {

    /**
     * @dev Returns the total amount of funds a given address is able to withdraw currently.
     * @param owner Address of FundsDistributionToken holder
     * @return A uint256 representing the available funds for a given account
     */
    function withdrawableFundsOf(address owner) external view returns (uint256);

    /**
     * @dev Withdraws all available funds for a FundsDistributionToken holder.
     */
    function withdrawFunds() external;

    /**
     * @dev This event emits when new funds are distributed
     * @param fundsDistributed the amount of funds received for distribution
     */
    event FundsDistributed(uint256 fundsDistributed);

    /**
     * @dev This event emits when distributed funds are withdrawn by a token holder.
     * @param by the address of the receiver of funds
     * @param fundsWithdrawn the amount of funds that were withdrawn
     */
    event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn);
}


/** 
 * @title PayingToken
 * Based on https://github.com/atpar/funds-distribution-token
 * @dev A  mintable token that can represent claims on cash flow of arbitrary assets such as dividends, loan repayments, 
 * fee or revenue shares among large numbers of token holders. Anyone can deposit funds, token holders can withdraw 
 * their claims.
 */
abstract contract PayingToken is IPayingToken, ERC20 {

    // optimize, see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal pointsMultiplier = 2**128;
    uint256 internal pointsPerShare;
    uint256 internal activeTokens; 

    mapping(address => int256) internal pointsCorrection;
    mapping(address => uint256) internal withdrawnFunds;
    mapping(address => bool) internal activatedAddresses;


    constructor (
        string memory name, 
        string memory symbol
    ) 
        ERC20(name, symbol) 
    {}


    function activateAddress() public {
        address account = msg.sender;

        require(!isAddressActivated(account), "PayingToken.activateAddress: already activated");

        activatedAddresses[account] = true;
        uint256 balance = balanceOf(account);

        activeTokens = activeTokens + balance;

        pointsCorrection[account] = pointsCorrection[account] -  int256(pointsPerShare * balance);
    }

    function isAddressActivated(address account) public view returns(bool) {
        return activatedAddresses[account];
    }

    /** 
     * prev. distributeDividends
     * @notice Distributes funds to token holders.
     * @dev It reverts if the total supply of tokens is 0.
    **/
    function _distributeFunds(uint256 value) internal {
        pointsPerShare = pointsPerShare + (value * pointsMultiplier) / activeTokens;
        emit FundsDistributed(value);
    }

    /**
     * prev. withdrawDividend
     * @notice Prepares funds withdrawal
     * @dev It emits a `FundsWithdrawn` event if the amount of withdrawn ether is greater than 0.
     */
    function _prepareWithdraw() internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableFundsOf(msg.sender);
    
        withdrawnFunds[msg.sender] = withdrawnFunds[msg.sender] + _withdrawableDividend;
        
        emit FundsWithdrawn(msg.sender, _withdrawableDividend);

        return _withdrawableDividend;
    }

    /** 
     * prev. withdrawableDividendOf
     * @notice View the amount of funds that an address can withdraw.
     * @param _owner The address of a token holder.
     * @return The amount funds that `_owner` can withdraw.
     */
    function withdrawableFundsOf(address _owner) public view override returns(uint256) {
        return accumulativeFundsOf(_owner)- withdrawnFunds[_owner];
    }
    
    /**
     * prev. withdrawnDividendOf
     * @notice View the amount of funds that an address has withdrawn.
     * @param _owner The address of a token holder.
     * @return The amount of funds that `_owner` has withdrawn.
     */
    function withdrawnFundsOf(address _owner) public view returns(uint256) {
        return withdrawnFunds[_owner];
    }

    /**
     * prev. accumulativeDividendOf
     * @notice View the amount of funds that an address has earned in total.
     * @dev accumulativeFundsOf(_owner) = withdrawableFundsOf(_owner) + withdrawnFundsOf(_owner)
     * = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier
     * @param _owner The address of a token holder.
     * @return The amount of funds that `_owner` has earned in total.
     */
    function accumulativeFundsOf(address _owner) public view returns(uint256) {
        if (!isAddressActivated(_owner)) {
            return 0;
        }

        return uint256(int256(pointsPerShare * balanceOf(_owner)) + pointsCorrection[_owner]) / pointsMultiplier;
    }

    /**
     * @dev Internal function that transfer tokens from one address to another.
     * Update pointsCorrection to keep funds unchanged.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal override {
        super._transfer(from, to, value);

        if (!isAddressActivated(from) && !isAddressActivated(to)) {
            return;
        }

        int256 _magCorrection = int256(pointsPerShare * value);

        if (isAddressActivated(from) && !isAddressActivated(to)) {
            activeTokens = activeTokens - value;
            require(activeTokens > 0, "PayingToken: you cannot transfer all active tokens to an inactive address");
            pointsCorrection[from] = pointsCorrection[from] + _magCorrection;

            return;
        }

        if (!isAddressActivated(from) && isAddressActivated(to)) {
            activeTokens = activeTokens + value;
            pointsCorrection[to] = pointsCorrection[to] - _magCorrection;
            
            return;
        }

        pointsCorrection[from] = pointsCorrection[from] + _magCorrection;
        pointsCorrection[to] = pointsCorrection[to] - _magCorrection;
    }
}


contract MoonFlarePayingToken is IPayingToken, PayingToken {
    string constant TOKEN_NAME = "Moon Flare Paying Token";
    string constant TOKEN_SYMBOL = "MFPT";
    uint256 constant TOTAL_SUPPLY = 10**24;

    constructor() payable PayingToken(TOKEN_NAME, TOKEN_SYMBOL) 
    {
        _mint(msg.sender, TOTAL_SUPPLY); 
        activateAddress();
    }

    /**
     * @notice Withdraws available funds for user.
     */
    function withdrawFunds() external override {
        uint256 withdrawableFunds = _prepareWithdraw();
        
        payable(msg.sender).transfer(withdrawableFunds);
    }

    /**
     * @notice The default function calls _distributeFunds() whereby magnifiedFundsPerShare gets updated.
     */
    receive() external payable {
        if (msg.value > 0) {
            _distributeFunds(msg.value);
        }
    }

    fallback() external payable {
        if (msg.value > 0) {
            _distributeFunds(msg.value);
        }
    }
}