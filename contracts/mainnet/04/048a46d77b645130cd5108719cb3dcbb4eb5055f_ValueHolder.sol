/**
 *Submitted for verification at Etherscan.io on 2020-12-27
*/

// File: localhost/contracts/access/Context.sol

// SPDX-License-Identifier: MIT

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
// File: localhost/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

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
    function initialize() internal {
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
// File: localhost/contracts/interfaces/IWETH.sol


pragma solidity ^0.6.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
// File: localhost/contracts/interfaces/IXChanger.sol


pragma solidity ^0.6.0;


interface XChanger {
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        bool slipProtect
    ) external payable returns (uint result);
    
    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) external view returns (uint returnAmount);
    
    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 returnAmount
    ) external view returns (uint inputAmount);
}
// File: localhost/contracts/utils/SafeERC20.sol


// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/utils/Address.sol



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

// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol

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
}


// File: browser/github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol


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

library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function universalTransfer(IERC20 token, address to, uint256 amount) internal {
        if (token == IERC20(0)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (token != IERC20(0)) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (token == IERC20(0)) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (token == IERC20(0)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}
// File: localhost/contracts/XChangerUser.sol


pragma solidity ^0.6.0;



contract XChangerUser {
    using UniversalERC20 for IERC20;
    
    XChanger public xchanger;

    function quote(
        IERC20 fromToken,
        IERC20 toToken,
        uint amount
    ) public view returns (uint returnAmount) {
        if (fromToken == toToken) {
            returnAmount = amount;
        } else {
            (bool success, bytes memory data) = address(xchanger).staticcall(abi.encodeWithSelector(
                xchanger.quote.selector,
                fromToken,
                toToken,
                amount
            ));
            
            require (success && data.length > 0, 'XChanger quote not successful'); 
            
            (returnAmount) = abi.decode(data, (uint));    
        }
    }
    
    function reverseQuote(
        IERC20 fromToken,
        IERC20 toToken,
        uint returnAmount
    ) public view returns (uint inputAmount) {
        if (fromToken == toToken) {
            inputAmount = returnAmount;
        } else {
            (bool success, bytes memory data) = address(xchanger).staticcall(abi.encodeWithSelector(
                xchanger.reverseQuote.selector,
                fromToken,
                toToken,
                returnAmount
            ));
            require (success && data.length > 0, 'XChanger reverseQuote not successful'); 
            
            (inputAmount) = abi.decode(data, (uint));       
            inputAmount += 1; // Curve requires this
        }
    }
    
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint amount,
        bool slipProtect
    ) public payable returns (uint returnAmount) {
        
        if (fromToken.allowance(address(this), address(xchanger)) != uint(-1)) {
            fromToken.universalApprove(address(xchanger), uint(-1));
        }
        
        returnAmount = xchanger.swap(fromToken, toToken, amount, slipProtect);
        
        /*
        (bool success, bytes memory data) = address(xchanger).delegatecall(abi.encodeWithSelector(
                xchanger.swap.selector,
                fromToken,
                toToken,
                amount,
                slipProtect
            ));
            
        require (success && data.length > 0, 'XChanger swap not successful'); 
        
        (returnAmount) = abi.decode(data, (uint));    */
    }
}
// File: localhost/contracts/interfaces/ICHI.sol


pragma solidity ^0.6.0;

interface ICHI {
    function freeFromUpTo(address from, uint256 value)
        external
        returns (uint256);

    function freeUpTo(uint256 value) external returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function mint(uint256 value) external;
}

// File: localhost/contracts/CHIBurner.sol


pragma solidity ^0.6.0;


contract CHIBurner {
    address public constant CHI_ADDRESS = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    ICHI public constant chi = ICHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;

        /*uint256 availableAmount = chi.balanceOf(msg.sender);
        uint256 allowedAmount = chi.allowance(msg.sender, address(this));
        if (allowedAmount < availableAmount) {
            availableAmount = allowedAmount;
        }
        uint256 ourBalance = chi.balanceOf(address(this));

        address sender;
        if (ourBalance > availableAmount) {
            sender = address(this);
            ourBalance = availableAmount;
        } else {
            sender = msg.sender;
        }

        if (ourBalance > 0) {*/
        uint256 gasLeft = gasleft();
        uint256 gasSpent = 21000 + gasStart - gasLeft + 16 * msg.data.length;
        //chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
        chi.freeUpTo((gasSpent + 14154) / 41947);
        //}
    }
}

