// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeBEP20.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./RewardsDistributionRecipientUpgradeable.sol";
import "./IStrategy.sol";
import "./IMasterChef.sol";
import "./IAMVMinterV2.sol";
import "./VaultController.sol";
import "./IPancakeRouter02.sol";
import {PoolConstant} from "./PoolConstant.sol";


contract VaultFlipToBNB is VaultController, IStrategy, RewardsDistributionRecipientUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    IMasterChef private constant CAKE_MASTER_CHEF = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToBNB;

    /* ========== STATE VARIABLES ========== */

    IStrategy private _rewardsToken;

    uint public periodFinish;
    uint public rewardRate;
    uint public rewardsDuration;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    uint public override pid;
    mapping (address => uint) private _depositedAt;

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint reward);
    event RewardsDurationUpdated(uint newDuration);

    /* ========== INITIALIZER ========== */

    function initialize(uint _pid) external initializer {
        (address _token,,,) = CAKE_MASTER_CHEF.poolInfo(_pid);
        __VaultController_init(IBEP20(_token));
        __RewardsDistributionRecipient_init();
        __ReentrancyGuard_init();

        _stakingToken.safeApprove(address(CAKE_MASTER_CHEF), uint(~0));

        pid = _pid;

        rewardsDuration = 4 hours;

        rewardsDistribution = msg.sender;
        setMinter(0xC7EBF06A6188040B45fe95112Ff5557c36Ded7c0);  
        setRewardsToken(0xb8A475c0197b477bb1c41671ACA22986EA8765D2); 
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function balance() override external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function sharesOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function principalOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_rewardsToken);
    }

    function priceShare() external view override returns (uint) {
        return 1e18;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) override public view returns (uint) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint amount) override public {
        _deposit(amount, msg.sender);
    }

    function depositAll() override external {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdraw(uint amount) override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "VaultFlipToBNB: amount must be greater than zero");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uint cakeHarvested = _withdrawStakingToken(amount);
        uint withdrawalFee;
        if (canMint()) {
            uint depositTimestamp = _depositedAt[msg.sender];
            withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
            if (withdrawalFee > 0) {
                uint performanceFee = withdrawalFee.div(100);
                _minter.mintFor(address(_stakingToken), withdrawalFee.sub(performanceFee), performanceFee, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }
        
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        _harvest(cakeHarvested);
    }

    function withdrawAll() external override {
// 		getReward();
        uint _withdraw = withdrawableBalanceOf(msg.sender);
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
		getReward();
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint reward;
        // if(rewards[msg.sender] > 0) {
        //     reward = rewards[msg.sender];
        // } else {
        //     reward = earned(msg.sender);
        // }
		reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint before = IBEP20(CAKE).balanceOf(address(this));
            
            _rewardsToken.withdraw(reward);
            
            uint cakeBalance = IBEP20(CAKE).balanceOf(address(this)).sub(before);
            uint performanceFee;

            if (canMint()) {
                performanceFee = _minter.performanceFee(cakeBalance);
                _minter.mintFor(CAKE, 0, performanceFee, msg.sender, _depositedAt[msg.sender]);
            }

            // IBEP20(CAKE).safeTransfer(msg.sender, cakeBalance.sub(performanceFee));
            if (cakeBalance.sub(performanceFee) > 0) {
                _swapTokenToToken(CAKE, cakeBalance.sub(performanceFee), WBNB);
            }
            emit ProfitPaid(msg.sender, cakeBalance, performanceFee);
        }
    }

    function harvest() public override {
        uint cakeHarvested = _withdrawStakingToken(0);
        _harvest(cakeHarvested);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address newMinter) override public onlyOwner {
        VaultController.setMinter(newMinter);
        if (newMinter != address(0)) {
            IBEP20(CAKE).safeApprove(newMinter, 0);
            IBEP20(CAKE).safeApprove(newMinter, uint(- 1));
        }
    }

    function setRewardsToken(address newRewardsToken) public onlyOwner {
        require(address(_rewardsToken) == address(0), "VaultFlipToBNB: rewards token already set");

        _rewardsToken = IStrategy(newRewardsToken);
        IBEP20(CAKE).safeApprove(newRewardsToken, 0);
        IBEP20(CAKE).safeApprove(newRewardsToken, uint(- 1));
    }

    function notifyRewardAmount(uint reward) public override onlyRewardsDistribution {
        _notifyRewardAmount(reward);
    }

    function setRewardsDuration(uint _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "VaultFlipToBNB: reward duration can only be updated after the period ends");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    
    function _approveTokenIfNeeded(address token) private {
        if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
            IBEP20(token).safeApprove(address(ROUTER), uint(~0));
        }
    }
    
    function _swapTokenToToken(address _from, uint amount, address _to) private returns (uint) {
        
        require(amount > 0, "VaultFlipToBNB: amount must be greater than zero");
        _approveTokenIfNeeded(_from);
        
        address[] memory path;
        
        if (_from == WBNB || _to == WBNB) {
            // [WBNB, AMV] or [AMV, WBNB]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [USDT, AMV] or [AMV, USDT]
            path = new address[](3);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = _to;
        }
       
        uint[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, msg.sender, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _deposit(uint amount, address _to) private nonReentrant notPaused updateReward(_to) {
        require(amount > 0, "VaultFlipToBNB: amount must be greater than zero");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        _depositedAt[_to] = block.timestamp;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint cakeHarvested = _depositStakingToken(amount);
        emit Deposited(_to, amount);
		
        _harvest(cakeHarvested);
    }

    function _depositStakingToken(uint amount) private returns (uint cakeHarvested) {
        uint before = IBEP20(CAKE).balanceOf(address(this));
        CAKE_MASTER_CHEF.deposit(pid, amount);
        cakeHarvested = IBEP20(CAKE).balanceOf(address(this)).sub(before);
    }

    function _withdrawStakingToken(uint amount) private returns (uint cakeHarvested) {
        uint before = IBEP20(CAKE).balanceOf(address(this));
        CAKE_MASTER_CHEF.withdraw(pid, amount);
        cakeHarvested = IBEP20(CAKE).balanceOf(address(this)).sub(before);
    }

    function _harvest(uint cakeAmount) private {
        uint _before = _rewardsToken.sharesOf(address(this));
        _rewardsToken.deposit(cakeAmount);
        uint amount = _rewardsToken.sharesOf(address(this)).sub(_before);
        if (amount > 0) {
            _notifyRewardAmount(amount);
            emit Harvested(amount);
        }
    }

    function _notifyRewardAmount(uint reward) private updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint _balance = _rewardsToken.sharesOf(address(this));
        require(rewardRate <= _balance.div(rewardsDuration), "VaultFlipToBNB: reward rate must be in the right range");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev rewardToken(CAKE) must not remain balance in this contract. So dev should be able to salvage reward token transferred by mistake.
    // function recoverToken(address tokenAddress, uint tokenAmount) external override onlyOwner {
    //     require(tokenAddress != address(_stakingToken), "VaultFlipToBNB: cannot recover underlying token");

    //     IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
    //     emit Recovered(tokenAddress, tokenAmount);
    // }

    /* ========== MIGRATE PANCAKE V1 to V2 ========== */

    // function migrate(address account, uint amount) public {
    //     if (amount == 0) return;
    //     _deposit(amount, account);
    // }

    // function migrateCake(uint amount) public onlyOwner {
    //     IBEP20(CAKE).safeTransferFrom(msg.sender, address(this), amount);

    //     uint _before = _rewardsToken.sharesOf(address(this));
    //     _rewardsToken.deposit(amount);

    //     uint reward = _rewardsToken.sharesOf(address(this)).sub(_before);
    //     if (reward > 0) {
    //         _notifyRewardAmount(reward);
    //     }
    // }

    // function setPidToken(uint _pid, address token) external onlyOwner {
    //     require(_totalSupply == 0);
    //     pid = _pid;
    //     _stakingToken = IBEP20(token);

    //     _stakingToken.safeApprove(address(CAKE_MASTER_CHEF), 0);
    //     _stakingToken.safeApprove(address(CAKE_MASTER_CHEF), uint(- 1));

    //     _stakingToken.safeApprove(address(_minter), 0);
    //     _stakingToken.safeApprove(address(_minter), uint(- 1));
    // }
}