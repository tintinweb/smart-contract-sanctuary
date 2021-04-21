/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;


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

// 
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

// 
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

// 
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

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

library ProtocolAdapterTypes {
    enum OptionType {Invalid, Put, Call}

    // We have 2 types of purchase methods so far - by contract and by 0x.
    // Contract is simple because it involves just specifying the option terms you want to buy.
    // ZeroEx involves an off-chain API call which prepares a ZeroExOrder object to be passed into the tx.
    enum PurchaseMethod {Invalid, Contract, ZeroEx}

    /**
     * @notice Terms of an options contract
     * @param underlying is the underlying asset of the options. E.g. For ETH $800 CALL, ETH is the underlying.
     * @param strikeAsset is the asset used to denote the asset paid out when exercising the option. E.g. For ETH $800 CALL, USDC is the underlying.
     * @param collateralAsset is the asset used to collateralize a short position for the option.
     * @param expiry is the expiry of the option contract. Users can only exercise after expiry in Europeans.
     * @param strikePrice is the strike price of an optio contract. E.g. For ETH $800 CALL, 800*10**18 is the USDC.
     * @param optionType is the type of option, can only be OptionType.Call or OptionType.Put
     * @param paymentToken is the token used to purchase the option. E.g. Buy UNI/USDC CALL with WETH as the paymentToken.
     */
    struct OptionTerms {
        address underlying;
        address strikeAsset;
        address collateralAsset;
        uint256 expiry;
        uint256 strikePrice;
        ProtocolAdapterTypes.OptionType optionType;
        address paymentToken;
    }

    /**
     * @notice 0x order for purchasing otokens
     * @param exchangeAddress [deprecated] is the address we call to conduct a 0x trade. Slither flagged this as a potential vulnerability so we hardcoded it.
     * @param buyTokenAddress is the otoken address
     * @param sellTokenAddress is the token used to purchase USDC. This is USDC most of the time.
     * @param allowanceTarget is the address the adapter needs to provide sellToken allowance to so the swap happens
     * @param protocolFee is the fee paid (in ETH) when conducting the trade
     * @param makerAssetAmount is the buyToken amount
     * @param takerAssetAmount is the sellToken amount
     * @param swapData is the encoded msg.data passed by the 0x api response
     */
    struct ZeroExOrder {
        address exchangeAddress;
        address buyTokenAddress;
        address sellTokenAddress;
        address allowanceTarget;
        uint256 protocolFee;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        bytes swapData;
    }
}

interface IProtocolAdapter {
    /**
     * @notice Emitted when a new option contract is purchased
     */
    event Purchased(
        address indexed caller,
        string indexed protocolName,
        address indexed underlying,
        uint256 amount,
        uint256 optionID
    );

    /**
     * @notice Emitted when an option contract is exercised
     */
    event Exercised(
        address indexed caller,
        address indexed options,
        uint256 indexed optionID,
        uint256 amount,
        uint256 exerciseProfit
    );

    /**
     * @notice Name of the adapter. E.g. "HEGIC", "OPYN_V1". Used as index key for adapter addresses
     */
    function protocolName() external pure returns (string memory);

    /**
     * @notice Boolean flag to indicate whether to use option IDs or not.
     * Fungible protocols normally use tokens to represent option contracts.
     */
    function nonFungible() external pure returns (bool);

    /**
     * @notice Returns the purchase method used to purchase options
     */
    function purchaseMethod()
        external
        pure
        returns (ProtocolAdapterTypes.PurchaseMethod);

    /**
     * @notice Check if an options contract exist based on the passed parameters.
     * @param optionTerms is the terms of the option contract
     */
    function optionsExist(ProtocolAdapterTypes.OptionTerms calldata optionTerms)
        external
        view
        returns (bool);

    /**
     * @notice Get the options contract's address based on the passed parameters
     * @param optionTerms is the terms of the option contract
     */
    function getOptionsAddress(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms
    ) external view returns (address);

    /**
     * @notice Gets the premium to buy `purchaseAmount` of the option contract in ETH terms.
     * @param optionTerms is the terms of the option contract
     * @param purchaseAmount is the number of options purchased
     */
    function premium(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 purchaseAmount
    ) external view returns (uint256 cost);

