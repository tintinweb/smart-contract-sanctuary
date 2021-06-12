// Spraytoken.net (SPRAY)
// SPRAY is a deflationary cryptocurrency with auto-staking and dynamic burn model,
// designed to resist the bear market by increasing the burn rate when the market is in a downward phase.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20Metadata.sol";
import "Address.sol";
import "AggregatorV3Interface.sol";

/**
 * @dev Wrapper for chainlink oracle (AggregatorV3Interface)
 */
abstract contract Aggregator is Ownable {
    using Address for address;

    AggregatorV3Interface private _aggregator;
    int256 private _price = 0;
    bool private _isTrandUp = true;

    /**
     * @dev Emitted when agregator changes to `newAggregator`.
     */
    event UpdateAggregator(address indexed newAggregator);

    /**
     * @dev Updates the oracle used to receive market data.
     *
     * Can be called by the contract owner.
     */
    function updateAggregator(address newAggregator) public virtual onlyOwner {
        require(newAggregator.isContract(), "Address: call to non-contract");

        _aggregator = AggregatorV3Interface(newAggregator);
        updateTrand();

        emit UpdateAggregator(newAggregator);
    }

    /**
     * @dev Checks if the market trend is upward (bullish).
     */
    function isTrandUp() public view virtual returns (bool) {
        return _isTrandUp;
    }

    /**
     * @dev Updates the trend information.
     */
    function updateTrand() public virtual {
        (, int256 price, , , ) = _aggregator.latestRoundData();

        if (price != _price) {
            _isTrandUp = price > _price;
            _price = price;
        }
    }
}

/**
 * @dev Deflationary ERC-20 token. Automatic rewards for holders. Dynamic supply. Rich in memes.
 *
 * For more information see spraytoken.net
 */
contract Spray is Aggregator, IERC20Metadata {
    uint8 private constant _FEE_BASE = 3;
    uint8 private constant _FEE_DIV = 100;
    uint8 private constant _FIRE_MARKET_UP = 1;
    uint8 private constant _FIRE_MARKET_DOWN = 2;
    uint8 private constant _FIRE_DIV = 3;

    string private constant _NAME = "spraytoken.net";
    string private constant _SYMBOL = "SPRAY";
    uint8 private constant _DECIMALS = 8;
    uint256 private constant _EMISSION_INIT = 500 * (10**12) * (10**8);

    uint256 private _emissionExcluded = 0;
    uint256 private _emissionIncluded = _EMISSION_INIT;
    uint256 private _rate = type(uint256).max / _EMISSION_INIT;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    mapping(address => bool) private _isExcluded;
    mapping(address => uint256) private _excludedBalances;

    constructor() {
        _balances[_msgSender()] = _EMISSION_INIT * _rate;
        emit Transfer(address(0), _msgSender(), _EMISSION_INIT);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure override returns (string memory) {
        return _NAME;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public pure override returns (string memory) {
        return _SYMBOL;
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return _emissionExcluded + _emissionIncluded;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _excludedBalances[account];

        return _balances[account] / _rate;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        _transfer(sender, recipient, amount);

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Check whether the account is included in redistribution.
     */
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /**
     * @dev Exclude `account` from receiving 1-2% transaction fee redistribution via auto-staking.
     *
     * Can be used to exclude technical addresses, such as exchange hot wallets.
     * Can be called by the contract owner.
     */
    function excludeAccount(address account) public virtual onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        uint256 eBalance = _balances[account] / _rate;
        _excludedBalances[account] += eBalance;
        _balances[account] = 0;
        _isExcluded[account] = true;
        _emissionExcluded += eBalance;
        _emissionIncluded -= eBalance;
    }

    /**
     * @dev Includes `accounts` back for receiving 1-2% transaction fee redistribution via auto-staking.
     *
     * Can be called by the contract owner.
     */
    function includeAccount(address account) public virtual onlyOwner {
        require(_isExcluded[account], "Account is already included");

        uint256 eBalance = _excludedBalances[account];
        _excludedBalances[account] = 0;
        _balances[account] = eBalance * _rate;
        _isExcluded[account] = false;
        _emissionExcluded -= eBalance;
        _emissionIncluded += eBalance;
    }

    /**
     * @dev Exclude sender account from receiving 1-2% transaction fee redistribution via auto-staking.
     *
     * Can be used to exclude technical addresses, such as exchange hot wallets.
     */
    function excludeSelf() public virtual {
        excludeAccount(_msgSender());
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves tokens `eAmount` from `sender` to `recipient`.
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
        uint256 eAmount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            _EMISSION_INIT >= eAmount,
            "ERC20: transfer amount exceeds balance"
        );

        // Withdrawal from sender
        uint256 rAmount = eAmount * _rate;
        if (_isExcluded[sender]) {
            uint256 senderBalance = _excludedBalances[sender];
            require(
                senderBalance >= eAmount,
                "ERC20: transfer amount exceeds balance"
            );
            _excludedBalances[sender] = senderBalance - eAmount;

            _emissionExcluded -= eAmount;
            _emissionIncluded += eAmount;
        } else {
            uint256 senderBalance = _balances[sender];
            require(
                senderBalance >= rAmount,
                "ERC20: transfer amount exceeds balance"
            );
            uint256 newBalance = senderBalance - rAmount;
            if (newBalance < _rate) {
                rAmount += newBalance;
                _balances[sender] = 0;
            } else {
                _balances[sender] = newBalance;
            }
        }

        // Calculate fee and fired fee
        updateTrand();

        uint256 eFee = (eAmount * _FEE_BASE) / _FEE_DIV;
        uint256 rFee = eFee * _rate;
        uint8 fireBase = isTrandUp() ? _FIRE_MARKET_UP : _FIRE_MARKET_DOWN;
        uint256 eFire = (eFee * fireBase) / _FIRE_DIV;

        // Update emission and coefficient
        uint256 oldEmission = _emissionIncluded;
        _emissionIncluded -= eFire;
        _rate = (_rate * (oldEmission - eFee)) / _emissionIncluded;

        // Refill to recipient
        if (_isExcluded[recipient]) {
            uint256 tAmount = (rAmount - rFee) / _rate;
            _excludedBalances[recipient] += tAmount;

            _emissionExcluded += tAmount;
            _emissionIncluded -= tAmount;
        } else {
            _balances[recipient] += rAmount - rFee;
        }

        emit Transfer(sender, recipient, eAmount - eFee);
    }
}