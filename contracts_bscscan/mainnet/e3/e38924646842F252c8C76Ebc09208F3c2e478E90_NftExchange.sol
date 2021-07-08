/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// Sources flattened with hardhat v2.0.3 https://hardhat.org

// File @openzeppelin/contracts/GSN/[email protected]

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


// File contracts/Administrable.sol


pragma solidity ^0.6;

abstract contract Administrable is Ownable {
    mapping(address => bool) public admins;

    constructor() public Ownable() {
        admins[owner()] = true;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender]);
        _;
    }

    function addAdmin(address account) external onlyOwner {
        admins[account] = true;
    }
    function removeAdmin(address account) external onlyOwner {
        delete admins[account];
    }

    function isAdmin(address account) external view returns (bool) {
        return admins[account];
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/math/[email protected]


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
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/introspection/[email protected]

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


pragma solidity ^0.6.2;


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


// File @openzeppelin/contracts/token/ERC1155/[email protected]


pragma solidity ^0.6.2;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC721 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

   
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    
    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File @openzeppelin/contracts/token/ERC1155/[email protected]


pragma solidity ^0.6.0;

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}


// File @openzeppelin/contracts/introspection/[email protected]


pragma solidity ^0.6.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]


pragma solidity ^0.6.0;


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is IERC1155Receiver {
    
     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        public virtual override
        returns(bytes4){
            return this.onERC1155Received.selector;
        }

   
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        public virtual override
        returns(bytes4){
            return this.onERC1155BatchReceived.selector;
        }
   
}


// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

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


// File contracts/Exchange.sol


pragma solidity ^0.6;
pragma experimental ABIEncoderV2;


interface IERC1155Collection is IERC1155{
    function setURI(string memory newuri) external;
   
    function setIdURI(uint256 tokenid,string memory uri) external;
    
    function tokenURI(uint256 tokenId) external view returns (string memory);
    
    function tokenName(uint256 tokenId) external view returns (string memory);
    
    function setRoyalty(uint256 tokenid,uint256 royalty) external;
   
    function getRoyalty(uint256 tokenId) external view returns (uint256) ;
    
    function getCreator () external view returns (address payable);

    function mint(address to, uint256 value,string memory _uri, string memory _name,uint256 _royalty,bytes memory data) external;

    function burn(address owner, uint256 id, uint256 value) external;

    function burnBatch(address owner, uint256[] memory ids, uint256[] memory values) external;
    
}