    /**
     * @notice Amount of profit made from exercising an option contract (current price - strike price). 0 if exercising out-the-money.
     * @param options is the address of the options contract
     * @param optionID is the ID of the option position in non fungible protocols like Hegic.
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     */
    function exerciseProfit(
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (uint256 profit);

    function canExercise(
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (bool);

    /**
     * @notice Purchases the options contract.
     * @param optionTerms is the terms of the option contract
     * @param amount is the purchase amount in Wad units (10**18)
     */
    function purchase(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 amount,
        uint256 maxCost
    ) external payable returns (uint256 optionID);

    /**
     * @notice Exercises the options contract.
     * @param options is the address of the options contract
     * @param optionID is the ID of the option position in non fungible protocols like Hegic.
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     * @param recipient is the account that receives the exercised profits. This is needed since the adapter holds all the positions and the msg.sender is an instrument contract.
     */
    function exercise(
        address options,
        uint256 optionID,
        uint256 amount,
        address recipient
    ) external payable;

    /**
     * @notice Opens a short position for a given `optionTerms`.
     * @param optionTerms is the terms of the option contract
     * @param amount is the short position amount
     */
    function createShort(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 amount
    ) external returns (uint256);

    /**
     * @notice Closes an existing short position. In the future, we may want to open this up to specifying a particular short position to close.
     */
    function closeShort() external returns (uint256);
}

library ProtocolAdapter {
    function delegateOptionsExist(
        IProtocolAdapter adapter,
        ProtocolAdapterTypes.OptionTerms calldata optionTerms
    ) external view returns (bool) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "optionsExist((address,address,address,uint256,uint256,uint8,address))",
                    optionTerms
                )
            );
        revertWhenFail(success, result);
        return abi.decode(result, (bool));
    }

    function delegateGetOptionsAddress(
        IProtocolAdapter adapter,
        ProtocolAdapterTypes.OptionTerms calldata optionTerms
    ) external view returns (address) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "getOptionsAddress((address,address,address,uint256,uint256,uint8,address))",
                    optionTerms
                )
            );
        revertWhenFail(success, result);
        return abi.decode(result, (address));
    }

    function delegatePremium(
        IProtocolAdapter adapter,
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 purchaseAmount
    ) external view returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "premium((address,address,address,uint256,uint256,uint8,address),uint256)",
                    optionTerms,
                    purchaseAmount
                )
            );
        revertWhenFail(success, result);
        return abi.decode(result, (uint256));
    }

    function delegateExerciseProfit(
        IProtocolAdapter adapter,
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "exerciseProfit(address,uint256,uint256)",
                    options,
                    optionID,
                    amount
                )
            );
        revertWhenFail(success, result);
        return abi.decode(result, (uint256));
    }

    function delegatePurchase(
        IProtocolAdapter adapter,
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 purchaseAmount,
        uint256 maxCost
    ) external returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "purchase((address,address,address,uint256,uint256,uint8,address),uint256,uint256)",
                    optionTerms,
                    purchaseAmount,
                    maxCost
                )
            );
        revertWhenFail(success, result);
        return abi.decode(result, (uint256));
    }

    function delegatePurchaseWithZeroEx(
        IProtocolAdapter adapter,
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        ProtocolAdapterTypes.ZeroExOrder calldata zeroExOrder
    ) external {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "purchaseWithZeroEx((address,address,address,uint256,uint256,uint8,address),(address,address,address,address,uint256,uint256,uint256,bytes))",
                    optionTerms,
                    zeroExOrder
                )
            );
        revertWhenFail(success, result);
    }

    function delegateExercise(
        IProtocolAdapter adapter,
        address options,
        uint256 optionID,
        uint256 amount,
        address recipient
    ) external {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "exercise(address,uint256,uint256,address)",
                    options,
                    optionID,
                    amount,
                    recipient
                )
            );
        revertWhenFail(success, result);
    }

    function delegateClaimRewards(
        IProtocolAdapter adapter,
        address rewardsAddress,
        uint256[] calldata optionIDs
    ) external returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "claimRewards(address,uint256[])",
                    rewardsAddress,
                    optionIDs
                )
            );
        revertWhenFail(success, result);
        return abi.decode(result, (uint256));
    }

    function delegateRewardsClaimable(
        IProtocolAdapter adapter,
        address rewardsAddress,
        uint256[] calldata optionIDs
    ) external view returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).staticcall(
                abi.encodeWithSignature(
                    "rewardsClaimable(address,uint256[])",
                    rewardsAddress,
                    optionIDs
                )
            );
        revertWhenFail(success, result);
        return abi.decode(result, (uint256));
    }

    function delegateCreateShort(
        IProtocolAdapter adapter,
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 amount
    ) external returns (uint256) {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "createShort((address,address,address,uint256,uint256,uint8,address),uint256)",
                    optionTerms,
                    amount
                )
            );
        revertWhenFail(success, result);
        return abi.decode(result, (uint256));
    }

    function delegateCloseShort(IProtocolAdapter adapter)
        external
        returns (uint256)
    {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature("closeShort()")
            );
        require(success, getRevertMsg(result));
        return abi.decode(result, (uint256));
    }

    function revertWhenFail(bool success, bytes memory returnData)
        private
        pure
    {
        if (success) return;
        revert(getRevertMsg(returnData));
    }

    function getRevertMsg(bytes memory _returnData)
        private
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "ProtocolAdapter: reverted";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

