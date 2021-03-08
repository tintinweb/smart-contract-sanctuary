// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20,
    SafeERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "../../vendor/openzeppelin/contracts/math/SafeMath.sol";
import "../../dapps/krystal/burnHelper/IBurnGasHelper.sol";
import "../../interfaces/krystal/IKyberProxy.sol";
import "../../interfaces/dapps/Uniswap/IUniswapV2Router02.sol";
import "../../interfaces/krystal/IGasToken.sol";

abstract contract Utils {
    uint256 internal constant _MAX_AMOUNT = 2**256 - 1;
    uint256 internal constant _MAX_DECIMALS = 18;
    uint256 internal constant _MAX_QTY = (10**28);
    uint256 internal constant _PRECISION = (10**18);
    uint256 internal constant _MAX_RATE = (_PRECISION * 10**7);

    IERC20 internal constant _ETH_TOKEN_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function _calcDestAmount(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return
            _calcDstQty(srcAmount, _getDecimals(src), _getDecimals(dest), rate);
    }

    function _calcDstQty(
        uint256 srcQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(srcQty <= _MAX_QTY, "srcQty > _MAX_QTY");
        require(rate <= _MAX_RATE, "rate > _MAX_RATE");

        if (dstDecimals >= srcDecimals) {
            require(
                (dstDecimals - srcDecimals) <= _MAX_DECIMALS,
                "dst - src > _MAX_DECIMALS"
            );
            return
                (srcQty * rate * (10**(dstDecimals - srcDecimals))) /
                _PRECISION;
        } else {
            require(
                (srcDecimals - dstDecimals) <= _MAX_DECIMALS,
                "src - dst > _MAX_DECIMALS"
            );
            return
                (srcQty * rate) /
                (_PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function _calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= _MAX_QTY, "srcAmount > _MAX_QTY");
        require(destAmount <= _MAX_QTY, "destAmount > _MAX_QTY");

        if (dstDecimals >= srcDecimals) {
            require(
                (dstDecimals - srcDecimals) <= _MAX_DECIMALS,
                "dst - src > _MAX_DECIMALS"
            );
            return ((destAmount * _PRECISION) /
                ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require(
                (srcDecimals - dstDecimals) <= _MAX_DECIMALS,
                "src - dst > _MAX_DECIMALS"
            );
            return ((destAmount *
                _PRECISION *
                (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    function _getDecimals(IERC20 token)
        internal
        view
        returns (uint256 tokenDecimals)
    {
        // return token decimals if has constant value
        tokenDecimals = _getDecimalsConstant(token);
        if (tokenDecimals > 0) return tokenDecimals;

        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        return token.decimals();
    }

    function _getDecimalsConstant(IERC20 token)
        internal
        pure
        returns (uint256)
    {
        if (token == _ETH_TOKEN_ADDRESS) {
            return _MAX_DECIMALS;
        }

        return 0;
    }
}

contract UniAndKyberSwaps is Utils {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public uniRouters;
    IKyberProxy public immutable kyberProxy;
    IBurnGasHelper public immutable burnGasHelper;

    constructor(
        address _kyberProxy,
        address[] memory _uniRouters,
        address _burnGasHelper
    ) {
        kyberProxy = IKyberProxy(_kyberProxy);
        for (uint256 i = 0; i < _uniRouters.length; i++) {
            uniRouters[_uniRouters[i]] = true;
        }
        burnGasHelper = IBurnGasHelper(_burnGasHelper);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function swapKyber(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        address payable recipient,
        bytes calldata hint,
        bool useGasToken
    ) external payable returns (uint256 destAmount) {
        uint256 gasBefore = useGasToken ? gasleft() : 0;
        destAmount = _doKyberTrade(
            src,
            dest,
            srcAmount,
            minConversionRate,
            recipient,
            hint
        );
        uint256 numGasBurns = 0;
        // burn gas token if needed
        if (useGasToken) {
            numGasBurns = _burnGasTokensAfter(gasBefore);
        }
    }

    function swapUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        address payable recipient,
        bool useGasToken
    ) external payable returns (uint256 destAmount) {
        require(uniRouters[address(router)], "router not supported");
        uint256 numGasBurns;
        {
            // prevent stack too deep
            uint256 gasBefore = useGasToken ? gasleft() : 0;
            destAmount = _swapUniswapInternal(
                router,
                srcAmount,
                minDestAmount,
                tradePath,
                recipient
            );
            if (useGasToken) {
                numGasBurns = _burnGasTokensAfter(gasBefore);
            }
        }
    }

    /// @dev get expected return and conversion rate if using Kyber
    function getExpectedReturnKyber(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        bytes calldata hint
    ) external view returns (uint256 destAmount, uint256 expectedRate) {
        try
            kyberProxy.getExpectedRateAfterFee(src, dest, srcAmount, 0, hint)
        returns (uint256 rate) {
            expectedRate = rate;
        } catch {
            expectedRate = 0;
        }
        destAmount = _calcDestAmount(src, dest, srcAmount, expectedRate);
    }

    /// @dev get expected return and conversion rate if using a Uniswap router
    function getExpectedReturnUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        address[] calldata tradePath
    ) external view returns (uint256 destAmount, uint256 expectedRate) {
        // in case router is not supported
        if (!uniRouters[address(router)]) {
            return (0, 0);
        }
        try router.getAmountsOut(srcAmount, tradePath) returns (
            uint256[] memory amounts
        ) {
            destAmount = amounts[tradePath.length - 1];
        } catch {
            destAmount = 0;
        }
        expectedRate = _calcRateFromQty(
            srcAmount,
            destAmount,
            _getDecimals(IERC20(tradePath[0])),
            _getDecimals(IERC20(tradePath[tradePath.length - 1]))
        );
    }

    function _doKyberTrade(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        address payable recipient,
        bytes memory hint
    ) internal returns (uint256 destAmount) {
        _validateAndPrepareSourceAmount(address(kyberProxy), src, srcAmount);
        uint256 callValue = src == _ETH_TOKEN_ADDRESS ? srcAmount : 0;
        destAmount = kyberProxy.tradeWithHintAndFee{value: callValue}(
            src,
            srcAmount,
            dest,
            recipient,
            _MAX_AMOUNT,
            minConversionRate,
            payable(0),
            0,
            hint
        );
    }

    function _swapUniswapInternal(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] memory tradePath,
        address payable recipient
    ) internal returns (uint256 destAmount) {
        IERC20 src = IERC20(tradePath[0]);
        destAmount = _doUniswapTrade(
            router,
            src,
            srcAmount,
            minDestAmount,
            tradePath,
            recipient
        );
    }

    // solhint-disable-next-line function-max-lines
    function _doUniswapTrade(
        IUniswapV2Router02 router,
        IERC20 src,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] memory tradePath,
        address payable recipient
    ) internal returns (uint256 destAmount) {
        _validateAndPrepareSourceAmount(address(router), src, srcAmount);
        uint256 tradeLen = tradePath.length;
        IERC20 actualDest = IERC20(tradePath[tradeLen - 1]);
        {
            // convert eth -> weth address to trade on Uniswap
            if (tradePath[0] == address(_ETH_TOKEN_ADDRESS)) {
                tradePath[0] = router.WETH();
            }
            if (tradePath[tradeLen - 1] == address(_ETH_TOKEN_ADDRESS)) {
                tradePath[tradeLen - 1] = router.WETH();
            }
        }

        uint256[] memory amounts;
        if (src == _ETH_TOKEN_ADDRESS) {
            // swap eth -> token
            amounts = router.swapExactETHForTokens{value: srcAmount}(
                minDestAmount,
                tradePath,
                recipient,
                _MAX_AMOUNT
            );
        } else {
            if (actualDest == _ETH_TOKEN_ADDRESS) {
                // swap token -> eth
                amounts = router.swapExactTokensForETH(
                    srcAmount,
                    minDestAmount,
                    tradePath,
                    recipient,
                    _MAX_AMOUNT
                );
            } else {
                // swap token -> token
                amounts = router.swapExactTokensForTokens(
                    srcAmount,
                    minDestAmount,
                    tradePath,
                    recipient,
                    _MAX_AMOUNT
                );
            }
        }

        destAmount = amounts[amounts.length - 1];
    }

    function _validateAndPrepareSourceAmount(
        address protocol,
        IERC20 src,
        uint256 srcAmount
    ) internal {
        require(srcAmount > 0, "invalid src amount");
        if (src == _ETH_TOKEN_ADDRESS) {
            require(msg.value == srcAmount, "wrong msg value");
        } else {
            require(msg.value == 0, "wrong msg value");
            src.safeTransferFrom(msg.sender, address(this), srcAmount);
            src.safeApprove(protocol, srcAmount);
        }
    }

    function _burnGasTokensAfter(uint256 gasBefore)
        internal
        virtual
        returns (uint256 numGasBurns)
    {
        if (burnGasHelper == IBurnGasHelper(address(0))) return 0;
        IGasToken gasToken;
        uint256 gasAfter = gasleft();

        try
            burnGasHelper.getAmountGasTokensToBurn(
                gasBefore.sub(gasAfter),
                msg.data // forward all data
            )
        returns (uint256 _gasBurns, address _gasToken) {
            numGasBurns = _gasBurns;
            gasToken = IGasToken(_gasToken);
        } catch {
            numGasBurns = 0;
        }

        if (numGasBurns > 0 && gasToken != IGasToken(address(0))) {
            numGasBurns = gasToken.freeFromUpTo(msg.sender, numGasBurns);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IBurnGasHelper {
    function getAmountGasTokensToBurn(
        uint256 gasConsumption,
        bytes calldata data
    ) external view returns (uint256 numGas, address gasToken);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IGasToken {
    function mint(uint256 value) external;

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value)
        external
        returns (uint256 freed);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address who) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKyberProxy {
    function tradeWithHintAndFee(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8 digits);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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