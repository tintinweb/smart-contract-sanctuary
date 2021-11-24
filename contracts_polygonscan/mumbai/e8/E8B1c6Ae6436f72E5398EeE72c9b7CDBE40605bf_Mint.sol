/**
 *Submitted for verification at polygonscan.com on 2021-11-23
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File hardhat/[email protected]


pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}


// File contracts/interface/IERC20Extented.sol


pragma solidity ^0.8.0;
interface IERC20Extented is IERC20 {
    function decimals() external view returns(uint8);
}


// File contracts/interface/IAssetToken.sol


pragma solidity ^0.8.0;
interface IAssetToken is IERC20Extented {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function owner() external view;
}


// File contracts/interface/IAsset.sol



pragma solidity ^0.8.2;
struct IPOParams{
    uint mintEnd;
    uint preIPOPrice;
    // >= 1000
    uint16 minCRatioAfterIPO;
}

struct AssetConfig {
    IAssetToken token;
    AggregatorV3Interface oracle;
    uint16 auctionDiscount;
    uint16 minCRatio;
    uint endPrice;
    uint8 endPriceDecimals;
    // 鏄惁鍦≒reIPO闃舵
    bool isInPreIPO;
    IPOParams ipoParams;
    // 鏄惁宸查€€甯?
    bool delisted;
    // the Id of the pool in ShortStaking contract.
    uint poolId;
    // 鍒ゆ柇璇ョ┖闂存槸鍚﹀凡琚垎閰?
    bool assigned;
}

// Collateral Asset Config
struct CAssetConfig {
    IERC20Extented token;
    AggregatorV3Interface oracle;
    uint16 multiplier;
    // 鍒ゆ柇璇ョ┖闂存槸鍚﹀凡琚垎閰?
    bool assigned;
}

interface IAsset {
    function asset(address nToken) external view returns(AssetConfig memory);
    function cAsset(address token) external view returns(CAssetConfig memory);
    function isCollateralInPreIPO(address cAssetToken) external view returns(bool);
}


// File contracts/interface/IShortLock.sol



pragma solidity ^0.8.2;
struct PositionLockInfo {
        uint positionId;
        address receiver;
        IERC20 lockedToken; // address(1) means native token, such as ETH or MITIC.
        uint lockedAmount;
        uint unlockTime;
        bool assigned;
    }

interface IShortLock {
    function lock(uint positionId, address receiver, address token, uint amount) external payable;
    function unlock(uint positionId) external;
    function release(uint positionId) external;
    function lockInfoMap(uint positionId) external view returns(PositionLockInfo memory);
}


// File contracts/interface/IShortToken.sol


pragma solidity ^0.8.0;
interface IShortToken is IERC20Extented {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function owner() external view returns (address);
}


// File contracts/interface/IShortStaking.sol



pragma solidity ^0.8.2;
interface IShortStaking {
    function pendingNSDX(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount, address _realUser) external;
    function withdraw(uint256 _pid, uint256 _amount, address _realUser) external;
    function poolLength() external view returns (uint256);
}


// File contracts/interface/IPositions.sol



pragma solidity ^0.8.2;
struct Position{
    uint id;
    address owner;
    // collateral asset token.
    IERC20Extented cAssetToken;
    uint cAssetAmount;
    // nAsset token.
    IAssetToken assetToken;
    uint assetAmount;
    // if is it short position
    bool isShort;
    // 鍒ゆ柇璇ョ┖闂存槸鍚﹀凡琚垎閰?
    bool assigned;
}

interface IPositions {
    function openPosition(
        address owner,
        IERC20Extented cAssetToken,
        uint cAssetAmount,
        IAssetToken assetToken,
        uint assetAmount,
        bool isShort
    ) external returns(uint positionId);

    function updatePosition(Position memory position_) external;

    function removePosition(uint positionId) external;

    function getPosition(uint positionId) external view returns(Position memory);
    function getNextPositionId() external view returns(uint);
    function getPositions(address ownerAddr, uint startAt, uint limit) external view returns(Position[] memory);
}


// File contracts/interface/IUniswapV2Router.sol


pragma solidity ^0.8.2;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}


// File contracts/library/Swappable.sol


pragma solidity ^0.8.2;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
library Swappable {

    function swapExactTokensForTokens(
        IUniswapV2Router swapRouter,
        uint amountIn,
        uint amountOutMin,
        address tokenIn,
        address tokenOut,
        address to,
        uint deadline
    ) external returns (uint amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint[] memory amounts = swapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
        amountOut = amounts[amounts.length - 1];
    }

    function swapExactTokensForETH(
        IUniswapV2Router swapRouter,
        address weth,
        uint amountIn, 
        uint amountOutMin, 
        address tokenIn, 
        address to, 
        uint deadline
    ) external returns (uint amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;

        uint[] memory amounts = swapRouter.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
        amountOut = amounts[amounts.length - 1];
    }
}


// File contracts/Mint.sol


pragma solidity ^0.8.2;
/// @title Mint
/// @author Iwan
/// @notice The Mint Contract implements the logic for Collateralized Debt Positions (CDPs),
/// @notice through which users can mint or short new nAsset tokens against their deposited collateral. 
/// @dev The Mint Contract also contains the logic for liquidating CDPs with C-ratios below the 
/// @dev minimum for their minted mAsset through auction.
contract Mint is Ownable {
    
    using SafeERC20 for IERC20Extented;
    using SafeERC20 for IAssetToken;
    using SafeERC20 for IERC20;

    // Using the struct to avoid Stack too deep error
    struct VarsInFuncs{
        uint assetPrice;
        uint8 assetPriceDecimals;
        uint collateralPrice;
        uint8 collateralPriceDecimals;
    }

    struct VarsInAuction {
        uint returnedCollateralAmount;
        uint refundedAssetAmount;
        uint liquidatedAssetAmount;
        uint leftAssetAmount;
        uint leftCAssetAmount;
        uint protocolFee_;
    }

    /// @dev address(1) means native token, such as ETH or MATIC.
    // address constant private NATIVE_TOKEN = address(1);

    uint256 MAX_UINT256 = 2**256 - 1;

    /// @notice token address => total fee amount
    mapping(address => uint) public protocolFee;

    IAsset public asset;

    IPositions public positions;

    // 0 ~ 1000, fee = amount * feeRate / 1000.
    uint16 public feeRate;

    // Specify a token which will swap to it after
    // selling nAsset when people create a short position.
    address public swapToToken;

    /// @notice Short lock contract address.
    IShortLock public lock;

    /// @notice Short staking contract address.
    IShortStaking public staking;

    // 浠锋牸瀵撹█鏈烘渶鏂颁环鏍肩殑鏇存柊鏃堕棿鍒板綋鍓嶆椂闂寸殑闂撮殧涓嶈兘澶т簬杩欎釜鍊?
    uint private _oracleMaxDelay;

    IUniswapV2Router swapRouter;
    address weth;

    /// @notice Triggered when deposit.
    /// @param positionId The index of this position.
    /// @param cAssetAmount collateral amount.
    event Deposit(uint positionId, uint cAssetAmount);

    /// @notice Triggered when withdraw.
    /// @param positionId The index of this position.
    /// @param cAssetAmount collateral amount.
    event Withdraw(uint positionId, uint cAssetAmount);

    /// @notice Triggered when mint.
    /// @param positionId The index of this position.
    /// @param assetAmount asset amount.
    event MintAsset(uint positionId, uint assetAmount);

    /// @notice Triggered when burn.
    /// @param positionId The index of this position.
    /// @param assetAmount asset amount.
    event Burn(uint positionId, uint assetAmount);

    /// @notice Triggered when auction.
    /// @param positionId The index of this position.
    /// @param assetAmount asset amount.
    event Auction(uint positionId, uint assetAmount);

    /// @notice 鏋勯€犲嚱鏁?
    /// @param feeRate_ 鎸囧畾绯荤粺鏀跺彇鎵嬬画璐圭殑鐧惧垎姣?
    /// @param swapRouter_ A router address of a swap like Uniswap.
    constructor(
        uint16 feeRate_, 
        address asset_,
        address positions_,
        address swapToToken_, 
        address lock_,
        address staking_,
        address swapRouter_, 
        address weth_
    ) {
        feeRate = feeRate_;
        asset = IAsset(asset_);
        swapToToken = swapToToken_;
        _oracleMaxDelay = 300;
        lock = IShortLock(lock_);
        positions = IPositions(positions_);
        staking = IShortStaking(staking_);
        swapRouter = IUniswapV2Router(swapRouter_);
        weth = weth_;

        IERC20Extented(swapToToken).safeApprove(address(lock), MAX_UINT256);
        IERC20Extented(swapToToken).safeApprove(address(swapRouter), MAX_UINT256);
    }

    function updateState(
        address asset_,
        address positions_,
        uint oracleMaxDelay_,
        address swapToToken_,
        uint16 feeRate_,
        address lock_,
        address staking_,
        address swapRouter_
    ) external onlyOwner {
        IERC20Extented(swapToToken).safeApprove(address(lock), 0);
        IERC20Extented(swapToToken).safeApprove(address(swapRouter), 0);
        asset = IAsset(asset_);
        positions = IPositions(positions_);
        require(feeRate_ >= 0 || feeRate_ <= 1000, "setFeeRate: value out of range.");
        feeRate = feeRate_;
        require(swapToToken_ != address(0), "setSwapToToken: can not point to zero address.");
        swapToToken = swapToToken_;
        _oracleMaxDelay = oracleMaxDelay_;
        lock = IShortLock(lock_);
        staking = IShortStaking(staking_);
        swapRouter = IUniswapV2Router(swapRouter_);
        IERC20Extented(swapToToken).safeApprove(address(lock), MAX_UINT256);
        IERC20Extented(swapToToken).safeApprove(address(swapRouter), MAX_UINT256);
    }

    /// @notice 閫氳繃鎶垫娂璧勪骇鏂板缓涓€涓柊鐨勪粨浣嶏紝涓擬int n璧勪骇銆?
    /// @dev 鐢ㄦ埛鎸囧畾鐨勬姷鎶肩巼涓嶅緱灏忎簬绯荤粺閰嶇疆鐨勬渶浣庢姷鎶肩巼銆?
    /// @param assetToken 鐢ㄦ埛瑕佸悎鎴愮殑n璧勪骇鐨則oken鍚堢害鍦板潃
    /// @param cAssetToken 鐢ㄦ埛閫夋嫨鐨勬姷鎶艰祫浜х殑Token鍚堢害鍦板潃銆?
    /// @param cAssetAmount 鎶垫娂璧勪骇鏁伴噺
    /// @param cRatio 鎶垫娂鐜?
    function openPosition(
        IAssetToken assetToken, 
        IERC20Extented cAssetToken, 
        uint cAssetAmount, 
        uint16 cRatio
    ) public {
        _openPosition(assetToken, cAssetToken, cAssetAmount, cRatio, msg.sender, msg.sender, false);
    }

    /// @notice 寮€鍚竴涓仛绌轰粨浣嶏紝鐒跺悗绔嬪嵆鍗栨帀mint鍑烘潵鐨勮祫浜э紝鐒跺悗
    /// @notice 1.鍏坢int銆?
    /// @notice 2.鍗栧嚭mint鍚庣殑n璧勪骇銆?
    /// @notice 3.灏嗗崠鍑哄悗鑾峰緱鐨勮祫閲戦攣瀹氳嚦ShortLock鍚堢害銆?
    /// @notice 4.mint鍑轰笌n璧勪骇绛夐噺鐨剆LP token涓旇川鎶煎埌ShortStaking鍚堢害涓寲鐭裤€?
    /// @dev 鐢ㄦ埛鎸囧畾鐨勬姷鎶肩巼涓嶅緱灏忎簬绯荤粺閰嶇疆鐨勬渶浣庢姷鎶肩巼銆?
    /// @param assetToken 鐢ㄦ埛瑕佸悎鎴愮殑n璧勪骇鐨則oken鍚堢害鍦板潃
    /// @param cAssetToken 鐢ㄦ埛閫夋嫨鐨勬姷鎶艰祫浜х殑Token鍚堢害鍦板潃銆?
    /// @param cAssetAmount 鎶垫娂璧勪骇鏁伴噺
    /// @param cRatio 鎶垫娂鐜?
    /// @param swapAmountMin 鍗栧嚭n璧勪骇鏃讹紝甯屾湜寰楀埌鐨勫彟涓€绉嶈祫浜х殑鏈€灏忔暟閲?
    /// @param swapDeadline 鍗栧嚭n璧勪骇鏃讹紝甯屾湜姝や氦鏄撴墽琛岀殑鏈€鍚庢湡闄?
    function openShortPosition(
        IAssetToken assetToken, 
        IERC20Extented cAssetToken, 
        uint cAssetAmount, 
        uint16 cRatio,
        uint swapAmountMin,
        uint swapDeadline
    ) external {
        uint positionId;
        uint mintAmount;
        (positionId, mintAmount) = _openPosition(assetToken, cAssetToken, cAssetAmount, cRatio, msg.sender, address(this), true);

        if(assetToken.allowance(address(this), address(swapRouter)) < mintAmount) {
            assetToken.safeApprove(address(swapRouter), MAX_UINT256);
        }

        uint amountOut;
        if(swapToToken == address(1)) {
            amountOut = Swappable.swapExactTokensForETH(
                swapRouter, 
                weth, 
                mintAmount, 
                swapAmountMin, 
                address(assetToken), 
                address(this), 
                swapDeadline
            );
            amountOut = min(amountOut, address(this).balance);
        } else {
            amountOut = Swappable.swapExactTokensForTokens(
                swapRouter, 
                mintAmount, 
                swapAmountMin, 
                address(assetToken), 
                swapToToken, 
                address(this), 
                swapDeadline
            );
            amountOut = min(amountOut, IERC20(swapToToken).balanceOf(address(this)));
        }

        if(swapToToken == address(1)) {
            lock.lock{value:amountOut}(positionId, msg.sender, swapToToken, amountOut);
        } else {
            lock.lock(positionId, msg.sender, swapToToken, amountOut);
        }

        staking.deposit(asset.asset(address(assetToken)).poolId, mintAmount, msg.sender);
    }

    function _openPosition(
        IAssetToken assetToken, 
        IERC20Extented cAssetToken, 
        uint cAssetAmount, 
        uint16 cRatio, 
        address spender, 
        address receiver, 
        bool isShort
    ) private returns(uint positionId, uint mintAmount) {
        //n璧勪骇蹇呴』宸茶鍒楀叆鐧藉悕鍗曚笖娌℃湁閫€甯?
        // AssetConfig memory assetConfig = asset.asset(address(assetToken));
        require(asset.asset(address(assetToken)).assigned && (!asset.asset(address(assetToken)).delisted), "Asset invalid");

        //璇璧勪骇濡傛灉鏄疨reIPO闃舵锛孧int period涓嶈兘杩囨湡
        //璇璧勪骇濡傛灉鏄疨reIPO闃舵锛屽垯鎶垫娂璧勪骇蹇呴』鏄寚瀹氱殑璧勪骇
        if(asset.asset(address(assetToken)).isInPreIPO) {
            require(asset.asset(address(assetToken)).ipoParams.mintEnd > block.timestamp);
            require(asset.isCollateralInPreIPO(address(cAssetToken)), "cAsset can not be collateral in PreIPO.");
        }

        // 纭畾鎶垫娂鐗╁凡琚垪鍏ョ櫧鍚嶅崟锛屼笖鏈绉婚櫎
        // CAssetConfig memory cAssetConfig = asset.cAsset(address(cAssetToken));
        require(asset.cAsset(address(cAssetToken)).assigned, "Collateral not been listed yet.");
        //cRatio >= min_cRatio * multiplier
        require(asset.asset(address(assetToken)).minCRatio * asset.cAsset(address(cAssetToken)).multiplier <= cRatio, "C-Ratio should be greater than the min C-Ratio");

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        (v.assetPrice, v.assetPriceDecimals) = _getPrice(asset.asset(address(assetToken)).token, false);
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(asset.cAsset(address(cAssetToken)).token, true);

        // calculate mint amount.
        // uint collateralPriceInAsset = (collateralPrice / (10 ** collateralPriceDecimals)) / (assetPrice / (10 ** assetPriceDecimals));
        // uint mintAmount = (cAssetAmount / (10 ** cAssetToken.decimals())) * collateralPriceInAsset / (cRatio / 1000);
        // mintAmount = mintAmount * (10 ** assetToken.decimals());
        // 涓洪伩鍏嶇簿搴﹂棶棰樺甫鏉ョ殑璁＄畻鍋忓樊锛屼互涓婁笁琛屽彲杞崲鎴愪互涓嬩袱琛?
        // uint mintAmount = cAssetAmount * collateralPrice * (10 ** assetPriceDecimals) * cRatio * (10 ** assetToken.decimals())
        //     / 1000 / (10 ** cAssetToken.decimals()) / (10 ** collateralPriceDecimals) / assetPrice;
        // 涓洪伩鍏嶄骇鐢熷爢鏍堟繁搴﹂棶棰橈紝浠ヤ笂涓よ鍙浆鎹负浠ヤ笅涓よ
        uint a = cAssetAmount * v.collateralPrice * (10 ** v.assetPriceDecimals) * 1000 * (10 ** assetToken.decimals());
        mintAmount = a / cRatio / (10 ** cAssetToken.decimals()) / (10 ** v.collateralPriceDecimals) / v.assetPrice;
        require(mintAmount > 0, "mint amount cannot be 0");

        // transfer token
        cAssetToken.safeTransferFrom(spender, address(this), cAssetAmount);

        //create position
        positionId = positions.openPosition(spender, cAssetToken, cAssetAmount, assetToken, mintAmount, isShort);

        //mint token
        asset.asset(address(assetToken)).token.mint(receiver, mintAmount);
    }

    /// @notice 鍚戜竴涓凡缁忓瓨鍦ㄧ殑浠撲綅瀛樺叆棰濆鐨勬姷鎶肩墿锛屼互鎻愰珮鎶垫娂鐜囷紙C-Ratio锛?
    /// @dev 1.Token鍚堢害鍦板潃閫氳繃position()
    /// @dev 2.鍑芥暟鑾峰彇瀛樺叆鍓嶉渶鍏?approve 鎿嶄綔
    /// @param positionId 浠撲綅ID
    /// @param cAssetAmount 鐢ㄦ埛瑕佸瓨鍏ョ殑鎶垫娂鐗╃殑鏁伴噺
    function deposit(uint positionId, uint cAssetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "There is no such a position, or it was removed.");
        // 鎿嶄綔鑰呭繀椤绘槸浠撲綅鎸佹湁浜?
        require(position.owner == msg.sender, "You're not the position's owner.");
        // 鍏呭€兼暟閲忎笉鑳芥槸0
        require(cAssetAmount > 0, "Amount must cannot be 0.");
        // 纭畾鎶垫娂鐗╁凡琚垪鍏ョ櫧鍚嶅崟锛屼笖鏈绉婚櫎
        CAssetConfig memory cAssetConfig = asset.cAsset(address(position.cAssetToken));
        require(cAssetConfig.assigned, "Collateral not been listed yet.");

        //n璧勪骇蹇呴』宸茶鍒楀叆鐧藉悕鍗?
        AssetConfig memory assetConfig = asset.asset(address(position.assetToken));
        require(assetConfig.assigned, "Asset was not registered yet.");

        //n璧勪骇蹇呴』娌℃湁閫€甯?
        require(!assetConfig.delisted, "Asset has been delisted.");

        // transfer token
        position.cAssetToken.safeTransferFrom(msg.sender, address(this), cAssetAmount);

        // Increase collateral amount
        position.cAssetAmount += cAssetAmount;

        positions.updatePosition(position);

        emit Deposit(positionId, cAssetAmount);
    }

    /// @notice 浠庝竴涓粨浣嶄腑鎻愬彇鎸囧畾鏁伴噺鐨勬姷鎶肩墿銆?
    /// @dev 鎻愬彇鍚庤淇濊瘉鎶垫娂鐜囦笉鑳藉皬浜庢渶灏忔姷鎶肩巼銆?
    /// @param positionId 浠撲綅ID
    /// @param cAssetAmount 瑕佹彁鍙栫殑鎶垫娂鐗╂暟閲?
    function withdraw(uint positionId, uint cAssetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "There is no such a position, or it was removed.");
        // 鎿嶄綔鑰呭繀椤绘槸浠撲綅鎸佹湁浜?
        require(position.owner == msg.sender, "You're not the position's owner.");
        // 鎻愬竵鏁伴噺涓嶈兘鏄?
        require(cAssetAmount > 0, "Amount must cannot be 0.");

        // 鎻愬彇鏁伴噺涓嶈兘澶т簬浠撲綅涓幇鏈夌殑鏁伴噺
        require(position.cAssetAmount >= cAssetAmount, "Cannot withdraw more than you provide.");

        AssetConfig memory assetConfig = asset.asset(address(position.assetToken));
        CAssetConfig memory cAssetConfig = asset.cAsset(address(position.cAssetToken));

        // get price
        uint assetPrice;
        uint8 assetPriceDecimals;
        (assetPrice, assetPriceDecimals) = _getPrice(assetConfig.token, false);
        // console.log("asset price: %d, decimals: %d", assetPrice, assetPriceDecimals);
        uint collateralPrice;
        uint8 collateralPriceDecimals;
        (collateralPrice, collateralPriceDecimals) = _getPrice(cAssetConfig.token, true);
        // console.log("collateral price: %d, decimals: %d", collateralPrice, collateralPriceDecimals);

        // ignore multiplier for delisted assets
        uint16 multiplier = (assetConfig.delisted ? 1 : cAssetConfig.multiplier);

        uint remainingAmount = position.cAssetAmount - cAssetAmount;

        // Check minimum collateral ratio is satisfied
        // uint assetPriceInCollateral = (assetPrice / (10 ** assetPriceDecimals)) / (collateralPrice / (10 ** collateralPriceDecimals));
        // uint assetValueInCollateral = position.assetAmount / position.assetToken.decimals() * assetPriceInCollateral * position.cAssetToken.decimals();
        uint assetValueInCollateral = position.assetAmount * assetPrice * (10 ** collateralPriceDecimals) * position.cAssetToken.decimals() 
            / (10 ** assetPriceDecimals) / collateralPrice / position.assetToken.decimals();
        uint expectedAmount = assetValueInCollateral * assetConfig.minCRatio * multiplier / 1000;
        require(expectedAmount <= remainingAmount, "Cannot withdraw with an unsatisfied amount.");

        if(remainingAmount == 0 && position.assetAmount == 0) {
            positions.removePosition(positionId);
            // if it is a short position, release locked funds
            if(position.isShort) {
                lock.release(positionId);
            }
        } else {
            position.cAssetAmount = remainingAmount;
            positions.updatePosition(position);
        }

        // // charge a fee.
        // uint feeAmount = cAssetAmount * feeRate / 1000;
        // uint amountAfterFee = cAssetAmount - feeAmount;
        // protocolFee[address(position.cAssetToken)] += feeAmount;

        position.cAssetToken.safeTransfer(msg.sender, cAssetAmount);

        emit Withdraw(positionId, cAssetAmount);
    }

    /// @notice 鍦ㄤ竴涓凡鏈夌殑浠撲綅涓婄户缁悎鎴愭柊鐨刵璧勪骇銆?
    /// @dev Mint鍚庤淇濊瘉鎶垫娂鐜囦笉鑳藉皬浜庢渶灏忔姷鎶肩巼銆?
    /// @param positionId 浠撲綅ID
    /// @param assetAmount 瑕佸悎鎴愮殑n璧勪骇鐨勬暟閲?
    /// @param swapAmountMin Min amount you wanna received when sold to a swap if this position is a short position.
    /// @param swapDeadline Deadline time when sold to swap.
    function mint(uint positionId, uint assetAmount, uint swapAmountMin, uint swapDeadline) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "There is no such a position, or it was removed.");

        uint mintAmount = assetAmount;
        if(!position.isShort) {
            _mint(position, assetAmount, msg.sender);
            return;
        }

        _mint(position, assetAmount, address(this));

        uint amountOut;
        if(swapToToken == address(1)) {
            amountOut = Swappable.swapExactTokensForETH(
                swapRouter, 
                weth, 
                mintAmount, 
                swapAmountMin, 
                address(position.assetToken), 
                address(this), 
                swapDeadline
            );
            amountOut = min(amountOut, address(this).balance);
        } else {
            amountOut = Swappable.swapExactTokensForTokens(
                swapRouter, 
                mintAmount, 
                swapAmountMin, 
                address(position.assetToken), 
                swapToToken, 
                address(this), 
                swapDeadline
            );
            uint bal = IERC20(swapToToken).balanceOf(address(this));
            amountOut = min(amountOut, bal);
        }

        if(swapToToken == address(1)) {
            lock.lock{value:amountOut}(positionId, msg.sender, swapToToken, amountOut);
        } else {
            lock.lock(positionId, msg.sender, swapToToken, amountOut);
        }

        staking.deposit(asset.asset(address(position.assetToken)).poolId, mintAmount, msg.sender);
    }

    function _mint(Position memory position, uint assetAmount, address receiver) private {
        
        // 鎿嶄綔鑰呭繀椤绘槸浠撲綅鎸佹湁浜?
        require(position.owner == msg.sender, "You're not the position's owner.");
        // 鍏呭€兼暟閲忎笉鑳芥槸0
        require(assetAmount > 0, "Amount must cannot be 0.");

        //n璧勪骇蹇呴』宸茶鍒楀叆鐧藉悕鍗?
        AssetConfig memory assetConfig = asset.asset(address(position.assetToken));
        require(assetConfig.assigned, "Asset was not registered yet.");

        //n璧勪骇蹇呴』娌℃湁閫€甯?
        require(!assetConfig.delisted, "Asset has been delisted.");

        // 纭畾鎶垫娂鐗╁凡琚垪鍏ョ櫧鍚嶅崟锛屼笖鏈绉婚櫎
        CAssetConfig memory cAssetConfig = asset.cAsset(address(position.cAssetToken));
        require(cAssetConfig.assigned, "Collateral not been listed yet, or be removed.");

        //璇璧勪骇濡傛灉鏄疨reIPO闃舵锛孧int period涓嶈兘杩囨湡
        if(assetConfig.isInPreIPO) {
            require(assetConfig.ipoParams.mintEnd > block.timestamp);
        }

        // get price
        uint assetPrice;
        uint8 assetPriceDecimals;
        (assetPrice, assetPriceDecimals) = _getPrice(assetConfig.token, false);
        uint collateralPrice;
        uint8 collateralPriceDecimals;
        (collateralPrice, collateralPriceDecimals) = _getPrice(cAssetConfig.token, true);

        uint16 multiplier = cAssetConfig.multiplier;
        // Compute new asset amount
        uint mintedAmount = position.assetAmount + assetAmount;

        // Check minimum collateral ratio is satisfied
        // uint assetPriceInCollateral = (assetPrice / (10 ** assetPriceDecimals)) / (collateralPrice / (10 ** collateralPriceDecimals));
        // uint assetValueInCollateral = mintedAmount / position.assetToken.decimals() * assetPriceInCollateral * position.cAssetToken.decimals();
        uint assetValueInCollateral = mintedAmount * assetPrice * (10 ** collateralPriceDecimals) * position.cAssetToken.decimals() 
            / (10 ** assetPriceDecimals) / collateralPrice / position.assetToken.decimals();
        uint expectedAmount = assetValueInCollateral * assetConfig.minCRatio * multiplier / 1000;
        require(expectedAmount <= position.cAssetAmount, "Cannot mint with an unsatisfied amount.");

        position.assetAmount = mintedAmount;
        positions.updatePosition(position);

        position.assetToken.mint(receiver, assetAmount);

        emit MintAsset(position.id, assetAmount);
    }

    /// @notice 閿€姣乶璧勪骇锛屼互鎻愰珮浠撲綅鐨勬姷鎶肩巼
    /// @dev 濡傛灉姝や粨浣嶅悎鎴愮殑鎵€鏈塶璧勪骇鍏ㄩ儴閿€姣侊紝鍒欐浠撲綅灏嗗叧闂?
    /// @param positionId 浠撲綅ID
    /// @param assetAmount 瑕侀攢姣佺殑n璧勪骇鐨勬暟閲?
    function burn(uint positionId, uint assetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "There is no such a position, or it was removed.");
        require((assetAmount > 0) && (assetAmount <= position.assetAmount), "Wrong burn amount");

        //n璧勪骇蹇呴』宸茶鍒楀叆鐧藉悕鍗?
        AssetConfig memory assetConfig = asset.asset(address(position.assetToken));
        require(assetConfig.assigned, "Asset was not registered yet.");

        CAssetConfig memory cAssetConfig = asset.cAsset(address(position.cAssetToken));

        //璇璧勪骇濡傛灉鏄疨reIPO闃舵锛孧int period涓嶈兘杩囨湡
        if(assetConfig.isInPreIPO) {
            require(assetConfig.ipoParams.mintEnd > block.timestamp);
        }

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        // uint collateralPrice;
        // uint8 collateralPriceDecimals;
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(cAssetConfig.token, true);

        bool closePosition = false;
        // uint assetPrice;
        // uint8 assetPriceDecimals;
        uint cAssetAmount;
        uint protocolFee_;

        if(assetConfig.delisted) {
            v.assetPrice = assetConfig.endPrice;
            v.assetPriceDecimals = assetConfig.endPriceDecimals;
            // uint assetPriceInCollateral = (assetPrice / (10 ** assetPriceDecimals)) / (collateralPrice / (10 ** collateralPriceDecimals));
            // uint conversionRate = position.cAssetAmount / position.assetAmount;
            // uint amount1 = assetAmount / assetConfig.token.decimals() * assetPriceInCollateral * cAssetConfig.token.decimals();
            // uint amount2 = assetAmount * conversionRate;

            uint a = assetAmount * cAssetConfig.token.decimals() * v.assetPrice * (10 ** v.collateralPriceDecimals);
            uint amount1 = a / (10 ** v.assetPriceDecimals) / v.collateralPrice / assetConfig.token.decimals();
            uint amount2 = assetAmount * position.cAssetAmount / position.assetAmount;
            cAssetAmount = min(amount1, amount2);

            position.assetAmount -= assetAmount;
            position.cAssetAmount -= cAssetAmount;

            // due to rounding, include 1
            if(position.cAssetAmount <= 1 && position.assetAmount == 0) {
                closePosition = true;
                positions.removePosition(positionId);
            } else {
                positions.updatePosition(position);
            }

            // TODO 姝ゅ鍜孧irror涓嶄竴鏍?
            protocolFee_ = cAssetAmount * feeRate / 1000;
            protocolFee[address(position.cAssetToken)] += protocolFee_;
            cAssetAmount = cAssetAmount - protocolFee_;
            
            position.cAssetToken.safeTransfer(msg.sender, cAssetAmount);
            position.assetToken.burnFrom(msg.sender, assetAmount);
        } else {
            require(msg.sender == position.owner, "You don't own this position.");
            
            (v.assetPrice, v.assetPriceDecimals) = _getPrice(assetConfig.token, false);
            cAssetAmount = assetAmount * cAssetConfig.token.decimals() * v.assetPrice * (10 ** v.collateralPriceDecimals) / (10 ** v.assetPriceDecimals) / v.collateralPrice / assetConfig.token.decimals();
            protocolFee_ = cAssetAmount * feeRate / 1000;
            protocolFee[address(position.cAssetToken)] += protocolFee_;

            position.assetAmount -= assetAmount;
            position.cAssetAmount -= protocolFee_;

            if(position.assetAmount == 0) {
                closePosition = true;
                positions.removePosition(positionId);
                position.cAssetToken.safeTransfer(msg.sender, position.cAssetAmount);
            } else {
                positions.updatePosition(position);
            }
            
            position.assetToken.burnFrom(msg.sender, assetAmount);

            emit Burn(positionId, assetAmount);
        }

        if(position.isShort) {
            staking.withdraw(assetConfig.poolId, assetAmount, msg.sender);
            if(closePosition) {
                lock.release(positionId);
            }
        }
    }

    /// @notice 褰撲粨浣嶇殑鎶垫娂鐜囦綆浜庣郴缁熻缃殑鏈€灏忔姷鎶肩巼鏃讹紝绯荤粺灏嗘墽琛屾竻绠楁搷浣滐紝
    /// @notice 娓呯畻杩囩▼涓紝绯荤粺灏嗕互鎶樻墸浠峰嚭鍞粨浣嶄腑鐨勬姷鎶肩墿锛?
    /// @notice 浠讳綍浜洪兘鍙互閫氳繃璋冪敤姝ゅ嚱鏁版潵璐拱浠撲綅涓殑鎶垫娂鐗┿€?
    /// @param positionId 浠撲綅ID
    /// @param assetAmount 鐢ㄤ簬璐拱鎶垫娂鐗╃殑n璧勪骇鐨勬暟閲?
    function auction(uint positionId, uint assetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "There is no such a position, or it was removed.");
        // 娓呯畻鏁伴噺涓嶈兘鏄?
        require((assetAmount > 0) && assetAmount <= position.assetAmount, "Amount must be greater than 0 and less than the amount in position.");

        //n璧勪骇蹇呴』娌℃湁琚€€甯?
        AssetConfig memory assetConfig = asset.asset(address(position.assetToken));
        require(!assetConfig.delisted, "Asset was already delisted.");

        CAssetConfig memory cAssetConfig = asset.cAsset(address(position.cAssetToken));

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        (v.assetPrice, v.assetPriceDecimals) = _getPrice(assetConfig.token, false);
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(cAssetConfig.token, true);

        require(_checkPositionInAuction(position, v), "Cannot liquidate a safely collateralized position");

        // uint assetPriceInCollateral = (v.assetPrice / (10 ** v.assetPriceDecimals)) / (v.collateralPrice / (10 ** v.collateralPriceDecimals));
        // uint discountedPrice = assetPriceInCollateral / (assetConfig.auctionDiscount / 1000);
        // uint discountedValue = assetAmount * discountedPrice;
        // uint discountedPrice = v.assetPrice * (10 ** v.collateralPriceDecimals) * 1000 / (10 ** v.assetPriceDecimals) / v.collateralPrice / assetConfig.auctionDiscount;
        // uint discountedValue = assetAmount * v.assetPrice * (10 ** v.collateralPriceDecimals) * 1000 / (10 ** v.assetPriceDecimals) / v.collateralPrice / assetConfig.auctionDiscount;
        uint c = assetAmount * v.assetPrice * (10 ** v.collateralPriceDecimals) * 1000;
        uint discountedValue = c / (10 ** v.assetPriceDecimals) / v.collateralPrice / assetConfig.auctionDiscount;

        // uint returnedCollateralAmount;
        // uint refundedAssetAmount;
        VarsInAuction memory va = VarsInAuction(0, 0, 0, 0, 0, 0);

        if(discountedValue > position.cAssetAmount) {
            va.returnedCollateralAmount = position.cAssetAmount;
            // uint discountedPrice = v.assetPrice * (10 ** v.collateralPriceDecimals) * 1000 / (10 ** v.assetPriceDecimals) / v.collateralPrice / assetConfig.auctionDiscount;
            // refundedAssetAmount = (discountedValue - position.cAssetAmount) / discountedPrice;

            // discountedPrice = d / e
            uint d = v.assetPrice * (10 ** v.collateralPriceDecimals) * 1000;
            // uint e = (10 ** v.assetPriceDecimals) * v.collateralPrice * assetConfig.auctionDiscount;
            va.refundedAssetAmount = (discountedValue - position.cAssetAmount) * (10 ** v.assetPriceDecimals) * v.collateralPrice * assetConfig.auctionDiscount / d;
        } else {
            va.returnedCollateralAmount = discountedValue;
            va.refundedAssetAmount = 0;
        }

        va.liquidatedAssetAmount = assetAmount - va.refundedAssetAmount;

        va.leftAssetAmount = position.assetAmount - va.liquidatedAssetAmount;
        va.leftCAssetAmount = position.cAssetAmount - va.returnedCollateralAmount;

        bool closedPosition = false;

        if(va.leftCAssetAmount == 0) {
            closedPosition = true;
            positions.removePosition(positionId);
            // TODO 鑰冭檻鏈夋病鏈夊墿浣檔璧勪骇鐨勬儏鍐?
        } else if(va.leftAssetAmount == 0) {
            closedPosition = true;
            positions.removePosition(positionId);
            // refunds left collaterals to position owner
            position.cAssetToken.safeTransfer(position.owner, va.leftCAssetAmount);
        } else {
            position.cAssetAmount = va.leftCAssetAmount;
            position.assetAmount = va.leftAssetAmount;
            positions.updatePosition(position);
        }

        position.assetToken.burnFrom(msg.sender, va.liquidatedAssetAmount);

        // uint assetPriceInCollateral = (v.assetPrice / (10 ** v.assetPriceDecimals)) / (v.collateralPrice / (10 ** v.collateralPriceDecimals));
        // uint protocolFee_ = liquidatedAssetAmount * assetPriceInCollateral * feeRate / 1000;
        va.protocolFee_ = va.liquidatedAssetAmount * v.assetPrice * (10 ** v.collateralPriceDecimals) / (10 ** v.assetPriceDecimals) / v.collateralPrice * feeRate / 1000;
        protocolFee[address(position.cAssetToken)] += va.protocolFee_;

        va.returnedCollateralAmount = va.returnedCollateralAmount - va.protocolFee_;
        position.cAssetToken.safeTransfer(msg.sender, va.returnedCollateralAmount);

        emit Auction(positionId, assetAmount);

        if(position.isShort) {
            staking.withdraw(assetConfig.poolId, assetAmount, msg.sender);
            if(closedPosition) {
                lock.release(positionId);
            }
        }
    }

    /// @notice 鏌ヨ鏌愪釜浠撲綅鏄惁姝ｅ浜庢竻绠楃姸鎬?
    /// @param positionId 浠撲綅ID
    /// @return bool - 璇ヤ粨浣嶆槸鍚︽鍦ㄨ娓呯畻銆?
    function isInAuction(uint positionId) external view returns(bool) {
        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);
        Position memory position = positions.getPosition(positionId);
        AssetConfig memory assetConfig = asset.asset(address(position.assetToken));
        CAssetConfig memory cAssetConfig = asset.cAsset(address(position.cAssetToken));

        if (!position.assigned) {
            return false;
        }

        (v.assetPrice, v.assetPriceDecimals) = _getPrice(assetConfig.token, false);
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(cAssetConfig.token, true);

        return _checkPositionInAuction(position, v);
    }

    function _getPrice(IERC20Extented token, bool isCollateral) private view returns(uint, uint8) {
        AggregatorV3Interface oracle;
        if(isCollateral) {
            require(asset.cAsset(address(token)).assigned, "Collateral not been listed yet, or be removed.");
            if(address(asset.cAsset(address(token)).oracle) == address(0x0)) {
                // 绋冲畾甯?
                return (uint(100000000), uint8(8));
            }
            if(asset.asset(address(token)).assigned && asset.asset(address(token)).delisted) {
                // 鏄姷鎶肩墿锛屽悓鏃跺張鏄痭璧勪骇锛岃€屼笖宸查€€甯?
                return (asset.asset(address(token)).endPrice, asset.asset(address(token)).endPriceDecimals);
            }
            oracle = asset.cAsset(address(token)).oracle;
        } else {
            require(asset.asset(address(token)).assigned, "Asset was not registered yet.");
            if(asset.asset(address(token)).delisted) {
                // 宸查€€甯傜殑n璧勪骇
                return (asset.asset(address(token)).endPrice, asset.asset(address(token)).endPriceDecimals);
            }
            oracle = asset.asset(address(token)).oracle;
        }
        
        (
            , 
            int price,
            uint startedAt,
            ,
        ) = oracle.latestRoundData();

        require((block.timestamp - startedAt) < _oracleMaxDelay, "Price expired.");
        require(price >= 0, "Price is incorrect.");

        uint8 decimals = oracle.decimals();

        return (uint(price), decimals);
    }

    function _checkPositionInAuction(Position memory position, VarsInFuncs memory v) private view returns(bool) {
        CAssetConfig memory cAssetConfig = asset.cAsset(address(position.cAssetToken));
        AssetConfig memory assetConfig = asset.asset(address(position.assetToken));
        // uint assetPriceInCollateral = (v.assetPrice / (10 ** v.assetPriceDecimals)) / (v.collateralPrice / (10 ** v.collateralPriceDecimals));
        // uint assetValueInCollateral = position.assetAmount / position.assetToken.decimals() * assetPriceInCollateral * position.cAssetToken.decimals();
        uint assetValueInCollateral = position.assetAmount * v.assetPrice * (10 ** v.collateralPriceDecimals) * position.cAssetToken.decimals() 
            / (10 ** v.assetPriceDecimals) / v.collateralPrice / position.assetToken.decimals();
        
        uint expectedAmount = assetValueInCollateral * assetConfig.minCRatio / 1000 * cAssetConfig.multiplier;
        
        return (expectedAmount >= position.cAssetAmount);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}