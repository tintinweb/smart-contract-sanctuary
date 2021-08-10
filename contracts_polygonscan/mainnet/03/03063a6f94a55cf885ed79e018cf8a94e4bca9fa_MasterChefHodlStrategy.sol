//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "../../uniswap/interfaces/IUniswapV2Router02.sol";
import "../../uniswap/interfaces/IUniswapV2Pair.sol";
import "../../hardworkInterface/IStrategy.sol";
import "../../hardworkInterface/IVault.sol";
import "./BaseUpgradeableStrategy.sol";
import "./IMiniChefV2.sol";

contract MasterChefHodlStrategy is IStrategy, BaseUpgradeableStrategy {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _FEERATIO_SLOT = 0xdd068d8a32502e81a10cdf5394059be07ccd47fe6df7741b57a2f9937efedeaf;
  bytes32 internal constant _FEEHOLDER_SLOT = 0x00679b6f1cace16785324a171df0e550ee9f20b64671a53b5c491a3065b30f2b;
  bytes32 internal constant _ROUTER_ADDRESS_V2_SLOT = 0x92199eab42483f175b95375c69585e82b184587d7846fbeb28030f68fbdf2feb;
  bytes32 internal constant _SUSHI_TOKEN_ADDRESS_SLOT = 0xcf3b156443750e93863e4613b74db96a0f6b1a281dd67c87ff4afda1c52d545a;
  bytes32 internal constant _WMATIC_TOKEN_ADDRESS_SLOT = 0x9b943037a3ba4823127740ffb7abf7566d132d3c50fe28fa8fd45de2c2a6f834;
  bytes32 internal constant _SELL_SUSHI_BOOL_SLOT = 0xb404b34be2ff9c417c92ed70e602d3743dc67c81ec3e52a56e152248436e66f2;
  bytes32 internal constant _SELL_WMATIC_BOOL_SLOT = 0x73f61035ecc9fe9b9df7f01bc4f1011784dd694ac3cac759bcd208fbf3da6e4a;
  bytes32 internal constant _CLAIM_ALLOWED_BOOL_SLOT = 0x643da254e9d7470053896c065c0a957d88a3eb48e03c87bfdfe16b3b5282046a;
  bytes32 internal constant _FEE_BASE_UNIT256_SLOT = 0xb03ba70f2714416bbb89d5653110256725bbfd3c1a0a6334c283e953a6ea7993;
  bytes32 internal constant _MIN_LIQUIDATE_TOKENS_SLOT = 0x9a17f7f8724c1a2f0558868646dcdc38b7bebed9cec1eb59d4529eaa55f4cfad;
 
  //Wmatic -> WETH paths[0]
  bytes32 internal constant _ROUTE_WMATIC_TOKEN0_LHS = 0x6565901a24447709405ab3697f2ea640ce7791edb0ea046095d626972d683601;
  
  //Wmatic -> WETH paths[1]
  bytes32 internal constant _ROUTE_WMATIC_TOKEN0_RHS = 0x900fb2a9fa2b2b2820f295064f6e6adbf7ddab98fcd6d808328c83637697bcab;

  //Wmatic -> underlying paths[0]
  bytes32 internal constant _ROUTE_WMATIC_TOKEN1_LHS = 0x8faa525983a40d73a9645634c5c07faf273c288aac622ba3f4b00dc2bdcc70ed;

  //Wmatic -> underlying paths[1]
  bytes32 internal constant _ROUTE_WMATIC_TOKEN1_RHS = 0x11715c74c260a518c242046509eb0522741596bbc940b2effdc1424b13e585fd;

  //SUSHI -> WETH paths[0]
  bytes32 internal constant _ROUTE_SUSHI_TOKEN0_LHS = 0x525d87f3a88df1e5365945ad2b18acddb07378fd70f898bf731c21f78fe2f23b;

  //SUSHI -> WETH paths[1]
  bytes32 internal constant _ROUTE_SUSHI_TOKEN0_RHS = 0x158eb59ee802a12ccb51e0e690e309c49ee37438bb1ded3c31f09ac4348b2923;

  //SUSHI -> underlying paths[0]
  bytes32 internal constant _ROUTE_SUSHI_TOKEN1_LHS = 0x05bbcb07ee015ebbef26793b36c0acd7e35b0da4e41c9be77244c04eb97ad92a;

  //SUSHI -> underlying paths[1]
  bytes32 internal constant _ROUTE_SUSHI_TOKEN1_RHS = 0xab89abbedde2addb80dde4b5025427e94813c85004af27ed6a3d14614e675d5a;

  event LogLiquidateRewardToken(address indexed rewardTokenAddress, address indexed token0Address, address indexed token1Address, uint256 rewardTokenBalance, uint256 token0Amount, uint256 token1Amount);
  event LogLiquidityAdded(address indexed token0Address, address indexed token1Address, uint256 amountA, uint256 amountB, uint256 liquidity);


  constructor() BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_FEERATIO_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.feeRatio")) - 1));
    assert(_FEEHOLDER_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.feeHolder")) - 1));
    assert(_ROUTER_ADDRESS_V2_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.routerAddressV2")) - 1));
    assert(_SUSHI_TOKEN_ADDRESS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sushiTokenAddress")) - 1));
    assert(_WMATIC_TOKEN_ADDRESS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.wmaticTokenAddress")) - 1));
    assert(_SELL_SUSHI_BOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellSushi")) - 1));
    assert(_SELL_WMATIC_BOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellMatic")) - 1));
    assert(_CLAIM_ALLOWED_BOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.claimAllowed")) - 1));
    assert(_FEE_BASE_UNIT256_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.feeBase")) - 1));
    assert(_MIN_LIQUIDATE_TOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.minLiquidateTokens")) - 1));

    assert(_ROUTE_WMATIC_TOKEN0_LHS == bytes32(uint256(keccak256("eip1967.strategyStorage.route.wmatic.token0.lhs")) - 1));
    assert(_ROUTE_WMATIC_TOKEN0_RHS == bytes32(uint256(keccak256("eip1967.strategyStorage.route.wmatic.token0.rhs")) - 1));

    assert(_ROUTE_WMATIC_TOKEN1_LHS == bytes32(uint256(keccak256("eip1967.strategyStorage.route.wmatic.token1.lhs")) - 1));
    assert(_ROUTE_WMATIC_TOKEN1_RHS == bytes32(uint256(keccak256("eip1967.strategyStorage.route.wmatic.token1.rhs")) - 1));

    assert(_ROUTE_SUSHI_TOKEN0_LHS == bytes32(uint256(keccak256("eip1967.strategyStorage.route.sushi.token0.lhs")) - 1));
    assert(_ROUTE_SUSHI_TOKEN0_RHS == bytes32(uint256(keccak256("eip1967.strategyStorage.route.sushi.token0.rhs")) - 1));
    
    assert(_ROUTE_SUSHI_TOKEN1_LHS == bytes32(uint256(keccak256("eip1967.strategyStorage.route.sushi.token1.lhs")) - 1));
    assert(_ROUTE_SUSHI_TOKEN1_RHS == bytes32(uint256(keccak256("eip1967.strategyStorage.route.sushi.token1.rhs")) - 1));
  }

  /// @param _storage Root Storage Contract Address (Storage.sol)
  /// @param _underlying Underlying token deposit through vault
  /// @param _vault Vault Contract Address
  /// @param _miniChefV2 MiniChefV2 Contract Address
  /// @param _poolId MiniChefV2 PoolId for the underlying
  /// @param _routerAddressV2 UniswapRouterV2 Address
  /// @param _sushiTokenAddress Sushi Reward-Token Address (Incoming Yield paid in Sushi)
  /// @param _wmaticTokenAddress WMatic Reward-Token Address (Incoming Yield paid in Matic)
  /// @param _routeSushiToken0 Uniswap-Route for Sushi to Token0 of Pool
  /// @param _routeSushiToken1 Uniswap-Route for Sushi to Token1 of Pool
  /// @param _routeWmaticToken0 Uniswap-Route for WMatic to Token0 of Pool
  /// @param _routeWmaticToken1 Uniswap-Route for WMatic to Token1 of Pool
  function initializeMasterChefHodlStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _miniChefV2,
    uint256 _poolId,
    address _routerAddressV2,
    address _sushiTokenAddress,
    address _wmaticTokenAddress,
    address[] memory _routeSushiToken0,
    address[] memory _routeSushiToken1,
    address[] memory _routeWmaticToken0,
    address[] memory _routeWmaticToken1
  ) public initializer {
    require(_storage != address(0), "storage is empty");
    require(_underlying != address(0), "underlying is empty");
    require(_vault != address(0), "vault is empty");
    require(_miniChefV2 != address(0), "reward pool is empty");
    require(_routerAddressV2 != address(0), "routerAddressV2 is empty");
    require(_routeSushiToken0.length == 2, "routeSushi-Token0 is invalid");
    require(_routeSushiToken1.length == 2, "routeSushi-Token1 is invalid");
    require(_routeWmaticToken0.length == 2, "routeWmatic-Token0 is invalid");
    require(_routeWmaticToken1.length == 2, "routeWmatic-Token1 is invalid");
    require(_routeSushiToken0[0] != address(0) || _routeSushiToken0[1] != address(0), "Zero-Address is invalid");
    require(_routeSushiToken1[0] != address(0) || _routeSushiToken1[1] != address(0), "Zero-Address is invalid");
    require(_routeWmaticToken0[0] != address(0) || _routeWmaticToken0[1] != address(0), "Zero-Address is invalid");
    require(_routeWmaticToken1[0] != address(0) || _routeWmaticToken1[1] != address(0), "Zero-Address is invalid");

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _miniChefV2,
      300, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e18, // sell floor
      12 hours // implementation change delay
    );
    
    address _lpt = IMiniChefV2(rewardPool()).lpToken(_poolId);
    require(_lpt == underlying(), "Pool Info does not match underlying");

    setUint256(_MIN_LIQUIDATE_TOKENS_SLOT, 10 ether);
    setUint256(_POOLID_SLOT, _poolId);
    setAddress(_ROUTER_ADDRESS_V2_SLOT, _routerAddressV2);
    setAddress(_SUSHI_TOKEN_ADDRESS_SLOT, _sushiTokenAddress);
    setAddress(_WMATIC_TOKEN_ADDRESS_SLOT, _wmaticTokenAddress);

    setAddress(_ROUTE_SUSHI_TOKEN0_LHS, _routeSushiToken0[0]);
    setAddress(_ROUTE_SUSHI_TOKEN0_RHS, _routeSushiToken0[1]);
    setAddress(_ROUTE_SUSHI_TOKEN1_LHS, _routeSushiToken1[0]);
    setAddress(_ROUTE_SUSHI_TOKEN1_RHS, _routeSushiToken1[1]);

    setAddress(_ROUTE_WMATIC_TOKEN0_LHS, _routeWmaticToken0[0]);
    setAddress(_ROUTE_WMATIC_TOKEN0_RHS, _routeWmaticToken0[1]);
    setAddress(_ROUTE_WMATIC_TOKEN1_LHS, _routeWmaticToken1[0]);
    setAddress(_ROUTE_WMATIC_TOKEN1_RHS, _routeWmaticToken1[1]);
    
    setUint256(_FEE_BASE_UNIT256_SLOT, 1000);
  }

  function getWmaticRoutes() public view returns (address[] memory, address[] memory){

    address[] memory wmaticToken0Route = new address[](2);
    address wmaticToken0Lhs = getAddress(_ROUTE_WMATIC_TOKEN0_LHS);
    wmaticToken0Route[0] = wmaticToken0Lhs;
    address wmaticToken0Rhs = getAddress(_ROUTE_WMATIC_TOKEN0_RHS);
    wmaticToken0Route[1] = wmaticToken0Rhs;

    address[] memory wmaticToken1Route = new address[](2);
    address wmaticToken1Lhs = getAddress(_ROUTE_WMATIC_TOKEN1_LHS);
    wmaticToken1Route[0] = wmaticToken1Lhs;
    address wmaticToken1Rhs = getAddress(_ROUTE_WMATIC_TOKEN1_RHS);
    wmaticToken1Route[1] = wmaticToken1Rhs;

    return (wmaticToken0Route, wmaticToken1Route);
  }


  function getSushiRoutes() public view returns (address[] memory, address[] memory){

    address[] memory sushiToken0Route = new address[](2);
    address sushiToken0Lhs = getAddress(_ROUTE_SUSHI_TOKEN0_LHS);
    sushiToken0Route[0] = sushiToken0Lhs;
    address sushiToken0Rhs = getAddress(_ROUTE_SUSHI_TOKEN0_RHS);
    sushiToken0Route[1] = sushiToken0Rhs;

    address[] memory sushiToken1Route = new address[](2);
    address sushiToken1Lhs = getAddress(_ROUTE_SUSHI_TOKEN1_LHS);
    sushiToken1Route[0] = sushiToken1Lhs;
    address sushiToken1Rhs = getAddress(_ROUTE_SUSHI_TOKEN1_RHS);
    sushiToken1Route[1] = sushiToken1Rhs;
    
    return (sushiToken0Route, sushiToken1Route);
  }

  function depositArbCheck() public pure override returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      IMiniChefV2.UserInfo memory userInfo = IMiniChefV2(rewardPool()).userInfo(poolId(), address(this));
      bal = userInfo.amount;
  }

  function exitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          if (claimAllowed()) {
            IMiniChefV2(rewardPool()).withdrawAndHarvest(poolId(), bal, address(this));
          } else {
            IMiniChefV2(rewardPool()).withdraw(poolId(), bal, address(this));
          }
      }
  }

  function emergencyExitRewardPool() internal {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
          IMiniChefV2(rewardPool()).emergencyWithdraw(poolId(), address(this));
      }
  }

  function unsalvagableTokens(address token) public view override returns (bool) {
    return (token == sushiTokenAddress() || token == wmaticTokenAddress() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IERC20Upgradeable(underlying()).balanceOf(address(this));
    IERC20Upgradeable(underlying()).safeApprove(rewardPool(), 0);
    IERC20Upgradeable(underlying()).safeApprove(rewardPool(), entireBalance);
    IMiniChefV2(rewardPool()).deposit(poolId(), entireBalance, address(this));
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  // We Hodl all the rewards
  function _hodlAndNotify() internal {

    uint256 liquidityAdded;

    //liquidate the Sushi Rewards
    if (sellSushi()) {
      (address[] memory sushiPath0, address[] memory sushiPath1) = getSushiRoutes();
      liquidityAdded.add(liquidateRewardToken(sushiTokenAddress(), sushiPath0, sushiPath1));
    }

    //liquidate the WMatic Rewards
    if (sellWMatic()) {
      (address[] memory maticPath0, address[] memory maticPath1) = getWmaticRoutes();
      liquidityAdded.add(liquidateRewardToken(wmaticTokenAddress(), maticPath0, maticPath1));
    }

    //compute Fee and transfer Fee to controller
    if(controller() != address(0)){
      uint256 fee = liquidityAdded.mul(feeRatio()).div(feeBase());
      if(fee > 0){
        IERC20Upgradeable(underlying()).safeTransfer(controller(), fee);
      }
    }
  }

  function liquidateRewardToken(address _rewardTokenAddress, address[] memory _uniswapPath0, address[] memory _uniswapPath1) internal returns (uint256) {
    uint256 rewardTokenBalance = IERC20Upgradeable(_rewardTokenAddress).balanceOf(address(this));

    if (rewardTokenBalance > minLiquidateTokens()) {
      //halve the tokenBalance
      //first half of tokenBalance will be used to buy token0
      //second half of tokenBalance will be used to buy token1
      uint256 half = rewardTokenBalance.div(2);
      uint256 otherHalf = rewardTokenBalance.sub(half);

      IERC20Upgradeable(_rewardTokenAddress).safeApprove(routerAddressV2(), 0);
      IERC20Upgradeable(_rewardTokenAddress).safeApprove(routerAddressV2(), rewardTokenBalance);
      
      uint256 token0Amount;

      if(_uniswapPath0[0] != _uniswapPath0[1]){
        // we can accept 1 as the minimum because this will be called only by a trusted worker
        uint256[] memory amounts0 = IUniswapV2Router02(routerAddressV2()).swapExactTokensForTokens(
          half,
          1,
          _uniswapPath0,
          address(this),
          block.timestamp
        );

        token0Amount = amounts0[amounts0.length - 1];
      } else {
        token0Amount = half;
      }

      uint256 token1Amount;

      if(_uniswapPath1[0] != _uniswapPath1[1]){

        // we can accept 1 as the minimum because this will be called only by a trusted worker
        uint256[] memory amounts1 = IUniswapV2Router02(routerAddressV2()).swapExactTokensForTokens(
          otherHalf,
          1,
          _uniswapPath1,
          address(this),
          block.timestamp
        );

        token1Amount = amounts1[amounts1.length - 1];
      } else {
        token1Amount = otherHalf;
      }

      //reset approval to 0.
      IERC20Upgradeable(_rewardTokenAddress).safeApprove(routerAddressV2(), 0);

      address token0Address = _uniswapPath0[1];
      address token1Address = _uniswapPath1[1];

      emit LogLiquidateRewardToken(_rewardTokenAddress, token0Address, token1Address, rewardTokenBalance, token0Amount, token1Amount);
      return addLiquidity(token0Address, token0Amount, token1Address, token1Amount);
    } else {
      return 0;
    }
  }

  function addLiquidity(address token0Address, uint256 token0Amount, address token1Address, uint256 token1Amount) private returns (uint256) {
    // approve token transfer
    IERC20Upgradeable(token0Address).safeApprove(routerAddressV2(), 0);
    IERC20Upgradeable(token0Address).safeApprove(routerAddressV2(), token0Amount);
    IERC20Upgradeable(token1Address).safeApprove(routerAddressV2(), 0);
    IERC20Upgradeable(token1Address).safeApprove(routerAddressV2(), token1Amount);

    // add the liquidity
    (uint256 amountA, uint256 amountB, uint256 liquidity) = IUniswapV2Router02(routerAddressV2()).addLiquidity(
      token0Address,
      token1Address,
      token0Amount,
      token1Amount,
      1,  // min
      1,  // min
      vault(),
      block.timestamp
    );

    emit LogLiquidityAdded(token0Address, token1Address, amountA, amountB, liquidity);
    return liquidity;
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20Upgradeable(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public override restricted {
    exitRewardPool();
    _hodlAndNotify();
    IERC20Upgradeable(underlying()).safeTransfer(vault(), IERC20Upgradeable(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public override restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20Upgradeable(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = MathUpgradeable.min(rewardPoolBalance(), needToWithdraw);
      IMiniChefV2(rewardPool()).withdraw(poolId(), toWithdraw, address(this));
    }

    IERC20Upgradeable(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view override returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20Upgradeable(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IERC20Upgradeable(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external override onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20Upgradeable(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external override onlyNotPausedInvesting restricted {
    exitRewardPool();
    _hodlAndNotify();
    investAllUnderlying();
  }

  function setFeeRatio(uint256 _value) public onlyGovernance {
    require(_value <= feeBase().mul(3).div(10), "Cannot be more then 30%");
    setUint256(_FEERATIO_SLOT, _value);
  }

  function setFeeHolder(address _value) public onlyGovernance {
    setAddress(_FEEHOLDER_SLOT, _value);
  }

  function feeRatio() public view returns (uint256) {
    return getUint256(_FEERATIO_SLOT);
  }

  function feeHolder() public view returns (address) {
    return getAddress(_FEEHOLDER_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    setFeeRatio(1500);
    _finalizeUpgrade();
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function routerAddressV2() public view returns (address) {
    return getAddress(_ROUTER_ADDRESS_V2_SLOT);
  }

  function sushiTokenAddress() public view returns (address) {
    return getAddress(_SUSHI_TOKEN_ADDRESS_SLOT);
  }

  function wmaticTokenAddress() public view returns (address) {
    return getAddress(_WMATIC_TOKEN_ADDRESS_SLOT);
  }

  function setSellSushi(bool _sellSushi) internal {
    setBoolean(_SELL_SUSHI_BOOL_SLOT, _sellSushi);
  }

  function sellSushi() public view returns (bool) {
    return getBoolean(_SELL_SUSHI_BOOL_SLOT);
  }

  function setSellWMatic(bool _sellWMatic) internal {
    setBoolean(_SELL_WMATIC_BOOL_SLOT, _sellWMatic);
  }

  function sellWMatic() public view returns (bool) {
    return getBoolean(_SELL_WMATIC_BOOL_SLOT);
  }

  function setClaimAllowed(bool _claimAllowed) internal {
    setBoolean(_CLAIM_ALLOWED_BOOL_SLOT, _claimAllowed);
  }

  function claimAllowed() public view returns (bool) {
    return getBoolean(_CLAIM_ALLOWED_BOOL_SLOT);
  }

  function feeBase() public view returns (uint256) {
    return getUint256(_FEE_BASE_UNIT256_SLOT);
  }
  function minLiquidateTokens() public view returns (uint256) {
    return getUint256(_MIN_LIQUIDATE_TOKENS_SLOT);
  }

  function getVault() public view override returns (address) {
    return vault();
  }

  function getUnderlying() public view override returns (address) {
    return underlying();
  }

  function setLiquidation(
      bool _sellSushi,
      bool _sellWMatic,
      bool _claimAllowed
  ) public onlyGovernance {
      setSellSushi(_sellSushi);
      setSellWMatic(_sellWMatic);
      setClaimAllowed(_claimAllowed);
  }

  function setMinLiquidateTokens(uint256 minLiquidate)
    public
    onlyGovernance
  {
      setUint256(_MIN_LIQUIDATE_TOKENS_SLOT, minLiquidate);
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 {
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

//SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity 0.8.4;

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function getUnderlying() external view returns (address);
    function getVault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IVault {

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../../ControllableInit.sol";

contract BaseUpgradeableStrategy is Initializable, ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event ProfitsNotCollected(bool sell, bool floor);
  event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);
  event ProfitAndBuybackLog(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() BaseUpgradeableStrategyStorage() {
  }

  function initialize(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _profitSharingNumerator,
    uint256 _profitSharingDenominator,
    bool _sell,
    uint256 _sellFloor,
    uint256 _implementationChangeDelay
  ) public initializer {
    ControllableInit.initialize(
      _storage
    );
    _setUnderlying(_underlying);
    _setVault(_vault);
    _setRewardPool(_rewardPool);
    _setProfitSharingNumerator(_profitSharingNumerator);
    _setProfitSharingDenominator(_profitSharingDenominator);

    _setSell(_sell);
    _setSellFloor(_sellFloor);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setPausedInvesting(false);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function _finalizeUpgrade() internal {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  function shouldUpgrade() external view returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IMiniChefV2 {

    /// @notice Deposit LP tokens to MCV2 for SUSHI allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) external;

     /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) external;
    
    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) external;

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of SUSHI rewards.
    function harvest(uint256 pid, address to) external;

    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and SUSHI rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    function userInfo(uint256 _pid, address _user) external view returns (IMiniChefV2.UserInfo memory);

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external;

    /// @param pid The index of the pool.
    function lpToken(uint256 pid) external returns (address);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract BaseUpgradeableStrategyStorage {

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
  bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

  bytes32 internal constant _REWARD_CLAIMABLE_SLOT = 0xbc7c0d42a71b75c3129b337a259c346200f901408f273707402da4b51db3b8e7;
  bytes32 internal constant _MULTISIG_SLOT = 0x3e9de78b54c338efbc04e3a091b87dc7efb5d7024738302c548fc59fba1c34e6;
  

  constructor() {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));

    assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

    assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
    assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));

    assert(_REWARD_CLAIMABLE_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardClaimable")) - 1));
    assert(_MULTISIG_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.multiSig")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setRewardPool(address _address) internal {
    setAddress(_REWARD_POOL_SLOT, _address);
  }

  function rewardPool() public view returns (address) {
    return getAddress(_REWARD_POOL_SLOT);
  }

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function _setProfitSharingNumerator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_NUMERATOR_SLOT, _value);
  }

  function profitSharingNumerator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_NUMERATOR_SLOT);
  }

  function _setProfitSharingDenominator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_DENOMINATOR_SLOT, _value);
  }

  function profitSharingDenominator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_DENOMINATOR_SLOT);
  }

  function allowedRewardClaimable() public view returns (bool) {
    return getBoolean(_REWARD_CLAIMABLE_SLOT);
  }

  function _setRewardClaimable(bool _value) internal {
    setBoolean(_REWARD_CLAIMABLE_SLOT, _value);
  }

  function multiSig() public view returns(address) {
    return getAddress(_MULTISIG_SLOT);
  }

  function _setMultiSig(address _address) internal {
    setAddress(_MULTISIG_SLOT, _address);
  }

  // upgradeability

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() {
  }

  function initialize(address _storage) public override initializer {
    GovernableInit.initialize(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view virtual returns (address) {
    return Storage(_storage()).controller();
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public virtual initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view virtual returns (address) {
    return Storage(_storage()).governance();
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Storage {

  address public governance;
  address public controller;

  // [whiteList]
  // An EOA can safely interact with the system no matter what.
  // If you're using Metamask, you're using an EOA.
  // Only smart contracts may be affected by this whiteList.
  //
  // Only smart contracts added to the whiteList may interact with the vaults.
  mapping (address => bool) public whiteList;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }

  // Only smart contracts will be affected by the whiteList.
  function addToWhiteList(address _target) public onlyGovernance {
    whiteList[_target] = true;
  }

  function removeFromWhiteList(address _target) public onlyGovernance {
    whiteList[_target] = false;
  }

  function checkWhitelist(address _target) public view returns (bool) {
    return whiteList[_target];
  }
}