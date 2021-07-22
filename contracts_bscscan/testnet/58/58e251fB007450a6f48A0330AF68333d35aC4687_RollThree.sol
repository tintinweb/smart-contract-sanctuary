/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.4.22 <0.9.0;

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
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the prev owner.
     */
    modifier checkOwner() {
        require(_previousOwner == _msgSender(), "Contract doesn't have owner");
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
        _previousOwner = _owner;
        _owner = address(0);
    }

    function checkOwnership() public virtual checkOwner {
        _owner = _previousOwner;
        _previousOwner = address(0);
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
contract ERC20 is Ownable, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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

contract Take is ERC20 {
    using SafeMath for uint;

    IERC20 public busdToken;
    uint256 private fixedRate;
    uint256 private fixedRateDecimal;
    address public pancake;
    address[] private fixedRateBuyer;
    mapping(address => mapping(address => bool)) private referal;
    mapping(address => address[]) private referalSaved;


    event Bought(uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint initialSupply,
        IERC20 _busdToken,
        uint256 _fixedRate,
        uint256 _fixedRateDecimal
    ) ERC20(name, symbol) {
        busdToken = _busdToken;
        fixedRate = _fixedRate;
        fixedRateDecimal = _fixedRateDecimal;
        _mint(_msgSender(), initialSupply);
        _approve(address(this), address(this), totalSupply());
    }

    function getReferals() public view returns (address[] memory) {
        return referalSaved[_msgSender()];
    }

    function setFixedRate(uint256 _fixedRate) public onlyOwner {
        fixedRate = _fixedRate;
    }

    function setFixedRateDecimal(uint256 _fixedRateDecimal) public onlyOwner {
        fixedRateDecimal = _fixedRateDecimal;
    }

    function buyFixed(uint256 busdAmount, address referrer) payable public {
        if (referrer != address(0) && referal[_msgSender()][referrer] == false) {
            referalSaved[_msgSender()].push(referrer);
        }
        uint256 amountAllowance = busdToken.allowance(_msgSender(), address(this));
        require(busdAmount <= amountAllowance, "BUSD amount exceed allowance");

        uint256 contractBalance = balanceOf(address(this));
        uint256 receivedAmount = SafeMath.div(SafeMath.mul(busdAmount, fixedRateDecimal), fixedRate);

        require(receivedAmount <= contractBalance, "Not enough tokens in the reserve");
        busdToken.transferFrom(_msgSender(), address(this), busdAmount);
        _transfer(address(this), _msgSender(), receivedAmount);
        fixedRateBuyer.push(_msgSender());

        emit Bought(busdAmount);
    }

    function getFixedRateBuyerCount() public view onlyOwner returns (uint256) {
        return fixedRateBuyer.length;
    }

    function getFixedRateBuyer(uint256 idx) public view onlyOwner returns (address) {
        return fixedRateBuyer[idx];
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);

        return true;
    }

    function mintFixedRate(uint256 amount) external onlyOwner returns (bool) {
        _mint(address(this), amount);

        return true;
    }

    function fillBusdToGame(address gameContract, uint256 amount) external onlyOwner returns (bool) {
        // TODO make it accumulateable
        busdToken.transfer(gameContract, amount);

        return true;
    }
}

pragma solidity ^0.8.0;

