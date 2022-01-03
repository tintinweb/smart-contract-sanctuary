/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (){
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

/* Lock Type:
1: Daily
2: Weakly
3: Monthly
4: Yearly
*/

contract ReleaseVault is Ownable {
    using SafeMath for uint256;

	uint256 private LOCKTYPE_MINUTELY 	= 0;
	uint256 private LOCKTYPE_DAILY 		= 1;
	uint256 private LOCKTYPE_WEAKLY 	= 2;
	uint256 private LOCKTYPE_MONTHLY 	= 3;
	uint256 private LOCKTYPE_YEARLY	 	= 4;

	struct AllocationInfo {
    	string alloName;
        uint256 lockType;
        uint256 lockAmount;
        uint256 releaseRecurringAmount;
        uint256 startTime;
        uint256 cliffingTimePeriod;
        uint256 releaseTimePeriod;
        bool exists;
    }

    struct ReleaseInfo {
        string alloName;
        uint256 releasedAmount;
        uint256 lastReleaseTime;
        bool exists;
    }

    address public _tokenAddress;
    mapping (address => ReleaseInfo) private _releaseMapping;
    mapping (string => AllocationInfo) private _alloMapping;
    mapping (string => address[]) private _addressMapping;


    function setTokenAddress(address tokenAddress) public onlyOwner {
    	_tokenAddress = tokenAddress;
    }

    function setLockAllocation(string memory alloName, address[] memory releaseAddresses, uint256 lockType, uint256 lockAmount, uint256 cliffingTimePeriod, uint256 releaseTimePeriod) public onlyOwner {
        require(_alloMapping[alloName].exists == false, "The allocation is existed");
        
        for (uint256 i =  0; i < releaseAddresses.length; i++) {
            address releaseAddress = releaseAddresses[i];
            require(releaseAddress != address(0), "Addresses must not be zero");
    	    require(_releaseMapping[releaseAddress].exists == false, "There is addresses in lock allocation");
        }
        
    	require(lockType >= LOCKTYPE_MINUTELY && lockType <= LOCKTYPE_YEARLY, "Lock type is not included");
    	require(_tokenAddress != address(0), "Token address must not be zero");

    	uint256 ownerBalance = IERC20(_tokenAddress).balanceOf(_msgSender());
    	require(ownerBalance >= lockAmount, "Balance of owner must be greater than lock amount");

    	IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), lockAmount);

    	uint256 recurringAmount = _calculateRecurringAmount(lockType, releaseTimePeriod, lockAmount);

    	AllocationInfo memory allocationInfo = AllocationInfo({
    		alloName: alloName,
    		lockType: lockType,
    		lockAmount: lockAmount,
    		releaseRecurringAmount: recurringAmount,
            startTime: block.timestamp,
    		cliffingTimePeriod: cliffingTimePeriod,
            releaseTimePeriod: releaseTimePeriod,
    		exists: true
    	});

        for (uint256 i = 0; i < releaseAddresses.length; i++) {
            address releaseAddress = releaseAddresses[i];
            ReleaseInfo memory releaseInfo = ReleaseInfo({
            	alloName: alloName,
            	releasedAmount: 0,
            	lastReleaseTime: 0,
                exists: true
            });

            _releaseMapping[releaseAddress] = releaseInfo;
            _addressMapping[alloName].push(releaseAddress);
        }
    	
    	_alloMapping[alloName] = allocationInfo;
    }

    function addLockAllocation(string memory alloName, address[] memory releaseAddresses) public onlyOwner {
        require(_alloMapping[alloName].exists == true, "The allocation is not existed");

        for (uint256 i =  0; i < releaseAddresses.length; i++) {
            address releaseAddress = releaseAddresses[i];
            require(releaseAddress != address(0), "Addresses must not be zero");
    	    require(_releaseMapping[releaseAddress].exists == false, "There are addresses in lock allocation");
        }

        for (uint256 i =  0; i < releaseAddresses.length; i++) {
            address releaseAddress = releaseAddresses[i];
            ReleaseInfo memory releaseInfo = ReleaseInfo({
            	alloName: alloName,
            	releasedAmount: 0,
            	lastReleaseTime: 0,
                exists: true
            });

            _releaseMapping[releaseAddress] = releaseInfo;
            _addressMapping[alloName].push(releaseAddress);
        }
    }

    function removeLockAllocation(string memory alloName) public onlyOwner {
    	require(_alloMapping[alloName].exists == true, "The allocation is not existed");
    	AllocationInfo memory allocationInfo = _alloMapping[alloName];
    	uint256 totalReleasedAmount = 0;
    	for (uint256 i = 0; i < _addressMapping[alloName].length; i++) {
    		address releaseAddress = _addressMapping[alloName][i];
    		ReleaseInfo memory releaseInfo = _releaseMapping[releaseAddress];
    		totalReleasedAmount += releaseInfo.releasedAmount;
    	}

    	uint256 remainLockAmount = allocationInfo.lockAmount - totalReleasedAmount;

    	IERC20(_tokenAddress).transfer(_msgSender(), remainLockAmount);

    	for (uint256 i = 0; i < _addressMapping[alloName].length; i++) {
    		address releaseAddress = _addressMapping[alloName][i];
    		delete _releaseMapping[releaseAddress];
    	}
    	
    	delete _alloMapping[alloName];
        delete _addressMapping[alloName];
    }

    function claimLockToken() public {
    	require(_releaseMapping[_msgSender()].exists == true, "The address is not in lock allocation");

    	ReleaseInfo memory releaseInfo = _releaseMapping[_msgSender()];
    	AllocationInfo memory allocationInfo = _alloMapping[releaseInfo.alloName];
    	uint256 unclaimAmount = _calculateUnclaimAmount(allocationInfo, releaseInfo);
    	require(unclaimAmount > 0, "There is no token for claiming");

    	IERC20(_tokenAddress).transfer(_msgSender(), unclaimAmount);

    	releaseInfo.releasedAmount += unclaimAmount;
    	releaseInfo.lastReleaseTime = block.timestamp;

        _releaseMapping[_msgSender()] = releaseInfo;
    }

    function getLockInfo(address releaseAddress) public view 
    returns(
    	string memory _alloName,
    	uint256 _lockType,
    	uint256 _lockAmount,
    	uint256 _releaseRecurringAmount,
    	uint256 _releasedAmount,
    	uint256 _unclaimAmount,
    	uint256 _startTime,
    	uint256 _nextReleaseTime,
    	uint256 _cliffingTimePeriod,
    	uint256 _releaseTimePeriod,
    	uint256 _lastReleaseTime
    ) {
    	require(releaseAddress != address(0), "The address must not be zero");
    	require(_releaseMapping[releaseAddress].exists == true, "The address is not in lock allocation");

    	ReleaseInfo memory releaseInfo = _releaseMapping[releaseAddress];
    	AllocationInfo memory allocationInfo = _alloMapping[releaseInfo.alloName];
    	uint256 unclaimAmount = _calculateUnclaimAmount(allocationInfo, releaseInfo);
    	uint256 nextReleaseTime = _getNextReleaseTime(allocationInfo.lockType, allocationInfo.startTime, allocationInfo.cliffingTimePeriod);
    	uint256 alloAddressCount = _addressMapping[releaseInfo.alloName].length;

    	_alloName = allocationInfo.alloName;
    	_lockType = allocationInfo.lockType;
    	_lockAmount = allocationInfo.lockAmount.div(alloAddressCount);
    	_releaseRecurringAmount = allocationInfo.releaseRecurringAmount.div(alloAddressCount);
    	_releasedAmount = releaseInfo.releasedAmount;
    	_unclaimAmount = unclaimAmount;
    	_startTime = allocationInfo.startTime;
    	_nextReleaseTime = nextReleaseTime;
    	_cliffingTimePeriod = allocationInfo.cliffingTimePeriod;
    	_releaseTimePeriod = allocationInfo.releaseTimePeriod;
    	_lastReleaseTime = releaseInfo.lastReleaseTime;
    }

    function getAllocationInfo(string memory alloName) public view 
    returns(
    	string memory _alloName,
    	uint256 _lockType,
    	uint256 _lockAmount,
    	uint256 _releaseRecurringAmount,
    	uint256 _startTime,
    	uint256 _cliffingTimePeriod,
    	uint256 _releaseTimePeriod
    ) {
    	require(_alloMapping[alloName].exists == true, "The allocation is not existed");

    	AllocationInfo memory allocationInfo = _alloMapping[alloName];
    	_alloName = allocationInfo.alloName;
    	_lockType = allocationInfo.lockType;
    	_lockAmount = allocationInfo.lockAmount;
    	_releaseRecurringAmount = allocationInfo.releaseRecurringAmount;
    	_startTime = allocationInfo.startTime;
    	_cliffingTimePeriod = allocationInfo.cliffingTimePeriod;
    	_releaseTimePeriod = allocationInfo.releaseTimePeriod;
    }

    function _calculateRecurringAmount(uint256 lockType, uint256 releaseTimePeriod, uint256 lockAmount) private view returns(uint256) {
    	uint256 recurringTimePeriod = _getRecurringTimePeriod(lockType);
    	uint256 numberOfRelease = releaseTimePeriod / recurringTimePeriod;
    	uint256 recurringAmount = numberOfRelease > 0 ? lockAmount / numberOfRelease : lockAmount;
    	return recurringAmount;
    }

    function _calculateUnclaimAmount(AllocationInfo memory allocationInfo, ReleaseInfo memory releaseInfo) private view returns(uint256) {
    	uint256 currentTime = block.timestamp;
    	uint256 recurringTimePeriod = _getRecurringTimePeriod(allocationInfo.lockType);
    	uint256 checkPointTime = allocationInfo.startTime + allocationInfo.cliffingTimePeriod;
    	if (checkPointTime > currentTime) {
    		return 0;
    	}
    	uint256 diffTime = currentTime - checkPointTime;

    	uint256 alloAddressCount = _addressMapping[allocationInfo.alloName].length;
    	uint256 numberOfUnclaimTerms = diffTime / recurringTimePeriod;
    	uint256 unclaimAmount = allocationInfo.releaseRecurringAmount.div(alloAddressCount) * numberOfUnclaimTerms - releaseInfo.releasedAmount;
    	uint256 lockAmount = allocationInfo.lockAmount.div(alloAddressCount);
    	uint256 remainLockAmount = lockAmount - releaseInfo.releasedAmount;
    	if (unclaimAmount > remainLockAmount) {
    		unclaimAmount = remainLockAmount;
    	}
    	
    	return unclaimAmount;
    }

    function _getNextReleaseTime(uint256 lockType, uint256 startTime, uint256 cliffingTimePeriod) private view returns(uint256) {
    	uint256 recurringTimePeriod = _getRecurringTimePeriod(lockType);
    	uint256 currentTime = block.timestamp;
    	uint256 checkPointTime = startTime + cliffingTimePeriod;
    	if (currentTime < checkPointTime) {
    		return checkPointTime + recurringTimePeriod;
    	}

    	uint256 diffTime = currentTime - checkPointTime;
    	uint256 nextRecurringTimeCount = (diffTime / recurringTimePeriod) + 1;
    	uint256 nextReleaseTime = checkPointTime + (recurringTimePeriod * nextRecurringTimeCount);
    	return nextReleaseTime;
    }	

    function _getRecurringTimePeriod(uint256 lockType) private view returns(uint256) {
    	uint256 MINUTELY_SECOND = 60;
    	uint256 DAILY_SECOND = 86400;
    	uint256 recurringTimePeriod = 0;
    	if (lockType == LOCKTYPE_MINUTELY) {
    		recurringTimePeriod = MINUTELY_SECOND;
    	}
    	else if (lockType == LOCKTYPE_DAILY) {
    		recurringTimePeriod = DAILY_SECOND;
    	}
    	else if (lockType == LOCKTYPE_WEAKLY) {
    		recurringTimePeriod = DAILY_SECOND * 7;
    	}
    	else if (lockType == LOCKTYPE_MONTHLY) {
    		recurringTimePeriod = DAILY_SECOND * 30;
    	}
    	else if (lockType == LOCKTYPE_YEARLY) {
    		recurringTimePeriod = DAILY_SECOND * 365;
    	}

    	return recurringTimePeriod;
    }
}