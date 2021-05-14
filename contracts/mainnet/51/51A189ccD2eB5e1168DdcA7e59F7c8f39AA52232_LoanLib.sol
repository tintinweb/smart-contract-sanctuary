/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/library/LoanLib.sol
pragma solidity =0.6.11 >=0.6.0 <0.8.0 >=0.6.2 <0.8.0;

////// contracts/interfaces/ICollateralLocker.sol
/* pragma solidity 0.6.11; */

interface ICollateralLocker {

    function collateralAsset() external view returns (address);

    function loan() external view returns (address);

    function pull(address, uint256) external;

}

////// contracts/interfaces/ICollateralLockerFactory.sol
/* pragma solidity 0.6.11; */

interface ICollateralLockerFactory {

    function owner(address) external view returns (address);
    
    function isLocker(address) external view returns (bool);

    function factoryType() external view returns (uint8);

    function newLocker(address) external returns (address);

}

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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

////// contracts/interfaces/IERC20Details.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

interface IERC20Details is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

}

////// contracts/interfaces/IFundingLocker.sol
/* pragma solidity 0.6.11; */

interface IFundingLocker {

    function liquidityAsset() external view returns (address);

    function loan() external view returns (address);

    function pull(address, uint256) external;

    function drain() external;

}

////// contracts/interfaces/IFundingLockerFactory.sol
/* pragma solidity 0.6.11; */

interface IFundingLockerFactory {

    function owner(address) external view returns (address);
    
    function isLocker(address) external view returns (bool);

    function factoryType() external view returns (uint8);
    
    function newLocker(address) external returns (address);

}

////// contracts/interfaces/ILateFeeCalc.sol
/* pragma solidity 0.6.11; */

interface ILateFeeCalc {

    function calcType() external view returns (uint8);

    function name() external view returns (bytes32);

    function lateFee() external view returns (uint256);

    function getLateFee(uint256) external view returns (uint256);

} 

////// contracts/interfaces/ILoanFactory.sol
/* pragma solidity 0.6.11; */

interface ILoanFactory {

    function CL_FACTORY() external view returns (uint8);

    function FL_FACTORY() external view returns (uint8);

    function INTEREST_CALC_TYPE() external view returns (uint8);

    function LATEFEE_CALC_TYPE() external view returns (uint8);

    function PREMIUM_CALC_TYPE() external view returns (uint8);

    function globals() external view returns (address);

    function loansCreated() external view returns (uint256);

    function loans(uint256) external view returns (address);

    function isLoan(address) external view returns (bool);

    function loanFactoryAdmins(address) external view returns (bool);

    function setGlobals(address) external;
    
    function createLoan(address, address, address, address, uint256[5] memory, address[3] memory) external returns (address);

    function setLoanFactoryAdmin(address, bool) external;

    function pause() external;

    function unpause() external;

}

////// contracts/interfaces/IMapleGlobals.sol
/* pragma solidity 0.6.11; */

interface IMapleGlobals {

    function pendingGovernor() external view returns (address);

    function governor() external view returns (address);

    function globalAdmin() external view returns (address);

    function mpl() external view returns (address);

    function mapleTreasury() external view returns (address);

    function isValidBalancerPool(address) external view returns (bool);

    function treasuryFee() external view returns (uint256);

    function investorFee() external view returns (uint256);

    function defaultGracePeriod() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function swapOutRequired() external view returns (uint256);

    function isValidLiquidityAsset(address) external view returns (bool);

    function isValidCollateralAsset(address) external view returns (bool);

    function isValidPoolDelegate(address) external view returns (bool);

    function validCalcs(address) external view returns (bool);

    function isValidCalc(address, uint8) external view returns (bool);

    function getLpCooldownParams() external view returns (uint256, uint256);

    function isValidLoanFactory(address) external view returns (bool);

    function isValidSubFactory(address, address, uint8) external view returns (bool);

    function isValidPoolFactory(address) external view returns (bool);
    
    function getLatestPrice(address) external view returns (uint256);
    
    function defaultUniswapPath(address, address) external view returns (address);

    function minLoanEquity() external view returns (uint256);
    
