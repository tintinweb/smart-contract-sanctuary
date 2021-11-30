/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// File: openzeppelin-solidity/contracts/access/Roles.sol
pragma solidity 0.8.10;

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

// File: contracts/roles/BurnerRole.sol
/**
 * @title Burner Role
 * @dev Follows the openzeppelin's guidelines of working with roles.
 * @dev Derived contracts must implement the `addBurner` and the `removeBurner` functions.
 */
contract BurnerRole {

    using Roles for Roles.Role;

    Roles.Role private _burners;

    /**
     * @notice Fired when a new role is added.
     */
    event BurnerAdded(address indexed account);

    /**
     * @notice Fired when a new role is added.
     */
    event BurnerRemoved(address indexed account);

    /**
     * @dev The role is granted to the deployer.
     */
    constructor ()  {
        _addBurner(msg.sender);
    }

    /**
     * @dev Callers must have the role.
     */
    modifier onlyBurner() {
        require(isBurner(msg.sender), "BurnerRole: caller does not have the Burner role");
        _;
    }

    /**
     * @dev The role is removed for the caller.    
     */
    function renounceBurner() public {
        _removeBurner(msg.sender);
    }

    /**
     * @dev Checks if @param account has the role.
     */
    function isBurner(address account) public view returns (bool) {
        return _burners.has(account);
    }

    /**
     * @dev Assigns the role to @param account.
     */
    function _addBurner(address account) internal {
        _burners.add(account);
        emit BurnerAdded(account);
    }

    /**
     * @dev Removes the role from @param account.
     */
    function _removeBurner(address account) internal {
        _burners.remove(account);
        emit BurnerRemoved(account);
    }

}

// File: contracts/roles/MinterRole.sol
/**
 * @title Minter Role
 * @dev Follows the openzeppelin's guidelines of working with roles.
 * @dev Derived contracts must implement the `addMinter` and the `removeMinter` functions.
 */
contract MinterRole {
    
    using Roles for Roles.Role;

    Roles.Role private _minters;

    /**
     * @notice Fired when a new role is added.
     */
    event MinterAdded(address indexed account);

    /**
     * @notice Fired when a new role is added.
     */
    event MinterRemoved(address indexed account);

    /**
     * @dev The role is granted to the deployer.
     */
    constructor ()  {
        _addMinter(msg.sender);
    }

    /**
     * @dev Callers must have the role.
     */
    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    /**
     * @dev The role is removed for the caller.    
     */
    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    /**
     * @dev Checks if @param account has the role.
     */
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    /**
     * @dev Assigns the role to @param account.
     */
    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    /**
     * @dev Removes the role from @param account.
     */
    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when the `owner` initiates a force transfer
     *
     * Note that `value` may be zero.
     * Note that `details` may be zero.
     */
    event ForceTransfer(address indexed from, address indexed to, uint256 value, bytes32 details);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Fee.sol
/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20Fee is IERC20 {
    using SafeMath for uint256;


    mapping (address => uint256) private _balances;

    /**
     * @dev List of whitelisted accounts.
     * 0 = default (initial value for all accounts)
     * 1 = verified account
     * 2 = partner account
     * 3 = blacklisted account (cannot send or receive tokens)
     */
    mapping (address => uint8) public whitelist;

    /**
     * @dev List of fixed transfer fees in order of account level (0 to 2). Value is in wei.
     */
    uint[] public fixedTransferFee = [uint32(0), uint32(0), uint32(0)];

    /**
     * @dev List of dynamic transfer fees in order of account level (0 to 2). Value is in mpip (milipip or 1/1000 of a PIP) per amount transferred.
     */
    uint[] public dynamicTransferFee = [uint32(0), uint32(0), uint32(0)];

    /**
     * @dev Minting fee in mpip (milipip or 1/1000 of a PIP) per amount.
     */
    uint256 public mintingFee = 0;

    /**
     * @dev Constant mpip divider
     */
    uint256 private constant mpipDivider = 10000000;

    /**
     * @dev The account that receives the fees (minting, storage and transfer).
     */
    address public feeManager;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    address public childChainManagerProxy = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");

        uint256 amount = abi.decode(depositData, (uint256));

        // `amount` token getting minted here & equal amount got locked in RootChainManager
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
        
        emit Transfer(address(0), user, amount);
    }

    function withdraw(uint256 amount) external {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Forced transfer from one account to another. Will contain details about AML procedure.
     */
    function _forceTransfer(address sender, address recipient, uint256 amount, bytes32 details) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        emit ForceTransfer(sender, recipient, amount, details);
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) override virtual public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) override virtual public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) override virtual public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) virtual public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) virtual public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        uint8 level = whitelist[sender];
        require(level != 3, "Sender is blacklisted");

        uint256 transferFee = fixedTransferFee[level] + ((dynamicTransferFee[level].mul(amount)).div(mpipDivider));

        _balances[sender] = (_balances[sender].sub(amount)).sub(transferFee);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);

        if (transferFee > 0) {
            _balances[feeManager] = _balances[feeManager].add(transferFee);
            emit Transfer(sender, feeManager, transferFee);
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        uint256 mintingFeeAmount = amount.mul(mintingFee).div(mpipDivider);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount).sub(mintingFeeAmount);
        emit Transfer(address(0), account, (amount.sub(mintingFeeAmount)));

        if (mintingFeeAmount > 0) {
            _balances[feeManager] = _balances[feeManager].add(mintingFeeAmount);
            emit Transfer(address(0), feeManager, mintingFeeAmount);
        }
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol
contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor ()  {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor ()  {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20TransferFee.sol
/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 */
contract ERC20TransferFee is ERC20Fee, Pausable {
    function transfer(address to, uint256 value) override public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) override virtual public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) override virtual public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) override virtual public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) override virtual public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/IToken.sol
