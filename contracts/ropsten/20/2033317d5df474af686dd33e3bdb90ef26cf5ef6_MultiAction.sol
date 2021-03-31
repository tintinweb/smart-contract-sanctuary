/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/roles/OwnerRole.sol

pragma solidity 0.5.8;


contract OwnerRole {
    using Roles for Roles.Role;

    event OwnerAdded(address indexed addedOwner, address indexed addedBy);
    event OwnerRemoved(address indexed removedOwner, address indexed removedBy);

    Roles.Role private _owners;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "OwnerRole: caller does not have the Owner role");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return _owners.has(account);
    }

    function addOwner(address account) public onlyOwner {
        _addOwner(account);
    }

    function removeOwner(address account) public onlyOwner {
        require(msg.sender != account, "Owners cannot remove themselves as owner");
        _removeOwner(account);
    }

    function _addOwner(address account) internal {
        _owners.add(account);
        emit OwnerAdded(account, msg.sender);
    }

    function _removeOwner(address account) internal {
        _owners.remove(account);
        emit OwnerRemoved(account, msg.sender);
    }
}

// File: contracts/1404/IERC1404.sol

pragma solidity 0.5.8;

interface IERC1404 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value) external view returns (uint8);

    /// @notice Detects if a transferFrom will be reverted and if so returns an appropriate reference code
    /// @param sender Transaction sending address
    /// @param from Source of funds address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferFromRestriction (address sender, address from, address to, uint256 value) external view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode) external view returns (string memory);
}

interface IERC1404getSuccessCode {
    /// @notice Return the uint256 that represents the SUCCESS_CODE
    /// @return uint256 SUCCESS_CODE
    function getSuccessCode () external view returns (uint256);
}

/**
 * @title IERC1404Success
 * @dev Combines IERC1404 and IERC1404getSuccessCode interfaces, to be implemented by the TransferRestrictions contract
 */
contract IERC1404Success is IERC1404getSuccessCode, IERC1404 {
}

// File: contracts/1404/IERC1404Validators.sol

pragma solidity 0.5.8;

/**
 * @title IERC1404Validators
 * @dev Interfaces implemented by the token contract to be called by the TransferRestrictions contract
 */
interface IERC1404Validators {
    /// @notice Returns the token balance for an account
    /// @param account The address to get the token balance of
    /// @return uint256 representing the token balance for the account
    function balanceOf (address account) external view returns (uint256);

    /// @notice Returns a boolean indicating the paused state of the contract
    /// @return true if contract is paused, false if unpaused
    function paused () external view returns (bool);

    /// @notice Determine if sender and receiver are whitelisted, return true if both accounts are whitelisted
    /// @param from The address sending tokens.
    /// @param to The address receiving tokens.
    /// @return true if both accounts are whitelisted, false if not
    function checkWhitelists (address from, address to) external view returns (bool);

