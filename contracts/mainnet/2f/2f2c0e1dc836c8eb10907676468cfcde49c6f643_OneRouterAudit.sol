// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// File: contracts/IOneRouter.sol


pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;



interface IOneRouterView {
    struct Swap {
        IERC20 destToken;
        uint256 flags;
        uint256 destTokenEthPriceTimesGasPrice;
        address[] disabledDexes;
    }

    struct Path {
        Swap[] swaps;
    }

    struct SwapResult {
        uint256[] returnAmounts;
        uint256[] estimateGasAmounts;
        uint256[][] distributions;
        address[][] dexes;
    }

    struct PathResult {
        SwapResult[] swaps;
    }

    function getReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        );

    function getSwapReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        returns(SwapResult memory result);

    function getPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path calldata path
    )
        external
        view
        returns(PathResult memory result);

    function getMultiPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path[] calldata paths
    )
        external
        view
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        );
}


abstract contract IOneRouter is IOneRouterView {
    struct Referral {
        address payable ref;
        uint256 fee;
    }

    struct SwapInput {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 minReturn;
        Referral referral;
    }

    struct SwapDistribution {
        uint256[] weights;
    }

    struct PathDistribution {
        SwapDistribution[] swapDistributions;
    }

    function makeSwap(
        SwapInput calldata input,
        Swap calldata swap,
        SwapDistribution calldata swapDistribution
    )
        external
        payable
        virtual
        returns(uint256 returnAmount);

    function makePathSwap(
        SwapInput calldata input,
        Path calldata path,
        PathDistribution calldata pathDistribution
    )
        external
        payable
        virtual
        returns(uint256 returnAmount);

    function makeMultiPathSwap(
        SwapInput calldata input,
        Path[] calldata paths,
        PathDistribution[] calldata pathDistributions,
        SwapDistribution calldata interPathsDistribution
    )
        external
        payable
        virtual
        returns(uint256 returnAmount);
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

// File: contracts/libraries/UniERC20.sol


pragma solidity ^0.6.0;





library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 public constant ZERO_ADDRESS = IERC20(0);

    function isETH(IERC20 token) internal pure returns(bool) {
        return (token == ZERO_ADDRESS || token == ETH_ADDRESS);
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFromSender(IERC20 token, address payable target, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                target.transfer(amount);
                if (msg.value > amount) {
                    // Return remainder if exist
                    msg.sender.transfer(msg.value.sub(amount));
                }
            } else {
                token.safeTransferFrom(msg.sender, target, amount);
            }
        }
    }

    function uniApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function uniDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSignature("decimals()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return success ? abi.decode(data, (uint8)) : 18;
    }

    function uniSymbol(IERC20 token) internal view returns(string memory) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSignature("symbol()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSignature("SYMBOL()")
            );
        }

        if (success && data.length >= 96) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            if (offset == 0x20 && len > 0 && len <= 256) {
                return string(abi.decode(data, (bytes)));
            }
        }

        if (success && data.length == 32) {
            uint len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                len++;
            }

            if (len > 0) {
                bytes memory result = new bytes(len);
                for (uint i = 0; i < len; i++) {
                    result[i] = data[i];
                }
                return string(result);
            }
        }

        return _toHex(address(token));
    }

    function _toHex(address account) private pure returns(string memory) {
        return _toHex(abi.encodePacked(account));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        uint j = 2;
        for (uint i = 0; i < data.length; i++) {
            uint a = uint8(data[i]) >> 4;
            uint b = uint8(data[i]) & 0x0f;
            str[j++] = byte(uint8(a + 48 + (a/10)*39));
            str[j++] = byte(uint8(b + 48 + (b/10)*39));
        }

        return string(str);
    }
}

// File: contracts/interfaces/IMooniswap.sol


pragma solidity ^0.6.0;



interface IMooniswapRegistry {
    function pools(IERC20 token1, IERC20 token2) external view returns(IMooniswap);
    function isPool(address addr) external view returns(bool);
}


interface IMooniswap {
    function fee() external view returns (uint256);
    function tokens(uint256 i) external view returns (IERC20);
    function getBalanceForAddition(IERC20 token) external view returns(uint256);
    function getBalanceForRemoval(IERC20 token) external view returns(uint256);
    function getReturn(IERC20 fromToken, IERC20 destToken, uint256 amount) external view returns(uint256 returnAmount);

    function deposit(uint256[] calldata amounts, uint256[] calldata minAmounts) external payable returns(uint256 fairSupply);
    function withdraw(uint256 amount, uint256[] calldata minReturns) external;
    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 minReturn, address referral) external payable returns(uint256 returnAmount);
}

