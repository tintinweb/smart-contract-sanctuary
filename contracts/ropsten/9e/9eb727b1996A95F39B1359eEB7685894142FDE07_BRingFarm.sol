/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity >=0.8.0;


library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
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

abstract contract Pausable is Context {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor () {
        _paused = false;
    }

    
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract BRingFarmAdmin is Ownable, Pausable {
    struct tokenInfo {
        bool isExist;
        uint8 decimal;
        uint256 userMinStake;
        uint256 userMaxStake;
        uint256 totalMaxStake;
        uint256 lockableDays;
    }

    using SafeMath for uint256;
    address[] public tokens;
    mapping (address => address[]) public tokensSequenceList;
    mapping (address => tokenInfo) public tokenDetails;
    mapping (address => mapping (address => uint256)) public tokenDailyDistribution;
    mapping (address => mapping (address => bool)) public tokenBlockedStatus;
    uint256[] public intervalDays = [1, 8, 15, 22, 29];
    uint256 public constant DAYS = 1 days;
    uint256 public constant HOURS = 1 hours;
    uint256 public stakeDuration;
    uint256 public refPercentage;

    event TokenDetails(
        address indexed tokenAddress,
        uint256 userMinStake,
        uint256 userMaxStake,
        uint256 totalMaxStake,
        uint256 updatedTime
    );
    
    event LockableTokenDetails(
        address indexed tokenAddress,
        uint256 lockableDys,
        uint256 updatedTime
    );
    
    event DailyDistributionDetails(
        address indexed stakedTokenAddress,
        address indexed rewardTokenAddress,
        uint256 rewards,
        uint256 time
    );
    
    event SequenceDetails(
        address indexed stakedTokenAddress,
        address []  rewardTokenSequence,
        uint256 time
    );
    
    event StakeDurationDetails(
        uint256 updatedDuration,
        uint256 time
    );
    
    event ReferrerPercentageDetails(
        uint256 updatedRefPercentage,
        uint256 time
    );
    
    event IntervalDaysDetails(
        uint256[] updatedIntervals,
        uint256 time
    );
    
    event BlockedDetails(
        address indexed stakedTokenAddress,
        address indexed rewardTokenAddress,
        bool blockedStatus,
        uint256 time
    );
    
    event WithdrawDetails(
        address indexed tokenAddress,
        uint256 withdrawalAmount,
        uint256 time
    );


    constructor() { 
        stakeDuration = 90 days;
        refPercentage = 5 ether;
    }

    function addToken(
        address tokenAddress,
        uint256 userMinStake,
        uint256 userMaxStake,
        uint256 totalStake,
        uint8 decimal
    ) public onlyOwner returns (bool) {
        if (!(tokenDetails[tokenAddress].isExist))
            tokens.push(tokenAddress);

        tokenDetails[tokenAddress].isExist = true;
        tokenDetails[tokenAddress].decimal = decimal;
        tokenDetails[tokenAddress].userMinStake = userMinStake;
        tokenDetails[tokenAddress].userMaxStake = userMaxStake;
        tokenDetails[tokenAddress].totalMaxStake = totalStake;

        emit TokenDetails(
            tokenAddress,
            userMinStake,
            userMaxStake,
            totalStake,
            block.timestamp
        );
        return true;
    }

    function setDailyDistribution(
        address[] memory stakedToken,
        address[] memory rewardToken,
        uint256[] memory dailyDistribution
    ) public onlyOwner {
        require(
            stakedToken.length == rewardToken.length &&
                rewardToken.length == dailyDistribution.length,
            "Invalid Input"
        );

        for (uint8 i = 0; i < stakedToken.length; i++) {
            require(
                tokenDetails[stakedToken[i]].isExist &&
                    tokenDetails[rewardToken[i]].isExist,
                "Token not exist"
            );
            tokenDailyDistribution[stakedToken[i]][
                rewardToken[i]
            ] = dailyDistribution[i];
            
            emit DailyDistributionDetails(
                stakedToken[i],
                rewardToken[i],
                dailyDistribution[i],
                block.timestamp
            );
        }
    }

    function updateSequence(
        address stakedToken,
        address[] memory rewardTokenSequence
    ) public onlyOwner {
        tokensSequenceList[stakedToken] = new address[](0);
        require(
            tokenDetails[stakedToken].isExist,
            "Staked Token Not Exist"
        );
        for (uint8 i = 0; i < rewardTokenSequence.length; i++) {
            require(
                rewardTokenSequence.length <= tokens.length,
                "Invalid Input"
            );
            require(
                tokenDetails[rewardTokenSequence[i]].isExist,
                "Reward Token Not Exist"
            );
            tokensSequenceList[stakedToken].push(rewardTokenSequence[i]);
        }
        
        emit SequenceDetails(
            stakedToken,
            tokensSequenceList[stakedToken],
            block.timestamp
        );
        
        
    }

    function updateToken(
        address tokenAddress,
        uint256 userMinStake,
        uint256 userMaxStake,
        uint256 totalStake
    ) public onlyOwner {
        require(tokenDetails[tokenAddress].isExist, "Token Not Exist");
        tokenDetails[tokenAddress].userMinStake = userMinStake;
        tokenDetails[tokenAddress].userMaxStake = userMaxStake;
        tokenDetails[tokenAddress].totalMaxStake = totalStake;

        emit TokenDetails(
            tokenAddress,
            userMinStake,
            userMaxStake,
            totalStake,
            block.timestamp
        );
    }

    function lockableToken(
        address tokenAddress,
        uint8 lockableStatus,
        uint256 lockedDays
    ) public onlyOwner {
        require(
            lockableStatus == 1 || lockableStatus == 2 || lockableStatus == 3,
            "Invalid Lockable Status"
        );
        require(tokenDetails[tokenAddress].isExist == true, "Token Not Exist");

        if (lockableStatus == 1) {
            tokenDetails[tokenAddress].lockableDays = block.timestamp.add(
                lockedDays
            );
        } else if (lockableStatus == 2) {
            tokenDetails[tokenAddress].lockableDays = 0;
        }

        emit LockableTokenDetails (
            tokenAddress,
            tokenDetails[tokenAddress].lockableDays,
            block.timestamp
        );
    }

    function updateStakeDuration(uint256 durationTime) public onlyOwner {
        stakeDuration = durationTime;
        
        emit StakeDurationDetails(
            stakeDuration,
            block.timestamp
        );
    }

    function updateRefPercentage(uint256 refPer) public onlyOwner {
        refPercentage = refPer;
        
        emit ReferrerPercentageDetails(
            refPercentage,
            block.timestamp
        );
    }

    function updateIntervalDays(uint256[] memory _interval) public onlyOwner {
        intervalDays = new uint256[](0);

        for (uint8 i = 0; i < _interval.length; i++) {
            uint256 noD = stakeDuration.div(DAYS);
            require(noD > _interval[i], "Invalid Interval Day");
            intervalDays.push(_interval[i]);
        }
        
        emit IntervalDaysDetails(
            intervalDays,
            block.timestamp
        );
        
        
    }

    function changeTokenBlockedStatus(
        address stakedToken,
        address rewardToken,
        bool status
    ) public onlyOwner {
        require(
            tokenDetails[stakedToken].isExist &&
                tokenDetails[rewardToken].isExist,
            "Token not exist"
        );
        tokenBlockedStatus[stakedToken][rewardToken] = status;
        
        
        emit BlockedDetails(
            stakedToken,
            rewardToken,
            tokenBlockedStatus[stakedToken][rewardToken],
            block.timestamp
        );
    }

    function retrieveTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
      require(_amount > 0, "Invalid amount");

      require(
        IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
        "Insufficient Balance"
      );
      require(
        IERC20(_tokenAddress).transfer(owner(), _amount),
        "Transfer failed"
      );
      
      
      emit WithdrawDetails(
        _tokenAddress,
        _amount,
        block.timestamp
      );
    }
    
    function totalTokensCount() external view returns(uint256) {
      return tokens.length;
    }

}

