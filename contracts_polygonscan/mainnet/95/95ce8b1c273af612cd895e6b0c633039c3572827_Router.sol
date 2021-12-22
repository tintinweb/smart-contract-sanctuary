/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/PriceOracle.sol

pragma solidity ^0.8.4;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the price of a token
      * @param token The token to get the price of
      * @return The asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getTokenPrice(address token) external virtual view returns (uint);
}


// File @openzeppelin/contracts/utils/math/[email protected]


pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


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
    using Address for address;

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interfaces/IERC20Extended.sol

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Extended {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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


// File contracts/ConnextPriceOracle.sol

pragma solidity ^0.8.4;




interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract ConnextPriceOracle is PriceOracle {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Extended;
    address public admin;

    address public wrapped;

    /// @notice Chainlink Aggregators
    mapping(address => AggregatorV3Interface) public aggregators;    

    struct PriceInfo {
        address token;              // Address of token contract, TOKEN
        address baseToken;          // Address of base token contract, BASETOKEN
        address lpToken;            // Address of TOKEN-BASETOKEN pair contract
        bool active;                // Active status of price record 0 
    }

    mapping(address => PriceInfo) public priceRecords;
    mapping(address => uint256) public assetPrices;
    
    event NewAdmin(address oldAdmin, address newAdmin);
    event PriceRecordUpdated(address token, address baseToken, address lpToken, bool _active);
    event DirectPriceUpdated(address token, uint256 oldPrice, uint256 newPrice);
    event AggregatorUpdated(address tokenAddress, address source);

    constructor(address _wrapped) {
        wrapped = _wrapped;
        admin = msg.sender;
    }

    function getTokenPrice(address _tokenAddress) public view override returns (uint256) {
        address tokenAddress = _tokenAddress;
        if (_tokenAddress == address(0)) {
            tokenAddress = wrapped;
        }
        uint256 tokenPrice = assetPrices[tokenAddress];
        if (tokenPrice == 0) {
            tokenPrice = getPriceFromOracle(tokenAddress);
        }
        if (tokenPrice == 0) {
            tokenPrice = getPriceFromDex(tokenAddress);
        } 
        return tokenPrice;
    }

    function getPriceFromDex(address _tokenAddress) public view returns (uint256) {
        PriceInfo storage priceInfo = priceRecords[_tokenAddress];
        if (priceInfo.active) {
            uint256 rawTokenAmount = IERC20Extended(priceInfo.token).balanceOf(priceInfo.lpToken);
            uint256 tokenDecimalDelta = 18-uint256(IERC20Extended(priceInfo.token).decimals());
            uint256 tokenAmount = rawTokenAmount.mul(10**tokenDecimalDelta);
            uint256 rawBaseTokenAmount = IERC20Extended(priceInfo.baseToken).balanceOf(priceInfo.lpToken);
            uint256 baseTokenDecimalDelta = 18-uint256(IERC20Extended(priceInfo.baseToken).decimals());
            uint256 baseTokenAmount = rawBaseTokenAmount.mul(10**baseTokenDecimalDelta);
            uint256 baseTokenPrice = getPriceFromOracle(priceInfo.baseToken);
            uint256 tokenPrice = baseTokenPrice.mul(baseTokenAmount).div(tokenAmount);

            return tokenPrice;
        } else {
            return 0;
        }
    }

    function getPriceFromOracle(address _tokenAddress) public view returns (uint256) {
        uint256 chainLinkPrice = getPriceFromChainlink(_tokenAddress);
        return chainLinkPrice;
    }

    function getPriceFromChainlink(address _tokenAddress) public view returns (uint256) {
        AggregatorV3Interface aggregator = aggregators[_tokenAddress];
        if (address(aggregator) != address(0)) {
            ( , int answer, , , ) = aggregator.latestRoundData();

            // It's fine for price to be 0. We have two price feeds.
            if (answer == 0) {
                return 0;
            }

            // Extend the decimals to 1e18.
            uint retVal = uint(answer);
            uint price = retVal.mul(10**(18 - uint(aggregator.decimals())));

            return price;            
        }
        return 0;        
    }

    function setDexPriceInfo(address _token, address _baseToken, address _lpToken, bool _active) external {
        require(msg.sender == admin, "only admin can set DEX price");
        PriceInfo storage priceInfo = priceRecords[_token];
        uint256 baseTokenPrice = getPriceFromOracle(_baseToken);
        require(baseTokenPrice > 0, "invalid base token");
        priceInfo.token = _token;
        priceInfo.baseToken = _baseToken;
        priceInfo.lpToken = _lpToken;
        priceInfo.active = _active;
        emit PriceRecordUpdated(_token, _baseToken, _lpToken, _active);
    }

    function setDirectPrice(address _token, uint256 _price) external {
        require(msg.sender == admin, "only admin can set direct price");
        emit DirectPriceUpdated(_token, assetPrices[_token], _price);
        assetPrices[_token] = _price;
    }

    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "only admin can set new admin");
        address oldAdmin = admin;
        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    function setAggregators(address[] calldata tokenAddresses, address[] calldata sources) external {
        require(msg.sender == admin, "only the admin may set the aggregators");
        for (uint i = 0; i < tokenAddresses.length; i++) {
            aggregators[tokenAddresses[i]] = AggregatorV3Interface(sources[i]);
            emit AggregatorUpdated(tokenAddresses[i], sources[i]);
        }
    } 

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }    


}


// File contracts/interfaces/IFulfillInterpreter.sol

pragma solidity 0.8.4;

interface IFulfillInterpreter {

  event Executed(
    bytes32 indexed transactionId,
    address payable callTo,
    address assetId,
    address payable fallbackAddress,
    uint256 amount,
    bytes callData,
    bytes returnData,
    bool success,
    bool isContract
  );

  function getTransactionManager() external returns (address);

  function execute(
    bytes32 transactionId,
    address payable callTo,
    address assetId,
    address payable fallbackAddress,
    uint256 amount,
    bytes calldata callData
  ) external payable returns (bool success, bool isContract, bytes memory returnData);
}


// File contracts/lib/LibAsset.sol

pragma solidity 0.8.4;



