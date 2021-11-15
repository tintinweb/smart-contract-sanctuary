// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



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

// File: openzeppelin-solidity/contracts/utils/Address.sol



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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol



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

// File: original_contracts/ITokenTransferProxy.sol

pragma solidity 0.7.5;


interface ITokenTransferProxy {

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external;
}

// File: original_contracts/lib/Utils.sol

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;





interface IERC20Permit {
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );
    
    uint256 constant MAX_UINT = type(uint256).max;

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee;
        Route[] route;
    }

    struct Route {
        uint256 index;//Adapter at which index needs to be used
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    function ethAddress() internal pure returns (address) {return ETH_ADDRESS;}

    function maxUint() internal pure returns (uint256) {return MAX_UINT;}

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    )
    internal
    {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{value: amount, gas: 10000}("");
                require(result, "Failed to transfer Ether");
            }
            else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }

    }

    function tokenBalance(
        address token,
        address account
    )
    internal
    view
    returns (uint256)
    {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(
        address token,
        bytes memory permit
    )
        internal
    {
        if (permit.length == 32 * 7) {
            (bool success,) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
        }
    }

}

// File: original_contracts/adapters/IAdapter.sol

pragma solidity 0.7.5;



interface IAdapter {

    /**
    * @dev Certain adapters needs to be initialized.
    * This method will be called from Augustus
    */
    function initialize(bytes calldata data) external;

    /**
   * @dev The function which performs the swap on an exchange.
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param networkFee Network fee to be used in this router
   * @param route Route to be followed
   */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    )
        external
        payable;
}

// File: original_contracts/lib/bancor/IBancor.sol

pragma solidity 0.7.5;



interface IBancor {

    function quickConvert(
        address[] calldata _path,
        uint256 _amount,
        uint256 _minReturn
    )
    external
    payable
    returns (uint256);

    function convert2(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
    external
    payable
    returns (uint256);

    function claimAndConvert2(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
    external
    returns (uint256);

    function claimAndConvertFor2(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
    external
    returns (uint256);

}

// File: original_contracts/lib/bancor/IContractRegistry.sol

pragma solidity 0.7.5;


interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);

}

// File: original_contracts/lib/bancor/Bancor.sol

pragma solidity 0.7.5;






contract Bancor {
    using SafeMath for uint256;

    struct BancorData {
        IERC20[] path;
    }

    bytes32 public constant BANCOR_NETWORK = 0x42616e636f724e6574776f726b00000000000000000000000000000000000000;

    address public immutable affiliateAccount;
    uint256 public immutable affiliateCode;

    constructor(
        address _affiliateAccount,
        uint256 _affiliateCode
    )
        public
    {
        affiliateAccount = _affiliateAccount;
        affiliateCode = _affiliateCode;
    }

    function swapOnBancor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address registry,
        bytes calldata payload
    )
        internal

    {
        BancorData memory data = abi.decode(payload, (BancorData));

        address bancorNetwork = IContractRegistry(registry).addressOf(
          BANCOR_NETWORK
        );

        _swapOnBancor(
            fromToken,
            toToken,
            fromAmount,
            1,
            data.path,
            bancorNetwork
        );
    }

    function _swapOnBancor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        IERC20[] memory path,
        address bancorNetwork
    )
      private
    {

      Utils.approve(bancorNetwork, address(fromToken), fromAmount);

      if (address(fromToken) == Utils.ethAddress()) {
          IBancor(bancorNetwork).convert2{value: fromAmount}(
              path,
              fromAmount,
              toAmount,
              affiliateAccount,
              affiliateCode
          );
      }
      else {
          IBancor(bancorNetwork).claimAndConvert2(
              path,
              fromAmount,
              toAmount,
              affiliateAccount,
              affiliateCode
          );
      }

    }
}

// File: original_contracts/lib/compound/ICompound.sol

pragma solidity 0.7.5;



abstract contract ICToken is IERC20 {
    function redeem(uint redeemTokens) external virtual returns (uint);

    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
}


abstract contract ICEther is ICToken {
    function mint() external virtual payable;
}


