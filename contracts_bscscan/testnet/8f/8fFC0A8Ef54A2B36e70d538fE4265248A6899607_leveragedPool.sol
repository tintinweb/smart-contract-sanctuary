/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-20
*/

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.5.0;

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
    constructor () internal {
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


pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}




pragma solidity ^0.5.0;

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // new function method
    uint256 constant internal calDecimal = 1e18;

    function mulPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(mul(mul(prices[1],value),calDecimal),prices[0]) :
            div(mul(mul(prices[0],value),calDecimal),prices[1]);
    }

    function divPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(div(mul(prices[0],value),calDecimal),prices[1]) :
            div(div(mul(prices[1],value),calDecimal),prices[0]);
    }
}





pragma solidity =0.5.16;

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
        (bool success, ) = recipient.call.value(amount)("");
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
        (bool success, bytes memory returndata) = target.call.value(value )(data);
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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


pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

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
pragma solidity =0.5.16;




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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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
pragma solidity =0.5.16;

contract SafeTransfer{

    using SafeERC20 for IERC20;
    event Redeem(address indexed recieptor,address indexed token,uint256 amount);

    /**
     * @notice  transfers money to the pool
     * @dev function to transfer
     * @param token of address
     * @param amount of amount
     * @return return amount
     */
    function getPayableAmount(address token,uint256 amount) internal returns (uint256) {
        if (token == address(0)){
            amount = msg.value;
        }else if (amount > 0){
            IERC20 oToken = IERC20(token);
            oToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        return amount;
    }

    /**
     * @dev An auxiliary foundation which transter amount stake coins to recieptor.
     * @param recieptor account.
     * @param token address
     * @param amount redeem amount.
     */
    function _redeem(address payable recieptor,address token,uint256 amount) internal{
        if (token == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 oToken = IERC20(token);
            oToken.safeTransfer(recieptor,amount);
        }
        emit Redeem(recieptor,token,amount);
    }
}







pragma solidity =0.5.16;


interface IStakePool {
    function poolToken()external view returns (address);
    function loan(address account) external view returns(uint256);
    function PPTCoin()external view returns (address);
    function interestRate()external view returns (uint64);
    function setInterestRate(uint64 interestrate)external;
    function interestInflation(uint64 inflation)external;
    function poolBalance() external view returns (uint256);
    function borrowLimit(address account)external view returns (uint256);
    function borrow(uint256 amount) external returns(uint256);
    function borrowAndInterest(uint256 amount) external;
    function repay(uint256 amount,bool bAll) external payable;
    function repayAndInterest(uint256 amount) external payable;
    function setPoolInfo(address PPTToken,address stakeToken,uint64 interestrate) external;
}






pragma solidity =0.5.16;

interface IRebaseToken {

    function changeTokenName(string calldata _name, string calldata _symbol,address token)external;
    function calRebaseRatio(uint256 newTotalSupply) external;
    function newErc20(uint256 leftAmount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}



pragma solidity =0.5.16;


interface IBSCLeverageOracle {
    /**
      * @notice retrieves price of an asset
      * @dev function to get price for an asset
      * @param asset Asset for which to get the price
      * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
      */
    function getPrice(address asset) external view returns (uint256);
    function getUnderlyingPrice(uint256 cToken) external view returns (uint256);
    function getPrices(uint256[] calldata assets) external view returns (uint256[]memory);
    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) external view returns (uint256,uint256);
}







pragma solidity =0.5.16;


contract ImportOracle is Ownable{

    IBSCLeverageOracle internal _oracle;

    function oraclegetPrices(uint256[] memory assets) internal view returns (uint256[]memory){
        uint256[] memory prices = _oracle.getPrices(assets);
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
        require(prices[i] >= 100 && prices[i] <= 1e30,"oracle price error");
        }
        return prices;
    }

    function oraclePrice(address asset) internal view returns (uint256){
        uint256 price = _oracle.getPrice(asset);
        require(price >= 100 && price <= 1e30,"oracle price error");
        return price;
    }

    function oracleUnderlyingPrice(uint256 cToken) internal view returns (uint256){
        uint256 price = _oracle.getUnderlyingPrice(cToken);
        require(price >= 100 && price <= 1e30,"oracle price error");
        return price;
    }

    function oracleAssetAndUnderlyingPrice(address asset,uint256 cToken) internal view returns (uint256,uint256){
        (uint256 price1,uint256 price2) = _oracle.getAssetAndUnderlyingPrice(asset,cToken);
        require(price1 >= 100 && price1 <= 1e30,"oracle price error");
        require(price2 >= 100 && price2 <= 1e30,"oracle price error");
        return (price1,price2);
    }

    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }

    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = IBSCLeverageOracle(oracle);
    }
}







