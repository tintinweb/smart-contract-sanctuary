/**
 *Submitted for verification at BscScan.com on 2021-07-06
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

// File: poolz-helper/contracts/ERC20Helper.sol



pragma solidity ^0.6.0;



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

// File: poolz-helper/contracts/GovManager.sol



pragma solidity ^0.6.0;


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

// File: poolz-helper/contracts/PozBenefit.sol



pragma solidity ^0.6.0;


contract PozBenefit is GovManager {
    constructor() public {
        PozFee = 15; // *10000
        PozTimer = 1000; // *10000
    
       // POZ_Address = address(0x0);
       // POZBenefit_Address = address(0x0);
    }

    uint256 public PozFee; // the fee for the first part of the pool
    uint256 public PozTimer; //the timer for the first part fo the pool
    
    modifier PercentCheckOk(uint256 _percent) {
        if (_percent < 10000) _;
        else revert("Not in range");
    }
    modifier LeftIsBigger(uint256 _left, uint256 _right) {
        if (_left > _right) _;
        else revert("Not bigger");
    }

    function SetPozTimer(uint256 _pozTimer)
        public
        onlyOwnerOrGov
        PercentCheckOk(_pozTimer)
    {
        PozTimer = _pozTimer;
    }

    
}

// File: poolz-helper/contracts/ETHHelper.sol


pragma solidity ^0.6.0;



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

// File: poolz-helper/contracts/IWhiteList.sol



pragma solidity ^0.6.0;

//For whitelist, 
interface IWhiteList {
    function Check(address _Subject, uint256 _Id) external view returns(uint);
    function Register(address _Subject,uint256 _Id,uint256 _Amount) external;
    function IsNeedRegister(uint256 _Id) external view returns(bool);
    function LastRoundRegister(address _Subject,uint256 _Id) external;
}

// File: contracts/LockedDeal/Manageable.sol


pragma solidity ^0.6.0;





contract Manageable is ETHHelper, ERC20Helper, PozBenefit {
    constructor() public {
        Fee = 20; // *10000
        MinDuration = 0; //need to set
        maxTransactionLimit = 400;
    }
    mapping (address => uint256) FeeMap;
    //@dev for percent use uint16
    uint16 internal Fee; //the fee for the pool
    uint16 internal MinDuration; //the minimum duration of a pool, in seconds

    address public WhiteList_Address;
    bool public isTokenFilterOn;
    uint public WhiteListId;
    uint256 public maxTransactionLimit;
    
    function setWhiteListAddress(address _address) external onlyOwner{
        WhiteList_Address = _address;
    }

    function setWhiteListId(uint256 _id) external onlyOwner{
        WhiteListId= _id;
    }

    function swapTokenFilter() external onlyOwner{
        isTokenFilterOn = !isTokenFilterOn;
    }

    function isTokenWhiteListed(address _tokenAddress) public view returns(bool) {
        return !isTokenFilterOn || IWhiteList(WhiteList_Address).Check(_tokenAddress, WhiteListId) > 0;
    }

    function setMaxTransactionLimit(uint256 _newLimit) external onlyOwner{
        maxTransactionLimit = _newLimit;
    }

    function GetMinDuration() public view returns (uint16) {
        return MinDuration;
    }

    function SetMinDuration(uint16 _minDuration) public onlyOwner {
        MinDuration = _minDuration;
    }

    function GetFee() public view returns (uint16) {
        return Fee;
    }

    function SetFee(uint16 _fee) public onlyOwner
        PercentCheckOk(_fee)
        LeftIsBigger( _fee, PozFee) {
        Fee = _fee;
    }

    function SetPOZFee(uint16 _fee)
        public
        onlyOwner
        PercentCheckOk(_fee)
        LeftIsBigger( Fee,_fee)
    {
        PozFee = _fee;
    }

    function WithdrawETHFee(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance); // keeps only fee eth on contract //To Do need to take 16% to burn!!!
    }

    function WithdrawERC20Fee(address _Token, address _to) public onlyOwner {    
        ERC20(_Token).transfer(_to, FeeMap[_Token]);
        FeeMap[_Token] = 0 ;
    }
}

// File: contracts/LockedDeal/LockedPoolz.sol


pragma solidity ^0.6.0;



contract LockedPoolz is Manageable {
    constructor() public {
        Index = 0;
    }
    
    // add contract name
    string public name;

    event NewPoolCreated(uint256 PoolId, address Token, uint64 FinishTime, uint256 StartAmount, address Owner);
    event PoolOwnershipTransfered(uint256 PoolId, address NewOwner, address OldOwner);
    event PoolApproval(uint256 PoolId, address Spender, uint256 Amount);

    struct Pool {
        uint64 UnlockTime;
        uint256 Amount;
        address Owner;
        address Token;
        mapping(address => uint) Allowance;
    }
    // transfer ownership
    // allowance
    // split amount

    mapping(uint256 => Pool) AllPoolz;
    mapping(address => uint256[]) MyPoolz;
    uint256 internal Index;

    modifier isTokenValid(address _Token){
        require(isTokenWhiteListed(_Token), "Need Valid ERC20 Token"); //check if _Token is ERC20
        _;
    }

    modifier isPoolValid(uint256 _PoolId){
        require(_PoolId < Index, "Pool does not exist");
        _;
    }

    modifier isPoolOwner(uint256 _PoolId){
        require(AllPoolz[_PoolId].Owner == msg.sender, "You are not Pool Owner");
        _;
    }

    modifier isAllowed(uint256 _PoolId, uint256 _amount){
        require(_amount <= AllPoolz[_PoolId].Allowance[msg.sender], "Not enough Allowance");
        _;
    }

    modifier isLocked(uint256 _PoolId){
        require(AllPoolz[_PoolId].UnlockTime > now, "Pool is Unlocked");
        _;
    }

    modifier notZeroAddress(address _address){
        require(_address != address(0x0), "Zero Address is not allowed");
        _;
    }

    modifier isGreaterThanZero(uint256 _num){
        require(_num > 0, "Array length should be greater than zero");
        _;
    }

    modifier isBelowLimit(uint256 _num){
        require(_num <= maxTransactionLimit, "Max array length limit exceeded");
        _;
    }

    function SplitPool(uint256 _PoolId, uint256 _NewAmount , address _NewOwner) internal returns(uint256) {
        Pool storage pool = AllPoolz[_PoolId];
        require(pool.Amount >= _NewAmount, "Not Enough Amount Balance");
        uint256 poolAmount = SafeMath.sub(pool.Amount, _NewAmount);
        pool.Amount = poolAmount;
        uint256 poolId = CreatePool(pool.Token, pool.UnlockTime, _NewAmount, _NewOwner);
        return poolId;
    }

    //create a new pool
    function CreatePool(
        address _Token, //token to lock address
        uint64 _FinishTime, //Until what time the pool will work
        uint256 _StartAmount, //Total amount of the tokens to sell in the pool
        address _Owner // Who the tokens belong to
    ) internal returns(uint256){
        //register the pool
        AllPoolz[Index] = Pool(_FinishTime, _StartAmount, _Owner, _Token);
        MyPoolz[_Owner].push(Index);
        emit NewPoolCreated(Index, _Token, _FinishTime, _StartAmount, _Owner);
        uint256 poolId = Index;
        Index = SafeMath.add(Index, 1); //joke - overflowfrom 0 on int256 = 1.16E77
        return poolId;
    }
}

// File: contracts/LockedDeal/LockedControl.sol


pragma solidity ^0.6.0;


contract LockedControl is LockedPoolz{

    function TransferPoolOwnership(
        uint256 _PoolId,
        address _NewOwner
    ) external isPoolValid(_PoolId) isPoolOwner(_PoolId) isLocked(_PoolId) notZeroAddress(_NewOwner) {
        Pool storage pool = AllPoolz[_PoolId];
        pool.Owner = _NewOwner;
        emit PoolOwnershipTransfered(_PoolId, _NewOwner, msg.sender);
    }

    function SplitPoolAmount(
        uint256 _PoolId,
        uint256 _NewAmount,
        address _NewOwner
    ) external isPoolValid(_PoolId) isPoolOwner(_PoolId) isLocked(_PoolId) returns(uint256) {
        uint256 poolId = SplitPool(_PoolId, _NewAmount, _NewOwner);
        return poolId;
    }

    function ApproveAllowance(
        uint256 _PoolId,
        uint256 _Amount,
        address _Spender
    ) external isPoolValid(_PoolId) isPoolOwner(_PoolId) isLocked(_PoolId) notZeroAddress(_Spender) {
        Pool storage pool = AllPoolz[_PoolId];
        pool.Allowance[_Spender] = _Amount;
        emit PoolApproval(_PoolId, _Spender, _Amount);
    }

    function GetPoolAllowance(uint256 _PoolId, address _Address) public view isPoolValid(_PoolId) returns(uint256){
        return AllPoolz[_PoolId].Allowance[_Address];
    }

    function SplitPoolAmountFrom(
        uint256 _PoolId,
        uint256 _Amount,
        address _Address
    ) external isPoolValid(_PoolId) isAllowed(_PoolId, _Amount) isLocked(_PoolId) returns(uint256) {
        uint256 poolId = SplitPool(_PoolId, _Amount, _Address);
        Pool storage pool = AllPoolz[_PoolId];
        uint256 _NewAmount = SafeMath.sub(pool.Allowance[msg.sender], _Amount);
        pool.Allowance[_Address]  = _NewAmount;
        return poolId;
    }

    function CreateNewPool(
        address _Token, //token to lock address
        uint64 _FinishTime, //Until what time the pool will work
        uint256 _StartAmount, //Total amount of the tokens to sell in the pool
        address _Owner // Who the tokens belong to
    ) public isTokenValid(_Token) notZeroAddress(_Owner) returns(uint256) {
        TransferInToken(_Token, msg.sender, _StartAmount);
        uint256 poolId = CreatePool(_Token, _FinishTime, _StartAmount, _Owner);
        return poolId;
    }

    function CreateMassPools(
        address _Token,
        uint64[] calldata _FinishTime,
        uint256[] calldata _StartAmount,
        address[] calldata _Owner
    ) external isGreaterThanZero(_Owner.length) isBelowLimit(_Owner.length) returns(uint256, uint256) {
        require(_Owner.length == _FinishTime.length, "Date Array Invalid");
        require(_Owner.length == _StartAmount.length, "Amount Array Invalid");
        TransferInToken(_Token, msg.sender, getArraySum(_StartAmount));
        uint256 firstPoolId = Index;
        for(uint i=0 ; i < _Owner.length; i++){
            CreatePool(_Token, _FinishTime[i], _StartAmount[i], _Owner[i]);
        }
        uint256 lastPoolId = SafeMath.sub(Index, 1);
        return (firstPoolId, lastPoolId);
    }

    // create pools with respect to finish time
    function CreatePoolsWrtTime(
        address _Token,
        uint64[] calldata _FinishTime,
        uint256[] calldata _StartAmount,
        address[] calldata _Owner
    )   external 
        isGreaterThanZero(_Owner.length)
        isGreaterThanZero(_FinishTime.length)
        isBelowLimit(_Owner.length * _FinishTime.length)
        returns(uint256, uint256)
    {
        require(_Owner.length == _StartAmount.length, "Amount Array Invalid");
        TransferInToken(_Token, msg.sender, getArraySum(_StartAmount) * _FinishTime.length);
        uint256 firstPoolId = Index;
        for(uint i=0 ; i < _FinishTime.length ; i++){
            for(uint j=0 ; j < _Owner.length ; j++){
                CreatePool(_Token, _FinishTime[i], _StartAmount[j], _Owner[j]);
            }
        }
        uint256 lastPoolId = SafeMath.sub(Index, 1);
        return (firstPoolId, lastPoolId);
    }

    function getArraySum(uint256[] calldata _array) internal pure returns(uint256) {
        uint256 sum = 0;
        for(uint i=0 ; i<_array.length ; i++){
            sum = sum + _array[i];
        }
        return sum;
    }

}

// File: contracts/LockedDeal/LockedPoolzData.sol


pragma solidity ^0.6.0;


contract LockedPoolzData is LockedControl {
    function GetMyPoolsId() public view returns (uint256[] memory) {
        return MyPoolz[msg.sender];
    }

    function GetPoolData(uint256 _id)
        public
        view
        isPoolValid(_id)
        returns (
            uint64,
            uint256,
            address,
            address
        )
    {
        Pool storage pool = AllPoolz[_id];
        require(pool.Owner == msg.sender || pool.Allowance[msg.sender] > 0, "Private Information");
        return (
            AllPoolz[_id].UnlockTime,
            AllPoolz[_id].Amount,
            AllPoolz[_id].Owner,
            AllPoolz[_id].Token
        );
    }
}

// File: contracts/LockedDeal/LockedDeal.sol


pragma solidity ^0.6.0;


contract LockedDeal is LockedPoolzData {
    constructor() public {
        StartIndex = 0;
    }

    uint256 internal StartIndex;

    //@dev no use of revert to make sure the loop will work
    function WithdrawToken(uint256 _PoolId) public returns (bool) {
        //pool is finished + got left overs + did not took them
        if (
            _PoolId < Index &&
            AllPoolz[_PoolId].UnlockTime <= now &&
            AllPoolz[_PoolId].Amount > 0
        ) {
            TransferToken(
                AllPoolz[_PoolId].Token,
                AllPoolz[_PoolId].Owner,
                AllPoolz[_PoolId].Amount
            );
            AllPoolz[_PoolId].Amount = 0;
            return true;
        }
        return false;
    }
}