// File: contracts/ISource.sol


pragma solidity ^0.6.0;



interface ISource {
    function calculate(IERC20 fromToken, uint256[] calldata amounts, IOneRouterView.Swap calldata swap)
        external view returns(uint256[] memory rets, address dex, uint256 gas);

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) external;
}

// File: contracts/sources/MooniswapSource.sol


pragma solidity ^0.6.0;







library MooniswapHelper {
    using SafeMath for uint256;
    using UniERC20 for IERC20;

    IMooniswapRegistry constant public REGISTRY = IMooniswapRegistry(0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303);

    function getReturn(
        IMooniswap mooniswap,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal view returns(uint256 ret) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory rets = getReturns(mooniswap, fromToken, destToken, amounts);
        if (rets.length > 0) {
            return rets[0];
        }
    }

    function getReturns(
        IMooniswap mooniswap,
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts
    ) internal view returns(uint256[] memory rets) {
        rets = new uint256[](amounts.length);

        uint256 fee = mooniswap.fee();
        uint256 fromBalance = mooniswap.getBalanceForAddition(fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken);
        uint256 destBalance = mooniswap.getBalanceForRemoval(destToken.isETH() ? UniERC20.ZERO_ADDRESS : destToken);
        if (fromBalance > 0 && destBalance > 0) {
            for (uint i = 0; i < amounts.length; i++) {
                uint256 amount = amounts[i].sub(amounts[i].mul(fee).div(1e18));
                rets[i] = amount.mul(destBalance).div(
                    fromBalance.add(amount)
                );
            }
        }
    }
}


contract MooniswapSourceView {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using MooniswapHelper for IMooniswap;

    function _calculateMooniswap(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        IMooniswap mooniswap = MooniswapHelper.REGISTRY.pools(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            swap.destToken.isETH() ? UniERC20.ZERO_ADDRESS : swap.destToken
        );
        if (mooniswap == IMooniswap(0)) {
            return (new uint256[](0), address(0), 0);
        }

        for (uint t = 0; t < swap.disabledDexes.length; t++) {
            if (swap.disabledDexes[t] == address(mooniswap)) {
                return (new uint256[](0), address(0), 0);
            }
        }

        rets = mooniswap.getReturns(fromToken, swap.destToken, amounts);
        if (rets.length == 0 || rets[0] == 0) {
            return (new uint256[](0), address(0), 0);
        }

        return (rets, address(mooniswap), (fromToken.isETH() || swap.destToken.isETH()) ? 80_000 : 110_000);
    }
}


contract MooniswapSourceSwap {
    using UniERC20 for IERC20;

    function _swapOnMooniswap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 /*flags*/) internal {
        IMooniswap mooniswap = MooniswapHelper.REGISTRY.pools(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            destToken.isETH() ? UniERC20.ZERO_ADDRESS : destToken
        );

        fromToken.uniApprove(address(mooniswap), amount);
        mooniswap.swap{ value: fromToken.isETH() ? amount : 0 }(
            fromToken.isETH() ? UniERC20.ZERO_ADDRESS : fromToken,
            destToken.isETH() ? UniERC20.ZERO_ADDRESS : destToken,
            amount,
            0,
            0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5
        );
    }
}


contract MooniswapSourcePublic is ISource, MooniswapSourceView, MooniswapSourceSwap {
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateMooniswap(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnMooniswap(fromToken, destToken, amount, flags);
    }
}

// File: contracts/OneRouterConstants.sol


pragma solidity ^0.6.0;



