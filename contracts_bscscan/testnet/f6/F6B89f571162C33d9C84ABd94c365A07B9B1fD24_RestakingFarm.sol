/**
 *Submitted for verification at BscScan.com on 2021-11-01
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

// File: factoryRestakingFarm.sol



pragma solidity ^0.8.0;


 
interface PurseToken {

    function transfer(address to, uint tokens) external  returns (bool success);

    function mint(address to, uint tokens) external;

    function transferFrom(address from, address to, uint tokens) external  returns (bool success);

    function balanceOf(address tokenOwner) external view returns (uint balance);

}

contract RestakingFarm is Ownable{

    // ---Contract Variables---
    string public name = "RestakingFarm";

    // Userinfo
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PURSEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPursePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPursePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 pursePerBlock;
        uint256 lastRewardBlock;  // Last block number that PURSEs distribution occurs.
        uint256 accPursePerShare; // Accumulated PURSEs per share, times 1e12. See below.
        uint256 startBlock;
    }

    // The PURSE TOKEN!
    PurseToken public purseToken;
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolId;  // poolId count from 1, need to subtract by 1 before using with variable poolInfo

    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event AddNewPool(address indexed owner, IERC20 indexed _lpToken, uint256 _pursePerBlock, bool _withUpdate, uint256 _startBlock);
    event UpdatePoolReward(address indexed owner, uint256 indexed _pid, uint256 _pursePerBlock, bool _withUpdate);
    event Harvest(address indexed user, uint256 amount);

    constructor(
        PurseToken _purseToken
    ) {
        purseToken = _purseToken;
        }
    

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(IERC20 _lpToken, uint256 _pursePerBlock, bool _withUpdate, uint256 _startBlock) public onlyOwner {
        require(poolId[address(_lpToken)] == 0, "Farmer::add: lp is already in pool");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        poolId[address(_lpToken)] = poolInfo.length + 1;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            pursePerBlock : _pursePerBlock,
            lastRewardBlock: lastRewardBlock,
            accPursePerShare: 0,
            startBlock: _startBlock
        }));
        emit AddNewPool(msg.sender, _lpToken, _pursePerBlock, _withUpdate, _startBlock);
    }

    // Update the given pool's PURSE _pursePerBlock. Can only be called by the owner.
    function set(uint256 _pid, uint256 _pursePerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        poolInfo[_pid].pursePerBlock = _pursePerBlock;
        emit UpdatePoolReward(msg.sender, _pid, _pursePerBlock, _withUpdate);
    }


    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }




    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to-_from;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 purseReward = multiplier*pool.pursePerBlock;
        purseToken.mint(address(this), purseReward);
        pool.accPursePerShare = pool.accPursePerShare+(purseReward*1e12/lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Restaking Pool for Purse allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount*pool.accPursePerShare/1e12-user.rewardDebt;
            if(pending > 0) {
                purseToken.transfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount+_amount;
        }
        user.rewardDebt = user.amount*pool.accPursePerShare/1e12;
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount*pool.accPursePerShare/1e12-user.rewardDebt;
        if(pending > 0) {
            purseToken.transfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount-_amount;
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount*pool.accPursePerShare/1e12;
        emit Withdraw(msg.sender, _amount);
    }

    // Harvest reward tokens from pool.
    function claimReward(uint256 _pid) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);
        uint256 pending = user.amount*pool.accPursePerShare/1e12-user.rewardDebt;
        if(pending > 0) {
            purseToken.transfer(msg.sender, pending);
        }
        user.rewardDebt = user.amount*pool.accPursePerShare/1e12;

        emit Harvest(msg.sender, pending);
    }


     // View function to see pending PURSEs on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPursePerShare = pool.accPursePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 multiplier;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 purseReward = multiplier*pool.pursePerBlock;
            accPursePerShare = accPursePerShare+(purseReward*(1e12)/lpSupply);
        }
        return (user.amount*(accPursePerShare)/(1e12)-(user.rewardDebt));
    }
}