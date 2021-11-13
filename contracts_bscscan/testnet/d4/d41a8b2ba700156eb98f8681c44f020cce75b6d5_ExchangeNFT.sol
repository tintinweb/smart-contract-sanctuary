/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/math/Math.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Holder.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts/libraries/EnumerableMap.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableMap.sol
 */
library EnumerableMap {
    struct MapEntry {
        uint256 _key;
        uint256 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(uint256 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        uint256 key,
        uint256 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, uint256 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, uint256 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (uint256, uint256) {
        require(map._entries.length > index, 'EnumerableMap: index out of bounds');

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, uint256 key) private view returns (uint256) {
        return _get(map, key, 'EnumerableMap: nonexistent key');
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        uint256 key,
        string memory errorMessage
    ) private view returns (uint256) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToUintMap

    struct UintToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return _get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return _get(map._inner, key, errorMessage);
    }
}

// File: contracts/ExchangeNFT.sol

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;











contract ExchangeNFT is ERC721Holder, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public MAX_TRADABLE_TOKEN_ID = 100000000;
    uint256 public DIVIDER = 1000;
    uint256 private fee_rate = 25;
    IERC721 public nft;
    IERC20 public quoteErc20;
    address payable public operator;
    address payable public admin_fee;
    EnumerableSet.AddressSet private _operators;
    //一口价[ETH]
    EnumerableMap.UintToUintMap private _asksMap;
    //一口价[ERC20]
    EnumerableMap.UintToUintMap private _asksMapErc20;
    mapping(uint256 => address) private _tokenSellers;
    mapping(address => EnumerableSet.UintSet) private _userSellingTokens;
    //拍卖[ETH]
    EnumerableMap.UintToUintMap private _initialPricesMap; //作品起拍价
    EnumerableMap.UintToUintMap private _deadlineMap; //作品竞价时间
    //拍卖[ERC20]
    EnumerableMap.UintToUintMap private _initialPricesMapErc20; //作品起拍价
    EnumerableMap.UintToUintMap private _deadlineMapErc20; //作品竞价时间
    mapping(uint256 => mapping(address=>uint256)) private _tokenBidOffers;//竞价Map
    mapping(uint256 => EnumerableSet.AddressSet) private _tokenAddressOfferSet; //竞价的地址集合;

    event OneTimeOfferTrade(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);
    event OneTimeOfferTradeERC20(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);
    event DueTrade(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);
    event DueTradeERC20(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);
    event AskETH(address indexed seller, uint256 indexed tokenId, uint256 price);
    event AskERC20(address indexed seller, uint256 indexed tokenId, uint256 price);
    event CancelSellTokenETH(address indexed seller, uint256 indexed tokenId);
    event CancelSellTokenERC20(address indexed seller, uint256 indexed tokenId);
    event NewAuctionETH(address indexed seller, uint256 indexed tokenId, uint256 price);
    event NewAuctionERC20(address indexed seller, uint256 indexed tokenId, uint256 price);
    event NewOfferETH(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event NewOfferERC20(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event DistributeNFT(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event DistributeNFTERC20(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event UpdateMaxTradableTokenId(uint256 indexed oldId, uint256 newId);

    constructor(address _nftAddress, address _quoteErc20Address) public {
        require(_nftAddress != address(0) && _nftAddress != address(this));
        require(_quoteErc20Address != address(0) && _quoteErc20Address != address(this));
        nft = IERC721(_nftAddress);
        quoteErc20 = IERC20(_quoteErc20Address);
	operator = msg.sender;
	admin_fee = msg.sender;
	EnumerableSet.add(_operators, operator);
    }

    //一口价购买[ETH]
    function buyTokenByETH(uint256 _tokenId) public payable whenNotPaused {
        require(msg.sender != address(0) && msg.sender != address(this), 'Wrong msg sender');
        require(_asksMap.contains(_tokenId), 'Token not in sell book');
        uint256 price = _asksMap.get(_tokenId);
	require(msg.value >= price, "Bigger than price");

	//admin fee
	admin_fee.transfer(price.mul(fee_rate).div(DIVIDER));
	//transfer to seller 
	payable(_tokenSellers[_tokenId]).transfer(price.mul(DIVIDER.sub(fee_rate)).div(DIVIDER));

        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        _asksMap.remove(_tokenId);
        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        emit OneTimeOfferTrade(_tokenSellers[_tokenId], msg.sender, _tokenId, price);
        delete _tokenSellers[_tokenId];
    }
    //一口价购买[ERC20]
    function buyTokenByErc20(uint256 _tokenId) public whenNotPaused {
        require(msg.sender != address(0) && msg.sender != address(this), 'Wrong msg sender');
        require(_asksMapErc20.contains(_tokenId), 'Token not in sell book');
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        uint256 price = _asksMap.get(_tokenId);

	//admin_fee
        quoteErc20.safeTransferFrom(msg.sender, admin_fee, price.mul(fee_rate.div(DIVIDER)));
	//transfer to seller
        quoteErc20.safeTransferFrom(msg.sender, _tokenSellers[_tokenId], price.mul(DIVIDER.sub(fee_rate).div(DIVIDER)));

        _asksMapErc20.remove(_tokenId);
        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        emit OneTimeOfferTradeERC20(_tokenSellers[_tokenId], msg.sender, _tokenId, price);
        delete _tokenSellers[_tokenId];
    }

    //设置NFT作品一口价价格[ETH]
    function setCurrentPriceETH(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(_userSellingTokens[msg.sender].contains(_tokenId), 'Only Seller can update price');
        require(_price > 0, 'Price must be granter than zero');
        _asksMap.set(_tokenId, _price);
        emit AskETH(msg.sender, _tokenId, _price);
    }
    //设置NFT作品一口价价格[ERC20]
    function setCurrentPriceErc20(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(_userSellingTokens[msg.sender].contains(_tokenId), 'Only Seller can update price');
        require(_price > 0, 'Price must be granter than zero');
        _asksMapErc20.set(_tokenId, _price);
        emit AskERC20(msg.sender, _tokenId, _price);
    }

    //上架一口价销售[ETH]
    function readyToSellTokenETH(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(msg.sender == nft.ownerOf(_tokenId), 'Only Token Owner can sell token');
        require(_price > 0, 'Price must be granter than zero');
        require(_tokenId <= MAX_TRADABLE_TOKEN_ID, 'TokenId must be less than MAX_TRADABLE_TOKEN_ID');
        nft.safeTransferFrom(address(msg.sender), address(this), _tokenId);
        _asksMap.set(_tokenId, _price);
        _tokenSellers[_tokenId] = address(msg.sender);
        _userSellingTokens[msg.sender].add(_tokenId);
        emit AskETH(msg.sender, _tokenId, _price);
    }
    //上架一口价销售[ERC20]
    function readyToSellTokenERC20(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(msg.sender == nft.ownerOf(_tokenId), 'Only Token Owner can sell token');
        require(_price > 0, 'Price must be granter than zero');
        require(_tokenId <= MAX_TRADABLE_TOKEN_ID, 'TokenId must be less than MAX_TRADABLE_TOKEN_ID');
        nft.safeTransferFrom(address(msg.sender), address(this), _tokenId);
        _asksMapErc20.set(_tokenId, _price);
        _tokenSellers[_tokenId] = address(msg.sender);
        _userSellingTokens[msg.sender].add(_tokenId);
        emit AskERC20(msg.sender, _tokenId, _price);
    }

    //取消一口价售卖[ETH]
    function cancelSellTokenETH(uint256 _tokenId) public whenNotPaused {
        require(_userSellingTokens[msg.sender].contains(_tokenId), 'Only Seller can cancel sell token');
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        _asksMap.remove(_tokenId);
        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        delete _tokenSellers[_tokenId];
        emit CancelSellTokenETH(msg.sender, _tokenId);
    }
    //取消一口价售卖[ERC20]
    function cancelSellTokenERC20(uint256 _tokenId) public whenNotPaused {
        require(_userSellingTokens[msg.sender].contains(_tokenId), 'Only Seller can cancel sell token');
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        _asksMapErc20.remove(_tokenId);
        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        delete _tokenSellers[_tokenId];
        emit CancelSellTokenERC20(msg.sender, _tokenId);
    }

    //获取一口价售卖NFT数量[ETH]
    function getAskEthLength() public view returns (uint256) {
        return _asksMap.length();
    }
    //获取一口价售卖NFT数量[ERC20]
    function getAskERC20Length() public view returns (uint256) {
        return _asksMapErc20.length();
    }

    //上架NFT作品拍卖[ETH]
    //deadline为秒数
    function readyToAuctionTokenETH(uint256 _tokenId, uint256 _price, uint256 deadline) public payable whenNotPaused {
        require(msg.sender == nft.ownerOf(_tokenId), 'Only Token Owner can sell token');
        require(_price > 0, 'Price must be granter than zero');
        require(_tokenId <= MAX_TRADABLE_TOKEN_ID, 'TokenId must be less than MAX_TRADABLE_TOKEN_ID');
        require(msg.value>1e15, "Gas fee for operator.");
	operator.transfer(msg.value);
        nft.safeTransferFrom(address(msg.sender), address(this), _tokenId);
        _initialPricesMap.set(_tokenId, _price);
	uint256 ts = block.timestamp.add(deadline);
	_deadlineMap.set(_tokenId, ts);
        _tokenSellers[_tokenId] = address(msg.sender);
        _userSellingTokens[msg.sender].add(_tokenId);
        emit NewAuctionETH(msg.sender, _tokenId, _price);
    }
    //上架NFT作品拍卖[ERC20]
    //deadline为秒数
    function readyToAuctionTokenERC20(uint256 _tokenId, uint256 _price, uint256 deadline) public payable whenNotPaused {
        require(msg.sender == nft.ownerOf(_tokenId), 'Only Token Owner can sell token');
        require(_price > 0, 'Price must be granter than zero');
        require(_tokenId <= MAX_TRADABLE_TOKEN_ID, 'TokenId must be less than MAX_TRADABLE_TOKEN_ID');
        require(msg.value>1e15, "Gas fee for operator.");
	operator.transfer(msg.value);
        nft.safeTransferFrom(address(msg.sender), address(this), _tokenId);
        _initialPricesMapErc20.set(_tokenId, _price);
	uint256 ts = block.timestamp.add(deadline);
	_deadlineMapErc20.set(_tokenId, ts);
        _tokenSellers[_tokenId] = address(msg.sender);
        _userSellingTokens[msg.sender].add(_tokenId);
        emit NewAuctionETH(msg.sender, _tokenId, _price);
    }
   
     //针对某个NFT作品offer一个价格（ETH）
     function makeOfferETH(uint256 _tokenId) external payable  returns (bool){
 
         require(_initialPricesMap.contains(_tokenId), 'Token not in sell book');

	 require(block.timestamp < getDeadlineETH(_tokenId), 'Auction is out-dated');
 
	 _tokenBidOffers[_tokenId][msg.sender] = _tokenBidOffers[_tokenId][msg.sender].add(msg.value); 

	 if(!_tokenAddressOfferSet[_tokenId].contains(msg.sender))
		_tokenAddressOfferSet[_tokenId].add(msg.sender);

         emit NewOfferETH(msg.sender, _tokenId, msg.value);
 
         return true;
     }
     //针对某个NFT作品offer一个价格（ERC20）
     function makeOfferERC20(uint256 _tokenId) external payable  returns (bool){
 
         require(_initialPricesMapErc20.contains(_tokenId), 'Token not in sell book');

	 require(block.timestamp < getDeadlineErc20(_tokenId), 'Auction is out-dated');
 
	 _tokenBidOffers[_tokenId][msg.sender] = _tokenBidOffers[_tokenId][msg.sender].add(msg.value); 

	 if(!_tokenAddressOfferSet[_tokenId].contains(msg.sender))
		_tokenAddressOfferSet[_tokenId].add(msg.sender);

         emit NewOfferERC20(msg.sender, _tokenId, msg.value);
 
         return true;
     }
     //获取自己对某个NFT的出价
     function getMyOfferPrice(uint256 _tokenId, address account) public view returns (uint256) {
         return _tokenBidOffers[_tokenId][account];
     }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
    //获取某个拍卖作品的初始拍卖价[ETH]
     function getInitialPriceETH(uint256 _tokenId) public view returns (uint256)
    {
	return _initialPricesMap.get(_tokenId);
    }
    //获取某个拍卖作品的初始拍卖价[ERC20]
     function getInitialPriceERC20(uint256 _tokenId) public view returns (uint256)
    {
	return _initialPricesMapErc20.get(_tokenId);
    }
    //获取某个拍卖作品的过期时间戳[ETH]
     function getDeadlineETH(uint256 _tokenId) public view returns (uint256)
    {
	return _deadlineMap.get(_tokenId);
    }
    //获取某个拍卖作品的过期时间戳[ERC20]
     function getDeadlineErc20(uint256 _tokenId) public view returns (uint256)
    {
	return _deadlineMapErc20.get(_tokenId);
    }
	
    //更新tokenId最大值
    function updateMaxTradableTokenId(uint256 _max_tradable_token_id) public onlyOwner {
        emit UpdateMaxTradableTokenId(MAX_TRADABLE_TOKEN_ID, _max_tradable_token_id);
        MAX_TRADABLE_TOKEN_ID = _max_tradable_token_id;
    }

    //更新NFT合约
    function updateNFTContract(address _nftAddress) public onlyOwner {
	require(_nftAddress != address(0) && _nftAddress != address(this));
        nft = IERC721(_nftAddress);
    }
    //更新底层购买代币
    function updateQuoteErc20(address _quoteErc20Address) public onlyOwner {
	require(_quoteErc20Address != address(0) && _quoteErc20Address != address(this));
        quoteErc20 = IERC20(_quoteErc20Address);
    }
    //更新operator地址
    function updateOperator(address payable _operatorAddress) public onlyOwner {
	require(_operatorAddress!= address(0) && _operatorAddress != address(this));
        operator = _operatorAddress;
    }
    //更新admin_fee地址
    function updateAdminFee(address payable _adminFeeAddress) public onlyOwner {
	require(_adminFeeAddress!= address(0) && _adminFeeAddress != address(this));
	admin_fee = _adminFeeAddress;
    }
    //更新admin_fee rate
    function updateFeeRate(uint256 _feeRate) public onlyOwner {
	fee_rate = _feeRate;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
     function emergencyWithdraw() onlyOwner public {
         uint256 eth_amount = address(this).balance;
         uint256 erc20_amount = quoteErc20.balanceOf(address(this));
         if(eth_amount > 0)
                 msg.sender.transfer(eth_amount);
         if(erc20_amount > 0)
                 quoteErc20.transfer(msg.sender, erc20_amount);
     }

     //Transfer NFT to 最高出价者（到期后）[ETH]
     function distributeNFT(address _receiver, uint256 _tokenId, uint256 _price) external onlyOperator returns (bool){
 
         require(_receiver != address(0), "Invalid receiver address");
         require(_initialPricesMap.contains(_tokenId), 'Token not in sell book');
         require(_price>0, "Invalid price");
 
         nft.safeTransferFrom(address(this), _receiver, _tokenId);

	 address payable seller = payable(_tokenSellers[_tokenId]);
	//admin fee
	admin_fee.transfer(_price.mul(fee_rate).div(DIVIDER));
	//transfer to seller 
	seller.transfer(_price.mul(DIVIDER.sub(fee_rate)).div(DIVIDER));
 
        //给make offer的人退ETH
        for (uint256 i = 0; i < _tokenAddressOfferSet[_tokenId].length(); ++i) {
            address payable account = payable(_tokenAddressOfferSet[_tokenId].at(i));
	    if(address(account) == _receiver)
		continue;
            uint256 price = _tokenBidOffers[_tokenId][account];
	    account.transfer(price); //退款
	    delete _tokenBidOffers[_tokenId][account];
        }

        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        emit DistributeNFT(_receiver, _tokenId, _price);
        emit DueTrade(_tokenSellers[_tokenId], _receiver, _tokenId, _price);
        delete _tokenSellers[_tokenId];
        _initialPricesMap.remove(_tokenId);
        _deadlineMap.remove(_tokenId);
        delete _tokenAddressOfferSet[_tokenId];
 
        return true;
     }
     //Transfer NFT to 最高出价者（到期后）[ERC20]
     function distributeNFTERC20(address _receiver, uint256 _tokenId, uint256 _price) external onlyOperator returns (bool){
 
         require(_receiver != address(0), "Invalid receiver address");
         require(_initialPricesMapErc20.contains(_tokenId), 'Token not in sell book');
         require(_price>0, "Invalid price");
 
         nft.safeTransferFrom(address(this), _receiver, _tokenId);

	 //admin_fee
         quoteErc20.safeTransferFrom(address(this), admin_fee, _price.mul(fee_rate.div(DIVIDER)));
	 //transfer to seller
         quoteErc20.safeTransferFrom(address(this), _tokenSellers[_tokenId], _price.mul(DIVIDER.sub(fee_rate).div(DIVIDER)));
 
        //给make offer的人退ERC20
        for (uint256 i = 0; i < _tokenAddressOfferSet[_tokenId].length(); ++i) {
            address account = _tokenAddressOfferSet[_tokenId].at(i);
	    if(account == _receiver)
		continue;
            uint256 price = _tokenBidOffers[_tokenId][account];
	    quoteErc20.safeTransferFrom(address(this), account, price);
	    delete _tokenBidOffers[_tokenId][account];
        }

        _userSellingTokens[_tokenSellers[_tokenId]].remove(_tokenId);
        emit DistributeNFTERC20(_receiver, _tokenId, _price);
        emit DueTradeERC20(_tokenSellers[_tokenId], _receiver, _tokenId, _price);
        delete _tokenSellers[_tokenId];
        _initialPricesMapErc20.remove(_tokenId);
        _deadlineMapErc20.remove(_tokenId);
        delete _tokenAddressOfferSet[_tokenId];
 
        return true;
     }


    /***********************************|
     |        Operators Functions         |
     |__________________________________*/
     function addOperator(address payable _addOperator) public onlyOwner returns (bool) {
         require(_addOperator != address(0), "_addOperator is the zero address");
	 operator = _addOperator;
         return EnumerableSet.add(_operators, _addOperator);
     }
 
     function delOperator(address _delOperator) public onlyOwner returns (bool) {
         require(_delOperator != address(0), "_delOperator is the zero address");
         return EnumerableSet.remove(_operators, _delOperator);
     }
 
     function getOperatorLength() public view returns (uint256) {
         return EnumerableSet.length(_operators);
     }
 
     function isOperator(address account) public view returns (bool) {
         return EnumerableSet.contains(_operators, account);
     }
 
     function getOperator(uint256 _index) public view onlyOwner returns (address){
         require(_index <= getOperatorLength() - 1, "index out of bounds");
         return EnumerableSet.at(_operators, _index);
     }
 
     // modifier for transfer function
     modifier onlyOperator() {
         require(isOperator(msg.sender), "caller is not the operator");
         _;
     }
}