contract OneRouterConstants {
    uint256 constant internal _FLAG_DISABLE_ALL_SOURCES          = 0x100000000000000000000000000000000;
    uint256 constant internal _FLAG_DISABLE_RECALCULATION        = 0x200000000000000000000000000000000;
    uint256 constant internal _FLAG_ENABLE_CHI_BURN              = 0x400000000000000000000000000000000;
    uint256 constant internal _FLAG_ENABLE_CHI_BURN_ORIGIN       = 0x800000000000000000000000000000000;
    uint256 constant internal _FLAG_ENABLE_REFERRAL_GAS_DISCOUNT = 0x1000000000000000000000000000000000;


    uint256 constant internal _FLAG_DISABLE_KYBER_ALL =
        _FLAG_DISABLE_KYBER_1 +
        _FLAG_DISABLE_KYBER_2 +
        _FLAG_DISABLE_KYBER_3 +
        _FLAG_DISABLE_KYBER_4;
    uint256 constant internal _FLAG_DISABLE_CURVE_ALL =
        _FLAG_DISABLE_CURVE_COMPOUND +
        _FLAG_DISABLE_CURVE_USDT +
        _FLAG_DISABLE_CURVE_Y +
        _FLAG_DISABLE_CURVE_BINANCE +
        _FLAG_DISABLE_CURVE_SYNTHETIX +
        _FLAG_DISABLE_CURVE_PAX +
        _FLAG_DISABLE_CURVE_RENBTC +
        _FLAG_DISABLE_CURVE_TBTC +
        _FLAG_DISABLE_CURVE_SBTC;
    uint256 constant internal _FLAG_DISABLE_BALANCER_ALL =
        _FLAG_DISABLE_BALANCER_1 +
        _FLAG_DISABLE_BALANCER_2 +
        _FLAG_DISABLE_BALANCER_3;
    uint256 constant internal _FLAG_DISABLE_BANCOR_ALL =
        _FLAG_DISABLE_BANCOR_1 +
        _FLAG_DISABLE_BANCOR_2 +
        _FLAG_DISABLE_BANCOR_3;

    uint256 constant internal _FLAG_DISABLE_UNISWAP_V1      = 0x1;
    uint256 constant internal _FLAG_DISABLE_UNISWAP_V2      = 0x2;
    uint256 constant internal _FLAG_DISABLE_MOONISWAP       = 0x4;
    uint256 constant internal _FLAG_DISABLE_KYBER_1         = 0x8;
    uint256 constant internal _FLAG_DISABLE_KYBER_2         = 0x10;
    uint256 constant internal _FLAG_DISABLE_KYBER_3         = 0x20;
    uint256 constant internal _FLAG_DISABLE_KYBER_4         = 0x40;
    uint256 constant internal _FLAG_DISABLE_CURVE_COMPOUND  = 0x80;
    uint256 constant internal _FLAG_DISABLE_CURVE_USDT      = 0x100;
    uint256 constant internal _FLAG_DISABLE_CURVE_Y         = 0x200;
    uint256 constant internal _FLAG_DISABLE_CURVE_BINANCE   = 0x400;
    uint256 constant internal _FLAG_DISABLE_CURVE_SYNTHETIX = 0x800;
    uint256 constant internal _FLAG_DISABLE_CURVE_PAX       = 0x1000;
    uint256 constant internal _FLAG_DISABLE_CURVE_RENBTC    = 0x2000;
    uint256 constant internal _FLAG_DISABLE_CURVE_TBTC      = 0x4000;
    uint256 constant internal _FLAG_DISABLE_CURVE_SBTC      = 0x8000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_1      = 0x10000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_2      = 0x20000;
    uint256 constant internal _FLAG_DISABLE_BALANCER_3      = 0x40000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_1        = 0x80000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_2        = 0x100000;
    uint256 constant internal _FLAG_DISABLE_BANCOR_3        = 0x200000;
    uint256 constant internal _FLAG_DISABLE_OASIS           = 0x400000;
    uint256 constant internal _FLAG_DISABLE_DFORCE_SWAP     = 0x800000;
    uint256 constant internal _FLAG_DISABLE_SHELL           = 0x1000000;
    uint256 constant internal _FLAG_DISABLE_MSTABLE_MUSD    = 0x2000000;
    uint256 constant internal _FLAG_DISABLE_BLACK_HOLE_SWAP = 0x4000000;

    IERC20 constant internal _DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant internal _USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant internal _USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant internal _TUSD = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    IERC20 constant internal _BUSD = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 constant internal _SUSD = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant internal _PAX = IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    IERC20 constant internal _RENBTC = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    IERC20 constant internal _WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 constant internal _SBTC = IERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);
    IERC20 constant internal _CHI = IERC20(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
}

// File: contracts/OneRouterAudit.sol


pragma solidity ^0.6.0;









interface IReferralGasSponsor {
    function makeGasDiscount(
        uint256 gasSpent,
        uint256 returnAmount,
        bytes calldata msgSenderCalldata
    ) external;
}


interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}


