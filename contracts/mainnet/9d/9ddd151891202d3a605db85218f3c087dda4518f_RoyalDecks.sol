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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./libraries/SafeMath96.sol";
import "./libraries/SafeMath32.sol";

// Stake a package from one NFT and some amount of $KINGs to "farm" more $KINGs.
// If $KING airdrops for NFT holders happen, rewards will go to stake holders.
contract RoyalDecks is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath96 for uint96;
    using SafeMath32 for uint32;

    using SafeERC20 for IERC20;

    // The $KING amount to return on stake withdrawal is calculated as:
    // `amountDue = Stake.amountStaked * TermSheet.kingFactor/1e+6` (1)

    // On top of amount (1), airdrop $KING rewards may be distributed
    // between NFTs holders. The contract collects airdrops for users.
    // Any time, pended airdrop $KING amount entitled to a stake holder:
    // `airdrop = accAirKingPerNft[nft] - accAirKingBias[stakeId]`  (2)

    struct Stake {
        uint96 amountStaked;   // $KING amount staked on `startTime`
        uint96 amountDue;      // $KING amount due on `unlockTime`
        uint32 startTime;      // UNIX-time the tokens get staked on
        uint32 unlockTime;     // UNIX-time the tokens get locked until
    }

    struct TermSheet {
        bool enabled;          // If staking is enabled
        address nft;           // ERC-721 contract of the NFT to stake
        uint96 minAmount;      // Min $KING amount to stake (with the NFT)
        uint96 kingFactor;     // Multiplier, scaled by 1e+6 (see (1) above)
        uint16 lockHours;      // Staking period in hours
    }

    // All stakes of a user
    struct UserStakes {
        // Set of (unique) stake IDs (see `encodeStakeId` function)
        uint256[] ids;
        // Mapping from stake ID to stake data
        mapping(uint256 => Stake) data;
    }

    bool public emergencyWithdrawEnabled = false;

    // Latest block when airdrops rewards was "collected"
    uint32 lastAirBlock;

    // Amounts in $KING
    uint96 public kingDue;
    uint96 public kingReserves;

    // The $KING token contract
    address public king;

    // Info on each TermSheet
    TermSheet[] internal termSheets;

    // Addresses and "airdrop weights" of NFT contracts (stored as uint256)
    uint256[] internal airPools;
    uint256 constant internal MAX_AIR_POOLS_QTY = 12; // to limit gas

    // Mapping from user account to user stakes
    mapping(address => UserStakes) internal stakes;

    // Mapping from NFT address to accumulated airdrop rewards - see (2) above
    mapping(address => uint256) internal accAirKingPerNft;

    // Mapping from stake ID to "reward bias" for the stake - see (2) above
    mapping(uint256 => uint256) internal accAirKingBias;

    event Deposit(
        address indexed user,
        uint256 stakeId,       // ID of the NFT
        uint256 amountStaked,  // $KING amount staked
        uint256 amountDue,     // $KING amount to be returned
        uint256 unlockTime     // UNIX-time when the stake is unlocked
    );

    event Withdraw(
        address indexed user,
        uint256 stakeId        // ID of the NFT
    );

    event Emergency(bool enabled);
    event EmergencyWithdraw(
        address indexed user,
        uint256 stakeId        // ID of the NFT
    );

    event NewTermSheet(
        uint256 indexed termsId,
        address indexed nft,   // Address of the ERC-721 contract
        uint256 minAmount,     // Min $KING amount to stake
        uint256 lockHours,     // Staking period in hours
        uint256 kingFactor     // See (1) above
    );

    event TermsEnabled(uint256 indexed termsId);
    event TermsDisabled(uint256 indexed termsId);

    // $KING added to or removed from stakes repayment reserves
    event Reserved(uint256 amount);
    event Removed(uint256 amount);

    // $KING amount collected as an airdrop reward
    event Airdrop(uint256 amount);

    constructor(address _king) public {
        king = _king;
    }

    // Stake ID uniquely identifies a stake
    // (`stakeHours` excessive for stakes identification but needed for the UI)
    function encodeStakeId(
        address nft,           // NFT contract address
        uint256 nftId,         // Token ID (limited to 48 bits)
        uint256 startTime,     // UNIX time (limited to 32 bits)
        uint256 stakeHours     // Stake duration (limited to 16 bits)
    ) public pure returns (uint256) {
        require(nftId < 2**48, "RDeck::nftId_EXCEEDS_48_BITS");
        require(startTime < 2**32, "RDeck::nftId_EXCEEDS_32_BITS");
        require(stakeHours < 2**16, "RDeck::stakeHours_EXCEEDS_16_BITS");
        return _encodeStakeId(nft, nftId, startTime, stakeHours);
    }

    function decodeStakeId(uint256 stakeId)
        public
        pure
        returns (
            address nft,
            uint256 nftId,
            uint256 startTime,
            uint256 stakeHours
        )
    {
        nft = address(stakeId >> 96);
        nftId = (stakeId >> 48) & (2**48 - 1);
        startTime = (stakeId >> 16) & (2**32 - 1);
        stakeHours = stakeId & (2**16 - 1);
    }

    function stakeIds(address user) external view returns (uint256[] memory) {
        _revertZeroAddress(user);
        UserStakes storage userStakes = stakes[user];
        return userStakes.ids;
    }

    function stakeData(
        address user,
        uint256 stakeId
    ) external view returns (Stake memory)
    {
        return stakes[_nonZeroAddr(user)].data[stakeId];
    }

    function pendedAirdrop(
        uint256 stakeId
    ) external view returns (uint256 kingAmount) {
        kingAmount = 0;
        (address nft, , , ) = decodeStakeId(stakeId);
        if (nft != address(0)) {
            uint256 accAir = accAirKingPerNft[nft];
            if (accAir > 1) {
                uint256 bias = accAirKingBias[stakeId];
                if (accAir > bias) kingAmount = accAir.sub(bias);
            }
        }
    }

    function termSheet(uint256 termsId) external view returns (TermSheet memory) {
        return termSheets[_validTermsID(termsId)];
    }

    function termsLength() external view returns (uint256) {
        return termSheets.length;
    }

    // Deposit 1 NFT and `kingAmount` of $KING
    function deposit(
        uint256 termsId,       // term sheet ID
        uint256 nftId,         // ID of NFT to stake
        uint256 kingAmount     // $KING amount to stake
    ) public nonReentrant {
        TermSheet memory terms = termSheets[_validTermsID(termsId)];
        require(terms.enabled, "deposit: terms disabled");

        uint96 amountStaked = SafeMath96.fromUint(kingAmount);
        require(amountStaked >= terms.minAmount, "deposit: too small amount");

        uint96 amountDue = SafeMath96.fromUint(
            kingAmount.mul(uint256(terms.kingFactor)).div(1e6)
        );
        uint96 _totalDue = kingDue.add(amountDue);
        uint96 _newReserves = kingReserves.add(amountStaked);
        require(_newReserves >= _totalDue, "deposit: too low reserves");

        uint256 stakeId = _encodeStakeId(
            terms.nft,
            nftId,
            now,
            terms.lockHours
        );

        IERC20(king).safeTransferFrom(msg.sender, address(this), amountStaked);
        IERC721(terms.nft).safeTransferFrom(
            msg.sender,
            address(this),
            nftId,
            _NFT_PASS
        );

        kingDue = _totalDue;
        kingReserves = _newReserves;

        uint32 startTime = SafeMath32.fromUint(now);
        uint32 unlockTime = startTime.add(uint32(terms.lockHours) * 3600);
        _addUserStake(
            stakes[msg.sender],
            stakeId,
            Stake(
                amountStaked,
                amountDue,
                startTime,
                SafeMath32.fromUint(unlockTime)
            )
        );

        uint256 accAir = accAirKingPerNft[terms.nft];
        if (accAir > 1) accAirKingBias[stakeId] = accAir;

        emit Deposit(msg.sender, stakeId, kingAmount, amountDue, unlockTime);
    }

    // Withdraw staked 1 NFT and entire $KING token amount due
    function withdraw(uint256 stakeId) public nonReentrant {
        _withdraw(stakeId, false);
        emit Withdraw(msg.sender, stakeId);
    }

    // Withdraw staked 1 NFT and staked $KING token amount, w/o any rewards
    // !!! All possible rewards entitled be lost. Use in emergency only !!!
    function emergencyWithdraw(uint256 stakeId) public nonReentrant {
        _withdraw(stakeId, true);
        emit EmergencyWithdraw(msg.sender, stakeId);
    }

    // Account for $KING amount the contact has got as airdrops for NFTs staked
    // !!! Be cautious of high gas cost
    function collectAirdrops() external nonReentrant {
        if (block.number <= lastAirBlock) return;
        lastAirBlock = SafeMath32.fromUint(block.number);

        // $KING balance exceeding `kingReserves` treated as airdrop rewards
        uint256 reward;
        {
            uint256 _kingReserves = kingReserves;
            uint256 kingBalance = IERC20(king).balanceOf(address(this));
            if (kingBalance <= _kingReserves) return;
            reward = kingBalance.sub(_kingReserves);
            kingReserves = SafeMath96.fromUint(_kingReserves.add(reward));
            kingDue = kingDue.add(uint96(reward));
        }

        // First, compute "weights" for rewards distribution
        address[MAX_AIR_POOLS_QTY] memory nfts;
        uint256[MAX_AIR_POOLS_QTY] memory weights;
        uint256 totalWeight;
        uint256 qty = airPools.length;
        uint256 k = 0;
        for (uint256 i = 0; i < qty; i++) {
            (address nft, uint256 weight) = _unpackAirPoolData(airPools[i]);
            uint256 nftQty = IERC721(nft).balanceOf(address(this));
            if (nftQty == 0 || weight == 0) continue;
            nfts[k] = nft;
            weights[k] = weight;
            k++;
            totalWeight = totalWeight.add(nftQty.mul(weight));
        }

        // Then account for rewards in pools
        for (uint i = 0; i <= k; i++) {
            address nft = nfts[i];
            accAirKingPerNft[nft] = accAirKingPerNft[nft].add(
                reward.mul(weights[i]).div(totalWeight) // can't be zero
            );
        }
        emit Airdrop(reward);
    }

    function addTerms(TermSheet[] memory _termSheets) public onlyOwner {
        for (uint256 i = 0; i < _termSheets.length; i++) {
            _addTermSheet(_termSheets[i]);
        }
    }

    function enableTerms(uint256 termsId) external onlyOwner {
        termSheets[_validTermsID(termsId)].enabled = true;
        emit TermsEnabled(termsId);
    }

    function disableTerms(uint256 termsId) external onlyOwner {
        termSheets[_validTermsID(termsId)].enabled = false;
        emit TermsDisabled(termsId);
    }

    function enableEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawEnabled = true;
        emit Emergency(true);
    }

    function disableEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawEnabled = false;
        emit Emergency(false);
    }

    function addAirdropPools(
        address[] memory nftAddresses,
        uint8[] memory nftWeights
    ) public onlyOwner {
        uint length = nftAddresses.length;
        require(length == nftWeights.length, "RDeck:INVALID_ARRAY_LENGTH");
        for (uint256 i = 0; i < length; i++) {
            require(
                airPools.length < MAX_AIR_POOLS_QTY,
                "RDeck:MAX_AIR_POOLS_QTY"
            );
            uint8 w = nftWeights[i];
            require(w != 0, "RDeck:INVALID_AIR_WEIGHT");
            address a = nftAddresses[i];
            _revertZeroAddress(a);
            require(accAirKingPerNft[a] == 0, "RDeck:AIR_POOL_EXISTS");
            accAirKingPerNft[a] == 1;
            airPools.push(_packAirPoolData(a, w));
        }
    }

    // Caution: it may kill pended airdrop rewards
    function removeAirdropPool(
        address nft,
        uint8 weight
    ) external onlyOwner {
        require(accAirKingPerNft[nft] != 0, "RDeck:UNKNOWN_AIR_POOL");
        accAirKingPerNft[nft] = 0;
        _removeArrayElement(airPools, _packAirPoolData(nft, weight));
    }

    function addKingReserves(address from, uint256 amount) external onlyOwner {
        IERC20(king).safeTransferFrom(from, address(this), amount);
        kingReserves = kingReserves.add(SafeMath96.fromUint(amount));
        emit Reserved(amount);
    }

    function removeKingReserves(uint256 amount) external onlyOwner {
        uint96 _newReserves = kingReserves.sub(SafeMath96.fromUint(amount));
        require(_newReserves >= kingDue, "RDeck:TOO_LOW_RESERVES");

        kingReserves = _newReserves;
        IERC20(king).safeTransfer(owner(), amount);
        emit Removed(amount);
    }

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // Equals to `bytes4(keccak256("RoyalDecks"))`
    bytes private constant _NFT_PASS = abi.encodePacked(bytes4(0x8adbe135));

    // Implementation of the ERC721 Receiver
    function onERC721Received(address, address, uint256, bytes calldata data)
        external
        returns (bytes4)
    {
        // Only accept transfers with _NFT_PASS passed as `data`
        return (data.length == 4 && data[0] == 0x8a && data[3] == 0x35)
            ? _ERC721_RECEIVED
            : bytes4(0);
    }

    function _withdraw(uint256 stakeId, bool isEmergency) internal {
        require(
            !isEmergency || emergencyWithdrawEnabled,
            "withdraw: emergency disabled"
        );

        (address nft, uint256 nftId, , ) = decodeStakeId(stakeId);

        UserStakes storage userStakes = stakes[msg.sender];
        Stake memory stake = userStakes.data[stakeId];
        require(
            isEmergency || now >= stake.unlockTime,
            "withdraw: stake is locked"
        );

        uint96 amountDue = stake.amountDue;
        require(amountDue != 0, "withdraw: unknown or returned stake");

        { // Pended airdrop rewards
            uint256 accAir = accAirKingPerNft[nft];
            if (accAir > 1) {
                uint256 bias = accAirKingBias[stakeId];
                if (accAir > bias) amountDue = amountDue.add(
                    SafeMath96.fromUint(accAir.sub(bias))
                );
            }
        }

        uint96 amountToUser = isEmergency ? stake.amountStaked : amountDue;

        _removeUserStake(userStakes, stakeId);
        kingDue = kingDue.sub(amountDue);
        kingReserves = kingReserves.sub(amountDue);

        IERC20(king).safeTransfer(msg.sender, uint256(amountToUser));
        IERC721(nft).safeTransferFrom(address(this), msg.sender, nftId);
    }

    function _addTermSheet(TermSheet memory tS) internal {
        _revertZeroAddress(tS.nft);
        require(
            (tS.minAmount != 0) && (tS.lockHours != 0) && (tS.kingFactor != 0),
            "RDeck::add:INVALID_ZERO_PARAM"
        );
        require(_isMissingTerms(tS), "RDeck::add:TERMS_DUPLICATED");
        termSheets.push(tS);

        emit NewTermSheet(
            termSheets.length - 1,
            tS.nft,
            tS.minAmount,
            tS.lockHours,
            tS.kingFactor
        );
        if (tS.enabled) emit TermsEnabled(termSheets.length);
    }

    function _safeKingTransfer(address _to, uint256 _amount) internal {
        uint256 kingBal = IERC20(king).balanceOf(address(this));
        IERC20(king).safeTransfer(_to, _amount > kingBal ? kingBal : _amount);
    }

    // Returns `true` if the term sheet has NOT been yet added.
    function _isMissingTerms(TermSheet memory newSheet)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < termSheets.length; i++) {
            TermSheet memory sheet = termSheets[i];
            if (
                sheet.nft == newSheet.nft &&
                sheet.minAmount == newSheet.minAmount &&
                sheet.lockHours == newSheet.lockHours &&
                sheet.kingFactor == newSheet.kingFactor
            ) {
                return false;
            }
        }
        return true;
    }

    function _addUserStake(
        UserStakes storage userStakes,
        uint256 stakeId,
        Stake memory stake
    ) internal {
        require(
            userStakes.data[stakeId].amountDue == 0,
            "RDeck:DUPLICATED_STAKE_ID"
        );
        userStakes.data[stakeId] = stake;
        userStakes.ids.push(stakeId);
    }

    function _removeUserStake(UserStakes storage userStakes, uint256 stakeId)
        internal
    {
        require(
            userStakes.data[stakeId].amountDue != 0,
            "RDeck:INVALID_STAKE_ID"
        );
        userStakes.data[stakeId].amountDue = 0;
        _removeArrayElement(userStakes.ids, stakeId);
    }

    // Assuming the given array does contain the given element
    function _removeArrayElement(uint256[] storage arr, uint256 el) internal {
        uint256 lastIndex = arr.length - 1;
        if (lastIndex != 0) {
            uint256 replaced = arr[lastIndex];
            if (replaced != el) {
                // Shift elements until the one being removed is replaced
                do {
                    uint256 replacing = replaced;
                    replaced = arr[lastIndex - 1];
                    lastIndex--;
                    arr[lastIndex] = replacing;
                } while (replaced != el && lastIndex != 0);
            }
        }
        // Remove the last (and quite probably the only) element
        arr.pop();
    }

    function _encodeStakeId(
        address nft,
        uint256 nftId,
        uint256 startTime,
        uint256 stakeHours
    ) internal pure returns (uint256) {
        require(nftId < 2**48, "RDeck::nftId_EXCEEDS_48_BITS");
        return uint256(nft) << 96 | nftId << 48 | startTime << 16 | stakeHours;
    }

    function _packAirPoolData(
        address nft,
        uint8 weight
    ) internal pure returns(uint256) {
        return (uint256(nft) << 8) | uint256(weight);
    }

    function _unpackAirPoolData(
        uint256 packed
    ) internal pure returns(address nft, uint8 weight)
    {
        return (address(packed >> 8), uint8(packed & 7));
    }

    function _revertZeroAddress(address _address) internal pure {
        require(_address != address(0), "RDeck::ZERO_ADDRESS");
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function _validTermsID(uint256 termsId) private view returns (uint256) {
        require(termsId < termSheets.length, "RDeck::INVALID_TERMS_ID");
        return termsId;
    }
}

pragma solidity 0.6.12;

library SafeMath32 {

    function add(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        return add(a, b, "SafeMath32: addition overflow");
    }

    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub(a, b, "SafeMath32: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function fromUint(uint n) internal pure returns (uint32) {
        return fromUint(n, "SafeMath32: exceeds 32 bits");
    }
}

pragma solidity 0.6.12;

library SafeMath96 {

    function add(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        return add(a, b, "SafeMath96: addition overflow");
    }

    function sub(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        return sub(a, b, "SafeMath96: subtraction overflow");
    }

    function fromUint(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function fromUint(uint n) internal pure returns (uint96) {
        return fromUint(n, "SafeMath96: exceeds 96 bits");
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}