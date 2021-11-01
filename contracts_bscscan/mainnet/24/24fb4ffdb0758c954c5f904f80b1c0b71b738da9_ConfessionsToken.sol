/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
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

/**
 * @title   ConfessionsToken
 * @author  Andrew J. Purves
 * @notice  ConfessionsToken is an ERC20 token. It is the token used by the Confessions App.
 *
 *          Features:
 *              -   Preminted initial supply.
 *              -   Ability for holders to burn (destroy) their tokens.
 *              -   No access control mechanism (for minting/pausing) and hence no governance.
 *
 *          Tokenomics:
 *              -   Each of the 2 developers receives 6% of the total supply.
 *              -   Of this 6%, 5% is locked until Valentines Day (14 Feb) 2023 (midnight UTC) and the remaining 1% is unlocked.
 *              -   3% of the total supply is set aside for future development and marketing.
 *              -   The remaining 85% is also minted to the first developer. This will be added to
 *                  a PancakeSwap liquidity pool. The liquidity tokens will then be sent to the burn address
 *                  so that the liquidity is locked. This transaction will be linked on the Confessions website
 *                  as proof of this.
 */
contract ConfessionsToken is IERC20 {
    // Balances available to each address
    mapping(address => uint256) private _availableBalances;
    // Balances locked for each address (unlockable after `_valentinesDayTimestamp`)
    mapping(address => uint256) private _lockedBalances;
    // Allowances, i.e. how much one address may spend on behalf of another
    mapping(address => mapping(address => uint256)) private _allowances;
    // Total number of tokens in existence
    uint256 private _totalSupply;
    // Total number of tokens minted on construction
    uint256 private _initialSupply;

    // Addresses of relevant team members
    address private constant _developer1 =
        0xFC4bB3Fb2978E06295309D447659b9C243e3690a;
    address private constant _developer2 =
        0xCa74E04FAC17486Cd17Fa3a65b10397C039d0757;
    address private constant _marketing =
        0xa45120D381b2EF5c77010923EB4921e5D027D901;
    address private constant _confessionsFund =
        0xDAb972cD5E582ac0B1E8Bb5C770EC4d97f8F9e80;
    uint256 private immutable _deploymentTimestamp;

    // Timestamp of Valentine's Day 2023 (midnight UTC), after which locked balances can be unlocked
    uint256 constant _valentinesDayTimestamp = 1676332800;

    // Percentage of each transfer which is burned
    uint256 private constant TRANSFER_BURN_PERCENTAGE = 1;
    // Percentage of each transfer which is sent to the Confessions Fund
    uint256 private constant TRANSFER_FUND_PERCENTAGE = 2;

    /**
     * @dev Creates the token and mints 1 000 000 000 (one billion) tokens
     *      and allocates them as described.
     */
    constructor() {
        _deploymentTimestamp = block.timestamp;

        _initialSupply = 10**9 * 10**uint256(decimals());

        _mint(_developer1, _initialSupply / 100);
        _mint(_developer2, _initialSupply / 100);
        _mint(_marketing, (_initialSupply * 3) / 100);
        _mintLocked(_developer1, _initialSupply / 20);
        _mintLocked(_developer2, _initialSupply / 20);
        _mint(_developer1, (_initialSupply * 17) / 20);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return "Confessions Token";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     *      name.
     */
    function symbol() public pure returns (string memory) {
        return "XOXO";
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     *      For example, if `decimals` equals `2`, a balance of `505` tokens should
     *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     *       no way affects any of the arithmetic of the contract, including
     *       {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure returns (uint8) {
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _availableBalances[account];
    }

    /**
     * @dev Returns the locked balance of an account
     */
    function lockedBalanceOf(address account) public view returns (uint256) {
        return _lockedBalances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ConfessionsToken: Transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     *      allowance.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(
            currentAllowance >= amount,
            "ConfessionsToken: Burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }

    /**
     * @dev Unlocks all locked tokens of an account, if the lock time has been surpassed.
     */
    function unlockTokens(address account) public {
        require(
            block.timestamp >= _valentinesDayTimestamp,
            "ConfessionsToken: Tokens cannot be unlocked before Valentine's Day 2023"
        );
        _availableBalances[account] += _lockedBalances[account];
        _lockedBalances[account] = 0;
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            sender != address(0),
            "ConfessionsToken: Transfer from the zero address"
        );
        require(
            recipient != address(0),
            "ConfessionsToken: Transfer to the zero address"
        );

        uint256 senderBalance = _availableBalances[sender];
        require(
            senderBalance >= amount,
            "ConfessionsToken: Transfer amount exceeds balance"
        );
        unchecked {
            _availableBalances[sender] = senderBalance - amount;
        }

        uint256 fundAmount = (amount * TRANSFER_FUND_PERCENTAGE) / 100;
        _availableBalances[_confessionsFund] += fundAmount;

        _availableBalances[recipient] += amount - fundAmount;

        uint256 burnAmount = (amount * TRANSFER_BURN_PERCENTAGE) / 100;
        _burn(recipient, burnAmount);

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to the available balance
     *      of `account`, increasing the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(
            account != address(0),
            "ConfessionsToken: Mint to the zero address"
        );

        _totalSupply += amount;
        _availableBalances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to the locked balance
     *      of `account`, increasing the total supply
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mintLocked(address account, uint256 amount) internal {
        require(
            account != address(0),
            "ConfessionsToken: Mint to the zero address"
        );

        _totalSupply += amount;
        _lockedBalances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     *      total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(
            account != address(0),
            "ConfessionsToken: Burn from the zero address"
        );

        uint256 accountBalance = _availableBalances[account];
        require(
            accountBalance >= amount,
            "ConfessionsToken: Burn amount exceeds balance"
        );
        unchecked {
            _availableBalances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(
            owner != address(0),
            "ConfessionsToken: Approve from the zero address"
        );
        require(
            spender != address(0),
            "ConfessionsToken: Approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}