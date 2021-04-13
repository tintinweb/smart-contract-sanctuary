/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// Sources flattened with hardhat v2.0.10 https://hardhat.org

// File contracts/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

/*
                                              dHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHb   
                                              HHP%%#%%%%%%%%%%%%%%%%#%%%%%%%#%%VHH
                                              HH%%%%%%%%%%#%v~~~~~~\%%%#%%%%%%%%HH
                                              HH%%%%%#%%%%v'        ~~~~\%%%%%#%HH
                                              HH%%#%%%%%%v'dHHb      a%%%#%%%%%%HH
                                              HH%%%%%#%%v'dHHHA     :%%%%%%#%%%%HH
                                              HH%%%#%%%v' VHHHHaadHHb:%#%%%%%%%%HH
                                              HH%%%%%#v'   `VHHHHHHHHb:%%%%%#%%%HH
                                              HH%#%%%v'      `VHHHHHHH:%%%#%%#%%HH
                                              HH%%%%%'        dHHHHHHH:%%#%%%%%%HH
                                              HH%%#%%        dHHHHHHHH:%%%%%%#%%HH
                                              HH%%%%%       dHHHHHHHHH:%%#%%%%%%HH
                                              HH#%%%%       VHHHHHHHHH:%%%%%#%%%HH
                                              HH%%%%#   b    HHHHHHHHV:%%%#%%%%#HH
                                              HH%%%%%   Hb   HHHHHHHV'%%%%%%%%%%HH
                                              HH%%#%%   HH  dHHHHHHV'%%%#%%%%%%%HH
                                              HH%#%%%   VHbdHHHHHHV'#%%%%%%%%#%%HH
                                              HHb%%#%    VHHHHHHHV'%%%%%#%%#%%%%HH
                                              HHHHHHHb    VHHHHHHH:%odHHHHHHbo%dHH
                                              HHHHHHHHboodboooooodHHHHHHHHHHHHHHHH
                                              HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                              HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                              VHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHGGN94
 ___  ___  ___  ___  ________  ________  ___       _______       ________ ___  ________   ________  ________   ________  _______      
|\  \|\  \|\  \|\  \|\   ___ \|\   ___ \|\  \     |\  ___ \     |\  _____|\  \|\   ___  \|\   __  \|\   ___  \|\   ____\|\  ___ \     
\ \  \\\  \ \  \\\  \ \  \_|\ \ \  \_|\ \ \  \    \ \   __/|    \ \  \__/\ \  \ \  \\ \  \ \  \|\  \ \  \\ \  \ \  \___|\ \   __/|    
 \ \   __  \ \  \\\  \ \  \ \\ \ \  \ \\ \ \  \    \ \  \_|/__   \ \   __\\ \  \ \  \\ \  \ \   __  \ \  \\ \  \ \  \    \ \  \_|/__  
  \ \  \ \  \ \  \\\  \ \  \_\\ \ \  \_\\ \ \  \____\ \  \_|\ \ __\ \  \_| \ \  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \____\ \  \_|\ \ 
   \ \__\ \__\ \_______\ \_______\ \_______\ \_______\ \_______|\__\ \__\   \ \__\ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \_______\
    \|__|\|__|\|_______|\|_______|\|_______|\|_______|\|_______\|__|\|__|    \|__|\|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|_______|
*/

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


// File contracts/contracts/token/ERC20/IERC20.sol

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


// File contracts/contracts/math/SafeMath.sol

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


// File contracts/contracts/token/ERC20/ERC20.sol

// SPDX-License-Identifier: MIT

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


// File contracts/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

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


// File contracts/HUDLToken.sol

pragma solidity >=0.6.6;


