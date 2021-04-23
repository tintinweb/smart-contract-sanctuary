/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/LoanFactory.sol
pragma solidity =0.6.11 >=0.6.7 >=0.6.0 <0.8.0 >=0.6.2 <0.8.0;

////// contracts/interfaces/ICollateralLocker.sol
/* pragma solidity 0.6.11; */

interface ICollateralLocker {
    function collateralAsset() external view returns (address);

    function loanVault() external view returns (address);

    function pull(address, uint256) external;
}

////// contracts/interfaces/ICollateralLockerFactory.sol
/* pragma solidity 0.6.11; */

interface ICollateralLockerFactory {
    function newLocker(address) external returns (address);

    function owner(address) external returns (address);
    
    function isLocker(address) external returns (bool);
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
    function fundingAsset() external view returns (address);

    function loanVault() external view returns (address);

    function pull(address, uint256) external;

    function drain() external;
}

////// contracts/interfaces/IFundingLockerFactory.sol
/* pragma solidity 0.6.11; */

interface IFundingLockerFactory {
    function newLocker(address) external returns (address);

    function owner(address) external returns (address);
    
    function isLocker(address) external returns (bool);
}

////// contracts/interfaces/IGlobals.sol
/* pragma solidity 0.6.11; */

interface IGlobals {
    function governor() external view returns (address);

    function admin() external view returns (address);

    function mpl() external view returns (address);

    function mapleTreasury() external view returns (address);

    function isExemptFromTransferRestriction(address) external view returns (bool);

    function isValidBalancerPool(address) external view returns (bool);

    function treasuryFee() external view returns (uint256);

    function investorFee() external view returns (uint256);

    function defaultGracePeriod() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function swapOutRequired() external view returns (uint256);

    function isValidLiquidityAsset(address) external view returns (bool);

    function isValidCollateralAsset(address) external view returns (bool);

    function isValidPoolDelegate(address) external view returns (bool);

    function validLiquidityAssets() external view returns (address[] memory);

    function validCollateralAssets() external view returns (address[] memory);

    function loanFactory() external view returns (address);

    function poolFactory() external view returns (address);

    function getPrice(address) external view returns (uint256);

    function isValidCalc(address, uint8) external view returns (bool);

    function isValidLoanFactory(address) external view returns (bool);

    function isValidSubFactory(address, address, uint8) external view returns (bool);

    function isValidPoolFactory(address) external view returns (bool);
    
    function getLatestPrice(address) external view returns (uint256);
    
    function defaultUniswapPath(address, address) external view returns (address);

    function minLoanEquity() external view returns (uint256);
    
    function maxSwapSlippage() external view returns (uint256);

    function protocolPaused() external view returns (bool);

    function stakerCooldownPeriod() external view returns(uint256);

    function lpCooldownPeriod() external view returns(uint256);

    function stakerUnstakeWindow() external view returns(uint256);

    function lpWithdrawWindow() external view returns(uint256);
}

////// contracts/interfaces/ILateFeeCalc.sol
/* pragma solidity 0.6.11; */

interface ILateFeeCalc {
    function getLateFee(uint256) external view returns (uint256);
} 

////// contracts/interfaces/ILiquidityLocker.sol
/* pragma solidity >=0.6.7; */

interface ILiquidityLocker {
    function fundLoan(address, address, uint256) external;

    function transfer(address, uint256) external;

    function pool() external view returns(address);
}

////// contracts/interfaces/ILoanFactory.sol
/* pragma solidity 0.6.11; */

interface ILoanFactory {
    function isLoan(address) external view returns (bool);

    function loans(uint256)  external view returns (address);

    function globals() external view returns (address);
    
    function createLoan(address, address, address, address, uint256[5] memory, address[3] memory) external returns (address);
}

////// contracts/interfaces/IPool.sol
/* pragma solidity 0.6.11; */

interface IPool {
    function poolDelegate() external view returns (address);

    function admins(address) external view returns (bool);

    function deposit(uint256) external;

    function transfer(address, uint256) external;

    function poolState() external view returns(uint256);

    function deactivate() external;

    function finalize() external;

    function claim(address, address) external returns(uint256[7] memory);

    function setLockupPeriod(uint256) external;
    
    function setStakingFee(uint256) external;

    function setAdmin(address, bool) external;

    function fundLoan(address, address, uint256) external;

    function withdraw(uint256) external;

    function superFactory() external view returns (address);
    
    function setAllowlistStakeLocker(address, bool) external;

    function claimableFunds(address) external view returns(uint256, uint256, uint256);

    function triggerDefault(address, address) external;

    function isPoolFinalized() external view returns(bool);

    function setOpenToPublic(bool) external;

    function setAllowList(address user, bool status) external;

    function allowedLiquidityProviders(address user) external view returns(bool);

    function openToPublic() external view returns(bool);

    function intendToWithdraw() external;
}

////// contracts/interfaces/IPoolFactory.sol
/* pragma solidity 0.6.11; */

interface IPoolFactory {
    function isPool(address) external view returns (bool);

    function createPool(address, address, address, address,uint256, uint256, uint256) external returns (address);

    function pools(uint256) external view returns (address);

    function globals() external view returns (address);
}

////// contracts/interfaces/IPremiumCalc.sol
/* pragma solidity 0.6.11; */

interface IPremiumCalc {
    function getPremiumPayment(address) external view returns (uint256, uint256, uint256);
} 

////// contracts/interfaces/IRepaymentCalc.sol
/* pragma solidity 0.6.11; */

