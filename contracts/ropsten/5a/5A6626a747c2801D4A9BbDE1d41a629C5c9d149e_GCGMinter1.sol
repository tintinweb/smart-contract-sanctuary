/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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



interface IGCG is IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);
}

contract GCGMinter1 is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;  
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 lastRewardBlock;  
        uint256 accGCGPerShare;
        uint256 startBlock;
        uint256 endBlock;
        uint256 GCGPerBlock;
        uint256 maxDeposit;
        uint256 hasDeposit;
    }

    IGCG public GCG;

    PoolInfo[] public poolList;
    
    mapping (uint256 => mapping (address => UserInfo)) public userInfoMap;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() public {}
    
    function init( 
        address _GCG
    ) public onlyOwner {
        require(GCG == IGCG(address(0)), "has init!");
        GCG = (IGCG)(_GCG);
    }

    function poolLength() external view returns (uint256) {
        return poolList.length;
    }

    function addPool(address _lpToken, uint256 _startBlock, uint256 _endBlock, uint256 _GCGPerBlock, uint256 _maxDeposit/*,  bool _withUpdate */) public onlyOwner {
        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        poolList.push(PoolInfo({
            lpToken: (IERC20)(_lpToken),
            startBlock: _startBlock,
            endBlock: _endBlock,
            GCGPerBlock: _GCGPerBlock,
            lastRewardBlock: lastRewardBlock,
            accGCGPerShare: 0,
            maxDeposit: _maxDeposit,
            hasDeposit: 0
        }));
    }

    function setPoolGCGPerBlock(uint256 _pid, uint256 _GCGPerBlock) public onlyOwner {
        updatePool(_pid);
        PoolInfo storage pool = poolList[_pid];
        pool.GCGPerBlock = _GCGPerBlock;
    }

    function isStartMining(uint256 _pid) public view returns(bool) {
        PoolInfo storage pool = poolList[_pid];
        return block.number >= pool.startBlock;
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingGCG(uint256 _pid, address _user) external view returns (uint256) {
        if (poolList.length <= _pid) return 0;
        PoolInfo storage pool = poolList[_pid];
        UserInfo storage user = userInfoMap[_pid][_user];
        if (user.amount == 0) return 0;
        uint256 accGCGPerShare = pool.accGCGPerShare;
        uint256 lpSupply = pool.hasDeposit;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 currentBlock = block.number <= pool.endBlock ? block.number : pool.endBlock;
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, currentBlock);
            uint256 GCGReward = multiplier.mul(pool.GCGPerBlock);
            accGCGPerShare = accGCGPerShare.add(GCGReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accGCGPerShare).div(1e12).sub(user.rewardDebt);  
    }

    function massUpdatePools() public {
        uint256 length = poolList.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolList[_pid];
        
        uint256 currentBlock = block.number <= pool.endBlock ? block.number : pool.endBlock;

        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.hasDeposit;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, currentBlock);
        uint256 GCGReward = multiplier.mul(pool.GCGPerBlock);
        GCG.mint(address(this), GCGReward);
        pool.accGCGPerShare = pool.accGCGPerShare.add(GCGReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = currentBlock;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolList[_pid];
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        require(pool.hasDeposit.add(_amount) <= pool.maxDeposit, "deposit more than maxDeposit!");
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accGCGPerShare).div(1e12).sub(user.rewardDebt);
            safeGCGTransfer(msg.sender, pending);
        }
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accGCGPerShare).div(1e12);
        pool.hasDeposit = pool.hasDeposit.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _lpAmount) public {
        PoolInfo storage pool = poolList[_pid];
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        require(user.amount >= _lpAmount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accGCGPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeGCGTransfer(msg.sender, pending);
        }
        if (_lpAmount > 0) {
            user.amount = user.amount.sub(_lpAmount);
            pool.lpToken.transfer(address(msg.sender), _lpAmount);  
        }
        user.rewardDebt = user.amount.mul(pool.accGCGPerShare).div(1e12);
        pool.hasDeposit = pool.hasDeposit.sub(_lpAmount);
        emit Withdraw(msg.sender, _pid, _lpAmount, pending);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolList[_pid];
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.transfer(address(msg.sender), amount);
        pool.hasDeposit = pool.hasDeposit.sub(amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function safeGCGTransfer(address _to, uint256 _amount) internal {

        uint256 GCGBal = GCG.balanceOf(address(this));
        if (_amount > GCGBal) {
            GCG.transfer(_to, GCGBal);
        } else {
            GCG.transfer(_to, _amount);
        }
    }
}