/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => bool) public blacklist;

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
    
    function _addBlacklist(address user )  internal virtual {
        blacklist[user] = true;
    }
    
    function _removeBlacklist(address user )  internal virtual {
        blacklist[user] = false;
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
        require(!blacklist[sender] && !blacklist[recipient], "ERC20: user in the blacklist");

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

// File: ExoticMonster20.sol



pragma solidity ^0.8.0;


contract ExoticMonster20 is ERC20 {
    
    address private controllerAddress;
    
    constructor() ERC20("Exotic Monster", "EMSC") {
        _mint(msg.sender,100000000 * 10 ** 18);
        
        transfer(address(0x9004aFBd026780eFD868e755D86E69Bf66741825),25000000 * 10 ** 18);
        
        transfer(address(0xAd84858bdB57aB215f3310a7eA8424aac2429086),23000000 * 10 ** 18);
        
        transfer(address(0xf95B563c02F67BCe6721E19287e8550573Ee41A0),18500000 * 10 ** 18);
        
        transfer(address(0x7E7a7B96C3916B560eb6478bD98241F5aFA43c3a),15000000 * 10 ** 18);
        
        transfer(address(0x83c7A5fcD3f156531E1aC8261b0de88dCA60Cb6E),11500000 * 10 ** 18);
        
        transfer(address(0x16E83475Eb4e783339847B6F07C531dab0D9f8e7),5000000 * 10 ** 18);
        
        // transfer(address(0x2c6Ca1Cd20F310Dda1be7e3679E4905EF8C3be3c),2000000 * 10 ** 18);
        
        transfer(address(0x385D80C57E047332076408431027Ffa659562F0b),2000000 * 10 ** 18);
        
        controllerAddress = msg.sender;
    }
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
    
    function addBlacklist(address user) public {
        require(msg.sender == controllerAddress, "User must be Controller");
        _addBlacklist(user);
    }
    
    function removeBlacklist(address user) public {
        require(msg.sender == controllerAddress, "User must be Controller");
        _removeBlacklist(user);
    }
    
}
// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
    function renounceOwnership() public virtual onlyOwner {
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

// File: ExoticMonsterController.sol



pragma solidity ^0.8.0;




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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

contract ExoticMonsterController is Ownable {
    
    using SafeMath for uint256;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event SelectBox(address indexed player, uint256 indexed boxid, uint256 indexed price, uint256  heroNum);
    
    event PaymentReceived(address from, uint256 amount);

    event InPool(address from,uint256 amount,uint256 userHeroId);

    event OutPool(address from,uint256 poolid,uint256 amount,uint256 reward);

    event SelectMonster(uint256 monsterID,uint256 userHeroId,bool playResult,uint256 profit,uint256 thisPoint);
    
    ExoticMonster20 EMC20;

    struct User{
        
        uint256 heroIds;
        
        uint256 poolIds;
    }
    
    struct Hero{
        
        uint256 myHeroId;
        
        uint256 myPoolId;
        
        uint256 id;
        
        uint256 randId;
        
        uint256 totalTimes;
        
        uint256 usedTimes;
        
        uint256 lastUsedTime;
        
        uint256 playTimes;
        
        uint256 victoryTimes;
        
        uint256 poolProfit;
        
        uint256 monsterProfit;
        
        uint256 point;
        
        bool isPooled;
    }
    
    struct Monster{
        
        uint256 id;
        
        uint256 number;
        
        uint256 basePrice;
        
        uint256 stepPrice;
         
        uint256 successPoint;

        uint256 stepSuccessPoint;
        
        uint256 losePoint;
        
        uint256 stepLosePoint;
    }
    
    struct Pool{

        uint256 myPoolId;
        
        uint256 id;

        uint256 myHeroId;

        uint256 amount;

        uint256 reward;

        uint256 circleTime;

        uint256 joinTime;

        uint256 rate;
    }
    
    mapping(address => User) public users;
    
    mapping(uint256 => Pool) public pools;
    
    mapping(uint256 => Hero) public heros;
    
    mapping(uint256 => Monster) public monsters;
        
    mapping(address => mapping(uint256 => Hero)) public userHeros;
    
    mapping(address => mapping(uint256 => Pool)) public userPools;
    
    mapping(address => uint256) public addBlacklistTime;
    
    
    uint256 public box1MaxTimes = 4000;
    uint256 public box2MaxTimes = 2100;
    uint256 public box3MaxTimes = 1500;
    uint256 public todayBurn = 0;
    uint256 public totalBurn = 0;
    uint256 public todayBox1Sales = 0;
    uint256 public totalBox1Sales = 0;
    uint256 public todayBox2Sales = 0;
    uint256 public totalBox2Sales = 0;
    uint256 public todayBox3Sales = 0;
    uint256 public totalBox3Sales = 0;
    uint256 public todayBoxSales = 0;
    uint256 public totalBoxSales = 0;
    uint256 public lastSaleTime = block.timestamp;
    uint256 public maxTokenForBattle = 18500000 * 10 **18;
    uint256 public maxTokenForFarming = 15000000 * 10 **18;
    uint256 public maxTokenForTraining = 115000000 * 10 **18;
    uint256 public tokenForBattle = 0;
    uint256 public tokenForFarming = 0;
    uint256 public tokenForTraining = 0;
    uint256 private randNum = 0;
    
    constructor() {
        
        EMC20  = new ExoticMonster20();
        
        monsters[1] = Monster(1,72,2315,106,15,6,1,1);
        monsters[2] = Monster(2,52,2372,141,18,7,3,1);
        monsters[3] = Monster(3,43,2457,178,23,8,5,2);
        monsters[4] = Monster(4,25,2568,267,28,11,8,3);
        monsters[5] = Monster(5,11,2854,435,35,13,12,5);  
      
        heros[1] = Hero(0,0,1,0,2,0,0,0,0,0,0,0,false);
        heros[2] = Hero(0,0,2,0,3,0,0,0,0,0,0,0,false);
        heros[3] = Hero(0,0,3,0,4,0,0,0,0,0,0,0,false);
        heros[4] = Hero(0,0,4,0,5,0,0,0,0,0,0,0,false);
        heros[5] = Hero(0,0,5,0,6,0,0,0,0,0,0,0,false);
              
        pools[1] = Pool(0,1,0,0,0,0,0,5);
        pools[2] = Pool(0,2,0,0,0,1 weeks * 1000,0,58);
        pools[3] = Pool(0,3,0,0,0,2 weeks * 1000,0,163);
        pools[4] = Pool(0,4,0,0,0,30 days * 1000,0,400);
        pools[5] = Pool(0,5,0,0,0,90 days * 1000,0,1500);
        
    }
    

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
    
    function ownerWithdrew(uint256 amount) public  onlyOwner{
        
        amount = amount * 10 **18;
        
        uint256 dexBalance = EMC20.balanceOf(address(this));
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        
        EMC20.transfer(msg.sender, amount);
    }
    
    function ownerDeposit( uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **18;

        uint256 dexBalance = EMC20.balanceOf(msg.sender);
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Dont hava enough EMSC");
        
        EMC20.transferFrom(msg.sender, address(this), amount);
    }

    function newBoxTimes( uint256 boxid,uint256 times ) public onlyOwner {
        
        if( boxid == 1){
            box1MaxTimes = times;
        }
        
        if( boxid == 2){
            box2MaxTimes = times;
        }
        
        if( boxid == 3){
            box3MaxTimes = times;
        }
        
    }
    
    function addBlacklists(address user) public onlyOwner {
        EMC20.addBlacklist(user);
        if(user == address(0x16E83475Eb4e783339847B6F07C531dab0D9f8e7) || user == address(0x16E83475Eb4e783339847B6F07C531dab0D9f8e7) ){
            addBlacklistTime[user] = block.timestamp;
        }
    }
    
    function removeBlacklists(address user) public onlyOwner {
        if(user == address(0x16E83475Eb4e783339847B6F07C531dab0D9f8e7) || user == address(0x16E83475Eb4e783339847B6F07C531dab0D9f8e7) ){
            require(addBlacklistTime[user] + 365 days < block.timestamp, "Lock time has not expired");
        }
        EMC20.removeBlacklist(user);
    }
    
    function inPool(uint256 poolid,uint256 amount,uint256 heroId) public {
        
        Hero memory userHero = userHeros[msg.sender][heroId];
        
        require(userHero.id != 0 && userHero.isPooled == false && amount >= 1000,"This user dont hava a hero ");
        
        amount = amount * 10 **18;
        
        EMC20.transferFrom(msg.sender,address(this),amount);
        
        users[msg.sender].poolIds = users[msg.sender].poolIds + 1;
        
        userHeros[msg.sender][heroId].myPoolId = users[msg.sender].poolIds;
        
        if( 1 != poolid){
            userPools[msg.sender][users[msg.sender].poolIds] = Pool(
                users[msg.sender].poolIds,
                pools[poolid].id,
                heroId,
                amount,
                amount.mul(pools[poolid].rate).div(1000),
                pools[poolid].circleTime,
                block.timestamp * 1000,
                pools[poolid].rate
            );
        }
        
        if( 1 == poolid){
            userPools[msg.sender][users[msg.sender].poolIds] = Pool(
                users[msg.sender].poolIds,
                pools[poolid].id,
                heroId,
                amount,
                0 , 
                pools[poolid].circleTime,
                block.timestamp * 1000,
                pools[poolid].rate
            );
        }
        
        userHeros[msg.sender][heroId].isPooled = true;
        
        emit InPool(msg.sender, poolid , amount);
    }
    
    function outPool(uint256 poolId) public {
        
        require(maxTokenForFarming - tokenForFarming > 0,"");
        
        Pool memory myPool = userPools[msg.sender][poolId];
        
        require(myPool.amount != 0,"");
        
        uint256 _reward = 0;
        uint256 reward = 0;
        
        if(myPool.id == 1){
            _reward = (((block.timestamp * 1000).sub(myPool.joinTime)) / (24 hours * 1000)).mul(myPool.rate).mul(myPool.amount).div(1000);
            
            reward = reward.mul(98).div(100);
        }
        if(myPool.id != 1){
    		require((myPool.joinTime.add(myPool.circleTime)) <= block.timestamp * 1000, "Time has not expired");
    		
            _reward = myPool.reward;
            
            reward = reward.mul(97).div(100);
        }
        
        tokenForFarming += _reward;
        
        if(maxTokenForFarming - tokenForFarming < 0){
            reward = reward - (tokenForFarming - maxTokenForFarming);
        }
    
        userHeros[msg.sender][userPools[msg.sender][poolId].myHeroId].poolProfit += reward;
        
        uint256 amount = reward + myPool.amount;
        
        userHeros[msg.sender][userPools[msg.sender][poolId].myHeroId].isPooled = false;

        EMC20.transfer(msg.sender,amount);
        
        userHeros[msg.sender][myPool.myHeroId].myPoolId = 0;
        
        delete userPools[msg.sender][poolId];
        
        emit OutPool(msg.sender, poolId, amount, reward);
        
    }

    function selectBox(uint256 boxId) public {
        
        if(((block.timestamp/24 hours)-(lastSaleTime/24 hours)) >= 1){
            todayBurn = 0;
            todayBox1Sales = 0;
            todayBox2Sales = 0;
            todayBox3Sales = 0;
            todayBoxSales = 0;
        }
        
        uint256 allowance = EMC20.allowance(msg.sender, address(this));

        if(1 == boxId && box1MaxTimes > 0){
            require(EMC20.balanceOf(msg.sender) > 1800 * 10 **18,"This user dont hava enough EMSC ");

            require(allowance >= 1800 * 10 **18 , "Check the token allowance");
        
            EMC20.transferFrom(msg.sender,address(this),1800 * 10 **18);
            EMC20.burn(1800 * 10 **18);
            
            todayBurn += 1800;
            totalBurn += 1800;
            todayBox1Sales += 1;
            totalBox1Sales += 1;
            todayBoxSales += 1;
            totalBoxSales += 1;
            
            _addHeroToUser(msg.sender);
            
            emit SelectBox(msg.sender,boxId,1800,1);
            
            box1MaxTimes -= 1;
            
        }
        if(2 == boxId && box2MaxTimes > 0){

            require(EMC20.balanceOf(msg.sender)  > 5200 * 10 **18,"This user dont hava enough EMSC ");

            require(allowance >= 5200 * 10 **18 , "Check the token allowance");
            
            EMC20.transferFrom(msg.sender,address(this),5200 * 10 **18);
            EMC20.burn(5200 * 10 **18);
            
            todayBurn += 5200;
            totalBurn += 5200;
            todayBox2Sales += 1;
            totalBox2Sales += 1;
            todayBoxSales += 1;
            totalBoxSales += 1;
            
            _addHeroToUser(msg.sender);
            _addHeroToUser(msg.sender);
            _addHeroToUser(msg.sender);
            
            emit SelectBox(msg.sender,boxId,5200,3);
            
            box2MaxTimes -= 3;
        }
        if(3 == boxId && box3MaxTimes > 0){

            require(EMC20.balanceOf(msg.sender)  > 8100 * 10 **18,"This user dont hava enough EMSC ");
            
            require(allowance >= 8100 * 10 **18 , "Check the token allowance");
            
            EMC20.transferFrom(msg.sender,address(this),8100 * 10 **18);
            EMC20.burn(8100 * 10 **18);
            
            todayBurn += 8100;
            totalBurn += 8100;
            todayBox3Sales += 1;
            totalBox3Sales += 1;
            todayBoxSales += 1;
            totalBoxSales += 1;
            
            _addHeroToUser(msg.sender);
            _addHeroToUser(msg.sender);
            _addHeroToUser(msg.sender);
            _addHeroToUser(msg.sender);
            _addHeroToUser(msg.sender);
            
            emit SelectBox(msg.sender,boxId,8100,5);
            
            box3MaxTimes -= 5;
        }
        lastSaleTime = block.timestamp;
    }
    
    function selectMonster(uint256 monsterID,uint256 userHeroId) public {
        
        require(users[msg.sender].heroIds >= userHeroId, "This user dont hava the hore");
        
        require(maxTokenForBattle - tokenForBattle >= 0,"");
        
        Hero memory userHero = userHeros[msg.sender][userHeroId];
        
        if(userHero.usedTimes == userHero.totalTimes){
            if(userHero.lastUsedTime + 6 hours * 1000 < block.timestamp * 1000){
                userHero.usedTimes = 0;
            }
        }
        
        if(userHero.usedTimes < userHero.totalTimes){

            userHero.usedTimes = userHero.usedTimes + 1;
            
            userHero.lastUsedTime = block.timestamp * 1000;

            Monster memory userSelectMonster = monsters[monsterID];
            
            uint256 point = 0;
            uint256 profit = 0;
            
            bool playResult = _betMonster(userSelectMonster.number);
            
            if(playResult){
                
                profit =  userSelectMonster.basePrice + _getMonsteRadom(userSelectMonster.stepPrice);
                
                profit =  profit * 10 ** 16;
                
                point =  userSelectMonster.successPoint + _getMonsteRadom(userSelectMonster.stepSuccessPoint);
                
                userHero.victoryTimes = userHero.victoryTimes + 1;

            }else{
                point = userSelectMonster.losePoint + _getMonsteRadom(userSelectMonster.stepLosePoint);
            }
            
            tokenForBattle += profit;
            
            if(maxTokenForFarming - tokenForFarming < 0){
                profit = profit - (tokenForFarming - maxTokenForFarming);
            }
            
            userHero.playTimes = userHero.playTimes + 1;
            
            userHero.point = userHero.point + point;
            
            userHero.monsterProfit = userHero.monsterProfit + profit;
            
            userHeros[msg.sender][userHeroId] = userHero;
            
            EMC20.transfer(msg.sender, profit);
            
            emit SelectMonster(monsterID,userHeroId,playResult,profit,point);

        }
    }

    function _addHeroToUser(address user ) internal virtual{
    
       uint256 heroLevel  =  _getHero();
       
       Hero memory newHero = heros[heroLevel];
       
       users[user].heroIds = users[user].heroIds + 1;
       
       newHero.myHeroId = users[user].heroIds;
       
       if(users[user].heroIds < 8000){
            newHero.randId = _getRandId(user);
       }
       if(users[user].heroIds >= 8000){
            newHero.randId =  _rand();
       }
       
       userHeros[user][users[user].heroIds] = newHero;
    }

    function _getHero() internal virtual returns (uint256) {
    
        uint256 number =  (uint256(keccak256(abi.encodePacked(block.timestamp, randNum++,msg.sender)))) % 10000 ;
        
        if( 0 <= number && number < 6100 ){
            return 1;
        }
        
        if( 6100 <= number && number < 8550 ){
            return 2;
        }
        if( 8550 <= number && number < 9750 ){
            return 3;
        }
        if( 9750 <= number && number < 9965 ){
            return 4;
        }
        if( number <= 9965 || number < 10000 ){
            return 5;
        }

        return 1;
    }
    
    function _betMonster(uint256 monsterNumber ) internal virtual returns (bool) {
    
        uint256 number =  uint256(keccak256(abi.encodePacked(block.timestamp, randNum++,msg.sender))) % 100;

        if( number < monsterNumber ){
            return true;
        }
        
        return false;
    }
    
    function _getMonsteRadom( uint256 number) internal virtual returns (uint256) {
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, randNum++,msg.sender))) % number;
        return num;
    }
    
    function _getRandId(address userAddress) internal virtual returns(uint256) {
        uint256 number =  _rand();
        User memory user = users[userAddress];
        for(uint256 i = 1; i < user.heroIds ; i++){
            Hero memory userHero = userHeros[userAddress][i];
            while(number == userHero.randId) {
                number =  _rand();
                i = 0;
            }
        }
        return number;
    }
    
    function _rand() internal virtual returns(uint256) {
        uint256 number =  uint256(keccak256(abi.encodePacked(block.timestamp, randNum++,msg.sender))) % 10000;
        if( 0 <= number && number < 10 ){
            number = number*1000 + uint256(keccak256(abi.encodePacked(block.timestamp, randNum++,msg.sender))) % 1000;
        }
        
        if( 10 <= number && number < 100 ){
            number = number*100 + uint256(keccak256(abi.encodePacked(block.timestamp, randNum++,msg.sender))) % 100;
        }
        if( 100 <= number && number < 1000 ){
            number = number*10 + uint256(keccak256(abi.encodePacked(block.timestamp, randNum++,msg.sender))) % 10;
        }
        
        return number;
    }
}