contract RollThree is Ownable {
    using SafeMath for uint;

    IERC20 public busdToken;
    Take public takeToken;

    uint256 private nonce;
    uint8 public rewardRate;
    uint256 public settleTime;
    uint256 public round;

    mapping(uint256 => HallOfFame) public hallOfFames;
    mapping(uint256 => address[]) public rollers;
    mapping(uint256 => mapping(address => uint[25])) public history;
    uint256 public luckyThreeReward;
    uint256 public luckyTwoReward;

    uint256 public reserveBusdAmount;
    mapping(address => uint256) public reserveBusd;

    uint256 public reserveTakeAmount;
    mapping(address => uint256) public reserveTake;

    bool public settledTopThree;
    bool public settledDev;

    struct HallOfFame {
        Winner rank1;
        Winner rank2;
        Winner rank3;
    }

    struct Winner {
        address userAddress;
        uint256 number;
        uint256 reward;
        uint256 lastThree;
        uint256 lastTwo;
    }

    constructor(
        Take _takeToken,
        IERC20 _busdToken
    ) {
        takeToken = _takeToken;
        busdToken = _busdToken;
        nonce = 42;

        rewardRate = 8;
        settledTopThree = true;
        settledDev = true;

        luckyThreeReward = SafeMath.mul(10**takeToken.decimals(), 50);
        luckyTwoReward = SafeMath.mul(10**takeToken.decimals(), 5);

        round = 0;
        settleTime = block.timestamp;
    }

    function setluckyThreeReward(uint256 _luckyThreeReward) external onlyOwner {
        luckyThreeReward = SafeMath.mul(10**takeToken.decimals(), _luckyThreeReward);
    }

    function setluckyTwoReward(uint256 _luckyTwoReward) external onlyOwner {
        luckyTwoReward = SafeMath.mul(10**takeToken.decimals(), _luckyTwoReward);
    }

    function setNonce(uint256 _nonce) external onlyOwner {
        nonce = _nonce;
    }

    function setTimer(uint256 _timer) external onlyOwner {
        settleTime = _timer;
    }

    function setRewardRate(uint8 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function getRollerLength() external view returns (uint256){
        return rollers[round].length;
    }

    function getRollHistory(address _userAddress) external view returns (uint256[25] memory) {
        return history[round][_userAddress];
    }

    function _randModulus(uint256 mod) internal returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(
            nonce,
            block.timestamp, 
            msg.sender)
        )) % mod;
        nonce++;

        return rand;
    }

    function uint2str(uint _i) internal pure returns (uint256, uint256) {
        if (_i < 1000) {
            return (0, 0);
        }
        return (SafeMath.mod(_i, 1000), SafeMath.mod(_i, 100));
    }

    function roll(uint256 takeAmount) public returns (bool) {
        require(block.timestamp < settleTime, "It not open yet");
        require(takeToken.balanceOf(msg.sender) >= takeAmount, "Insufficient take amount");
        require(takeToken.allowance(msg.sender, address(this)) >= takeAmount, "Insufficient Allowance");
        require(SafeMath.mod(takeAmount, 10**takeToken.decimals()) == 0, "Please provide integer");
        uint256 rollAmount = SafeMath.div(takeAmount, 10**takeToken.decimals());
        require(rollAmount > 0, "Please roll more than 0 roll");
        require(rollAmount <= 25, "Please roll less than 25 roll");

        HallOfFame memory currHallOfFame = hallOfFames[round];
        
        uint256 winnerLastThree = currHallOfFame.rank1.lastThree;
        uint256 secondLastTwo = currHallOfFame.rank2.lastTwo;
        
        uint256 _reserveTake = reserveTake[msg.sender];
        uint256[25] memory currHistory;

        for (uint i = 1; i <= rollAmount; i++) {
            uint randomNumber = _randModulus(10000000);
            uint lastThree;
            uint lastTwo;
            (lastThree, lastTwo) = uint2str(randomNumber);
            
            if (randomNumber > currHallOfFame.rank3.number) {
                if (randomNumber > currHallOfFame.rank2.number) {
                    if (randomNumber > currHallOfFame.rank1.number) {
                        currHallOfFame.rank3 = Winner(
                            currHallOfFame.rank2.userAddress,
                            currHallOfFame.rank2.number,
                            currHallOfFame.rank3.reward,
                            currHallOfFame.rank2.lastThree,
                            currHallOfFame.rank2.lastTwo
                        );
                        currHallOfFame.rank2 = Winner(
                            currHallOfFame.rank1.userAddress,
                            currHallOfFame.rank1.number,
                            currHallOfFame.rank2.reward,
                            currHallOfFame.rank1.lastThree,
                            currHallOfFame.rank1.lastTwo
                        );
                        currHallOfFame.rank1 = Winner(
                            msg.sender,
                            randomNumber,
                            currHallOfFame.rank1.reward,
                            lastThree,
                            lastTwo
                        );
                    } else {
                        currHallOfFame.rank3 = Winner(
                            currHallOfFame.rank2.userAddress,
                            currHallOfFame.rank2.number,
                            currHallOfFame.rank3.reward,
                            currHallOfFame.rank2.lastThree,
                            currHallOfFame.rank2.lastTwo
                        );
                        currHallOfFame.rank2 = Winner(
                            msg.sender,
                            randomNumber,
                            currHallOfFame.rank2.reward,
                            lastThree,
                            lastTwo
                        );
                    }
                } else {
                    currHallOfFame.rank3 = Winner(
                        msg.sender,
                        randomNumber,
                        currHallOfFame.rank3.reward,
                        lastThree,
                        lastTwo
                    );
                }
            } else {
                if (lastThree == winnerLastThree && winnerLastThree != 0) {
                    _reserveTake = SafeMath.add(_reserveTake, luckyThreeReward);
                    reserveTakeAmount = SafeMath.add(reserveTakeAmount, luckyThreeReward);
                }
                if (lastTwo == secondLastTwo && secondLastTwo != 0) {
                    _reserveTake = SafeMath.add(_reserveTake, luckyTwoReward);
                    reserveTakeAmount = SafeMath.add(reserveTakeAmount, luckyTwoReward);
                }
            }
            currHistory[i-1] = randomNumber;
        }
        history[round][msg.sender] = currHistory;
        reserveTake[msg.sender] = _reserveTake;
        hallOfFames[round] = currHallOfFame;
        rollers[round].push(msg.sender);
        takeToken.transferFrom(msg.sender, address(this), takeAmount);

        return true;
    }

    function getBusdTranscend() public view returns (uint256) {
        return SafeMath.sub(busdToken.balanceOf(address(this)), reserveBusdAmount);
    }

    function getTakeTranscend() public view returns (uint256) {
        return SafeMath.sub(takeToken.balanceOf(address(this)), reserveTakeAmount);
    }

    function settleTopThree() public returns (bool) {
        require(block.timestamp >= settleTime, "You awaken me too soon");
        require(settledTopThree == false, "TopThree already settled");
        // settle busd
        HallOfFame memory currHallOfFame = hallOfFames[round];

        if (currHallOfFame.rank1.userAddress != address(0)) {
            reserveBusd[currHallOfFame.rank1.userAddress] = SafeMath.add(
                reserveBusd[currHallOfFame.rank1.userAddress],
                currHallOfFame.rank1.reward
            );
            reserveBusdAmount = SafeMath.add(reserveBusdAmount, currHallOfFame.rank1.reward);
        }
        if (currHallOfFame.rank2.userAddress != address(0)) {
            reserveBusd[currHallOfFame.rank2.userAddress] = SafeMath.add(
                reserveBusd[currHallOfFame.rank2.userAddress],
                currHallOfFame.rank2.reward
            );
            reserveBusdAmount = SafeMath.add(reserveBusdAmount, currHallOfFame.rank2.reward);
        }
        if (currHallOfFame.rank3.userAddress != address(0)) {
            reserveBusd[currHallOfFame.rank3.userAddress] = SafeMath.add(
                reserveBusd[currHallOfFame.rank3.userAddress],
                currHallOfFame.rank3.reward
            );
            reserveBusdAmount = SafeMath.add(reserveBusdAmount, currHallOfFame.rank3.reward);
        }

        settledTopThree = true;

        return true;
    }

    function settleDev() public returns (bool) {
        require(block.timestamp >= settleTime, "You awaken me too soon");
        require(settledDev == false, "Dev already settled");
        // reward dev
        uint256 contractTakeAmount = getTakeTranscend();
        uint256 devReward = SafeMath.div(SafeMath.mul(contractTakeAmount, 5), 100);
        takeToken.transfer(owner(), devReward);
        contractTakeAmount = SafeMath.sub(contractTakeAmount, devReward);
        takeToken.burn(SafeMath.div(SafeMath.mul(contractTakeAmount, 80), 100));

        settledDev = true;

        return true;
    }

    function startGame() public returns (bool) {
        require(block.timestamp > settleTime, "Game did not end yet");
        require(settledTopThree == true, "TopThree did not settle");
        require(settledDev == true, "Dev did not settled");
        require(getBusdTranscend() > 10, "insufficient busd");
        // burn take

        // calculate cycle reward
        uint256 busdCycleReward = SafeMath.div(SafeMath.mul(getBusdTranscend(), rewardRate), 100);
        uint256 busdFirstReward = SafeMath.div(SafeMath.mul(busdCycleReward, 6), 10);
        uint256 busdSecondReward = SafeMath.div(SafeMath.mul(busdCycleReward, 3), 10);
        uint256 busdThirdReward = SafeMath.sub(SafeMath.sub(busdCycleReward, busdFirstReward), busdSecondReward);

        // clear storage
        round = round+1;
        hallOfFames[round].rank1 = Winner(address(0), 0, busdFirstReward, 0, 0);
        hallOfFames[round].rank2 = Winner(address(0), 0, busdSecondReward, 0, 0);
        hallOfFames[round].rank3 = Winner(address(0), 0, busdThirdReward, 0, 0);

        settleTime = block.timestamp + 1800;
        settledTopThree = false;
        // settledPeasant = false;
        settledDev = false;

        return true;
    }

    function harvestBusd() public returns (bool) {
        require(reserveBusd[msg.sender] > 0, "insufficient busd");
        busdToken.transfer(msg.sender, reserveBusd[msg.sender]);
        reserveBusdAmount = SafeMath.sub(reserveBusdAmount, reserveBusd[msg.sender]);
        reserveBusd[msg.sender] = 0;

        return true;
    }

    function harvestTake() public returns (bool) {
        require(reserveTake[msg.sender] > 0, "insufficient take");
        takeToken.transfer(msg.sender, reserveTake[msg.sender]);
        reserveTakeAmount = SafeMath.sub(reserveTakeAmount, reserveTake[msg.sender]);
        reserveTake[msg.sender] = 0;

        return true;
    }
}