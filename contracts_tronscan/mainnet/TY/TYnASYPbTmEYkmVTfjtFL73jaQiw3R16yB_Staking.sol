//SourceUnit: Ownable.sol

pragma solidity ^0.5.8;

/**
 * @title Ownable
 * @dev Set & transfer owner
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnershipTransferred(owner, msg.sender);
    }
    
    // modifier to check if caller is owner
    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Transfer Ownership
     * @param _newOwner address of new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

//SourceUnit: Staking.sol

pragma solidity ^0.5.8;

import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title BeatzCoin Staking (BTZC)
 * @author @VibraVid @LapitsTechnologies
 * @dev Implements a Staking contract
 */
contract Staking is Ownable {
    using SafeMath for uint256;
    
    struct StakeHistory {
        uint256 amount; // stake amount (BTZC)
        uint256 apr; // annual percent return
        uint256 stakeTime; // staked at
        uint256 lastDistributionTime; // reward distributed at
    }

    address[] internal stakeholders;
    address[] internal distributors; // allowed distributors
    uint256 internal _totalRewards;
    uint256 apr = 20;
    uint256 internal stage2;
    bool internal allowStaking = false;
    mapping(address => uint256) internal unlocked;
    mapping(address => uint256) internal cooltime;
    mapping(address => StakeHistory[]) stakeHistory;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;

    event  Stake(address indexed account, uint256 value);
    event  Unlock(address indexed account, uint256 value);
    event  Unstake(address indexed account, uint256 value);
    event  Claim(address indexed account, uint256 value);
    event  Distribution(uint256 value);

    trcToken internal tokenID = trcToken(1002413); // TRC10 token ID (which is to be staked/unstaked)
    uint256 internal totalStaked;
    
    /**
     * @dev A method to start staking
     */
    function startStaking() public onlyOwner returns(bool) {
        require(!isStakingAllowed(), "Staking is already on");
        allowStaking = true;
        stage2 = now + 42 days; // stage 2 will start after 6 weeks
        return true;
    }

    /**
     * @dev A method to check if staking is started
     */
    function isStakingAllowed() public view returns(bool) {
        return allowStaking;
    }

    /**
     * @dev A method to pause staking
     */
    function pauseStaking() public onlyOwner returns(bool) {
        require(isStakingAllowed(), "Staking is already paused.");
        allowStaking = false;
        return true;
    }

    /**
     * @dev A method for a stakeholder to create a stake.
     */
    function stake() public payable returns(bool){
        require(isStakingAllowed(), "Staking is not allowed.");
        require(msg.tokenid == tokenID, "Staking of this token is not supported");
        require(msg.tokenvalue>0, "Amount is zero or not provided");
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
        if(!_isStakeholder) addStakeholder(msg.sender);
        if(now > stage2) apr = 12; // check if stage 2 is started
        stakes[msg.sender] = stakes[msg.sender].add(msg.tokenvalue);
        stakeHistory[msg.sender].push(StakeHistory(msg.tokenvalue, apr, now, now));
        totalStaked = totalStaked.add(msg.tokenvalue);
        emit Stake(msg.sender, msg.tokenvalue);
        return true;
    }

    /**
     * @dev A method for a stakeholder to ustake.
     */
    function unlock() public returns(bool){
        require(cooltime[msg.sender]<now, "Please wait until your current unlock period is over.");
        uint256 total = stakeOf(msg.sender);
        require(total>0, "No stakes");
        stakes[msg.sender] = 0;
        removeStakeHistory(msg.sender);
        uint256 cooling = now + 7 days; // 7 days for mainnet
        if(unlocked[msg.sender]>0){
            msg.sender.transferToken(unlocked[msg.sender], tokenID);
            totalStaked = totalStaked.sub(unlocked[msg.sender]);
        }
        unlocked[msg.sender] = total;
        cooltime[msg.sender] = cooling;
        emit Unlock(msg.sender, total);
        return true;
    }
    
    /**
     * @dev method to unstake
     */
    function unstake() public returns(bool) {
        require(cooltime[msg.sender]<now, "Please wait until your current unlock period is over.");
        require(unlocked[msg.sender]>0, "Please unlock your stakes first.");
        msg.sender.transferToken(unlocked[msg.sender], tokenID);
        totalStaked = totalStaked.sub(unlocked[msg.sender]);
        emit Unstake(msg.sender, unlocked[msg.sender]);
        unlocked[msg.sender] = 0;
        cooltime[msg.sender] = 0;
        return true;
    }
    
    /**
     * @dev distribute rewards
     */
    function distributeRewards() public returns(bool) {
        (bool _isDistributor, ) = isDistributor(msg.sender);
        require(_isDistributor,"Sender is not distributor.");
        require(isStakingAllowed(), "Staking was stopped.");
        uint256 totalDistribution = 0;
        for (uint256 s = 0; s < stakeholders.length; s++){
            address _stakeholder = stakeholders[s];
            if(stakeHistory[_stakeholder].length>0){
                uint256 s20 = 0;
                uint256 s12 = 0;
                for(uint256 h = 0; h<stakeHistory[_stakeholder].length; h++){
                    uint256 timeDiff = (now - stakeHistory[_stakeholder][h].lastDistributionTime)/86400;
                    uint256 totalamount = stakeHistory[_stakeholder][h].amount*timeDiff;
                    if(totalamount>0) stakeHistory[_stakeholder][h].lastDistributionTime = now;
                    if(stakeHistory[_stakeholder][h].apr==20) {
                        s20 = s20.add(totalamount);
                    }else{
                        s12 = s12.add(totalamount);
                    }
                }
                uint256 rewards20 = calculateReward(s20, 20);
                uint256 rewards12 = calculateReward(s12, 12);
                uint256 t = rewards20 + rewards12;
                rewards[_stakeholder] = rewards[_stakeholder].add(t);
                 _totalRewards = _totalRewards.add(t);
                 totalDistribution = totalDistribution.add(t);
            }
        }
        emit Distribution(totalDistribution);
        return true;
    }
    
    /** 
     * @dev A simple method that calculates the reward for its arguments
     * @param _stake stake value.
     * @param _apr yearly apr.
     */
    function calculateReward(uint256 _stake, uint256 _apr) internal pure returns(uint256) {
        uint256 dailyReward = 0;
        dailyReward = (_stake.mul(_apr)/100)/365; // daily
        return dailyReward;
    }
    
    /**
     * @dev check unlocked stakes
     */
    function unlockedStakes(address _stakeholder) public view returns(uint256){
        if(cooltime[_stakeholder]>0 && cooltime[_stakeholder]<now) return unlocked[_stakeholder];
        return 0;
    }
    
    /**
     * @dev check under cooling stakes
     */
    function underCoolingStakes(address _stakeholder) public view returns(uint256){
        if(cooltime[_stakeholder]>0 && cooltime[_stakeholder]>now) return unlocked[_stakeholder];
        return 0;
    }
    
    /**
     * @dev cooling timer
     */
    function coolingTimer(address _stakeholder) public view returns(uint256){
        return cooltime[_stakeholder];
    }
    
    /**
     * @dev Check Stake history count
     */
    function checkStakeHistoryCount(address _stakeholder) public view returns(uint256) {
        return stakeHistory[_stakeholder].length;
    }
    
    /**
     * @dev Check Stake history
     */
    function checkStakeHistory(address _stakeholder, uint256 _index) public view returns(uint256, uint256, uint256, uint256) {
        return (stakeHistory[_stakeholder][_index].amount,
        stakeHistory[_stakeholder][_index].apr,
        stakeHistory[_stakeholder][_index].stakeTime,
        stakeHistory[_stakeholder][_index].lastDistributionTime);
    }
    
    /**
     * @dev remove Stake history after unlocking
     */
    function removeStakeHistory(address _stakeholder) internal {
        uint256 size = stakeHistory[_stakeholder].length;
        for (uint256 i = 0; i < size; i++) {
            stakeHistory[_stakeholder].pop();
        }
    }
    
    /**
     * @dev Check stakes for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     */
    function stakeOf(address _stakeholder) public view returns(uint256) {
        return stakes[_stakeholder];
    }
    
    /**
     * @dev total stakes.
     */
    function totalStakes() public view returns(uint256) {
        return totalStaked;
    }

    /**
     * @dev A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     */
    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s++){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @dev A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder) internal {
        require(isStakingAllowed(), "Staking is not allowed.");
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @dev A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }
    
    /**
     * @dev A method to check if an address is a distributor.
     * @param _address The address to verify.
     */
    function isDistributor(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < distributors.length; s++){
            if (_address == distributors[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @dev A method to add a distributor.
     * @param _distributor The distributor to add.
     */
    function addDistributor(address _distributor) public onlyOwner returns(bool) {
        (bool _isDistributor, ) = isDistributor(_distributor);
        if(!_isDistributor) distributors.push(_distributor);
        return true;
    }

    /**
     * @dev A method to remove a distributor.
     * @param _distributor The distributor to remove.
     */
    function removeDistributor(address _distributor) public onlyOwner returns(bool) {
        (bool _isDistributor, uint256 s) = isDistributor(_distributor);
        if(_isDistributor){
            distributors[s] = distributors[distributors.length - 1];
            distributors.pop();
        }
        return true;
    }

    /**
     * @dev A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256) {
        return rewards[_stakeholder];
    }

    /**
     * @dev total rewards so far
     */
    function totalRewards() public view returns(uint256) {
        return _totalRewards;
    }

    /**
     * @dev A method to allow a stakeholder to withdraw his rewards.
     */
    function claimRewards() public returns(bool) {
        require(rewards[msg.sender]>0, "No rewards are available.");
        msg.sender.transferToken(rewards[msg.sender], tokenID);
        emit Claim(msg.sender, rewards[msg.sender]);
        rewards[msg.sender] = 0;
        return true;
    }
    
    /**
     * @dev Function to withdraw BTZC
     * @param _amount of BTZC token to withdraw.
     */
    function withdraw(uint256 _amount) public onlyOwner returns (bool) {
        msg.sender.transferToken(_amount, tokenID);
        return true;
    }
}