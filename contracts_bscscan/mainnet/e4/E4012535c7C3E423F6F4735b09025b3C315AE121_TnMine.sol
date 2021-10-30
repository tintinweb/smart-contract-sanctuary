/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

/**
 *Submitted for verification at arbiscan.io on 2021-09-15
*/

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

    mapping(address => uint256) private _balances;
    IERC20 public stakedToken;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    string constant _transferErrorMessage = "staked token transfer failed";
    
    function stakeFor(address forWhom, uint128 amount) public payable virtual {
        IERC20 st = stakedToken;
        if(st == IERC20(address(0))) { //eth
            unchecked {
                totalSupply += msg.value;
                _balances[forWhom] += msg.value;
            }
        }
        else {
            require(msg.value == 0, "non-zero eth");
            require(amount > 0, "Cannot stake 0");
            require(st.transferFrom(msg.sender, address(this), amount), _transferErrorMessage);
            unchecked { 
                totalSupply += amount;
                _balances[forWhom] += amount;
            }
        }
        emit Staked(forWhom, amount);
    }

    function withdraw(uint128 amount) public virtual {
        require(amount <= _balances[msg.sender], "withdraw: balance is lower");
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

contract TnMine is StakedTokenWrapper, Ownable {
    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint64 public periodFinish;
    uint64 public lastUpdateTime;
    uint128 public rewardPerTokenStored;
    struct UserRewards {
        uint128 userRewardPerTokenPaid;
        uint128 rewards;
    }
    mapping(address => UserRewards) public userRewards;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(IERC20 _rewardToken, IERC20 _stakedToken) {
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
    }

    modifier updateReward(address account) {
        uint128 _rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewardPerTokenStored = _rewardPerTokenStored;
        userRewards[account].rewards = earned(account);
        userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored;
        }
        unchecked {
            uint256 rewardDuration = lastTimeRewardApplicable()-lastUpdateTime;
            return uint128(rewardPerTokenStored + rewardDuration*rewardRate*1e18/totalStakedSupply);
        }
    }

    function earned(address account) public view returns (uint128) {
        unchecked { 
            return uint128(balanceOf(account)*(rewardPerToken()-userRewards[account].userRewardPerTokenPaid)/1e18 + userRewards[account].rewards);
        }
    }

    function stake(uint128 amount) external payable {
        stakeFor(msg.sender, amount);
    }

    function stakeFor(address forWhom, uint128 amount) public payable override updateReward(forWhom) {
        super.stakeFor(forWhom, amount);
    }

    function withdraw(uint128 amount) public override updateReward(msg.sender) {
        super.withdraw(amount);
    }

    function exit() external {
        getReward();
        withdraw(uint128(balanceOf(msg.sender)));
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            userRewards[msg.sender].rewards = 0;
            require(rewardToken.transfer(msg.sender, reward), "reward transfer failed");
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setRewardParams(uint128 reward, uint64 duration) external onlyOwner {
        unchecked {
            require(reward > 0);
            rewardPerTokenStored = rewardPerToken();
            uint64 blockTimestamp = uint64(block.timestamp);
            uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
            if(rewardToken == stakedToken)
                maxRewardSupply -= totalSupply;
            uint256 leftover = 0;
            if (blockTimestamp >= periodFinish) {
                rewardRate = reward/duration;
            } else {
                uint256 remaining = periodFinish-blockTimestamp;
                leftover = remaining*rewardRate;
                rewardRate = (reward+leftover)/duration;
            }
            require(reward+leftover <= maxRewardSupply, "not enough tokens");
            lastUpdateTime = blockTimestamp;
            periodFinish = blockTimestamp+duration;
            emit RewardAdded(reward);
        }
    }

    function withdrawReward() external onlyOwner {
        uint256 rewardSupply = rewardToken.balanceOf(address(this));
        //ensure funds staked by users can't be transferred out
        if(rewardToken == stakedToken)
                rewardSupply -= totalSupply;
        require(rewardToken.transfer(msg.sender, rewardSupply));
        rewardRate = 0;
        periodFinish = uint64(block.timestamp);
    }
}