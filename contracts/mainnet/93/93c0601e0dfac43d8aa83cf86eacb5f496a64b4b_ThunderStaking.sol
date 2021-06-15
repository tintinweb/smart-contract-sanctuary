/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: MIT

// /$$$$$$$  /$$$$$$ /$$   /$$  /$$$$$$        /$$$$$$$$  /$$$$$$   /$$$$$$   /$$$$$$  /$$     /$$ /$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$      /$$
//| $$__  $$|_  $$_/| $$  /$$/ /$$__  $$      | $$_____/ /$$__  $$ /$$__  $$ /$$__  $$|  $$   /$$//$$__  $$|__  $$__/| $$_____/| $$$    /$$$
//| $$  \ $$  | $$  | $$ /$$/ | $$  \ $$      | $$      | $$  \__/| $$  \ $$| $$  \__/ \  $$ /$$/| $$  \__/   | $$   | $$      | $$$$  /$$$$
//| $$$$$$$/  | $$  | $$$$$/  | $$$$$$$$      | $$$$$   | $$      | $$  | $$|  $$$$$$   \  $$$$/ |  $$$$$$    | $$   | $$$$$   | $$ $$/$$ $$
//| $$____/   | $$  | $$  $$  | $$__  $$      | $$__/   | $$      | $$  | $$ \____  $$   \  $$/   \____  $$   | $$   | $$__/   | $$  $$$| $$
//| $$        | $$  | $$\  $$ | $$  | $$      | $$      | $$    $$| $$  | $$ /$$  \ $$    | $$    /$$  \ $$   | $$   | $$      | $$\  $ | $$
//| $$       /$$$$$$| $$ \  $$| $$  | $$      | $$$$$$$$|  $$$$$$/|  $$$$$$/|  $$$$$$/    | $$   |  $$$$$$/   | $$   | $$$$$$$$| $$ \/  | $$
//|__/      |______/|__/  \__/|__/  |__/      |________/ \______/  \______/  \______/     |__/    \______/    |__/   |________/|__/     |__/
                                                                                                                                          
// website: https://pikacrypto.com

pragma solidity 0.8.4;

interface IThunder {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 value) external;
}


pragma solidity 0.8.4;

contract Owned {
    address public owner;
    address public proposedOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() virtual {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev propeses a new owner
     * Can only be called by the current owner.
     */
    function proposeOwner(address payable _newOwner) external onlyOwner {
        proposedOwner = _newOwner;
    }

    /**
     * @dev claims ownership of the contract
     * Can only be called by the new proposed owner.
     */
    function claimOwnership() external {
        require(msg.sender == proposedOwner);
        emit OwnershipTransferred(owner, proposedOwner);
        owner = proposedOwner;
    }
}

pragma solidity 0.8.4;



contract ThunderStaking is Owned {
    address public teamWallet;
    uint256 public totalAmountStaked = 0;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public claimPeriods;
    IThunder public thunder;
    uint256 public periodNonce = 0;
    uint256 public periodFinish;
    uint256 public minPeriodDuration = 14 days;
    uint256 public rewardPerToken = 0;
    uint256 public maxInitializationReward;

    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event StakingPeriodStarted(uint256 totalRewardPool, uint256 periodFinish);
    event MinPeriodDurationUpdated(uint256 oldDuration, uint256 newDuration);
    event MaxInitializationRewardUpdated(uint256 oldValue, uint256 newValue);

    constructor(address _token, address _teamWallet) {
        thunder = IThunder(_token);
        teamWallet = _teamWallet;
        maxInitializationReward = 100000 ether;
        periodFinish = block.timestamp + 3 days;
    }

    /**
     * @notice allows a user to stake tokens
     * @dev requires to claim pending rewards before being able to stake more tokens
     * @param _amount of tokens to stake
     */
    function stake(uint256 _amount) public {
        uint256 balance = balances[msg.sender];
        if (balance > 0) {
            require(claimPeriods[msg.sender] == periodNonce, "Claim your reward before staking more tokens");
        }
        thunder.transferFrom(msg.sender, address(this), _amount);
        uint256 burnedAmount = (_amount * 6) / 100;
        thunder.burn(burnedAmount);
        uint256 teamWalletAmount = (_amount * 1) / 100;
        thunder.transfer(teamWallet, teamWalletAmount);
        uint256 userBalance = _amount - burnedAmount - teamWalletAmount;
        balances[msg.sender] += userBalance;
        claimPeriods[msg.sender] = periodNonce;
        totalAmountStaked += userBalance;
        emit Staked(msg.sender, userBalance);
    }

    /**
     * @notice allows a user to withdraw staked tokens
     * @dev unclaimed tokens cannot be claimed after withdrawal
     * @dev unstakes all tokens
     */
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        totalAmountStaked -= balance;
        thunder.transfer(msg.sender, balance);
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice claims a reward for the staked tokens
     * @dev can only claim once per staking period
     */
    function claimReward() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No tokens staked");
        require(claimPeriods[msg.sender] < periodNonce, "Wait for this period to finish before claiming your reward");
        claimPeriods[msg.sender] = periodNonce;
        uint256 reward = (balance * rewardPerToken) / 1 ether;
        thunder.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @notice returns claimable reward for a user
     * @param _user to check
     */
    function claimableReward(address _user) public view returns (uint256) {
        if (claimPeriods[_user] == periodNonce) {
            return 0;
        }
        return (balances[_user] * rewardPerToken) / 1 ether;
    }

    /**
     * @notice initializes new staking claim period
     * @dev requires previous staking period to be over
     * @dev only callable by anyone, msg.sender receives a portion of the staking pool as a reward
     */
    function initNewRewardPeriod() external {
        require(block.timestamp >= periodFinish, "Wait for claim period to finish");
        require(totalAmountStaked > 0, "No tokens staked in contract");
        uint256 rewardPool = thunder.balanceOf(address(this)) - totalAmountStaked;
        uint256 initializationReward = rewardPool / 1000;
        if (initializationReward > maxInitializationReward) {
            initializationReward = maxInitializationReward;
        }
        rewardPool -= initializationReward;
        thunder.transfer(msg.sender, initializationReward);
        rewardPerToken = (rewardPool * 1 ether) / totalAmountStaked;
        periodNonce++;
        periodFinish = block.timestamp + minPeriodDuration;
        emit StakingPeriodStarted(rewardPool, periodFinish);
    }

    /**
     * @notice sets a new minimum duration for each staking claim period
     * @dev only callable by owner
     * @param _days amount of days the new staking claim period should at least last
     */
    function setMinDuration(uint256 _days) external onlyOwner {
        emit MinPeriodDurationUpdated(minPeriodDuration / 1 days, _days);
        minPeriodDuration = _days * 1 days;
    }

    /**
     * @notice sets maximum initialization reward
     * @dev only callable by owner
     * @param _newMaxReward new maximum reward paid out by initNewRewardPeriod function
     */
    function setMaxInitializationReward(uint256 _newMaxReward) external onlyOwner {
        emit MaxInitializationRewardUpdated(maxInitializationReward, _newMaxReward);
        maxInitializationReward = _newMaxReward;
    }
}