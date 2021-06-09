/**
 *Submitted for verification at Etherscan.io on 2021-06-09
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

interface INimbusRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
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

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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

contract LockStakingRewardMinAmountFixedAPY is ILockStakingRewards, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardsToken;
    IERC20 public immutable stakingToken;
    uint256 public rewardRate; 
    uint256 public immutable lockDuration; 
    uint256 public constant rewardDuration = 365 days; 
    
    INimbusRouter public swapRouter;
    address public swapToken;                       
    uint public swapTokenAmountThresholdForStaking;

    mapping(address => uint256) public weightedStakeDate;
    mapping(address => mapping(uint256 => uint256)) public stakeLocks;
    mapping(address => mapping(uint256 => uint256)) public stakeAmounts;
    mapping(address => mapping(uint256 => uint256)) public stakeAmountsRewardEquivalent;
    mapping(address => uint256) public stakeNonces;

    uint256 private _totalSupply;
    uint256 private _totalSupplyRewardEquivalent;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesRewardEquivalent;

    event RewardUpdated(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Rescue(address to, uint amount);
    event RescueToken(address to, address token, uint amount);

    constructor(
        address _rewardsToken,
        address _stakingToken,
        uint _rewardRate,
        uint _lockDuration,
        address _swapRouter,
        address _swapToken,
        uint _swapTokenAmount
    ) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
        lockDuration = _lockDuration;
        swapRouter = INimbusRouter(_swapRouter);
        swapToken = _swapToken;
        swapTokenAmountThresholdForStaking = _swapTokenAmount;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function totalSupplyRewardEquivalent() external view returns (uint256) {
        return _totalSupplyRewardEquivalent;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function balanceOfRewardEquivalent(address account) external view returns (uint256) {
        return _balancesRewardEquivalent[account];
    }

    function earned(address account) public view override returns (uint256) {
        return (_balancesRewardEquivalent[account].mul(block.timestamp.sub(weightedStakeDate[account])).mul(rewardRate)) / (100 * rewardDuration);
    }

    function isAmountMeetsMinThreshold(uint amount) public view returns (bool) {
        address[] memory path = new address[](2);
        path[0] = address(stakingToken);
        path[1] = swapToken;
        uint tokenAmount = swapRouter.getAmountsOut(amount, path)[1];
        return tokenAmount >= swapTokenAmountThresholdForStaking;
    }

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(amount > 0, "LockStakingRewardMinAmountFixedAPY: Cannot stake 0");
        // permit
        IERC20Permit(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(amount, msg.sender);
    }

    function stake(uint256 amount) external override nonReentrant {
        require(amount > 0, "LockStakingRewardMinAmountFixedAPY: Cannot stake 0");
        _stake(amount, msg.sender);
    }

    function stakeFor(uint256 amount, address user) external override nonReentrant {
        require(amount > 0, "LockStakingRewardMinAmountFixedAPY: Cannot stake 0");
        _stake(amount, user);
    }

    function _stake(uint256 amount, address user) private {
        require(isAmountMeetsMinThreshold(amount), "LockStakingRewardMinAmountFixedAPY: Amount is less than min stake");
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint amountRewardEquivalent = getEquivalentAmount(amount);

        _totalSupply = _totalSupply.add(amount);
        _totalSupplyRewardEquivalent = _totalSupplyRewardEquivalent.add(amountRewardEquivalent);
        uint previousAmount = _balances[user];
        uint newAmount = previousAmount.add(amount);
        weightedStakeDate[user] = (weightedStakeDate[user].mul(previousAmount) / newAmount).add(block.timestamp.mul(amount) / newAmount);
        _balances[user] = newAmount;

        uint stakeNonce = stakeNonces[user]++;
        stakeAmounts[user][stakeNonce] = amount;
        stakeLocks[user][stakeNonce] = block.timestamp + lockDuration;
        
        stakeAmountsRewardEquivalent[user][stakeNonce] = amountRewardEquivalent;
        _balancesRewardEquivalent[user] = _balancesRewardEquivalent[user].add(amountRewardEquivalent);
        emit Staked(user, amount);
    }


    //A user can withdraw its staking tokens even if there is no rewards tokens on the contract account
    function withdraw(uint256 nonce) public override nonReentrant {
        require(stakeAmounts[msg.sender][nonce] > 0, "LockStakingRewardMinAmountFixedAPY: This stake nonce was withdrawn");
        require(stakeLocks[msg.sender][nonce] < block.timestamp, "LockStakingRewardMinAmountFixedAPY: Locked");
        uint amount = stakeAmounts[msg.sender][nonce];
        uint amountRewardEquivalent = stakeAmountsRewardEquivalent[msg.sender][nonce];
        _totalSupply = _totalSupply.sub(amount);
        _totalSupplyRewardEquivalent = _totalSupplyRewardEquivalent.sub(amountRewardEquivalent);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balancesRewardEquivalent[msg.sender] = _balancesRewardEquivalent[msg.sender].sub(amountRewardEquivalent);
        stakingToken.safeTransfer(msg.sender, amount);
        stakeAmounts[msg.sender][nonce] = 0;
        stakeAmountsRewardEquivalent[msg.sender][nonce] = 0;
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            weightedStakeDate[msg.sender] = block.timestamp;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function withdrawAndGetReward(uint256 nonce) external override {
        getReward();
        withdraw(nonce);
    }

    function getEquivalentAmount(uint amount) public view returns (uint) {
        address[] memory path = new address[](2);

        uint equivalent;
        if (stakingToken != rewardsToken) {
            path[0] = address(stakingToken);            
            path[1] = address(rewardsToken);
            equivalent = swapRouter.getAmountsOut(amount, path)[1];
        } else {
            equivalent = amount;   
        }
        
        return equivalent;
    }


    function updateRewardAmount(uint256 reward) external onlyOwner {
        rewardRate = reward;
        emit RewardUpdated(reward);
    }

    function updateSwapRouter(address newSwapRouter) external onlyOwner {
        require(newSwapRouter != address(0), "LockStakingRewardMinAmountFixedAPY: Address is zero");
        swapRouter = INimbusRouter(newSwapRouter);
    }

    function updateSwapToken(address newSwapToken) external onlyOwner {
        require(newSwapToken != address(0), "LockStakingRewardMinAmountFixedAPY: Address is zero");
        swapToken = newSwapToken;
    }

    function updateStakeSwapTokenAmountThreshold(uint threshold) external onlyOwner {
        swapTokenAmountThresholdForStaking = threshold;
    }

    function rescue(address to, address token, uint256 amount) external onlyOwner {
        require(to != address(0), "LockStakingRewardMinAmountFixedAPY: Cannot rescue to the zero address");
        require(amount > 0, "LockStakingRewardMinAmountFixedAPY: Cannot rescue 0");
        require(token != address(stakingToken), "LockStakingRewardMinAmountFixedAPY: Cannot rescue staking token");
        //owner can rescue rewardsToken if there is spare unused tokens on staking contract balance

        IERC20(token).safeTransfer(to, amount);
        emit RescueToken(to, address(token), amount);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "LockStakingRewardMinAmountFixedAPY: Cannot rescue to the zero address");
        require(amount > 0, "LockStakingRewardMinAmountFixedAPY: Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
}