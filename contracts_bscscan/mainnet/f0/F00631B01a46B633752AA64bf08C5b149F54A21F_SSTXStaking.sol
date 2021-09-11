/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
        );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
            );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount)
    external
    returns (bool);


    function allowance(address owner, address spender)
    external
    view
    returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
        );
}

contract SSTXStaking is Ownable {

    struct Stake {
        uint256 staked;
        uint256 lastWithdrawnTime;
        uint256 cooldown;
        uint256 totalEarned;
    }

    struct MembershipLevel {
        uint256 threshold;
        uint256 APY;
    }

    uint256 constant _divider = 1000;
    uint256 constant _decimals = 7;
    uint256 public rewardPeriod = 60;
    uint256 constant apyBase = 364 days;
    // uint256 public totalTokenLocked;
    uint256 public rewardMembers;

    mapping(address => Stake) public Stakes;
    MembershipLevel[] public MembershipLevels;
    uint256 public levelsCount = 0;

    IERC20 _token;
    address locker;

    event MembershipAdded(uint256 threshold, uint256 apy, uint256 newLevelsCount);
    event MembershipRemoved(uint256 index, uint256 newLevelsCount);
    event Staked(address fromUser, uint256 amount);
    event Claimed(address byUser, uint256 reward);
    event Unstaked(address byUser, uint256 amount);

    constructor(address token) {
        addMembership(750000000  * 10**_decimals, 50);
        addMembership(1500000000 * 10**_decimals, 60);
        addMembership(3000000000 * 10**_decimals, 80);
        addMembership(5000000000 * 10**_decimals, 100);
        addMembership(8500000000 * 10**_decimals, 120);
        setToken(token);
    }
    
    function setLocker(address _locker) external onlyOwner {
        locker = _locker;
    }

    function changeRewardPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Cannot be 0");
        rewardPeriod = newPeriod;
    }

    function changeMembershipAPY(uint256 index, uint256 newAPY) external onlyOwner {
        require(index <= levelsCount - 1, "Wrong membership id");
        if (index > 0) require(MembershipLevels[index - 1].APY < newAPY, "Cannot be lower than previous lvl");
        if (index < levelsCount - 1) require(MembershipLevels[index + 1].APY > newAPY, "Cannot be higher than next lvl");
        MembershipLevels[index].APY = newAPY;
    }

    function changeMembershipThreshold(uint256 index, uint256 newThreshold) external onlyOwner {
        require(index <= levelsCount - 1, "Wrong membership id");
        if (index > 0) require(MembershipLevels[index - 1].threshold < newThreshold, "Cannot be lower than previous lvl");
        if (index < levelsCount - 1) require(MembershipLevels[index + 1].threshold > newThreshold, "Cannot be higher than next lvl");
        MembershipLevels[index].threshold = newThreshold;
    }

    function addMembership(uint256 threshold, uint256 APY) public onlyOwner {
        require(threshold > 0 && APY > 0, "Threshold and APY should be larger than zero");
        if (levelsCount == 0) {
            MembershipLevels.push(MembershipLevel(threshold, APY));
        } else {
            require(MembershipLevels[levelsCount - 1].threshold < threshold, "New threshold must be larger than the last");
            require(MembershipLevels[levelsCount - 1].APY < APY, "New APY must be larger than the last");
            MembershipLevels.push(MembershipLevel(threshold, APY));
        }
        levelsCount++;
        emit MembershipAdded(threshold, APY, levelsCount);
    }

    function removeMembership(uint256 index) external onlyOwner {
        require(levelsCount > 0, "Nothing to remove");
        require(index <= levelsCount - 1, "Wrong index");

        for (uint256 i = index; i < levelsCount - 1; i++) {
            MembershipLevels[i] = MembershipLevels[i + 1];
        }
        delete MembershipLevels[levelsCount - 1];
        levelsCount--;
        emit MembershipRemoved(index, levelsCount);
    }

    function setToken(address token) public onlyOwner {
        _token = IERC20(token);
    }

    function getStakeInfo(address user)
        external
        view
        returns (
            uint256 staked,
            uint256 apy,
            uint256 lastClaimed,
            uint256 cooldown
        )
    {
        return (Stakes[user].staked, getAPY(Stakes[user].staked), Stakes[user].lastWithdrawnTime, Stakes[user].cooldown);
    }

    function canClaim(address user) public view returns (bool) {
        return (getReward(user) > 0);
    }

    function getAPY(uint256 tokens) public view returns (uint256) {
        require(levelsCount > 0, "No membership levels exist");

        for (uint256 i = levelsCount; i != 0; i--) {
            uint256 currentAPY = MembershipLevels[i - 1].APY;
            uint256 currentThreshold = MembershipLevels[i - 1].threshold;
            if (currentThreshold <= tokens) {
                return currentAPY;
            }
        }
        return 0;
    }

    function calculateReward(
        uint256 APY,
        uint256 cooldown,
        uint256 lastWithdrawn,
        uint256 tokens
    ) public view returns (uint256) {
        if (block.timestamp - cooldown <= lastWithdrawn) return 0;
        return ((block.timestamp - lastWithdrawn) * tokens * APY) / _divider / apyBase;
    }

    function getReward(address user) public view returns (uint256) {
        require(levelsCount > 0, "No membership levels exist");
        if (Stakes[user].staked == 0) return 0;

        uint256 staked = Stakes[user].staked;
        uint256 lastWithdrawn = Stakes[user].lastWithdrawnTime;
        uint256 APY = getAPY(staked);
        uint256 cooldown = Stakes[user].cooldown;

        return calculateReward(APY, cooldown, lastWithdrawn, staked);
    }

    function stake(uint256 tokens) external returns (bool) {
        require(tokens > 0, "Cannot stake 0");
        require(MembershipLevels[0].threshold <= tokens + Stakes[msg.sender].staked, "Insufficient tokens for staking.");
        uint256 currentBalance = _token.balanceOf(locker);
        _token.transferFrom(msg.sender, locker, tokens);
        uint256 tokensReceived = _token.balanceOf(locker) - currentBalance;
        require(tokensReceived > 0, "Cannot stake 0");

        //if it is the first time then just set lastWithdrawnTime to now
        if (Stakes[msg.sender].staked == 0) {
            Stakes[msg.sender].cooldown = rewardPeriod;
            Stakes[msg.sender].lastWithdrawnTime = block.timestamp;
            // Increases number of total active rewardMembers
            rewardMembers++;
        } else {
            //In case a user has unclaimed TokenX, add them to the newly staked amount
            uint256 reward = getReward(msg.sender);
            if (reward > 0) {
                Stakes[msg.sender].staked += reward;
                // totalTokenLocked += reward;
                emit Staked(msg.sender, reward);
            }

            Stakes[msg.sender].lastWithdrawnTime = block.timestamp;
            Stakes[msg.sender].cooldown = rewardPeriod;

        }

        Stakes[msg.sender].staked += tokensReceived;
        // totalTokenLocked += tokensReceived;
        emit Staked(msg.sender, tokensReceived);
        return true;
    }

    function claim() public returns (bool) {
        require(canClaim(msg.sender), "Please wait for some time to Claim");
        uint256 reward = getReward(msg.sender);
        _token.transferFrom(locker, msg.sender, reward);
        Stakes[msg.sender].lastWithdrawnTime = block.timestamp;
        Stakes[msg.sender].cooldown = rewardPeriod;
        Stakes[msg.sender].totalEarned += reward;
        emit Claimed(msg.sender, reward);
        return true;
    }

    function emergency_withdraw() external onlyOwner() returns (bool) {
        require(Stakes[msg.sender].staked > 0, "Nothing to unstake");
        uint256 reward = getReward(msg.sender);
        uint256 unstakeAmount = Stakes[msg.sender].staked;

        _token.transferFrom(locker, msg.sender, reward + unstakeAmount);

        // totalTokenLocked = totalTokenLocked - reward - unstakeAmount;
        delete Stakes[msg.sender];
        // Decreases number of total active rewardMembers
        rewardMembers--;
        emit Claimed(msg.sender, reward);
        emit Unstaked(msg.sender, unstakeAmount);
        return true;
    }

    function unstake(uint256 unstakeAmount) external returns (bool) {

        require(Stakes[msg.sender].staked > 0, "Nothing to unstake");
        require(0 < unstakeAmount  && unstakeAmount <= Stakes[msg.sender].staked, "Unstake amount exceeds total staked amount");
        uint256 reward = getReward(msg.sender);

        if(unstakeAmount == Stakes[msg.sender].staked){
            _token.transferFrom(locker, msg.sender, reward + unstakeAmount);
            // totalTokenLocked = totalTokenLocked - reward - unstakeAmount;
            delete Stakes[msg.sender];
            // Decreases number of total active rewardMembers
            rewardMembers--;
            emit Claimed(msg.sender, reward);
            emit Unstaked(msg.sender, unstakeAmount);
            return true;
        }else{
            require(Stakes[msg.sender].staked - unstakeAmount >= MembershipLevels[0].threshold, "The number of tokens you are trying to unstake exceed the required minimum amount. Unstake all tokens or choose a smaller amount");

            _token.transferFrom(locker, msg.sender, reward + unstakeAmount);

            Stakes[msg.sender].staked -= unstakeAmount;
            Stakes[msg.sender].lastWithdrawnTime = block.timestamp;
            Stakes[msg.sender].cooldown = rewardPeriod;
            Stakes[msg.sender].totalEarned += reward;

            emit Claimed(msg.sender, reward);
            emit Unstaked(msg.sender, unstakeAmount);
            return true;
        }
    }

    function getUserDetails(address userAddress) public view returns(uint256, uint256, uint256){
        Stake storage user = Stakes[userAddress];
        uint256 totalEarned = user.totalEarned;
        uint256 liveEarned = totalEarned+getReward(userAddress);
        uint256 rewardDate = user.lastWithdrawnTime+user.cooldown;
        return (totalEarned, liveEarned, rewardDate);
    }

    function canClaimAfter(address userAddress) external view returns(uint256){
        Stake storage user = Stakes[userAddress];
        uint256 delta = user.lastWithdrawnTime+user.cooldown;
        if(delta<block.timestamp) return 0;
        return delta-block.timestamp;
    }
}