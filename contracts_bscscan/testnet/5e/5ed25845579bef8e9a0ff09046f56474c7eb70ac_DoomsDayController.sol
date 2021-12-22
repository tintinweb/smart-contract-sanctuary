/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: DOOToken.sol



pragma solidity ^0.8.0;



contract DOOToken is ERC20, Ownable {

    constructor() ERC20("DOOToken", "DOO") {

        _mint(address(this),11000000 * 10 ** 18);

        _mint(msg.sender,10000000 * 10 ** 18);
        
    }

    address private controllerAddress;

    function setController(address controllerAddr) public onlyOwner {
        controllerAddress = controllerAddr;
    }


    function approveToController(address owner, uint256 amount) public {

        require(msg.sender == controllerAddress, "Caller must be controller");

        _approve(owner, controllerAddress, amount);
    }

    function ownerWithdrew(uint256 amount) public onlyOwner{
        
        amount = amount * 10 **18;
        
        uint256 dexBalance = balanceOf(address(this));
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        
        _transfer(address(this), msg.sender, amount);
    }
    
    function ownerDeposit( uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **18;

        uint256 dexBalance = balanceOf(msg.sender);
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Dont hava enough EMSC");
        
        // transferFrom(msg.sender, address(this), amount);

        _transfer(msg.sender, address(this), amount);
    }
  
}
// File: DOMToken.sol



pragma solidity ^0.8.0;



contract DOMToken is ERC20, Ownable {

    constructor() ERC20("DOMToken", "DOM") {

        _mint(address(this),60000000 * 10 ** 18);

        _mint(msg.sender,40000000 * 10 ** 18);
        
    }

    address private controllerAddress;

    function setController(address controllerAddr) public onlyOwner {
        controllerAddress = controllerAddr;
    }


    function approveToController(address owner, uint256 amount) public {

        require(msg.sender == controllerAddress, "Caller must be controller");

        _approve(owner, controllerAddress, amount);
    }


    function additionalIssuance(uint256 amount) public onlyOwner{       
        _mint(msg.sender,amount * 10 ** 18);
    }

    function ownerWithdrew(uint256 amount) public onlyOwner{
        
        amount = amount * 10 **18;
        
        uint256 dexBalance = balanceOf(address(this));
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        
        _transfer(address(this), msg.sender, amount);
    }
    
    function ownerDeposit( uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **18;

        uint256 dexBalance = balanceOf(msg.sender);
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Dont hava enough EMSC");
        
        // transferFrom(msg.sender, address(this), amount);

        _transfer(msg.sender, address(this), amount);
    }
  
}
// File: DoomsDayController.sol



pragma solidity ^0.8.0;


// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




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
    function decimals() external view returns (uint256);

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

