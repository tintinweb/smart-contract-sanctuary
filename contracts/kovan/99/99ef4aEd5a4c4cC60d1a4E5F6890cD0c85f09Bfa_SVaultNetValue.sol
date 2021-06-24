pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IPair.sol";

interface IToken{
    function decimals() view external returns (uint256);
}

contract PriceView {
    using SafeMath for uint256;
    IFactory public factory;
    address public anchorToken;
    address public usdt;
    uint256 constant private one = 1e18;

    constructor(address _anchorToken, address _usdt, IFactory _factory) public {
        anchorToken = _anchorToken;
        usdt = _usdt;
        factory = _factory;
    }

    function getPrice(address token) view external returns (uint256){
        if(token == anchorToken) return one;
        address pair = factory.getPair(token, anchorToken);
        (uint256 reserve0, uint256 reserve1,) = IPair(pair).getReserves();
        (uint256 tokenReserve, uint256 anchorTokenReserve) = token == IPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        return one.mul(anchorTokenReserve).div(tokenReserve);
    }

    function getPriceInUSDT(address token) view external returns (uint256){
        uint256 decimals = IToken(token).decimals();
        if(token == usdt) return 10 ** decimals;
        decimals = IToken(anchorToken).decimals();
        uint256 price = 10 ** decimals;
        if(token != anchorToken){
            decimals = IToken(token).decimals();
            address pair = factory.getPair(token, anchorToken);
            (uint256 reserve0, uint256 reserve1,) = IPair(pair).getReserves();
            (uint256 tokenReserve, uint256 anchorTokenReserve) = token == IPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
            price = (10 ** decimals).mul(anchorTokenReserve).div(tokenReserve);
        }
        if(anchorToken != usdt){
            address pair = factory.getPair(anchorToken, usdt);
            (uint256 reserve0, uint256 reserve1,) = IPair(pair).getReserves();
            (uint256 anchorTokenReserve, uint256 usdtReserve) = anchorToken == IPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
            price = price.mul(usdtReserve).div(anchorTokenReserve);
        }
        return price;
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IFundPool.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IController.sol";
import "./PriceView.sol";

contract SVaultNetValue {
    using SafeMath for uint256;
    
    address public admin;
    address public controller;
    PriceView public priceView;
    mapping(address => uint256) public poolWeight;
    uint256 public tokenCount = 1;

   struct PoolInfo{
        address pool;
        address token;
        //uint256 amount;
        uint256 amountInUSD;
        uint256 weight;
        uint256 profitWeight;
        uint256 allocatedProfitInUSD;
        uint256 price;
    }

    struct NetValue{
        address pool;
        address token;
        uint256 amount;
        uint256 amountInUSD;
        uint256 totalTokens; //本金加收益
        uint256 totalTokensInUSD; //本金加收益
    }

    struct TokenPrice{
        address token;
        uint256 price;
        // uint256 amount;
        //uint256 amountInUSD;
    }

    event PoolWeight(address pool, uint256 weight);

    constructor (address _controller, PriceView _priceView) public {
        controller = _controller;
        priceView = _priceView;
        admin = msg.sender;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "!admin");
        admin = _admin;
    }

    function setPoolWeight(address[] memory pools, uint256[] memory weights) external{
        require(msg.sender == admin, "!admin");
        require(pools.length == weights.length, "Invalid input");
        IController(controller).accrueProfit();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();
        for(uint256 i = 0; i < pools.length; i++){
            require(hasItem(flexiblePools,pools[i]),"Invalid pool");
            require(weights[i] > 0, "Invalid weight");
            poolWeight[pools[i]] = weights[i];
            emit PoolWeight(pools[i], weights[i]);
        }
    }

    function removePoolWeight(address pool) external{
        require(msg.sender == admin, "!admin");
        IController(controller).accrueProfit();
        delete poolWeight[pool];
        emit PoolWeight(pool, 0);
    }

    function setTokenCount(uint256 count) external{
        require(msg.sender == admin, "!admin");
        require(count > 0, "Invalid input");
        tokenCount = count;
    }

    function getNetValueForTest(address pool) view external returns(NetValue memory netValue, uint256 blockNumber) {
        NetValue[] memory netValues = getNetValues();
        blockNumber = block.number;
        for(uint256 i = 0; i < netValues.length; i++){
            if(netValues[i].pool == pool){
                netValue = netValues[i];
                break;
            }
        }
    }

    function getNetValue(address pool) view external returns(NetValue memory){
        NetValue[] memory netValues = getNetValues();
        for(uint256 i = 0; i < netValues.length; i++){
            if(netValues[i].pool == pool) return netValues[i];
        }
    }

    function getNetValues() view public returns(NetValue[] memory netValues){
        address[] memory fixedPools = IController(controller).getFixedPools();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();
        uint256 count = fixedPools.length.add(flexiblePools.length);
        TokenPrice[] memory tokenPrices = new TokenPrice[](tokenCount);
        // get all tokens in pool and strategy
        uint256 allTokensInUSD = getAllTokensInUSD(fixedPools, flexiblePools, tokenPrices);
        netValues = new NetValue[](count);
        uint256 totalFixedPoolUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            netValues[i].pool = fixedPools[i];
            (netValues[i].token, netValues[i].amount, netValues[i].totalTokens) = IFundPool(fixedPools[i]).getTotalTokensByProfitRate();
            uint256 price = getTokenPrice(tokenPrices, netValues[i].token);
            netValues[i].amountInUSD = price.mul(netValues[i].amount);
            netValues[i].totalTokensInUSD = price.mul(netValues[i].totalTokens);
            totalFixedPoolUSD = totalFixedPoolUSD.add(netValues[i].totalTokensInUSD);
        }
        if(allTokensInUSD < totalFixedPoolUSD) return netValues;
        allTokensInUSD = allTokensInUSD.sub(totalFixedPoolUSD);
        (PoolInfo[] memory poolInfos, uint256 totalWeight, uint256 totalProfitWeight, uint256 totalAmountInUSD, uint256 totalAllocatedProfitInUSD) = getPoolInfos(flexiblePools, tokenPrices);
        uint256 totalProfitAmountInUSD = 0;
        allTokensInUSD = allTokensInUSD.sub(totalAllocatedProfitInUSD);
        if(allTokensInUSD < totalAmountInUSD){
            totalAmountInUSD = allTokensInUSD;
        }else{
            totalProfitAmountInUSD = allTokensInUSD.sub(totalAmountInUSD);
        }

        uint256 fixedPoolLength = fixedPools.length;
        for(uint256 i = 0; i < poolInfos.length; i++){
            NetValue memory netValue = netValues[fixedPoolLength+i];
            netValue.pool = poolInfos[i].pool;
            netValue.token = poolInfos[i].token;
            netValue.amountInUSD = totalWeight == 0 ? 0 : totalAmountInUSD.mul(poolInfos[i].weight).div(totalWeight);
            uint256 allocatedProfitInUSD = poolInfos[i].allocatedProfitInUSD;
             if(netValue.amountInUSD < poolInfos[i].amountInUSD){
                uint256 lossAmountInUSD = poolInfos[i].amountInUSD.sub(netValue.amountInUSD);
                lossAmountInUSD = lossAmountInUSD > allocatedProfitInUSD ? allocatedProfitInUSD : lossAmountInUSD;
                netValue.amountInUSD = netValue.amountInUSD.add(lossAmountInUSD);
                allocatedProfitInUSD = allocatedProfitInUSD.sub(lossAmountInUSD);
            }
            netValue.totalTokensInUSD = netValue.amountInUSD.add(totalProfitWeight == 0 ? 0 : totalProfitAmountInUSD.mul(poolInfos[i].profitWeight).div(totalProfitWeight)).add(allocatedProfitInUSD);
            netValue.amount =netValue.amountInUSD.div(poolInfos[i].price);
            netValue.totalTokens = netValue.totalTokensInUSD.div(poolInfos[i].price);
        }
    }

    //get flexible pool weight
    function getPoolInfos(address[] memory flexiblePools, TokenPrice[] memory tokenPrices) view internal returns (PoolInfo[] memory, uint256, uint256, uint256, uint256){
        PoolInfo[] memory poolWeights = new PoolInfo[](flexiblePools.length);
        uint256 totalProfitWeight = 0;
        uint256 totalAmountInUSD = 0;
        uint256 totalAllocatedProfitInUSD = 0;
        uint256 amount = 0;
        for(uint256 i = 0; i < flexiblePools.length; i++){
            poolWeights[i].pool = flexiblePools[i];
            (poolWeights[i].token, amount) = IFundPool(flexiblePools[i]).getTotalTokenSupply();
            poolWeights[i].price = getTokenPrice(tokenPrices, poolWeights[i].token);
            poolWeights[i].amountInUSD = poolWeights[i].price.mul(amount);
            poolWeights[i].weight = poolWeights[i].amountInUSD;
            uint256 profitWeight = poolWeight[poolWeights[i].pool];
            poolWeights[i].profitWeight = poolWeights[i].weight.mul(profitWeight);
            poolWeights[i].allocatedProfitInUSD = IController(controller).allocatedProfit(poolWeights[i].pool).mul(poolWeights[i].price);
            totalAmountInUSD = totalAmountInUSD.add(poolWeights[i].amountInUSD);
            totalProfitWeight = totalProfitWeight.add(poolWeights[i].profitWeight);
            totalAllocatedProfitInUSD = totalAllocatedProfitInUSD.add(poolWeights[i].allocatedProfitInUSD);
        }
        return (poolWeights,totalAmountInUSD,totalProfitWeight,totalAmountInUSD,totalAllocatedProfitInUSD);
    }

    function getAllTokensInUSD(address[] memory fixedPools, address[] memory flexiblePools, TokenPrice[] memory tokenPrices) view internal returns(uint256){
        uint256 allTokensInUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            (address token, uint256 tokenBalance) = IFundPool(fixedPools[i]).getTokenBalance();
            if(tokenBalance == 0) continue;
            allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, token).mul(tokenBalance));
        }
        for(uint256 i = 0; i < flexiblePools.length; i++){
            (address token, uint256 tokenBalance) = IFundPool(flexiblePools[i]).getTokenBalance();
            if(tokenBalance == 0) continue;
            allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, token).mul(tokenBalance));
        }
        address[] memory strategies = IController(controller).getStrategies();
        for(uint256 i = 0; i < strategies.length; i++) {
            (address[] memory tokens, uint256[] memory amounts) = IStrategy(strategies[i]).getTokenAmounts();
            for(uint256 j = 0; j < tokens.length; j++){
                if(amounts[j] == 0) continue;
                allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, tokens[j]).mul(amounts[j]));
            }
        }
        return allTokensInUSD;
    }

    function getTokenPrice(TokenPrice[] memory tokenPrices, address token) view internal returns (uint256){
        for(uint256 j = 0; j < tokenPrices.length; j++){
            if(tokenPrices[j].token == address(0)){
                tokenPrices[j].token = token;
                tokenPrices[j].price = priceView.getPrice(token);
                return tokenPrices[j].price;
            }else if(token == tokenPrices[j].token){
                return tokenPrices[j].price;
            }
        }
        return priceView.getPrice(token);
    }

    function hasItem(address[] memory _array, address _item) internal pure returns (bool){
        for(uint256 i = 0; i < _array.length; i++){
            if(_array[i] == _item) return true;
        }
        return false;
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./ISVaultNetValue.sol";

interface IController {
    struct TokenAmount{
        address token;
        uint256 amount;
    }
    function withdraw(uint256 _amount, uint256 _profitAmount) external returns (TokenAmount[] memory);
    function accrueProfit() external returns (ISVaultNetValue.NetValue[] memory netValues);
    function getStrategies() view external returns(address[] memory);
    function getFixedPools() view external returns(address[] memory);
    function getFlexiblePools() view external returns(address[] memory);
    function allocatedProfit(address _pool) view external returns(uint256);
    function acceptedPools(address token, address pool) view external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity ^0.6.12;

abstract contract IFundPool {
    function token() external view virtual returns (address);

    function takeToken(uint256 amount) external virtual;

    function getTotalTokensByProfitRate()
        external
        view
        virtual
        returns (
            address,
            uint256,
            uint256
        );

    function profitRatePerBlock() external view virtual returns (uint256);

    function getTokenBalance() external view virtual returns (address, uint256);

    function getTotalTokenSupply()
        external
        view
        virtual
        returns (address, uint256);

    function returnToken(uint256 amount) external virtual;

    function deposit(uint256 amount, string memory channel) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPair {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ISVaultNetValue {
    function getNetValue(address pool) external view returns (NetValue memory);

    struct NetValue {
        address pool;
        address token;
        uint256 amount;
        uint256 amountInETH;
        uint256 totalTokens; //本金加收益
        uint256 totalTokensInETH; //本金加收益
    }
}

pragma solidity ^0.6.12;

abstract contract IStrategy {
    function earn(address[] memory tokens, uint256[] memory amounts, address[] memory earnTokens, uint256[] memory amountLimits) external virtual;
    function withdraw(address token) external virtual returns (uint256);
    function withdraw(uint256 amount) external virtual returns (address[] memory tokens, uint256[] memory amounts);
    function withdraw(address[] memory tokens, uint256 amount) external virtual returns (uint256, address[] memory, uint256[] memory);
    function withdrawProfit(address token, uint256 amount) external virtual returns (uint256, address[] memory, uint256[] memory);
    //function withdraw(address[] memory tokens, uint256 amount, uint256 _profitAmount) external virtual returns (uint256, uint256, address[] memory, uint256[] memory);
    function reinvestment(address[] memory pools, address[] memory tokens, uint256[] memory amounts) external virtual;
    function getTokenAmounts() external view virtual returns (address[] memory tokens, uint256[] memory amounts);
    function getTokens() external view virtual returns (address[] memory tokens);
    function getProfitTokens() external view virtual returns (address[] memory tokens);
    function getProfitAmount() view external virtual returns (address[] memory tokens, uint256[] memory amounts, uint256[] memory pendingAmounts);
    function isStrategy() external view virtual returns (bool);
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
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