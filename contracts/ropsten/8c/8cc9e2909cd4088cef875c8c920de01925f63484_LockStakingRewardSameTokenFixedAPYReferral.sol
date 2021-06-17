/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity =0.8.0;

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

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in construction, 
        // since the code is only stored at the end of the constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

interface ILockStakingRewards {
    function earned(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function stakeFor(uint256 amount, address user) external;
    function getReward() external;
    function withdraw(uint256 nonce) external;
    function withdrawAndGetReward(uint256 nonce) external;
}

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface INimbusReferralProgram {
    function userSponsorByAddress(address user) external view returns (uint);
    function userIdByAddress(address user) external view returns (uint);
    function userSponsorAddressByAddress(address user) external view returns (address);
}

interface INimbusReferralProgramMarketing {
    function updateReferralStakingAmount(address user, address token, uint amount) external;
}

contract LockStakingRewardSameTokenFixedAPYReferral is ILockStakingRewards, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    IERC20 public immutable stakingToken; //read only variable for compatibility with other contracts
    uint256 public rewardRate;
    uint256 public referralRewardRate;
    uint256 public withdrawalCashbackRate;
    uint256 public stakingCashbackRate;

    INimbusReferralProgram public referralProgram;
    INimbusReferralProgramMarketing public referralProgramMarketing;

    uint256 public immutable lockDuration; 
    uint256 public constant rewardDuration = 365 days; 

    mapping(address => uint256) public weightedStakeDate;
    mapping(address => mapping(uint256 => uint256)) public stakeLocks;
    mapping(address => mapping(uint256 => uint256)) public stakeAmounts;
    mapping(address => uint256) public stakeNonces;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event RewardUpdated(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed to, address indexed token, uint amount);
    event WithdrawalCashbackSent(address indexed to, uint withdrawnAmount, uint cashbackAmout);
    event StakingCashbackSent(address indexed to, uint stakedAmount, uint cashbackAmout);

