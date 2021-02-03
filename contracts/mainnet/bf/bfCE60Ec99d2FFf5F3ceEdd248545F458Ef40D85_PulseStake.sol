/**
 *
 * @title PulseStake, pulse token staking contract
 * @dev Holders of Pulse will have the choice to stake in the contract
 * for 5 different durations.
 *
 * Staking reward will be paid out in Pulse obtained
 * from the global tax on all Pulse transfers. 
 *      
 * Only one staking duration is allowed per user address.
 *
 */

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PulseStake is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct UserStakeBracketInfo {
        uint256 reward;
        uint256 initial;
        uint256 payday;
        uint256 startday;
    }
    
    IERC20 public Pulse;

    uint256 private percentageDivisor; 

    uint256 public totalStaked = 0;
    uint256 public totalRewards = 0;

    mapping (address => mapping(uint256 => UserStakeBracketInfo)) public stakes;
    mapping (uint256 => uint256) public bracketDays;
    mapping (uint256 => uint256) public stakeReward;
    mapping (uint256 => uint256) public totalStakedInBracket;
    mapping (uint256 => uint256) public totalRewardsInBracket;
    mapping (address => bool) public Staked;

    //events
    event userStaked(address User, uint256 Amount, uint256 BracketTierLengthDays);
    event userClaimed(address User, uint256 Amount, uint256 BracketTierLengthDays);
    event stakeRewardUpdated(uint256 stakeBracket, uint256 Percentage);

    constructor(address _pulse) public {
        Pulse = IERC20(_pulse);

        stakeReward[0] = 25;
        stakeReward[1] = 55;
        stakeReward[2] = 190;
        stakeReward[3] = 450;
        stakeReward[4] = 1200;

        bracketDays[0] = 14 days;
        bracketDays[1] = 31 days;
        bracketDays[2] = 90 days;
        bracketDays[3] = 183 days;
        bracketDays[4] = 365 days;

        percentageDivisor = 1000;
    }

    // public entry functions for staking
    function stake14(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 0);
    }
    function stake1mo(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 1);
    }
    function stake3mo(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 2);
    }
    function stake6mo(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 3);
    }
    function stake12mo(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 4);
    }


    function stake(uint256 _amount, uint256 _stakeBracket) internal {
        require(stakes[_msgSender()][_stakeBracket].payday == 0, "PulseStake: User already staked for this bracket!");
        require(_amount >= 1e18, "PulseStake: Minimum of 1 token to stake!");
        require(!Staked[_msgSender()], "PulseStake: User is already stake in a pool!");
        
        // calculate reward
        uint256 _reward = calculateReward(_amount, _stakeBracket);

        // contract must have funds
        require(Pulse.balanceOf(address(this)) > totalOwedValue().add(_reward).add(_amount), "PulseStake: Contract does not have enough tokens, try again soon!");

        // wrapped transfer from revert 
        require(Pulse.transferFrom(_msgSender(), address(this), _amount), "PulseStake: Transfer Failed");

        stakes[_msgSender()][_stakeBracket].payday = block.timestamp.add(bracketDays[_stakeBracket]);
        stakes[_msgSender()][_stakeBracket].reward = _reward;
        stakes[_msgSender()][_stakeBracket].startday = block.timestamp;
        stakes[_msgSender()][_stakeBracket].initial = _amount;

        // update stats on total and on a per bracket basis
        totalStaked = totalStaked.add(_amount);
        totalRewards = totalRewards.add(_reward);
        totalStakedInBracket[_stakeBracket] = totalStakedInBracket[_stakeBracket].add(_amount);
        totalRewardsInBracket[_stakeBracket] = totalRewardsInBracket[_stakeBracket].add(_reward);

        Staked[_msgSender()] = true;
        emit userStaked(_msgSender(), _amount, bracketDays[_stakeBracket].div(1 days));
    }

    // public entry functions for staking
    function claim14() public nonReentrant {
        //
        claim(0);
    }
    function claim1mo() public nonReentrant {
        //
        claim(1);
    }
    function claim3mo() public nonReentrant {
        //
        claim(2);
    }
    function claim6mo() public nonReentrant {
        //
        claim(3);
    }
    function claim12mo() public nonReentrant {
        //
        claim(4);
    }

    function claim(uint256 _stakeBracket) internal {
        require(owedBalance(_msgSender(),_stakeBracket) > 0, "PulseStake: No rewards for this bracket!");
        require(block.timestamp >= stakes[_msgSender()][_stakeBracket].payday, "PulseStake: Too Early to withdraw from this bracket!");

        uint256 owed = (stakes[_msgSender()][_stakeBracket].reward).add(stakes[_msgSender()][_stakeBracket].initial);

        // update total and per bracket stats
        totalStaked = totalStaked.sub(stakes[_msgSender()][_stakeBracket].initial);
        totalRewards = totalRewards.sub(stakes[_msgSender()][_stakeBracket].reward);
        totalStakedInBracket[_stakeBracket] = totalStakedInBracket[_stakeBracket].sub(stakes[_msgSender()][_stakeBracket].initial);
        totalRewardsInBracket[_stakeBracket] = totalRewardsInBracket[_stakeBracket].sub(stakes[_msgSender()][_stakeBracket].reward);

        stakes[_msgSender()][_stakeBracket].initial = 0;
        stakes[_msgSender()][_stakeBracket].reward = 0;
        stakes[_msgSender()][_stakeBracket].payday = 0;
        stakes[_msgSender()][_stakeBracket].startday = 0;

        require(Pulse.transfer(_msgSender(), owed), "PulseStake: Transfer Failed");

        Staked[_msgSender()] = false;

        emit userClaimed(_msgSender(), owed, bracketDays[_stakeBracket].div(1 days));
    }

    function calculateReward(uint256 _amount, uint256 _stakeBracket) public view returns (uint256) {
        require(_amount > 1e18 && _stakeBracket >=0 && _stakeBracket <= 4, "PulseStake: Incorrect parameter entry!");

        // amount required to be 1e18, when percentage divisor < multiplier
        // no error will ocur
        return (_amount.mul(stakeReward[_stakeBracket])).div(percentageDivisor);
    }

    /* ===== Public View Functions ===== */

    function totalOwedValue() public view returns (uint256) {
        return totalStaked.add(totalRewards);
    }


    function owedBalance(address _address, uint256 _stakeBracket) public view returns(uint256) {
        return stakes[_address][_stakeBracket].initial.add(stakes[_address][_stakeBracket].reward);
    }

    /* ===== Owner Functions ===== */

    /* 
    * Allows the owner to withdraw leftover Pulse Tokens
    * NOTE: this will not allow the owner to withdraw reward allocation
    */
    function reclaimPulse(uint256 _amount) public onlyOwner {
        require(_amount <= Pulse.balanceOf(address(this)).sub(totalOwedValue()), "PulseStake: Attempting to withdraw too many tokens!");
        Pulse.transfer(_msgSender(), _amount);
    }


    /* 
    * Allows the owner to change the return rate for a given bracket
    * NOTE: changes to this rate will only affect those that stake AFTER this change.
    * Will not affect the currently staked amounts.
    */
    function changeReturnRateForBracket(uint256 _percentage, uint256 _stakeBracket) public onlyOwner {
        require(_stakeBracket <= 4);
        // TAKE NOTE OF FORMATTING:
        // stakeReward[0] = 25;
        // stakeReward[1] = 55;
        // stakeReward[2] = 190;
        // stakeReward[3] = 450;
        // stakeReward[4] = 1200;

        stakeReward[_stakeBracket] = _percentage;
        emit stakeRewardUpdated(_stakeBracket,_percentage);
    }
}