/**
 * @title Token Interface
 * @dev Exposes token functionality
 */
interface IToken {

    function burn(uint256 amount) external ;

    function mint(address account, uint256 amount) external ;

}

// File: contracts/token/ECRecovery.sol
/**
 * @title Eliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */
library ECRecovery {

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}

// File: contracts/token/AWG.sol
/**
 * @title AWG Token
 * @notice ERC20 token implementation.
 * @dev Implements mintable, burnable and pausable token interfaces.
 */
contract AWG is ERC20TransferFee, MinterRole, BurnerRole, Ownable, IToken {

    /**
     * @dev Fired when a feeless transfer has been executed.
     */
    event TransferFeeless(address indexed account, uint256 indexed value);

    /**
     * @dev Fired when a feeless approve has been executed.
     */
    event ApproveFeeless(address indexed spender, uint256 indexed value);

    /**
     * @notice ERC20 convention.
     */
    uint8 public constant decimals = 18;

    /**
     * @notice ERC20 convention.
     */
    string public constant name = "AurusGOLD";
    
    /**
     * @notice ERC20 convention.
     */
    string public constant symbol = "AWG";

    /**
     * @dev Force a transfer between 2 accounts. AML logs on https://aurus.io/aml
     */
    function forceTransfer(address sender, address recipient, uint256 amount, bytes32 details) external onlyOwner {
        _forceTransfer(sender,recipient,amount,details);
    }

    /**
     * @dev Set the whitelisting level for an account.
     */
    function whitelistAddress(address account, uint8 level) external onlyOwner {
        require(level<=3, "Level: Please use level 0 to 3.");
        whitelist[account] = level;
    }

    /**
     * @dev Set the fees in the system. All the fees are in mpip, except fixedTransferFee that is in wei. Level is between 0 and 2
     */
    function setFees(uint256 _fixedTransferFee, uint256 _dynamicTransferFee, uint256 _mintingFee, uint8 level) external onlyOwner {
        require(level<=2, "Level: Please use level 0 to 2.");
        fixedTransferFee[level] = _fixedTransferFee;
        dynamicTransferFee[level] = _dynamicTransferFee;
        mintingFee = _mintingFee;
    }

    /**
     * @dev Set the address where the fees are forwarded.
     */
    function setFeeManager(address account) external onlyOwner {
        feeManager = account;
    }

    /**
     * @dev See `MinterRole._addMinter`.
     */
    function addMinter(address account) external onlyOwner {
        _addMinter(account);
    }

    /**
     * @dev See `MinterRole._removeMinter`.
     */
    function removeMinter(address account) external onlyOwner {
        _removeMinter(account);
    }

    /**
     * @dev See `BurnerRole._addBurner`.
     */
    function addBurner(address account) external onlyOwner {
        _addBurner(account);
    }

    /**
     * @dev See `BurnerRole._removeBurner`.
     */
    function removeBurner(address account) external onlyOwner {
        _removeBurner(account);
    }

    /**
     * @notice The caller must have the `BurnerRole`.
     * @dev See `ERC20._burn`.
     */
    function burn(uint256 amount) external onlyBurner {
        _burn(msg.sender, amount);
    }

    /**
     * @notice The caller must have the `MinterRole`.
     * @dev See `ERC20._mint`.
     */
    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

}