interface IRibbonFactory {
    function isInstrument(address instrument) external returns (bool);

    function getAdapter(string calldata protocolName)
        external
        view
        returns (address);

    function getAdapters()
        external
        view
        returns (address[] memory adaptersArray);

    function burnGasTokens() external;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

library Types {
    struct Order {
        uint256 nonce; // Unique per order and should be sequential
        uint256 expiry; // Expiry in seconds since 1 January 1970
        Party signer; // Party to the trade that sets terms
        Party sender; // Party to the trade that accepts terms
        Party affiliate; // Party compensated for facilitating (optional)
        Signature signature; // Signature of the order
    }

    struct Party {
        bytes4 kind; // Interface ID of the token
        address wallet; // Wallet address of the party
        address token; // Contract address of the token
        uint256 amount; // Amount for ERC-20 or ERC-1155
        uint256 id; // ID for ERC-721 or ERC-1155
    }

    struct Signature {
        address signatory; // Address of the wallet used to sign
        address validator; // Address of the intended swap contract
        bytes1 version; // EIP-191 signature version
        uint8 v; // `v` value of an ECDSA signature
        bytes32 r; // `r` value of an ECDSA signature
        bytes32 s; // `s` value of an ECDSA signature
    }
}

interface ISwap {
    event Swap(
        uint256 indexed nonce,
        uint256 timestamp,
        address indexed signerWallet,
        uint256 signerAmount,
        uint256 signerId,
        address signerToken,
        address indexed senderWallet,
        uint256 senderAmount,
        uint256 senderId,
        address senderToken,
        address affiliateWallet,
        uint256 affiliateAmount,
        uint256 affiliateId,
        address affiliateToken
    );

    event Cancel(uint256 indexed nonce, address indexed signerWallet);

    event CancelUpTo(uint256 indexed nonce, address indexed signerWallet);

    event AuthorizeSender(
        address indexed authorizerAddress,
        address indexed authorizedSender
    );

    event AuthorizeSigner(
        address indexed authorizerAddress,
        address indexed authorizedSigner
    );

    event RevokeSender(
        address indexed authorizerAddress,
        address indexed revokedSender
    );

    event RevokeSigner(
        address indexed authorizerAddress,
        address indexed revokedSigner
    );

    /**
     * @notice Atomic Token Swap
     * @param order Types.Order
     */
    function swap(Types.Order calldata order) external;

    /**
     * @notice Cancel one or more open orders by nonce
     * @param nonces uint256[]
     */
    function cancel(uint256[] calldata nonces) external;

    /**
     * @notice Cancels all orders below a nonce value
     * @dev These orders can be made active by reducing the minimum nonce
     * @param minimumNonce uint256
     */
    function cancelUpTo(uint256 minimumNonce) external;

    /**
     * @notice Authorize a delegated sender
     * @param authorizedSender address
     */
    function authorizeSender(address authorizedSender) external;

    /**
     * @notice Authorize a delegated signer
     * @param authorizedSigner address
     */
    function authorizeSigner(address authorizedSigner) external;

    /**
     * @notice Revoke an authorization
     * @param authorizedSender address
     */
    function revokeSender(address authorizedSender) external;

    /**
     * @notice Revoke an authorization
     * @param authorizedSigner address
     */
    function revokeSigner(address authorizedSigner) external;

