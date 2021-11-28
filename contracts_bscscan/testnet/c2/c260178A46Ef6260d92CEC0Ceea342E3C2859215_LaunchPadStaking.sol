/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

contract LaunchPadStaking {
    IERC20Metadata public stakingToken;
    address public admin; 
    uint8 public unstakeLimit;
    uint8 public rewardPercentage;
    uint256 public totalStaked;
    uint8 decimals;
    
    mapping(uint => uint) tierParticipants;

    struct User{
        uint256 tierId;
        uint256 stakeAmount;
        uint256 rewards;
        uint256 intialStakingTime;
        uint256 lastStakedTime;
        uint256 lastRewardTime;
        uint256 unStaKeInitiatedAmount;
        bool isStaker;
        bool isUnStakeInitiated;
        uint256 unstakeInitiatedTime;
    }
    mapping (address => User) Users;

    event Stake(address User,uint amount);
    event Unstake(address User,uint amount);
    event Withdraw(address User,uint amount);
    constructor (IERC20Metadata _stakingToken,uint8 _unstakeLimit,uint8 _rewardPercentage){
        stakingToken = _stakingToken;
        admin = msg.sender;
        unstakeLimit = _unstakeLimit;
        rewardPercentage = _rewardPercentage;
        decimals = stakingToken.decimals();
    }
    
    function getTotalStaked() public view returns(uint256){
        return totalStaked;
    }
    
    function updateTier(uint amount) internal view returns(uint8){
        if(amount>=1000 * 10 ** decimals  && amount < 2500 * 10 ** decimals){
            return 1;
        }
        else if(amount >= 2500 * 10 ** decimals && amount < 5000 * 10 ** decimals){
            return 2;
        }
        else if(amount >= 5000 * 10 ** decimals && amount < 10000* 10 ** decimals){
            return 3;
        }
        else if(amount >= 10000 * 10 ** decimals && amount < 25000 * 10 ** decimals){
            return 4;
        }
        else if(amount >= 25000 * 10 ** decimals && amount < 75000 * 10 ** decimals ){
            return 5;
        }
        else if(amount > 75000 * 10 ** decimals) {
            return 6;
        }
        else{
            return 0;
        }
    }
    
    function _stake(uint256 amount) internal updateReward {
        totalStaked += amount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Stake(msg.sender,amount);
    }

    function unStake(uint256 amount) public updateReward{
    require(!Users[msg.sender].isUnStakeInitiated,"you have already a unstake initiated");
        if(amount == Users[msg.sender].stakeAmount){
            Users[msg.sender].isStaker = false;
            Users[msg.sender].intialStakingTime = 0;
       }
        Users[msg.sender].isUnStakeInitiated = true;
        Users[msg.sender].unStaKeInitiatedAmount = amount;
        totalStaked -=amount;
        Users[msg.sender].stakeAmount -= amount;
        Users[msg.sender].tierId = updateTier(Users[msg.sender].stakeAmount);
        updateParticipants();
        Users[msg.sender].unstakeInitiatedTime = block.timestamp;
        emit Unstake(msg.sender, amount);
    }

    function withdraw() public updateReward{
        require(Users[msg.sender].isUnStakeInitiated,"you should initiate unstake first");
        require(block.timestamp >= Users[msg.sender].unstakeInitiatedTime + unstakeLimit * 86400,"cant withdraw before unstake listed days");
        stakingToken.transfer(msg.sender,Users[msg.sender].unStaKeInitiatedAmount);
        Users[msg.sender].isUnStakeInitiated = false;
        Users[msg.sender].unStaKeInitiatedAmount = 0;
        emit Withdraw(msg.sender, Users[msg.sender].unStaKeInitiatedAmount);
    }

    function updateParticipants() internal {
        uint intialTierId = Users[msg.sender].tierId;
        if(Users[msg.sender].tierId != intialTierId){
           tierParticipants[intialTierId] -= 1;
           tierParticipants[Users[msg.sender].tierId] += 1;
        }
    }

    function emergencyWithdraw() public{
        uint amount = Users[msg.sender].stakeAmount;
        Users[msg.sender].isStaker = false;
        Users[msg.sender].stakeAmount = 0;
        Users[msg.sender].rewards = 0;
        tierParticipants[Users[msg.sender].tierId] -= 1;
        Users[msg.sender].tierId = updateTier(Users[msg.sender].stakeAmount);
        stakingToken.transfer(msg.sender,amount);
    }

    function getStakedAmount(address sender) public view returns(uint){
        return Users[sender].stakeAmount;
    }
    
    function joinStaking(uint256 amount) public{
        require(amount >= 1000 * 10 ** decimals,"Intial value must be greater than 1000");
      //  Users[msg.sender].user = msg.sender;
        Users[msg.sender].isStaker = true;
        Users[msg.sender].stakeAmount += amount;
        Users[msg.sender].intialStakingTime = block.timestamp;
        Users[msg.sender].tierId = updateTier(amount);
        Users[msg.sender].lastStakedTime = block.timestamp;
        tierParticipants[Users[msg.sender].tierId] += 1;
        _stake(amount);
    }
    
    function stake(uint256 amount) public{
        Users[msg.sender].stakeAmount +=amount;
        Users[msg.sender].tierId = updateTier(Users[msg.sender].stakeAmount);
        updateParticipants();
        _stake(amount);
    }
    
    //getRewards
    function getReward() external updateReward returns(uint){
        return Users[msg.sender].rewards;
    }

    function withdrawReward() external updateReward() {
        uint reward = Users[msg.sender].rewards;
        Users[msg.sender].rewards = 0;
        stakingToken.transferFrom(admin,msg.sender, reward);
    }

    function getTotalParticipants() external view returns(uint256){
        uint total;
        for(uint i=1;i<7;i++){
            total += tierParticipants[i];
        }
        return total;
    }
    
    function getParticipantsByTierId(uint tierId) external view returns(uint256){
        return tierParticipants[tierId];
    }

    function isAllocationEligible(uint participationEndTime) public view returns(bool){
        if(Users[msg.sender].intialStakingTime <= participationEndTime){
            return true;
        }
        return false;
    }

    function getTierIdFromUser(address sender) public view returns(uint){
        return Users[sender].tierId;
    }

    function getUser(address sender) public view returns(uint,uint,uint,uint){
        return(Users[sender].stakeAmount,Users[msg.sender].tierId,Users[msg.sender].rewards,Users[msg.sender].intialStakingTime);
    }

    function isStaker(address user) external view returns(bool){
        return Users[user].isStaker;
    }


    modifier updateReward() {
        //uint overall = calculateOverallReward();
        Users[msg.sender].rewards += (Users[msg.sender].stakeAmount*(rewardPercentage)/100)*(block.timestamp-Users[msg.sender].lastStakedTime)/365 days;
        Users[msg.sender].lastStakedTime = block.timestamp;
        _;
    }

}