contract NftExchange is Administrable,ERC721Holder,ERC1155Receiver {
    using SafeERC20 for IERC20;


    mapping (uint256 => uint256) private _next;
    mapping (uint256 => uint256) private _previous;
    uint256 private _tail;

    struct Order {
        IERC1155Collection nft;
        uint256 tokenId;
        uint256 amount;
        address payable owner;
        uint256 price;
        address exchangeToken;
        uint256 royalty;
    }

    struct BidEntity {
        uint256 price;
        address bidder;
        bool isTook;
    }

    struct UserBidHistory {
        uint256 price;
        uint256 orderId;
        bool isTook;
    }

    mapping (uint256 => Order) private _orders;
    mapping (uint256 => Order) private _orderHistory;
    mapping (address => Order[]) private _userOrdersNow;
    mapping (address => Order[]) private _userOrdersHis;
    mapping (address => uint256[]) private _extokenOrderIds;
    mapping (uint256 => BidEntity[]) private _bidQueue;
    mapping (address => UserBidHistory[]) private _userBidQueue;

    uint256 private _totalOrder;
    uint256 private _nextOrderId;
    uint256 private _feePer10000;
    address payable private _feeOwner;

    event OrderAdded(uint256 orderId, address indexed nft, uint256 id, uint256 amount, address indexed owner, uint256 price);
    event OrderRemoved(uint256 orderId);
    event PriceUpdated(uint256 orderId, uint256 price);
    event OrderTrade(uint256 orderId);
    event OrderBid(uint256 orderId, uint256 price);

    constructor(uint256 feePer10000) public {
        _nextOrderId = 1;
        _feePer10000 = feePer10000;
        _feeOwner = 0x9849bA9a22cF2509c99eb600E5895B198c1EC8E8;
    }
    
     function setFeeOwner(address payable feeOwner) external onlyAdmins{
        _feeOwner = feeOwner;
    }

    function getFeeOwner() external view returns (address payable){
        return _feeOwner;
    }

    function setFee(uint256 feePer10000) external onlyAdmins{
        _feePer10000 = feePer10000;
    }

    function getFee() external view returns (uint256){
        return _feePer10000;
    }

    function totalOrder() external view returns (uint256) {
        return _totalOrder;
    }
    function getAllOrders() external view returns (Order[] memory result) {
        result = new Order[](_totalOrder);

        uint256 index = 0;
        uint256 orderId = _next[0];

        while (orderId > 0) {
            result[index++] = _orders[orderId];
            orderId = _next[orderId];
        }
    }
    
    function getOrdersByPage(uint256 page, uint256 size) external view returns (Order[] memory result) {
        
        if (_nextOrderId>1) {
            uint256 from = page == 0 ? 1 : (page - 1) * size+1;
            uint256 to = SafeMath.min((page == 0 ? 1 : page) * size, _nextOrderId-1)+1;
            Order[] memory asks = new Order[]((to - from));
            for (uint256 i = 0; from < to; ++i) {
                asks[i] = _orders[from];
                ++from;
            }
            return asks;
        } else {
            return new Order[](0);
        }
        
      
    }
    
    function getNextId() external view returns (uint256){
        return _nextOrderId;
    }
    
    function getOrdersByExtoken(address token) external view returns (Order[] memory result) {
        uint[] memory ids = _extokenOrderIds[token];
        result = new Order[](ids.length);

        for (uint i = 0; i < ids.length; i++){
            result[i] = _orders[ids[i]];
        }

    }
    function getOrder(uint256 id) external view returns (Order memory) {
        return _orders[id];
    }
    function getUserBids(address userAddr) public view returns (UserBidHistory[] memory) {
        return _userBidQueue[userAddr];
    }

    function getUserClosedBids(address userAddr) external view returns (UserBidHistory[] memory) {
        UserBidHistory[] memory ubh = getUserBids(userAddr);
        uint length = 0;
        for (uint i=0;i<ubh.length;i++){
            if(address(_orders[ubh[i].orderId].nft)!=address(0)) {
                continue;
            }
            length++;
        }
        
        UserBidHistory[] memory ubhClosed = new UserBidHistory[](length);
        uint j = 0;
         for (uint i=0;i<ubh.length;i++){
            if(address(_orders[ubh[i].orderId].nft)!=address(0)) {
                continue;
            }
            ubhClosed[j] = ubh[i];
            j++;
        }
        
        return ubhClosed;
    }


    function getUserNowBids(address userAddr) external view returns (UserBidHistory[] memory) {
        UserBidHistory[] memory ubh = getUserBids(userAddr);
        uint length = 0;
        for (uint i=0;i<ubh.length;i++){
            if(address(_orders[ubh[i].orderId].nft)!=address(0)) {
                length++;
            }
        }
        
        UserBidHistory[] memory ubhNow = new UserBidHistory[](length);
        uint j = 0;
         for (uint i=0;i<ubh.length;i++){
            if(address(_orders[ubh[i].orderId].nft)!=address(0)) {
                ubhNow[j] = ubh[i];
                j++;
            }
            
        }
        return ubhNow;
    }
    

    function getOrderBids(uint256 orderId) external view returns (BidEntity[]  memory) {
        return _bidQueue[orderId];
    }

    function _bid(address bidder,uint256 orderId, uint256 price,bool isTook) internal {
        BidEntity memory be = BidEntity(price,bidder,isTook);
        _bidQueue[orderId].push(be);
        UserBidHistory memory ubh = UserBidHistory(price,orderId,isTook);
        _userBidQueue[bidder].push(ubh);
        emit OrderBid(orderId,price);
    }

    function _match(Order memory order,uint256 orderId,uint256 price,address receiver,bool isSetPrice) internal {

        order.nft.safeTransferFrom(address(this), receiver, order.tokenId);
        uint256 exFee = SafeMath.div(SafeMath.mul(price,_feePer10000),10000);
        uint256 royaltyFee = SafeMath.div(SafeMath.mul(price,order.royalty),10000);
        uint256 restCost = SafeMath.sub(SafeMath.sub(price,exFee),royaltyFee) ;
        if(order.exchangeToken != address(0)){
            IERC20 extoken = IERC20(order.exchangeToken);
            // require(extoken.balanceOf(address(this)) > price, "NftExchange: insufficient balance");
            extoken.transfer(order.owner, restCost);
            extoken.transfer(_feeOwner, exFee);
            extoken.transfer(order.nft.getCreator(),royaltyFee);
//            BidEntity[] bes = _bidQueue[orderId];
//            for(uint i = 0; i < bes.length; i++) {
//                if(i < bes.length-1){
//                    order.exchangeToken.safeTransferFrom(address(this), bes[i].bidder, bes[i].price);
//                }
//            }
        }else{
//           require(address(this).balance > price, "NftExchange: insufficient balance");
           order.owner.transfer(restCost);
           _feeOwner.transfer(exFee);
           order.nft.getCreator().transfer(royaltyFee);
        }

        if(!isSetPrice){
            _bid(receiver,orderId,price,true);
        }

        emit OrderTrade(orderId);

        removeOrder(orderId);
    }


    function bid(uint256 id,uint256 price) external {
        Order memory order = _orders[id];
        require(address(order.nft) != address(0), "NftExchange: bad id");
        require(order.owner != msg.sender, "NftExchange: you're the owner of this order");

        uint256 buyerBalance = IERC20(order.exchangeToken).balanceOf(msg.sender);
        require(buyerBalance >= price, "NftExchange: insufficient balance");
        require(price <= order.price, "NftExchange: exceed origin price");
        BidEntity[] memory Bids = _bidQueue[id];

        if (Bids.length != 0){
            BidEntity memory latestBid = Bids[Bids.length-1];
            require(latestBid.price < price,"NftExchange: lower price than other bids");
        }

        IERC20(order.exchangeToken).safeTransferFrom(msg.sender, address(this), price);

        if(price < order.price){
            _bid(msg.sender,id, price, false);
        }else{
            _match(order,id,price,msg.sender,false);
        }

    }

    function bidBNB(uint256 id) payable external{
        Order memory order = _orders[id];
        require(address(order.nft) != address(0), "NftExchange: bad id");
        require(order.owner != msg.sender, "NftExchange: you're the owner of this order");

        uint256 price = msg.value;

        require(price <= order.price, "NftExchange: exceed origin price");
        BidEntity[] memory Bids = _bidQueue[id];

        if (Bids.length != 0){
            BidEntity memory latestBid = Bids[Bids.length-1];
            require(latestBid.price < price,"NftExchange: lower price than other bids");
        }

        if(price < order.price){
            _bid(msg.sender,id, price, false);
        }else{
            _match(order,id,price,msg.sender,false);
        }

    }

    function revoke(uint256 id) external{
        Order memory order = _orders[id];
        require(address(order.nft) != address(0), "BestNftExchange: bad id");
        require(order.owner == msg.sender, "BestNftExchange: not order owner");

        order.nft.safeTransferFrom(address(this), msg.sender, order.tokenId, order.amount, "");

        removeOrder(id);
    }

    function setPrice(uint256 id, uint256 price) external {
        Order storage order = _orders[id];
        require(address(order.nft) != address(0), "BestNftExchange: bad id");
        require(order.owner == msg.sender, "BestNftExchange: not order owner");

        BidEntity[] memory Bids = _bidQueue[id];

        if (Bids.length != 0){
            BidEntity memory latestBid = Bids[Bids.length-1];
            require(latestBid.price <= price,"NftExchange: lower price than bids price");
            order.price = price;
            if(latestBid.price == price){
                _match(order,id,price,latestBid.bidder,true);
            }
            emit PriceUpdated(id, price);
        }

    }

    // function onERC1155Received(address, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
    //     uint256 price;
    //     if (data.length == 0)
    //         price = 0;
    //     else
    //         price = abi.decode(data, (uint256));

    //     addOrder(IERC1155(msg.sender), id, value, from, price,address(0));

    //     return IERC1155Receiver.onERC1155Received.selector;
    // }
    // function onERC1155BatchReceived(address, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns (bytes4) {
    //     uint256[] memory prices = abi.decode(data, (uint256[]));
    //     require(prices.length == ids.length, "BestNftExchange: prices count mismatch");

    //     for (uint256 i = 0; i < ids.length; i++)
    //         addOrder(IERC1155(msg.sender), ids[i], values[i], from, prices[i],address(0));

    //     return IERC1155Receiver.onERC1155BatchReceived.selector;
    // }

    function addOrder(IERC1155Collection nft, uint256 id, uint256 amount, address payable owner, uint256 price,uint256 royalty,address exchangeToken) public onlyAdmins {
        
        nft.safeTransferFrom(nft.ownerOf(id), address(this), id);
        
        uint256 orderId = _nextOrderId;

        _orders[orderId] = Order(nft, id, amount, owner, price,exchangeToken,royalty);
        _next[_tail] = orderId;
        _previous[orderId] = _tail;
        _tail = orderId;

        _nextOrderId++;
        _totalOrder++;

        emit OrderAdded(orderId, msg.sender, id, amount, owner, price);
    }
    
    
    function batchAddOrder(IERC1155Collection [] memory nfts, uint256 [] memory ids, uint256 [] memory amounts, address payable [] memory owners, uint256 [] memory prices,uint256 [] memory royalties,address [] memory exchangeTokens) public onlyAdmins {
        
       for(uint256 i = 0; i<nfts.length; i++){
           addOrder(nfts[i], ids[i], amounts[i], owners[i], prices[i],royalties[i],exchangeTokens[i]);
       }
       
    }
    
    
    function removeOrder(uint256 id) private {
        
        delete _orders[id];

        uint256 next = _next[id];
        uint256 previous = _previous[id];

        if (_tail == id)
            _tail = previous;

        _next[previous] = next;
        _previous[next] = previous;

        delete _next[id];
        delete _previous[id];

        _totalOrder--;


        emit OrderRemoved(id);
    }

    function withdrawAll(address take) external onlyAdmins {
        if(take!=address(0)){
            withdrawAmount(take, IERC20(take).balanceOf(address(this)));
        }else{
            withdrawAmount(take, address(this).balance);
        }
    }
    function withdrawAmount(address take,uint256 _amount) public onlyAdmins {
        if(take!=address(0)){
            IERC20 token = IERC20(take);
            token.transfer(msg.sender, _amount);
        }else{
            msg.sender.transfer(_amount);
        }
    }
}