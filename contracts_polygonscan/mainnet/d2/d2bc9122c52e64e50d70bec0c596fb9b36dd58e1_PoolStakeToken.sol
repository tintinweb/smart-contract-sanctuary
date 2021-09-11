/**
 *Submitted for verification at polygonscan.com on 2021-09-11
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

// File: PolyCrystal/staking-pools/contracts/libraries/IPoolV1.sol


pragma solidity ^0.8.4;

/*
Join us at PolyCrystal.Finance!
█▀▀█ █▀▀█ █░░ █░░█ █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░█ █░░█ █░░ █▄▄█ █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
█▀▀▀ ▀▀▀▀ ▀▀▀ ▄▄▄█ ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/


interface IPoolV1 {
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 accRewardTokenPerShare; // Accumulated Rewards per share, times 1e30. See below.
    }
    
    // The stake token
    function STAKE_TOKEN() external view returns (IERC20);
    
    // The reward token
    function REWARD_TOKEN() external view returns (IERC20);
    
    // Reward tokens created per block.
    function rewardPerBlock() external view returns (uint256);
    
    // Keep track of number of tokens staked in case the contract earns reflect fees
    function totalStaked() external view returns (uint256);
    
    function poolInfo() external view returns (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accRewardTokenPerShare);
    
    function userInfo(address _user) external view returns (uint256 amount, uint256 rewardDebt);

    // The block number when Reward mining starts.
    function startBlock() external view returns (uint256);
	// The block number when mining ends.
    function bonusEndBlock() external view returns (uint256);

    event Deposit(address indexed user, uint256 amount);
    event DepositRewards(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event SkimStakeTokenFees(address indexed user, uint256 amount);
    event LogUpdatePool(uint256 bonusEndBlock, uint256 rewardPerBlock);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event EmergencySweepWithdraw(address indexed user, IERC20 indexed token, uint256 amount);

    function initialize(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external;

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    /// @param  _bonusEndBlock The block when rewards will end
    function setBonusEndBlock(uint256 _bonusEndBlock) external;
    

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256);

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() external;


    /// Deposit staking token into the contract to earn rewards.
    /// @dev Since this contract needs to be supplied with rewards we are
    ///  sending the balance of the contract if the pending rewards are higher
    /// @param _amount The amount of staking tokens to deposit
    function deposit(uint256 _amount) external;

    /// Withdraw rewards and/or staked tokens. Pass a 0 amount to withdraw only rewards
    /// @param _amount The amount of staking tokens to withdraw
    function withdraw(uint256 _amount) external;
    
    /// Obtain the reward balance of this contract
    /// @return wei balace of conract
    function rewardBalance() external view returns (uint256);

    // Deposit Rewards into contract
    function depositRewards(uint256 _amount) external;

    /// @dev Obtain the stake balance of this contract
    function totalStakeTokenBalance() external view returns (uint256);
    
    /// @dev Obtain the stake token fees (if any) earned by reflect token
    function getStakeTokenFeeBalance() external view returns (uint256);

    /* Admin Functions */

    /// @param _rewardPerBlock The amount of reward tokens to be given per block
    function setRewardPerBlock(uint256 _rewardPerBlock) external;

        /// @dev Remove excess stake tokens earned by reflect fees
    function skimStakeTokenFees() external;

    /* Emergency Functions */

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external;

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external;
    /// @notice A public function to sweep accidental BEP20 transfers to this contract.
    ///   Tokens are sent to owner
    /// @param token The address of the BEP20 token to sweep
    function sweepToken(IERC20 token) external;

}
// File: PolyCrystal/staking-pools/contracts/PoolStakeToken.sol


pragma solidity ^0.8.4;

