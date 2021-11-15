pragma solidity >=0.6.6;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "../interfaces/IDAO.sol";
import "../interfaces/IStabilizerNode.sol";

import "./LPPrivileged.sol";

contract LiquidityMine is Initializable, LiquidityMinePrivileged {
  function initialize(
    address _rewardToken,
    address _maltToken,
    address _stakeToken,
    uint256 duration,
    uint256 _startTime,
    address _dao,
    address _treasuryMultisig,
    address _router,
    address _stabilizerNode,
    address _timelock,
    address _reinvestor,
    address _offering
  ) external initializer {
    _adminSetup(_timelock);
    _setupRole(STABILIZER_NODE_ROLE, _stabilizerNode);
    _setupRole(REINVESTOR_ROLE, _reinvestor);

    rewardToken = ERC20(_rewardToken);
    stakeToken = ERC20(_stakeToken);
    malt = ERC20(_maltToken);

    treasuryMultisig = _treasuryMultisig;
    router = IUniswapV2Router02(_router);
    stabilizerNode = IStabilizerNode(_stabilizerNode);
    payoutDuration = duration; // In epochs
    startTime = _startTime;
    dao = IDAO(_dao);
    reinvestor = _reinvestor;
    offering = _offering;

    // Max approval
    uint256 MAX_INT = 2**256 - 1;
    rewardToken.approve(_reinvestor, MAX_INT);
    malt.approve(_reinvestor, MAX_INT);
  }

  /* Core external functions */
  function bond(uint256 amount) external notSameBlock {
    bondToAccount(msg.sender, amount);
  }

  function bondToAccount(address account, uint256 amount)
    public
  {
    if (msg.sender != offering) {
      _notSameBlock();
    }
    advance();
    require(amount > 0, "Cannot bond 0");

    _handleStakePadding(account, amount);
    _bond(account, amount);

    uint256 currentEpoch = dao.epoch();

    epochRewards[currentEpoch].totalBonded = _globals.bonded;
  }

  function unbond(uint256 amount)
    external
  {
    require(amount > 0, "Cannot unbond 0");

    // Check if the user has any malt locked due to governance voting
    // uint256 lockedMalt = dao.getLockedMalt(msg.sender);
    (uint256 accountTotalBondedValue,) = realValueOfBonded(msg.sender);
    (uint256 realMaltValue,) = maltPoolPeriphery.realValueOfLPToken(amount);

    // Users total available balance must be gte the value they are trying to withdraw
    require(accountTotalBondedValue >= realMaltValue, "< balance");

    uint256 bondedBalance = balanceOfBonded(msg.sender);
    require(bondedBalance > 0, "< bonded balance");
    require(amount <= bondedBalance, "< bonded balance");

    advance();

    _checkForForfeit(amount, bondedBalance);

    _removeFromEpochBonding(msg.sender, amount);

    uint256 lessStakePadding = balanceOfStakePadding(msg.sender).mul(amount).div(bondedBalance);
    uint256 lessMaltStakePadding = balanceOfMaltStakePadding(msg.sender).mul(amount).div(bondedBalance);

    _removeFromStakePadding(msg.sender, lessStakePadding, lessMaltStakePadding, "< stake padding");

    _updateCurrentEpochTotalRewards();

    _clearSubsidizedLP(msg.sender, bondedBalance);

    _unbond(amount);

    uint256 currentEpoch = dao.epoch();

    epochRewards[currentEpoch].totalBonded = _globals.bonded;
  }

  function withdraw(uint256 rewardAmount, uint256 maltAmount)
    external
  {
    advance();
    (uint256 rewardEarned, uint256 maltEarned) = earned(msg.sender);

    require(rewardAmount <= rewardEarned, "< earned");
    require(maltAmount <= maltEarned, "< malt earned");

    // Remove from reward and add equivalent to stake padding.
    // Conservation of reward space volume
    _addToStakePadding(msg.sender, rewardAmount, maltAmount);
    _globals.declaredBalance = _globals.declaredBalance.sub(rewardAmount);
    _globals.declaredMaltBalance = _globals.declaredMaltBalance.sub(maltAmount);

    _updateCurrentEpochTotalRewards();

    _addToEpochWithdraw(msg.sender, rewardAmount, maltAmount);

    _removeFromUnbondedBalance(msg.sender, rewardEarned, maltEarned);

    _withdraw(rewardAmount, maltAmount);
  }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.6;

interface IDAO {
  function epoch() external view returns (uint256);
  function epochLength() external view returns (uint256);
  function genesisTime() external view returns (uint256);
  function getEpochStartTime(uint256 _epoch) external view returns (uint256);
  function getLockedMalt(address account) external view returns (uint256);
}

pragma solidity >=0.6.6;

import "./IAuction.sol";

interface IStabilizerNode {
  function initialize(address dao) external;
  function requiredMint() external;
  function distributeSupply(uint256 amount) external;
  function liquidityMine() external view returns (address);
  function requestMint(uint256 amount) external;
  function requestBurn(uint256 amount) external;
  function stabilize() external;
  function auction() external view returns (IAuction);
  function auctionPreBurn(
    uint256 maxSpend,
    uint256 rRatio,
    uint256 decimals
  ) external returns (
    uint256 initialReservePledge,
    uint256 initialBurn
  );
}

pragma solidity >=0.6.6;

import "./LPSetters.sol";

contract LiquidityMinePrivileged is LiquidityMineSetters {
  function declareReward(uint256 amount)
    external
    onlyRole(STABILIZER_NODE_ROLE, "Only stabilizer node")
  {
    _rewardCheck(amount, 0);

    if (totalBonded() == 0) {
      // There is no accounts to distribute the rewards to so forfeit it to the dao
      _forfeit(amount);
      _updateCurrentEpochTotalRewards();
      return;
    } 
    
    _addEpochRewards(amount, 0);

    emit DeclareReward(0, amount, address(rewardToken));
  }

  function declareMaltReward(uint256 amount)
    external
    onlyRole(STABILIZER_NODE_ROLE, "Only stabilizer node")
  {
    _rewardCheck(0, amount);

    if (totalBonded() == 0) {
      // There is no accounts to distribute the rewards to so forfeit it to the dao
      _forfeitMalt(amount);
      _updateCurrentEpochTotalRewards();
      return;
    } 

    _addEpochRewards(0, amount);
    emit DeclareReward(amount, 0, address(rewardToken));
  }

  function setNewPoolPeriphery(address _periphery)
    external
    onlyRole(TIMELOCK_ROLE, "Must have timelock role")
  {
    maltPoolPeriphery = IMaltPoolPeriphery(_periphery);
    emit SetNewMaltPeriphery(_periphery);
  }

  function setNewStabilizerNode(address _node)
    external
    onlyRole(TIMELOCK_ROLE, "Must have timelock role")
  {
    _swapRole(_node, address(stabilizerNode), STABILIZER_NODE_ROLE);
    stabilizerNode = IStabilizerNode(_node);
    emit SetStabilizerNode(_node);
  }

  function setNewReinvestor(address _reinvestor)
    external
    onlyRole(TIMELOCK_ROLE, "Must have timelock role")
  {
    _swapRole(_reinvestor, reinvestor, REINVESTOR_ROLE);
    reinvestor = _reinvestor;
    emit SetNewReinvestor(_reinvestor);
  }

  function updateBond(address account, uint256 amountReward, uint256 maltRemoval, uint256 liquidity)
    external
    onlyRole(REINVESTOR_ROLE, "Must have reinvestor role")
  {
    _updateBond(account, amountReward, maltRemoval, liquidity);
  }

  function finalizeSubsidy(address account, uint256 amountReward, uint256 liquidity)
    external
    onlyRole(REINVESTOR_ROLE, "Must have reinvestor role")
  {
    // Remove from reward and add equivalent to stake padding.
    // This reward now exists in LP tokens instead
    _addToStakePadding(account, amountReward, 0);
    _globals.declaredBalance = _globals.declaredBalance.sub(amountReward);

    _updateCurrentEpochTotalRewards();

    uint256 currentEpoch = dao.epoch();

    _addToEpochWithdraw(account, amountReward, 0);

    _removeFromUnbondedBalance(account, amountReward, 0);

    _handleStakePadding(account, liquidity);

    _addToBonded(account, liquidity);
    _addToSubsidizedLP(account, liquidity.div(2));

    epochRewards[currentEpoch].totalBonded = _globals.bonded;

    _balanceCheck();
  }

  function transferExcessMalt(address account, uint256 requiredMalt, uint256 maltAmount)
    external
    onlyRole(REINVESTOR_ROLE, "Must have reinvestor role")
  {
    if (requiredMalt > maltAmount) {
      malt.safeTransferFrom(account, address(this), requiredMalt.sub(maltAmount));
    }
  }

  function transferExcessReward(address account, uint256 requiredReward, uint256 rewardAmount)
    external
    onlyRole(REINVESTOR_ROLE, "Must have reinvestor role")
  {
    if (requiredReward > rewardAmount) {
      rewardToken.safeTransferFrom(account, address(this), requiredReward.sub(rewardAmount));
    }
  }

  function requestMint(uint256 amount)
    external
    onlyRole(REINVESTOR_ROLE, "Must have reinvestor role")
  {
    stabilizerNode.requestMint(amount);
    malt.safeTransfer(reinvestor, amount);
  }

  function requestBurn(uint256 amount)
    external
    onlyRole(REINVESTOR_ROLE, "Must have reinvestor role")
  {
    malt.transfer(address(stabilizerNode), amount);
    stabilizerNode.requestBurn(amount);
  }

  function reinvestLiquidity(
    address account,
    uint256 liquidityMalt,
    uint256 liquidityReward,
    bool rebalanceMalt,
    uint256 otherQuantity
  )
    public
    onlyRole(REINVESTOR_ROLE, "Must have reinvestor role")
  {
    // rebalanceMalt defines whether we may need to transfer back malt or reward tokens to the caller
    // otherQuantity is how much of the other token's rewards is used to make up the liquidity.
    // As opposed to being transfered in by the user.
    ReinvestRebalance memory rebalance = ReinvestRebalance({
      rewardRemoval: 0,
      maltRemoval: 0,
      excess: 0,
      minMalt: liquidityMalt.mul(95).div(100),
      minReward: liquidityReward.mul(95).div(100)
    });

    malt.approve(address(router), liquidityMalt);
    rewardToken.approve(address(router), liquidityReward);

    (
      uint256 amountMalt,
      uint256 amountReward,
      uint256 liquidity
    ) = router.addLiquidity(
      address(malt),
      address(rewardToken),
      liquidityMalt,
      liquidityReward,
      rebalance.minMalt, // 5% slippage
      rebalance.minReward, // 5% slippage
      address(this),
      now
    );

    if (rebalanceMalt) {
      rebalance.rewardRemoval = amountReward;
      rebalance.maltRemoval = otherQuantity;

      if (amountMalt < liquidityMalt) {
        rebalance.excess = liquidityMalt.sub(amountMalt);

        if (amountMalt > otherQuantity) {
          // Transfer excess back
          malt.safeTransfer(account, rebalance.excess);
        } else {
          // Not all of otherQuantity was used so don't remove it all
          rebalance.maltRemoval = amountMalt;
          malt.safeTransfer(account, liquidityMalt.sub(otherQuantity));
        }
      }
    } else {
      rebalance.rewardRemoval = otherQuantity;
      rebalance.maltRemoval = amountMalt;

      if (amountReward < liquidityReward) {
        rebalance.excess = liquidityReward.sub(amountReward);

        if (amountReward > otherQuantity) {
          // Transfer excess back
          rewardToken.safeTransfer(account, rebalance.excess);
        } else {
          // Not all of desiredReward was used so don't remove it all
          rebalance.rewardRemoval = amountReward;
          rewardToken.safeTransfer(account, liquidityReward.sub(otherQuantity));
        }
      }
    }

    _updateBond(account, rebalance.rewardRemoval, rebalance.maltRemoval, liquidity);
  }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.6;

interface IAuction {
  function checkAuctionFinalization() external returns (
    bool shouldFinalize,
    uint256 id
  );
  function currentAuctionId() external view returns (uint256);
  function auctionActive(uint256 _id) external view returns (bool);
  function capCommitment(
    uint256 _id,
    uint256 _commitment
  ) external view returns (
    uint256 realCommitment,
    uint256 purchaseCommitment
  );
  function commitFunds(
    uint256 _id,
    uint256 _commitment,
    uint256 _maltPurchased,
    address account
  ) external;
  function userClaimableArbTokens(
    address account,
    uint256 auctionId
  ) external view returns (uint256);
  function claimArb(
    uint256 _id,
    address account,
    uint256 amount
  ) external returns (bool);
  function claimableArbitrageRewards() external view returns (uint256);
  function setupAuctionFinalization(uint256 _id) external returns (
    uint256 averageMaltPrice,
    uint256 commitments,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 preAuctionReserveRatio,
    uint256 initialReservePledge
  );
  function allocateArbRewards(
    uint256 rewarded,
    uint256 replenishSplit
  ) external returns (uint256);
  function createAuction(uint256 pegPrice) external returns (
    uint256 initialPurchase,
    bool executeBurn
  );
  function getActiveAuction() external view returns (
    uint256 auctionId,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 initialReservePledge
  );
  function getAuction(uint256 id) external view returns (
    uint256 auctionId,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 initialReservePledge
  );
  function balanceOfArbTokens(
    uint256 auctionId,
    address account
  ) external view returns (uint256);
  function getAuctionCommitments(uint256 auctionId) external view returns (uint256, uint256);
}

pragma solidity >=0.6.6;

import "./LPGetters.sol";

contract LiquidityMineSetters is LiquidityMineGetters {
  function advance() public {
    uint256 currentEpoch = dao.epoch();

    // This is should be called right at the start of the epoch to lock in how much
    // was bonded and how much stake padding etc there is to make accounting easier
    if (!epochRewards[currentEpoch].advanced) {
      uint256 bonded = totalBonded();
      (uint256 maltValue, uint256 rewardValue) = maltPoolPeriphery.realValueOfLPToken(bonded);
      epochRewards[currentEpoch].totalBonded = bonded;
      epochRewards[currentEpoch].advanced = true;
      epochRewards[currentEpoch].valueOfBondedMalt = maltValue;
      epochRewards[currentEpoch].valueOfBondedReward = rewardValue;
      epochRewards[currentEpoch].stakePadding = _globals.stakePadding;
      epochRewards[currentEpoch].maltStakePadding = _globals.maltStakePadding;

      emit Advance(currentEpoch, now);
    }

    _updateCurrentEpochTotalRewards();
  }

  function _bond(address account, uint256 amount) internal {
    stakeToken.safeTransferFrom(msg.sender, address(this), amount);

    _addToBonded(account, amount);

    _balanceCheck();

    emit Bond(account, amount);
  }

  function _unbond(uint256 amountLPToken) internal notSameBlock {
    _removeFromBonded(msg.sender, amountLPToken, "LP: Insufficient bonded balance");

    stakeToken.safeTransfer(msg.sender, amountLPToken);

    _balanceCheck();

    emit Unbond(msg.sender, amountLPToken);
  }

  function _withdraw(uint256 amountReward, uint256 maltReward) internal notSameBlock {
    rewardToken.safeTransfer(msg.sender, amountReward);
    malt.safeTransfer(msg.sender, maltReward);

    _balanceCheck();

    emit Withdraw(msg.sender, amountReward, maltReward);
  }

  function _addToBonded(address account, uint256 amount) internal {
    userState[account].bonded = userState[account].bonded.add(amount);
    _globals.bonded = _globals.bonded.add(amount);
  }

  function _addToSubsidizedLP(address account, uint256 amount) internal {
    userState[account].subsidizedLP = userState[account].subsidizedLP.add(amount);
    _globals.subsidizedLP = _globals.subsidizedLP.add(amount);
  }

  function _removeFromBonded(address account, uint256 amount, string memory reason) internal {
    userState[account].bonded = userState[account].bonded.sub(amount, reason);
    _globals.bonded = _globals.bonded.sub(amount, reason);
  }

  function removeFromSubsidizedLP(address account, uint256 amount, string memory reason) internal {
    userState[account].subsidizedLP = userState[account].subsidizedLP.sub(amount, reason);
    _globals.subsidizedLP = _globals.subsidizedLP.sub(amount, reason);
  }

  function _updateBond(address account, uint256 amountReward, uint256 maltRemoval, uint256 liquidity) internal {
    // Remove from reward and add equivalent to stake padding.
    // Conservation of reward space volume
    // This reward now exists in LP tokens instead
    _addToStakePadding(account, amountReward, maltRemoval);
    _globals.declaredBalance = _globals.declaredBalance.sub(amountReward);
    _globals.declaredMaltBalance = _globals.declaredMaltBalance.sub(maltRemoval);

    _updateCurrentEpochTotalRewards();

    uint256 currentEpoch = dao.epoch();

    _addToEpochWithdraw(account, amountReward, maltRemoval);

    _handleStakePadding(account, liquidity);

    _addToBonded(account, liquidity);

    epochRewards[currentEpoch].totalBonded = _globals.bonded;

    _balanceCheck();

    emit Bond(account, liquidity);
  }

  function _handleStakePadding(address account, uint256 amount) internal {
    // Bond the new LP tokens to the user
    _addToEpochBonding(account, amount);
    
    uint256 totalRewardedWithStakePadding = totalBondedRewarded().add(totalStakePadding());
    uint256 totalMaltWithStakePadding = totalBondedMaltRewarded().add(totalMaltStakePadding());

    uint256 INITIAL_STAKE_SHARE_MULTIPLE = 1e6;

    uint256 newStakePadding = totalBonded() == 0 ?
      totalBondedRewarded() == 0 ? amount.mul(INITIAL_STAKE_SHARE_MULTIPLE) : 0 :
      totalRewardedWithStakePadding.mul(amount).div(totalBonded());

    uint256 newMaltStakePadding = totalBonded() == 0 ?
      totalBondedMaltRewarded() == 0 ? amount.mul(INITIAL_STAKE_SHARE_MULTIPLE) : 0 :
      totalMaltWithStakePadding.mul(amount).div(totalBonded());
    
    _addToStakePadding(account, newStakePadding, newMaltStakePadding);

    if (balanceOfBonded(account) == 0) {
      userState[account].bondedEpoch = dao.epoch();
    }
  }

  function _addToStakePadding(address account, uint256 amount, uint256 amountMalt) internal {
    userState[account].stakePadding = userState[account].stakePadding.add(amount);
    userState[account].maltStakePadding = userState[account].maltStakePadding.add(amountMalt);
    _globals.stakePadding = _globals.stakePadding.add(amount);
    _globals.maltStakePadding = _globals.maltStakePadding.add(amountMalt);

    uint256 currentEpoch = dao.epoch();

    epochRewards[currentEpoch].stakePadding = _globals.stakePadding;
    epochRewards[currentEpoch].maltStakePadding = _globals.maltStakePadding;

    userState[account].epochStakePadding[currentEpoch].reward = userState[account].epochStakePadding[currentEpoch].reward + int256(amount);
    userState[account].epochStakePadding[currentEpoch].malt = userState[account].epochStakePadding[currentEpoch].malt + int256(amountMalt);
  }

  function _removeFromStakePadding(address account, uint256 amount, uint256 amountMalt, string memory reason) internal {
    userState[account].stakePadding = userState[account].stakePadding.sub(amount, reason);
    userState[account].maltStakePadding = userState[account].maltStakePadding.sub(amountMalt, reason);
    _globals.stakePadding = _globals.stakePadding.sub(amount, reason);
    _globals.maltStakePadding = _globals.maltStakePadding.sub(amountMalt, reason);

    uint256 currentEpoch = dao.epoch();

    epochRewards[currentEpoch].stakePadding = _globals.stakePadding;
    epochRewards[currentEpoch].maltStakePadding = _globals.maltStakePadding;

    // These are signed ints. It should be allowed to go negative
    userState[account].epochStakePadding[currentEpoch].reward = userState[account].epochStakePadding[currentEpoch].reward - int256(amount);
    userState[account].epochStakePadding[currentEpoch].malt = userState[account].epochStakePadding[currentEpoch].malt - int256(amountMalt);
  }

  function _addToEpochBonding(address account, uint256 amount) internal {
    uint256 currentEpoch = dao.epoch();

    uint256 length = userState[account].bondEpochs.length;

    if (length == 0 || userState[account].bondEpochs[length - 1] != currentEpoch) {
      userState[account].bondEpochs.push(currentEpoch);
    }
    userState[account].epochBonds[currentEpoch] = userState[account].epochBonds[currentEpoch].add(amount);
  }

  function _removeFromEpochBonding(address account, uint256 amount) internal {
    uint256 currentEpoch = dao.epoch();

    uint256 length = userState[account].unbondEpochs.length;

    if (length == 0 || userState[account].unbondEpochs[length - 1] != currentEpoch) {
      userState[account].unbondEpochs.push(currentEpoch);
    }
    userState[account].epochUnbonds[currentEpoch] = userState[account].epochUnbonds[currentEpoch].add(amount);
  }

  function _addToEpochWithdraw(address account, uint256 amountReward, uint256 amountMalt) internal {
    uint256 currentEpoch = dao.epoch();

    uint256 length = userState[account].withdrawEpochs.length;

    if (length == 0 || userState[account].withdrawEpochs[length - 1] != currentEpoch) {
      userState[account].withdrawEpochs.push(currentEpoch);
    }
    userState[account].epochWithdraws[currentEpoch].reward = userState[account].epochWithdraws[currentEpoch].reward.add(amountReward);
    userState[account].epochWithdraws[currentEpoch].malt = userState[account].epochWithdraws[currentEpoch].malt.add(amountMalt);
  }

  function _addToUnbondedBalance(address account, uint256 amount, uint256 amountMalt) internal {
    _globals.unbondedBalance = _globals.unbondedBalance + amount;
    _globals.unbondedMaltBalance = _globals.unbondedMaltBalance + amountMalt;

    userState[account].unbondedBalance = userState[account].unbondedBalance + amount;
    userState[account].unbondedMaltBalance = userState[account].unbondedMaltBalance + amountMalt;
  }

  function _removeFromUnbondedBalance(address account, uint256 amount, uint256 amountMalt) internal {
    uint256 rewardRemoval = 0;
    uint256 maltRemoval = 0;

    if (amount > userState[account].unbondedBalance) {
      rewardRemoval = userState[account].unbondedBalance;
      userState[account].unbondedBalance = 0;
    } else {
      rewardRemoval = amount;
      userState[account].unbondedBalance = userState[account].unbondedBalance.sub(amount);
    }

    if (amountMalt > userState[account].unbondedMaltBalance) {
      maltRemoval = userState[account].unbondedMaltBalance;
      userState[account].unbondedMaltBalance = 0;
    } else {
      maltRemoval = amountMalt;
      userState[account].unbondedMaltBalance = userState[account].unbondedMaltBalance.sub(amountMalt);
    }

    _globals.unbondedBalance = _globals.unbondedBalance.sub(rewardRemoval);
    _globals.unbondedMaltBalance = _globals.unbondedMaltBalance.sub(maltRemoval);
  }

  function _clearSubsidizedLP(address account, uint256 bondedBalance) internal {
    uint256 subsidies = balanceOfSubsidizedLP(account);

    if (subsidies > 0) {
      _removeFromEpochBonding(account, subsidies);

      uint256 lessStakePadding = balanceOfStakePadding(account).mul(subsidies).div(bondedBalance.add(subsidies));
      uint256 lessMaltStakePadding = balanceOfMaltStakePadding(account).mul(subsidies).div(bondedBalance.add(subsidies));

      _removeFromStakePadding(account, lessStakePadding, lessMaltStakePadding, "Insufficient stake padding");

      _removeFromBonded(account, subsidies, "LP: Insufficient bonded balance");
      removeFromSubsidizedLP(account, subsidies, "Subsidized LP: Insufficient balance");

      stakeToken.safeTransfer(treasuryMultisig, subsidies);
      _balanceCheck();
    }
  }

  function _checkForForfeit(uint256 amount, uint256 bondedBalance) internal {
    (uint256 rewardEarned, uint256 maltEarned) = earned(msg.sender);
    uint256 amountClaimable = rewardEarned.mul(amount).div(bondedBalance).sub(userState[msg.sender].unbondedBalance);
    uint256 maltClaimable = maltEarned.mul(amount).div(bondedBalance).sub(userState[msg.sender].unbondedMaltBalance);
    uint256 currentEpoch = dao.epoch();

    uint256 allocation = balanceOfRewards(msg.sender).mul(amount).div(bondedBalance);
    uint256 maltAllocation = balanceOfMaltRewards(msg.sender).mul(amount).div(bondedBalance);

    uint256 forfeited = allocation.sub(amountClaimable);

    if (forfeited > 0) {
      _forfeit(forfeited);
      userState[msg.sender].epochForfeits[currentEpoch].reward = userState[msg.sender].epochForfeits[currentEpoch].reward + forfeited;
    }

    uint256 forfeitedMalt = maltAllocation.sub(maltClaimable);

    if (forfeitedMalt > 0) {
      _forfeitMalt(forfeitedMalt);
      userState[msg.sender].epochForfeits[currentEpoch].malt = userState[msg.sender].epochForfeits[currentEpoch].malt + forfeitedMalt;
    }

    if (forfeited > 0 || forfeitedMalt > 0) {
      _addToStakePadding(msg.sender, forfeited, forfeitedMalt);
    }

    _addToUnbondedBalance(msg.sender, amountClaimable, maltClaimable);

    _updateCurrentEpochTotalRewards();
  }

  function _updateCurrentEpochTotalRewards() internal {
    uint256 currentEpoch = dao.epoch();

    epochRewards[currentEpoch].totalReward = _globals.declaredBalance;
    epochRewards[currentEpoch].totalMaltReward = _globals.declaredMaltBalance;
  }

  function _forfeit(uint256 forfeited) internal {
    _globals.declaredBalance = _globals.declaredBalance.sub(forfeited);

    rewardToken.safeTransfer(treasuryMultisig, forfeited);

    emit Forfeit(msg.sender, address(rewardToken), forfeited);
  }

  function _forfeitMalt(uint256 forfeited) internal {
    _globals.declaredMaltBalance = _globals.declaredMaltBalance.sub(forfeited);

    malt.safeTransfer(treasuryMultisig, forfeited);

    emit Forfeit(msg.sender, address(malt), forfeited);
  }

  function _addEpochRewards(uint256 reward, uint256 maltReward) internal {
    uint256 currentEpoch = dao.epoch();

    if (reward > 0) {
      epochRewards[currentEpoch].reward = epochRewards[currentEpoch].reward + reward;
    }
    if (maltReward > 0) {
      epochRewards[currentEpoch].maltReward = epochRewards[currentEpoch].maltReward + maltReward;
    }

    _updateCurrentEpochTotalRewards();

    if (epochRewards[currentEpoch].completionTime == 0) {
      epochRewards[currentEpoch].completionTime = dao.getEpochStartTime(
        currentEpoch.add(payoutDuration)
      );
    }

    advance();
  }
}

pragma solidity >=0.6.6;

import "./LPState.sol";

contract LiquidityMineGetters is LiquidityMineState {
  function totalBonded() public view returns (uint256) {
    return _globals.bonded;
  }

  function totalSubsidizedLp() public view returns (uint256) {
    return _globals.subsidizedLP;
  }

  function totalStakePadding() public view returns(uint256) {
    return _globals.stakePadding;  
  }

  function totalMaltStakePadding() public view returns(uint256) {
    return _globals.maltStakePadding;  
  }

  function totalBondedRewarded() public view returns (uint256) {
    return _globals.declaredBalance.sub(_globals.unbondedBalance);
  }

  function totalBondedMaltRewarded() public view returns (uint256) {
    return _globals.declaredMaltBalance.sub(_globals.unbondedMaltBalance);
  }

  function balanceOfBonded(address account) public view returns (uint256) {
    return userState[account].bonded.sub(userState[account].subsidizedLP);
  }

  function balanceOfSubsidizedLP(address account) public view returns (uint256) {
    return userState[account].subsidizedLP;
  }

  function balanceOfStakePadding(address account) public view returns (uint256) {
    return userState[account].stakePadding;
  }

  function balanceOfMaltStakePadding(address account) public view returns (uint256) {
    return userState[account].maltStakePadding;
  }

  function getEpochReward(uint256 epoch) public view returns (
    uint256 reward,
    uint256 maltReward,
    uint256 totalReward,
    uint256 totalMaltReward,
    uint256 stakePadding,
    uint256 maltStakePadding,
    uint256 completionTime,
    uint256 epochTotalBonded,
    uint256 valueOfBondedMalt,
    uint256 valueOfBondedReward
  ) {
    EpochRewards storage rewards = epochRewards[epoch];

    return (
      rewards.reward,
      rewards.maltReward,
      rewards.totalReward,
      rewards.totalMaltReward,
      rewards.stakePadding,
      rewards.maltStakePadding,
      rewards.completionTime,
      rewards.totalBonded,
      rewards.valueOfBondedMalt,
      rewards.valueOfBondedReward
    );
  }

  function getGlobalState() public view returns (
    uint256 bonded,
    uint256 subsidizedLP,
    uint256 stakePadding,
    uint256 maltStakePadding,
    uint256 unbondedBalance,
    uint256 unbondedMaltBalance,
    uint256 declaredBalance,
    uint256 declaredMaltBalance
  ) {
    return (
      _globals.bonded,
      _globals.subsidizedLP,
      _globals.stakePadding,
      _globals.maltStakePadding,
      _globals.unbondedBalance,
      _globals.unbondedMaltBalance,
      _globals.declaredBalance,
      _globals.declaredMaltBalance
    );
  }

  function getAccountState(address account) public view returns (
    uint256 bonded,
    uint256 subsidizedLP,
    uint256 stakePadding,
    uint256 maltStakePadding,
    uint256 bondedEpoch,
    uint256 unbondedBalance,
    uint256 unbondedMaltBalance
  ) {
    return (
      userState[account].bonded,
      userState[account].subsidizedLP,
      userState[account].stakePadding,
      userState[account].maltStakePadding,
      userState[account].bondedEpoch,
      userState[account].unbondedBalance,
      userState[account].unbondedMaltBalance
    );
  }

  function getAccountActionEpochs(address account) public view returns(
    uint256[] memory bondEpochs,
    uint256[] memory unbondEpochs,
    uint256[] memory withdrawEpochs
  ) {
    return (
      userState[account].bondEpochs,
      userState[account].unbondEpochs,
      userState[account].withdrawEpochs
    );
  }

  function getAccountEpochData(address account, uint256 epoch) public view returns (
    uint256 bonded,
    uint256 unbonded,
    uint256 withdrawnReward,
    uint256 withdrawnMalt,
    uint256 forfeitedReward,
    uint256 forfeitedMalt
  ) {
    return (
      userState[account].epochBonds[epoch],
      userState[account].epochUnbonds[epoch],
      userState[account].epochWithdraws[epoch].reward,
      userState[account].epochWithdraws[epoch].malt,
      userState[account].epochForfeits[epoch].reward,
      userState[account].epochForfeits[epoch].malt
    );
  }

  function getAccountEpochStakePadding(address account, uint256 epoch) public view returns (
    int256 rewardStakePadding,
    int256 maltStakePadding
  ) {
    return (
      userState[account].epochStakePadding[epoch].reward,
      userState[account].epochStakePadding[epoch].malt
    );
  }

  function _balanceCheck() internal view {
    require(stakeToken.balanceOf(address(this)) >= totalBonded(), "Balance inconsistency");
  }

  function earned(address account) public view returns (uint256 earnedReward, uint256 earnedMalt) {
    uint256 currentEpoch = dao.epoch();

    if (userState[account].bondedEpoch == currentEpoch) {
      return (0, 0);
    }

    Totals memory accountTotals;

    uint256 initialEpoch = 0;
    if (currentEpoch > payoutDuration) {
      initialEpoch = currentEpoch - payoutDuration;
    }
    if (initialEpoch < userState[account].bondedEpoch) {
      initialEpoch = userState[account].bondedEpoch;
    }
    uint256 bondedBalance = balanceOfBonded(account) + balanceOfSubsidizedLP(account);

    accountTotals.stakePadding.reward = int256(balanceOfStakePadding(account));
    accountTotals.stakePadding.malt = int256(balanceOfMaltStakePadding(account));

    uint256 earnedTotal = 0;
    uint256 allocated = 0;

    for (uint256 i = currentEpoch; i > initialEpoch; i -= 1) {
      bondedBalance = bondedBalance - userState[account].epochBonds[i] + userState[account].epochUnbonds[i];

      accountTotals.stakePadding.reward = accountTotals.stakePadding.reward - userState[account].epochStakePadding[i].reward;
      accountTotals.stakePadding.malt = accountTotals.stakePadding.malt - userState[account].epochStakePadding[i].malt;

      accountTotals.withdraws.reward = accountTotals.withdraws.reward + userState[account].epochWithdraws[i].reward;
      accountTotals.withdraws.malt = accountTotals.withdraws.malt + userState[account].epochWithdraws[i].malt;

      (earnedTotal, allocated) = _epochEarnedRewards(i, bondedBalance);
      accountTotals.earned.reward = accountTotals.earned.reward + earnedTotal;
      accountTotals.allocated.reward = accountTotals.allocated.reward + allocated;

      (earnedTotal, allocated) = _epochEarnedMaltRewards(i, bondedBalance);
      accountTotals.earned.malt = accountTotals.earned.malt + earnedTotal;
      accountTotals.allocated.malt = accountTotals.allocated.malt + allocated;

      accountTotals.forfeited.reward = accountTotals.forfeited.reward + userState[account].epochForfeits[i].reward;
      accountTotals.forfeited.malt = accountTotals.forfeited.malt + userState[account].epochForfeits[i].malt;
    }

    // TODO go through anywhere we can use a conditional to avoid writing a new value to storage Tue 30 Mar 2021 12:34:03 BST

    // Add full rewards from initialEpoch
    if (initialEpoch > userState[account].bondedEpoch) {
      bondedBalance = bondedBalance - userState[account].epochBonds[initialEpoch] + userState[account].epochUnbonds[initialEpoch];
      accountTotals.stakePadding.reward = accountTotals.stakePadding.reward - userState[account].epochStakePadding[initialEpoch].reward;
      accountTotals.stakePadding.malt = accountTotals.stakePadding.malt - userState[account].epochStakePadding[initialEpoch].malt;

      allocated = _epochBalanceOfRewards(initialEpoch, uint256(accountTotals.stakePadding.reward), bondedBalance);
      accountTotals.earned.reward = accountTotals.earned.reward + allocated;
      accountTotals.allocated.reward = accountTotals.allocated.reward + allocated;

      allocated = _epochBalanceOfMaltRewards(initialEpoch, uint256(accountTotals.stakePadding.malt), bondedBalance);
      accountTotals.earned.malt = accountTotals.earned.malt + allocated;
      accountTotals.allocated.malt = accountTotals.allocated.malt + allocated;
    }

    // Subtract totalWithdraws
    if (accountTotals.withdraws.reward >= accountTotals.earned.reward) {
      accountTotals.earned.reward = 0;
    } else {
      accountTotals.earned.reward = accountTotals.earned.reward - accountTotals.withdraws.reward;
    }

    if (accountTotals.withdraws.malt >= accountTotals.earned.malt) {
      accountTotals.earned.malt = 0;
    } else {
      accountTotals.earned.malt = accountTotals.earned.malt - accountTotals.withdraws.malt;
    }

    if (accountTotals.earned.reward > accountTotals.allocated.reward.sub(accountTotals.forfeited.reward)) {
      accountTotals.earned.reward = accountTotals.allocated.reward.sub(accountTotals.forfeited.reward);
    }

    if (accountTotals.earned.malt > accountTotals.allocated.malt.sub(accountTotals.forfeited.malt)) {
      accountTotals.earned.malt = accountTotals.allocated.malt.sub(accountTotals.forfeited.malt);
    }

    return (accountTotals.earned.reward, accountTotals.earned.malt);
  }

  function balanceOfRewards(address account) public view returns (uint256) {
    /*
     * This represents the rewards allocated to a given account but does not
     * mean all these rewards are unlocked yet. The earned method will
     * fetch the balance that is unlocked for an account
     */
    uint256 balanceOfRewardedWithStakePadding = _getFullyPaddedReward(account);

    uint256 stakePaddingBalance = balanceOfStakePadding(account);

    if (balanceOfRewardedWithStakePadding > stakePaddingBalance) {
      return balanceOfRewardedWithStakePadding - stakePaddingBalance;
    }
    return 0;
  }


  function balanceOfMaltRewards(address account) public view returns (uint256) {
    /*
     * This represents the malt rewards allocated to a given account but does not
     * mean all these rewards are unlocked yet. The earned method will
     * fetch the balance that is unlocked for an account
     */
    uint256 balanceOfRewardedWithStakePadding = _getFullyPaddedMaltReward(account);

    uint256 stakePaddingBalance = balanceOfMaltStakePadding(account);
    if (balanceOfRewardedWithStakePadding > stakePaddingBalance) {
      return balanceOfRewardedWithStakePadding.sub(stakePaddingBalance);
    }
    return 0;
  }

  function _getFullyPaddedMaltReward(address account) internal view returns (uint256) {
    uint256 globalBondedTotal = totalBonded();
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalRewardedWithStakePadding = totalBondedMaltRewarded().add(totalMaltStakePadding());
    
    return totalRewardedWithStakePadding
      .mul(balanceOfBonded(account).add(balanceOfSubsidizedLP(account)))
      .div(globalBondedTotal);
  }

  function _getFullyPaddedReward(address account) internal view returns (uint256) {
    uint256 globalBondedTotal = totalBonded();
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalRewardedWithStakePadding = totalBondedRewarded().add(totalStakePadding());
    
    return totalRewardedWithStakePadding
      .mul(balanceOfBonded(account).add(balanceOfSubsidizedLP(account)))
      .div(globalBondedTotal);
  }

  function _epochEarnedRewards(
    uint256 epoch,
    uint256 bondedBalance
  ) internal view returns (uint256, uint256) {
    if (epochRewards[epoch].reward == 0 || bondedBalance == 0) {
      return (0, 0);
    }

    uint256 previousEpoch = epoch > 0 ? epoch - 1 : 0;
    uint256 epochMaturity = block.timestamp - dao.getEpochStartTime(epoch);

    uint256 globalBondedTotal = epochRewards[previousEpoch].totalBonded;
    if (globalBondedTotal == 0) {
      return (0, 0);
    }

    uint256 rewardBalance = epochRewards[epoch].reward.mul(bondedBalance).div(globalBondedTotal);

    return (rewardBalance.mul(epochMaturity).div(payoutDuration * dao.epochLength()), rewardBalance);
  }

  function _epochEarnedMaltRewards(
    uint256 epoch,
    uint256 bondedBalance
  ) internal view returns (uint256, uint256) {
    if (epochRewards[epoch].maltReward == 0 || bondedBalance == 0) {
      return (0, 0);
    }

    uint256 previousEpoch = epoch > 0 ? epoch - 1 : 0;
    uint256 epochMaturity = block.timestamp - dao.getEpochStartTime(epoch);

    uint256 globalBondedTotal = epochRewards[previousEpoch].totalBonded;
    if (globalBondedTotal == 0) {
      return (0, 0);
    }

    uint256 rewardBalance = epochRewards[epoch].maltReward.mul(bondedBalance).div(globalBondedTotal);

    return (rewardBalance.mul(epochMaturity).div(payoutDuration * dao.epochLength()), rewardBalance);
  }

  function _epochBalanceOfRewards(
    uint256 epoch,
    uint256 stakePadding,
    uint256 bondedBalance
  ) internal view returns (uint256) {
    if (epochRewards[epoch].totalReward == 0 || bondedBalance == 0) {
      return 0;
    }

    uint256 previousEpoch = epoch > 0 ? epoch - 1 : 0;

    uint256 globalBondedTotal = epochRewards[previousEpoch].totalBonded;
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalRewardedWithStakePadding = epochRewards[epoch].totalReward + epochRewards[previousEpoch].stakePadding;
    uint256 balanceOfRewardedWithStakePadding = totalRewardedWithStakePadding
      .mul(bondedBalance)
      .div(globalBondedTotal);

    if (balanceOfRewardedWithStakePadding > stakePadding) {
      return balanceOfRewardedWithStakePadding - stakePadding;
    }

    return 0;
  }

  function _epochBalanceOfMaltRewards(
    uint256 epoch,
    uint256 stakePadding,
    uint256 bondedBalance
  ) internal view returns (uint256) {
    if (epochRewards[epoch].totalMaltReward == 0 || bondedBalance == 0) {
      return 0;
    }

    uint256 previousEpoch = epoch > 0 ? epoch - 1 : 0;

    uint256 globalBondedTotal = epochRewards[previousEpoch].totalBonded;
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalMaltRewardedWithStakePadding = epochRewards[epoch].totalMaltReward + epochRewards[previousEpoch].maltStakePadding;
    uint256 balanceOfMaltRewardedWithStakePadding = totalMaltRewardedWithStakePadding
      .mul(bondedBalance)
      .div(globalBondedTotal);

    if (balanceOfMaltRewardedWithStakePadding > stakePadding) {
      return balanceOfMaltRewardedWithStakePadding - stakePadding;
    }

    return 0;
  }

  function realValueOfBonded(address account) public view returns (uint256, uint256) {
    uint256 bondedBalance = balanceOfBonded(account);
    return maltPoolPeriphery.realValueOfLPToken(bondedBalance);
  }

  function realValueOfSubsidizedLP(address account) public view returns (uint256, uint256) {
    uint256 subsidizedBalance = balanceOfSubsidizedLP(account);
    return maltPoolPeriphery.realValueOfLPToken(subsidizedBalance);
  }

  function _rewardCheck(uint256 reward, uint256 rewardMalt) internal {
    require(reward > 0 || rewardMalt > 0, "Cannot declare 0 reward");

    _globals.declaredBalance = _globals.declaredBalance.add(reward);
    _globals.declaredMaltBalance = _globals.declaredMaltBalance.add(rewardMalt);

    require(_globals.declaredBalance <= rewardToken.balanceOf(address(this)), "Insufficient balance");
    require(_globals.declaredMaltBalance <= malt.balanceOf(address(this)), "Insufficient balance");
  }
}

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import "../interfaces/IDAO.sol";
import "../interfaces/IStabilizerNode.sol";
import "../interfaces/IMaltPoolPeriphery.sol";
import "../Permissions.sol";

struct Pair {
  uint256 reward;
  uint256 malt;
}

struct SignedPair {
  int256 reward;
  int256 malt;
}

struct Totals {
  Pair withdraws;
  Pair earned;
  Pair forfeited;
  Pair allocated;
  SignedPair stakePadding;
}

struct State {
  uint256 bonded;
  uint256 subsidizedLP;
  uint256 stakePadding;
  uint256 maltStakePadding;
  uint256 unbondedBalance;
  uint256 unbondedMaltBalance;
  uint256 declaredBalance;
  uint256 declaredMaltBalance;
}

struct UserState {
  uint256 bonded;
  uint256 subsidizedLP;
  uint256 stakePadding;
  uint256 maltStakePadding;
  uint256 bondedEpoch;
  uint256 unbondedBalance;
  uint256 unbondedMaltBalance;
  uint256[] bondEpochs;
  uint256[] unbondEpochs;
  uint256[] withdrawEpochs;
  mapping(uint256 => uint256) epochBonds;
  mapping(uint256 => uint256) epochUnbonds;
  mapping(uint256 => Pair) epochWithdraws;
  mapping(uint256 => Pair) epochForfeits;
  mapping(uint256 => SignedPair) epochStakePadding;
}

struct EpochRewards {
  uint256 reward;
  uint256 maltReward;
  uint256 totalReward;
  uint256 totalMaltReward;
  uint256 stakePadding;
  uint256 maltStakePadding;
  uint256 completionTime;
  uint256 totalBonded;
  uint256 valueOfBondedMalt;
  uint256 valueOfBondedReward;
  bool advanced;
}

struct UnlockData {
  uint256 totalReward;
  uint256 unlockedReward;
  uint256 totalMalt;
  uint256 unlockedMalt;
  uint256 userBondedTotal;
}

struct ReinvestRebalance {
  uint256 rewardRemoval;
  uint256 maltRemoval;
  uint256 excess;
  uint256 minMalt;
  uint256 minReward;
}
  
contract LiquidityMineState is Permissions {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  bytes32 public constant REINVESTOR_ROLE = keccak256("REINVESTOR_ROLE");

  ERC20 public malt;
  ERC20 public rewardToken;
  ERC20 public stakeToken;
  IDAO public dao;
  IUniswapV2Router02 public router;

  IMaltPoolPeriphery public maltPoolPeriphery;
  IStabilizerNode public stabilizerNode;
  address public reinvestor;
  address internal offering;

  address public treasuryMultisig;
  uint256 public payoutDuration;
  uint256 public startTime;

  State internal _globals;
  mapping(address => UserState) internal userState;
  mapping(uint256 => EpochRewards) public epochRewards;

  event Bond(address indexed account, uint256 value);
  event Unbond(address indexed account, uint256 value);
  event Withdraw(address indexed account, uint256 rewarded, uint256 maltReward);
  event Forfeit(address indexed account, address token, uint256 amount);
  event Advance(uint256 epoch, uint256 timestamp);
  event DeclareReward(uint256 amountMalt, uint256 amountReward, address rewardToken);
  event SetStabilizerNode(address stabilizerNode);
  event SetNewMaltPeriphery(address maltPeriphery);
  event SetNewReinvestor(address reinvestor);
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

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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
}

pragma solidity >=0.6.6;

interface IMaltPoolPeriphery {
  function maltMarketPrice() external view returns (uint256 price, uint256 decimals);
  function reserves() external view returns (uint256 maltSupply, uint256 rewardSupply);
  function reserveRatio() external view returns (uint256, uint256); 
  function calculateAuctionPricing(
    uint256 rRatio
  ) external returns (uint256 startingPrice, uint256 endingPrice);
  function calculateMintingTradeSize(uint256 dampingFactor) external view returns (uint256);
  function calculateBurningTradeSize() external view returns (uint256);
  function calculateFixedReward(uint256, uint256) external view returns (uint256);
  function realValueOfLPToken(uint256 amount) external view returns (uint256, uint256);
  function getOptimalLiquidity(address tokenA, address tokenB, uint256 liquidityB) external view returns (uint256 liquidityA);
}

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Permissions is AccessControl {
  // Timelock has absolute power across the system
  bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

  // Can mint/burn Malt
  bytes32 public constant MONETARY_REGULATOR_ROLE = keccak256("MONETARY_REGULATOR_ROLE");

  // Contract types
  bytes32 public constant STABILIZER_NODE_ROLE = keccak256("STABILIZER_NODE_ROLE");
  bytes32 public constant LIQUIDITY_MINE_ROLE = keccak256("LIQUIDITY_MINE_ROLE");
  bytes32 public constant AUCTION_ROLE = keccak256("AUCTION_ROLE");

  address internal admin;

  mapping(address => uint256) public lastBlock; // protect against reentrancy

  function _adminSetup(address _timelock) internal {
    _roleSetup(TIMELOCK_ROLE, _timelock);
    _roleSetup(GOVERNOR_ROLE, _timelock);
    _roleSetup(MONETARY_REGULATOR_ROLE, _timelock);
    _roleSetup(STABILIZER_NODE_ROLE, _timelock);

    admin = _timelock;
  }

  function assignRole(bytes32 role, address _assignee)
    external
    onlyRole(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    _setupRole(role, _assignee);
  }

  function removeRole(bytes32 role, address _entity)
    external
    onlyRole(TIMELOCK_ROLE, "Only timelock can revoke roles")
  {
    revokeRole(role, _entity);
  }

  function reassignAdmin(address _admin)
    external
    onlyRole(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    _swapRole(_admin, admin, TIMELOCK_ROLE);
    _swapRole(_admin, admin, GOVERNOR_ROLE);
    _swapRole(_admin, admin, MONETARY_REGULATOR_ROLE);
    _swapRole(_admin, admin, STABILIZER_NODE_ROLE);

    admin = _admin;
  }

  function _swapRole(address newAccount, address oldAccount, bytes32 role) internal {
    revokeRole(role, oldAccount);
    _setupRole(role, newAccount);
  }

  function _roleSetup(bytes32 role, address account) internal {
    _setupRole(role, account);
    _setRoleAdmin(role, TIMELOCK_ROLE);
  }

  function _onlyRole(bytes32 role, string memory reason) internal view {
    require(
      hasRole(
        role,
        _msgSender()
      ),
      reason
    );
  }

  function _notSameBlock() internal {
    require(
      block.number > lastBlock[_msgSender()],
      "Can't carry out actions in the same block"
    );
    lastBlock[_msgSender()] = block.number;
  }

  // Using internal function calls here reduces compiled bytecode size
  modifier onlyRole(bytes32 role, string memory reason) {
    _onlyRole(role, reason);
    _;
  }

  modifier notSameBlock() {
    _notSameBlock();
    _;
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
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

