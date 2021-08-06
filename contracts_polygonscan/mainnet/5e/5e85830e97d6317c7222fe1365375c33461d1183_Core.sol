/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/3_Ballot.sol

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

//Required libs





//Options Market Contract
contract Core is  ReentrancyGuard {
    using SafeMath for uint256;
    fallback() external payable { }
    mapping (address => bool) public tokenActivated;

    //currently DAI is the stablecoin of choice and the address cannot be edited by anyone to prevent users unable to complete their option trade cycles under any circumstance. If the DAI address changes, a new contract should be used by users.
    address public daiTokenAddress = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    IERC20 daiToken = IERC20(daiTokenAddress);

    //mappings for sellers and buyers of options (database)
    mapping(address=> mapping(address=> mapping(bool=> mapping(uint256=>mapping(uint256=> mapping(uint256=>uint256)))))) public orderbook;
    mapping(address=> mapping(address=>mapping(bool=> mapping(uint256=>mapping(uint256=>uint256))))) public positions;
    mapping(address => mapping(address => uint256)) private _allowances;

    //Incrementing identifiers for orders. This number will be the last offer or purchase ID
    uint256 lastOrderId=0;
    uint256 lastPurchaseId =0;

    //All events based on major function executions (purchase, offers, exersizes and cancellations)
    event OptionPurchase(address buyer, address seller, address token, bool isCallOption, uint256 strikePrice, uint256 premium, uint256 expiry, uint256 amountPurchasing, uint256 purchaseId);
    event OptionOffer(address seller, address token, bool isCallOption, uint256 strikePrice, uint256 premium, uint256 expiry, uint256 amountSelling, uint256 orderId);
    event OptionExcersize(uint256 optionId, uint256 excersizeCost, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 value, uint256 purchaseId,uint256 timestamp);
    event Approval(address indexed owner, address indexed spender, uint256 value, uint256 purchaseId);

   //Structures of offers and purchases
    struct optionOffer {
        address seller;
        address token;
        bool isCallOption;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        uint256 amountUnderlyingToken;
        uint256 offeredTimestamp;
        bool isStillValid;
    }
    struct optionPurchase {
        address buyer;
        address seller;
        address token;
        bool isCallOption;
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        uint256 amountUnderlyingToken;
        uint256 offerId;
        uint256 purchasedTimestamp;
        bool exercized;
    }

    //publicly available data for all purchases and sale offers
    mapping (uint256 => optionPurchase) public optionPurchases;
    mapping (uint256 => optionOffer) public optionOffers;


    //Allows anyone to attempt to excersize an option after its excersize date. This can be done by a bot of the service provider or the user themselves
    function excersizeOption(uint256 purchaseId) public returns (bool){

        require(optionPurchases[purchaseId].exercized== false, "This option has already been excersized");
        require(optionPurchases[purchaseId].expiry >= block.timestamp, "This option has not reached its excersize timestamp yet");
        optionPurchase memory opData = optionPurchases[purchaseId];
        address underlyingAddress  = opData.token;
        IERC20 underlyingToken = IERC20(underlyingAddress);
        uint256 amountDAIToPay = opData.amountUnderlyingToken.mul(opData.strikePrice);
        require(daiToken.transferFrom(opData.buyer, opData.seller, amountDAIToPay), "Did the buyer approve this contract to handle DAI or have anough DAI to excersize?");
        optionPurchases[purchaseId].exercized= true;
        underlyingToken.transfer(opData.buyer, opData.amountUnderlyingToken);
        emit OptionExcersize(purchaseId, amountDAIToPay, block.timestamp);
        return true;

    }

    //This allows for the excersizing of many options with a single transaction
    function excersizeOptions(uint256[] memory purchaseIds) public returns (bool){
        for(uint i = 0; i<purchaseIds.length; i++){
            excersizeOption(purchaseIds[i]);
        }
        return true;
    }

    //This allows a user or smart contract to create a sell option order that anyone else can fill (completely or partially)
    function sellOption(address seller, address token, bool isCallOption, uint256 strikePrice, uint256 premium, uint256 expiry, uint256 amountUnderlyingToken) public returns(uint256 orderIdentifier){
        IERC20 underlyingToken = IERC20(token);
        uint256 contractBalanceBeforeTransfer = underlyingToken.balanceOf(address(this));
        underlyingToken.transferFrom(msg.sender, address(this), amountUnderlyingToken);
        uint256 contractBalanceAfterTransfer = underlyingToken.balanceOf(address(this));
        require(contractBalanceAfterTransfer >= (contractBalanceBeforeTransfer.add(amountUnderlyingToken)), "Could not transfer the amount from msg.sender that was requested");
        if(orderbook[seller][token][isCallOption][strikePrice][premium][expiry] ==0){
            orderbook[seller][token][isCallOption][strikePrice][premium][expiry] = amountUnderlyingToken;
        }
        else{
            orderbook[seller][token][isCallOption][strikePrice][premium][expiry] = orderbook[seller][token][isCallOption][strikePrice][premium][expiry].add(amountUnderlyingToken);
        }
        lastOrderId = lastOrderId.add(1);
        emit OptionOffer( seller, token, isCallOption, strikePrice, premium, expiry, amountUnderlyingToken, lastOrderId);
        return lastOrderId;
    }

    //This allows a user to immediately purchase an option based on the Id of an offer
    function buyOptionByID(address buyer,uint256 offerId, uint256 amountPurchasing) public returns (bool){
  		require(optionOffers[offerId].isStillValid== true, "This option is no longer valid");
  		optionOffer memory opData = optionOffers[offerId];
  		bool optionIsBuyable = isOptionBuyable(opData.seller, opData.token, opData.isCallOption, opData.strikePrice, opData.premium, opData.expiry, amountPurchasing);
  		require(optionIsBuyable, "This option is not buyable. Please check the seller's offer information");
      require(amountPurchasing <= opData.amountUnderlyingToken, "There is not enough inventory for this order");
      uint256 orderSize = opData.premium.mul(amountPurchasing);
      require(daiToken.transferFrom(msg.sender, opData.seller, orderSize), "Please ensure that you have approved this contract to handle your DAI (error)");
      orderbook[opData.seller][opData.token][opData.isCallOption][opData.strikePrice][opData.premium][opData.expiry].sub(amountPurchasing);
      positions[buyer][opData.token][opData.isCallOption][opData.strikePrice][opData.expiry].add(amountPurchasing);
      lastPurchaseId = lastPurchaseId.add(1);
      emit OptionPurchase(buyer, opData.seller, opData.token, opData.isCallOption, opData.strikePrice, opData.premium, opData.expiry, amountPurchasing, lastPurchaseId);
      return true;
    }

    //This allows a user to immediately purchase an option based on the seller and offer information
    function buyOptionByExactPremiumAndExpiry(address buyer, address seller, address token, bool isCallOption, uint256 strikePrice, uint256 premium, uint256 expiry, uint256 amountPurchasing ) public returns (bool){
        bool optionIsBuyable = isOptionBuyable(seller, token, isCallOption, strikePrice, premium, expiry, amountPurchasing);
        require(optionIsBuyable, "This option is not buyable. Please check the seller's offer information");
        require(optionIsBuyable, "Sorry: there is no one selling options that meet your specifications. Perhaps try buyOptionByIds");
        uint256 amountSelling = orderbook[seller][token][isCallOption][strikePrice][premium][expiry];
        require(amountPurchasing <= amountSelling," There is not enough inventory for this order");
        uint256 orderSize = premium.mul(amountPurchasing);
        require(daiToken.transferFrom(msg.sender, seller, orderSize), "Please ensure that you have approved this contract to handle your DAI (error)");
        orderbook[seller][token][isCallOption][strikePrice][premium][expiry]=orderbook[seller][token][isCallOption][strikePrice][premium][expiry].sub(amountPurchasing);
        positions[buyer][token][isCallOption][strikePrice][expiry]=positions[buyer][token][isCallOption][strikePrice][expiry].add(amountPurchasing);
        lastPurchaseId = lastPurchaseId.add(1);
        emit OptionPurchase(buyer, seller, token, isCallOption, strikePrice, premium, expiry, amountPurchasing, lastPurchaseId);
        return true;
    }

    //This allows a seller to cancel all or the remainder of an option offer and redeem their underlying. A seller cannot redeem the tokens that are needed by a user who already has purchased part of the offer
    function cancelOptionOffer(uint256 offerId) public returns(bool){
        //msg.sender is seller
        require(optionOffers[offerId].seller == msg.sender, "The msg.sender has to be the seller");
        uint256 amountUnderlyingToReturn = orderbook[msg.sender][optionOffers[offerId].token][optionOffers[offerId].isCallOption][optionOffers[offerId].strikePrice][optionOffers[offerId].premium][optionOffers[offerId].expiry];
        address underlyingAddress  = optionOffers[offerId].token;
        IERC20 underlyingToken = IERC20(underlyingAddress);
        orderbook[msg.sender][optionOffers[offerId].token][optionOffers[offerId].isCallOption][optionOffers[offerId].strikePrice][optionOffers[offerId].premium][optionOffers[offerId].expiry]= 0;
        optionOffers[offerId].isStillValid = false;
        underlyingToken.transfer(msg.sender, amountUnderlyingToReturn);
        return true;

    }

    //This allows a user to know if an option is purchasable based on the seller and offer information
    function isOptionBuyable(address seller, address token, bool isCallOption, uint256 strikePrice, uint256 premium, uint256 expiry, uint256 amountPurchasing) public view returns (bool){
        if(orderbook[seller][token][isCallOption][strikePrice][premium][expiry] >=amountPurchasing){
            return true;
        }
        else{
            return false;
        }
    }

    function transfer (address recipient, uint256 amount, uint256 purchaseId) public{//Transfer the amount of options from the msg.sender to the recipient address
        _transfer(msg.sender, recipient, amount,purchaseId);
    }

    function approve (address designee, uint256 amount , uint256 purchaseId ) public returns(bool){//allows the designee to spend an amount of options
        require(optionPurchases[purchaseId].buyer == msg.sender,'The sender must own the option');
        require(optionPurchases[purchaseId].amountUnderlyingToken>=amount,'Cannot approve more than owned');
        _allowances[msg.sender][designee]= amount;
        emit Approval(msg.sender, designee, amount, purchaseId);
    }

    function approval(address owner, address designee, uint256 purchaseId)public returns(uint256 approvalAmount){//return the amount of options the designee can spend
        return _allowances[owner][designee];
    }

    function transferFrom(address from , address recipient, uint256 amount,uint256 purchaseId) public {//Transfer the amount of options to the recipient address
        uint256 allowance = approval(from, recipient, purchaseId);
        require(allowance == 0 ,'Not approved');
        require(allowance>= amount,'Not approved for this amount');
        _transfer(from,recipient, amount, purchaseId);
        approve(recipient,allowance.sub(amount),purchaseId);
    }

    function _transfer(address sender, address recipient, uint256 amount,uint256 purchaseId) internal {//inernal transfer function
        require(optionPurchases[purchaseId].buyer == sender,'The sender must own the option');
        require(optionPurchases[purchaseId].amountUnderlyingToken>=amount,'Cannot tranfer more than owned');
        optionPurchase memory optData = optionPurchases[purchaseId];
        require(!optData.exercized,'cannot transfer an exercized option');
        positions[sender][optData.token][optData.isCallOption][optData.strikePrice][optData.expiry]=positions[sender][optData.token][optData.isCallOption][optData.strikePrice][optData.expiry].sub(amount);//adjust the position of the owner
        positions[recipient][optData.token][optData.isCallOption][optData.strikePrice][optData.expiry]=positions[recipient][optData.token][optData.isCallOption][optData.strikePrice][optData.expiry].add(amount);//adjust the position of the reciever
        emit Transfer(sender, recipient, amount, purchaseId, block.timestamp);
    }


}