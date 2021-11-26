// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/AddressArray.sol";
import "./interfaces/ICapitalStruggleV2.sol";
import "./Token.sol";

contract CapitalStruggleV2 is ICapitalStruggleV2, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using AddressArray for address[];
  
  Token public Capital;
  Token public Struggle;
  IUniswapV2Factory public factory;
  IWETH public WETH;
  IERC20 public DAI;
  address[] public tokens;
  uint256 public flipFee = 0.001 ether;
  mapping(address=>uint256) activeTokens;
  IUniswapV2Router02 public router;
  bool public initiated;
  bool public paused = true;
  
  constructor(ConstructorParam memory info){
    Capital = Token(info.capital);
    Struggle = Token(info.struggle);
    WETH = IWETH(info.weth);
    DAI = IERC20(info.dai);
    tokens.addValue(address(info.weth));
    tokens.addValue(address(info.dai));
    router = IUniswapV2Router02(info.router);
    factory = IUniswapV2Factory(router.factory());
    IERC20(address(WETH)).approve(address(router), type(uint256).max);
    DAI.approve(address(router), type(uint256).max);
    Struggle.approve(address(router), type(uint256).max);
  }

  modifier notPaused {
    require(!paused, "contract paused");
    _;
  }
  
  function setFlipFee(uint256 _fee) external override onlyOwner {
    flipFee = _fee;
  }

  function setPaused(bool status) external override onlyOwner {
    paused = status;
  }
  
  function tokensLength() external override view returns(uint256){
    return tokens.length;
  }

  function estimateSwap(uint256 amount, address fromToken, address toToken)
    internal
    view
    returns(uint256){
    
    address[] memory path = new address[](2);
    path[0] = address(fromToken);
    path[1] = address(toToken);
    uint256[] memory expected = router.getAmountsOut(amount, path);      
    return expected[1];
  }
  
  function swap(uint256 amount, address fromToken, address toToken, uint256 minOutput)
    internal
    returns(uint256){
    
    forceRouterAllowance(address(fromToken), amount);
    address[] memory path = new address[](2);
    path[0] = fromToken;
    path[1] = toToken;
    uint256[] memory resulted = router.swapExactTokensForTokens(amount,
                                                                minOutput,
                                                                path,
                                                                address(this),
                                                                block.timestamp * 2);
    return resulted[1];
  }

  function upgrade(address[] calldata _tokens)
    external
    override
    onlyOwner
    {
    
      require(!initiated, "AI");
      initiated = true;
      activeTokens[address(WETH)] = block.timestamp;
      activeTokens[address(DAI)] = block.timestamp;
      for(uint256 i = 0; i < _tokens.length; i++){
        tokens.addValue(_tokens[i]);
        activeTokens[_tokens[i]] = block.timestamp;
      }
  }
  
  function mintCapital(address to, uint256 amount)
    internal {
    
    Capital.mint(amount);
    Capital.transfer(to, amount);
  }

  function refundRemaining(address token) internal {
    uint256 remainingBalance = IERC20(token).balanceOf(address(this));
    if(remainingBalance > 0){
      IERC20(token).transfer(msg.sender, remainingBalance);
    }
  }

  function initTokenWithToken(address token, uint256 tokenAmount)
    external
    override
    onlyOwner
    {
    require(activeTokens[token] == 0,
            "ITWTAI"); // token must not be already initiated
    require(tokenAmount > 0,
            "ITWTIA");
    require(IERC20(token).balanceOf(msg.sender) >= tokenAmount
            && IERC20(token).allowance(msg.sender, address(this)) >= tokenAmount,
            "ITWTB");
    IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
    activeTokens[token] = block.timestamp;
    tokens.addValue(token);
    uint256 tokenValue = estimateSwap(tokenAmount, token, address(WETH));
    uint256 struggleAmount = estimatedStruggle(tokenValue);
    uint256 liquidity = addLiquidity(token, tokenAmount, struggleAmount);
    mintCapital(msg.sender, liquidity.div(tokens.length));
    refundRemaining(token);
  }
  
  function initToken(address token)
    external
    override
    onlyOwner
    payable {
    
    require(activeTokens[token] == 0,
            "ITAI"); // token must not be already initiated
    require(msg.value > 0,
            "ITIA"); 
    activeTokens[token] = block.timestamp;
    tokens.addValue(token);
    WETH.deposit{value: msg.value}();
    uint256 tokenAmount = estimateSwap(msg.value, address(WETH), token);
    tokenAmount = swap(msg.value, address(WETH), token, tokenAmount);
    uint256 struggleAmount = estimatedStruggle(msg.value);
    uint256 liquidity = addLiquidity(token, tokenAmount, struggleAmount);
    mintCapital(msg.sender, liquidity.div(tokens.length));
    refundRemaining(address(WETH));
    refundRemaining(token);
  }
  
  function depositETH() external override notPaused payable{
    require(msg.value > tokens.length, "IDV");
    WETH.deposit{value: msg.value}();
    _deposit(msg.value, true);
    refundRemaining(address(WETH));
  }
  
  function depositToken(address token, uint256 amount) external override notPaused {
    require(activeTokens[token] > 0, "DTNA"); //  accepting only active tokens as deposit
    require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "DNEA");
    require(IERC20(token).balanceOf(msg.sender) >= amount, "DNEB");
    IERC20(token).transferFrom(msg.sender, address(this), amount);
    if(token == address(WETH)){
      _deposit(amount, true);
    } else {
      // we will exchange all amount of provided token for WETH
      address[] memory path = new address[](2);
      path[0] = token;
      path[1] = address(WETH);
      uint256 expectedWeth = estimateSwap(amount,
                                          token,
                                          address(WETH));
      uint256 resultedWeth = swap(amount,
                                  token,
                                  address(WETH),
                                  expectedWeth);
      _deposit(resultedWeth, true);
    }
    refundRemaining(token);
    refundRemaining(address(WETH));
  }
  
  function strugglePair(address token)
    internal
    view
    returns (IUniswapV2Pair){
    
    return IUniswapV2Pair(factory.getPair(token, address(Struggle)));
  }
  
  function estimatedTokenStruggle(uint256 amount, address token)
    internal
    view
    returns(uint256){
    
    (uint256 reserve0, uint256 reserve1,) = strugglePair(token).getReserves();
    
    (uint256 reserveToken, uint256 reserveStruggle) = address(token) < address(Struggle) ? (reserve0, reserve1) : (reserve1, reserve0);
    require(reserve0 > 0 && reserve1 > 0, "NL");
    return amount.mul(reserveStruggle).div(reserveToken);
  }
  
  function estimatedStruggle(uint256 amountInWeth)
    internal
    view
    returns(uint256){
    
    return estimatedTokenStruggle(amountInWeth, address(WETH));
  }

  function forceRouterAllowance(address token, uint256 minAmount)
    internal {
    
    if(IERC20(token).allowance(address(this), address(router)) < minAmount){
      IERC20(token).approve(address(router), type(uint256).max);
    }
  }

  function addLiquidity(address token,
                        uint256 tokenAmount,
                        uint256 struggleAmount)
      internal
      returns (uint256) {
    
      Struggle.mint(struggleAmount.mul(2));
      forceRouterAllowance(token, tokenAmount);
      forceRouterAllowance(address(Struggle), struggleAmount);
      (,,uint256 liquidity) = router.addLiquidity(token,
                                                  address(Struggle),
                                                  tokenAmount,
                                                  struggleAmount,
                                                  0,
                                                  0,
                                                  address(this),
                                                  block.timestamp * 2);
      return liquidity;
  }
  
  function removeLiquidity(address token, uint256 amount)
    internal
    returns(uint256){
    
    address pair = address(strugglePair(token));
    
    IERC20(pair).transfer(pair, amount); // send liquidity to pair
    
    (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(address(this));
    (uint256 tokenAmount, uint256 struggleAmount) = address(token) < address(Struggle) ? (amount0, amount1) : (amount1, amount0);

    if(struggleAmount > 0){
      if(Struggle.balanceOf(address(this)) >=  struggleAmount.mul(2)){
        Struggle.burn(struggleAmount.mul(2));

      } else {
        Struggle.burn(struggleAmount);
      }
    }

    return tokenAmount;
  }

  function capitalPrice()
    external
    override
    view
    returns(uint256){
    
    uint256 wethAmount = 0;
    
    for(uint256 i = 0; i < tokens.length; i++){
      (uint256 reserve0, uint256 reserve1,) = strugglePair(tokens[i]).getReserves();

      (uint256 reserveToken,) = address(tokens[i]) < address(Struggle) ? (reserve0, reserve1) : (reserve1, reserve0);
      if(tokens[i] == address(WETH)){
        wethAmount = wethAmount.add(reserveToken);
      } else {
        wethAmount = wethAmount.add(estimateSwap(reserveToken,
                                                 tokens[i],
                                                 address(WETH)
                                                 ));
      }
    }
    
    return wethAmount.mul(1 ether).div(Capital.totalSupply());
  }

  function capitalPriceDAI()
    external
    override
    view
    returns(uint256){
    
    uint256 value = 0;
    
    for(uint256 i = 0; i < tokens.length; i++){
      (uint256 reserve0, uint256 reserve1,) = strugglePair(tokens[i]).getReserves();

      (uint256 reserveToken,) = address(tokens[i]) < address(Struggle) ? (reserve0, reserve1) : (reserve1, reserve0);
      if(tokens[i] == address(DAI)){
        value = value.add(reserveToken);
      } else {
        value = value.add(estimateSwap(reserveToken,
                                       tokens[i],
                                       address(DAI)
                                       ));
      }
    }
    
    return value.mul(1 ether).div(Capital.totalSupply());
  }

  function deactivateToken(address token)
    external
    override
    onlyOwner
  {
    require(activeTokens[token] > 0,
            "DNAT"); // can only deactivate active tokens
    
    address pair = address(strugglePair(token));
    uint256 liquidityBalance = IERC20(pair).balanceOf(address(this));
    require(liquidityBalance > 0,
            "DNEL"); // contract must own some liquidity
    uint256 tokenReceived = removeLiquidity(token, liquidityBalance);
    uint256 resultedWeth = swap(tokenReceived,
                                token,
                                address(WETH),
                                0);
    tokens.removeValue(token);
    
    _deposit(resultedWeth, false);
    
  }
  
  
  // only WETH
  function _deposit(uint256 amount, bool doMintCapital)
    internal
    nonReentrant {
    
    forceRouterAllowance(address(WETH), amount);
    uint256 valueWethPerToken = amount.div(tokens.length);
    uint256 totalStruggleForPairs = estimatedStruggle(amount);
    forceRouterAllowance(address(Struggle), totalStruggleForPairs);
    uint256 valueStrugglePerToken = totalStruggleForPairs.div(tokens.length);
    uint256 totalLiquidityGenerated = 0;
    for(uint256 i = 0; i < tokens.length; i++){
      if(tokens[i] == address(WETH)){
        uint256 liquidity = addLiquidity(address(WETH),
                                         valueWethPerToken,
                                         valueStrugglePerToken);
        totalLiquidityGenerated = totalLiquidityGenerated.add(liquidity);
      } else {
        forceRouterAllowance(address(tokens[i]), amount);
        uint256 expected = estimateSwap(valueWethPerToken,
                                        address(WETH),
                                        tokens[i]);      
        uint256 resulted = swap(valueWethPerToken,
                                address(WETH),
                                tokens[i],
                                expected);
        uint256 liquidity = addLiquidity(address(tokens[i]),
                                         resulted,
                                         valueStrugglePerToken);
        totalLiquidityGenerated = totalLiquidityGenerated.add(liquidity);
      }
    }
    if(doMintCapital){
      uint256 capitalToMint = totalLiquidityGenerated.div(tokens.length);
      Capital.mint(capitalToMint);
      Capital.transfer(msg.sender, capitalToMint);
    }
  }

  function withdrawETH(uint256 amount)
    external
    override
    notPaused
    nonReentrant {
    
    require(amount > 0, "WIV");
    require(Capital.balanceOf(msg.sender) >= amount, "WIB");
    require(Capital.allowance(msg.sender, address(this)) >= amount, "WIA");
    Capital.transferFrom(msg.sender, address(this), amount);
    uint256 withdrawPercentage = amount.mul(1 ether).div(Capital.totalSupply());
    require(withdrawPercentage > 0, "WATL");
    require(withdrawPercentage <= 1 ether, "WATH");
    uint256 totalWethValue = 0; 

    for(uint256 i = 0; i < tokens.length; i++){
      uint256 pairLiquidity = IERC20(address(strugglePair(tokens[i]))).balanceOf(address(this));
      
      uint256 liquidityToRemove = pairLiquidity.mul(withdrawPercentage).div(1 ether);

      if(liquidityToRemove > 0){
        uint256 amountToken = removeLiquidity(tokens[i], liquidityToRemove);

        if(tokens[i] == address(WETH)){
          totalWethValue = totalWethValue.add(amountToken);

        } else {
          if(amountToken > 0){

            totalWethValue = totalWethValue
              .add(swap(amountToken,
                        tokens[i],
                        address(WETH),
                        0));

          }
        }
      }
    }
    
    if(totalWethValue == 0){
      revert("WTL");
    }
    
    if(IERC20(address(WETH)).balanceOf(address(this)) >= totalWethValue){

      WETH.withdraw(totalWethValue);

      payable(msg.sender).transfer(totalWethValue);

    }else{
      revert("Not enough balance");
    }
    
    Capital.burn(amount);

  }

  function withdrawRaw(uint256 amount)
    external
    override
    notPaused
    nonReentrant {
    
    require(amount > 0, "WRIV");
    require(Capital.balanceOf(msg.sender) >= amount, "WRIB");
    require(Capital.allowance(msg.sender, address(this)) >= amount, "WRIA");

    Capital.transferFrom(msg.sender, address(this), amount);

    uint256 withdrawPercentage = amount.mul(1 ether).div(Capital.totalSupply());
    require(withdrawPercentage > 0, "WRATL");
    require(withdrawPercentage <= 1 ether, "WRATH");

    for(uint256 i = 0; i < tokens.length; i++){
      uint256 pairLiquidity = IERC20(address(strugglePair(tokens[i]))).balanceOf(address(this));
      
      uint256 liquidityToRemove = pairLiquidity.mul(withdrawPercentage).div(1 ether);

      if(liquidityToRemove > 0){
        uint256 amountToken = removeLiquidity(tokens[i], liquidityToRemove);
        if(amountToken > 0){
          IERC20(tokens[i]).transfer(msg.sender, amountToken);
        }
      }
    }
    
    Capital.burn(amount);

  }

  function swipe() external override onlyOwner {
    
      Struggle.transfer(msg.sender, Struggle.balanceOf(address(this)));
      if(address(this).balance > 0){
          payable(msg.sender).transfer(address(this).balance);
      }
      for(uint256 i = 0; i < tokens.length; i++){
          address pair = address(strugglePair(tokens[i]));
          uint256 LPBalance = IERC20(pair).balanceOf(address(this));
          if(LPBalance > 0){
              IERC20(pair).transfer(msg.sender, LPBalance);
          }
          refundRemaining(tokens[i]);
      }
  }
  
  function changeTokensOwnership(address _owner) external override onlyOwner {
      Capital.transferOwnership(_owner);
      Struggle.transferOwnership(_owner);
  }

  function setRouter(address _router) external override onlyOwner {
    router = IUniswapV2Router02(_router);
    factory = IUniswapV2Factory(router.factory());
    Struggle.approve(address(router), type(uint256).max);
    for(uint256 i = 0; i < tokens.length; i++){
      IERC20(tokens[i]).approve(address(router), type(uint256).max);
    }
  }

  function acceptedTolerance(address ofAddress) internal view returns(uint256){
    uint256 balanceOfAddress = Struggle.balanceOf(ofAddress);
    uint256 allowanceOfAddress = Struggle.allowance(ofAddress, address(this));
    if(balanceOfAddress == 0
       || allowanceOfAddress == 0){
      return 0;
    }
    if(balanceOfAddress > allowanceOfAddress){
      return allowanceOfAddress;
    }
    return balanceOfAddress;
  }
  
  function flip(uint256 amount, address[] memory path)
    external
    override
    nonReentrant {
    
    require(Capital.balanceOf(msg.sender) > 0,
            "FOC"); // only Capital holders can flip
    require(amount > 0
            && Struggle.balanceOf(address(this)) >= amount,
            "FIA"); // contract must have the Struggle amount to flip
    require(path.length > 3
            && path[0] == path[path.length-1]
            && path[0] == address(Struggle),
            "FIP"); // path through which the flip happens must begin and end with Struggle
    uint256 tolerance = acceptedTolerance(msg.sender);
    
    uint256[] memory expected = router.getAmountsOut(amount, path);
    require(expected[expected.length-1] + tolerance >= amount,
            "FIF"); // estimated flip result must be greater than the amount that is flipped
    forceRouterAllowance(address(Struggle), amount);
    
    uint256[] memory resulted = router.swapExactTokensForTokens(amount,
                                                                0,
                                                                path,
                                                                address(this),
                                                                block.timestamp * 2);
    require(resulted[resulted.length-1] + tolerance >= amount,
            "FIF2"); // resulting flip amount must be greater than the amount flipped
    uint256 flipResult = resulted[resulted.length-1];
    if(flipResult < amount){
      uint256 diff = amount.sub(flipResult);
      require(diff <= tolerance, "FT");
      Struggle.transferFrom(msg.sender, address(this), diff);
      flipResult = flipResult.add(diff);
    }
    uint256 result = flipResult.sub(amount);
    if(result > 0){
      uint256 struggleToBurn = result.div(2);
      uint256 fee = result.sub(struggleToBurn).mul(flipFee).div(1 ether);
      uint256 reward = result.sub(struggleToBurn).sub(fee);
      if(struggleToBurn > 0){
        Struggle.burn(struggleToBurn.add(fee).mul(2)); // burning 2 times the number of tokens + fees
      }
      if(reward > 0) {
        Struggle.transfer(msg.sender, reward);
      }
    }
  }

  receive() external payable {
   
  }

  fallback() external payable {
   
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
library SafeMath {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressArray {
  uint256 constant MAX_INT = 2 ** 256 - 1;
  function indexOf(address[] storage values, address value) internal view returns(uint256) {
    for(uint256 index = 0; index < values.length; index++){
      if(values[index] == value){
        return index;
      }
    }
    return MAX_INT;
  }
  function removeValue(address[] storage values, address value) internal {
    uint index = indexOf(values, value);
    if(index < values.length){
      removeValueAtIndex(values, index);
    }
  }
  function removeValueAtIndex(address[] storage values, uint256 index) internal {
    if(index < values.length){
      
      uint i = index;
      while(i < values.length-1){
        values[i] = values[i+1];
        i++;
      }
      values.pop();
    }
  }
  function addValue(address[] storage values, address value) internal {
    if(indexOf(values, value) >= values.length){
      values.push(value);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICapitalStruggleV2 {
  struct ConstructorParam{
    address capital;
    address struggle;
    address weth;
    address dai;
    address router;
  }
  function tokensLength() external view returns(uint256);
  function upgrade(address[] calldata) external;
  function flip(uint256, address[] memory) external;
  function swipe() external;
  function changeTokensOwnership(address) external;
  function setRouter(address) external;
  function withdrawRaw(uint256) external;
  function withdrawETH(uint256) external;
  function deactivateToken(address) external;
  function capitalPriceDAI() external view returns(uint256);
  function capitalPrice() external view returns(uint256);
  function depositToken(address, uint256) external;
  function depositETH() external payable;
  function initToken(address) external payable;
  function initTokenWithToken(address, uint256) external;
  function setPaused(bool) external;
  function setFlipFee(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
  uint8 private _decimals;
  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){
   
  }
  function decimals() public pure virtual override returns (uint8) {
    return 18;
  }
  function mint(uint256 amount) external onlyOwner{
    _mint(msg.sender, amount);
  }
  function burn(uint256 amount) external onlyOwner {
    _burn(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}