contract OneRouterAudit is IOneRouter, OneRouterConstants, Ownable {
    using UniERC20 for IERC20;
    using SafeMath for uint256;

    IOneRouter public oneRouterImpl;

    modifier validateInput(SwapInput memory input) {
        require(input.referral.fee <= 0.03e18, "OneRouter: fee out of range");
        require(input.fromToken == input.destToken, "OneRouter: invalid input");
        _;
    }

    constructor(IOneRouter oneRouter) public {
        oneRouterImpl = oneRouter;
    }

    function setOneRouterImpl(IOneRouter oneRouter) public onlyOwner {
        oneRouterImpl = oneRouter;
    }

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "OneRouter: ETH deposit rejected");
    }

    // View methods

    function getReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        return oneRouterImpl.getReturn(fromToken, amounts, swap);
    }

    function getSwapReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(SwapResult memory result)
    {
        return oneRouterImpl.getSwapReturn(fromToken, amounts, swap);
    }

    function getPathReturn(IERC20 fromToken, uint256[] memory amounts, Path memory path)
        public
        view
        override
        returns(PathResult memory result)
    {
        return oneRouterImpl.getPathReturn(fromToken, amounts, path);
    }

    function getMultiPathReturn(IERC20 fromToken, uint256[] memory amounts, Path[] memory paths)
        public
        view
        override
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        return oneRouterImpl.getMultiPathReturn(fromToken, amounts, paths);
    }

    // Swap methods

    function makeSwap(
        SwapInput memory input,
        Swap memory swap,
        SwapDistribution memory swapDistribution
    )
        public
        payable
        override
        validateInput(input)
        returns(uint256 returnAmount)
    {
        uint256 gasStart = gasleft();
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterImpl), input.amount);
        oneRouterImpl.makeSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, swap, swapDistribution);
        return _checkMinReturn(gasStart, input, swap.flags);
    }

    function makePathSwap(
        SwapInput memory input,
        Path memory path,
        PathDistribution memory pathDistribution
    )
        public
        payable
        override
        validateInput(input)
        returns(uint256 returnAmount)
    {
        uint256 gasStart = gasleft();
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterImpl), input.amount);
        oneRouterImpl.makePathSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, path, pathDistribution);
        return _checkMinReturn(gasStart, input, path.swaps[0].flags);
    }

    function makeMultiPathSwap(
        SwapInput memory input,
        Path[] memory paths,
        PathDistribution[] memory pathDistributions,
        SwapDistribution memory interPathsDistribution
    )
        public
        payable
        override
        validateInput(input)
        returns(uint256 returnAmount)
    {
        uint256 gasStart = gasleft();
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterImpl), input.amount);
        oneRouterImpl.makeMultiPathSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, paths, pathDistributions, interPathsDistribution);
        return _checkMinReturn(gasStart, input, paths[0].swaps[0].flags);
    }

    // Internal methods

    function _claimInput(SwapInput memory input) internal {
        input.fromToken.uniTransferFromSender(address(this), input.amount);
        input.amount = input.fromToken.uniBalanceOf(address(this));
    }

    function _checkMinReturn(uint256 gasStart, SwapInput memory input, uint256 flags) internal returns(uint256 returnAmount) {
        uint256 remaining = input.fromToken.uniBalanceOf(address(this));
        returnAmount = input.destToken.uniBalanceOf(address(this));
        require(returnAmount >= input.minReturn, "OneRouter: less than minReturn");
        input.fromToken.uniTransfer(msg.sender, remaining);
        input.destToken.uniTransfer(input.referral.ref, returnAmount.mul(input.referral.fee).div(1e18));
        input.destToken.uniTransfer(msg.sender, returnAmount.sub(returnAmount.mul(input.referral.fee).div(1e18)));

        if ((flags & (_FLAG_ENABLE_CHI_BURN | _FLAG_ENABLE_CHI_BURN_ORIGIN)) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            _chiBurnOrSell(
                ((flags & _FLAG_ENABLE_CHI_BURN_ORIGIN) > 0) ? tx.origin : msg.sender, // solhint-disable-line avoid-tx-origin
                (gasSpent + 14154) / 41947
            );
        }
        else if ((flags & _FLAG_ENABLE_REFERRAL_GAS_DISCOUNT) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            IReferralGasSponsor(input.referral.ref).makeGasDiscount(gasSpent, returnAmount, msg.data);
        }
    }

    function _chiBurnOrSell(address payable sponsor, uint256 amount) internal {
        IMooniswap exchange = IMooniswap(0x5B1fC2435B1f7C16c206e7968C0e8524eC29b786);
        uint256 sellRefund = MooniswapHelper.getReturn(exchange, _CHI, UniERC20.ZERO_ADDRESS, amount);
        uint256 burnRefund = amount.mul(18_000).mul(tx.gasprice);

        if (sellRefund < burnRefund.add(tx.gasprice.mul(36_000))) {
            IFreeFromUpTo(address(_CHI)).freeFromUpTo(sponsor, amount);
        }
        else {
            _CHI.transferFrom(sponsor, address(exchange), amount);
            exchange.swap(_CHI, UniERC20.ZERO_ADDRESS, amount, 0, 0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
            sponsor.transfer(address(this).balance);
        }
    }
}