// File: localhost/contracts/interfaces/ISFToken.sol


pragma solidity ^0.6.0;

interface ISFToken {
    function rebase(uint256 totalSupply) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

// File: localhost/contracts/interfaces/IExternalPool.sol


pragma solidity ^0.6.0;

abstract contract IExternalPool {
    address public enterToken;

    function getPoolValue(address denominator)
        external
        virtual
        view
        returns (uint256);

    function getTokenStaked() external virtual view returns (uint256);

    function addPosition() external virtual returns (uint256);

    function exitPosition(uint256 amount) external virtual;

    function claimValue() external virtual;
    
    function transferTokenTo(
        address TokenAddress,
        address recipient,
        uint256 amount
    ) external virtual returns (uint256);
}

// File: localhost/contracts/interfaces/IERC20.sol


pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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


    function decimals() external view returns (uint8);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: localhost/contracts/interfaces/IUniswapV2.sol


pragma solidity ^0.6.0;


interface IUniRouter {
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    
}

interface IUniswapV2Factory {
    function addLiquidity(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
    ) external returns (uint amountA, uint amountB);

    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Exchange pair);
}

interface IUniswapV2Exchange {
    //event Approval(address indexed owner, address indexed spender, uint value);
    //event Transfer(address indexed from, address indexed to, uint value);

    //function name() external pure returns (string memory);
    //function symbol() external pure returns (string memory);
    //function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    

    //function allowance(address owner, address spender) external view returns (uint);

    //function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    //function transferFrom(address from, address to, uint value) external returns (bool);

    //function DOMAIN_SEPARATOR() external view returns (bytes32);
    //function PERMIT_TYPEHASH() external pure returns (bytes32);
    //function nonces(address owner) external view returns (uint);

    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    //event Mint(address indexed sender, uint amount0, uint amount1);
    //event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    /*event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    */
    function token0() external view returns (address);

    function token1() external view returns (address);

    /*function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    */
}

// File: localhost/contracts/ValueHolder.sol


pragma solidity ^0.6.12;