/**
* @title LibAsset
* @author Connext <[email protected]>
* @notice This library contains helpers for dealing with onchain transfers
*         of assets, including accounting for the native asset `assetId`
*         conventions and any noncompliant ERC20 transfers
*/
library LibAsset {
  /** 
  * @dev All native assets use the empty address for their asset id
  *      by convention
  */
  address constant NATIVE_ASSETID = address(0);

  /** 
  * @notice Determines whether the given assetId is the native asset
  * @param assetId The asset identifier to evaluate
  * @return Boolean indicating if the asset is the native asset
  */
  function isNativeAsset(address assetId) internal pure returns (bool) {
    return assetId == NATIVE_ASSETID;
  }

  /** 
  * @notice Gets the balance of the inheriting contract for the given asset
  * @param assetId The asset identifier to get the balance of
  * @return Balance held by contracts using this library
  */
  function getOwnBalance(address assetId) internal view returns (uint256) {
    return
      isNativeAsset(assetId)
        ? address(this).balance
        : IERC20(assetId).balanceOf(address(this));
  }

  /** 
  * @notice Transfers ether from the inheriting contract to a given
  *         recipient
  * @param recipient Address to send ether to
  * @param amount Amount to send to given recipient
  */
  function transferNativeAsset(address payable recipient, uint256 amount)
      internal
  {
    Address.sendValue(recipient, amount);
  }

  /** 
  * @notice Transfers tokens from the inheriting contract to a given
  *         recipient
  * @param assetId Token address to transfer
  * @param recipient Address to send ether to
  * @param amount Amount to send to given recipient
  */
  function transferERC20(
      address assetId,
      address recipient,
      uint256 amount
  ) internal {
    SafeERC20.safeTransfer(IERC20(assetId), recipient, amount);
  }

  /** 
  * @notice Transfers tokens from a sender to a given recipient
  * @param assetId Token address to transfer
  * @param from Address of sender/owner
  * @param to Address of recipient/spender
  * @param amount Amount to transfer from owner to spender
  */
  function transferFromERC20(
    address assetId,
    address from,
    address to,
    uint256 amount
  ) internal {
    SafeERC20.safeTransferFrom(IERC20(assetId), from, to, amount);
  }

  /** 
  * @notice Increases the allowance of a token to a spender
  * @param assetId Token address of asset to increase allowance of
  * @param spender Account whos allowance is increased
  * @param amount Amount to increase allowance by
  */
  function increaseERC20Allowance(
    address assetId,
    address spender,
    uint256 amount
  ) internal {
    require(!isNativeAsset(assetId), "#IA:034");
    SafeERC20.safeIncreaseAllowance(IERC20(assetId), spender, amount);
  }

  /**
  * @notice Decreases the allowance of a token to a spender
  * @param assetId Token address of asset to decrease allowance of
  * @param spender Account whos allowance is decreased
  * @param amount Amount to decrease allowance by
  */
  function decreaseERC20Allowance(
    address assetId,
    address spender,
    uint256 amount
  ) internal {
    require(!isNativeAsset(assetId), "#DA:034");
    SafeERC20.safeDecreaseAllowance(IERC20(assetId), spender, amount);
  }

  /**
  * @notice Wrapper function to transfer a given asset (native or erc20) to
  *         some recipient. Should handle all non-compliant return value
  *         tokens as well by using the SafeERC20 contract by open zeppelin.
  * @param assetId Asset id for transfer (address(0) for native asset, 
  *                token address for erc20s)
  * @param recipient Address to send asset to
  * @param amount Amount to send to given recipient
  */
  function transferAsset(
      address assetId,
      address payable recipient,
      uint256 amount
  ) internal {
    isNativeAsset(assetId)
      ? transferNativeAsset(recipient, amount)
      : transferERC20(assetId, recipient, amount);
  }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/ReentrancyGuard.sol[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
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

    constructor() {
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
}


// File contracts/interpreters/FulfillInterpreter.sol

pragma solidity 0.8.4;





/**
  * @title FulfillInterpreter
  * @author Connext <[email protected]>
  * @notice This library contains an `execute` function that is callabale by
  *         an associated TransactionManager contract. This is used to execute
  *         arbitrary calldata on a receiving chain.
  */
contract FulfillInterpreter is ReentrancyGuard, IFulfillInterpreter {
  address private immutable _transactionManager;

  constructor(address transactionManager) {
    _transactionManager = transactionManager;
  }

  /**
  * @notice Errors if the sender is not the transaction manager
  */
  modifier onlyTransactionManager {
    require(msg.sender == _transactionManager, "#OTM:027");
    _;
  }

  /** 
    * @notice Returns the transaction manager address (only address that can 
    *         call the `execute` function)
    * @return The address of the associated transaction manager
    */
  function getTransactionManager() override external view returns (address) {
    return _transactionManager;
  }

  /** 
    * @notice Executes some arbitrary call data on a given address. The
    *         call data executes can be payable, and will have `amount` sent
    *         along with the function (or approved to the contract). If the
    *         call fails, rather than reverting, funds are sent directly to 
    *         some provided fallbaack address
    * @param transactionId Unique identifier of transaction id that necessitated
    *        calldata execution
    * @param callTo The address to execute the calldata on
    * @param assetId The assetId of the funds to approve to the contract or
    *                send along with the call
    * @param fallbackAddress The address to send funds to if the `call` fails
    * @param amount The amount to approve or send with the call
    * @param callData The data to execute
    */
  function execute(
    bytes32 transactionId,
    address payable callTo,
    address assetId,
    address payable fallbackAddress,
    uint256 amount,
    bytes calldata callData
  ) override external payable onlyTransactionManager returns (bool, bool, bytes memory) {
    // If it is not ether, approve the callTo
    // We approve here rather than transfer since many external contracts
    // simply require an approval, and it is unclear if they can handle 
    // funds transferred directly to them (i.e. Uniswap)
    bool isNative = LibAsset.isNativeAsset(assetId);
    if (!isNative) {
      LibAsset.increaseERC20Allowance(assetId, callTo, amount);
    }

    // Check if the callTo is a contract
    bool success;
    bytes memory returnData;
    bool isContract = Address.isContract(callTo);
    if (isContract) {
      // Try to execute the callData
      // the low level call will return `false` if its execution reverts
      (success, returnData) = callTo.call{value: isNative ? amount : 0}(callData);
    }

    // Handle failure cases
    if (!success) {
      // If it fails, transfer to fallback
      LibAsset.transferAsset(assetId, fallbackAddress, amount);
      // Decrease allowance
      if (!isNative) {
        LibAsset.decreaseERC20Allowance(assetId, callTo, amount);
      }
    }

    // Emit event
    emit Executed(
      transactionId,
      callTo,
      assetId,
      fallbackAddress,
      amount,
      callData,
      returnData,
      success,
      isContract
    );
    return (success, isContract, returnData);
  }
}


// File contracts/interfaces/ITransactionManager.sol

pragma solidity 0.8.4;

interface ITransactionManager {
  // Structs

  // Holds all data that is constant between sending and
  // receiving chains. The hash of this is what gets signed
  // to ensure the signature can be used on both chains.
  struct InvariantTransactionData {
    address receivingChainTxManagerAddress;
    address user;
    address router;
    address initiator; // msg.sender of sending side
    address sendingAssetId;
    address receivingAssetId;
    address sendingChainFallback; // funds sent here on cancel
    address receivingAddress;
    address callTo;
    uint256 sendingChainId;
    uint256 receivingChainId;
    bytes32 callDataHash; // hashed to prevent free option
    bytes32 transactionId;
  }

  // Holds all data that varies between sending and receiving
  // chains. The hash of this is stored onchain to ensure the
  // information passed in is valid.
  struct VariantTransactionData {
    uint256 amount;
    uint256 expiry;
    uint256 preparedBlockNumber;
  }

  // All Transaction data, constant and variable
  struct TransactionData {
    address receivingChainTxManagerAddress;
    address user;
    address router;
    address initiator; // msg.sender of sending side
    address sendingAssetId;
    address receivingAssetId;
    address sendingChainFallback;
    address receivingAddress;
    address callTo;
    bytes32 callDataHash;
    bytes32 transactionId;
    uint256 sendingChainId;
    uint256 receivingChainId;
    uint256 amount;
    uint256 expiry;
    uint256 preparedBlockNumber; // Needed for removal of active blocks on fulfill/cancel
  }

  // The structure of the signed data for fulfill
  struct SignedFulfillData {
    bytes32 transactionId;
    uint256 relayerFee;
    string functionIdentifier; // "fulfill" or "cancel"
    uint256 receivingChainId; // For domain separation
    address receivingChainTxManagerAddress; // For domain separation
  }

  // The structure of the signed data for cancellation
  struct SignedCancelData {
    bytes32 transactionId;
    string functionIdentifier;
    uint256 receivingChainId;
    address receivingChainTxManagerAddress; // For domain separation
  }

  /**
    * Arguments for calling prepare()
    * @param invariantData The data for a crosschain transaction that will
    *                      not change between sending and receiving chains.
    *                      The hash of this data is used as the key to store 
    *                      the inforamtion that does change between chains 
    *                      (amount,expiry,preparedBlock) for verification
    * @param amount The amount of the transaction on this chain
    * @param expiry The block.timestamp when the transaction will no longer be
    *               fulfillable and is freely cancellable on this chain
    * @param encryptedCallData The calldata to be executed when the tx is
    *                          fulfilled. Used in the function to allow the user
    *                          to reconstruct the tx from events. Hash is stored
    *                          onchain to prevent shenanigans.
    * @param encodedBid The encoded bid that was accepted by the user for this
    *                   crosschain transfer. It is supplied as a param to the
    *                   function but is only used in event emission
    * @param bidSignature The signature of the bidder on the encoded bid for
    *                     this transaction. Only used within the function for
    *                     event emission. The validity of the bid and
    *                     bidSignature are enforced offchain
    * @param encodedMeta The meta for the function
    */
  struct PrepareArgs {
    InvariantTransactionData invariantData;
    uint256 amount;
    uint256 expiry;
    bytes encryptedCallData;
    bytes encodedBid;
    bytes bidSignature;
    bytes encodedMeta;
  }

  /**
    * @param txData All of the data (invariant and variant) for a crosschain
    *               transaction. The variant data provided is checked against
    *               what was stored when the `prepare` function was called.
    * @param relayerFee The fee that should go to the relayer when they are
    *                   calling the function on the receiving chain for the user
    * @param signature The users signature on the transaction id + fee that
    *                  can be used by the router to unlock the transaction on 
    *                  the sending chain
    * @param callData The calldata to be sent to and executed by the 
    *                 `FulfillHelper`
    * @param encodedMeta The meta for the function
    */
  struct FulfillArgs {
    TransactionData txData;
    uint256 relayerFee;
    bytes signature;
    bytes callData;
    bytes encodedMeta;
  }

  /**
    * Arguments for calling cancel()
    * @param txData All of the data (invariant and variant) for a crosschain
    *               transaction. The variant data provided is checked against
    *               what was stored when the `prepare` function was called.
    * @param signature The user's signature that allows a transaction to be
    *                  cancelled by a relayer
    * @param encodedMeta The meta for the function
    */
  struct CancelArgs {
    TransactionData txData;
    bytes signature;
    bytes encodedMeta;
  }

  // Adding/removing asset events
  event RouterAdded(address indexed addedRouter, address indexed caller);

  event RouterRemoved(address indexed removedRouter, address indexed caller);

  // Adding/removing router events
  event AssetAdded(address indexed addedAssetId, address indexed caller);

  event AssetRemoved(address indexed removedAssetId, address indexed caller);

  // Liquidity events
  event LiquidityAdded(address indexed router, address indexed assetId, uint256 amount, address caller);

  event LiquidityRemoved(address indexed router, address indexed assetId, uint256 amount, address recipient);

  // Transaction events
  event TransactionPrepared(
    address indexed user,
    address indexed router,
    bytes32 indexed transactionId,
    TransactionData txData,
    address caller,
    PrepareArgs args
  );

  event TransactionFulfilled(
    address indexed user,
    address indexed router,
    bytes32 indexed transactionId,
    FulfillArgs args,
    bool success,
    bool isContract,
    bytes returnData,
    address caller
  );

  event TransactionCancelled(
    address indexed user,
    address indexed router,
    bytes32 indexed transactionId,
    CancelArgs args,
    address caller
  );

  // Getters
  function getChainId() external view returns (uint256);

  function getStoredChainId() external view returns (uint256);

  // Owner only methods
  function addRouter(address router) external;

  function removeRouter(address router) external;

  function addAssetId(address assetId) external;

  function removeAssetId(address assetId) external;

  // Router only methods
  function addLiquidityFor(uint256 amount, address assetId, address router) external payable;

  function addLiquidity(uint256 amount, address assetId) external payable;

  function removeLiquidity(
    uint256 amount,
    address assetId,
    address payable recipient
  ) external;

  // Methods for crosschain transfers
  // called in the following order (in happy case)
  // 1. prepare by user on sending chain
  // 2. prepare by router on receiving chain
  // 3. fulfill by user on receiving chain
  // 4. fulfill by router on sending chain
  function prepare(
    PrepareArgs calldata args
  ) external payable returns (TransactionData memory);

  function fulfill(
    FulfillArgs calldata args
  ) external returns (TransactionData memory);

  function cancel(CancelArgs calldata args) external returns (TransactionData memory);
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/Router.sol

pragma solidity ^0.8.4;




contract Router is Ownable {
  address public immutable routerFactory;

  ITransactionManager public transactionManager;

  uint256 private chainId;

  address public recipient;

  address public routerSigner;

  struct SignedPrepareData {
    ITransactionManager.PrepareArgs args;
    address routerRelayerFeeAsset;
    uint256 routerRelayerFee;
    uint256 chainId; // For domain separation
  }

  struct SignedFulfillData {
    ITransactionManager.FulfillArgs args;
    address routerRelayerFeeAsset;
    uint256 routerRelayerFee;
    uint256 chainId; // For domain separation
  }

  struct SignedCancelData {
    ITransactionManager.CancelArgs args;
    address routerRelayerFeeAsset;
    uint256 routerRelayerFee;
    uint256 chainId; // For domain separation
  }

  struct SignedRemoveLiquidityData {
    uint256 amount;
    address assetId;
    address routerRelayerFeeAsset;
    uint256 routerRelayerFee;
    uint256 chainId; // For domain separation
  }

  event RelayerFeeAdded(address assetId, uint256 amount, address caller);
  event RelayerFeeRemoved(address assetId, uint256 amount, address caller);
  event RemoveLiquidity(
    uint256 amount, 
    address assetId,
    address routerRelayerFeeAsset,
    uint256 routerRelayerFee, 
    address caller
  );
  event Prepare(
    ITransactionManager.InvariantTransactionData invariantData,
    address routerRelayerFeeAsset,
    uint256 routerRelayerFee,
    address caller
  );
  event Fulfill(
    ITransactionManager.TransactionData txData,
    address routerRelayerFeeAsset,
    uint256 routerRelayerFee,
    address caller
  );
  event Cancel(
    ITransactionManager.TransactionData txData,
    address routerRelayerFeeAsset,
    uint256 routerRelayerFee,
    address caller
  );

  constructor(address _routerFactory) {
    routerFactory = _routerFactory;
  }

  // Prevents from calling methods other than routerFactory contract
  modifier onlyViaFactory() {
    require(msg.sender == routerFactory, "ONLY_VIA_FACTORY");
    _;
  }

  function init(
    address _transactionManager,
    uint256 _chainId,
    address _routerSigner,
    address _recipient,
    address _owner
  ) external onlyViaFactory {
    transactionManager = ITransactionManager(_transactionManager);
    chainId = _chainId;
    routerSigner = _routerSigner;
    recipient = _recipient;
    transferOwnership(_owner);
  }

  function setRecipient(address _recipient) external onlyOwner {
    recipient = _recipient;
  }

  function setSigner(address _routerSigner) external onlyOwner {
    routerSigner = _routerSigner;
  }

  function addRelayerFee(uint256 amount, address assetId) external payable {
    // Sanity check: nonzero amounts
    require(amount > 0, "#RC_ARF:002");

    // Transfer funds to contract
    // Validate correct amounts are transferred
    if (LibAsset.isNativeAsset(assetId)) {
      require(msg.value == amount, "#RC_ARF:005");
    } else {
      require(msg.value == 0, "#RC_ARF:006");
      LibAsset.transferFromERC20(assetId, msg.sender, address(this), amount);
    }

    // Emit event
    emit RelayerFeeAdded(assetId, amount, msg.sender);
  }

  function removeRelayerFee(uint256 amount, address assetId) external onlyOwner {
    // Sanity check: nonzero amounts
    require(amount > 0, "#RC_RRF:002");

    // Transfer funds from contract
    LibAsset.transferAsset(assetId, payable(recipient), amount);

    // Emit event
    emit RelayerFeeRemoved(assetId, amount, msg.sender);
  }

  function removeLiquidity(
    uint256 amount,
    address assetId,
    address routerRelayerFeeAsset,
    uint256 routerRelayerFee,
    bytes calldata signature
  ) external {
    if (msg.sender != routerSigner) {
      SignedRemoveLiquidityData memory payload = SignedRemoveLiquidityData({
        amount: amount,
        assetId: assetId,
        routerRelayerFeeAsset: routerRelayerFeeAsset,
        routerRelayerFee: routerRelayerFee,
        chainId: chainId
      });

      address recovered = recoverSignature(abi.encode(payload), signature);
      require(recovered == routerSigner, "#RC_RL:040");

      // Send the relayer the fee
      if (routerRelayerFee > 0) {
        LibAsset.transferAsset(routerRelayerFeeAsset, payable(msg.sender), routerRelayerFee);
      }
    }

    emit RemoveLiquidity(amount, assetId, routerRelayerFeeAsset, routerRelayerFee, msg.sender);
    return transactionManager.removeLiquidity(amount, assetId, payable(recipient));
  }

  function prepare(
    ITransactionManager.PrepareArgs calldata args,
    address routerRelayerFeeAsset,
    uint256 routerRelayerFee,
    bytes calldata signature
  ) external payable returns (ITransactionManager.TransactionData memory) {
    if (msg.sender != routerSigner) {
      SignedPrepareData memory payload = SignedPrepareData({
        args: args,
        routerRelayerFeeAsset: routerRelayerFeeAsset,
        routerRelayerFee: routerRelayerFee,
        chainId: chainId
      });

      address recovered = recoverSignature(abi.encode(payload), signature);
      require(recovered == routerSigner, "#RC_P:040");

      // Send the relayer the fee
      if (routerRelayerFee > 0) {
        LibAsset.transferAsset(routerRelayerFeeAsset, payable(msg.sender), routerRelayerFee);
      }
    }

    emit Prepare(args.invariantData, routerRelayerFeeAsset, routerRelayerFee, msg.sender);
    return transactionManager.prepare(args);
  }

  function fulfill(
    ITransactionManager.FulfillArgs calldata args,
    address routerRelayerFeeAsset,
    uint256 routerRelayerFee,
    bytes calldata signature
  ) external returns (ITransactionManager.TransactionData memory) {
    if (msg.sender != routerSigner) {
      SignedFulfillData memory payload = SignedFulfillData({
        args: args,
        routerRelayerFeeAsset: routerRelayerFeeAsset,
        routerRelayerFee: routerRelayerFee,
        chainId: chainId
      });

      address recovered = recoverSignature(abi.encode(payload), signature);
      require(recovered == routerSigner, "#RC_F:040");

      // Send the relayer the fee
      if (routerRelayerFee > 0) {
        LibAsset.transferAsset(routerRelayerFeeAsset, payable(msg.sender), routerRelayerFee);
      }
    }
    emit Fulfill(args.txData, routerRelayerFeeAsset, routerRelayerFee, msg.sender);
    return transactionManager.fulfill(args);
  }

  function cancel(
    ITransactionManager.CancelArgs calldata args,
    address routerRelayerFeeAsset,
    uint256 routerRelayerFee,
    bytes calldata signature
  ) external returns (ITransactionManager.TransactionData memory) {
    if (msg.sender != routerSigner) {
      SignedCancelData memory payload = SignedCancelData({
        args: args,
        routerRelayerFeeAsset: routerRelayerFeeAsset,
        routerRelayerFee: routerRelayerFee,
        chainId: chainId
      });

      address recovered = recoverSignature(abi.encode(payload), signature);
      require(recovered == routerSigner, "#RC_C:040");

      // Send the relayer the fee
      if (routerRelayerFee > 0) {
        LibAsset.transferAsset(routerRelayerFeeAsset, payable(msg.sender), routerRelayerFee);
      }
    }
    emit Cancel(args.txData, routerRelayerFeeAsset, routerRelayerFee, msg.sender);
    return transactionManager.cancel(args);
  }

  /**
   * @notice Holds the logic to recover the routerSigner from an encoded payload.
   *         Will hash and convert to an eth signed message.
   * @param encodedPayload The payload that was signed
   * @param signature The signature you are recovering the routerSigner from
   */
  function recoverSignature(bytes memory encodedPayload, bytes calldata signature) internal pure returns (address) {
    // Recover
    return ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(encodedPayload)), signature);
  }

  receive() external payable {}
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}


// File contracts/interfaces/IRouterFactory.sol

pragma solidity ^0.8.4;

interface IRouterFactory {
  event RouterCreated(address router, address routerSigner, address recipient, address transactionManager);

  function getRouterAddress(address routerSigner) external view returns (address);

  function createRouter(address router, address recipient) external returns (address);
}


// File contracts/RouterFactory.sol

pragma solidity ^0.8.4;




contract RouterFactory is IRouterFactory, Ownable {
  /**
   * @dev The stored chain id of the contract, may be passed in to avoid any
   *      evm issues
   */
  uint256 private chainId;

  /**
   * @dev The transaction Manager contract
   */
  ITransactionManager public transactionManager;

  /**
   * @dev Mapping of routerSigner to created Router contract address
   */
  mapping(address => address) public routerAddresses;

  constructor(address _owner) {
    transferOwnership(_owner);
  }

  function init(address _transactionManager) external onlyOwner {
    require(address(_transactionManager) != address(0), "#RF_I:042");

    transactionManager = ITransactionManager(_transactionManager);
    chainId = ITransactionManager(_transactionManager).getChainId();
  }

  /**
   * @notice Allows us to create new router contract
   * @param routerSigner address router signer
   * @param recipient address recipient
   */

  function createRouter(address routerSigner, address recipient) external override returns (address) {
    require(address(transactionManager) != address(0), "#RF_CR:042");

    require(routerSigner != address(0), "#RF_CR:041");

    require(recipient != address(0), "#RF_CR:007");

    address payable router = payable(Create2.deploy(0, generateSalt(routerSigner), getBytecode()));
    Router(router).init(address(transactionManager), chainId, routerSigner, recipient, msg.sender);

    routerAddresses[routerSigner] = router;
    emit RouterCreated(router, routerSigner, recipient, address(transactionManager));
    return router;
  }

  /**
   * @notice Allows us to get the address for a new router contract created via `createRouter`
   * @param routerSigner address router signer
   */
  function getRouterAddress(address routerSigner) external view override returns (address) {
    return Create2.computeAddress(generateSalt(routerSigner), keccak256(getBytecode()));
  }

  ////////////////////////////////////////
  // Internal Methods

  function getBytecode() internal view returns (bytes memory) {
    bytes memory bytecode = type(Router).creationCode;
    return abi.encodePacked(bytecode, abi.encode(address(this)));
  }

  function generateSalt(address routerSigner) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(routerSigner));
  }
}


