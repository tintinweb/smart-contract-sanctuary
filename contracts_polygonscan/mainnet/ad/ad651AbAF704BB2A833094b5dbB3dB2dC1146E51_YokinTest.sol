/**
 *Submitted for verification at polygonscan.com on 2021-10-06
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

interface IHRC20 {
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

interface IREWARD {
    function burn(address _address, uint256 _amount) external;
    function mint(address _address, uint256 _amount) external;
    function totalSupply() external returns (uint256);
    function transfer(address _address, uint256 _amount) external;
    function balanceOf(address _address) external returns(uint256);
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
contract ERC20 is Context, IHRC20, Ownable {
    using SafeMath for uint256;


    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping (address => bool) public isLocked;

    mapping (address => bool) public isRegistered;

    struct LockedData {
        uint256 startHoldTime;
        uint256 endHoldTime;
        uint8   checkLocked;
        uint256 balance;
    }

    mapping (address => LockedData) public LockedDatas;

    address[] public lockedAccount;

    address public AFFILIATE_ADDRESS = 0xD00db6Bd6d4498f3d865B2EEaB2f5D69b7823b68;

    IREWARD public RewardToken = IREWARD(address(0xF38339Ea7f640C5f3b78401b4c9f497cF5978959));
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint32[] InterestRate = [11, 24, 41, 60, 82, 106, 131, 158, 187, 217, 249, 282, 316, 352, 388, 426, 464, 504, 545, 586, 629, 672, 717, 762, 808, 855, 902, 951, 1000, 1050, 1101, 1152, 1205, 1257, 1311, 1365, 1420, 1476, 1532, 1589, 1646, 1705, 1763, 1823, 1883, 1943, 2004, 2066, 2128, 2191, 2255, 2319, 2383, 2448, 2514, 2580, 2646, 2714, 2781, 2849, 2918, 2987, 3057, 3127, 3198, 3269, 3341, 3413, 3485, 3558, 3632, 3706, 3780, 3855, 3930, 4006, 4082, 4159, 4236, 4314, 4392, 4470, 4549, 4628, 4708, 4788, 4868, 4949, 5030, 5112, 5194, 5276, 5359, 5443, 5526, 5610, 5695, 5780, 5865, 5950, 6036, 6123, 6210, 6297, 6384, 6472, 6560, 6649, 6738, 6827, 6917, 7007, 7097, 7188, 7279, 7370, 7462, 7554, 7647, 7740, 7833, 7926, 8020, 8114, 8209, 8304, 8399, 8494, 8590, 8687, 8783, 8880, 8977, 9075, 9172, 9270, 9369, 9468, 9567, 9666, 9766, 9866, 9966, 10067, 10168, 10269, 10371, 10473, 10575, 10677, 10780, 10883, 10987, 11090, 11194, 11299, 11403, 11508, 11613, 11719, 11825, 11931, 12037, 12144, 12251, 12358, 12465, 12573, 12681, 12790, 12898, 13007, 13116, 13226, 13336, 13446, 13556, 13666, 13777, 13888, 14000, 14112, 14224, 14336, 14448, 14561, 14674, 14787, 14901, 15015, 15129, 15243, 15358, 15473, 15588, 15703, 15819, 15935, 16051, 16168, 16284, 16401, 16519, 16636, 16754, 16872, 16990, 17108, 17227, 17346, 17465, 17585, 17705, 17825, 17945, 18065, 18186, 18307, 18428, 18550, 18672, 18794, 18916, 19038, 19161, 19284, 19407, 19531, 19654, 19778, 19902, 20027, 20151, 20276, 20401, 20527, 20652, 20778, 20904, 21030, 21157, 21283, 21410, 21538, 21665, 21793, 21921, 22049, 22177, 22306, 22434, 22563, 22693, 22822, 22952, 23082, 23212, 23342, 23473, 23604, 23735, 23866, 23998, 24129, 24261, 24393, 24526, 24658, 24791, 24924, 25057, 25191, 25325, 25458, 25593, 25727, 25861, 25996, 26131, 26266, 26402, 26537, 26673, 26809, 26946, 27082, 27219, 27356, 27493, 27630, 27768, 27905, 28043, 28181, 28320, 28458, 28597, 28736, 28875, 29015, 29154, 29294, 29434, 29574, 29715, 29855, 29996, 30137, 30278, 30420, 30561, 30703, 30845, 30987, 31130, 31273, 31415, 31558, 31702, 31845, 31989, 32133, 32277, 32421, 32565, 32710, 32855, 33000, 33145, 33290, 33436, 33582, 33728, 33874, 34020, 34167, 34314, 34461, 34608, 34755, 34903, 35050, 35198, 35346, 35495, 35643, 35792, 35941, 36090, 36239, 36388, 36538, 36688, 36838, 36988, 37138, 37289, 37440, 37591, 37742, 37893, 38045, 38196, 38348, 38500];
    uint16 bonusRatio = 1000;   // 10%
    uint32 public interestPeriod = 60;  // 1min
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
    function _transfer (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        // uint256 receiveAmount;
        // uint256 taxFeeAmount;
        bool bLocked = isLocked[sender];
        if(bLocked == false) {
            _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
            _balances[recipient] = _balances[recipient].add(amount);
        } else {
            require(bLocked, "While locking, any transaction is not alloweded");
        }

    }

    function setInterestPeriod(uint32 _period) public onlyOwner {
        require(_period > 0, "Period can't be less than zero");
        interestPeriod = _period;
    }
    
    function updateInterestRateForDay(uint16 _day, uint16 _dayInterestRatio) public onlyOwner {
        require(_day > 0, "Interest Day can't be less than zero");
        require(_dayInterestRatio > 0, "Interest Ratio can't be less than zero");
        require(_dayInterestRatio < 100000, "Interest Ratio can't exceed 100%");
        InterestRate[_day-1] = _dayInterestRatio;
    }

    function updateBonusRatio(uint16 _bonusRatio) public onlyOwner {
        require(_bonusRatio > 0, "Bonus Ratio can't be less than zero");
        require(_bonusRatio < 10000, "Bonus Ratio can't exceed 100%");
        bonusRatio = _bonusRatio;
    }

    function upadateAffiliateAddress(address _address) public onlyOwner {
        AFFILIATE_ADDRESS = _address;
    }

    function withdraw(address _to, uint256 amount) private onlyOwner {
        _transfer(address(this), address(_to), amount);
    }

    function withdrawFrom(address _from, uint256 amount) private onlyOwner {
        transferFrom(_from, address(this), amount); 
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

    function startHolding(address account) internal {
        require(!isLocked[account], "Account is already locked");

        isLocked[account] = true;
        lockedAccount.push(account);
        LockedDatas[account].startHoldTime = block.timestamp;
        LockedDatas[account].checkLocked = 1;
        LockedDatas[account].balance = balanceOf(account) + RewardToken.balanceOf(account);

        // emit startHolding(account);
    }

    function endHolding(address account) private {
        require(isLocked[account], "Account is already unlocked");
        uint256 lockedLen = lockedAccount.length;
        for(uint256 i = 0; i< lockedLen; i++) {
            if(account == lockedAccount[i]) {
                lockedAccount[i] = lockedAccount[lockedLen - 1];
                isLocked[account] = false;
                lockedAccount.pop();
                break;
            }
        }

        LockedDatas[account].endHoldTime = block.timestamp;
        LockedDatas[account].checkLocked = 2;

        // emit endHolding(account);
    }

    function calcInterestRewardAmount(uint256 balance, uint256 lockedDays) internal view returns(uint256 amount) {
        require(balance > 0, "Balance can't be less than zero");
        require(lockedDays > 0, "Locked days can't be less than zero");

        uint256 interestAmount = balance.mul(InterestRate[lockedDays-1]).div(100000);
        return interestAmount;
    }

    function calcAffiliateBonusAmount(uint256 balance) internal view returns(uint256 amount) {
        require(balance > 0, "Balance can't be less than zero");

        uint256 bonusAmount = balance.mul(bonusRatio).div(10000);
        return bonusAmount;
    }

    function rewardTo(address account, uint256 interestAmount, bool bRegistered) private {
        require(interestAmount > 0, "rewardAmount can'be less than zero");

        _mint(account, interestAmount);
        if(bRegistered) {
            uint256 bonusAmount = calcAffiliateBonusAmount(interestAmount);
            RewardToken.totalSupply().add(bonusAmount);
            RewardToken.mint(account, bonusAmount);
            RewardToken.mint(AFFILIATE_ADDRESS, bonusAmount);
        }
        // emit Transfer(account, rewardAmount);
    }

    function registerAffiliate(address account) public onlyOwner {
        require(!isRegistered[account], "Account is already registered to Affiliate");
        isRegistered[account] = true;
    }

    function registerRemove(address account) public onlyOwner {
        require(isRegistered[account], "Account is already removed from Affiliate");
            isRegistered[account] = false;
    }

    function Locked() public {
        require(balanceOf(msg.sender) > 0, "Current Token balance is zero");

        startHolding(msg.sender);
    }

    function unLocked() public {
        endHolding(msg.sender);

        require(LockedDatas[msg.sender].endHoldTime > LockedDatas[msg.sender].startHoldTime, "End Time can't be less than START Time");

        uint256 lockedDays = (LockedDatas[msg.sender].endHoldTime - LockedDatas[msg.sender].startHoldTime).div(interestPeriod);
        if(lockedDays > 365)
            lockedDays = 365;
        if(lockedDays > 0) {
            uint256 interestAmount = calcInterestRewardAmount(LockedDatas[msg.sender].balance, lockedDays);
            bool bRegistered = isRegistered[msg.sender];
            rewardTo(msg.sender, interestAmount, bRegistered);
        }
        LockedDatas[msg.sender].checkLocked = 0;    
        LockedDatas[msg.sender].balance = 0;
    }

}

// YokinToken
contract YokinTest is ERC20('YokinTest', 'YK', 8), MinterRole {

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