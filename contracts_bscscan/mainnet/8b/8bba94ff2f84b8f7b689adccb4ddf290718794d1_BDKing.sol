/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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
        return 6;
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
            _balances[sender] = senderBalance - amount + 1;
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

// File: BDKing.sol



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

contract BDKing is ERC20, Ownable{

    using SafeMath for uint256;

    event Minging(uint256 indexed tokenInPool, uint256 indexed tokenMine, uint256 indexed tokenDividents);

    event UserDrawProfit(address indexed user, uint256 indexed burnToken, uint256 indexed drawProfit);

    event UserDrawReturnFee(address indexed user, uint256 indexed drawReturnFee);

    mapping (address => bool) public _isExcludedFromFees;
    
    constructor() ERC20("Bull Demon King", "BDKing") {
    
        excludeFromFees(msg.sender, true);

        excludeFromFees(address(this), true);

        excludeFromFees(fundAddress, true);

        _mint(address(this), 70000000000 * (10**6));

        _mint(presaleAddress, 25000000000 * (10**6));

        _mint(fundAddress, 5000000000 * (10**6));
        
    }

    address public exchangeAddress;

    address public pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public presaleAddress = 0xc867665D73CeFbf4cad8099E5015D3a61aa3D708;

    address public fundAddress = 0xca1b78eC6d7ED1B09031F86AD4320A1B4405468A;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    mapping (uint256 => address) public idToPoolUsers;
    
    mapping (address => uint256) public poolUsersToId;
    
    mapping (address => uint256) public userTokenInPool;
    
    mapping (address => uint256) public lastInPoolTime;
    
    mapping (address => uint256) public tokenUserSwap;

    mapping (address => uint256) public swapTime;
    
    mapping (address => uint256) public dayMine;
    
    mapping (address => uint256) public totalMine;
    
    mapping (address => uint256) public dayDividends;
    
    mapping (address => uint256) public totalDividends;
    
    mapping (address => uint256) public tokenDraw;
    
    mapping (address => uint256) public tokenSurplus;

    uint256 public _presaleFee = 20;
    uint256 private _previousPresaleFee = _presaleFee;

    uint256 public _burnFee = 3;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _dividendsFee = 3;
    uint256 private _previousDividendsFee = _dividendsFee;

    uint256 public _returnFee = 16;
    uint256 private _previousReturnFee = _returnFee;

    uint256 public _adminFee = 14;
    uint256 private _previousAdminFee = _adminFee;
    
    uint256 public _taxBurnFee = 10;
    uint256 private _previousTaxBurnFee = _taxBurnFee;

    uint256 public totalPoolUser = 0;
    
    uint256 public tokenMineMax = 70000000000 * 10**6;

    uint256 public tokenBuyMaxOnce = 100000000 * 10**6;
    
    uint256 public totalTokenMine = 0;
    
    uint256 public lastSettleTime = 0;
    
    uint256 public totalTokenBurn;
    
    uint256 public totalDividendsFee;
    
    uint256 private totalDividendsFeeOld;
    
    uint256 public totalAdminFee;
    
    mapping (address => uint256) public returnFee;
    
    mapping (address => uint256) public presaleTime;
    
    address public lastSender;

    mapping (address => uint256) public lastAmounts;

    uint256 public lastTime;
    
    uint256 public previousTotalLiquidity;
    
    mapping (address => uint256) public lastState;
    
    uint256 public sendLeft = 5* 10**6;
    
    function setSendLeft(uint256 left) public onlyOwner {
  	    sendLeft = left;
    }

    function setExchangeAddress(address exchangeAdd) public onlyOwner {
  	    exchangeAddress = exchangeAdd;
    }

    function setPancakeRouter(address routerAdd) public onlyOwner {
  	    pancakeRouter = routerAdd;
    }

    function setPresaleAddress(address presaleAdd) public onlyOwner {
  	    presaleAddress = presaleAdd;
    }
    
    function setFundAddress(address fundAdd) public onlyOwner {
  	    fundAddress = fundAdd;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BDK: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
    }

    function ownerWithdrew(uint256 amount) public onlyOwner{
        
        amount = amount * 10 **6;
        
        uint256 dexBalance = balanceOf(address(this));
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        
        _transfer(address(this), msg.sender, amount);
    }
    
    function ownerDeposit( uint256 amount ) public onlyOwner{
        
        amount = amount * 10 **6;

        uint256 dexBalance = balanceOf(msg.sender);
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Dont hava enough EMSC");

        _transfer(msg.sender, address(this), amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(lastTime != 0 && lastState[lastSender] == 0 ){
            
            uint256 totalLiquidity = ERC20(exchangeAddress).totalSupply();
            
            uint256 lastAmount = lastAmounts[lastSender];

            if(totalLiquidity > previousTotalLiquidity){
                
                lastState[lastSender] = 2;
                
                uint256 time = lastInPoolTime[lastSender];
                
                if(time == 0 || time + 60 days > block.timestamp){
                    lastInPoolTime[lastSender] = lastTime;
                }
                
                if(poolUsersToId[lastSender] == 0){
                    totalPoolUser ++;
                
                    idToPoolUsers[totalPoolUser] = lastSender;
                    
                    poolUsersToId[lastSender] = totalPoolUser;
                }
                
                userTokenInPool[lastSender] += lastAmount;
                
            }else{  
                lastState[lastSender] = 4;                 
            }
            
        }
        
        if(amount == 0) {
            return super._transfer(from, to, 0);
        }
        
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            
            if(from == owner() && totalPoolUser == 0){
                totalPoolUser++;
            
                idToPoolUsers[1] = from;
                
                poolUsersToId[from] = 1;
            }

            return super._transfer(from, to, amount);
        }
        
        require(amount <= tokenBuyMaxOnce, "ERC20: amount exceed max");
        
        if(from == presaleAddress && !_isExcludedFromFees[to]){
            
            uint256 swap =  tokenUserSwap[to];

            swap += amount;
            
            require(swap <= tokenBuyMaxOnce, "ERC20: amount exceed max");
            
            tokenUserSwap[to] = swap;

            uint256 presaleFee = amount.mul(_presaleFee).div(100);
            
            returnFee[to] += presaleFee;
            
        	amount = amount.sub(presaleFee);
        	
            super._transfer(from, address(this), presaleFee);
            
            super._transfer(from, to, amount);
            
            presaleTime[to] = block.timestamp;
            
            return;
        }

        if(from == exchangeAddress && to == pancakeRouter){
            return super._transfer(from, to, amount);
        }
       
        if(from == pancakeRouter && !_isExcludedFromFees[to]){
      
            require(lastInPoolTime[to] != 0 && lastInPoolTime[to] + 60 days < block.timestamp,"Lock time is not up");
            
            super._transfer(from, to, amount);

            userTokenInPool[to] -= amount;
            
            return;
        }

        if(from == exchangeAddress && !_isExcludedFromFees[to]){
            
            uint256 userLiquidity = ERC20(exchangeAddress).balanceOf(to);

            require(userLiquidity == 0 && lastInPoolTime[to] == 0 && presaleTime[to] == 0, "ERC20: do not meet the purchase conditions");
            
            uint256 swap = tokenUserSwap[to];
            
            swap += amount;
            
            require(swap <= tokenBuyMaxOnce, "ERC20: amount exceed max");
            
            tokenUserSwap[to] = swap;
            
            uint256 burnFee = amount.mul(_burnFee).div(100);
            uint256 dividendsFee = amount.mul(_dividendsFee).div(100);
            uint256 returnFees = amount.mul(_returnFee).div(100);
            uint256 adminFee = amount.mul(_adminFee).div(100);
            
            totalTokenBurn += burnFee;
            totalDividendsFee += dividendsFee;
            returnFee[to] += returnFees;
            totalAdminFee += adminFee;
            
            uint256 totalFee = dividendsFee.add(returnFees).add(adminFee);
            
            super._transfer(from, to, amount);
            
            super._transfer(to, deadWallet, burnFee);
    
            super._transfer(to, address(this), totalFee);
            
            if(swapTime[to] == 0){
                swapTime[to] = block.timestamp;
            }

            return;
        }

        if(!_isExcludedFromFees[from] && to == exchangeAddress){
            
            uint256 time = swapTime[from];
            
            if(time > 0){
                
                require(time + 4 hours > block.timestamp || time + 60 days < block.timestamp, "ERC20: Time exceed");
                
                uint256 balance = balanceOf(from);
                
                require(balance <= amount + sendLeft, " All must enter the pool ");
                
                swapTime[from] = 0;
                
            }
            
            uint256 time2 = presaleTime[from];
            
            if(time2 > 0){
                
                require(time2 + 4 hours > block.timestamp, "ERC20: Time exceed");
                
                uint256 balance = balanceOf(from);
                    
                require(balance <= amount + sendLeft, " All must enter the pool ");
                
                presaleTime[from] = 0;
                
            }
            
            lastSender = from;
            lastAmounts[from] = amount;
            lastTime = block.timestamp;
            previousTotalLiquidity = ERC20(exchangeAddress).totalSupply();
            lastState[from] = 0;

            super._transfer(from, to, amount);
            
            return;  
        }
        
        require(lastInPoolTime[from] != 0 && lastInPoolTime[from] + 60 days < block.timestamp, "You must first add liquidity pool");

        super._transfer(from, to, amount);
        
    }
    
    function mining(uint256 dayNum) public onlyOwner {
        
        require((block.timestamp/24 hours)-(lastSettleTime/24 hours) >= 1 && dayNum > 0,"Can only be settled once a day");

        _transfer(address(this), msg.sender, 0);
        
        uint256 totalTokenInPool = balanceOf(exchangeAddress);
        
        require(totalTokenMine < tokenMineMax,"Up to max mine amount,stop mining");
        
        uint256 tokenNum = totalTokenInPool.mul(_mineRate()).mul(dayNum).div(10000);
        
        totalTokenMine += tokenNum;

        if(totalTokenMine > tokenMineMax){

            tokenNum = tokenNum - (totalTokenMine - tokenMineMax); 

            totalTokenMine = tokenMineMax;
           
        }
        
        uint256 tokenDividends = totalDividendsFee.sub(totalDividendsFeeOld);
        
        uint256 totalLiquidity = ERC20(exchangeAddress).totalSupply();
            
        for(uint256 i = 1; i <= totalPoolUser; i++){

            address user = idToPoolUsers[i];

            uint256 liquidity = ERC20(exchangeAddress).balanceOf(user);
            
            if(liquidity == 0){
                continue;
            }

            uint256 mine = tokenNum.mul(liquidity).div(totalLiquidity);
            
            dayMine[user] = mine;
            
            totalMine[user] += mine;

            uint256 dividends;

            if(tokenDividends > 0){
                           
                dividends = tokenDividends.mul(liquidity).div(totalLiquidity);
                
                dayDividends[user] = dividends;
                
                totalDividends[user] += dividends;
            }
            
            tokenSurplus[user] = tokenSurplus[user].add(mine).add(dividends);
        }
                 
        lastSettleTime = block.timestamp;
        
        totalDividendsFeeOld = totalDividendsFee;

        emit Minging(totalTokenInPool, tokenNum, tokenDividends);
    }
    
    function userDrawProfit() public {
        
        uint256 tokenNum = tokenSurplus[msg.sender];
        
        require(tokenNum > 0 ,"Insufficient balance");

        tokenDraw[msg.sender] += tokenNum;
        
        uint256 burnFee = tokenNum.mul(_taxBurnFee).div(100);
        
        totalTokenBurn += burnFee;
        
        tokenNum = tokenNum.sub(burnFee);
        
        super._transfer(address(this), deadWallet, burnFee);
        
        super._transfer(address(this), msg.sender, tokenNum);
        
        tokenSurplus[msg.sender] = 0;

        emit UserDrawProfit(msg.sender, burnFee, tokenNum);
        
    }
    
    function userDrawReturnFee() public {
        
        uint256 tokenNum = returnFee[msg.sender];
        
        require(tokenNum > 0,"Insufficient balance");
        
        uint256 liquiditys = ERC20(exchangeAddress).balanceOf(msg.sender);
        
        require(liquiditys > 0 ,"Not added to the liquidity pool");
        
        super._transfer(address(this), msg.sender, tokenNum);    
        
        returnFee[msg.sender] = 0;

        emit UserDrawReturnFee(msg.sender, tokenNum);
        
    }

    function _mineRate() internal view returns (uint256 mineRate){

        if(0 <= totalTokenMine && totalTokenMine <= 500000000* 10**6){
            mineRate = 100;
        }
        if(500000000* 10**6 < totalTokenMine && totalTokenMine <= 2000000000* 10**6){
            mineRate = 80;
        }
        if(2000000000* 10**6 < totalTokenMine && totalTokenMine <= 10000000000* 10**6){
            mineRate = 64;
        }
        if(10000000000* 10**6 < totalTokenMine && totalTokenMine <= 20000000000* 10**6){
            mineRate = 51;
        }
        if(20000000000* 10**6 < totalTokenMine && totalTokenMine <= 30000000000* 10**6){
            mineRate = 41;
        }
        if(30000000000* 10**6 < totalTokenMine && totalTokenMine <= 40000000000* 10**6){
            mineRate = 33;
        }
        if(40000000000* 10**6 < totalTokenMine && totalTokenMine <= 50000000000* 10**6){
            mineRate = 26;
        }
        if(50000000000* 10**6 < totalTokenMine && totalTokenMine <= 60000000000* 10**6){
            mineRate = 21;
        }
        if(60000000000* 10**6 < totalTokenMine && totalTokenMine <= 70000000000* 10**6){
            mineRate = 17;
        }
        return mineRate;
    }

    function queryLiquidity(address user) public view returns (uint256 liqusditys){
        
        liqusditys = ERC20(exchangeAddress).balanceOf(user);

        return liqusditys;
        
    }
        
}