// File contracts/test/Counter.sol

pragma solidity 0.8.4;

contract Counter {
  bool public shouldRevert;
  uint256 public count = 0;

  constructor() {
    shouldRevert = false;
  }

  function setShouldRevert(bool value) public {
    shouldRevert = value;
  }

  function increment() public {
    require(!shouldRevert, "increment: shouldRevert is true");
    count += 1;
  }

  function incrementAndSend(address assetId, address recipient, uint256 amount) public payable {
    if (LibAsset.isNativeAsset(assetId)) {
      require(msg.value == amount, "incrementAndSend: INVALID_ETH_AMOUNT");
    } else {
      require(msg.value == 0, "incrementAndSend: ETH_WITH_ERC");
      LibAsset.transferFromERC20(assetId, msg.sender, address(this), amount);
    }
    increment();

    LibAsset.transferAsset(assetId, payable(recipient), amount);
  }
}


// File contracts/interfaces/IERC20Minimal.sol

pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;



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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/test/FeeERC20.sol

pragma solidity 0.8.4;

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 */
contract FeeERC20 is ERC20 {

  uint256 public fee = 1;

  constructor() ERC20("Fee Token", "FEERC20") {
    _mint(msg.sender, 1000000 ether);
  }

  function setFee(uint256 _fee) external {
    fee = _fee;
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }

  function transfer(address account, uint256 amount) public override returns (bool) {
    uint256 toTransfer = amount - fee;
    _transfer(msg.sender, account, toTransfer);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    uint256 toTransfer = amount - fee;
    _burn(sender, fee);
    _transfer(sender, recipient, toTransfer);
    return true;
  }
}


