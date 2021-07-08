/**
 *Submitted for verification at Etherscan.io on 2021-07-07
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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

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

// File: openzeppelin-solidity/contracts/access/Roles.sol

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

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol

pragma solidity ^0.5.0;


/**
 * @dev Extension of {ERC20Mintable} that adds a cap to the supply of tokens.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20Mintable-mint}.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// File: @uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: contracts/IWETH9.sol

pragma solidity ^0.5.17;

// https://ethereum.stackexchange.com/questions/56466/wrapping-eth-calling-the-weth-contract

contract WETH9_ {
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() external payable ;
    function deposit() external payable ;
    function withdraw(uint wad) external ;
    function totalSupply() external view returns (uint) ;

    function approve(address guy, uint wad) external returns (bool) ;

    function transfer(address dst, uint wad) external returns (bool) ;

    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// File: contracts/Quado.sol

pragma solidity >=0.5.0;










/**
@title Quado: The Holobots Coin
@dev ERC20 Token to be used as in-world money for the Holobots.world.
 * Supports UniSwap to ETH and off-chain deposit/cashout.
 * Pre-mints locked funds for liquidity pool bootstrap, developer incentives and infrastructure coverage.
 * Approves payout to developers for each 10% of all minted bots, monthly infrastructre costs.
 * Bootstrap approved to transfer on creation.
 */
