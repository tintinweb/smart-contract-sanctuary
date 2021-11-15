/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IUniswapV2Factory } from "../interfaces/external/IUniswapV2Factory.sol";
import { IUniswapV2Router } from "../interfaces/external/IUniswapV2Router.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";

/**
 * @title AMMSplitter
 * @author Set Protocol
 *
 * Peripheral contract which splits trades efficiently between Uniswap V2 and Sushiswap. Works for both exact input 
 * and exact output trades. This contract adheres to the IUniswapV2Router interface, so it can work with existing contracts that
 * expect the Uniswap router. All math for calculating the optimal split is performed on-chain. This contract only supports
 * trade paths a max length of three because with two hops, we have a common unit (the middle token), to measure the pool sizes in.
 * Additionally, the math to calculate the optimal split for greater than two hops becomes increasingly complex.
 */
contract AMMSplitter {

    using SafeMath for uint256;
    using PreciseUnitMath for uint256;

    /* ============ Structs ============== */

    struct TradeInfo {
        uint256 uniSize;        // Uniswap trade size (can be either input or output depending on context)
        uint256 sushiSize;      // Sushiswap trade size (can be either input or output depending on context)
    }

    /* ============= Events ================= */

    event TradeExactInputExecuted(
        address indexed _sendToken,
        address indexed _receiveToken,
        address indexed _to,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _uniTradeSize,
        uint256 _sushiTradeSize
    );

    event TradeExactOutputExecuted(
        address indexed _sendToken,
        address indexed _receiveToken,
        address indexed _to,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _uniTradeSize,
        uint256 _sushiTradeSize
    );

    /* ============ State Variables ============ */

    // address of the Uniswap Router contract
    IUniswapV2Router public immutable uniRouter;
    // address of the Sushiswap Router contract
    IUniswapV2Router public immutable sushiRouter;
    // address of the Uniswap Factory contract
    IUniswapV2Factory public immutable uniFactory;
    // address of the Sushiswap Factory contract
    IUniswapV2Factory public immutable sushiFactory;

    /* =========== Constructor =========== */

    /**
     * Sets state variables
     *
     * @param _uniRouter        the Uniswap router contract
     * @param _sushiRouter      the Sushiswap router contract
     * @param _uniFactory       the Uniswap factory contract 
     * @param _sushiFactory     the Sushiswap factory contract
     */
    constructor(
        IUniswapV2Router _uniRouter,
        IUniswapV2Router _sushiRouter,
        IUniswapV2Factory _uniFactory,
        IUniswapV2Factory _sushiFactory
    )
        public
    {
        uniRouter = _uniRouter;
        sushiRouter = _sushiRouter;
        uniFactory = _uniFactory;
        sushiFactory = _sushiFactory;
    }

    /* ============ External Functions ============= */

    /**
     * Executes an exact input trade split between Uniswap and Sushiswap. This function is for when one wants to trade with the optimal split between Uniswap 
     * and Sushiswap. This function's interface matches the Uniswap V2 swapExactTokensForTokens function. Input/output tokens are inferred implicitly from
     * the trade path with first token as input and last as output.
     *
     * @param _amountIn     the exact input amount
     * @param _amountOutMin the minimum output amount that must be received
     * @param _path         the path to use for the trade (length must be 3 or less so we can measure the pool size in units of the middle token for 2 hops)
     * @param _to           the address to direct the outputs to
     * @param _deadline     the deadline for the trade
     * 
     * @return totalOutput  the actual output amount
     */
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        returns (uint256 totalOutput)
    {
        _checkPath(_path);

        IERC20 inputToken = IERC20(_path[0]);
        inputToken.transferFrom(msg.sender, address(this), _amountIn);
        
        TradeInfo memory tradeInfo = _getTradeSizes(_path, _amountIn);

        _checkApprovals(tradeInfo.uniSize, tradeInfo.sushiSize, inputToken);

        uint256 uniOutput = _executeTrade(uniRouter, tradeInfo.uniSize, _path, _to, _deadline, true);
        uint256 sushiOutput = _executeTrade(sushiRouter, tradeInfo.sushiSize, _path, _to, _deadline, true);

        totalOutput = uniOutput.add(sushiOutput);
        require(totalOutput >= _amountOutMin, "AMMSplitter: INSUFFICIENT_OUTPUT_AMOUNT");

        emit TradeExactInputExecuted(
            _path[0],
            _path[_path.length.sub(1)],
            _to,
            _amountIn,
            totalOutput,
            tradeInfo.uniSize,
            tradeInfo.sushiSize
        );
    }

    /**
     * Executes an exact output trade split between Uniswap and Sushiswap. This function is for when one wants to trade with the optimal split between Uniswap 
     * and Sushiswap. This function's interface matches the Uniswap V2 swapTokensForExactTokens function. Input/output tokens are inferred implicitly from
     * the trade path with first token as input and last as output.
     *
     * @param _amountOut    the exact output amount
     * @param _amountInMax  the maximum input amount that can be spent
     * @param _path         the path to use for the trade (length must be 3 or less so we can measure the pool size in units of the middle token for 2 hops)
     * @param _to           the address to direct the outputs to
     * @param _deadline     the deadline for the trade
     * 
     * @return totalInput   the actual input amount
     */
    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        returns (uint256 totalInput)
    {
        _checkPath(_path);

        TradeInfo memory tradeInfo = _getTradeSizes(_path, _amountOut);

        uint256 expectedUniInput = _getTradeInputOrOutput(uniRouter, tradeInfo.uniSize, _path, false)[0];
        uint256 expectedSushiInput = _getTradeInputOrOutput(sushiRouter, tradeInfo.sushiSize, _path, false)[0];

        totalInput = expectedUniInput.add(expectedSushiInput);
        // expected inputs are guaranteed to equal the actual inputs so we can revert early and save gas
        require(totalInput <= _amountInMax, "AMMSplitter: INSUFFICIENT_INPUT_AMOUNT");

        IERC20 inputToken = IERC20(_path[0]);
        inputToken.transferFrom(msg.sender, address(this), totalInput);

        _checkApprovals(expectedUniInput, expectedSushiInput, inputToken);

        // total trade inputs here are guaranteed to equal totalInput calculated above so no check needed
        _executeTrade(uniRouter, tradeInfo.uniSize, _path, _to, _deadline, false);
        _executeTrade(sushiRouter, tradeInfo.sushiSize, _path, _to, _deadline, false);

        emit TradeExactOutputExecuted(
            _path[0],
            _path[_path.length.sub(1)],
            _to,
            totalInput,
            _amountOut,
            tradeInfo.uniSize,
            tradeInfo.sushiSize
        );
    }

    /* =========== External Getter Functions =========== */

    /**
     * Returns a quote with an estimated trade output amount
     *
     * @param _amountIn     input amount
     * @param _path         the trade path to use
     *
     * @return uint256[]    array of input amounts, intermediary amounts, and output amounts
     */
    function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint256[] memory) {
        return _getAmounts(_amountIn, _path, true);
    }

    /**
     * Returns a quote with an estimated trade input amount
     *
     * @param _amountOut    output amount
     * @param _path         the trade path to use
     *
     * @return uint256[]    array of input amounts, intermediary amounts, and output amounts
     */
    function getAmountsIn(uint256 _amountOut, address[] calldata _path) external view returns (uint256[] memory) {
        return _getAmounts(_amountOut, _path, false);
    }

    /* ============= Internal Functions ============ */

    /**
     * Helper function for getting trade quotes
     *
     * @param _size             input or output amount depending on _isExactInput
     * @param _path             trade path to use
     * @param _isExactInput     whether an exact input or an exact output trade quote is needed
     *
     * @return amounts          array of input amounts, intermediary amounts, and output amounts
     */
    function _getAmounts(uint256 _size, address[] calldata _path, bool _isExactInput) internal view returns (uint256[] memory amounts) {

        _checkPath(_path);

        TradeInfo memory tradeInfo = _getTradeSizes(_path, _size);

        uint256[] memory uniTradeResults = _getTradeInputOrOutput(uniRouter, tradeInfo.uniSize, _path, _isExactInput);
        uint256[] memory sushiTradeResults = _getTradeInputOrOutput(sushiRouter, tradeInfo.sushiSize, _path, _isExactInput);

        amounts = new uint256[](_path.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = uniTradeResults[i].add(sushiTradeResults[i]);
        }
    }

    /**
     * Calculates the optimal trade sizes for Uniswap and Sushiswap. Pool values must be measured in the same token. For single hop trades
     * this is the balance of the output token. For two hop trades, it is measured as the balance of the intermediary token. The equation to
     * calculate the ratio for two hop trades is documented under _calculateTwoHopRatio. For single hop trades, this equation is:
     *
     * Tu/Ts = Pu / Ps
     *
     * Tu = Uniswap trade size
     * Ts = Sushiswap trade size
     * Pu = Uniswap pool size
     * Ps = Sushiswap pool size
     *
     * @param _path         the trade path that will be used
     * @param _size         the total size of the trade
     *
     * @return tradeInfo    TradeInfo struct containing Uniswap and Sushiswap trade sizes
     */
    function _getTradeSizes(address[] calldata _path, uint256 _size) internal view returns (TradeInfo memory tradeInfo) {

        uint256 uniPercentage;
        if (_path.length == 2) {

            uint256 uniLiqPool = _getTokenBalanceInPair(uniFactory, _path[0], _path[1]);
            uint256 sushiLiqPool = _getTokenBalanceInPair(sushiFactory, _path[0], _path[1]);

            uniPercentage = uniLiqPool.preciseDiv(uniLiqPool.add(sushiLiqPool));
        } else {

            // always get the amount of the intermediate asset, so we have value measured in the same units for both pool A and B
            uint256 uniLiqPoolA = _getTokenBalanceInPair(uniFactory, _path[0], _path[1]);
            uint256 uniLiqPoolB = _getTokenBalanceInPair(uniFactory, _path[2], _path[1]);

            // returning early here saves gas and prevents division by zero errors later on
            if(uniLiqPoolA == 0 || uniLiqPoolB == 0) return TradeInfo(0, _size);

            // always get the amount of the intermediate asset, so we have value measured in the same units for both pool A and B
            uint256 sushiLiqPoolA = _getTokenBalanceInPair(sushiFactory, _path[0], _path[1]);
            uint256 sushiLiqPoolB = _getTokenBalanceInPair(sushiFactory, _path[2], _path[1]);

            // returning early here saves gas and prevents division by zero errors later on
            if(sushiLiqPoolA == 0 || sushiLiqPoolB == 0) return TradeInfo(_size, 0);

            uint256 ratio = _calculateTwoHopRatio(uniLiqPoolA, uniLiqPoolB, sushiLiqPoolA, sushiLiqPoolB);
            // to go from a ratio to percentage we must calculate: ratio / (ratio + 1). This percentage is measured in precise units
            uniPercentage = ratio.preciseDiv(ratio.add(PreciseUnitMath.PRECISE_UNIT));
        }

        tradeInfo.uniSize = _size.preciseMul(uniPercentage);
        tradeInfo.sushiSize = _size.sub(tradeInfo.uniSize);
    }

    /**
     * Calculates the optimal ratio of Uniswap trade size to Sushiswap trade size. To calculate the ratio between Uniswap
     * and Sushiswap use: 
     *
     * Tu/Ts = ((Psa + Psb) * Pua * Pub) / ((Pua + Pub) * Psa * Psb)
     *
     * Ts  = Sushiswap trade size
     * Tu  = Uniswap trade size
     * Pua = Uniswap liquidity for pool A
     * Pub = Uniswap liquidity for pool B
     * Psa = Sushiswap liquidity for pool A
     * Psb = Sushiswap liquidity for pool B
     *
     * This equation is derived using several assumptions. First, it assumes that the price impact is equal to 2T / P where T is
     * equal to the trade size, and P is equal to the pool size. This approximation holds given that the price impact is a small percentage.
     * The second approximation made is that when executing trades that utilize multiple hops, total price impact is the sum of the each
     * hop's price impact (not accounting for the price impact of the prior trade). This approximation again holds true under the assumption
     * that the total price impact is a small percentage. The full derivation of this equation can be viewed in STIP-002.
     *
     * @param _uniLiqPoolA        Size of the first Uniswap pool
     * @param _uniLiqPoolB        Size of the second Uniswap pool
     * @param _sushiLiqPoolA      Size of the first Sushiswap pool
     * @param _sushiLiqPoolB      Size of the second Sushiswap pool
     *
     * @return uint256          the ratio of Uniswap trade size to Sushiswap trade size
     */
    function _calculateTwoHopRatio(
        uint256 _uniLiqPoolA,
        uint256 _uniLiqPoolB,
        uint256 _sushiLiqPoolA,
        uint256 _sushiLiqPoolB
    ) 
        internal
        pure
        returns (uint256)
    {
        uint256 a = _sushiLiqPoolA.add(_sushiLiqPoolB).preciseDiv(_uniLiqPoolA.add(_uniLiqPoolB));
        uint256 b = _uniLiqPoolA.preciseDiv(_sushiLiqPoolA);
        uint256 c = _uniLiqPoolB.preciseDiv(_sushiLiqPoolB);

        return a.preciseMul(b).preciseMul(c);
    }

    /**
     * Checks the token approvals to the Uniswap and Sushiswap routers are sufficient. If not
     * it bumps the allowance to MAX_UINT_256.
     *
     * @param _uniAmount    Uniswap input amount
     * @param _sushiAmount  Sushiswap input amount
     * @param _token        Token being traded
     */
    function _checkApprovals(uint256 _uniAmount, uint256 _sushiAmount, IERC20 _token) internal {
        if (_token.allowance(address(this), address(uniRouter)) < _uniAmount) {
            _token.approve(address(uniRouter), PreciseUnitMath.MAX_UINT_256);
        }
        if (_token.allowance(address(this), address(sushiRouter)) < _sushiAmount) {
            _token.approve(address(sushiRouter), PreciseUnitMath.MAX_UINT_256);
        }
    }

    /**
     * Confirms that the path length is either two or three. Reverts if it does not fall within these bounds. When paths are greater than three in 
     * length, the calculation for the optimal split between Uniswap and Sushiswap becomes much more difficult, so it is disallowed.
     *
     * @param _path     trade path to check
     */
    function _checkPath(address[] calldata _path) internal pure {
        require(_path.length == 2 || _path.length == 3, "AMMSplitter: incorrect path length");
    }

    /**
     * Gets the balance of a component token in a Uniswap / Sushiswap pool
     *
     * @param _factory          factory contract to use (either uniFactory or sushiFactory)
     * @param _pairedToken      first token in pair
     * @param _balanceToken     second token in pair, and token to get balance of
     *
     * @return uint256          balance of second token in pair
     */
    function _getTokenBalanceInPair(IUniswapV2Factory _factory, address _pairedToken, address _balanceToken) internal view returns (uint256) {
        address uniPair = _factory.getPair(_pairedToken, _balanceToken);
        return IERC20(_balanceToken).balanceOf(uniPair);
    }

    /**
     * Executes a trade on Uniswap or Sushiswap. If passed a trade size of 0, skip the
     * trade.
     *
     * @param _router           The router to execute the trade through (either Uniswap or Sushiswap)
     * @param _size             Input amount if _isExactInput is true, output amount if false
     * @param _path             Path for the trade
     * @param _to               Address to redirect trade output to
     * @param _deadline         Timestamp that trade must execute before
     * @param _isExactInput     Whether to perform an exact input or exact output swap
     *
     * @return uint256          the actual input / output amount of the trade
     */
    function _executeTrade(
        IUniswapV2Router _router,
        uint256 _size,
        address[] calldata _path,
        address _to,
        uint256 _deadline,
        bool _isExactInput
    ) 
        internal
        returns (uint256)
    {
        if (_size == 0) return 0;
        
        // maxInput or minOutput not checked here. The sum all inputs/outputs is instead checked after all trades execute
        if (_isExactInput) {
            return _router.swapExactTokensForTokens(_size, 0, _path, _to, _deadline)[_path.length.sub(1)];
        } else {
            return _router.swapTokensForExactTokens(_size, uint256(-1), _path, _to, _deadline)[0];
        }
    }

    /**
     * Gets a trade quote on Uniswap or Sushiswap
     *
     * @param _router           The router to get the quote from (either Uniswap or Sushiswap)
     * @param _size             Input amount if _isExactInput is true, output amount if false
     * @param _path             Path for the trade
     * @param _isExactInput     Whether to get a getAmountsIn or getAmountsOut quote
     *
     * @return uint256[]        Array of input amounts, intermediary amounts, and output amounts
     */
    function _getTradeInputOrOutput(
        IUniswapV2Router _router,
        uint256 _size,
        address[] calldata _path,
        bool _isExactInput
    )
        internal
        view
        returns (uint256[] memory)
    {
        // if trade size is zero return an array of all zeros to prevent a revert
        if (_size == 0) return new uint256[](_path.length);

        if(_isExactInput) {
            return _router.getAmountsOut(_size, _path);
        } else {
            return _router.getAmountsIn(_size, _path);
        }
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

pragma solidity 0.6.10;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

interface IUniswapV2Router {
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

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