// File contracts/test/LibAssetTest.sol

pragma solidity 0.8.4;

/// @title LibAssetTest
/// @author Connext
/// @notice Used to easily test the internal methods of
///         LibAsset.sol by aliasing them to public
///         methods.

contract LibAssetTest {
  
  constructor() {}

  receive() external payable {}

  function isNativeAsset(address assetId) public pure returns (bool) {
    return LibAsset.isNativeAsset(assetId);
  }

  function getOwnBalance(address assetId) public view returns (uint256) {
    return LibAsset.getOwnBalance(assetId);
  }

  function transferNativeAsset(address payable recipient, uint256 amount) public {
    LibAsset.transferNativeAsset(recipient, amount);
  }

  function increaseERC20Allowance(address assetId, address spender, uint256 amount) public {
    LibAsset.increaseERC20Allowance(assetId, spender, amount);
  }

  function decreaseERC20Allowance(address assetId, address spender, uint256 amount) public {
    LibAsset.decreaseERC20Allowance(assetId, spender, amount);
  }

  function transferERC20(
    address assetId,
    address recipient,
    uint256 amount
  ) public {
    LibAsset.transferERC20(assetId, recipient, amount);
  }

  // This function is a wrapper for transfers of Ether or ERC20 tokens,
  // both standard-compliant ones as well as tokens that exhibit the
  // missing-return-value bug.
  function transferAsset(
    address assetId,
    address payable recipient,
    uint256 amount
  ) public {
    LibAsset.transferAsset(assetId, recipient, amount);
  }
}


// File contracts/test/RevertableERC20.sol

pragma solidity 0.8.4;

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 */
contract RevertableERC20 is ERC20 {

  bool public shouldRevert = false;

  constructor() ERC20("Revertable Token", "RVRT") {
    _mint(msg.sender, 1000000 ether);
  }

  function mint(address account, uint256 amount) external {
     require(!shouldRevert, "mint: SHOULD_REVERT");
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    require(!shouldRevert, "burn: SHOULD_REVERT");
    _burn(account, amount);
  }

  function transfer(address account, uint256 amount) public override returns (bool) {
    require(!shouldRevert, "transfer: SHOULD_REVERT");
    _transfer(msg.sender, account, amount);
    return true;
  }

  function setShouldRevert(bool _shouldRevert) external {
    shouldRevert = _shouldRevert;
  }
}


// File contracts/test/TestERC20.sol

pragma solidity 0.8.4;

/* This token is ONLY useful for testing
 * Anybody can mint as many tokens as they like
 * Anybody can burn anyone else's tokens
 */