    constructor(
        address _token,
        address _referralProgram,
        address _referralProgramMarketing,
        uint _rewardRate,
        uint _referralRewardRate,
        uint _stakingCashbackRate,
        uint _withdrawalCashbackRate,
        uint _lockDuration
    ) {
        token = IERC20(_token);
        stakingToken = IERC20(_token);
        referralProgram = INimbusReferralProgram(_referralProgram);
        referralProgramMarketing = INimbusReferralProgramMarketing(_referralProgramMarketing);
        rewardRate = _rewardRate;
        referralRewardRate = _referralRewardRate;
        stakingCashbackRate = _stakingCashbackRate;
        withdrawalCashbackRate = _withdrawalCashbackRate;
        lockDuration = _lockDuration;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(amount > 0, "LockStakingRewardSameTokenFixedAPYReferral: Cannot stake 0");
        _totalSupply += amount;
        uint previousAmount = _balances[msg.sender];
        uint newAmount = previousAmount + amount;
        weightedStakeDate[msg.sender] = (weightedStakeDate[msg.sender] * previousAmount / newAmount) + (block.timestamp * amount / newAmount);
        _balances[msg.sender] = newAmount;

        // permit
        IERC20Permit(address(token)).permit(msg.sender, address(this), amount, deadline, v, r, s);
        
        token.safeTransferFrom(msg.sender, address(this), amount);
        _sendStakingCashback(msg.sender, amount);
        uint stakeNonce = stakeNonces[msg.sender]++;
        stakeLocks[msg.sender][stakeNonce] = block.timestamp + lockDuration;
        stakeAmounts[msg.sender][stakeNonce] = amount;
        referralProgramMarketing.updateReferralStakingAmount(msg.sender, address(token), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external override nonReentrant {
        require(amount > 0, "LockStakingRewardSameTokenFixedAPYReferral: Cannot stake 0");
        _totalSupply += amount;
        uint previousAmount = _balances[msg.sender];
        uint newAmount = previousAmount + amount;
        weightedStakeDate[msg.sender] = (weightedStakeDate[msg.sender] * previousAmount / newAmount) + (block.timestamp * amount / newAmount);
        _balances[msg.sender] = newAmount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        _sendStakingCashback(msg.sender, amount);
        uint stakeNonce = stakeNonces[msg.sender]++;
        stakeLocks[msg.sender][stakeNonce] = block.timestamp + lockDuration;
        stakeAmounts[msg.sender][stakeNonce] = amount;
        referralProgramMarketing.updateReferralStakingAmount(msg.sender, address(token), amount);
        emit Staked(msg.sender, amount);
    }

    function stakeFor(uint256 amount, address user) external override nonReentrant {
        require(amount > 0, "LockStakingRewardSameTokenFixedAPYReferral: Cannot stake 0");
        require(user != address(0), "LockStakingRewardSameTokenFixedAPYReferral: Cannot stake for zero address");
        _totalSupply += amount;
        uint previousAmount = _balances[user];
        uint newAmount = previousAmount + amount;
        weightedStakeDate[user] = (weightedStakeDate[user] * previousAmount / newAmount) + (block.timestamp * amount / newAmount);
        _balances[user] = newAmount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        _sendStakingCashback(user, amount);
        uint stakeNonce = stakeNonces[user]++;
        stakeLocks[user][stakeNonce] = block.timestamp + lockDuration;
        stakeAmounts[user][stakeNonce] = amount;
        referralProgramMarketing.updateReferralStakingAmount(user, address(token), amount);
        emit Staked(user, amount);
    }

    function withdrawAndGetReward(uint256 nonce) external override {
        getReward();
        withdraw(nonce);
    }

    function updateRewardAmount(uint256 reward) external onlyOwner {
        rewardRate = reward;
        emit RewardUpdated(reward);
    }

    function rescue(address to, address tokenAddress, uint256 amount) external onlyOwner {
        require(to != address(0), "LockStakingRewardSameTokenFixedAPYReferral: Cannot rescue to the zero address");
        require(amount > 0, "LockStakingRewardSameTokenFixedAPYReferral: Cannot rescue 0");
        require(tokenAddress != address(token), "LockStakingRewardSameTokenFixedAPYReferral: Cannot rescue staking/reward token");

        IERC20(tokenAddress).safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "LockStakingRewardSameTokenFixedAPYReferral: Cannot rescue to the zero address");
        require(amount > 0, "LockStakingRewardSameTokenFixedAPYReferral: Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
    
    function earned(address account) public view override returns (uint256) {
        if(address(referralProgram) == address(0) || referralProgram.userIdByAddress(account) == 0) {
            return (_balances[account] * (block.timestamp - weightedStakeDate[account]) * rewardRate) / (100 * rewardDuration);
        } else {
            return (_balances[account] * (block.timestamp - weightedStakeDate[account]) * referralRewardRate) / (100 * rewardDuration);
        }
    }

    //A user can withdraw its staking tokens even if there is no rewards tokens on the contract account
    function withdraw(uint256 nonce) public override nonReentrant {
        uint amount = stakeAmounts[msg.sender][nonce];
        require(stakeAmounts[msg.sender][nonce] > 0, "LockStakingRewardSameTokenFixedAPYReferral: This stake nonce was withdrawn");
        require(stakeLocks[msg.sender][nonce] < block.timestamp, "LockStakingRewardSameTokenFixedAPYReferral: Locked");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);
        _sendWithdrawalCashback(msg.sender, amount);
        stakeAmounts[msg.sender][nonce] = 0;
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            weightedStakeDate[msg.sender] = block.timestamp;
            token.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
        
    function getUserReferralId(address account) external view returns (uint256) {
        require(address(referralProgram) != address(0), "LockStakingRewardSameTokenFixedAPYReferral: Referral Program was not added.");
        return referralProgram.userIdByAddress(account);
    }

    function updateRewardRate(uint256 _rewardRate) external onlyOwner {
        require(_rewardRate >= 0, "LockStakingRewardSameTokenFixedAPYReferral: Reward rate must be grater than 0");
        rewardRate = _rewardRate;
    }
    
    function updateReferralRewardRate(uint256 _referralRewardRate) external onlyOwner {
        require(_referralRewardRate >= 0, "LockStakingRewardSameTokenFixedAPYReferral: Referral reward rate must be grater than 0");
        referralRewardRate = _referralRewardRate;
    }
    
    function updateStakingCashbackRate(uint256 _stakingCashbackRate) external onlyOwner {
        require(_stakingCashbackRate >= 0, "LockStakingRewardSameTokenFixedAPYReferral: Staking cashback rate must be grater than 0");
        stakingCashbackRate = _stakingCashbackRate;
    }
    
    function updateWithdrawalCashbackRate(uint256 _withdrawalCashbackRate) external onlyOwner {
        require(_withdrawalCashbackRate >= 0, "LockStakingRewardSameTokenFixedAPYReferral: Withdrawal cashback rate must be grater than 0");
        withdrawalCashbackRate = _withdrawalCashbackRate;
    }
    
    function updateReferralProgram(address _referralProgram) external onlyOwner {
        require(_referralProgram != address(0), "LockStakingRewardSameTokenFixedAPYReferral: Referral program address can't be equal to address(0)");
        referralProgram = INimbusReferralProgram(_referralProgram);
    }

    function updateReferralProgramMarketing(address _referralProgramMarketing) external onlyOwner {
        require(_referralProgramMarketing != address(0), "LockStakingRewardFixedAPYReferral: Referral program marketing address can't be equal to address(0)");
        referralProgramMarketing = INimbusReferralProgramMarketing(_referralProgramMarketing);
    }

    function _sendWithdrawalCashback(address account, uint _withdrawalAmount) internal {
        if(address(referralProgram) != address(0) && referralProgram.userIdByAddress(account) != 0) {
            uint256 cashbackAmount = (_withdrawalAmount * withdrawalCashbackRate) / 100;
            token.safeTransfer(account, cashbackAmount);
            emit WithdrawalCashbackSent(account, _withdrawalAmount, cashbackAmount);
        }
    }
    
    function _sendStakingCashback(address account, uint _stakingAmount) internal {
        if(address(referralProgram) != address(0) && referralProgram.userIdByAddress(account) != 0) {
            uint256 cashbackAmount = (_stakingAmount * stakingCashbackRate) / 100;
            token.safeTransfer(account, cashbackAmount);
            emit StakingCashbackSent(account, _stakingAmount, cashbackAmount);
        }
    }
}