/*
Join us at PolyCrystal.Finance!
█▀▀█ █▀▀█ █░░ █░░█ █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░█ █░░█ █░░ █▄▄█ █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
█▀▀▀ ▀▀▀▀ ▀▀▀ ▄▄▄█ ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/




contract PoolStakeToken is Ownable {
    
    address public constant pool = 0xF26914ea34EE64A439caAaBb1FACf9f063c7B234;
    IPoolV1 internal constant _pool = IPoolV1(pool);
    string public constant name = unicode"CRYSTL→ETH pool";
    string public constant symbol = unicode"💎→ETH";
    uint8 public constant decimals = 18;
    
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint) internal lkBalance; //last known balance
    mapping (address => uint) internal userID;
    uint userTotal;
    
    address[] users;
    
    constructor() {
        uint _totalSupply = totalSupply();
        lkBalance[pool] = _totalSupply;
        users.push() = pool;
        
        emit Transfer(address(0), pool, _totalSupply);
    }
    
    function setlkBalance(address user) internal returns (uint oldBalance, uint newBalance) {
        oldBalance = lkBalance[user];
        
        newBalance = balanceOf(user);
        lkBalance[user] = newBalance;
            
    }
    
    function totalSupply() public view returns (uint256) {
        return _pool.totalStaked();
    }

    function balanceOf(address account) public view returns (uint256 balance) {
        if (account == pool) {
            uint _totalSupply = totalSupply();
            balance = _totalSupply > userTotal ? _totalSupply - userTotal : 0;
        }
        else {
            (balance, ) = _pool.userInfo(account);
        }
    }

    function transfer(address recipient, uint256 amount) external returns (bool success) {
        update(msg.sender);
        update(recipient);
        
        if (amount == 0) {
            emit Transfer(msg.sender, recipient,  amount);
            return true;
        }
        return false;
    }

    function approve(address spender, uint256) external returns (bool success) {
        update(msg.sender);
        update(spender);
        emit Approval(msg.sender, spender, 0);
        return false;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external _update(sender) _update(recipient) returns (bool) {
        update(msg.sender);
        if (sender != msg.sender) update(sender);
        if (recipient != msg.sender) update(recipient);
       if (amount == 0) {
            emit Transfer(sender, recipient, 0);
            return true;
        }
        return false;
    }
    modifier _update(address account) {
        update(account);
        _;
    }
    
    function update(address account) public {
        if (account == pool) return;
        
        (uint oldBalance, uint newBalance) = setlkBalance(account);
        (uint oldPoolBalance, uint newPoolBalance) = setlkBalance(pool);
    
        uint newAll = newBalance + newPoolBalance;
        uint oldAll = oldBalance + oldPoolBalance;
    
        if (newAll > oldAll) emit Transfer(address(0), pool, newAll - oldAll);
        
        if (newBalance < oldBalance) emit Transfer(account, pool, oldBalance - newBalance);
        else if (newBalance > oldBalance) emit Transfer(pool, account, newBalance - oldBalance);
        
        
        if (newAll < oldAll) emit Transfer(pool, address(0), oldAll - newAll);

    }
    function updateAll() external {
        (uint oldPoolBalance, uint newPoolBalance) = setlkBalance(pool);
        
        uint oldTotalBalance;
        uint newTotalBalance;
        uint[] memory oldBalance = new uint[](users.length);
        uint[] memory newBalance = new uint[](users.length);
        for (uint i; i < users.length; i++) {
            if (users[i] == pool) continue;
            (oldBalance[i], newBalance[i]) = setlkBalance(users[i]);
            oldTotalBalance += oldBalance[i];
            newTotalBalance += newBalance[i];
        }
        
        uint newAll = newPoolBalance + newTotalBalance;
        uint oldAll = oldPoolBalance + oldTotalBalance;
        
        if (newAll > oldAll) emit Transfer(address(0), pool, newAll - oldAll);
        
        for (uint i; i < users.length; i++) {
            if (newBalance[i] < oldBalance[i]) emit Transfer(users[i], pool, oldBalance[i] - newBalance[i]);
            if (oldBalance[i] < newBalance[i]) emit Transfer(pool, users[i], newBalance[i] - oldBalance[i]);
        }
        
        if (newAll < oldAll) emit Transfer(pool, address(0), oldAll - newAll);
        
    }
    
    function destroy() onlyOwner external {
        
        selfdestruct(payable(owner()));
    }
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
}