/*
                                              dHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHb   
                                              HHP%%#%%%%%%%%%%%%%%%%#%%%%%%%#%%VHH
                                              HH%%%%%%%%%%#%v~~~~~~\%%%#%%%%%%%%HH
                                              HH%%%%%#%%%%v'        ~~~~\%%%%%#%HH
                                              HH%%#%%%%%%v'dHHb      a%%%#%%%%%%HH
                                              HH%%%%%#%%v'dHHHA     :%%%%%%#%%%%HH
                                              HH%%%#%%%v' VHHHHaadHHb:%#%%%%%%%%HH
                                              HH%%%%%#v'   `VHHHHHHHHb:%%%%%#%%%HH
                                              HH%#%%%v'      `VHHHHHHH:%%%#%%#%%HH
                                              HH%%%%%'        dHHHHHHH:%%#%%%%%%HH
                                              HH%%#%%        dHHHHHHHH:%%%%%%#%%HH
                                              HH%%%%%       dHHHHHHHHH:%%#%%%%%%HH
                                              HH#%%%%       VHHHHHHHHH:%%%%%#%%%HH
                                              HH%%%%#   b    HHHHHHHHV:%%%#%%%%#HH
                                              HH%%%%%   Hb   HHHHHHHV'%%%%%%%%%%HH
                                              HH%%#%%   HH  dHHHHHHV'%%%#%%%%%%%HH
                                              HH%#%%%   VHbdHHHHHHV'#%%%%%%%%#%%HH
                                              HHb%%#%    VHHHHHHHV'%%%%%#%%#%%%%HH
                                              HHHHHHHb    VHHHHHHH:%odHHHHHHbo%dHH
                                              HHHHHHHHboodboooooodHHHHHHHHHHHHHHHH
                                              HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                              HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                              VHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHGGN94
 ___  ___  ___  ___  ________  ________  ___       _______       ________ ___  ________   ________  ________   ________  _______      
|\  \|\  \|\  \|\  \|\   ___ \|\   ___ \|\  \     |\  ___ \     |\  _____|\  \|\   ___  \|\   __  \|\   ___  \|\   ____\|\  ___ \     
\ \  \\\  \ \  \\\  \ \  \_|\ \ \  \_|\ \ \  \    \ \   __/|    \ \  \__/\ \  \ \  \\ \  \ \  \|\  \ \  \\ \  \ \  \___|\ \   __/|    
 \ \   __  \ \  \\\  \ \  \ \\ \ \  \ \\ \ \  \    \ \  \_|/__   \ \   __\\ \  \ \  \\ \  \ \   __  \ \  \\ \  \ \  \    \ \  \_|/__  
  \ \  \ \  \ \  \\\  \ \  \_\\ \ \  \_\\ \ \  \____\ \  \_|\ \ __\ \  \_| \ \  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \____\ \  \_|\ \ 
   \ \__\ \__\ \_______\ \_______\ \_______\ \_______\ \_______|\__\ \__\   \ \__\ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \_______\
    \|__|\|__|\|_______|\|_______|\|_______|\|_______|\|_______\|__|\|__|    \|__|\|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|_______|
*/

