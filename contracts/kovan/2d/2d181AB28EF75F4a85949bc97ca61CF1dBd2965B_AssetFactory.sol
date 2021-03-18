/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// File: openzeppelin-solidity/contracts/utils/Context.sol

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

// File: openzeppelin-solidity/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: openzeppelin-solidity/contracts/utils/Create2.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

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

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/pancake-swap/interfaces/IPancakeRouter01.sol

pragma solidity 0.7.6;

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/pancake-swap/interfaces/IPancakeRouter02.sol

pragma solidity 0.7.6;


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/pancake-swap/interfaces/IPancakeFactory.sol

pragma solidity 0.7.6;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts/pancake-swap/interfaces/IPancakeERC20.sol

pragma solidity 0.7.6;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: contracts/pancake-swap/interfaces/IPancakePair.sol

pragma solidity 0.7.6;


interface IPancakePair is IPancakeERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/pancake-swap/libraries/PancakeLibrary.sol

pragma solidity 0.7.6;


//import '@uniswap/v2-core/contracts/interfaces/IPancakePair.sol';




library PancakeLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "PancakeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "PancakeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB)
        internal
        view
        returns (address pair)
    {
        pair = IPancakeFactory(factory).getPair(tokenA, tokenB);
        /* (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"d0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66" // init code hash
                    )
                )
            )
        ); */
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(
            pairFor(factory, tokenA, tokenB)
        )
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
        internal
        pure
        returns (uint256 amountB)
    {
        require(amountA > 0, "PancakeLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "PancakeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PancakeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(998);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PancakeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "PancakeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "PancakeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/Asset.sol


pragma solidity 0.7.6;








contract Asset is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /* STATE VARIABLES */

    address[] public tokens;
    uint256[] public numOfTokensInOneAsset;

    IPancakeRouter02 public router;
    IPancakeFactory public factory;
    address public assetFactory;
    address private weth;

    uint256 private constant ONE_TOKEN = 1e18;

    bool private isInitialized;

    /* MODIFIERS */

    modifier whenInitialized {
        require(isInitialized == true, "Asset: Asset is not initialized yet");
        _;
    }

    /* EVENTS */

    event MintAssetFromUniswap(
        address indexed user,
        uint256 timestamp,
        uint256 amountOfTokensOut,
        uint256 amountOfEthIn
    );
    event MintAssetFromUser(
        address indexed user,
        uint256 timestamp,
        uint256 amountOfTokensOut
    );
    event RedeemAssetToUniswap(
        address indexed user,
        uint256 timestamp,
        uint256 amountOfTokensIn,
        uint256 amountOfEthOut
    );
    event RedeemAssetToUser(
        address indexed user,
        uint256 timestamp,
        uint256 amountOfTokensIn
    );

    /* FUNCTIONS */

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        require(
            ONE_TOKEN == 10**decimals(),
            "Asset: Change exponent of ONE_TOKEN constant"
        );
        assetFactory = _msgSender();
    }

    /* EXTERNAL FUNCTIONS */

    function init(
        IPancakeFactory _factory,
        IPancakeRouter02 _router,
        address[] memory _tokens,
        uint256[] memory _numOfTokensInOneAsset,
        address newOwner
    ) external onlyOwner {
        require(isInitialized == false, "Asset: Asset is already initialized");
        require(
            _tokens.length == _numOfTokensInOneAsset.length &&
                _tokens.length > 0,
            "Asset: Wrong tokens and numOfTokensInOneAsset inputs"
        );

        uint256 len = _tokens.length;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            require(
                _numOfTokensInOneAsset[i] != 0,
                "Asset: Wrong numOfTokensInOneAsset"
            );
            for (uint256 j = i.add(1); j < len; j = j.add(1)) {
                require(
                    _tokens[i] != _tokens[j],
                    "Asset: Wrong address in tokens array"
                );
            }
        }

        router = _router;
        factory = _factory;
        weth = router.WETH();
        tokens = _tokens;
        numOfTokensInOneAsset = _numOfTokensInOneAsset;

        if (owner() != newOwner){
            transferOwnership(newOwner);
        }

        isInitialized = true;
    }

    function buyAssetFromUniswap(uint256 minTokensToBuy, uint256 deadline)
        external
        payable
        nonReentrant
    {
        require(block.timestamp <= deadline, "Asset: Expired");
        uint256 allValue = msg.value;
        uint256 remainingValue = allValue;
        require(allValue > 0, "Asset: Value mast be larger than zero");

        (uint256 amountOfToken, ) = _getBuyEthPriceIn(allValue);
        require(
            amountOfToken != 0,
            "Asset: Internal error (amountOfToken != 0)"
        );
        require(amountOfToken >= minTokensToBuy, "Asset: Insufficient funds");

        (uint256 ethPrice, uint256[] memory ethPriceTokens) =
            _getBuyEthPriceOut(amountOfToken);
        require(
            ethPrice <= allValue,
            "Asset: Internal error (ethPrice <= allValue)"
        );

        uint256 len = tokens.length;
        address[] memory path = new address[](2);
        IPancakeRouter02 _router = router;

        for (uint256 i = 0; i < len; i = i.add(1)) {
            remainingValue = remainingValue.sub(ethPriceTokens[i]);
            path[0] = weth;
            path[1] = tokens[i];
            _router.swapExactETHForTokens{value: ethPriceTokens[i]}(
                0,
                path,
                address(this),
                deadline
            );
        }
        delete path;

        address payable sender = _msgSender();
        _mint(sender, amountOfToken);
        if (remainingValue != 0) {
            sender.transfer(remainingValue);
        }

        emit MintAssetFromUniswap(
            sender,
            block.timestamp,
            amountOfToken,
            allValue.sub(remainingValue)
        );
    }

    function buyAsset(uint256 numOfTokens) external nonReentrant {
        require(numOfTokens > 0, "Asset: numOfTokens must be larger than zero");
        address sender = _msgSender();
        uint256 len = tokens.length;
        uint256[] memory tokensDistributon = _getTokensDistributon(numOfTokens);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            uint256 allowanceOfThisToken =
                IERC20(tokens[i]).allowance(sender, address(this));
            require(
                allowanceOfThisToken >= tokensDistributon[i],
                "Asset: Not enough allowance"
            );
            require(
                IERC20(tokens[i]).transferFrom(
                    sender,
                    address(this),
                    tokensDistributon[i]
                ),
                "Asset: Transfer to contract failed"
            );
        }

        _mint(sender, numOfTokens);

        emit MintAssetFromUser(
            sender,
            block.timestamp,
            numOfTokens
        );
    }

    function sellAssetToUsniswap(
        uint256 amount,
        uint256 minimumEth,
        uint256 deadline
    ) external nonReentrant {
        require(block.timestamp <= deadline, "Asset: Expired");
        require(amount > 0, "Asset: Amount mast be larger than zero");
        address sender = _msgSender();
        require(amount <= balanceOf(sender), "Asset: Not enough balance");

        uint256 len = tokens.length;
        uint256[] memory tokensDistributon = _getTokensDistributon(amount);
        address[] memory path = new address[](2);
        uint256[] memory result;
        uint256 ethOut;
        IPancakeRouter02 _router = router;

        for (uint256 i = 0; i < len; i = i.add(1)) {
            require(tokensDistributon[i] > 0, "Asset: Low value");
            path[0] = tokens[i];
            path[1] = weth;
            uint256 thisTokenAllowance =
                IERC20(path[0]).allowance(address(this), address(_router));
            if (thisTokenAllowance < tokensDistributon[i]) {
                IERC20(path[0]).approve(address(_router), uint256(-1));
            }
            result = _router.swapExactTokensForETH(
                tokensDistributon[i],
                0,
                path,
                sender,
                deadline
            );
            ethOut = ethOut.add(result[1]);
        }
        delete path;

        require(ethOut >= minimumEth, "Asset: Insufficient funds");

        _burn(sender, amount);

        emit RedeemAssetToUniswap(
            sender,
            block.timestamp,
            amount,
            ethOut
        );
    }

    function sellAsset(uint256 amount) external nonReentrant {
        require(amount > 0, "Asset: Amount mast be larger than zero");
        address sender = _msgSender();
        require(amount <= balanceOf(sender), "Asset: Not enough balance");

        uint256 len = tokens.length;
        uint256[] memory tokensDistributon = _getTokensDistributon(amount);

        for (uint256 i = 0; i < len; i = i.add(1)) {
            require(tokensDistributon[i] > 0, "Asset: Low value");
            IERC20(tokens[i]).transfer(sender, tokensDistributon[i]);
        }

        _burn(sender, amount);

        emit RedeemAssetToUser(
            sender,
            block.timestamp,
            amount
        );
    }

    /* EXTERNAL VIEW FUNCTIONS */

    function getBuyEthPriceOut(uint256 amountOfTokenOut)
        external
        view
        returns (uint256 ethPrice, uint256[] memory ethPriceTokens)
    {
        return _getBuyEthPriceOut(amountOfTokenOut);
    }

    function getBuyEthPriceIn(uint256 amountOfEthIn)
        external
        view
        returns (uint256 amountOfToken, uint256[] memory amountOfTokens)
    {
        return _getBuyEthPriceIn(amountOfEthIn);
    }

    function getSellEthPriceOut(uint256 amountOfEthOut)
        external
        view
        returns (uint256 amountOfToken, uint256[] memory amountOfTokens)
    {
        return _getSellEthPriceOut(amountOfEthOut);
    }

    function getSellEthPriceIn(uint256 amountOfTokenIn)
        external
        view
        returns (uint256 ethPrice, uint256[] memory ethPriceTokens)
    {
        return _getSellEthPriceIn(amountOfTokenIn);
    }

    function getTokensDistributon(uint256 numOfTokens)
        external
        view
        returns (uint256[] memory)
    {
        return _getTokensDistributon(numOfTokens);
    }

    function tokensLen() external view returns (uint256) {
        return tokens.length;
    }

    function contractTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /* PUBLIC FUNCTIONS */
    /* INTERNAL FUNCTIONS */
    /* PRIVATE FUNCTIONS */
    /* PRIVATE VIEW FUNCTIONS */

    function _getTokensDistributon(uint256 numOfTokens)
        private
        view
        returns (uint256[] memory tokensDistribution)
    {
        uint256 len = tokens.length;
        tokensDistribution = new uint256[](len);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            tokensDistribution[i] = numOfTokensInOneAsset[i]
                .mul(numOfTokens)
                .div(ONE_TOKEN);
        }
    }

    function _getBuyEthPriceOut(uint256 amountOfTokenOut)
        private
        view
        returns (uint256 ethPrice, uint256[] memory ethPriceTokens)
    {
        uint256 len = tokens.length;
        ethPriceTokens = new uint256[](len);

        address _factory = address(factory);

        uint256[] memory tokensDistributon =
            _getTokensDistributon(amountOfTokenOut);

        for (uint256 i = 0; i < len; i = i.add(1)) {
            require(tokensDistributon[i] > 0, "Asset: Insufficient funds");
            (uint256 reserveEth, uint256 reserveToken) =
                PancakeLibrary.getReserves(_factory, weth, tokens[i]);
            uint256 ethPriceThisToken =
                PancakeLibrary.getAmountIn(
                    tokensDistributon[i],
                    reserveEth,
                    reserveToken
                );

            ethPriceTokens[i] = ethPriceThisToken;
            ethPrice = ethPrice.add(ethPriceThisToken);
        }
    }

    function _getBuyEthPriceIn(uint256 amountOfEthIn)
        private
        view
        returns (uint256 amountOfToken, uint256[] memory amountOfTokens)
    {
        uint256 divider = 100;
        uint256 divider2 = divider.mul(10);
        uint256 maxInerations = 100;
        require(amountOfEthIn >= divider, "Asset: Not enough eth");
        uint256 len = tokens.length;
        amountOfTokens = new uint256[](len);

        uint256 ethPrice;
        uint256 diff;
        amountOfToken = ONE_TOKEN;
        uint256 i;
        do {
            require(amountOfToken > 0, "Asset: Insufficient funds");
            (ethPrice, ) = _getBuyEthPriceOut(amountOfToken);
            if (amountOfEthIn >= ethPrice) {
                diff = amountOfEthIn.sub(ethPrice);
                if (diff < amountOfEthIn.div(divider)) break;
                amountOfToken = amountOfToken.add(
                    amountOfToken.mul(diff).div(ethPrice)
                );
            } else {
                diff = ethPrice.sub(amountOfEthIn);
                if (diff < amountOfEthIn.div(divider)) break;
                //uint256 delta = ethPrice.div(divider2);
                uint256 delta = 0;
                amountOfToken = amountOfToken.sub(
                    amountOfToken.mul(diff.add(delta)).div(ethPrice)
                );
            }
            i = i.add(1);
        } while (i < maxInerations);

        require(
            i < maxInerations || diff < amountOfEthIn.div(divider),
            "Asset: Could not estimate number of tokens to buy"
        );

        amountOfTokens = _getTokensDistributon(amountOfToken);
    }

    function _getSellEthPriceOut(uint256 amountOfEthOut)
        private
        view
        returns (uint256 amountOfToken, uint256[] memory amountOfTokens)
    {
        uint256 divider = 100;
        uint256 divider2 = divider.mul(10);
        uint256 maxInerations = 100;
        require(amountOfEthOut >= divider, "Asset: Not enough eth");
        uint256 len = tokens.length;
        amountOfTokens = new uint256[](len);

        uint256 ethPrice;
        uint256 diff;
        amountOfToken = ONE_TOKEN;
        uint256 i;
        do {
            (ethPrice, ) = _getSellEthPriceIn(amountOfToken);
            if (amountOfEthOut >= ethPrice) {
                diff = amountOfEthOut.sub(ethPrice);
                if (diff < amountOfEthOut.div(divider)) break;
                amountOfToken = amountOfToken.add(
                    amountOfToken.mul(diff).div(ethPrice)
                );
            } else {
                diff = ethPrice.sub(amountOfEthOut);
                if (diff < amountOfEthOut.div(divider)) break;
                amountOfToken = amountOfToken.sub(
                    amountOfToken.mul(diff.add(ethPrice.div(divider2))).div(
                        ethPrice
                    )
                );
            }
            i = i.add(1);
        } while (i < maxInerations);

        require(
            i < maxInerations || diff < amountOfEthOut.div(divider),
            "Asset: Could not estimate number of tokens to buy"
        );

        amountOfTokens = _getTokensDistributon(amountOfToken);
    }

    function _getSellEthPriceIn(uint256 amountOfTokenIn)
        private
        view
        returns (uint256 ethPrice, uint256[] memory ethPriceTokens)
    {
        uint256 len = tokens.length;
        ethPriceTokens = new uint256[](len);

        address _factory = address(factory);

        uint256[] memory tokensDistributon =
            _getTokensDistributon(amountOfTokenIn);

        for (uint256 i = 0; i < len; i = i.add(1)) {
            (uint256 reserveEth, uint256 reserveToken) =
                PancakeLibrary.getReserves(_factory, weth, tokens[i]);
            uint256 ethPriceThisToken =
                PancakeLibrary.getAmountOut(
                    tokensDistributon[i],
                    reserveToken,
                    reserveEth
                );

            ethPriceTokens[i] = ethPriceThisToken;
            ethPrice = ethPrice.add(ethPriceThisToken);
        }
    }
}