    /// @notice Determine if a users tokens are locked preventing a transfer
    /// @param _address the address to retrieve the data from
    /// @param amount the amount to send
    /// @param balance the token balance of the sending account
    /// @return true if user has sufficient unlocked token to transfer the requested amount, false if not
    function checkTimelock (address _address, uint256 amount, uint256 balance) external view returns (bool);
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: contracts/roles/RevokerRole.sol

pragma solidity 0.5.8;


contract RevokerRole is OwnerRole {

    event RevokerAdded(address indexed addedRevoker, address indexed addedBy);
    event RevokerRemoved(address indexed removedRevoker, address indexed removedBy);

    Roles.Role private _revokers;

    modifier onlyRevoker() {
        require(isRevoker(msg.sender), "RevokerRole: caller does not have the Revoker role");
        _;
    }

    function isRevoker(address account) public view returns (bool) {
        return _revokers.has(account);
    }

    function addRevoker(address account) public onlyOwner {
        _addRevoker(account);
    }

    function removeRevoker(address account) public onlyOwner {
        _removeRevoker(account);
    }

    function _addRevoker(address account) internal {
        _revokers.add(account);
        emit RevokerAdded(account, msg.sender);
    }

    function _removeRevoker(address account) internal {
        _revokers.remove(account);
        emit RevokerRemoved(account, msg.sender);
    }
}

// File: contracts/capabilities/Revocable.sol

pragma solidity 0.5.8;



/**
 * Allows an administrator to move tokens from a target account to their own.
 */
contract Revocable is ERC20, RevokerRole {

  event Revoke(address indexed revoker, address indexed from, uint256 amount);

  function revoke(
    address _from,
    uint256 _amount
  )
    public
    onlyRevoker
    returns (bool)
  {
    ERC20._transfer(_from, msg.sender, _amount);
    emit Revoke(msg.sender, _from, _amount);
    return true;
  }
}

// File: contracts/roles/WhitelisterRole.sol

pragma solidity 0.5.8;


contract WhitelisterRole is OwnerRole {

    event WhitelisterAdded(address indexed addedWhitelister, address indexed addedBy);
    event WhitelisterRemoved(address indexed removedWhitelister, address indexed removedBy);

    Roles.Role private _whitelisters;

    modifier onlyWhitelister() {
        require(isWhitelister(msg.sender), "WhitelisterRole: caller does not have the Whitelister role");
        _;
    }

    function isWhitelister(address account) public view returns (bool) {
        return _whitelisters.has(account);
    }

    function addWhitelister(address account) public onlyOwner {
        _addWhitelister(account);
    }

    function removeWhitelister(address account) public onlyOwner {
        _removeWhitelister(account);
    }

    function _addWhitelister(address account) internal {
        _whitelisters.add(account);
        emit WhitelisterAdded(account, msg.sender);
    }

    function _removeWhitelister(address account) internal {
        _whitelisters.remove(account);
        emit WhitelisterRemoved(account, msg.sender);
    }
}

// File: contracts/capabilities/Whitelistable.sol

pragma solidity 0.5.8;


/**
 * @title Whitelistable
 * @dev Allows tracking whether addressess are allowed to hold tokens.
 */
contract Whitelistable is WhitelisterRole {

    event WhitelistUpdate(address _address, bool status, string data);

    // Tracks whether an address is whitelisted
    // data field can track any external field (like a hash of personal details)
    struct whiteListItem {
        bool status;
        string data;
    }

    // white list status
    mapping (address => whiteListItem) public whitelist;

    /**
    * @dev Set a white list address
    * @param to the address to be set
    * @param status the whitelisting status (true for yes, false for no)
    * @param data a string with data about the whitelisted address
    */
    function setWhitelist(address to, bool status, string memory data)  public onlyWhitelister returns(bool){
        whitelist[to] = whiteListItem(status, data);
        emit WhitelistUpdate(to, status, data);
        return true;
    }

    /**
    * @dev Get the status of the whitelist
    * @param _address the address to be check
    */
    function getWhitelistStatus(address _address) public view returns(bool){
        return whitelist[_address].status;
    }

    /**
    * @dev Get the data of and address in the whitelist
    * @param _address the address to retrieve the data from
    */
    function getWhitelistData(address _address) public view returns(string memory){
        return whitelist[_address].data;
    }

    /**
    * @dev Determine if sender and receiver are whitelisted, return true if both accounts are whitelisted
    * @param from The address sending tokens.
    * @param to The address receiving tokens.
    */
    function checkWhitelists(address from, address to) external view returns (bool) {
        return whitelist[from].status && whitelist[to].status;
    }
}

// File: contracts/roles/TimelockerRole.sol

pragma solidity 0.5.8;


contract TimelockerRole is OwnerRole {

    event TimelockerAdded(address indexed addedTimelocker, address indexed addedBy);
    event TimelockerRemoved(address indexed removedTimelocker, address indexed removedBy);

    Roles.Role private _timelockers;

    modifier onlyTimelocker() {
        require(isTimelocker(msg.sender), "TimelockerRole: caller does not have the Timelocker role");
        _;
    }

    function isTimelocker(address account) public view returns (bool) {
        return _timelockers.has(account);
    }

    function addTimelocker(address account) public onlyOwner {
        _addTimelocker(account);
    }

    function removeTimelocker(address account) public onlyOwner {
        _removeTimelocker(account);
    }

    function _addTimelocker(address account) internal {
        _timelockers.add(account);
        emit TimelockerAdded(account, msg.sender);
    }

    function _removeTimelocker(address account) internal {
        _timelockers.remove(account);
        emit TimelockerRemoved(account, msg.sender);
    }
}

// File: contracts/capabilities/Timelockable.sol

pragma solidity 0.5.8;



/**
 * @title INX Timelockable
 * @dev Lockup all or a portion of an accounts tokens until an expiration date
 */
contract Timelockable is TimelockerRole {

    using SafeMath for uint256;

    struct lockupItem {
        uint256 amount;
        uint256 releaseTime;
    }

    mapping (address => lockupItem) lockups;

    event AccountLock(address _address, uint256 amount, uint256 releaseTime);
    event AccountRelease(address _address, uint256 amount);


    /**
    * @dev lock address and amount and lock it, set the release time
    * @param _address the address to lock
    * @param amount the amount to lock
    * @param releaseTime of the locked amount (in seconds since the epoch)
    */
    function lock( address _address, uint256 amount, uint256 releaseTime) public onlyTimelocker returns (bool) {
        require(releaseTime > block.timestamp, "Release time needs to be in the future");
        require(_address != address(0), "Address must be valid for lockup");

        lockupItem memory _lockupItem = lockupItem(amount, releaseTime);
        lockups[_address] = _lockupItem;
        emit AccountLock(_address, amount, releaseTime);
        return true;
    }

    /**
    * @dev release locked amount
    * @param _address the address to retrieve the data from
    * @param amountToRelease the amount to check
    */
    function release( address _address, uint256 amountToRelease) public onlyTimelocker returns(bool) {
        require(_address != address(0), "Address must be valid for release");

        uint256 _lockedAmount = lockups[_address].amount;

        // nothing to release
        if(_lockedAmount == 0){
            emit AccountRelease(_address, 0);
            return true;
        }

        // extract release time for re-locking
        uint256 _releaseTime = lockups[_address].releaseTime;

        // delete the lock entry
        delete lockups[_address];

        if(_lockedAmount >= amountToRelease){
           uint256 newLockedAmount = _lockedAmount.sub(amountToRelease);

           // re-lock the new locked balance
           lock(_address, newLockedAmount, _releaseTime);
           emit AccountRelease(_address, amountToRelease);
           return true;
        } else {
            // if they requested to release more than the locked amount emit the event with the locked amount that has been released
            emit AccountRelease(_address, _lockedAmount);
            return true;
        }
    }

    /**
    * @dev return true if the given account has enough unlocked tokens to send the requested amount
    * @param _address the address to retrieve the data from
    * @param amount the amount to send
    * @param balance the token balance of the sending account
    */
    function checkTimelock(address _address, uint256 amount, uint256 balance) external view returns (bool) {
        // if the user does not have enough tokens to send regardless of lock return true here
        // the failure will still fail but this should make it explicit that the transfer failure is not
        // due to locked tokens but because of too low token balance
        if (balance < amount) {
            return true;
        }

        // get the sending addresses token balance that is not locked
        uint256 nonLockedAmount = balance.sub(lockups[_address].amount);

        // determine if the sending address has enough free tokens to send the entire amount
        bool notLocked = amount <= nonLockedAmount;

        // if the timelock is greater then the release time the time lock is expired
        bool timeLockExpired = block.timestamp > lockups[_address].releaseTime;

        // if the timelock is expired OR the requested amount is available the transfer is not locked
        if(timeLockExpired || notLocked){
            return true;

        // if the timelocked is not expired AND the requested amount is not available the tranfer is locked
        } else {
            return false;
        }
    }

    /**
    * @dev get address lockup info
    * @param _address the address to retrieve the data from
    * @return array of 2 uint256, release time (in seconds since the epoch) and amount (in INX)
    */
    function checkLockup(address _address) public view returns(uint256, uint256) {
        // copy lockup data into memory
        lockupItem memory _lockupItem = lockups[_address];

        return (_lockupItem.releaseTime, _lockupItem.amount);
    }
}

// File: contracts/roles/PauserRole.sol

pragma solidity 0.5.8;


contract PauserRole is OwnerRole {

    event PauserAdded(address indexed addedPauser, address indexed addedBy);
    event PauserRemoved(address indexed removedPauser, address indexed removedBy);

    Roles.Role private _pausers;

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function removePauser(address account) public onlyOwner {
        _removePauser(account);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account, msg.sender);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account, msg.sender);
    }
}