abstract contract ICERC20 is ICToken {
    function mint(uint mintAmount) external virtual returns (uint);

    function underlying() external virtual view returns (address token);
}

// File: original_contracts/lib/compound/Compound.sol

pragma solidity 0.7.5;




contract Compound {

    struct CompoundData {
        address cToken;
    }

    address public immutable ceth;

    constructor(address _ceth) public {
        ceth = _ceth;
    }

    function swapOnCompound(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
        internal

    {

        _swapOnCompound(
            fromToken,
            toToken,
            fromAmount,
            exchange,
            payload
        );
    }

    function buyOnCompound(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
        internal

    {

        _swapOnCompound(
            fromToken,
            toToken,
            fromAmount,
            exchange,
            payload
        );
    }

    function _swapOnCompound(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes memory payload) private {

        CompoundData memory compoundData = abi.decode(payload, (CompoundData));

        Utils.approve(
          address(compoundData.cToken),
          address(fromToken),
          fromAmount
        );

        if (address(fromToken) == address(compoundData.cToken)) {
            if (address(toToken) == Utils.ethAddress()) {
                require(
                    address(fromToken) == ceth,
                    "Invalid to token"
                );
            }
            else {
                require(
                    ICERC20(compoundData.cToken).underlying() == address(toToken),
                    "Invalid from token"
                );
            }

            ICToken(compoundData.cToken).redeem(fromAmount);
        }
        else if(address(toToken) == address(compoundData.cToken)) {
            if (address(fromToken) == Utils.ethAddress()) {
                require(
                    address(toToken) == ceth,
                    "Invalid to token"
                );

                ICEther(compoundData.cToken).mint{value: fromAmount}();
            }
            else {
                require(
                    ICERC20(compoundData.cToken).underlying() == address(fromToken),
                    "Invalid from token"
                );

                ICERC20(compoundData.cToken).mint(fromAmount);
            }
        }
        else {
            revert("Invalid token pair");
        }
    }
}

// File: original_contracts/lib/dodo/IDODO.sol

pragma solidity 0.7.5;

interface IDODO {
  function dodoSwapV1(
    address fromToken,
    address toToken,
    uint256 fromTokenAmount,
    uint256 minReturnAmount,
    address[] memory dodoPairs,
    uint256 directions,
    bool isIncentive,
    uint256 deadLine
    ) external payable returns (uint256 returnAmount);
}

// File: original_contracts/lib/dodo/DODO.sol

pragma solidity 0.7.5;




contract DODO {

  struct DODOData {
    address[] dodoPairs;
    uint256 directions;
  }

  address public immutable erc20ApproveProxy;
  uint256 public immutable dodoSwapLimitOverhead;

  constructor(address _erc20ApproveProxy, uint256 _swapLimitOverhead) public {
    dodoSwapLimitOverhead = _swapLimitOverhead;
    erc20ApproveProxy = _erc20ApproveProxy;
  }

  function swapOnDodo(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 fromAmount,
    address exchange,
    bytes calldata payload
  )
    internal
  {
    DODOData memory dodoData = abi.decode(payload, (DODOData));

    Utils.approve(erc20ApproveProxy, address(fromToken), fromAmount);

    IDODO(exchange).dodoSwapV1{
      value: address(fromToken) == Utils.ethAddress() ? fromAmount : 0
    }(
      address(fromToken),
      address(toToken),
      fromAmount,
      1,
      dodoData.dodoPairs,
      dodoData.directions,
      false,
      block.timestamp + dodoSwapLimitOverhead
    );
  }
}

// File: original_contracts/lib/kyber/IKyberNetwork.sol

pragma solidity 0.7.5;

interface IKyberNetwork {
    function maxGasPrice() external view returns(uint);

    function tradeWithHintAndFee(
        address src,
        uint256 srcAmount,
        address dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);
}

// File: original_contracts/lib/kyber/Kyber.sol

pragma solidity 0.7.5;




contract Kyber {

    struct KyberData {
        uint256 minConversionRateForBuy;
        bytes hint;
    }

    address payable public immutable _feeWallet;
    uint256 public immutable _platformFeeBps;

    constructor(
        address payable feeWallet,
        uint256 platformFeeBps
    )
        public
    {
        _feeWallet = feeWallet;
        _platformFeeBps = platformFeeBps;
    }

    function swapOnKyber(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address kyberAddress,
        bytes calldata payload
    )
        internal

    {
        KyberData memory data = abi.decode(payload, (KyberData));

        _swapOnKyber(
            address(fromToken),
            address(toToken),
            fromAmount,
            1,
            kyberAddress,
            data.hint,
            _feeWallet,
            _platformFeeBps
        );
    }

    function buyOnKyber(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address kyberAddress,
        bytes calldata payload
    )
        internal

    {
        KyberData memory data = abi.decode(payload, (KyberData));

        Utils.approve(address(kyberAddress), address(fromToken), fromAmount);

        if (address(fromToken) == Utils.ethAddress()) {
            IKyberNetwork(kyberAddress).tradeWithHintAndFee{value: fromAmount}(
                address(fromToken),
                fromAmount,
                address(toToken),
                payable(address(this)),
                toAmount,
                data.minConversionRateForBuy,
                _feeWallet,
                _platformFeeBps,
                data.hint
            );
        }
        else {
            IKyberNetwork(kyberAddress).tradeWithHintAndFee(
                address(fromToken),
                fromAmount,
                address(toToken),
                payable(address(this)),
                toAmount,
                data.minConversionRateForBuy,
                _feeWallet,
                _platformFeeBps,
                data.hint
            );
        }
    }

    function _swapOnKyber(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address kyberAddress,
        bytes memory hint,
        address payable _feeWallet,
        uint256 _platformFeeBps

    )
        private
        returns(uint256)
    {
        Utils.approve(kyberAddress, fromToken, fromAmount);

        uint256 receivedAmount = 0;

        if (fromToken == Utils.ethAddress()) {
            receivedAmount = IKyberNetwork(kyberAddress).tradeWithHintAndFee{value: fromAmount}(
                fromToken,
                fromAmount,
                toToken,
                payable(address(this)),
                Utils.maxUint(),
                toAmount,
                _feeWallet,
                _platformFeeBps,
                hint
            );
        }
        else {
            receivedAmount = IKyberNetwork(kyberAddress).tradeWithHintAndFee(
                fromToken,
                fromAmount,
                toToken,
                payable(address(this)),
                Utils.maxUint(),
                toAmount,
                _feeWallet,
                _platformFeeBps,
                hint
            );
        }
        return receivedAmount;
    }
}

// File: original_contracts/lib/shell/IShell.sol

pragma solidity 0.7.5;

interface IShell {
  function originSwap(
    address _origin,
    address _target,
    uint _originAmount,
    uint _minTargetAmount,
    uint _deadline
  ) external returns (uint targetAmount_);

  function targetSwap(
    address _origin,
    address _target,
    uint _maxOriginAmount,
    uint _targetAmount,
    uint _deadline
  ) external returns (uint originAmount_);
}

// File: original_contracts/AugustusStorage.sol

pragma solidity 0.7.5;


contract AugustusStorage {

    struct FeeStructure {
        uint256 partnerShare;
        bool noPositiveSlippage;
        bool positiveSlippageToUser;
        uint16 feePercent;
        string partnerId;
        bytes data;
    }

    ITokenTransferProxy internal tokenTransferProxy;
    address payable internal feeWallet;
    
    mapping(address => FeeStructure) internal registeredPartners;

    mapping (bytes4 => address) internal selectorVsRouter;
    mapping (bytes32 => bool) internal adapterInitialized;
    mapping (bytes32 => bytes) internal adapterVsData;

    mapping (bytes32 => bytes) internal routerData;
    mapping (bytes32 => bool) internal routerInitialized;


    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

}

// File: original_contracts/lib/shell/Shell.sol

pragma solidity 0.7.5;






contract Shell {
    using SafeMath for uint256;

    uint256 public immutable swapLimitOverhead;
    
    constructor(uint256 _swapLimitOverhead) public {
        swapLimitOverhead = _swapLimitOverhead;
    }

    function swapOnShell(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    )
        internal

    {
        Utils.approve(address(exchange), address(fromToken), fromAmount);

        IShell(exchange).originSwap(
            address(fromToken),
            address(toToken),
            fromAmount,
            1,
            block.timestamp + swapLimitOverhead
        );
    }

    function buyOnShell(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange
    )
        internal
    {
        Utils.approve(address(exchange), address(fromToken), fromAmount);

        IShell(exchange).targetSwap(
            address(fromToken),
            address(toToken),
            fromAmount,
            toAmount,
            block.timestamp + swapLimitOverhead
        );
    }
}

// File: original_contracts/lib/weth/IWETH.sol

pragma solidity 0.7.5;



abstract contract IWETH is IERC20 {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) external virtual;
}

// File: original_contracts/lib/WethProvider.sol

pragma solidity 0.7.5;


contract WethProvider {
    address public immutable WETH;

    constructor(address weth) public {
        WETH = weth;
    }
}

// File: original_contracts/lib/weth/WethExchange.sol

pragma solidity 0.7.5;






abstract contract WethExchange is WethProvider {

    function swapOnWETH(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    )
        internal

    {

        _swapOnWeth(
            fromToken,
            toToken,
            fromAmount
        );
    }

    function buyOnWeth(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    )
        internal

    {

        _swapOnWeth(
            fromToken,
            toToken,
            fromAmount
        );
    }

    function _swapOnWeth(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    )
        private
    {
        address weth = WETH;

        if (address(fromToken) == weth){
            require(address(toToken) == Utils.ethAddress(), "Destination token should be ETH");
            IWETH(weth).withdraw(fromAmount);
        }
        else if (address(fromToken) == Utils.ethAddress()) {
            require(address(toToken) == weth, "Destination token should be weth");
            IWETH(weth).deposit{value: fromAmount}();
        }
        else {
            revert("Invalid fromToken");
        }

    }

}

// File: original_contracts/lib/dodov2/IDODOV2Proxy.sol

pragma solidity 0.7.5;

interface IDODOV2Proxy {
    function dodoSwapV2ETHToToken(
        address toToken,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function dodoSwapV2TokenToETH(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);
}

// File: original_contracts/lib/dodov2/DODOV2.sol

pragma solidity 0.7.5;




contract DODOV2 {

  uint256 public immutable dodoV2SwapLimitOverhead;
  address public immutable dodoErc20ApproveProxy;

  struct DODOV2Data {
    address[] dodoPairs;
    uint256 directions;
  }

  constructor(uint256 _dodoV2SwapLimitOverhead, address _dodoErc20ApproveProxy) public {
    dodoV2SwapLimitOverhead = _dodoV2SwapLimitOverhead;
    dodoErc20ApproveProxy = _dodoErc20ApproveProxy;
  }

  function swapOnDodoV2(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 fromAmount,
    address exchange,
    bytes calldata payload
  )
    internal
  {
    DODOV2Data memory dodoData = abi.decode(payload, (DODOV2Data));

    if (address(fromToken) == Utils.ethAddress()) {
      IDODOV2Proxy(exchange).dodoSwapV2ETHToToken{value: fromAmount}(
        address(toToken),
        1,
        dodoData.dodoPairs,
        dodoData.directions,
        false,
        block.timestamp + dodoV2SwapLimitOverhead
      );
    } else if (address(toToken) == Utils.ethAddress()) {
      Utils.approve(dodoErc20ApproveProxy, address(fromToken), fromAmount);

      IDODOV2Proxy(exchange).dodoSwapV2TokenToETH(
        address(fromToken),
        fromAmount,
        1,
        dodoData.dodoPairs,
        dodoData.directions,
        false,
        block.timestamp + dodoV2SwapLimitOverhead
      );
    } else {
      Utils.approve(dodoErc20ApproveProxy, address(fromToken), fromAmount);

      IDODOV2Proxy(exchange).dodoSwapV2TokenToToken(
        address(fromToken),
        address(toToken),
        fromAmount,
        1,
        dodoData.dodoPairs,
        dodoData.directions,
        false,
        block.timestamp + dodoV2SwapLimitOverhead
      );
    }
  }
}

// File: original_contracts/lib/onebit/ISwapRouterOneBit.sol

pragma solidity 0.7.5;


interface ISwapRouterOneBit {
    function swapTokensWithTrust(
        IERC20 srcToken,
        IERC20 destToken,
        uint srcAmount,
        uint destAmountMin,
        address to
    ) external returns (uint destAmount);
}

// File: original_contracts/lib/onebit/OneBit.sol

pragma solidity 0.7.5;






abstract contract OneBit is WethProvider {

    function swapOnOneBit(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
        internal
    {

        address _fromToken = address(fromToken) == Utils.ethAddress()
        ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress()
        ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{value : fromAmount}();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ISwapRouterOneBit(exchange).swapTokensWithTrust(
            IERC20(_fromToken),
            IERC20(_toToken),
            fromAmount,
            1,
            address(this)
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(
                IERC20(WETH).balanceOf(address(this))
            );
        }

    }
}

// File: original_contracts/lib/saddle/ISwap.sol

pragma solidity 0.7.5;


interface ISwap {

  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  )
  external ;

}

// File: original_contracts/lib/saddle/SaddleAdapter.sol

pragma solidity 0.7.5;




contract SaddleAdapter {

  struct SaddleData {
    uint8 i;
    uint8 j;
    uint256 deadline;
  }

  function swapOnSaddle(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 fromAmount,
    address exchange,
    bytes calldata payload
  )
    internal
  {

    SaddleData memory data = abi.decode(payload, (SaddleData));

    Utils.approve(address(exchange), address(fromToken), fromAmount);

    ISwap(exchange).swap(data.i, data.j, fromAmount, 1, data.deadline);

  }
}

// File: original_contracts/adapters/mainnet/Adapter02.sol

pragma solidity 0.7.5;











/**
* @dev This contract will route to:
* 0- Bancor
* 1- Compound
* 2- Dodo
* 3- Kyber
* 4- Shell
* 5- weth
* 6- DODOV2
* 7- OneBit
* 8 -SaddelAdapter
* The above are the indexes
*/
contract Adapter02 is IAdapter, Bancor, Compound, DODO, Kyber, Shell, WethExchange, DODOV2, OneBit, SaddleAdapter {
    using SafeMath for uint256;

    struct Data {
        address _bancorAffiliateAccount;
        uint256 _bancorAffiliateCode;
        address _ceth;
        address _dodoErc20ApproveProxy;
        uint256 _dodSwapLimitOverhead;
        address payable _kyberFeeWallet;
        uint256 _kyberPlatformFeeBps;
        uint256 _shellSwapLimitOverhead;
        address _weth;
    }

    constructor(
        Data memory data
    )
        WethProvider(data._weth)
        Bancor(data._bancorAffiliateAccount, data._bancorAffiliateCode)
        Compound(data._ceth)
        DODO(data._dodoErc20ApproveProxy, data._dodSwapLimitOverhead)
        Kyber(data._kyberFeeWallet, data._kyberPlatformFeeBps)
        Shell(data._shellSwapLimitOverhead)
        DODOV2(data._dodSwapLimitOverhead, data._dodoErc20ApproveProxy)
        public
    {
    }

    function initialize(bytes calldata data) override external {
        revert("METHOD NOT IMPLEMENTED");
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    )
        external
        override
        payable
    {
        for (uint256 i = 0; i < route.length; i++) {
            if (route[i].index == 0) {
                //swap on Bancor
                swapOnBancor(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 1) {
                //swap on compound
                swapOnCompound(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 2) {
                //swap on DODO
                swapOnDodo(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 3) {
                //swap on kyber
                swapOnKyber(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 4) {
                //swap on Shell
                swapOnShell(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange
                );
            }
            else if (route[i].index == 5) {
                //swap on WETH
                swapOnWETH(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000)
                );
            }
            else if (route[i].index == 6) {
                //swap on DODOV2
                swapOnDodoV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 7) {
                //swap on OneBit
                swapOnOneBit(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 8) {
                //swap on Saddle
                swapOnSaddle(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else {
                revert("Index not supported");
            }
        }
    }
}