struct User {
  uint256 referralsNumber;
  address[] referrals;
  mapping(address => bool) isReferral;
}

contract BRingFarm is BRingFarmAdmin {
    
    using SafeMath for uint256;

    
    struct stakeInfo {
        address user;
        bool[] isActive;
        address[] referrer;
        address[] tokenAddress;
        uint256[] stakeId;
        uint256[] stakedAmount;
        uint256[] startTime;
    }

    
    mapping(address => stakeInfo) public stakingDetails;
    mapping(address => mapping(address => uint256)) public userTotalStaking;
    mapping(address => uint256) public totalStaking;
    uint256 public poolStartTime;

    mapping(address => User) public users;
    mapping(address => uint256[]) public stakeAmounts;

    
    event Stake(
        address indexed userAddress,
        uint256 stakeId,
        address indexed referrerAddress,
        address indexed tokenAddress,
        uint256 stakedAmount,
        uint256 time
    );
    event Claim(
        address indexed userAddress,
        address indexed stakedTokenAddress,
        address indexed tokenAddress,
        uint256 claimRewards,
        uint256 stakeId,
        uint256 time
    );
    event UnStake(
        address indexed userAddress,
        address indexed unStakedtokenAddress,
        uint256 unStakedAmount,
        uint256 time
    );
    
     event ReferralEarn(
        address indexed userAddress,
        address indexed callerAddress,
        address indexed rewardTokenAddress,	
        uint256 rewardAmount,	
        uint256 time	
    );

    constructor() {
        poolStartTime = block.timestamp;
    }

    
    function stake(
        address referrerAddress,
        address tokenAddress,
        uint256 amount
    ) external whenNotPaused {
        
        require(
            tokenDetails[tokenAddress].isExist,
            "STAKE : Token is not Exist"
        );
        require(
            userTotalStaking[msg.sender][tokenAddress].add(amount) >=
                tokenDetails[tokenAddress].userMinStake,
            "STAKE : Min Amount should be within permit"
        );
        require(
            userTotalStaking[msg.sender][tokenAddress].add(amount) <=
                tokenDetails[tokenAddress].userMaxStake,
            "STAKE : Max Amount should be within permit"
        );
        require(
            totalStaking[tokenAddress].add(amount) <=
                tokenDetails[tokenAddress].totalMaxStake,
            "STAKE : Maxlimit exceeds"
        );

        require(poolStartTime.add(stakeDuration) > block.timestamp, "STAKE: Staking Time Completed");

        address ref = referrerAddress;
        if (ref == msg.sender || !isActiveUser(ref)) {
          ref = address(0x0);
        }

        if (ref != address(0x0) && !users[ref].isReferral[msg.sender]) {
          users[ref].isReferral[msg.sender] = true;
          users[ref].referrals.push(msg.sender);
          users[ref].referralsNumber = users[ref].referralsNumber.add(1);
        }

        
        uint256 stakeId = stakingDetails[msg.sender].stakeId.length;

        stakingDetails[msg.sender].stakeId.push(stakeId);
        stakingDetails[msg.sender].isActive.push(true);
        stakingDetails[msg.sender].user = msg.sender;
        stakingDetails[msg.sender].referrer.push(ref);
        stakingDetails[msg.sender].tokenAddress.push(tokenAddress);
        stakingDetails[msg.sender].startTime.push(block.timestamp);
    
        
        stakingDetails[msg.sender].stakedAmount.push(amount);
        totalStaking[tokenAddress] = totalStaking[tokenAddress].add(
            amount
        );
        userTotalStaking[msg.sender][tokenAddress] = userTotalStaking[
            msg.sender
        ][tokenAddress]
            .add(amount);
        stakeAmounts[msg.sender].push(amount);

        
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount),
                "Transfer Failed");

        
        emit Stake(msg.sender, stakeId, ref, tokenAddress, amount, block.timestamp);
    }

    
    function claimRewards(address userAddress, uint256 stakeId, uint256 stakedAmount, uint256 totalStake) internal {
        
        uint256  interval;
        uint256 endOfProfit; 

        interval = poolStartTime.add(stakeDuration);
        
        
        if (interval > block.timestamp) 
            endOfProfit = block.timestamp;
           
        else 
            endOfProfit = poolStartTime.add(stakeDuration);
        
        interval = endOfProfit.sub(stakingDetails[userAddress].startTime[stakeId]); 
        
        uint256[2] memory stakeData;
        stakeData[0]  = (stakedAmount);
        stakeData[1] = (totalStake);

        
        if (interval >= HOURS) 
            _rewardCalculation(userAddress, stakeId, stakeData, interval);
    }

     function _rewardCalculation(
        address userAddress,
        uint256 stakeId,
        uint256[2] memory stakingData,
        uint256 interval
    ) internal {
        uint256 rewardsEarned;
        uint256 refEarned;
        uint256[2] memory noOfDays;
        
        noOfDays[1] = interval.div(HOURS);
        noOfDays[0] = interval.div(DAYS);

        rewardsEarned = noOfDays[1].mul(
            getDailyReward(
                stakingData[0],
                stakingDetails[userAddress].tokenAddress[stakeId],
                stakingDetails[userAddress].tokenAddress[stakeId],
                stakingData[1]
            )
        );

        
        refEarned = (rewardsEarned.mul(refPercentage)).div(100 ether);
        if (stakingDetails[userAddress].referrer[stakeId] != address(0x0) && refEarned > 0) {
          rewardsEarned = rewardsEarned.sub(refEarned);

          require(
            IERC20(stakingDetails[userAddress].tokenAddress[stakeId]).transfer(
              stakingDetails[userAddress].referrer[stakeId],
              refEarned
            ),
            "Transfer Failed"
          );

          emit ReferralEarn(
            stakingDetails[userAddress].referrer[stakeId],
            msg.sender,	
            stakingDetails[userAddress].tokenAddress[stakeId],
            refEarned,
            block.timestamp
          );
        } else {
          rewardsEarned = rewardsEarned.sub(refEarned.mul(2));
        }

        
        sendToken(
            userAddress,
            stakingDetails[userAddress].tokenAddress[stakeId],
            stakingDetails[userAddress].tokenAddress[stakeId],
            rewardsEarned,
            stakeId
        );

        uint8 i = 1;
        while (i < intervalDays.length) {
            
            if (noOfDays[0] >= intervalDays[i]) {
                uint256 reductionHours = (intervalDays[i].sub(1)).mul(24);
                uint256 balHours = noOfDays[1].sub(reductionHours);
                

                address rewardToken =
                    tokensSequenceList[
                        stakingDetails[userAddress].tokenAddress[stakeId]][i];

                if ( rewardToken != stakingDetails[userAddress].tokenAddress[stakeId] 
                        && tokenBlockedStatus[stakingDetails[userAddress].tokenAddress[stakeId]][rewardToken] ==  false) {
                    rewardsEarned = balHours.mul(
                        getDailyReward(
                            stakingData[0],
                            stakingDetails[userAddress].tokenAddress[stakeId],
                            rewardToken,
                            stakingData[1]
                        )
                    );

                    
                    refEarned = rewardsEarned.mul(refPercentage).div(100 ether);
                    if (stakingDetails[userAddress].referrer[stakeId] != address(0x0)) {
                      rewardsEarned = rewardsEarned.sub(refEarned);

                      require(
                        IERC20(rewardToken).transfer(
                          stakingDetails[userAddress].referrer[stakeId],
                          refEarned
                        ),
                        "Transfer Failed"
                      );

                      emit ReferralEarn(
                        stakingDetails[userAddress].referrer[stakeId],
                        msg.sender,	
                        rewardToken,
                        refEarned,
                        block.timestamp
                      );
                    } else {
                      rewardsEarned = rewardsEarned.sub(refEarned.mul(2));
                    }

                    
                    sendToken(
                      userAddress,
                      stakingDetails[userAddress].tokenAddress[stakeId],
                      rewardToken,
                      rewardsEarned,
                      stakeId
                    );
                }
                i = i + 1;
            } else {
                break;
            }
        }
    }

    
    function getDailyReward(
        uint256 stakedAmount,
        address stakedToken,
        address rewardToken,
        uint256 totalStake
    ) public view returns (uint256 reward) {
        reward = (stakedAmount.mul(tokenDailyDistribution[stakedToken][rewardToken])).div(totalStake);
    }
 
    
    function sendToken(
        address userAddress,
        address stakedToken,
        address tokenAddress,
        uint256 amount,
        uint256 stakeId
    ) internal {
        if (amount == 0) {
          return;
        }

        
        if (tokenAddress != address(0)) {
            require(
                IERC20(tokenAddress).balanceOf(address(this)) >= amount,
                "SEND : Insufficient Balance"
            );
            
            require(IERC20(tokenAddress).transfer(userAddress, amount), 
                    "Transfer failed");

            
            emit Claim(
                userAddress,
                stakedToken,
                tokenAddress,
                amount,
                stakeId,
                block.timestamp
            );
        }
    }

    
    function unstake(address userAddress, uint256 stakeId) external whenNotPaused returns (bool) {
        
        require(msg.sender == userAddress || msg.sender == owner(), "UNSTAKE: Invalid User Entry");
        
        address stakedToken = stakingDetails[userAddress].tokenAddress[stakeId];
        
        
        require(
            tokenDetails[stakedToken].lockableDays <= block.timestamp,
            "UNSTAKE: Token Locked"
        );
            
        
        require(
            stakingDetails[userAddress].stakedAmount[stakeId] > 0 || stakingDetails[userAddress].isActive[stakeId] == true,
            "UNSTAKE : Already Claimed (or) Insufficient Staked"
        );

        
        uint256 stakedAmount = stakingDetails[userAddress].stakedAmount[stakeId];
        uint256 totalStaking1 =  totalStaking[stakedToken];
        totalStaking[stakedToken] = totalStaking[stakedToken].sub(stakedAmount);
        userTotalStaking[userAddress][stakedToken] =  userTotalStaking[userAddress][stakedToken].sub(stakedAmount);
        stakingDetails[userAddress].stakedAmount[stakeId] = 0;        
        stakingDetails[userAddress].isActive[stakeId] = false;

        
        require(
            IERC20(stakingDetails[userAddress].tokenAddress[stakeId]).balanceOf(
                address(this)
            ) >= stakedAmount,
            "UNSTAKE : Insufficient Balance"
        );

        
        IERC20(stakingDetails[userAddress].tokenAddress[stakeId]).transfer(
            userAddress,
            stakedAmount
        );
       
       claimRewards(userAddress, stakeId, stakedAmount, totalStaking1);
        

        
        emit UnStake(
            userAddress,
            stakingDetails[userAddress].tokenAddress[stakeId],
            stakedAmount,
            block.timestamp
        );
        return true;
    }

    
    function viewStakingDetails(address _user)
        public
        view
        returns (
            address[] memory,
            address[] memory,
            bool[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            stakingDetails[_user].referrer,
            stakingDetails[_user].tokenAddress,
            stakingDetails[_user].isActive,
            stakingDetails[_user].stakeId,
            stakingDetails[_user].stakedAmount,
            stakingDetails[_user].startTime
        );
    }

    function getPoolTokens(address _stakedTokenAddress) external view returns (address[] memory) {
      return tokensSequenceList[_stakedTokenAddress];
    }

    function isActiveUser(address _userAddress) public view returns (bool) {
      return stakingDetails[_userAddress].stakeId.length > 0;
    }

    function referrals(address _userAddress) public view returns(address[] memory) {
        return users[_userAddress].referrals;
    }

    function getStakeAmount(address _userAddress, uint256 _stakeId) external view returns (uint256) {
      if (_stakeId >= stakeAmounts[_userAddress].length) {
        return 0;
      }

      return stakeAmounts[_userAddress][_stakeId];
    }

}