interface IRepaymentCalc {
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
/* import "../interfaces/IGlobals.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */

/// @title Util is a library that contains utility functions.
library Util {

    using SafeMath for uint256;

    /**
        @dev Helper function for calculating min amount from a swap (adjustable for price slippage).
        @param globals   Interface of MapleGlobals
        @param fromAsset Address of ERC-20 that will be swapped
        @param toAsset   Address of ERC-20 that will returned from swap
        @param swapAmt   Amount of fromAsset to be swapped
        @return Expected amount of toAsset to receive from swap based on current oracle prices
    */
    function calcMinAmount(IGlobals globals, address fromAsset, address toAsset, uint256 swapAmt) public view returns(uint256) {
        return 
            swapAmt
                .mul(globals.getLatestPrice(fromAsset))           // Convert from "from" asset value
                .mul(10 ** IERC20Details(toAsset).decimals())     // Convert to "to" asset decimal precision
                .div(globals.getLatestPrice(toAsset))             // Convert to "to" asset value
                .div(10 ** IERC20Details(fromAsset).decimals());  // Convert from "from" asset decimal precision
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
/* import "../interfaces/IGlobals.sol"; */
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

    enum State { Ready, Active, Matured, Expired, Liquidated }

    address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /********************************/
    /*** Lender Utility Functions ***/
    /********************************/

    /**
        @dev If the borrower has not drawn down loan past grace period, return capital to lenders.
        @param liquidityAsset  IERC20 of the liquidityAsset
        @param superFactory    Factory that instantiated Loan
        @param fundingLocker   Address of FundingLocker
        @param createdAt       Timestamp of Loan instantiation
        @return excessReturned Amount of liquidityAsset that was returned to the Loan from the FundingLocker
    */
    function unwind(IERC20 liquidityAsset, address superFactory, address fundingLocker, uint256 createdAt) external returns(uint256 excessReturned) {
        IGlobals globals = _globals(superFactory);

        // Only callable if time has passed drawdown grace period, set in MapleGlobals
        require(block.timestamp > createdAt.add(globals.fundingPeriod()), "Loan:FUNDING_PERIOD_NOT_FINISHED");

        uint256 preBal = liquidityAsset.balanceOf(address(this));  // Account for existing balance in Loan

        // Drain funding from FundingLocker, transfers all liquidityAsset to this Loan
        IFundingLocker(fundingLocker).drain();

        // Update excessReturned accounting for claim()
        return liquidityAsset.balanceOf(address(this)).sub(preBal);
    }

    /**
        @dev Liquidate a Borrower's collateral via Uniswap when a default is triggered.
        @param collateralAsset   IERC20 of the collateralAsset
        @param liquidityAsset         Address of liquidityAsset
        @param superFactory      Factory that instantiated Loan
        @param collateralLocker  Address of CollateralLocker
        @return amountLiquidated Amount of collateralAsset that was liquidated
        @return amountRecovered  Amount of liquidityAsset that was returned to the Loan from the liquidation
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
        // Get liquidation amount from CollateralLocker
        uint256 liquidationAmt = collateralAsset.balanceOf(address(collateralLocker));
        
        // Pull collateralAsset from collateralLocker
        ICollateralLocker(collateralLocker).pull(address(this), liquidationAmt);

        if (address(collateralAsset) != liquidityAsset && liquidationAmt > uint256(0)) {
            collateralAsset.safeApprove(UNISWAP_ROUTER, uint256(0));
            collateralAsset.safeApprove(UNISWAP_ROUTER, liquidationAmt);

            IGlobals globals = _globals(superFactory);

            uint256 minAmount = Util.calcMinAmount(globals, address(collateralAsset), liquidityAsset, liquidationAmt);  // Minimum amount of loan asset get after swapping collateral asset

            // Generate path
            address uniswapAssetForPath = globals.defaultUniswapPath(address(collateralAsset), liquidityAsset);
            bool middleAsset = uniswapAssetForPath != liquidityAsset && uniswapAssetForPath != address(0);

            address[] memory path = new address[](middleAsset ? 3 : 2);

            path[0] = address(collateralAsset);
            path[1] = middleAsset ? uniswapAssetForPath : liquidityAsset;

            if (middleAsset) path[2] = liquidityAsset;

            // Swap collateralAsset for liquidityAsset
            uint256[] memory returnAmounts = IUniswapRouter(UNISWAP_ROUTER).swapExactTokensForTokens(
                liquidationAmt,
                minAmount.sub(minAmount.mul(globals.maxSwapSlippage()).div(10_000)),
                path,
                address(this),
                block.timestamp
            );

            amountLiquidated = returnAmounts[0];
            amountRecovered  = returnAmounts[path.length - 1];
        } else {
            amountLiquidated = liquidationAmt;
            amountRecovered  = liquidationAmt;
        }
    }

    /**********************************/
    /*** Governor Utility Functions ***/
    /**********************************/

    /**
        @dev Transfer any locked funds to the governor.
        @param token Address of the token that need to reclaimed.
        @param liquidityAsset Address of loan asset that is supported by the loan in other words denominated currency in which it taking funds.
        @param globals Instance of the `MapleGlobals` contract.
     */
    function reclaimERC20(address token, address liquidityAsset, IGlobals globals) external {
        require(msg.sender == globals.governor(), "Loan:UNAUTHORIZED");
        require(token != liquidityAsset && token != address(0), "Loan:INVALID_TOKEN");
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    /**
        @dev Determines if a default can be triggered.
        @param nextPaymentDue     Timestamp of when payment is due
        @param defaultGracePeriod Amount of time after `nextPaymentDue` that a borrower has before a liquidation can occur
        @param superFactory       Factory that instantiated Loan
        @param balance            LoanFDT balance of msg.sender
        @param totalSupply        LoanFDT totalSupply
        @return boolean indicating if default can be triggered
    */
    function canTriggerDefault(uint256 nextPaymentDue, uint256 defaultGracePeriod, address superFactory, uint256 balance, uint256 totalSupply) external view returns(bool) {

        bool pastDefaultGracePeriod = block.timestamp > nextPaymentDue.add(defaultGracePeriod);

        // Check if the loan is past the defaultGracePeriod and that msg.sender has a percentage of total LoanFDTs that is greater
        // than the minimum equity needed (specified in globals)
        return pastDefaultGracePeriod && balance >= totalSupply * _globals(superFactory).minLoanEquity() / 10_000;
    }

    /**
        @dev Returns information on next payment amount.
        @param superFactory     Factory that instantiated Loan
        @param repaymentCalc    Address of RepaymentCalc
        @param nextPaymentDue   Timestamp of when payment is due
        @param lateFeeCalc      Address of LateFeeCalc
        @return total           Entitiled interest to the next payment, Principal + Interest only when the next payment is last payment of the loan
        @return principal       Entitiled principal amount needs to pay in the next payment
        @return interest        Entitiled interest amount needs to pay in the next payment
        @return _nextPaymentDue Payment Due Date
        @return paymentLate     Boolean if payment is late
    */
    function getNextPayment(
        address superFactory,
        address repaymentCalc,
        uint256 nextPaymentDue,
        address lateFeeCalc
    ) 
        public
        view
        returns (
            uint256 total,
            uint256 principal,
            uint256 interest,
            uint256 _nextPaymentDue,
            bool    paymentLate
        ) 
    {
        IGlobals globals = _globals(superFactory);
        _nextPaymentDue  = nextPaymentDue;

        // Get next payment amounts from repayment calc
        (total, principal, interest) = IRepaymentCalc(repaymentCalc).getNextPayment(address(this));

        paymentLate = block.timestamp > _nextPaymentDue;

        // If payment is late, add late fees
        if (paymentLate) {
            uint256 lateFee = ILateFeeCalc(lateFeeCalc).getLateFee(interest);
            
            total    = total.add(lateFee);
            interest = interest.add(lateFee);
        }
    }

    /**
        @dev Helper for calculating collateral required to drawdown amt.
        @param collateralAsset IERC20 of the collateralAsset
        @param liquidityAsset  IERC20 of the liquidityAsset
        @param collateralRatio Percentage of drawdown value that must be posted as collateral
        @param superFactory    Factory that instantiated Loan
        @param amt             Drawdown amount
        @return Amount of collateralAsset required to post in CollateralLocker for given drawdown amt
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
        IGlobals globals = _globals(superFactory);

        uint256 wad = _toWad(amt, liquidityAsset);  // Convert to WAD precision

        // Fetch current value of liquidityAsset and collateralAsset (Chainlink oracles provide 8 decimal precision)
        uint256 liquidityAssetPrice  = globals.getLatestPrice(address(liquidityAsset));
        uint256 collateralPrice = globals.getLatestPrice(address(collateralAsset));

        // Calculate collateral required
        uint256 collateralRequiredUSD = wad.mul(liquidityAssetPrice).mul(collateralRatio).div(10_000); // 18 + 8 = 26 decimals
        uint256 collateralRequiredWAD = collateralRequiredUSD.div(collateralPrice);               // 26 - 8 = 18 decimals

        return collateralRequiredWAD.div(10 ** (18 - collateralAsset.decimals()));  // 18 - (18 - collateralDecimals) = collateralDecimals
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    function _globals(address loanFactory) internal view returns (IGlobals) {
        return IGlobals(ILoanFactory(loanFactory).globals());
    }

    function _toWad(uint256 amt, IERC20Details liquidityAsset) internal view returns(uint256) {
        return amt.mul(10 ** 18).div(10 ** liquidityAsset.decimals());
    }
}

////// contracts/math/SafeMathInt.sol
/* pragma solidity 0.6.11; */

library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

////// contracts/math/SafeMathUint.sol
/* pragma solidity 0.6.11; */

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

////// contracts/token/IFDT.sol
/* pragma solidity 0.6.11; */

interface IFDT {
    /**
        @dev Returns the total amount of funds a given address is able to withdraw currently.
        @param owner Address of FDT holder
        @return A uint256 representing the available funds for a given account
    */
    function withdrawableFundsOf(address owner) external view returns (uint256);

    /**
        @dev Withdraws all available funds for a FDT holder.
    */
    function withdrawFunds() external;

    /**
        @dev This event emits when new funds are distributed
        @param by the address of the sender who distributed funds
        @param fundsDistributed the amount of funds received for distribution
    */
    event FundsDistributed(address indexed by, uint256 fundsDistributed);

    /**
        @dev This event emits when distributed funds are withdrawn by a token holder.
        @param by the address of the receiver of funds
        @param fundsWithdrawn the amount of funds that were withdrawn
        @param totalWithdrawn the total amount of funds that were withdrawn
    */
    event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn, uint256 totalWithdrawn);
}

////// lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol

/* pragma solidity >=0.6.0 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/GSN/Context.sol

/* pragma solidity >=0.6.0 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/* import "../../GSN/Context.sol"; */
/* import "./IERC20.sol"; */
/* import "../../math/SafeMath.sol"; */

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

////// contracts/token/BasicFDT.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol"; */
/* import "./IFDT.sol"; */
/* import "../math/SafeMathUint.sol"; */
/* import "../math/SafeMathInt.sol"; */

/// @title BasicFDT implements base level FDT functionality for accounting for revenues
abstract contract BasicFDT is IFDT, ERC20 {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;

    uint256 internal constant pointsMultiplier = 2 ** 128;
    uint256 internal pointsPerShare;

    mapping(address => int256)  internal pointsCorrection;
    mapping(address => uint256) internal withdrawnFunds;

    event PointsPerShareUpdated(uint256 pointsPerShare);
    event PointsCorrectionUpdated(address account, int256 pointsCorrection);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) public { }

    /**
        @dev Distributes funds to token holders.
        @dev It reverts if the total supply of tokens is 0.
        It emits the `FundsDistributed` event if the amount of received ether is greater than 0.
        About undistributed funds:
            In each distribution, there is a small amount of funds which does not get distributed,
                which is `(value  pointsMultiplier) % totalSupply()`.
            With a well-chosen `pointsMultiplier`, the amount funds that are not getting distributed
                in a distribution can be less than 1 (base unit).
            We can actually keep track of the undistributed ether in a distribution
                and try to distribute it in the next distribution.
     */
    function _distributeFunds(uint256 value) internal {
        require(totalSupply() > 0, "FDT:SUPPLY_EQ_ZERO");

        if (value > 0) {
            pointsPerShare = pointsPerShare.add(value.mul(pointsMultiplier) / totalSupply());
            emit FundsDistributed(msg.sender, value);
            emit PointsPerShareUpdated(pointsPerShare);
        }
    }

    /**
        @dev Prepares funds withdrawal
        @dev It emits a `FundsWithdrawn` event if the amount of withdrawn ether is greater than 0.
    */
    function _prepareWithdraw() internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableFundsOf(msg.sender);

        withdrawnFunds[msg.sender] = withdrawnFunds[msg.sender].add(_withdrawableDividend);

        emit FundsWithdrawn(msg.sender, _withdrawableDividend, withdrawnFunds[msg.sender]);

        return _withdrawableDividend;
    }

    /**
        @dev View the amount of funds that an address can withdraw.
        @param _owner The address of a token holder.
        @return The amount funds that `_owner` can withdraw.
    */
    function withdrawableFundsOf(address _owner) public view override returns (uint256) {
        return accumulativeFundsOf(_owner).sub(withdrawnFunds[_owner]);
    }

    /**
        @dev View the amount of funds that an address has withdrawn.
        @param _owner The address of a token holder.
        @return The amount of funds that `_owner` has withdrawn.
    */
    function withdrawnFundsOf(address _owner) public view returns (uint256) {
        return withdrawnFunds[_owner];
    }

    /**
        @dev View the amount of funds that an address has earned in total.
        @dev accumulativeFundsOf(_owner) = withdrawableFundsOf(_owner) + withdrawnFundsOf(_owner)
        = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier
        @param _owner The address of a token holder.
        @return The amount of funds that `_owner` has earned in total.
    */
    function accumulativeFundsOf(address _owner) public view returns (uint256) {
        return
            pointsPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(pointsCorrection[_owner])
                .toUint256Safe() / pointsMultiplier;
    }

    /**
        @dev Internal function that transfer tokens from one address to another.
        Update pointsCorrection to keep funds unchanged.
        @param from  The address to transfer from.
        @param to    The address to transfer to.
        @param value The amount to be transferred.
    */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        super._transfer(from, to, value);

        int256 _magCorrection = pointsPerShare.mul(value).toInt256Safe();
        pointsCorrection[from] = pointsCorrection[from].add(_magCorrection);
        pointsCorrection[to] = pointsCorrection[to].sub(_magCorrection);

        emit PointsCorrectionUpdated(from, pointsCorrection[from]);
        emit PointsCorrectionUpdated(to,   pointsCorrection[to]);
    }

