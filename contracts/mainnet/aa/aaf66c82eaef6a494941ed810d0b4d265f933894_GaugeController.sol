// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IPlus.sol";
import "../interfaces/IGauge.sol";
import "../interfaces/IGaugeController.sol";

/**
 * @title Controller for all liquidity gauges.
 *
 * The Gauge Controller is responsible for the following:
 * 1) AC emission rate computation for plus gauges;
 * 2) AC reward claiming;
 * 3) Liquidity gauge withdraw fee processing.
 *
 * Liquidity gauges can be divided into two categories:
 * 1) Plus gauge: Liquidity gauges for plus tokens, the total rate is dependent on the total staked amount in these gauges;
 * 2) Non-plus gage: Liquidity gauges for non-plus token, the rate is set by governance.
 */
contract GaugeController is Initializable, IGaugeController {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    event ClaimerUpdated(address indexed claimer, bool allowed);
    event BasePlusRateUpdated(uint256 oldBaseRate, uint256 newBaseRate);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event GaugeAdded(address indexed gauge, bool plus, uint256 gaugeWeight, uint256 gaugeRate);
    event GaugeRemoved(address indexed gauge);
    event GaugeUpdated(address indexed gauge, uint256 oldWeight, uint256 newWeight, uint256 oldGaugeRate, uint256 newGaugeRate);
    event Checkpointed(uint256 oldRate, uint256 newRate, uint256 totalSupply, uint256 ratePerToken, address[] gauges, uint256[] guageRates);
    event RewardClaimed(address indexed gauge, address indexed user, address indexed receiver, uint256 amount);
    event FeeProcessed(address indexed gauge, address indexed token, uint256 amount);

    uint256 constant WAD = 10 ** 18;
    uint256 constant LOG_10_2 = 301029995663981195;  // log10(2) = 0.301029995663981195
    uint256 constant DAY = 86400;
    uint256 constant PLUS_BOOST_THRESHOLD = 100 * WAD;   // Plus boosting starts at 100 plus staked!

    address public override governance;
    // AC token
    address public override reward;
    // Address => Whether this is claimer address.
    // A claimer can help claim reward on behalf of the user.
    mapping(address => bool) public override claimers;
    address public override treasury;

    struct Gauge {
        // Helps to check whether the gauge is in the gauges list.
        bool isSupported;
        // Whether this is a plus gauge. The emission rate for the plus gauges depends on
        // the total staked value in the plus gauges, while the emission rate for the non-plus
        // gauges is set by the governance.
        bool isPlus;
        // Multiplier applied to the gauge in computing emission rate. Only applied to plus
        // gauges as non-plus gauges should have fixed rate set by governance.
        uint256 weight;
        // Fixed AC emission rate for non-plus gauges.
        uint256 rate;
    }

    // List of supported liquidity gauges
    address[] public gauges;
    // Liquidity gauge address => Liquidity gauge data
    mapping(address => Gauge) public gaugeData;
    // Liquidity gauge address => Actual AC emission rate
    // For non-plus gauges, it is equal to gaugeData.rate when staked amount is non-zero and zero otherwise.
    mapping(address => uint256) public override gaugeRates;

    // Base AC emission rate for plus gauges. It's equal to the emission rate when there is no plus boosting,
    // i.e. total plus staked <= PLUS_BOOST_THRESHOLD
    uint256 public basePlusRate;
    // Boost for all plus gauges. 1 when there is no plus boosting, i.e.total plus staked <= PLUS_BOOST_THRESHOLD
    uint256 public plusBoost;
    // Global AC emission rate, including both plus and non-plus gauge.
    uint256 public totalRate;
    // Last time the checkpoint is called
    uint256 public lastCheckpoint;
    // Total amount of AC rewarded until the latest checkpoint
    uint256 public lastTotalReward;
    // Total amount of AC claimed so far. totalReward - totalClaimed is the minimum AC balance that should be kept.
    uint256 public totalClaimed;
    // Mapping: Gauge address => Mapping: User address => Total claimed amount for this user in this gauge
    mapping(address => mapping(address => uint256)) public override claimed;
    // Mapping: User address => Timestamp of the last claim
    mapping(address => uint256) public override lastClaim;

    /**
     * @dev Initializes the gauge controller.
     * @param _reward AC token address.
     * @param _plusRewardPerDay Amount of AC rewarded per day for plus gauges if there is no plus boost.
     */
    function initialize(address _reward, uint256 _plusRewardPerDay) public initializer {        
        governance = msg.sender;
        treasury = msg.sender;
        reward = _reward;
        // Base rate is in WAD
        basePlusRate = _plusRewardPerDay.mul(WAD).div(DAY);
        plusBoost = WAD;
        lastCheckpoint = block.timestamp;
    }

    /**
     * @dev Computes log2(num). Result in WAD.
     * Credit: https://medium.com/coinmonks/math-in-solidity-part-5-exponent-and-logarithm-9aef8515136e
     */
    function _log2(uint256 num) internal pure returns (uint256) {
        uint256 msb = 0;
        uint256 xc = num;
        if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }    // 2**128
        if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore
    
        uint256 lsb = 0;
        uint256 ux = num << uint256 (127 - msb);
        for (uint256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
          ux *= ux;
          uint256 b = ux >> 255;
          ux >>= 127 + b;
          lsb += bit * b;
        }
    
        return msb * 10**18 + (lsb * 10**18 >> 64);
    }

    /**
     * @dev Computes log10(num). Result in WAD.
     * Credit: https://medium.com/coinmonks/math-in-solidity-part-5-exponent-and-logarithm-9aef8515136e
     */
    function _log10(uint256 num) internal pure returns (uint256) {
        return _log2(num).mul(LOG_10_2).div(WAD);
    }

    /**
     * @dev Most important function of the gauge controller. Recompute total AC emission rate
     * as well as AC emission rate per liquidity guage.
     * Anyone can call this function so that if the liquidity gauge is exploited by users with short-term
     * large amount of minting, others can restore to the correct mining paramters.
     */
    function checkpoint() public {
        // Loads the gauge list for better performance
        address[] memory _gauges = gauges;
        // The total amount of plus tokens staked
        uint256 _totalPlus = 0;
        // The total weighted amount of plus tokens staked
        uint256 _totalWeightedPlus = 0;
        // Amount of plus token staked in each gauge
        uint256[] memory _gaugePlus = new uint256[](_gauges.length);
        // Weighted amount of plus token staked in each gauge
        uint256[] memory _gaugeWeightedPlus = new uint256[](_gauges.length);
        uint256 _plusBoost = WAD;

        for (uint256 i = 0; i < _gauges.length; i++) {
            // Don't count if it's non-plus gauge
            if (!gaugeData[_gauges[i]].isPlus) continue;

            // Liquidity gauge token and staked token is 1:1
            // Total plus is used to compute boost
            address _staked = IGauge(_gauges[i]).token();
            // Rebase once to get an accurate result
            IPlus(_staked).rebase();
            _gaugePlus[i] = IGauge(_gauges[i]).totalStaked();
            _totalPlus = _totalPlus.add(_gaugePlus[i]);

            // Weighted plus is used to compute rate allocation
            _gaugeWeightedPlus[i] = _gaugePlus[i].mul(gaugeData[_gauges[i]].weight);
            _totalWeightedPlus = _totalWeightedPlus.add(_gaugeWeightedPlus[i]);
        }

        // Computes the AC emission per plus. The AC emission rate is determined by total weighted plus staked.
        uint256 _ratePerPlus = 0;
        // Total AC emission rate for plus gauges is zero if the weighted total plus staked is zero!
        if (_totalWeightedPlus > 0) {
            // Plus boost is applied when more than 100 plus are staked
            if (_totalPlus > PLUS_BOOST_THRESHOLD) {
                // rate = baseRate * (log total - 1)
                // Minus 19 since the TVL is in WAD, so -1 - 18 = -19
                _plusBoost = _log10(_totalPlus) - 19 * WAD;
            }

            // Both plus boot and total weighted plus are in WAD so it cancels out
            // Therefore, _ratePerPlus is still in WAD
            _ratePerPlus = basePlusRate.mul(_plusBoost).div(_totalWeightedPlus);
        }

        // Allocates AC emission rates for each liquidity gauge
        uint256 _oldTotalRate = totalRate;
        uint256 _totalRate;
        uint256[] memory _gaugeRates = new uint256[](_gauges.length);
        for (uint256 i = 0; i < _gauges.length; i++) {
            if (gaugeData[_gauges[i]].isPlus) {
                // gauge weighted plus is in WAD
                // _ratePerPlus is also in WAD
                // so block.timestamp gauge rate is in WAD
                _gaugeRates[i] = _gaugeWeightedPlus[i].mul(_ratePerPlus).div(WAD);
            } else {
                // AC emission rate for non-plus gauge is fixed and set by the governance.
                // However, if no token is staked, the gauge rate is zero.
                _gaugeRates[i] = IERC20Upgradeable(_gauges[i]).totalSupply() == 0 ? 0 : gaugeData[_gauges[i]].rate;
            }
            gaugeRates[_gauges[i]] = _gaugeRates[i];
            _totalRate = _totalRate.add(_gaugeRates[i]);
        }

        // Checkpoints gauge controller
        lastTotalReward = lastTotalReward.add(_oldTotalRate.mul(block.timestamp.sub(lastCheckpoint)).div(WAD));
        lastCheckpoint = block.timestamp;
        totalRate = _totalRate;
        plusBoost = _plusBoost;

        // Checkpoints each gauge to consume the latest rate
        // We trigger gauge checkpoint after all parameters are updated
        for (uint256 i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).checkpoint();
        }

        emit Checkpointed(_oldTotalRate, _totalRate, _totalPlus, _ratePerPlus, _gauges, _gaugeRates);
    }

    /**
     * @dev Claims rewards for a user. Only the liquidity gauge can call this function.
     * @param _account Address of the user to claim reward.
     * @param _receiver Address that receives the claimed reward
     * @param _amount Amount of AC to claim
     */
    function claim(address _account, address _receiver, uint256 _amount) external override {
        require(gaugeData[msg.sender].isSupported, "not gauge");

        totalClaimed = totalClaimed.add(_amount);
        claimed[msg.sender][_account] = claimed[msg.sender][_account].add(_amount);
        lastClaim[msg.sender] = block.timestamp;
        IERC20Upgradeable(reward).safeTransfer(_receiver, _amount);

        emit RewardClaimed(msg.sender, _account, _receiver, _amount);
    }

    /**
     * @dev Return the total amount of rewards generated so far.
     */
    function totalReward() public view returns (uint256) {
        return lastTotalReward.add(totalRate.mul(block.timestamp.sub(lastCheckpoint)).div(WAD));
    }

    /**
     * @dev Returns the total amount of rewards that can be claimed by user until block.timestamp.
     * It can be seen as minimum amount of reward tokens should be buffered in the gauge controller.
     */
    function claimable() external view returns (uint256) {
        return totalReward().sub(totalClaimed);
    }

    /**
     * @dev Returns the total number of gauges.
     */
    function gaugeSize() public view returns (uint256) {
        return gauges.length;
    }

    /**
     * @dev Donate the gauge fee. Only liqudity gauge can call this function.
     * @param _token Address of the donated token.
     */
    function donate(address _token) external override {
        require(gaugeData[msg.sender].isSupported, "not gauge");

        uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this));
        if (_balance == 0)  return;
        address _staked = IGauge(msg.sender).token();

        if (gaugeData[msg.sender].isPlus && _token == _staked) {
            // If this is a plus gauge and the donated token is the gauge staked token,
            // then the gauge is donating the plus token!
            // For plus token, donate it to all holders
            IPlus(_token).donate(_balance);
        } else {
            // Otherwise, send to treasury for future process
            IERC20Upgradeable(_token).safeTransfer(treasury, _balance);
        }
    }

    /*********************************************
     *
     *    Governance methods
     *
     **********************************************/
    
    function _checkGovernance() internal view {
        require(msg.sender == governance, "not governance");
    }

    modifier onlyGovernance() {
        _checkGovernance();
        _;
    }

    /**
     * @dev Updates governance. Only governance can update governance.
     */
    function setGovernance(address _governance) external onlyGovernance {
        address _oldGovernance = governance;
        governance = _governance;
        emit GovernanceUpdated(_oldGovernance, _governance);
    }

    /**
     * @dev Updates claimer. Only governance can update claimers.
     */
    function setClaimer(address _account, bool _allowed) external onlyGovernance {
        claimers[_account] = _allowed;
        emit ClaimerUpdated(_account, _allowed);
    }

    /**
     * @dev Updates the AC emission base rate for plus gauges. Only governance can update the base rate.
     */
    function setPlusReward(uint256 _plusRewardPerDay) external onlyGovernance {
        uint256 _oldRate = basePlusRate;
        // Base rate is in WAD
        basePlusRate = _plusRewardPerDay.mul(WAD).div(DAY);
        // Need to checkpoint with the base rate update!
        checkpoint();

        emit BasePlusRateUpdated(_oldRate, basePlusRate);
    }

    /**
     * @dev Updates the treasury.
     */
    function setTreasury(address _treasury) external onlyGovernance {
        require(_treasury != address(0x0), "treasury not set");
        address _oldTreasury = treasury;
        treasury = _treasury;

        emit TreasuryUpdated(_oldTreasury, _treasury);
    }

    /**
     * @dev Adds a new liquidity gauge to the gauge controller. Only governance can add new gauge.
     * @param _gauge The new liquidity gauge to add.
     * @param _plus Whether it's a plus gauge.
     * @param _weight Weight of the liquidity gauge. Useful for plus gauges only.
     * @param _rewardPerDay AC reward for the gauge per day. Useful for non-plus gauges only.
     */
    function addGauge(address _gauge, bool _plus, uint256 _weight, uint256 _rewardPerDay) external onlyGovernance {
        require(_gauge != address(0x0), "gauge not set");
        require(!gaugeData[_gauge].isSupported, "gauge exist");

        uint256 _rate = _rewardPerDay.mul(WAD).div(DAY);
        gauges.push(_gauge);
        gaugeData[_gauge] = Gauge({
            isSupported: true,
            isPlus: _plus,
            weight: _weight,
            // Reward rate is in WAD
            rate: _rate
        });

        // Need to checkpoint with the new token!
        checkpoint();

        emit GaugeAdded(_gauge, _plus, _weight, _rate);
    }

    /**
     * @dev Removes a liquidity gauge from gauge controller. Only governance can remove a plus token.
     * @param _gauge The liquidity gauge to remove from gauge controller.
     */
    function removeGauge(address _gauge) external onlyGovernance {
        require(_gauge != address(0x0), "gauge not set");
        require(gaugeData[_gauge].isSupported, "gauge not exist");

        uint256 _gaugeSize = gauges.length;
        uint256 _gaugeIndex = _gaugeSize;
        for (uint256 i = 0; i < _gaugeSize; i++) {
            if (gauges[i] == _gauge) {
                _gaugeIndex = i;
                break;
            }
        }
        // We must have found the gauge!
        assert(_gaugeIndex < _gaugeSize);

        gauges[_gaugeIndex] = gauges[_gaugeSize - 1];
        gauges.pop();
        delete gaugeData[_gauge];

        // Need to checkpoint with the token removed!
        checkpoint();

        emit GaugeRemoved(_gauge);
    }

    /**
     * @dev Updates the weight of the liquidity gauge.
     * @param _gauge Address of the liquidity gauge to update.
     * @param _weight New weight of the liquidity gauge.
     * @param _rewardPerDay AC reward for the gauge per day
     */
    function updateGauge(address _gauge, uint256 _weight, uint256 _rewardPerDay) external onlyGovernance {
        require(gaugeData[_gauge].isSupported, "gauge not exist");

        uint256 _oldWeight = gaugeData[_gauge].weight;
        uint256 _oldRate = gaugeData[_gauge].rate;

        uint256 _rate = _rewardPerDay.mul(WAD).div(DAY);
        gaugeData[_gauge].weight = _weight;
        gaugeData[_gauge].rate = _rate;

        // Need to checkpoint with the token removed!
        checkpoint();

        emit GaugeUpdated(_gauge, _oldWeight, _weight, _oldRate, _rate);
    }

    /**
     * @dev Used to salvage any ETH deposited to gauge controller by mistake. Only governance can salvage ETH.
     * The salvaged ETH is transferred to treasury for futher operation.
     */
    function salvage() external onlyGovernance {
        uint256 _amount = address(this).balance;
        address payable _target = payable(treasury);
        (bool success, ) = _target.call{value: _amount}(new bytes(0));
        require(success, 'ETH salvage failed');
    }

    /**
     * @dev Used to salvage any token deposited to gauge controller by mistake. Only governance can salvage token.
     * The salvaged token is transferred to treasury for futhuer operation.
     * Note: The gauge controller is not expected to hold any token, so any token is salvageable!
     * @param _token Address of the token to salvage.
     */
    function salvageToken(address _token) external onlyGovernance {
        IERC20Upgradeable _target = IERC20Upgradeable(_token);
        _target.safeTransfer(treasury, _target.balanceOf(address(this)));
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
 * @title Interface for plus token.
 * Plus token is a value pegged ERC20 token which provides global interest to all holders.
 */
interface IPlus {
    /**
     * @dev Returns the governance address.
     */
    function governance() external view returns (address);

    /**
     * @dev Returns whether the account is a strategist.
     */
    function strategists(address _account) external view returns (bool);

    /**
     * @dev Returns the treasury address.
     */
    function treasury() external view returns (address);

    /**
     * @dev Accrues interest to increase index.
     */
    function rebase() external;

    /**
     * @dev Returns the total value of the plus token in terms of the peg value.
     */
    function totalUnderlying() external view returns (uint256);

    /**
     * @dev Allows anyone to donate their plus asset to all other holders.
     * @param _amount Amount of plus token to donate.
     */
    function donate(uint256 _amount) external;
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

