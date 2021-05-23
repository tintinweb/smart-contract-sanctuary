/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/interfaces/IFundPool.sol

pragma solidity ^0.6.12;

abstract contract IFundPool {
    function token() external view virtual returns (address);

    function take(uint256 amount) external virtual;

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
}

// File: contracts/interfaces/IStrategy.sol

pragma solidity ^0.6.12;

abstract contract IStrategy {
    function earn(address[] memory tokens, uint256[] memory amounts) external virtual;
    function withdraw(address token) external virtual returns (uint256);
    function withdraw(uint256 amount) external virtual returns (address[] memory tokens, uint256[] memory amounts);
    function withdraw(address[] memory tokens, uint256 amount, uint256 _profitAmount) external virtual returns (uint256, uint256, address[] memory, uint256[] memory);
    function getTokenAmounts() external view virtual returns (address[] memory tokens, uint256[] memory amounts);
    function getTokens() external view virtual returns (address[] memory tokens);
    function getProfitTokens() external view virtual returns (address[] memory tokens);
}

// File: contracts/interfaces/ISVaultNetValue.sol

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

// File: contracts/interfaces/IController.sol

pragma solidity ^0.6.12;



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
}

// File: contracts/interfaces/IFactory.sol


pragma solidity >=0.5.0;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// File: contracts/interfaces/IPair.sol


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

// File: contracts/PriceView.sol

pragma solidity ^0.6.12;





contract PriceView {
    using SafeMath for uint256;
    IFactory public factory;
    address public WETH;
    uint256 constant private one = 1e18;

    constructor(address _WETH, IFactory _factory) public {
        WETH = _WETH;
        factory = _factory;
    }

    function getPrice(address token) view external returns (uint256){
        if(token == WETH) return one;
        address pair = factory.getPair(token, WETH);
        (uint256 reserve0, uint256 reserve1,) = IPair(pair).getReserves();
        (uint256 tokenReserve, uint256 WETHReserve) = token == IPair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        return one.mul(WETHReserve).div(tokenReserve);
    }
}

// File: contracts/SVaultNetValue.sol

pragma solidity ^0.6.12;