// File: contracts/capabilities/Pausable.sol

pragma solidity 0.5.8;


/**
 * Allows transfers on a token contract to be paused by an administrator.
 */
contract Pausable is PauserRole {
    event Paused();
    event Unpaused();

    bool private _paused;

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev internal function, triggers paused state
     */
    function _pause() internal {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev internal function, returns to unpaused state
     */
    function _unpause() internal {
        _paused = false;
        emit Unpaused();
    }

     /**
     * @dev called by pauser role to pause, triggers stopped state
     */
    function pause() public onlyPauser {
        _pause();
    }

    /**
     * @dev called by pauer role to unpause, returns to normal state
     */
    function unpause() public onlyPauser {
        _unpause();
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/InxToken.sol

pragma solidity 0.5.8;











contract InxToken is IERC1404, IERC1404Validators, IERC20, ERC20Detailed, OwnerRole, Revocable, Whitelistable, Timelockable, Pausable {

    // Token Details
    string constant TOKEN_NAME = "INX Token";
    string constant TOKEN_SYMBOL = "INX";
    uint8 constant TOKEN_DECIMALS = 18;

    // Token supply - 2 Hundred Million Tokens, with 18 decimal precision
    uint256 constant HUNDRED_MILLION = 100000000;
    uint256 constant TOKEN_SUPPLY = 2 * HUNDRED_MILLION * (10 ** uint256(TOKEN_DECIMALS));

    // This tracks the external contract where restriction logic is executed
    IERC1404Success private transferRestrictions;

    // Event tracking when restriction logic contract is updated
    event RestrictionsUpdated (address newRestrictionsAddress, address updatedBy);

    /**
    Constructor for the token to set readable details and mint all tokens
    to the specified owner.
    */
    constructor(address owner) public
        ERC20Detailed(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS)
    {
        _mint(owner, TOKEN_SUPPLY);
        _addOwner(owner);
    }

    /**
    Function that can only be called by an owner that updates the address
    with the ERC1404 Transfer Restrictions defined
    */
    function updateTransferRestrictions(address _newRestrictionsAddress)
        public
        onlyOwner
        returns (bool)
    {
        transferRestrictions = IERC1404Success(_newRestrictionsAddress);
        emit RestrictionsUpdated(address(transferRestrictions), msg.sender);
        return true;
    }

    /**
    The address with the Transfer Restrictions contract
    */
    function getRestrictionsAddress () public view returns (address) {
        return address(transferRestrictions);
    }


    /**
    This function detects whether a transfer should be restricted and not allowed.
    If the function returns SUCCESS_CODE (0) then it should be allowed.
    */
    function detectTransferRestriction (address from, address to, uint256 amount)
        public
        view
        returns (uint8)
    {
        // Verify the external contract is valid
        require(address(transferRestrictions) != address(0), 'TransferRestrictions contract must be set');

        // call detectTransferRestriction on the current transferRestrictions contract
        return transferRestrictions.detectTransferRestriction(from, to, amount);
    }

    /**
    This function detects whether a transferFrom should be restricted and not allowed.
    If the function returns SUCCESS_CODE (0) then it should be allowed.
    */
    function detectTransferFromRestriction (address sender, address from, address to, uint256 amount)
        public
        view
        returns (uint8)
    {
        // Verify the external contract is valid
        require(address(transferRestrictions) != address(0), 'TransferRestrictions contract must be set');

        // call detectTransferFromRestriction on the current transferRestrictions contract
        return  transferRestrictions.detectTransferFromRestriction(sender, from, to, amount);
    }

    /**
    This function allows a wallet or other client to get a human readable string to show
    a user if a transfer was restricted.  It should return enough information for the user
    to know why it failed.
    */
    function messageForTransferRestriction (uint8 restrictionCode)
        external
        view
        returns (string memory)
    {
        // call messageForTransferRestriction on the current transferRestrictions contract
        return transferRestrictions.messageForTransferRestriction(restrictionCode);
    }

    /**
    Evaluates whether a transfer should be allowed or not.
    */
    modifier notRestricted (address from, address to, uint256 value) {
        uint8 restrictionCode = transferRestrictions.detectTransferRestriction(from, to, value);
        require(restrictionCode == transferRestrictions.getSuccessCode(), transferRestrictions.messageForTransferRestriction(restrictionCode));
        _;
    }

    /**
    Evaluates whether a transferFrom should be allowed or not.
    */
    modifier notRestrictedTransferFrom (address sender, address from, address to, uint256 value) {
        uint8 transferFromRestrictionCode = transferRestrictions.detectTransferFromRestriction(sender, from, to, value);
        require(transferFromRestrictionCode == transferRestrictions.getSuccessCode(), transferRestrictions.messageForTransferRestriction(transferFromRestrictionCode));
        _;
    }

    /**
    Overrides the parent class token transfer function to enforce restrictions.
    */
    function transfer (address to, uint256 value)
        public
        notRestricted(msg.sender, to, value)
        returns (bool success)
    {
        success = ERC20.transfer(to, value);
    }

    /**
    Overrides the parent class token transferFrom function to enforce restrictions.
    */
    function transferFrom (address from, address to, uint256 value)
        public
        notRestrictedTransferFrom(msg.sender, from, to, value)
        returns (bool success)
    {
        success = ERC20.transferFrom(from, to, value);
    }
}

// File: contracts/multiAction.sol

pragma solidity 0.5.8;



contract MultiAction is OwnerRole {

  InxToken token;

  /**
   * Sets the owner and the token address
   */
  constructor(address _owner, InxToken _token) public
  {
      _addOwner(_owner);
      token = _token;
  }

  /**
   * Internal function to sweep token balance
   */
  function _sweep(address sweeepTo) internal {
    token.transfer(sweeepTo, token.balanceOf(address(this)));
  }

  /**
   * Owners can sweep any tokens
   */
  function sweep() public onlyOwner {
    _sweep(msg.sender);
  }

  /**
   * Owners can bulk revoke
   */
  function multiRevoke(address[] memory fromAddresses, uint256[] memory amounts) public onlyOwner {
    require(fromAddresses.length == amounts.length, "Invalid array length");

    for(uint i = 0 ; i < fromAddresses.length; i++) {
      token.revoke(fromAddresses[i], amounts[i]);
    }
    _sweep(msg.sender);
  }

  /**
   * Owners can bulk set whitelists
   */
  function multiWhitelist(address[] memory addresses, bool[] memory statuses) public onlyOwner {
    require(addresses.length == statuses.length, "Invalid array length");

    for(uint i = 0 ; i < addresses.length; i++) {
      token.setWhitelist(addresses[i], statuses[i], "");
    }
  }

  /**
   * Owners can bulk transfer
   */
  function multiSend(address[] memory addresses, uint256[] memory amounts) public onlyOwner {
    require(addresses.length == amounts.length, "Invalid array length");

    for(uint i = 0 ; i < addresses.length; i++) {
      token.transferFrom(msg.sender, addresses[i], amounts[i]);
    }
  }
}