// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: contracts/oracle/ICADConversionOracle.sol


/**
 * @title ICADRateOracle
 * @notice provides interface for converting USD stable coins to CAD
*/
interface ICADConversionOracle {

    /**
     * @notice convert USD amount to CAD amount
     * @param amount     amount of USD in 18 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdToCad(uint256 amount) external view returns (uint256);

    /**
     * @notice convert Dai amount to CAD amount
     * @param amount     amount of dai in 18 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function daiToCad(uint256 amount) external view returns (uint256);

    /**
     * @notice convert USDC amount to CAD amount
     * @param amount     amount of USDC in 6 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdcToCad(uint256 amount) external view returns (uint256);


    /**
     * @notice convert USDT amount to CAD amount
     * @param amount     amount of USDT in 6 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdtToCad(uint256 amount) external view returns (uint256);


    /**
     * @notice convert CAD amount to USD amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USD in 18 decimal places
     */
    function cadToUsd(uint256 amount) external view returns (uint256);

    /**
     * @notice convert CAD amount to Dai amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of Dai in 18 decimal places
     */
    function cadToDai(uint256 amount) external view returns (uint256);

    /**
     * @notice convert CAD amount to USDC amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USDC in 6 decimal places
     */
    function cadToUsdc(uint256 amount) external view returns (uint256);

    /**
     * @notice convert CAD amount to USDT amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USDT in 6 decimal places
     */
    function cadToUsdt(uint256 amount) external view returns (uint256);
}

// File: contracts/standardTokens/IDividendAware.sol


/**
 * @dev Interface for dividend claim functions that should be present in dividend aware tokens
 */
interface IDividendAware {

    /**
     * @notice withdraw all accrued dividends by the sender to the sender
     * @return true if successful
     */
    function claimAllDividends() external returns (bool);

    /**
     * @notice withdraw all accrued dividends by the sender to the recipient
     * @param recipient     address to receive dividends
     * @return true if successful
     */
    function claimAllDividendsTo(address recipient) external returns (bool);

    /**
     * @notice withdraw portion of dividends by the sender to the sender
     * @return true if successful
     */
    function claimDividends(uint256 amount) external returns (bool);

    /**
     * @notice withdraw portion of dividends by the sender to the recipient
     * @param recipient     address to receive dividends
     * @param amount        amount of dividends to withdraw
     * @return true if successful
     */
    function claimDividendsTo(address recipient, uint256 amount) external returns (bool);
}

// File: contracts/acquisition/ITokenPool.sol


/**
 * @title ITokenPool
 * @notice provides interface for token pool where ERC20 tokens can be deposited and withdraw
*/
interface ITokenPool {

    /**
    * @notice deposit token into the pool from the source
    * @param amount     amount of token to deposit
    * @return true if success
    */
    function depositAssetToken(uint256 amount) external returns (bool);

    /**
    * @notice withdraw token from the pool back to the source
    * @param amount     amount of token to withdraw
    * @return true if success
    */
    function withdrawAssetToken(uint256 amount) external returns (bool);
}

// File: contracts/acquisition/FixedPriceCADSingleSourceTokenPool.sol