    function maxSwapSlippage() external view returns (uint256);

    function protocolPaused() external view returns (bool);

    function stakerCooldownPeriod() external view returns (uint256);

    function lpCooldownPeriod() external view returns (uint256);

    function stakerUnstakeWindow() external view returns (uint256);

    function lpWithdrawWindow() external view returns (uint256);

    function oracleFor(address) external view returns (address);

    function validSubFactories(address, address) external view returns (bool);

    function setStakerCooldownPeriod(uint256) external;

    function setLpCooldownPeriod(uint256) external;

    function setStakerUnstakeWindow(uint256) external;

    function setLpWithdrawWindow(uint256) external;

    function setMaxSwapSlippage(uint256) external;

    function setGlobalAdmin(address) external;

    function setValidBalancerPool(address, bool) external;

    function setProtocolPause(bool) external;

    function setValidPoolFactory(address, bool) external;

    function setValidLoanFactory(address, bool) external;

    function setValidSubFactory(address, address, bool) external;

    function setDefaultUniswapPath(address, address, address) external;

    function setPoolDelegateAllowlist(address, bool) external;

    function setCollateralAsset(address, bool) external;

    function setLiquidityAsset(address, bool) external;

    function setCalc(address, bool) external;

    function setInvestorFee(uint256) external;

    function setTreasuryFee(uint256) external;

    function setMapleTreasury(address) external;

    function setDefaultGracePeriod(uint256) external;

    function setMinLoanEquity(uint256) external;

    function setFundingPeriod(uint256) external;

    function setSwapOutRequired(uint256) external;

    function setPriceOracle(address, address) external;

    function setPendingGovernor(address) external;

    function acceptGovernor() external;

}

////// contracts/interfaces/IPremiumCalc.sol
/* pragma solidity 0.6.11; */

interface IPremiumCalc {

    function calcType() external view returns (uint8);

    function name() external view returns (bytes32);

    function premiumFee() external view returns (uint256);

    function getPremiumPayment(address) external view returns (uint256, uint256, uint256);

} 

////// contracts/interfaces/IRepaymentCalc.sol
/* pragma solidity 0.6.11; */

interface IRepaymentCalc {

    function calcType() external view returns (uint8);

    function name() external view returns (bytes32);

    function getNextPayment(address) external view returns (uint256, uint256, uint256);

} 

////// contracts/interfaces/IUniswapRouter.sol
/* pragma solidity 0.6.11; */

interface IUniswapRouter {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function WETH() external pure returns (address);

}

////// lib/openzeppelin-contracts/contracts/math/SafeMath.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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

////// contracts/library/Util.sol
/* pragma solidity 0.6.11; */

/* import "../interfaces/IERC20Details.sol"; */
/* import "../interfaces/IMapleGlobals.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */

/// @title Util is a library that contains utility functions.
library Util {

    using SafeMath for uint256;

    /**
        @dev    Calculates the minimum amount from a swap (adjustable for price slippage).
        @param  globals   Instance of a MapleGlobals.
        @param  fromAsset Address of ERC-20 that will be swapped.
        @param  toAsset   Address of ERC-20 that will returned from swap.
        @param  swapAmt   Amount of `fromAsset` to be swapped.
        @return Expected amount of `toAsset` to receive from swap based on current oracle prices.
    */
    function calcMinAmount(IMapleGlobals globals, address fromAsset, address toAsset, uint256 swapAmt) external view returns (uint256) {
        return 
            swapAmt
                .mul(globals.getLatestPrice(fromAsset))           // Convert from `fromAsset` value.
                .mul(10 ** IERC20Details(toAsset).decimals())     // Convert to `toAsset` decimal precision.
                .div(globals.getLatestPrice(toAsset))             // Convert to `toAsset` value.
                .div(10 ** IERC20Details(fromAsset).decimals());  // Convert from `fromAsset` decimal precision.
    }
}

////// lib/openzeppelin-contracts/contracts/utils/Address.sol
/* pragma solidity >=0.6.2 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol
/* pragma solidity >=0.6.0 <0.8.0; */

