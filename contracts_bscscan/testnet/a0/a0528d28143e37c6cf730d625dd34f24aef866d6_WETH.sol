/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/IBookkeeper.sol



interface IBookkeeper {
    // date = days since unix epoch
    function getVolume(address user, uint256 date) external view returns (uint256);

    function recordVolume(address user, uint256 amount) external;
}


// File contracts/IFeeController.sol



interface IFeeController {
    function rateBase() external view returns (uint256);

    function feeRate(address user) external view returns (uint256);

    function getLevel(address user) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File contracts/IWETH.sol



interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}


// File @openzeppelin/contracts/utils/[email protected]



/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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


// File @openzeppelin/contracts/security/[email protected]



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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


// File @openzeppelin/contracts/security/[email protected]



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

    constructor () {
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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]




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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// File contracts/Auction.sol












contract Auction is ReentrancyGuard, Ownable, Pausable, IERC721Receiver {
    using SafeERC20 for IERC20;

    uint8 public constant ST_OPEN = 0;
    uint8 public constant ST_FINISHED = 1;
    uint8 public constant ST_CANCELLED = 2;

    struct TokenPair {
        IERC721 nft;
        uint256 tokenId;
    }

    struct Inventory {
        uint256 nftCount;
        address seller;
        address bidder;
        IERC20 currency;
        uint256 askPrice;
        uint256 bidPrice;
        uint256 netBidPrice;
        uint256 startBlock;
        uint256 endTimestamp;
        uint8 status;
    }

    event EvNFTBlacklistUpdate(IERC721 nft, bool blacklisted);
    event EvCurrency(IERC20 indexed token, bool approved);
    event EvNewAuction(
        uint256 indexed id,
        address indexed seller,
        IERC20 currency,
        uint256 askPrice,
        uint256 endTimestamp,
        TokenPair[] bundle
    );
    event EvNewBid(uint256 indexed id, address indexed bidder, uint256 price, uint256 endTimestamp);
    event EvAuctionCancelled(uint256 indexed id);
    event EvAuctionFinished(uint256 indexed id, address indexed winner);

    bool internal _canReceive = false;
    IWETH public immutable weth;
    Inventory[] public auctions;
    mapping(uint256 => mapping(uint256 => TokenPair)) auctionNfts;

    mapping(IERC721 => bool) public nftBlacklist;
    mapping(IERC20 => bool) public currencyBlacklist;

    IBookkeeper public bookkeeper;
    IFeeController public feeController;
    address public feeWallet;

    uint256 public extendEndTimestamp; // in seconds
    uint256 public minAuctionDuration; // in seconds

    uint256 public rateBase;
    uint256 public bidderIncentiveRate;
    uint256 public bidIncrRate;

    constructor(
        IWETH weth_,
        IBookkeeper bookkeeper_,
        IFeeController feeController_,
        address feeWallet_,
        uint256 extendEndTimestamp_,
        uint256 minAuctionDuration_,
        uint256 rateBase_,
        uint256 bidderIncentiveRate_,
        uint256 bidIncrRate_
    ) {
        weth = weth_;
        bookkeeper = bookkeeper_;
        feeWallet = feeWallet_;
        feeController = feeController_;
        extendEndTimestamp = extendEndTimestamp_;
        minAuctionDuration = minAuctionDuration_;
        rateBase = rateBase_;
        bidderIncentiveRate = bidderIncentiveRate_;
        bidIncrRate = bidIncrRate_;

        auctions.push(
            Inventory({
                nftCount: 0,
                seller: address(0),
                bidder: address(0),
                currency: IERC20(address(0)),
                askPrice: 0,
                bidPrice: 0,
                netBidPrice: 0,
                startBlock: 0,
                endTimestamp: 0,
                status: 0
            })
        );
    }

    function updateSettings(
        IBookkeeper bookkeeper_,
        IFeeController feeController_,
        uint256 extendEndTimestamp_,
        uint256 minAuctionDuration_,
        uint256 rateBase_,
        uint256 bidderIncentiveRate_,
        uint256 bidIncrRate_
    ) public onlyOwner {
        bookkeeper = bookkeeper_;
        feeController = feeController_;
        extendEndTimestamp = extendEndTimestamp_;
        minAuctionDuration = minAuctionDuration_;
        rateBase = rateBase_;
        bidderIncentiveRate = bidderIncentiveRate_;
        bidIncrRate = bidIncrRate_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function unbanCurrency(IERC20 cur) public onlyOwner {
        delete currencyBlacklist[cur];
        emit EvCurrency(cur, true);
    }

    function banCurrency(IERC20 cur) public onlyOwner {
        currencyBlacklist[cur] = true;
        emit EvCurrency(cur, false);
    }

    function blacklistNFT(IERC721 nft) public onlyOwner {
        nftBlacklist[nft] = true;
        emit EvNFTBlacklistUpdate(nft, true);
    }

    function unblacklistNFT(IERC721 nft) public onlyOwner {
        delete nftBlacklist[nft];
        emit EvNFTBlacklistUpdate(nft, false);
    }

    // public

    receive() external payable {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override whenNotPaused returns (bytes4) {
        if (data.length > 0) {
            require(operator == from, 'caller should own the token');
            require(!nftBlacklist[IERC721(msg.sender)], 'token not allowed');
            (IERC20 currency, uint256 askPrice, uint256 endTimestamp) = abi.decode(
                data,
                (IERC20, uint256, uint256)
            );
            TokenPair[] memory bundle = new TokenPair[](1);
            bundle[0].nft = IERC721(msg.sender);
            bundle[0].tokenId = tokenId;
            _sell(from, bundle, currency, askPrice, endTimestamp);
        } else {
            require(_canReceive, 'cannot transfer directly');
        }

        return this.onERC721Received.selector;
    }

    function sell(
        TokenPair[] calldata bundle,
        IERC20 currency,
        uint256 askPrice,
        uint256 endTimestamp
    ) public nonReentrant whenNotPaused _waitForTransfer {
        require(bundle.length > 0, 'empty tokens');

        for (uint256 i = 0; i < bundle.length; i++) {
            TokenPair calldata p = bundle[i];
            require(!nftBlacklist[p.nft], 'token not allowed');
            require(_isTokenOwnerAndApproved(p.nft, p.tokenId), 'token not approved');
            p.nft.safeTransferFrom(msg.sender, address(this), p.tokenId);
        }

        _sell(msg.sender, bundle, currency, askPrice, endTimestamp);
    }

    function _sell(
        address seller,
        TokenPair[] memory bundle,
        IERC20 currency,
        uint256 askPrice,
        uint256 endTimestamp
    ) internal _allowedCurrency(currency) {
        require(askPrice > 0, 'askPrice > 0');
        require(
            endTimestamp >= block.timestamp + minAuctionDuration,
            'auction duration not long enough'
        );

        uint256 id = auctions.length;
        for (uint256 i = 0; i < bundle.length; i++) {
            auctionNfts[id][i] = bundle[i];
        }

        auctions.push(
            Inventory({
                nftCount: bundle.length,
                seller: seller,
                bidder: address(0),
                currency: currency,
                askPrice: askPrice,
                bidPrice: 0,
                netBidPrice: 0,
                startBlock: block.number,
                endTimestamp: endTimestamp,
                status: ST_OPEN
            })
        );

        emit EvNewAuction(id, seller, currency, askPrice, endTimestamp, bundle);
    }

    function bid(uint256 id, uint256 offer)
        public
        payable
        _hasAuction(id)
        _isStOpen(id)
        nonReentrant
        whenNotPaused
    {
        Inventory storage inv = auctions[id];
        require(block.timestamp < inv.endTimestamp, 'auction finished');

        // set offer to native value
        if (inv.currency == weth) {
            offer = msg.value;
        }

        // minimum increment
        require(offer >= getMinBidPrice(id), 'not enough');

        // collect token
        if (inv.currency == weth) {
            weth.deposit{value: offer}(); // convert to weth for later use
        } else {
            inv.currency.safeTransferFrom(msg.sender, address(this), offer);
        }

        // transfer some to previous bidder
        uint256 incentive = 0;
        if (inv.netBidPrice > 0 && inv.bidder != address(0)) {
            incentive = (offer * bidderIncentiveRate) / rateBase;
            _transfer(inv.currency, inv.bidder, inv.netBidPrice + incentive);
        }

        inv.bidPrice = offer;
        inv.netBidPrice = offer - incentive;
        inv.bidder = msg.sender;
        if (block.timestamp + extendEndTimestamp >= inv.endTimestamp) {
            inv.endTimestamp += extendEndTimestamp;
        }

        emit EvNewBid(id, msg.sender, offer, inv.endTimestamp);
    }

    function cancel(uint256 id)
        public
        _hasAuction(id)
        _isStOpen(id)
        _isSeller(id)
        nonReentrant
        whenNotPaused
    {
        Inventory storage inv = auctions[id];
        require(inv.bidder == address(0), 'has bidder');
        _cancel(id);
    }

    function _cancel(uint256 id) internal {
        Inventory storage inv = auctions[id];

        inv.status = ST_CANCELLED;
        _transferInventoryTo(id, inv.seller);
        emit EvAuctionCancelled(id);
    }

    // anyone can collect any auction, as long as it's finished
    function collect(uint256[] calldata ids) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < ids.length; i++) {
            _collect0(ids[i]);
        }
    }

    function _collect0(uint256 id) internal _hasAuction(id) _isStOpen(id) {
        Inventory storage inv = auctions[id];
        require(block.timestamp >= inv.endTimestamp, 'auction not done yet');
        if (inv.bidder == address(0)) {
            _cancel(id);
        } else {
            _collect(id);
        }
    }

    function _collect(uint256 id) internal {
        Inventory storage inv = auctions[id];

        // take fee
        uint256 fee = (inv.netBidPrice * feeController.feeRate(inv.seller)) /
            feeController.rateBase();
        if (fee > 0) {
            _transfer(inv.currency, feeWallet, fee);
        }

        // transfer profit and token
        _transfer(inv.currency, inv.seller, inv.netBidPrice - fee);
        inv.status = ST_FINISHED;
        _transferInventoryTo(id, inv.bidder);

        if (inv.currency == weth) {
            bookkeeper.recordVolume(inv.seller, inv.bidPrice);
            bookkeeper.recordVolume(inv.bidder, inv.bidPrice);
        }

        emit EvAuctionFinished(id, inv.bidder);
    }

    function isOpen(uint256 id) public view _hasAuction(id) returns (bool) {
        Inventory storage inv = auctions[id];
        return inv.status == ST_OPEN && block.timestamp < inv.endTimestamp;
    }

    function isCollectible(uint256 id) public view _hasAuction(id) returns (bool) {
        Inventory storage inv = auctions[id];
        return inv.status == ST_OPEN && block.timestamp >= inv.endTimestamp;
    }

    function isCancellable(uint256 id) public view _hasAuction(id) returns (bool) {
        Inventory storage inv = auctions[id];
        return inv.status == ST_OPEN && inv.bidder == address(0);
    }

    function numAuctions() public view returns (uint256) {
        return auctions.length;
    }

    function getMinBidPrice(uint256 id) public view returns (uint256) {
        Inventory storage inv = auctions[id];

        // minimum increment
        if (inv.bidPrice == 0) {
            return inv.askPrice;
        } else {
            return inv.bidPrice + (inv.bidPrice * bidIncrRate) / rateBase;
        }
    }

    // internal

    modifier _isStOpen(uint256 id) {
        require(auctions[id].status == ST_OPEN, 'auction finished or cancelled');
        _;
    }

    modifier _hasAuction(uint256 id) {
        require(id > 0 && id < auctions.length, 'auction does not exist');
        _;
    }

    modifier _isSeller(uint256 id) {
        require(auctions[id].seller == msg.sender, 'caller is not seller');
        _;
    }

    modifier _allowedCurrency(IERC20 token) {
        require(!currencyBlacklist[token], 'currency not allowed');
        _;
    }

    modifier _waitForTransfer() {
        _canReceive = true;
        _;
        _canReceive = false;
    }

    function _transfer(
        IERC20 currency,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (currency == weth) {
                weth.withdraw(amount);
                payable(to).transfer(amount);
            } else {
                currency.safeTransfer(to, amount);
            }
        }
    }

    function _isTokenOwnerAndApproved(IERC721 token, uint256 tokenId) internal returns (bool) {
        return
            (token.ownerOf(tokenId) == msg.sender) &&
            (token.getApproved(tokenId) == address(this) ||
                token.isApprovedForAll(msg.sender, address(this)));
    }

    function _transferInventoryTo(uint256 id, address to) internal {
        Inventory storage inv = auctions[id];
        for (uint256 i = 0; i < inv.nftCount; i++) {
            TokenPair storage p = auctionNfts[id][i];
            p.nft.safeTransferFrom(address(this), to, p.tokenId);
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


// File @openzeppelin/contracts/utils/introspection/[email protected]



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/access/AccessCo[email protected]





/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File contracts/Bookkeeper.sol




contract Bookkeeper is AccessControl, IBookkeeper {
    bytes32 public constant RECORDER_ROLE = keccak256('RECORDER_ROLE');
    uint256 public constant DAY_IN_SECONDS = 24 * 60 * 60;

    mapping(address => mapping(uint256 => uint256)) userVolumes; // user => date => volume sum

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyRecorder() {
        require(hasRole(RECORDER_ROLE, msg.sender), 'RECORDER only');
        _;
    }

    function getDate() public view returns (uint256) {
        return block.timestamp / DAY_IN_SECONDS;
    }

    function getVolume(address user, uint256 date) external view override returns (uint256) {
        return userVolumes[user][date];
    }

    function recordVolume(address user, uint256 amount) external override onlyRecorder {
        uint256 date = getDate();
        userVolumes[user][date] += amount;
    }
}


// File contracts/IFarm.sol



interface IFarm {
    function stakedWantTokens(uint256 pid, address user) external view returns (uint256);
}


// File contracts/FeeController.sol






contract FeeController is AccessControl, IFeeController {
    struct Tier {
        uint256 minVolume;
        uint256 minStaked;
        uint256 rate;
    }

    uint256 public constant override rateBase = 1e6;
    uint256 public constant DAY_IN_SECONDS = 24 * 3600;
    uint256 public constant defaultFeeRate = (rateBase * 5) / 100;

    IBookkeeper public bookkeeper;
    IFarm public farm;
    uint256 public farmPID;
    uint256 public volumeWindowSize = 30;

    Tier[] public tiers;

    constructor(
        IBookkeeper bookkeeper_,
        IFarm farm_,
        uint256 farmPID_
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        updateAddresses(bookkeeper_, farm_, farmPID_);
        // default rate = 5%
        tiers.push(Tier({minVolume: 0, minStaked: 0, rate: defaultFeeRate}));
    }

    modifier _onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'ADMIN only');
        _;
    }

    function updateAddresses(
        IBookkeeper bookkeeper_,
        IFarm farm_,
        uint256 farmPID_
    ) public _onlyAdmin {
        bookkeeper = bookkeeper_;
        farm = farm_;
        farmPID = farmPID_;
    }

    function updateSettings(uint256 windowSize_, Tier[] calldata tiers_) public _onlyAdmin {
        volumeWindowSize = windowSize_;

        // sync length
        while (tiers.length > 0) {
            tiers.pop();
        }

        // copy data
        for (uint256 i = 0; i < tiers_.length; i++) {
            tiers.push(tiers_[i]);
        }
    }

    function getLevel(address user) public view override returns (uint256) {
        uint256 staked = getUserStaking(user);
        uint256 vol = getUserVolume(user);
        for (uint256 i = tiers.length; i > 0; i--) {
            Tier storage t = tiers[i - 1];
            if (staked >= t.minStaked && vol >= t.minVolume) {
                return i - 1;
            }
        }
        return 0;
    }

    function getUserStaking(address user) public view returns (uint256) {
        return farm.stakedWantTokens(farmPID, user);
    }

    function getUserVolume(address user) public view returns (uint256) {
        uint256 sum = 0;
        uint256 startDate = block.timestamp / DAY_IN_SECONDS;
        uint256 endDate = (volumeWindowSize > startDate) ? 0 : startDate - volumeWindowSize;
        for (uint256 i = startDate; i >= endDate; i--) {
            sum += bookkeeper.getVolume(user, i);
        }
        return sum;
    }

    function feeRate(address user) external view override returns (uint256) {
        uint256 level = getLevel(user);
        if (level < tiers.length) {
            return tiers[level].rate;
        } else {
            return defaultFeeRate;
        }
    }
}