contract ValueHolder is Ownable, CHIBurner, XChangerUser{
    using UniversalERC20 for IERC20;
    using SafeMath for uint256;
    
    mapping(uint => address) public uniPools;
    mapping(uint => address) public externalPools;

    uint public uniLen;
    uint public extLen;

    address public denominateTo;
    uint8 private denominateDecimals;
    uint8 private sfDecimals;
    address public SFToken;

    address public votedPool;
    enum PoolType {EXT, UNI}
    PoolType public votedPoolType;
    
    uint public votedFee; // 1% = 100
    uint public votedChi; // number of Chi to hold

    uint private constant fpDigits = 8;
    uint private constant fpNumbers = 10 ** fpDigits;
    
    event LogValueManagerUpdated(address Manager);
    event LogVoterUpdated(address Voter);
    event LogVotedExtPoolUpdated(address pool, PoolType poolType);
    event LogVotedUniPoolUpdated(address pool);
    event LogSFTokenUpdated(address _NewSFToken);
    event LogXChangerUpdated(address _NewXChanger);
    event LogFeeUpdated(uint newFee);
    event LogFeeTaken(uint feeAmount);
    event LogMintTaken(uint fromTokenAmount);
    event LogBurnGiven(uint toTokenAmount);
    event LogChiToppedUpdated(uint spendAmount);
    address public ValueManager;
    
    //address private constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IERC20 private constant WETH_ADDRESS = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    bool private initialized;
    
    modifier onlyValueManager() {
        require(msg.sender == ValueManager, "Not Value Manager");
        _;
    }

    address public Voter;
    modifier onlyVoter() {
        require(msg.sender == Voter, "Not Voter");
        _;
    }

    function initialize(
        address _votePool,
        PoolType _votePoolType,
        address _sfToken,
        address _Xchanger
    ) public {
        //XChanger._init();
        require(!initialized, "Initialized");
        initialized = true;
        _initVariables(_votePool, _votePoolType, _sfToken, _Xchanger);
        Ownable.initialize(); // Do not forget this call!
    }
    
    function _initVariables(
        address _votePool,
        PoolType _votePoolType,
        address _sfToken,
        address _Xchanger
    ) internal {
        uniLen = 0;
        extLen = 0;
        //0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f UNI

        externalPools[extLen] = _votePool;
        extLen++;

        votedPool = _votePool;
        votedPoolType = _votePoolType;
        if (votedPoolType == PoolType.UNI) {
            uniPools[uniLen] = _votePool;
            uniLen++;
        }
        
        emit LogVotedExtPoolUpdated(_votePool, _votePoolType);

        denominateTo = DAI_ADDRESS; //0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        denominateDecimals = IERC20(denominateTo).decimals();
        SFToken = _sfToken; //
        sfDecimals = IERC20(_sfToken).decimals();
        ValueManager = msg.sender;
        Voter = msg.sender;
        xchanger = XChanger(_Xchanger);
        votedFee = 200;
        votedChi = 10;
    }

    function reInit(
        address _extPool,
        PoolType _votePoolType,
        address _sfToken,
        address _Xchanger
    ) public onlyOwner {
        _initVariables(_extPool, _votePoolType, _sfToken, _Xchanger);
    }

    function setSFToken(address _NewSFToken) public onlyOwner {
        SFToken = _NewSFToken;
        emit LogSFTokenUpdated(_NewSFToken);
    }

    function setValueManager(address _ValueManager) external onlyOwner {
        ValueManager = _ValueManager;
        emit LogValueManagerUpdated(_ValueManager);
    }

    function setVoter(address _Voter) external onlyOwner {
        Voter = _Voter;
        emit LogVoterUpdated(_Voter);
    }
    
    function setXChangerImpl(address _Xchanger) external onlyVoter {
        xchanger = XChanger(_Xchanger);
        emit LogSFTokenUpdated(_Xchanger);
    }

    function setVotedPool(address pool, PoolType poolType) public onlyVoter {
        votedPool = pool;
        votedPoolType = poolType;
        emit LogVotedExtPoolUpdated(pool,poolType);
    }

    function setVotedFee(uint _votedFee) public onlyVoter {
        votedFee = _votedFee;
        emit LogFeeUpdated(_votedFee);
    }

    function setVotedChi(uint _votedChi) public onlyVoter {
        votedChi = _votedChi;
    }
    
    function retrieveToken(
        address TokenAddress
    ) external onlyValueManager returns (uint) {
        IERC20 Token = IERC20(TokenAddress);
        uint balance = Token.balanceOf(address(this));
        Token.universalTransfer(msg.sender, balance);
        return balance;
    }
    
    function topUpChi(address Token) public returns (uint spendAmount) {
        uint currentChi = chi.balanceOf(address(this));
        if (currentChi < votedChi) {
            
            IERC20 _Token = IERC20(Token);
            IERC20 _Chi = IERC20(CHI_ADDRESS);
            //top up 1/2 votedChi
            spendAmount = reverseQuote(
                _Token,
                _Chi,
                votedChi.div(2)
            );
            
            uint balance = _Token.balanceOf(address(this));
            if (spendAmount > balance) {
                spendAmount = balance;
            }
            
            if (spendAmount > 0) {
                swap(_Token, _Chi, spendAmount, false);
                LogChiToppedUpdated(spendAmount);
            }
        } 
    }

    function mintQuote(
        address fromToken,
        uint amount
    ) external view returns (uint returnAmount) {
        require (votedPool != address(0), 'No voted pool available');
        if (votedPoolType == PoolType.EXT) {
            IERC20 _fromToken = IERC20(fromToken);
            IERC20 _toToken = IERC20(IExternalPool(votedPool).enterToken());

            (returnAmount) = quote(
                _fromToken,
                _toToken,
                amount
            );
            
            (returnAmount) = quote(
                _toToken,
                IERC20(denominateTo),
                returnAmount
            );
            
        } else {
            revert("Other not yet implemented");
        }
    }

    function mint(address fromToken, uint amount)
        external
        payable
        discountCHI
    {
        require(votedPool != address(0), 'No voted pool available');
        require(amount > 0, 'Mint does not make sense');
        
        IERC20 _fromToken = IERC20(fromToken);
        if (fromToken != address(0)) {
            require(
                _fromToken.allowance(msg.sender, address(this)) >= amount,
                "Allowance is not enough"
            );
            uint balanceBefore = _fromToken.balanceOf(address(this));
            _fromToken.universalTransferFrom(msg.sender, address(this), amount);
            //confirmed amount
            amount = _fromToken.balanceOf(address(this)).sub(balanceBefore);
        } else {
            //convert to WETH
            IWETH(address(WETH_ADDRESS)).deposit{value: msg.value}();
            amount = msg.value;
            fromToken = address(WETH_ADDRESS);
            _fromToken = IERC20(fromToken);
        }
        emit LogMintTaken(amount);
        
        amount = amount.sub(topUpChi(fromToken));
        uint toMint;
        
        // we rebase before depositing token to pool as we dont want to count it yet
        _rebase(getTotalValue()+1);
        
        if (votedPoolType == PoolType.EXT) {
            IExternalPool extPool = IExternalPool(votedPool);
            IERC20 _toToken = IERC20(extPool.enterToken());

            uint returnAmount = swap(
                _fromToken,
                _toToken,
                amount,
                false
            );

            _toToken.universalTransfer(votedPool, _toToken.balanceOf(address(this)));
            extPool.addPosition();
            
            // convert return amount to [denominateTo]
            toMint = quote(
                _toToken,
                IERC20(denominateTo),
                returnAmount
            );

        } else {
            IUniswapV2Exchange pair = IUniswapV2Exchange(votedPool);
            
            (uint I0, uint I1, address token0, address token1) = getUniSplit(amount, pair, _fromToken, false);
            
            uint amount0 = swap(
                _fromToken,
                IERC20(token0),
                I0,
                false
            );
            
            uint amount1 = swap(
                _fromToken,
                IERC20(token1),
                I1,
                false
            );
            
            /*
            fixAllowance(token0, address(uniV2));
            fixAllowance(token1, address(uniV2));
            
            uniV2.addLiquidity(token0,token1,amount0,amount1,0,0,address(this),block.number);
            */
            
            IERC20(token0).universalTransfer(address(pair), amount0);
            IERC20(token1).universalTransfer(address(pair), amount1);
            
            pair.mint(address(this));
            
            toMint = quote(
                IERC20(token0),
                IERC20(denominateTo),
                amount0
            );
            
            toMint += quote(
                IERC20(token1),
                IERC20(denominateTo),
                amount1
            );
        } 
        
        // mint that amount to sender
        require(toMint > 0, 'Nothing to mint');
        toMint = toSFDecimals(toMint);
        ISFToken(SFToken).mint(msg.sender, toMint);
    }
    
    /*
    function fixAllowance(address _token, address recipient) internal {
        if (IERC20(_token).allowance(address(this), recipient) != uint(-1)) {
            IERC20(_token).universalApprove(recipient, uint(-1));
        }
    }*/
    
    function _P(uint Q0, uint Q1, IUniswapV2Exchange pair) internal view returns (uint P) {
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        
        require(reserve0 > 0 && reserve1 > 0, 'UNI pool is empty');
        
        P = (reserve0.mul(Q1).mul(10**fpDigits)).div(reserve1.mul(Q0));
    }
    
    function _I0(uint P, uint Q) internal pure returns (uint I0) {
        I0 = Q.mul(fpNumbers**2).div(P.add(fpNumbers)).div(fpNumbers);
    }
    
    function getUniSplit(uint Q, IUniswapV2Exchange pair, IERC20 fromToken, bool reverse) 
    internal view returns (uint I0, uint I1, address token0, address token1) {
        token0 = pair.token0();
        token1 = pair.token1();
        
        uint I = Q.div(2);
        
        uint Q0;
        uint Q1;
        
        if (reverse) {
            Q0 = reverseQuote(IERC20(token0), fromToken, I);
            Q1 = reverseQuote(IERC20(token1), fromToken, I);
        } else {
            Q0 = quote(fromToken, IERC20(token0), I);
            Q1 = quote(fromToken, IERC20(token1), I);
        }
        
        uint P = _P(Q0, Q1, pair);
        
        I0 = _I0(P, Q);
        I1 = Q-I0;
        
        if (reverse) {
            I0 = reverseQuote(IERC20(token0), fromToken, I0);
            I1 = reverseQuote(IERC20(token0), fromToken, I1);
        }
    }
    
    function pickPoolToExtract(uint amount) public view returns (address pool, PoolType poolType) {
         //check UNI pool values
        for (uint i = 0; i < uniLen; i++) {
        address uniAddress = uniPools[i];
        
        uint PairReserve;
        if (uniAddress != address(0)) {
            IUniswapV2Exchange uniPool = IUniswapV2Exchange(uniAddress);
            (uint myreserve0, uint myreserve1) = getDenominatedValue(uniPool);

            PairReserve += myreserve0;
            PairReserve += myreserve1;
            
            if (PairReserve >= amount) {
                return (uniAddress, PoolType.UNI);
                }
            }
        }
        
        for (uint i = 0; i < extLen; i++) {
            address extAddress = externalPools[i];

            if (extAddress != address(0)) {
                // get quote to denominateTo
                IExternalPool extPool = IExternalPool(extAddress);
                uint poolValue = quote(IERC20(extPool.enterToken()), IERC20(denominateTo), extPool.getTokenStaked());
                if (poolValue >= amount) {
                    return (extAddress, PoolType.EXT);
                }
            }
        }
        
        require(pool != address(0), "No pool for requested amount");
    }

    function burn(address toToken, uint amount) external discountCHI {
        IERC20 _toToken = IERC20(toToken);
        ISFToken _SFToken = ISFToken(SFToken);
        // get latest token value
        _rebase(getTotalValue().add(1)); 
        
        // limit by existing balance
        uint senderBalance = _SFToken.balanceOf(msg.sender);
        if (senderBalance < amount) {
            amount = senderBalance;
        }
        
        _SFToken.burn(msg.sender, amount);

        require(amount > 0, "Not enough burn balance");

        /// convert to denominateTo 
        amount = fromSFDecimals(amount);
        uint feeTaken = getFee(amount);
        emit LogFeeTaken(feeTaken);
        amount -= feeTaken;
        
        (address pool, PoolType poolType) = pickPoolToExtract(amount);
    
        uint returnAmount;
        
        if (poolType == PoolType.EXT) {
            IExternalPool extPool = IExternalPool(pool);
            address poolToken = extPool.enterToken();

            // get quote from sf token to pool token
            // how much pool token [DAI?] is needed to make this amount of [denominateTo] (also DAI now)
            // poolToken might be == denominateTo
            uint poolTokenWithdraw = reverseQuote(
                IERC20(poolToken),
                IERC20(denominateTo),
                amount
            );
            
            require(poolTokenWithdraw > 0, 'Reverse Quote is 0');
        
            //pull out pool tokens
            extPool.exitPosition(poolTokenWithdraw);
            //get them out from the pool here
            uint returnPoolTokenAmount = extPool.transferTokenTo(
                poolToken,
                address(this),
                poolTokenWithdraw
            );
            
            // topup with CHi
            returnPoolTokenAmount = returnPoolTokenAmount.sub(
                topUpChi(poolToken)
            );
            
            if (toToken == address(0)) {
                _toToken = WETH_ADDRESS;
            }

            returnAmount = swap(
                IERC20(poolToken),
                _toToken,
                returnPoolTokenAmount,
                true
            );
        } else {
            (IERC20 token0, IERC20 token1, uint bal0, uint bal1) = burnUniLq(amount, pool);
            
            returnAmount = swap(
                token0,
                _toToken,
                bal0,
                true
            );
            
            returnAmount += swap(
                token1,
                _toToken,
                bal1,
                true
            );
            
            // topup with CHi
            returnAmount = returnAmount.sub(topUpChi(address(_toToken)));
        }
        
        if (toToken == address(WETH_ADDRESS)) {
                IWETH(address(WETH_ADDRESS)).withdraw(returnAmount);
                msg.sender.transfer(returnAmount);
            } else {
                _toToken.universalTransfer(msg.sender, returnAmount);
            } 

        emit LogBurnGiven(returnAmount);
    }

    function burnUniLq(uint amount, address pool) internal returns (IERC20 token0, IERC20 token1, uint bal0, uint bal1) {
        IUniswapV2Exchange pair = IUniswapV2Exchange(pool);
        (, uint I1, address tok0, address tok1) = getUniSplit(amount, pair, IERC20(denominateTo), true);
            
        (, uint reserve1,) = pair.getReserves();
        
        uint lq = pair.totalSupply().mul(reserve1).div(I1); // might be min of either of those token0/token1
        
        pair.transfer(pool, lq);
        pair.burn(address(this));
        
        token0 = IERC20(tok0);
        token1 = IERC20(tok1);
        
        bal0 = token0.balanceOf(address(this));
        bal1 = token0.balanceOf(address(this));
    }

    function getFee(uint amount) internal view returns(uint feeTaken) {
        feeTaken = amount.mul(votedFee).div(10000);
    }

    function _rebase(uint value) internal {
        ISFToken SF = ISFToken(SFToken);
        SF.rebase(value);
    }
    
    function rebase() public discountCHI onlyValueManager {
        _rebase(toSFDecimals(getTotalValue()+1));
    }

    function rebase(uint value) external onlyValueManager {
        _rebase(value);
    }
    
    function fromSFDecimals (uint value) internal view returns (uint) {
        return value.mul(10 ** uint(denominateDecimals - sfDecimals));
    }
    
    function toSFDecimals (uint value) internal view returns (uint) {
        return value.div(10 ** uint(denominateDecimals - sfDecimals));
    }
    
    // update external pool Value, add and rebase
    function updateRebase() external onlyValueManager {
        require(votedPool != address(0), 'No voted pool available'); 
        require(votedPoolType == PoolType.EXT, 'Wrong pool type for Update');
        
        IExternalPool extPool = IExternalPool(votedPool);
        extPool.claimValue();
       
        IERC20 poolToken = IERC20(extPool.enterToken());
        if (poolToken.balanceOf(votedPool) > 0) {
            extPool.addPosition();
        }
    }

    function getHolderPc(IUniswapV2Exchange uniPool) public view returns (uint holderPc) {
        try uniPool.totalSupply() returns (uint uniTotalSupply)
        {
            holderPc = (uniPool.balanceOf(address(this)).mul(fpNumbers)).div(uniTotalSupply);    
        } catch {}
    }

    function getUniReserve(IUniswapV2Exchange uniPool)
        public
        view
        returns (uint myreserve0, uint myreserve1)
    {
        uint holderPc = getHolderPc(uniPool);

        try uniPool.getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
        
            myreserve0 = (uint(reserve0).mul(holderPc)).div(fpNumbers);
            myreserve1 = (uint(reserve1).mul(holderPc)).div(fpNumbers);
    
        } catch {}
    }

    function getExternalValue() public view returns (uint totalReserve) {
        for (uint j = 0; j < extLen; j++) {
            address extAddress = externalPools[j];
            if (extAddress != address(0)) {
                IExternalPool externalPool = IExternalPool(extAddress);

                address poolToken = externalPool.enterToken();
                // changing quotes to this contract instead
                (uint addValue) = quote(IERC20(poolToken), IERC20(denominateTo), externalPool.getPoolValue(poolToken));
                totalReserve = totalReserve.add(addValue);
            }
        }
    }

    function getDenominatedValue(IUniswapV2Exchange uniPool)
        public
        view
        returns (uint myreserve0, uint myreserve1)
    {
        (myreserve0, myreserve1) = getUniReserve(uniPool);

        address token0 = uniPool.token0();
        address token1 = uniPool.token1();

        if (token0 != denominateTo) {
            //get amount and convert to denominate addr;
            if (token0 != SFToken && myreserve0 > 0) {
                (myreserve0) = quote(IERC20(uniPool.token0()), IERC20(denominateTo), myreserve0);
                
            } else {
                myreserve0 = 0;
            }
        }

        if (uniPool.token1() != denominateTo) {
            //get amount and convert to denominate addr;
            if (token1 != SFToken && myreserve1 > 0) {
                (myreserve1) = quote(IERC20(uniPool.token1()), IERC20(denominateTo), myreserve1);
            } else {
                myreserve1 = 0;
            }
        }
    }

    function getTotalValue() public view returns (uint totalReserve) {
        for (uint i = 0; i < uniLen; i++) {
            address uniAddress = uniPools[i];
            
            if (uniAddress != address(0)) {
                IUniswapV2Exchange uniPool = IUniswapV2Exchange(uniAddress);
                (uint myreserve0, uint myreserve1) = getDenominatedValue(uniPool);

                totalReserve += myreserve0;
                totalReserve += myreserve1;
            }
        }

        totalReserve += getExternalValue();
        totalReserve += IERC20(denominateTo).balanceOf(address(this));
    }

    function addUni(address pool) public onlyVoter {
        uniPools[uniLen] = pool;
        uniLen++;
    }

    function delUni(uint i) external onlyVoter {
        uniPools[i] = address(0);
    }

    function addExt(address pool) public onlyVoter {
        externalPools[extLen] = pool;
        extLen++;
    }

    function delExt(uint i) external onlyVoter {
        externalPools[i] = address(0);
    }
    
    function setUniLen(uint i) external onlyVoter {
        uniLen = i;
    }
    
    function setExtLen(uint i) external onlyVoter {
        extLen = i;
    }
}