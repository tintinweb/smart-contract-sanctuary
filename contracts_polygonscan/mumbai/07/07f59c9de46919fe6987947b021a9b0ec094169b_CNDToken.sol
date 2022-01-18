// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

import "./Roles.sol";

/**
 * @title CND | Candella Security Token
 * @author Stobox Technologies Inc.
 * @dev CND ERC20 Token | This contract is opt for digital securities management.
 */
 
contract CNDToken is IERC20, Roles {
    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;

    struct TransferLimit {
        uint256 transferLimit;
        uint256 lastTransferLimitTimestamp;
        uint256 allowedToTransfer;
    }

    struct TransactionCountLimit {
        uint256 transactionCountLimit;
        uint256 lastTransactionCountLimitTimestamp;
        uint256 leftTransactionCountLimit;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => TransferLimit) private _transferLimits;
    mapping(address => TransactionCountLimit) private _transactionCountLimits;

    uint256 private _defaultTransferLimit;
    uint256 private _defaultTransactionCountLimit;
    uint256 private _totalSupply;
    uint256 private _kDecimals;
    uint256 private _k;

    string private _name;
    string private _symbol;

    uint8 private _decimals;

    bool public _isDisabledWitelist;
    bool public _isEnabledTransactionCount;

    EnumerableSet.AddressSet private _whitelist;
    EnumerableSet.AddressSet private _frozenlist;

    // Modifiers

    modifier onlyWhitelisted(address _account) {
        if (_isDisabledWitelist) {
            require(
                _whitelist.contains(_account),
                "CND: not whitelisted address."
            );
        }
        _;
    }

    modifier onlyWithUnfrozenFunds(address _account) {
        require(
            _frozenlist.contains(_account) == false,
            "CND: funds are frozen."
        );
        _;
    }

    /**
     * @notice CNDToken simply implements a ERC20 token.
     */
    constructor() public Roles(msg.sender) {
        _name = "Candella Security Token";
        _symbol = "CND";
        _decimals = 0;
        _kDecimals = 18;
        _k = 10**_kDecimals;
        _defaultTransferLimit = 0;
        _defaultTransactionCountLimit = 0;

        _mint(msg.sender, 158400);
        _whitelist.add(msg.sender);
    }

    // External functions

    /**
     * @notice Enable or disable the whitelist.
     * @param _value Flag that enables or disables the whitelist.
     */
    function toggleOpenWhitelist(bool _value) external onlySuperAdmin {
        _isDisabledWitelist = _value;
    }

    /**
     * @notice Enable or disable the transactions limit.
     * @param _value Flag that enables or disables the transactions limit.
     */
    function toggleOpenTransactionCount(bool _value) external onlySuperAdmin {
        _isEnabledTransactionCount = _value;
    }

    /**
     * @notice Add an address to the whitelist.
     * @param _address Address to add to the whitelist.
     */
    function addAddressToWhitelist(address _address) external onlyWhitelister {
        _whitelist.add(_address);
        _frozenlist.remove(_address);
    }

    /**
     * @notice Remove an address from the whitelist.
     * @param _address Address to remove from the whitelist.
     */
    function removeAddressFromWhitelist(address _address)
        external
        onlyWhitelister
    {
        _whitelist.remove(_address);
        _frozenlist.add(_address);
    }

    /**
     * @notice Freeze all funds at the address.
     * @param _account Account at which to freeze funds.
     */
    function freezeFunds(address _account) external onlyFreezer {
        _frozenlist.add(_account);
    }

    /**
     * @notice Unfreeze all funds at the address.
     * @param _account Account at which to unfreeze funds.
     */
    function unfreezeFunds(address _account) external onlyFreezer {
        _frozenlist.remove(_account);
    }

    /**
     * @notice Minting of new tokens to the address.
     * @param _account Account where to mint tokens.
     * @param _amount Amount of tokens to mint.
     */
    function mint(address _account, uint256 _amount)
        external
        onlySuperAdmin
        onlyWhitelisted(_account)
    {
        _mint(_account, _getNormilizedValue(_amount));
    }

    /**
     * @notice Burning of tokens from the address.
     * @param _account Account where to burn tokens.
     * @param _amount Amount of tokens to burn.
     *
     * Calling conditions:
     *
     * - balance of `_account` must be grater or equal than `_amount`.
     */
    function burn(address _account, uint256 _amount) external onlySuperAdmin {
        require(balanceOf(_account) >= _amount, "CND: balance too low");
        _burn(_account, _getNormilizedValue(_amount));
    }

    /**
     * @notice Transfer funds from one address to another.
     * @param _from Address from which to transfer funds.
     * @param _where Address where to transfer funds.
     * @param _amount Amount to transfer.
     *
     * Requirements:
     *
     * - balance of `_from` must be greater or equal to `_amount`.
     */
    function transferFunds(
        address _from,
        address _where,
        uint256 _amount
    ) external onlyTransporter onlyWhitelisted(_where) returns (bool) {
        require(balanceOf(_from) >= _amount, "CND: not enough tokens");

        _transfer(_from, _where, _getNormilizedValue(_amount));

        return true;
    }

    /**
     * @notice Stock split or merge (consolidation).
     * @param _x The count of shares before split.
     * @param _y The count of shares after split.
     * @dev 1-2: one share turns into two. 3-2: three shares turns into two.
     *
     * Requirements:
     *
     * - `_x` must not be equal to `_y`.
     * - `_x` and `_y` must be greater than 0.
     */
      /**
    function splitOrMerge(uint256 _x, uint256 _y) external onlySuperAdmin {
        require(_x != _y, "CND: _x must not be equal to _y");
        require(_x > 0, "CND: _x must be greater than 0");
        require(_y > 0, "CND: _y must be greater than 0");

        _split(_x, _y);
    }
    */

    /**
     * @notice Set transfer limit for address.
     * @param _account Address where to set transfer limit.
     * @param _transferLimit Daily transfer limit for an `_account`.
     */
    function setTransferLimit(address _account, uint256 _transferLimit)
        external
        onlyLimiter
    {
        _transferLimits[_account].transferLimit = _transferLimit;
        _transferLimits[_account].allowedToTransfer = _transferLimit;
        _transferLimits[_account].lastTransferLimitTimestamp = block.timestamp;
    }

    /**
     * @notice Set transaction count limit for address.
     * @param _account Address where to set transaction count limit.
     * @param _transactionCountLimit Daily transfer limit for an `_account`.
     */
    function setTransactionCountLimit(
        address _account,
        uint256 _transactionCountLimit
    ) external onlyLimiter {
        _transactionCountLimits[_account]
            .transactionCountLimit = _transactionCountLimit;
        _transactionCountLimits[_account]
            .leftTransactionCountLimit = _transactionCountLimit;
        _transactionCountLimits[_account]
            .lastTransactionCountLimitTimestamp = block.timestamp;
    }

    // External view functions

    /**
     * @notice Checking if the address is whitelisted.
     * @param _address Address to check in the whitelist.
     * @return Is the address in the whitelist.
     */
    function isWhitelistedAddress(address _address)
        external
        view
        returns (bool)
    {
        return _whitelist.contains(_address);
    }

    /**
     * @notice Checking if the funds are frozen.
     * @param _account Address to check.
     * @return Is the funds are frozen.
     */
    function isFrozenFunds(address _account) external view returns (bool) {
        return _frozenlist.contains(_account);
    }

    /**
     * @notice Get main coefficient.
     * @return Coefficient.
     */
    function getK() external view returns (uint256) {
        return _k;
    }

    // Public functions

    /**
     * @notice Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply.mul(_k).div(10**_kDecimals);
    }

    /**
     * @notice Returns the amount of tokens owned by `_account`.
     * @param _account Account to check balance.
     */
    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        return _balances[_account].mul(_k).div(10**_kDecimals);
    }

    /**
     * @notice Returns transfer limit for `_account`.
     * Can be defaul value or personally assigned to the `_account` value.
     * @param _account Account to get transfer limit.
     */
    function getTransferLimit(address _account) public view returns (uint256) {
        if (_transferLimits[_account].transferLimit > 0) {
            return _transferLimits[_account].transferLimit;
        }

        return _defaultTransferLimit;
    }

    /**
     * @notice Get the number of tokens that can be transferred today
     * by `_account`. Can be 0 in 2 cases:
     * a) `_updateTransferLimit` function not called yet;
     * b) transfer limit was set to 0 by limiter.
     * @param _account Account to get amount allowed to transfer today.
     */
    function getAllowedToTransfer(address _account)
        public
        view
        returns (uint256)
    {
        return _transferLimits[_account].allowedToTransfer;
    }

    /**
     * @notice Returns transaction count limit for `_account`.
     * Can be default value or personally assigned to the `_account` value.
     * @param _account Account to get transfer limit.
     */
    function getTransactionCountLimit(address _account)
        public
        view
        returns (uint256)
    {
        if (_transactionCountLimits[_account].transactionCountLimit > 0) {
            return _transactionCountLimits[_account].transactionCountLimit;
        }

        return _defaultTransactionCountLimit;
    }

    /**
     * @notice Get the number of transactions that can be transferred today
     * by `_account`. Can be 0 in 2 cases:
     * a) `_updateTransferLimit` function not called yet;
     * b) transfer limit was set to 0 by limiter.
     * @param _account Account to get amount allowed to transfer today.
     */
    function getLeftTransactionCountLimit(address _account)
        public
        view
        returns (uint256)
    {
        return _transactionCountLimits[_account].leftTransactionCountLimit;
    }

    /**
     * @notice Moves `_amount` tokens from the caller's account to `_recipient`.
     * Emits a {Transfer} event.
     * @param _recipient Recipient of the tokens.
     * @param _amount Amount tokens to move.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(address _recipient, uint256 _amount)
        public
        virtual
        override
        onlyWhitelisted(msg.sender)
        onlyWhitelisted(_recipient)
        onlyWithUnfrozenFunds(msg.sender)
        returns (bool)
    {
        _updateTransferLimit(msg.sender, _amount);
        _updateTransactionCountLimit(_recipient);
        _updateTransactionCountLimit(msg.sender);
        _transfer(msg.sender, _recipient, _getNormilizedValue(_amount));

        return true;
    }

    /**
     * @notice the remaining number of tokens that `_spender` will be
     * allowed to spend on behalf of `_owner` through {transferFrom}. This is
     * zero by default.
     * @param _owner Owner of tokens.
     * @param _spender Spender of tokens.
     */
    function allowance(address _owner, address _spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[_owner][_spender].mul(_k).div(10**_kDecimals);
    }

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the caller's tokens.
     * Emits an {Approval} event.
     * @param _spender Spender of the tokens.
     * @param _amount Amount of tokens to set as the allowance.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(address _spender, uint256 _amount)
        public
        virtual
        override
        onlyWhitelisted(msg.sender)
        onlyWhitelisted(_spender)
        onlyWithUnfrozenFunds(msg.sender)
        returns (bool)
    {
        _approve(msg.sender, _spender, _getNormilizedValue(_amount));

        return true;
    }

    /**
     * @notice Moves `_amount` tokens from `_sender` to `_recipient` using the
     * allowance mechanism. `_amount` is then deducted from the caller's
     * allowance.
     * Emits a {Transfer} event.
     * @param _sender Spender of tokens.
     * @param _recipient Recipient of tokens.
     * @param _amount Amount of tokens to transfer.
     * @return A boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - `_amount` must be less or equal allowance for the `_sender`.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        public
        virtual
        override
        onlyWhitelisted(_sender)
        onlyWhitelisted(_recipient)
        onlyWithUnfrozenFunds(_sender)
        returns (bool)
    {
        _updateTransferLimit(_sender, _amount);
        _updateTransactionCountLimit(_sender);
        _updateTransactionCountLimit(_recipient);
        _transfer(_sender, _recipient, _getNormilizedValue(_amount));
        _approve(
            _sender,
            msg.sender,
            _allowances[_sender][msg.sender].sub(
                _getNormilizedValue(_amount),
                "CND: transfer amount exceeds allowance"
            )
        );

        return true;
    }

    /**
     * @notice Increase allowance for the `_spender`.
     * @param _spender Spender of tokens.
     * @param _addedValue Value to add to the allowance for the `_spender`.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        virtual
        onlyWhitelisted(msg.sender)
        onlyWhitelisted(_spender)
        onlyWithUnfrozenFunds(msg.sender)
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowances[msg.sender][_spender].add(
                _getNormilizedValue(_addedValue)
            )
        );

        return true;
    }

    /**
     * @notice Decrease allowance for the `_spender`.
     * @param _spender Spender of tokens.
     * @param _subtractedValue Value to substruct from the allowance for the `_spender`.
     * @return A boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - result of substruction must be greater or equal to 0.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        virtual
        onlyWhitelisted(msg.sender)
        onlyWhitelisted(_spender)
        onlyWithUnfrozenFunds(msg.sender)
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowances[msg.sender][_spender].sub(
                _getNormilizedValue(_subtractedValue),
                "CND: decreased allowance below zero"
            )
        );

        return true;
    }

    // Internal functions

    /**
     * @notice Moves tokens `_amount` from `_sender` to `_recipient`.
     * Emits a {Transfer} event.
     * @param _sender Sender of tokens.
     * @param _recipient Recipient of tokens.
     * @param _amount Amount of tokens to transfer.
     *
     * Requirements:
     *
     * - `_sender` cannot be the zero address.
     * - `_recipient` cannot be the zero address.
     * - `_sender` must have a balance of at least `_amount`.
     */
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_sender != address(0), "CND: transfer from the zero address");
        require(_recipient != address(0), "CND: transfer to the zero address");

        _beforeTokenTransfer(_sender, _recipient, _amount);

        _balances[_sender] = _balances[_sender].sub(
            _amount,
            "CND: transfer amount exceeds balance"
        );
        _balances[_recipient] = _balances[_recipient].add(_amount);

        emit Transfer(_sender, _recipient, _amount);
    }

    /** @notice Creates `_amount` tokens and assigns them to `_account`, increasing
     * the total supply.
     * Emits a {Transfer} event with `_from` set to the zero address.
     * @param _account Account where to mint tokens.
     * @param _amount Amount of tokens to mint.
     *
     * Requirements:
     *
     * - `_account` cannot be the zero address.
     */
    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "CND: mint to the zero address");

        _beforeTokenTransfer(address(0), _account, _amount);

        _totalSupply = _totalSupply.add(_amount);
        _balances[_account] = _balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @notice Destroys `_amount` tokens from `_account`, reducing the
     * total supply.
     * Emits a {Transfer} event with `_to` set to the zero address.
     * @param _account Account where to burn tokens.
     * @param _amount Amount of tokens to burn.
     *
     * Requirements:
     *
     * - `_account` cannot be the zero address.
     * - `_amount` must have at least `amount` tokens.
     */
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "CND: burn from the zero address");

        _beforeTokenTransfer(_account, address(0), _amount);

        _balances[_account] = _balances[_account].sub(
            _amount,
            "CND: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
     * Emits an {Approval} event.
     * @param _owner Owner of the tokens.
     * @param _spender Spender of the tokens.
     * @param _amount Amount of tokens to set as the allowance.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "CND: approve from the zero address");
        require(_spender != address(0), "CND: approve to the zero address");

        _allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @notice Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     * @param _from The address from which tokens will be moved.
     * @param _to The address where tokens will be moved.
     * @param _amount Amount of tokens that will be moved.
     *
     * Calling conditions:
     *
     * - when `_from` and `_to` are both non-zero, `_amount` of ``_from``'s tokens
     * will be to transferred to `_to`.
     * - when `_from` is zero, `_amount` tokens will be minted for `_to`.
     * - when `_to` is zero, `_amount` of ``_from``'s tokens will be burned.
     * - `_from` and `_to` are never both zero.
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {}

    // Private functions

    /**
     * @notice Changes the global multiplier during stock splits and consolidations.
     * @param _x First coefficient.
     * @param _y Second coefficient.
     */
    function _split(uint256 _x, uint256 _y) private {
        _k = _k.mul(_y.mul(10**_kDecimals).div(_x));
        _k = _k.div(10**18);
    }

    /**
     * @notice Getting normalized value depends on coefficient.
     * @param _value Value to normilize.
     * @return Normilized value.
     */
    function _getNormilizedValue(uint256 _value)
        private
        view
        returns (uint256)
    {
        return _value.mul(10**_kDecimals).div(_k);
    }

    /**
     * @notice Update transfer limit for `_account` before each operation with
     * tokens.
     * @param _account Account to update transfer limit if needed.
     * @param _amount Amount to substruct from transfer limit after updating.
     */
    function _updateTransferLimit(address _account, uint256 _amount) private {
        if (
            _transferLimits[_account].lastTransferLimitTimestamp + 1 days <
            block.timestamp
        ) {
            _transferLimits[_account].lastTransferLimitTimestamp = block
                .timestamp;

            if (_transferLimits[_account].transferLimit > 0) {
                _transferLimits[_account].allowedToTransfer = _transferLimits[
                    _account
                ]
                    .transferLimit;
            } else {
                _transferLimits[_account]
                    .allowedToTransfer = _defaultTransferLimit;
            }
        }

        _transferLimits[_account].allowedToTransfer = _transferLimits[_account]
            .allowedToTransfer
            .sub(_amount, "CND: transfer exceeds your transfer limit");
    }

    /**
     * @notice Update transaction count limit for `_account` before each operation with
     * tokens.
     * @param _account Account to update transaction count limit if needed.
     */
    function _updateTransactionCountLimit(address _account) private {
        if (_isEnabledTransactionCount) {
            if (
                _transactionCountLimits[_account]
                    .lastTransactionCountLimitTimestamp +
                    1 days <
                block.timestamp
            ) {
                _transactionCountLimits[_account]
                    .lastTransactionCountLimitTimestamp = block.timestamp;

                if (
                    _transactionCountLimits[_account].transactionCountLimit > 0
                ) {
                    _transactionCountLimits[_account]
                        .leftTransactionCountLimit = _transactionCountLimits[
                        _account
                    ]
                        .transactionCountLimit;
                } else {
                    _transactionCountLimits[_account]
                        .leftTransactionCountLimit = _defaultTransactionCountLimit;
                }
            }

            _transactionCountLimits[_account]
                .leftTransactionCountLimit = _transactionCountLimits[_account]
                .leftTransactionCountLimit
                .sub(1, "CND: transfer exceeds your transaction count limit");
        }
    }
}