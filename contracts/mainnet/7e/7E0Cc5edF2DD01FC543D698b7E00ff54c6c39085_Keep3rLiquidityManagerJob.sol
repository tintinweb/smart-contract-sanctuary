// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@lbertenasco/contract-utils/contracts/abstract/UtilsReady.sol';
import '@lbertenasco/contract-utils/contracts/keep3r/Keep3rAbstract.sol';

import '../keep3r-liquidity-manager/Keep3rLiquidityManagerWork.sol';
import './IKeep3rLiquidityManagerJob.sol';

contract Keep3rLiquidityManagerJob is UtilsReady, Keep3r, IKeep3rLiquidityManagerJob {
  using SafeMath for uint256;

  uint256 public constant PRECISION = 1_000;
  uint256 public constant MAX_REWARD_MULTIPLIER = 1 * PRECISION; // 1x max reward multiplier
  uint256 public override rewardMultiplier = MAX_REWARD_MULTIPLIER;

  address public override keep3rLiquidityManager;

  constructor(
    address _keep3rLiquidityManager,
    address _keep3r,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) public UtilsReady() Keep3r(_keep3r) {
    _setKeep3rRequirements(_bond, _minBond, _earned, _age, _onlyEOA);
    _setKeep3rLiquidityManager(_keep3rLiquidityManager);
  }

  // Keep3r Setters
  function setKeep3r(address _keep3r) external override onlyGovernor {
    _setKeep3r(_keep3r);
  }

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) external override onlyGovernor {
    _setKeep3rRequirements(_bond, _minBond, _earned, _age, _onlyEOA);
  }

  function setRewardMultiplier(uint256 _rewardMultiplier) external override onlyGovernor {
    _setRewardMultiplier(_rewardMultiplier);
    emit SetRewardMultiplier(_rewardMultiplier);
  }

  function _setRewardMultiplier(uint256 _rewardMultiplier) internal {
    require(_rewardMultiplier <= MAX_REWARD_MULTIPLIER, 'Keep3rLiquidityManagerJob::set-reward-multiplier:multiplier-exceeds-max');
    rewardMultiplier = _rewardMultiplier;
  }

  function setKeep3rLiquidityManager(address _keep3rLiquidityManager) external override onlyGovernor {
    _setKeep3rLiquidityManager(_keep3rLiquidityManager);
    emit SetKeep3rLiquidityManager(_keep3rLiquidityManager);
  }

  function _setKeep3rLiquidityManager(address _keep3rLiquidityManager) internal {
    require(_keep3rLiquidityManager != address(0), 'Keep3rLiquidityManagerJob::set-keep3r-liqudiity-manager:not-address-0');
    keep3rLiquidityManager = _keep3rLiquidityManager;
  }

  // Setters
  function workable(address _job) external override notPaused returns (bool) {
    return _workable(_job);
  }

  function _workable(address _job) internal view returns (bool) {
    return IKeep3rLiquidityManagerWork(keep3rLiquidityManager).workable(_job);
  }

  //Getters
  function jobs() public view override returns (address[] memory _jobs) {
    return IKeep3rLiquidityManagerJobsLiquidityHandler(keep3rLiquidityManager).jobs();
  }

  // Keeper actions
  function _work(address _job, bool _workForTokens) internal returns (uint256 _credits) {
    uint256 _initialGas = gasleft();

    require(_workable(_job), 'Keep3rLiquidityManagerJob::work:not-workable');

    _keep3rLiquidityManagerWork(_job);

    _credits = _calculateCredits(_initialGas);

    emit Worked(_job, msg.sender, _credits, _workForTokens);
  }

  function work(address _job) external override returns (uint256 _credits) {
    return workForBond(_job);
  }

  function workForBond(address _job) public override notPaused onlyKeeper returns (uint256 _credits) {
    _credits = _work(_job, false);
    _paysKeeperAmount(msg.sender, _credits);
  }

  function workForTokens(address _job) external override notPaused onlyKeeper returns (uint256 _credits) {
    _credits = _work(_job, true);
    _paysKeeperInTokens(msg.sender, _credits);
  }

  function _calculateCredits(uint256 _initialGas) internal view returns (uint256 _credits) {
    // Gets default credits from KP3R_Helper and applies job reward multiplier
    return _getQuoteLimit(_initialGas).mul(rewardMultiplier).div(PRECISION);
  }

  // Mechanics keeper bypass
  function forceWork(address _job) external override onlyGovernor {
    _keep3rLiquidityManagerWork(_job);
    emit ForceWorked(_job);
  }

  function _keep3rLiquidityManagerWork(address _job) internal {
    IKeep3rLiquidityManagerWork(keep3rLiquidityManager).work(_job);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../utils/Governable.sol';
import '../utils/CollectableDust.sol';
import '../utils/Pausable.sol';

abstract
contract UtilsReady is Governable, CollectableDust, Pausable {

  constructor() public Governable(msg.sender) {
  }

  // Governable: restricted-access
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }

  // Collectable Dust: restricted-access
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override virtual onlyGovernor {
    _sendDust(_to, _token, _amount);
  }

  // Pausable: restricted-access
  function pause(bool _paused) external override onlyGovernor {
    _pause(_paused);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../../interfaces/keep3r/IKeep3rV1.sol';
import '../../interfaces/keep3r/IKeep3r.sol';

abstract
contract Keep3r is IKeep3r {
  using SafeMath for uint256;

  IKeep3rV1 internal _Keep3r;
  address public bond;
  uint256 public minBond;
  uint256 public earned;
  uint256 public age;
  bool public onlyEOA;

  constructor(address _keep3r) public {
    _setKeep3r(_keep3r);
  }

  // Setters
  function _setKeep3r(address _keep3r) internal {
    _Keep3r = IKeep3rV1(_keep3r);
    emit Keep3rSet(_keep3r);
  }

  function _setKeep3rRequirements(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA) internal {
    bond = _bond;
    minBond = _minBond;
    earned = _earned;
    age = _age;
    onlyEOA = _onlyEOA;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age, _onlyEOA);
  }

  // Modifiers
  // Only checks if caller is a valid keeper, payment should be handled manually
  modifier onlyKeeper() {
    _isKeeper();
    _;
  }

  // view
  function keep3r() external view override returns (address _keep3r) {
    return address(_Keep3r);
  }

  // handles default payment after execution
  modifier paysKeeper() {
    _;
    _paysKeeper(msg.sender);
  }

  // Internal helpers
  function _isKeeper() internal {
    if (onlyEOA) require(msg.sender == tx.origin, "keep3r::isKeeper:keeper-is-not-eoa");
    if (minBond == 0 && earned == 0 && age == 0) {
      // If no custom keeper requirements are set, just evaluate if sender is a registered keeper
      require(_Keep3r.isKeeper(msg.sender), "keep3r::isKeeper:keeper-is-not-registered");
    } else {
      if (bond == address(0)) {
        // Checks for min KP3R, earned and age.
        require(_Keep3r.isMinKeeper(msg.sender, minBond, earned, age), "keep3r::isKeeper:keeper-not-min-requirements");
      } else {
        // Checks for min custom-bond, earned and age.
        require(_Keep3r.isBondedKeeper(msg.sender, bond, minBond, earned, age), "keep3r::isKeeper:keeper-not-custom-min-requirements");
      }
    }
  }

  function _getQuoteLimit(uint256 _gasUsed) internal view returns (uint256 _credits) {
    return _Keep3r.KPRH().getQuoteLimit(_gasUsed.sub(gasleft()));
  }

  // pays in bonded KP3R after execution
  function _paysKeeper(address _keeper) internal {
    _Keep3r.worked(_keeper);
  }
  // pays _amount in KP3R after execution
  function _paysKeeperInTokens(address _keeper, uint256 _amount) internal {
    _Keep3r.receipt(address(_Keep3r), _keeper, _amount);
  }
  // pays _amount in bonded KP3R after execution
  function _paysKeeperAmount(address _keeper, uint256 _amount) internal {
    _Keep3r.workReceipt(_keeper, _amount);
  }
  // pays _amount in _credit after execution
  function _paysKeeperCredit(address _credit, address _keeper, uint256 _amount) internal {
    _Keep3r.receipt(_credit, _keeper, _amount);
  }
  // pays _amount in ETH after execution
  function _paysKeeperEth(address _keeper, uint256 _amount) internal {
    _Keep3r.receiptETH(_keeper, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './Keep3rLiquidityManagerEscrowsHandler.sol';
import './Keep3rLiquidityManagerJobHandler.sol';
import './Keep3rLiquidityManagerJobsLiquidityHandler.sol';
import './Keep3rLiquidityManagerParameters.sol';
import './Keep3rLiquidityManagerUserJobsLiquidityHandler.sol';
import './Keep3rLiquidityManagerUserLiquidityHandler.sol';

interface IKeep3rLiquidityManagerWork {
  enum Actions { None, AddLiquidityToJob, ApplyCreditToJob, UnbondLiquidityFromJob, RemoveLiquidityFromJob }
  enum Steps { NotStarted, LiquidityAdded, CreditApplied, UnbondingLiquidity }

  // Actions by Keeper
  event Worked(address indexed _job);
  // Actions forced by governor
  event ForceWorked(address indexed _job);

  function getNextAction(address _job) external view returns (address _escrow, Actions _action);

  function workable(address _job) external view returns (bool);

  function jobEscrowStep(address _job, address _escrow) external view returns (Steps _step);

  function jobEscrowTimestamp(address _job, address _escrow) external view returns (uint256 _timestamp);

  function work(address _job) external;

  function forceWork(address _job) external;
}

abstract contract Keep3rLiquidityManagerWork is Keep3rLiquidityManagerUserJobsLiquidityHandler, IKeep3rLiquidityManagerWork {
  // job => escrow => Steps
  mapping(address => mapping(address => Steps)) public override jobEscrowStep;
  // job => escrow => timestamp
  mapping(address => mapping(address => uint256)) public override jobEscrowTimestamp;

  // Since all liquidity behaves the same, we just need to check one of them
  function getNextAction(address _job) public view override returns (address _escrow, Actions _action) {
    require(_jobLiquidities[_job].length() > 0, 'Keep3rLiquidityManager::getNextAction:job-has-no-liquidity');

    Steps _escrow1Step = jobEscrowStep[_job][escrow1];
    Steps _escrow2Step = jobEscrowStep[_job][escrow2];

    // Init (add liquidity to escrow1)
    if (_escrow1Step == Steps.NotStarted && _escrow2Step == Steps.NotStarted) {
      return (escrow1, Actions.AddLiquidityToJob);
    }

    // Init (add liquidity to NotStarted escrow)
    if ((_escrow1Step == Steps.NotStarted || _escrow2Step == Steps.NotStarted) && _jobHasDesiredLiquidities(_job)) {
      _escrow = _escrow1Step == Steps.NotStarted ? escrow1 : escrow2;
      address _otherEscrow = _escrow == escrow1 ? escrow2 : escrow1;

      // on _otherEscrow step CreditApplied
      if (jobEscrowStep[_job][_otherEscrow] == Steps.CreditApplied) {
        // make sure to wait 14 days
        if (block.timestamp > jobEscrowTimestamp[_job][_otherEscrow].add(14 days)) {
          // add liquidity to NotStarted _escrow
          return (_escrow, Actions.AddLiquidityToJob);
        }
      }

      // on _otherEscrow step UnbondingLiquidity add liquidity
      if (jobEscrowStep[_job][_otherEscrow] == Steps.UnbondingLiquidity) {
        // add liquidity to NotStarted _escrow
        return (_escrow, Actions.AddLiquidityToJob);
      }
    }

    // can return None, ApplyCreditToJob and RemoveLiquidityFromJob.
    _action = _getNextActionOnStep(escrow1, _escrow1Step, _escrow2Step, _job);
    if (_action != Actions.None) return (escrow1, _action);

    // if escrow1 next actions is None we need to check escrow2

    _action = _getNextActionOnStep(escrow2, _escrow2Step, _escrow1Step, _job);
    if (_action != Actions.None) return (escrow2, _action);

    return (address(0), Actions.None);
  }

  function _jobHasDesiredLiquidities(address _job) internal view returns (bool) {
    // search for desired liquidity > 0 on all job liquidities
    for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
      if (jobLiquidityDesiredAmount[_job][_jobLiquidities[_job].at(i)] > 0) {
        return true;
      }
    }
    return false;
  }

  function _getNextActionOnStep(
    address _escrow,
    Steps _escrowStep,
    Steps _otherEscrowStep,
    address _job
  ) internal view returns (Actions) {
    // after adding liquidity wait 3 days to apply
    if (_escrowStep == Steps.LiquidityAdded) {
      // The escrow with liquidityAmount is the one to call applyCreditToJob, the other should call unbondLiquidityFromJob
      if (block.timestamp > jobEscrowTimestamp[_job][_escrow].add(3 days)) {
        return Actions.ApplyCreditToJob;
      }
      return Actions.None;
    }

    // after applying credits wait 17 days to unbond (only happens when other escrow is on NotStarted [desired liquidity = 0])
    // makes sure otherEscrowStep is still notStarted (it can be liquidityAdded)
    if (_escrowStep == Steps.CreditApplied) {
      if (_otherEscrowStep == Steps.NotStarted && block.timestamp > jobEscrowTimestamp[_job][_escrow].add(17 days)) {
        return Actions.UnbondLiquidityFromJob;
      }
      return Actions.None;
    }

    // after unbonding liquidity wait 14 days to remove
    if (_escrowStep == Steps.UnbondingLiquidity) {
      if (block.timestamp > jobEscrowTimestamp[_job][_escrow].add(14 days)) {
        return Actions.RemoveLiquidityFromJob;
      }
      return Actions.None;
    }

    // for steps: NotStarted. return Actions.None
    return Actions.None;
  }

  function workable(address _job) public view override returns (bool) {
    (, Actions _action) = getNextAction(_job);
    return _workable(_action);
  }

  function _workable(Actions _action) internal pure returns (bool) {
    return (_action != Actions.None);
  }

  function _work(
    address _escrow,
    Actions _action,
    address _job
  ) internal {
    // AddLiquidityToJob
    if (_action == Actions.AddLiquidityToJob) {
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        address _liquidity = _jobLiquidities[_job].at(i);
        uint256 _escrowAmount = jobLiquidityDesiredAmount[_job][_liquidity].div(2);
        IERC20(_liquidity).approve(_escrow, _escrowAmount);
        IKeep3rEscrow(_escrow).deposit(_liquidity, _escrowAmount);
        _addLiquidityToJob(_escrow, _liquidity, _job, _escrowAmount);
        jobEscrowStep[_job][_escrow] = Steps.LiquidityAdded;
        jobEscrowTimestamp[_job][_escrow] = block.timestamp;
      }

      // ApplyCreditToJob (_unbondLiquidityFromJob, _removeLiquidityFromJob, _addLiquidityToJob)
    } else if (_action == Actions.ApplyCreditToJob) {
      address _otherEscrow = _escrow == escrow1 ? escrow2 : escrow1;

      // ALWAYS FIRST: Should try to unbondLiquidityFromJob from _otherEscrow
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        address _liquidity = _jobLiquidities[_job].at(i);
        uint256 _liquidityProvided = IKeep3rV1(keep3rV1).liquidityProvided(_otherEscrow, _liquidity, _job);
        if (_liquidityProvided > 0) {
          _unbondLiquidityFromJob(_otherEscrow, _liquidity, _job, _liquidityProvided);
          jobEscrowStep[_job][_otherEscrow] = Steps.UnbondingLiquidity;
          jobEscrowTimestamp[_job][_otherEscrow] = block.timestamp;
        }
      }
      // Run applyCreditToJob
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        _applyCreditToJob(_escrow, _jobLiquidities[_job].at(i), _job);
        jobEscrowStep[_job][_escrow] = Steps.CreditApplied;
        jobEscrowTimestamp[_job][_escrow] = block.timestamp;
      }

      // UnbondLiquidityFromJob
    } else if (_action == Actions.UnbondLiquidityFromJob) {
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        address _liquidity = _jobLiquidities[_job].at(i);

        uint256 _liquidityProvided = IKeep3rV1(keep3rV1).liquidityProvided(_escrow, _liquidity, _job);
        if (_liquidityProvided > 0) {
          _unbondLiquidityFromJob(_escrow, _liquidity, _job, _liquidityProvided);
          jobEscrowStep[_job][_escrow] = Steps.UnbondingLiquidity;
          jobEscrowTimestamp[_job][_escrow] = block.timestamp;
        }
      }

      // RemoveLiquidityFromJob
    } else if (_action == Actions.RemoveLiquidityFromJob) {
      // Clone _jobLiquidities so we can remove unused without breaking the loop
      address[] memory _jobLiquiditiesClone = new address[](_jobLiquidities[_job].length());
      for (uint256 i = 0; i < _jobLiquidities[_job].length(); i++) {
        _jobLiquiditiesClone[i] = _jobLiquidities[_job].at(i);
      }

      for (uint256 i = 0; i < _jobLiquiditiesClone.length; i++) {
        address _liquidity = _jobLiquiditiesClone[i];
        // remove liquidity
        uint256 _amount = _removeLiquidityFromJob(_escrow, _liquidity, _job);
        jobEscrowStep[_job][_escrow] = Steps.NotStarted;
        jobEscrowTimestamp[_job][_escrow] = block.timestamp;

        // increase jobCycle
        jobCycle[_job] = jobCycle[_job].add(1);

        uint256 _escrowAmount = jobLiquidityDesiredAmount[_job][_liquidity].div(2);
        // check if a withdraw or deposit is needed
        if (_amount > _escrowAmount) {
          IKeep3rEscrow(_escrow).withdraw(_liquidity, _amount.sub(_escrowAmount));
        } else if (_amount < _escrowAmount) {
          IERC20(_liquidity).approve(_escrow, _escrowAmount.sub(_amount));
          IKeep3rEscrow(_escrow).deposit(_liquidity, _escrowAmount.sub(_amount));
        }

        // add liquidity
        if (_escrowAmount > 0) {
          _addLiquidityToJob(_escrow, _liquidity, _job, _escrowAmount);
          jobEscrowStep[_job][_escrow] = Steps.LiquidityAdded;
          jobEscrowTimestamp[_job][_escrow] = block.timestamp;
        }

        uint256 _liquidityInUse =
          IKeep3rEscrow(escrow1).liquidityTotalAmount(_liquidity).add(IKeep3rEscrow(escrow2).liquidityTotalAmount(_liquidity));
        if (_liquidityInUse == 0) _removeLPFromJob(_job, _liquidity);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './IKeep3rJob.sol';

interface IKeep3rLiquidityManagerJob is IKeep3rJob {
  event SetKeep3rLiquidityManager(address _keep3rLiquidityManager);

  // Actions by Keeper
  event Worked(address _job, address _keeper, uint256 _credits, bool _workForTokens);

  // Actions forced by Governor
  event ForceWorked(address _job);

  // Setters
  function setKeep3rLiquidityManager(address _keep3rLiquidityManager) external;

  // Getters
  function keep3rLiquidityManager() external returns (address _keep3rLiquidityManager);

  function jobs() external view returns (address[] memory _jobs);

  function workable(address _job) external returns (bool);

  // Keeper actions
  function work(address _job) external returns (uint256 _credits);

  function workForBond(address _job) external returns (uint256 _credits);

  function workForTokens(address _job) external returns (uint256 _credits);

  // Governor keeper bypass
  function forceWork(address _job) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../../interfaces/utils/IGovernable.sol';

abstract
contract Governable is IGovernable {
  address public override governor;
  address public override pendingGovernor;

  constructor(address _governor) public {
    require(_governor != address(0), 'governable/governor-should-not-be-zero-address');
    governor = _governor;
  }

  function _setPendingGovernor(address _pendingGovernor) internal {
    require(_pendingGovernor != address(0), 'governable/pending-governor-should-not-be-zero-addres');
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(_pendingGovernor);
  }

  function _acceptGovernor() internal {
    governor = pendingGovernor;
    pendingGovernor = address(0);
    emit GovernorAccepted();
  }

  function isGovernor(address _account) public view override returns (bool _isGovernor) {
    return _account == governor;
  }

  modifier onlyGovernor {
    require(isGovernor(msg.sender), 'governable/only-governor');
    _;
  }

  modifier onlyPendingGovernor {
    require(msg.sender == pendingGovernor, 'governable/only-pending-governor');
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import '../../interfaces/utils/ICollectableDust.sol';

abstract
contract CollectableDust is ICollectableDust {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  EnumerableSet.AddressSet internal protocolTokens;

  constructor() public {}

  function _addProtocolToken(address _token) internal {
    require(!protocolTokens.contains(_token), 'collectable-dust/token-is-part-of-the-protocol');
    protocolTokens.add(_token);
  }

  function _removeProtocolToken(address _token) internal {
    require(protocolTokens.contains(_token), 'collectable-dust/token-not-part-of-the-protocol');
    protocolTokens.remove(_token);
  }

  function _sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    require(_to != address(0), 'collectable-dust/cant-send-dust-to-zero-address');
    require(!protocolTokens.contains(_token), 'collectable-dust/token-is-part-of-the-protocol');
    if (_token == ETH_ADDRESS) {
      payable(_to).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
    emit DustSent(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../../interfaces/utils/IPausable.sol';

abstract
contract Pausable is IPausable {
  bool public paused;

  constructor() public {}
  
  modifier notPaused() {
    require(!paused, 'paused');
    _;
  }

  function _pause(bool _paused) internal {
    require(paused != _paused, 'no-change');
    paused = _paused;
    emit Paused(_paused);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IGovernable {
  event PendingGovernorSet(address pendingGovernor);
  event GovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;
  function acceptGovernor() external;

  function governor() external view returns (address _governor);
  function pendingGovernor() external view returns (address _pendingGovernor);

  function isGovernor(address _account) external view returns (bool _isGovernor);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
pragma solidity 0.6.12;

interface ICollectableDust {
  event DustSent(address _to, address token, uint256 amount);

  function sendDust(address _to, address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPausable {
  event Paused(bool _paused);

  function pause(bool _paused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IKeep3rV1Helper.sol";

interface IKeep3rV1 is IERC20 {
    function name() external returns (string memory);
    function KPRH() external view returns (IKeep3rV1Helper);

    function isKeeper(address _keeper) external returns (bool);
    function isMinKeeper(address _keeper, uint256 _minBond, uint256 _earned, uint256 _age) external returns (bool);
    function isBondedKeeper(address _keeper, address bond, uint256 _minBond, uint256 _earned, uint256 _age) external returns (bool);
    function addKPRCredit(address _job, uint256 _amount) external;
    function addJob(address _job) external;
    function removeJob(address _job) external;
    function addVotes(address voter, uint256 amount) external;
    function removeVotes(address voter, uint256 amount) external;

    function worked(address _keeper) external;
    function workReceipt(address _keeper, uint256 _amount) external;
    function receipt(address credit, address _keeper, uint256 _amount) external;
    function receiptETH(address _keeper, uint256 _amount) external;

    function addLiquidityToJob(address liquidity, address job, uint amount) external;
    function applyCreditToJob(address provider, address liquidity, address job) external;
    function unbondLiquidityFromJob(address liquidity, address job, uint amount) external;
    function removeLiquidityFromJob(address liquidity, address job) external;

    function jobs(address _job) external view returns (bool);
    function jobList(uint256 _index) external view returns (address _job);
    function credits(address _job, address _credit) external view returns (uint256 _amount);

    function liquidityAccepted(address _liquidity) external view returns (bool);

    function liquidityProvided(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityApplied(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityAmount(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    
    function liquidityUnbonding(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);
    function liquidityAmountsUnbonding(address _provider, address _liquidity, address _job) external view returns (uint256 _amount);

    function bond(address bonding, uint256 amount) external;
    function activate(address bonding) external;
    function unbond(address bonding, uint256 amount) external;
    function withdraw(address bonding) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
interface IKeep3r {
    event Keep3rSet(address _keep3r);
    event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA);
    
    function keep3r() external view returns (address _keep3r);

    function setKeep3r(address _keep3r) external;
    function setKeep3rRequirements(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IKeep3rV1Helper {
    function quote(uint256 eth) external view returns (uint256);

    function getFastGas() external view returns (uint256);

    function bonds(address keeper) external view returns (uint256);

    function getQuoteLimit(uint256 gasUsed) external view returns (uint256);

    function getQuoteLimitFor(address origin, uint256 gasUsed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@lbertenasco/contract-utils/interfaces/utils/IGovernable.sol';
import '@lbertenasco/contract-utils/interfaces/utils/ICollectableDust.sol';

import '../escrow/Keep3rEscrow.sol';

interface IKeep3rLiquidityManagerEscrowsHandler {
  event Escrow1Set(address _escrow1);

  event Escrow2Set(address _escrow2);

  function escrow1() external view returns (address _escrow1);

  function escrow2() external view returns (address _escrow2);

  function isValidEscrow(address _escrow) external view returns (bool);

  function addLiquidityToJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function applyCreditToJob(
    address _escrow,
    address _liquidity,
    address _job
  ) external;

  function unbondLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function removeLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job
  ) external returns (uint256 _amount);

  function setPendingGovernorOnEscrow(address _escrow, address _pendingGovernor) external;

  function acceptGovernorOnEscrow(address _escrow) external;

  function sendDustOnEscrow(
    address _escrow,
    address _to,
    address _token,
    uint256 _amount
  ) external;
}

abstract contract Keep3rLiquidityManagerEscrowsHandler is IKeep3rLiquidityManagerEscrowsHandler {
  address public immutable override escrow1;
  address public immutable override escrow2;

  constructor(address _escrow1, address _escrow2) public {
    require(_escrow1 != address(0), 'Keep3rLiquidityManager::zero-address');
    require(_escrow2 != address(0), 'Keep3rLiquidityManager::zero-address');
    escrow1 = _escrow1;
    escrow2 = _escrow2;
  }

  modifier _assertIsValidEscrow(address _escrow) {
    require(isValidEscrow(_escrow), 'Keep3rLiquidityManager::invalid-escrow');
    _;
  }

  function isValidEscrow(address _escrow) public view override returns (bool) {
    return _escrow == escrow1 || _escrow == escrow2;
  }

  function _addLiquidityToJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal _assertIsValidEscrow(_escrow) {
    IKeep3rEscrow(_escrow).addLiquidityToJob(_liquidity, _job, _amount);
  }

  function _applyCreditToJob(
    address _escrow,
    address _liquidity,
    address _job
  ) internal _assertIsValidEscrow(_escrow) {
    IKeep3rEscrow(_escrow).applyCreditToJob(address(_escrow), _liquidity, _job);
  }

  function _unbondLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal _assertIsValidEscrow(_escrow) {
    IKeep3rEscrow(_escrow).unbondLiquidityFromJob(_liquidity, _job, _amount);
  }

  function _removeLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job
  ) internal _assertIsValidEscrow(_escrow) returns (uint256 _amount) {
    return IKeep3rEscrow(_escrow).removeLiquidityFromJob(_liquidity, _job);
  }

  function _setPendingGovernorOnEscrow(address _escrow, address _pendingGovernor) internal _assertIsValidEscrow(_escrow) {
    IGovernable(_escrow).setPendingGovernor(_pendingGovernor);
  }

  function _acceptGovernorOnEscrow(address _escrow) internal _assertIsValidEscrow(_escrow) {
    IGovernable(_escrow).acceptGovernor();
  }

  function _sendDustOnEscrow(
    address _escrow,
    address _to,
    address _token,
    uint256 _amount
  ) internal _assertIsValidEscrow(_escrow) {
    ICollectableDust(_escrow).sendDust(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IKeep3rLiquidityManagerJobHandler {
  function job() external view returns (address _job);

  function setJob(address _job) external;
}

abstract contract Keep3rLiquidityManagerJobHandler is IKeep3rLiquidityManagerJobHandler {
  address public override job;

  function _setJob(address _job) internal {
    job = _job;
  }

  modifier onlyJob() {
    require(msg.sender == job, 'Keep3rLiquidityManagerJobHandler::unauthorized-job');
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';

interface IKeep3rLiquidityManagerJobsLiquidityHandler {
  event JobAdded(address _job);

  event JobRemoved(address _job);

  function jobs() external view returns (address[] memory _jobsList);

  function jobLiquidities(address _job) external view returns (address[] memory _liquiditiesList);

  function jobLiquidityDesiredAmount(address _job, address _liquidity) external view returns (uint256 _amount);
}

abstract contract Keep3rLiquidityManagerJobsLiquidityHandler is IKeep3rLiquidityManagerJobsLiquidityHandler {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  // job[]
  EnumerableSet.AddressSet internal _jobs;
  // job => lp[]
  mapping(address => EnumerableSet.AddressSet) internal _jobLiquidities;
  // job => lp => amount
  mapping(address => mapping(address => uint256)) public override jobLiquidityDesiredAmount;

  function jobs() public view override returns (address[] memory _jobsList) {
    _jobsList = new address[](_jobs.length());
    for (uint256 i; i < _jobs.length(); i++) {
      _jobsList[i] = _jobs.at(i);
    }
  }

  function jobLiquidities(address _job) public view override returns (address[] memory _liquiditiesList) {
    _liquiditiesList = new address[](_jobLiquidities[_job].length());
    for (uint256 i; i < _jobLiquidities[_job].length(); i++) {
      _liquiditiesList[i] = _jobLiquidities[_job].at(i);
    }
  }

  function _addJob(address _job) internal {
    if (_jobs.add(_job)) emit JobAdded(_job);
  }

  function _removeJob(address _job) internal {
    if (_jobs.remove(_job)) emit JobRemoved(_job);
  }

  function _addLPToJob(address _job, address _liquidity) internal {
    _jobLiquidities[_job].add(_liquidity);
    if (_jobLiquidities[_job].length() == 1) _addJob(_job);
  }

  function _removeLPFromJob(address _job, address _liquidity) internal {
    _jobLiquidities[_job].remove(_liquidity);
    if (_jobLiquidities[_job].length() == 0) _removeJob(_job);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@lbertenasco/contract-utils/interfaces/keep3r/IKeep3rV1.sol';

interface IKeep3rLiquidityManagerParameters {
  event Keep3rV1Set(address _keep3rV1);

  function keep3rV1() external view returns (address);
}

abstract contract Keep3rLiquidityManagerParameters is IKeep3rLiquidityManagerParameters {
  address public override keep3rV1;

  constructor(address _keep3rV1) public {
    _setKeep3rV1(_keep3rV1);
  }

  function _setKeep3rV1(address _keep3rV1) internal {
    require(_keep3rV1 != address(0), 'Keep3rLiquidityManager::zero-address');
    keep3rV1 = _keep3rV1;
    emit Keep3rV1Set(_keep3rV1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './Keep3rLiquidityManagerEscrowsHandler.sol';
import './Keep3rLiquidityManagerUserLiquidityHandler.sol';
import './Keep3rLiquidityManagerJobsLiquidityHandler.sol';

interface IKeep3rLiquidityManagerUserJobsLiquidityHandler {
  event LiquidityMinSet(address _liquidity, uint256 _minAmount);
  event LiquidityOfJobSet(address indexed _user, address _liquidity, address _job, uint256 _amount);
  event IdleLiquidityRemovedFromJob(address indexed _user, address _liquidity, address _job, uint256 _amount);

  function liquidityMinAmount(address _liquidity) external view returns (uint256 _minAmount);

  function userJobLiquidityAmount(
    address _user,
    address _job,
    address _liquidity
  ) external view returns (uint256 _amount);

  function userJobLiquidityLockedAmount(
    address _user,
    address _job,
    address _liquidity
  ) external view returns (uint256 _amount);

  function userJobCycle(address _user, address _job) external view returns (uint256 _cycle);

  function jobCycle(address _job) external view returns (uint256 _cycle);

  function setMinAmount(address _liquidity, uint256 _minAmount) external;

  function setJobLiquidityAmount(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function forceRemoveLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job
  ) external;

  function removeIdleLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;
}

abstract contract Keep3rLiquidityManagerUserJobsLiquidityHandler is
  Keep3rLiquidityManagerEscrowsHandler,
  Keep3rLiquidityManagerUserLiquidityHandler,
  Keep3rLiquidityManagerJobsLiquidityHandler,
  IKeep3rLiquidityManagerUserJobsLiquidityHandler
{
  using SafeMath for uint256;

  // lp => minAmount
  mapping(address => uint256) public override liquidityMinAmount;
  // user => job => lp => amount
  mapping(address => mapping(address => mapping(address => uint256))) public override userJobLiquidityAmount;
  // user => job => lp => amount
  mapping(address => mapping(address => mapping(address => uint256))) public override userJobLiquidityLockedAmount;
  // user => job => cycle
  mapping(address => mapping(address => uint256)) public override userJobCycle;
  // job => cycle
  mapping(address => uint256) public override jobCycle;

  function _setMinAmount(address _liquidity, uint256 _minAmount) internal {
    liquidityMinAmount[_liquidity] = _minAmount;
    emit LiquidityMinSet(_liquidity, _minAmount);
  }

  function setJobLiquidityAmount(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external virtual override {
    _setLiquidityToJobOfUser(msg.sender, _liquidity, _job, _amount);
  }

  function removeIdleLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external virtual override {
    _removeIdleLiquidityOfUserFromJob(msg.sender, _liquidity, _job, _amount);
  }

  function _setLiquidityToJobOfUser(
    address _user,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    _amount = _amount.div(2).mul(2); // removes potential decimal dust

    require(_amount != userJobLiquidityAmount[_user][_job][_liquidity], 'Keep3rLiquidityManager::same-liquidity-amount');

    userJobCycle[_user][_job] = jobCycle[_job];

    if (_amount > userJobLiquidityLockedAmount[_user][_job][_liquidity]) {
      _addLiquidityOfUserToJob(_user, _liquidity, _job, _amount.sub(userJobLiquidityAmount[_user][_job][_liquidity]));
    } else {
      _subLiquidityOfUserFromJob(_user, _liquidity, _job, userJobLiquidityAmount[_user][_job][_liquidity].sub(_amount));
    }
    emit LiquidityOfJobSet(_user, _liquidity, _job, _amount);
  }

  function _forceRemoveLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job
  ) internal {
    require(!IKeep3rV1(keep3rV1).jobs(_job), 'Keep3rLiquidityManager::force-remove-liquidity:job-on-keep3r');
    // set liquidity as 0 to force exit on stuck job
    _setLiquidityToJobOfUser(_user, _liquidity, _job, 0);
  }

  function _addLiquidityOfUserToJob(
    address _user,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    require(IKeep3rV1(keep3rV1).jobs(_job), 'Keep3rLiquidityManager::job-not-on-keep3r');
    require(_amount > 0, 'Keep3rLiquidityManager::zero-amount');
    require(_amount <= userLiquidityIdleAmount[_user][_liquidity], 'Keep3rLiquidityManager::no-idle-liquidity-available');
    require(liquidityMinAmount[_liquidity] != 0, 'Keep3rLiquidityManager::liquidity-min-not-set');
    require(
      userJobLiquidityLockedAmount[_user][_job][_liquidity].add(_amount) >= liquidityMinAmount[_liquidity],
      'Keep3rLiquidityManager::locked-amount-not-enough'
    );
    // set liquidity amount on user-job
    userJobLiquidityAmount[_user][_job][_liquidity] = userJobLiquidityAmount[_user][_job][_liquidity].add(_amount);
    // increase user-job liquidity locked amount
    userJobLiquidityLockedAmount[_user][_job][_liquidity] = userJobLiquidityLockedAmount[_user][_job][_liquidity].add(_amount);
    // substract amount from user idle amount
    userLiquidityIdleAmount[_user][_liquidity] = userLiquidityIdleAmount[_user][_liquidity].sub(_amount);
    // add lp to job if that lp was not being used on that job
    if (jobLiquidityDesiredAmount[_job][_liquidity] == 0) _addLPToJob(_job, _liquidity);
    // add amount to desired liquidity on job
    jobLiquidityDesiredAmount[_job][_liquidity] = jobLiquidityDesiredAmount[_job][_liquidity].add(_amount);
  }

  function _subLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    require(_amount <= userJobLiquidityAmount[_user][_job][_liquidity], 'Keep3rLiquidityManager::not-enough-lp-in-job');
    // only allow user job liquidity to be reduced to 0 or higher than minumum
    require(
      userJobLiquidityAmount[_user][_job][_liquidity].sub(_amount) == 0 ||
        userJobLiquidityAmount[_user][_job][_liquidity].sub(_amount) >= liquidityMinAmount[_liquidity],
      'Keep3rLiquidityManager::locked-amount-not-enough'
    );

    userJobLiquidityAmount[_user][_job][_liquidity] = userJobLiquidityAmount[_user][_job][_liquidity].sub(_amount);
    jobLiquidityDesiredAmount[_job][_liquidity] = jobLiquidityDesiredAmount[_job][_liquidity].sub(_amount);
  }

  function _removeIdleLiquidityOfUserFromJob(
    address _user,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    require(_amount > 0, 'Keep3rLiquidityManager::zero-amount');
    require(
      jobCycle[_job] >= userJobCycle[_user][_job].add(2) || // wait for full cycle
        _jobLiquidities[_job].length() == 0, // or removes if 1 cycle was enough to remove all liquidity
      'Keep3rLiquidityManager::liquidity-still-locked'
    );

    _amount = _amount.div(2).mul(2);

    uint256 _unlockedIdleAvailable = userJobLiquidityLockedAmount[_user][_job][_liquidity].sub(userJobLiquidityAmount[_user][_job][_liquidity]);
    require(_amount <= _unlockedIdleAvailable, 'Keep3rLiquidityManager::amount-bigger-than-idle-available');

    userJobLiquidityLockedAmount[_user][_job][_liquidity] = userJobLiquidityLockedAmount[_user][_job][_liquidity].sub(_amount);
    userLiquidityIdleAmount[_user][_liquidity] = userLiquidityIdleAmount[_user][_liquidity].add(_amount);

    emit IdleLiquidityRemovedFromJob(_user, _liquidity, _job, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import './Keep3rLiquidityManagerParameters.sol';

interface IKeep3rLiquidityManagerUserLiquidityHandler {
  event LiquidityFeeSet(uint256 _liquidityFee);

  event FeeReceiverSet(address _feeReceiver);

  event DepositedLiquidity(address indexed _depositor, address _recipient, address _lp, uint256 _amount, uint256 _fee);

  event WithdrewLiquidity(address indexed _withdrawer, address _recipient, address _lp, uint256 _amount);

  function liquidityFee() external view returns (uint256 _liquidityFee);

  function feeReceiver() external view returns (address _feeReceiver);

  function liquidityTotalAmount(address _liquidity) external view returns (uint256 _amount);

  function userLiquidityTotalAmount(address _user, address _lp) external view returns (uint256 _amount);

  function userLiquidityIdleAmount(address _user, address _lp) external view returns (uint256 _amount);

  function depositLiquidity(address _lp, uint256 _amount) external;

  function depositLiquidityTo(
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) external;

  function withdrawLiquidity(address _lp, uint256 _amount) external;

  function withdrawLiquidityTo(
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) external;

  function setLiquidityFee(uint256 _liquidityFee) external;

  function setFeeReceiver(address _feeReceiver) external;
}

abstract contract Keep3rLiquidityManagerUserLiquidityHandler is Keep3rLiquidityManagerParameters, IKeep3rLiquidityManagerUserLiquidityHandler {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // liquidity fee precision
  uint256 public constant PRECISION = 1_000;
  // max liquidity fee
  uint256 public constant MAX_LIQUIDITY_FEE = PRECISION / 10; // 10%
  // liquidity fee
  uint256 public override liquidityFee;
  // feeReceiver address
  address public override feeReceiver;
  // lp => amount (helps safely collect extra dust)
  mapping(address => uint256) public override liquidityTotalAmount;
  // user => lp => amount
  mapping(address => mapping(address => uint256)) public override userLiquidityTotalAmount;
  // user => lp => amount
  mapping(address => mapping(address => uint256)) public override userLiquidityIdleAmount;

  constructor() public {
    _setFeeReceiver(msg.sender);
  }

  // user
  function depositLiquidity(address _lp, uint256 _amount) public virtual override {
    depositLiquidityTo(msg.sender, _lp, _amount);
  }

  function depositLiquidityTo(
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) public virtual override {
    _depositLiquidity(msg.sender, _liquidityRecipient, _lp, _amount);
  }

  function withdrawLiquidity(address _lp, uint256 _amount) public virtual override {
    withdrawLiquidityTo(msg.sender, _lp, _amount);
  }

  function withdrawLiquidityTo(
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) public virtual override {
    _withdrawLiquidity(msg.sender, _liquidityRecipient, _lp, _amount);
  }

  function _depositLiquidity(
    address _liquidityDepositor,
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) internal {
    require(IKeep3rV1(keep3rV1).liquidityAccepted(_lp), 'Keep3rLiquidityManager::liquidity-not-accepted-on-keep3r');
    IERC20(_lp).safeTransferFrom(_liquidityDepositor, address(this), _amount);
    uint256 _fee = _amount.mul(liquidityFee).div(PRECISION);
    if (_fee > 0) IERC20(_lp).safeTransfer(feeReceiver, _fee);
    _addLiquidity(_liquidityRecipient, _lp, _amount.sub(_fee));
    emit DepositedLiquidity(_liquidityDepositor, _liquidityRecipient, _lp, _amount.sub(_fee), _fee);
  }

  function _withdrawLiquidity(
    address _liquidityWithdrawer,
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) internal {
    require(userLiquidityIdleAmount[_liquidityWithdrawer][_lp] >= _amount, 'Keep3rLiquidityManager::user-insufficient-idle-balance');
    _subLiquidity(_liquidityWithdrawer, _lp, _amount);
    IERC20(_lp).safeTransfer(_liquidityRecipient, _amount);
    emit WithdrewLiquidity(_liquidityWithdrawer, _liquidityRecipient, _lp, _amount);
  }

  function _addLiquidity(
    address _user,
    address _lp,
    uint256 _amount
  ) internal {
    require(_user != address(0), 'Keep3rLiquidityManager::zero-user');
    require(_amount > 0, 'Keep3rLiquidityManager::amount-bigger-than-zero');
    liquidityTotalAmount[_lp] = liquidityTotalAmount[_lp].add(_amount);
    userLiquidityTotalAmount[_user][_lp] = userLiquidityTotalAmount[_user][_lp].add(_amount);
    userLiquidityIdleAmount[_user][_lp] = userLiquidityIdleAmount[_user][_lp].add(_amount);
  }

  function _subLiquidity(
    address _user,
    address _lp,
    uint256 _amount
  ) internal {
    require(userLiquidityTotalAmount[_user][_lp] >= _amount, 'Keep3rLiquidityManager::amount-bigger-than-total');
    liquidityTotalAmount[_lp] = liquidityTotalAmount[_lp].sub(_amount);
    userLiquidityTotalAmount[_user][_lp] = userLiquidityTotalAmount[_user][_lp].sub(_amount);
    userLiquidityIdleAmount[_user][_lp] = userLiquidityIdleAmount[_user][_lp].sub(_amount);
  }

  function _setLiquidityFee(uint256 _liquidityFee) internal {
    // TODO better revert messages
    require(_liquidityFee <= MAX_LIQUIDITY_FEE, 'Keep3rLiquidityManager::fee-exceeds-max-liquidity-fee');
    liquidityFee = _liquidityFee;
    emit LiquidityFeeSet(_liquidityFee);
  }

  function _setFeeReceiver(address _feeReceiver) internal {
    require(_feeReceiver != address(0), 'Keep3rLiquidityManager::zero-address');
    feeReceiver = _feeReceiver;
    emit FeeReceiverSet(_feeReceiver);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './Keep3rEscrowParameters.sol';
import './Keep3rEscrowLiquidityHandler.sol';

interface IKeep3rEscrow is IKeep3rEscrowParameters, IKeep3rEscrowLiquidityHandler {}

contract Keep3rEscrow is Keep3rEscrowParameters, Keep3rEscrowLiquidityHandler, IKeep3rEscrow {
  constructor(address _keep3r) public Keep3rEscrowParameters(_keep3r) {}

  // Manager Liquidity Handler
  function deposit(address _liquidity, uint256 _amount) external override onlyGovernor {
    _deposit(_liquidity, _amount);
  }

  function withdraw(address _liquidity, uint256 _amount) external override onlyGovernor {
    _withdraw(_liquidity, _amount);
  }

  // Job Liquidity Handler
  function addLiquidityToJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external override onlyGovernor {
    _addLiquidityToJob(_liquidity, _job, _amount);
  }

  function applyCreditToJob(
    address _provider,
    address _liquidity,
    address _job
  ) external override onlyGovernor {
    _applyCreditToJob(_provider, _liquidity, _job);
  }

  function unbondLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external override onlyGovernor {
    _unbondLiquidityFromJob(_liquidity, _job, _amount);
  }

  function removeLiquidityFromJob(address _liquidity, address _job) external override onlyGovernor returns (uint256 _amount) {
    return _removeLiquidityFromJob(_liquidity, _job);
  }

  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _safeSendDust(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@lbertenasco/contract-utils/contracts/abstract/UtilsReady.sol';

interface IKeep3rEscrowParameters {
  function keep3r() external returns (address);
}

abstract contract Keep3rEscrowParameters is UtilsReady, IKeep3rEscrowParameters {
  address public immutable override keep3r;

  constructor(address _keep3r) public UtilsReady() {
    require(address(_keep3r) != address(0), 'Keep3rEscrowParameters::constructor::keep3r-zero-address');
    keep3r = _keep3r;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@lbertenasco/contract-utils/interfaces/keep3r/IKeep3rV1.sol';

import './Keep3rEscrowParameters.sol';

interface IKeep3rEscrowLiquidityHandler {
  event LiquidityAddedToJob(address _liquidity, address _job, uint256 _amount);
  event AppliedCreditToJob(address _provider, address _liquidity, address _job);
  event LiquidityUnbondedFromJob(address _liquidity, address _job, uint256 _amount);
  event LiquidityRemovedFromJob(address _liquidity, address _job);

  function liquidityTotalAmount(address _liquidity) external returns (uint256 _amount);

  function liquidityProvidedAmount(address _liquidity) external returns (uint256 _amount);

  function deposit(address _liquidity, uint256 _amount) external;

  function withdraw(address _liquidity, uint256 _amount) external;

  function addLiquidityToJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function applyCreditToJob(
    address _provider,
    address _liquidity,
    address _job
  ) external;

  function unbondLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function removeLiquidityFromJob(address _liquidity, address _job) external returns (uint256 _amount);
}

abstract contract Keep3rEscrowLiquidityHandler is Keep3rEscrowParameters, IKeep3rEscrowLiquidityHandler {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  mapping(address => uint256) public override liquidityTotalAmount;
  mapping(address => uint256) public override liquidityProvidedAmount;

  // Handler Liquidity Handler
  function _deposit(address _liquidity, uint256 _amount) internal {
    liquidityTotalAmount[_liquidity] = liquidityTotalAmount[_liquidity].add(_amount);
    IERC20(_liquidity).safeTransferFrom(governor, address(this), _amount);
  }

  function _withdraw(address _liquidity, uint256 _amount) internal {
    liquidityTotalAmount[_liquidity] = liquidityTotalAmount[_liquidity].sub(_amount);
    IERC20(_liquidity).safeTransfer(governor, _amount);
  }

  // Job Liquidity Handler
  function _addLiquidityToJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    // Set infinite approval once per liquidity?
    IERC20(_liquidity).approve(keep3r, _amount);
    IKeep3rV1(keep3r).addLiquidityToJob(_liquidity, _job, _amount);
    liquidityProvidedAmount[_liquidity] = liquidityProvidedAmount[_liquidity].add(_amount);
  }

  function _applyCreditToJob(
    address _provider,
    address _liquidity,
    address _job
  ) internal {
    IKeep3rV1(keep3r).applyCreditToJob(_provider, _liquidity, _job);
    emit AppliedCreditToJob(_provider, _liquidity, _job);
  }

  function _unbondLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal {
    IKeep3rV1(keep3r).unbondLiquidityFromJob(_liquidity, _job, _amount);
  }

  function _removeLiquidityFromJob(address _liquidity, address _job) internal returns (uint256 _amount) {
    uint256 _before = IERC20(_liquidity).balanceOf(address(this));
    IKeep3rV1(keep3r).removeLiquidityFromJob(_liquidity, _job);
    _amount = IERC20(_liquidity).balanceOf(address(this)).sub(_before);
    liquidityProvidedAmount[_liquidity] = liquidityProvidedAmount[_liquidity].sub(_amount);
  }

  // Collectable Dust
  function _safeSendDust(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    if (liquidityTotalAmount[_token] > 0) {
      uint256 _balance = IERC20(_token).balanceOf(address(this));
      uint256 _provided = liquidityProvidedAmount[_token];
      require(_amount <= _balance.add(_provided).sub(liquidityTotalAmount[_token]));
    }
    _sendDust(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IKeep3rJob {
  event SetRewardMultiplier(uint256 _rewardMultiplier);

  function rewardMultiplier() external view returns (uint256 _rewardMultiplier);

  function setRewardMultiplier(uint256 _rewardMultiplier) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}