// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import './SimplePositionBaseConnector.sol';
import '../interfaces/ISimplePositionLeveragedLendingConnector.sol';
import '../../core/interfaces/IExchangerAdapterProvider.sol';
import '../../modules/FlashLoaner/DyDx/DyDxFlashModule.sol';
import '../../modules/Exchanger/ExchangerDispatcher.sol';
import '../../modules/FundsManager/FundsManager.sol';

contract SimplePositionLeveragedLendingConnector is
    SimplePositionBaseConnector,
    ExchangerDispatcher,
    FundsManager,
    DyDxFlashModule,
    ISimplePositionLeveragedLendingConnector
{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor(
        address soloAddress,
        uint256 _principal,
        uint256 _profit,
        address _holder
    ) public DyDxFlashModule(soloAddress) FundsManager(_principal, _profit, _holder) {}

    function getExchanger(bytes1 flag) private view returns (address) {
        return IExchangerAdapterProvider(aStore().foldingRegistry).getExchangerAdapter(flag);
    }

    struct FoldingData {
        uint256 principalAmount;
        uint256 supplyAmount;
        uint256 borrowAmount;
        bool increasePosition;
        bytes exchangeDataBeforePosition;
        bytes exchangeDataAfterPosition;
    }

    function increaseSimplePositionWithFlashLoan(
        address flashLoanToken,
        uint256 flashLoanAmount,
        address platform,
        address supplyToken,
        uint256 principalAmount,
        uint256 supplyAmount,
        address borrowToken,
        uint256 borrowAmount,
        bytes memory exchangeDataBeforePosition,
        bytes memory exchangeDataAfterPosition
    ) external override onlyAccountOwnerOrRegistry {
        address lender = getLender(platform);
        if (isSimplePosition()) {
            requireSimplePositionDetails(platform, supplyToken, borrowToken);
        } else {
            simplePositionStore().platform = platform;
            simplePositionStore().supplyToken = supplyToken;
            simplePositionStore().borrowToken = borrowToken;

            address[] memory markets = new address[](2);
            markets[0] = supplyToken;
            markets[1] = borrowToken;
            enterMarkets(lender, platform, markets);
        }
        if (flashLoanAmount == 0) {
            _increaseWithFlashLoan(
                supplyToken,
                0,
                0,
                FoldingData({
                    principalAmount: principalAmount,
                    supplyAmount: supplyAmount,
                    borrowAmount: borrowAmount,
                    increasePosition: true,
                    exchangeDataBeforePosition: exchangeDataBeforePosition,
                    exchangeDataAfterPosition: exchangeDataAfterPosition
                })
            );
        } else {
            getFlashLoan(
                flashLoanToken,
                flashLoanAmount,
                abi.encode(
                    FoldingData({
                        principalAmount: principalAmount,
                        supplyAmount: supplyAmount,
                        borrowAmount: borrowAmount,
                        increasePosition: true,
                        exchangeDataBeforePosition: exchangeDataBeforePosition,
                        exchangeDataAfterPosition: exchangeDataAfterPosition
                    })
                )
            );
        }
    }

    function decreaseSimplePositionWithFlashLoan(
        address flashLoanToken,
        uint256 flashLoanAmount,
        address platform,
        address redeemToken,
        uint256 redeemPrincipal,
        uint256 redeemAmount,
        address repayToken,
        uint256 repayAmount,
        bytes memory exchangeDataBeforePosition,
        bytes memory exchangeDataAfterPosition
    ) external override onlyAccountOwner {
        requireSimplePositionDetails(platform, redeemToken, repayToken);
        if (flashLoanAmount == 0) {
            _decreaseWithFlashLoan(
                redeemToken,
                0,
                0,
                FoldingData({
                    principalAmount: redeemPrincipal,
                    supplyAmount: redeemAmount,
                    borrowAmount: repayAmount,
                    increasePosition: false,
                    exchangeDataBeforePosition: exchangeDataBeforePosition,
                    exchangeDataAfterPosition: exchangeDataAfterPosition
                })
            );
        } else {
            getFlashLoan(
                flashLoanToken,
                flashLoanAmount,
                abi.encode(
                    FoldingData({
                        principalAmount: redeemPrincipal,
                        supplyAmount: redeemAmount,
                        borrowAmount: repayAmount,
                        increasePosition: false,
                        exchangeDataBeforePosition: exchangeDataBeforePosition,
                        exchangeDataAfterPosition: exchangeDataAfterPosition
                    })
                )
            );
        }
    }

    /// @dev Called by the flash loaner in the flash loan callback
    function useFlashLoan(
        address flashloanToken,
        uint256 flashloanAmount,
        uint256 repayFlashAmount,
        bytes memory passedData
    ) internal override {
        FoldingData memory fd = abi.decode(passedData, (FoldingData));

        if (fd.increasePosition) {
            _increaseWithFlashLoan(flashloanToken, flashloanAmount, repayFlashAmount, fd);
        } else {
            _decreaseWithFlashLoan(flashloanToken, flashloanAmount, repayFlashAmount, fd);
        }
    }

    function _increaseWithFlashLoan(
        address flashloanToken,
        uint256 flashloanAmount,
        uint256 repayFlashAmount,
        FoldingData memory fd
    ) internal {
        SimplePositionStore memory sp = simplePositionStore();
        address lender = getLender(sp.platform);
        if (fd.principalAmount > 0) {
            addPrincipal(fd.principalAmount);
        }
        uint256 availableSupplyAmount;
        if (sp.supplyToken == flashloanToken) {
            availableSupplyAmount = flashloanAmount.add(fd.principalAmount);
            require(availableSupplyAmount >= fd.supplyAmount, 'SPLLC1');
        } else {
            availableSupplyAmount = swapFromExact(
                getExchanger(fd.exchangeDataBeforePosition[0]),
                flashloanToken,
                sp.supplyToken,
                flashloanAmount,
                fd.supplyAmount.sub(fd.principalAmount)
            ).add(fd.principalAmount);
        }

        supply(lender, sp.platform, sp.supplyToken, availableSupplyAmount);

        if (repayFlashAmount == 0) {
            return;
        }

        if (sp.borrowToken == flashloanToken) {
            require(fd.borrowAmount >= repayFlashAmount, 'SPLLC2');
            borrow(lender, sp.platform, sp.borrowToken, repayFlashAmount);
        } else {
            address exchangerAdapter = getExchanger(fd.exchangeDataAfterPosition[0]);
            uint256 borrowAmountNeeded = getAmountIn(
                exchangerAdapter,
                sp.borrowToken,
                flashloanToken,
                repayFlashAmount
            );
            require(fd.borrowAmount >= borrowAmountNeeded, 'SPLLC2');
            borrow(lender, sp.platform, sp.borrowToken, borrowAmountNeeded);
            swapToExact(exchangerAdapter, sp.borrowToken, flashloanToken, borrowAmountNeeded, repayFlashAmount);
        }
    }

    function _decreaseWithFlashLoan(
        address flashloanToken,
        uint256 flashloanAmount,
        uint256 repayFlashAmount,
        FoldingData memory fd
    ) internal {
        SimplePositionStore memory sp = simplePositionStore();
        address lender = getLender(sp.platform);

        uint256 debt = getBorrowBalance(lender, sp.platform, sp.borrowToken);
        uint256 deposit = getSupplyBalance(lender, sp.platform, sp.supplyToken);
        uint256 positionValue = deposit.sub(
            debt.mul(getReferencePrice(lender, sp.platform, sp.borrowToken)).div(
                getReferencePrice(lender, sp.platform, sp.supplyToken)
            )
        );
        if (debt > fd.borrowAmount) {
            debt = fd.borrowAmount;
        }
        if (debt > 0) {
            if (sp.borrowToken == flashloanToken) {
                require(flashloanAmount >= debt, 'SPLLC3');
                repayFlashAmount = repayFlashAmount.sub(flashloanAmount - debt);
            } else {
                uint256 flashloanAmountNeeded = swapToExact(
                    getExchanger(fd.exchangeDataBeforePosition[0]),
                    flashloanToken,
                    sp.borrowToken,
                    flashloanAmount,
                    debt
                );
                repayFlashAmount = repayFlashAmount.sub(flashloanAmount - flashloanAmountNeeded);
            }
            repayBorrow(lender, sp.platform, sp.borrowToken, debt);
        }

        if (fd.supplyAmount > deposit) {
            fd.supplyAmount = deposit;
        }

        redeemSupply(lender, sp.platform, sp.supplyToken, fd.supplyAmount);

        uint256 redeemPrincipalAmount;
        if (sp.supplyToken == flashloanToken) {
            redeemPrincipalAmount = fd.supplyAmount.sub(repayFlashAmount);
        } else {
            redeemPrincipalAmount = fd.supplyAmount.sub(
                swapToExact(
                    getExchanger(fd.exchangeDataAfterPosition[0]),
                    sp.supplyToken,
                    flashloanToken,
                    fd.supplyAmount,
                    repayFlashAmount
                )
            );
        }
        require(redeemPrincipalAmount >= fd.principalAmount, 'SPLLC5');
        if (redeemPrincipalAmount > 0) {
            withdraw(redeemPrincipalAmount, positionValue);
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '../../modules/Lender/LendingDispatcher.sol';
import '../../modules/SimplePosition/SimplePositionStorage.sol';
import '../interfaces/ISimplePositionBaseConnector.sol';

contract SimplePositionBaseConnector is LendingDispatcher, SimplePositionStorage, ISimplePositionBaseConnector {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function getBorrowBalance() public override returns (uint256) {
        return
            getBorrowBalance(
                getLender(simplePositionStore().platform),
                simplePositionStore().platform,
                simplePositionStore().borrowToken
            );
    }

    function getSupplyBalance() public override returns (uint256) {
        return
            getSupplyBalance(
                getLender(simplePositionStore().platform),
                simplePositionStore().platform,
                simplePositionStore().supplyToken
            );
    }

    function getCollateralUsageFactor() public override returns (uint256) {
        return getCollateralUsageFactor(getLender(simplePositionStore().platform), simplePositionStore().platform);
    }

    function getPositionValue() public override returns (uint256 positionValue) {
        SimplePositionStore memory sp = simplePositionStore();
        address lender = getLender(sp.platform);

        uint256 debt = getBorrowBalance(lender, sp.platform, sp.borrowToken);
        uint256 deposit = getSupplyBalance(lender, sp.platform, sp.supplyToken);
        debt = debt.mul(getReferencePrice(lender, sp.platform, sp.borrowToken)).div(
            getReferencePrice(lender, sp.platform, sp.supplyToken)
        );
        if (deposit >= debt) {
            positionValue = deposit - debt;
        } else {
            positionValue = 0;
        }
    }

    function getPrincipalValue() public override returns (uint256) {
        return simplePositionStore().principalValue;
    }

    function getPositionMetadata() external override returns (SimplePositionMetadata memory metadata) {
        metadata.positionAddress = address(this);
        metadata.platformAddress = simplePositionStore().platform;
        metadata.supplyTokenAddress = simplePositionStore().supplyToken;
        metadata.borrowTokenAddress = simplePositionStore().borrowToken;
        metadata.supplyAmount = getSupplyBalance();
        metadata.borrowAmount = getBorrowBalance();
        metadata.collateralUsageFactor = getCollateralUsageFactor();
        metadata.principalValue = getPrincipalValue();
        metadata.positionValue = getPositionValue();
    }

    function getSimplePositionDetails()
        external
        view
        override
        returns (
            address,
            address,
            address
        )
    {
        SimplePositionStore storage sp = simplePositionStore();
        return (sp.platform, sp.supplyToken, sp.borrowToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISimplePositionLeveragedLendingConnector {
    function increaseSimplePositionWithFlashLoan(
        address flashLoanToken,
        uint256 flashLoanAmount,
        address platform,
        address supplyToken,
        uint256 principalAmount,
        uint256 supplyAmount,
        address borrowToken,
        uint256 borrowAmount,
        bytes memory exchangeDataBeforePosition,
        bytes memory exchangeDataAfterPosition
    ) external;

    function decreaseSimplePositionWithFlashLoan(
        address flashLoanToken,
        uint256 flashLoanAmount,
        address platform,
        address redeemToken,
        uint256 redeemPrincipal,
        uint256 redeemAmount,
        address repayToken,
        uint256 repayAmount,
        bytes memory exchangeDataBeforePosition,
        bytes memory exchangeDataAfterPosition
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IExchangerAdapterProvider {
    function getExchangerAdapter(byte flag) external view returns (address exchangerAdapter);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import './DydxFlashloanBase.sol';
import './ICallee.sol';
import '../../../modules/FoldingAccount/FoldingAccountStorage.sol';

abstract contract DyDxFlashModule is ICallee, DydxFlashloanBase, FoldingAccountStorage {
    using SafeERC20 for IERC20;

    address public immutable SELF_ADDRESS;
    address public immutable SOLO; //0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    constructor(address soloAddress) public {
        require(soloAddress != address(0), 'ICP0');
        SELF_ADDRESS = address(this);
        SOLO = soloAddress;
    }

    struct LoanData {
        address loanedToken;
        uint256 loanAmount;
        uint256 repayAmount;
        bytes data;
    }

    function getFlashLoan(
        address tokenToLoan,
        uint256 flashLoanAmount,
        bytes memory data
    ) internal {
        uint256 marketId = _getMarketIdFromTokenAddress(SOLO, tokenToLoan);
        uint256 repayAmount = _getRepaymentAmountInternal(flashLoanAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);
        operations[0] = _getWithdrawAction(marketId, flashLoanAmount);
        operations[1] = _getCallAction(
            abi.encode(
                LoanData({
                    loanedToken: tokenToLoan,
                    loanAmount: flashLoanAmount,
                    repayAmount: repayAmount,
                    data: data
                })
            )
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        // @dev Force callback to this connector
        aStore().callbackTarget = SELF_ADDRESS;
        aStore().expectedCallbackSig = bytes4(keccak256('callFunction(address,(address,uint256),bytes)'));

        IERC20(tokenToLoan).safeIncreaseAllowance(SOLO, repayAmount);
        ISoloMargin(SOLO).operate(accountInfos, operations);
        IERC20(tokenToLoan).safeApprove(SOLO, 0);
    }

    function callFunction(
        address sender,
        Account.Info calldata,
        bytes calldata data
    ) external override {
        require(address(msg.sender) == SOLO, 'DFM1');
        require(sender == address(this), 'DFM2');
        require(aStore().callbackTarget == SELF_ADDRESS, 'DFM3');

        // @dev Clear forced callback to this connector
        delete aStore().callbackTarget;
        delete aStore().expectedCallbackSig;

        LoanData memory loanData = abi.decode(data, (LoanData));
        useFlashLoan(loanData.loanedToken, loanData.loanAmount, loanData.repayAmount, loanData.data);
    }

    function useFlashLoan(
        address loanToken,
        uint256 loanAmount,
        uint256 repayAmount,
        bytes memory data
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/utils/Address.sol';

import './IExchanger.sol';

contract ExchangerDispatcher {
    using Address for address;

    function exchange(
        address adapter,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        bytes memory txData
    ) internal returns (uint256) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(IExchanger.exchange.selector, fromToken, toToken, fromAmount, minToAmount, txData)
        );
        return abi.decode(returnData, (uint256));
    }

    function swapToExact(
        address adapter,
        address fromToken,
        address toToken,
        uint256 maxFromAmount,
        uint256 toAmount
    ) internal returns (uint256) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(IExchanger.swapToExact.selector, fromToken, toToken, maxFromAmount, toAmount)
        );
        return abi.decode(returnData, (uint256));
    }

    function swapFromExact(
        address adapter,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount
    ) internal returns (uint256) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(IExchanger.swapFromExact.selector, fromToken, toToken, fromAmount, minToAmount)
        );
        return abi.decode(returnData, (uint256));
    }

    function getAmountOut(
        address adapter,
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) internal returns (uint256) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(IExchanger.getAmountOut.selector, fromToken, toToken, fromAmount)
        );
        return abi.decode(returnData, (uint256));
    }

    function getAmountIn(
        address adapter,
        address fromToken,
        address toToken,
        uint256 toAmount
    ) internal returns (uint256) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(IExchanger.getAmountIn.selector, fromToken, toToken, toAmount)
        );
        return abi.decode(returnData, (uint256));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '../SimplePosition/SimplePositionStorage.sol';
import '../FoldingAccount/FoldingAccountStorage.sol';

contract FundsManager is FoldingAccountStorage, SimplePositionStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 internal constant MANTISSA = 1e18;

    uint256 public immutable principal;
    uint256 public immutable profit;
    address public immutable holder;

    constructor(
        uint256 _principal,
        uint256 _profit,
        address _holder
    ) public {
        require(_principal < MANTISSA, 'ICP1');
        require(_profit < MANTISSA, 'ICP1');
        require(_holder != address(0), 'ICP0');
        principal = _principal;
        profit = _profit;
        holder = _holder;
    }

    function addPrincipal(uint256 amount) internal {
        IERC20(simplePositionStore().supplyToken).safeTransferFrom(accountOwner(), address(this), amount);
        simplePositionStore().principalValue += amount;
    }

    function withdraw(uint256 amount, uint256 positionValue) internal {
        SimplePositionStore memory sp = simplePositionStore();

        uint256 principalFactor = sp.principalValue.mul(MANTISSA).div(positionValue);

        uint256 principalShare = amount;
        uint256 profitShare;

        if (principalFactor < MANTISSA) {
            principalShare = amount.mul(principalFactor) / MANTISSA;
            profitShare = amount.sub(principalShare);
        }

        uint256 subsidy = principalShare.mul(principal).add(profitShare.mul(profit)) / MANTISSA;

        if (sp.principalValue > principalShare) {
            simplePositionStore().principalValue = sp.principalValue - principalShare;
        } else {
            simplePositionStore().principalValue = 0;
        }

        IERC20(sp.supplyToken).safeTransfer(holder, subsidy);
        IERC20(sp.supplyToken).safeTransfer(accountOwner(), amount.sub(subsidy));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Address.sol';

import './ILendingPlatform.sol';
import '../../core/interfaces/ILendingPlatformAdapterProvider.sol';
import '../../modules/FoldingAccount/FoldingAccountStorage.sol';

contract LendingDispatcher is FoldingAccountStorage {
    using Address for address;

    function getLender(address platform) internal view returns (address) {
        return ILendingPlatformAdapterProvider(aStore().foldingRegistry).getPlatformAdapter(platform);
    }

    function getCollateralUsageFactor(address adapter, address platform)
        internal
        returns (uint256 collateralUsageFactor)
    {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getCollateralUsageFactor.selector, platform)
        );
        return abi.decode(returnData, (uint256));
    }

    function getCollateralFactorForAsset(
        address adapter,
        address platform,
        address asset
    ) internal returns (uint256) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getCollateralFactorForAsset.selector, platform, asset)
        );
        return abi.decode(returnData, (uint256));
    }

    /// @dev precision and decimals are expected to follow Compound 's pattern (1e18 precision, decimals taken into account).
    /// Currency in which the price is expressed is different depending on the platform that is being queried
    function getReferencePrice(
        address adapter,
        address platform,
        address asset
    ) internal returns (uint256 referencePrice) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getReferencePrice.selector, platform, asset)
        );
        return abi.decode(returnData, (uint256));
    }

    function getBorrowBalance(
        address adapter,
        address platform,
        address token
    ) internal returns (uint256 borrowBalance) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getBorrowBalance.selector, platform, token)
        );
        return abi.decode(returnData, (uint256));
    }

    function getSupplyBalance(
        address adapter,
        address platform,
        address token
    ) internal returns (uint256 supplyBalance) {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.getSupplyBalance.selector, platform, token)
        );
        return abi.decode(returnData, (uint256));
    }

    function enterMarkets(
        address adapter,
        address platform,
        address[] memory markets
    ) internal {
        adapter.functionDelegateCall(abi.encodeWithSelector(ILendingPlatform.enterMarkets.selector, platform, markets));
    }

    function claimRewards(address adapter, address platform)
        internal
        returns (address rewardsToken, uint256 rewardsAmount)
    {
        bytes memory returnData = adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.claimRewards.selector, platform)
        );
        return abi.decode(returnData, (address, uint256));
    }

    function supply(
        address adapter,
        address platform,
        address token,
        uint256 amount
    ) internal {
        adapter.functionDelegateCall(abi.encodeWithSelector(ILendingPlatform.supply.selector, platform, token, amount));
    }

    function borrow(
        address adapter,
        address platform,
        address token,
        uint256 amount
    ) internal {
        adapter.functionDelegateCall(abi.encodeWithSelector(ILendingPlatform.borrow.selector, platform, token, amount));
    }

    function redeemSupply(
        address adapter,
        address platform,
        address token,
        uint256 amount
    ) internal {
        adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.redeemSupply.selector, platform, token, amount)
        );
    }

    function repayBorrow(
        address adapter,
        address platform,
        address token,
        uint256 amount
    ) internal {
        adapter.functionDelegateCall(
            abi.encodeWithSelector(ILendingPlatform.repayBorrow.selector, platform, token, amount)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract SimplePositionStorage {
    bytes32 private constant SIMPLE_POSITION_STORAGE_LOCATION = keccak256('folding.simplePosition.storage');

    /**
     * platform:        address of the underlying platform (AAVE, COMPOUND, etc)
     *
     * supplyToken:     address of the token that is being supplied to the underlying platform
     *                  This token is also the principal token
     *
     * borrowToken:     address of the token that is being borrowed to leverage on supply token
     *
     * principalValue:  amount of supplyToken that user has invested in this position
     */
    struct SimplePositionStore {
        address platform;
        address supplyToken;
        address borrowToken;
        uint256 principalValue;
    }

    function simplePositionStore() internal pure returns (SimplePositionStore storage s) {
        bytes32 position = SIMPLE_POSITION_STORAGE_LOCATION;
        assembly {
            s_slot := position
        }
    }

    function isSimplePosition() internal view returns (bool) {
        return simplePositionStore().platform != address(0);
    }

    function requireSimplePositionDetails(
        address platform,
        address supplyToken,
        address borrowToken
    ) internal view {
        require(simplePositionStore().platform == platform, 'SP2');
        require(simplePositionStore().supplyToken == supplyToken, 'SP3');
        require(simplePositionStore().borrowToken == borrowToken, 'SP4');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct SimplePositionMetadata {
    uint256 supplyAmount;
    uint256 borrowAmount;
    uint256 collateralUsageFactor;
    uint256 principalValue;
    uint256 positionValue;
    address positionAddress;
    address platformAddress;
    address supplyTokenAddress;
    address borrowTokenAddress;
}

interface ISimplePositionBaseConnector {
    function getBorrowBalance() external returns (uint256);

    function getSupplyBalance() external returns (uint256);

    function getPositionValue() external returns (uint256);

    function getPrincipalValue() external returns (uint256);

    function getCollateralUsageFactor() external returns (uint256);

    function getSimplePositionDetails()
        external
        view
        returns (
            address,
            address,
            address
        );

    function getPositionMetadata() external returns (SimplePositionMetadata memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @dev All factors or APYs are written as a number with mantissa 18.
struct AssetMetadata {
    address assetAddress;
    string assetSymbol;
    uint8 assetDecimals;
    uint256 referencePrice;
    uint256 totalLiquidity;
    uint256 totalSupply;
    uint256 totalBorrow;
    uint256 totalReserves;
    uint256 supplyAPR;
    uint256 borrowAPR;
    address rewardTokenAddress;
    string rewardTokenSymbol;
    uint8 rewardTokenDecimals;
    uint256 estimatedSupplyRewardsPerYear;
    uint256 estimatedBorrowRewardsPerYear;
    uint256 collateralFactor;
    uint256 liquidationFactor;
    bool canSupply;
    bool canBorrow;
}

interface ILendingPlatform {
    function getAssetMetadata(address platform, address asset) external returns (AssetMetadata memory assetMetadata);

    function getCollateralUsageFactor(address platform) external returns (uint256 collateralUsageFactor);

    function getCollateralFactorForAsset(address platform, address asset) external returns (uint256);

    function getReferencePrice(address platform, address token) external returns (uint256 referencePrice);

    function getBorrowBalance(address platform, address token) external returns (uint256 borrowBalance);

    function getSupplyBalance(address platform, address token) external returns (uint256 supplyBalance);

    function claimRewards(address platform) external returns (address rewardsToken, uint256 rewardsAmount);

    function enterMarkets(address platform, address[] memory markets) external;

    function supply(
        address platform,
        address token,
        uint256 amount
    ) external;

    function borrow(
        address platform,
        address token,
        uint256 amount
    ) external;

    function redeemSupply(
        address platform,
        address token,
        uint256 amount
    ) external;

    function repayBorrow(
        address platform,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILendingPlatformAdapterProvider {
    function getPlatformAdapter(address platform) external view returns (address platformAdapter);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract FoldingAccountStorage {
    bytes32 constant ACCOUNT_STORAGE_POSITION = keccak256('folding.account.storage');

    /**
     * entryCaller:         address of the caller of the account, during a transaction
     *
     * callbackTarget:      address of logic to be run when expecting a callback
     *
     * expectedCallbackSig: signature of function to be run when expecting a callback
     *
     * foldingRegistry      address of factory creating FoldingAccount
     *
     * nft:                 address of the nft contract.
     *
     * owner:               address of the owner of this FoldingAccount.
     */
    struct AccountStore {
        address entryCaller;
        address callbackTarget;
        bytes4 expectedCallbackSig;
        address foldingRegistry;
        address nft;
        address owner;
    }

    modifier onlyAccountOwner() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.owner, 'FA2');
        _;
    }

    modifier onlyNFTContract() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.nft, 'FA3');
        _;
    }

    modifier onlyAccountOwnerOrRegistry() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.owner || s.entryCaller == s.foldingRegistry, 'FA4');
        _;
    }

    function aStore() internal pure returns (AccountStore storage s) {
        bytes32 position = ACCOUNT_STORAGE_POSITION;
        assembly {
            s_slot := position
        }
    }

    function accountOwner() internal view returns (address) {
        return aStore().owner;
    }
}

// SPDX-License-Identifier: MIT

// Taken from: https://github.com/studydefi/money-legos/blob/master/src/dydx/contracts/DydxFlashloanBase.sol

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './ISoloMargin.sol';

contract DydxFlashloanBase {
    using SafeMath for uint256;

    // -- Internal Helper functions -- //

    function _getMarketIdFromTokenAddress(address _solo, address token) internal view returns (uint256) {
        ISoloMargin solo = ISoloMargin(_solo);

        uint256 numMarkets = solo.getNumMarkets();

        address curToken;
        for (uint256 i = 0; i < numMarkets; i++) {
            curToken = solo.getMarketTokenAddress(i);

            if (curToken == token) {
                return i;
            }
        }

        revert('No marketId found for provided token');
    }

    function _getRepaymentAmountInternal(uint256 amount) internal pure returns (uint256) {
        // Needs to be overcollateralize
        // Needs to provide +2 wei to be safe
        return amount.add(2);
    }

    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({ owner: address(this), number: 1 });
    }

    function _getWithdrawAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ''
            });
    }

    function _getCallAction(bytes memory data) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: 0
                }),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: data
            });
    }

    function _getDepositAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ''
            });
    }
}

