pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IAggregator.sol";

contract PriceView {
    using SafeMath for uint256;
    IAggregator arrgregator;

    mapping(address => uint8) public tokenIndexes;

    constructor(IAggregator _aggregator) public {
        arrgregator = _aggregator;
    }

    function setTokenIndex(address token, uint8 index) external{
        tokenIndexes[token] = index;
    }

    function getPrice(address token) view public returns (uint256){
        string memory answer = arrgregator.getLatestStringAnswerByIndex(tokenIndexes[token]);
        return safeParseInt(answer);
    }

    function safeParseInt(string memory _a) internal pure returns (uint256 _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint256 mint = 0;
        for (uint256 i = 0; i < bresult.length; i++) {
            if ((uint256(uint8(bresult[i])) >= 48) && (uint256(uint8(bresult[i])) <= 57)) {
                mint = mint.mul(10);
                mint = mint.add(uint256(uint8(bresult[i])).sub(48));
            } else if (uint256(uint8(bresult[i])) == 46) {
                break;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        return mint;
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
            totalFixedPoolUSD = totalFixedPoolUSD.add(netValues[i].amountInUSD).add(netValues[i].totalTokensInUSD.sub(netValues[i].amountInUSD));
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

        for(uint256 i = 0; i < poolWeights.length; i++){
            netValues[fixedPools.length+i].pool = poolWeights[i].pool;
            netValues[fixedPools.length+i].token = poolWeights[i].token;
            netValues[fixedPools.length+i].amountInUSD = totalWeight == 0 ? 0 : totalAmountInUSD.mul(poolWeights[i].weight).div(totalWeight);
            netValues[fixedPools.length+i].totalTokensInUSD = netValues[fixedPools.length+i].amountInUSD.add(totalWeight == 0 ? 0 : totalProfitAmountInUSD.mul(poolWeights[i].weight).div(totalWeight)).add(poolWeights[i].allocatedProfitInUSD);
            netValues[fixedPools.length+i].amount = netValues[fixedPools.length+i].amountInUSD.div(poolWeights[i].price);
            netValues[fixedPools.length+i].totalTokens = netValues[fixedPools.length+i].totalTokensInUSD.div(poolWeights[i].price);
        }
    }

    //TODO 单独写一个合约计算权重
    //获取高风险资金池占比
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

    function getTokenAmount(TokenAmount[] memory tokenAmounts, address token) view internal returns (TokenAmount memory){
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

pragma solidity ^0.6.12;

interface IAggregator {
    function getLatestStringAnswerByIndex(uint8 _index) external view returns (string memory);
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
}

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
    function earn(address[] memory tokens, uint256[] memory amounts) external virtual;
    function withdraw(address token) external virtual returns (uint256);
    function withdraw(uint256 amount) external virtual returns (address[] memory tokens, uint256[] memory amounts);
    function withdraw(address[] memory tokens, uint256 amount, uint256 _profitAmount) external virtual returns (uint256, uint256, address[] memory, uint256[] memory);
    function getTokenAmounts() external view virtual returns (address[] memory tokens, uint256[] memory amounts);
    function getTokens() external view virtual returns (address[] memory tokens);
    function getProfitTokens() external view virtual returns (address[] memory tokens);
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