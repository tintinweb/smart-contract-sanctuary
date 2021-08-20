/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
	
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
	
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IBEP20 {
   
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
    event Transfer(address indexed from, address indexed to, uint256 value);
	
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
   
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
	
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 rewardToken, address to, uint256 value) internal {
        _callOptionalReturn(rewardToken, abi.encodeWithSelector(rewardToken.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 rewardToken, address from, address to, uint256 value) internal {
        _callOptionalReturn(rewardToken, abi.encodeWithSelector(rewardToken.transferFrom.selector, from, to, value));
    }
	
    function safeApprove( IBEP20 rewardToken, address spender, uint256 value) internal {
        require((value == 0) || (rewardToken.allowance(address(this), spender) == 0),"SafeBEP20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(rewardToken, abi.encodeWithSelector(rewardToken.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 rewardToken, address spender, uint256 value) internal {
        uint256 newAllowance = rewardToken.allowance(address(this), spender).add(value);
        _callOptionalReturn(rewardToken, abi.encodeWithSelector(rewardToken.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 rewardToken, address spender, uint256 value) internal {
        uint256 newAllowance = rewardToken.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(rewardToken, abi.encodeWithSelector(rewardToken.approve.selector, spender, newAllowance));
    }
	
    function _callOptionalReturn(IBEP20 rewardToken, bytes memory data) private {
        bytes memory returndata = address(rewardToken).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract GOMAMasterChef is Ownable {
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        uint256 amount;     // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.        
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 stakeToken;           
        uint256 allocPoint;      
        uint256 lastRewardTime;  
        uint256 accRewardTokensPerShare; 
    }

    // such a Tokens rewardToken!
    IBEP20 public rewardToken;
    
    // rewardToken tokens created per block.
    uint256 public tokenPerSecond;

    // set a max rewardToken per second, which can never be higher than 1 per second
    uint256 public constant maxTokensPerSecond = 1e18;
    uint256 public constant maxAllocPoint = 4000;

	uint256 public pausedTime;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block time when rewardToken mining starts.
    uint256 public immutable startTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event Supply(address indexed user, uint256 amount);
	
    constructor(
        IBEP20 _rewardToken,
        uint256 _tokenPerSecond,
        uint256 _startTime
    ) {
        rewardToken = _rewardToken;
        tokenPerSecond = _tokenPerSecond;
        startTime = _startTime;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Changes rewardToken rewardToken reward per second, with a cap of maxtoken per second
    // Good practice to update pools without messing up the contract
    function setTokensPerSecond(uint256 _tokenPerSecond) external onlyOwner {
        require(pausedTime == 0, "setTokensPerSecond: you can't set while paused!");
		require(_tokenPerSecond <= maxTokensPerSecond, "setTokensPerSecond: too many tokens!");

        // This MUST be done or pool rewards will be calculated with new rewardToken per second
        // This could unfairly punish small pools that dont have frequent deposits/withdraws/harvests
        massUpdatePools(); 

        tokenPerSecond = _tokenPerSecond;
    }

	// 
    function supplyTokensForRewards(uint256 _amount) public {
		rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit Supply(msg.sender, _amount);
    }

	// 
    function pause() external onlyOwner {
		require(pausedTime == 0, "pause: already paused!");		
		pausedTime = block.timestamp;
    }

	// 
    function resume() external onlyOwner {
		require(pausedTime > 0, "resume: not paused!");
		massUpdatePools();
		pausedTime = 0;	
    }

    function checkForDuplicate(IBEP20 _stakeToken) internal view {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; _pid++) {
            require(poolInfo[_pid].stakeToken != _stakeToken, "add: pool already exists!");
        }
    }

    // Add a new lp to the pool.
    function addPool(uint256 _allocPoint, IBEP20 _stakeToken) external onlyOwner {
        require(_allocPoint <= maxAllocPoint, "add: too many alloc points!");
		require(pausedTime == 0, "add: you can't add while paused!");

        checkForDuplicate(_stakeToken); // ensure you cant add duplicate pools

        massUpdatePools();

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;

        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolInfo.push(PoolInfo({
            stakeToken: _stakeToken,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accRewardTokensPerShare: 0
        }));
    }

    // Update the given pool's allocation point. 
    function setPoolAllocationPoints(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        require(pausedTime == 0, "add: you can't set while paused!");
		require(_allocPoint <= maxAllocPoint, "add: too many alloc points!");

        massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        _from = _from > startTime ? _from : startTime;
        if (_to < startTime) {
            return 0;
        }

		if (pausedTime > 0) {
			return _to - (_from + (block.timestamp - pausedTime));
		} else {
			return _to - _from;
		}        
    }

    // View function to see pending on frontend.
    function pendingRewards(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        
		uint256 accRewardTokensPerShare = pool.accRewardTokensPerShare;
        uint256 stakeTokenSupply = pool.stakeToken.balanceOf(address(this));
        
		if (block.timestamp > pool.lastRewardTime && stakeTokenSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 tokenReward = multiplier * tokenPerSecond * pool.allocPoint / totalAllocPoint;
            accRewardTokensPerShare = accRewardTokensPerShare + (tokenReward * 1e12 / stakeTokenSupply);
        }

        return user.amount * accRewardTokensPerShare / 1e12 - user.rewardDebt;
    }
    

    // Update reward variables for all pools. 
    function massUpdatePools() private {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        
		uint256 stakedTokenSupply = pool.stakeToken.balanceOf(address(this));
        
		if (stakedTokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 tokenReward = multiplier * tokenPerSecond * pool.allocPoint / totalAllocPoint;

        pool.accRewardTokensPerShare = pool.accRewardTokensPerShare + (tokenReward * 1e12 / stakedTokenSupply);
        pool.lastRewardTime = block.timestamp;
    }

    // 
    function deposit(uint256 _pid, uint256 _amount) public {
		require(pausedTime == 0, "add: you can't deposit while paused!");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = user.amount * pool.accRewardTokensPerShare / 1e12 - user.rewardDebt;

        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * pool.accRewardTokensPerShare / 1e12;

        if(pending > 0) {
            safeSHADETransfer(msg.sender, pending);
        }
        pool.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw staked tokens
    function withdraw(uint256 _pid, uint256 _amount) public {  
		require(pausedTime == 0, "add: you can't withdraw while paused!");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint256 pending = user.amount * pool.accRewardTokensPerShare / 1e12 - user.rewardDebt;

        user.amount = user.amount - _amount;
        user.rewardDebt = user.amount * pool.accRewardTokensPerShare / 1e12;

        if(pending > 0) {
            safeSHADETransfer(msg.sender, pending);
        }
        
        if(_amount > 0) {
            pool.stakeToken.safeTransfer(address(msg.sender), _amount);
            emit Withdraw(msg.sender, _pid, _amount);
        }
        
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 userAmount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        pool.stakeToken.safeTransfer(address(msg.sender), userAmount);
        emit EmergencyWithdraw(msg.sender, _pid, userAmount);
    }

    // Safe rewardToken transfer function.
    function safeSHADETransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = balanceOfRewardToken();
        if (_amount > tokenBal) {
            rewardToken.transfer(_to, tokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
    
    function balanceOfRewardToken() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
}