/**
 * @title FixedPriceCADSingleSourceTokenPool
 * @notice Convert USD into a wToken in CAD. wToken is transfered from a single-source pool to the sender of USD, while USD is transferred to the source.
*/
contract FixedPriceCADSingleSourceTokenPool is ITokenPool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event TokenDeposited(uint256 amount);
    event TokenWithdrawn(uint256 amount);

    event TokenTransaction(address indexed from, address to, uint256 tokenAmount, uint8 usdType, uint256 usdAmount);

    // source where the wTokens come from
    address public _poolSource;

    // address of the wToken
    IERC20 public _wToken;

    // address of the USD to CAD oracle
    ICADConversionOracle public _cadOracle;

    // wTokens, if fix-priced in CAD, will not require more than 2 decimals
    uint256 public _fixedPriceCADCent;

    // Dai contract
    IERC20 public _daiContract;

    // USDC contract
    IERC20 public _usdcContract;

    // USDT contract
    IERC20 public _usdtContract;


    constructor(
        address poolSource,
        address tokenAddress,
        address cadOracleAddress,
        uint256 fixedPriceCADCent,

        address daiContractddress,
        address usdcContractAddress,
        address usdtContractAddress
    ) public {
        _poolSource = poolSource;
        _wToken = IERC20(tokenAddress);
        _cadOracle = ICADConversionOracle(cadOracleAddress);
        _fixedPriceCADCent = fixedPriceCADCent;

        _daiContract = IERC20(daiContractddress);
        _usdcContract = IERC20(usdcContractAddress);
        _usdtContract = IERC20(usdtContractAddress);
    }

    /**
    * @notice deposit token into the pool from the source
    * @param amount     amount of token to deposit
    * @return true if success
    */
    function depositAssetToken(uint256 amount) external virtual override returns (bool) {
        require(msg.sender == _poolSource, "Only designated source can deposit token");
        require(amount > 0, "Amount must be greater than 0");

        _wToken.transferFrom(_poolSource, address(this), amount);

        emit TokenDeposited(amount);
        return true;
    }

    /**
    * @notice withdraw token from the pool back to the source
    * @param amount     amount of token to withdraw
    * @return true if success
    */
    function withdrawAssetToken(uint256 amount) external virtual override returns (bool) {
        require(msg.sender == _poolSource, "Only designated source can withdraw token");
        require(amount > 0, "Amount must be greater than 0");

        _wToken.transfer(_poolSource, amount);

        emit TokenWithdrawn(amount);
        return true;
    }

    /**
    * @notice withdraw any Dai accumulated as dividends, and any tokens that might have been erroneously sent to this contract
    * @param token      address of token to withdraw
    * @param amount     amount of token to withdraw
    * @return true if success
    */
    function withdrawERC20(address token, uint256 amount) external returns (bool) {
        require(msg.sender == _poolSource, "Only designated source can withdraw any token");
        require(token != address(_wToken), "Cannot withdraw asset token this way");

        IERC20(token).safeTransfer(_poolSource, amount);
        return true;
    }

    /**
    * @notice while the pool holds wNest, it is accumulating dividends, pool source can claim them
    * @return true if success
    */
    function claimDividends() external returns (bool) {
        require(msg.sender == _poolSource, "Only designated source can claim dividends");

        IDividendAware(address(_wToken)).claimAllDividendsTo(msg.sender);
        return true;
    }


    /**
    * @notice deposit Dai and get back wTokens
    * @param amount      amount of Dai to deposit
    * @return true if success
    */
    function swapWithDai(uint256 amount) external returns (bool) {
        require(amount > 0, "Dai amount must be greater than 0");

        uint256 tokenAmount = daiToToken(amount);

        // through not strictly needed, useful to have a clear message for this error case
        require(_wToken.balanceOf(address(this)) >= tokenAmount, "Insufficient token supply in the pool");

        _daiContract.transferFrom(msg.sender, _poolSource, amount);
        _wToken.transfer(msg.sender, tokenAmount);

        emit TokenTransaction(msg.sender, msg.sender, tokenAmount, 1, amount);
        return true;
    }

    /**
    * @notice deposit USDC and get back wTokens
    * @param amount      amount of USDC to deposit
    * @return true if success
    */
    function swapWithUSDC(uint256 amount) external returns (bool) {
        require(amount > 0, "USDC amount must be greater than 0");

        uint256 tokenAmount = usdcToToken(amount);

        require(_wToken.balanceOf(address(this)) >= tokenAmount, "Insufficient token supply in the pool");

        _usdcContract.transferFrom(msg.sender, _poolSource, amount);
        _wToken.transfer(msg.sender, tokenAmount);

        emit TokenTransaction(msg.sender, msg.sender, tokenAmount, 2, amount);
        return true;
    }

    /**
    * @notice deposit USDT and get back wTokens
    * @param amount      amount of USDT to deposit
    * @return true if success
    */
    function swapWithUSDT(uint256 amount) external returns (bool) {
        require(amount > 0, "USDT amount must be greater than 0");

        uint256 tokenAmount = usdtToToken(amount);

        require(_wToken.balanceOf(address(this)) >= tokenAmount, "Insufficient token supply in the pool");

        // safeTransferFrom is necessary for USDT due to argument byte size check in USDT's transferFrom function
        _usdtContract.safeTransferFrom(msg.sender, _poolSource, amount);
        _wToken.transfer(msg.sender, tokenAmount);

        emit TokenTransaction(msg.sender, msg.sender, tokenAmount, 3, amount);
        return true;
    }



    /**
    * @notice given a Dai amount, calculate resulting wToken amount
    * @param amount      amount of Dai for conversion, in 18 decimals
    * @return amount of resulting wTokens
    */
    function daiToToken(uint256 amount) public view returns (uint256) {
        return _cadOracle
            .daiToCad(amount.mul(100))
            .div(_fixedPriceCADCent);
    }

    /**
    * @notice given a USDC amount, calculate resulting wToken amount
    * @param amount      amount of USDC for conversion, in 6 decimals
    * @return amount of resulting wTokens
    */
    function usdcToToken(uint256 amount) public view returns (uint256) {
        return _cadOracle
            .usdcToCad(amount.mul(100))
            .div(_fixedPriceCADCent);
    }

    /**
    * @notice given a USDT amount, calculate resulting wToken amount
    * @param amount      amount of USDT for conversion, in 6 decimals
    * @return amount of resulting wTokens
    */
    function usdtToToken(uint256 amount) public view returns (uint256) {
        return _cadOracle
            .usdtToCad(amount.mul(100))
            .div(_fixedPriceCADCent);
    }



    /**
    * @notice view how many tokens are currently available
    * @return amount of tokens available in the pool
    */
    function tokensAvailable() public view returns (uint256) {
        return _wToken.balanceOf(address(this));
    }

    /**
    * @notice view max amount of USD deposit that can be accepted
    * @return max amount of USD deposit (18 decimal places)
    */
    function availableTokenInUSD() external view returns (uint256) {
        return _cadOracle
            .cadToUsd(tokensAvailable().mul(_fixedPriceCADCent))
            .div(100);
    }
}