contract HUDLToken is Ownable, ERC20{
    /* Scalar for safe math */
    uint256 scalar = 1000000;
    /* Max supply of HUDL tokens */
    uint256 maxSupply = 40000000 * 10**18;
    /* Initial supply for distributor */
    uint256 initialSupply = 2000000 * 10**18;
    /* Initial founder supply*/
    uint256 initialFounderSupply = 500000 * 10**18;
    /* Max pool supply scaled 10000 = 1% */
    uint256 poolMaxSize = 10000;
    /* Min pool supply scaled 100 = 0.01% */
    uint256 poolMinSize = 100;
    /* Timestamp for tracking */
    uint256 lastPoolTimeStamp = block.timestamp;
    /* Distributor contract address */
    address distributorAddress = address(0);
    /* HUDL pool contract address */
    address hudlPoolAddress = address(0);
    /* How much tokens are in reserve for the pool */ 
    uint256 amountInReserve = maxSupply;
    /* How much tokens are in reserve for the pool */ 
    uint256 mintTimeLock = 0;
    /* have the initial tokens been minted? */ 
    bool initialMinted = false;

    constructor (string memory name, string memory symbol, uint256 timeLock) public ERC20(name, symbol) Ownable(){
        mintTimeLock = timeLock + 60 days; 
    }


    /*** GETTER FUNCTIONS ***/
    function getHudlPoolAddress() external view returns(address){
        return hudlPoolAddress;
    }

    function getDistributorAddress() external view returns(address){
        return distributorAddress;
    }

   function getAmountInReserve() external view returns(uint256){
        return amountInReserve;
    }

    function getMaxPoolSize() external view returns(uint256, uint256, uint256, uint256){
        uint256 tempPool;
        if(block.timestamp - lastPoolTimeStamp > 24 hours){
            tempPool = 10000;
        }
        else{
            tempPool = poolMaxSize + (((block.timestamp - lastPoolTimeStamp) * 24 hours * (10000 - poolMaxSize)) / 24 hours) / 24 hours;
        }
        uint256 responseTokensMinSize = amountInReserve/10000;
        uint256 responseTokensMaxSize = (tempPool * amountInReserve) / scalar;

        return (poolMaxSize, tempPool, responseTokensMinSize, responseTokensMaxSize);
    }
    

    /*** MUTATOR FUNCTIONS ***/
    /* Allows the distributor contract to mint tokens into its address */
    function mintInitial() external onlyOwner{
        require(distributorAddress != address(0), "Distributor address required");
        require(!initialMinted, "Can only initially mint once");
        _mint(distributorAddress, initialSupply);
        _mint(owner(), initialFounderSupply);
        amountInReserve = amountInReserve - initialSupply - initialFounderSupply;
        initialMinted = true;
    }

    /* Allows the hudl pool contract to mint tokens into its address */
    function hudlCreatePool(uint256 size) external onlyOwner{
        uint256 tempPool;
        require(block.timestamp >= mintTimeLock, "Require distribution to be over");
        
        if(block.timestamp - lastPoolTimeStamp > 24 hours){
            tempPool = 10000;
        }
        else{
            tempPool = poolMaxSize + (((block.timestamp - lastPoolTimeStamp) * 24 hours * (10000 - poolMaxSize)) / 24 hours) / 24 hours;
        }

        if(((size * scalar) / amountInReserve) > tempPool){
            revert("Pool too big");
        }
        if(((size * scalar) / amountInReserve) < poolMinSize){
            revert("Pool too small");
        }
        else{
            /* Check if pool goes under 3000 with an subtraction overflow protection*/
            if(((poolMaxSize - ((size * 700000) / amountInReserve)) > 3000) && ((poolMaxSize - ((size * 700000) / amountInReserve)) < 10000000000000000)){
                poolMaxSize = poolMaxSize - ((size * 700000) / (amountInReserve));
            }  
            else{  
                poolMaxSize = 3000;
            }
        }
        
        lastPoolTimeStamp = block.timestamp;
        
        amountInReserve -= size;

        _mint(hudlPoolAddress, size);
    }

    /* Allows the distributor to send tokens to the uniswapv2 contract */
    function approvePair(address pair) external{
        approve(distributorAddress, initialSupply);
        _approve(distributorAddress, pair, initialSupply);
    }

    /*** SETTER FUNCTIONS ***/

    /* Sets the hudl pool contract address */
    function setHudlPoolAddress(address newAddress) external onlyOwner{
        hudlPoolAddress = newAddress;
        transferOwnership(hudlPoolAddress);
    }

    /* Sets the distributor contract address */
    function setDistributorAddress(address newAddress) external onlyOwner{
        require(distributorAddress == address(0), "Can only set once");
        distributorAddress = newAddress;
    }
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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


// File @uniswap/lib/contracts/libraries/[email protected]

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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


// File contracts/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}


// File contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/HuddlDistributionContract.sol

pragma solidity >=0.6.6;






/*
                                              dHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHb   
                                              HHP%%#%%%%%%%%%%%%%%%%#%%%%%%%#%%VHH
                                              HH%%%%%%%%%%#%v~~~~~~\%%%#%%%%%%%%HH
                                              HH%%%%%#%%%%v'        ~~~~\%%%%%#%HH
                                              HH%%#%%%%%%v'dHHb      a%%%#%%%%%%HH
                                              HH%%%%%#%%v'dHHHA     :%%%%%%#%%%%HH
                                              HH%%%#%%%v' VHHHHaadHHb:%#%%%%%%%%HH
                                              HH%%%%%#v'   `VHHHHHHHHb:%%%%%#%%%HH
                                              HH%#%%%v'      `VHHHHHHH:%%%#%%#%%HH
                                              HH%%%%%'        dHHHHHHH:%%#%%%%%%HH
                                              HH%%#%%        dHHHHHHHH:%%%%%%#%%HH
                                              HH%%%%%       dHHHHHHHHH:%%#%%%%%%HH
                                              HH#%%%%       VHHHHHHHHH:%%%%%#%%%HH
                                              HH%%%%#   b    HHHHHHHHV:%%%#%%%%#HH
                                              HH%%%%%   Hb   HHHHHHHV'%%%%%%%%%%HH
                                              HH%%#%%   HH  dHHHHHHV'%%%#%%%%%%%HH
                                              HH%#%%%   VHbdHHHHHHV'#%%%%%%%%#%%HH
                                              HHb%%#%    VHHHHHHHV'%%%%%#%%#%%%%HH
                                              HHHHHHHb    VHHHHHHH:%odHHHHHHbo%dHH
                                              HHHHHHHHboodboooooodHHHHHHHHHHHHHHHH
                                              HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                              HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
                                              VHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHGGN94
 ___  ___  ___  ___  ________  ________  ___       _______       ________ ___  ________   ________  ________   ________  _______      
|\  \|\  \|\  \|\  \|\   ___ \|\   ___ \|\  \     |\  ___ \     |\  _____|\  \|\   ___  \|\   __  \|\   ___  \|\   ____\|\  ___ \     
\ \  \\\  \ \  \\\  \ \  \_|\ \ \  \_|\ \ \  \    \ \   __/|    \ \  \__/\ \  \ \  \\ \  \ \  \|\  \ \  \\ \  \ \  \___|\ \   __/|    
 \ \   __  \ \  \\\  \ \  \ \\ \ \  \ \\ \ \  \    \ \  \_|/__   \ \   __\\ \  \ \  \\ \  \ \   __  \ \  \\ \  \ \  \    \ \  \_|/__  
  \ \  \ \  \ \  \\\  \ \  \_\\ \ \  \_\\ \ \  \____\ \  \_|\ \ __\ \  \_| \ \  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \____\ \  \_|\ \ 
   \ \__\ \__\ \_______\ \_______\ \_______\ \_______\ \_______|\__\ \__\   \ \__\ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \_______\
    \|__|\|__|\|_______|\|_______|\|_______|\|_______|\|_______\|__|\|__|    \|__|\|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|_______|
*/

contract HuddlDistributionContract is Ownable{
  /* Total amount of deposited ETH in contract */
  uint256 totalETH;
  /* Total amount of HUDL in contract */
  uint256 totalHUDL = 2000000 * 10**18;
  /* Total supply of initial LP in contract */
  uint256 initTotalLP;
  /* Total of locked vesting LP in contract */
  uint256 lockedLPTokens;
  /* Total unlocked vesting LP in contract */
  uint256 unlockedLPTokens;
  /* Total amount of LP tokens claimed */
  uint256 totalLPClaimed;
  /* Start date of despositing into the distributor */
  uint256 startDate;
  /* Deposit end date of despositing into the distributor */
  uint256 depositEndDate;
  /* Total vesting period time */
  uint256 vestingSchedule;                                             
  /* Date for deployment of the distributor */
  uint256 deployDate;
  /* Checks whether the deployer is active to take deposits */
  bool active;
  /* If by chance the contract should fail in provisioning liquidity we will enable huddlers to withdraw their ETH */
  bool emergency;
  /* Enables users to collect their newly provisioned LP tokens */
  bool claimable;
  /* When the distributor will be able to start releasing vested tokens */
  uint256 vestingLockedDate;
  /* Minimum buy in */
  uint256 minBuy;
  /* Maximum buy in */
  uint256 maxBuy;
  /* The maximum amount of ETH possible for the buy in */
  uint256 maxAmount;
  /* HUDL token address */
  address hudlTokenAddress;
  /* HUDL LP token address */
  address hudlLPAddress;
  /* HUDL LP token address */
  IERC20 hudlLPToken;
  /* Tracks each users deposit */
  mapping(address=>uint256) huddlerETHDeposit;
  /* Tracks each users claimed vesting */
  mapping(address=>uint256) huddlerLPClaimed;
  /* Uniswapv2 router contract addresses */
  address public immutable factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address public immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  HUDLToken private hudlTokenObject;

  constructor(
  address _hudlToken, 
  uint256 _maxAmount,
  uint256 _startDate,
  uint256 _minBuy,
  uint256 _maxBuy) public{
    hudlTokenAddress = _hudlToken;
    maxAmount = _maxAmount;
    startDate = _startDate;
    depositEndDate = startDate + (30 days);
    deployDate = startDate + (60 days);
    minBuy = _minBuy;
    maxBuy = _maxBuy;
    active = true;
    
    vestingSchedule = 31536000; //1 year in seconds
    hudlTokenObject = HUDLToken(_hudlToken);  
  }

  /*** GETTER FUNCTIONS ***/
  function totalETHSupply() external view returns (uint256){
    return totalETH;
  }
  
  function totalHUDLSupply() external view returns (uint256){
    return totalHUDL;
  }
  
  function totalLPSupply() external view returns (uint256){
    return initTotalLP + lockedLPTokens - totalLPClaimed;
  }

  function totalUnlockedLP() external view returns (uint256){
    return unlockedLPTokens;
  }

  function getMaxAmount() external view returns (uint256){
    return maxAmount;
  }

  function getMinBuyIn() external view returns (uint256){
    return minBuy;
  }

  function getMaxBuyIn() external view returns (uint256){
    return maxBuy;
  }

  function getDeployDate() external view returns (uint256){
    return deployDate;
  }

  function getDepositEndDate() external view returns (uint256){
    return depositEndDate;
  }

  function getHuddlerLPClaimed() external view returns (uint256){
    return huddlerLPClaimed[msg.sender];
  }

  function getStartDate() external view returns (uint256){
    return startDate;
  }

  function getHUDLAddress() external view returns (address){
    return hudlTokenAddress;
  }

  function getInitTotalLP() external view returns (uint256){
    return initTotalLP;
  }

  function getHUDLLPAddress() external view returns (address){
    return hudlLPAddress;
  }

  function getEmergency() external view returns (bool){
    return emergency;
  }

  function getETHDeposit() external view returns (uint256){
    return huddlerETHDeposit[msg.sender];
  }

  function getHUDLLPUnlocked() external view returns (uint256){
    if((unlockedLPTokens + initTotalLP) > 0){
      return (((unlockedLPTokens + initTotalLP) * huddlerETHDeposit[msg.sender]) / totalETH) - huddlerLPClaimed[msg.sender];
    }
    else{
      return 0;
    }
  }

  /*** SETTER FUNCTIONS ***/
  function setEmergency() external onlyOwner{
    emergency = !emergency;
  }

  function pushLaunchDate() external onlyOwner{
    deployDate = deployDate + (1 days);
  }

  function setActive() external onlyOwner{
    active = !active;
  }

  function setMaxAmount(uint256 _maxAmount) external onlyOwner{
    require(_maxAmount > maxAmount, "Can't decrease amount, only increase");
    maxAmount = _maxAmount;
  }

  /*** MUTATIVE FUNCTIONS ***/

  /* Allows huddlers to claim their provisioned LP tokens */
  function claim() public {
    _claim();
  }

  function _claim() internal{
    require(claimable, "Can't claim before HDC over");
    
    unlockLPTokens();

    uint256 amount = (((unlockedLPTokens + initTotalLP) * huddlerETHDeposit[msg.sender]) / totalETH) - huddlerLPClaimed[msg.sender];

    hudlLPToken.transfer(msg.sender, amount);

    huddlerLPClaimed[msg.sender] += amount;
    
    totalLPClaimed += amount;

    emit Claimed(msg.sender, amount);
  }

  /* Users desposit their tokens  */
  function deposit() public payable{    
    _deposit(msg.value);
  }

  function _deposit(uint256 amount) internal{
    require(!emergency, "Emergency failsafe in effect, cannot deposit");
    require(active, "HDC must be active");
    require(depositEndDate >= block.timestamp, "Deposit period has ended");
    require(amount >= minBuy && (huddlerETHDeposit[msg.sender] + amount) <= maxBuy && ((totalETH + amount) < maxAmount), "Wrong amount or HDC full");

    huddlerETHDeposit[msg.sender] += amount;
    totalETH += msg.value;

    emit Deposit(msg.sender, totalETH);
  }

  /* Allows either the huddlers or the owners to call the provisioning to UniSwap */
  function provisionLiquidity() public {
    _provisionLiquidity();
  }

  function _provisionLiquidity() private{
    require(deployDate <= block.timestamp, "HDC must be over");
    require(!claimable, "Already complete");

    uint trash;
  
    (trash, trash, initTotalLP, hudlLPAddress) = addLiquidityETH(hudlTokenAddress, totalHUDL, totalHUDL / 2, totalETH / 2, address(this), block.timestamp + 15 minutes);

    hudlLPToken = IERC20(hudlLPAddress);
    initTotalLP = initTotalLP / 2;
    lockedLPTokens = initTotalLP;
    vestingLockedDate = block.timestamp + (365 days);  
    claimable = true;
  }

  /* Users withdraw their desposits  */
  function withdraw() public payable{    
    _withdraw();
  }

  function _withdraw() internal{
    require(emergency, "Requires emergency toggle to be on");
    
    address payable receiver = msg.sender;

    uint256 amountToWithdraw = huddlerETHDeposit[msg.sender];

    totalETH = totalETH - huddlerETHDeposit[msg.sender];
    huddlerETHDeposit[msg.sender] = 0;
    
    receiver.transfer(amountToWithdraw);
  }


  /*** UTILITY FUNCTIONS ***/
  function unlockLPTokens() internal{
    if(block.timestamp >= vestingLockedDate){
      uint256 secondsSinceStart = (block.timestamp - vestingLockedDate);
      uint256 secondsYear = vestingSchedule; 

      if(secondsSinceStart >= 1){
        uint256 tempAmount = (lockedLPTokens * secondsSinceStart) / secondsYear;
        if(tempAmount >= (initTotalLP)){
          unlockedLPTokens = initTotalLP;
        }
        else{
          unlockedLPTokens = tempAmount;
        }
      }
    }
  }

  /*** UNISWAPV2 FUNCTIONS ***/
  modifier ensure(uint256 deadline) {
      require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
      _;
  }

  function _addLiquidity(
      address tokenA,
      address tokenB,
      uint256 amountADesired,
      uint256 amountBDesired,
      uint256 amountAMin,
      uint256 amountBMin
  ) internal returns (uint256 amountA, uint256 amountB) {
      // create the pair if it doesn't exist yet
      if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
          IUniswapV2Factory(factory).createPair(tokenA, tokenB);
      }
      (uint256 reserveA, uint256 reserveB) =
          UniswapV2Library.getReserves(factory, tokenA, tokenB);
      if (reserveA == 0 && reserveB == 0) {
          (amountA, amountB) = (amountADesired, amountBDesired);
      } else {
          uint256 amountBOptimal =
              UniswapV2Library.quote(amountADesired, reserveA, reserveB);
          if (amountBOptimal <= amountBDesired) {
              require(
                  amountBOptimal >= amountBMin,
                  "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
              );
              (amountA, amountB) = (amountADesired, amountBOptimal);
          } else {
              uint256 amountAOptimal =
                  UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
              assert(amountAOptimal <= amountADesired);
              require(
                  amountAOptimal >= amountAMin,
                  "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
              );
              (amountA, amountB) = (amountAOptimal, amountBDesired);
          }
      }
  }

  function addLiquidityETH(
      address token,
      uint256 amountTokenDesired,
      uint256 amountTokenMin,
      uint256 amountETHMin,
      address to,
      uint256 deadline
  )
      internal
      ensure(deadline)
      returns (
          uint256 amountToken,
          uint256 amountETH,
          uint256 liquidity,
          address pair
      )
  {
      (amountToken, amountETH) = _addLiquidity(
          token,
          WETH,
          amountTokenDesired,
          amountETHMin * 2,
          amountTokenMin,
          amountETHMin
      );

      pair = UniswapV2Library.pairFor(factory, token, WETH);

      hudlTokenObject.approvePair(pair);

      hudlTokenObject.transferFrom(address(this), pair, amountToken);

      IWETH(WETH).deposit{value: amountETH}();
      assert(IWETH(WETH).transfer(pair, amountETH));
      //works with this commented
      liquidity = IUniswapV2Pair(pair).mint(to);
      if ((amountETHMin * 2) > amountETH)
          TransferHelper.safeTransferETH(to, (amountETHMin * 2) - amountETH); // refund dust eth, if any
  }

  /*** EVENTS ***/
  event Deposit(address indexed user, uint256 amount);
  event Claimed(address indexed user, uint256 amount);
}