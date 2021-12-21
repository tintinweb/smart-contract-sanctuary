/**
 *Submitted for verification at snowtrace.io on 2021-12-21
*/

// File: contracts/intf/IERC20.sol

// This is a file copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.6.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/SmartRoute/intf/IDODOV1.sol


interface IDODOV1 {
    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external;

    function transferOwnership(address newOwner) external;

    function claimOwnership() external;

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function querySellBaseToken(uint256 amount) external view returns (uint256 receiveQuote);

    function queryBuyBaseToken(uint256 amount) external view returns (uint256 payQuote);

    function depositBaseTo(address to, uint256 amount) external returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function depositQuoteTo(address to, uint256 amount) external returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external returns (address);

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _R_STATUS_() external view returns (uint8);

    function _QUOTE_BALANCE_() external view returns (uint256);

    function _BASE_BALANCE_() external view returns (uint256);

    function _K_() external view returns (uint256);

    function _MT_FEE_RATE_() external view returns (uint256);

    function _LP_FEE_RATE_() external view returns (uint256);

    function getExpectedTarget() external view returns (uint256 baseTarget, uint256 quoteTarget);

    function getOraclePrice() external view returns (uint256);

    function getMidPrice() external view returns (uint256 midPrice); 
}

// File: contracts/lib/SafeMath.sol


/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/SafeERC20.sol


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/lib/DecimalMath.sol


/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }
}

// File: contracts/SmartRoute/helper/DODOSellHelper.sol

// import {DODOMath} from "../lib/DODOMath.sol";

interface IDODOSellHelper {
    function querySellQuoteToken(address dodo, uint256 amount) external view returns (uint256);
    
    function querySellBaseToken(address dodo, uint256 amount) external view returns (uint256);
}

library DODOMath {
    using SafeMath for uint256;

    /*
        Integrate dodo curve fron V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))
    */
    function _GeneralIntegrate(
        uint256 V0,
        uint256 V1,
        uint256 V2,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        uint256 fairAmount = DecimalMath.mulFloor(i, V1.sub(V2)); // i*delta
        uint256 V0V0V1V2 = DecimalMath.divCeil(V0.mul(V0).div(V1), V2);
        uint256 penalty = DecimalMath.mulFloor(k, V0V0V1V2); // k(V0^2/V1/V2)
        return DecimalMath.mulFloor(fairAmount, DecimalMath.ONE.sub(k).add(penalty));
    }

    /*
        The same with integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan
        if deltaBSig=true, then Q2>Q1
        if deltaBSig=false, then Q2<Q1
    */
    function _SolveQuadraticFunctionForTrade(
        uint256 Q0,
        uint256 Q1,
        uint256 ideltaB,
        bool deltaBSig,
        uint256 k
    ) internal pure returns (uint256) {
        // calculate -b value and sig
        // -b = (1-k)Q1-kQ0^2/Q1+i*deltaB
        uint256 kQ02Q1 = DecimalMath.mulFloor(k, Q0).mul(Q0).div(Q1); // kQ0^2/Q1
        uint256 b = DecimalMath.mulFloor(DecimalMath.ONE.sub(k), Q1); // (1-k)Q1
        bool minusbSig = true;
        if (deltaBSig) {
            b = b.add(ideltaB); // (1-k)Q1+i*deltaB
        } else {
            kQ02Q1 = kQ02Q1.add(ideltaB); // i*deltaB+kQ0^2/Q1
        }
        if (b >= kQ02Q1) {
            b = b.sub(kQ02Q1);
            minusbSig = true;
        } else {
            b = kQ02Q1.sub(b);
            minusbSig = false;
        }

        // calculate sqrt
        uint256 squareRoot = DecimalMath.mulFloor(
            DecimalMath.ONE.sub(k).mul(4),
            DecimalMath.mulFloor(k, Q0).mul(Q0)
        ); // 4(1-k)kQ0^2
        squareRoot = b.mul(b).add(squareRoot).sqrt(); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = DecimalMath.ONE.sub(k).mul(2); // 2(1-k)
        uint256 numerator;
        if (minusbSig) {
            numerator = b.add(squareRoot);
        } else {
            numerator = squareRoot.sub(b);
        }

        if (deltaBSig) {
            return DecimalMath.divFloor(numerator, denominator);
        } else {
            return DecimalMath.divCeil(numerator, denominator);
        }
    }

    /*
        Start from the integration function
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Assume Q2=Q0, Given Q1 and deltaB, solve Q0
        let fairAmount = i*deltaB
    */
    function _SolveQuadraticFunctionForTarget(
        uint256 V1,
        uint256 k,
        uint256 fairAmount
    ) internal pure returns (uint256 V0) {
        // V0 = V1+V1*(sqrt-1)/2k
        uint256 sqrt = DecimalMath.divCeil(DecimalMath.mulFloor(k, fairAmount).mul(4), V1);
        sqrt = sqrt.add(DecimalMath.ONE).mul(DecimalMath.ONE).sqrt();
        uint256 premium = DecimalMath.divCeil(sqrt.sub(DecimalMath.ONE), k.mul(2));
        // V0 is greater than or equal to V1 according to the solution
        return DecimalMath.mulFloor(V1, DecimalMath.ONE.add(premium));
    }
}

