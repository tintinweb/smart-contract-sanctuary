// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @title STBX | Stobox Technologies Common Stock
 * @author Stobox Technologies Inc.
 * @dev STBX ERC20 Token | This contract is opt for digital securities management.
 */

contract Roles is Ownable, AccessControl {
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant LIMITER_ROLE = keccak256("LIMITER_ROLE");

    /**
     * @notice Add `_address` to the super admin role as a member.
     * @param _address Address to aad to the super admin role as a member.
     */
    constructor(address _address) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);

        _setRoleAdmin(WHITELISTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(FREEZER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(TRANSPORTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(VOTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(LIMITER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // Modifiers
    modifier onlySuperAdmin() {
        require(isSuperAdmin(msg.sender), "Restricted to super admins.");
        _;
    }

    modifier onlyWhitelister() {
        require(isWhitelister(msg.sender), "Restricted to whitelisters.");
        _;
    }

    modifier onlyFreezer() {
        require(isFreezer(msg.sender), "Restricted to freezers.");
        _;
    }

    modifier onlyTransporter() {
        require(isTransporter(msg.sender), "Restricted to transporters.");
        _;
    }

    modifier onlyVoter() {
        require(isVoter(msg.sender), "Restricted to voters.");
        _;
    }

    modifier onlyLimiter() {
        require(isLimiter(msg.sender), "Restricted to limiters.");
        _;
    }

    // External functions

    /**
     * @notice Add the super admin role for the address.
     * @param _address Address for assigning the super admin role.
     */
    function addSuperAdmin(address _address) external onlySuperAdmin {
        _assignRole(_address, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @notice Add the whitelister role for the address.
     * @param _address Address for assigning the whitelister role.
     */
    function addWhitelister(address _address) external onlySuperAdmin {
        _assignRole(_address, WHITELISTER_ROLE);
    }

    /**
     * @notice Add the freezer role for the address.
     * @param _address Address for assigning the freezer role.
     */
    function addFreezer(address _address) external onlySuperAdmin {
        _assignRole(_address, FREEZER_ROLE);
    }

    /**
     * @notice Add the transporter role for the address.
     * @param _address Address for assigning the transporter role.
     */
    function addTransporter(address _address) external onlySuperAdmin {
        _assignRole(_address, TRANSPORTER_ROLE);
    }

    /**
     * @notice Add the voter role for the address.
     * @param _address Address for assigning the voter role.
     */
    function addVoter(address _address) external onlySuperAdmin {
        _assignRole(_address, VOTER_ROLE);
    }

    /**
     * @notice Add the limiter role for the address.
     * @param _address Address for assigning the limiter role.
     */
    function addLimiter(address _address) external onlySuperAdmin {
        _assignRole(_address, LIMITER_ROLE);
    }

    /**
     * @notice Renouncement of supera dmin role.
     */
    function renounceSuperAdmin() external onlySuperAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Remove the whitelister role for the address.
     * @param _address Address for removing the whitelister role.
     */
    function removeWhitelister(address _address) external onlySuperAdmin {
        _removeRole(_address, WHITELISTER_ROLE);
    }

    /**
     * @notice Remove the freezer role for the address.
     * @param _address Address for removing the freezer role.
     */
    function removeFreezer(address _address) external onlySuperAdmin {
        _removeRole(_address, FREEZER_ROLE);
    }

    /**
     * @notice Remove the transporter role for the address.
     * @param _address Address for removing the transporter role.
     */
    function removeTransporter(address _address) external onlySuperAdmin {
        _removeRole(_address, TRANSPORTER_ROLE);
    }

    /**
     * @notice Remove the voter role for the address.
     * @param _address Address for removing the voter role.
     */
    function removeVoter(address _address) external onlySuperAdmin {
        _removeRole(_address, VOTER_ROLE);
    }

    /**
     * @notice Remove the limiter role for the address.
     * @param _address Address for removing the limiter role.
     */
    function removeLimiter(address _address) external onlySuperAdmin {
        _removeRole(_address, LIMITER_ROLE);
    }

    // Public functions

    /**
     * @notice Checks if the address is assigned the super admin role.
     * @param _address Address for checking.
     */
    function isSuperAdmin(address _address) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the whitelister role.
     * @param _address Address for checking.
     */
    function isWhitelister(address _address)
        public
        view
        virtual
        returns (bool)
    {
        return hasRole(WHITELISTER_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the freezer role.
     * @param _address Address for checking.
     */
    function isFreezer(address _address) public view virtual returns (bool) {
        return hasRole(FREEZER_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the transporter role.
     * @param _address Address for checking.
     */
    function isTransporter(address _address)
        public
        view
        virtual
        returns (bool)
    {
        return hasRole(TRANSPORTER_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the voter role.
     * @param _address Address for checking.
     */
    function isVoter(address _address) public view virtual returns (bool) {
        return hasRole(VOTER_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the limiter role.
     * @param _address Address for checking.
     */
    function isLimiter(address _address) public view virtual returns (bool) {
        return hasRole(LIMITER_ROLE, _address);
    }

    // Private functions

    /**
     * @notice Add the `_role` for the `_address`.
     * @param _role Role to assigning for the `_address`.
     * @param _address Address for assigning the `_role`.
     */
    function _assignRole(address _address, bytes32 _role) private {
        grantRole(_role, _address);
    }

    /**
     * @notice Remove the `_role` from the `_address`.
     * @param _role Role to removing from the `_address`.
     * @param _address Address for removing the `_role`.
     */
    function _removeRole(address _address, bytes32 _role) private {
        revokeRole(_role, _address);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/EnumerableSet.sol";

import "./Roles.sol";

/**
 * @title STBX | Stobox Technologies Common Stock
 * @author Stobox Technologies Inc.
 * @dev STBX ERC20 Token | This contract is opt for digital securities management.
 */
 
contract STBXToken is IERC20, Roles {
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
                "STBX: not whitelisted address."
            );
        }
        _;
    }

    modifier onlyWithUnfrozenFunds(address _account) {
        require(
            _frozenlist.contains(_account) == false,
            "STBX: funds are frozen."
        );
        _;
    }

    /**
     * @notice STBXToken simply implements a ERC20 token.
     */
    constructor() public Roles(msg.sender) {
        _name = "Stobox Technologies Common Stock";
        _symbol = "STBX";
        _decimals = 0;
        _kDecimals = 18;
        _k = 10**_kDecimals;
        _defaultTransferLimit = 0;
        _defaultTransactionCountLimit = 0;

        _mint(msg.sender, 10000000);
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
        require(balanceOf(_account) >= _amount, "STBX: balance too low");
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
        require(balanceOf(_from) >= _amount, "STBX: not enough tokens");

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
        require(_x != _y, "STBX: _x must not be equal to _y");
        require(_x > 0, "STBX: _x must be greater than 0");
        require(_y > 0, "STBX: _y must be greater than 0");

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
                "STBX: transfer amount exceeds allowance"
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
                "STBX: decreased allowance below zero"
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
        require(_sender != address(0), "STBX: transfer from the zero address");
        require(_recipient != address(0), "STBX: transfer to the zero address");

        _beforeTokenTransfer(_sender, _recipient, _amount);

        _balances[_sender] = _balances[_sender].sub(
            _amount,
            "STBX: transfer amount exceeds balance"
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
        require(_account != address(0), "STBX: mint to the zero address");

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
        require(_account != address(0), "STBX: burn from the zero address");

        _beforeTokenTransfer(_account, address(0), _amount);

        _balances[_account] = _balances[_account].sub(
            _amount,
            "STBX: burn amount exceeds balance"
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
        require(_owner != address(0), "STBX: approve from the zero address");
        require(_spender != address(0), "STBX: approve to the zero address");

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
            .sub(_amount, "STBX: transfer exceeds your transfer limit");
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
                .sub(1, "STBX: transfer exceeds your transaction count limit");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}