/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: SimPL-2.0

// File: contracts/SafeMath.sol

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

// File: contracts/TONEToken.sol


pragma solidity ^0.8.0;



contract TONEToken is ERC20, Ownable {

    constructor() ERC20("TONEToken", "TONE") {

        _mint(address(this),21000000 * 10 ** 18);

        _mint(msg.sender,21000000 * 10 ** 18);
              
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
        
        require(amount <= dexBalance, "Dont hava enough DOO");
        
        // transferFrom(msg.sender, address(this), amount);

        _transfer(msg.sender, address(this), amount);
    }


  
}
// File: contracts/DualTokenPledge.sol


pragma solidity ^0.8.0;






contract DualTokenPledge is Ownable{

    using SafeMath for uint256;


    struct User{

        // 用户地址
        address userAddress;

        // 是否有效用户
        bool valid;

        // 直推人数
        uint256 directPushNum;

        // 直推收益
        uint256 directPushIncome;

        // 间推人数
        uint256 indirectPushNum;

        // 间推收益
        uint256 indirectPushIncome;

        // 上级
        address superior;

    }

    
    struct UserPool{

        // 资金池收益
        uint256 miningIncome;

        // 用户某个池子质押的代币
        uint256 tokenAmount;

        // 质押的trx
        uint256 trxAmount;

        // 用户算力
        uint256 power;

        // 用户最后一次质押的时间
        uint256 timestamp;

        // 最后一次结算时间
        uint256 lastSettlementTime;

        // 已提取的金额
        uint256 checkedOutAmount;

    }


    // 质押规则
    struct PledgeRule{

        // 是否双币质押  true:双币质押 false:单币质押
        bool isDual;
        
        // trx累计上限
        uint256 totalTopLimitTRX;

        // token累计上限
        uint256 totalTopLimitToken;

        // trx单次质押下限
        uint256 singleLowerLimitTRX;

        // token单次质押下限
        uint256 singleLowerLimitToken;

    }

    // 手续费
    struct ServiceFee{

        uint256 NO;

        // 最小天数
        uint256 fateMIN;

        // 最大天数
        uint256 fateMAX;

        // 是否可以退出
        bool isOut;

        // 手续费
        uint256 percentageService;

    }

    
    // 资金池
    struct Pool{

        // TONE
        uint256 totalAmount;

        // trx
        uint256 trxAmount;  

    }


    // 所有用户
    mapping(address => User) public allUsers;

    // 直推用户
    mapping(address => mapping(address => User)) public directPushUsers;

    // 间推用户
    mapping(address => mapping(address => User)) public indirectPushUsers;

    // 手续费
    mapping(uint256 => ServiceFee) serviceFees;

    // 质押规则
    mapping(bool => PledgeRule) public  pledgeRules;

    // 资金池对应的用户
    mapping(bool => mapping(address => UserPool)) public userPools;

    // 记录资金池key
    mapping(bool => address[])  private userPoolKeys;
    
    // 资金池
    mapping(bool => Pool) public pools;




    // 有效用户门槛(质押的币的金额)
    uint256 public validUserAmount = 100 * 10 ** 18;
    // 产币总额
    uint256 public constant totalOrePool = 12600000 * 10 ** 18;
    // 初始每分钟产币
    uint256 public initMinuteToken = 5 * 10 ** 18;
    // 递减周期
    uint256 public diminishingDays = 10 * 10 ** 18;
    // 初始时间
    uint256 public initTime;
    // 已产出的币
    uint256 public outToken;
    // 分佣总额
    uint256 public constant commissionMax = 2100000 * 10 ** 18;
    // 已发放的佣金
    uint256 public totalCommission;
    // 直推佣金
    uint256 public constant directPushCommission = 10 * 10 ** 18;
    // 间推佣金
    uint256 public constant indirectPushCommission = 5 * 10 ** 18;




    TONEToken TONE;
    constructor(){

        TONE = new TONEToken();

        initTime = block.timestamp;

        outToken = 0;

        totalCommission = 0;

        // 初始化手续费
        serviceFees[1] = ServiceFee(1,0,30,false,0);
        serviceFees[2] = ServiceFee(2,30,60,true,20*10**18);
        serviceFees[3] = ServiceFee(3,60,90,true,10*10**18);
        serviceFees[4] = ServiceFee(4,90,100000,true,0);


        // 初始化质押规则
        pledgeRules[true] = PledgeRule(true,50000*10**18,50000*10**18,50*10**18,50);
        pledgeRules[false] = PledgeRule(true,0,100000*10**18,0,50*10**18);


        // 初始化两个资金池
        pools[true] = Pool(0,0);
        pools[false] = Pool(0,0);

    }


    
    // 用户提取收益
    function userWithdrew(uint amount) public{

        amount = amount * 10 ** 18;
        
        // 可提取的余额
        uint balance = getBalance();
                
        require(amount > 0, "You need to send some ether");
        
        require(amount <= balance, "Not enough tokens in the reserve");

        // 必须全额提取
        require(amount == balance,"The balance must be withdrawn in full!");
        
        TONE.transfer(msg.sender,balance);

        // 所有收益清零
        allUsers[msg.sender].directPushIncome = 0;

        allUsers[msg.sender].indirectPushIncome = 0;

        userPools[true][msg.sender].miningIncome = 0;

        userPools[false][msg.sender].miningIncome = 0;
    }


    // 余额
    function getBalance()public view returns(uint256){

        // 余额=直推分佣+间推分佣+资金池收益
        return allUsers[msg.sender].directPushIncome + allUsers[msg.sender].indirectPushIncome + userPools[true][msg.sender].miningIncome + userPools[false][msg.sender].miningIncome;
    
    }



    // 绑定上级
    function bingingSuperior(address superior) public{

        // 上级不存在
        require(allUsers[superior].userAddress != address(0),"address not found!");

        // 无效用户
        require(allUsers[superior].valid,"Invalid user!");

        // 已绑定上级
        require(allUsers[msg.sender].superior == address(0),"You are bound to a parent!");

        User memory user;

        // 用户未注册
        if(allUsers[msg.sender].userAddress == address(0)){

             user = _register(superior);

        }else{

             user = allUsers[msg.sender];

            // 上级不能是自己
            require(user.superior != msg.sender,"Invalid invitation code!");   

        }

        // 绑定上级
        allUsers[msg.sender].superior = superior;

        // 当前用户成为上级用户的直推用户
        directPushUsers[superior][msg.sender] = user;

        // 当前用户成为spuerior上级用户的间推用户    
        indirectPushUsers[allUsers[superior].superior][msg.sender] = user;

        if(user.valid && totalCommission < commissionMax){
            // 分佣
            _subCommission(user.userAddress);
        }

    }





    // 用户注册
    function _register(address superior)private returns(User memory){

        User memory user;

        // 构建新用户
        user = User(msg.sender,false,0,0,0,0,superior);

        // 用户信息 
        allUsers[msg.sender] = user;        

        return user;    

    }



    // 今日产币
    function _productionToken() public returns(uint256){

        uint256 blockTime = block.timestamp;

        // 天
        uint256 day = (blockTime - initTime) / 86400;
        
        // 分
        // uint256 min = (blockTime - timestamp) % 86400 / 60;
        uint256 tokenAmount;

        if(day > 100){
            tokenAmount = 1440;
        }else if(day < 10){
            tokenAmount = 7200;
        }else{
            tokenAmount = 7200 - 7200 * 8 / 100 * (day / 10);
        }

        outToken += tokenAmount;

        // 产币超出上限
        require(outToken <= totalOrePool,"Output has exceeded the ceiling!");

        return tokenAmount;
    }



    // 每日结算
    function everySettlement()public{

        uint256 todayToken = _productionToken();
        
        // 双币池结算
        for(uint256 i = 0 ; i <= userPoolKeys[true].length - 1 ; i++){

            if(userPoolKeys[true][i] != address(0)){
                // 今日收益 = 权重 * 产币
                userPools[true][userPoolKeys[true][i]].miningIncome += getWeight().mul(todayToken);
            }            
        }

        // 单币池结算
        for(uint256 i = 0 ; i <= userPoolKeys[false].length - 1 ; i++){

            if(userPoolKeys[true][i] != address(0)){
                // 今日收益 = 权重 * 产币
                userPools[false][userPoolKeys[false][i]].miningIncome += getWeight().mul(todayToken);
            }
        }
    }


    // 质押 ,是否双币， 质押的代币金额
    function pledge(bool islp,uint256 tokenAmount)public payable{

         tokenAmount = tokenAmount * 10 ** 18;

          //   未注册
          if(allUsers[msg.sender].userAddress == address(0)){    
                _register(address(0));
          }      

          bool isValid;

          UserPool memory userpool = userPools[islp][msg.sender].power == 0 ? UserPool(0,0,0,0,0,0,0) : userPools[islp][msg.sender];

          if(islp){

             //   双币质押
            isValid = tokenAmount * 2 >= validUserAmount;
             
            // 双币质押下限
            require(tokenAmount >= pledgeRules[islp].singleLowerLimitToken && msg.value >= pledgeRules[islp].singleLowerLimitTRX,"Both TRX and token must be greater than 50!");
            
            // 双币质押上限
            require(userPools[islp][msg.sender].tokenAmount + tokenAmount <= pledgeRules[islp].totalTopLimitToken && userPools[islp][msg.sender].trxAmount + msg.value <= pledgeRules[islp].totalTopLimitTRX,"Total pledge cannot exceed 50000!");

            // 资金池token总额
            pools[islp].totalAmount += tokenAmount;

            // 资金池trx总额
            pools[islp].trxAmount += msg.value;

            // 用户trx
            userpool.trxAmount += msg.value;

            // 算力
            userpool.power += (msg.value + tokenAmount);

          }else{

            //   单币质押
            isValid = tokenAmount >= validUserAmount;

            // 单币质押下限
            require(tokenAmount >= pledgeRules[islp].singleLowerLimitToken,"Single pledge cannot be less than 50!");

            // 单币质押上限
            require(userPools[islp][msg.sender].tokenAmount + tokenAmount <= pledgeRules[islp].totalTopLimitToken,"Total pledge cannot exceed 50000!");

            // 资金池总额
            pools[islp].totalAmount += tokenAmount;

            // 算力
            userpool.power += tokenAmount;

          }
           
            // 用户token总额
            userpool.tokenAmount += tokenAmount;

            userpool.timestamp = block.timestamp;

            // 用户资金池更新
            userPools[islp][msg.sender] = userpool;

            // token
            TONE.transferFrom(msg.sender,address(this),tokenAmount);

            //  key更新
            if(!_contains(islp,msg.sender)){
                userPoolKeys[islp].push(msg.sender);
            }

            // 有效入金用户分佣
            if(isValid){

                if(!allUsers[msg.sender].valid && totalCommission < commissionMax){

                    // 第一次成为有效用户给上级分佣
                    _subCommission(msg.sender);

                }                    
            }

            allUsers[msg.sender].valid = isValid;
    }


    // 退出矿池
    function outPool(bool isDual) public{

        UserPool memory userPool = userPools[isDual][msg.sender];

        // 用户未加入矿池
        require(userPool.power != 0,"You haven't joined the pool yet!");

        uint256 day = (block.timestamp - userPool.timestamp) / 86400;

        // 手续费规则
        ServiceFee memory ServiceFee;

        // token手续费
        uint256 tokenPerAmount = 0;

        // trx手续费
        uint256 trxPerAmount = 0;

        for(uint256 i = 0 ; i < 4 ; i++){

            if(day > serviceFees[i].fateMIN && day < serviceFees[i].fateMAX){

                ServiceFee = serviceFees[i];
                
                if(serviceFees[i].percentageService != 0){
                    
                    tokenPerAmount = userPools[isDual][msg.sender].tokenAmount * serviceFees[i].percentageService / 100;

                    trxPerAmount = userPools[isDual][msg.sender].trxAmount * serviceFees[i].percentageService / 100;
                }
            }
        }

        // 未满30天不能退出
        require(ServiceFee.isOut,"You cannot exit now!");
        
        // 总资金池token减少
        pools[isDual].totalAmount -= userPools[isDual][msg.sender].tokenAmount;

        // 扣除token手续费并将token本金放入余额中
        userPools[isDual][msg.sender].miningIncome += (userPools[isDual][msg.sender].tokenAmount - tokenPerAmount);

        // 本金清零
        userPools[isDual][msg.sender].tokenAmount = 0;

        // 算力清零
        userPools[isDual][msg.sender].power = 0;

        // 移除keys
        _remove(isDual,msg.sender);

        if(isDual){
             // 总资金池trx减少
            pools[isDual].trxAmount -= userPools[isDual][msg.sender].trxAmount;

            // 扣除trx手续费
            userPools[isDual][msg.sender].trxAmount -= trxPerAmount;
        }
    }



    // 用户在资金池的权重  %
    function getWeight() public view returns(uint256){

        // 权重 = 用户在资金池的总算力/资金池的总算力 
        return (userPools[true][msg.sender].power + userPools[false][msg.sender].power) / (pools[false].totalAmount + pools[true].totalAmount + pools[true].trxAmount) * 100;
    
    }


    // 分佣
    function _subCommission(address sender) private {

        // 直推用户(sender的上级)
        User memory superiorLv1 = allUsers[allUsers[sender].superior];

        // 间推用户（superior1的上级）
        User memory superiorLv2 = allUsers[superiorLv1.superior];

        if(superiorLv1.userAddress != address(0)){

            // superiorLv1的直推人数+1
            allUsers[superiorLv1.userAddress].directPushNum++;

            // 直推分佣
            allUsers[superiorLv1.userAddress].directPushIncome += directPushCommission;

            totalCommission += directPushCommission;
        }

        if(superiorLv2.userAddress != address(0)){

            // superiorLv2的间推人数+1
             allUsers[superiorLv2.userAddress].indirectPushNum++;

            // 间推分佣
            allUsers[superiorLv2.userAddress].indirectPushIncome += indirectPushCommission;

            totalCommission += indirectPushCommission;
            
        }
    }


    // 合约余额
    function getTONEBalance() public view returns(uint256){
        TONE.balanceOf(address(this));
    }


    // userPoolKeys集合中是否包含某个item
    function _contains(bool isDual,address item) private returns(bool){
        if(userPoolKeys[isDual].length == 0){
            return false;
        }
        for(uint256 i = 0 ; i <= userPoolKeys[isDual].length - 1 ; i++){
            if(userPoolKeys[isDual][i] != address(0)){
                return true;
            }
        }

    }




    // userPoolKeys移除
    function _remove(bool isDual,address item)public returns(bool){
        if(userPoolKeys[isDual].length == 0){
            return false;
        }

         uint256 index = 999999999;

         for(uint256 i = 0 ; i <= userPoolKeys[isDual].length - 1 ; i++){
            if(userPoolKeys[isDual][i] == item){
               index = i;
            }
            // if(i >= index && i < userPoolKeys[isDual].length){
            //     // 后面的元素前移
            //     userPoolKeys[isDual][i] = userPoolKeys[isDual][i+1];
            // }
        }

        if(index != 999999999){
            //  删除元素
             delete userPoolKeys[isDual][index];
            return true;
        }
    }

}