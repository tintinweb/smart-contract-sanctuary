/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _governance;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_governance == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_governance, newOwner);
        _governance = newOwner;
    }
}

contract ReentrancyGuard {
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

    constructor () internal {
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

// File: contracts/strategies/ReethRouterV1.sol

pragma solidity =0.6.6;

// This is a wrapper router for Paraswap router
// It will take whatever fee is designated for it, convert it to WETH and calculate the total spent by the user with that
// This amount will be sent to the ETH spent oracle

interface SpentOracle{
    function addUserETHSpent(address _add, uint256 _ethback) external;
}

interface PartnerInfo{
    function getFee() external view returns(uint256);
    function getPartnerShare() external view returns(uint256);
}

interface WrappedEther {
    function withdraw(uint256) external;
    function deposit() external payable;
}

interface ParaswapProxy {
    function getTokenTransferProxy() external view returns (address);
}

contract ReethRouterV1 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public ethSpentOracleAddress;
    address public paraswapRouterAddress;
    address public paraswapPartnerAddress;
    address public reethTreasuryAddress;
    
    address constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 constant DIVISION_FACTOR = 100000;
    
    event SwappedTokens(address srcToken, address desToken, uint256 srcAmount, uint256 ethEquivalent);
    
    constructor(
        address _router,
        address _partner,
        address _ethspent,
        address _treasury
    ) public {
        paraswapPartnerAddress = _partner;
        paraswapRouterAddress = _router;
        ethSpentOracleAddress = _ethspent;
        reethTreasuryAddress = _treasury;
    }
    
    receive() external payable {
        // We need an anonymous fallback function to accept ether into this contract
    }
    
    // Called by eth_call to get the fee return of a route
    // It returns the feeamount and blocktime
    function querySwapTokensForTokensProxyFee(
                                        address srcToken, 
                                        address destToken, 
                                        uint256 srcAmount,
                                        bytes calldata paraswapTradeData
                                        ) external payable nonReentrant returns (uint256,uint256)
    {
        require(srcAmount > 0, "Amount is too small");
        require(srcToken != destToken, "Tokens are the same");
        
        // Transfer the token in
        uint256 _before = 0;
        if(srcToken != ETH_ADDRESS){
            _before = IERC20(srcToken).balanceOf(address(this));
            IERC20(srcToken).safeTransferFrom(_msgSender(), address(this), srcAmount);
            srcAmount = IERC20(srcToken).balanceOf(address(this)).sub(_before);
            // And set the approvals
            IERC20(srcToken).safeApprove(ParaswapProxy(paraswapRouterAddress).getTokenTransferProxy(), 0);
            IERC20(srcToken).safeApprove(ParaswapProxy(paraswapRouterAddress).getTokenTransferProxy(), srcAmount);
        }else{
            require(srcAmount == msg.value, "Sent uneven amount to router");
        }
        // Now do a function call to paraswap router with its data
        if(destToken != ETH_ADDRESS){
            _before = IERC20(destToken).balanceOf(address(this));
        }else{
            _before = address(this).balance;
        }
        {
            (bool success, bytes memory returndata) = paraswapRouterAddress.call{value: msg.value}(paraswapTradeData);
            if(success == false){
                // Look for revert reason and bubble it up if present
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
    
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("Failed for unknown reason");
                }
            }
        }
        if(srcToken != ETH_ADDRESS){
            uint256 _bal = IERC20(srcToken).balanceOf(address(this));
            if(_bal > 0){
                // Send it back to the sender if any source token left over
                IERC20(srcToken).safeTransfer(_msgSender(), _bal);
            }
        }
        // Whatever fee is obtained is returned
        uint256 feeAmount = 0;
        if(destToken != ETH_ADDRESS){
            feeAmount = IERC20(destToken).balanceOf(address(this)).sub(_before);
        }else{
            feeAmount = address(this).balance.sub(_before);
        }
        return (feeAmount, now); // To be used for actual call in destination token units
    }
    
    // Proxy function for paraswap 
    // We do not handle WETH to ETH conversions
    function swapTokensForTokensProxy(
                                    address srcToken, 
                                    address destToken, 
                                    uint256 srcAmount, 
                                    uint256 expFeeAmount, // This is in destination token units
                                    uint256 deadlineTime,
                                    bytes calldata paraswapTradeData,
                                    bytes calldata paraswapFeeData) external payable nonReentrant
    {
        uint256 gasUsed = gasleft(); // Start calculate gas spent
        require(srcAmount > 0 && expFeeAmount > 0, "Amounts are too small");
        require(srcToken != destToken, "Tokens are the same");
        require(now <= deadlineTime, "Time has run out");
        
        // Transfer the token in
        uint256 _before = 0;
        if(srcToken != ETH_ADDRESS){
            _before = IERC20(srcToken).balanceOf(address(this));
            IERC20(srcToken).safeTransferFrom(_msgSender(), address(this), srcAmount);
            srcAmount = IERC20(srcToken).balanceOf(address(this)).sub(_before);
            // And set the approvals
            IERC20(srcToken).safeApprove(ParaswapProxy(paraswapRouterAddress).getTokenTransferProxy(), 0);
            IERC20(srcToken).safeApprove(ParaswapProxy(paraswapRouterAddress).getTokenTransferProxy(), srcAmount);
        }else{
            require(srcAmount == msg.value, "Sent uneven amount to router");
        }
        // Now do a function call to paraswap router with its data
        if(destToken != ETH_ADDRESS){
            _before = IERC20(destToken).balanceOf(address(this));
        }else{
            _before = address(this).balance;
        }
        {
            (bool success, bytes memory returndata) = paraswapRouterAddress.call{value: msg.value}(paraswapTradeData);
            if(success == false){
                // Look for revert reason and bubble it up if present
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
    
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("Failed for unknown reason for swap");
                }
            }
        }
        if(srcToken != ETH_ADDRESS){
            uint256 _bal = IERC20(srcToken).balanceOf(address(this));
            if(_bal > 0){
                // Send it back to the sender if any source token left over
                IERC20(srcToken).safeTransfer(_msgSender(), _bal);
            }
        }
        // The receiver should get the tokens and only the fee should be returned here in destination tokens
        uint256 feeAmount = 0;
        if(destToken != ETH_ADDRESS){
            feeAmount = IERC20(destToken).balanceOf(address(this)).sub(_before);
        }else{
            // Only look at gained ETH for fee
            feeAmount = address(this).balance.sub(_before);
            // But convert all ETH to WETH
            WrappedEther(WETH_ADDRESS).deposit{value: address(this).balance}();
            destToken = WETH_ADDRESS;
        }
        require(feeAmount > 0, "There should be a fee here");
        require(expFeeAmount <= feeAmount, "Expected fee must be less than or equal to the actual");
        if(destToken != WETH_ADDRESS){
            // Do another trade to WETH from whatever token is there based on the expected fee (in destination token)
            // Expected fee calculated from a simulated previous trade
            IERC20(destToken).safeApprove(ParaswapProxy(paraswapRouterAddress).getTokenTransferProxy(), 0);
            IERC20(destToken).safeApprove(ParaswapProxy(paraswapRouterAddress).getTokenTransferProxy(), expFeeAmount);
            _before = IERC20(WETH_ADDRESS).balanceOf(address(this));
            {
                (bool success, bytes memory returndata) = paraswapRouterAddress.call(paraswapFeeData);
                if(success == false){
                    // Look for revert reason and bubble it up if present
                    if (returndata.length > 0) {
                        // The easiest way to bubble the revert reason is using memory via assembly
        
                        // solhint-disable-next-line no-inline-assembly
                        assembly {
                            let returndata_size := mload(returndata)
                            revert(add(32, returndata), returndata_size)
                        }
                    } else {
                        revert("Failed for unknown reason for fee");
                    }
                }
            }
            feeAmount = IERC20(WETH_ADDRESS).balanceOf(address(this)).sub(_before);
            uint256 _bal = IERC20(destToken).balanceOf(address(this));
            if(_bal > 0){
                // Send this dust amount of the random token to the treasury
                // This is not factored into the eth spent
                IERC20(destToken).safeTransfer(reethTreasuryAddress, _bal);
            }
        }
        {
            // Send whatever weth to the treasury
            uint256 _bal = IERC20(WETH_ADDRESS).balanceOf(address(this));
            if(_bal > 0){
                IERC20(WETH_ADDRESS).safeTransfer(reethTreasuryAddress, _bal);
            }
        }
        if(ethSpentOracleAddress != address(0)){
            // Factor this gas usage to stake into the oracle
            SpentOracle oracle = SpentOracle(ethSpentOracleAddress);
            uint256 spent = calculateTradeInETH(feeAmount);
            gasUsed = gasUsed.sub(gasleft()).mul(tx.gasprice); // The amount of ETH used for this transaction
            oracle.addUserETHSpent(_msgSender(), gasUsed);
            // Now add the feeAmount equivalent
            // Simple conversion to calculate the total trade worth in ETH
            // Take our exchange fee (0.%)  minus paraswap fee (15% of the 3%) => 0.255%
            // Divide fee / 0.255% to calculate trade worth
            // We will send this amount to the eth spent oracle
            oracle.addUserETHSpent(_msgSender(), spent);
            emit SwappedTokens(srcToken, destToken, srcAmount, spent.add(gasUsed));
        }
    }
    
    function calculateTradeInETH(uint256 ethAmount) internal view returns (uint256) {
        PartnerInfo partner = PartnerInfo(paraswapPartnerAddress);
        uint256 PARASWAP_DIVISOR = 10000;
        uint256 feePercent = partner.getFee().mul(DIVISION_FACTOR).mul(partner.getPartnerShare()).div(PARASWAP_DIVISOR).div(PARASWAP_DIVISOR);
        uint256 spent = ethAmount.mul(DIVISION_FACTOR).div(feePercent);
        return spent;
    }
    
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        require(now >= _timelockStart + TIMELOCK_DURATION, "Timelock time not met");
        _;
    }
    
    // Change the owner of the token contract
    // --------------------
    function startGovernanceChange(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external onlyGovernance timelockConditionsMet(1) {
        transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the paraswap partner contract
    // --------------------
    function startChangeParaswapPartner(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishChangeParaswapPartner() external onlyGovernance timelockConditionsMet(2) {
        paraswapPartnerAddress = _timelock_address;
    }
    // --------------------
    
    // Change the eth spent oracle
    // --------------------
    function startChangeSpentOracle(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_address = _address;
    }
    
    function finishChangeSpentOracle() external onlyGovernance timelockConditionsMet(3) {
        ethSpentOracleAddress = _timelock_address;
    }
    // --------------------
    
    // Change the reeth treastury
    // --------------------
    function startChangeReethTreasury(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 4;
        _timelock_address = _address;
    }
    
    function finishChangeReethTreasury() external onlyGovernance timelockConditionsMet(4) {
        reethTreasuryAddress = _timelock_address;
    }
    // --------------------
}