    function senderAuthorizations(address, address)
        external
        view
        returns (bool);

    function signerAuthorizations(address, address)
        external
        view
        returns (bool);

    function signerNonceStatus(address, uint256) external view returns (bytes1);

    function signerMinimumNonce(address) external view returns (uint256);

    function registry() external view returns (address);
}

interface OtokenInterface {
    function addressBook() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

// 
/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// 
// solhint-disable-next-line compiler-version
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// 
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// 
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// 
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
library SafeMathUpgradeable {
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

contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    uint256[44] private __gap;
}


contract OptionsVaultStorageV1 is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    // DEPRECATED: This variable was originally used to store the asset address we are using as collateral
    // But due to gas optimization and upgradeability security concerns,
    // we removed it in favor of using immutable variables
    // This variable is left here to hold the storage slot for upgrades
    address private _oldAsset;

    // Privileged role that is able to select the option terms (strike price, expiry) to short
    address public manager;

    // Option that the vault is shorting in the next cycle
    address public nextOption;

    // The timestamp when the `nextOption` can be used by the vault
    uint256 public nextOptionReadyAt;

    // Option that the vault is currently shorting
    address public currentOption;

    // Amount that is currently locked for selling options
    uint256 public lockedAmount;

    // Cap for total amount deposited into vault
    uint256 public cap;

    // Fee incurred when withdrawing out of the vault, in the units of 10**18
    // where 1 ether = 100%, so 0.005 means 0.005% fee
    uint256 public instantWithdrawalFee;

