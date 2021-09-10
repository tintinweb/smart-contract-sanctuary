/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol


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

// File: contracts/access/Roles.sol

/**
 * @title Roles
 * @notice copied from openzeppelin-solidity
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

// File: contracts/access/WhitelistAdminRole.sol


/**
 * @title WhitelistAdminRole
 * @notice copied from openzeppelin-solidity
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: contracts/access/WhitelistedRole.sol



/**
 * @title WhitelistedRole
 * @notice copied from openzeppelin-solidity
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol


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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


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

// File: contracts/standardTokens/ISecuritiesERC20.sol



/**
 * @dev Interface (in the form of a abstract contract) of an extended ERC20 standard for security tokens.
 */
abstract contract ISecuritiesERC20 is IERC20 {
    /**
    * @notice mint token balance to account
    * @param to     acount of receive minted tokens
    * @param value  amount of tokens to mint
    * @return true if success
    */
    function mint(address to, uint256 value) public virtual returns (bool);

    /**
    * @notice burn token balance from account, must revert if not enough balance
    * @param from   acount of burn token balance from
    * @param value  amount of tokens to burn
    * @return true if success
    */
    function burn(address from, uint256 value) public virtual returns (bool);

    /**
    * @notice Detect if the transfer is not allowed by the transferController
    * @dev Modified from ERC1404
    * @param from       address the ether address of account where the token is coming from
    * @param to         address the ether address of receiver
    * @param initiator  ether address of signer of the transaction
    * @param value      uint256 the amount of token you want to transfer
    * @return 0 if successful, positive integer if error occurred
    */
    function detectTransferRestriction(address from, address to, address initiator, uint256 value) public virtual view returns (uint256);

    /**
    * @notice Lookup a string message represented by a given code
    * @dev Modified from ERC1404
    * @param restrictionCode    uint256 code to lookup for
    * @return string message if code is found, empty string if code is not found
    */
    function messageForTransferRestriction(uint256 restrictionCode) public virtual view returns (string memory);
}

// File: contracts/standardTokens/SecuritiesERC20.sol




/**
 * @notice copied from openzeppelin-solidity, but chaned _name and _synbol to be internal
 * @dev Implementation of the {ISecuritiesERC20} interface.
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
abstract contract SecuritiesERC20 is Context, ISecuritiesERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
    function _mint(address account, uint256 amount) internal virtual {
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
}

// File: contracts/codeDefinitions/CodeDefinitions.sol


/**
 * @title CodeDefinitions
 * @dev This contract returns proper message for a given code
*/
interface CodeDefinitions {

    /**
     * @dev returns proper message for a given code
     * @param code to lookup
     * @return message represented by the given code
     */
    function lookup(uint256 code) external view returns (string memory);
}

// File: contracts/transferController/TransferController.sol


/**
 * @title TransferController
 * @dev This contract contains the logic that enforces KYC transferability rules as outlined by a securities commission
*/
interface TransferController {

    /**
     * @dev Check if tokenAmount of token can be transfered from from address to to address, initiatied by initiator address
     * @param from address the ether address of sender
     * @param to address the ether address of receiver
     * @param initiator ether address of the original transaction initiator
     * @param tokenAddress ether address of the token contract
     * @param tokenAmount uint256 the amount of token you want to transfer
     * @return 0 if successful, positive integer if error occurred
     */
    function check(address from, address to, address initiator, address tokenAddress, uint256 tokenAmount) external view returns (uint256);
}

// File: contracts/transferHook/TransferHook.sol


/**
 * @title TransferHook
 * @dev This hook will be invoked upon token transfer.
*/
interface TransferHook {

    /**
     * @dev hook function invoked when a transfer is determined as good to go
     * @param from address the ether address of sender
     * @param to address the ether address of receiver
     * @param initiator ether address of the original transaction initiator
     * @param tokenAddress ether address of the token contract
     * @param tokenAmount uint256 the amount of token you want to transfer
     */
    function invoke(address from, address to, address initiator, address tokenAddress, uint256 tokenAmount) external;
}

// File: contracts/standardTokens/StandardSecurityToken.sol