// File contracts/Market.sol









contract Market is ReentrancyGuard, Ownable, Pausable {
    uint8 public constant SIDE_SELL = 1;
    uint8 public constant SIDE_BUY = 2;

    uint8 public constant STATUS_OPEN = 0;
    uint8 public constant STATUS_ACCEPTED = 1;
    uint8 public constant STATUS_CANCELLED = 2;

    struct Offer {
        uint256 tokenId;
        uint256 price;
        IERC721 nft;
        address user;
        address acceptUser;
        uint8 status;
        uint8 side;
    }

    // events

    event EvNewOffer(
        address indexed user,
        IERC721 indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        uint8 side,
        uint256 id
    );

    event EvCancelOffer(uint256 indexed id);
    event EvAcceptOffer(uint256 indexed id, address indexed user, uint256 price);

    event EvSettingsUpdated(address feeAddress, address feeController, address bookkeeper);
    event EvNFTBlacklistUpdate(IERC721 nft, bool blacklisted);

    // variables

    address public feeAddress;
    IFeeController public feeController;
    IBookkeeper public bookkeeper;

    Offer[] public offers;
    mapping(IERC721 => mapping(uint256 => uint256)) public tokenSellOffers; // nft => tokenId => id
    mapping(address => mapping(IERC721 => mapping(uint256 => uint256))) public userBuyOffers; // user => nft => tokenId => id
    mapping(IERC721 => bool) public nftBlacklist;

    // settings
    constructor(
        address feeAddress_,
        address feeController_,
        address bookkeeper_
    ) {
        feeAddress = feeAddress_;
        feeController = IFeeController(feeController_);
        bookkeeper = IBookkeeper(bookkeeper_);

        // take id(0) as placeholder
        offers.push(
            Offer({
                tokenId: 0,
                price: 0,
                nft: IERC721(address(0)),
                user: address(0),
                acceptUser: address(0),
                status: STATUS_CANCELLED,
                side: 0
            })
        );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateSettings(
        address feeAddress_,
        address feeController_,
        address bookkeeper_
    ) public onlyOwner {
        feeAddress = feeAddress_;
        feeController = IFeeController(feeController_);
        bookkeeper = IBookkeeper(bookkeeper_);

        emit EvSettingsUpdated(feeAddress, feeController_, bookkeeper_);
    }

    function blacklistNFT(IERC721[] calldata nfts) public onlyOwner {
        for (uint256 i = 0; i < nfts.length; i++) {
            nftBlacklist[nfts[i]] = true;
            emit EvNFTBlacklistUpdate(nfts[i], true);
        }
    }

    function unblacklistNFT(IERC721[] calldata nfts) public onlyOwner {
        for (uint256 i = 0; i < nfts.length; i++) {
            delete nftBlacklist[nfts[i]];
            emit EvNFTBlacklistUpdate(nfts[i], false);
        }
    }

    // user functions

    function offer(
        uint8 side,
        IERC721 nft,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant whenNotPaused _nftAllowed(nft) {
        if (side == SIDE_BUY) {
            _offerBuy(nft, tokenId);
        } else if (side == SIDE_SELL) {
            _offerSell(nft, tokenId, price);
        } else {
            revert('impossible');
        }
    }

    function accept(uint256 id)
        public
        payable
        nonReentrant
        _offerExists(id)
        _offerOpen(id)
        _notBlacklisted(id)
        whenNotPaused
    {
        Offer storage _offer = offers[id];
        if (_offer.side == SIDE_BUY) {
            _acceptBuy(id);
        } else {
            _acceptSell(id);
        }
    }

    function cancel(uint256 id)
        public
        nonReentrant
        _offerExists(id)
        _offerOpen(id)
        _offerOwner(id)
        whenNotPaused
    {
        Offer storage _offer = offers[id];
        if (_offer.side == SIDE_BUY) {
            _cancelBuy(id);
        } else {
            _cancelSell(id);
        }
    }

    function multiCancel(uint256[] calldata ids) public {
        for (uint256 i = 0; i < ids.length; i++) {
            cancel(ids[i]);
        }
    }

    function _offerSell(
        IERC721 nft,
        uint256 tokenId,
        uint256 price
    ) internal {
        require(msg.value == 0, 'thank you but seller should not pay');
        require(price > 0, 'price > 0');
        offers.push(
            Offer({
                tokenId: tokenId,
                price: price,
                nft: nft,
                user: msg.sender,
                acceptUser: address(0),
                status: STATUS_OPEN,
                side: SIDE_SELL
            })
        );

        uint256 id = offers.length - 1;
        emit EvNewOffer(msg.sender, nft, tokenId, price, SIDE_SELL, id);

        require(getTokenOwner(id) == msg.sender, 'sender should own the token');
        require(isTokenApproved(id, msg.sender), 'token is not approved');
        _closeSellOfferFor(nft, tokenId);
        tokenSellOffers[nft][tokenId] = id;
    }

    function _offerBuy(IERC721 nft, uint256 tokenId) internal {
        uint256 price = msg.value;
        require(price > 0, 'buyer should pay');
        offers.push(
            Offer({
                tokenId: tokenId,
                price: price,
                nft: nft,
                user: msg.sender,
                acceptUser: address(0),
                status: STATUS_OPEN,
                side: SIDE_BUY
            })
        );
        uint256 id = offers.length - 1;
        emit EvNewOffer(msg.sender, nft, tokenId, price, SIDE_BUY, id);
        _closeUserBuyOffer(userBuyOffers[msg.sender][nft][tokenId]);
        userBuyOffers[msg.sender][nft][tokenId] = id;
    }

    function _acceptBuy(uint256 id) internal {
        // caller is seller
        Offer storage _offer = offers[id];
        require(msg.value == 0, 'thank you but seller should not pay');

        require(getTokenOwner(id) == msg.sender, 'only owner can call');
        require(isTokenApproved(id, msg.sender), 'token is not approved');

        _offer.nft.safeTransferFrom(msg.sender, _offer.user, _offer.tokenId);
        _distributePayment(_offer.price, msg.sender);

        _offer.status = STATUS_ACCEPTED;
        _offer.acceptUser = msg.sender;
        emit EvAcceptOffer(id, msg.sender, _offer.price);
        _unlinkBuyOffer(_offer);
        _closeSellOfferFor(_offer.nft, _offer.tokenId);

        bookkeeper.recordVolume(_offer.user, _offer.price);
        bookkeeper.recordVolume(msg.sender, _offer.price);
    }

    function _acceptSell(uint256 id) internal {
        // caller is buyer
        Offer storage _offer = offers[id];
        require(getTokenOwner(id) == _offer.user, 'token not owned by the seller anymore');
        require(isTokenApproved(id, _offer.user), 'token is not approved');
        require(msg.value >= _offer.price, 'send more money');

        _offer.nft.safeTransferFrom(_offer.user, msg.sender, _offer.tokenId);
        _distributePayment(msg.value, _offer.user);

        _offer.status = STATUS_ACCEPTED;
        _offer.acceptUser = msg.sender;
        _offer.price = msg.value;
        emit EvAcceptOffer(id, msg.sender, msg.value);
        _unlinkSellOffer(_offer);

        bookkeeper.recordVolume(_offer.user, msg.value);
        bookkeeper.recordVolume(msg.sender, msg.value);
    }

    function _cancelSell(uint256 id) internal {
        Offer storage _offer = offers[id];
        _offer.status = STATUS_CANCELLED;
        emit EvCancelOffer(id);
        _unlinkSellOffer(_offer);
    }

    function _cancelBuy(uint256 id) internal {
        Offer storage _offer = offers[id];
        _offer.status = STATUS_CANCELLED;
        _transfer(msg.sender, _offer.price);
        emit EvCancelOffer(id);
        _unlinkBuyOffer(_offer);
    }

    // modifiers

    modifier _offerExists(uint256 id) {
        require(id > 0 && id < offers.length, 'offer does not exist');
        _;
    }

    modifier _offerOpen(uint256 id) {
        require(offers[id].status == STATUS_OPEN, 'offer should be open');
        _;
    }

    modifier _offerOwner(uint256 id) {
        require(offers[id].user == msg.sender, 'call should own the offer');
        _;
    }

    modifier _notBlacklisted(uint256 id) {
        Offer storage _offer = offers[id];
        require(!nftBlacklist[_offer.nft], 'NFT in blacklist');
        _;
    }

    modifier _nftAllowed(IERC721 nft) {
        require(!nftBlacklist[nft], 'NFT in blacklist');
        _;
    }

    // internal helpers

    function _sendValue(address to, uint256 amount) internal {
        if (amount > 0) {
            Address.sendValue(payable(to), amount);
        }
    }

    function _transfer(address to, uint256 amount) internal {
        if (amount > 0) {
            payable(to).transfer(amount);
        }
    }

    function _distributePayment(uint256 totalAmount, address seller) internal {
        uint256 feeRate = feeController.feeRate(seller);
        uint256 fee = (totalAmount * feeRate) / feeController.rateBase();
        _sendValue(feeAddress, fee);
        _transfer(seller, totalAmount - fee);
    }

    function _closeSellOfferFor(IERC721 nft, uint256 tokenId) internal {
        uint256 id = tokenSellOffers[nft][tokenId];
        if (id == 0) return;

        // closes old open sell offer
        Offer storage _offer = offers[id];
        _offer.status = STATUS_CANCELLED;
        tokenSellOffers[_offer.nft][_offer.tokenId] = 0;
        emit EvCancelOffer(id);
    }

    function _closeUserBuyOffer(uint256 id) internal {
        Offer storage o = offers[id];
        if (id > 0 && o.status == STATUS_OPEN && o.side == SIDE_BUY) {
            o.status = STATUS_CANCELLED;
            _transfer(o.user, o.price);
            _unlinkBuyOffer(o);
            emit EvCancelOffer(id);
        }
    }

    function _unlinkBuyOffer(Offer storage o) internal {
        userBuyOffers[o.user][o.nft][o.tokenId] = 0;
    }

    function _unlinkSellOffer(Offer storage o) internal {
        tokenSellOffers[o.nft][o.tokenId] = 0;
    }

    // helpers

    function isValidSell(uint256 id) public view returns (bool) {
        if (id >= offers.length) {
            return false;
        }

        Offer storage _offer = offers[id];
        // try to not throw exception
        return
            _offer.status == STATUS_OPEN &&
            _offer.side == SIDE_SELL &&
            isTokenApproved(id, _offer.user) &&
            (_offer.nft.ownerOf(_offer.tokenId) == _offer.user);
    }

    function isTokenApproved(uint256 id, address owner) public view returns (bool) {
        Offer storage _offer = offers[id];
        return
            _offer.nft.getApproved(_offer.tokenId) == address(this) ||
            _offer.nft.isApprovedForAll(owner, address(this));
    }

    function getTokenOwner(uint256 id) public view returns (address) {
        Offer storage _offer = offers[id];
        return _offer.nft.ownerOf(_offer.tokenId);
    }
}


// File contracts/Market2.sol












contract Market2 is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    uint8 public constant SIDE_SELL = 1;
    uint8 public constant SIDE_BUY = 2;

    uint8 public constant STATUS_OPEN = 0;
    uint8 public constant STATUS_ACCEPTED = 1;
    uint8 public constant STATUS_CANCELLED = 2;

    struct Offer {
        uint256 tokenId;
        uint256 price;
        IERC20 currency;
        IERC721 nft;
        address user;
        address acceptUser;
        uint8 status;
        uint8 side;
    }

    // events

    event EvNewOffer(
        address indexed user,
        IERC721 indexed nft,
        uint256 indexed tokenId,
        IERC20 currency,
        uint256 price,
        uint8 side,
        uint256 id
    );

    event EvCancelOffer(uint256 indexed id);
    event EvAcceptOffer(uint256 indexed id, address indexed user, IERC20 currency, uint256 price);

    event EvSettingsUpdated(address feeController, address bookkeeper, address feewallet);
    event EvNFTBlacklistUpdate(IERC721 nft, bool blacklisted);
    event EvCurrency(IERC20 indexed token, bool allow);

    // variables

    IFeeController public feeController;
    IBookkeeper public bookkeeper;
    IWETH public weth;
    address public feeWallet;

    Offer[] public offers;
    mapping(IERC721 => mapping(uint256 => uint256)) public tokenSellOffers; // nft => tokenId => id
    mapping(address => mapping(IERC721 => mapping(uint256 => uint256))) public userBuyOffers; // user => nft => tokenId => id
    mapping(IERC721 => bool) public nftBlacklist;
    mapping(IERC20 => bool) public currencyBlacklist;

    receive() external payable {}

    // settings
    constructor(
        IFeeController feeController_,
        IBookkeeper bookkeeper_,
        IWETH weth_,
        address feeWallet_
    ) {
        feeController = feeController_;
        bookkeeper = bookkeeper_;
        weth = weth_;
        feeWallet = feeWallet_;

        // take id(0) as placeholder
        offers.push(
            Offer({
                tokenId: 0,
                price: 0,
                currency: IERC20(address(0)),
                nft: IERC721(address(0)),
                user: address(0),
                acceptUser: address(0),
                status: STATUS_CANCELLED,
                side: 0
            })
        );
    }

    function unbanCurrency(IERC20 cur) public onlyOwner {
        delete currencyBlacklist[cur];
        emit EvCurrency(cur, true);
    }

    function banCurrency(IERC20 cur) public onlyOwner {
        currencyBlacklist[cur] = true;
        emit EvCurrency(cur, false);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateSettings(
        IFeeController feeController_,
        IBookkeeper bookkeeper_,
        address feeWallet_
    ) public onlyOwner {
        feeController = feeController_;
        bookkeeper = bookkeeper_;
        feeWallet = feeWallet_;

        emit EvSettingsUpdated(address(feeController_), address(bookkeeper_), feeWallet_);
    }

    function blacklistNFT(IERC721 nft) public onlyOwner {
        nftBlacklist[nft] = true;
        emit EvNFTBlacklistUpdate(nft, true);
    }

    function unblacklistNFT(IERC721 nft) public onlyOwner {
        delete nftBlacklist[nft];
        emit EvNFTBlacklistUpdate(nft, false);
    }

    // user functions

    function offer(
        uint8 side,
        IERC721 nft,
        uint256 tokenId,
        IERC20 currency,
        uint256 price
    ) public payable nonReentrant whenNotPaused _nftAllowed(nft) _allowedCurrency(currency) {
        if (side == SIDE_BUY) {
            _offerBuy(nft, tokenId, currency, price);
        } else if (side == SIDE_SELL) {
            _offerSell(nft, tokenId, currency, price);
        } else {
            revert('impossible');
        }
    }

    function accept(uint256 id)
        public
        payable
        nonReentrant
        _offerExists(id)
        _offerOpen(id)
        _notBlacklisted(id)
        whenNotPaused
    {
        Offer storage _offer = offers[id];
        if (_offer.side == SIDE_BUY) {
            _acceptBuy(id);
        } else if (_offer.side == SIDE_SELL) {
            _acceptSell(id);
        } else {
            revert('impossible');
        }
    }

    function cancel(uint256 id)
        public
        nonReentrant
        _offerExists(id)
        _offerOpen(id)
        _offerOwner(id)
        whenNotPaused
    {
        Offer storage _offer = offers[id];
        if (_offer.side == SIDE_BUY) {
            _cancelBuy(id);
        } else if (_offer.side == SIDE_SELL) {
            _cancelSell(id);
        } else {
            revert('impossible');
        }
    }

    function multiCancel(uint256[] calldata ids) public {
        for (uint256 i = 0; i < ids.length; i++) {
            cancel(ids[i]);
        }
    }

    function _offerSell(
        IERC721 nft,
        uint256 tokenId,
        IERC20 currency,
        uint256 price
    ) internal {
        require(msg.value == 0, 'thank you but seller should not pay');
        require(price > 0, 'price > 0');
        offers.push(
            Offer({
                tokenId: tokenId,
                price: price,
                currency: currency,
                nft: nft,
                user: msg.sender,
                acceptUser: address(0),
                status: STATUS_OPEN,
                side: SIDE_SELL
            })
        );

        uint256 id = offers.length - 1;
        emit EvNewOffer(msg.sender, nft, tokenId, currency, price, SIDE_SELL, id);

        require(getTokenOwner(id) == msg.sender, 'sender should own the token');
        require(isTokenApproved(id, msg.sender), 'token is not approved');
        _closeSellOfferFor(nft, tokenId);
        tokenSellOffers[nft][tokenId] = id;
    }

    function _offerBuy(
        IERC721 nft,
        uint256 tokenId,
        IERC20 currency,
        uint256 price
    ) internal {
        if (currency == weth) {
            weth.deposit{value: msg.value}();
            price = msg.value;
        } else {
            currency.safeTransferFrom(msg.sender, address(this), price);
        }
        require(price > 0, 'buyer should pay');

        offers.push(
            Offer({
                tokenId: tokenId,
                price: price,
                currency: currency,
                nft: nft,
                user: msg.sender,
                acceptUser: address(0),
                status: STATUS_OPEN,
                side: SIDE_BUY
            })
        );

        uint256 id = offers.length - 1;
        emit EvNewOffer(msg.sender, nft, tokenId, currency, price, SIDE_BUY, id);

        _closeUserBuyOffer(userBuyOffers[msg.sender][nft][tokenId]);
        userBuyOffers[msg.sender][nft][tokenId] = id;
    }

    function _acceptBuy(uint256 id) internal {
        // caller is seller
        Offer storage _offer = offers[id];
        require(msg.value == 0, 'thank you but seller should not pay');

        require(getTokenOwner(id) == msg.sender, 'only owner can call');
        require(isTokenApproved(id, msg.sender), 'token is not approved');

        _offer.nft.safeTransferFrom(msg.sender, _offer.user, _offer.tokenId);
        _distributePayment(_offer.currency, _offer.price, msg.sender, _offer.user, _offer.nft);

        _offer.status = STATUS_ACCEPTED;
        _offer.acceptUser = msg.sender;
        emit EvAcceptOffer(id, msg.sender, _offer.currency, _offer.price);
        _unlinkBuyOffer(_offer);
        _closeSellOfferFor(_offer.nft, _offer.tokenId);

        if (_offer.currency == weth) {
            bookkeeper.recordVolume(_offer.user, _offer.price);
            bookkeeper.recordVolume(msg.sender, _offer.price);
        }
    }

    function _acceptSell(uint256 id) internal {
        // caller is buyer
        Offer storage _offer = offers[id];
        require(getTokenOwner(id) == _offer.user, 'token not owned by the seller anymore');
        require(isTokenApproved(id, _offer.user), 'token is not approved');

        if (_offer.currency == weth) {
            require(msg.value >= _offer.price, 'send more money');
            weth.deposit{value: msg.value}();
            _offer.price = msg.value;
        } else {
            _offer.currency.transferFrom(msg.sender, address(this), _offer.price);
        }

        _offer.nft.safeTransferFrom(_offer.user, msg.sender, _offer.tokenId);
        _distributePayment(_offer.currency, _offer.price, _offer.user, msg.sender, _offer.nft);

        _offer.status = STATUS_ACCEPTED;
        _offer.acceptUser = msg.sender;
        emit EvAcceptOffer(id, msg.sender, _offer.currency, _offer.price);
        _unlinkSellOffer(_offer);

        if (_offer.currency == weth) {
            bookkeeper.recordVolume(_offer.user, _offer.price);
            bookkeeper.recordVolume(msg.sender, _offer.price);
        }
    }

    function _cancelSell(uint256 id) internal {
        Offer storage _offer = offers[id];
        _offer.status = STATUS_CANCELLED;
        emit EvCancelOffer(id);
        _unlinkSellOffer(_offer);
    }

    function _cancelBuy(uint256 id) internal {
        Offer storage _offer = offers[id];
        _offer.status = STATUS_CANCELLED;
        _transfer(msg.sender, _offer.currency, _offer.price);
        emit EvCancelOffer(id);
        _unlinkBuyOffer(_offer);
    }

    // modifiers

    modifier _offerExists(uint256 id) {
        require(id > 0 && id < offers.length, 'offer does not exist');
        _;
    }

    modifier _offerOpen(uint256 id) {
        require(offers[id].status == STATUS_OPEN, 'offer should be open');
        _;
    }

    modifier _offerOwner(uint256 id) {
        require(offers[id].user == msg.sender, 'call should own the offer');
        _;
    }

    modifier _notBlacklisted(uint256 id) {
        Offer storage _offer = offers[id];
        require(!nftBlacklist[_offer.nft], 'NFT in blacklist');
        _;
    }

    modifier _nftAllowed(IERC721 nft) {
        require(!nftBlacklist[nft], 'NFT in blacklist');
        _;
    }

    modifier _allowedCurrency(IERC20 token) {
        require(!currencyBlacklist[token], 'currency not allowed');
        _;
    }

    // internal helpers

    function _transfer(
        address to,
        IERC20 currency,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (currency == weth) {
                weth.withdraw(amount);
                payable(to).transfer(amount);
            } else {
                currency.safeTransfer(to, amount);
            }
        }
    }

    function _distributePayment(
        IERC20 currency,
        uint256 totalAmount,
        address seller,
        address buyer,
        IERC721 nft
    ) internal {
        uint256 fee = (totalAmount * feeController.feeRate(seller)) / feeController.rateBase();
        if (fee > 0) {
            _transfer(feeWallet, currency, fee);
        }
        _transfer(seller, currency, totalAmount - fee);
    }

    function _closeSellOfferFor(IERC721 nft, uint256 tokenId) internal {
        uint256 id = tokenSellOffers[nft][tokenId];
        if (id == 0) return;

        // closes old open sell offer
        Offer storage _offer = offers[id];
        _offer.status = STATUS_CANCELLED;
        tokenSellOffers[_offer.nft][_offer.tokenId] = 0;
        emit EvCancelOffer(id);
    }

    function _closeUserBuyOffer(uint256 id) internal {
        Offer storage o = offers[id];
        if (id > 0 && o.status == STATUS_OPEN && o.side == SIDE_BUY) {
            o.status = STATUS_CANCELLED;
            _transfer(o.user, o.currency, o.price);
            _unlinkBuyOffer(o);
            emit EvCancelOffer(id);
        }
    }

    function _unlinkBuyOffer(Offer storage o) internal {
        userBuyOffers[o.user][o.nft][o.tokenId] = 0;
    }

    function _unlinkSellOffer(Offer storage o) internal {
        tokenSellOffers[o.nft][o.tokenId] = 0;
    }

    // helpers

    function isValidSell(uint256 id) public view returns (bool) {
        if (id >= offers.length) {
            return false;
        }

        Offer storage _offer = offers[id];
        // try to not throw exception
        return
            _offer.status == STATUS_OPEN &&
            _offer.side == SIDE_SELL &&
            isTokenApproved(id, _offer.user) &&
            (_offer.nft.ownerOf(_offer.tokenId) == _offer.user);
    }

    function isTokenApproved(uint256 id, address owner) public view returns (bool) {
        Offer storage _offer = offers[id];
        return
            _offer.nft.getApproved(_offer.tokenId) == address(this) ||
            _offer.nft.isApprovedForAll(owner, address(this));
    }

    function getTokenOwner(uint256 id) public view returns (address) {
        Offer storage _offer = offers[id];
        return _offer.nft.ownerOf(_offer.tokenId);
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]









/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]




/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


// File contracts/mocks.sol






contract AnyERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}

contract FooNFT is ERC721 {
    constructor() ERC721('Foo', 'Foo') {}

    uint256 public nextId = 0;

    function mint(address to, uint256 tokenId) public {
        nextId = tokenId + 1;
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}

contract TestNFT is ERC721Enumerable {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    uint256 public nextId = 0;

    function mint(address to) public {
        _mint(to, nextId);
        nextId += 1;
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}

contract MockFarm is IFarm {
    mapping(uint256 => mapping(address => uint256)) public staked;

    function update(
        uint256 pid,
        address user,
        uint256 amount
    ) external {
        staked[pid][user] = amount;
    }

    function stakedWantTokens(uint256 pid, address user) external view override returns (uint256) {
        return staked[pid][user];
    }
}


// File contracts/WETH.sol





contract WETH is IWETH, ERC20 {
    constructor() ERC20('WETH', 'WETH') {}

    function deposit() external payable override {
        if (msg.value > 0) {
            _mint(msg.sender, msg.value);
        }
    }

    function withdraw(uint256 wad) external override {
        if (wad > 0) {
            _burn(msg.sender, wad);
            Address.sendValue(payable(msg.sender), wad);
        }
    }
}