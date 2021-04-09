// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IGaugeController.sol";
import "../interfaces/IGauge.sol";
import "../interfaces/IUniPool.sol";
import "../interfaces/IVotingEscrow.sol";

/**
 * @dev Liquidity gauge that stakes token and earns reward.
 * 
 * Note: The liquidity gauge token might not be 1:1 with the staked token.
 * For plus tokens, the total staked amount increases as interest from plus token accrues.
 * Credit: https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/gauges/LiquidityGaugeV2.vy
 */
contract LiquidityGauge is ERC20Upgradeable, ReentrancyGuardUpgradeable, IGauge {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event LiquidityLimitUpdated(address indexed account, uint256 balance, uint256 supply, uint256 oldWorkingBalance,
        uint256 oldWorkingSupply, uint256 newWorkingBalance, uint256 newWorkingSupply);
    event Deposited(address indexed account, uint256 stakedAmount, uint256 mintAmount);
    event Withdrawn(address indexed account, uint256 withdrawAmount, uint256 fee, uint256 burnAmount);
    event RewardContractUpdated(address indexed oldRewardContract, address indexed newRewardContract, address[] rewardTokens);
    event WithdrawFeeUpdated(uint256 oldWithdrawFee, uint256 newWithdrawFee);
    event DirectClaimCooldownUpdated(uint256 oldCooldown, uint256 newCooldown);

    uint256 constant TOKENLESS_PRODUCTION = 40;
    uint256 constant WAD = 10**18;
    uint256 constant MAX_PERCENT = 10000;   // 0.01%

    // Token staked in the liquidity gauge
    address public override token;
    // AC token
    address public reward;
    // Gauge controller
    address public controller;
    address public votingEscrow;
    // AC emission rate per seconds in the gauge
    uint256 public rate;
    uint256 public withdrawFee;
    // List of tokens that cannot be salvaged
    mapping(address => bool) public unsalvageable;

    uint256 public workingSupply;
    mapping(address => uint256) public workingBalances;

    uint256 public integral;
    // Last global checkpoint timestamp
    uint256 public lastCheckpoint;
    // Integral of the last user checkpoint
    mapping(address => uint256) public integralOf;
    // Timestamp of the last user checkpoint
    mapping(address => uint256) public checkpointOf;
    // Mapping: User => Rewards accrued last checkpoint
    mapping(address => uint256) public rewards;
    // Mapping: User => Last time the user claims directly from the gauge
    // Users can claim directly from gauge or indirectly via a claimer
    mapping(address => uint256) public lastDirectClaim;
    // The cooldown interval between two direct claims from the gauge
    uint256 public directClaimCooldown;

    address public rewardContract;
    address[] public rewardTokens;
    // Reward token address => Reward token integral
    mapping(address => uint256) public rewardIntegral;
    // Reward token address => (User address => Reward integral of the last user reward checkpoint)
    mapping(address => mapping(address => uint256)) public rewardIntegralOf;

    /**
     * @dev Initlaizes the liquidity gauge contract.
     */
    function initialize(address _token, address _controller, address _votingEscrow) public initializer {
        token = _token;
        controller = _controller;
        reward = IGaugeController(_controller).reward();
        votingEscrow = _votingEscrow;
        directClaimCooldown = 14 days;  // A default 14 day direct claim cool down

        // Should not salvage token from the gauge
        unsalvageable[token] = true;
        // We allow salvage reward token since the liquidity gauge should not hold reward token. It's
        // distributed from gauge controller to user directly.

        __ERC20_init(string(abi.encodePacked(ERC20Upgradeable(_token).name(), " Gauge Deposit")),
            string(abi.encodePacked(ERC20Upgradeable(_token).symbol(), "-gauge")));
        __ReentrancyGuard_init();
    }

    /**
     * @dev Important: Updates the working balance of the user to effectively apply
     * boosting on liquidity mining.
     * @param _account Address to update liquidity limit
     */
    function _updateLiquidityLimit(address _account) internal {
        IERC20Upgradeable _votingEscrow = IERC20Upgradeable(votingEscrow);
        uint256 _votingBalance = _votingEscrow.balanceOf(_account);
        uint256 _votingTotal = _votingEscrow.totalSupply();

        uint256 _balance = balanceOf(_account);
        uint256 _supply = totalSupply();
        uint256 _limit = _balance.mul(TOKENLESS_PRODUCTION).div(100);
        if (_votingTotal > 0) {
            uint256 _boosting = _supply.mul(_votingBalance).mul(100 - TOKENLESS_PRODUCTION).div(_votingTotal).div(100);
            _limit = _limit.add(_boosting);
        }

        _limit = MathUpgradeable.min(_balance, _limit);
        uint256 _oldWorkingBalance = workingBalances[_account];
        uint256 _oldWorkingSupply = workingSupply;
        workingBalances[_account] = _limit;
        uint256 _newWorkingSupply = _oldWorkingSupply.add(_limit).sub(_oldWorkingBalance);
        workingSupply = _newWorkingSupply;

        emit LiquidityLimitUpdated(_account, _balance, _supply, _oldWorkingBalance, _oldWorkingSupply, _limit, _newWorkingSupply);
    }

    /**
     * @dev Claims pending rewards and checkpoint rewards for a user.
     * @param _account Address of the user to checkpoint reward. Zero means global checkpoint only.
     */
    function _checkpointRewards(address _account) internal {
        uint256 _supply = totalSupply();
        address _rewardContract = rewardContract;
        address[] memory _rewardList = rewardTokens;
        uint256[] memory _rewardBalances = new uint256[](_rewardList.length);
        // No op if nothing is staked yet!
        if (_supply == 0 || _rewardContract == address(0x0) || _rewardList.length == 0) return;

        // Reads balance for each reward token
        for (uint256 i = 0; i < _rewardList.length; i++) {
            _rewardBalances[i] = IERC20Upgradeable(_rewardList[i]).balanceOf(address(this));
        }
        IUniPool(_rewardContract).getReward();
        
        uint256 _balance = balanceOf(_account);
        // Checks balance increment for each reward token
        for (uint256 i = 0; i < _rewardList.length; i++) {
            // Integral is in WAD
            uint256 _diff = IERC20Upgradeable(_rewardList[i]).balanceOf(address(this)).sub(_rewardBalances[i]).mul(WAD).div(_supply);
            uint256 _newIntegral = rewardIntegral[_rewardList[i]].add(_diff);
            if (_diff != 0) {
                rewardIntegral[_rewardList[i]] = _newIntegral;
            }
            if (_account == address(0x0))   continue;

            uint256 _userIntegral = rewardIntegralOf[_rewardList[i]][_account];
            if (_userIntegral < _newIntegral) {
                uint256 _claimable = _balance.mul(_newIntegral.sub(_userIntegral)).div(WAD);
                rewardIntegralOf[_rewardList[i]][_account] = _newIntegral;

                if (_claimable > 0) {
                    IERC20Upgradeable(_rewardList[i]).safeTransfer(_account, _claimable);
                }
            }
        }
    }

    /**
     * @dev Performs checkpoint on AC rewards.
     * @param _account User address to checkpoint. Zero to do global checkpoint only.
     */
    function _checkpoint(address _account) internal {
        uint256 _workingSupply = workingSupply;
        if (_workingSupply == 0) {
            lastCheckpoint = block.timestamp;
            return;
        }

        uint256 _diffTime = block.timestamp.sub(lastCheckpoint);
        // Both rate and integral are in WAD
        uint256 _newIntegral = integral.add(rate.mul(_diffTime).div(_workingSupply));
        integral = _newIntegral;
        lastCheckpoint = block.timestamp;

        if (_account == address(0x0))   return;

        uint256 _amount = workingBalances[_account].mul(_newIntegral.sub(integralOf[_account])).div(WAD);
        integralOf[_account] = _newIntegral;
        checkpointOf[_account] = block.timestamp;
        rewards[_account] = rewards[_account].add(_amount);
    }

    /**
     * @dev Performs global checkpoint for the liquidity gauge.
     * Note: AC emission rate change is triggered by gauge controller. Each time there is a rate change,
     * Gauge controller will checkpoint the gauge. Therefore, we could assume that the rate is not changed
     * between two checkpoints!
     */
    function checkpoint() external override nonReentrant {
        _checkpoint(address(0x0));
        // Loads the new emission rate from gauge controller
        rate = IGaugeController(controller).gaugeRates(address(this));
    }

    /**
     * @dev Returns the next time user can trigger a direct claim.
     */
    function nextDirectClaim(address _account) external view returns (uint256) {
        return MathUpgradeable.max(block.timestamp, lastDirectClaim[_account].add(directClaimCooldown));
    }

    /**
     * @dev Returns the amount of AC token that the user can claim.
     * @param _account Address of the account to check claimable reward.
     */
    function claimable(address _account) external view override returns (uint256) {
        // Reward claimable until the previous checkpoint
        uint256 _reward = workingBalances[_account].mul(integral.sub(integralOf[_account])).div(WAD);
        // Add the remaining claimable rewards
        _reward = _reward.add(rewards[_account]);
        if (workingSupply > 0) {
            uint256 _diffTime = block.timestamp.sub(lastCheckpoint);
            // Both rate and integral are in WAD
            uint256 _additionalReard = rate.mul(_diffTime).mul(workingBalances[_account]).div(workingSupply).div(WAD);

            _reward = _reward.add(_additionalReard);
        }

        return _reward;
    }

    /**
     * @dev Returns the amount of reward token that the user can claim until the latest checkpoint.
     * @param _account Address of the account to check claimable reward.
     * @param _rewardToken Address of the reward token
     */
    function claimableReward(address _account, address _rewardToken) external view returns (uint256) {
        return balanceOf(_account).mul(rewardIntegral[_rewardToken].sub(rewardIntegralOf[_rewardToken][_account])).div(WAD);
    }

    /**
     * @dev Claims reward for the user. 
     * @param _account Address of the user to claim.
     * @param _claimRewards Whether to claim other rewards as well.
     */
    function claim(address _account, bool _claimRewards) external nonReentrant {
        _claim(_account, _account, _claimRewards);
    }

    /**
     * @dev Claims reward for the user. 
     * @param _account Address of the user to claim.
     * @param _receiver Address that receives the claimed reward
     * @param _claimRewards Whether to claim other rewards as well.
     */
    function claim(address _account, address _receiver, bool _claimRewards) external override nonReentrant {
        _claim(_account, _receiver, _claimRewards);
    }

    /**
     * @dev Claims reward for the user. It transfers the claimable reward to the user and updates user's liquidity limit.
     * Note: We allow anyone to claim other rewards on behalf of others, but not for the AC reward. This is because claiming AC
     * reward also updates the user's liquidity limit. Therefore, only authorized claimer can do that on behalf of user.
     * @param _account Address of the user to claim.
     * @param _receiver Address that receives the claimed reward
     * @param _claimRewards Whether to claim other rewards as well.
     */
    function _claim(address _account, address _receiver, bool _claimRewards) internal {
        // Direct claim mean user claiming directly to the gauge. Cooldown applies to direct claim.
        // Indirect claim means user claimsing via claimers. There is no cooldown in indirect claim.
        require((_account == msg.sender && block.timestamp >= lastDirectClaim[_account].add(directClaimCooldown))
            || IGaugeController(controller).claimers(msg.sender), "cannot claim");

        _checkpoint(_account);
        _updateLiquidityLimit(_account);

        uint256 _claimable = rewards[_account];
        if (_claimable > 0) {
            IGaugeController(controller).claim(_account, _receiver, _claimable);
            rewards[_account] = 0;
        }

        if (_claimRewards) {
            _checkpointRewards(_account);
        }

        // Cooldown applies only to direct claim
        if (_account == msg.sender) {
            lastDirectClaim[msg.sender] = block.timestamp;
        }
    }

    /**
     * @dev Claims all rewards for the caller.
     * @param _account Address of the user to claim.
     */
    function claimRewards(address _account) external nonReentrant {
        _checkpointRewards(_account);
    }

    /**
     * @dev Checks whether an account can be kicked.
     * An account is kickable if the account has another voting event since last checkpoint,
     * or the lock of the account expires.
     */
    function kickable(address _account) public view override returns (bool) {
        address _votingEscrow = votingEscrow;
        uint256 _lastUserCheckpoint = checkpointOf[_account];
        uint256 _lastUserEvent = IVotingEscrow(_votingEscrow).user_point_history__ts(_account, IVotingEscrow(_votingEscrow).user_point_epoch(_account));

        return IERC20Upgradeable(_votingEscrow).balanceOf(_account) == 0 || _lastUserEvent > _lastUserCheckpoint;
    }

    /**
     * @dev Kicks an account for abusing their boost. Only kick if the user
     * has another voting event, or their lock expires.
     */
    function kick(address _account) external override nonReentrant {
        // We allow claimers to kick since kick can be seen as subset of claim.
        require(kickable(_account) || IGaugeController(controller).claimers(msg.sender), "kick not allowed");

        _checkpoint(_account);
        _updateLiquidityLimit(_account);
    }

    /**
     * @dev Returns the total amount of token staked.
     */
    function totalStaked() public view override returns (uint256) {
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    /**
     * @dev Returns the amount staked by the user.
     */
    function userStaked(address _account) public view override returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 _balance = IERC20Upgradeable(token).balanceOf(address(this));

        return _totalSupply == 0 ? 0 : balanceOf(_account).mul(_balance).div(_totalSupply);
    }

    /**
     * @dev Deposit the staked token into liquidity gauge.
     * @param _amount Amount of staked token to deposit.
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "zero amount");
        if (_amount == uint256(int256(-1))) {
            // -1 means deposit all
            _amount = IERC20Upgradeable(token).balanceOf(msg.sender);
        }

        _checkpoint(msg.sender);
        _checkpointRewards(msg.sender);

        uint256 _totalSupply = totalSupply();
        uint256 _balance = IERC20Upgradeable(token).balanceOf(address(this));
        // Note: Ideally, when _totalSupply = 0, _balance = 0.
        // However, it's possible that _balance != 0 when _totalSupply = 0, e.g.
        // 1) There are some leftover due to rounding error after all people withdraws;
        // 2) Someone sends token to the liquidity gauge before there is any deposit.
        // Therefore, when either _totalSupply or _balance is 0, we treat the gauge is empty.
        uint256 _mintAmount = _totalSupply == 0 || _balance == 0 ? _amount : _amount.mul(_totalSupply).div(_balance);
        
        _mint(msg.sender, _mintAmount);
        _updateLiquidityLimit(msg.sender);

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), _amount);

        address _rewardContract = rewardContract;
        if (_rewardContract != address(0x0)) {
            IUniPool(_rewardContract).stake(_amount);
        }

        emit Deposited(msg.sender, _amount, _mintAmount);
    }

    /**
     * @dev Withdraw the staked token from liquidity gauge.
     * @param _amount Amounf of staked token to withdraw
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "zero amount");
        uint256 _burnAmount = 0;
        if (_amount == uint256(int256(-1))) {
            // -1 means withdraw all
            _amount = userStaked(msg.sender);
            _burnAmount = balanceOf(msg.sender);
        } else {
            uint256 _totalSupply = totalSupply();
            uint256 _balance = IERC20Upgradeable(token).balanceOf(address(this));
            require(_totalSupply > 0 && _balance > 0, "no balance");
            _burnAmount = _amount.mul(_totalSupply).div(_balance);
        }

        _checkpoint(msg.sender);
        _checkpointRewards(msg.sender);

        _burn(msg.sender, _burnAmount);
        _updateLiquidityLimit(msg.sender);

        address _rewardContract = rewardContract;
        if (_rewardContract != address(0x0)) {
            IUniPool(_rewardContract).withdraw(_amount);
        }
        
        uint256 _fee;
        address _token = token;
        address _controller = controller;
        if (withdrawFee > 0) {
            _fee = _amount.mul(withdrawFee).div(MAX_PERCENT);
            IERC20Upgradeable(_token).safeTransfer(_controller, _fee);
            // Donate the withdraw fee for future processing
            // Withdraw fee for plus token is donated to all token holders right away
            IGaugeController(_controller).donate(_token);
        }

        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount.sub(_fee));
        emit Withdrawn(msg.sender, _amount, _fee, _burnAmount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     */
    function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual override {
        _checkpoint(_sender);
        _checkpoint(_recipient);
        _checkpointRewards(_sender);
        _checkpointRewards(_recipient);

        // Invoke super _transfer to emit Transfer event
        super._transfer(_sender, _recipient, _amount);

        _updateLiquidityLimit(_sender);
        _updateLiquidityLimit(_recipient);
    }

    /*********************************************
     *
     *    Governance methods
     *
     **********************************************/
    
    /**
     * @dev All liqduiity gauge share the same governance of gauge controller.
     */
    function _checkGovernance() internal view {
        require(msg.sender == IGaugeController(controller).governance(), "not governance");
    }

    modifier onlyGovernance() {
        _checkGovernance();
        _;
    }

    /**
     * @dev Updates the reward contract and reward tokens.
     * @param _rewardContract The new active reward contract.
     * @param _rewardTokens The reward tokens from the reward contract.
     */
    function setRewards(address _rewardContract, address[] memory _rewardTokens) external onlyGovernance {
        address _currentRewardContract = rewardContract;
        address _token = token;
        if (_currentRewardContract != address(0x0)) {
            _checkpointRewards(address(0x0));
            IUniPool(_currentRewardContract).exit();

            IERC20Upgradeable(_token).safeApprove(_currentRewardContract, 0);
        }

        if (_rewardContract != address(0x0)) {
            require(_rewardTokens.length > 0, "reward tokens not set");
            IERC20Upgradeable(_token).safeApprove(_rewardContract, uint256(int256(-1)));
            IUniPool(_rewardContract).stake(totalSupply());

            rewardContract = _rewardContract;
            rewardTokens = _rewardTokens;

            // Complete an initial checkpoint to make sure that everything works.
            _checkpointRewards(address(0x0));

            // Reward contract is tokenized as well
            unsalvageable[_rewardContract] = true;
            // Don't salvage any reward token
            for (uint256 i = 0; i < _rewardTokens.length; i++) {
                unsalvageable[_rewardTokens[i]] = true;
            }
        }

        emit RewardContractUpdated(_currentRewardContract, _rewardContract, _rewardTokens);
    }

    /**
     * @dev Updates the withdraw fee. Only governance can update withdraw fee.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyGovernance {
        require(_withdrawFee <= MAX_PERCENT, "too big");
        uint256 _oldWithdrawFee = withdrawFee;
        withdrawFee = _withdrawFee;

        emit WithdrawFeeUpdated(_oldWithdrawFee, _withdrawFee);
    }

    /**
     * @dev Updates the cooldown between two direct claims.
     */
    function setDirectClaimCooldown(uint256 _cooldown) external onlyGovernance {
        uint256 _oldCooldown = directClaimCooldown;
        directClaimCooldown = _cooldown;

        emit DirectClaimCooldownUpdated(_oldCooldown, _cooldown);
    }

    /**
     * @dev Used to salvage any ETH deposited to gauge contract by mistake. Only governance can salvage ETH.
     * The salvaged ETH is transferred to treasury for futher operation.
     */
    function salvage() external onlyGovernance {
        uint256 _amount = address(this).balance;
        address payable _target = payable(IGaugeController(controller).treasury());
        (bool success, ) = _target.call{value: _amount}(new bytes(0));
        require(success, 'ETH salvage failed');
    }

    /**
     * @dev Used to salvage any token deposited to gauge contract by mistake. Only governance can salvage token.
     * The salvaged token is transferred to treasury for futhuer operation.
     * @param _token Address of the token to salvage.
     */
    function salvageToken(address _token) external onlyGovernance {
        require(!unsalvageable[_token], "cannot salvage");

        IERC20Upgradeable _target = IERC20Upgradeable(_token);
        _target.safeTransfer(IGaugeController(controller).treasury(), _target.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title Interface for liquidity gauge.
 */
interface IGauge is IERC20Upgradeable {

    /**
     * @dev Returns the address of the staked token.
     */
    function token() external view returns (address);

    /**
     * @dev Checkpoints the liquidity gauge.
     */
    function checkpoint() external;

    /**
     * @dev Returns the total amount of token staked in the gauge.
     */
    function totalStaked() external view returns (uint256);

    /**
     * @dev Returns the amount of token staked by the user.
     */
    function userStaked(address _account) external view returns (uint256);

    /**
     * @dev Returns the amount of AC token that the user can claim.
     * @param _account Address of the account to check claimable reward.
     */
    function claimable(address _account) external view returns (uint256);

    /**
     * @dev Claims reward for the user. It transfers the claimable reward to the user and updates user's liquidity limit.
     * Note: We allow anyone to claim other rewards on behalf of others, but not for the AC reward. This is because claiming AC
     * reward also updates the user's liquidity limit. Therefore, only authorized claimer can do that on behalf of user.
     * @param _account Address of the user to claim.
     * @param _receiver Address that receives the claimed reward
     * @param _claimRewards Whether to claim other rewards as well.
     */
    function claim(address _account, address _receiver, bool _claimRewards) external;

    /**
     * @dev Checks whether an account can be kicked.
     * An account is kickable if the account has another voting event since last checkpoint,
     * or the lock of the account expires.
     */
    function kickable(address _account) external view returns (bool);

    /**
     * @dev Kicks an account for abusing their boost. Only kick if the user
     * has another voting event, or their lock expires.
     */
    function kick(address _account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @title Interface for gauge controller.
 */
interface IGaugeController {

    /**
     * @dev Returns the reward token address.
     */
    function reward() external view returns(address);

    /**
     * @dev Returns the governance address.
     */
    function governance() external view returns (address);

    /**
     * @dev Returns the treasury address.
     */
    function treasury() external view returns (address);

    /**
     * @dev Returns the current AC emission rate for the gauge.
     * @param _gauge The liquidity gauge to check AC emission rate.
     */
    function gaugeRates(address _gauge) external view returns (uint256);

    /**
     * @dev Returns whether the account is a claimer which can claim rewards on behalf
     * of the user. Since user's liquidity limit is updated each time a user claims, we
     * don't want to allow anyone to claim for others.
     */
    function claimers(address _account) external view returns (bool);

    /**
     * @dev Returns the total amount of AC claimed by the user in the liquidity pool specified.
     * @param _gauge Liquidity gauge which generates the AC reward.
     * @param _account Address of the user to check.
     */
    function claimed(address _gauge, address _account) external view returns (uint256);

    /**
     * @dev Returns the last time the user claims from any gauge.
     * @param _account Address of the user to claim.
     */
    function lastClaim(address _account) external view returns (uint256);

    /**
     * @dev Claims rewards for a user. Only the supported gauge can call this function.
     * @param _account Address of the user to claim reward.
     * @param _receiver Address that receives the claimed reward
     * @param _amount Amount of AC to claim
     */
    function claim(address _account, address _receiver, uint256 _amount) external;

    /**
     * @dev Donate the gauge fee. Only liqudity gauge can call this function.
     * @param _token Address of the donated token.
     */
    function donate(address _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Interface for the UniPool reward contract.
 */
interface IUniPool {

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function exit() external;

    function getReward() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @title Interface for voting escrow.
 */
interface IVotingEscrow {

    function balanceOf(address _account) external view returns (uint256);

    function deposit_for(address _account, uint256 _amount) external;

    function user_point_epoch(address _account) external view returns (uint256);

    function user_point_history__ts(address _account, uint256 _epoch) external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}