    /**
        @dev Internal function that mints tokens to an account.
        Update pointsCorrection to keep funds unchanged.
        @param account The account that will receive the created tokens.
        @param value   The amount that will be created.
    */
    function _mint(address account, uint256 value) internal virtual override {
        super._mint(account, value);

        pointsCorrection[account] = pointsCorrection[account].sub(
            (pointsPerShare.mul(value)).toInt256Safe()
        );

        emit PointsCorrectionUpdated(account, pointsCorrection[account]);
    }

    /**
        @dev Internal function that burns an amount of the token of a given account.
        Update pointsCorrection to keep funds unchanged.
        @param account The account whose tokens will be burnt.
        @param value   The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal virtual override {
        super._burn(account, value);

        pointsCorrection[account] = pointsCorrection[account].add(
            (pointsPerShare.mul(value)).toInt256Safe()
        );
        emit PointsCorrectionUpdated(account, pointsCorrection[account]);
    }

    /**
        @dev Withdraws all available funds for a token holder
    */
    function withdrawFunds() public virtual override {}

    /**
        @dev Updates the current funds token balance
        and returns the difference of new and previous funds token balances
        @return A int256 representing the difference of the new and previous funds token balance
    */
    function _updateFundsTokenBalance() internal virtual returns (int256) {}

