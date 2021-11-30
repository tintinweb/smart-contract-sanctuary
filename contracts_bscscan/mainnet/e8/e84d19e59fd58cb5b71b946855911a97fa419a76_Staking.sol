// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ABDKMathQuad.sol";

    
contract Staking is Ownable{
    using SafeERC20 for IERC20;
    uint8 constant COMISSION_PERCENTAGE = 20;

    modifier contractExpired() {
        uint256 currentDay = getCurrentDay();
        if(_totalStakes == 0) {
            uint256 pausedDays = currentDay - _lastActiveDay;
            _daysInPause += pausedDays == 0 ? 0 : pausedDays - 1;
            _lastActiveDay = currentDay;
        }
        require(currentDay - _daysInPause >= _contractDurationInDays && _totalStakes == 0, "Staking: The staking contract is not yet expired");
        _;
    }

    modifier contractNotExpired() {
        uint256 currentDay = getCurrentDay();
        if(_totalStakes == 0) {
            uint256 pausedDays = currentDay - _lastActiveDay;
            _daysInPause += pausedDays == 0 ? 0 : pausedDays - 1;
            _lastActiveDay = currentDay;
        }
        require(currentDay - _daysInPause < _contractDurationInDays, "Staking: The staking contract has already expired");
        _;
    }

    modifier contractStarted() {
        require(_stakingStarted == true, "Staking: The staking contract has not started yet");
        _;
    }

    modifier contractNotStarted() {
        require(_stakingStarted == false, "Staking: The staking contract has already started");
        _;
    }

    // <================================ CONSTRUCTOR AND INITIALIZER ================================>

    constructor(uint256 supplyPercentage, uint256 durationInDays, address tokenAddress) {
        setToken(tokenAddress);
        setSupplyAndDuration(supplyPercentage, durationInDays);
    }

    function changeSupplyAndDuration(uint256 supplyPercentage, uint256 durationInDays) external onlyOwner contractNotStarted {
        setSupplyAndDuration(supplyPercentage, durationInDays);
    }

    function changeToken(address newTokenAddress) external onlyOwner contractNotStarted{
        setToken(newTokenAddress);
    }

    function initialize(uint256 _initialAmount)
        external
        onlyOwner
        contractNotStarted
    {
        require(_stakingStarted == false, "Staking: The staking contract has been already initialized");
        _stakingStarted = true;
        _startDate = block.timestamp - (block.timestamp % 86400);
        transferTokensToContract(_initialAmount);
    }

    // <================================ END OF CONSTRUCTOR AND INITIALIZER ================================>
    // VARIABLES IN BYTES16 ARE USED FOR PRECISION CALCULATIONS WITH ABDKMATHQUAD LIBRARY

    IERC20 private _token;
    bytes16 private _distributedRewards; // S value in the Article Paper
    bytes16 private _dailyReward; // Amount of tokens that will be distributed among all users in 1 Day 
    bytes16 private _totalRewardsInBytes; // Total rewards with float precision
    uint256 private _initialSupply; // Amount of tokens allocated for Staking contract use
    uint256 private _contractDurationInDays; // Duration of contract in days
    uint256 private _startDate; // Timestamp of the start day of the contract
    uint256 private _totalStakes; // Represents the total amount of staked Tokens. T value in the Article Paper. Find source of the article on top comment
    uint256 private _previousTotalStakes; // Represents the previous state of total amount of staked Tokens 
    uint256 private _lastActiveDay; // Represents the last day of last activity
    uint256 private _stakeHoldersCount; // Total number of stake holders (users)
    uint256 private _daysInPause; // Number of days with no active stakes. If there were no stakes on a specific day, then no reward is distributed and the duration of contract is extended to plus one day
    uint256 private _totalRewards; // The total amount of rewards that have already been distributed
    uint256 private _collectedComission;
    bool private _stakingStarted; // The boolean to check if the staking contract has been initialized and started the work process
    bool private _distributionEnded; // This boolean is used to control the work of distribuiteRewards() function
    mapping(address => mapping(uint256 => bytes16)) private _distributedRewardsSnapshot; // S0 value in the Article Paper
    mapping(address => mapping(uint256 => uint256)) private _stake; // Keeps record of user's made stakings. Note that every new staking is considered as a seperate _stake transaction
    mapping(address => uint256) private _stakesCount; // Total number of accomplished stakes by a specific user
    
    // <================================ EVENTS ================================>
    event StakeCreated(address indexed stakeHolder, uint256 indexed stake);

    event RewardsDistributed(uint256 indexed currentDay);

    event UnStaked(address indexed stakeHolder, uint256 indexed withdrawAmount);

    event StakeHolderAdded(address indexed stakeHolder);

    event StakeHolderRemoved(address indexed stakeHolder);

    event TokensTransferedToStakingBalance(address indexed sender, uint256 indexed amount);

    // <================================ EXTERNAL FUNCTIONS ================================>

    // <<<================================= GETTERS =================================>>>

    function getStartDayOfContract() external view returns(uint256) {
        return _startDate;
    }

    function getDurationOfContract() external view returns(uint256) {
        return _contractDurationInDays;
    }

    function getDaysInPause() external view returns(uint256) {
        return _daysInPause;
    }

    function getInitialSupply() external view returns(uint256) {
        return _initialSupply;
    }

    function getTotalStakes() external view returns(uint256) {
        return _totalStakes;
    }

    function getStakeHoldersCount() external view returns(uint256) {
        return _stakeHoldersCount;
    }


    // <<<================================= END OF GETTERS =================================>>>

    function transferTokensToContract(uint256 amount) public onlyOwner
    {
        _token.safeTransferFrom(_msgSender(), address(this), amount);
        emit TokensTransferedToStakingBalance(_msgSender(), amount);
    }

   function isStakeHolder(address stakeholder) public view returns(bool) {
       if(_stake[stakeholder][0] != 0 && _stakesCount[stakeholder] != 0) {
           return true;
       }
       return false;
   }

   function createStake(uint256 stakeAmount) external contractStarted contractNotExpired returns (bool) {
        address _stakeHolder = _msgSender();
        require(_stakeHolder != address(0), "Staking: No zero address is allowed");
        require(stakeAmount >= toKiloToken(1000), "Staking: Minimal stake value is 1000 CRACE tokens");
        uint256 stakeId = _stakesCount[_stakeHolder];
        _token.safeTransferFrom(_stakeHolder, address(this), stakeAmount);

        if(!isStakeHolder(_stakeHolder))
        { 
            _stakeHoldersCount += 1; 
            emit StakeHolderAdded(_stakeHolder);
        }
        if(!_distributionEnded && getCurrentDay() != _lastActiveDay) {
            _distributeRewards();
        }

        _stake[_stakeHolder][stakeId] = stakeAmount;
        _distributedRewardsSnapshot[_stakeHolder][stakeId] = _distributedRewards;
       
        _totalStakes += stakeAmount;
        _stakesCount[_stakeHolder] += 1;

        if(_previousTotalStakes == 0 || getCurrentDay() == _lastActiveDay) {
            _previousTotalStakes = _totalStakes;
        }

        emit StakeCreated(_stakeHolder, stakeAmount);

        return true;
   }

    function _withdrawComission() external onlyOwner contractStarted returns(bool) {
        address owner = _msgSender();
        uint256 contractBalance = _token.balanceOf(address(this));
        require(contractBalance > 0, "Staking: Nothing to withdraw. Contract's token balance is empty");
        _token.safeTransfer(owner, _collectedComission);

        return true;
    }

    function finalize() external onlyOwner contractStarted contractExpired {
        selfdestruct(payable(_msgSender()));
    }

    function unStake() external contractStarted returns (bool) {
        address _stakeHolder = _msgSender();
        uint256 userStakesCount = _stakesCount[_stakeHolder];
        bytes16 rewardInBytes;
        uint256 reward;
        uint256 withdrawAmount;
        uint256 totalDeposited;
        require(userStakesCount != 0, "Staking: This user must be a stake holder");

        if(!_distributionEnded)
        {
            if(getCurrentDay() != _lastActiveDay) {
                _distributeRewards();
            }
            
            _distributeRewards();
        }

        // Calculation of User reward
        for(uint i = 0; i < userStakesCount; i++) {
            uint256 deposited = _stake[_stakeHolder][i];
            rewardInBytes = ABDKMathQuad.add(rewardInBytes, ABDKMathQuad.mul(ABDKMathQuad.fromUInt(deposited), ABDKMathQuad.sub(_distributedRewards, _distributedRewardsSnapshot[_stakeHolder][i])));
            totalDeposited += deposited;
        }

        reward = ABDKMathQuad.toUInt(rewardInBytes);
        require(reward > 0, "Staking: Address does not have any rewarded tokens in his balance");

        _totalRewardsInBytes = ABDKMathQuad.add(_totalRewardsInBytes, rewardInBytes);
        _totalRewards += reward;
        uint256 addition = ABDKMathQuad.toUInt(_totalRewardsInBytes) - _totalRewards;
        reward += addition;
        _totalRewards += addition;

        _totalStakes -= totalDeposited;
        _previousTotalStakes = _totalStakes;
        
        uint256 comission = (reward * COMISSION_PERCENTAGE) / 100;
        _collectedComission += comission;

        withdrawAmount = (reward + totalDeposited) - comission;
        _token.safeTransfer(_stakeHolder, withdrawAmount);

        removeStakeHolder(_stakeHolder);
        emit UnStaked(_stakeHolder, withdrawAmount);

        return true;
    }

    // <================================ INTERNAL FUNCTIONS ================================>

    function decimals() internal pure returns(uint8) {
        return 18;
    }

    function toKiloToken(uint256 amount) internal pure returns(uint256) {
        return amount * (10 ** decimals());
    }

    function balanceOfContract()
       internal
       view
       returns(uint256)
   {
       return _token.balanceOf(address(this));
   }

    // <================================ PRIVATE FUNCTIONS ================================>

    function removeStakeHolder(address stakeholder) private contractStarted {
       require(stakeholder != address(0), "Staking: No zero address is allowed");
       bool _isStakeHolder = isStakeHolder(stakeholder);
       require(_isStakeHolder == true, "Staking: There is not any stake holder with provided address");

       if(_isStakeHolder) {
           for(uint i = 0; i < _stakesCount[stakeholder]; i++) {
               delete _stake[stakeholder][i];
               delete _distributedRewardsSnapshot[stakeholder][i];
           }
           delete _stakesCount[stakeholder];
           _stakeHoldersCount -= 1;
       }

       emit StakeHolderRemoved(stakeholder);
   }

   function setSupplyAndDuration(uint256 supplyPercentage, uint256 durationInDays) private contractNotStarted {
       require(durationInDays > 0, "Staking: Duration cannot be a zero value");
       require(supplyPercentage > 0, "Staking: Supply percentage cannot be a zero value");
        _contractDurationInDays = durationInDays;
        bytes16 initialSupplyInBytes = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_token.totalSupply() * supplyPercentage), ABDKMathQuad.fromUInt(100));
        _initialSupply = ABDKMathQuad.toUInt(initialSupplyInBytes);
        _dailyReward = ABDKMathQuad.div(initialSupplyInBytes, ABDKMathQuad.fromUInt(_contractDurationInDays));
   }

   function setToken(address newTokenAddress) private contractNotStarted {
        require(
            address(_token) != newTokenAddress,
            "Staking: Cannot change token of same address"
        );
        _token = IERC20(newTokenAddress);
    }

    function getCurrentDay() private view returns (uint256) 
    {
        return (block.timestamp - _startDate) / 86400;    
    }

    function _distributeRewards()
        private
        contractStarted
    {
        uint256 currentDay = getCurrentDay();
        uint256 passedDays;

        if(_lastActiveDay == currentDay || _lastActiveDay == _contractDurationInDays + _daysInPause) return;
        
        if (currentDay - _daysInPause > _contractDurationInDays) {
            _distributionEnded = true;
            passedDays = _contractDurationInDays - _lastActiveDay - _daysInPause;
        } else {
            passedDays = currentDay - _lastActiveDay;
        }

        //MATH BELOW LOOKS LIKE -> _distributedRewards += ((dailyReward * passedDays) / _previousTotalStakes)
        _distributedRewards = ABDKMathQuad.add(_distributedRewards, ABDKMathQuad.div(ABDKMathQuad.mul(_dailyReward, ABDKMathQuad.fromUInt(passedDays)), ABDKMathQuad.fromUInt(_previousTotalStakes)));
        
        _lastActiveDay = currentDay;
        _previousTotalStakes = _totalStakes;

        emit RewardsDistributed(currentDay);
    }
}