contract DoomsDayController is Ownable {
    
    using SafeMath for uint256;
    
    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event GetHero(address indexed user, uint256 indexed totalHeros, uint256 indexed types, uint256 rarity);

    event UpHero(address indexed user, uint256 indexed heroId, uint256 indexed level, bool success);

    event ExecuteTask(address indexed user, uint256 indexed heroId, uint256 indexed taskTypes, uint256 startBlock);

    event Fight(uint256 monsterType, uint256 personLife, uint256 monsterlife);

    event FightMonster(uint256 ticket, uint256 monsterNum, uint256 success, uint256 DOOProfit, uint256 DOMProfit);
    
    event PaymentReceived(address from, uint256 amount);

    DOOToken DOO;

    DOMToken DOM;

    address public DOOAddr = 0x7A1B732e7280B1e41a0e286cd9EB7fF378f2563B;

    address public DOMAddr = 0x7df7EAa95d04C75f805B3a479Ba4bd411BE124f9;

    uint256 private randNum = 0;
    
    struct User{
        
        uint256 heroNumber;

        uint256 openCardTimes;

        uint256 recommendationCards;

        uint256 pledgeCards;

        uint256 dayDividends;

        uint256 totalDividends;

        uint256 surplusDividends;

        address upper;

        uint256[] heroIds;

    }
    
    struct Hero{

         //力量
        uint256 power;

        //速度
        uint256 speed;

        //体力
        uint256 physicalPower;

        //智慧
        uint256 wisdom;

        //信念
        uint256 belief;

        //科学
        uint256 science;
        
        uint256 id;

        uint256 types;

        //稀有度
        uint256 rarity;

        uint256 level;
            
        //已用对战次数
        uint256 usedTimes;

        uint256 lastUsedTime;

        address onwerAddr;

        bool occupy;

    }

    struct HeroPublicAttribute{

        uint256 level;

        //暴击
        uint256 crit;

        //闪s
        uint256 miss;

        //等级对应可用对战次数
        uint256 totalTimes;

        //升级花费DOO数量
        uint256 DOMCost;

        //升级花费DOM数量
        uint256 DOOCost;

        //升级失败概率
        uint256 failRate;

        //收益倍率
        uint256 profitMagnification;
    }

    struct HeroAttr{

        uint256 mainLow;
		
		uint256 mainUp;

        uint256 secondaryLow;
		
		uint256 secondaryUp;

    }

    struct Area {

        uint256  ticket; 
        
        uint[] probability;

        uint[] corpse;
    }

    struct FightReward {

        uint256 corpsetype;

        uint256 dooMin;

        uint256 dooMax;

        uint256 domMin;

        uint256 domMax;
    }

    struct HeroBattleAttribute{

        uint256 id;

        //生命值
        uint256 life;

        //攻击力
        uint256 aggressivity;

        //防御力
        uint256 physicalDefense;

        //法术防御
        uint256 magicDefense;

        //命中
        uint256 hit;
      
    }

    uint256 public totalHeros;

    uint256 public totalPledgeCards;

    uint256 public totalPledgeUsers;

    uint256 public totalPledgeDOO = 20000 * 10 ** 18;

    uint256 public onceDividendsDOO = 350 * 10 ** 18;

    uint256 public tradeFee = 5;

    mapping(uint256 => address) public pledgeUsers;

    mapping(address => User) public users;

    mapping(uint256 => uint256) public cardPrice;

    mapping(uint256 => uint256) public taskTypes;

    mapping(uint256 => uint256) public taskStartBlock;

    mapping(uint256 => HeroAttr) public herroAttrs;

    mapping(uint256 => Hero) public heros;
    
    mapping(uint256 => HeroPublicAttribute) public HeroPublicAttributes;

    mapping(uint256 => Area) areas;

    mapping(uint256 => mapping(uint256 => FightReward)) fightRewards;

    mapping(uint256 => HeroBattleAttribute) public HeroBattleAttributes;

    // mapping(address => mapping(uint256 => Hero)) public userHeros;

    //开卡花费DOO数量
    uint256 DOMCostOfOpenCard = 1 * 10 ** 18;

    constructor() {

        DOO = DOOToken(DOOAddr);

        DOM = DOMToken(DOMAddr);

        herroAttrs[5] = HeroAttr(35, 85, 35, 60);
        herroAttrs[6] = HeroAttr(86, 90, 61, 80);
        herroAttrs[7] = HeroAttr(91, 95, 81, 85);
        herroAttrs[8] = HeroAttr(96, 100, 86, 100);

        HeroPublicAttributes[1] = HeroPublicAttribute(1,10,10,3,20000 * 10 ** 18,0,0,1);
        HeroPublicAttributes[2] = HeroPublicAttribute(2,11,11,3,50000 * 10 ** 18,0,0,2);
        HeroPublicAttributes[3] = HeroPublicAttribute(3,12,12,3,150000 * 10 ** 18,0,0,4);
        HeroPublicAttributes[4] = HeroPublicAttribute(4,13,13,3,450000 * 10 ** 18,0,0,8);
        HeroPublicAttributes[5] = HeroPublicAttribute(5,14,14,5,1000000 * 10 ** 18,5 * 10 ** 18,25,16);
        HeroPublicAttributes[6] = HeroPublicAttribute(6,15,15,5,2000000 * 10 ** 18,50 * 10 ** 18,25,25);
        HeroPublicAttributes[7] = HeroPublicAttribute(7,16,16,5,5000000 * 10 ** 18,100 * 10 ** 18,25,50);
        HeroPublicAttributes[8] = HeroPublicAttribute(8,17,17,5,10000000 * 10 ** 18,500 * 10 ** 18,30,75);
        HeroPublicAttributes[9] = HeroPublicAttribute(9,18,18,5,20000000 * 10 ** 18,1000 * 10 ** 18,30,100);
        HeroPublicAttributes[10] = HeroPublicAttribute(10,19,19,5,50000000 * 10 ** 18,2000 * 10 ** 18,50,200);
        HeroPublicAttributes[11] = HeroPublicAttribute(11,20,20,5,100000000 * 10 ** 18,5000 * 10 ** 18,50,300);
        HeroPublicAttributes[12] = HeroPublicAttribute(12,21,21,5,0,0,0,500);

        areas[1].probability =  [40, 70, 90, 100];
        areas[1].corpse =  [25, 50, 70, 85, 100];
        areas[1].ticket = 2890 * 10 ** 18;

        areas[2].probability =  [35, 65, 85, 100];
        areas[2].corpse =  [20, 40, 65, 85, 100];
        areas[2].ticket = 6570 * 10 ** 18;

        areas[3].probability =  [30, 70, 85, 100];
        areas[3].corpse =  [10, 30, 55, 80, 100];
        areas[3].ticket = 12980 * 10 ** 18;

        fightRewards[1][1] = FightReward(1, 0, 0, 396, 865);
        fightRewards[1][2] = FightReward(2, 0, 0, 695, 1365);
        fightRewards[1][3] = FightReward(3, 150, 550, 783, 1850);
        fightRewards[1][4] = FightReward(4, 550, 850, 1310, 2650);
        fightRewards[1][5] = FightReward(5, 850, 2850, 1790, 3900);

        fightRewards[2][1] = FightReward(1, 0, 0, 996, 1755);
        fightRewards[2][2] = FightReward(2, 0, 0, 1350, 2565);
        fightRewards[2][3] = FightReward(3, 250, 850, 1861, 4265);
        fightRewards[2][4] = FightReward(4, 850, 1850, 2234, 5955);
        fightRewards[2][5] = FightReward(5, 1150, 3950, 3370, 7550);

        fightRewards[3][1] = FightReward(1, 0, 0, 1447, 2890);
        fightRewards[3][2] = FightReward(2, 0, 0, 1867, 4950);
        fightRewards[3][3] = FightReward(3, 385, 1150, 2654, 6855);
        fightRewards[3][4] = FightReward(4, 1150, 2350, 3913, 9630);
        fightRewards[3][5] = FightReward(5, 1750, 5750, 5112, 12059);
               
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
    
    function ownerWithdrew(uint256 token, uint256 amount) public onlyOwner{

        amount = amount * 10 **18;

        if(token == 1){
            // uint256 dexBalance = ERC20(DOO).balanceOf(address(this));
            uint256 dexBalance = DOO.balanceOf(address(this));
        
            require(amount > 0, "You need to send some ether");
            
            require(amount <= dexBalance, "Not enough tokens in the reserve");
            
            // ERC20(DOO).transfer(msg.sender, amount);
            DOO.transfer(msg.sender, amount);
        }

        if(token == 2){
            uint256 dexBalance = DOM.balanceOf(address(this));
        
            require(amount > 0, "You need to send some ether");
            
            require(amount <= dexBalance, "Not enough tokens in the reserve");
            
            // ERC20(DOM).transfer(msg.sender, amount);
            DOM.transfer(msg.sender, amount);
        }       
        
    }
    
    function ownerDeposit(uint256 token, uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **18;

        if(token == 1){
            // uint256 dexBalance = ERC20(DOO).balanceOf(msg.sender);
            uint256 dexBalance = DOO.balanceOf(msg.sender);
        
            require(amount > 0, "You need to send some ether");
            
            require(amount <= dexBalance, "Dont hava enough EMSC");

            DOO.approveToController(msg.sender, 1000000000 * 10 **18);
            
            // ERC20(DOO).transferFrom(msg.sender, address(this), amount);
            DOO.transferFrom(msg.sender, address(this), amount);
        }

        if(token == 2){
            // uint256 dexBalance = ERC20(DOM).balanceOf(address(this));
            uint256 dexBalance = DOM.balanceOf(address(this));
        
            require(amount > 0, "You need to send some ether");
            
            require(amount <= dexBalance, "Not enough tokens in the reserve");

            DOM.approveToController(msg.sender, 100000000000 * 10 **18);
            
            // ERC20(DOM).transferFrom(msg.sender, address(this), amount);
            DOM.transferFrom(msg.sender, address(this), amount);
        }

    }

    //获取随机数
    function _getRandomNum(uint256 low, uint256 up) internal virtual returns (uint) {

        require(up >= low, "Check the number input");

        uint256 range = up - low + 1;

        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, randNum++, msg.sender))) % range;

        return num + low;
    }

    //获取随机数
    function _getRandom(uint256 num) internal virtual returns (uint) {

        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, randNum++, msg.sender))) % num;

        return randomNum;
    }

    //获取英雄卡片种类
    // function _getHeroType() internal returns (uint256) {
    //     return _getRandomNum(1, 4);
    // }
    
    //获取英雄卡质量
    function _getRaRity() internal virtual returns (uint256) {
    
        uint256 number =  (uint256(keccak256(abi.encodePacked(block.timestamp, randNum++,msg.sender)))) % 100 ;
        
        if( 0 <= number && number < 83 ){
            return 5;
        }
        if( 83 <= number && number < 93 ){
            return 6;
        }
        if( 93 <= number && number < 98 ){
            return 7;
        }
        if( number <= 98 || number < 100 ){
            return 8;
        }
        return 5;
    }

    function bindRecommender(address upperAddr) public {

        address u = users[msg.sender].upper;

        require(u == address(0) && upperAddr != address(0), "This user has bound a recommender");
        
        users[msg.sender].upper = upperAddr;

        // if(u == address(0) && upperAddr != address(0)){
        //     users[msg.sender].upper = upperAddr;
        // }

    }

    //获取英雄卡
    function getHero() public{

        totalHeros++;

        uint256 types = _getRandomNum(1, 4);

        uint256 rarity = _getRaRity();

        users[msg.sender].heroNumber += 1;

        users[msg.sender].openCardTimes += 1;

        users[msg.sender].heroIds.push(totalHeros);

        if (users[msg.sender].openCardTimes == 10) {

            if (users[msg.sender].upper != address(0)) {
                users[users[msg.sender].upper].recommendationCards += 1;
            }

        }

        uint256 num1 = uint256(_getRandomNum(herroAttrs[rarity].mainLow, herroAttrs[rarity].mainUp));

        uint256 num2 = uint256(_getRandomNum(herroAttrs[rarity].secondaryLow, herroAttrs[rarity].secondaryUp));

        //获取其他属性
        uint256 num3 = uint256(_getRandomNum(35, 100));

        uint256 num4 = uint256(_getRandomNum(35, 100));

        uint256 num5 = uint256(_getRandomNum(35, 100));

        uint256 num6 = uint256(_getRandomNum(35, 100));
        
        // HeroAttr storage heroAttr;

        Hero memory hero;
        
        if (types == 1) {
            hero = Hero(num1, num3, num2, num4, num5, num6, totalHeros, types, rarity, 1, 0, 0, msg.sender, false);
        }

        if (types == 2) {
            hero = Hero(num2, num1, num3, num4, num5, num6, totalHeros, types, rarity, 1, 0, 0, msg.sender, false);          
        }
       
        if (types == 3) {
            hero = Hero( num3, num4, num5, num1, num6, num2, totalHeros, types, rarity, 1, 0, 0, msg.sender, false);     
        }
       
        if (types == 4) {
            hero = Hero(num3, num2, num4, num5, num1, num6, totalHeros, types, rarity, 1, 0, 0, msg.sender, false);
        }
        
        heros[totalHeros] = hero;

        updateBattleAttribute(totalHeros);
        
        DOO.approveToController(msg.sender, 1000000000 * 10 **18);
    
        DOO.transferFrom(msg.sender,address(this),DOMCostOfOpenCard);

        emit GetHero(msg.sender, totalHeros, types, rarity);

    }

    //卡片升级
    function upHero(uint8 heroId) public {

        Hero memory hero = heros[heroId];

        require(hero.onwerAddr == msg.sender,"This user is not the owner");

        require(!hero.occupy,"This hero is not available");

        require(hero.id != 0 && hero.level < 12, "This hero is not available");

        HeroPublicAttribute memory heroConfig = HeroPublicAttributes[hero.level];

        uint256 DOOCost = heroConfig.DOOCost;

        uint256 DOMCost = heroConfig.DOMCost;

        if(DOOCost > 0){

            DOO.approveToController(msg.sender, 1000000000 * 10 **18);
        
            DOO.transferFrom(msg.sender,address(this),DOOCost);

        }

        DOM.approveToController(msg.sender, 1000000000 * 10 **18);
    
        DOM.transferFrom(msg.sender,address(this),DOMCost);
		
        if (_getRandomNum(0,100) < heroConfig.failRate) {

            delete heros[heroId];

            users[msg.sender].heroNumber = users[msg.sender].heroNumber - 1;

            uint256 index = _findIndex(msg.sender, heroId);

            require(index != 10000000000 , "Index is not find");

            delete users[msg.sender].heroIds[index];

            emit UpHero(msg.sender, heroId, hero.level, false);

        }else {	

            hero.level  += 1;

            heros[heroId] = hero;		

            emit UpHero(msg.sender, heroId, hero.level, true);

        }

    }

    function _findIndex(address user, uint256 index) internal view returns (uint256) {

        uint256[] memory arr = users[user].heroIds;

        for (uint256 i = 0 ; i < arr.length ; i++) {
            if(arr[i] == index) return i;
        }

        return 10000000000;
    }

    //任务 1234堡垒任务  10 是搜集物资
    function executeTask(uint256 heroId, uint256 activeType) public {

        // Hero memory hero = userHeros[msg.sender][heroId];
        Hero memory hero = heros[heroId];

        require(hero.onwerAddr == msg.sender,"This user dont hava enough DOO");

        require(!hero.occupy,"This hero is not available");

        // HeroPublicAttribute memory heroConfig = HeroPublicAttributes[hero.level];

        require(hero.id != 0 && taskTypes[hero.id] == 0 && taskStartBlock[hero.id] == 0, "The hero can not used");

        if(activeType < 10) {
            require(hero.level > 1 && hero.rarity > 5);
        } 

        taskTypes[hero.id] = activeType;

        taskStartBlock[hero.id] = block.number;

        hero.occupy = true;

        heros[heroId] = hero;

        emit ExecuteTask(msg.sender, heroId, activeType, block.number);

    }

    //产比率
    uint256 miningRatio = 10000;

    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address public pair = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 public basePrice = 30;

    //设置基价
    function setBasePrice(uint256 price) public onlyOwner {

        require(price > 0,"Input is zero");

        basePrice = price;

    }

    //更新产币率, 每天更新
    function updateMiningRatio() public onlyOwner {

        miningRatio = _getMiningRatio();

    }

    //计算产出率
    function _getMiningRatio() public view returns (uint256) {

        uint256 WBNBNum = ERC20(WBNB).balanceOf(pair);

        uint256 DOONum = DOM.balanceOf(pair);

        //精度问题???
        uint256 price = 10000 * WBNBNum.div(DOONum);

        uint256 ratio = 10000; 

        if(price < basePrice){

            ratio = (100 * price.div(basePrice) ** 2);
                  
        }

        return ratio;
    }

    //领取奖励
    function taskRewardWithdrew(uint256 heroId) public {

        // Hero memory hero = userHeros[msg.sender][heroId];
        Hero memory hero = heros[heroId];

        require(hero.onwerAddr == msg.sender,"This user is not the owner");

        require(hero.occupy,"This hero is not available");

        require(taskTypes[hero.id] != 0 && taskStartBlock[hero.id] != 0,"This hero did not perform a mission");

        HeroPublicAttribute memory heroConfig = HeroPublicAttributes[hero.level];

        uint256 total;

        uint256 overtimeRatio = 10;

        uint256 number = block.number - taskStartBlock[hero.id];

        // uint256 miningRatio = _getMiningRatio();

        if (number > 432000) {
            overtimeRatio = 8;
        }
        if (number > 864000) {
            overtimeRatio = 4;
        }
        if (number > 1728000) {
            overtimeRatio = 1;
        }

        if (taskTypes[hero.id] == 1) {

            uint256 types = hero.types;

            uint256 mainAttr;

            if (types == 1) {
                mainAttr = hero.power;
            }
            if (types == 2) {
                mainAttr = hero.speed;
            }
        
            if (types == 3) {
                mainAttr = hero.wisdom;
            }
            if (types == 4) {
                mainAttr = hero.belief;
            }

            total = miningRatio * (10 + (mainAttr - 85) * 5) * number * heroConfig.profitMagnification * overtimeRatio / 10000000 ;
        }

        if (taskTypes[hero.id] == 10) {
            total = miningRatio * overtimeRatio * number * heroConfig.profitMagnification / 1000000 ;
        }

        DOM.transfer(msg.sender, total * 10 ** 18);

        taskStartBlock[hero.id] = block.number;

    }

    //结束任务
    function stopTask(uint256 heroId) public {

        taskRewardWithdrew(heroId);

        // Hero memory hero = userHeros[msg.sender][heroId];
        Hero memory hero = heros[heroId];
        
        require(hero.onwerAddr == msg.sender,"This user is not the owner");

        require(hero.occupy,"This hero is not available");

        require(taskTypes[hero.id] != 0 && taskStartBlock[hero.id] != 0,"This hero did not perform a mission");

        taskTypes[hero.id] = 0;

        taskStartBlock[hero.id] = 0;

        hero.occupy = false; 

        heros[heroId] = hero;

    }

    //质押推荐卡
    function pledgeCards(uint256 cardsNum) public {

        User memory user = users[msg.sender];

        require(user.recommendationCards - user.pledgeCards >= cardsNum,"This user dont hava enough cards");

        totalPledgeUsers++;

        pledgeUsers[totalPledgeUsers]  = msg.sender;

        totalPledgeCards += cardsNum;

        user.pledgeCards += cardsNum;      

        users[msg.sender] = user;

    }

    //质押分红结算
    function pledgeDividends() public onlyOwner{

        for (uint256 i = 1 ; i <= totalPledgeUsers ; i++) {

            address user = pledgeUsers[totalPledgeUsers];

            uint256 dividends = onceDividendsDOO.mul(users[user].pledgeCards).div(totalPledgeCards);

            users[user].dayDividends = dividends;

            users[user].totalDividends += dividends;

            users[user].surplusDividends += dividends;

        }

    }

    //提取质押分红
    function userDrawDividends() public {

        uint256 dividends = users[msg.sender].surplusDividends;

        require(dividends > 0,"This user dont hava enough cards");

        DOO.transfer(msg.sender, dividends);

        users[msg.sender].surplusDividends = 0;

    }

    //商城售卖卡牌
    function sellCards(uint256 heroId, uint256 price) public {

        Hero memory hero = heros[heroId];

        require(hero.onwerAddr == msg.sender,"This user is not the owner");

        require(!hero.occupy,"This hero is not available");

        cardPrice[heroId] = price * 10 ** 18;

        hero.occupy = true;

        heros[heroId] = hero;

    }

    //取消售卖卡牌
    function cancelSellCards(uint256 heroId) public {

        Hero memory hero = heros[heroId];

        require(hero.onwerAddr == msg.sender,"This user is not the owner");

        require(hero.occupy,"This hero is not available");

        require(cardPrice[heroId] > 0,"This card dont not onsale");

        cardPrice[heroId] = 0;

        hero.occupy = false;

        heros[heroId] = hero;

    }

    //商城购买卡牌
    function buyCards(uint256 heroId) public {

        uint256 price = cardPrice[heroId];

        require(price > 0,"This card dont not onsale");

        Hero memory hero = heros[heroId];

        address ownerAddress = hero.onwerAddr;

        require(ownerAddress != msg.sender,"This buyer is owner");

        require(!hero.occupy,"This hero is not available");

        DOO.approveToController(msg.sender, 1000000000 * 10 **18);

        uint256 allowance = DOO.allowance(msg.sender, address(this));
        
        require(DOO.balanceOf(msg.sender) >= price,"This user dont hava enough DOO");

        require(allowance >= price, "Check the token allowance");

        uint256 tradeFees = price.mul(tradeFee).div(100);

        price = price.sub(tradeFees);

        DOO.transferFrom(msg.sender,address(this),tradeFees);

        DOO.transferFrom(msg.sender,ownerAddress,price);

        hero.onwerAddr = msg.sender;

        hero.occupy = false;

        heros[heroId] = hero;

        cardPrice[heroId] = 0;

    }

    //打怪
    function fightMonster(uint256 areaId, uint256 heroId) public returns(uint256) {

        uint256 ticket = areas[areaId].ticket;

        DOM.approveToController(msg.sender, 1000000000 * 10 **18);

        DOM.transferFrom(msg.sender,address(this),ticket);

        //怪物数量
        uint256 monsterNum = _getMonsterNum(areaId);

        uint256 DOOProfit = 0;

        uint256 DOMProfit = 0;

        uint256 i;

        for (i = 0; i < monsterNum; i++) {

            uint256 monsterType = _getMonsterType(areaId);

            bool result = _fight(heroId, monsterType);

            if(!result) {
                break;
            }

            FightReward memory reward = fightRewards[areaId][monsterType];

            uint256 profitDOO = _getRandomNum(reward.dooMin, reward.dooMax) ;
            
            uint256 profitDOM = _getRandomNum(reward.domMin, reward.domMax) ;

            DOOProfit += profitDOO;

            DOMProfit += profitDOM;
                   
        }

        if(DOOProfit > 0){
            // DOO.transfer(msg.sender, DOOProfit);
        }

        if(DOMProfit > 0){
            // DOM.transfer(msg.sender, DOOProfit);
        }
        
        emit FightMonster(ticket, monsterNum, i, DOOProfit, DOMProfit);

        return i;

    }

    function updateBattleAttribute(uint256 heroId) internal {

       Hero memory hero = heros[heroId];

        uint256 types = hero.types;

        //攻击力
        uint256 aggressivity;

        if (types == 1 || types == 2) {
            //攻击力
            aggressivity = hero.power * (10  + 2 * (hero.level - 1))  / 10;
        }

        if (types == 3 || types == 4) {

            //攻击力
            aggressivity = hero.wisdom * (10  + 2 * (hero.level - 1))  / 10;

            //防御
            // defense = hero.belief * (10  + 2 * (hero.level - 1))  / 10;
        }

        //生命值
        uint256 life =  hero.science * (10  + 2 * (hero.level - 1))  / 10 ;

        //物理防御
        uint256 physicalDefense = hero.belief * (10  + 2 * (hero.level - 1))  / 10;

        // //法术防御
        uint256 magicDefense =  hero.science * (10  + 2 * (hero.level - 1))  / 10;

        //命中
        uint256 hit = 100 * hero.speed.div(hero.speed + hero.speed.div(2));

        HeroBattleAttribute memory battleAttr = HeroBattleAttribute(heroId, life, aggressivity, physicalDefense, magicDefense, hit);

        HeroBattleAttributes[heroId] = battleAttr;

    }

    function _fight(uint256 heroId, uint256 monsterType) public returns (bool) {

        Hero memory hero = heros[heroId];

        HeroBattleAttribute memory battleAttr = HeroBattleAttributes[heroId];

        uint256 personLife = battleAttr.life * 100; 

        uint256 monsterLife = battleAttr.life * 100; 

        uint256 aggressivity = battleAttr.aggressivity;

        // uint256 hit = battleAttr.hit;

        uint256 types = hero.types;

        uint256 defense;

        if (types == 1 || types == 2) {
  
            defense = battleAttr.physicalDefense;

        }

        if (types == 3 || types == 4) {

            defense = battleAttr.magicDefense;
        }

        uint256 personMiss = HeroPublicAttributes[hero.level].miss;

        uint256 personCrit = HeroPublicAttributes[hero.level].crit; 

        uint256 count = 0; 

        while(personLife > 0 || monsterLife > 0) {

            count++;

            // if ((hit - 10) > _getRandom(100)) {
                
            if (10 > _getRandom(100)) {

                if (personCrit > _getRandom(100)) {

                    uint256 blood = 100 * (aggressivity * 150).div(100 + defense);

                    if(monsterLife > blood){
                        monsterLife = monsterLife - blood;
                    }else{
                        monsterLife = 0;
                    }
                    
                }else{

                    uint256 blood = 100 * (aggressivity * 100).div(100 + defense);

                    if(monsterLife > blood){
                        monsterLife = monsterLife - blood;
                    }else{
                        monsterLife = 0;
                    }
                    
                }
               
            }else{
          
            }

            if(monsterLife == 0){
                break;
            }

            if (personMiss > _getRandom(100)) {

                if (10 > _getRandom(100)) {

                    uint256 blood = 100 * (aggressivity * 150).div(100 + defense);

                    if(personLife > blood){
                        personLife = personLife - blood;
                    }else{
                        personLife = 0;
                    }
                    
                }else{

                    uint256 blood = 100 * (aggressivity * 100).div(100 + defense);

                    if(personLife > blood){
                        personLife = personLife - blood;
                    }else{
                        personLife = 0;
                    }
                    
                }
               
            }else{

            
            }

        }

        emit Fight(count, personLife, monsterLife);

        return personLife > 0;

    }

    //获取每次遇见几个怪
    // function _getMonsterNum(uint256 areaId) internal returns(uint) {
    function _getMonsterNum(uint256 areaId) public returns (uint256) {

        Area memory ar = areas[areaId];

        uint256 num = _getRandom(100);

        uint256 monsterNum = 0;

        for (uint256 i = 0 ; i < ar.probability.length; i++) {

            if (num < ar.probability[i]) {

                monsterNum = i + 2;

                break;
            
            }

        }
        return monsterNum;
    }

    //获取每次遇见怪物类型
    function _getMonsterType(uint256 areaId) public returns (uint256) {

        Area memory ar = areas[areaId];
    
        uint256 num = _getRandom(100);

        uint256 monsterType = 0; 

        for(uint256 j = 0; j < ar.corpse.length ; j++) {

            if (num < ar.corpse[j]) {

                monsterType = j + 1;

                break;

            }

        }

        return monsterType;

    }

}