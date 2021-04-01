pragma solidity ^0.6.6;

import './Ownable.sol';
import './SafeMath.sol';
import './ACOAssetHelper.sol';
import './IACOToken.sol';


contract ACORewards is Ownable {
    using SafeMath for uint256;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, address indexed aco, uint256 reward);
    event SetLPTokenAllocPoint(uint256 indexed pid, address indexed lpToken, uint256 allocPoint);
	event SetCurrentReward(address indexed aco, uint256 rewardRate);
	event WithdrawStuckToken(address indexed token, address indexed destination, uint256 amount);
	
	struct CurrentRewardData {
		address aco;               // Address of the ACO to be distributed.
		uint256 rewardRate;        // ACOs te be reward per second.
	}
	
	struct PoolInfo {
		address lpToken;           // Address of LP token contract.
		uint256 allocPoint;        // How many allocation points assigned to this LP token.
	}
	
    struct ACORewardData {
		uint256 lastUpdateTime;    // Last timestamp that ACO distribution was updated.
		uint256 accRewardPerShare; // Accumulated ACO per share, times 1e18.
	}
	
	struct UserACORewardData {
		uint256 pendingRewardStored;        // Pending reward stored.
		uint256 accAcoRewardPerShareStored; // Last accumulated ACO per share, times 1e18, since last user interaction with the SC.
	}

	// Total allocation poitns. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint;
	 
	// The current reward data. See CurrentRewardData struct.
	CurrentRewardData public currentReward;
	
	// Info of each pool.
    PoolInfo[] public poolInfo;

    // Array with all ACOs used to reward and that it is still not expired.
	address[] public acos;
	
	// LP token index => ACO => ACO reward data. See ACORewardData struct.
	mapping(uint256 => mapping(address => ACORewardData)) public acosRewardDataPerLP;

	// LP token index => User => How many LP tokens the user has provided.
    mapping(uint256 => mapping(address => uint256)) public balanceOf;
	
	// LP token index => User => ACO => User reward data. See UserACORewardData struct.
    mapping(uint256 => mapping(address => mapping(address => UserACORewardData))) public usersAcoRewardData; 
    
    constructor() public {
        super.init();
    }
    
    ////////////////////// VIEW FUNCTIONS //////////////////////
    
    function poolLength() external view returns(uint256) {
        return poolInfo.length;
    }
    
    function acosLength() external view returns(uint256) {
        return acos.length;
    }
    
    // External function to be used on the front-end to list the pending ACOs rewards for an account and a LP token. 
    function pendingReward(uint256 _pid, address account) external view returns (address[] memory _acos, uint256[] memory _amounts) {
        PoolInfo storage info = poolInfo[_pid];
		uint256 share = balanceOf[_pid][account];
        uint256 totalLPSupply = ACOAssetHelper._getAssetBalanceOf(info.lpToken, address(this));
        
        uint256 qty = 0;
        for (uint256 i = 0; i < acos.length; ++i) {
            uint256 pending = _getPendingReward(
                _pid,
				info.allocPoint, 
	            totalLPSupply,
	            account,
	            share,
	            acos[i]);
                
            if (pending > 0) {
                ++qty;
            }
        }
        
        _acos = new address[](qty);
        _amounts = new uint256[](qty);
        
		if (qty > 0) {
			uint256 index = 0;
			for (uint256 i = 0; i < acos.length; ++i) {
				uint256 pending = _getPendingReward(
					_pid,
					info.allocPoint,
					totalLPSupply,
					account,
					share,
					acos[i]);
					
				if (pending > 0) {
					_acos[index] = acos[i];
					_amounts[index] = pending;
					++index;
				}
			}
		}
    }
    
    ////////////////////// USERS FUNCTIONS //////////////////////

    function deposit(uint256 _pid, uint256 amount) external {
		CurrentRewardData storage _currentReward = currentReward;
		PoolInfo storage info = poolInfo[_pid];
		require(info.allocPoint > 0 && _currentReward.rewardRate > 0, "LP token is forbidden");
        require(amount > 0, "Invalid amount");
		
		_setCurrentAcoRewardAccPerShare(_pid, _currentReward);
		_getUserAcoReward(_pid, true); // Claim available rewards.

		ACOAssetHelper._callTransferFromERC20(info.lpToken, msg.sender, address(this), amount);

        balanceOf[_pid][msg.sender] = amount.add(balanceOf[_pid][msg.sender]);
        
        emit Deposit(msg.sender, _pid, amount);
    }

    function withdraw(uint256 _pid, uint256 amount) external {
		uint256 totalUserBalance = balanceOf[_pid][msg.sender];
        require(amount > 0 && totalUserBalance >= amount, "Invalid amount");

		_setCurrentAcoRewardAccPerShare(_pid, currentReward);
		_getUserAcoReward(_pid, true); // Claim available rewards.
		
        balanceOf[_pid][msg.sender] = totalUserBalance.sub(amount);
        
        ACOAssetHelper._callTransferERC20(poolInfo[_pid].lpToken, msg.sender, amount);
        
		emit Withdraw(msg.sender, _pid, amount);
    }

    function claimReward(uint256 _pid) public {
		PoolInfo storage info = poolInfo[_pid];
        require(info.lpToken != address(0), "Invalid LP token");
		
		_setCurrentAcoRewardAccPerShare(_pid, currentReward);
		_getUserAcoReward(_pid, false);
    }

	function claimRewards(uint256[] calldata _pids) external {
		for (uint256 i = 0; i < _pids.length; ++i) {
			claimReward(_pids[i]);
		}
    }
	
	// Withdraw without caring about rewards. EMERGENCY ONLY!
    function emergencyWithdraw(uint256 _pid) external {
        uint256 totalUserBalance = balanceOf[_pid][msg.sender];
        require(totalUserBalance > 0, "No balance");

		_setCurrentAcoRewardAccPerShare(_pid, currentReward);

		balanceOf[_pid][msg.sender] = 0;
        ACOAssetHelper._callTransferERC20(poolInfo[_pid].lpToken, msg.sender, totalUserBalance);

        emit EmergencyWithdraw(msg.sender, _pid, totalUserBalance);
    }
    
    ////////////////////// INTERNAL FUNCTIONS //////////////////////
	
	/*
	 * Calculate the pending rewards and transfers them to the user.
	 * The math is basically, any point in time, the amount of ACOs entitled to a user but is pending to be distributed is:
     *
     * pending reward = user.share * (aco.accRewardPerShare - user.AccAcoRewardPerShareStored)
     *
     * Whenever a user deposit or withdraws for a LP token or even a reward claim:
     *  1. The current ACOs accRewardPerShare and `lastUpdateTime get updated. `_setCurrentAcoRewardAccPerShare` function.
     *  2. User receives the pending reward sent to his/her address.
     *  3. userAccAcoRewardPerShareStored gets updated with the current ACO accRewardPerShare.
	 */
	function _getUserAcoReward(uint256 _pid, bool ignoreIfNoBalance) internal {
		uint256 share = balanceOf[_pid][msg.sender];
		for (uint256 i = acos.length; i > 0; --i) {
			address aco = acos[i - 1];
			
			if (IACOToken(aco).expiryTime() <= block.timestamp) { // ACO is expired.
				_removeAco(i - 1);
			} else {
				uint256 acoAccRewardPerShare = acosRewardDataPerLP[_pid][aco].accRewardPerShare;
				
				UserACORewardData storage userAcoRewardData = usersAcoRewardData[_pid][msg.sender][aco];
				
				uint256 pending = _earned(share, acoAccRewardPerShare, userAcoRewardData.accAcoRewardPerShareStored);
				pending = pending.add(userAcoRewardData.pendingRewardStored);

				userAcoRewardData.pendingRewardStored = pending;
				userAcoRewardData.accAcoRewardPerShareStored = acoAccRewardPerShare;
				
				if (pending > 0) {
				    // If for some reason the current ACO on the SC has not enough balance, the respective reward could be skipped to be paid later and this way avoids an error. (This is true on withdraw and deposit).
				    if (ignoreIfNoBalance) {
				        uint256 acoBalance = ACOAssetHelper._getAssetBalanceOf(aco, address(this));
				        if (acoBalance < pending) {
				            continue;
				        }
				    }

				    userAcoRewardData.pendingRewardStored = 0; // All ACO reward was paid.
					ACOAssetHelper._callTransferERC20(aco, msg.sender, pending);
					emit RewardPaid(msg.sender, _pid, aco, pending);
				}
			}
		}
	}
	
	// Update the current ACO accRewardPerShare and lastUpdateTime for the active LP token.
	function _setCurrentAcoRewardAccPerShare(uint256 _pid, CurrentRewardData storage _currentReward) internal {
		PoolInfo storage info = poolInfo[_pid];
		if (info.allocPoint > 0) {
			uint256 totalLPSupply = ACOAssetHelper._getAssetBalanceOf(info.lpToken, address(this));
			ACORewardData storage currentAcoData = acosRewardDataPerLP[_pid][_currentReward.aco];
			currentAcoData.accRewardPerShare = _getAccRewardPerAco(totalLPSupply, info.allocPoint, _currentReward.aco, _currentReward.rewardRate, _currentReward.aco, currentAcoData);
			currentAcoData.lastUpdateTime = block.timestamp;
		}
	}
	
	/*
	 * Get the accumulated reward per share for an ACO.
	 * For the current ACO rewarding: 
	 * previous accRewardPerShare + [rewardRate * (now - lastUpdateTime) * lpAllocPoint / totalAllocPoint] * 1e18 / totalSupply
	 * lpAllocPoint / totalAllocPoint is to get the weight for the respective LP token on the ACO reward.
	 * The value is multiplied by 1e18 for no losing precision. Hereafter it will be divided by 1e18.
	 */
	function _getAccRewardPerAco(
		uint256 totalSupply,
		uint256	allocPoint,	
		address currentAco, 
		uint256 currentAcoRewardRate,
		address aco, 
		ACORewardData storage acoRewardData
	) internal view returns (uint256) {
        if (currentAco != aco || totalSupply == 0 || allocPoint == 0 || currentAcoRewardRate == 0) {
            return acoRewardData.accRewardPerShare;
        } else {
			uint256 acoReward = block.timestamp.sub(acoRewardData.lastUpdateTime).mul(currentAcoRewardRate).mul(allocPoint).div(totalAllocPoint);
			return acoReward.mul(1e18).div(totalSupply).add(acoRewardData.accRewardPerShare);
		}
    }
	
	// user.share * (aco.accRewardPerShare - user.accAcoRewardPerShareStored) / 1e18 (the division per 1e18 is because all "per share" data is multiplied by 1e18)
	function _earned(
		uint256 accountShare, 
		uint256 acoAccRewardPerShare,
		uint256 userAccAcoRewardPerShareStored
	) internal pure returns (uint256) {
        return accountShare.mul(acoAccRewardPerShare.sub(userAccAcoRewardPerShareStored)).div(1e18);
    }
	
	/*
	 * To remove an expired ACO that expired condition already was checked.
	 * Useful to save gas on next txs.
	 */
	function _removeAco(uint256 acoIndex) internal {
		uint256 lastIndex = acos.length - 1;
		if (lastIndex != acoIndex) {
			address last = acos[lastIndex];
			acos[acoIndex] = last;
		}
		acos.pop();
	}
	
	// Used only on the pending reward external view function.
	function _getPendingReward(
	    uint256 _pid, 
		uint256 allocPoint,
	    uint256 totalLPSupply,
	    address account,
	    uint256 accountShare,
	    address aco
    ) internal view returns(uint256 pending) {
	    pending = 0;
	    if (IACOToken(aco).expiryTime() > block.timestamp) {
                
    	    uint256 accRewardPerShare = _getAccRewardPerAco(
    	        totalLPSupply, 
    	        allocPoint, 
    	        currentReward.aco, 
    	        currentReward.rewardRate, 
    	        aco, 
    	        acosRewardDataPerLP[_pid][aco]
            );
            
            UserACORewardData storage userAcoRewardData = usersAcoRewardData[_pid][account][aco];
			pending = _earned(accountShare, accRewardPerShare, userAcoRewardData.accAcoRewardPerShareStored);
			pending = pending.add(userAcoRewardData.pendingRewardStored);
        }
	}
	
	////////////////////// PUBLIC FUNCTIONS //////////////////////
	
	
	// Update all accumulated per share value for the current ACO rewarding on all active LP tokens.
	function setAllLPTokensCurrentAcoRewardAccPerShare() internal {
		CurrentRewardData storage _currentReward = currentReward;
		for (uint256 i = 0; i < poolInfo.length; ++i) {
			_setCurrentAcoRewardAccPerShare(i, _currentReward);
		}
	}

    // Remove expired ACOs from the array. To save gas on the next txs.
	function setValidAcos() public {
		for (uint256 i = acos.length; i > 0; --i) {
            address aco = acos[i - 1];
			if (IACOToken(aco).expiryTime() <= block.timestamp) {
				_removeAco(i - 1);
			}
        }
	}
	
	////////////////////// ADMIN FUNCTIONS //////////////////////

    /*
	 * Function to the admin sets new LP tokens or change the allocation points.
	 * When an allocation point is set to zero the respective LP token is inactivated.
	 * If the LP token is inactived there is no reward and the respective deposit is also forbidden.
	 * However, withdrawals and previous rewards claims keep working.
	 */
	function setLPTokens(address[] calldata lpTokens, uint256[] calldata allocPoints) external onlyOwner {
		require(lpTokens.length == allocPoints.length, "Invalid arguments");
		
		setAllLPTokensCurrentAcoRewardAccPerShare();
		setValidAcos();
		
		address _currentAco = currentReward.aco;
		for (uint256 i = 0; i < lpTokens.length; ++i) {
			require(allocPoints[i] <= 1e18, "Invalid alloc point"); // To avoid overflow.

			bool isNew = true;
			uint256 _pid;
			for (uint256 j = 0; j < poolInfo.length; ++j) {

				PoolInfo storage info = poolInfo[j];
				if (info.lpToken == lpTokens[i]) {
					_pid = j;
					totalAllocPoint = totalAllocPoint.sub(info.allocPoint).add(allocPoints[i]);
					info.allocPoint = allocPoints[i];
					isNew = false;
					break;
				}
			}
			if (isNew) { // It is new LP token.
				_pid = poolInfo.length;
				poolInfo.push(PoolInfo(lpTokens[i], allocPoints[i]));
				totalAllocPoint = totalAllocPoint.add(allocPoints[i]);
			}

			// Sets the current ACO timestamp as "now" for the new LP token configuration.
			acosRewardDataPerLP[_pid][_currentAco].lastUpdateTime = block.timestamp;

			emit SetLPTokenAllocPoint(_pid, lpTokens[i], allocPoints[i]);
		}
	}
	
	/*
	 * Function to the admin sets the ACO to the current reward.
	 * The rewardRate is ACO per second.
	 */
	function setCurrentReward(address aco, uint256 rewardRate) external onlyOwner {
		require(rewardRate <= 1e40, "The reward rate is too big"); // To avoid overflow.

		setAllLPTokensCurrentAcoRewardAccPerShare();
		setValidAcos();
		
		bool isNew = true;
		for (uint256 i = 0; i < acos.length; ++i) {
			if (acos[i] == aco) {
				isNew = false;
				break;
			}
		}
		if (isNew) {
			acos.push(aco);
		}
		
		CurrentRewardData storage _currentReward = currentReward;
		_currentReward.aco = aco;
		_currentReward.rewardRate = rewardRate;
		
		/*
		 * Set the lastUpdateTime as now for all active LP tokens.
		 * This timestamp is used to calculate the accumulated per share value.
		 * So new current ACO timestamp is set for all LP tokens as "now".
		 */
		for (uint256 i = 0; i < poolInfo.length; ++i) {
			if (poolInfo[i].allocPoint > 0) {
				acosRewardDataPerLP[i][aco].lastUpdateTime = block.timestamp;
			}
		}
		
		emit SetCurrentReward(aco, rewardRate);
	}
	
	/*
	 * Function to the admin withdraws a stuck token if necessary. 
	 * For example, an ACO rewarded and that is not being used anymore.
	 * Withdraw any LP token is FORBIDDEN.
	 */
    function withdrawStuckToken(address token, uint256 amount, address destination) external onlyOwner {
		// To guarantee the deny for withdrawing a LP token.
		for (uint256 i = 0; i < poolInfo.length; ++i) {
			require(poolInfo[i].lpToken != token, "Forbidden!");
		}
		
		uint256 tokenBalance = ACOAssetHelper._getAssetBalanceOf(token, address(this));
		if (amount > tokenBalance) {
			amount = tokenBalance;
		}
		if (amount > 0) {
		    ACOAssetHelper._callTransferERC20(token, destination, amount);
			emit WithdrawStuckToken(token, destination, amount);
		}
    }
}