pragma solidity =0.5.16;



contract leveragedPool is Ownable, ReentrancyGuard, SafeTransfer, ImportOracle{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant internal calDecimal = 1e18;
    uint256 constant internal feeDecimal = 1e8;
    struct leverageInfo {
        uint8 id;
        bool bRebase;
        address token;
        IStakePool stakePool;
        uint256 leverageRate;
        uint256 rebalanceWorth;
        IRebaseToken leverageToken;
    }
    leverageInfo internal leverageCoin;
    leverageInfo internal hedgeCoin;
    address public swapRouter;
    address public phxSwapLib;
    uint256[2] public rebalancePrices;
    uint256[2] internal currentPrice;
    uint256 public buyFee;
    uint256 public sellFee;
    uint256 public rebalanceFee;
    uint256 public defaultLeverageRatio;
    uint256 public defaultRebalanceWorth;
    uint256 public rebaseThreshold;
    uint256 public liquidateThreshold;

    address payable public feeAddress;
    uint256 public rebalanceTol;

    event Swap(address indexed fromCoin,address indexed toCoin,uint256 fromValue,uint256 toValue);
    event Redeem(address indexed recieptor,address indexed Coin,uint256 amount);
    event BuyLeverage(address indexed from,address indexed Coin,uint256 payAmount,uint256 leverageAmount,uint256 tokenPrice);
    event BuyHedge(address indexed from,address indexed Coin,uint256 payAmount,uint256 hedgeAmount,uint256 tokenPrice);
    event SellLeverage(address indexed from,address indexed Coin,uint256 leverageAmount,uint256 amount,uint256 tokenPrice);
    event SellHedge(address indexed from,address indexed Coin,uint256 hedgeAmount,uint256 amount,uint256 tokenPrice);
    event Rebalance(address indexed from,address indexed token,uint256 buyAount,uint256 sellAmount);
    event Liquidate(address indexed from,address indexed token,uint256 loan,uint256 fee,uint256 leftAmount);

    constructor ( )  public{
        rebalanceTol = 5e7;
    }

    function() external payable {
    }

    function setSwapRouterAddress(address _swapRouter)public onlyOwner{
        require(swapRouter != _swapRouter,"swapRouter : same address");

        if(leverageCoin.token != address(0)){
            IERC20 oToken = IERC20(leverageCoin.token);
            oToken.safeApprove(swapRouter,0);
            oToken.safeApprove(_swapRouter,uint256(-1));
        }
        if(hedgeCoin.token != address(0)){
            IERC20 oToken = IERC20(hedgeCoin.token);
            oToken.safeApprove(swapRouter,0);
            oToken.safeApprove(_swapRouter,uint256(-1));
        }
        swapRouter = _swapRouter;
    }

    function setSwapLibAddress(address _swapLib)public onlyOwner{
        phxSwapLib = _swapLib;
    }

    function setFeeAddress(address payable addrFee) onlyOwner external {
        feeAddress = addrFee;
    }

    function getLeverageRebase() external view returns (bool,bool) {
        return (leverageCoin.bRebase,hedgeCoin.bRebase);
    }

    function getCurrentLeverageRate()external view returns (uint256,uint256) {
        uint256[2] memory underlyingPrice = getUnderlyingPriceView();
        return (_getCurrentLeverageRate(leverageCoin,underlyingPrice),   _getCurrentLeverageRate(hedgeCoin,underlyingPrice));
    }

    function _getCurrentLeverageRate(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice)internal view returns (uint256){
        uint256 leverageCp = coinInfo.leverageRate.mulPrice(underlyingPrice, coinInfo.id);
        uint256 leverageRp = (coinInfo.leverageRate-feeDecimal).mulPrice(rebalancePrices, coinInfo.id);
        return leverageCp.mul(feeDecimal).div(leverageCp.sub(leverageRp));
    }

    function getLeverageInfo() external view returns (address,address,address,uint256,uint256) {
        return (leverageCoin.token, address(leverageCoin.stakePool),address(leverageCoin.leverageToken),leverageCoin.leverageRate,leverageCoin.rebalanceWorth);
    }

    function getHedgeInfo() external view returns (address,address,address,uint256,uint256) {
        return (hedgeCoin.token,address(hedgeCoin.stakePool),address(hedgeCoin.leverageToken),hedgeCoin.leverageRate,hedgeCoin.rebalanceWorth);
    }

    function setLeverageFee(uint256 _buyFee,uint256 _sellFee,uint256 _rebalanceFee) onlyOwner external{
        require(_buyFee<5e6 && _sellFee<5e6 &&_rebalanceFee<5e6,"Leverage fee is beyond the limit");
        buyFee = _buyFee;
        sellFee = _sellFee;
        rebalanceFee = _rebalanceFee;
    }

     function setLeveragePoolInfo(address payable _feeAddress,address leveragePool,address hedgePool,
        address oracle,address _swapRouter,address swaplib,address rebaseTokenA,address rebaseTokenB,
        uint256 _buyFees,uint256 _sellFees,uint256 _rebalanceFee,uint256 _defaultLeverageRatio,
        uint256 _threshold,uint256 _liquidateThreshold,uint256 rebaseWorth) onlyOwner external{

            setLeveragePoolAddress(_feeAddress,leveragePool,hedgePool,oracle,_swapRouter,swaplib);

            setLeveragePoolInfo_sub(rebaseTokenA,rebaseTokenB,_buyFees,_sellFees,_rebalanceFee,
                _threshold,rebaseWorth,_defaultLeverageRatio,_liquidateThreshold);
        }

    function setLeveragePoolAddress(address payable _feeAddress,address leveragePool,address hedgePool,
        address oracle,address _swapRouter,address swaplib)internal{
        feeAddress = _feeAddress;
        _oracle = IBSCLeverageOracle(oracle);
        swapRouter = _swapRouter;
        phxSwapLib = swaplib;

        setStakePool(leverageCoin,0,leveragePool);
        setStakePool(hedgeCoin,1,hedgePool);
    }

    function setLeveragePoolInfo_sub(address rebaseTokenA,address rebaseTokenB,
        uint256 _buyFees,uint256 _sellFees,uint256 _rebalanceFee,uint256 _threshold,
        uint256 rebaseWorth, uint256 _defaultLeverageRatio, uint256 _liquidateThreshold) internal {
        rebalancePrices = getUnderlyingPriceView();
        defaultLeverageRatio = _defaultLeverageRatio;
        defaultRebalanceWorth = rebaseWorth;
        leverageCoin.leverageRate = defaultLeverageRatio;
        leverageCoin.rebalanceWorth = rebaseWorth*calDecimal/rebalancePrices[0];
        leverageCoin.leverageToken = IRebaseToken(rebaseTokenA);
        hedgeCoin.leverageRate = defaultLeverageRatio;
        hedgeCoin.rebalanceWorth = rebaseWorth*calDecimal/rebalancePrices[1];
        hedgeCoin.leverageToken = IRebaseToken(rebaseTokenB);
        buyFee = uint64(_buyFees);
        sellFee = uint64(_sellFees);
        rebalanceFee = uint64(_rebalanceFee);
        rebaseThreshold = uint128(_threshold);
        liquidateThreshold = uint128(_liquidateThreshold);
    }

    function setStakePool(leverageInfo storage coinInfo,uint8 id,address stakePool) internal{
        coinInfo.id = id;
        coinInfo.stakePool = IStakePool(stakePool);
        coinInfo.token = coinInfo.stakePool.poolToken();
        if(coinInfo.token != address(0)){
            IERC20 oToken = IERC20(coinInfo.token);
            oToken.safeApprove(swapRouter,uint256(-1));
            oToken.safeApprove(stakePool,uint256(-1));
        }
    }

    function underlyingBalance(uint8 id)internal view returns (uint256){
        address token = (id == 0) ? hedgeCoin.token : leverageCoin.token;
        if (token == address(0)){
            return address(this).balance;
        }else{
            return IERC20(token).balanceOf(address(this));
        }
    }

    function getTotalworths() public view returns(uint256,uint256){
        uint256[2] memory underlyingPrice = getUnderlyingPriceView();
        return (_totalWorth(leverageCoin,underlyingPrice),   _totalWorth(hedgeCoin,underlyingPrice));
    }

    function getTokenNetworths() public view returns(uint256,uint256){
        uint256[2] memory underlyingPrice = getUnderlyingPriceView();
        return (_tokenNetworth(leverageCoin,underlyingPrice),_tokenNetworth(hedgeCoin,underlyingPrice));
    }

    function _totalWorth(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice) internal view returns (uint256){
        uint256 totalSup = coinInfo.leverageToken.totalSupply();
        uint256 allLoan = (totalSup.mul(coinInfo.rebalanceWorth)/feeDecimal).mul(coinInfo.leverageRate-feeDecimal);
        return underlyingBalance(coinInfo.id).mulPrice(underlyingPrice,coinInfo.id).sub(allLoan);
    }

    function buyPrices() public view returns(uint256,uint256){
        uint256[2] memory underlyingPrice = getUnderlyingPriceView();
        return (_tokenNetworthBuy(leverageCoin,underlyingPrice),_tokenNetworthBuy(hedgeCoin,underlyingPrice));
    }

    function _tokenNetworthBuy(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice) internal view returns (uint256){
        uint256 curValue = coinInfo.rebalanceWorth.mul(coinInfo.leverageRate).mulPrice(underlyingPrice,coinInfo.id).divPrice(rebalancePrices,coinInfo.id);
        return curValue.sub(coinInfo.rebalanceWorth.mul(coinInfo.leverageRate-feeDecimal))/feeDecimal;
    }

    function _tokenNetworth(leverageInfo memory coinInfo,uint256[2] memory underlyingPrice) internal view returns (uint256){
        uint256 tokenNum = coinInfo.leverageToken.totalSupply();
        if (tokenNum == 0){
            return coinInfo.rebalanceWorth;
        }else{
            return _totalWorth(coinInfo,underlyingPrice)/tokenNum;
        }
    }

    function buyLeverage(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _buy(leverageCoin,amount,minAmount,deadLine,true);
    }

    function buyHedge(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/)  external payable{
        _buy(hedgeCoin, amount,minAmount,deadLine,true);
    }

    function buyLeverage2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _buy(leverageCoin,amount,minAmount,deadLine,false);
    }

    function buyHedge2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _buy(hedgeCoin, amount,minAmount,deadLine,false);
    }

    function sellLeverage(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _sell(leverageCoin,amount,minAmount,deadLine,true);
    }

    function sellHedge(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/)  external payable{
        _sell(hedgeCoin, amount,minAmount,deadLine,true);
    }

    function sellLeverage2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _sell(leverageCoin,amount,minAmount,deadLine,false);
    }

    function sellHedge2(uint256 amount,uint256 minAmount,uint256 deadLine,bytes calldata /*data*/) external payable{
        _sell(hedgeCoin, amount,minAmount,deadLine,false);
    }

    function delegateCallSwap(bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = phxSwapLib.call(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    function _swap(address token0,address token1,uint256 amountSell) internal returns (uint256){
        return abi.decode(delegateCallSwap(abi.encodeWithSignature("swap(address,address,address,uint256)",swapRouter,token0,token1,amountSell)), (uint256));
    }

    // TODO : 测试emit 事件日志
    // TODO : event Swap(address indexed fromCoin,address indexed toCoin,uint256 fromValue,uint256 toValue);
    event Amount(uint256 amount);
    event Price(uint256 price);
    event LeverageAmount(uint256 leverageamount);
    event LoanAmount(uint256 loanamount);

    function _buy(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,uint256 deadLine,bool bFirstToken) ensure(deadLine) nonReentrant getUnderlyingPrice internal{
        address inputToken;
        if(bFirstToken){
            inputToken = coinInfo.token;
        }else{
            inputToken = (coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token;
        }
        // inputToken = BUSD
        amount = getPayableAmount(inputToken,amount);
        emit Amount(amount);

        require(amount > 0, 'buy amount is zero');
        uint256 userPay = amount;
        amount = redeemFees(buyFee,inputToken,amount);
        emit Amount(amount);

        uint256 price = _tokenNetworthBuy(coinInfo,currentPrice);
        emit Price(price);

        uint256 leverageAmount = bFirstToken ? amount.mul(calDecimal)/price:
            amount.mulPrice(currentPrice,coinInfo.id)/price;
        emit LeverageAmount(leverageAmount);

        require(leverageAmount>=minAmount,"token amount is less than minAmount");
        {
            uint256 userLoan = (leverageAmount.mul(coinInfo.rebalanceWorth)/calDecimal).mul(coinInfo.leverageRate-feeDecimal)/feeDecimal;
            userLoan = coinInfo.stakePool.borrow(userLoan);
            emit LoanAmount(userLoan);

            amount = bFirstToken ? userLoan.add(amount) : userLoan;
            emit Amount(amount);

            //98%
            uint256 amountOut = amount.mul(98e16).divPrice(currentPrice,coinInfo.id);
            address token1 = (coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token;
            amount = _swap(coinInfo.token,token1,amount);
            emit Amount(amount);
            require(amount>=amountOut, "swap slip page is more than 2%");
        }
        coinInfo.leverageToken.mint(msg.sender,leverageAmount);
        price = price.mul(currentPrice[coinInfo.id])/calDecimal;
        if(coinInfo.id == 0){
            emit BuyLeverage(msg.sender,inputToken,userPay,leverageAmount,price);
        }else{
            emit BuyHedge(msg.sender,inputToken,userPay,leverageAmount,price);
        }
    }

    function _sellSwap(uint8 id,uint256 sellAmount,uint256 userLoan)internal returns(uint256){
        (address token0,address token1) = (id == 0) ? (hedgeCoin.token,leverageCoin.token) : (leverageCoin.token,hedgeCoin.token);
        sellAmount = _swap(token0,token1,sellAmount);
        return sellAmount.sub(userLoan);
    }

    function _sellSwap2(uint8 id,uint256 sellAmount,uint256 userLoan)internal returns(uint256){
        (address token0,address token1) = (id == 0) ? (hedgeCoin.token,leverageCoin.token) : (leverageCoin.token,hedgeCoin.token);
        (uint256 amountIn,) = abi.decode(
            delegateCallSwap(abi.encodeWithSignature("sellExactAmount(address,address,address,uint256)",swapRouter,token0,token1,userLoan)), (uint256,uint256));
        return sellAmount.sub(amountIn);
    }

    function _sell(leverageInfo memory coinInfo,uint256 amount,uint256 minAmount,uint256 deadLine,bool bFirstToken) ensure(deadLine) nonReentrant getUnderlyingPrice internal{
        require(amount > 0, 'sell amount is zero');
        uint256 total = coinInfo.leverageToken.totalSupply();
        uint256 getLoan = coinInfo.stakePool.loan(address(this)).mul(calDecimal);

        uint256 userLoan;
        uint256 sellAmount;
        uint256 userPayback;
        if(total == amount){
            userLoan = getLoan;
            sellAmount = underlyingBalance(coinInfo.id);
        }else{
            userLoan = (amount.mul(coinInfo.rebalanceWorth)/feeDecimal).mul(coinInfo.leverageRate-feeDecimal);
            if(userLoan > getLoan){
                userLoan = getLoan;
            }
            userPayback =  amount.mul(_tokenNetworth(coinInfo,currentPrice));
            sellAmount = userLoan.add(userPayback).divPrice(currentPrice,coinInfo.id);  
        }
        userLoan = userLoan/calDecimal;
        address outputToken;
        uint256 sellPrice;
        if (bFirstToken){
            userPayback = _sellSwap(coinInfo.id,sellAmount,userLoan);
            outputToken = coinInfo.token;
            sellPrice = userPayback.mul(currentPrice[coinInfo.id])/amount;
        }else{
            userPayback = _sellSwap2(coinInfo.id,sellAmount,userLoan);
            outputToken = coinInfo.id == 0 ? hedgeCoin.token : leverageCoin.token;
            uint256 id = coinInfo.id == 0 ? 1 : 0;
            sellPrice = userPayback.mul(currentPrice[id])/amount;
        }
        userPayback = redeemFees(sellFee,outputToken,userPayback);
        require(userPayback >= minAmount, "Repay amount is less than minAmount");
        _repay(coinInfo,userLoan,false);
        _redeem(msg.sender,outputToken,userPayback);
        coinInfo.leverageToken.burn(msg.sender,amount);
        if(coinInfo.id == 0){
            emit SellLeverage(msg.sender,outputToken,amount,userPayback,sellPrice);
        }else{
            emit SellHedge(msg.sender,outputToken,amount,userPayback,sellPrice);
        }
    }

    function _settle(leverageInfo storage coinInfo) internal returns(uint256,uint256){
        if (coinInfo.leverageToken.totalSupply() == 0){
            return (0,0);
        }
        uint256 insterest = coinInfo.stakePool.interestRate();
        uint256 totalWorth = _totalWorth(coinInfo,currentPrice).divPrice(currentPrice,coinInfo.id);
        totalWorth = redeemFees(rebalanceFee, (coinInfo.id == 0) ? hedgeCoin.token : leverageCoin.token, totalWorth);
        uint256 oldUnderlying = underlyingBalance(coinInfo.id).mulPrice(currentPrice,coinInfo.id)/calDecimal;
        uint256 oldLoan = coinInfo.stakePool.loan(address(this));
        uint256 oldLoanAdd = oldLoan.mul(feeDecimal)/(feeDecimal.sub(insterest));
        if(oldUnderlying>oldLoanAdd){
            uint256 leverageRate = oldUnderlying.mul(feeDecimal)/(oldUnderlying-oldLoanAdd);
            if(leverageRate <defaultLeverageRatio+rebalanceTol && leverageRate >defaultLeverageRatio-rebalanceTol){
                    return (0,0);
            }
        }
        uint256 leverageRate = defaultLeverageRatio;
        uint256 allLoan = oldUnderlying.sub(oldLoan).mul(leverageRate-feeDecimal).mul(feeDecimal);
        allLoan = allLoan/(feeDecimal*feeDecimal+leverageRate*insterest-2*feeDecimal*insterest);
        uint256 poolBorrow = coinInfo.stakePool.borrowLimit(address(this));
        if(allLoan > poolBorrow){
            allLoan = poolBorrow;
            totalWorth = oldUnderlying.sub(oldLoan).mul(feeDecimal).sub(allLoan.mul(insterest));
        }else{
            totalWorth = allLoan.mul((feeDecimal-insterest)*feeDecimal)/(leverageRate-feeDecimal)/feeDecimal;
        }
        uint256 newUnderlying = totalWorth+allLoan;
        if(oldUnderlying>newUnderlying){
            return (0,oldUnderlying-newUnderlying);
        }else{
            return (newUnderlying-oldUnderlying,0);
        }
    }

    function swapRebalance(address token0,address token1,uint256 amountLev,uint256 amountHe,uint256[2] memory prices,uint256 id)internal returns (uint256,uint256){
        return abi.decode(delegateCallSwap(abi.encodeWithSignature("swapRebalance(address,address,address,uint256,uint256,uint256[2],uint256)",
            swapRouter,token0,token1,amountLev,amountHe,prices,id)), (uint256,uint256));
    }

    function rebalance() getUnderlyingPrice onlyOwner external {
        _rebalance();
    }

    function _rebalance() internal {
        uint256 levSlip = calAverageSlip(leverageCoin);
        uint256 heSlip = calAverageSlip(hedgeCoin);

        (uint256 buyLev,uint256 sellLev) = _settle(leverageCoin);
        emit Rebalance(msg.sender,leverageCoin.token,buyLev,sellLev);

        (uint256 buyHe,uint256 sellHe) = _settle(hedgeCoin);
        emit Rebalance(msg.sender,hedgeCoin.token,buyHe,sellHe);

        rebalancePrices = currentPrice;
        if (buyLev>0){
            leverageCoin.stakePool.borrowAndInterest(buyLev);
        }
        if(buyHe>0){
            hedgeCoin.stakePool.borrowAndInterest(buyHe);
        }
        if (buyLev > 0 && buyHe>0){
            swapRebalance(leverageCoin.token,hedgeCoin.token,buyLev,buyHe,currentPrice,0);
        }else if(buyLev>0){
            swapRebalance(leverageCoin.token,hedgeCoin.token,buyLev,sellHe.mulPrice(currentPrice,0)/calDecimal,currentPrice,2<<128);
        }else if(buyHe>0){
            swapRebalance(hedgeCoin.token,leverageCoin.token,buyHe,sellLev.mulPrice(currentPrice,1)/calDecimal,currentPrice,(2<<128)+1);
        }else{
            if(sellLev>0 || sellHe> 0){
                (sellLev,sellHe)= swapRebalance(leverageCoin.token,hedgeCoin.token,sellLev,sellHe,currentPrice,1<<128);
            }
        }
        if(buyLev == 0){
            _repayAndInterest(leverageCoin,sellLev);
        }
        if(buyHe == 0){
            _repayAndInterest(hedgeCoin,sellHe);
        }
        calLeverageInfo(leverageCoin,levSlip);
        calLeverageInfo(hedgeCoin,heSlip);
    }

    function calAverageSlip(leverageInfo memory coinInfo) internal view returns(uint256) {
        uint256 loan = coinInfo.stakePool.loan(address(this));
        if(loan>0){
            return underlyingBalance(coinInfo.id).mulPrice(rebalancePrices, coinInfo.id).mul(coinInfo.leverageRate - feeDecimal)/coinInfo.leverageRate/loan/(calDecimal/feeDecimal);
        }else{
            return feeDecimal;
        }
    }

    function calLeverageInfo(leverageInfo storage coinInfo,uint256 swapSlip) internal{
        uint256 tokenNum = coinInfo.leverageToken.totalSupply();
        if(tokenNum > 0){
            uint256 balance = underlyingBalance(coinInfo.id).mulPrice(rebalancePrices, coinInfo.id).mul(feeDecimal)/swapSlip;
            uint256 loan = coinInfo.stakePool.loan(address(this));
            uint256 totalWorth = balance.sub(loan.mul(calDecimal));
            coinInfo.leverageRate = balance.mul(feeDecimal)/totalWorth;
            if (coinInfo.bRebase){
                coinInfo.rebalanceWorth = defaultRebalanceWorth*calDecimal/currentPrice[coinInfo.id];
                coinInfo.bRebase = false;
                coinInfo.leverageToken.calRebaseRatio(totalWorth/coinInfo.rebalanceWorth);
            }else{
                coinInfo.rebalanceWorth = totalWorth/tokenNum;
                coinInfo.bRebase = coinInfo.rebalanceWorth<defaultRebalanceWorth.mul(feeDecimal*calDecimal)/currentPrice[coinInfo.id]/rebaseThreshold;
            }
        }
    }

    function rebalanceAndLiquidate() external getUnderlyingPrice {
        if(checkLiquidate(leverageCoin,currentPrice,liquidateThreshold)){
            _liquidate(leverageCoin);
        }else if(checkLiquidate(hedgeCoin,currentPrice,liquidateThreshold)){
            _liquidate(hedgeCoin);
        }else if(checkLiquidate(leverageCoin,currentPrice,liquidateThreshold*4) ||
            checkLiquidate(hedgeCoin,currentPrice,liquidateThreshold*4)){
            _rebalance();
        }else{
            require(false, "Liquidate: current price is not under the threshold!");
        }
    }

    function _liquidate(leverageInfo storage coinInfo) internal{
        (address token0,address token1) = (coinInfo.id == 0) ? (hedgeCoin.token,leverageCoin.token) : (leverageCoin.token,hedgeCoin.token);
        uint256 amount = _swap(token0,token1,underlyingBalance(coinInfo.id));
        uint256 fee = amount.mul(rebalanceFee)/feeDecimal;
        uint256 leftAmount = amount.sub(fee);
        uint256 allLoan = coinInfo.stakePool.loan(address(this));
        if (amount<allLoan){
            allLoan = amount;
            leftAmount = amount;
            fee = 0;
        }else if(leftAmount<allLoan){
            leftAmount = allLoan;
            fee = amount-leftAmount;
        }
        if(fee>0){
            _redeem(feeAddress,coinInfo.token, fee);
        }
        _repay(coinInfo,allLoan,true);
        leftAmount = leftAmount - allLoan;
        if(leftAmount>0){
            _redeem(address(uint160(address(coinInfo.leverageToken))),coinInfo.token,leftAmount);
        }
        coinInfo.leverageToken.newErc20(leftAmount);
        emit Liquidate(msg.sender,coinInfo.token,allLoan,fee,leftAmount);
    }

    function _repay(leverageInfo memory coinInfo,uint256 amount,bool bAll)internal{
        if (coinInfo.token == address(0)){
            coinInfo.stakePool.repay.value(amount)(amount,bAll);
        }else{
            coinInfo.stakePool.repay(amount,bAll);
        }
    }

    function _repayAndInterest(leverageInfo memory coinInfo,uint256 amount)internal{
        if (coinInfo.token == address(0)){
            coinInfo.stakePool.repayAndInterest.value(amount)(amount);
        }else{
            coinInfo.stakePool.repayAndInterest(amount);
        }
    }

    function redeemFees(uint256 feeRatio,address token,uint256 amount) internal returns (uint256){
        uint256 fee = amount.mul(feeRatio)/feeDecimal;
        if (fee>0){
            _redeem(feeAddress,token, fee);
        }
        return amount.sub(fee);
    }

    function getUnderlyingPriceView() public view returns(uint256[2]memory){
        uint256[] memory assets = new uint256[](2);
        assets[0] = uint256(leverageCoin.token);
        assets[1] = uint256(hedgeCoin.token);
        uint256[]memory prices = oraclegetPrices(assets);
        return [prices[0],prices[1]];
    }

    function getEnableRebalanceAndLiquidate()external view returns (bool,bool){
        uint256[2]memory prices = getUnderlyingPriceView();
        uint256 threshold = liquidateThreshold*39e7/feeDecimal;
        return (checkLiquidate(leverageCoin,prices,threshold),
                checkLiquidate(hedgeCoin,prices,threshold));
    }

    function checkLiquidate(leverageInfo memory coinInfo,uint256[2]memory prices,uint256 threshold) internal view returns(bool){
        if(coinInfo.leverageToken.totalSupply() == 0){
            return false;
        }
        return coinInfo.leverageRate.mulPrice(prices,coinInfo.id) <
            (coinInfo.leverageRate-feeDecimal+threshold).mulPrice(rebalancePrices,coinInfo.id);
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'leveragedPool: EXPIRED');
        _;
    }

    modifier getUnderlyingPrice(){
        currentPrice = getUnderlyingPriceView();
        _;
    }
}