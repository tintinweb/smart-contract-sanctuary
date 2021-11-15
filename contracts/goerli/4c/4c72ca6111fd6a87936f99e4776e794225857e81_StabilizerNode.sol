pragma solidity >=0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./libraries/UniswapV2Library.sol";
import "./libraries/SafeBurnMintableERC20.sol";
import "./interfaces/IDAO.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IMalt.sol";
import "./interfaces/IBurnMintableERC20.sol";
import "./interfaces/IStabilizer.sol";
import "./interfaces/ILiquidityMine.sol";
import "./interfaces/IAuctionBurnReserveSkew.sol";
import "./interfaces/IAuction.sol";
import "./Auction.sol";
import "./interfaces/IMaltPoolPeriphery.sol";


contract StabilizerNode is Initializable, AccessControl {
  using SafeMath for uint256;
  using SafeBurnMintableERC20 for IBurnMintableERC20;

  uint256 private stabilizeWindowEnd;

  bytes32 public constant STABILIZER_ROLE = keccak256("STABILIZER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant LIQUIDITY_MINE_ROLE = keccak256("LIQUIDITY_MINE_ROLE");
  bytes32 public constant AUCTION_ROLE = keccak256("AUCTION_ROLE");

  IStabilizer public stabilizer;
  IDAO public dao;
  IOracle public oracle;
  address public uniswapV2Factory;
  IUniswapV2Router02 public router;
  address public liquidityMine;
  address public treasuryMultisig;

  uint256 public stabilizeBackoffPeriod = 5;
  uint256 public priceTarget = 10**18;
  uint256 public expansionDampingFactor = 1;
  uint256 public contractionDampingFactor = 2;
  uint256 public upperStabilityThreshold = (10**18) / 100; // 1%
  uint256 public lowerStabilityThreshold = (10**18) / 100;

  mapping(address => uint256) public lastBlock; // protect against reentrancy
  IBurnMintableERC20 public rewardToken;
  IBurnMintableERC20 public malt;
  IAuctionBurnReserveSkew public auctionBurnReserveSkew;
  IAuction public auction;
  IMaltPoolPeriphery public maltPoolPeriphery;

  uint256 public defaultIncentive = 100;
  uint256 public arbTokenReplenishSplit = 7000; // 70%

  uint256 public totalRewardCut = 1000;

  // Initially there are no dao rewards but to avoid limiting future options
  // there is still the ability to update this property to allocate rewards to dao
  uint256 public daoRewardCut = 0;
  uint256 public lpRewardCut = 930;
  uint256 public treasuryRewardCut = 20;
  uint256 public callerRewardCut = 50;
  // TODO methods to set these values Tue 06 Apr 2021 19:57:15 BST
  uint256 public minReserveRatio = 20;
  uint256 public maxReservePledgeFactor = 10;
  uint256 public lastStabilize;

  uint256 public perEpochYield;

  event SetPriceTarget(uint256 _target);
  event SetExpansionDamping(uint256 expansionAmount);
  event SetContractionDamping(uint256 contractionAmount);
  event SetArbTokenReplenishSplit(uint256 split);
  event SetDefaultIncentive(uint256 incentive);
  event SetFixedEpochYield(uint256 yield);
  event SetAuctionBurnSkew(address burnSkewAddress);
  event SetStabilizeBackoff(uint256 _period);
  event SetRewardCut(uint256 _daoCut, uint256 _lpCut, uint256 _callerCut, uint256 _treasuryCut);
  event SetNewLiquidityMine(address _lpmine);

  event MintMalt(uint256 amount);
  event BurnMalt(uint256 amount);
  event RewardDistribution(uint256 amount);
  event RedistributeRewards(uint256 amount, uint256 newRatio);
  event ReserveTransfer(address destination, uint256 amount);
  event RemoveLiquidityMine(address _lpmine);

  event Stabilize(uint256 time, uint256 exchangeRate);
  event TrackReserveRatio(uint256 rRatio, uint256 decimals);

  function initialize(
    address _dao,
    address _timelock,
    address _stabilizer,
    address _liquidityMine,
    address _oracle,
    address _router,
    address _uniswapV2Factory,
    address _malt,
    address _rewardToken,
    address _treasuryMultisig,
    address _auction
  ) external initializer {
    _setupRole(STABILIZER_ROLE, _stabilizer);
    _setupRole(ADMIN_ROLE, _dao);
    _setupRole(ADMIN_ROLE, _timelock);
    _setupRole(LIQUIDITY_MINE_ROLE, _liquidityMine);
    _setupRole(AUCTION_ROLE, _auction);
    _setRoleAdmin(STABILIZER_ROLE, ADMIN_ROLE);
    _setRoleAdmin(LIQUIDITY_MINE_ROLE, ADMIN_ROLE);
    _setRoleAdmin(AUCTION_ROLE, ADMIN_ROLE);

    stabilizer = IStabilizer(_stabilizer);
    uniswapV2Factory = _uniswapV2Factory;
    router = IUniswapV2Router02(_router);
    malt = IBurnMintableERC20(_malt);
    rewardToken = IBurnMintableERC20(_rewardToken);
    dao = IDAO(_dao);
    oracle = IOracle(_oracle);
    liquidityMine = _liquidityMine;
    treasuryMultisig = _treasuryMultisig;
    auction = IAuction(_auction);

    // 1e18 is considered 1 here
    _setFixedEpochYield(15846690000000); // 32% APY
  }

  function stabilize() external notSameBlock {
    (bool shouldFinalize, uint256 id) = auction.checkAuctionFinalization();

    if (shouldFinalize) {
      _finalizeAuction(id);
    }

    require(
      block.timestamp >= stabilizeWindowEnd || _stabilityWindowOverride(),
      "Can't call stabilize"
    );
    stabilizeWindowEnd = block.timestamp + stabilizeBackoffPeriod * 60;

    uint256 maltDecimals = malt.decimals();
    (uint256 exchangeRate, bool valid) = oracle.consult(address(malt), 10**maltDecimals, address(rewardToken));
    require(valid, "Oracle result not valid");

    if (!_shouldAdjustSupply(exchangeRate)) {
      uint256 constantReward = maltPoolPeriphery.calculateFixedReward(lastStabilize, perEpochYield);

      stabilizer.requestMint(constantReward);
      malt.safeTransfer(liquidityMine, constantReward);
      ILiquidityMine(liquidityMine).declareMaltReward(constantReward);
      emit MintMalt(constantReward);

      (uint256 rRatio, uint256 decimals) = maltPoolPeriphery.reserveRatio();
      emit TrackReserveRatio(rRatio, decimals);

      lastStabilize = block.timestamp;
      return;
    }

    emit Stabilize(block.timestamp, exchangeRate);

    if (exchangeRate > priceTarget) {
      uint256 rewarded = _distributeSupply();

      uint256 reserveReplenish = rewarded.mul(minReserveRatio).div(100);

      _distributeRewards(rewarded.sub(reserveReplenish));

      (uint256 rRatio, uint256 decimals) = maltPoolPeriphery.reserveRatio();
      emit TrackReserveRatio(rRatio, decimals);
    } else {
      _startAuction();
    }

    ILiquidityMine(liquidityMine).advance();
    lastStabilize = block.timestamp;
  }

  function purchaseArbitrageToken(uint256 amount) external notSameBlock {
    require(auction.auctionActive(auction.currentAuctionId()), "No auction running");

    (uint256 realCommitment, uint256 purchaseCommitment) = auction.capCommitment(auction.currentAuctionId(), amount);

    rewardToken.safeTransferFrom(msg.sender, address(this), realCommitment);

    uint256 purchased = 0;

    if (purchaseCommitment > 0) {
      purchased = _buyMalt(purchaseCommitment);
      stabilizer.requestBurn(purchased);
      emit BurnMalt(purchased);
    }
    
    auction.commitFunds(auction.currentAuctionId(), realCommitment, purchased, msg.sender);
  }

  function claimArbitrage(uint256 _auctionId) external notSameBlock {
    uint256 amountTokens = auction.userClaimableArbTokens(msg.sender, _auctionId);

    require(amountTokens > 0, "No claimable Arb tokens");

    bool success = auction.claimArb(_auctionId, msg.sender, amountTokens);

    require(success, "Can't claim tokens");

    rewardToken.safeTransfer(msg.sender, amountTokens);
  }

  /* DAO only methods */
  function setStabilizeBackoff(uint256 _period) external onlyAdmin {
    require(_period > 0, "Must be greater than 0");
    stabilizeBackoffPeriod = _period;
    emit SetStabilizeBackoff(_period);
  }

  function setFixedEpochYield(uint256 yield) external onlyAdmin {
    _setFixedEpochYield(yield);
  }

  function setAuctionBurnSkew(address _auctionBurnReserveSkew) external onlyAdmin {
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_auctionBurnReserveSkew);
    emit SetAuctionBurnSkew(_auctionBurnReserveSkew);
  }

  function setRewardCut(
    uint256 _daoCut,
    uint256 _lpCut,
    uint256 _callerCut,
    uint256 _treasuryCut
  ) external onlyAdmin {
    require(_daoCut.add(_lpCut).add(_callerCut).add(_treasuryCut) == totalRewardCut, "Reward cut must add to 100%");
    daoRewardCut = _daoCut;
    lpRewardCut = _lpCut;
    callerRewardCut = _callerCut;
    treasuryRewardCut = _treasuryCut;

    emit SetRewardCut(_daoCut, _lpCut, _callerCut, _treasuryCut);
  }

  function setDefaultIncentive(uint256 _incentive) external onlyAdmin {
    require(_incentive > 0, "No negative incentive");

    defaultIncentive = _incentive;

    emit SetDefaultIncentive(_incentive);
  }

  function setArbTokenReplenishSplit(uint256 split) external onlyAdmin {
    require(split > 0 && split <= 100, "Must be between 0 and 100");

    arbTokenReplenishSplit = split;
    emit SetArbTokenReplenishSplit(split);
  }

  function setExpansionDamping(uint256 amount) external onlyAdmin {
    require(amount > 0, "No negative damping");

    expansionDampingFactor = amount;
    emit SetExpansionDamping(amount);
  }

  function setContractionDamping(uint256 amount) external onlyAdmin {
    require(amount > 0, "No negative damping");

    contractionDampingFactor = amount;
    emit SetContractionDamping(amount);
  }

  function setDamping(uint256 expansionAmount, uint256 contractionAmount) external onlyAdmin {
    require(expansionAmount > 0, "No negative damping");
    require(contractionAmount > 0, "No negative damping");

    expansionDampingFactor = expansionAmount;
    contractionDampingFactor = contractionAmount;

    emit SetExpansionDamping(expansionAmount);
    emit SetContractionDamping(contractionAmount);
  }

  function setPriceTarget(uint256 _target) external onlyAdmin {
    require(_target > 0);
    priceTarget = _target;

    emit SetPriceTarget(_target);
  }

  function redistributeReserves(uint newRatio) public onlyAdmin {
    // Redistribute some of the reserves as rewards leaving a specified ratio behind
    (uint256 rRatio, uint256 decimals) = maltPoolPeriphery.reserveRatio();

    uint256 diff = rRatio.sub(newRatio);

    uint256 balance = rewardToken.balanceOf(address(this)) - auction.claimableArbitrageRewards();
    uint256 rewardDecimals = rewardToken.decimals();
    uint256 maltDecimals = malt.decimals();

    (, uint256 rewardSupply) = UniswapV2Library.getReserves(
      uniswapV2Factory,
      address(malt),
      address(rewardToken)
    );

    uint256 rewarded = rewardSupply.mul(2).mul(diff).div(10**decimals);

    emit RedistributeRewards(rewarded, newRatio);

    _distributeRewards(rewarded);
  }

  function transferReserves(address destination) public onlyAdmin {
    uint256 balance = rewardToken.balanceOf(address(this)) - auction.claimableArbitrageRewards();
    rewardToken.safeTransfer(destination, balance);
    emit ReserveTransfer(destination, balance);
  }

  function requestMint(uint256 amount) external onlyLiquidityMine {
    stabilizer.requestMint(amount);
    malt.safeTransfer(liquidityMine, amount);
  }

  function requestBurn(uint256 amount) external onlyLiquidityMine {
    stabilizer.requestBurn(amount);
  }

  function claimableArbitrageRewards() external view returns (uint256) {
    return auction.claimableArbitrageRewards();
  }

  function currentAuctionId() external view returns (uint256) {
    return auction.currentAuctionId();
  }

  function getAuctionCommitments(uint256 _id) public view returns (uint256 commitments, uint256 maxCommitments) {
    return auction.getAuctionCommitments(_id);
  }

  /* Internal methods */
  function _finalizeAuction(uint256 auctionId) private {
    (
      uint256 averageMaltPrice,
      uint256 commitments,
      uint256 startingPrice,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio,
      uint256 initialReservePledge
    ) = auction.setupAuctionFinalization(auctionId);

    if (commitments <= initialReservePledge) {
      // We didn't even raise enough to cover initial reserve pledge.
      // So we definitely don't want to be spending any more.
      (uint256 rRatio, uint256 decimals) = maltPoolPeriphery.reserveRatio();
      emit TrackReserveRatio(rRatio, decimals);
      return;
    }

    if (averageMaltPrice == 0) {
      (uint256 rRatio, uint256 decimals) = maltPoolPeriphery.reserveRatio();
      emit TrackReserveRatio(rRatio, decimals);
      return;
    }

    uint256 totalTokens = commitments.mul(startingPrice).div(finalPrice);

    uint256 premiumExcess = 0;

    if (finalPrice < averageMaltPrice) {
      premiumExcess = totalTokens.mul(averageMaltPrice.sub(finalPrice)).div(startingPrice);
    }

    // TODO does this still work if starting price < 1 Fri 02 Apr 2021 11:21:26 BST
    uint256 maxBurnSpend = (commitments.mul(startingPrice).div(startingPrice.sub(preAuctionReserveRatio))).sub(commitments);

    uint256 realBurnBudget = auctionBurnReserveSkew.getRealBurnBudget(maxBurnSpend, premiumExcess);

    if (realBurnBudget > 0) {
      uint256 purchased = _buyMalt(realBurnBudget);
      stabilizer.requestBurn(purchased);
      emit BurnMalt(purchased);
    }
    (uint256 rRatio, uint256 decimals) = maltPoolPeriphery.reserveRatio();
    emit TrackReserveRatio(rRatio, decimals);
  }

  function _distributeRewards(uint256 rewarded) private {
    rewarded = auction.allocateArbRewards(rewarded, arbTokenReplenishSplit);

    uint256 callerCut = rewarded.mul(callerRewardCut).div(totalRewardCut);
    uint256 lpCut = rewarded.mul(lpRewardCut).div(totalRewardCut);
    uint256 daoCut = rewarded.mul(daoRewardCut).div(totalRewardCut);

    // Treasury gets paid after everyone else
    uint256 treasuryCut = rewarded.sub(daoCut).sub(lpCut).sub(callerCut);

    if (callerCut < priceTarget.mul(100)) {
      // If caller reward is less than 100dai send them some malt
      stabilizer.requestMint(defaultIncentive*10**18);
      malt.safeTransfer(msg.sender, defaultIncentive*10**18);
      emit MintMalt(defaultIncentive*10**18);
    }

    rewardToken.safeTransfer(msg.sender, callerCut);
    rewardToken.safeTransfer(liquidityMine, lpCut);
    rewardToken.safeTransfer(address(dao), daoCut);
    rewardToken.safeTransfer(treasuryMultisig, treasuryCut);

    ILiquidityMine(liquidityMine).declareReward(lpCut);

    emit RewardDistribution(rewarded);
  }

  function _startAuction() private {
    (uint256 purchaseAmount, bool executeBurn) = auction.createAuction(
      priceTarget
    );

    if (executeBurn && purchaseAmount > 0) {
      uint256 purchased = _buyMalt(purchaseAmount);
      stabilizer.requestBurn(purchased);
      emit BurnMalt(purchased);
    }

    stabilizer.requestMint(defaultIncentive*10**18);
    malt.safeTransfer(msg.sender, defaultIncentive*10**18);
    emit MintMalt(defaultIncentive*10**18);

    auctionBurnReserveSkew.addBelowPegObservation(purchaseAmount);

    (uint256 rRatio, uint256 decimals) = maltPoolPeriphery.reserveRatio();
    emit TrackReserveRatio(rRatio, decimals);
  }

  function auctionPreBurn(uint256 maxSpend, uint256 rRatio, uint256 decimals) external onlyAuction returns (
    uint256 initialReservePledge,
    uint256 initialBurn
  ) {
    if (rRatio > minReserveRatio.mul(10**decimals).div(100)) {
      // Make an initial purchase and burn using reserves
      initialReservePledge = maxSpend.div(contractionDampingFactor);
      uint256 rewardBalance = rewardToken.balanceOf(address(this)) - auction.claimableArbitrageRewards();

      // If max raise is larger than the protocol is willing to commit, adjust initial pledge
      if (initialReservePledge > rewardBalance.div(maxReservePledgeFactor)) {
        initialReservePledge = rewardBalance.div(maxReservePledgeFactor).div(contractionDampingFactor);
      }

      initialBurn = _buyMalt(initialReservePledge);
      stabilizer.requestBurn(initialBurn);
      emit BurnMalt(initialBurn);
    }
  }

  function _sellMalt(uint256 amountMalt) private returns (uint256 rewards) {
    if (amountMalt == 0) {
      return 0;
    }

    malt.approve(address(router), amountMalt);

    address[] memory path = new address[](2);
    path[0] = address(malt);
    path[1] = address(rewardToken);

    uint256 initialMaltBalance = malt.balanceOf(address(this));

    if (initialMaltBalance < amountMalt) {
      return 0;
    }

    uint256 initialBalance = rewardToken.balanceOf(address(this));

    router.swapExactTokensForTokens(
      amountMalt,
      0, // amountOutMin: we can skip computing this number because the math is tested
      path,
      address(this),
      now
    );

    uint256 finalBalance = rewardToken.balanceOf(address(this));
    rewards = finalBalance - initialBalance;
  }

  function _buyMalt(uint256 amountRewardToken) private returns (uint256 purchased) {
    if (amountRewardToken == 0) {
      return 0;
    }

    rewardToken.approve(address(router), amountRewardToken);

    address[] memory path = new address[](2);
    path[0] = address(rewardToken);
    path[1] = address(malt);

    uint256 initialBalance = malt.balanceOf(address(this));
    uint256 rewardBalance = rewardToken.balanceOf(address(this));

    if (rewardBalance < amountRewardToken) {
      return 0;
    }

    router.swapExactTokensForTokens(
      amountRewardToken,
      0, // amountOutMin: we can skip computing this number because the math is tested
      path,
      address(this),
      now
    );

    uint256 finalBalance = malt.balanceOf(address(this));
    purchased = finalBalance - initialBalance;
  }

  function _distributeSupply() private returns (uint256) {
    uint256 tradeSize = maltPoolPeriphery.calculateMintingTradeSize(expansionDampingFactor);

    if (tradeSize == 0) {
      return 0;
    }

    stabilizer.requestMint(tradeSize);
    emit MintMalt(defaultIncentive*10**18);

    uint256 rewards = _sellMalt(tradeSize);

    auctionBurnReserveSkew.addAbovePegObservation(tradeSize);

    return rewards;
  }

  function _shouldAdjustSupply(uint256 exchangeRate) private view returns (bool) {
    uint256 decimals = rewardToken.decimals();

    uint256 upperThreshold = priceTarget.mul(upperStabilityThreshold).div(10**decimals);
    uint256 lowerThreshold = priceTarget.mul(lowerStabilityThreshold).div(10**decimals);

    return (exchangeRate <= priceTarget.sub(lowerThreshold) && !auction.auctionActive(auction.currentAuctionId())) || exchangeRate >= priceTarget.add(upperThreshold);
  }

  function _stabilityWindowOverride() private view returns (bool) {
    (uint256 maltReserves, uint256 rewardReserves) = UniswapV2Library.getReserves(
      uniswapV2Factory,
      address(malt),
      address(rewardToken)
    );

    uint256 exchangeRate = priceTarget.mul(rewardReserves) / maltReserves;

    uint256 upperThreshold = priceTarget.mul(110).div(100);
    uint256 lowerThreshold = priceTarget.mul(95).div(100);

    return exchangeRate <= lowerThreshold || exchangeRate >= upperThreshold;
  }

  function _setFixedEpochYield(uint256 yield) internal {
    perEpochYield = yield;
    emit SetFixedEpochYield(yield);
  }

  function setNewLiquidityMine(address _lpmine) external onlyAdmin {
    _setupRole(LIQUIDITY_MINE_ROLE, _lpmine);
    emit SetNewLiquidityMine(_lpmine);
  }

  function removeLiquidityMine(address _lpmine) external onlyAdmin {
    revokeRole(LIQUIDITY_MINE_ROLE, _lpmine);
    emit RemoveLiquidityMine(_lpmine);
  }

  function setNewPoolPeriphery(address _periphery) external onlyAdmin {
    maltPoolPeriphery = IMaltPoolPeriphery(_periphery);
  }

  function setAuctionContract(address _auction) external onlyAdmin {

    if (address(auction) != address(0)) {
      revokeRole(AUCTION_ROLE, address(auction));
    }

    auction = IAuction(_auction);
    _setupRole(AUCTION_ROLE, _auction);
  }

  modifier onlyAdmin() {
    require(
      hasRole(
        ADMIN_ROLE,
        _msgSender()
      ),
      "Must have admin role"
    );
    _;
  }

  modifier onlyLiquidityMine() {
    require(
      hasRole(
        LIQUIDITY_MINE_ROLE,
        _msgSender()
      ),
      "Must have liquidity mine role"
    );
    _;
  }

  modifier onlyAuction() {
    require(
      hasRole(
        AUCTION_ROLE,
        _msgSender()
      ),
      "Must have auction role"
    );
    _;
  }

  modifier notSameBlock() {
    require(
      block.number > lastBlock[_msgSender()],
      "Can't carry out actions in the same block"
    );
    lastBlock[_msgSender()] = block.number;
    _;
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IBurnMintableERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBurnMintableERC20 for IBurnMintableERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBurnMintableERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBurnMintableERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBurnMintableERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBurnMintableERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBurnMintableERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBurnMintableERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBurnMintableERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBurnMintableERC20 token, bytes memory data) private {
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

pragma solidity >=0.6.6;

interface IDAO {
  function epoch() external view returns (uint256);
  function epochLength() external view returns (uint256);
  function genesisTime() external view returns (uint256);
  function getEpochStartTime(uint256 _epoch) external view returns (uint256);
  function getLockedMalt(address account) external view returns (uint256);
}

pragma solidity >=0.6.6;

interface IOracle {
  function update(address tokenA) external;
  function updateAll() external;
  function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut, bool valid);
  function initializeNewTokenPair(address tokenA) external; 
  function getRecentReserves(address tokenA) external view returns (uint reserves);
}

pragma solidity >=0.6.6;

interface IMalt {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBurnMintableERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function burn(uint256 amount) external;
    function mint(address account, uint256 amount) external;

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

pragma solidity >=0.6.6;

interface IStabilizer {
  function requestMint(uint256 amount) external;
  function requestBurn(uint256 amount) external;
  function setEnabledOnStabilizerNode(uint256 index, bool enabled) external;
  function removeStabilizerNode(address _node) external;
  function addNewStabilizerNode(address _node, address _rewardToken) external;
  function userTotalMaltBonded(address account) external view returns (uint256);
}

pragma solidity >=0.6.6;

interface ILiquidityMine {
  function totalStaged() external view returns (uint256);
  function totalBonded() external view returns (uint256);
  function totalClaimable() external view returns (uint256);
  function totalRewarded() external view returns (uint256);
  function balanceOfStaged(address account) external view returns (uint256);
  function balanceOfBonded(address account) external view returns (uint256);
  function balanceOfClaimable(address account) external view returns (uint256);
  function realValueOfBonded(address account) external view returns (uint256, uint256);
  function declareReward(uint256 amount) external;
  function declareMaltReward(uint256 amount) external;
  function advance() external;
}

pragma solidity >=0.6.6;

interface IAuctionBurnReserveSkew {
  function consult(uint256 excess) external view returns (uint256);
  function getAverageParticipation() external view;
  function getPegDeltaFrequency() external view;
  function addAbovePegObservation(uint256 amount) external;
  function addBelowPegObservation(uint256 amount) external;
  function setNewStabilizerNode() external;
  function removeStabilizerNode() external;
  function getRealBurnBudget(
    uint256 maxBurnSpend,
    uint256 premiumExcess
  ) external view returns(uint256);
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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IStabilizerNode.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IDAO.sol";
import "./interfaces/IMalt.sol";
import "./interfaces/IMaltPoolPeriphery.sol";
import "./interfaces/IBurnMintableERC20.sol";


struct Auction {
  // total maximum desired commitments to this auction
  uint256 maxCommitments;
  // Quantity of sale currency committed to this auction
  uint256 commitments;
  // Malt purchased and burned using current commitments
  uint256 maltPurchased;
  // Desired starting price for the auction
  uint256 startingPrice;
  // Desired lowest price for the arbitrage token
  uint256 endingPrice;
  // Price of arbitrage tokens at conclusion of auction. This is either
  // when the duration elapses or the maxCommitments is reached
  uint256 finalPrice;
  // The peg price for the liquidity pool
  uint256 pegPrice;
  // Time when auction started
  uint256 startingTime;
  uint256 endingTime;
  // Is the auction currently accepting commitments?
  bool active;
  // The amount of reserve capital used to bolster price at the start of the auction
  // This will be paid back via the auction mechanics
  uint256 initialReservePledge;
  // The reserve ratio at the start of the auction
  uint256 preAuctionReserveRatio;
  // Has this auction been finalized? Meaning any additional stabilizing
  // has been done
  bool finalized;
  // The amount of arb tokens that have been executed and are now claimable
  uint256 claimableTokens;

  mapping(address => uint256) accountCommitments;
}

contract AuctionBase is Initializable, AccessControl {
  using SafeMath for uint256;

  bytes32 public constant STABILIZER_NODE_ROLE = keccak256("STABILIZER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  IStabilizerNode public stabilizerNode;
  IMaltPoolPeriphery maltPoolPeriphery;
  IBurnMintableERC20 public rewardToken;
  IBurnMintableERC20 public malt;
  IDAO public dao;
  uint256 public _unclaimedArbTokens;
  uint256 public replenishingAuctionId = 0;
  uint256 public currentAuctionId = 0;
  uint256 public claimableArbitrageRewards;
  uint256 public nextCommitmentId = 0;
  uint256 auctionLength = 1800; // 30 minutes

  struct AccountCommitment {
    uint256 commitment;
    uint256 redeemed;
  }

  event AuctionStarted(
    uint256 id,
    uint256 maxCommitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 startingTime,
    uint256 endingTime
  );
  event AuctionEnded(
    uint256 id,
    uint256 commitments,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 maltPurchased
  );
  event AuctionCommitment(
    uint256 id,
    uint256 auctionId,
    address account,
    uint256 commitment,
    uint256 maltPurchased
  );
  event ClaimArbTokens(
    uint256 id,
    address account,
    uint256 amount
  );
  event ArbTokenAllocation(
    uint256 id,
    uint256 amount
  );

  mapping (uint256 => Auction) private idToAuction;
  mapping(address => uint256[]) private accountCommitmentEpochs;
  mapping(address => mapping(uint256 => AccountCommitment)) private accountEpochCommitments;

  function initialize(
    address _stabilizerNode,
    address _periphery,
    address _rewardToken,
    address _malt,
    uint256 _auctionLength,
    address _timelock
  ) external initializer {
    _setupRole(STABILIZER_NODE_ROLE, _stabilizerNode);
    _setupRole(ADMIN_ROLE, _timelock);
    _setRoleAdmin(STABILIZER_NODE_ROLE, ADMIN_ROLE);

    stabilizerNode = IStabilizerNode(_stabilizerNode);
    maltPoolPeriphery = IMaltPoolPeriphery(_periphery);
    rewardToken = IBurnMintableERC20(_rewardToken);
    malt = IBurnMintableERC20(_malt);
    auctionLength = _auctionLength;
  }

  function balanceOfArbTokens(uint256 _auctionId, address account) public view returns (uint256) {
    return _balanceOfArb(_auctionId, account);
  }

  function getAuction(uint256 _id) public view returns (
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
  ) {
    Auction storage auction = _getAuction(_id);
    
    return (
      _id,
      auction.maxCommitments,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.initialReservePledge
    );
  }

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
  ) {
    return getAuction(currentAuctionId);
  }

  function setupAuctionFinalization(uint256 _id) external onlyStabilizerNode returns (
    uint256 averageMaltPrice,
    uint256 commitments,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 preAuctionReserveRatio,
    uint256 initialReservePledge
  ) {
    Auction storage auction = _getAuction(_id);
    auction.finalized = true;

    uint256 avgMaltPrice = 0;

    if (auction.maltPurchased > 0) {
      avgMaltPrice = auction.commitments.mul(auction.pegPrice).div(auction.maltPurchased);
    }

    
    return (
      avgMaltPrice,
      auction.commitments,
      auction.startingPrice,
      auction.finalPrice,
      auction.preAuctionReserveRatio,
      auction.initialReservePledge
    );
  }

  function getAccountCommitmentsAuctions(address account) external view returns (uint[] memory) {
    return accountCommitmentEpochs[account];
  }

  function getAccountCommitments(address account) external view returns (
    uint256[] memory auctions,
    uint256[] memory commitments,
    uint256[] memory awardedTokens,
    uint256[] memory redeemedTokens,
    uint256[] memory finalPrice,
    uint256[] memory claimable,
    bool[] memory finished
  ) {
    uint256[] memory epochCommitments = accountCommitmentEpochs[account];

    auctions = new uint256[](epochCommitments.length);
    commitments = new uint256[](epochCommitments.length);
    awardedTokens = new uint256[](epochCommitments.length);
    redeemedTokens = new uint256[](epochCommitments.length);
    finalPrice = new uint256[](epochCommitments.length);
    claimable = new uint256[](epochCommitments.length);
    finished = new bool[](epochCommitments.length);

    for (uint i = 0; i < epochCommitments.length; ++i) {
      Auction storage auction = idToAuction[epochCommitments[i]];

      AccountCommitment storage commitment = accountEpochCommitments[account][epochCommitments[i]];

      uint256 remaining = commitment.commitment.sub(commitment.redeemed);

      uint256 price = auction.finalPrice;

      if (auction.finalPrice == 0) {
        price = currentPrice(epochCommitments[i]);
      }

      auctions[i] = epochCommitments[i];
      commitments[i] = commitment.commitment;
      awardedTokens[i] = commitment.commitment.mul(auction.pegPrice).div(price);
      redeemedTokens[i] = commitment.redeemed.mul(auction.pegPrice).div(price);
      finalPrice[i] = price;
      claimable[i] = userClaimableArbTokens(account, epochCommitments[i]);
      finished[i] = isAuctionFinished(epochCommitments[i]);
    }
  }

  function checkAuctionFinalization() external onlyStabilizerNode returns (bool shouldFinalize, uint256 id) {
    shouldFinalize = false;
    if (isAuctionFinished(currentAuctionId)) {
      if (auctionActive(currentAuctionId)) {
        _endAuction(currentAuctionId);
      }

      if (!isAuctionFinalized(currentAuctionId)) {
        shouldFinalize = true;
        id = currentAuctionId;
      }
      currentAuctionId = currentAuctionId + 1;
    }
  }

  function createAuction(
    uint256 pegPrice
  ) external onlyStabilizerNode returns (uint256 initialPurchase, bool executeBurn) {
    if (auctionExists(currentAuctionId)) {
      return (0, false);
    }
    (uint256 rRatio, uint256 decimals) = maltPoolPeriphery.reserveRatio();
    uint256 purchaseAmount = maltPoolPeriphery.calculateBurningTradeSize();

    if (purchaseAmount == 0) {
      return (0, false);
    }

    uint256 realBurn = purchaseAmount.mul(
      Math.min(
        rRatio,
        10**decimals
      )
    ).div(10**decimals);

    uint256 realMaxRaise = purchaseAmount.sub(realBurn);

    initialPurchase = purchaseAmount;

    if (realMaxRaise == 0) {
      // No coupons will be issued. All malt purchasing comes from reserves
      executeBurn = true;
      return (initialPurchase, executeBurn);
    }

    executeBurn = false;

    (
      uint256 initialReservePledge,
      uint256 initialBurn
    ) = stabilizerNode.auctionPreBurn(realMaxRaise, rRatio, decimals);

    (uint256 startingPrice, uint256 endingPrice) = maltPoolPeriphery.calculateAuctionPricing(rRatio);

    Auction memory auction = Auction(
      realMaxRaise,
      0, // commitments
      initialBurn, // maltPurchased
      startingPrice,
      endingPrice,
      0, // finalPrice
      pegPrice,
      now, // startingTime
      now.add(auctionLength), // endingTime
      true, // active
      initialReservePledge,
      rRatio, // preAuctionReserveRatio
      false, // finalized
      0 // claimableTokens
    );

    _createAuction(
      currentAuctionId,
      auction
    );

    return (initialPurchase, executeBurn);
  }

  function _createAuction(
    uint256 _id,
    Auction memory auction
  ) internal {
    require(auction.endingTime == uint256(uint64(auction.endingTime)));

    idToAuction[_id] = auction;

    emit AuctionStarted(
      _id,
      auction.maxCommitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.startingTime,
      auction.endingTime
    );
  }

  function _endAuction(uint256 _id) internal {
    Auction storage auction = idToAuction[_id];

    require(auction.active == true, "Auction is already over");

    auction.active = false;
    auction.finalPrice = currentPrice(_id);

    uint256 amountArbTokens = auction.commitments.mul(auction.pegPrice).div(auction.finalPrice);
    _unclaimedArbTokens = _unclaimedArbTokens.add(amountArbTokens);

    emit AuctionEnded(
      _id,
      auction.commitments,
      auction.startingPrice,
      auction.finalPrice,
      auction.maltPurchased
    );
  }

  function capCommitment(uint256 _id, uint256 _commitment) public view returns (uint256 realCommitment, uint256 purchaseCommitment) {
    Auction storage auction = idToAuction[_id];

    realCommitment = _commitment;

    if (auction.commitments.add(_commitment) >= auction.maxCommitments) {
      realCommitment = auction.maxCommitments.sub(auction.commitments);
    }

    // We only want to make a malt purchase when we have cleared the
    // initial reserve pledge amount
    purchaseCommitment = 0;

    uint256 totalCommitment = auction.commitments.add(realCommitment);

    if (auction.commitments >= auction.initialReservePledge) {
      purchaseCommitment = realCommitment;
    } else if (totalCommitment >= auction.initialReservePledge) {
      purchaseCommitment = totalCommitment.sub(auction.initialReservePledge);
    }
  }

  function commitFunds(uint256 _id, uint256 _commitment, uint256 _maltPurchased, address account) external onlyStabilizerNode {
    Auction storage auction = idToAuction[_id];

    require(auction.startingTime <= now, "Auction hasn't started yet");
    require(auction.endingTime >= now, "Auction is already over");
    require(auction.active == true, "Auction is not active");

    auction.commitments = auction.commitments.add(_commitment);
    auction.accountCommitments[account] = auction.accountCommitments[account].add(_commitment);

    if (accountEpochCommitments[account][_id].commitment == 0) {
      accountCommitmentEpochs[account].push(_id);
    }
    accountEpochCommitments[account][_id].commitment = accountEpochCommitments[account][_id].commitment.add(_commitment);
    auction.maltPurchased = auction.maltPurchased.add(_maltPurchased);

    emit AuctionCommitment(
      nextCommitmentId,
      _id,
      account,
      _commitment,
      _maltPurchased
    );

    nextCommitmentId = nextCommitmentId + 1;

    if (auction.commitments >= auction.maxCommitments) {
      _endAuction(_id) ;
    }
  }

  function _balanceOfArb(uint256 _id, address account) internal view returns (uint256) {
    Auction storage auction = idToAuction[_id];

    AccountCommitment storage commitment = accountEpochCommitments[account][_id];

    uint256 remaining = commitment.commitment.sub(commitment.redeemed);

    uint256 price = auction.finalPrice;

    if (auction.finalPrice == 0) {
      price = currentPrice(_id);
    }

    return remaining.mul(auction.pegPrice).div(price);
  }

  function totalUnclaimedArb() public view returns (uint256) {
    return _unclaimedArbTokens;
  }

  function userClaimableArbTokens(address account, uint256 auctionId) public view returns (uint256) {
    Auction storage auction = idToAuction[auctionId];

    if (auction.claimableTokens == 0 || auction.finalPrice == 0 || auction.commitments == 0) {
      return 0;
    }

    AccountCommitment storage commitment = accountEpochCommitments[account][auctionId];

    uint256 totalTokens = auction.commitments.mul(auction.pegPrice).div(auction.finalPrice);

    uint256 claimablePerc = auction.claimableTokens.mul(auction.pegPrice).div(totalTokens);

    uint256 price = auction.finalPrice;

    if (auction.finalPrice == 0) {
      price = currentPrice(auctionId);
    }

    uint256 amountTokens = commitment.commitment.mul(auction.pegPrice).div(price);
    uint256 redeemedTokens = commitment.redeemed.mul(auction.pegPrice).div(price);

    return amountTokens.mul(claimablePerc).div(auction.pegPrice).sub(redeemedTokens);
  }

  function claimArb(uint256 _id, address account, uint256 amount) external onlyStabilizerNode returns (bool) {
    Auction storage auction = idToAuction[_id];

    require(!auction.active, "Cannot claim tokens on an active auction");

    AccountCommitment storage commitment = accountEpochCommitments[account][_id];

    uint256 redemption = amount.mul(auction.finalPrice).div(auction.pegPrice);
    uint256 remaining = commitment.commitment.sub(commitment.redeemed);

    require(redemption <= remaining.add(1), "Cannot claim more tokens than available");

    commitment.redeemed = commitment.redeemed.add(redemption);

    _unclaimedArbTokens = _unclaimedArbTokens.sub(amount);
    claimableArbitrageRewards = claimableArbitrageRewards.sub(amount);

    emit ClaimArbTokens(
      _id,
      account,
      amount
    );

    return true;
  }

  function allocateArbRewards(uint256 rewarded, uint256 replenishSplit) external onlyStabilizerNode returns (uint256) {
    Auction storage auction = idToAuction[replenishingAuctionId];

    if (auction.finalPrice == 0 || auction.commitments == 0) {
      return rewarded;
    }

    uint256 totalTokens = auction.commitments.mul(auction.pegPrice).div(auction.finalPrice);

    if (auction.claimableTokens < totalTokens) {
      uint256 requirement = totalTokens.sub(auction.claimableTokens);
      uint256 maxArbAllocation = rewarded.mul(replenishSplit).div(10000);

      if (requirement >= maxArbAllocation) {
        auction.claimableTokens = auction.claimableTokens.add(maxArbAllocation);
        rewarded = rewarded.sub(maxArbAllocation);
        claimableArbitrageRewards = claimableArbitrageRewards.add(maxArbAllocation);

        emit ArbTokenAllocation(
          replenishingAuctionId,
          maxArbAllocation
        );
      } else {
        auction.claimableTokens = auction.claimableTokens.add(requirement);
        rewarded = rewarded.sub(requirement);
        claimableArbitrageRewards = claimableArbitrageRewards.add(requirement);

        emit ArbTokenAllocation(
          replenishingAuctionId,
          requirement
        );
      }

      if (auction.claimableTokens == totalTokens) {
        uint256 count = 1;

        while (true) {
          auction = idToAuction[replenishingAuctionId + count];

          if (auction.commitments > 0 || !auction.finalized) {
            replenishingAuctionId = replenishingAuctionId + count;
            break;
          }
          count += 1;
        }
      }
    }

    return rewarded;
  }

  function averageMaltPrice(uint256 _id) external view returns (uint256) {
    Auction storage auction = idToAuction[_id];

    if (auction.maltPurchased == 0) {
      return 0;
    }

    return auction.commitments.mul(auction.pegPrice).div(auction.maltPurchased);
  }

  function currentPrice(uint256 _id) public view returns (uint256) {
    Auction storage auction = idToAuction[_id];

    require(auction.startingTime > 0, "No auction available with the given id");

    uint256 secondsSinceStart = 0;

    if (now > auction.startingTime) {
      secondsSinceStart = now - auction.startingTime;
    }

    uint256 auctionDuration = auction.endingTime - auction.startingTime;

    if (secondsSinceStart >= auctionDuration) {
      return auction.endingPrice;
    }

    uint256 totalPriceDelta = auction.startingPrice.sub(auction.endingPrice);

    uint256 currentPriceDelta = totalPriceDelta.mul(secondsSinceStart).div(auctionDuration);

    return auction.startingPrice.sub(currentPriceDelta);
  }

  function isAuctionFinished(uint256 _id) public view returns(bool) {
    Auction storage auction = idToAuction[_id];

    return auction.endingTime > 0 && (now >= auction.endingTime || auction.finalPrice > 0 || auction.commitments >= auction.maxCommitments);
  }

  function isAuctionFinalized(uint256 _id) public view returns (bool) {
    Auction storage auction = idToAuction[_id];
    return auction.finalized;
  }

  function getAuctionCommitments(uint256 _id) public view returns (uint256 commitments, uint256 maxCommitments) {
    Auction storage auction = idToAuction[_id];

    return (auction.commitments, auction.maxCommitments);
  }

  function getAuctionPrices(uint256 _id) public view returns (uint256 startingPrice, uint256 endingPrice, uint256 finalPrice) {
    Auction storage auction = idToAuction[_id];

    return (auction.startingPrice, auction.endingPrice, auction.finalPrice);
  }

  function _getAuction(uint256 _id) internal view returns (Auction storage auction) {
    auction = idToAuction[_id];

    require(auction.startingTime > 0, "No auction available for the given id");
  }

  function auctionExists(uint256 _id) public view returns (bool) {
    Auction storage auction = idToAuction[_id];

    return auction.startingTime > 0;
  }

  function auctionActive(uint256 _id) public view returns (bool) {
    Auction storage auction = idToAuction[_id];
    
    return auction.active && now >= auction.startingTime;
  }

  function setAuctionLength(uint256 _length) external onlyTimelock {
    require(_length > 0, "Length must be larger than 0");
    auctionLength = _length;
  }

  function setStabilizerNode(address _stabilizerNode) external onlyTimelock {
    revokeRole(STABILIZER_NODE_ROLE, address(stabilizerNode));
    stabilizerNode = IStabilizerNode(_stabilizerNode);
    _setupRole(STABILIZER_NODE_ROLE, _stabilizerNode);
  }

  function setMaltPoolPeriphery(address _periphery) external onlyTimelock {
    maltPoolPeriphery = IMaltPoolPeriphery(_periphery);
  }

  modifier onlyTimelock {
    require(
      hasRole(
        ADMIN_ROLE,
        _msgSender()
      ),
      "Must be admin"
    );
    _;
  }

  modifier onlyStabilizerNode {
    require(
      hasRole(
        STABILIZER_NODE_ROLE,
        _msgSender()
      ),
      "Must be stabilizer node"
    );
    _;
  }
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.6;

interface IStabilizerNode {
  function initialize(address dao) external;
  function requiredMint() external;
  function distributeSupply(uint256 amount) external;
  function liquidityMine() external view returns (address);
  function requestMint(uint256 amount) external;
  function requestBurn(uint256 amount) external;
  function currentAuctionId() external view returns (uint256);
  function claimableArbitrageRewards() external view returns (uint256);
  function auctionPreBurn(
    uint256 maxSpend,
    uint256 rRatio,
    uint256 decimals
  ) external returns (
    uint256 initialReservePledge,
    uint256 initialBurn
  );
  function getAuctionCommitments(uint256 _id) external view returns (uint256 commitments, uint256 maxCommitments);
}

