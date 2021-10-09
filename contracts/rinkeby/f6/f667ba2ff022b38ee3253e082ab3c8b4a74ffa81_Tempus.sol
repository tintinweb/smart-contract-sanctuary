/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Tempus is ERC20, Ownable {
    
    using SafeMath for uint256;
    
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 440000000 * (10 ** _decimals);
    
    struct HODL_Info {
        bool isStart;
        uint256 startTime;
        uint256 startAmount;
        bool isQuality;
        bool useAffiliateCode;
        address affiliateAddress;
    }
    
    uint256 private timeinterval = 1 minutes;
    uint256 private rateInterest = 25 * (10 ** _decimals) / (100 * 100); // 0.25%
    uint256 private rateBonus = 1000 * (10 ** _decimals) / (100 * 100); // 10%
    
    mapping(address => HODL_Info) private HODLInfos;
    
    uint256 startSignalAmount = 1; //0.00000001
    uint256 stopSignalAmount = 2; //0.00000002
    
    uint256 private totalHODLs;
    uint256 private totalGoodHODLs;
    uint256 private totalCurrentHolding;
    uint256 private totalGoodHODLsAmount;
    uint256 private totalCurrentHoldingAmount;
    uint256 private totalHODLsAmount;
    
    uint256 private totalInterestReward;
    uint256 private totalBonusReward;
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(address(this), _totalSupply);
    }
    
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    
    function getTotalHODLInfo() public view returns(
        uint256 _totalHODLs,
        uint256 _totalGoodHODLs,
        uint256 _totalCurrentHolding,
        uint256 _totalGoodHODLsAmount,
        uint256 _totalCurrentHoldingAmount,
        uint256 _totalHODLsAmount,
        uint256 _totalInterestReward,
        uint256 _totalBonusReward
        ) {
        
        _totalHODLs = totalHODLs;
        _totalGoodHODLs = totalGoodHODLs;
        _totalCurrentHolding = totalCurrentHolding;
        _totalGoodHODLsAmount = totalGoodHODLsAmount;
        _totalCurrentHoldingAmount = totalCurrentHoldingAmount;
        _totalHODLsAmount = totalHODLsAmount;
        _totalInterestReward = totalInterestReward;
        _totalBonusReward = totalBonusReward;
    }
    
    function getHODLStateFromAddress(address account) public view returns(
                bool _isStart,
                uint256 _startTime,
                uint256 _startAmount,
                bool _isQuality,
                bool _useAffiliateCode,
                address _affiliateAddress) {
                    
        HODL_Info memory info = HODLInfos[account];
        _isStart = info.isStart;
        _startTime = info.startTime;
        _startAmount = info.startAmount;
        _isQuality = info.isQuality;
        _useAffiliateCode = info.useAffiliateCode;
        _affiliateAddress = info.affiliateAddress;
    }
    
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    } 
     
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override
    {
        super._afterTokenTransfer(from, to, amount);

        
        processTransfer(from, to, amount);
    }
    
    // function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override
    // {
    //     super._beforeTokenTransfer(from, to, amount);

    //     processTransfer(from, to, amount);
    // }
    
    function processTransfer(address from, address to, uint256 amount) private {
        if(amount == startSignalAmount && to == address(this)) {
            processStartHODL(from, false, address(0));
        } else if(amount == stopSignalAmount && to == address(this)) {
            processStopHODL(from);
        } else {
            HODL_Info memory info = HODLInfos[from];
            if(info.isStart && (balanceOf(from) < info.startAmount)) {
                HODLInfos[from].isQuality = false;
            }
        }
    }
    
    function reset() public {
        require(msg.sender != address(0), "ERC20: transaction from the zero address");
        
        reset(msg.sender);
    }
    
    function reset(address inAddress) private {
        HODL_Info memory info;
        
        if(HODLInfos[inAddress].isStart) {
            totalCurrentHolding -= 1;
            totalCurrentHoldingAmount = totalCurrentHoldingAmount.sub(HODLInfos[inAddress].startAmount);
        }
        
        info.isStart = false;
        info.startTime = 0;
        info.startAmount = 0;
        info.isQuality = false;
        info.useAffiliateCode = false;
        info.affiliateAddress = address(0);
        
        HODLInfos[inAddress] = info;
    }
    
    function startHODLWithAffiliate(address affiliateAddress) public returns(bool) {
        address inAddress = msg.sender;
        require(inAddress != address(0), "ERC20: transaction from the zero address");
        require(balanceOf(inAddress) != 0, "ERC20: balance is zero.");
        require(HODLInfos[inAddress].isStart == false, "ERC20: HODL is already started.");
        
        HODL_Info memory info;
        
        info.isStart = true;
        info.startTime = block.timestamp;
        info.startAmount = balanceOf(inAddress);
        info.isQuality = true;
        info.useAffiliateCode = true;
        info.affiliateAddress = affiliateAddress;
        
        totalCurrentHolding += 1;
        totalCurrentHoldingAmount = totalCurrentHoldingAmount.add(info.startAmount);
        totalHODLs += 1;
        totalHODLsAmount = totalHODLsAmount.add(info.startAmount);
        
        HODLInfos[inAddress] = info;
        return true;
    }
    
    function startHODLWithoutAffiliate() public returns(bool) {
        address inAddress = msg.sender;
        require(inAddress != address(0), "ERC20: transaction from the zero address");
        require(balanceOf(inAddress) != 0, "ERC20: balance is zero.");
        require(HODLInfos[inAddress].isStart == false, "ERC20: HODL is already started.");
        
        HODL_Info memory info;
        
        info.isStart = true;
        info.startTime = block.timestamp;
        info.startAmount = balanceOf(inAddress);
        info.isQuality = true;
        info.useAffiliateCode = false;
        info.affiliateAddress = address(0);
        
        totalCurrentHolding += 1;
        totalCurrentHoldingAmount = totalCurrentHoldingAmount.add(info.startAmount);
        totalHODLs += 1;
        totalHODLsAmount = totalHODLsAmount.add(info.startAmount);
        
        HODLInfos[inAddress] = info;
        return true;
    }
    
    function processStartHODL(address inAddress, bool useAffiliateCode, address affiliateAddress) private {
        
        require(inAddress != address(0), "ERC20: transaction from the zero address");
        require(balanceOf(inAddress) != 0, "ERC20: balance is zero.");
        require(HODLInfos[inAddress].isStart == false, "ERC20: HODL is already started.");
        
        HODL_Info memory info;
        
        info.isStart = true;
        info.startTime = block.timestamp;
        info.startAmount = balanceOf(inAddress);
        info.isQuality = true;
        info.useAffiliateCode = useAffiliateCode;
        info.affiliateAddress = affiliateAddress;
        
        totalCurrentHolding += 1;
        totalCurrentHoldingAmount = totalCurrentHoldingAmount.add(info.startAmount);
        totalHODLs += 1;
        totalHODLsAmount = totalHODLsAmount.add(info.startAmount);
        
        HODLInfos[inAddress] = info;
    }
    
    function stopHODLWithAffiliate() public returns(bool) {
        address inAddress = msg.sender;
        require(inAddress != address(0), "ERC20: transaction from the zero address");
        require(balanceOf(inAddress) != 0, "ERC20: balance is zero.");
        require(HODLInfos[inAddress].isStart, "ERC20: No start HODL.");
        require(HODLInfos[inAddress].isQuality, "ERC20: HODL amount is zero.");
        
        uint256 interestReward = getInterestReward(inAddress);
        uint256 bonusReward = getBonusReward(inAddress, interestReward);
        
        uint256 totalReward = interestReward.add(bonusReward);
        
        if(HODLInfos[inAddress].useAffiliateCode && bonusReward > 0)
            this.transfer(HODLInfos[inAddress].affiliateAddress, bonusReward);
        
        if(interestReward > 0)
            this.transfer(inAddress, totalReward);
        
        if(balanceOf(address(this)) < 10000000 * (10 ** _decimals)) {
            _mint(address(address(this)), 10000000 * (10 ** decimals()));
            _totalSupply = _totalSupply.add(10000000 * (10 ** decimals()));
        }
        
        //change infos
        totalGoodHODLs += 1;
        totalGoodHODLsAmount = totalGoodHODLsAmount.add(HODLInfos[inAddress].startAmount);
        totalInterestReward = totalInterestReward.add(interestReward);
        totalBonusReward = totalBonusReward.add(bonusReward);
        
        reset(inAddress);
        return true;
    }
    
    function stopHODLWithoutAffiliate() public returns(bool) {
        address inAddress = msg.sender;
        require(inAddress != address(0), "ERC20: transaction from the zero address");
        require(balanceOf(inAddress) != 0, "ERC20: balance is zero.");
        require(HODLInfos[inAddress].isStart, "ERC20: No start HODL.");
        require(HODLInfos[inAddress].isQuality, "ERC20: HODL amount is zero.");
        
        uint256 interestReward = getInterestReward(inAddress);
        uint256 bonusReward = getBonusReward(inAddress, interestReward);
        
        uint256 totalReward = interestReward.add(bonusReward);
        
        if(HODLInfos[inAddress].useAffiliateCode && bonusReward > 0)
            this.transfer(HODLInfos[inAddress].affiliateAddress, bonusReward);
        
        if(interestReward > 0)
            this.transfer(inAddress, totalReward);
        
        if(balanceOf(address(this)) < 10000000 * (10 ** _decimals)) {
            _mint(address(address(this)), 10000000 * (10 ** decimals()));
            _totalSupply = _totalSupply.add(10000000 * (10 ** decimals()));
        }
        
        //change infos
        totalGoodHODLs += 1;
        totalGoodHODLsAmount = totalGoodHODLsAmount.add(HODLInfos[inAddress].startAmount);
        totalInterestReward = totalInterestReward.add(interestReward);
        totalBonusReward = totalBonusReward.add(bonusReward);
        
        reset(inAddress);
        return true;
    }
    
    function processStopHODL(address inAddress) private {
        require(inAddress != address(0), "ERC20: transaction from the zero address");
        require(balanceOf(inAddress) != 0, "ERC20: balance is zero.");
        require(HODLInfos[inAddress].isStart, "ERC20: No start HODL.");
        require(HODLInfos[inAddress].isQuality, "ERC20: HODL amount is zero.");
        
        (
            uint256 interestReward,
            uint256 bonusReward,
            uint256 totalReward
        ) = getTotalReward(inAddress);
        
        if(HODLInfos[inAddress].useAffiliateCode && bonusReward > 0)
            this.transfer(HODLInfos[inAddress].affiliateAddress, bonusReward);
        
        if(interestReward > 0)
            this.transfer(inAddress, totalReward);
        
        if(balanceOf(address(this)) < 10000000 * (10 ** _decimals)) {
            _mint(address(address(this)), 10000000 * (10 ** decimals()));
            _totalSupply = _totalSupply.add(10000000 * (10 ** decimals()));
        }
        
        //change infos
        totalGoodHODLs += 1;
        totalGoodHODLsAmount = totalGoodHODLsAmount.add(HODLInfos[inAddress].startAmount);
        totalInterestReward = totalInterestReward.add(interestReward);
        totalBonusReward = totalBonusReward.add(bonusReward);
        
        reset(inAddress);
    }
    
    function getTotalReward(address inAddress) public view returns(uint256 _interestReward, uint256 _bonusReward, uint256 _totalReward){
        _interestReward = getInterestReward(inAddress);
        _bonusReward = getBonusReward(inAddress, _interestReward);
        
        _totalReward = _interestReward.add(_bonusReward);
    }
    
    function getInterestReward(address inAddress) private view returns(uint256) {
        HODL_Info memory info = HODLInfos[inAddress];
        if(info.isQuality == false) {
            //reset(inAddress);
            return 0;
        }
        
        uint256 holdedtime = (block.timestamp).sub(info.startTime);
        uint256 hodleddays = (holdedtime.sub(holdedtime.mod(timeinterval))).div(timeinterval);
        
        uint256 interestReward = (info.startAmount).mul(hodleddays.mul(rateInterest)).div(10 ** decimals());
        
        return interestReward;
    }
    
    function getBonusReward(address inAddress, uint256 interestedReward) private view returns(uint256) {
        HODL_Info memory info = HODLInfos[inAddress];
        uint256 bonusReward = 0;
        if(info.useAffiliateCode)
            bonusReward = interestedReward.mul(rateBonus).div(10 ** decimals());
        
        return bonusReward;
    }

}