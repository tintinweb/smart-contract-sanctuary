/**
 *Submitted for verification at polygonscan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

contract StakingOwnable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract StakedTokenWrapper {
    struct Reward {
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
        uint256 lastUpdateTime;
        uint256 periodFinish;
        uint256 balance;
        uint256 rebase;
    }

    struct UserRewards {
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }

    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    struct Balances {
        uint256 total;
        uint256 unlocked;
        uint256 locked;
        uint256 earned;
    }

    struct RewardData {
        address token;
        uint256 amount;
    }    

    IERC20 public stakedToken;

    address[] public rewardTokens;
    
    uint256 public constant rewardsDuration = 86400 * 7;
    uint256 public constant lockDuration = rewardsDuration * 8;

    uint256 public totalSupply;
    uint256 public lockedSupply;    

    mapping(address => Balances) public balances;
    mapping(address => LockedBalance[]) public userLocks;
    mapping(address => LockedBalance[]) public userEarnings;
    mapping(address => Reward) public rewardData;
    mapping(address => mapping(address => UserRewards)) public userRewards;

    event Staked(address indexed user, uint256 amount, bool lock);
    event Withdrawn(address indexed user, uint256 amount);

    string constant _transferErrorMessage = 'staked token transfer failed';

    function stakeFor(address forWhom, uint256 amount, bool lock) public payable virtual {
        IERC20 st = stakedToken;
        Balances storage bal = balances[forWhom];
        
        require(msg.value == 0, 'non-zero eth');
        require(amount > 0, 'Cannot stake 0');
        require(st.transferFrom(forWhom, address(this), amount), _transferErrorMessage);
        
        if (lock) {
            lockedSupply += amount;
            bal.locked += amount;
            uint256 unlockTime = block.timestamp / rewardsDuration * rewardsDuration + lockDuration;
            uint256 idx = userLocks[forWhom].length;
            if (idx == 0 || userLocks[forWhom][idx-1].unlockTime < unlockTime) {
                userLocks[forWhom].push(LockedBalance({amount: amount, unlockTime: unlockTime}));
            } else {
                userLocks[forWhom][idx-1].amount = userLocks[forWhom][idx-1].amount + amount;
            }
        } else {
            bal.unlocked += amount;
        }
        totalSupply += amount;
        bal.total += amount;
        
        emit Staked(forWhom, amount, lock);
    }

    function withdraw(uint256 amount) public virtual {
        Balances storage bal = balances[msg.sender];
        if (amount <= bal.unlocked) {
            bal.unlocked -= amount;
        } else {
            uint256 remaining = amount - bal.unlocked;
            require(bal.earned >= remaining, "Insufficient unlocked balance");
            bal.unlocked = 0;
            bal.earned -= remaining;
            for (uint i = 0; ; i++) {
                uint256 earnedAmount = userEarnings[msg.sender][i].amount;
                if (earnedAmount == 0) continue;
                if (remaining <= earnedAmount) {
                    userEarnings[msg.sender][i].amount = earnedAmount - remaining;
                    break;
                } else {
                    delete userEarnings[msg.sender][i];
                    remaining -= earnedAmount;
                }
            }
            bal.total -= amount;
            totalSupply = totalSupply - amount;
            stakedToken.transfer(msg.sender, amount);
        }
        emit Withdrawn(msg.sender, amount);
    }

    function earnedBalances(
        address user
    ) view external returns (
        uint256 total,
        LockedBalance[] memory earningsData
    ) {
        LockedBalance[] storage earnings = userEarnings[user];
        uint256 idx;
        for (uint i = 0; i < earnings.length; i++) {
            if (earnings[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    earningsData = new LockedBalance[](earnings.length - i);
                }
                earningsData[idx] = earnings[i];
                idx++;
                total += earnings[i].amount;
            }
        }
        return (total, earningsData);
    }

    // Information on a user's locked balances
    function lockedBalances(
        address user
    ) view external returns (
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    ) {
        LockedBalance[] storage locks = userLocks[user];
        uint256 idx;
        for (uint i = 0; i < locks.length; i++) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }
                lockData[idx] = locks[i];
                idx++;
                locked += locks[i].amount;
            } else {
                unlockable += locks[i].amount;
            }
        }
        return (balances[user].total, unlockable, locked, lockData);
    }

    function withdrawableBalance(
        address user
    ) view public returns (
        uint256 amount
    ) {
        Balances storage bal = balances[user];
        uint256 earned = bal.earned;
        amount = bal.unlocked - earned;
        return amount;
    }
    
    
}

contract ERC20Staking is StakedTokenWrapper, StakingOwnable {
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, address indexed token, uint256 reward);

    constructor(address _stakedToken, uint256 _reward) {
        stakedToken = IERC20(_stakedToken);
        rewardTokens.push(_stakedToken);
        rewardData[_stakedToken].rewardRate = _reward / rewardsDuration;
        rewardData[_stakedToken].lastUpdateTime = block.timestamp;
        rewardData[_stakedToken].periodFinish = block.timestamp + rewardsDuration;

    }

    modifier updateReward(address account) {
        address token = address(stakedToken);
        uint256 balance;
        Reward storage r = rewardData[token];
        uint256 rpt = rewardPerToken(token, lockedSupply);
        r.rewardPerTokenStored = rpt;
        r.lastUpdateTime = lastTimeRewardApplicable(token);
        if (account != address(this)) {
            // Special case, use the locked balances and supply for stakingReward rewards
            userRewards[account][token].rewards = _earned(account, token, balances[account].locked, rpt);
            userRewards[account][token].userRewardPerTokenPaid = rpt;
            balance = balances[account].total;
        }

        uint256 supply = totalSupply;
        uint256 length = rewardTokens.length;
        for (uint i = 1; i < length; i++) {
            token = rewardTokens[i];
            r = rewardData[token];
            rpt = rewardPerToken(token, supply);
            r.rewardPerTokenStored = rpt;
            r.lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(this)) {
                userRewards[account][token].rewards = _earned(account, token, balance, rpt);
                userRewards[account][token].userRewardPerTokenPaid = rpt;
            }
        }
        _;
    }

    function lastTimeRewardApplicable(address _token) public view returns (uint256) {
        uint256 blockTimestamp = block.timestamp;
        uint periodFinish = rewardData[_token].periodFinish;
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }

    function rewardPerToken(address token, uint256 supply) public view returns (uint256) {
        uint256 rewardRate = rewardData[token].rewardRate;
        uint256 rewardPerTokenStored = rewardData[token].rewardPerTokenStored;
        uint256 lastUpdateTime = rewardData[token].lastUpdateTime;
        if (supply == 0) {
            return rewardPerTokenStored;
        }
        unchecked {
            uint256 rewardDuration = lastTimeRewardApplicable(token) - lastUpdateTime;
            return
                uint256(
                    rewardPerTokenStored +
                        (rewardDuration * rewardRate * 1e18) /
                        supply
                );
        }
    }

    function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
        return rewardData[_rewardsToken].rewardRate * rewardsDuration;
    }
    
    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address account) external view returns (RewardData[] memory rewards) {
        rewards = new RewardData[](rewardTokens.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            // If i == 0 this is the stakingReward, distribution is based on locked balances
            uint256 balance = i == 0 ? balances[account].locked : balances[account].total;
            uint256 supply = i == 0 ? lockedSupply : totalSupply;
            rewards[i].token = rewardTokens[i];
            rewards[i].amount = _earned(account, rewards[i].token, balance, rewardPerToken(rewardTokens[i], supply));
        }
        return rewards;
    }

    function _earned(address account, address token, uint256 balance, uint256 currentRewardPerToken) internal view returns (uint256) {
        unchecked {
            return
                uint256(
                    (balance *
                        (currentRewardPerToken -
                            userRewards[account][token].userRewardPerTokenPaid)) /
                        1e18 +
                        userRewards[account][token].rewards
                );
        }
    }
    

    function stake(uint256 amount, bool lock) external payable {
        stakeFor(msg.sender, amount, lock);
    }

    function stakeFor(address forWhom, uint256 amount, bool lock)
        public
        override
        payable
        updateReward(forWhom)
    {
        super.stakeFor(forWhom, amount, lock);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        super.withdraw(amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 length = rewardTokens.length;
        for (uint i; i < length; i++) {
            address token = rewardTokens[i];
            uint256 reward = userRewards[msg.sender][token].rewards;
            if (token != address(stakedToken)) {
                Reward storage r = rewardData[token];
                uint256 periodFinish = r.periodFinish;
                require(periodFinish > 0, "Unknown reward token");
                uint256 balance = r.balance;
                if (periodFinish < block.timestamp + rewardsDuration - 86400) {
                    uint256 rebaseAmount = balance * r.rebase / 1000;
                    if (rebaseAmount > 0) {
                        _rebase(token, rebaseAmount);
                        balance += rebaseAmount;
                    }
                }
                r.balance -= reward;
            }            
            if (reward == 0) continue;
            userRewards[msg.sender][token].rewards = 0;
            IERC20(token).mint(msg.sender, reward);
            emit RewardPaid(msg.sender, token, reward);
        }
    }

    // Withdraw full unlocked balance and optionally claim pending rewards
    function exit(bool claimRewards) external updateReward(msg.sender) {
        
        uint256 amount = withdrawableBalance(msg.sender);
        delete userEarnings[msg.sender];
        Balances storage bal = balances[msg.sender];
        bal.total -= bal.unlocked - bal.earned;
        bal.unlocked = 0;
        bal.earned = 0;

        totalSupply -= amount;
        stakedToken.transfer(msg.sender, amount);
        if (claimRewards) getReward();

        emit Withdrawn(msg.sender, amount);
    }

    // Add a new reward token to be distributed to stakers
    function addReward(address _rewardsToken, uint256 _reward, uint256 _duration, uint256 _rebaseAmount) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime == 0);
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].balance = _reward;
        rewardData[_rewardsToken].rewardRate = _reward / _duration;
        rewardData[_rewardsToken].rebase = _rebaseAmount;
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp + _duration;
    }

    function modifyReward(address _rewardsToken, uint256 _reward, uint256 _duration, uint256 _rebaseAmount) external onlyOwner {
        rewardData[_rewardsToken].balance = _reward;
        rewardData[_rewardsToken].rewardRate = _reward / _duration;
        rewardData[_rewardsToken].rebase = _rebaseAmount;
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp + _duration;        
    }

    // Withdraw all currently locked tokens where the unlock time has passed
    function withdrawExpiredLocks() external updateReward(msg.sender) {
        LockedBalance[] storage locks = userLocks[msg.sender];
        Balances storage bal = balances[msg.sender];
        uint256 amount;
        uint256 length = locks.length;
        if (locks[length-1].unlockTime <= block.timestamp) {
            amount = bal.locked;
            delete userLocks[msg.sender];
        } else {
            for (uint i = 0; i < length; i++) {
                if (locks[i].unlockTime > block.timestamp) break;
                amount += locks[i].amount;
                delete locks[i];
            }
        }
        bal.locked -= amount;
        bal.total -= amount;
        totalSupply -= amount;
        lockedSupply -= amount;
        stakedToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function _rebase(address _rewardsToken, uint256 reward) internal {
        Reward storage r = rewardData[_rewardsToken];
        if (block.timestamp >= r.periodFinish) {
            r.rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = r.periodFinish - block.timestamp;
            uint256 leftover = remaining * r.rewardRate;
            r.rewardRate = (reward + leftover) / rewardsDuration;
        }

        r.lastUpdateTime = block.timestamp;
        r.periodFinish = block.timestamp + rewardsDuration;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakedToken), "Cannot withdraw staking token");
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }


}