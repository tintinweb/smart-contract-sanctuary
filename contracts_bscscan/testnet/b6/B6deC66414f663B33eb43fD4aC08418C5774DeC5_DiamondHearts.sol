// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LoveCoin.sol";

//  .     '     ,
//     _________
//  _ /_|_____|_\ _
//    '. \   / .'
//      '.\ /.'
//        '.'
contract DiamondHearts {
    LoveCoin _tokenContract;
    address private _admin;
    address private _newAdmin;

    enum StakeType {
        SIX_MONTH,
        ONE_YEAR,
        THREE_YEAR,
        FIVE_YEAR,
        TEN_YEAR
    }

    //            Monthly interest:  1%     2%      3%      4%      5%
    uint[] private _interestRates = [32876, 65753, 98630, 131504, 164384]; //# of 1/8ths of a token earned per day, per full token staked.
    uint[] private _timeSpans = [183, 365, 1095, 1825, 3650]; //In days
    uint constant ONE_DAY = 1 days;

    struct Stake {
        StakeType stakeType;
        bool initialStakeWithdrawn;
        uint beginTime;
        uint stakeAmount;
        uint rate;
    }

    mapping(address => Stake[]) private _stakes;
    uint private rewardsPool;

    mapping(address => uint) private _voters; //Stores the ballot index of the voter's most recent voting activity.
    uint[] private _causes; //Stores the number of votes for each cause.
    uint private _ballotIndex = 1; //Incremented each time a new ballot is started.
    uint private _votingRewardMultiplier = 1;

    constructor(address tokenContract) {
        _tokenContract = LoveCoin(tokenContract);
        _admin = msg.sender;
        _newAdmin = msg.sender;
    }

    /*
    ===========================================================================================
    VIEWS 
    ===========================================================================================
    */

    function getStake(uint stakeID) public view returns (Stake memory) {
        require(_stakes[msg.sender].length > stakeID, "Stake does not exist.");
        return _stakes[msg.sender][stakeID];
    }

    function getStakeCount(address owner) public view returns (uint) {
        return _stakes[owner].length;
    }

    function getVoteCounts() public view returns (uint[] memory) {
        return _causes;
    }

    /*
    ===========================================================================================
    PUBLIC FUNCTIONS
    ===========================================================================================
    */

    function vote(uint causeID) public returns (bool) {
        require(_voters[msg.sender] < _ballotIndex, "You have already voted. Please wait for next voting ballot.");
        require(_causes.length > causeID, "Invalid causeID.");
        _voters[msg.sender] = _ballotIndex;
        uint votingPower;
        Stake[] memory stakes = _stakes[msg.sender];
        for (uint i = 0; i < stakes.length; i++) {
            if (stakes[i].initialStakeWithdrawn) continue;
            votingPower += stakes[i].stakeAmount;
        }
        votingPower /= 1000;
        require(votingPower > 0, "You have no coins staked.");
        _causes[causeID] += votingPower;
        uint votingReward = votingPower * _votingRewardMultiplier;
        if (rewardsPool >= votingReward) {
            _tokenContract.transfer(msg.sender, votingReward);
        }
        return true;
    }

    function newBallot(uint numOfCauses) public returns (bool) {
        require(msg.sender == _admin, "Admin address required.");
        _ballotIndex++;
        delete _causes;
        for (uint i = 0; i < numOfCauses; i++) {
            _causes.push();
        }
        return true;
    }

    function createStake(StakeType stakeType, uint amount) public returns (bool) {
        require(amount >= 1000 * 10**8, "Minimum stake of 1000 Lovecoin.");
        _tokenContract.transferFrom(msg.sender, address(this), amount);
        Stake memory stake = Stake(stakeType, false, block.timestamp, amount, _interestRates[uint(stakeType)]);
        _stakes[msg.sender].push(stake);
        emit Staked(msg.sender, stakeType, amount);
        return true;
    }

    function transferStake(address recipient, uint stakeID) public returns (bool) {
        require(
            _voters[msg.sender] < _ballotIndex,
            "Cannot transfer a stake if you have already voted. Please wait for next voting ballot."
        );
        require(_stakes[msg.sender].length > stakeID, "Stake ID invalid.");
        require(msg.sender != recipient, "Cannot transfer stakes to self.");
        Stake memory stake = _stakes[msg.sender][stakeID];
        require(
            !stake.initialStakeWithdrawn,
            "Cannot transfer a stake if the initial investment has already been withdrawn."
        );
        _removeStakeFromList(_stakes[msg.sender], stakeID);
        _stakes[recipient].push(stake);
        return true;
    }

    function addToRewardsPool(uint amount) public returns (bool) {
        _tokenContract.transferFrom(msg.sender, address(this), amount);
        rewardsPool += amount;
        return true;
    }

    //Returns the amount claimed, including (potentially) the initial stake.
    function claimStake(uint stakeID) public returns (uint) {
        require(_stakes[msg.sender].length > stakeID, "Stake ID does not exist.");
        Stake storage stake = _stakes[msg.sender][stakeID];

        uint numOfStakeDays = _timeSpans[uint8(stake.stakeType)];
        uint endTime = stake.beginTime + numOfStakeDays * ONE_DAY;
        require(block.timestamp >= endTime, "Stake not yet ready to claim.");

        uint interestRate = stake.rate;

        //Reward calculation.
        uint reward = (stake.stakeAmount / (10**8)) * interestRate * numOfStakeDays;
        bool rewardsWithdrawn = false;

        if (reward <= rewardsPool) {
            rewardsPool -= reward;
            rewardsWithdrawn = true;
        } else {
            //Pool empty. However, don't revert because we may still need to claim the original stake.
            reward = 0;
        }

        if (!stake.initialStakeWithdrawn) {
            //Withdraw initial stake. This is not removed from the rewards pool (because it is not added in the first place.)
            stake.initialStakeWithdrawn = true;
            reward += stake.stakeAmount;
        }

        if (rewardsWithdrawn && stake.initialStakeWithdrawn) {
            //Stake fully complete.
            _removeStakeFromList(_stakes[msg.sender], stakeID);
        }
        require(
            reward > 0,
            "Nothing to claim. Either your reward has been claimed already today, or the rewards pool is empty."
        );
        _tokenContract.transfer(msg.sender, reward);
        return reward;
    }

    /*
    ===========================================================================================
    ADMIN FUNCTIONS
    ===========================================================================================
    */

    function editVotingReward(uint newMultiplier) public {
        require(msg.sender == _admin, "Admin address required.");
        _votingRewardMultiplier = newMultiplier;
    }

    function editAdmin(address newAdmin) public {
        require(msg.sender == _admin, "Admin address required.");
        _newAdmin = newAdmin;
    }

    function claimAdmin() public {
        require(msg.sender == _newAdmin, "This address does not have the rights to claim the Admin position.");
        _admin = _newAdmin;
    }

    function setInterestRates(uint[] memory rates) public {
        require(msg.sender == _admin, "Admin address required.");
        require(rates.length == 5, "Please pass in an array of 5 values.");
        _interestRates = rates;
    }

    /*
    ===========================================================================================
    PRIVATE FUNCTIONS
    ===========================================================================================
    */

    function _removeStakeFromList(Stake[] storage stakeList, uint i) internal {
        uint lastIndex = stakeList.length - 1;

        if (i != lastIndex) {
            stakeList[i] = stakeList[lastIndex];
        }

        stakeList.pop();
    }

    /*
    ===========================================================================================
    EVENTS
    ===========================================================================================
    */
    event Staked(address indexed addr, StakeType indexed length, uint amount);
}