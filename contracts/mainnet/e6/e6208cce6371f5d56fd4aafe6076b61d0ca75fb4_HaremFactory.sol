/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// File: contracts-waifu/waif/utils/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts-waifu/waif/utils/Ownable.sol

pragma solidity 0.5.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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

// File: contracts-waifu/waif/utils/SafeMath.sol

pragma solidity 0.5.0;
/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }

}

// File: contracts-waifu/waif/utils/IERC20.sol

pragma solidity 0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts-waifu/waif/utils/Roles.sol

pragma solidity 0.5.0;
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

// File: contracts-waifu/waif/utils/MinterRole.sol

pragma solidity 0.5.0;




contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
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

// File: contracts-waifu/waif/utils/CanTransferRole.sol

pragma solidity 0.5.0;




contract CanTransferRole is Context {
    using Roles for Roles.Role;

    event CanTransferAdded(address indexed account);
    event CanTransferRemoved(address indexed account);

    Roles.Role private _canTransfer;

    constructor () internal {
        _addCanTransfer(_msgSender());
    }

    modifier onlyCanTransfer() {
        require(canTransfer(_msgSender()), "CanTransferRole: caller does not have the CanTransfer role");
        _;
    }

    function canTransfer(address account) public view returns (bool) {
        return _canTransfer.has(account);
    }

    function addCanTransfer(address account) public onlyCanTransfer {
        _addCanTransfer(account);
    }

    function renounceCanTransfer() public {
        _removeCanTransfer(_msgSender());
    }

    function _addCanTransfer(address account) internal {
        _canTransfer.add(account);
        emit CanTransferAdded(account);
    }

    function _removeCanTransfer(address account) internal {
        _canTransfer.remove(account);
        emit CanTransferRemoved(account);
    }
}

// File: contracts-waifu/waif/HaremNonTradable.sol

pragma solidity 0.5.0;









