/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

//SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.8.7;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakedTokenWrapper {
    uint256 public totalSupply;
    address public feeAddress;
    uint256 public depositFee;
    uint256 public lockingDuration;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public lastDeposits;
    IERC20 public stakedToken;
    
    event Staked(address indexed user, uint256 amount, uint256 depositFee);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    string constant _transferErrorMessage = "staked token transfer failed";
    
    function stakeFor(address forWhom, uint256 amount) public payable virtual {
        IERC20 st = stakedToken;
        if(st == IERC20(address(0))) { //eth
            unchecked {
                uint256 feeAmt = msg.value * depositFee / 10000;
                require(msg.value > feeAmt, "underflow exception");
                uint256 depositedAmt = msg.value - feeAmt;
                totalSupply += depositedAmt;
                _balances[forWhom] += depositedAmt;
                if (feeAmt > 0) {
                    (bool success, ) = feeAddress.call{value: feeAmt}("");
                    require(success, "eth transfer failed");
                }
            }
        }
        else {
            require(msg.value == 0, "non-zero eth");
            require(amount > 0, "Cannot stake 0");
            require(st.transferFrom(msg.sender, address(this), amount), _transferErrorMessage);
            unchecked { 
                uint256 feeAmt = amount * depositFee / 10000;
                require(amount > feeAmt, "underflow exception");
                uint256 depositedAmt = amount - feeAmt;
                totalSupply += depositedAmt;
                _balances[forWhom] += depositedAmt;
                if (feeAmt > 0) {
                    st.transfer(feeAddress, feeAmt);
                }
            }
        }
        if (lastDeposits[forWhom] == 0) {
            lastDeposits[forWhom] = block.timestamp;
        }
        emit Staked(forWhom, amount, depositFee);
    }

    function withdraw(uint256 amount) public virtual {
        require(amount <= _balances[msg.sender], "withdraw: balance is lower");
        require(block.timestamp > (lastDeposits[msg.sender] + lockingDuration), "withdraw: unavailable until locking endtime");
        unchecked {
            _balances[msg.sender] -= amount;
            totalSupply = totalSupply-amount;
        }
        IERC20 st = stakedToken;
        if(st == IERC20(address(0))) { //eth
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "eth transfer failure");
        }
        else {
            require(stakedToken.transfer(msg.sender, amount), _transferErrorMessage);
        }
        emit Withdrawn(msg.sender, amount);
    }
}