contract Quado is ERC20, ERC20Detailed, ERC20Mintable, ERC20Capped, Ownable, IUniswapV3SwapCallback {

    //address god;
    uint256 public gasToCashOut = 23731;
    uint256 public gasToCashOutToEth = 43731;
    uint256 public currentInfrastructureCosts = 200000 * 10**18;

    uint256 public percentBootstrap;
    uint256 public percentDevteam;
    uint256 public percentInfrastructureFund;
    
    uint public lastInfrastructureGrand;
    
    IUniswapV3PoolActions quadoEthUniswapPool;
    address payable public quadoEthUniswapPoolAddress;
    bool quadoEthUniswapPoolToken0IsQuado;

    address public devTeamPayoutAdress;
    address public infrastructurePayoutAdress;
    uint256 public usedForInfrstructure;

    WETH9_ internal WETH;

    /**  
    * @dev Emited when funds for the owner gets approved to be taken from the contract
    **/
    event OwnerFundsApproval (
        uint16 eventType,
        uint256 indexed amount
    );

    /**  
    * @dev Emited to swap quado cash/quado coin/eth
    **/
    event SwapEvent (
        uint16 eventType,
        address indexed owner,
        uint256 indexed ethValue,
        uint256 indexed coinAmount
    );

    struct SwapData { 
        uint8 eventType;
        address payable account;
    }

    /**  
    * @dev 
    * @param _maxSupply Max supply of coins
    * @param _percentBootstrap How many percent of the currency are reserved for the bootstrap
    * @param _percentDevteam How many percent of the currency are reserved for dev incentives
    * @param _percentInfrastructureFund How many percent of the currency is reserved to fund infrastcture during game pre-launch
    **/
    constructor(
        uint256 _maxSupply,
        uint256 _percentBootstrap,
        uint256 _percentDevteam,
        uint256 _percentInfrastructureFund,
        address _bootstrapPayoutAdress,
        address payable _WETHAddr
    ) public ERC20Detailed("Quado Holobots Coin", "OOOO", 18) 
        ERC20Capped(_maxSupply)
    { 
        require(_WETHAddr != address(0), "WETH is the zero address");
        require(_bootstrapPayoutAdress != address(0), "bootstrap_payout is the zero address");

        WETH = WETH9_(_WETHAddr);

        // Bootstrap is a stash of coins to provide initial liquidity to the uniswap pool and launch campiagn
        percentBootstrap = _percentBootstrap;
        
        // Developer team coverage
        percentDevteam = _percentDevteam;

        // Funds to cover the expenses for run the infrastructre until launch
        percentInfrastructureFund = _percentInfrastructureFund;
        usedForInfrstructure = 0;
        lastInfrastructureGrand = now;

        // Mint the pre-mine
        mintOwnerFundsTo((_maxSupply/100)*percentBootstrap, _bootstrapPayoutAdress);
        emit OwnerFundsApproval(0, (_maxSupply/100)*percentBootstrap);
    }

    /**
     * @dev ETH to Quado Cash
     */
    function toQuadoCash(uint160 sqrtPriceLimitX96) public payable {
        wrap(msg.value);
        WETH.approve(quadoEthUniswapPoolAddress, msg.value);

        // → coinswap ETH/OOOO 
        // docs: https://docs.uniswap.org/reference/core/interfaces/pool/IUniswapV3PoolActions
        /*
          swap( address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes data) external returns (int256 amount0, int256 amount1)
         */
        quadoEthUniswapPool.swap(address(this), !quadoEthUniswapPoolToken0IsQuado, int256(msg.value), sqrtPriceLimitX96, swapDataToBytes(SwapData(2, msg.sender)));
    }

    /**
     * @dev ETH to Quado Coin
     */
    function toQuadoCoin(uint160 sqrtPriceLimitX96) public payable {
        
        wrap(msg.value);
        WETH.approve(quadoEthUniswapPoolAddress, msg.value);

        // → coinswap ETH/OOOO
        quadoEthUniswapPool.swap(address(this), !quadoEthUniswapPoolToken0IsQuado, int256(msg.value), sqrtPriceLimitX96, swapDataToBytes(SwapData(4, msg.sender)));
    }

    /**
     * @dev Quado Coin to ETH
     * @param _amount amount of quado to swap to eth
     */
    function toETH(uint256 _amount, uint160 sqrtPriceLimitX96) public {
        
        require(_amount <= balanceOf(msg.sender), 'low_balance');
        _approve(msg.sender, quadoEthUniswapPoolAddress, _amount);

        // → coinswap OOOO/ETH
        quadoEthUniswapPool.swap(address(this), quadoEthUniswapPoolToken0IsQuado, int256(_amount), sqrtPriceLimitX96, swapDataToBytes(SwapData(3, msg.sender)));
    }

    function wrap(uint256 ETHAmount) private 
    {
        //create WETH from ETH
        if (ETHAmount != 0) {
            WETH.deposit.value(ETHAmount)();
        }   
        require(WETH.balanceOf(address(this)) >= ETHAmount, "eth_not_deposited");
    }

    function unwrap(uint256 Amount) private 
    {
        if (Amount != 0) {
            WETH.withdraw(Amount);
        }
    }

    // default method when ether is paid to the contract's address
    // used for the WETH withdraw callback
    function() external payable {
        
    }


    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
            addr := div( mload( add(bys, 32) ), 0x1000000000000000000000000)
        }
    }

    //  https://ethereum.stackexchange.com/questions/11246/convert-struct-to-bytes-in-solidity
    function swapDataFromBytes(bytes memory data) private pure returns (SwapData memory d) {
        d.eventType = uint8(data[20]);
        bytes memory adr20 = new bytes(20);
        for (uint i=0;i<20;i++) {
            adr20[i]=data[i];
        }
        d.account = bytesToAddress(adr20);
    }

    function swapDataToBytes(SwapData memory swapData) private pure returns (bytes memory data) {
        
        uint _size = 1 + 20;
        bytes memory _data = new bytes(_size);
        
        _data[20] = byte(swapData.eventType);
        uint counter=0;
        bytes20 adr = bytes20(address(swapData.account));
        for (uint i=0;i<20;i++) {
            _data[counter]=adr[i];
            counter++;
        }
        return (_data);
    }

    /**
     * @dev Uniswap swap callback, satisfy IUniswapV3SwapCallback
     * https://docs.uniswap.org/reference/core/interfaces/callback/IUniswapV3SwapCallback 
     */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        
        require(msg.sender == quadoEthUniswapPoolAddress, 'uni_sender');

        SwapData memory swapData = swapDataFromBytes(data);

        require(swapData.eventType > 0, 'swap_data_type');
        require((amount0Delta > 0) || (amount1Delta > 0), 'delta_pos');

        int256 quadoAmount = quadoEthUniswapPoolToken0IsQuado ? amount0Delta : amount1Delta;
        int256 ethAmount = quadoEthUniswapPoolToken0IsQuado ? amount1Delta : amount0Delta;

        if(quadoAmount > 0) {
            // OOOO is needed by the pool, means quado to ETH
            require(uint256(quadoAmount) <= balanceOf(swapData.account), 'owner_oooo_bal');
            transferFrom(swapData.account, msg.sender, uint256(quadoAmount));
            
            // pay the owner the ETH he got
            // UNWRAP WETH
            // https://ethereum.stackexchange.com/questions/83929/while-testing-wrap-unwrap-of-eth-to-weth-on-kovan-however-the-wrap-function-i
            unwrap(uint256(-ethAmount));
            swapData.account.transfer( uint256(-ethAmount)); //, 'eth_to_acc');
            
            emit SwapEvent(3, swapData.account, uint256(ethAmount), uint256(quadoAmount));

        } else if(ethAmount > 0) {
            // ETH is needed, means eth to quado cash (eventType 2) or coin (eventType 4)
            //require(uint256(amount0Delta) <= address(this).balance, 'contract_eth_bal');
            require(WETH.balanceOf(address(this)) >= uint256(ethAmount), 'contract_weth_bal');
            
            // Transfer WRAPPED ETH to contract
            WETH.transfer(quadoEthUniswapPoolAddress, uint256(ethAmount));
            //quadoEthUniswapPoolAddress.transfer(uint256(amount0Delta));// ), 'eth_to_uni');

            // pay the owner the OOOO he got
            if(swapData.eventType == 2) {
                // inform the cash system that it should mint coins to the owner
                emit SwapEvent(2, swapData.account, uint256(ethAmount), uint256(-quadoAmount));
            } else {
                emit SwapEvent(4, swapData.account, uint256(ethAmount), uint256(-quadoAmount));
                _approve(address(this), quadoEthUniswapPoolAddress, uint256(-quadoAmount));
                transferFrom(address(this), swapData.account,  uint256(-quadoAmount));
            }
        } 
    }

    /**
     * @dev Quado Cash to Coin: Emits event to cash out deposited Quado Cash to Quado in user's wallet
     * @param _amount amount of quado cash to cash out
     */
    function cashOut(uint256 _amount, bool _toEth) public payable {
        require(msg.value >= tx.gasprice * (_toEth ? gasToCashOutToEth : gasToCashOut), "min_gas_to_cashout");
        
        // pay owner the gas fee it needs to call settlecashout
        address payable payowner = address(uint160(owner()));
        require(payowner.send( msg.value ), "fees_to_owner");

        //→ emit event
        emit SwapEvent(_toEth ? 7 : 1, msg.sender, msg.value, _amount);
    }

    /**
     * @dev Cashes out deposited Quado Cash to Quado in user's wallet
     * @param _to address of the future owner of the token
     * @param _amount how much Quado to cash out
     * @param _notMinted not minted cash to reflect on blockchain
     */
    function settleCashOut(address payable _to, uint256 _amount, bool _toEth, uint160 sqrtPriceLimitX96, uint256 _notMinted) public onlyOwner {
        mintFromCash(_notMinted);
        
        // must be done in any case, so it can be taken from him for uniswap or left if not swapped
        transferFrom(address(this), _to, _amount);

        if(_toEth) {
            // owner wanted ETH in return to Cash
            //require(_amount <= balanceOf(_to), 'low_balance');
            _approve(_to, quadoEthUniswapPoolAddress, _amount);

            quadoEthUniswapPool.swap(
                address(this), 
                quadoEthUniswapPoolToken0IsQuado, 
                int256(_amount), 
                sqrtPriceLimitX96, 
                swapDataToBytes(SwapData(3, _to))
            );
        }
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
        _transfer(msg.sender, recipient, amount);
        // if it's a cash deposit transfer
        if(recipient == address(this)) {
            _approve(address(this), owner(), amount);
            // signal the cash system the deposit
            emit SwapEvent(5, msg.sender, 0, amount);
        }
        return true;
    }

    /**
     * @dev Mints token to one of the payout adddresses for bootstrap, infrastructure and dev team
     * @dev Approves the contract owner to transfer that minted tokens
     * @param _amount mints this amount of Quado to the contract itself
     * @param _to address on where to mint
     */
    function mintOwnerFundsTo(uint256 _amount, address _to) internal onlyMinter {
        require(_amount > 0, "zero amount to mint");
        require(_to != address(0), "mint to is zero address");

        //_approve(address(this), msg.sender, _amount);
        //_transfer(address(this), _to, _amount);
        mint(_to, _amount);
        _approve(_to, owner(), _amount);
    }

    /**
     * @dev Reflects the current quado cash state to quado coin by minting to the contract itself
     * @dev Approves the contract owner to transfer that minted cash later
     * @dev Additionally approves pre-minted funds for hardware payment and dev incentives
     * @param _amount mints this amount of Quado to the contract itself
     */
    function mintFromCash(uint256 _amount) public onlyMinter {
        uint256 totalApprove = _amount;
        if(_amount > 0) {
            mint(address(this), _amount);
            // approve for later cashout
            _approve(address(this), owner(), totalApprove);

            // check if a 10% milestone is broken, and if so grant the dev team 10% of their fund
            if( (totalSupply() * 10 / cap()) < ((totalSupply() + _amount) * 10 / cap()) ) {
                uint256 devFunds = cap()/100*percentDevteam/10;
                mintOwnerFundsTo(devFunds, devTeamPayoutAdress);
                emit OwnerFundsApproval(2, devFunds);
            }
            
        }
        // check for next infrastructure cost settlement
        if ((now >= lastInfrastructureGrand + 4 * 1 weeks) 
            && ((usedForInfrstructure + currentInfrastructureCosts) <= (cap()/100 * percentInfrastructureFund))
        ) {
            usedForInfrstructure += currentInfrastructureCosts;
            lastInfrastructureGrand = now;
            mintOwnerFundsTo(currentInfrastructureCosts, infrastructurePayoutAdress);
            emit OwnerFundsApproval(1, currentInfrastructureCosts);     
        }
    }

    function setGasToCashOutEstimate(uint256 _cashOut, uint256 _cashOutToEth) public onlyOwner {
        gasToCashOut = _cashOut;
        gasToCashOutToEth = _cashOutToEth;
    }
    function setCurrentInfrastructureCosts(uint256 _costs) public onlyOwner {
        currentInfrastructureCosts = _costs;
    }

    function setUniswapPool(address payable _poolAddress) public onlyOwner {

        IUniswapV3PoolImmutables poolImmu = IUniswapV3PoolImmutables(_poolAddress);

        require((poolImmu.token0() == address(this)) || (poolImmu.token1() == address(this)));
        
        quadoEthUniswapPoolToken0IsQuado = (poolImmu.token0() == address(this));
        quadoEthUniswapPoolAddress = _poolAddress;
        quadoEthUniswapPool = IUniswapV3PoolActions(quadoEthUniswapPoolAddress);
    }

    function setPayoutAddresses(address _devTeamPayoutAdress, address _infrastructurePayoutAdress) public onlyOwner {
        devTeamPayoutAdress = _devTeamPayoutAdress;
        infrastructurePayoutAdress = _infrastructurePayoutAdress;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdrawETH(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, 'balance_low');
        require(msg.sender.send(amount), 'no_send');
    }


    /*function setGod(address _god) public onlyOwner {
        god = _god;
    }*/
}