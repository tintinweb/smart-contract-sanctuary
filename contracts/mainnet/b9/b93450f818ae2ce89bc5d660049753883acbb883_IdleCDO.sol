// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IIdleCDOStrategy.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IIdleCDOTrancheRewards.sol";
import "./interfaces/IStakedAave.sol";

import "./GuardedLaunchUpgradable.sol";
import "./IdleCDOTranche.sol";
import "./IdleCDOStorage.sol";

/// @title A perpetual tranche implementation
/// @author Idle Labs Inc.
/// @notice More info and high level overview in the README
/// @dev The contract is upgradable, to add storage slots, create IdleCDOStorageVX and inherit from IdleCDOStorage, then update the definitaion below
contract IdleCDO is PausableUpgradeable, GuardedLaunchUpgradable, IdleCDOStorage {
  using SafeERC20Upgradeable for IERC20Detailed;

  // ERROR MESSAGES:
  // 0 = is 0
  // 1 = already initialized
  // 2 = Contract limit reached
  // 3 = Tranche withdraw not allowed (Paused or in shutdown)
  // 4 = Default, wait shutdown
  // 5 = Amount too low
  // 6 = Not authorized
  // 7 = Amount too high
  // 8 = Same block

  // Used to prevent initialization of the implementation contract
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    token = address(1);
  }

  // ###################
  // Initializer
  // ###################

  /// @notice can only be called once
  /// @dev Initialize the upgradable contract
  /// @param _limit contract value limit, can be 0
  /// @param _guardedToken underlying token
  /// @param _governanceFund address where funds will be sent in case of emergency
  /// @param _owner guardian address (can pause, unpause and call emergencyShutdown)
  /// @param _rebalancer rebalancer address
  /// @param _strategy strategy address
  /// @param _trancheAPRSplitRatio trancheAPRSplitRatio value
  /// @param _trancheIdealWeightRatio trancheIdealWeightRatio value
  /// @param _incentiveTokens array of addresses for incentive tokens
  function initialize(
    uint256 _limit, address _guardedToken, address _governanceFund, address _owner, // GuardedLaunch args
    address _rebalancer,
    address _strategy,
    uint256 _trancheAPRSplitRatio, // for AA tranches, so eg 10000 means 10% interest to AA and 90% BB
    uint256 _trancheIdealWeightRatio, // for AA tranches, so eg 10000 means 10% of tranches are AA and 90% BB
    address[] memory _incentiveTokens
  ) external initializer {
    uint256 _idealRange = FULL_ALLOC / 10;
    require(token == address(0), '1');
    require(_rebalancer != address(0) && _strategy != address(0) && _guardedToken != address(0), "0");
    require( _trancheAPRSplitRatio <= FULL_ALLOC, '7');
    require(_trancheIdealWeightRatio <= (FULL_ALLOC - _idealRange), '7');
    require(_trancheIdealWeightRatio >= _idealRange, '5');
    // Initialize contracts
    PausableUpgradeable.__Pausable_init();
    // check for _governanceFund and _owner != address(0) are inside GuardedLaunchUpgradable
    GuardedLaunchUpgradable.__GuardedLaunch_init(_limit, _governanceFund, _owner);
    // Deploy Tranches tokens
    address _strategyToken = IIdleCDOStrategy(_strategy).strategyToken();
    // get strategy token symbol (eg. idleDAI)
    string memory _symbol = IERC20Detailed(_strategyToken).symbol();
    // create tranche tokens (concat strategy token symbol in the name and symbol of the tranche tokens)
    AATranche = address(new IdleCDOTranche(_concat(string("IdleCDO AA Tranche - "), _symbol), _concat(string("AA_"), _symbol)));
    BBTranche = address(new IdleCDOTranche(_concat(string("IdleCDO BB Tranche - "), _symbol), _concat(string("BB_"), _symbol)));
    // Set CDO params
    token = _guardedToken;
    strategy = _strategy;
    strategyToken = _strategyToken;
    rebalancer = _rebalancer;
    trancheAPRSplitRatio = _trancheAPRSplitRatio;
    trancheIdealWeightRatio = _trancheIdealWeightRatio;
    idealRange = _idealRange; // trancheIdealWeightRatio ± 10%
    uint256 _oneToken = 10**(IERC20Detailed(_guardedToken).decimals());
    oneToken = _oneToken;
    uniswapRouterV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    incentiveTokens = _incentiveTokens;
    priceAA = _oneToken;
    priceBB = _oneToken;
    unlentPerc = 2000; // 2%
    // # blocks, after an harvest, during which harvested rewards gets progressively unlocked
    releaseBlocksPeriod = 1500; // about 1/4 of a day
    // Set flags
    allowAAWithdraw = true;
    allowBBWithdraw = true;
    revertIfTooLow = true;
    // skipDefaultCheck = false is the default value
    // Set allowance for strategy
    _allowUnlimitedSpend(_guardedToken, _strategy);
    _allowUnlimitedSpend(strategyToken, _strategy);
    // Save current strategy price
    lastStrategyPrice = _strategyPrice();
    // Fee params
    fee = 10000; // 10% performance fee
    feeReceiver = address(0xBecC659Bfc6EDcA552fa1A67451cC6b38a0108E4); // feeCollector
    guardian = _owner;
    // feeSplit = 0; // default all to feeReceiver as default
    // StkAAVE unwrapping is active
    isStkAAVEActive = true;
  }

  // ###############
  // Public methods
  // ###############

  /// @notice pausable
  /// @dev msg.sender should approve this contract first to spend `_amount` of `token`
  /// @param _amount amount of `token` to deposit
  /// @return AA tranche tokens minted
  function depositAA(uint256 _amount) external returns (uint256) {
    return _deposit(_amount, AATranche);
  }

  /// @notice pausable in _deposit
  /// @dev msg.sender should approve this contract first to spend `_amount` of `token`
  /// @param _amount amount of `token` to deposit
  /// @return BB tranche tokens minted
  function depositBB(uint256 _amount) external returns (uint256) {
    return _deposit(_amount, BBTranche);
  }

  /// @notice pausable in _deposit
  /// @param _amount amount of AA tranche tokens to burn
  /// @return underlying tokens redeemed
  function withdrawAA(uint256 _amount) external returns (uint256) {
    require(!paused() || allowAAWithdraw, '3');
    return _withdraw(_amount, AATranche);
  }

  /// @notice pausable
  /// @param _amount amount of BB tranche tokens to burn
  /// @return underlying tokens redeemed
  function withdrawBB(uint256 _amount) external returns (uint256) {
    require(!paused() || allowBBWithdraw, '3');
    return _withdraw(_amount, BBTranche);
  }

  // ###############
  // Views
  // ###############

  /// @param _tranche tranche address
  /// @return tranche price
  function tranchePrice(address _tranche) external view returns (uint256) {
    return _tranchePrice(_tranche);
  }

  /// @notice calculates the current total value locked (in `token` terms)
  /// @dev unclaimed rewards (gov tokens) are not counted.
  /// NOTE: `unclaimedFees` are not included in the contract value
  /// NOTE2: fees that *will* be taken (in the next _updateAccounting call) are counted
  function getContractValue() public override view returns (uint256) {
    address _strategyToken = strategyToken;
    uint256 strategyTokenDecimals = IERC20Detailed(_strategyToken).decimals();
    // TVL is the sum of unlent balance in the contract + the balance in lending - the reduction for harvested rewards - unclaimedFees
    // the balance in lending is the value of the interest bearing assets (strategyTokens) in this contract
    // TVL = (strategyTokens * strategy token price) + unlent balance - lockedRewards - unclaimedFees
    return (_contractTokenBalance(_strategyToken) * _strategyPrice() / (10**(strategyTokenDecimals))) +
            _contractTokenBalance(token) -
            _lockedRewards() -
            unclaimedFees;
  }

  /// @param _tranche tranche address
  /// @return apr at ideal ratio (trancheIdealWeightRatio) between AA and BB
  function getIdealApr(address _tranche) external view returns (uint256) {
    return _getApr(_tranche, trancheIdealWeightRatio);
  }

  /// @param _tranche tranche address
  /// @return actual apr given current ratio between AA and BB tranches
  function getApr(address _tranche) external view returns (uint256) {
    return _getApr(_tranche, getCurrentAARatio());
  }

  /// @notice calculates the current AA tranches ratio
  /// @dev _virtualBalance is used to have a more accurate/recent value for the AA ratio
  /// because it calculates the balance after splitting the accrued interest since the
  /// last depositXX/withdrawXX/harvest
  /// @return AA tranches ratio (in underlying value) considering all interest
  function getCurrentAARatio() public view returns (uint256) {
    uint256 AABal = _virtualBalance(AATranche);
    uint256 contractVal = AABal + _virtualBalance(BBTranche);
    if (contractVal == 0) {
      return 0;
    }
    // Current AA tranche split ratio = AABal * FULL_ALLOC / (AABal + BBBal)
    return AABal * FULL_ALLOC / contractVal;
  }

  /// @notice calculates the current tranches price considering the interest that is yet to be splitted
  /// ie the interest generated since the last update of priceAA and priceBB (done on depositXX/withdrawXX/harvest)
  /// useful for showing updated gains on frontends
  /// @dev this should always be >= of _tranchePrice(_tranche)
  /// @param _tranche address of the requested tranche
  /// @return _virtualPrice tranche price considering all interest
  function virtualPrice(address _tranche) public view returns (uint256 _virtualPrice) {
    // get both NAVs, because we need the total NAV anyway
    uint256 _lastNAVAA = lastNAVAA;
    uint256 _lastNAVBB = lastNAVBB;

    (_virtualPrice, ) = _virtualPricesAux(
      _tranche,
      getContractValue(), // nav
      _lastNAVAA + _lastNAVBB, // lastNAV
      _tranche == AATranche ? _lastNAVAA : _lastNAVBB, // lastTrancheNAV
      trancheAPRSplitRatio
    );
  }

  /// @notice returns an array of tokens used to incentive tranches via IIdleCDOTrancheRewards
  /// @return array with addresses of incentiveTokens (can be empty)
  function getIncentiveTokens() external view returns (address[] memory) {
    return incentiveTokens;
  }

  // ###############
  // Internal
  // ###############

  /// @notice method used to deposit `token` and mint tranche tokens
  /// Ideally users should deposit right after an `harvest` call to maximize profit
  /// @dev this contract must be approved to spend at least _amount of `token` before calling this method
  /// automatically reverts on lending provider default (_strategyPrice decreased)
  /// @param _amount amount of underlyings (`token`) to deposit
  /// @param _tranche tranche address
  /// @return _minted number of tranche tokens minted
  function _deposit(uint256 _amount, address _tranche) internal whenNotPaused returns (uint256 _minted) {
    if (_amount == 0) {
      return _minted;
    }
    // check that we are not depositing more than the contract available limit
    _guarded(_amount);
    // set _lastCallerBlock hash
    _updateCallerBlock();
    // check if _strategyPrice decreased
    _checkDefault();
    // interest accrued since last depositXX/withdrawXX/harvest is splitted between AA and BB
    // according to trancheAPRSplitRatio. NAVs of AA and BB are updated and tranche
    // prices adjusted accordingly
    _updateAccounting();
    // get underlyings from sender
    IERC20Detailed(token).safeTransferFrom(msg.sender, address(this), _amount);
    // mint tranche tokens according to the current tranche price
    _minted = _mintShares(_amount, msg.sender, _tranche);
  }

  /// @notice this method is called on depositXX/withdrawXX/harvest and
  /// updates the accounting of the contract and effectively splits the yield between the
  /// AA and BB tranches
  /// @dev this method:
  /// - update tranche prices (priceAA and priceBB)
  /// - update net asset value for both tranches (lastNAVAA and lastNAVBB)
  /// - update fee accounting (unclaimedFees)
  function _updateAccounting() internal {
    uint256 _lastNAVAA = lastNAVAA;
    uint256 _lastNAVBB = lastNAVBB;
    uint256 _lastNAV = _lastNAVAA + _lastNAVBB;
    uint256 nav = getContractValue();
    uint256 _aprSplitRatio = trancheAPRSplitRatio;

    // If gain is > 0, then collect some fees in `unclaimedFees`
    if (nav > _lastNAV) {
      unclaimedFees += (nav - _lastNAV) * fee / FULL_ALLOC;
    }

    (uint256 _priceAA, uint256 _totalAAGain) = _virtualPricesAux(AATranche, nav, _lastNAV, _lastNAVAA, _aprSplitRatio);
    (uint256 _priceBB, uint256 _totalBBGain) = _virtualPricesAux(BBTranche, nav, _lastNAV, _lastNAVBB, _aprSplitRatio);

    lastNAVAA += _totalAAGain;
    lastNAVBB += _totalBBGain;
    priceAA = _priceAA;
    priceBB = _priceBB;
  }

  /// @notice calculates the NAV for a tranche considering the interest that is yet to be splitted
  /// @param _tranche address of the requested tranche
  /// @return net asset value, in underlying tokens, for _tranche considering all nav
  function _virtualBalance(address _tranche) internal view returns (uint256) {
    // balance is: tranche supply * virtual tranche price
    return IdleCDOTranche(_tranche).totalSupply() * virtualPrice(_tranche) / ONE_TRANCHE_TOKEN;
  }

  /// @notice calculates the current tranches price considering the interest that is yet to be splitted and the
  /// total gain for a specific tranche
  /// @param _tranche address of the requested tranche
  /// @param _nav current NAV
  /// @param _lastNAV last saved NAV
  /// @param _lastTrancheNAV last saved tranche NAV
  /// @param _trancheAPRSplitRatio APR split ratio for AA tranche
  /// @return _virtualPrice tranche price considering all interest
  /// @return _totalTrancheGain tranche gain since last update
  function _virtualPricesAux(
    address _tranche,
    uint256 _nav,
    uint256 _lastNAV,
    uint256 _lastTrancheNAV,
    uint256 _trancheAPRSplitRatio
  ) internal view returns (uint256 _virtualPrice, uint256 _totalTrancheGain) {
    // If there is no gain return the current price
    if (_nav <= _lastNAV) {
      return (_tranchePrice(_tranche), 0);
    }

    // Check if there are tranche holders
    uint256 trancheSupply = IdleCDOTranche(_tranche).totalSupply();
    if (_lastNAV == 0 || trancheSupply == 0) {
      return (oneToken, 0);
    }
    // In order to correctly split the interest generated between AA and BB tranche holders
    // (according to the trancheAPRSplitRatio) we need to know how much interest we gained
    // since the last price update (during a depositXX/withdrawXX/harvest)
    // To do that we need to get the current value of the assets in this contract
    // and the last saved one (always during a depositXX/withdrawXX/harvest)

    // Calculate the total gain
    uint256 totalGain = _nav - _lastNAV;
    // Remove performance fee
    totalGain -= totalGain * fee / FULL_ALLOC;

    address _AATranche = AATranche;
    bool _isAATranche = _tranche == _AATranche;
    // Get the supply of the other tranche and
    // if it's 0 then give all gain to the current `_tranche` holders
    if (IdleCDOTranche(_isAATranche ? BBTranche : _AATranche).totalSupply() == 0) {
      _totalTrancheGain = totalGain;
    } else {
      // Split the net gain, with precision loss favoring the AA tranche.
      uint256 totalBBGain = totalGain * (FULL_ALLOC - _trancheAPRSplitRatio) / FULL_ALLOC;
      // The new NAV for the tranche is old NAV + total gain for the tranche
      _totalTrancheGain = _isAATranche ? (totalGain - totalBBGain) : totalBBGain;
    }
    // Split the new NAV (_lastTrancheNAV + _totalTrancheGain) per tranche token
    _virtualPrice = (_lastTrancheNAV + _totalTrancheGain) * ONE_TRANCHE_TOKEN / trancheSupply;
  }

  /// @notice mint tranche tokens and updates tranche last NAV
  /// @param _amount, in underlyings, to convert in tranche tokens
  /// @param _to receiver address of the newly minted tranche tokens
  /// @param _tranche tranche address
  /// @return _minted number of tranche tokens minted
  function _mintShares(uint256 _amount, address _to, address _tranche) internal returns (uint256 _minted) {
    // calculate # of tranche token to mint based on current tranche price: _amount / tranchePrice
    _minted = _amount * ONE_TRANCHE_TOKEN / _tranchePrice(_tranche);
    IdleCDOTranche(_tranche).mint(_to, _minted);
    // update NAV with the _amount of underlyings added
    if (_tranche == AATranche) {
      lastNAVAA += _amount;
    } else {
      lastNAVBB += _amount;
    }
  }

  /// @notice convert fees (`unclaimedFees`) in AA tranche tokens
  /// Tranche tokens are then automatically staked in the relative IdleCDOTrancheRewards contact if present
  /// @dev this will be called only during harvests
  function _depositFees() internal {
    uint256 _amount = unclaimedFees;
    if (_amount > 0) {
      address stakingRewards = AAStaking;
      bool isStakingRewardsActive = stakingRewards != address(0);
      address _feeReceiver = feeReceiver;
      address _referral = referral;
      uint256 _referralAmount;
      if (_referral != address(0)) {
        // If the contract has a referral, then we give the referral a share of the fees (in AA tranche tokens)
        _referralAmount = _amount * feeSplit / FULL_ALLOC;
        _mintShares(_referralAmount, _referral, AATranche);
      }

      // mint tranches tokens to this contract
      uint256 _minted = _mintShares(_amount - _referralAmount,
        isStakingRewardsActive ? address(this) : _feeReceiver,
        // Mint AA tranche tokens as fees
        AATranche
      );
      // reset unclaimedFees counter
      unclaimedFees = 0;

      // auto stake fees in staking contract for feeReceiver
      if (isStakingRewardsActive) {
        IIdleCDOTrancheRewards(stakingRewards).stakeFor(_feeReceiver, _minted);
      }
    }
  }

  /// @notice It allows users to burn their tranche token and redeem their principal + interest back
  /// @dev automatically reverts on lending provider default (_strategyPrice decreased).
  /// @param _amount in tranche tokens
  /// @param _tranche tranche address
  /// @return toRedeem number of underlyings redeemed
  function _withdraw(uint256 _amount, address _tranche) internal nonReentrant returns (uint256 toRedeem) {
    // check if a deposit is made in the same block from the same user
    _checkSameTx();
    // check if _strategyPrice decreased
    _checkDefault();
    // accrue interest to tranches and updates tranche prices
    _updateAccounting();
    // redeem all user balance if 0 is passed as _amount
    if (_amount == 0) {
      _amount = IERC20Detailed(_tranche).balanceOf(msg.sender);
    }
    require(_amount > 0, '0');
    address _token = token;
    // get current available unlent balance
    uint256 balanceUnderlying = _contractTokenBalance(_token);
    // Calculate the amount to redeem
    toRedeem = _amount * _tranchePrice(_tranche) / ONE_TRANCHE_TOKEN;
    if (toRedeem > balanceUnderlying) {
      // if the unlent balance is not enough we try to redeem what's missing directly from the strategy
      // and then add it to the current unlent balance
      // NOTE: A difference of up to 100 wei due to rounding is tolerated
      toRedeem = _liquidate(toRedeem - balanceUnderlying, revertIfTooLow) + balanceUnderlying;
    }
    // burn tranche token
    IdleCDOTranche(_tranche).burn(msg.sender, _amount);
    // send underlying to msg.sender
    IERC20Detailed(_token).safeTransfer(msg.sender, toRedeem);

    // update NAV with the _amount of underlyings removed
    if (_tranche == AATranche) {
      lastNAVAA -= toRedeem;
    } else {
      lastNAVBB -= toRedeem;
    }
  }

  /// @dev check if _strategyPrice is decreased since last update and updates last saved strategy price
  function _checkDefault() internal {
    uint256 currPrice = _strategyPrice();
    if (!skipDefaultCheck) {
      require(lastStrategyPrice <= currPrice, "4");
    }
    lastStrategyPrice = currPrice;
  }

  /// @return strategy price, in underlyings
  function _strategyPrice() internal view returns (uint256) {
    return IIdleCDOStrategy(strategy).price();
  }

  /// @dev this should liquidate at least _amount of `token` from the lending provider or revertIfNeeded
  /// @param _amount in underlying tokens
  /// @param _revertIfNeeded flag whether to revert or not if the redeemed amount is not enough
  /// @return _redeemedTokens number of underlyings redeemed
  function _liquidate(uint256 _amount, bool _revertIfNeeded) internal returns (uint256 _redeemedTokens) {
    _redeemedTokens = IIdleCDOStrategy(strategy).redeemUnderlying(_amount);
    if (_revertIfNeeded) {
      // keep 100 wei as margin for rounding errors
      require(_redeemedTokens + 100 >= _amount, '5');
    }
    if (_redeemedTokens > _amount) {
      _redeemedTokens = _amount;
    }
  }

  /// @notice sends rewards to the tranche rewards staking contracts
  /// @dev this method is called only during harvests
  function _updateIncentives() internal {
    // Read state variables only once to save gas
    uint256 _trancheIdealWeightRatio = trancheIdealWeightRatio;
    uint256 _trancheAPRSplitRatio = trancheAPRSplitRatio;
    uint256 _idealRange = idealRange;
    address _BBStaking = BBStaking;
    address _AAStaking = AAStaking;
    bool _isBBStakingActive = _BBStaking != address(0);
    bool _isAAStakingActive = _AAStaking != address(0);

    uint256 currAARatio;
    if (_isBBStakingActive && _isAAStakingActive) {
      currAARatio = getCurrentAARatio();
    }

    // Check if BB tranches should be rewarded (if AA ratio is too high)
    if (_isBBStakingActive && (!_isAAStakingActive || (currAARatio > (_trancheIdealWeightRatio + _idealRange)))) {
      // give more rewards to BB holders, ie send some rewards to BB Staking contract
      return _depositIncentiveToken(_BBStaking, FULL_ALLOC);
    }
    // Check if AA tranches should be rewarded (id AA ratio is too low)
    if (_isAAStakingActive && (!_isBBStakingActive || (currAARatio < (_trancheIdealWeightRatio - _idealRange)))) {
      // give more rewards to AA holders, ie send some rewards to AA Staking contract
      return _depositIncentiveToken(_AAStaking, FULL_ALLOC);
    }

    // Split rewards according to trancheAPRSplitRatio in case the ratio between
    // AA and BB is already ideal
    if (_isAAStakingActive) {
      // NOTE: the order is important here, first there must be the deposit for AA rewards,
      // if staking contract for AA is present
      _depositIncentiveToken(_AAStaking, _trancheAPRSplitRatio);
    }

    if (_isBBStakingActive) {
      // NOTE: here we should use FULL_ALLOC directly and not (FULL_ALLOC - _trancheAPRSplitRatio)
      // because contract balance for incentive tokens is fetched at each _depositIncentiveToken
      // and the balance for AA is already transferred
      _depositIncentiveToken(_BBStaking, FULL_ALLOC);
    }
  }

  /// @notice sends requested ratio of reward to a specific IdleCDOTrancheRewards contract
  /// @param _stakingContract address which will receive incentive Rewards
  /// @param _ratio ratio of the incentive token balance to send
  function _depositIncentiveToken(address _stakingContract, uint256 _ratio) internal {
    address[] memory _incentiveTokens = incentiveTokens;
    for (uint256 i = 0; i < _incentiveTokens.length; i++) {
      address _incentiveToken = _incentiveTokens[i];
      // calculates the requested _ratio of the current contract balance of
      // _incentiveToken to be sent to the IdleCDOTrancheRewards contract
      uint256 _reward = _contractTokenBalance(_incentiveToken) * _ratio / FULL_ALLOC;
      if (_reward > 0) {
        // call depositReward to actually let the IdleCDOTrancheRewards get the reward
        IIdleCDOTrancheRewards(_stakingContract).depositReward(_incentiveToken, _reward);
      }
    }
  }

  /// @notice method used to sell `_rewardToken` for `_token` on uniswap
  /// @param _rewardToken address of the token to sell
  /// @param _path uniswap path for the trade
  /// @param _amount of `_rewardToken` to sell
  /// @param _minAmount min amount of `_token` to buy
  /// @return _amount of _rewardToken sold
  /// @return _amount received for the sell
  function _sellReward(address _rewardToken, address[] memory _path, uint256 _amount, uint256 _minAmount)
    internal
    returns (uint256, uint256) {
    // If 0 is passed as sell amount, we get the whole contract balance
    if (_amount == 0) {
      _amount = _contractTokenBalance(_rewardToken);
    }
    if (_amount == 0) {
      return (0, 0);
    }

    IUniswapV2Router02 _uniRouter = uniswapRouterV2;
    // approve the uniswap router to spend our reward
    IERC20Detailed(_rewardToken).safeIncreaseAllowance(address(_uniRouter), _amount);
    // do the trade with all `_rewardToken` in this contract
    uint256[] memory _amounts = _uniRouter.swapExactTokensForTokens(
      _amount,
      _minAmount,
      _path,
      address(this),
      block.timestamp + 1
    );
    // return the amount swapped and the amount received
    return (_amounts[0], _amounts[_amounts.length - 1]);
  }

  /// @notice method used to sell all sellable rewards for `_token` on uniswap
  /// @param _strategy IIdleCDOStrategy stategy instance
  /// @param _sellAmounts array with amounts of rewards to sell
  /// @param _minAmount array with amounts of _token buy for each reward sold. (should have the same length as _sellAmounts)
  /// @param _skipReward array of flags for skipping the market sell of specific rewards (should have the same length as _sellAmounts)
  /// @return _soldAmounts array with amounts of rewards actually sold
  /// @return _swappedAmounts array with amounts of _token actually bought
  /// @return _totSold total rewards sold in `_token`
  function _sellAllRewards(IIdleCDOStrategy _strategy, uint256[] memory _sellAmounts, uint256[] memory _minAmount, bool[] memory _skipReward)
    internal
    returns (uint256[] memory _soldAmounts, uint256[] memory _swappedAmounts, uint256 _totSold) {
    // Fetch state variables once to save gas
    address[] memory _incentiveTokens = incentiveTokens;
    // get all rewards addresses
    address[] memory _rewards = _strategy.getRewardTokens();
    address _rewardToken;
    // Prepare path for uniswap trade
    address[] memory _path = new address[](3);
    // _path[0] will be the reward token to sell
    _path[1] = weth;
    _path[2] = token;
    // Initialize the return array, containing the amounts received after swapping reward tokens
    _soldAmounts = new uint256[](_rewards.length);
    _swappedAmounts = new uint256[](_rewards.length);
    // loop through all reward tokens
    for (uint256 i = 0; i < _rewards.length; i++) {
      _rewardToken = _rewards[i];
      // check if it should be sold or not
      if (_skipReward[i] || _includesAddress(_incentiveTokens, _rewardToken)) { continue; }
      // do not sell stkAAVE but only AAVE if present
      if (_rewardToken == stkAave) {
        _rewardToken = AAVE;
      }
      // set token to sell in the uniswap path
      _path[0] = _rewardToken;
      // Market sell _rewardToken in this contract for _token
      (_soldAmounts[i], _swappedAmounts[i]) = _sellReward(_rewardToken, _path, _sellAmounts[i], _minAmount[i]);
      _totSold += _swappedAmounts[i];
    }
  }

  /// @param _tranche tranche address
  /// @return last saved tranche price, in underlyings
  function _tranchePrice(address _tranche) internal view returns (uint256) {
    if (IdleCDOTranche(_tranche).totalSupply() == 0) {
      return oneToken;
    }
    return _tranche == AATranche ? priceAA : priceBB;
  }

  /// @notice returns the current apr for a tranche based on trancheAPRSplitRatio and the provided AA ratio
  /// @dev the apr for a tranche can be higher than the strategy apr
  /// @param _tranche tranche token address
  /// @param _AATrancheSplitRatio AA split ratio used for calculations
  /// @return apr for the specific tranche
  function _getApr(address _tranche, uint256 _AATrancheSplitRatio) internal view returns (uint256) {
    uint256 stratApr = IIdleCDOStrategy(strategy).getApr();
    uint256 _trancheAPRSplitRatio = trancheAPRSplitRatio;
    bool isAATranche = _tranche == AATranche;
    if (_AATrancheSplitRatio == 0) {
      // if there are no AA tranches, apr for AA is 0 (all apr to BB and it will be equal to stratApr)
      return isAATranche ? 0 : stratApr;
    }
    return isAATranche ?
      // AA apr is: stratApr * AAaprSplitRatio / AASplitRatio
      stratApr * _trancheAPRSplitRatio / _AATrancheSplitRatio :
      // BB apr is: stratApr * BBaprSplitRatio / BBSplitRatio -> where
      // BBaprSplitRatio is: (FULL_ALLOC - _trancheAPRSplitRatio) and
      // BBSplitRatio is: (FULL_ALLOC - _AATrancheSplitRatio)
      stratApr * (FULL_ALLOC - _trancheAPRSplitRatio) / (FULL_ALLOC - _AATrancheSplitRatio);
  }

  /// @return _locked amount of harvested rewards that are still not available to be redeemed
  function _lockedRewards() internal view returns (uint256 _locked) {
    uint256 _releaseBlocksPeriod = releaseBlocksPeriod;
    uint256 _blocksSinceLastHarvest = block.number - latestHarvestBlock;
    uint256 _harvestedRewards = harvestedRewards;

    // NOTE: _harvestedRewards is never set to 0, but rather to 1 to save some gas
    if (_harvestedRewards > 1 && _blocksSinceLastHarvest < _releaseBlocksPeriod) {
      // progressively release harvested rewards
      _locked = _harvestedRewards * (_releaseBlocksPeriod - _blocksSinceLastHarvest) / _releaseBlocksPeriod;
    }
  }

  /// @notice used to start the cooldown for unstaking stkAAVE and claiming AAVE rewards (for the contract itself)
  function _claimStkAave() internal {
    if (!isStkAAVEActive) {
      return;
    }

    IStakedAave _stkAave = IStakedAave(stkAave);
    uint256 _stakersCooldown = _stkAave.stakersCooldowns(address(this));
    // If there is a pending cooldown:
    if (_stakersCooldown > 0) {
      // If it is over, redeem stkAave and begin new cooldown
      if (_stakersCooldown + _stkAave.COOLDOWN_SECONDS() < block.timestamp) {
        _stkAave.redeem(address(this), type(uint256).max);
      } else {
        // If it is not over, do nothing
        return;
      }
    }

    // Pull new stkAAVE rewards
    IIdleCDOStrategy(strategy).pullStkAAVE();

    // If there's no pending cooldown or we just redeem the prev locked rewards,
    // then begin a new cooldown
    if (_stkAave.balanceOf(address(this)) > 0) {
      // start a new cooldown
      _stkAave.cooldown();
    }
  }

  // ###################
  // Protected
  // ###################

  /// @notice This method is used to lend user funds in the lending provider through the IIdleCDOStrategy and update tranches incentives.
  /// The method:
  /// - redeems rewards (if any) from the lending provider
  /// - converts the rewards NOT present in the `incentiveTokens` array, in underlyings through uniswap v2
  /// - calls _updateAccounting to update the accounting of the system with the new underlyings received
  /// - it then convert fees in tranche tokens and stake tranche tokens in the IdleCDOTrancheRewards if any
  /// - sends the correct amount of `incentiveTokens` to the each of the IdleCDOTrancheRewards contracts
  /// - Finally it deposits the (initial unlent balance + the underlyings get from uniswap - fees) in the
  ///   lending provider through the IIdleCDOStrategy `deposit` call
  /// The method will be called by an external, whitelisted, keeper bot which will call the method sistematically (eg once a day)
  /// @dev can be called only by the rebalancer or the owner
  /// @param _skipFlags array of flags, [0] = skip reward redemption, [1] = skip incentives update, [2] = skip fee deposit, [3] = skip all
  /// @param _skipReward array of flags for skipping the market sell of specific rewards. Length should be equal to the `IIdleCDOStrategy(strategy).getRewardTokens()` array
  /// @param _minAmount array of min amounts for uniswap trades. Lenght should be equal to the _skipReward array
  /// @param _sellAmounts array of amounts (of reward tokens) to sell on uniswap. Lenght should be equal to the _minAmount array
  /// if a sellAmount is 0 the whole contract balance for that token is swapped
  /// @param _extraData bytes to be passed to the redeemRewards call
  /// @return _res array of arrays with the following elements:
  ///   [0] _soldAmounts array with amounts of rewards actually sold
  ///   [1] _swappedAmounts array with amounts of _token actually bought
  ///   [2] _redeemedRewards array with amounts of rewards redeemed
  function harvest(
    // _skipFlags[0] _skipRedeem,
    // _skipFlags[1] _skipIncentivesUpdate,
    // _skipFlags[2] _skipFeeDeposit,
    // _skipFlags[3] _skipRedeem && _skipIncentivesUpdate && _skipFeeDeposit,
    bool[] calldata _skipFlags,
    bool[] calldata _skipReward,
    uint256[] calldata _minAmount,
    uint256[] calldata _sellAmounts,
    bytes calldata _extraData
  ) external
    returns (uint256[][] memory _res) {
    _checkOnlyOwnerOrRebalancer();
    // initalize the returned array (elements will be [_soldAmounts, _swappedAmounts, _redeemedRewards])
    _res = new uint256[][](3);
    // Fetch state variable once to save gas
    IIdleCDOStrategy _strategy = IIdleCDOStrategy(strategy);
    // Check whether to redeem rewards from strategy or not
    if (!_skipFlags[3]) {
      uint256 _totSold;

      if (!_skipFlags[0]) {
        // Redeem all rewards associated with the strategy
        _res[2] = _strategy.redeemRewards(_extraData);
        // Redeem unlocked AAVE if any and start a new cooldown for stkAAVE
        _claimStkAave();
        // Sell rewards
        (_res[0], _res[1], _totSold) = _sellAllRewards(_strategy, _sellAmounts, _minAmount, _skipReward);
      }
      // update last saved harvest block number
      latestHarvestBlock = block.number;
      // update harvested rewards value (avoid setting it to 0 to save some gas)
      harvestedRewards = _totSold == 0 ? 1 : _totSold;

      // split converted rewards if any and update tranche prices
      // NOTE: harvested rewards won't be counted directly but released over time
      _updateAccounting();

      if (!_skipFlags[2]) {
        // Get fees in the form of totalSupply diluition
        _depositFees();
      }

      if (!_skipFlags[1]) {
        // Update tranche incentives distribution and send rewards to staking contracts
        _updateIncentives();
      }
    }

    // Deposit the remaining balance in the lending provider and 
    // keep some unlent balance for cheap redeems and as reserve of last resort
    uint256 underlyingBal = _contractTokenBalance(token);
    uint256 idealUnlent = getContractValue() * unlentPerc / FULL_ALLOC;
    if (underlyingBal > idealUnlent) {
      // Put unlent balance at work in the lending provider
      _strategy.deposit(underlyingBal - idealUnlent);
    }
  }

  /// @notice method used to redeem underlyings from the lending provider
  /// @dev can be called only by the rebalancer or the owner
  /// @param _amount in underlyings to liquidate from lending provider
  /// @param _revertIfNeeded flag to revert if amount liquidated is too low
  /// @return liquidated amount in underlyings
  function liquidate(uint256 _amount, bool _revertIfNeeded) external returns (uint256) {
    _checkOnlyOwnerOrRebalancer();
    return _liquidate(_amount, _revertIfNeeded);
  }

  // ###################
  // onlyOwner
  // ###################

  /// @param _allowed flag to allow AA withdraws
  function setAllowAAWithdraw(bool _allowed) external {
    _checkOnlyOwner();
    allowAAWithdraw = _allowed;
  }

  /// @param _allowed flag to allow BB withdraws
  function setAllowBBWithdraw(bool _allowed) external {
    _checkOnlyOwner();
    allowBBWithdraw = _allowed;
  }

  /// @param _allowed flag to enable the 'default' check (whether _strategyPrice decreased or not)
  function setSkipDefaultCheck(bool _allowed) external {
    _checkOnlyOwner();
    skipDefaultCheck = _allowed;
  }

  /// @param _allowed flag to enable the check if redeemed amount during liquidations is enough
  function setRevertIfTooLow(bool _allowed) external {
    _checkOnlyOwner();
    revertIfTooLow = _allowed;
  }

  /// @notice updates the strategy used (potentially changing the lending protocol used)
  /// @dev it's REQUIRED to liquidate / redeem everything from the lending provider before changing strategy
  /// if the leding provider of the new strategy is different from the current one
  /// it's also REQUIRED to transfer out any incentive tokens accrued if those are changed from the current ones
  /// if the lending provider is changed
  /// @param _strategy new strategy address
  /// @param _incentiveTokens array of incentive tokens addresses
  function setStrategy(address _strategy, address[] memory _incentiveTokens) external {
    _checkOnlyOwner();

    require(_strategy != address(0), '0');
    IERC20Detailed _token = IERC20Detailed(token);
    // revoke allowance for the current strategy
    address _currStrategy = strategy;
    _removeAllowance(address(_token), _currStrategy);
    _removeAllowance(strategyToken, _currStrategy);
    // Updated strategy variables
    strategy = _strategy;
    // Update incentive tokens
    incentiveTokens = _incentiveTokens;
    // Update strategyToken
    address _newStrategyToken = IIdleCDOStrategy(_strategy).strategyToken();
    strategyToken = _newStrategyToken;
    // Approve underlyingToken
    _allowUnlimitedSpend(address(_token), _strategy);
    // Approve the new strategy to transfer strategyToken out from this contract
    _allowUnlimitedSpend(_newStrategyToken, _strategy);
    // Update last strategy price
    lastStrategyPrice = _strategyPrice();
  }

  /// @param _rebalancer new rebalancer address
  function setRebalancer(address _rebalancer) external {
    _checkOnlyOwner();
    require((rebalancer = _rebalancer) != address(0), '0');
  }

  /// @param _feeReceiver new fee receiver address
  function setFeeReceiver(address _feeReceiver) external {
    _checkOnlyOwner();
    require((feeReceiver = _feeReceiver) != address(0), '0');
  }

  /// @notice set new referral address
  /// @dev can be called only by the owner
  /// @param _referral new referral address (can be address(0))
  function setReferral(address _referral) external {
    _checkOnlyOwner();
    referral = _referral;
  }

  /// @param _guardian new guardian (pauser) address
  function setGuardian(address _guardian) external {
    _checkOnlyOwner();
    require((guardian = _guardian) != address(0), '0');
  }

  /// @param _fee new fee
  function setFee(uint256 _fee) external {
    _checkOnlyOwner();
    require((fee = _fee) <= MAX_FEE, '7');
  }

  /// @notice set fee split between feeReceiver and referral (if any). If referral is not set, fee goes to feeReceiver.
  /// @dev can be called only by the owner
  /// @param _feeSplit new fee split
  function setFeeSplit(uint256 _feeSplit) external {
    _checkOnlyOwner();
    require((feeSplit = _feeSplit) <= FULL_ALLOC, '8');
  }

  /// @param _unlentPerc new unlent percentage
  function setUnlentPerc(uint256 _unlentPerc) external {
    _checkOnlyOwner();
    require((unlentPerc = _unlentPerc) <= FULL_ALLOC, '7');
  }

  /// @param _releaseBlocksPeriod new # of blocks after an harvest during which
  /// harvested rewards gets progressively redistriburted to users
  function setReleaseBlocksPeriod(uint256 _releaseBlocksPeriod) external {
    _checkOnlyOwner();
    releaseBlocksPeriod = _releaseBlocksPeriod;
  }

  /// @param _isStkAAVEActive whether the contract receive stkAAVE or not
  function setIsStkAAVEActive(bool _isStkAAVEActive) external {
    _checkOnlyOwner();
    isStkAAVEActive = _isStkAAVEActive;
  }

  /// @param _idealRange new ideal range
  function setIdealRange(uint256 _idealRange) external {
    _checkOnlyOwner();
    require((idealRange = _idealRange) <= FULL_ALLOC, '7');
  }

  /// @param _trancheAPRSplitRatio new apr split ratio
  function setTrancheAPRSplitRatio(uint256 _trancheAPRSplitRatio) external {
    _checkOnlyOwner();
    require((trancheAPRSplitRatio = _trancheAPRSplitRatio) <= FULL_ALLOC, '7');
  }

  /// @param _trancheIdealWeightRatio new ideal weight ratio (for incentives)
  function setTrancheIdealWeightRatio(uint256 _trancheIdealWeightRatio) external {
    _checkOnlyOwner();
    require((_trancheIdealWeightRatio) >= idealRange, '5');
    require((trancheIdealWeightRatio = _trancheIdealWeightRatio) <= (FULL_ALLOC - idealRange), '7');
  }

  /// @dev it's REQUIRED to transfer out any incentive tokens accrued before
  /// @param _incentiveTokens array with new incentive tokens
  function setIncentiveTokens(address[] memory _incentiveTokens) external {
    _checkOnlyOwner();
    incentiveTokens = _incentiveTokens;
  }

  /// @notice Set tranche Rewards contract addresses (for tranches incentivization)
  /// @param _AAStaking IdleCDOTrancheRewards contract address for AA tranches
  /// @param _BBStaking IdleCDOTrancheRewards contract address for BB tranches
  function setStakingRewards(address _AAStaking, address _BBStaking) external {
    _checkOnlyOwner();
    // Read state variable once
    address _AATranche = AATranche;
    address _BBTranche = BBTranche;
    address[] memory _incentiveTokens = incentiveTokens;
    address _currAAStaking = AAStaking;
    address _currBBStaking = BBStaking;
    bool _isAAStakingActive = _currAAStaking != address(0);
    bool _isBBStakingActive = _currBBStaking != address(0);
    address _incentiveToken;
    // Remove allowance for incentive tokens for current staking contracts
    for (uint256 i = 0; i < _incentiveTokens.length; i++) {
      _incentiveToken = _incentiveTokens[i];
      if (_isAAStakingActive) {
        _removeAllowance(_incentiveToken, _currAAStaking);
      }
      if (_isBBStakingActive) {
        _removeAllowance(_incentiveToken, _currBBStaking);
      }
    }
    // Remove allowace for tranche tokens (used for staking fees)
    if (_isAAStakingActive && _AATranche != address(0)) {
      _removeAllowance(_AATranche, _currAAStaking);
    }
    if (_isBBStakingActive && _BBTranche != address(0)) {
      _removeAllowance(_BBTranche, _currBBStaking);
    }

    // Update staking contract addresses
    AAStaking = _AAStaking;
    BBStaking = _BBStaking;

    _isAAStakingActive = _AAStaking != address(0);
    _isBBStakingActive = _BBStaking != address(0);

    // Increase allowance for incentiveTokens
    for (uint256 i = 0; i < _incentiveTokens.length; i++) {
      _incentiveToken = _incentiveTokens[i];
      // Approve each staking contract to spend each incentiveToken on beahlf of this contract
      if (_isAAStakingActive) {
        _allowUnlimitedSpend(_incentiveToken, _AAStaking);
      }
      if (_isBBStakingActive) {
        _allowUnlimitedSpend(_incentiveToken, _BBStaking);
      }
    }

    // Increase allowance for tranche tokens (used for staking fees)
    if (_isAAStakingActive && _AATranche != address(0)) {
      _allowUnlimitedSpend(_AATranche, _AAStaking);
    }
    if (_isBBStakingActive && _BBTranche != address(0)) {
      _allowUnlimitedSpend(_BBTranche, _BBStaking);
    }
  }

  /// @notice pause deposits and redeems for all classes of tranches
  /// @dev can be called by both the owner and the guardian
  function emergencyShutdown() external {
    _checkOnlyOwnerOrGuardian();
    // prevent deposits
    _pause();
    // prevent withdraws
    allowAAWithdraw = false;
    allowBBWithdraw = false;
    // Allow deposits/withdraws (once selectively re-enabled, eg for AA holders)
    // without checking for lending protocol default
    skipDefaultCheck = true;
    revertIfTooLow = true;
  }

  /// @notice Pauses deposits and redeems
  /// @dev can be called by both the owner and the guardian
  function pause() external  {
    _checkOnlyOwnerOrGuardian();
    _pause();
  }

  /// @notice Unpauses deposits and redeems
  /// @dev can be called by both the owner and the guardian
  function unpause() external {
    _checkOnlyOwnerOrGuardian();
    _unpause();
  }

  // ###################
  // Helpers
  // ###################

  /// @dev Check that the msg.sender is the either the owner or the guardian
  function _checkOnlyOwnerOrGuardian() internal view {
    require(msg.sender == guardian || msg.sender == owner(), "6");
  }

  /// @dev Check that the msg.sender is the either the owner or the rebalancer
  function _checkOnlyOwnerOrRebalancer() internal view {
    require(msg.sender == rebalancer || msg.sender == owner(), "6");
  }

  /// @notice returns the current balance of this contract for a specific token
  /// @param _token token address
  /// @return balance of `_token` for this contract
  function _contractTokenBalance(address _token) internal view returns (uint256) {
    return IERC20Detailed(_token).balanceOf(address(this));
  }

  /// @dev Set allowance for _token to 0 for _spender
  /// @param _token token address
  /// @param _spender spender address
  function _removeAllowance(address _token, address _spender) internal {
    IERC20Detailed(_token).safeApprove(_spender, 0);
  }

  /// @dev Set allowance for _token to unlimited for _spender
  /// @param _token token address
  /// @param _spender spender address
  function _allowUnlimitedSpend(address _token, address _spender) internal {
    IERC20Detailed(_token).safeIncreaseAllowance(_spender, type(uint256).max);
  }

  /// @dev Set last caller and block.number hash. This should be called at the beginning of the first function to protect
  function _updateCallerBlock() internal {
    _lastCallerBlock = keccak256(abi.encodePacked(tx.origin, block.number));
  }

  /// @dev Check that the second function is not called in the same tx from the same tx.origin
  function _checkSameTx() internal view {
    require(keccak256(abi.encodePacked(tx.origin, block.number)) != _lastCallerBlock, "8");
  }

  /// @dev this method is only used to check whether a token is an incentive tokens or not
  /// in the harvest call. The maximum number of element in the array will be a small number (eg at most 3-5)
  /// @param _array array of addresses to search for an element
  /// @param _val address of an element to find
  /// @return flag if the _token is an incentive token or not
  function _includesAddress(address[] memory _array, address _val) internal pure returns (bool) {
    for (uint256 i = 0; i < _array.length; i++) {
      if (_array[i] == _val) {
        return true;
      }
    }
    // explicit return to fix linter
    return false;
  }

  /// @notice concat 2 strings in a single one
  /// @param a first string
  /// @param b second string
  /// @return new string with a and b concatenated
  function _concat(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IIdleCDOStrategy {
  function strategyToken() external view returns(address);
  function token() external view returns(address);
  function tokenDecimals() external view returns(uint256);
  function oneToken() external view returns(uint256);
  function redeemRewards(bytes calldata _extraData) external returns(uint256[] memory);
  function pullStkAAVE() external returns(uint256);
  function price() external view returns(uint256);
  function getRewardTokens() external view returns(address[] memory);
  function deposit(uint256 _amount) external returns(uint256);
  // _amount in `strategyToken`
  function redeem(uint256 _amount) external returns(uint256);
  // _amount in `token`
  function redeemUnderlying(uint256 _amount) external returns(uint256);
  function getApr() external view returns(uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Detailed is IERC20Upgradeable {
  function name() external view returns(string memory);
  function symbol() external view returns(string memory);
  function decimals() external view returns(uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IIdleCDOTrancheRewards {
  function stake(uint256 _amount) external;
  function stakeFor(address _user, uint256 _amount) external;
  function unstake(uint256 _amount) external;
  function depositReward(address _reward, uint256 _amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IStakedAave {
  function COOLDOWN_SECONDS() external view returns (uint256);
  function redeem(address to, uint256 amount) external;
  function cooldown() external;
  function balanceOf(address) external view returns (uint256);
  function stakersCooldowns(address) external view returns (uint256);
}

//SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice This abstract contract is used to add an updatable limit on the total value locked
/// that the contract can have. It also have an emergency method that allows the owner to pull
/// funds into predefined recovery address
/// @dev Inherit this contract and add the _guarded method to the child contract
abstract contract GuardedLaunchUpgradable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // ERROR MESSAGES:
  // 0 = is 0
  // 1 = already initialized
  // 2 = Contract limit reached

  // TVL limit in underlying value
  uint256 public limit;
  // recovery address
  address public governanceRecoveryFund;

  /// @param _limit TVL limit. (0 means unlimited)
  /// @param _governanceRecoveryFund recovery address
  /// @param _owner owner address
  function __GuardedLaunch_init(uint256 _limit, address _governanceRecoveryFund, address _owner) internal {
    require(_governanceRecoveryFund != address(0), '0');
    require(_owner != address(0), '0');
    // Initialize inherited contracts
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    // Initialize state variables
    limit = _limit;
    governanceRecoveryFund = _governanceRecoveryFund;
    // Transfer ownership
    transferOwnership(_owner);
  }

  /// @notice this check should be called inside the child contract on deposits to check that the
  /// TVL didn't exceed a threshold
  /// @param _amount new amount to deposit
  function _guarded(uint256 _amount) internal view {
    uint256 _limit = limit;
    if (_limit == 0) {
      return;
    }
    require(getContractValue() + _amount <= _limit, '2');
  }

  /// @dev Check that the second function is not called in the same tx from the same tx.origin
  function _checkOnlyOwner() internal view {
    require(owner() == msg.sender, '6');
  }

  /// @notice abstract method, should return the TVL in underlyings
  function getContractValue() public virtual view returns (uint256);

  /// @notice set contract TVL limit
  /// @param _limit limit in underlying value, 0 means no limit
  function _setLimit(uint256 _limit) external {
    _checkOnlyOwner();
    limit = _limit;
  }

  /// @notice Emergency method, tokens gets transferred to the governanceRecoveryFund address
  /// @param _token address of the token to transfer
  /// @param _value amount to transfer
  function transferToken(address _token, uint256 _value) external {
    _checkOnlyOwner();
    IERC20Upgradeable(_token).safeTransfer(governanceRecoveryFund, _value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev ERC20 representing a tranche token
contract IdleCDOTranche is ERC20 {
  // allowed minter address
  address public minter;

  /// @param _name tranche name
  /// @param _symbol tranche symbol
  constructor(
    string memory _name, // eg. IdleDAI
    string memory _symbol // eg. IDLEDAI
  ) ERC20(_name, _symbol) {
    // minter is msg.sender which is IdleCDO (in initialize)
    minter = msg.sender;
  }

  /// @param account that should receive the tranche tokens
  /// @param amount of tranche tokens to mint
  function mint(address account, uint256 amount) external {
    require(msg.sender == minter, 'TRANCHE:!AUTH');
    _mint(account, amount);
  }

  /// @param account that should have the tranche tokens burned
  /// @param amount of tranche tokens to burn
  function burn(address account, uint256 amount) external {
    require(msg.sender == minter, 'TRANCHE:!AUTH');
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract IdleCDOStorage {
  // constant to represent 100%
  uint256 public constant FULL_ALLOC = 100000;
  // max fee, relative to FULL_ALLOC
  uint256 public constant MAX_FEE = 20000;
  // one token
  uint256 public constant ONE_TRANCHE_TOKEN = 10**18;
  // variable used to save the last tx.origin and block.number
  bytes32 internal _lastCallerBlock;
  // variable used to save the block of the latest harvest
  uint256 internal latestHarvestBlock;
  // WETH address
  address public weth;
  // tokens used to incentivize the idle tranche ideal ratio
  address[] public incentiveTokens;
  // underlying token (eg DAI)
  address public token;
  // address that can only pause/unpause the contract in case of emergency
  address public guardian;
  // one `token` (eg for DAI 10**18)
  uint256 public oneToken;
  // address that can call the 'harvest' method and lend pool assets
  address public rebalancer;
  // address of the uniswap v2 router
  IUniswapV2Router02 internal uniswapRouterV2;

  // Flag for allowing AA withdraws
  bool public allowAAWithdraw;
  // Flag for allowing BB withdraws
  bool public allowBBWithdraw;
  // Flag for allowing to enable reverting in case the strategy gives back less
  // amount than the requested one
  bool public revertIfTooLow;
  // Flag to enable the `Default Check` (related to the emergency shutdown)
  bool public skipDefaultCheck;

  // address of the strategy used to lend funds
  address public strategy;
  // address of the strategy token which represent the position in the lending provider
  address public strategyToken;
  // address of AA Tranche token contract
  address public AATranche;
  // address of BB Tranche token contract
  address public BBTranche;
  // address of AA Staking reward token contract
  address public AAStaking;
  // address of BB Staking reward token contract
  address public BBStaking;

  // Apr split ratio for AA tranches
  // (relative to FULL_ALLOC so 50% => 50000 => 50% of the interest to tranche AA)
  uint256 public trancheAPRSplitRatio; //
  // Ideal tranche split ratio in `token` value
  // (relative to FULL_ALLOC so 50% => 50000 means 50% of tranches (in value) should be AA)
  uint256 public trancheIdealWeightRatio;
  // Price for minting AA tranche, in underlyings
  uint256 public priceAA;
  // Price for minting BB tranche, in underlyings
  uint256 public priceBB;
  // last saved net asset value (in `token`) for AA tranches
  uint256 public lastNAVAA;
  // last saved net asset value (in `token`) for BB tranches
  uint256 public lastNAVBB;
  // last saved lending provider price
  uint256 public lastStrategyPrice;
  // Keeps track of unclaimed fees for feeReceiver
  uint256 public unclaimedFees;
  // Keeps an unlent balance both for cheap redeem and as 'insurance of last resort'
  uint256 public unlentPerc;

  // Fee amount (relative to FULL_ALLOC)
  uint256 public fee;
  // address of the fee receiver
  address public feeReceiver;

  // trancheIdealWeightRatio ± idealRanges, used in updateIncentives
  uint256 public idealRange;
  // period, in blocks, for progressively releasing harvested rewards to users
  uint256 public releaseBlocksPeriod;
  // amount of rewards sold in the last harvest (in `token`)
  uint256 internal harvestedRewards;
  // stkAave address
  address internal constant stkAave = address(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
  // aave address
  address internal constant AAVE = address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
  // if the cdo receive stkAAVE
  bool internal isStkAAVEActive;
  // referral address of the strategy developer
  address public referral;
  // amount of fee for feeReceiver. Max is FULL_ALLOC
  uint256 public feeSplit;
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
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

import "./IERC20.sol";
import "../../utils/Context.sol";

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
    constructor (string memory name_, string memory symbol_) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}