// File: contracts/AssetFactory.sol


pragma solidity 0.7.6;






contract AssetFactory is Ownable {
    IPancakeFactory public pancakeFactory;
    IPancakeRouter02 public pancakeRouter;

    mapping(address => bool) public isAsset;
    address[] public assets;

    event AssetCreated(
        address indexed creator,
        address indexed assetOwner,
        uint256 timestamp,
        address addressOfAsset,
        string name,
        string symbol,
        address[] tokens,
        uint256[] numOfTokensInOneAsset
    );

    constructor(
        IPancakeFactory _pancakeFactory,
        IPancakeRouter02 _pancakeRouter
    ) {
        pancakeFactory = _pancakeFactory;
        pancakeRouter = _pancakeRouter;
    }

    function createAsset(
        string memory _name,
        string memory _symbol,
        address[] memory _tokens,
        uint256[] memory _numOfTokensInOneAsset,
        address newOwner
    ) external onlyOwner {
        address newAsset = address(new Asset(_name, _symbol));
        /*Asset(newAsset).init(
            pancakeFactory,
            pancakeRouter,
            _tokens,
            _numOfTokensInOneAsset,
            newOwner
        );

        isAsset[newAsset] = true;
        assets.push(newAsset); */

        emit AssetCreated(
            _msgSender(),
            newOwner,
            block.timestamp,
            address(0),//newAsset,
            _name,
            _symbol,
            _tokens,
            _numOfTokensInOneAsset
        );
    }

    function AssetsLen() external view returns(uint256) {
        return assets.length;
    }
}