/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity >=0.6.0 <0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
	
    function owner() public view virtual returns (address) {
        return _owner;
    }
	
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
	
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }
	
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

pragma solidity >=0.4.0;

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

pragma solidity >=0.6.2 <0.8.0;

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


pragma solidity ^0.6.0;

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
	
    function safeApprove( IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeBEP20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
	
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

pragma solidity 0.6.12;

contract StakEarn is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
	
    // Time when current pool starts.
    uint256 public startTime;
	
    // Time when current pool ends.
    uint256 public endTime;

    // Min stake limit per user
    uint256 public minStakePerUser;
	
	// Max stake limit per user
    uint256 public maxStakePerUser;
	
	// Max stake limit on current pool
    uint256 public poolStakeLimit;
	
	// Min time to stake token
    uint256 public minTimeToStake;
	
    // reward amount per stake token (per day).
    uint256 public rewardPerStake;
	
	// Limit left to stake token
    uint256 public limitLeft;

    // The precision factor
    uint256 public PRECISION_FACTOR;
	
	// Current Pool Number
    uint256 public currentPoolNumber = 0;

    // The reward token
    IBEP20 public rewardToken;

    // The staked token
    IBEP20 public stakedToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;
	
	// WhiteList user to deposit
	mapping (address => bool) public isWhiteListed;
	
	// Pause Deposit
	bool public paused = false;
  
	modifier whenNotPaused() {
		require(!paused);
		_;
	}
	
	modifier whenPaused() {
		require(paused);
		_;
	}
	
    struct UserInfo {
        uint256 amount; 
        uint256 rewardDebt;
        uint256 startTime;
        uint256 endTime; 
		uint256 minTime;
        uint256 rewardPerStake;
        uint256 decimal;	
        IBEP20 stakedToken;
		IBEP20 rewardToken;		
    }
	
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewRewardPerStake(uint256 rewardPerStake);
    event MinStakePerUser(uint256 minStakePerUser);
	event MaxStakePerUser(uint256 maxStakePerUser);
	event MinTimeToStake(uint256 minTimeToStake);
	event PoolStakeLimit(uint256 poolStakeLimit);
    event Withdraw(address indexed user, uint256 amount);
	event AddToWhiteList(address _address);
    event RemovedFromWhiteList(address _address);
	event Pause();
    event Unpause();
   
    constructor() public {
    }
	
    function initialize(IBEP20 _stakedToken, IBEP20 _rewardToken, uint256 _rewardPerStake, uint256 _startTime, uint256 _endTime, uint256 _minStakePerUser, uint256 _maxStakePerUser, uint256 _poolStakeLimit, uint256 _minTimeToStake) external onlyOwner{
		require(endTime >= startTime, "Inccorect end time");
		require(maxStakePerUser >= minStakePerUser, "Inccorect max stake per user");
		require(poolStakeLimit >= maxStakePerUser, "Inccorect max pool stake limit");
		require(minStakePerUser >= 0, "Inccorect min stake per user");
		require(startTime >= block.timestamp, "Inccorect start time");
		
		stakedToken = _stakedToken;
		rewardToken = _rewardToken;
		rewardPerStake = _rewardPerStake;
		startTime = _startTime;
		endTime = _endTime;
		minStakePerUser = _minStakePerUser;
		maxStakePerUser = _maxStakePerUser;
		poolStakeLimit = _poolStakeLimit;
		minTimeToStake = _minTimeToStake;
		limitLeft = poolStakeLimit;
		uint256 decimalsStakedToken = uint256(stakedToken.decimals());
		PRECISION_FACTOR = uint256(10**(decimalsStakedToken));
		currentPoolNumber++;
    }
	
    function deposit(uint256 _amount) external nonReentrant {
	    UserInfo storage user = userInfo[msg.sender];
		if(paused){
		   require(isWhiteListed[msg.sender], "Sender not whitelist to deposit");
		}
		require(startTime >= block.timestamp, "Staking is not available right now");
		require(endTime < block.timestamp, "Staking is not available right now");
		require(endTime.sub(block.timestamp) >= minTimeToStake, "Staking is not available right now");
		require(limitLeft >= _amount, "This staking round is full");
		require(user.amount==0, "Staking already exits");
		require(_amount <= maxStakePerUser, "Maximum staking amount reached");
		require(_amount >= minStakePerUser, "Minimum staking amount required");
		
		if (_amount > 0) {
             user.amount = _amount;
			 user.startTime = block.timestamp;
			 user.endTime = endTime;
			 user.minTime = minTimeToStake;
			 user.rewardPerStake = rewardPerStake;
			 user.stakedToken = stakedToken;
			 user.rewardToken = rewardToken;
			 user.decimal = PRECISION_FACTOR;
             stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        }
		limitLeft.sub(_amount);
        emit Deposit(msg.sender, _amount);
    }
	
	function pendingreward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
		require(user.amount >= 0, "Stake not found");
		uint256 sTime = user.startTime;
		uint256 eTime = user.endTime > block.timestamp ? block.timestamp : user.endTime;
		uint256 tDays = ((eTime - sTime) / 1 days);
		uint256 dToken = user.amount.div(user.decimal);
		uint256 treward = dToken.mul(tDays).mul(user.rewardPerStake);
		return treward.sub(user.rewardDebt);
    }
	
    function withdraw() external nonReentrant {
		UserInfo storage user = userInfo[msg.sender];
		require(user.amount >= 0, "Stake not found");
		require(block.timestamp.sub(user.startTime) >= user.minTime, "Min staking time not complete");
		
		uint256 pending = pendingreward(msg.sender);
		uint256 _amount = user.amount;
		user.amount = 0;
		user.stakedToken.safeTransfer(address(msg.sender), _amount);
		if (pending > 0) {
			user.rewardToken.safeTransfer(address(msg.sender), pending);
		}
		user.rewardDebt = user.rewardDebt.add(pending);
		emit Withdraw(msg.sender, _amount);
    }
	
	function withdrawreward() external nonReentrant {
		UserInfo storage user = userInfo[msg.sender];
		require(user.amount >= 0, "Stake not found");
		uint256 pending = pendingreward(msg.sender);
		if (pending > 0) {
			user.rewardToken.safeTransfer(address(msg.sender), pending);
		}
		user.rewardDebt = user.rewardDebt.add(pending);
		emit Withdraw(msg.sender, pending);
    }
	
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }
	
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");
        IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
	
    function updateMinStakePerUser(uint256 _minStakePerUser) external onlyOwner {
        require(block.timestamp < startTime, "Pool has started");
        minStakePerUser = _minStakePerUser;
        emit MinStakePerUser(_minStakePerUser);
    }
	
	function updateMaxStakePerUser(uint256 _maxStakePerUser) external onlyOwner {
        require(block.timestamp < startTime, "Pool has started");
        maxStakePerUser = _maxStakePerUser;
        emit MaxStakePerUser(_maxStakePerUser);
    }
	
	function updatePoolStakeLimit(uint256 _poolStakeLimit) external onlyOwner {
        require(block.timestamp < startTime, "Pool has started");
        poolStakeLimit = _poolStakeLimit;
        emit PoolStakeLimit(_poolStakeLimit);
    }
	
    function updateRewardPerStake(uint256 _rewardPerStake) external onlyOwner {
        require(block.timestamp < startTime, "Pool has started");
        rewardPerStake = _rewardPerStake;
        emit NewRewardPerStake(_rewardPerStake);
    }
	
	function updateMinTimeToStake(uint256 _minTimeToStake) external onlyOwner {
        require(block.timestamp < startTime, "Pool has started");
        minTimeToStake = _minTimeToStake;
        emit MinTimeToStake(_minTimeToStake);
    }
	
	function getWhiteListStatus(address _address) public view returns (bool) {
        return isWhiteListed[_address];
	}
	
	function whiteListAddress(address _address) public onlyOwner{
	   isWhiteListed[_address] = true;
	   emit AddToWhiteList(_address);
    }
	
	function removeWhiteListAddress (address _address) public onlyOwner{
	   isWhiteListed[_address] = false;
	   emit RemovedFromWhiteList(_address);
	}
	
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		emit Pause();
	}
	
	function unpause() onlyOwner whenPaused public {
		paused = false;
		emit Unpause();
	}
}