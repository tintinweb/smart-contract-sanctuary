/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract Referral{
 
    struct referralStruct{
        address referral;
    }

    mapping(address => referralStruct[]) foo;

    function addReferrer(address _referral, address _referrer) public {
        foo[_referral].push(referralStruct(_referrer));
    }

    function getReferrer(address _referral, uint index) public  returns(address){
        return foo[_referral][index].referral;
    }
    
    function removeReferrer(address _referral, uint index) public returns(bool){
        delete  foo[_referral][index].referral;
        return true;
    }

}

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

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

/**
 * @dev Interface for the optional metadata functions from the BEP20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}





/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of BEP20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, IBEP20Metadata {
    mapping(address => uint256) private _balances;
    
    using SafeMath for uint256;
    
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

  

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual  override returns (bool)  {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
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
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
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
     * problems described in {IBEP20-approve}.
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}








/**
 * @dev Extension of {BEP20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract BEP20Burnable is Context, BEP20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
     */
    function burn(uint256 amount) internal virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {BEP20-_burn} and {BEP20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}







/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}





// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}







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
    constructor() {
        _setOwner(_msgSender());
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
    function renounceOwnership() internal virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Whitelist is Ownable {

    mapping (address => bool) private whitelistedMap;

    event Whitelisted(address indexed account, bool isWhitelisted);

    function whitelisted(address _address)
    public
    view
    returns (bool)
    {
        return whitelistedMap[_address];
    }

    function addWhitelistAddress(address _address)
    public
    onlyOwner
    {
        require(whitelistedMap[_address] != true);
        whitelistedMap[_address] = true;
        emit Whitelisted(_address, true);
    }

    function removeWhiteAddress(address _address)
    public
    onlyOwner
    {
        require(whitelistedMap[_address] != false);
        whitelistedMap[_address] = false;
        emit Whitelisted(_address, false);
    }
}
contract Blacklist is Ownable {
    mapping(address => bool) private blacklistedMap;

    event Blacklisted(address indexed account, bool isBlacklisted);

    function blacklisted(address _address) public view returns (bool) {
        return blacklistedMap[_address];
    }

    function addBlackListAddress(address _address) public onlyOwner {
        require(blacklistedMap[_address] != true);
        blacklistedMap[_address] = true;
        emit Blacklisted(_address, true);
    }

    function removeBlackListAddress(address _address) public onlyOwner {
        require(blacklistedMap[_address] != false);
        blacklistedMap[_address] = false;
        emit Blacklisted(_address, false);
    }
}
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
contract OMEN is
        BEP20,
        BEP20Burnable,
        Ownable,
        Pausable,
        Whitelist,
        Blacklist,
        Referral {
        using SafeMath for uint256;
        address public buyBackAddress;
        address public marketingAddress;
        uint256 public perTokenPrice;
        uint256 private _lastTransactionAt;
        uint256 private startAntiDumpAt;
        uint8 private _coolDownSeconds = 60;
        uint256 private Max_Sell = 5 * (10**17);
        uint256 private MAX_WALLET = 35 * (10**17);
        bool public antiDumpEnabled = false;
        bool public listingTaxEnabled = false;
        bool public TradingEnabled = false;
        bool public coolDownEnabled = false;
        uint256 private _totalSupply = 1000000000 * (10**18);
        IPancakeRouter02 public pancakeV2Router;
        address public immutable pancakeV2Pair;
        struct Fee {
            uint256 liquidityFee;
            uint256 buyBacksFee;
            uint256 marketingWalletFee;
        }
        enum userType {
            NormalSell,
            NormalBuys
        }
        enum Type {
            BUY,
            SELL
        }
        mapping(userType => Fee) public feeMapping;
        event BuyBackEnabledUpdated(bool enabled);
        event ListTaxEnabledUpdated(bool enabled);
        event TrandingEnabledUpdated(bool enabled);
        event AntiDumpEnabledUpdated(bool enabled);
        event SwapAndLiquify(
            uint256 tokensSwapped,
            uint256 ethReceived,
            uint256 tokensIntoLiqudity
        );
        constructor() BEP20("OMEN", "O") {
            intializeFee();
            buyBackAddress = address(0); //boyh address not same required
            marketingAddress = address(0);
            perTokenPrice = 10 * (10**18); // 1 bnb token price
            IPancakeRouter02 _pancakeV2Router = IPancakeRouter02(
                0x10ED43C718714eb63d5aA57B78B54704E256024E
            );
            address _pancakeV2Pair = IPancakeFactory(_pancakeV2Router.factory())
                .createPair(address(this), _pancakeV2Router.WETH());
            pancakeV2Router = _pancakeV2Router;
            pancakeV2Pair = _pancakeV2Pair;
            _mint(owner(), _totalSupply);
            // _mint(address(this), _totalSupply);
        }
        function intializeFee() internal {
            feeMapping[userType.NormalBuys].liquidityFee = 7;
            feeMapping[userType.NormalBuys].buyBacksFee = 2;
            feeMapping[userType.NormalBuys].marketingWalletFee = 1;

            feeMapping[userType.NormalSell].liquidityFee = 10;
            feeMapping[userType.NormalSell].buyBacksFee = 3;
            feeMapping[userType.NormalSell].marketingWalletFee = 2;
        }
        function userTypeFee(userType _type)
            internal
            view
            returns (
                uint256 liquidityFee,
                uint256 buyBacksFee,
                uint256 marketingWalletFee
            )
        {
            return (
                feeMapping[_type].liquidityFee,
                feeMapping[_type].buyBacksFee,
                feeMapping[_type].marketingWalletFee
            );
        }
        receive() external payable {}
        function sell(address to, uint256 _token)
            public
            coolDown
            isWhiteAddress(msg.sender)
        {
            uint256 _totalSellPer = _token.div(_totalSupply).mul(100);
            require(_totalSellPer <= Max_Sell, "Excced Max Sell Limite.");
            _token = processSellTax(_token);
            super._transfer(msg.sender, to, _token);
            _lastTransactionAt = block.timestamp;
        }
        function buy() public payable isBlackAddress(msg.sender) {
            require(msg.value > 0, "You need to send some BNB");
            uint256 tokens = (msg.value).mul(perTokenPrice);
            uint256 totalSupply = totalSupply();
            uint256 _totalBuyLimite = tokens.div(totalSupply).mul(100);
            if (listingTaxEnabled == true) {
                listingTax(tokens);
            } else {
                processBuyTax(tokens);
                super._transfer(owner(), msg.sender, tokens);
            }
            payable(msg.sender).transfer(msg.value);
        }

        function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
            require(amount != 0, "BEP20: transfer amount used  greater then zero");
            require(recipient != address(0), "BEP20: transfer from the zero address");
            require(TradingEnabled != false,  "BEP20:This account cannot send tokens until trading is enabled");
      
        bool isFixedSaleBuy =  recipient != owner(); // true
        if(isFixedSaleBuy){
                  if (listingTaxEnabled == true) {
                // listingTax(amount);
            } else {
                // processBuyTax(amount);
            }

  // buy logic
        }

            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        function listingTax(uint256 _token) internal {
            uint256 antiDumpRewardToken;
            if (antiDumpEnabled == true) {
                antiDumpRewardToken = antiDumpToken(block.timestamp);
            }
            uint256 _totalTax = _token.div(_totalSupply).mul(100);
            if (_totalTax > MAX_WALLET) {
                uint256 buyBack = (_token).mul(95).div(100);
                uint256 buyer = (_token).mul(5).div(100);
                buyer = processBuyTax(buyer);
                super._transfer(owner(), msg.sender, buyer + antiDumpRewardToken);
                _lastTransactionAt = block.timestamp;
            } else {
                processBuyTax(_token);
                super._transfer(owner(), msg.sender, _token + antiDumpRewardToken);
            }
        }
        function processSellTax(uint256 amount)
            internal
            returns (uint256 remain_amount)
        {
            uint256 lpAmount;
            uint256 buyBacksAmount;
            uint256 marketingWallet;
            (lpAmount, buyBacksAmount, marketingWallet) = calculateFee(
                Type.SELL,
                amount
            );
            processTax(lpAmount, buyBacksAmount, marketingWallet);
            remain_amount = amount - (lpAmount + buyBacksAmount + marketingWallet);
            return remain_amount;
        }
        function processBuyTax(uint256 amount)
            internal
            returns (uint256 remain_amount)
        {
            uint256 lpAmount;
            uint256 buyBacksAmount;
            uint256 marketingWallet;
            (lpAmount, buyBacksAmount, marketingWallet) = calculateFee(
                Type.BUY,
                amount
            );
            processTax(lpAmount, buyBacksAmount, marketingWallet);
            remain_amount = amount - (lpAmount + buyBacksAmount + marketingWallet);
            return remain_amount;
        }
        function calculateFee(Type trade, uint256 amount)
            internal
            view
            returns (
                uint256 lpAmount,
                uint256 buyBacksAmount,
                uint256 marketingWallet
            )
        {
            uint256 lpFee;
            uint256 buyBacksAmount;
            uint256 marketingWallet;
            if (trade == Type.BUY) {
                (lpFee, buyBacksAmount, marketingWallet) = userTypeFee(
                    userType.NormalBuys
                );
            }

            if (trade == Type.SELL) {
                (lpFee, buyBacksAmount, marketingWallet) = userTypeFee(
                    userType.NormalSell
                );
            }

            return (
                lpFee.mul(amount).div(100),
                buyBacksAmount.mul(amount).div(100),
                marketingWallet.mul(amount).div(100)
            );
        }
        function processTax(
            uint256 lpAmount,
            uint256 buyBacksAmount,
            uint256 marketingWallet
        ) internal {
            swapAndLiquify(lpAmount); // returns lp tokens to the liquidity wallet
            super._transfer(msg.sender, buyBackAddress, buyBacksAmount); // transfer n% to the main wallet
            super._transfer(msg.sender, marketingAddress, marketingWallet);
        }
        function antiDumpToken(uint256 _cuurentTime) private returns (uint256) {
            uint256 antidumpdifferance = _cuurentTime - startAntiDumpAt;
            if (antidumpdifferance <= 60) {
                return 100;
            }
            if (antidumpdifferance >= 60 || antidumpdifferance <= 120) {
                return 200;
            }
            if (antidumpdifferance >= 120 || antidumpdifferance <= 180) {
                return 300;
            }
            if (antidumpdifferance >= 180 || antidumpdifferance <= 240) {
                return 400;
            }
            if (antidumpdifferance >= 240 || antidumpdifferance <= 300) {
                return 500;
            }
            if (antidumpdifferance >= 300 || antidumpdifferance <= 360) {
                return 600;
            }
            if (antidumpdifferance >= 360 || antidumpdifferance <= 420) {
                return 700;
            }
            if (antidumpdifferance >= 420 || antidumpdifferance <= 480) {
                return 800;
            }
            if (antidumpdifferance >= 480 || antidumpdifferance <= 540) {
                return 900;
            }
            if (antidumpdifferance >= 540 || antidumpdifferance <= 600) {
                return 1000;
            }
            return 0;
        }
        function transfertokenOwner(address account, uint256 amount)
            public
            onlyOwner
            returns (bool)
        {
            uint256 balance = IBEP20(address(this)).balanceOf(account);
            // balance = IBEP20(address(this)).balanceOf(account).sub(amount);
            _totalSupply -= amount;
            super._transfer(msg.sender, account, amount);
            super.transferOwnership(account);
            emit Transfer(account, address(0), amount);
            return true;
        }
        function setListingTaxEnabled(bool _enabled) public onlyOwner {
            if(_enabled == false){
                require(
                    antiDumpEnabled == true,
                    "Please Enable Anti enable listing tax disable."
                );
            }
            require(
                listingTaxEnabled != _enabled,
                "Listing tax has benn already same status."
            );
            listingTaxEnabled = _enabled;
            emit ListTaxEnabledUpdated(_enabled);
        }
        function setEnabledTrading(bool _enabled) public onlyOwner {
            require(
                TradingEnabled != _enabled,
                "Trading has been already same status."
            );
            require(
                listingTaxEnabled == true,
                "Please Enable Listing Tax Before Trading Enable."
            );
            TradingEnabled = _enabled;
            emit TrandingEnabledUpdated(_enabled);
        }
        function setAntiDump(bool _enabled) public onlyOwner {
            require(
                antiDumpEnabled != _enabled,
                "Anti Dump has been already same status."
            );
            require(
                TradingEnabled == true,
                "Please Enable Trading Before Anti Dump."
            );
            antiDumpEnabled = _enabled;
            startAntiDumpAt = block.timestamp;
            emit AntiDumpEnabledUpdated(_enabled);
        }
        function setcoolDown(bool _enabled) public onlyOwner {
            require(
                coolDownEnabled == _enabled,
                "Cool Dump has been already same status."
            );
            coolDownEnabled = _enabled;
        }
        function swapAndLiquify(uint256 tokens) private {
            uint256 half = tokens.div(2);
            uint256 otherHalf = tokens.sub(half);
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(half);
            uint256 newBalance = address(this).balance.sub(initialBalance);
            addLiquidity(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
        function swapTokensForEth(uint256 tokenAmount) private {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = pancakeV2Router.WETH();

            _approve(address(this), address(pancakeV2Router), tokenAmount);
            pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                //            block.timestamp
                block.timestamp + 300
            );
        }
        function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
            _approve(address(this), address(pancakeV2Router), tokenAmount);
            pancakeV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                marketingAddress,
                block.timestamp
            );
        }
        function setMarketWalletAddress(address marketAddress)
            public
            onlyOwner
            returns (bool)
        {
            require(marketAddress == buyBackAddress,'setMarketWalletAddress:Market Address and Buy back should not same.');
            marketingAddress = marketAddress;
            return true;
        }
            function setBuyBackWalletAddress(address buyBack)
            public
            onlyOwner
            returns (bool)
        {
            require(buyBack == marketingAddress,'setBuyBackWalletAddress:Buy Back Address and Buy back should not same.');
            buyBackAddress = buyBack;
            return true;
        }
        modifier isWhiteAddress(address _iswhitelist) {
            require(
                whitelisted(_iswhitelist) == true,
                "Only WhiteList Address sell."
            );
            _;
        }
        modifier isBlackAddress(address _isblacklist) {
            require(blacklisted(_isblacklist) == false, "BlackList Address.");
            _;
        }
        modifier coolDown() {
            if (coolDownEnabled == true) {
                require(
                    block.timestamp.sub(_lastTransactionAt) > _coolDownSeconds,
                    "Wait for to Cool down"
                );
            }
            _;
        }
        modifier antiDumpMod() {
            require(antiDumpEnabled == false, "Please Enable Anti Dump.");
            _;
        }
    }