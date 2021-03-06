/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// File: contracts/compound/interfaces/ICToken.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ICToken {
    function borrowIndex() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function repayBorrowBehalf(address borrower) external payable;

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function liquidateBorrow(address borrower, address cTokenCollateral)
        external
        payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function borrowRatePerBlock() external returns (uint256);

    function totalReserves() external returns (uint256);

    function reserveFactorMantissa() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function getCash() external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function underlying() external returns (address);

    function exchangeRateStored() external view returns (uint256);
}

// File: contracts/compound/interfaces/IComptroller.sol


pragma solidity ^0.6.0;

interface IComptroller {
    //mapping(address => uint) public compAccrued;

    function claimComp(address holder) external;

    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function getAssetsIn(address account)
        external
        view
        returns (address[] memory);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function markets(address cTokenAddress)
        external
        view
        returns (bool, uint256);

    struct CompMarketState {
        uint224 index;
        uint32 block;
    }

    function compSupplyState(address) external view returns (uint224, uint32);

    function compBorrowState(address) external view returns (uint224, uint32);

    //    mapping(address => CompMarketState) external compBorrowState;

    //mapping(address => mapping(address => uint)) public compSupplierIndex;

    //mapping(address => mapping(address => uint)) public compBorrowerIndex;
}

// File: contracts/interfaces/IERC20.sol


pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

    function decimals() external view returns (uint8);

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

// File: contracts/utils/SafeERC20.sol

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/utils/Address.sol


pragma solidity ^0.6.12;


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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (token == IERC20(0)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (token != IERC20(0)) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (token == IERC20(0)) {
            require(
                from == msg.sender && msg.value >= amount,
                "msg.value is zero"
            );
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who)
        internal
        view
        returns (uint256)
    {
        if (token == IERC20(0)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}

// File: contracts/interfaces/IXChanger.sol


pragma solidity ^0.6.0;


interface XChanger {
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        bool slipProtect
    ) external payable returns (uint256 result);

    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256[3] memory swapAmountsIn,
            uint256[3] memory swapAmountsOut,
            bool swapVia
        );

    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    )
        external
        view
        returns (
            uint256 inputAmount,
            uint256[3] memory swapAmountsIn,
            uint256[3] memory swapAmountsOut,
            bool swapVia
        );
}

// File: contracts/XChangerUser.sol


pragma solidity ^0.6.12;



/**
 * @dev Helper contract to communicate to XChanger(XTrinity) contract to obtain prices and change tokens as needed
 */
contract XChangerUser {
    using UniversalERC20 for IERC20;

    XChanger public xchanger;

    /**
     * @dev get a price of one token amount in another
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken
     */

    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) public view returns (uint256 returnAmount) {
        if (fromToken == toToken) {
            returnAmount = amount;
        } else {
            try xchanger.quote(fromToken, toToken, amount) returns (
                uint256 _returnAmount,
                uint256[3] memory, //swapAmountsIn,
                uint256[3] memory, //swapAmountsOut,
                bool //swapVia
            ) {
                returnAmount = _returnAmount;
            } catch {}
        }
    }

    /**
     * @dev get a reverse price of one token amount in another
     * the opposite of above 'quote' method when we need to understand how much we need to spend actually
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param returnAmount - of the toToken
     */
    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    ) public view returns (uint256 inputAmount) {
        if (fromToken == toToken) {
            inputAmount = returnAmount;
        } else {
            try
                xchanger.reverseQuote(fromToken, toToken, returnAmount)
            returns (
                uint256 _inputAmount,
                uint256[3] memory, //swapAmountsIn,
                uint256[3] memory, //swapAmountsOut,
                bool // swapVia
            ) {
                inputAmount = _inputAmount;
                inputAmount += 1; // Curve requires this
            } catch {}
        }
    }

    /**
     * @dev swap one token to another given the amount we want to spend
     
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken we are spending
     * @param slipProtect - flag to ensure the transaction will be performed if the received amount is not less than expected within the given slip %% range (like 1%)
     */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        bool slipProtect
    ) public payable returns (uint256 returnAmount) {
        if (fromToken.allowance(address(this), address(xchanger)) < amount) {
            fromToken.universalApprove(address(xchanger), 0);
            fromToken.universalApprove(address(xchanger), uint256(-1));
        }

        returnAmount = xchanger.swap(fromToken, toToken, amount, slipProtect);
    }
}