contract HaremNonTradable is Ownable, MinterRole, CanTransferRole {
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => uint256) private _balances;

    uint256 private _totalSupply;
    uint256 private _totalClaimed;
    string public name = "HAREM - Non Tradable";
    string public symbol = "HAREM";
    uint8 public decimals = 18;

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns the total claimed Harem
    // This is just purely used to display the total Harem claimed by users on the frontend
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }

    // Add Harem claimed
    function addClaimed(uint256 _amount) public onlyCanTransfer {
        _totalClaimed = _totalClaimed.add(_amount);
    }

    // Set Harem claimed to a custom value, for if we wanna reset the counter on new season release
    function setClaimed(uint256 _amount) public onlyCanTransfer {
        require(_amount >= 0, "Cant be negative");
        _totalClaimed = _amount;
    }

    // As this token is non tradable, only minters are allowed to transfer tokens between accounts
    function transfer(address receiver, uint numTokens) public onlyCanTransfer returns (bool) {
        require(numTokens <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(numTokens);
        _balances[receiver] = _balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    // As this token is non tradable, only minters are allowed to transfer tokens between accounts
    function transferFrom(address owner, address buyer, uint numTokens) public onlyCanTransfer returns (bool) {
        require(numTokens <= _balances[owner]);

        _balances[owner] = _balances[owner].sub(numTokens);
        _balances[buyer] = _balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    function burn(address _account, uint256 value) public onlyCanTransfer {
        require(_balances[_account] >= value, "Cannot burn more than address has");
        _burn(_account, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
}

// File: contracts-waifu/waif/HaremFactory.sol

pragma solidity 0.5.0;





contract HaremFactory is Ownable {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Harems
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accHaremPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. The pool's `accHaremPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 haremsPerDay; // The amount of Harems per day generated for each token staked
        uint256 maxStake; // The maximum amount of tokens which can be staked in this pool
        uint256 lastUpdateTime; // Last timestamp that Harems distribution occurs.
        uint256 accHaremPerShare; // Accumulated Harems per share, times 1e12. See below.
    }

    // Treasury address.
    address public treasuryAddr;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Record whether the pair has been added.
    mapping(address => uint256) public tokenPID;

    HaremNonTradable public Harem;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(HaremNonTradable _haremAddress, address _treasuryAddr) public {
        Harem = _haremAddress;
        treasuryAddr = _treasuryAddr;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new token to the pool. Can only be called by the owner.
    // XXX DO NOT add the same token more than once. Rewards will be messed up if you do.
    function add(IERC20 _token, uint256 _haremsPerDay, uint256 _maxStake) public onlyOwner {
        require(tokenPID[address(_token)] == 0, "GiverOfHarem:duplicate add.");
        require(address(_token) != address(Harem), "Cannot add Harem as a pool" );
        poolInfo.push(
            PoolInfo({
                token: _token,
                maxStake: _maxStake,
                haremsPerDay: _haremsPerDay,
                lastUpdateTime: block.timestamp,
                accHaremPerShare: 0
            })
        );
        tokenPID[address(_token)] = poolInfo.length;
    }

  
    function setMaxStake(uint256 pid, uint256 amount) public onlyOwner {
        require(amount >= 0, "Max stake cannot be negative");
        poolInfo[pid].maxStake = amount;
    }

    // Set the amount of Harems generated per day for each token staked
    function setHaremsPerDay(uint256 pid, uint256 amount) public onlyOwner {
        require(amount >= 0, "Harems per day cannot be negative");
        updatePool(pid);
        poolInfo[pid].haremsPerDay = amount;
    }

    // View function to see pending Harems on frontend.
    function pendingHarem(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 blockTime = block.timestamp;
        uint256 accHaremPerShare = pool.accHaremPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (blockTime > pool.lastUpdateTime && tokenSupply != 0) {
            uint256 haremReward = pendingHaremOfPool(_pid);
            accHaremPerShare = accHaremPerShare.add(haremReward.mul(1e12).div(tokenSupply));
        }
        return user.amount.mul(accHaremPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to calculate the total pending Harems of address across all pools
    function totalPendingHarem(address _user) public view returns (uint256) {
        uint256 total = 0;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            total = total.add(pendingHarem(pid, _user));
        }

        return total;
    }

    // View function to see pending Harems on the whole pool
    function pendingHaremOfPool(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 blockTime = block.timestamp;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        return blockTime.sub(pool.lastUpdateTime).mul(tokenSupply.mul(pool.haremsPerDay).div(86400).div(1000000000000000000));
    }

    // Harvest pending Harems of a list of pools.
    // Be careful of gas spending if you try to harvest a big number of pools
    // Might be worth it checking in the frontend for the pool IDs with pending Harem for this address and only harvest those
    function rugPull(uint256[] memory _pids) public {
        for (uint i=0; i < _pids.length; i++) {
            withdraw(_pids[i], 0);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function rugPullAll() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastUpdateTime) {
            return;
        }
        if (pool.haremsPerDay == 0) {
            pool.lastUpdateTime = block.timestamp;
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastUpdateTime = block.timestamp;
            return;
        }

        // return blockTime.sub(lastUpdateTime[account]).mul(balanceOf(account).mul(haremsPerDay).div(86400));
        uint256 haremReward = pendingHaremOfPool(_pid);
        //Harem.mint(treasuryAddr, haremReward.div(40)); // 2.5% Harem for the treasury (Usable to purchase NFTs)
        Harem.mint(address(this), haremReward);

        pool.accHaremPerShare = pool.accHaremPerShare.add(haremReward.mul(1e12).div(tokenSupply));
        pool.lastUpdateTime = block.timestamp;
    }

    // Deposit LP tokens to pool for Harem allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(_amount.add(user.amount) <= pool.maxStake, "Cannot stake beyond maxStake value");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accHaremPerShare).div(1e12).sub(user.rewardDebt);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accHaremPerShare).div(1e12);
        if (pending > 0) safeHaremTransfer(msg.sender, pending);
        pool.token.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens from pool.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accHaremPerShare).div(1e12).sub(user.rewardDebt);

        // In case the maxStake has been lowered and address is above maxStake, we force it to withdraw what is above current maxStake
        // User can delay his/her withdraw/harvest to take advantage of a reducing of maxStake,
        // if he/she entered the pool at maxStake before the maxStake reducing occured
        uint256 leftAfterWithdraw = user.amount.sub(_amount);
        if (leftAfterWithdraw > pool.maxStake) {
            _amount = _amount.add(leftAfterWithdraw - pool.maxStake);
        }

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accHaremPerShare).div(1e12);
        safeHaremTransfer(msg.sender, pending);
        pool.token.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "emergencyWithdraw: not good");
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.transfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe Harem transfer function, just in case if rounding error causes pool to not have enough Harems.
    function safeHaremTransfer(address _to, uint256 _amount) internal {
        uint256 haremBal = Harem.balanceOf(address(this));
        if (_amount > haremBal) {
            Harem.transfer(_to, haremBal);
            Harem.addClaimed(haremBal);
        } else {
            Harem.transfer(_to, _amount);
            Harem.addClaimed(_amount);
        }
    }

    // Update dev address by the previous dev.
    function treasury(address _treasuryAddr) public {
        require(msg.sender == treasuryAddr, "Must be called from current treasury address");
        treasuryAddr = _treasuryAddr;
    }
}