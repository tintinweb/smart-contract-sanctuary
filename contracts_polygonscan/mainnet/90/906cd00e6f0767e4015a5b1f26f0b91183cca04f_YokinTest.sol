/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title MinterRole
 * @dev Implementation of the {MinterRole} interface.
 */
contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyMinter {
        _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
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

interface IERC20 {
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

interface IBonus {
    function bonusMint(address _address, uint256 _amount) external;
}

interface IInterest {
    function interestMint(address _address, uint256 _amount) external;
}


/**
 * @dev Implementation of the {IHRC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ERC20-supply-mechanisms/226[How
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
 * allowances. See {IHRC20-approve}.
 */
contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;


    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping (address => bool) public isHolded;

    mapping (address => bool) public isRegistered;

    mapping (address => address) public AFFILIATES;

    mapping (address => bool) public isValid;

    uint256 public RegisteredNum = 0;

    struct HoldedData {
        uint256 startHoldTime;
        uint256 endHoldTime;
        uint8   checkHolded;
        uint256 balance;
        bool regStats;
    }

    struct NetworkData {
        uint256 holdsInProgress;
        uint256 holdsCompleted;
        uint256 holdedToken;
        uint256 interestPaid;
        uint256 bonusPaid;
    }

    struct EarnData {
        uint256 interestAmount;
        uint256 bonusAmount;
        uint256 affiliateAmount;
        uint256 accInterestAmount;
        uint256 accBonusAmount;
    }

    struct ListData {
        address userAddress;
        address affAddress;
    }
    NetworkData public totalNetworkData;

    mapping (address => HoldedData) public HoldedDatas;

    mapping (address => EarnData) public EarnDatas;

    address[] public holdedAccount;
    ListData[] public AffiliateLists;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint16 public bonusRatio = 1000;   // 10%
    uint32 public interestPeriod = 60;  // 1min
    uint16 public APY = 105; 
    
    address public bonusAddress;
    address public interestAddress;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals; 

    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero'));
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        bool bHolded = isHolded[sender];
        if(bHolded)
            isValid[sender] = false;
        _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
    }

    function updateInterestPeriod(uint32 _period) public onlyOwner {
        require(_period > 0, "Period can't be less than zero");
        interestPeriod = _period;
    }
    
    function updateBonusRatio(uint16 _bonusRatio) public onlyOwner {
        require(_bonusRatio > 0, "Bonus Ratio can't be less than zero");
        require(_bonusRatio < 10000, "Bonus Ratio can't exceed 100%");
        bonusRatio = _bonusRatio;
    }

    function updateAPY(uint16 _apy) public onlyOwner {
        require(_apy > 0, "APY can't be less than zero");
        APY = _apy;
    }

    function updateInterestAddress(address _addr) public onlyOwner {
        interestAddress = _addr;
    }

    function updateBonusAddress(address _addr) public onlyOwner {
        bonusAddress = _addr;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: mint to the zero address');

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'ERC20: burn amount exceeds allowance'));
    }

    function holded(address account) internal {
        require(!isHolded[account], "Account is already holded");

        isHolded[account] = true;
        holdedAccount.push(account);
        HoldedDatas[account].startHoldTime = block.timestamp;
        HoldedDatas[account].checkHolded = 1;
        HoldedDatas[account].balance = balanceOf(account);
        HoldedDatas[account].regStats = isRegistered[account];

        totalNetworkData.holdsInProgress = totalNetworkData.holdsInProgress + 1;
        totalNetworkData.holdedToken = totalNetworkData.holdedToken + HoldedDatas[account].balance;
        // emit holded(account);
    }

    function unHolded(address account) private {
        require(isHolded[account], "Account is already unHolded");
        uint256 holdedLen = holdedAccount.length;
        for(uint256 i = 0; i< holdedLen; i++) {
            if(account == holdedAccount[i]) {
                holdedAccount[i] = holdedAccount[holdedLen - 1];
                isHolded[account] = false;
                holdedAccount.pop();
                break;
            }
        }

        HoldedDatas[account].endHoldTime = block.timestamp;
        HoldedDatas[account].checkHolded = 2;
        totalNetworkData.holdedToken = totalNetworkData.holdedToken - HoldedDatas[account].balance;

        // emit unHolded(account);
    }

    function calcInterestRewardAmount(uint256 balance, uint256 holdedDays) public view returns(uint256 amount) {
        require(balance > 0, "Balance can't be less than zero");
        require(holdedDays > 0, "Holded day can't be less than zero");

        uint256 interestAmount = 0;
        if(holdedDays < 365)
            interestAmount = balance.mul(APY).mul(holdedDays).div(365).div(100);
        else    
            interestAmount = balance.mul(APY).div(100);
        return interestAmount;
    }

    function calcAffiliateBonusAmount(uint256 balance) public view returns(uint256 amount) {
        require(balance > 0, "Balance can't be less than zero");

        uint256 bonusAmount = balance.mul(bonusRatio).div(10000);
        return bonusAmount;
    }

    function RegisterAffiliate(address _affiliateAddr) public {
        require(!isRegistered[msg.sender], "Account is already registered to Affiliate");
        isRegistered[msg.sender] = true;
        AFFILIATES[msg.sender] = _affiliateAddr;
        ListData memory oneList = ListData(msg.sender, _affiliateAddr);
        AffiliateLists.push(oneList);
        RegisteredNum = RegisteredNum + 1;
    }

    function registerRemove(address account) public onlyOwner {
        require(isRegistered[account], "Account is already removed from Affiliate");
        isRegistered[account] = false;
        AFFILIATES[account] = 0x0000000000000000000000000000000000000000;
        uint256 length = AffiliateLists.length;
        for(uint256 i = 0; i < length; i++) {
            if(account == AffiliateLists[i].userAddress) {
                AffiliateLists[i] = AffiliateLists[length - 1];
                AffiliateLists.pop();
            }
        }
        RegisteredNum = RegisteredNum - 1;
    }

    function StartHolding() public {
        require(balanceOf(msg.sender) > 0, "Current Token balance is zero");

        holded(msg.sender);
        isValid[msg.sender] = true;
    }

    function StopHolding() public {
        unHolded(msg.sender);

        require(HoldedDatas[msg.sender].endHoldTime > HoldedDatas[msg.sender].startHoldTime, "End Time can't be less than START Time");

        if(isValid[msg.sender] == true) {
            uint256 holdedDays = (HoldedDatas[msg.sender].endHoldTime - HoldedDatas[msg.sender].startHoldTime).div(interestPeriod);
            uint256 interestAmount = calcInterestRewardAmount(HoldedDatas[msg.sender].balance, holdedDays);
            bool bRegistered = HoldedDatas[msg.sender].regStats;
            
            // rewardTo(msg.sender, interestAmount, bRegistered);
            EarnDatas[msg.sender].interestAmount = EarnDatas[msg.sender].interestAmount + interestAmount;
            EarnDatas[msg.sender].accInterestAmount = EarnDatas[msg.sender].accInterestAmount + interestAmount;
            if(bRegistered) {
                uint256 bonusAmt = calcAffiliateBonusAmount(interestAmount);
                _mint(AFFILIATES[msg.sender], bonusAmt);
                if(AFFILIATES[msg.sender] == msg.sender) {
                    EarnDatas[msg.sender].bonusAmount = EarnDatas[msg.sender].bonusAmount.add(bonusAmt).add(bonusAmt);
                    EarnDatas[msg.sender].accBonusAmount = EarnDatas[msg.sender].accBonusAmount.add(bonusAmt).add(bonusAmt);

                } else {
                    EarnDatas[msg.sender].bonusAmount = EarnDatas[msg.sender].bonusAmount.add(bonusAmt);
                    EarnDatas[msg.sender].accBonusAmount = EarnDatas[msg.sender].accBonusAmount.add(bonusAmt);
                    EarnDatas[msg.sender].affiliateAmount = EarnDatas[msg.sender].affiliateAmount.add(bonusAmt);
                }
                totalNetworkData.bonusPaid = totalNetworkData.bonusPaid.add(bonusAmt);
            }
            
            
        }

        HoldedDatas[msg.sender].checkHolded = 0;    
        HoldedDatas[msg.sender].balance = 0;

        totalNetworkData.holdsInProgress = totalNetworkData.holdsInProgress - 1;
        totalNetworkData.holdsCompleted = totalNetworkData.holdsCompleted + 1;
        
        isValid[msg.sender] = false;
    }

    function claimInterest(address account) public {
        require(msg.sender == interestAddress, "You can claim interest in Interest Contract");

        uint256 intAmount = EarnDatas[account].accInterestAmount;
        _mint(account, intAmount);
        totalNetworkData.interestPaid = totalNetworkData.interestPaid + intAmount;
        EarnDatas[account].accInterestAmount = 0;

    }

    function claimBonus(address account) public {
        require(msg.sender == bonusAddress, "You can claim bonus in Bonus Contract");

        uint256 bonAmount = EarnDatas[account].accBonusAmount;
        _mint(account, bonAmount);
        totalNetworkData.bonusPaid = totalNetworkData.bonusPaid + bonAmount;
        EarnDatas[account].accBonusAmount = 0;

    }

    function ResetHolding() public {
        require(isHolded[msg.sender], "Account should be holding");

        if(isValid[msg.sender] == false) {
            unHolded(msg.sender);
            HoldedDatas[msg.sender].checkHolded = 0;    
            HoldedDatas[msg.sender].balance = 0;

            totalNetworkData.holdsInProgress = totalNetworkData.holdsInProgress - 1;
            totalNetworkData.holdsCompleted = totalNetworkData.holdsCompleted + 1;
        }

    }

}

// YokinToken
contract YokinTest is ERC20('YokinTest_v17', 'YK_v17', 8), MinterRole {

    uint256 private _premintAmount = 44 * 10**7 * 10**8;
    constructor () public {
        _mint(owner(), _premintAmount);
    }

    function approve(address owner, address spender, uint256 amount) public onlyOwner {
        _approve(owner, spender, amount);
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    /// @notice Bunrs `_amount` token fromo `_from`. Must only be called by the owner.
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }
    
    /// @notice Presale `_amount` token to `_to`. Must only be called by the minter.
    function presale(address _to, uint256 _amount) public onlyMinter {
        _transfer(address(this), _to, _amount);
    }
}