contract SVaultNetValue {
    using SafeMath for uint256;
    
   address public controller;
   PriceView public priceView;

   struct PoolWeight{
        address pool;
        address token;
        uint256 amount;
        uint256 amountInUSD;
        uint256 weight;
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

    struct TokenAmountView{
        TokenAmount[] tokenAmounts;
        uint256 totalAmountInUSD;
    }

    struct TokenAmount{
        address token;
        uint256 price;
        uint256 amount;
        uint256 amountInUSD;
    }

    constructor (address _controller, PriceView _priceView) public {
        controller = _controller;
        priceView = _priceView;
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
        // get all tokens in pool and strategy, 包括本金加收益
        TokenAmountView memory tokenAmountView = getTokenAmounts(fixedPools, flexiblePools);
        netValues = new NetValue[](fixedPools.length + flexiblePools.length);
        uint256 totalFixedPoolUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            netValues[i].pool = fixedPools[i];
            (netValues[i].token, netValues[i].amount, netValues[i].totalTokens) = IFundPool(fixedPools[i]).getTotalTokensByProfitRate();
            uint256 price = priceView.getPrice(netValues[i].token);
            netValues[i].amountInUSD = price.mul(netValues[i].amount);
            netValues[i].totalTokensInUSD = price.mul(netValues[i].totalTokens);
            totalFixedPoolUSD = totalFixedPoolUSD.add(netValues[i].totalTokensInUSD);
        }
        if(tokenAmountView.totalAmountInUSD < totalFixedPoolUSD) return netValues;
        tokenAmountView.totalAmountInUSD = tokenAmountView.totalAmountInUSD.sub(totalFixedPoolUSD);
        (PoolWeight[] memory poolWeights, uint256 totalWeight, uint256 totalAmountInUSD, uint256 totalAllocatedProfitInUSD) = getPoolWeights(flexiblePools);
        uint256 totalProfitAmountInUSD = 0;
        tokenAmountView.totalAmountInUSD = tokenAmountView.totalAmountInUSD.sub(totalAllocatedProfitInUSD);
        if(tokenAmountView.totalAmountInUSD < totalAmountInUSD){
            totalAmountInUSD = tokenAmountView.totalAmountInUSD;
        }else{
            totalProfitAmountInUSD = tokenAmountView.totalAmountInUSD.sub(totalAmountInUSD);
        }

        uint256 fixedPoolLength = fixedPools.length;
        for(uint256 i = 0; i < poolWeights.length; i++){
            NetValue memory netValue = netValues[fixedPoolLength+i];
            netValue.pool = poolWeights[i].pool;
            netValue.token = poolWeights[i].token;
            netValue.amountInUSD = totalWeight == 0 ? 0 : totalAmountInUSD.mul(poolWeights[i].weight).div(totalWeight);
            uint256 allocatedProfitInUSD = poolWeights[i].allocatedProfitInUSD;
            if(netValue.amountInUSD < poolWeights[i].amountInUSD){
                uint256 lossAmountInUSD = poolWeights[i].amountInUSD.sub(netValue.amountInUSD);
                lossAmountInUSD = lossAmountInUSD > allocatedProfitInUSD ? allocatedProfitInUSD : lossAmountInUSD;
                netValue.amountInUSD = netValue.amountInUSD.add(lossAmountInUSD);
                allocatedProfitInUSD = allocatedProfitInUSD.sub(lossAmountInUSD);
            }
            netValue.totalTokensInUSD = netValue.amountInUSD.add(totalWeight == 0 ? 0 : totalProfitAmountInUSD.mul(poolWeights[i].weight).div(totalWeight)).add(allocatedProfitInUSD);
            netValue.amount =netValue.amountInUSD.div(poolWeights[i].price);
            netValue.totalTokens = netValue.totalTokensInUSD.div(poolWeights[i].price);
        }
    }

    //get flexible pool weight
    function getPoolWeights(address[] memory flexiblePools) view internal returns (PoolWeight[] memory, uint256, uint256, uint256){
        PoolWeight[] memory poolWeights = new PoolWeight[](flexiblePools.length);
        uint256 totalWeight = 0;
        uint256 totalAmountInUSD = 0;
        uint256 totalAllocatedProfitInUSD = 0;
        for(uint256 i = 0; i < flexiblePools.length; i++){
            poolWeights[i].pool = flexiblePools[i];
            (poolWeights[i].token, poolWeights[i].amount) = IFundPool(flexiblePools[i]).getTotalTokenSupply();
            poolWeights[i].price = priceView.getPrice(poolWeights[i].token);
            poolWeights[i].amountInUSD = poolWeights[i].price.mul(poolWeights[i].amount);
            poolWeights[i].weight = poolWeights[i].amountInUSD;
            poolWeights[i].allocatedProfitInUSD = IController(controller).allocatedProfit(poolWeights[i].pool).mul(poolWeights[i].price);
            totalAmountInUSD = totalAmountInUSD.add(poolWeights[i].amountInUSD);
            totalWeight = totalWeight.add(poolWeights[i].weight);
            totalAllocatedProfitInUSD = totalAllocatedProfitInUSD.add(poolWeights[i].allocatedProfitInUSD);
        }
        return (poolWeights,totalWeight,totalAmountInUSD,totalAllocatedProfitInUSD);
    }

    function getTokenAmounts(address[] memory fixedPools, address[] memory flexiblePools) view internal returns(TokenAmountView memory){
        TokenAmountView memory tokenAmountView = TokenAmountView(new TokenAmount[](fixedPools.length + flexiblePools.length), 0);
        for(uint256 i = 0; i < fixedPools.length; i++){
            (address token, uint256 tokenBalance) = IFundPool(fixedPools[i]).getTokenBalance();
            AddTokenAmount(tokenAmountView, token, tokenBalance);
        }
        for(uint256 i = 0; i < flexiblePools.length; i++){
            (address token, uint256 tokenBalance) = IFundPool(flexiblePools[i]).getTokenBalance();
           AddTokenAmount(tokenAmountView, token, tokenBalance);
        }
        address[] memory strategies = IController(controller).getStrategies();
        for(uint256 i = 0; i < strategies.length; i++) {
            (address[] memory tokens, uint256[] memory amounts) = IStrategy(strategies[i]).getTokenAmounts();
            for(uint256 j = 0; j < tokens.length; j++){
                AddTokenAmount(tokenAmountView, tokens[j], amounts[j]);
            }
        }
        return tokenAmountView;
    }

    function getTokenAmount(TokenAmount[] memory tokenAmounts, address token) pure internal returns (TokenAmount memory){
        for(uint256 i = 0; i < tokenAmounts.length; i++){
            if(tokenAmounts[i].token == token) return tokenAmounts[i];
        }
    }

    function AddTokenAmount(TokenAmountView memory tokenAmountView, address token, uint256 amount) view internal{
        for(uint256 j = 0; j < tokenAmountView.tokenAmounts.length; j++){
            if(tokenAmountView.tokenAmounts[j].token == address(0)){
                tokenAmountView.tokenAmounts[j].token = token;
                tokenAmountView.tokenAmounts[j].price = priceView.getPrice(token);
                tokenAmountView.tokenAmounts[j].amount = amount;
                tokenAmountView.tokenAmounts[j].amountInUSD = tokenAmountView.tokenAmounts[j].price.mul(amount);
                tokenAmountView.totalAmountInUSD = tokenAmountView.totalAmountInUSD.add(tokenAmountView.tokenAmounts[j].amountInUSD);
                break;
            }
            if(token == tokenAmountView.tokenAmounts[j].token){
                tokenAmountView.tokenAmounts[j].amount = tokenAmountView.tokenAmounts[j].amount.add(amount);
                uint256 amountInUSD = tokenAmountView.tokenAmounts[j].price.mul(amount);
                tokenAmountView.tokenAmounts[j].amountInUSD = tokenAmountView.tokenAmounts[j].amountInUSD.add(amountInUSD);
                tokenAmountView.totalAmountInUSD = tokenAmountView.totalAmountInUSD.add(amountInUSD);
                break;
            }
        }
    }

    
}