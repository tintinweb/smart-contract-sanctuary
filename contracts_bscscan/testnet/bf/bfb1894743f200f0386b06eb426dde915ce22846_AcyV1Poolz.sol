/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

pragma solidity ^0.6.0;// SPDX-License-Identifier: MIT

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
 /**
 *  basic interface of ERC20 token
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

contract ERC20Helper  {
    event TransferOut(uint256 Amount, address To, address Token);
    event TransferIn(uint256 Amount, address From, address Token);
    modifier TestAllownce(
        address _token,
        address _owner,
        uint256 _amount
    ) {
        require(
            ERC20(_token).allowance(_owner, address(this)) >= _amount,
            "no allowance"
        );
        _;
    }

    function TransferToken(
        address _Token,
        address _Reciver,
        uint256 _Amount
    ) internal {
        uint256 OldBalance = CheckBalance(_Token, address(this));
        emit TransferOut(_Amount, _Reciver, _Token);
        ERC20(_Token).transfer(_Reciver, _Amount);
        require(
            (SafeMath.add(CheckBalance(_Token, address(this)), _Amount)) == OldBalance
                ,
            "recive wrong amount of tokens"
        );
    }

    function CheckBalance(address _Token, address _Subject)
        internal
        view
        returns (uint256)
    {
        return ERC20(_Token).balanceOf(_Subject);
    }

    function TransferInToken(
        address _Token,
        address _Subject,
        uint256 _Amount
    ) internal TestAllownce(_Token, _Subject, _Amount) {
        require(_Amount > 0);
        uint256 OldBalance = CheckBalance(_Token, address(this));
        ERC20(_Token).transferFrom(_Subject, address(this), _Amount);
        emit TransferIn(_Amount, _Subject, _Token);
        require(
            (SafeMath.add(OldBalance, _Amount)) ==
                CheckBalance(_Token, address(this)),
            "recive wrong amount of tokens"
        );
    }

    function ApproveAllowanceERC20(
        address _Token,
        address _Subject,
        uint256 _Amount
    ) internal {
        require(_Amount > 0);
        ERC20(_Token).approve(_Subject, _Amount);
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

contract GovManager is Ownable {
    address public GovernerContract;

    modifier onlyOwnerOrGov() {
        require(msg.sender == owner() || msg.sender == GovernerContract, "Authorization Error");
        _;
    }

    function setGovernerContract(address _address) external onlyOwnerOrGov{
        GovernerContract = _address;
    }

    constructor() public {
        GovernerContract = address(0);
    }
}

contract ETHHelper is Ownable {
    constructor() public {
        IsPayble = false;
    }

    modifier ReceivETH(uint256 msgValue, address msgSender, uint256 _MinETHInvest) {
        require(msgValue >= _MinETHInvest, "Send ETH to invest");
        emit TransferInETH(msgValue, msgSender);
        _;
    }

    //@dev not/allow contract to receive funds
    receive() external payable {
        if (!IsPayble) revert();
    }

    event TransferOutETH(uint256 Amount, address To);
    event TransferInETH(uint256 Amount, address From);

    bool public IsPayble;
 
    function SwitchIsPayble() public onlyOwner {
        IsPayble = !IsPayble;
    }

    function TransferETH(address payable _Reciver, uint256 _ammount) internal {
        emit TransferOutETH(_ammount, _Reciver);
        uint256 beforeBalance = address(_Reciver).balance;
        _Reciver.transfer(_ammount);
        require(
            SafeMath.add(beforeBalance, _ammount) == address(_Reciver).balance,
            "The transfer did not complite"
        );
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
    constructor () internal {
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

contract Manageable is ETHHelper, ERC20Helper,GovManager, Pausable  {
    constructor() public {
        MinETHInvest = 10000; // for percent calc
        MaxETHInvest = 100 * 10**18; // 100 eth per wallet
        MinERC20Invest = 10000;
        MaxERC20Invest = 10000 * 10**18;
    }

    uint256 public MinETHInvest;
    uint256 public MaxETHInvest;
    uint256 public MinERC20Invest;
    uint256 public MaxERC20Invest;

    function SetMinMaxETHInvest(uint256 _MinETHInvest, uint256 _MaxETHInvest)
        public
        onlyOwnerOrGov
    {
        MinETHInvest = _MinETHInvest;
        MaxETHInvest = _MaxETHInvest;
    }

    function SetMinMaxERC20Invest(uint256 _MinERC20Invest, uint256 _MaxERC20Invest)
        public
        onlyOwnerOrGov
    {
        MinERC20Invest = _MinERC20Invest;
        MaxERC20Invest = _MaxERC20Invest;
    }

    function pause() public onlyOwnerOrGov {
        _pause();
    }

    function unpause() public onlyOwnerOrGov {
        _unpause();
    }
}

contract Pools is Manageable {
    event NewPool(address token, uint256 id);
    event FinishPool(uint256 id);
    event PoolUpdate(uint256 id);

    constructor() public {
    //  poolsCount = 0; //Start with 0
    }

    uint256 public poolsCount; // the ids of the pool
    mapping(uint256 => Pool) pools; //the id of the pool with the data
    mapping(address => uint256[]) poolsMap; //the address and all of the pools id's

    struct Pool {
        PoolBaseData BaseData;
        PoolMoreData MoreData;
    }

    struct PoolBaseData {
        address Token; //the address of the erc20 toke for sale
        address Creator; //the project owner
        address Maincoin; // on adress.zero = ETH
        uint256 StartAmount; //The total amount of the tokens for sale
        uint256 SaledAmount; //The total amount of the tokens have saled
        uint256 StartTime; //Until what time the pool is active
        uint256 EndTime; //Until what time the pool is over
        uint256 SwapRate; // eg. if swapType==0,then a Maincoin == swapRate Tokens;else a Token == swapRate Maincoins.
        uint256 SwapType; //0 or 1
        uint256 Status; // 0= closed; 1 = available for user;2=creator haved withdrawed tokens
    }

    struct PoolMoreData {
        uint distributionCount;
        mapping(uint=>PoolDistributionData) DistributionData;
    }

    struct PoolDistributionData {
        uint distributionID;
        uint distributionTime; // after this time,gov could distribute tokens to all user
        uint distributionShare; // share/totalShare = distributionAmount/TotalAmount
        uint distributionStatus; // 0=uncompleted;1=complete
    }

    function isPoolLocked(uint256 _id) public view returns(bool){
        return pools[_id].BaseData.StartTime > now || pools[_id].MoreData.distributionCount == 0;
    }

    modifier isPoolId(uint256 _id) {
        require(_id < poolsCount, "Invalid Pool ID");
        _;
    }

    //create a new pool
    function CreatePool(
        address _Token, //token to sell address
        address _MainCoin, // address(0x0) = ETH, address of main token
        uint256 _StartAmount, //Total amount of the tokens to sell in the pool
        uint256 _StartTime, //Until what time the pool will work
        uint256 _EndTime, //Until what time the pool will not work
        uint256 _SwapRate,
        uint256 _SwapType
    ) public whenNotPaused onlyOwnerOrGov {
        require(_Token != address(0x0), "Need Valid ERC20 Token"); 
        require(
            _MainCoin != address(0x0) ,"Need Valid Main"
        );
        require(
            _MainCoin != _Token ,"Main coin or Token error"
        );
        require(_StartTime > now, "Need Valid startTime");
        require(_StartTime < _EndTime , "Need Valid endTime");
        require(_StartAmount>0, "Need Valid  StartAmount");
        require(_SwapRate>0,"Need Valid  _SwapRate");
        require(_SwapType==0 || _SwapType==1,"Need Valid  _SwapType");

        TransferInToken(_Token, msg.sender, _StartAmount);
        //register the pool
        pools[poolsCount] = Pool(
            PoolBaseData(
                _Token,
                msg.sender,
                _MainCoin,
                _StartAmount,
                0,
                _StartTime,
                _EndTime,
                _SwapRate,
                _SwapType,
                1
            ),
            PoolMoreData(
                0
            )
        );
        poolsMap[msg.sender].push(poolsCount);
        emit NewPool(_Token, poolsCount);
        poolsCount = SafeMath.add(poolsCount, 1); //joke - overflowfrom 0 on int256 = 1.16E77
    }

    //update pool distribution
    function UpdatePoolDistribution(
        uint256 _id,
        uint[] memory distributionTimeArr,
        uint[] memory distributionShareArr
    ) public whenNotPaused onlyOwnerOrGov isPoolId(_id){
        require(pools[_id].BaseData.StartTime > now,"You could not do this,when the pool is open");
        require(distributionTimeArr.length==distributionShareArr.length,"Need Valid Params");
        uint endTime = pools[_id].BaseData.EndTime;
        uint timeFlag = 0;
        for(uint i=0;i<distributionTimeArr.length;i++){
            require(distributionTimeArr[i] > endTime&&distributionTimeArr[i]>timeFlag,"Need Valid Params");
            timeFlag = distributionTimeArr[i];
            pools[_id].MoreData.distributionCount = SafeMath.add(pools[_id].MoreData.distributionCount, 1);
            pools[_id].MoreData.DistributionData[pools[_id].MoreData.distributionCount] = PoolDistributionData(
                pools[_id].MoreData.distributionCount,
                distributionTimeArr[i],
                distributionShareArr[i],
                0
            );
        }
    }

    function ResetPoolDistribution(
        uint256 _id
    ) public whenNotPaused onlyOwnerOrGov isPoolId(_id) {
        require(pools[_id].BaseData.StartTime < now,"You could not do this,when the pool is open");
        pools[_id].MoreData.distributionCount = 0;
    }
}

contract PoolsData is Pools {
    enum PoolStatus {PreCreated, PreOpen, Open, PreDistribute, Distributing, Finished, closed} //the status of the pools

    function GetMyPoolsId() public view returns (uint256[] memory) {
        return poolsMap[msg.sender];
    }

    function GetPoolBaseData(uint256 _Id)
        public
        view
        isPoolId(_Id)
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            pools[_Id].BaseData.Token,
            pools[_Id].BaseData.Maincoin,
            pools[_Id].BaseData.StartAmount,
            pools[_Id].BaseData.SaledAmount,
            pools[_Id].BaseData.StartTime,
            pools[_Id].BaseData.EndTime
        );
    }

    function GetPoolDistributionData(uint256 _Id)
        public
        view
        isPoolId(_Id)
        returns (
            uint,
            uint[] memory,
            uint[] memory,
            uint[] memory
        )
    {
        uint distributionCount = pools[_Id].MoreData.distributionCount;
        uint[] memory distributionTimeArr = new uint[](distributionCount);
        uint[] memory distributionShareArr = new uint[](distributionCount);
        uint[] memory distributionStatusArr = new uint[](distributionCount);
        for(uint i = 0;i<distributionCount;i++){
            distributionTimeArr[i] = pools[_Id].MoreData.DistributionData[i+1].distributionTime;
            distributionShareArr[i] = pools[_Id].MoreData.DistributionData[i+1].distributionShare;
            distributionStatusArr[i] = pools[_Id].MoreData.DistributionData[i+1].distributionStatus;
        }
        return (
            distributionCount,
            distributionTimeArr,
            distributionShareArr,
            distributionStatusArr
        );
    }

    function GetPoolStatus(uint256 _id)
        public
        view
        isPoolId(_id)
        returns (PoolStatus)
    {
        if (pools[_id].BaseData.Status==0) return PoolStatus.closed;
        //Don't like the logic here - ToDo Boolean checks (truth table)
        if (
            pools[_id].MoreData.distributionCount==0
        ) //no distribution rule
        {
            return (PoolStatus.PreCreated);
        }
        if (now < pools[_id].BaseData.StartTime) return PoolStatus.PreOpen;
        if (
            now < pools[_id].BaseData.EndTime &&
            pools[_id].BaseData.StartTime < now
        ) {
            return (PoolStatus.Open);
        }
        if (
            now > pools[_id].BaseData.EndTime &&
            pools[_id].MoreData.distributionCount >0 &&
            now < pools[_id].MoreData.DistributionData[1].distributionTime
        ) //no tokens on locked pool, got time
        {
            return (PoolStatus.PreDistribute);
        }
        if (
            now > pools[_id].BaseData.EndTime &&
            pools[_id].MoreData.distributionCount >0 &&
            now >= pools[_id].MoreData.DistributionData[1].distributionTime &&
            pools[_id].MoreData.DistributionData[pools[_id].MoreData.distributionCount].distributionStatus == 0
        ) //no tokens on direct pool
        {
            return (PoolStatus.Distributing);
        }
        if (
            now > pools[_id].BaseData.EndTime &&
            pools[_id].MoreData.distributionCount >0 &&
            now >= pools[_id].MoreData.DistributionData[pools[_id].MoreData.distributionCount].distributionTime &&
            pools[_id].MoreData.DistributionData[pools[_id].MoreData.distributionCount].distributionStatus == 1
        ) {
            // After finish time - not locked
            return (PoolStatus.Finished);
        }
        return (PoolStatus.closed);
    }

}

contract Invest is PoolsData {

    modifier CheckTime(uint256 _Time) {
        require(now >= _Time, "Pool not open yet");
        _;
    }

    modifier validateSender(){
        require(
            msg.sender == tx.origin && !isContract(msg.sender),
            "Some thing wrong with the msgSender"
        );
        _;
    }

    //using SafeMath for uint256;
    constructor() public {
        //TotalInvestors = 0;
    }

    //Investorsr Data
    uint256 internal TotalInvestors;

    mapping(uint256 => InvestorsData) poolInvestor;

    struct InvestorsData {
        uint TotalInvestors;
        mapping(address=>Investor) Investors;
    }

    struct Investor {
        uint256 Poolid; //the id of the pool, he got the rate info and the token, check if looked pool
        uint256 MainCoin; //the amount of the main coin invested (eth/dai), calc with rate
        uint256 InvestTime; //the time that investment made
        uint256 TotalTokensAmount; // total tokens amount
        uint256 DistributedAmount; // distributed amount
    }

    function getTotalInvestor() external view returns(uint256){
        return TotalInvestors;
    }

    function InvestERC20(uint256 _PoolId, uint256 _Amount)
        external
        whenNotPaused
        CheckTime(pools[_PoolId].BaseData.StartTime)
        isPoolId(_PoolId)
        validateSender()
    {
        require(GetPoolStatus(_PoolId) == PoolStatus.Open,"Wrong pool status to invest tokens");
        require(
            pools[_PoolId].BaseData.Maincoin != address(0x0),
            "Pool is for ETH, use InvestETH"
        );
        require(_Amount>0,"Need Valid _Amount");
        TransferInToken(pools[_PoolId].BaseData.Maincoin, msg.sender, _Amount);
        // 记录投资者，并拿到投资者的id(id可以拿到address)
        NewInvestor(msg.sender, _Amount, _PoolId);
        // 计算投资者可以拿到的目标token的数量
        uint256 Tokens = CalcTokens(_PoolId, _Amount);
        RegisterInvest(msg.sender,_PoolId, Tokens);
    }



    function CalcTokens(
        uint256 _PoolId,
        uint256 _Amount
    ) internal view returns (uint256) {
        uint256 msgValue = _Amount;
        uint256 result = 0;
        address _mainCoin = pools[_PoolId].BaseData.Maincoin;
        if(_mainCoin == address(0x0)){
                require(
                    msgValue >= MinETHInvest && msgValue <= MaxETHInvest,
                    "Investment amount not valid"
                );
            } else {
                require(
                    msgValue >= MinERC20Invest && msgValue <= MaxERC20Invest,
                    "Investment amount not valid"
                );
        }
        if(pools[_PoolId].BaseData.SwapType==0){
            result = SafeMath.mul(msgValue, pools[_PoolId].BaseData.SwapRate);
        }else if(pools[_PoolId].BaseData.SwapType==1){
            result = SafeMath.div(msgValue, pools[_PoolId].BaseData.SwapRate);
        }
        return result;
    }

    function NewInvestor(
        address _Sender,
        uint256 _Amount,
        uint256 _PoolId
    ) internal {
        require(poolInvestor[_PoolId].Investors[_Sender].MainCoin==0,"You have already invested");
        poolInvestor[_PoolId].Investors[_Sender] = Investor(
            _PoolId,
            _Amount,
            block.timestamp,
            0,
            0
        );
        TotalInvestors = SafeMath.add(TotalInvestors, 1);
        poolInvestor[_PoolId].TotalInvestors = SafeMath.add(poolInvestor[_PoolId].TotalInvestors,1);
    }

    function RegisterInvest(
        address _Sender,
        uint256 _PoolId, 
        uint256 _Tokens
    ) internal {
        pools[_PoolId].BaseData.SaledAmount = SafeMath.add(
            pools[_PoolId].BaseData.SaledAmount,
            _Tokens
        );
        poolInvestor[_PoolId].Investors[_Sender].TotalTokensAmount = _Tokens;
        require(pools[_PoolId].BaseData.SaledAmount<=pools[_PoolId].BaseData.StartAmount,"Not enough tokens in the pool");
        if (pools[_PoolId].BaseData.SaledAmount == pools[_PoolId].BaseData.StartAmount) emit FinishPool(_PoolId);
        else emit PoolUpdate(_PoolId);
    }

    //@dev use it with  require(msg.sender == tx.origin)
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

contract InvestorData is Invest {
    function GetInvestmentData(uint256 _PoolId, address _Investor)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            poolInvestor[_PoolId].Investors[_Investor].MainCoin,
            poolInvestor[_PoolId].Investors[_Investor].InvestTime,
            poolInvestor[_PoolId].Investors[_Investor].TotalTokensAmount,
            poolInvestor[_PoolId].Investors[_Investor].DistributedAmount
        );
    }

    function GetInvestorNum(uint256 _PoolId)
        public
        view
        returns (
            uint256
        )
    {
        return (
            poolInvestor[_PoolId].TotalInvestors
        );
    }
}

contract AcyV1Poolz is InvestorData {

    using SafeMath for uint;
    constructor() public {
        
    }

    function WithdrawERC20ToCreator(address _to,uint _PoolId) public isPoolId(_PoolId) onlyOwnerOrGov {
        require(
            GetPoolStatus(_PoolId) != PoolStatus.PreOpen &&
            GetPoolStatus(_PoolId) != PoolStatus.Open &&
            GetPoolStatus(_PoolId) != PoolStatus.closed ,
            "could not withdraw ERC20 now"
        );
        if(pools[_PoolId].BaseData.SaledAmount==0){
            pools[_PoolId].BaseData.Status = 0;
            TransferToken(pools[_PoolId].BaseData.Token, _to, pools[_PoolId].BaseData.StartAmount);
        }else{
            require(pools[_PoolId].BaseData.Status !=2,"don't withdraw tokens again");
            if(pools[_PoolId].BaseData.SaledAmount<pools[_PoolId].BaseData.StartAmount){
                TransferToken(pools[_PoolId].BaseData.Token, _to, SafeMath.sub(pools[_PoolId].BaseData.StartAmount, pools[_PoolId].BaseData.SaledAmount));
            }
            uint result = 0;
            if(pools[_PoolId].BaseData.SwapType == 0){
                result = SafeMath.div(pools[_PoolId].BaseData.SaledAmount,pools[_PoolId].BaseData.SwapRate);
            }else if(pools[_PoolId].BaseData.SwapType == 1){
                result = SafeMath.mul(pools[_PoolId].BaseData.SaledAmount,pools[_PoolId].BaseData.SwapRate);
            }
            if(result>0){
                TransferToken(pools[_PoolId].BaseData.Maincoin, _to, result);
            }
            pools[_PoolId].BaseData.Status = 2;
        }
    }

    function WithdrawERC20ToInvestor(uint _PoolId) isPoolId(_PoolId) public {
        require(
            GetPoolStatus(_PoolId) == PoolStatus.Distributing,
            "could not withdraw ERC20 now"
        );
        uint TotalTokensAmount = poolInvestor[_PoolId].Investors[msg.sender].TotalTokensAmount;
        uint DistributedAmount = poolInvestor[_PoolId].Investors[msg.sender].DistributedAmount;
        uint totalShare = 0;
        uint availableShare = 0;
        uint distributionCount = pools[_PoolId].MoreData.distributionCount;
        for(uint i=1;i<=distributionCount;i++){
            totalShare = totalShare + pools[_PoolId].MoreData.DistributionData[i].distributionShare;
            if(pools[_PoolId].MoreData.DistributionData[i].distributionTime<now){
                availableShare = availableShare + pools[_PoolId].MoreData.DistributionData[i].distributionShare;
            }
        }
        require(totalShare>0,"pool error");
        uint totalDistributionAmount = availableShare.mul(TotalTokensAmount).div(totalShare);
        require(DistributedAmount<totalDistributionAmount,"nothing could be distributed");
        
        poolInvestor[_PoolId].Investors[msg.sender].DistributedAmount = totalDistributionAmount;
        TransferToken(pools[_PoolId].BaseData.Token, msg.sender, totalDistributionAmount.sub(DistributedAmount));
    }


    function getNow() public view returns(uint){
        return now;
    }

}