// File: contracts/access/Context.sol


pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/CompMinerV2.0.sol


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;






abstract contract FLReceiver {
    enum FlashloanProvider {DYDX, AAVE}

    function initiateFlashLoan(
        uint256 amount,
        uint256 flashLoanAmount,
        int8 _provider
    ) external virtual;
}

/**
 * @title CompMiner external pool contract
 * @dev is an example of external pool which implements maximizing COMP yield mining capabilities.
 * It is curerntly denominated in DAI and accepts it
 */

contract CompMiner is Ownable, XChangerUser {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum OP {UNKNOWN, OPEN, CLOSE, PARTIALLYCLOSE}

    OP private state;

    enum FlashloanProvider {DYDX, AAVE}
    FlashloanProvider public flashloanProvider; // Flashloan Aave or dYdX

    mapping(FlashloanProvider => int8) internal providers;

    address private constant COMPTROLLER =
        0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address private constant COMPOUND_ORACLE =
        0x1D8aEdc9E924730DD3f9641CDb4D1B92B848b4bd;
    /* 
    * @dev now it is part of initializer
    
    address private constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant CDAI_ADDRESS =
        0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    */

    address private constant COMP_ADDRESS =
        0xc00e94Cb662C3520282E6f5717214004A7f26888;

    IERC20 private constant comp = IERC20(COMP_ADDRESS);

    address public enterToken; //= DAI_ADDRESS;
    address public cTokenAddress; //= CDAI_ADDRESS;
    IERC20 private enterTokenIERC20; //= IERC20(enterToken);
    ICToken private cToken; // = ICToken(cTokenAddress);

    uint256 public flRatio;
    uint256 public minCompConvert;

    bool private initialized;

    event ratioUpdated(uint256);
    event COMPRatioUpdated(uint256);
    event compChanged(uint256);
    event compTooSmall(uint256);
    event NotDeposited();
    event LogValueHolderUpdated(address Manager);

    address public ValueHolder;
    FLReceiver public flReceiver;

    /**
     * @dev this modifier is only for methods that should be called by ValueHolder contract
     */
    modifier onlyValueHolder() {
        require(msg.sender == ValueHolder, "Not Value Holder");
        _;
    }

    /**
     * @dev Sets new ValueHolder address
     */
    function setValueHolder(address _ValueHolder) external onlyOwner {
        ValueHolder = _ValueHolder;
        emit LogValueHolderUpdated(_ValueHolder);
    }

    /**
     * @dev new contract initializer - we dont' use constructors as it is required to run behind a proxy. For the cases we don't know the owner yet
     */
    function init(
        address _xChanger,
        address _flReceiver,
        address _enterToken,
        address _cToken
    ) external {
        require(!initialized, "Initialized");
        initialized = true;
        _initVariables(_xChanger, _flReceiver, _enterToken, _cToken);
        Ownable.initialize(); // Do not forget this call!
    }

    /**
     * @dev internal variable initializer function
     */
    function _initVariables(
        address _xChanger,
        address _flReceiver,
        address _enterToken,
        address _cToken
    ) internal {
        flRatio = 290;
        minCompConvert = 3 * 1e17;
        flashloanProvider = FlashloanProvider.DYDX;
        xchanger = XChanger(_xChanger);
        flReceiver = FLReceiver(_flReceiver);
        providers[FlashloanProvider.DYDX] = 0;
        providers[FlashloanProvider.AAVE] = 1;
        enterToken = _enterToken;
        cTokenAddress = _cToken;
        enterTokenIERC20 = IERC20(enterToken);
        cToken = ICToken(cTokenAddress);
        ValueHolder = msg.sender;
    }

    /**
     * @dev re-initializer might be helpful for the cases where proxy's storage is corrupted by an old contact, but we cannot run init as we have the owner address already.
     * This method might help fixing the storage state.
     */
    function reInit(
        address _xChanger,
        address _flReceiver,
        address _enterToken,
        address _cToken
    ) public onlyOwner {
        _initVariables(_xChanger, _flReceiver, _enterToken, _cToken);
    }

    /**
     * @dev method for setting flash loan provider (AAVE/dYdX)
     */
    function setFlashloanProvider(FlashloanProvider _flashloanProvider)
        external
        onlyOwner
    {
        flashloanProvider = _flashloanProvider;
    }

    /**
     * @dev set new flashloan ratio (290/100)
     */
    function updateFlRatio(uint256 newValue) external onlyOwner {
        flRatio = newValue;
        emit ratioUpdated(newValue);
    }

    /**
     * @dev sent new minimum COMP value for conversion as we don't want to spend much gas on cheap COMP
     */
    function updateMinCompConvert(uint256 newValue) external onlyOwner {
        minCompConvert = newValue;
        emit COMPRatioUpdated(newValue);
    }

    /**
     * @dev set new XChanger (XTrinity) contract implementation address to use
     */
    function setXChangerImpl(address _Xchanger) external onlyOwner {
        xchanger = XChanger(_Xchanger);
    }

    /**
     * @dev set new flashloan receiver implementation address to use
     */
    function setFLReceiverImpl(address _flReceiver) external onlyOwner {
        flReceiver = FLReceiver(_flReceiver);
    }

    /**
     * @dev method for retrieving tokens back to ValueHolder or whereever
     */

    function transferTokenTo(
        address TokenAddress,
        address recipient,
        uint256 amount
    ) external onlyValueHolder returns (uint256) {
        IERC20 Token = IERC20(TokenAddress);
        uint256 balance = Token.balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }

        Token.universalTransfer(recipient, amount);
        return amount;
    }

    /**
     * @dev Main function to enter Compound supply/borrow position using the available [DAI] token balance
     */
    function addPosition() external onlyValueHolder returns (uint256 amount) {
        convertComp();

        IERC20 _token = IERC20(enterToken);

        amount = _token.balanceOf(address(this));
        require(amount > 0, "No available enterToken");

        uint256 flAmount = (amount.mul(flRatio)).div(100);
        openPositionFlashloan(amount, flAmount);
        // TODO: if ratio is closer to 0.7489 -> only add collateral
    }

    /**
     * @dev Main function to exit Compound supply/borrow position - partially or completely
     */
    function exitPosition(uint256 amount) external onlyValueHolder {
        if (amount == uint256(-1)) {
            //115792089237316195423570985008687907853269984665640564039457584007913129639935
            //10000000000000000000000
            closePositionFlashloan();
        } else {
            partiallyClosePositionFlashloan(amount);
        }
    }

    /**
     * @dev Supplementary function to ad collateral when b/s ratio is closer to liquidation
     */
    function addCollateral() external returns (uint256 amount) {
        IERC20 _token = IERC20(enterToken);
        amount = _token.balanceOf(address(this));

        // add _cCollToken to market
        enterMarketInternal(cTokenAddress);
        // mint _cCollToken
        mintInternal(enterToken, cTokenAddress, amount);
    }

    /**
     * @dev internal function to add funds to position using flashloan
     */

    function openPositionFlashloan(uint256 amount, uint256 flashLoanAmount)
        internal
        returns (bool)
    {
        // FLASHLOAN LOGIC
        state = OP.OPEN;

        flReceiver.initiateFlashLoan(
            amount,
            flashLoanAmount,
            providers[flashloanProvider]
        );

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC

        return true;
    }

    /**
     * @dev internal function to completely close position and withdraw funds using flashloan
     */
    function closePositionFlashloan() internal {
        // FLASHLOAN LOGIC
        uint256 flashLoanAmount =
            ICToken(cTokenAddress).borrowBalanceCurrent(address(this));
        state = OP.CLOSE;

        flReceiver.initiateFlashLoan(
            uint256(-1),
            flashLoanAmount,
            providers[flashloanProvider]
        );

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    /**
     * @dev internal function to partially close position and withdraw funds using flashloan
     */
    function partiallyClosePositionFlashloan(uint256 amount) internal {
        // FLASHLOAN LOGIC
        uint256 flashLoanAmount = amount.mul(3);
        state = OP.PARTIALLYCLOSE;

        flReceiver.initiateFlashLoan(
            uint256(-1),
            flashLoanAmount,
            providers[flashloanProvider]
        );

        state = OP.UNKNOWN;
        // END FLASHLOAN LOGIC
    }

    /**
     * @dev public universal callback function to receive flashloan - used with any flashloan provider
     */
    function universalFLcallback(
        uint256 flashloanAmount,
        uint256 totalDebt,
        uint256 depositAmount
    ) external {
        require(state != OP.UNKNOWN, "dYdX Unknown state");

        if (state == OP.OPEN) {
            uint256 totalFunds = flashloanAmount + depositAmount;

            deposit(
                enterToken,
                cTokenAddress,
                totalFunds,
                enterToken,
                cTokenAddress,
                totalDebt
            );
            convertComp();
        } else if (state == OP.CLOSE) {
            withdraw(
                enterToken,
                cTokenAddress,
                uint256(-1),
                enterToken,
                cTokenAddress,
                uint256(-1)
            );
            convertComp();
        } else if (state == OP.PARTIALLYCLOSE) {
            // flashloanData.amountFlashLoan.div(3) - user token requested
            uint256 cDaiToExtract =
                flashloanAmount.add(flashloanAmount.div(3)).mul(1e18).div(
                    cToken.exchangeRateCurrent()
                );

            withdraw(
                enterToken,
                cTokenAddress,
                cDaiToExtract,
                enterToken,
                cTokenAddress,
                flashloanAmount
            );
            convertComp();
        }

        IERC20(enterToken).universalTransfer(address(flReceiver), totalDebt);
    }

    // ** PRIVATE & INTERNAL functions **

    /**
     * @dev internal function to use in Compound - entering market and creating a deposit, then borrowing some amount
     */
    function deposit(
        address _collToken,
        address _cCollToken,
        uint256 _collAmount,
        address _borrowToken,
        address _cBorrowToken,
        uint256 _borrowAmount
    ) internal {
        // add _cCollToken to market
        enterMarketInternal(_cCollToken);

        // mint _cCollToken
        mintInternal(_collToken, _cCollToken, _collAmount);

        // borrow and withdraw _borrowToken
        //TODO: check with 0 address might be removed
        if (_borrowToken != address(0)) {
            borrowInternal(_cBorrowToken, _borrowAmount);
        }
    }

    /**
     * @dev Claim all available COMP from compound and convert to DAI as needed
     */
    function claimValue() external {
        IComptroller(COMPTROLLER).claimComp(address(this));
        convertComp();
    }

    /**
     * @dev Convert COMP to [DAI] using XChanger (XTrinity swap) if there is enough value
     */
    function convertComp() public {
        uint256 returnAmount;
        uint256 balanceComp = comp.balanceOf(address(this));
        if (balanceComp > minCompConvert) {
            returnAmount = swap(comp, enterTokenIERC20, balanceComp, false);
            emit compChanged(returnAmount);
        } else {
            emit compTooSmall(returnAmount);
        }
    }

    /**
     * @dev Get the total amount of DAI currently in Compound
     */
    function getTokenStaked() public view returns (uint256 totalTokenStaked) {
        uint256 borrowBalance =
            ICToken(cTokenAddress).borrowBalanceStored(address(this));
        uint256 supplyBalance =
            (
                ICToken(cTokenAddress).balanceOf(address(this)).mul(
                    ICToken(cTokenAddress).exchangeRateStored()
                )
            )
                .div(1e18);
        totalTokenStaked = supplyBalance.sub(borrowBalance);
    }

    /**
     * @dev Get the total value the Pool in [denominateTo] tokens [DAI?]
     */

    function getPoolValue(address denominateTo)
        public
        view
        returns (uint256 totalValue)
    {
        uint256 freeDAI = enterTokenIERC20.balanceOf(address(this));
        uint256 totalDAI = freeDAI.add(getTokenStaked());
        totalValue = quote(enterTokenIERC20, IERC20(denominateTo), totalDAI);

        uint256 balanceComp = comp.balanceOf(address(this));
        if (balanceComp > 0) {
            uint256 compQuote = quote(comp, IERC20(denominateTo), balanceComp);
            totalValue = totalValue.add(compQuote);
        }
    }

    /**
     * @dev approve collateral [DAI] to [cDAI] if needed
     */
    function approveCTokenInternal(address _tokenAddr, address _cTokenAddr)
        internal
    {
        if (
            IERC20(_tokenAddr).allowance(address(this), address(_cTokenAddr)) !=
            uint256(-1)
        ) {
            IERC20(_tokenAddr).universalApprove(_cTokenAddr, uint256(-1));
        }
    }

    /**
     * @dev internal function to use in Compound - pay back the debt and redeem the [DAI] to withdraw from Compound
     */

    function withdraw(
        address _collToken,
        address _cCollToken,
        uint256 cAmountRedeem,
        address _borrowToken,
        address _cBorrowToken,
        uint256 amountRepay
    ) internal {
        // repayBorrow _cBorrowToken
        paybackInternal(_borrowToken, _cBorrowToken, amountRepay);

        // redeem _cCollToken
        redeemInternal(_collToken, _cCollToken, cAmountRedeem);
    }

    /**
     * @dev internal function to use in Compound - enter market
     */
    function enterMarketInternal(address _cTokenAddr) internal {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        IComptroller(COMPTROLLER).enterMarkets(markets);
    }

    /**
     * @dev internal function to use in Compound - mint [cDAI] from [DAI]
     */
    function mintInternal(
        address _tokenAddr,
        address _cTokenAddr,
        uint256 _amount
    ) internal {
        // approve _cTokenAddr to pull the _tokenAddr tokens
        approveCTokenInternal(_tokenAddr, _cTokenAddr);

        require(ICToken(_cTokenAddr).mint(_amount) == 0, "mint int not 0");
    }

    /**
     * @dev internal function to use in Compound - borrow
     */

    function borrowInternal(address _cTokenAddr, uint256 _amount) internal {
        require(ICToken(_cTokenAddr).borrow(_amount) == 0, "borrow int not 0");
    }

    /**
     * @dev internal function to use in Compound - repay borrow
     */
    function paybackInternal(
        address _tokenAddr,
        address _cTokenAddr,
        uint256 amount
    ) internal {
        // approve _cTokenAddr to pull the _tokenAddr tokens

        approveCTokenInternal(_tokenAddr, _cTokenAddr);
        if (amount == uint256(-1))
            amount = ICToken(_cTokenAddr).borrowBalanceCurrent(address(this));

        require(
            ICToken(_cTokenAddr).repayBorrow(amount) == 0,
            "payback int repay borrow not 0"
        );
    }

    /**
     * @dev internal function to use in Compound - redeem
     */
    function redeemInternal(
        address _tokenAddr,
        address _cTokenAddr,
        uint256 amount
    ) internal returns (uint256) {
        // converts all _cTokenAddr into the underlying asset (_tokenAddr)
        if (amount == uint256(-1))
            amount = IERC20(_cTokenAddr).balanceOf(address(this));
        require(ICToken(_cTokenAddr).redeem(amount) == 0, "redeem int not 0");

        // withdraw funds to msg.sender - not needed
        //tokensSent =
        return IERC20(_tokenAddr).balanceOf(address(this));
    }
}