// SPDX-License-Identifier: Apache

/*
    Copyright 2019 dYdX Trading Inc.
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

// Taken from: https://github.com/dydxprotocol/solo/blob/master/contracts/protocol/interfaces/ICallee.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { Account } from './ISoloMargin.sol';

/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for Solo must implement in order to ingest data.
 */
interface ICallee {
    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to Solo
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

// Taken from: https://github.com/studydefi/money-legos/blob/master/src/dydx/contracts/ISoloMargin.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library Account {
    enum Status {
        Normal,
        Liquid,
        Vapor
    }
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Storage {
        mapping(uint256 => Types.Par) balances; // Mapping from marketId to principal
        Status status;
    }
}

library Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (publicly)
        Sell, // sell an amount of some token (publicly)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AccountLayout {
        OnePrimary,
        TwoPrimary,
        PrimaryAndSecondary
    }

    enum MarketLayout {
        ZeroMarkets,
        OneMarket,
        TwoMarkets
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }
}

library Decimal {
    struct D256 {
        uint256 value;
    }
}

library Interest {
    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }
}

library Monetary {
    struct Price {
        uint256 value;
    }

    struct Value {
        uint256 value;
    }
}

library Storage {
    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;
        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;
        // Interest index of the market
        Interest.Index index;
        // Contract address of the price oracle for this market
        address priceOracle;
        // Contract address of the interest setter for this market
        address interestSetter;
        // Multiplier on the marginRatio for this market
        Decimal.D256 marginPremium;
        // Multiplier on the liquidationSpread for this market
        Decimal.D256 spreadPremium;
        // Whether additional borrows are allowed for this market
        bool isClosing;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;
        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;
        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;
        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        uint64 marginRatioMax;
        uint64 liquidationSpreadMax;
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of Solo
    struct State {
        // number of markets
        uint256 numMarkets;
        // marketId => Market
        mapping(uint256 => Market) markets;
        // owner => account number => Account
        mapping(address => mapping(uint256 => Account.Storage)) accounts;
        // Addresses that can control other users accounts
        mapping(address => mapping(address => bool)) operators;
        // Addresses that can control all users accounts
        mapping(address => bool) globalOperators;
        // mutable risk parameters of the system
        RiskParams riskParams;
        // immutable risk limits of the system
        RiskLimits riskLimits;
    }
}

