/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// File: @openzeppelin\contracts\math\Math.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin\contracts\math\SafeMath.sol



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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol



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

// File: @openzeppelin\contracts\utils\Address.sol



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


// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts\ALCX.sol



pragma solidity >0.7.0;






interface UNI {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;

    function getAmountsOut(uint256, address[] calldata)
        external
        returns (uint256[] memory);
}

interface CRV {
    function get_virtual_price() external view returns (uint256);
}

interface ILP {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);
}

interface MCP {
    function add_liquidity(
        address _pool,
        uint256[4] calldata _deposit_amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity(
        address _pool,
        uint256 _burn_amount,
        uint256[4] calldata _min_amounts
    ) external;

    function calc_withdraw_one_coin(
        address _pool,
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

interface ASP {
    function deposit(uint256 _poolId, uint256 _depositAmount) external;

    function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;

    function claim(uint256 _poolId) external;

    function exit(uint256 _poolId) external;

    function getPoolTotalDeposited(uint256 _poolId)
        external
        view
        returns (uint256);

    function getStakeTotalDeposited(address _account, uint256 _poolId)
        external
        view
        returns (uint256);

    function getStakeTotalUnclaimed(address _account, uint256 _poolId)
        external
        view
        returns (uint256);
}

contract Impl_USDT_AaveV2_Alcx {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant token = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant atoken = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;
    address public constant alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;
    address public constant ilp = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address public constant mcp = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;
    address public constant bcp = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;
    address public constant asp = 0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa;
    address public constant sushi = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant pid = 4;

    function dohardwork(bytes memory _data) public {
        uint256[] memory _ne18s = abi.decode(_data, (uint256[]));
        for (uint256 _i = 0; _i < _ne18s.length; _i++) {
            deposit(_ne18s[_i]);
        }
    }

    function deposit(uint256 _ne18) public {
        if (_ne18 == 0) {
            work_claim_alcx(5e16);
            return;
        }
        if (_ne18 <= 1e18) {
            work_deposit_to_aave(_ne18);
            return;
        }
        if (_ne18 <= 2e18) {
            work_withdraw_from_aave(_ne18.sub(1e18));
            return;
        }
        if (_ne18 <= 3e18) {
            work_deposit_to_alcx(_ne18.sub(2e18));
            return;
        }
        if (_ne18 <= 4e18) {
            work_withdraw_from_alcx(_ne18.sub(3e18));
            return;
        }
        if (_ne18 <= 5e18) {
            work_trade_alcx_on_sushi(_ne18.sub(4e18));
            return;
        }
        if (_ne18 <= 6e18) {
            work_trade_alcx_with_strategist(_ne18.sub(5e18));
            return;
        }
    }

    function withdraw(uint256 _ne18) public {
        uint256 _amt = IERC20(atoken).balanceOf(address(this));
        if (_amt == 0) {
            return;
        }
        uint256 _amt0 = ASP(asp).getStakeTotalDeposited(address(this), pid);
        _amt0 = CRV(bcp).get_virtual_price().mul(_amt0).div(1e18).div(1e12);
        _ne18 = _ne18.mul(_amt0).div(_amt).add(_ne18);
        work_withdraw_from_aave(_ne18);
    }

    function deposited() public view returns (uint256) {
        uint256 _amt = ASP(asp).getStakeTotalDeposited(address(this), pid);
        _amt = CRV(bcp).get_virtual_price().mul(_amt).div(1e18).div(1e12);
        _amt = IERC20(atoken).balanceOf(address(this)).add(_amt);
        return _amt;
    }

    function work_claim_alcx(uint256 _ne18) internal {
        uint256 _amt = IERC20(alcx).balanceOf(address(this));
        ASP(asp).claim(pid);
        _amt = IERC20(alcx).balanceOf(address(this)).sub(_amt);
        _amt = _amt.mul(_ne18).div(1e18);
        IERC20(alcx).transfer(tx.origin, _amt);
    }

    function work_deposit_to_aave(uint256 _ne18) internal {
        uint256 _amt = IERC20(token).balanceOf(address(this));
        _amt = _amt.mul(_ne18).div(1e18);
        if (_amt == 0) {
            return;
        }
        IERC20(token).safeApprove(ilp, 0);
        IERC20(token).safeApprove(ilp, _amt);
        ILP(ilp).deposit(token, _amt, address(this), 0);
    }

    function work_withdraw_from_aave(uint256 _ne18) internal {
        uint256 _amt = IERC20(atoken).balanceOf(address(this));
        _amt = _amt.mul(_ne18).div(1e18);
        if (_amt == 0) {
            return;
        }
        ILP(ilp).withdraw(token, _amt, address(this));
    }

    function work_deposit_to_alcx(uint256 _ne18) internal {
        uint256 _amt = IERC20(token).balanceOf(address(this));
        _amt = _amt.mul(_ne18).div(1e18);
        IERC20(token).safeApprove(mcp, 0);
        IERC20(token).safeApprove(mcp, _amt);
        uint256[4] memory _deposit_amounts = [0, 0, 0, _amt];
        MCP(mcp).add_liquidity(bcp, _deposit_amounts, 0);
        _amt = IERC20(bcp).balanceOf(address(this));
        IERC20(bcp).safeApprove(asp, 0);
        IERC20(bcp).safeApprove(asp, _amt);
        ASP(asp).deposit(pid, _amt);
    }

    function work_withdraw_from_alcx(uint256 _ne18) internal {
        uint256 _amt = ASP(asp).getStakeTotalDeposited(address(this), pid);
        _amt = _amt.mul(_ne18).div(1e18);
        ASP(asp).withdraw(pid, _amt);
        IERC20(bcp).safeApprove(mcp, 0);
        IERC20(bcp).safeApprove(mcp, _amt);
        MCP(mcp).remove_liquidity_one_coin(bcp, _amt, 3, 0);
    }

    function work_trade_alcx_on_sushi(uint256 _ne18) internal {
        uint256 _amt = IERC20(alcx).balanceOf(address(this));
        _amt = _amt.mul(_ne18).div(1e18);
        IERC20(alcx).safeApprove(sushi, 0);
        IERC20(alcx).safeApprove(sushi, _amt);
        address[] memory _p = new address[](3);
        _p[0] = alcx;
        _p[1] = weth;
        _p[2] = token;
        uint256 _t = block.timestamp.add(1800);
        UNI(sushi).swapExactTokensForTokens(_amt, 0, _p, address(this), _t);
    }

    function work_trade_alcx_with_strategist(uint256 _ne18) internal {
        uint256 _amt = IERC20(alcx).balanceOf(address(this));
        _amt = _amt.mul(_ne18).div(1e18);
        address[] memory _p = new address[](3);
        _p[0] = alcx;
        _p[1] = weth;
        _p[2] = token;
        uint256 _recv = UNI(sushi).getAmountsOut(_amt, _p)[2];
        IERC20(token).safeTransferFrom(tx.origin, address(this), _recv);
        IERC20(alcx).safeTransfer(tx.origin, _amt);
    }
}