/* import "./IERC20.sol"; */
/* import "../../math/SafeMath.sol"; */
/* import "../../utils/Address.sol"; */

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

////// contracts/library/LoanLib.sol
/* pragma solidity 0.6.11; */

/* import "../interfaces/ICollateralLocker.sol"; */
/* import "../interfaces/ICollateralLockerFactory.sol"; */
/* import "../interfaces/IERC20Details.sol"; */
/* import "../interfaces/IFundingLocker.sol"; */
/* import "../interfaces/IFundingLockerFactory.sol"; */
/* import "../interfaces/IMapleGlobals.sol"; */
/* import "../interfaces/ILateFeeCalc.sol"; */
/* import "../interfaces/ILoanFactory.sol"; */
/* import "../interfaces/IPremiumCalc.sol"; */
/* import "../interfaces/IRepaymentCalc.sol"; */
/* import "../interfaces/IUniswapRouter.sol"; */

/* import "../library/Util.sol"; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */

/// @title LoanLib is a library of utility functions used by Loan.
library LoanLib {

    using SafeMath  for uint256;
    using SafeERC20 for IERC20;

    address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /********************************/
    /*** Lender Utility Functions ***/
    /********************************/

    /**
        @dev    Performs sanity checks on the data passed in Loan constructor.
        @param  globals         Instance of a MapleGlobals.
        @param  liquidityAsset  Contract address of the Liquidity Asset.
        @param  collateralAsset Contract address of the Collateral Asset.
        @param  specs           Contains specifications for this Loan.
    */
    function loanSanityChecks(IMapleGlobals globals, address liquidityAsset, address collateralAsset, uint256[5] calldata specs) external view {
        require(globals.isValidLiquidityAsset(liquidityAsset),   "L:INVALID_LIQ_ASSET");
        require(globals.isValidCollateralAsset(collateralAsset), "L:INVALID_COL_ASSET");

        require(specs[2] != uint256(0),               "L:ZERO_PID");
        require(specs[1].mod(specs[2]) == uint256(0), "L:INVALID_TERM_DAYS");
        require(specs[3] > uint256(0),                "L:ZERO_REQUEST_AMT");
    }

    /**
        @dev    Returns capital to Lenders, if the Borrower has not drawn down the Loan past the grace period.
        @param  liquidityAsset IERC20 of the Liquidity Asset.
        @param  fundingLocker  Address of FundingLocker.
        @param  createdAt      Timestamp of Loan instantiation.
        @param  fundingPeriod  Duration of the funding period, after which funds can be reclaimed.
        @return excessReturned Amount of Liquidity Asset that was returned to the Loan from the FundingLocker.
    */
    function unwind(IERC20 liquidityAsset, address fundingLocker, uint256 createdAt, uint256 fundingPeriod) external returns (uint256 excessReturned) {
        // Only callable if Loan funding period has elapsed.
        require(block.timestamp > createdAt.add(fundingPeriod), "L:STILL_FUNDING_PERIOD");

        // Account for existing balance in Loan.
        uint256 preBal = liquidityAsset.balanceOf(address(this));

        // Drain funding from FundingLocker, transfers all the Liquidity Asset to this Loan.
        IFundingLocker(fundingLocker).drain();

        return liquidityAsset.balanceOf(address(this)).sub(preBal);
    }

    /**
        @dev    Liquidates a Borrower's collateral, via Uniswap, when a default is triggered. Only the Loan can call this function.
        @param  collateralAsset  IERC20 of the Collateral Asset.
        @param  liquidityAsset   Address of Liquidity Asset.
        @param  superFactory     Factory that instantiated Loan.
        @param  collateralLocker Address of CollateralLocker.
        @return amountLiquidated Amount of Collateral Asset that was liquidated.
        @return amountRecovered  Amount of Liquidity Asset that was returned to the Loan from the liquidation.
    */
    function liquidateCollateral(
        IERC20  collateralAsset,
        address liquidityAsset,
        address superFactory,
        address collateralLocker
    ) 
        external
        returns (
            uint256 amountLiquidated,
            uint256 amountRecovered
        ) 
    {
        // Get the liquidation amount from CollateralLocker.
        uint256 liquidationAmt = collateralAsset.balanceOf(address(collateralLocker));
        
        // Pull the Collateral Asset from CollateralLocker.
        ICollateralLocker(collateralLocker).pull(address(this), liquidationAmt);

        if (address(collateralAsset) == liquidityAsset || liquidationAmt == uint256(0)) return (liquidationAmt, liquidationAmt);

        collateralAsset.safeApprove(UNISWAP_ROUTER, uint256(0));
        collateralAsset.safeApprove(UNISWAP_ROUTER, liquidationAmt);

        IMapleGlobals globals = _globals(superFactory);

        // Get minimum amount of loan asset get after swapping collateral asset.
        uint256 minAmount = Util.calcMinAmount(globals, address(collateralAsset), liquidityAsset, liquidationAmt);

        // Generate Uniswap path.
        address uniswapAssetForPath = globals.defaultUniswapPath(address(collateralAsset), liquidityAsset);
        bool middleAsset = uniswapAssetForPath != liquidityAsset && uniswapAssetForPath != address(0);

        address[] memory path = new address[](middleAsset ? 3 : 2);

        path[0] = address(collateralAsset);
        path[1] = middleAsset ? uniswapAssetForPath : liquidityAsset;

        if (middleAsset) path[2] = liquidityAsset;

        // Swap collateralAsset for Liquidity Asset.
        uint256[] memory returnAmounts = IUniswapRouter(UNISWAP_ROUTER).swapExactTokensForTokens(
            liquidationAmt,
            minAmount.sub(minAmount.mul(globals.maxSwapSlippage()).div(10_000)),
            path,
            address(this),
            block.timestamp
        );

        return(returnAmounts[0], returnAmounts[path.length - 1]);
    }

    /**********************************/
    /*** Governor Utility Functions ***/
    /**********************************/

    /**
        @dev   Transfers any locked funds to the Governor. Only the Governor can call this function.
        @param token          Address of the token to be reclaimed.
        @param liquidityAsset Address of token that is used by the loan for drawdown and payments.
        @param globals        Instance of a MapleGlobals.
    */
    function reclaimERC20(address token, address liquidityAsset, IMapleGlobals globals) external {
        require(msg.sender == globals.governor(),               "L:NOT_GOV");
        require(token != liquidityAsset && token != address(0), "L:INVALID_TOKEN");
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    /**
        @dev    Returns if a default can be triggered.
        @param  nextPaymentDue     Timestamp of when payment is due.
        @param  defaultGracePeriod Amount of time after the next payment is due that a Borrower has before a liquidation can occur.
        @param  superFactory       Factory that instantiated Loan.
        @param  balance            LoanFDT balance of account trying to trigger a default.
        @param  totalSupply        Total supply of LoanFDT.
        @return Boolean indicating if default can be triggered.
    */
    function canTriggerDefault(uint256 nextPaymentDue, uint256 defaultGracePeriod, address superFactory, uint256 balance, uint256 totalSupply) external view returns (bool) {
        bool pastDefaultGracePeriod = block.timestamp > nextPaymentDue.add(defaultGracePeriod);

        // Check if the Loan is past the default grace period and that the account triggering the default has a percentage of total LoanFDTs
        // that is greater than the minimum equity needed (specified in globals)
        return pastDefaultGracePeriod && balance >= ((totalSupply * _globals(superFactory).minLoanEquity()) / 10_000);
    }

    /**
        @dev    Returns information on next payment amount.
        @param  repaymentCalc   Address of RepaymentCalc.
        @param  nextPaymentDue  Timestamp of when payment is due.
        @param  lateFeeCalc     Address of LateFeeCalc.
        @return total           Entitled total amount needed to be paid in the next payment (Principal + Interest only when the next payment is last payment of the Loan).
        @return principal       Entitled principal amount needed to be paid in the next payment.
        @return interest        Entitled interest amount needed to be paid in the next payment.
        @return _nextPaymentDue Payment Due Date.
        @return paymentLate     Whether payment is late.
    */
    function getNextPayment(
        address repaymentCalc,
        uint256 nextPaymentDue,
        address lateFeeCalc
    )
        external
        view
        returns (
            uint256 total,
            uint256 principal,
            uint256 interest,
            uint256 _nextPaymentDue,
            bool    paymentLate
        ) 
    {
        _nextPaymentDue  = nextPaymentDue;

        // Get next payment amounts from RepaymentCalc.
        (total, principal, interest) = IRepaymentCalc(repaymentCalc).getNextPayment(address(this));

        paymentLate = block.timestamp > _nextPaymentDue;

        // If payment is late, add late fees.
        if (paymentLate) {
            uint256 lateFee = ILateFeeCalc(lateFeeCalc).getLateFee(interest);
            
            total    = total.add(lateFee);
            interest = interest.add(lateFee);
        }
    }

    /**
        @dev    Returns information on full payment amount.
        @param  repaymentCalc   Address of RepaymentCalc.
        @param  nextPaymentDue  Timestamp of when payment is due.
        @param  lateFeeCalc     Address of LateFeeCalc.
        @param  premiumCalc     Address of PremiumCalc.
        @return total           Principal + Interest for the full payment.
        @return principal       Entitled principal amount needed to be paid in the full payment.
        @return interest        Entitled interest amount needed to be paid in the full payment.
    */
    function getFullPayment(
        address repaymentCalc,
        uint256 nextPaymentDue,
        address lateFeeCalc,
        address premiumCalc
    )
        external
        view
        returns (
            uint256 total,
            uint256 principal,
            uint256 interest
        ) 
    {
        (total, principal, interest) = IPremiumCalc(premiumCalc).getPremiumPayment(address(this));

        if (block.timestamp <= nextPaymentDue) return (total, principal, interest);

        // If payment is late, calculate and add late fees using interest amount from regular payment.
        (,, uint256 regInterest) = IRepaymentCalc(repaymentCalc).getNextPayment(address(this));

        uint256 lateFee = ILateFeeCalc(lateFeeCalc).getLateFee(regInterest);
        
        total    = total.add(lateFee);
        interest = interest.add(lateFee);
    }

    /**
        @dev    Calculates collateral required to drawdown amount.
        @param  collateralAsset IERC20 of the Collateral Asset.
        @param  liquidityAsset  IERC20 of the Liquidity Asset.
        @param  collateralRatio Percentage of drawdown value that must be posted as collateral.
        @param  superFactory    Factory that instantiated Loan.
        @param  amt             Drawdown amount.
        @return Amount of Collateral Asset required to post in CollateralLocker for given drawdown amount.
    */
    function collateralRequiredForDrawdown(
        IERC20Details collateralAsset,
        IERC20Details liquidityAsset,
        uint256 collateralRatio,
        address superFactory,
        uint256 amt
    ) 
        external
        view
        returns (uint256) 
    {
        IMapleGlobals globals = _globals(superFactory);

        uint256 wad = _toWad(amt, liquidityAsset);  // Convert to WAD precision.

        // Fetch current value of Liquidity Asset and Collateral Asset (Chainlink oracles provide 8 decimal precision).
        uint256 liquidityAssetPrice  = globals.getLatestPrice(address(liquidityAsset));
        uint256 collateralPrice = globals.getLatestPrice(address(collateralAsset));

        // Calculate collateral required.
        uint256 collateralRequiredUSD = wad.mul(liquidityAssetPrice).mul(collateralRatio).div(10_000);  // 18 + 8 = 26 decimals
        uint256 collateralRequiredWAD = collateralRequiredUSD.div(collateralPrice);                     // 26 - 8 = 18 decimals

        return collateralRequiredWAD.mul(10 ** collateralAsset.decimals()).div(10 ** 18);  // 18 + collateralAssetDecimals - 18 = collateralAssetDecimals
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    function _globals(address loanFactory) internal view returns (IMapleGlobals) {
        return IMapleGlobals(ILoanFactory(loanFactory).globals());
    }

    function _toWad(uint256 amt, IERC20Details liquidityAsset) internal view returns (uint256) {
        return amt.mul(10 ** 18).div(10 ** liquidityAsset.decimals());
    }
}