/**
 * @title StandardSecurityToken
 * @dev This is the baseline for standard security token to be issued by TokenFunder
*/
contract StandardSecurityToken is SecuritiesERC20, WhitelistedRole {
    using SafeMath for uint256;

    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    mapping (address => uint256) public replayNonce;


    TransferController public _transferController;
    CodeDefinitions public _codeDefinitions;
    TransferHook public _transferHook;

    constructor(
        uint256 totalSupply,
        address transferControllerAddr,
        address codeDefinitionsAddr,
        address transferHookAddr,
        string memory name,
        string memory symbol,
        uint8 decimalsVal
    ) public SecuritiesERC20(name, symbol) {
        require(transferControllerAddr != address(0), "transferControllerAddr not valid");
        require(codeDefinitionsAddr != address(0), "codeDefinitionsAddr not valid ");
        require(transferHookAddr != address(0), "transferHookAddr not valid");

        _transferController = TransferController(transferControllerAddr);
        _codeDefinitions = CodeDefinitions(codeDefinitionsAddr);
        _transferHook = TransferHook(transferHookAddr);

        _setupDecimals(decimalsVal);

        _mint(msg.sender, totalSupply);

        _addWhitelisted(msg.sender);
    }

    /**
    * @dev Transfer requires that no transfer restriction is detected
    */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        // Check for transferrability among white-listed individuals only
        require(detectTransferRestriction(msg.sender, to, msg.sender, value) == 0, "transfer restriction detected");

        super.transfer(to, value);

        _transferHook.invoke(msg.sender, to, msg.sender, address(this), value);
        return true;
    }

    /**
    * @dev TransferFrom requires that no transfer restriction is detected
    */
    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        // Check for transferrability among white-listed individuals only
        require(detectTransferRestriction(from, to, msg.sender, value) == 0, "transfer restriction detected");

        super.transferFrom(from, to, value);

        _transferHook.invoke(from, to, msg.sender, address(this), value);
        return true;
    }


    /**
    * @dev admin of the security token contract (can be another contract) can mint to a specific address
    */
    function mint(address to, uint256 value) public virtual override onlyWhitelisted returns (bool) {
        _mint(to, value);
        emit Mint(to, value);
        return true;
    }

    /**
    * @dev admin of the security token contract (can be another contract) can burn balance from a specific address
    */
    function burn(address from, uint256 value) public virtual override onlyWhitelisted returns (bool) {
        _burn(from, value);
        emit Burn(from, value);
        return true;
    }

    /**
    * @dev Modified from ERC1404
    * Detect if the transfer is not allowed by the transferController
    * @param from address the ether address of account where the token is coming from
    * @param to address the ether address of receiver
    * @param initiator ether address of signer of the transaction
    * @param value uint256 the amount of token you want to transfer
    * @return 0 if successful, positive integer if error occurred
    */
    function detectTransferRestriction(
        address from,
        address to,
        address initiator,
        uint256 value
    ) public virtual override view returns (uint256) {
        return _transferController.check(from, to, initiator, address(this), value);
    }

    /**
    * @dev Modified from ERC1404
    * Lookup a string message represented by a given code
    * @param restrictionCode uint256 code to lookup for
    * @return string message if code is found, empty string if code is not found
    */
    function messageForTransferRestriction(uint256 restrictionCode) public virtual override view returns (string memory) {
        return _codeDefinitions.lookup(restrictionCode);
    }

    /**
    * @dev sets the TransferController contract address, allowing for upgrades of KYC enforcement logic
    * @param transferControllerAddr the address of the new TransferController contract
    */
    function setTransferController(address transferControllerAddr) external onlyWhitelisted {
        require(transferControllerAddr != address(0), "transferControllerAddr not valid");

        _transferController = TransferController(transferControllerAddr);
    }

    /**
    * @dev sets the CodeDefinitions contract address, allowing for upgrades of code to message lookups
    * @param codeDefinitionsAddr the address of the new CodeDefinitions contract
    */
    function setCodeDefinitions(address codeDefinitionsAddr) external onlyWhitelisted {
        require(codeDefinitionsAddr != address(0), "codeDefinitionsAddr not valid");

        _codeDefinitions = CodeDefinitions(codeDefinitionsAddr);
    }

    /**
    * @dev sets the TransferHook contract address, allowing for upgrades of transfer hook functions
    * @param transferHookAddr the address of the new TransferHook contract
    */
    function setTransferHook(address transferHookAddr) external onlyWhitelisted {
        require(transferHookAddr != address(0), "transferHookAddr not valid");

        _transferHook = TransferHook(transferHookAddr);
    }

    /**
    * @dev changes the name, symbol, and decimals of the token
    * @param nameVal new name of the token
    * @param symbolVal new symbol of the token
    * @param decimalsVal new decimals value of the token
    */
    function setTokenMetaInfo(string calldata nameVal, string calldata symbolVal, uint8 decimalsVal) external onlyWhitelisted {
        require(bytes(nameVal).length > 0, "name empty");
        require(bytes(symbolVal).length > 0, "symbol empty");
        require(decimalsVal > 0, "Invalid decimals");

        _name = nameVal;
        _symbol = symbolVal;

        _setupDecimals(decimalsVal);
    }

    /**
    * @dev perform a transfer where initiator transfers on signer's behalf, signer produces signature detailing the transfer request to be taken
    * @param v recovery id, part of signature
    * @param r part of signature
    * @param s part of signature
    * @param from address of the signer
    * @param to recipient of the transfer
    * @param value amount to transfer
    * @param nonce replay nonce of the request
    */
    function metaTransfer(uint8 v, bytes32 r, bytes32 s, address from, address to, uint256 value, uint256 nonce) public returns (bool) {
        bytes32 metaHash = metaTransferHash(to, value, nonce);
        address signer = getSigner(metaHash, v, r, s);

        require(signer == from, "Signer mismatch");
        require(nonce == replayNonce[signer], "Nonce does not match");

        replayNonce[signer] = replayNonce[signer].add(1);

        // Check for transferrability among white-listed individuals only
        require(detectTransferRestriction(signer, to, msg.sender, value) == 0, "transfer restriction detected");

        super._transfer(signer, to, value);

        _transferHook.invoke(signer, to, msg.sender, address(this), value);
        return true;
    }

    /**
    * @dev produce hash that would detail a meta transfer request
    * @param to recipient of the transfer
    * @param value amount to transfer
    * @param nonce replay nonce of the request
    */
    function metaTransferHash(address to, uint256 value, uint256 nonce) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this), "metaTransfer", to, value, nonce));
    }

    /**
    * @dev perform an approve where initiator approves on signer's behalf, signer produces signature detailing the approve request to be taken
    * @param v recovery id, part of signature
    * @param r part of signature
    * @param s part of signature
    * @param from address of the signer
    * @param spender address to be approved
    * @param value amount to approved
    * @param nonce replay nonce of the request
    */
    function metaApprove(uint8 v, bytes32 r, bytes32 s, address from, address spender, uint256 value, uint256 nonce) public returns (bool) {
        bytes32 metaHash = metaApproveHash(spender, value, nonce);
        address signer = getSigner(metaHash, v, r, s);

        require(signer == from, "Signer mismatch");
        require(nonce == replayNonce[signer], "Nonce does not match");

        replayNonce[signer] = replayNonce[signer].add(1);

        super._approve(signer, spender, value);

        return true;
    }

    /**
    * @dev produce hash that would detail a meta approve request
    * @param spender address to be approved
    * @param value amount to be approved
    * @param nonce replay nonce of the request
    */
    function metaApproveHash(address spender, uint256 value, uint256 nonce) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this), "metaApprove", spender, value, nonce));
    }

    /**
    * @dev given a message and a signature, produce the Ethereum account that signed the message
    * @param message original content of the signature
    * @param v recovery id, part of signature
    * @param r part of signature
    * @param s part of signature
    */
    function getSigner(bytes32 message, uint8 v, bytes32 r, bytes32 s) public pure returns (address){
        return ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message)),
            v,
            r,
            s
        );
    }
}