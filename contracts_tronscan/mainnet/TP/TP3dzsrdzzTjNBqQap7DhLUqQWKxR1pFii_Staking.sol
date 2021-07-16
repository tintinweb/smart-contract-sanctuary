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

    uint256 internal stage2;
    uint256 public coolingPeriod;
    bool internal allowStaking = false;
    mapping(address => uint256) internal unlocked;
    mapping(address => uint256) internal cooltime;
    mapping(address => uint256) internal stakes20;
    mapping(address => uint256) internal stakes12;
    mapping(address => uint256) internal lastClaimedAt;

    event  Stake(address indexed account, uint256 value);
    event  Unlock(address indexed account, uint256 value);
    event  Unstake(address indexed account, uint256 value);
    event  Claim(address indexed account, uint256 value);

    trcToken internal tokenID = trcToken(1002413); // TRC10 token ID (which is to be staked/unstaked)
    uint256 internal totalStaked;
    
    /**
     * @dev A method to start staking
     */
    function startStaking(uint256 _weeksFor20perApr, uint256 _coolingPeriodInDays) public onlyOwner returns(bool) {
        require(!isStakingAllowed(), "Staking is already on");
        allowStaking = true;
        stage2 = now + _weeksFor20perApr * 7 days;
        coolingPeriod = _coolingPeriodInDays;
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
     * @dev A method to set cooling period
     */
    function setCoolingPeriod(uint256 _coolingPeriod) public onlyOwner returns(bool) {
        coolingPeriod = _coolingPeriod;
        return true;
    }

    /**
     * @dev A method for a stakeholder to create a stake.
     */
    function stake() public payable returns(bool){
        require(isStakingAllowed(), "Staking is not allowed.");
        require(msg.tokenid == tokenID, "Staking of this token is not supported");
        require(msg.tokenvalue>0, "Amount is zero or not provided");
        // process rewards if user stakes again
        if(stakeOf(msg.sender)>0) claimRewards();
        if(now < stage2) stakes20[msg.sender] = stakes20[msg.sender].add(msg.tokenvalue);
        else stakes12[msg.sender] = stakes12[msg.sender].add(msg.tokenvalue);
        lastClaimedAt[msg.sender] = now; // update lastClaimedAt date
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
        // Process rewards if available
        claimRewards();
        stakes20[msg.sender] = 0; stakes12[msg.sender] = 0;
        unstake(); // unstake those which are already unlocked
        unlocked[msg.sender] = total;
        cooltime[msg.sender] = now + coolingPeriod * 1 days;
        emit Unlock(msg.sender, total);
        return true;
    }
    
    /**
     * @dev credit unstakes
     */
    function unstake() public returns(bool) {
        require(cooltime[msg.sender]<now, "Please wait until your current unlock period is over.");
        if(unlocked[msg.sender]>0){
            msg.sender.transferToken(unlocked[msg.sender], tokenID);
            totalStaked = totalStaked.sub(unlocked[msg.sender]);
            emit Unstake(msg.sender, unlocked[msg.sender]);
            unlocked[msg.sender] = 0;
            cooltime[msg.sender] = 0;
            return true;
        }else{
            return false;
        }
    }
    
    /** 
     * @dev To calculate reward for stakeholder.
     * @param _stakeholder address
     */
    function calculateReward(address _stakeholder) internal view returns(uint256) {
        uint256 timeDiff = (now - lastClaimedAt[_stakeholder])/86400;
        uint256 reward20 = (stakes20[_stakeholder]*timeDiff*20)/36500;
        uint256 reward12 = (stakes12[_stakeholder]*timeDiff*12)/36500;
        uint256 estimatedReward = reward20 + reward12;
        return estimatedReward;
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
     * @dev Check stakes for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     */
    function stakeOf(address _stakeholder) public view returns(uint256) {
        return stakes20[_stakeholder] + stakes12[_stakeholder];
    }
    
    /**
     * @dev total stakes.
     */
    function totalStakes() public view returns(uint256) {
        return totalStaked;
    }

    /**
     * @dev A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns(uint256) {
        return calculateReward(_stakeholder);
    }

    /**
     * @dev A method to allow a stakeholder to withdraw his rewards.
     */
    function claimRewards() public returns(bool) {
        uint256 reward = calculateReward(msg.sender);
        if(reward>0){
            msg.sender.transferToken(reward, tokenID);
            emit Claim(msg.sender, reward);
            lastClaimedAt[msg.sender] = now; // update lastClaimedAt date
            return true;
        }else{
            return false;
        }
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