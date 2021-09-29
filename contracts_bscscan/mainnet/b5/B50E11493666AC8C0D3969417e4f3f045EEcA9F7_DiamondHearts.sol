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
    uint[] private _affiliateBonuses = [50, 50, 33, 20, 10]; //Reward is divided by this amount, i.e. 1==100%, 10==10%, 100=1%
    uint private _referredBonus = 50;
    uint constant ONE_DAY = 1 days;

    struct Stake {
        StakeType stakeType;
        bool initialStakeWithdrawn;
        uint beginTime;
        uint stakeAmount;
        uint rate;
    }

    mapping(address => Stake[]) private _stakes;
    mapping(address => uint) public affiliateRewards;
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

    function getVotedStatus() public view returns (bool) {
        if (_voters[msg.sender] == _ballotIndex) return true;
        else return false;
    }

    function getRewardsPool() public view returns (uint) {
        return rewardsPool;
    }

    /*
    ===========================================================================================
    PUBLIC FUNCTIONS
    ===========================================================================================
    */

    //Votes for a cause on the ballot, relative to the user's total staked coins.
    function vote(uint causeID) public returns (bool) {
        require(_voters[msg.sender] < _ballotIndex, "You have already voted. Please wait for next voting ballot.");
        require(_causes.length > causeID, "Invalid causeID.");
        _voters[msg.sender] = _ballotIndex;
        uint votingPower;
        Stake[] memory stakes = _stakes[msg.sender];
        for (uint i = 0; i < stakes.length; i++) {
            //Stakes that have had their principal withdrawn are not counted.
            if (stakes[i].initialStakeWithdrawn) continue;
            votingPower += stakes[i].stakeAmount;
        }

        //Each 1000 coins = 1 voting power.
        votingPower /= 1000;
        require(votingPower > 0, "You have no coins staked.");

        //Increment the causes total votes.
        _causes[causeID] += votingPower;

        //Reward the voter, if enough is in the rewards pool.
        uint votingReward = votingPower * _votingRewardMultiplier;
        if (rewardsPool >= votingReward) {
            _tokenContract.transfer(msg.sender, votingReward);
        }

        emit Voted(msg.sender, causeID, votingPower);
        return true;
    }

    //Creates a new time-locked stake, with an optional affiliate address.
    function createStake(
        StakeType stakeType,
        uint amount,
        address affiliate
    ) public returns (bool) {
        require(amount >= 1000 * 10**8, "Minimum stake of 1000 Lovecoin.");

        //Send the staked tokens to this contract.
        _tokenContract.transferFrom(msg.sender, address(this), amount);

        //The user gets a bonus to their original stake for using an affiliate link.
        uint referredBonus = (amount / _referredBonus);
        if (affiliate != address(0)) {
            //Used an affiliate link. Increase the principal stake, and award the affiliate their bonus.
            amount += referredBonus;
            affiliateRewards[affiliate] += (amount / _affiliateBonuses[uint(stakeType)]);
        } else referredBonus = 0;

        //The contract needs to be certain it can cover the principal stake when it is withdrawn.
        //Thus, we must decrease the rewards pool here (without actually transferring tokens away from this contract.)
        require(rewardsPool >= referredBonus, "Empty rewards pool. Please remove affiliate.");
        if (referredBonus > 0) rewardsPool -= referredBonus;

        //Create the stake and push it to the user's list of all their stakes.
        Stake memory stake = Stake(stakeType, false, block.timestamp, amount, _interestRates[uint(stakeType)]);
        _stakes[msg.sender].push(stake);
        emit Staked(msg.sender, stakeType, amount, affiliate);
        return true;
    }

    //Gift your stake to another address.
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
        emit StakeTransfered(msg.sender, recipient, stake.stakeType, stake.stakeAmount);
        return true;
    }

    //Typically called by admin, but anyone can donate to the rewards pool.
    function addToRewardsPool(uint amount) public returns (bool) {
        _tokenContract.transferFrom(msg.sender, address(this), amount);
        rewardsPool += amount;
        return true;
    }

    //Returns the amount claimed.
    function claimStake(uint stakeID) public returns (uint) {
        require(_stakes[msg.sender].length > stakeID, "Stake ID does not exist.");
        Stake storage stake = _stakes[msg.sender][stakeID];

        //The total number of days this stake lasts.
        uint numOfStakeDays = _timeSpans[uint8(stake.stakeType)];

        //The time when this stake will be ready to claim.
        uint endTime = stake.beginTime + numOfStakeDays * ONE_DAY;
        require(block.timestamp >= endTime, "Stake not yet ready to claim.");

        uint interestRate = stake.rate;

        //Reward calculation.
        uint reward = stake.stakeAmount * interestRate * numOfStakeDays / (10**8);

        //This flag is flipped to true if the reward is withdraw (the reward will not be withdrawn if the rewards pool is empty, but the user
        //will still get back their original stake.)
        bool rewardsWithdrawn = false;

        if (reward <= rewardsPool) {
            rewardsPool -= reward;
            rewardsWithdrawn = true;
        } else {
            //Pool empty. However, don't revert because we may still need to claim the original stake.
            reward = 0;
        }

        if (!stake.initialStakeWithdrawn) {
            //Withdraw initial stake. This is not removed from the rewards pool (because it is not added in the first place, thus
            //this contract will always be able to cover the transfer.)
            stake.initialStakeWithdrawn = true;
            reward += stake.stakeAmount;
        }

        if (rewardsWithdrawn) {
            //Stake fully complete. Remove it.
            emit StakeClaimed(stake.stakeType, stake.stakeAmount, reward);
            _removeStakeFromList(_stakes[msg.sender], stakeID);
        }
        require(
            reward > 0,
            "Nothing to claim. Either your reward has been claimed already today, or the rewards pool is empty."
        );

        //Issue reward.
        _tokenContract.transfer(msg.sender, reward);
        return reward;
    }

    //Withdraw the rewards that accumulate as stakes are created using your affiliate link.
    function withdrawAffiliateRewards() public returns (bool) {
        //Get the reward amount, then clear it.
        uint amt = affiliateRewards[msg.sender];
        affiliateRewards[msg.sender] = 0;
        require(amt > 0, "You have no affiliate rewards to claim.");
        require(rewardsPool >= amt, "No rewards remaining in rewards pool.");
        rewardsPool -= amt;
        _tokenContract.transfer(msg.sender, amt);
        emit AffiliateRewardsClaimed(msg.sender, amt);
        return true;
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

    //Allows the newAdmin address to claim the admin position. Two-step process to prevent mistyping the address.
    function editAdmin(address newAdmin) public {
        require(msg.sender == _admin, "Admin address required.");
        _newAdmin = newAdmin;
    }

    //If the calling address has been designated in the above editAdmin function, it will become the admin.
    //The old admin address will no longer have any admin priveleges.
    function claimAdmin() public {
        require(msg.sender == _newAdmin, "This address does not have the rights to claim the Admin position.");
        _admin = _newAdmin;
    }

    //Starts a new voting ballot, with the desired number of causes.
    function newBallot(uint numOfCauses) public returns (bool) {
        require(msg.sender == _admin, "Admin address required.");
        _ballotIndex++;
        delete _causes;
        for (uint i = 0; i < numOfCauses; i++) {
            _causes.push();
        }
        return true;
    }

    function editInterestRates(uint[] memory rates) public {
        require(msg.sender == _admin, "Admin address required.");
        require(rates.length == 5, "Please pass in an array of 5 values.");
        _interestRates = rates;
    }

    function editAffiliateBonuses(uint[] memory bonuses) public {
        require(msg.sender == _admin, "Admin address required.");
        require(bonuses.length == 5, "Please pass in an array of 5 values.");
        _affiliateBonuses = bonuses;
    }

    function editReferredBonus(uint newBonus) public {
        require(msg.sender == _admin, "Admin address required.");
        _referredBonus = newBonus;
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
    event Staked(address indexed addr, StakeType length, uint amount, address indexed affiliate);
    event StakeClaimed(StakeType length, uint principal, uint reward);
    event StakeTransfered(address indexed oldAddress, address indexed newAddress, StakeType length, uint principal);
    event AffiliateRewardsClaimed(address indexed user, uint amount);
    event Voted(address indexed user, uint causeSelected, uint votingPower);
}