contract MultifeeDistribution is StakedTokenWrapper, Ownable {
    address[] public rewardTokens;

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    struct UserRewards {
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    // user -> rewardToken -> UserRewards
    mapping(address => mapping(address => UserRewards)) public userRewards;
    // rewardToken -> Rewards
    mapping(address => Reward) public rewardData;

    event RewardAdded(uint256 reward, address token, uint256 duration);
    event RewardPaid(address indexed user, address token, uint256 reward);
    event UpdateLockingDuration(uint256 oldLockingDuration, uint256 newLockingDuration);

    constructor(IERC20 _stakedToken, address _feeAddress, uint256 _depositFee) {
        stakedToken = _stakedToken;
        feeAddress = _feeAddress;
        depositFee = _depositFee;
    }

    modifier updateReward(address account) {
        for (uint i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            uint256 _rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            rewardData[token].rewardPerTokenStored = _rewardPerTokenStored;
            userRewards[account][token].rewards = earned(account, token);
            userRewards[account][token].userRewardPerTokenPaid = _rewardPerTokenStored;
        }
        _;
    }

    function addReward(address rewardToken) external onlyOwner {
        require(rewardData[rewardToken].lastUpdateTime == 0, "Already added");
        rewardTokens.push(rewardToken);
        rewardData[rewardToken].lastUpdateTime = block.timestamp;
        rewardData[rewardToken].periodFinish = block.timestamp;
    }

    function lastTimeRewardApplicable(address rewardToken) public view returns (uint256) {
        uint256 periodFinish = rewardData[rewardToken].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken(address rewardToken) public view returns (uint256) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardData[rewardToken].rewardPerTokenStored;
        }
        unchecked {
            uint256 rewardDuration = lastTimeRewardApplicable(rewardToken)- rewardData[rewardToken].lastUpdateTime;
            return rewardData[rewardToken].rewardPerTokenStored + rewardDuration*rewardData[rewardToken].rewardRate*1e18/totalStakedSupply;
        }
    }

    function earned(address account, address rewardToken) public view returns (uint256) {
        unchecked { 
            return balanceOf(account)*(rewardPerToken(rewardToken)-userRewards[account][rewardToken].userRewardPerTokenPaid)/1e18 + userRewards[account][rewardToken].rewards;
        }
    }

    function claimableRewards(address account) external view returns (EarnedData[] memory earnings) {
        earnings = new EarnedData[](rewardTokens.length);
        for (uint i = 0; i < earnings.length; i++) {
            earnings[i].token = rewardTokens[i];
            earnings[i].amount = earned(account, rewardTokens[i]);
        }

        return earnings;
    }

    function stake(uint256 amount) external payable {
        stakeFor(msg.sender, amount);
    }

    function stakeFor(address forWhom, uint256 amount) public payable override updateReward(forWhom) {
        super.stakeFor(forWhom, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        super.withdraw(amount);
    }

    function exit() external {
        for (uint i = 0; i < rewardTokens.length; i++) {
            getReward(rewardTokens[i]);
        }
        withdraw(uint256(balanceOf(msg.sender)));
    }

    function getReward(address rewardToken) public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender, rewardToken);
        if (reward > 0) {
            userRewards[msg.sender][rewardToken].rewards = 0;
            require(IERC20(rewardToken).transfer(msg.sender, reward), "reward transfer failed");
            emit RewardPaid(msg.sender, rewardToken, reward);
        }
    }

    function getRewards() public {
        for (uint i = 0; i < rewardTokens.length; i++) {
            getReward(rewardTokens[i]);
        }
    }

    function setRewardParams(uint256 reward, address rewardToken, uint256 duration) external onlyOwner {
        unchecked {
            require(reward > 0);
            rewardData[rewardToken].rewardPerTokenStored = rewardPerToken(rewardToken);
            uint256 maxRewardSupply = IERC20(rewardToken).balanceOf(address(this));
            if(rewardToken == address(stakedToken))
                maxRewardSupply -= totalSupply;
            uint256 leftover = 0;
            if (block.timestamp >= rewardData[rewardToken].periodFinish) {
                rewardData[rewardToken].rewardRate = reward/duration;
            } else {
                uint256 remaining = rewardData[rewardToken].periodFinish-block.timestamp;
                leftover = remaining*rewardData[rewardToken].rewardRate;
                rewardData[rewardToken].rewardRate = (reward+leftover)/duration;
            } 
            require(reward+leftover <= maxRewardSupply, "not enough tokens");
            rewardData[rewardToken].lastUpdateTime = block.timestamp;
            rewardData[rewardToken].periodFinish = block.timestamp+duration;
            emit RewardAdded(reward, rewardToken, duration);
        }
    }

    function setLockingDuration(uint256 timestamp) external onlyOwner {
        emit UpdateLockingDuration(lockingDuration, timestamp);
        lockingDuration = timestamp;
    }

    function withdrawReward(address rewardToken) external onlyOwner {
        uint256 rewardSupply = IERC20(rewardToken).balanceOf(address(this));
        //ensure funds staked by users can't be transferred out
        if(rewardToken == address(stakedToken))
                rewardSupply -= totalSupply;
        require(IERC20(rewardToken).transfer(msg.sender, rewardSupply));
        rewardData[rewardToken].rewardRate = 0;
        rewardData[rewardToken].periodFinish = block.timestamp;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function setFeePercent(uint256 _depositFee) external onlyOwner {
        require(_depositFee <= 5000, "deposit fee must be smaller than 50%");
        depositFee = _depositFee;
    }
}