library Types {
    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

interface ISoloMargin {
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function ownerSetSpreadPremium(uint256 marketId, Decimal.D256 memory spreadPremium) external;

    function getIsGlobalOperator(address operator) external view returns (bool);

    function getMarketTokenAddress(uint256 marketId) external view returns (address);

    function ownerSetInterestSetter(uint256 marketId, address interestSetter) external;

    function getAccountValues(Account.Info memory account)
        external
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketPriceOracle(uint256 marketId) external view returns (address);

    function getMarketInterestSetter(uint256 marketId) external view returns (address);

    function getMarketSpreadPremium(uint256 marketId) external view returns (Decimal.D256 memory);

    function getNumMarkets() external view returns (uint256);

    function ownerWithdrawUnsupportedTokens(address token, address recipient) external returns (uint256);

    function ownerSetMinBorrowedValue(Monetary.Value memory minBorrowedValue) external;

    function ownerSetLiquidationSpread(Decimal.D256 memory spread) external;

    function ownerSetEarningsRate(Decimal.D256 memory earningsRate) external;

    function getIsLocalOperator(address owner, address operator) external view returns (bool);

    function getAccountPar(Account.Info memory account, uint256 marketId) external view returns (Types.Par memory);

    function ownerSetMarginPremium(uint256 marketId, Decimal.D256 memory marginPremium) external;

    function getMarginRatio() external view returns (Decimal.D256 memory);

    function getMarketCurrentIndex(uint256 marketId) external view returns (Interest.Index memory);

    function getMarketIsClosing(uint256 marketId) external view returns (bool);

    function getRiskParams() external view returns (Storage.RiskParams memory);

    function getAccountBalances(Account.Info memory account)
        external
        view
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        );

    function renounceOwnership() external;

    function getMinBorrowedValue() external view returns (Monetary.Value memory);

    function setOperators(OperatorArg[] memory args) external;

    function getMarketPrice(uint256 marketId) external view returns (address);

    function owner() external view returns (address);

    function isOwner() external view returns (bool);

    function ownerWithdrawExcessTokens(uint256 marketId, address recipient) external returns (uint256);

    function ownerAddMarket(
        address token,
        address priceOracle,
        address interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium
    ) external;

    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;

    function getMarketWithInfo(uint256 marketId)
        external
        view
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

    function ownerSetMarginRatio(Decimal.D256 memory ratio) external;

    function getLiquidationSpread() external view returns (Decimal.D256 memory);

    function getAccountWei(Account.Info memory account, uint256 marketId) external view returns (Types.Wei memory);

    function getMarketTotalPar(uint256 marketId) external view returns (Types.TotalPar memory);

    function getLiquidationSpreadForPair(uint256 heldMarketId, uint256 owedMarketId)
        external
        view
        returns (Decimal.D256 memory);

    function getNumExcessTokens(uint256 marketId) external view returns (Types.Wei memory);

    function getMarketCachedIndex(uint256 marketId) external view returns (Interest.Index memory);

    function getAccountStatus(Account.Info memory account) external view returns (uint8);

    function getEarningsRate() external view returns (Decimal.D256 memory);

    function ownerSetPriceOracle(uint256 marketId, address priceOracle) external;

    function getRiskLimits() external view returns (Storage.RiskLimits memory);

    function getMarket(uint256 marketId) external view returns (Storage.Market memory);

    function ownerSetIsClosing(uint256 marketId, bool isClosing) external;

    function ownerSetGlobalOperator(address operator, bool approved) external;

    function transferOwnership(address newOwner) external;

    function getAdjustedAccountValues(Account.Info memory account)
        external
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketMarginPremium(uint256 marketId) external view returns (Decimal.D256 memory);

    function getMarketInterestRate(uint256 marketId) external view returns (Interest.Rate memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IExchanger {
    function exchange(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        bytes calldata txData
    ) external returns (uint256 toAmount);

    function getAmountOut(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    function getAmountIn(
        address fromToken,
        address toToken,
        uint256 toAmount
    ) external view returns (uint256 fromAmount);

    function swapFromExact(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount
    ) external returns (uint256 toAmount);

    function swapToExact(
        address fromToken,
        address toToken,
        uint256 maxFromAmount,
        uint256 toAmount
    ) external returns (uint256 fromAmount);
}