contract TestERC20 is ERC20 {
    constructor() ERC20("Test Token", "TEST") {
        _mint(msg.sender, 1000000 ether);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}


// File contracts/ProposedOwnable.sol

pragma solidity 0.8.4;

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism, 
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the 
 * modifier `onlyOwner`, which can be applied to your functions to restrict 
 * their use to the owner.
 * 
 * @dev The majority of this code was taken from the openzeppelin Ownable 
 * contract
 *
 */
abstract contract ProposedOwnable {
  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  bool private _routerOwnershipRenounced;
  uint256 private _routerOwnershipTimestamp;

  bool private _assetOwnershipRenounced;
  uint256 private _assetOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  event RouterOwnershipRenunciationProposed(uint256 timestamp);

  event RouterOwnershipRenounced(bool renounced);

  event AssetOwnershipRenunciationProposed(uint256 timestamp);

  event AssetOwnershipRenounced(bool renounced);

  event OwnershipProposed(address indexed proposedOwner);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
    * @notice Initializes the contract setting the deployer as the initial 
    * owner.
    */
  constructor() {
    _setOwner(msg.sender);
  }

  /**
    * @notice Returns the address of the current owner.
    */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
    * @notice Returns the address of the proposed owner.
    */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
    * @notice Returns the address of the proposed owner.
    */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
    * @notice Returns the timestamp when router ownership was last proposed to be renounced
    */
  function routerOwnershipTimestamp() public view virtual returns (uint256) {
    return _routerOwnershipTimestamp;
  }

  /**
    * @notice Returns the timestamp when asset ownership was last proposed to be renounced
    */
  function assetOwnershipTimestamp() public view virtual returns (uint256) {
    return _assetOwnershipTimestamp;
  }

  /**
    * @notice Returns the delay period before a new owner can be accepted.
    */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
    * @notice Throws if called by any account other than the owner.
    */
  modifier onlyOwner() {
      require(_owner == msg.sender, "#OO:029");
      _;
  }

  /**
    * @notice Throws if called by any account other than the proposed owner.
    */
  modifier onlyProposed() {
      require(_proposed == msg.sender, "#OP:035");
      _;
  }

  /** 
    * @notice Indicates if the ownership of the router whitelist has
    * been renounced
    */
  function isRouterOwnershipRenounced() public view returns (bool) {
    return _owner == address(0) || _routerOwnershipRenounced;
  }

  /** 
    * @notice Indicates if the ownership of the router whitelist has
    * been renounced
    */
  function proposeRouterOwnershipRenunciation() public virtual onlyOwner {
    // Use contract as source of truth
    // Will fail if all ownership is renounced by modifier
    require(!_routerOwnershipRenounced, "#PROR:038");

    // Begin delay, emit event
    _setRouterOwnershipTimestamp();
  }

  /** 
    * @notice Indicates if the ownership of the asset whitelist has
    * been renounced
    */
  function renounceRouterOwnership() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    require(!_routerOwnershipRenounced, "#RRO:038");

    // Ensure there has been a proposal cycle started
    require(_routerOwnershipTimestamp > 0, "#RRO:037");

    // Delay has elapsed
    require((block.timestamp - _routerOwnershipTimestamp) > _delay, "#RRO:030");

    // Set renounced, emit event, reset timestamp to 0
    _setRouterOwnership(true);
  }

  /** 
    * @notice Indicates if the ownership of the asset whitelist has
    * been renounced
    */
  function isAssetOwnershipRenounced() public view returns (bool) {
    return _owner == address(0) || _assetOwnershipRenounced;
  }

  /** 
    * @notice Indicates if the ownership of the asset whitelist has
    * been renounced
    */
  function proposeAssetOwnershipRenunciation() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    require(!_assetOwnershipRenounced, "#PAOR:038");

    // Start cycle, emit event
    _setAssetOwnershipTimestamp();
  }

  /** 
    * @notice Indicates if the ownership of the asset whitelist has
    * been renounced
    */
  function renounceAssetOwnership() public virtual onlyOwner {
    // Contract as sournce of truth
    // Will fail if all ownership is renounced by modifier
    require(!_assetOwnershipRenounced, "#RAO:038");

    // Ensure there has been a proposal cycle started
    require(_assetOwnershipTimestamp > 0, "#RAO:037");

    // Ensure delay has elapsed
    require((block.timestamp - _assetOwnershipTimestamp) > _delay, "#RAO:030");

    // Set ownership, reset timestamp, emit event
    _setAssetOwnership(true);
  }

  /** 
    * @notice Indicates if the ownership has been renounced() by
    * checking if current owner is address(0)
    */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  /**
    * @notice Sets the timestamp for an owner to be proposed, and sets the
    * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    require(_proposed != newlyProposed || newlyProposed == address(0), "#PNO:036");

    // Sanity check: reasonable proposal
    require(_owner != newlyProposed, "#PNO:038");

    _setProposed(newlyProposed);
  }

  /**
    * @notice Renounces ownership of the contract after a delay
    */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    require(_proposedOwnershipTimestamp > 0, "#RO:037");

    // Ensure delay has elapsed
    require((block.timestamp - _proposedOwnershipTimestamp) > _delay, "#RO:030");

    // Require proposed is set to 0
    require(_proposed == address(0), "#RO:036");

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
    * @notice Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
  function acceptProposedOwner() public virtual onlyProposed {
    // Contract as source of truth
    require(_owner != _proposed, "#APO:038");

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    require((block.timestamp - _proposedOwnershipTimestamp) > _delay, "#APO:030");

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  ////// INTERNAL //////

  function _setRouterOwnershipTimestamp() private {
    _routerOwnershipTimestamp = block.timestamp;
    emit RouterOwnershipRenunciationProposed(_routerOwnershipTimestamp);
  }

  function _setRouterOwnership(bool value) private {
    _routerOwnershipRenounced = value;
    _routerOwnershipTimestamp = 0;
    emit RouterOwnershipRenounced(value);
  }

  function _setAssetOwnershipTimestamp() private {
    _assetOwnershipTimestamp = block.timestamp;
    emit AssetOwnershipRenunciationProposed(_assetOwnershipTimestamp);
  }

  function _setAssetOwnership(bool value) private {
    _assetOwnershipRenounced = value;
    _assetOwnershipTimestamp = 0;
    emit AssetOwnershipRenounced(value);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(_proposed);
  }
}


// File contracts/TransactionManager.sol

pragma solidity 0.8.4;








/**
  *
  * @title TransactionManager
  * @author Connext <[email protected]>
  * @notice This contract holds the logic to facilitate crosschain transactions.
  *         Transactions go through three phases in the happy case:
  *
  *         1. Route Auction (offchain): User broadcasts to our network 
  *         signalling their desired route. Routers respond with sealed bids 
  *         containing commitments to fulfilling the transaction within a 
  *         certain time and price range.
  *
  *         2. Prepare: Once the auction is completed, the transaction can be 
  *         prepared. The user submits a transaction to `TransactionManager` 
  *         contract on sender-side chain containing router's signed bid. This 
  *         transaction locks up the users funds on the sending chain. Upon 
  *         detecting an event containing their signed bid from the chain, 
  *         router submits the same transaction to `TransactionManager` on the 
  *         receiver-side chain, and locks up a corresponding amount of 
  *         liquidity. The amount locked on the receiving chain is `sending 
  *         amount - auction fee` so the router is incentivized to complete the 
  *         transaction.
  *
  *         3. Fulfill: Upon detecting the `TransactionPrepared` event on the 
  *         receiver-side chain, the user signs a message and sends it to a 
  *         relayer, who will earn a fee for submission. The relayer (which may 
  *         be the router) then submits the message to the `TransactionManager` 
  *         to complete their transaction on receiver-side chain and claim the 
  *         funds locked by the router. A relayer is used here to allow users 
  *         to submit transactions with arbitrary calldata on the receiving 
  *         chain without needing gas to do so. The router then submits the 
  *         same signed message and completes transaction on sender-side, 
  *         unlocking the original `amount`.
  *
  *         If a transaction is not fulfilled within a fixed timeout, it 
  *         reverts and can be reclaimed by the party that called `prepare` on 
  *         each chain (initiator). Additionally, transactions can be cancelled 
  *         unilaterally by the person owed funds on that chain (router for 
  *         sending chain, user for receiving chain) prior to expiry.
  */