    /**
        @dev Register a payment of funds in tokens. May be called directly after a deposit is made.
        @dev Calls _updateFundsTokenBalance(), whereby the contract computes the delta of the new and the previous
        funds token balance and increments the total received funds (cumulative) by delta by calling _registerFunds()
    */
    function updateFundsReceived() public virtual {
        int256 newFunds = _updateFundsTokenBalance();

        if (newFunds > 0) {
            _distributeFunds(newFunds.toUint256Safe());
        }
    }
}

////// contracts/token/FDT.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */

/* import "./BasicFDT.sol"; */

/// @title FDT inherits BasicFDT and uses the original ERC-2222 logic.
abstract contract FDT is BasicFDT {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;
    using SafeERC20      for  IERC20;

    IERC20 public immutable fundsToken;  // The fundsToken (dividends)

    uint256 public fundsTokenBalance;  // The amount of fundsToken (liquidityAsset) currently present and accounted for in this contract.

    constructor(string memory name, string memory symbol, address _fundsToken) BasicFDT(name, symbol) public {
        fundsToken = IERC20(_fundsToken);
    }

    /**
        @dev Withdraws all available funds for a token holder
    */
    function withdrawFunds() public virtual override {
        uint256 withdrawableFunds = _prepareWithdraw();

        if (withdrawableFunds > uint256(0)) {
            fundsToken.safeTransfer(msg.sender, withdrawableFunds);

            _updateFundsTokenBalance();
        }
    }

    /**
        @dev Updates the current funds token balance
        and returns the difference of new and previous funds token balances
        @return A int256 representing the difference of the new and previous funds token balance
    */
    function _updateFundsTokenBalance() internal virtual override returns (int256) {
        uint256 _prevFundsTokenBalance = fundsTokenBalance;

        fundsTokenBalance = fundsToken.balanceOf(address(this));

        return int256(fundsTokenBalance).sub(int256(_prevFundsTokenBalance));
    }
}

////// lib/openzeppelin-contracts/contracts/utils/Pausable.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/* import "../GSN/Context.sol"; */

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

////// contracts/Loan.sol
/* pragma solidity 0.6.11; */

/* import "./interfaces/ICollateralLocker.sol"; */
/* import "./interfaces/ICollateralLockerFactory.sol"; */
/* import "./interfaces/IERC20Details.sol"; */
/* import "./interfaces/IFundingLocker.sol"; */
/* import "./interfaces/IFundingLockerFactory.sol"; */
/* import "./interfaces/IGlobals.sol"; */
/* import "./interfaces/ILateFeeCalc.sol"; */
/* import "./interfaces/ILiquidityLocker.sol"; */
/* import "./interfaces/ILoanFactory.sol"; */
/* import "./interfaces/IPool.sol"; */
/* import "./interfaces/IPoolFactory.sol"; */
/* import "./interfaces/IPremiumCalc.sol"; */
/* import "./interfaces/IRepaymentCalc.sol"; */
/* import "./interfaces/IUniswapRouter.sol"; */
/* import "./library/Util.sol"; */
/* import "./library/LoanLib.sol"; */

/* import "./token/FDT.sol"; */

/* import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol"; */
/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */

/// @title Loan maintains all accounting and functionality related to Loans.
contract Loan is FDT, Pausable {

    using SafeMathInt     for int256;
    using SignedSafeMath  for int256;
    using SafeMath        for uint256;
    using SafeERC20       for IERC20;

    /**
        Ready      = The loan has been initialized and is ready for funding (assuming funding period hasn't ended)
        Active     = The loan has been drawdown and the borrower is making payments
        Matured    = The loan is fully paid off and has "matured"
        Expired    = The loan did not initiate, and all funding was returned to lenders
        Liquidated = The loan has been liquidated
    */
    enum State { Ready, Active, Matured, Expired, Liquidated }

    State public loanState;  // The current state of this loan, as defined in the State enum below

    IERC20 public immutable liquidityAsset;     // Asset deposited by lenders into the FundingLocker, when funding this loan
    IERC20 public immutable collateralAsset;    // Asset deposited by borrower into the CollateralLocker, for collateralizing this loan

    address public immutable fundingLocker;     // Funding locker - holds custody of loan funds before drawdown
    address public immutable flFactory;         // Funding locker factory
    address public immutable collateralLocker;  // Collateral locker - holds custody of loan collateral
    address public immutable clFactory;         // Collateral locker factory
    address public immutable borrower;          // Borrower of this loan, responsible for repayments
    address public immutable repaymentCalc;     // The repayment calculator for this loan
    address public immutable lateFeeCalc;       // The late fee calculator for this loan
    address public immutable premiumCalc;       // The premium calculator for this loan
    address public immutable superFactory;      // The factory that deployed this Loan

    mapping(address => bool) public admins;  // Admin addresses that have permission to do certain operations in case of disaster mgt

    uint256 public nextPaymentDue;  // The unix timestamp due date of next payment

    // Loan specifications
    uint256 public immutable apr;                     // APR in basis points
    uint256 public           paymentsRemaining;       // Number of payments remaining on the Loan
    uint256 public immutable termDays;                // Total length of the Loan term in days
    uint256 public immutable paymentIntervalSeconds;  // Time between Loan payments in seconds
    uint256 public immutable requestAmount;           // Total requested amount for Loan
    uint256 public immutable collateralRatio;         // Percentage of value of drawdown amount to post as collateral in basis points
    uint256 public immutable createdAt;               // Timestamp of when Loan was instantiated
    uint256 public immutable fundingPeriod;           // Time for a Loan to be funded in seconds
    uint256 public immutable defaultGracePeriod;      // Time a borrower has after a payment is due to make apayment before a liquidation can occur

    // Accounting variables
    uint256 public principalOwed;   // The principal owed (initially the drawdown amount)
    uint256 public principalPaid;   // Amount of principal  that has been paid by borrower since Loan instantiation
    uint256 public interestPaid;    // Amount of interest   that has been paid by borrower since Loan instantiation
    uint256 public feePaid;         // Amount of fees      that have been paid by borrower since Loan instantiation
    uint256 public excessReturned;  // Amount of excess that has been returned to lenders after Loan drawdown

    // Liquidation variables
    uint256 public amountLiquidated;   // Amount of collateral that has been liquidated after default
    uint256 public amountRecovered;    // Amount of liquidityAsset  that has been recovered  after default
    uint256 public defaultSuffered;    // Difference between `amountRecovered` and `principalOwed` after liquidation
    uint256 public liquidationExcess;  // If `amountRecovered > principalOwed`, amount of liquidityAsset that is to be returned to borrower

    event LoanFunded(uint256 amtFunded, address indexed _fundedBy);
    event BalanceUpdated(address who, address token, uint256 balance);
    event Drawdown(uint256 drawdownAmt);
    event LoanStateChanged(State state);
    event PaymentMade(
        uint totalPaid,
        uint principalPaid,
        uint interestPaid,
        uint paymentsRemaining,
        uint principalOwed,
        uint nextPaymentDue,
        bool latePayment
    );
    event Liquidation(
        uint collateralSwapped,
        uint liquidityAssetReturned,
        uint liquidationExcess,
        uint defaultSuffered
    );

    /**
        @dev Constructor for a Loan.
        @param  _borrower        Will receive the funding when calling `drawdown()`, is also responsible for repayments
        @param  _liquidityAsset  The asset, `borrower` is requesting funding in
        @param  _collateralAsset The asset provided as collateral by `borrower`
        @param  _flFactory       Factory to instantiate FundingLocker with
        @param  _clFactory       Factory to instantiate CollateralLocker with
        @param  specs            Contains specifications for this loan
                specs[0] = apr
                specs[1] = termDays
                specs[2] = paymentIntervalDays (aka PID)
                specs[3] = requestAmount
                specs[4] = collateralRatio
        @param  calcs The calculators used for the loan
                calcs[0] = repaymentCalc
                calcs[1] = lateFeeCalc
                calcs[2] = premiumCalc
    */
    constructor(
        address _borrower,
        address _liquidityAsset,
        address _collateralAsset,
        address _flFactory,
        address _clFactory,
        uint256[5] memory specs,
        address[3] memory calcs
    )
        FDT(
            string(abi.encodePacked("Maple Loan Token")),
            string(abi.encodePacked("MPL-LOAN")),
            _liquidityAsset
        )
        public
    {
        IGlobals globals = _globals(msg.sender);

        // Perform validity cross-checks
        require(globals.isValidLiquidityAsset(_liquidityAsset),   "Loan:INVALID_LIQUIDITY_ASSET");
        require(globals.isValidCollateralAsset(_collateralAsset), "Loan:INVALID_COLLATERAL_ASSET");

        require(specs[2] != uint256(0),               "Loan:PID_EQ_ZERO");
        require(specs[1].mod(specs[2]) == uint256(0), "Loan:INVALID_TERM_DAYS");
        require(specs[3] > uint256(0),                "Loan:REQUEST_AMT_EQ_ZERO");

        borrower        = _borrower;
        liquidityAsset  = IERC20(_liquidityAsset);
        collateralAsset = IERC20(_collateralAsset);
        flFactory       = _flFactory;
        clFactory       = _clFactory;
        createdAt       = block.timestamp;

        // Update state variables
        apr                    = specs[0];
        termDays               = specs[1];
        paymentsRemaining      = specs[1].div(specs[2]);
        paymentIntervalSeconds = specs[2].mul(1 days);
        requestAmount          = specs[3];
        collateralRatio        = specs[4];
        fundingPeriod          = globals.fundingPeriod();
        defaultGracePeriod     = globals.defaultGracePeriod();
        repaymentCalc          = calcs[0];
        lateFeeCalc            = calcs[1];
        premiumCalc            = calcs[2];
        superFactory           = msg.sender;

        // Deploy lockers
        collateralLocker = ICollateralLockerFactory(_clFactory).newLocker(_collateralAsset);
        fundingLocker    = IFundingLockerFactory(_flFactory).newLocker(_liquidityAsset);
        emit LoanStateChanged(State.Ready);
    }

    /**************************/
    /*** Borrower Functions ***/
    /**************************/

    /**
        @dev Drawdown funding from FundingLocker, post collateral, and transition loanState from `Ready` to `Active`.
        @param amt Amount of liquidityAsset borrower draws down, remainder is returned to Loan where it can be claimed back by LoanFDT holders.
    */
    function drawdown(uint256 amt) external {
        _whenProtocolNotPaused();
        _isValidBorrower();
        _isValidState(State.Ready);
        IGlobals globals = _globals(superFactory);

        IFundingLocker _fundingLocker = IFundingLocker(fundingLocker);

        require(amt >= requestAmount,              "Loan:AMT_LT_REQUEST_AMT");
        require(amt <= _getFundingLockerBalance(), "Loan:AMT_GT_FUNDED_AMT");

        // Update accounting variables for Loan
        principalOwed  = amt;
        nextPaymentDue = block.timestamp.add(paymentIntervalSeconds);

        loanState = State.Active;

        // Transfer the required amount of collateral for drawdown from Borrower to CollateralLocker.
        collateralAsset.safeTransferFrom(borrower, collateralLocker, collateralRequiredForDrawdown(amt));

        // Transfer funding amount from FundingLocker to Borrower, then drain remaining funds to Loan.
        uint256 treasuryFee = globals.treasuryFee();
        uint256 investorFee = globals.investorFee();

        address treasury = globals.mapleTreasury();

        uint256 _feePaid = feePaid = amt.mul(investorFee).div(10_000);  // Update fees paid for `claim()`
        uint256 treasuryAmt        = amt.mul(treasuryFee).div(10_000);  // Calculate amt to send to MapleTreasury

        _transferFunds(_fundingLocker, treasury, treasuryAmt);                         // Send `treasuryFee` directly to `MapleTreasury`
        _transferFunds(_fundingLocker, borrower, amt.sub(treasuryAmt).sub(_feePaid));  // Transfer drawdown amount to Borrower

        // Update excessReturned for claim()
        excessReturned = _getFundingLockerBalance().sub(_feePaid);

        // Drain remaining funds from FundingLocker (amount equal to excessReturned plus feePaid)
        _fundingLocker.drain();

        // Call updateFundsReceived() update FDT accounting with funds recieved from fees and excess returned
        updateFundsReceived();

        _emitBalanceUpdateEventForCollateralLocker();
        _emitBalanceUpdateEventForFundingLocker();
        _emitBalanceUpdateEventForLoan();

        emit BalanceUpdated(treasury, address(liquidityAsset), liquidityAsset.balanceOf(treasury));
        emit LoanStateChanged(State.Active);
        emit Drawdown(amt);
    }

    /**
        @dev Make a payment for the Loan. Amounts are calculated for the borrower.
    */
    function makePayment() external {
        _whenProtocolNotPaused();
        _isValidState(State.Active);
        (uint256 total, uint256 principal, uint256 interest,, bool paymentLate) = getNextPayment();
        paymentsRemaining--;
        _makePayment(total, principal, interest, paymentLate);
    }

    /**
        @dev Make the full payment for this loan, a.k.a. "calling" the loan. This requires the borrower to pay a premium fee.
    */
    function makeFullPayment() public {
        _whenProtocolNotPaused();
        _isValidState(State.Active);
        (uint256 total, uint256 principal, uint256 interest) = getFullPayment();
        paymentsRemaining = uint256(0);
        _makePayment(total, principal, interest, false);
    }

    /**
        @dev Internal function to update the payment variables and transfer funds from the borrower into the Loan.
    */
    function _makePayment(uint256 total, uint256 principal, uint256 interest, bool paymentLate) internal {

        // Caching to reduce `SLOADs`
        uint256 _paymentsRemaining = paymentsRemaining;

        // Update internal accounting variables
        interestPaid = interestPaid.add(interest);
        if (principal > uint256(0)) principalPaid = principalPaid.add(principal);

        if (_paymentsRemaining > uint256(0)) {
            // Update info related to next payment, decrement principalOwed if needed
            nextPaymentDue = nextPaymentDue.add(paymentIntervalSeconds);
            if (principal > uint256(0)) principalOwed = principalOwed.sub(principal);
        } else {
            // Update info to close loan
            principalOwed  = uint256(0);
            loanState      = State.Matured;
            nextPaymentDue = uint256(0);

            // Transfer all collateral back to the borrower
            ICollateralLocker(collateralLocker).pull(borrower, _getCollateralLockerBalance());
            _emitBalanceUpdateEventForCollateralLocker();
            emit LoanStateChanged(State.Matured);
        }

        // Loan payer sends funds to loan
        liquidityAsset.safeTransferFrom(msg.sender, address(this), total);

        // Call updateFundsReceived() update FDT accounting with funds recieved from interest payment
        updateFundsReceived();

        emit PaymentMade(
            total,
            principal,
            interest,
            _paymentsRemaining,
            principalOwed,
            _paymentsRemaining > 0 ? nextPaymentDue : 0,
            paymentLate
        );

        _emitBalanceUpdateEventForLoan();
    }

    /************************/
    /*** Lender Functions ***/
    /************************/

    /**
        @dev Fund this loan and mint LoanFDTs for mintTo (DebtLocker in the case of Pool funding)
        @param  amt    Amount to fund the loan
        @param  mintTo Address that LoanFDTs are minted to
    */
    function fundLoan(address mintTo, uint256 amt) whenNotPaused external {
        _whenProtocolNotPaused();
        _isValidState(State.Ready);
        _isValidPool();
        _isWithinFundingPeriod();
        liquidityAsset.safeTransferFrom(msg.sender, fundingLocker, amt);

        uint256 wad = _toWad(amt);  // Convert to WAD precision
        _mint(mintTo, wad);         // Mint FDT to `mintTo` i.e DebtLocker contract.

        emit LoanFunded(amt, mintTo);
        _emitBalanceUpdateEventForFundingLocker();
    }

    /**
        @dev If the borrower has not drawn down on the Loan past the drawdown grace period, return capital to Loan,
             where it can be claimed back by LoanFDT holders.
    */
    function unwind() external {
        _whenProtocolNotPaused();
        _isValidState(State.Ready);

        // Update accounting for claim(), transfer funds from FundingLocker to Loan
        excessReturned = LoanLib.unwind(liquidityAsset, superFactory, fundingLocker, createdAt);

        updateFundsReceived();

        // Transition state to Expired
        loanState = State.Expired;
        emit LoanStateChanged(State.Expired);
    }

    /**
        @dev Trigger a default if a Loan is in a condition where a default can be triggered, liquidating all collateral and updating accounting.
    */
    function triggerDefault() external {
        _whenProtocolNotPaused();
        _isValidState(State.Active);
        require(LoanLib.canTriggerDefault(nextPaymentDue, defaultGracePeriod, superFactory, balanceOf(msg.sender), totalSupply()), "Loan:FAILED_TO_LIQUIDATE");

        // Pull collateralAsset from CollateralLocker, swap to liquidityAsset, and hold custody of resulting liquidityAsset in Loan
        (amountLiquidated, amountRecovered) = LoanLib.liquidateCollateral(collateralAsset, address(liquidityAsset), superFactory, collateralLocker);

        // Decrement principalOwed by amountRecovered, set defaultSuffered to the difference (shortfall from liquidation)
        if (amountRecovered <= principalOwed) {
            principalOwed   = principalOwed.sub(amountRecovered);
            defaultSuffered = principalOwed;
        }
        // Set principalOwed to zero and return excess value from liquidation back to borrower
        else {
            liquidationExcess = amountRecovered.sub(principalOwed);
            principalOwed = 0;
            liquidityAsset.safeTransfer(borrower, liquidationExcess); // Send excess to Borrower
        }

        // Call updateFundsReceived() update FDT accounting with funds recieved from liquidation
        updateFundsReceived();

        // Transition loanState to Liquidated
        loanState = State.Liquidated;

        // Emit liquidation event
        emit Liquidation(
            amountLiquidated,  // Amount of collateralAsset swapped
            amountRecovered,   // Amount of liquidityAsset recovered from swap
            liquidationExcess, // Amount of liquidityAsset returned to borrower
            defaultSuffered    // Remaining losses after liquidation
        );
        emit LoanStateChanged(State.Liquidated);
    }

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    /**
        @dev Triggers paused state. Halts functionality for certain functions.
    */
    function pause() external {
        _isValidBorrowerOrAdmin();
        super._pause();
    }

    /**
        @dev Triggers unpaused state. Returns functionality for certain functions.
    */
    function unpause() external {
        _isValidBorrowerOrAdmin();
        super._unpause();
    }

    /**
        @dev Set admin.
        @param newAdmin New admin address
        @param allowed  Status of an admin
    */
    function setAdmin(address newAdmin, bool allowed) external {
        _whenProtocolNotPaused();
        _isValidBorrower();
        admins[newAdmin] = allowed;
    }

    /**************************/
    /*** Governor Functions ***/
    /**************************/

    /**
        @dev Transfer any locked funds to the governor.
        @param token Address of the token that need to reclaimed.
     */
    function reclaimERC20(address token) external {
        LoanLib.reclaimERC20(token, address(liquidityAsset), _globals(superFactory));
    }

    /*********************/
    /*** FDT Functions ***/
    /*********************/

    /**
        @dev Withdraws all available funds earned through FDT for a token holder.
    */
    function withdrawFunds() public override {
        _whenProtocolNotPaused();
        super.withdrawFunds();
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    /**
        @dev Public getter to know how much minimum amount of loan asset will get by swapping collateral asset.
        @return Expected amount of liquidityAsset to be recovered from liquidation based on current oracle prices
    */
    function getExpectedAmountRecovered() public view returns(uint256) {
        uint256 liquidationAmt = _getCollateralLockerBalance();
        return Util.calcMinAmount(_globals(superFactory), address(collateralAsset), address(liquidityAsset), liquidationAmt);
    }

    /**
        @dev Returns information on next payment amount.
        @return [0] = Entitiled interest to the next payment, Principal + Interest only when the next payment is last payment of the loan
                [1] = Entitiled principal amount needs to pay in the next payment
                [2] = Entitiled interest amount needs to pay in the next payment
                [3] = Payment Due Date
                [4] = Is Payment Late
    */
    function getNextPayment() public view returns(uint256, uint256, uint256, uint256, bool) {
        return LoanLib.getNextPayment(superFactory, repaymentCalc, nextPaymentDue, lateFeeCalc);
    }

    /**
        @dev Returns information on full payment amount.
        @return total     Principal and interest owed, combined
        @return principal Principal owed
        @return interest  Interest owed
    */
    function getFullPayment() public view returns(uint256 total, uint256 principal, uint256 interest) {
        (total, principal, interest) = IPremiumCalc(premiumCalc).getPremiumPayment(address(this));
    }

    /**
        @dev Helper for calculating collateral required to draw down amt.
        @param  amt The amount of liquidityAsset to draw down from FundingLocker
        @return The amount of collateralAsset required to post in CollateralLocker for given drawdown amt.
    */
    function collateralRequiredForDrawdown(uint256 amt) public view returns(uint256) {
        return LoanLib.collateralRequiredForDrawdown(
            IERC20Details(address(collateralAsset)),
            IERC20Details(address(liquidityAsset)),
            collateralRatio,
            superFactory,
            amt
        );
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    /**
        @dev Function to block functionality of functions when protocol is in a paused state.
    */
    function _whenProtocolNotPaused() internal {
        require(!_globals(superFactory).protocolPaused(), "Loan:PROTOCOL_PAUSED");
    }

    /**
        @dev Function to determine if msg.sender is eligible to trigger pause/unpause.
    */
    function _isValidBorrowerOrAdmin() internal {
        require(msg.sender == borrower || admins[msg.sender], "Pool:UNAUTHORIZED");
    }

    /**
        @dev Utility to convert to WAD precision.
    */
    function _toWad(uint256 amt) internal view returns(uint256) {
        return amt.mul(10 ** 18).div(10 ** IERC20Details(address(liquidityAsset)).decimals());
    }

    /**
        @dev Utility to return MapleGlobals interface.
    */
    function _globals(address loanFactory) internal view returns (IGlobals) {
        return IGlobals(ILoanFactory(loanFactory).globals());
    }

    /**
        @dev Utility to return CollateralLocker balance.
    */
    function _getCollateralLockerBalance() internal view returns (uint256) {
        return collateralAsset.balanceOf(collateralLocker);
    }

    /**
        @dev Utility to return FundingLocker balance.
    */
    function _getFundingLockerBalance() internal view returns (uint256) {
        return liquidityAsset.balanceOf(fundingLocker);
    }

    /**
        @dev Utility to check current state of Loan againt provided state.
        @param _state Enum of desired Loan state
    */
    function _isValidState(State _state) internal view {
        require(loanState == _state, "Loan:INVALID_STATE");
    }

    /**
        @dev Utility to return if msg.sender is the Loan borrower.
    */
    function _isValidBorrower() internal view {
        require(msg.sender == borrower, "Loan:INVALID_BORROWER");
    }

    /**
        @dev Utility to return if lender is using an approved Pool to fund the loan.
    */
    function _isValidPool() internal view {
        address pool        = ILiquidityLocker(msg.sender).pool();
        address poolFactory = IPool(pool).superFactory();
        require(
            _globals(superFactory).isValidPoolFactory(poolFactory) &&
            IPoolFactory(poolFactory).isPool(pool),
            "Loan:INVALID_LENDER"
        );
    }

    /**
        @dev Utility to ensure currently within the funding period.
    */
    function _isWithinFundingPeriod() internal view {
        require(block.timestamp <= createdAt.add(fundingPeriod), "Loan:PAST_FUNDING_PERIOD");
    }

    /**
        @dev Utility to transfer funds from the FundingLocker.
        @param from  Interface of the FundingLocker
        @param to    Address to send funds to
        @param value Amount to send
    */
    function _transferFunds(IFundingLocker from, address to, uint256 value) internal {
        from.pull(to, value);
    }

    /**
        @dev Utility to emit BalanceUpdated event for Loan.
    */
    function _emitBalanceUpdateEventForLoan() internal {
        emit BalanceUpdated(address(this), address(liquidityAsset), liquidityAsset.balanceOf(address(this)));
    }

    /**
        @dev Utility to emit BalanceUpdated event for FundingLocker.
    */
    function _emitBalanceUpdateEventForFundingLocker() internal {
        emit BalanceUpdated(fundingLocker, address(liquidityAsset), _getFundingLockerBalance());
    }

    /**
        @dev Utility to emit BalanceUpdated event for CollateralLocker.
    */
    function _emitBalanceUpdateEventForCollateralLocker() internal {
        emit BalanceUpdated(collateralLocker, address(collateralAsset), _getCollateralLockerBalance());
    }
}

////// contracts/LoanFactory.sol
/* pragma solidity 0.6.11; */

/* import "./Loan.sol"; */

/* import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol"; */

/// @title LoanFactory instantiates Loans.
contract LoanFactory is Pausable {

    using SafeMath for uint256;

    uint8 public constant CL_FACTORY = 0;  // Factory type of `CollateralLockerFactory`
    uint8 public constant FL_FACTORY = 2;  // Factory type of `FundingLockerFactory`

    uint8 public constant INTEREST_CALC_TYPE = 10;  // Calc type of `RepaymentCalc`
    uint8 public constant LATEFEE_CALC_TYPE  = 11;  // Calc type of `LateFeeCalc`
    uint8 public constant PREMIUM_CALC_TYPE  = 12;  // Calc type of `PremiumCalc`

    IGlobals public globals;  // Interface of MapleGlobals

    uint256 public loansCreated;  // Incrementor for number of loan vaults created.

    mapping(uint256 => address) public loans;   // Loans address mapping
    mapping(address => bool)    public isLoan;  // Used to check if a Loan was instantiated from this contract

    mapping(address => bool) public admins;  // Admin addresses that have permission to do certain operations in case of disaster mgt

    event LoanCreated(
        address loan,
        address indexed borrower,
        address indexed liquidityAsset,
        address collateralAsset,
        address collateralLocker,
        address fundingLocker,
        uint256[5] specs,
        address[3] calcs,
        string name,
        string symbol
    );

    constructor(address _globals) public {
        globals = IGlobals(_globals);
    }

    /**
        @dev Update the MapleGlobals contract
        @param newGlobals Address of new MapleGlobals contract
    */
    function setGlobals(address newGlobals) external {
        _isValidGovernor();
        globals = IGlobals(newGlobals);
    }

    /**
        @dev Create a new Loan.
        @param  liquidityAsset  Asset the loan will raise funding in
        @param  collateralAsset Asset the loan will use as collateral
        @param  flFactory       The factory to instantiate a FundingLocker from
        @param  clFactory       The factory to instantiate a CollateralLocker from
        @param  specs           Contains specifications for this loan
                specs[0] = apr
                specs[1] = termDays
                specs[2] = paymentIntervalDays
                specs[3] = requestAmount
                specs[4] = collateralRatio
        @param  calcs The calculators used for the loan.
                calcs[0] = repaymentCalc
                calcs[1] = lateFeeCalc
                calcs[2] = premiumCalc
        @return Address of the instantiated Loan.
    */
    function createLoan(
        address liquidityAsset,
        address collateralAsset,
        address flFactory,
        address clFactory,
        uint256[5] memory specs,
        address[3] memory calcs
    ) external whenNotPaused returns (address) {
        _whenProtocolNotPaused();
        IGlobals _globals = globals;

        // Validity checks
        require(_globals.isValidSubFactory(address(this), flFactory, FL_FACTORY), "LF:INVALID_FL_FACTORY");
        require(_globals.isValidSubFactory(address(this), clFactory, CL_FACTORY), "LF:INVALID_CL_FACTORY");

        require(_globals.isValidCalc(calcs[0], INTEREST_CALC_TYPE), "LF:INVALID_INTEREST_CALC");
        require(_globals.isValidCalc(calcs[1],  LATEFEE_CALC_TYPE), "LF:INVALID_LATE_FEE_CALC");
        require(_globals.isValidCalc(calcs[2],  PREMIUM_CALC_TYPE), "LF:INVALID_PREMIUM_CALC");

        // Deploy new Loan
        Loan loan = new Loan(
            msg.sender,
            liquidityAsset,
            collateralAsset,
            flFactory,
            clFactory,
            specs,
            calcs
        );

        // Update LoanFactory identification mappings
        loans[loansCreated]   = address(loan);
        isLoan[address(loan)] = true;
        loansCreated++;

        emit LoanCreated(
            address(loan),
            msg.sender,
            liquidityAsset,
            collateralAsset,
            loan.collateralLocker(),
            loan.fundingLocker(),
            specs,
            calcs,
            loan.name(),
            loan.symbol()
        );
        return address(loan);
    }

    /**
        @dev Set admin.
        @param newAdmin New admin address
        @param allowed  Status of an admin
    */
    function setAdmin(address newAdmin, bool allowed) external {
        _isValidGovernor();
        admins[newAdmin] = allowed;
    }

    /**
        @dev Triggers paused state. Halts functionality for certain functions. Only Governor can call this function.
    */
    function pause() external {
        _isValidGovernorOrAdmin();
        super._pause();
    }

    /**
        @dev Triggers unpaused state. Returns functionality for certain functions. Only Governor can call this function.
    */
    function unpause() external {
        _isValidGovernorOrAdmin();
        super._unpause();
    }

    /**
        @dev Function to determine if msg.sender is eligible to trigger pause/unpause.
    */
    function _isValidGovernor() internal view {
        require(msg.sender == globals.governor(), "PoolFactory:INVALID_GOVERNOR");
    }

    /**
        @dev Function to determine if msg.sender is eligible to trigger pause/unpause.
    */
    function _isValidGovernorOrAdmin() internal {
        require(msg.sender == globals.governor() || admins[msg.sender], "PoolFactory:UNAUTHORIZED");
    }

    /**
        @dev Function to determine if msg.sender is eligible to trigger pause/unpause.
    */
    function _whenProtocolNotPaused() internal {
        require(!globals.protocolPaused(), "PoolFactory:PROTOCOL_PAUSED");
    }
}