pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../external/UniswapV2Library.sol";
import "./IFeiRouter.sol";

/// @title A Uniswap Router for FEI/ETH swaps
/// @author Fei Protocol
contract FeiRouter is IFeiRouter {
    using SafeMathCopy for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IWETH public immutable WETH;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Pair public immutable PAIR;

    constructor(
        address pair,
        address weth
    ) public {
        PAIR = IUniswapV2Pair(pair);
        WETH = IWETH(weth);
    }

    modifier ensure(uint256 deadline) {
        // solhint-disable-next-line not-rely-on-time
        require(deadline >= block.timestamp, "FeiRouter: Expired");
        _;
    }

    receive() external payable {
        assert(msg.sender == address(WETH)); // only accept ETH via fallback from the WETH contract
    }

    /// @notice buy FEI for ETH with some protections
    /// @param minReward minimum mint reward for purchasing
    /// @param amountOutMin minimum FEI received
    /// @param to address to send FEI
    /// @param deadline block timestamp after which trade is invalid
    function buyFei(
        uint256 minReward,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external payable override ensure(deadline) returns (uint256 amountOut) {

        (uint256 reservesETH, uint256 reservesOther, bool isWETHPairToken0) = _getReserves();

        uint256 amountIn = msg.value;
        amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            reservesETH,
            reservesOther
        );
        
        require(
            amountOut >= amountOutMin,
            "FeiRouter: Insufficient output amount"
        );
        // Convert sent ETH to wrapped ETH and assert successful transfer to pair
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(address(PAIR), amountIn));

        address fei = isWETHPairToken0 ? PAIR.token1() : PAIR.token0();

        // Check fei balance of recipient before to compare against
        uint256 feiBalanceBefore = IERC20(fei).balanceOf(to);

        (uint256 amount0Out, uint256 amount1Out) =
            isWETHPairToken0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        PAIR.swap(amount0Out, amount1Out, to, new bytes(0));

        // Check that FEI recipient got at least minReward on top of trade amount
        uint256 feiBalanceAfter = IERC20(fei).balanceOf(to);
        uint256 reward = feiBalanceAfter.sub(feiBalanceBefore).sub(amountOut);
        require(reward >= minReward, "FeiRouter: Not enough reward");

        return amountOut;
    }

    /// @notice sell FEI for ETH with some protections
    /// @param maxPenalty maximum fei burn for purchasing
    /// @param amountIn amount of FEI to sell
    /// @param amountOutMin minimum ETH received
    /// @param to address to send ETH
    /// @param deadline block timestamp after which trade is invalid
    function sellFei(
        uint256 maxPenalty,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 amountOut) {
        (uint256 reservesETH, uint256 reservesOther, bool isWETHPairToken0) =
            _getReserves();

        address fei = isWETHPairToken0 ? PAIR.token1() : PAIR.token0();

        IERC20(fei).transferFrom(msg.sender, address(PAIR), amountIn);

        // Figure out how much the PAIR actually received net of FEI burn
        uint256 effectiveAmountIn = IERC20(fei).balanceOf(address(PAIR)).sub(reservesOther);

        // Check that burned fee-on-transfer is not more than the maxPenalty
        if (effectiveAmountIn < amountIn) {
            uint256 penalty = amountIn - effectiveAmountIn;
            require(penalty <= maxPenalty, "FeiRouter: Penalty too high");
        }

        amountOut = UniswapV2Library.getAmountOut(
            effectiveAmountIn,
            reservesOther,
            reservesETH
        );
        require(
            amountOut >= amountOutMin,
            "FeiRouter: Insufficient output amount"
        );

        (uint256 amount0Out, uint256 amount1Out) =
            isWETHPairToken0 ? (amountOut, uint256(0)) : (uint256(0), amountOut);

        PAIR.swap(amount0Out, amount1Out, address(this), new bytes(0));

        IWETH(WETH).withdraw(amountOut);

        TransferHelper.safeTransferETH(to, amountOut);
        return amountOut;
    }

    function _getReserves()
        internal
        view
        returns (
            uint256 reservesETH,
            uint256 reservesOther,
            bool isWETHPairToken0
        )
    {
        (uint256 reserves0, uint256 reserves1, ) = PAIR.getReserves();
        isWETHPairToken0 = PAIR.token0() == address(WETH);
        return
            isWETHPairToken0
                ? (reserves0, reserves1, isWETHPairToken0)
                : (reserves1, reserves0, isWETHPairToken0);
    }
}

pragma solidity >=0.6.0;

 import "./SafeMathCopy.sol";

 library UniswapV2Library {
    using SafeMathCopy for uint;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
 }

pragma solidity ^0.6.0;

import "../token/IUniswapIncentive.sol";

/// @title FeiRouter interface
/// @author Fei Protocol
interface IFeiRouter {
    // ----------- state changing api -----------

    function buyFei(
        uint256 minReward,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function sellFei(
        uint256 maxPenalty,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./IIncentive.sol";
import "../external/Decimal.sol";

/// @title UniswapIncentive interface
/// @author Fei Protocol
interface IUniswapIncentive is IIncentive {
    // ----------- Events -----------

    event TimeWeightUpdate(uint256 _weight, bool _active);

    event GrowthRateUpdate(uint256 _growthRate);

    event ExemptAddressUpdate(address indexed _account, bool _isExempt);

    // ----------- Governor only state changing api -----------

    function setExemptAddress(address account, bool isExempt) external;

    function setTimeWeightGrowth(uint32 growthRate) external;

    function setTimeWeight(
        uint32 weight,
        uint32 growth,
        bool active
    ) external;

    // ----------- Getters -----------

    function isIncentiveParity() external view returns (bool);

    function isExemptAddress(address account) external view returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function TIME_WEIGHT_GRANULARITY() external view returns (uint32);

    function getGrowthRate() external view returns (uint32);

    function getTimeWeight() external view returns (uint32);

    function isTimeWeightActive() external view returns (bool);

    function getBuyIncentive(uint256 amount)
        external
        view
        returns (
            uint256 incentive,
            uint32 weight,
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation
        );

    function getSellPenalty(uint256 amount)
        external
        view
        returns (
            uint256 penalty,
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation
        );

    function getSellPenaltyMultiplier(
        Decimal.D256 calldata initialDeviation,
        Decimal.D256 calldata finalDeviation
    ) external view returns (Decimal.D256 memory);

    function getBuyIncentiveMultiplier(
        Decimal.D256 calldata initialDeviation,
        Decimal.D256 calldata finalDeviation
    ) external view returns (Decimal.D256 memory);
}

pragma solidity ^0.6.2;

/// @title incentive contract interface
/// @author Fei Protocol
/// @notice Called by FEI token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentive {
    // ----------- Fei only state changing api -----------

    /// @notice apply incentives on transfer
    /// @param sender the sender address of the FEI
    /// @param receiver the receiver address of the FEI
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of FEI transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}

/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020 Empty Set Squad <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMathCopy.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMathCopy for uint256;

    // ============ Constants ============

    uint256 private constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
library SafeMathCopy { // To avoid namespace collision between openzeppelin safemath and uniswap safemath
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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