    // Recipient for withdrawal fees
    address public feeRecipient;
}

contract OptionsVaultStorage is OptionsVaultStorageV1 {

}

// 
contract RibbonCoveredCall is DSMath, OptionsVaultStorage {
    using ProtocolAdapter for IProtocolAdapter;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string private constant _adapterName = "OPYN_GAMMA";

    IRibbonFactory public immutable factory;
    IProtocolAdapter public immutable adapter;
    address public immutable asset;
    address public immutable WETH;
    address public immutable USDC;
    uint8 private immutable _decimals;

    // AirSwap Swap contract https://github.com/airswap/airswap-protocols/blob/master/source/swap/contracts/interfaces/ISwap.sol
    ISwap public immutable SWAP_CONTRACT;

    // 90% locked in options protocol, 10% of the pool reserved for withdrawals
    uint256 public constant lockedRatio = 0.9 ether;

    uint256 public constant delay = 1 hours;

    uint256 public immutable MINIMUM_SUPPLY;

    event ManagerChanged(address oldManager, address newManager);

    event Deposit(address indexed account, uint256 amount, uint256 share);

    event Withdraw(
        address indexed account,
        uint256 amount,
        uint256 share,
        uint256 fee
    );

    event OpenShort(
        address indexed options,
        uint256 depositAmount,
        address manager
    );

    event CloseShort(
        address indexed options,
        uint256 withdrawAmount,
        address manager
    );

    event WithdrawalFeeSet(uint256 oldFee, uint256 newFee);

    event CapSet(uint256 oldCap, uint256 newCap, address manager);

    /**
     * @notice Initializes the factory and adapter contract addresses
     * It's important to bake the _factory variable into the contract with the constructor
     * If we do it in the `initialize` function, users get to set the factory variable and
     * subsequently the adapter, which allows them to make a delegatecall, then selfdestruct the contract.
     */
    constructor(
        address _asset,
        address _factory,
        address _weth,
        address _usdc,
        address _swapContract,
        uint8 _tokenDecimals,
        uint256 _minimumSupply
    ) {
        require(_asset != address(0), "!_asset");
        require(_factory != address(0), "!_factory");
        require(_weth != address(0), "!_weth");
        require(_usdc != address(0), "!_usdc");
        require(_swapContract != address(0), "!_swapContract");
        require(_tokenDecimals > 0, "!_tokenDecimals");
        require(_minimumSupply > 0, "!_minimumSupply");

        IRibbonFactory factoryInstance = IRibbonFactory(_factory);

        address adapterAddr = factoryInstance.getAdapter(_adapterName);
        require(adapterAddr != address(0), "Adapter not set");

        asset = _asset;
        factory = factoryInstance;
        adapter = IProtocolAdapter(adapterAddr);
        WETH = _weth;
        USDC = _usdc;
        SWAP_CONTRACT = ISwap(_swapContract);
        _decimals = _tokenDecimals;
        MINIMUM_SUPPLY = _minimumSupply;
    }

    /**
     * @notice Initializes the OptionVault contract with an owner and a factory.
     * @param _owner is the owner of the contract who can set the manager
     * @param _initCap is the initial vault's cap on deposits, the manager can increase this as necessary
     */
    function initialize(
        address _owner,
        address _feeRecipient,
        uint256 _initCap,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) external initializer {
        require(_owner != address(0), "!_owner");
        require(_feeRecipient != address(0), "!_feeRecipient");
        require(_initCap > 0, "_initCap > 0");
        require(bytes(_tokenName).length > 0, "_tokenName != 0x");
        require(bytes(_tokenSymbol).length > 0, "_tokenSymbol != 0x");

        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        transferOwnership(_owner);
        cap = _initCap;

        // hardcode the initial withdrawal fee
        instantWithdrawalFee = 0.005 ether;
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Sets the new manager of the vault.
     * @param newManager is the new manager of the vault
     */
    function setManager(address newManager) external onlyOwner {
        require(newManager != address(0), "!newManager");
        address oldManager = manager;
        manager = newManager;

        emit ManagerChanged(oldManager, newManager);
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "!newFeeRecipient");
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Sets the new withdrawal fee
     * @param newWithdrawalFee is the fee paid in tokens when withdrawing
     */
    function setWithdrawalFee(uint256 newWithdrawalFee) external onlyManager {
        require(newWithdrawalFee > 0, "withdrawalFee != 0");

        // cap max withdrawal fees to 100% of the withdrawal amount
        require(newWithdrawalFee < 1 ether, "withdrawalFee >= 100%");

        uint256 oldFee = instantWithdrawalFee;
        emit WithdrawalFeeSet(oldFee, newWithdrawalFee);

        instantWithdrawalFee = newWithdrawalFee;
    }

    /**
     * @notice Deposits ETH into the contract and mint vault shares. Reverts if the underlying is not WETH.
     */
    function depositETH() external payable nonReentrant {
        require(asset == WETH, "asset is not WETH");
        require(msg.value > 0, "No value passed");

        IWETH(WETH).deposit{value: msg.value}();
        _deposit(msg.value);
    }

    /**
     * @notice Deposits the `asset` into the contract and mint vault shares.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(amount);
    }

    /**
     * @notice Mints the vault shares to the msg.sender
     * @param amount is the amount of `asset` deposited
     */
    function _deposit(uint256 amount) private {
        uint256 totalWithDepositedAmount = totalBalance();
        require(totalWithDepositedAmount < cap, "Cap exceeded");

        // amount needs to be subtracted from totalBalance because it has already been
        // added to it from either IWETH.deposit and IERC20.safeTransferFrom
        uint256 total = totalWithDepositedAmount.sub(amount);

        uint256 shareSupply = totalSupply();

        // Following the pool share calculation from Alpha Homora: https://github.com/AlphaFinanceLab/alphahomora/blob/340653c8ac1e9b4f23d5b81e61307bf7d02a26e8/contracts/5/Bank.sol#L104
        uint256 share =
            shareSupply == 0 ? amount : amount.mul(shareSupply).div(total);

        require(
            shareSupply.add(share) >= MINIMUM_SUPPLY,
            "Minimum share supply needs to be >=10**10"
        );
        require(
            totalWithDepositedAmount >= MINIMUM_SUPPLY,
            "Minimum asset balance needs to be >=10**10"
        );

        emit Deposit(msg.sender, amount, share);

        _mint(msg.sender, share);
    }

    /**
     * @notice Withdraws ETH from vault using vault shares
     * @param share is the number of vault shares to be burned
     */
    function withdrawETH(uint256 share) external nonReentrant {
        require(asset == WETH, "!WETH");
        uint256 withdrawAmount = _withdraw(share);

        IWETH(WETH).withdraw(withdrawAmount);
        (bool success, ) = msg.sender.call{value: withdrawAmount}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @notice Withdraws WETH from vault using vault shares
     * @param share is the number of vault shares to be burned
     */
    function withdraw(uint256 share) external nonReentrant {
        uint256 withdrawAmount = _withdraw(share);
        IERC20(asset).safeTransfer(msg.sender, withdrawAmount);
    }

    /**
     * @notice Burns vault shares and checks if eligible for withdrawal
     * @param share is the number of vault shares to be burned
     */
    function _withdraw(uint256 share) private returns (uint256) {
        (uint256 amountAfterFee, uint256 feeAmount) =
            withdrawAmountWithShares(share);

        emit Withdraw(msg.sender, amountAfterFee, share, feeAmount);

        _burn(msg.sender, share);
        IERC20(asset).safeTransfer(feeRecipient, feeAmount);

        return amountAfterFee;
    }

    /**
     * @notice Sets the next option address and the timestamp at which the admin can call `rollToNextOption` to open a short for the option
     * @param optionTerms is the terms of the option contract
     */
    function setNextOption(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms
    ) external onlyManager nonReentrant {
        address option = adapter.getOptionsAddress(optionTerms);
        require(option != address(0), "!option");
        OtokenInterface otoken = OtokenInterface(option);
        require(otoken.underlyingAsset() == asset, "!asset");
        require(otoken.strikeAsset() == USDC, "strikeAsset != USDC"); // we just assume all options use USDC as the strike

        uint256 readyAt = block.timestamp.add(delay);
        require(
            otoken.expiryTimestamp() >= readyAt,
            "Option expiry cannot be before delay"
        );

        nextOption = option;
        nextOptionReadyAt = readyAt;
    }

    /**
     * @notice Rolls from one short option position to another. Closes the expired short position, withdraw from it, then open a new position.
     */
    function rollToNextOption() external onlyManager nonReentrant {
        address oldOption = currentOption;
        address newOption = nextOption;
        require(newOption != address(0), "No found option");
        require(block.timestamp > nextOptionReadyAt, "Delay not passed");

        nextOption = address(0);
        currentOption = newOption;

        if (oldOption != address(0)) {
            uint256 withdrawAmount = adapter.delegateCloseShort();
            emit CloseShort(oldOption, withdrawAmount, msg.sender);
        }
        uint256 currentBalance = IERC20(asset).balanceOf(address(this));
        uint256 shortAmount = wmul(currentBalance, lockedRatio);
        lockedAmount = shortAmount;

        OtokenInterface otoken = OtokenInterface(newOption);

        ProtocolAdapterTypes.OptionTerms memory optionTerms =
            ProtocolAdapterTypes.OptionTerms(
                asset,
                USDC,
                otoken.collateralAsset(),
                otoken.expiryTimestamp(),
                otoken.strikePrice().mul(10**10), // scale back to 10**18
                ProtocolAdapterTypes.OptionType.Call, // isPut
                address(0)
            );

        uint256 shortBalance =
            adapter.delegateCreateShort(optionTerms, shortAmount);
        IERC20 optionToken = IERC20(newOption);
        optionToken.safeApprove(address(SWAP_CONTRACT), shortBalance);

        emit OpenShort(newOption, shortAmount, msg.sender);
    }

    /**
     * @notice Withdraw from the options protocol by closing short in an event of a emergency
     */
    function emergencyWithdrawFromShort() external onlyManager nonReentrant {
        address oldOption = currentOption;
        require(oldOption != address(0), "!currentOption");

        currentOption = address(0);
        nextOption = address(0);
        lockedAmount = 0;

        uint256 withdrawAmount = adapter.delegateCloseShort();
        emit CloseShort(oldOption, withdrawAmount, msg.sender);
    }

    /**
     * @notice Performs a swap of `currentOption` token to `asset` token with a counterparty
     * @param order is an Airswap order
     */
    function sellOptions(Types.Order calldata order) external onlyManager {
        require(
            order.sender.wallet == address(this),
            "Sender can only be vault"
        );
        require(
            order.sender.token == currentOption,
            "Can only sell currentOption"
        );
        require(order.signer.token == asset, "Can only buy with asset token");

        SWAP_CONTRACT.swap(order);
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyManager {
        uint256 oldCap = cap;
        cap = newCap;
        emit CapSet(oldCap, newCap, msg.sender);
    }

    /**
     * @notice Returns the expiry of the current option the vault is shorting
     */
    function currentOptionExpiry() external view returns (uint256) {
        address _currentOption = currentOption;
        if (_currentOption == address(0)) {
            return 0;
        }

        OtokenInterface oToken = OtokenInterface(currentOption);
        return oToken.expiryTimestamp();
    }

    /**
     * @notice Returns the amount withdrawable (in `asset` tokens) using the `share` amount
     * @param share is the number of shares burned to withdraw asset from the vault
     * @return amountAfterFee is the amount of asset tokens withdrawable from the vault
     * @return feeAmount is the fee amount (in asset tokens) sent to the feeRecipient
     */
    function withdrawAmountWithShares(uint256 share)
        public
        view
        returns (uint256 amountAfterFee, uint256 feeAmount)
    {
        uint256 currentAssetBalance = assetBalance();
        (
            uint256 withdrawAmount,
            uint256 newAssetBalance,
            uint256 newShareSupply
        ) = _withdrawAmountWithShares(share, currentAssetBalance);

        require(
            withdrawAmount <= currentAssetBalance,
            "Cannot withdraw more than available"
        );

        require(
            newShareSupply >= MINIMUM_SUPPLY,
            "Minimum share supply needs to be >=10**10"
        );
        require(
            newAssetBalance >= MINIMUM_SUPPLY,
            "Minimum asset balance needs to be >=10**10"
        );

        feeAmount = wmul(withdrawAmount, instantWithdrawalFee);
        amountAfterFee = withdrawAmount.sub(feeAmount);
    }

    /**
     * @notice Helper function to return the `asset` amount returned using the `share` amount
     * @param share is the number of shares used to withdraw
     * @param currentAssetBalance is the value returned by totalBalance(). This is passed in to save gas.
     */
    function _withdrawAmountWithShares(
        uint256 share,
        uint256 currentAssetBalance
    )
        private
        view
        returns (
            uint256 withdrawAmount,
            uint256 newAssetBalance,
            uint256 newShareSupply
        )
    {
        uint256 total = lockedAmount.add(currentAssetBalance);

        uint256 shareSupply = totalSupply();

        // Following the pool share calculation from Alpha Homora: https://github.com/AlphaFinanceLab/alphahomora/blob/340653c8ac1e9b4f23d5b81e61307bf7d02a26e8/contracts/5/Bank.sol#L111
        withdrawAmount = share.mul(total).div(shareSupply);
        newAssetBalance = total.sub(withdrawAmount);
        newShareSupply = shareSupply.sub(share);
    }

    /**
     * @notice Returns the max withdrawable shares for all users in the vault
     */
    function maxWithdrawableShares() public view returns (uint256) {
        uint256 withdrawableBalance = assetBalance();
        uint256 total = lockedAmount.add(assetBalance());
        return
            withdrawableBalance.mul(totalSupply()).div(total).sub(
                MINIMUM_SUPPLY
            );
    }

    /**
     * @notice Returns the max amount withdrawable by an account using the account's vault share balance
     * @param account is the address of the vault share holder
     * @return amount of `asset` withdrawable from vault, with fees accounted
     */
    function maxWithdrawAmount(address account)
        external
        view
        returns (uint256)
    {
        uint256 maxShares = maxWithdrawableShares();
        uint256 share = balanceOf(account);
        uint256 numShares = min(maxShares, share);

        (uint256 withdrawAmount, ) = withdrawAmountWithShares(numShares);
        return withdrawAmount;
    }

    /**
     * @notice Returns the number of shares for a given `assetAmount`. Used by the frontend to calculate withdraw amounts.
     * @param assetAmount is the asset amount to be withdrawn
     * @return share amount
     */
    function assetAmountToShares(uint256 assetAmount)
        external
        view
        returns (uint256)
    {
        uint256 total = lockedAmount.add(assetBalance());
        return assetAmount.mul(totalSupply()).div(total);
    }

    /**
     * @notice Returns an account's balance on the vault
     * @param account is the address of the user
     * @return vault balance of the user
     */
    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        (uint256 withdrawAmount, , ) =
            _withdrawAmountWithShares(balanceOf(account), assetBalance());
        return withdrawAmount;
    }

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a short position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        return lockedAmount.add(IERC20(asset).balanceOf(address(this)));
    }

    /**
     * @notice Returns the asset balance on the vault. This balance is freely withdrawable by users.
     */
    function assetBalance() public view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Only allows manager to execute a function
     */
    modifier onlyManager {
        require(msg.sender == manager, "Only manager");
        _;
    }
}