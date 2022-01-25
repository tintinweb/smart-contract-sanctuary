/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// File: openzeppelin-solidity/contracts/GSN/Context.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: @sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Overload/ERC20.sol

pragma solidity 0.5.12;




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

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
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
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance")
        );
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/Pausable.sol

/**
 * @title Pausable
 * @author Team 3301 <[email protected]>
 * @dev Contract module which allows children to implement an emergency stop
 *      mechanism that can be triggered by an authorized account in the TraderOperatorable
 *      contract.
 */
pragma solidity 0.5.12;

contract Pausable {
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    bool internal _paused;

    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by operator to pause child contract. The contract
     *      must not already be paused.
     */
    function pause() public whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /** @dev Called by operator to pause child contract. The contract
     *       must already be paused.
     */
    function unpause() public whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @return If child contract is already paused or not.
     */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @return If child contract is not paused.
     */
    function isNotPaused() public view returns (bool) {
        return !_paused;
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Pausable.sol

/**
 * @title ERC20Pausable
 * @author Team 3301 <[email protected]>
 * @dev Overloading ERC20 functions to ensure that the contract has not been paused.
 */

pragma solidity 0.5.12;

contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev Overload transfer function to ensure contract has not been paused.
     * @param to address that recieves the funds.
     * @param value amount of funds.
     */
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Overload approve function to ensure contract has not been paused.
     * @param spender address that can spend the funds.
     * @param value amount of funds.
     */
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    /**
     * @dev Overload transferFrom function to ensure contract has not been paused.
     * @param from address that funds will be transferred from.
     * @param to address that funds will be transferred to.
     * @param value amount of funds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overload increaseAllowance function to ensure contract has not been paused.
     * @param spender address that will be allowed to transfer funds.
     * @param addedValue amount of funds to added to current allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Overload decreaseAllowance function to ensure contract has not been paused.
     * @param spender address that will be allowed to transfer funds.
     * @param subtractedValue amount of funds to be deducted to current allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Overload _burn function to ensure contract has not been paused.
     * @param account address that funds will be burned from.
     * @param value amount of funds that will be burned.
     */
    function _burn(address account, uint256 value) internal whenNotPaused {
        super._burn(account, value);
    }

    /**
     * @dev Overload _burnFrom function to ensure contract has not been paused.
     * @param account address that funds will be burned from allowance.
     * @param amount amount of funds that will be burned.
     */
    function _burnFrom(address account, uint256 amount) internal whenNotPaused {
        super._burnFrom(account, amount);
    }

    /**
     * @dev Overload _mint function to ensure contract has not been paused.
     * @param account address that funds will be minted to.
     * @param amount amount of funds that will be minted.
     */
    function _mint(address account, uint256 amount) internal whenNotPaused {
        super._mint(account, amount);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Mintable.sol

/**
 * @title ERC20Mintable
 * @author Team 3301 <[email protected]>
 * @dev For blocking and unblocking particular user funds.
 */

pragma solidity 0.5.12;



contract ERC20Mintable is ERC20 {
    /**
     * @dev Overload _mint to ensure only operator or system can mint funds.
     * @param account address that will recieve new funds.
     * @param amount of funds to be minted.
     */
    function _mint(address account, uint256 amount) internal {
        require(amount > 0, "ERC20Mintable: amount has to be greater than 0");
        super._mint(account, amount);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Burnable.sol

/**
 * @title ERC20Burnable
 * @author Team 3301 <[email protected]>
 * @dev For burning funds from particular user addresses.
 */

pragma solidity 0.5.12;



contract ERC20Burnable is ERC20 {
    /**
     * @dev Overload ERC20 _burnFor, burning funds from a particular users address.
     * @param account address to burn funds from.
     * @param amount of funds to burn.
     */

    function _burnFor(address account, uint256 amount) internal {
        super._burn(account, amount);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/Freezable.sol

/**
 * @title Freezable
 * @author Team 3301 <[email protected]>
 * @dev Freezable contract to freeze functionality for particular addresses.  Freezing/unfreezing is controlled
 *       by operators in Operatorable contract which is initialized with the relevant BaseOperators address.
 */

pragma solidity 0.5.12;

contract Freezable {
    mapping(address => bool) public frozen;

    event FreezeToggled(address indexed account, bool frozen);

    /**
     * @dev Reverts if address is empty.
     * @param _address address to validate.
     */
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Freezable: Empty address");
        _;
    }

    /**
     * @dev Reverts if account address is frozen.
     * @param _account address to validate is not frozen.
     */
    modifier whenNotFrozen(address _account) {
        require(!frozen[_account], "Freezable: account is frozen");
        _;
    }

    /**
     * @dev Reverts if account address is not frozen.
     * @param _account address to validate is frozen.
     */
    modifier whenFrozen(address _account) {
        require(frozen[_account], "Freezable: account is not frozen");
        _;
    }

    /**
     * @dev Getter to determine if address is frozen.
     * @param _account address to determine if frozen or not.
     * @return bool is frozen
     */
    function isFrozen(address _account) public view returns (bool) {
        return frozen[_account];
    }

    /**
     * @dev Toggle freeze/unfreeze on _account address, with _toggled being true/false.
     * @param _account address to toggle.
     * @param _toggled freeze/unfreeze.
     */
    function toggleFreeze(address _account, bool _toggled) public {
        frozen[_account] = _toggled;
        emit FreezeToggled(_account, _toggled);
    }

    /**
     * @dev Batch freeze/unfreeze multiple addresses, with _toggled being true/false.
     * @param _addresses address array.
     * @param _toggled freeze/unfreeze.
     */
    function batchToggleFreeze(address[] memory _addresses, bool _toggled) public {
        require(_addresses.length <= 256, "Freezable: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            toggleFreeze(_addresses[i], _toggled);
        }
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Freezable.sol

/**
 * @title ERC20Freezable
 * @author Team 3301 <[email protected]>
 * @dev Overloading ERC20 functions to ensure client addresses are not frozen for particular actions.
 */

pragma solidity 0.5.12;



contract ERC20Freezable is ERC20, Freezable {
    /**
     * @dev Overload transfer function to ensure sender and receiver have not been frozen.
     * @param to address that recieves the funds.
     * @param value amount of funds.
     */
    function transfer(address to, uint256 value) public whenNotFrozen(msg.sender) whenNotFrozen(to) returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Overload approve function to ensure sender and receiver have not been frozen.
     * @param spender address that can spend the funds.
     * @param value amount of funds.
     */
    function approve(address spender, uint256 value)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.approve(spender, value);
    }

    /**
     * @dev Overload transferFrom function to ensure sender, approver and receiver have not been frozen.
     * @param from address that funds will be transferred from.
     * @param to address that funds will be transferred to.
     * @param value amount of funds.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public whenNotFrozen(msg.sender) whenNotFrozen(from) whenNotFrozen(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Overload increaseAllowance function to ensure sender and spender have not been frozen.
     * @param spender address that will be allowed to transfer funds.
     * @param addedValue amount of funds to added to current allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Overload decreaseAllowance function to ensure sender and spender have not been frozen.
     * @param spender address that will be allowed to transfer funds.
     * @param subtractedValue amount of funds to be deducted to current allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotFrozen(msg.sender)
        whenNotFrozen(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Overload _burnfrom function to ensure sender and user to be burned from have not been frozen.
     * @param account account that funds will be burned from.
     * @param amount amount of funds to be burned.
     */
    function _burnFrom(address account, uint256 amount) internal whenNotFrozen(msg.sender) whenNotFrozen(account) {
        super._burnFrom(account, amount);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/ERC20/ERC20Destroyable.sol

/**
 * @title ERC20Destroyable
 * @author Team 3301 <[email protected]>
 * @notice Allows operator to destroy contract.
 */

pragma solidity 0.5.12;


contract ERC20Destroyable {
    event Destroyed(address indexed caller, address indexed account, address indexed contractAddress);

    function destroy(address payable to) public {
        emit Destroyed(msg.sender, to, address(this));
        selfdestruct(to);
    }
}




// File: contracts/token/SygnumToken.sol

/**
 * @title SygnumToken
 * @author Team 3301 <[email protected]>
 * @notice ERC20 token with additional features.
 */

pragma solidity 0.5.12;

contract TestToken is
    ERC20Pausable,
    ERC20Mintable,
    ERC20Burnable,
    ERC20Freezable,
    ERC20Destroyable
{
    event Minted(address indexed minter, address indexed account, uint256 value);
    event Burned(address indexed burner, uint256 value);
    event BurnedFor(address indexed burner, address indexed account, uint256 value);
    event Confiscated(address indexed account, uint256 amount, address indexed receiver);
    event UpdateName(address indexed account, string name);
    event UpdateSymbol(address indexed account, string symbol);
    event UpdateClass(address indexed account, string class);
    event UpdateIssuer(address indexed account, address indexed issuer);
    event UpdateCategory(address indexed account, bytes4 category);
    event UpdateTokenURI(address indexed account, string tokenURI);


    uint16 internal constant BATCH_LIMIT = 256;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    string internal _class;
    address internal _issuer;
    bytes4 internal _category;
    string internal _tokenURI;

    constructor() public {
        _name = 'zzz External Token by Vlad';
        _symbol = 'ZZZA';
        _decimals = 2;
    }

    function confiscate(uint256 _amount, address _account) public {
        require(!isFrozen(msg.sender), "SygnumToken: Account must not be frozen.");
        emit Confiscated(msg.sender, _amount, _account);
    }

    /**
     * @dev Burn.
     * @param _amount Amount of tokens to burn.
     */
    function burn(uint256 _amount) public {
        require(!isFrozen(msg.sender), "SygnumToken: Account must not be frozen.");
        super._burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    /**
     * @dev BurnFor.
     * @param _account Address to burn tokens for.
     * @param _amount Amount of tokens to burn.
     */
    function burnFor(address _account, uint256 _amount) public {
        super._burnFor(_account, _amount);
        emit BurnedFor(msg.sender, _account, _amount);
    }

    /**
     * @dev BurnFrom.
     * @param _account Address to burn tokens from.
     * @param _amount Amount of tokens to burn.
     */
    function burnFrom(address _account, uint256 _amount) public {
        super._burnFrom(_account, _amount);
        emit Burned(_account, _amount);
    }

    /**
     * @dev Mint.
     * @param _account Address to mint tokens to.
     * @param _amount Amount to mint.
     */
    function mint(address _account, uint256 _amount) public {
        super._mint(_account, _amount);
        emit Minted(msg.sender, _account, _amount);
    }

    /**
     * @dev Batch burn for.
     * @param _amounts Array of all values to burn.
     * @param _accounts Array of all addresses to burn from.
     */
    function batchBurnFor(address[] memory _accounts, uint256[] memory _amounts) public {
        require(_accounts.length == _amounts.length, "SygnumToken: values and recipients are not equal.");
        require(_accounts.length <= BATCH_LIMIT, "SygnumToken: batch count is greater than BATCH_LIMIT.");
        for (uint256 i = 0; i < _accounts.length; i++) {
            burnFor(_accounts[i], _amounts[i]);
        }
    }

    /**
     * @dev Batch mint.
     * @param _accounts Array of all addresses to mint to.
     * @param _amounts Array of all values to mint.
     */
    function batchMint(address[] memory _accounts, uint256[] memory _amounts) public {
        require(_accounts.length == _amounts.length, "SygnumToken: values and recipients are not equal.");
        require(_accounts.length <= BATCH_LIMIT, "SygnumToken: batch count is greater than BATCH_LIMIT.");
        for (uint256 i = 0; i < _accounts.length; i++) {
            mint(_accounts[i], _amounts[i]);
        }
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    function updateName(string memory newName) public {
        _name = newName;
        emit UpdateName(msg.sender, newName);
    } 

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function updateSymbol(string memory newSymbol) public {
        _symbol = newSymbol;
        emit UpdateSymbol(msg.sender, newSymbol);
    }

    function class() public view returns (string memory) {
        return _class;
    }

    function updateClass(string memory newClass) public {
        _class = newClass;
        emit UpdateClass(msg.sender, newClass);
    }

    function issuer() public view returns (address) {
        return _issuer;
    }

    function updateIssuer(address newIssuer) public {
        _issuer = newIssuer;
        emit UpdateIssuer(msg.sender, newIssuer);
    }

    function category() public view returns (bytes4) {
        return _category;
    }

    function updateCategory(bytes4 newCategory) public {
        _category = newCategory;
        emit UpdateCategory(msg.sender, newCategory);
    }

    function tokenURI() public view returns (string memory) {
        return _tokenURI;
    }

    function updateTokenURI(string memory newTokenURI) public {
        _tokenURI = newTokenURI;
        emit UpdateTokenURI(msg.sender, newTokenURI);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}