contract DODOSellHelper {
    using SafeMath for uint256;

    enum RStatus {ONE, ABOVE_ONE, BELOW_ONE}

    uint256 constant ONE = 10**18;

    struct DODOState {
        uint256 oraclePrice;
        uint256 K;
        uint256 B;
        uint256 Q;
        uint256 baseTarget;
        uint256 quoteTarget;
        RStatus rStatus;
    }

    function querySellBaseToken(address dodo, uint256 amount) public view returns (uint256) {
        return IDODOV1(dodo).querySellBaseToken(amount);
    }

    function querySellQuoteToken(address dodo, uint256 amount) public view returns (uint256) {
        DODOState memory state;
        (state.baseTarget, state.quoteTarget) = IDODOV1(dodo).getExpectedTarget();
        state.rStatus = RStatus(IDODOV1(dodo)._R_STATUS_());
        state.oraclePrice = IDODOV1(dodo).getOraclePrice();
        state.Q = IDODOV1(dodo)._QUOTE_BALANCE_();
        state.B = IDODOV1(dodo)._BASE_BALANCE_();
        state.K = IDODOV1(dodo)._K_();

        uint256 boughtAmount;
        // Determine the status (RStatus) and calculate the amount
        // based on the state
        if (state.rStatus == RStatus.ONE) {
            boughtAmount = _ROneSellQuoteToken(amount, state);
        } else if (state.rStatus == RStatus.ABOVE_ONE) {
            boughtAmount = _RAboveSellQuoteToken(amount, state);
        } else {
            uint256 backOneBase = state.B.sub(state.baseTarget);
            uint256 backOneQuote = state.quoteTarget.sub(state.Q);
            if (amount <= backOneQuote) {
                boughtAmount = _RBelowSellQuoteToken(amount, state);
            } else {
                boughtAmount = backOneBase.add(
                    _ROneSellQuoteToken(amount.sub(backOneQuote), state)
                );
            }
        }
        // Calculate fees
        return
            DecimalMath.divFloor(
                boughtAmount,
                DecimalMath.ONE.add(IDODOV1(dodo)._MT_FEE_RATE_()).add(
                    IDODOV1(dodo)._LP_FEE_RATE_()
                )
            );
    }

    function _ROneSellQuoteToken(uint256 amount, DODOState memory state)
        internal
        pure
        returns (uint256 receiveBaseToken)
    {
        uint256 i = DecimalMath.divFloor(ONE, state.oraclePrice);
        uint256 B2 = DODOMath._SolveQuadraticFunctionForTrade(
            state.baseTarget,
            state.baseTarget,
            DecimalMath.mulFloor(i, amount),
            false,
            state.K
        );
        return state.baseTarget.sub(B2);
    }

    function _RAboveSellQuoteToken(uint256 amount, DODOState memory state)
        internal
        pure
        returns (uint256 receieBaseToken)
    {
        uint256 i = DecimalMath.divFloor(ONE, state.oraclePrice);
        uint256 B2 = DODOMath._SolveQuadraticFunctionForTrade(
            state.baseTarget,
            state.B,
            DecimalMath.mulFloor(i, amount),
            false,
            state.K
        );
        return state.B.sub(B2);
    }

    function _RBelowSellQuoteToken(uint256 amount, DODOState memory state)
        internal
        pure
        returns (uint256 receiveBaseToken)
    {
        uint256 Q1 = state.Q.add(amount);
        uint256 i = DecimalMath.divFloor(ONE, state.oraclePrice);
        return DODOMath._GeneralIntegrate(state.quoteTarget, Q1, state.Q, i, state.K);
    }
}

// File: contracts/SmartRoute/lib/UniversalERC20.sol


library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address payable to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function universalApproveMax(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        uint256 allowance = token.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, uint256(-1));
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function tokenBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        return token.balanceOf(who);
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return token == ETH_ADDRESS;
    }
}

// File: contracts/SmartRoute/intf/IDODOAdapter.sol


interface IDODOAdapter {
    
    function sellBase(address to, address pool, bytes memory data) external;

    function sellQuote(address to, address pool, bytes memory data) external;
}

// File: contracts/SmartRoute/adapter/DODOV1Adapter.sol


contract DODOV1Adapter is IDODOAdapter {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    address public immutable _DODO_SELL_HELPER_;

    constructor(address dodoSellHelper) public {
        _DODO_SELL_HELPER_ = dodoSellHelper;
    }
    
    function sellBase(address to, address pool, bytes memory) external override {
        address curBase = IDODOV1(pool)._BASE_TOKEN_();
        uint256 curAmountIn = IERC20(curBase).tokenBalanceOf(address(this));
        IERC20(curBase).universalApproveMax(pool, curAmountIn);
        IDODOV1(pool).sellBaseToken(curAmountIn, 0, "");
        if(to != address(this)) {
            address curQuote = IDODOV1(pool)._QUOTE_TOKEN_();
            SafeERC20.safeTransfer(IERC20(curQuote), to, IERC20(curQuote).tokenBalanceOf(address(this)));
        }
    }

    function sellQuote(address to, address pool, bytes memory) external override {
        address curQuote = IDODOV1(pool)._QUOTE_TOKEN_();
        uint256 curAmountIn = IERC20(curQuote).tokenBalanceOf(address(this));
        IERC20(curQuote).universalApproveMax(pool, curAmountIn);
        uint256 canBuyBaseAmount = IDODOSellHelper(_DODO_SELL_HELPER_).querySellQuoteToken(
            pool,
            curAmountIn
        );
        IDODOV1(pool).buyBaseToken(canBuyBaseAmount, curAmountIn, "");
        if(to != address(this)) {
            address curBase = IDODOV1(pool)._BASE_TOKEN_();
            SafeERC20.safeTransfer(IERC20(curBase), to, canBuyBaseAmount);
        }
    }
}