contract TransactionManager is ReentrancyGuard, ProposedOwnable, ITransactionManager {
  /**
   * @dev Mapping of router to balance specific to asset
   */
  mapping(address => mapping(address => uint256)) public routerBalances;

  /**
    * @dev Mapping of allowed router addresses. Must be added to both
    *      sending and receiving chains when forwarding a transfer.
    */
  mapping(address => bool) public approvedRouters;

  /**
    * @dev Mapping of allowed assetIds on same chain as contract
    */
  mapping(address => bool) public approvedAssets;

  /**
    * @dev Mapping of hash of `InvariantTransactionData` to the hash
    *      of the `VariantTransactionData`
    */
  mapping(bytes32 => bytes32) public variantTransactionData;

  /**
  * @dev The stored chain id of the contract, may be passed in to avoid any 
  *      evm issues
  */
  uint256 private immutable chainId;

  /**
    * @dev Minimum timeout (will be the lowest on the receiving chain)
    */
  uint256 public constant MIN_TIMEOUT = 1 days; // 24 hours

  /**
    * @dev Maximum timeout (will be the highest on the sending chain)
    */
  uint256 public constant MAX_TIMEOUT = 30 days; // 720 hours

  /**
    * @dev The external contract that will execute crosschain
    *      calldata
    */
  IFulfillInterpreter public immutable interpreter;

  constructor(uint256 _chainId) {
    chainId = _chainId;
    interpreter = new FulfillInterpreter(address(this));
  }

  /** 
   * @notice Gets the chainId for this contract. If not specified during init
   *         will use the block.chainId
   */
  function getChainId() public view override returns (uint256 _chainId) {
    // Hold in memory to reduce sload calls
    uint256 chain = chainId;
    if (chain == 0) {
      // If not provided, pull from block
      chain = block.chainid;
    }
    return chain;
  }

  /**
   * @notice Allows us to get the chainId that this contract has stored
   */
  function getStoredChainId() external view override returns (uint256) {
    return chainId;
  }

  /**
    * @notice Used to add routers that can transact crosschain
    * @param router Router address to add
    */
  function addRouter(address router) external override onlyOwner {
    // Sanity check: not empty
    require(router != address(0), "#AR:001");

    // Sanity check: needs approval
    require(approvedRouters[router] == false, "#AR:032");

    // Update mapping
    approvedRouters[router] = true;

    // Emit event
    emit RouterAdded(router, msg.sender);
  }

  /**
    * @notice Used to remove routers that can transact crosschain
    * @param router Router address to remove
    */
  function removeRouter(address router) external override onlyOwner {
    // Sanity check: not empty
    require(router != address(0), "#RR:001");

    // Sanity check: needs removal
    require(approvedRouters[router] == true, "#RR:033");

    // Update mapping
    approvedRouters[router] = false;

    // Emit event
    emit RouterRemoved(router, msg.sender);
  }

  /**
    * @notice Used to add assets on same chain as contract that can
    *         be transferred.
    * @param assetId AssetId to add
    */
  function addAssetId(address assetId) external override onlyOwner {
    // Sanity check: needs approval
    require(approvedAssets[assetId] == false, "#AA:032");

    // Update mapping
    approvedAssets[assetId] = true;

    // Emit event
    emit AssetAdded(assetId, msg.sender);
  }

  /**
    * @notice Used to remove assets on same chain as contract that can
    *         be transferred.
    * @param assetId AssetId to remove
    */
  function removeAssetId(address assetId) external override onlyOwner {
    // Sanity check: already approval
    require(approvedAssets[assetId] == true, "#RA:033");

    // Update mapping
    approvedAssets[assetId] = false;

    // Emit event
    emit AssetRemoved(assetId, msg.sender);
  }

  /**
    * @notice This is used by anyone to increase a router's available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    * @param router The router you are adding liquidity on behalf of
    */
  function addLiquidityFor(uint256 amount, address assetId, address router) external payable override nonReentrant {
    _addLiquidityForRouter(amount, assetId, router);
  }

  /**
    * @notice This is used by any router to increase their available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    */
  function addLiquidity(uint256 amount, address assetId) external payable override nonReentrant {
    _addLiquidityForRouter(amount, assetId, msg.sender);
  }

  /**
    * @notice This is used by any router to decrease their available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to remove for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're removing liquidity for
    * @param recipient The address that will receive the liquidity being removed
    */
  function removeLiquidity(
    uint256 amount,
    address assetId,
    address payable recipient
  ) external override nonReentrant {
    // Sanity check: recipient is sensible
    require(recipient != address(0), "#RL:007");

    // Sanity check: nonzero amounts
    require(amount > 0, "#RL:002");

    uint256 routerBalance = routerBalances[msg.sender][assetId];
    // Sanity check: amount can be deducted for the router
    require(routerBalance >= amount, "#RL:008");

    // Update router balances
    unchecked {
      routerBalances[msg.sender][assetId] = routerBalance - amount;
    }

    // Transfer from contract to specified recipient
    LibAsset.transferAsset(assetId, recipient, amount);

    // Emit event
    emit LiquidityRemoved(msg.sender, assetId, amount, recipient);
  }

  /**
    * @notice This function creates a crosschain transaction. When called on
    *         the sending chain, the user is expected to lock up funds. When
    *         called on the receiving chain, the router deducts the transfer
    *         amount from the available liquidity. The majority of the
    *         information about a given transfer does not change between chains,
    *         with three notable exceptions: `amount`, `expiry`, and 
    *         `preparedBlock`. The `amount` and `expiry` are decremented
    *         between sending and receiving chains to provide an incentive for 
    *         the router to complete the transaction and time for the router to
    *         fulfill the transaction on the sending chain after the unlocking
    *         signature is revealed, respectively.
    * @param args TODO
    */
  function prepare(
    PrepareArgs calldata args
  ) external payable override nonReentrant returns (TransactionData memory) {
    // Sanity check: user is sensible
    require(args.invariantData.user != address(0), "#P:009");

    // Sanity check: router is sensible
    require(args.invariantData.router != address(0), "#P:001");

    // Router is approved *on both chains*
    require(isRouterOwnershipRenounced() || approvedRouters[args.invariantData.router], "#P:003");

    // Sanity check: sendingChainFallback is sensible
    require(args.invariantData.sendingChainFallback != address(0), "#P:010");

    // Sanity check: valid fallback
    require(args.invariantData.receivingAddress != address(0), "#P:026");

    // Make sure the chains are different
    require(args.invariantData.sendingChainId != args.invariantData.receivingChainId, "#P:011");

    // Make sure the chains are relevant
    uint256 _chainId = getChainId();
    require(args.invariantData.sendingChainId == _chainId || args.invariantData.receivingChainId == _chainId, "#P:012");

    { // Expiry scope
      // Make sure the expiry is greater than min
      uint256 buffer = args.expiry - block.timestamp;
      require(buffer >= MIN_TIMEOUT, "#P:013");

      // Make sure the expiry is lower than max
      require(buffer <= MAX_TIMEOUT, "#P:014");
    }

    // Make sure the hash is not a duplicate
    bytes32 digest = keccak256(abi.encode(args.invariantData));
    require(variantTransactionData[digest] == bytes32(0), "#P:015");

    // NOTE: the `encodedBid` and `bidSignature` are simply passed through
    //       to the contract emitted event to ensure the availability of
    //       this information. Their validity is asserted offchain, and
    //       is out of scope of this contract. They are used as inputs so
    //       in the event of a router or user crash, they may recover the
    //       correct bid information without requiring an offchain store.

    // Amount actually used (if fee-on-transfer will be different than
    // supplied)
    uint256 amount = args.amount;

    // First determine if this is sender side or receiver side
    if (args.invariantData.sendingChainId == _chainId) {
      // Check the sender is correct
      require(msg.sender == args.invariantData.initiator, "#P:039");

      // Sanity check: amount is sensible
      // Only check on sending chain to enforce router fees. Transactions could
      // be 0-valued on receiving chain if it is just a value-less call to some
      // `IFulfillHelper`
      require(args.amount > 0, "#P:002");

      // Assets are approved
      // NOTE: Cannot check this on receiving chain because of differing
      // chain contexts
      require(isAssetOwnershipRenounced() || approvedAssets[args.invariantData.sendingAssetId], "#P:004");

      // This is sender side prepare. The user is beginning the process of 
      // submitting an onchain tx after accepting some bid. They should
      // lock their funds in the contract for the router to claim after
      // they have revealed their signature on the receiving chain via
      // submitting a corresponding `fulfill` tx

      // Validate correct amounts on msg and transfer from user to
      // contract
      amount = transferAssetToContract(
        args.invariantData.sendingAssetId,
        args.amount
      );

      // Store the transaction variants. This happens after transferring to
      // account for fee on transfer tokens
      variantTransactionData[digest] = hashVariantTransactionData(
        amount,
        args.expiry,
        block.number
      );
    } else {
      // This is receiver side prepare. The router has proposed a bid on the
      // transfer which the user has accepted. They can now lock up their
      // own liquidity on th receiving chain, which the user can unlock by
      // calling `fulfill`. When creating the `amount` and `expiry` on the
      // receiving chain, the router should have decremented both. The
      // expiry should be decremented to ensure the router has time to
      // complete the sender-side transaction after the user completes the
      // receiver-side transactoin. The amount should be decremented to act as
      // a fee to incentivize the router to complete the transaction properly.

      // Check that the callTo is a contract
      // NOTE: This cannot happen on the sending chain (different chain 
      // contexts), so a user could mistakenly create a transfer that must be
      // cancelled if this is incorrect
      require(args.invariantData.callTo == address(0) || Address.isContract(args.invariantData.callTo), "#P:031");

      // Check that the asset is approved
      // NOTE: This cannot happen on both chains because of differing chain 
      // contexts. May be possible for user to create transaction that is not
      // prepare-able on the receiver chain.
      require(isAssetOwnershipRenounced() || approvedAssets[args.invariantData.receivingAssetId], "#P:004");

      // Check that the caller is the router
      require(msg.sender == args.invariantData.router, "#P:016");

      // Check that the router isnt accidentally locking funds in the contract
      require(msg.value == 0, "#P:017");

      // Check that router has liquidity
      uint256 balance = routerBalances[args.invariantData.router][args.invariantData.receivingAssetId];
      require(balance >= amount, "#P:018");

      // Store the transaction variants
      variantTransactionData[digest] = hashVariantTransactionData(
        amount,
        args.expiry,
        block.number
      );

      // Decrement the router liquidity
      // using unchecked because underflow protected against with require
      unchecked {
        routerBalances[args.invariantData.router][args.invariantData.receivingAssetId] = balance - amount;
      }
    }

    // Emit event
    TransactionData memory txData = TransactionData({
      receivingChainTxManagerAddress: args.invariantData.receivingChainTxManagerAddress,
      user: args.invariantData.user,
      router: args.invariantData.router,
      initiator: args.invariantData.initiator,
      sendingAssetId: args.invariantData.sendingAssetId,
      receivingAssetId: args.invariantData.receivingAssetId,
      sendingChainFallback: args.invariantData.sendingChainFallback,
      callTo: args.invariantData.callTo,
      receivingAddress: args.invariantData.receivingAddress,
      callDataHash: args.invariantData.callDataHash,
      transactionId: args.invariantData.transactionId,
      sendingChainId: args.invariantData.sendingChainId,
      receivingChainId: args.invariantData.receivingChainId,
      amount: amount,
      expiry: args.expiry,
      preparedBlockNumber: block.number
    });

    emit TransactionPrepared(
      txData.user,
      txData.router,
      txData.transactionId,
      txData,
      msg.sender,
      args
    );

    return txData;
  }



    /**
    * @notice This function completes a crosschain transaction. When called on
    *         the receiving chain, the user reveals their signature on the
    *         transactionId and is sent the amount corresponding to the number
    *         of shares the router locked when calling `prepare`. The router 
    *         then uses this signature to unlock the corresponding funds on the 
    *         receiving chain, which are then added back to their available 
    *         liquidity. The user includes a relayer fee since it is not 
    *         assumed they will have gas on the receiving chain. This function 
    *         *must* be called before the transaction expiry has elapsed.
    * @param args TODO
    */
  function fulfill(
    FulfillArgs calldata args
  ) external override nonReentrant returns (TransactionData memory) {
    // Get the hash of the invariant tx data. This hash is the same
    // between sending and receiving chains. The variant data is stored
    // in the contract when `prepare` is called within the mapping.

    { // scope: validation and effects
      bytes32 digest = hashInvariantTransactionData(args.txData);

      // Make sure that the variant data matches what was stored
      require(variantTransactionData[digest] == hashVariantTransactionData(
        args.txData.amount,
        args.txData.expiry,
        args.txData.preparedBlockNumber
      ), "#F:019");

      // Make sure the expiry has not elapsed
      require(args.txData.expiry >= block.timestamp, "#F:020");

      // Make sure the transaction wasn't already completed
      require(args.txData.preparedBlockNumber > 0, "#F:021");

      // Check provided callData matches stored hash
      require(keccak256(args.callData) == args.txData.callDataHash, "#F:024");

      // To prevent `fulfill` / `cancel` from being called multiple times, the
      // preparedBlockNumber is set to 0 before being hashed. The value of the
      // mapping is explicitly *not* zeroed out so users who come online without
      // a store can tell the difference between a transaction that has not been
      // prepared, and a transaction that was already completed on the receiver
      // chain.
      variantTransactionData[digest] = hashVariantTransactionData(
        args.txData.amount,
        args.txData.expiry,
        0
      );
    }

    // Declare these variables for the event emission. Are only assigned
    // IFF there is an external call on the receiving chain
    bool success;
    bool isContract;
    bytes memory returnData;

    uint256 _chainId = getChainId();

    if (args.txData.sendingChainId == _chainId) {
      // The router is completing the transaction, they should get the
      // amount that the user deposited credited to their liquidity
      // reserves.

      // Make sure that the user is not accidentally fulfilling the transaction
      // on the sending chain
      require(msg.sender == args.txData.router, "#F:016");

      // Validate the user has signed
      require(
        recoverFulfillSignature(
          args.txData.transactionId,
          args.relayerFee,
          args.txData.receivingChainId,
          args.txData.receivingChainTxManagerAddress,
          args.signature
        ) == args.txData.user, "#F:022"
      );

      // Complete tx to router for original sending amount
      routerBalances[args.txData.router][args.txData.sendingAssetId] += args.txData.amount;

    } else {
      // Validate the user has signed, using domain of contract
      require(
        recoverFulfillSignature(
          args.txData.transactionId,
          args.relayerFee,
          _chainId,
          address(this),
          args.signature
        ) == args.txData.user, "#F:022"
      );

      // Sanity check: fee <= amount. Allow `=` in case of only 
      // wanting to execute 0-value crosschain tx, so only providing 
      // the fee amount
      require(args.relayerFee <= args.txData.amount, "#F:023");

      (success, isContract, returnData) = _receivingChainFulfill(
        args.txData,
        args.relayerFee,
        args.callData
      );
    }

    // Emit event
    emit TransactionFulfilled(
      args.txData.user,
      args.txData.router,
      args.txData.transactionId,
      args,
      success,
      isContract,
      returnData,
      msg.sender
    );

    return args.txData;
  }

  /**
    * @notice Any crosschain transaction can be cancelled after it has been
    *         created to prevent indefinite lock up of funds. After the
    *         transaction has expired, anyone can cancel it. Before the
    *         expiry, only the recipient of the funds on the given chain is
    *         able to cancel. On the sending chain, this means only the router
    *         is able to cancel before the expiry, while only the user can
    *         prematurely cancel on the receiving chain.
    * @param args TODO
    */
  function cancel(CancelArgs calldata args)
    external
    override
    nonReentrant
    returns (TransactionData memory)
  {
    // Make sure params match against stored data
    // Also checks that there is an active transfer here
    // Also checks that sender or receiver chainID is this chainId (bc we checked it previously)

    // Get the hash of the invariant tx data. This hash is the same
    // between sending and receiving chains. The variant data is stored
    // in the contract when `prepare` is called within the mapping.
    bytes32 digest = hashInvariantTransactionData(args.txData);

    // Verify the variant data is correct
    require(variantTransactionData[digest] == hashVariantTransactionData(args.txData.amount, args.txData.expiry, args.txData.preparedBlockNumber), "#C:019");

    // Make sure the transaction wasn't already completed
    require(args.txData.preparedBlockNumber > 0, "#C:021");

    // To prevent `fulfill` / `cancel` from being called multiple times, the
    // preparedBlockNumber is set to 0 before being hashed. The value of the
    // mapping is explicitly *not* zeroed out so users who come online without
    // a store can tell the difference between a transaction that has not been
    // prepared, and a transaction that was already completed on the receiver
    // chain.
    variantTransactionData[digest] = hashVariantTransactionData(args.txData.amount, args.txData.expiry, 0);

    // Get chainId for gas
    uint256 _chainId = getChainId();

    // Return the appropriate locked funds
    if (args.txData.sendingChainId == _chainId) {
      // Sender side, funds must be returned to the user
      if (args.txData.expiry >= block.timestamp) {
        // Timeout has not expired and tx may only be cancelled by router
        // NOTE: no need to validate the signature here, since you are requiring
        // the router must be the sender when the cancellation is during the
        // fulfill-able window
        require(msg.sender == args.txData.router, "#C:025");
      }

      // Return users locked funds
      // NOTE: no need to check if amount > 0 because cant be prepared on
      // sending chain with 0 value
      LibAsset.transferAsset(
        args.txData.sendingAssetId,
        payable(args.txData.sendingChainFallback),
        args.txData.amount
      );

    } else {
      // Receiver side, router liquidity is returned
      if (args.txData.expiry >= block.timestamp) {
        // Timeout has not expired and tx may only be cancelled by user
        // Validate signature
        require(msg.sender == args.txData.user || recoverCancelSignature(args.txData.transactionId, _chainId, address(this), args.signature) == args.txData.user, "#C:022");

        // NOTE: there is no incentive here for relayers to submit this on
        // behalf of the user (i.e. fee not respected) because the user has not
        // locked funds on this contract. However, if the user reveals their
        // cancel signature to the router, they are incentivized to submit it
        // to unlock their own funds
      }

      // Return liquidity to router
      routerBalances[args.txData.router][args.txData.receivingAssetId] += args.txData.amount;
    }

    // Emit event
    emit TransactionCancelled(
      args.txData.user,
      args.txData.router,
      args.txData.transactionId,
      args,
      msg.sender
    );

    // Return
    return args.txData;
  }

  //////////////////////////
  /// Private functions ///
  //////////////////////////

  /**
    * @notice Contains the logic to verify + increment a given routers liquidity
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    * @param router The router you are adding liquidity on behalf of
    */
  function _addLiquidityForRouter(
    uint256 amount,
    address assetId,
    address router
  ) internal {
    // Sanity check: router is sensible
    require(router != address(0), "#AL:001");

    // Sanity check: nonzero amounts
    require(amount > 0, "#AL:002");

    // Router is approved
    require(isRouterOwnershipRenounced() || approvedRouters[router], "#AL:003");

    // Asset is approved
    require(isAssetOwnershipRenounced() || approvedAssets[assetId], "#AL:004");

    // Transfer funds to contract
    amount = transferAssetToContract(assetId, amount);

    // Update the router balances. Happens after pulling funds to account for
    // the fee on transfer tokens
    routerBalances[router][assetId] += amount;

    // Emit event
    emit LiquidityAdded(router, assetId, amount, msg.sender);
  }

  /**
   * @notice Handles transferring funds from msg.sender to the
   *         transaction manager contract. Used in prepare, addLiquidity
   * @param assetId The address to transfer
   * @param specifiedAmount The specified amount to transfer. May not be the 
   *                        actual amount transferred (i.e. fee on transfer 
   *                        tokens)
   */
  function transferAssetToContract(address assetId, uint256 specifiedAmount) internal returns (uint256) {
    uint256 trueAmount = specifiedAmount;

    // Validate correct amounts are transferred
    if (LibAsset.isNativeAsset(assetId)) {
      require(msg.value == specifiedAmount, "#TA:005");
    } else {
      uint256 starting = LibAsset.getOwnBalance(assetId);
      require(msg.value == 0, "#TA:006");
      LibAsset.transferFromERC20(assetId, msg.sender, address(this), specifiedAmount);
      // Calculate the *actual* amount that was sent here
      trueAmount = LibAsset.getOwnBalance(assetId) - starting;
    }

    return trueAmount;
  }

  /// @notice Recovers the signer from the signature provided by the user
  /// @param transactionId Transaction identifier of tx being recovered
  /// @param signature The signature you are recovering the signer from
  function recoverCancelSignature(
    bytes32 transactionId,
    uint256 receivingChainId,
    address receivingChainTxManagerAddress,
    bytes calldata signature
  ) internal pure returns (address) {
    // Create the signed payload
    SignedCancelData memory payload = SignedCancelData({
      transactionId: transactionId,
      functionIdentifier: "cancel",
      receivingChainId: receivingChainId,
      receivingChainTxManagerAddress: receivingChainTxManagerAddress
    });

    // Recover
    return recoverSignature(abi.encode(payload), signature);
  }

  /**
    * @notice Recovers the signer from the signature provided by the user
    * @param transactionId Transaction identifier of tx being recovered
    * @param relayerFee The fee paid to the relayer for submitting the
    *                   tx on behalf of the user.
    * @param signature The signature you are recovering the signer from
    */
  function recoverFulfillSignature(
    bytes32 transactionId,
    uint256 relayerFee,
    uint256 receivingChainId,
    address receivingChainTxManagerAddress,
    bytes calldata signature
  ) internal pure returns (address) {
    // Create the signed payload
    SignedFulfillData memory payload = SignedFulfillData({
      transactionId: transactionId,
      relayerFee: relayerFee,
      functionIdentifier: "fulfill",
      receivingChainId: receivingChainId,
      receivingChainTxManagerAddress: receivingChainTxManagerAddress
    });

    // Recover
    return recoverSignature(abi.encode(payload), signature);
  }

  /**
    * @notice Holds the logic to recover the signer from an encoded payload.
    *         Will hash and convert to an eth signed message.
    * @param encodedPayload The payload that was signed
    * @param signature The signature you are recovering the signer from
    */
  function recoverSignature(bytes memory encodedPayload, bytes calldata  signature) internal pure returns (address) {
    // Recover
    return ECDSA.recover(
      ECDSA.toEthSignedMessageHash(keccak256(encodedPayload)),
      signature
    );
  }

  /**
    * @notice Returns the hash of only the invariant portions of a given
    *         crosschain transaction
    * @param txData TransactionData to hash
    */
  function hashInvariantTransactionData(TransactionData calldata txData) internal pure returns (bytes32) {
    InvariantTransactionData memory invariant = InvariantTransactionData({
      receivingChainTxManagerAddress: txData.receivingChainTxManagerAddress,
      user: txData.user,
      router: txData.router,
      initiator: txData.initiator,
      sendingAssetId: txData.sendingAssetId,
      receivingAssetId: txData.receivingAssetId,
      sendingChainFallback: txData.sendingChainFallback,
      callTo: txData.callTo,
      receivingAddress: txData.receivingAddress,
      sendingChainId: txData.sendingChainId,
      receivingChainId: txData.receivingChainId,
      callDataHash: txData.callDataHash,
      transactionId: txData.transactionId
    });
    return keccak256(abi.encode(invariant));
  }

  /**
    * @notice Returns the hash of only the variant portions of a given
    *         crosschain transaction
    * @param amount amount to hash
    * @param expiry expiry to hash
    * @param preparedBlockNumber preparedBlockNumber to hash
    * @return Hash of the variant data
    *
    */
  function hashVariantTransactionData(uint256 amount, uint256 expiry, uint256 preparedBlockNumber) internal pure returns (bytes32) {
    VariantTransactionData memory variant = VariantTransactionData({
      amount: amount,
      expiry: expiry,
      preparedBlockNumber: preparedBlockNumber
    });
    return keccak256(abi.encode(variant));
  }

  /**
   * @notice Handles the receiving-chain fulfillment. This function should
   *         pay the relayer and either send funds to the specified address
   *         or execute the calldata. Will return a tuple of boolean,bytes
   *         indicating the success and return data of the external call.
   * @dev Separated from fulfill function to avoid stack too deep errors
   *
   * @param txData The TransactionData that needs to be fulfilled
   * @param relayerFee The fee to be paid to the relayer for submission
   * @param callData The data to be executed on the receiving chain
   *
   * @return Tuple representing (success, returnData) of the external call
   */
  function _receivingChainFulfill(
    TransactionData calldata txData,
    uint256 relayerFee,
    bytes calldata callData
  ) internal returns (bool, bool, bytes memory) {
    // The user is completing the transaction, they should get the
    // amount that the router deposited less fees for relayer.

    // Get the amount to send
    uint256 toSend;
    unchecked {
      toSend = txData.amount - relayerFee;
    }

    // Send the relayer the fee
    if (relayerFee > 0) {
      LibAsset.transferAsset(txData.receivingAssetId, payable(msg.sender), relayerFee);
    }

    // Handle receiver chain external calls if needed
    if (txData.callTo == address(0)) {
      // No external calls, send directly to receiving address
      if (toSend > 0) {
        LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend);
      }
      return (false, false, new bytes(0));
    } else {
      // Handle external calls with a fallback to the receiving
      // address in case the call fails so the funds dont remain
      // locked.

      bool isNativeAsset = LibAsset.isNativeAsset(txData.receivingAssetId);

      // First, transfer the funds to the helper if needed
      if (!isNativeAsset && toSend > 0) {
        LibAsset.transferERC20(txData.receivingAssetId, address(interpreter), toSend);
      }

      // Next, call `execute` on the helper. Helpers should internally
      // track funds to make sure no one user is able to take all funds
      // for tx, and handle the case of reversions
      return interpreter.execute{ value: isNativeAsset ? toSend : 0}(
        txData.transactionId,
        payable(txData.callTo),
        txData.receivingAssetId,
        payable(txData.receivingAddress),
        toSend,
        callData
      );
    }
  }
}


// File contracts/interfaces/IPriceOracle.sol

pragma solidity ^0.8.4;

interface IPriceOracle {
    /**
      * @notice Get the price of a token
      * @param token The token to get the price of
      * @return The asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getTokenPrice(address token) external view returns (uint256);
}


// File contracts/Multicall.sol

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

/// @title Multicall - Aggregate results from multiple read-only function calls

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }

}


// File contracts/test/TestAggregator.sol

pragma solidity 0.8.4;

/* 
 * This aggregator is ONLY useful for testing
 */
contract TestAggregator {

    uint8 public decimals = 18;

    string public description = "Chainlink Test Aggregator";

    uint256 public version = 1;

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ){
        return (_roundId, 1e18, 0, block.timestamp, 1e18);
    }

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
      return (1, 1e18, 0, block.timestamp, 1e18);
    }
}