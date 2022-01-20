// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ISmartVault.sol";
import "../interface/IFeeRewardForwarder.sol";
import "../interface/IBookkeeper.sol";
import "./Controllable.sol";
import "../../third_party/uniswap/IUniswapV2Router02.sol";
import "../../third_party/uniswap/IUniswapV2Factory.sol";
import "../../third_party/uniswap/IUniswapV2Pair.sol";
import "./ForwarderV2Storage.sol";

/// @title Convert rewards from external projects to TETU and FundToken(USDC by default)
///        and send them to Profit Sharing pool, FundKeeper and vaults
///        After swap TETU tokens are deposited to the Profit Share pool and give xTETU tokens.
///        These tokens send to Vault as a reward for vesting (4 weeks).
///        If external rewards have a destination Profit Share pool
///        it is just sent to the contract as TETU tokens increasing share price.
/// @author belbix
contract ForwarderV2 is Controllable, IFeeRewardForwarder, ForwarderV2Storage {
  using SafeERC20 for IERC20;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.2.1";
  uint256 public constant LIQUIDITY_DENOMINATOR = 100;
  uint constant public DEFAULT_UNI_FEE_DENOMINATOR = 1000;
  uint constant public DEFAULT_UNI_FEE_NOMINATOR = 997;
  uint constant public ROUTE_LENGTH_MAX = 5;
  uint constant public SLIPPAGE_DENOMINATOR = 100;
  uint constant public SLIPPAGE_NOMINATOR = 95;

  // ************ EVENTS **********************
  /// @notice Fee distributed to Profit Sharing pool
  event FeeMovedToPs(address indexed ps, address indexed token, uint256 amount);
  /// @notice Fee distributed to vault
  event FeeMovedToVault(address indexed vault, address indexed token, uint256 amount);
  /// @notice Fee distributed to FundKeeper
  event FeeMovedToFund(address indexed fund, address indexed token, uint256 amount);
  /// @notice Simple liquidation was done
  event Liquidated(address indexed tokenIn, address indexed tokenOut, uint256 amount);
  event LiquidityAdded(
    address router,
    address token0,
    uint256 token0Amount,
    address token1,
    uint256 token1Amount
  );

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  ///      Initialize Controllable with sender address
  function initialize(address _controller) external initializer {
    Controllable.initializeControllable(_controller);
  }

  // ***************** VIEW ************************

  /// @notice Return Profit Sharing pool address
  /// @return Profit Sharing pool address
  function psVault() public view returns (address) {
    return IController(controller()).psVault();
  }

  /// @notice Return FundKeeper address
  /// @return FundKeeper address
  function fund() public view returns (address) {
    return IController(controller()).fund();
  }

  /// @notice Return Target token (TETU) address
  /// @return Target token (TETU) address
  function tetu() public view returns (address) {
    return IController(controller()).rewardToken();
  }

  /// @notice Return a token address used for FundKeeper (USDC by default)
  /// @return FundKeeper's main token address (USDC by default)
  function fundToken() public view returns (address) {
    return IController(controller()).fundToken();
  }

  // ************ GOVERNANCE ACTIONS **************************

  /// @notice Only Governance or Controller can call it.
  ///         Add a pair with largest TVL for given token
  function addLargestLps(address[] memory _tokens, address[] memory _lps) external onlyControllerOrGovernance {
    require(_tokens.length == _lps.length, "F2: Wrong arrays");
    for (uint i = 0; i < _lps.length; i++) {
      IUniswapV2Pair lp = IUniswapV2Pair(_lps[i]);
      address oppositeToken;
      if (lp.token0() == _tokens[i]) {
        oppositeToken = lp.token1();
      } else if (lp.token1() == _tokens[i]) {
        oppositeToken = lp.token0();
      } else {
        revert("F2: Wrong LP");
      }
      largestLps[_tokens[i]] = LpData(address(lp), _tokens[i], oppositeToken);
    }
  }

  /// @notice Only Governance or Controller can call it.
  ///         Add largest pairs with the most popular tokens on the current network
  function addBlueChipsLps(address[] memory _lps) external onlyControllerOrGovernance {
    for (uint i = 0; i < _lps.length; i++) {
      IUniswapV2Pair lp = IUniswapV2Pair(_lps[i]);
      blueChipsLps[lp.token0()][lp.token1()] = LpData(address(lp), lp.token0(), lp.token1());
      blueChipsLps[lp.token1()][lp.token0()] = LpData(address(lp), lp.token0(), lp.token1());
      blueChipsTokens[lp.token0()] = true;
      blueChipsTokens[lp.token1()] = true;
    }
  }

  /// @notice Only Governance or Controller can call it.
  ///         Sets numerator for a part of profit that goes instead of PS to TETU liquidity
  function setLiquidityNumerator(uint256 _value) external onlyControllerOrGovernance {
    require(_value <= LIQUIDITY_DENOMINATOR, "F2: Too high value");
    _setLiquidityNumerator(_value);
  }

  /// @notice Only Governance or Controller can call it.
  ///         Sets router for a pair with TETU liquidity
  function setLiquidityRouter(address _value) external onlyControllerOrGovernance {
    _setLiquidityRouter(_value);
  }

  /// @notice Only Governance or Controller can call it.
  ///         Sets specific Swap fee for given factory
  function setUniPlatformFee(address _factory, uint _feeNominator, uint _feeDenominator) external onlyControllerOrGovernance {
    require(_factory != address(0), "F2: Zero factory");
    require(_feeNominator <= _feeDenominator, "F2: Wrong values");
    require(_feeDenominator != 0, "F2: Wrong denominator");
    uniPlatformFee[_factory] = UniFee(_feeNominator, _feeDenominator);
  }

  // ***************** EXTERNAL *******************************

  /// @notice Only Reward Distributor or Governance or Controller can call it.
  ///         Distribute rewards for given vault, move fees to PS and Fund
  ///         Under normal circumstances, sender is the strategy
  /// @param _amount Amount of tokens for distribute
  /// @param _token Token for distribute
  /// @param _vault Target vault
  /// @return Amount of distributed Target(TETU) tokens + FundKeeper fee (approx)
  function distribute(
    uint256 _amount,
    address _token,
    address _vault
  ) public override onlyRewardDistribution returns (uint256){
    require(fundToken() != address(0), "F2: Fund token is zero");
    require(_amount != 0, "F2: Zero amount for distribute");
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    // calculate require amounts
    uint toFund = _toFundAmount(_amount);
    uint toPsAndLiq = _toPsAndLiqAmount(_amount - toFund);
    uint toLiq = _toTetuLiquidityAmount(toPsAndLiq);
    uint toLiqFundTokenPart = toLiq / 2;
    uint toLiqTetuTokenPart = toLiq - toLiqFundTokenPart;
    uint toPs = toPsAndLiq - toLiq;
    uint toVault = _amount - toFund - toPsAndLiq;

    uint fundTokenRequires = toFund + toLiqFundTokenPart;
    uint tetuTokenRequires = toLiqTetuTokenPart + toPs + toVault;
    require(fundTokenRequires + tetuTokenRequires == _amount, "F2: Wrong amount sum");


    uint fundTokenAmount = _liquidate(_token, fundToken(), fundTokenRequires);
    uint sentToFund = _sendToFund(fundTokenAmount, toFund, toLiqFundTokenPart);

    uint tetuTokenAmount = _liquidate(_token, tetu(), tetuTokenRequires);

    uint256 tetuDistributed = 0;
    if (toPsAndLiq > 0) {
      tetuDistributed += _sendToPsAndLiquidity(
        tetuTokenAmount,
        toLiqTetuTokenPart,
        toPs,
        toVault,
        fundTokenAmount - sentToFund
      );
    }
    if (toVault > 0) {
      tetuDistributed += _sendToVault(
        _vault,
        tetuTokenAmount,
        toLiqTetuTokenPart,
        toPs,
        toVault
      );
    }

    _sendExcessTokens();
    return _plusFundAmountToDistributedAmount(tetuDistributed);
  }

  /// @dev Simple function for liquidate and send back the given token
  ///      No strict access
  function liquidate(address tokenIn, address tokenOut, uint256 amount) external override returns (uint256) {
    if (tokenIn == tokenOut) {
      // no action required if the same token;
      return amount;
    }
    if (amount == 0) {
      return 0;
    }
    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amount);
    uint256 resultAmount = _liquidate(tokenIn, tokenOut, amount);
    require(resultAmount > 0, "F2: Liquidated with zero result");
    IERC20(tokenOut).safeTransfer(msg.sender, resultAmount);
    emit Liquidated(tokenIn, tokenOut, amount);
    return resultAmount;
  }

  /// @dev We don't need this function anymore, keep for compatibility
  function notifyPsPool(address, uint256) external pure override returns (uint256) {
    revert("F2: Directly notifyPsPool not implemented");
  }

  /// @dev We don't need this function anymore, keep for compatibility
  function notifyCustomPool(address, address, uint256) external pure override returns (uint256) {
    revert("F2: Directly notifyCustomPool not implemented");
  }


  //************************* INTERNAL **************************

  function _sendExcessTokens() internal {
    uint excessFundToken = IERC20(fundToken()).balanceOf(address(this));
    if (excessFundToken != 0 && fund() != address(0)) {
      IERC20(fundToken()).safeTransfer(fund(), excessFundToken);
      IBookkeeper(IController(controller()).bookkeeper())
      .registerFundKeeperEarned(fundToken(), excessFundToken);
      emit FeeMovedToFund(fund(), fundToken(), excessFundToken);
    }

    uint excessTetuToken = IERC20(tetu()).balanceOf(address(this));
    if (excessTetuToken != 0) {
      IERC20(tetu()).safeTransfer(psVault(), excessTetuToken);
      emit FeeMovedToPs(psVault(), tetu(), excessTetuToken);
    }
  }

  function _sendToPsAndLiquidity(
    uint tetuTokenAmount,
    uint baseToLiqTetuTokenPart,
    uint baseToPs,
    uint baseToVault,
    uint toLiqFundTokenPart
  ) internal returns (uint) {
    uint baseSum = baseToLiqTetuTokenPart + baseToPs + baseToVault;

    uint toLiqTetuTokenPart = tetuTokenAmount * baseToLiqTetuTokenPart / baseSum;
    uint tetuLiqAmount = _sendToLiquidity(toLiqTetuTokenPart, toLiqFundTokenPart);

    uint toPs = tetuTokenAmount * baseToPs / baseSum;
    if (toPs != 0) {
      IERC20(tetu()).safeTransfer(psVault(), toPs);
      emit FeeMovedToPs(psVault(), tetu(), toPs);
    }
    return toPs + tetuLiqAmount;
  }

  function _sendToVault(
    address _vault,
    uint tetuTokenAmount,
    uint baseToLiqTetuTokenPart,
    uint baseToPs,
    uint baseToVault
  ) internal returns (uint256) {
    address xTetu = psVault();
    ISmartVault smartVault = ISmartVault(_vault);
    address[] memory rts = smartVault.rewardTokens();
    require(rts.length > 0, "F2: No reward tokens");
    address rt = rts[0];

    uint baseSum = baseToLiqTetuTokenPart + baseToPs + baseToVault;
    uint toVault = tetuTokenAmount * baseToVault / baseSum;

    uint256 amountToSend;
    if (rt == xTetu) {
      uint rtBalanceBefore = IERC20(xTetu).balanceOf(address(this));
      IERC20(tetu()).safeApprove(psVault(), toVault);
      ISmartVault(psVault()).deposit(toVault);
      amountToSend = IERC20(xTetu).balanceOf(address(this)) - rtBalanceBefore;
    } else if (rt == tetu()) {
      amountToSend = toVault;
    } else {
      revert("F2: First reward token not TETU nor xTETU");
    }

    IERC20(rt).safeApprove(_vault, amountToSend);
    smartVault.notifyTargetRewardAmount(rt, amountToSend);
    emit FeeMovedToVault(_vault, rt, amountToSend);
    return toVault;
  }

  function _sendToFund(uint256 fundTokenAmount, uint baseToFundAmount, uint baseToLiqFundTokenPart) internal returns (uint){
    uint toFund = fundTokenAmount * baseToFundAmount / (baseToFundAmount + baseToLiqFundTokenPart);

    // no actions if we don't have a fee for fund
    if (toFund == 0) {
      return 0;
    }
    require(fund() != address(0), "F2: Fund is zero");

    IERC20(fundToken()).safeTransfer(fund(), toFund);

    IBookkeeper(IController(controller()).bookkeeper())
    .registerFundKeeperEarned(fundToken(), toFund);
    emit FeeMovedToFund(fund(), fundToken(), toFund);
    return toFund;
  }

  function _sendToLiquidity(uint toLiqTetuTokenPart, uint toLiqFundTokenPart) internal returns (uint256) {
    // no actions if we don't have a fee for liquidity
    if (toLiqTetuTokenPart == 0 || toLiqFundTokenPart == 0) {
      return 0;
    }

    uint256 lpAmount = _addLiquidity(
      liquidityRouter(),
      fundToken(),
      tetu(),
      toLiqFundTokenPart,
      toLiqTetuTokenPart
    );

    require(lpAmount != 0, "F2: Liq: Zero LP amount");

    address liquidityPair = IUniswapV2Factory(IUniswapV2Router02(liquidityRouter()).factory())
    .getPair(fundToken(), tetu());

    IERC20(liquidityPair).safeTransfer(fund(), lpAmount);
    return toLiqTetuTokenPart * 2;
  }

  /// @dev Compute amount for FundKeeper based on Fund ratio from Controller
  /// @param _amount 100% Amount
  /// @return Percent of total amount
  function _toFundAmount(uint256 _amount) internal view returns (uint256) {
    uint256 fundNumerator = IController(controller()).fundNumerator();
    uint256 fundDenominator = IController(controller()).fundDenominator();
    return _amount * fundNumerator / fundDenominator;
  }

  /// @dev Compute amount for Profit Sharing vault based Controller settings
  /// @param _amount 100% Amount
  /// @return Percent of total amount
  function _toPsAndLiqAmount(uint _amount) internal view returns (uint) {
    uint256 psNumerator = IController(controller()).psNumerator();
    uint256 psDenominator = IController(controller()).psDenominator();
    return _amount * psNumerator / psDenominator;
  }

  /// @dev Compute amount for TETU liquidity
  function _toTetuLiquidityAmount(uint256 _amount) internal view returns (uint256) {
    return _amount * liquidityNumerator() / LIQUIDITY_DENOMINATOR;
  }

  /// @dev Compute Approximate Total amount normalized to TETU token
  /// @param _amount Amount of TETU token distributed to PS and Vault
  /// @return Approximate Total amount normalized to TETU token
  function _plusFundAmountToDistributedAmount(uint256 _amount) internal view returns (uint256) {
    uint256 fundNumerator = IController(controller()).fundNumerator();
    uint256 fundDenominator = IController(controller()).fundDenominator();
    return _amount * fundDenominator / (fundDenominator - fundNumerator);
  }

  /// @dev Swap one token to another using all available amount
  function _liquidate(address _tokenIn, address _tokenOut, uint256 _amount) internal returns (uint256) {
    if (_tokenIn == _tokenOut) {
      // this is already the right token
      return _amount;
    }
    (LpData[] memory route, uint count) = _createLiquidationRoute(_tokenIn, _tokenOut);

    uint outBalance = _amount;
    for (uint i = 0; i < count; i++) {
      LpData memory lpData = route[i];
      uint outBalanceBefore = IERC20(lpData.oppositeToken).balanceOf(address(this));
      _swap(lpData.token, lpData.oppositeToken, IUniswapV2Pair(lpData.lp), outBalance);
      outBalance = IERC20(lpData.oppositeToken).balanceOf(address(this)) - outBalanceBefore;
    }
    return outBalance;
  }

  function _createLiquidationRoute(address _tokenIn, address _tokenOut) internal view returns (LpData[] memory, uint)  {
    LpData[] memory route = new LpData[](ROUTE_LENGTH_MAX);
    // in case that we try to liquidate blue chips use bc lps directly
    LpData memory lpDataBC = blueChipsLps[_tokenIn][_tokenOut];
    if (lpDataBC.lp != address(0)) {
      lpDataBC.token = _tokenIn;
      lpDataBC.oppositeToken = _tokenOut;
      route[0] = lpDataBC;
      return (route, 1);
    }

    // find the best LP for token IN
    LpData memory lpDataIn = largestLps[_tokenIn];
    require(lpDataIn.lp != address(0), "F2: not found LP for tokenIn");
    route[0] = lpDataIn;
    // if the best LP for token IN a pair with token OUT token we complete the route
    if (lpDataIn.oppositeToken == _tokenOut) {
      return (route, 1);
    }

    // if we able to swap opposite token to a blue chip it is the cheaper way to liquidate
    lpDataBC = blueChipsLps[lpDataIn.oppositeToken][_tokenOut];
    if (lpDataBC.lp != address(0)) {
      lpDataBC.token = lpDataIn.oppositeToken;
      lpDataBC.oppositeToken = _tokenOut;
      route[1] = lpDataBC;
      return (route, 2);
    }

    // find the largest LP for token out
    LpData memory lpDataOut = largestLps[_tokenOut];
    require(lpDataIn.lp != address(0), "F2: not found LP for tokenOut");
    // if we can swap between largest LPs the route is ended
    if (lpDataIn.oppositeToken == lpDataOut.oppositeToken) {
      lpDataOut.oppositeToken = lpDataOut.token;
      lpDataOut.token = lpDataIn.oppositeToken;
      route[1] = lpDataOut;
      return (route, 2);
    }

    // if we able to swap opposite token to a blue chip it is the cheaper way to liquidate
    lpDataBC = blueChipsLps[lpDataIn.oppositeToken][lpDataOut.oppositeToken];
    if (lpDataBC.lp != address(0)) {
      lpDataBC.token = lpDataIn.oppositeToken;
      lpDataBC.oppositeToken = lpDataOut.oppositeToken;
      route[1] = lpDataBC;
      lpDataOut.oppositeToken = lpDataOut.token;
      lpDataOut.token = lpDataBC.oppositeToken;
      route[2] = lpDataOut;
      return (route, 3);
    }

    LpData memory lpDataInMiddle;
    // this case only for a token with specific opposite token in a pair
    if (!blueChipsTokens[lpDataIn.oppositeToken]) {

      // some tokens have primary liquidity with specific token
      // need to find a liquidity for them
      lpDataInMiddle = largestLps[lpDataIn.oppositeToken];
      require(lpDataInMiddle.lp != address(0), "F2: not found LP for middle in");
      route[1] = lpDataInMiddle;
      if (lpDataInMiddle.oppositeToken == _tokenOut) {
        return (route, 2);
      }

      // if we able to swap opposite token to a blue chip it is the cheaper way to liquidate
      lpDataBC = blueChipsLps[lpDataInMiddle.oppositeToken][_tokenOut];
      if (lpDataBC.lp != address(0)) {
        lpDataBC.token = lpDataInMiddle.oppositeToken;
        lpDataBC.oppositeToken = _tokenOut;
        route[2] = lpDataBC;
        return (route, 3);
      }

      // if we able to swap opposite token to a blue chip it is the cheaper way to liquidate
      lpDataBC = blueChipsLps[lpDataInMiddle.oppositeToken][lpDataOut.oppositeToken];
      if (lpDataBC.lp != address(0)) {
        lpDataBC.token = lpDataInMiddle.oppositeToken;
        lpDataBC.oppositeToken = lpDataOut.oppositeToken;
        route[2] = lpDataBC;
        (lpDataOut.oppositeToken, lpDataOut.token) = (lpDataOut.token, lpDataOut.oppositeToken);
        route[3] = lpDataOut;
        return (route, 4);
      }

    }


    // if we don't have pair for token out try to find a middle lp
    // it needs for cases where tokenOut has a pair with specific token
    LpData memory lpDataOutMiddle = largestLps[lpDataOut.oppositeToken];
    require(lpDataOutMiddle.lp != address(0), "F2: not found LP for middle out");
    // even if we found lpDataInMiddle we have shorter way
    if (lpDataOutMiddle.oppositeToken == lpDataIn.oppositeToken) {
      (lpDataOutMiddle.oppositeToken, lpDataOutMiddle.token) = (lpDataOutMiddle.token, lpDataOutMiddle.oppositeToken);
      route[1] = lpDataOutMiddle;
      return (route, 2);
    }

    // tokenIn has not pair with bluechips
    if (lpDataInMiddle.lp != address(0)) {
      lpDataBC = blueChipsLps[lpDataInMiddle.oppositeToken][lpDataOutMiddle.oppositeToken];
      if (lpDataBC.lp != address(0)) {
        lpDataBC.token = lpDataInMiddle.oppositeToken;
        lpDataBC.oppositeToken = lpDataOutMiddle.oppositeToken;
        route[2] = lpDataBC;
        (lpDataOutMiddle.oppositeToken, lpDataOutMiddle.token) = (lpDataOutMiddle.token, lpDataOutMiddle.oppositeToken);
        route[3] = lpDataOutMiddle;
        (lpDataOut.oppositeToken, lpDataOut.token) = (lpDataOut.token, lpDataOut.oppositeToken);
        route[4] = lpDataOut;
        return (route, 5);
      }
    } else {
      // tokenIn has pair with bluechips
      lpDataBC = blueChipsLps[lpDataIn.oppositeToken][lpDataOutMiddle.oppositeToken];
      if (lpDataBC.lp != address(0)) {
        lpDataBC.token = lpDataIn.oppositeToken;
        lpDataBC.oppositeToken = lpDataOutMiddle.oppositeToken;
        route[1] = lpDataBC;
        (lpDataOutMiddle.oppositeToken, lpDataOutMiddle.token) = (lpDataOutMiddle.token, lpDataOutMiddle.oppositeToken);
        route[2] = lpDataOutMiddle;
        (lpDataOut.oppositeToken, lpDataOut.token) = (lpDataOut.token, lpDataOut.oppositeToken);
        route[3] = lpDataOut;
        return (route, 4);
      }
    }

    // we are not handling other cases
    revert("F2: Liquidation path not found");
  }


  /// @dev Adopted version of swap function from UniswapRouter
  ///      Assume that tokens exist on this contract
  function _swap(address tokenIn, address tokenOut, IUniswapV2Pair lp, uint amount) internal {
    require(amount != 0, "F2: Zero swap amount");
    (uint reserveIn, uint reserveOut) = getReserves(lp, tokenIn, tokenOut);

    UniFee memory fee = uniPlatformFee[lp.factory()];
    if (fee.nominator == 0) {
      fee = UniFee(DEFAULT_UNI_FEE_NOMINATOR, DEFAULT_UNI_FEE_DENOMINATOR);
    }
    uint amountOut = getAmountOut(amount, reserveIn, reserveOut, fee);

    IERC20(tokenIn).safeTransfer(address(lp), amount);
    _swapCall(lp, tokenIn, tokenOut, amountOut);
  }

  function _addLiquidity(
    address _router,
    address _token0,
    address _token1,
    uint256 _token0Amount,
    uint256 _token1Amount
  ) internal returns (uint256){
    IERC20(_token0).safeApprove(_router, 0);
    IERC20(_token0).safeApprove(_router, _token0Amount);
    IERC20(_token1).safeApprove(_router, 0);
    IERC20(_token1).safeApprove(_router, _token1Amount);

    (,, uint256 liquidity) = IUniswapV2Router02(_router).addLiquidity(
      _token0,
      _token1,
      _token0Amount,
      _token1Amount,
      _token0Amount * SLIPPAGE_NOMINATOR / SLIPPAGE_DENOMINATOR,
      _token1Amount * SLIPPAGE_NOMINATOR / SLIPPAGE_DENOMINATOR,
      address(this),
      block.timestamp
    );
    emit LiquidityAdded(_router, _token0, _token0Amount, _token1, _token1Amount);
    return liquidity;
  }

  /// @dev Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, UniFee memory fee) internal pure returns (uint amountOut) {
    uint amountInWithFee = amountIn * fee.nominator;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = (reserveIn * fee.denominator) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  /// @dev Call swap function on pair with necessary preparations
  ///      Assume that amountOut already sent to the pair
  function _swapCall(IUniswapV2Pair _lp, address tokenIn, address tokenOut, uint amountOut) internal {
    (address token0,) = sortTokens(tokenIn, tokenOut);
    (uint amount0Out, uint amount1Out) = tokenIn == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
    _lp.swap(amount0Out, amount1Out, address(this), new bytes(0));
  }

  /// @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  /// @dev fetches and sorts the reserves for a pair
  function getReserves(IUniswapV2Pair _lp, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = _lp.getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function changeActivityStatus(bool _active) external;

  function changeProtectionMode(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function setLockPeriod(uint256 _value) external;

  function setLockPenalty(uint256 _value) external;

  function setToInvest(uint256 _value) external;

  function doHardWork() external;

  function rebalance() external;

  function disableLock() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFor(uint256 amount, address holder) external;

  function withdraw(uint256 numberOfShares) external;

  function exit() external;

  function getAllRewards() external;

  function getReward(address rt) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function duration() external view returns (uint256);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function availableToInvestOut() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function earnedWithBoost(address rt, address account) external view returns (uint256);

  function rewardPerToken(address rt) external view returns (uint256);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function rewardTokensLength() external view returns (uint256);

  function active() external view returns (bool);

  function rewardTokens() external view returns (address[] memory);

  function periodFinishForToken(address _rt) external view returns (uint256);

  function rewardRateForToken(address _rt) external view returns (uint256);

  function lastUpdateTimeForToken(address _rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

  function rewardsForToken(address _rt, address account) external view returns (uint256);

  function userLastWithdrawTs(address _user) external view returns (uint256);

  function userLastDepositTs(address _user) external view returns (uint256);

  function userBoostTs(address _user) external view returns (uint256);

  function userLockTs(address _user) external view returns (uint256);

  function addRewardToken(address rt) external;

  function removeRewardToken(address rt) external;

  function stop() external;

  function ppfsDecreaseAllowed() external view returns (bool);

  function lockPeriod() external view returns (uint256);

  function lockPenalty() external view returns (uint256);

  function toInvest() external view returns (uint256);

  function depositFeeNumerator() external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IFeeRewardForwarder {
  function distribute(uint256 _amount, address _token, address _vault) external returns (uint256);

  function notifyPsPool(address _token, uint256 _amount) external returns (uint256);

  function notifyCustomPool(address _token, address _rewardPool, uint256 _maxBuyback) external returns (uint256);

  function liquidate(address tokenIn, address tokenOut, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerFundKeeperEarned(address _token, uint256 _fundTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerVaultTransfer(address from, address to, uint256 amount) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function registerRewardDistribution(address vault, address token, uint256 amount) external;

  function vaults() external view returns (address[] memory);

  function vaultsLength() external view returns (uint256);

  function strategies() external view returns (address[] memory);

  function strategiesLength() external view returns (uint256);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  /// @notice Return total earned TETU tokens for strategy
  /// @dev Should be incremented after strategy rewards distribution
  /// @param strategy Strategy address
  /// @return Earned TETU tokens
  function targetTokenEarned(address strategy) external view returns (uint256);

  /// @notice Return share(xToken) balance of given user
  /// @dev Should be calculated for each xToken transfer
  /// @param vault Vault address
  /// @param user User address
  /// @return User share (xToken) balance
  function vaultUsersBalances(address vault, address user) external view returns (uint256);

  /// @notice Return earned token amount for given token and user
  /// @dev Fills when user claim rewards
  /// @param user User address
  /// @param vault Vault address
  /// @param token Token address
  /// @return User's earned tokens amount
  function userEarned(address user, address vault, address token) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  /// @notice Return users quantity for given Vault
  /// @dev Calculation based in Bookkeeper user balances
  /// @param vault Vault address
  /// @return Users quantity
  function vaultUsersQuantity(address vault) external view returns (uint256);

  function fundKeeperEarned(address vault) external view returns (uint256);

  function vaultRewards(address vault, address token, uint256 idx) external view returns (uint256);

  function vaultRewardsLength(address vault, address token) external view returns (uint256);

  function strategyEarnedSnapshots(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsTime(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsLength(address strategy) external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Router02 {
  function factory() external view returns (address);

  function WETH() external view returns (address);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: UNLICENSED

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IFeeRewardForwarder.sol";

/// @title Eternal storage + getters and setters pattern
/// @dev If you will change a key value it will require setup it again
/// @author belbix
abstract contract ForwarderV2Storage is Initializable {

  struct LpData {
    address lp;
    address token;
    address oppositeToken;
  }

  struct UniFee {
    uint nominator;
    uint denominator;
  }

  // don't change names or ordering!
  mapping(bytes32 => uint256) private uintStorage;
  mapping(bytes32 => address) private addressStorage;

  /// @dev Liquidity Pools with the highest TVL for given token
  mapping(address => LpData) public largestLps;
  /// @dev Liquidity Pools with the most popular tokens
  mapping(address => mapping(address => LpData)) public blueChipsLps;
  /// @dev Factory address to fee value map
  mapping(address => UniFee) public uniPlatformFee;
  /// @dev Hold blue chips tokens addresses
  mapping(address => bool) public blueChipsTokens;

  /// @notice Address changed the variable with `name`
  event UpdatedAddressSlot(string indexed name, address oldValue, address newValue);
  /// @notice Value changed the variable with `name`
  event UpdatedUint256Slot(string indexed name, uint256 oldValue, uint256 newValue);

  // ******************* SETTERS AND GETTERS **********************

  function _setLiquidityRouter(address _address) internal {
    emit UpdatedAddressSlot("liquidityRouter", liquidityRouter(), _address);
    setAddress("liquidityRouter", _address);
  }

  /// @notice Router address for adding liquidity
  function liquidityRouter() public view returns (address) {
    return getAddress("liquidityRouter");
  }

  function _setLiquidityNumerator(uint256 _value) internal {
    emit UpdatedUint256Slot("liquidityNumerator", liquidityNumerator(), _value);
    setUint256("liquidityNumerator", _value);
  }

  /// @notice Numerator for part of profit that goes to TETU liquidity
  function liquidityNumerator() public view returns (uint256) {
    return getUint256("liquidityNumerator");
  }

  // ******************** STORAGE INTERNAL FUNCTIONS ********************

  function setAddress(string memory key, address _address) private {
    addressStorage[keccak256(abi.encodePacked(key))] = _address;
  }

  function getAddress(string memory key) private view returns (address) {
    return addressStorage[keccak256(abi.encodePacked(key))];
  }

  function setUint256(string memory key, uint256 _value) private {
    uintStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getUint256(string memory key) private view returns (uint256) {
    return uintStorage[keccak256(abi.encodePacked(key))];
  }

  //slither-disable-next-line unused-state
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function distributor() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function rebalance(address _strategy) external;

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function changeWhiteListStatus(address[] calldata _targets, bool status) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}