/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

pragma solidity 0.8.6;


// SPDX-License-Identifier: MIT
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


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


interface IReferral {
    function set(address from, address to) external;

    function refOf(address to) external view returns (address);

    function reward(
        address addr,
        uint256 amount
    ) external;
}


interface IERC721Locker {
    function unlock(uint256 tokenId) external;

    function onERC721Locked(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);

    function onERC721Unlocked(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


interface IMeebMasterNFT is IERC721 {
    function getStats(uint256 tokenId) external view returns (uint16[] memory pvpStats, uint16 luckStat, uint16 productivityStat, uint256 otherStats);

    function totalBurned() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function lockedBy(uint256 tokenId) external view returns (address);

    function lock(uint256 tokenId, address locker) external;

    function unlock(uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}


contract UpDown is IERC721Locker,OwnableUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // the address used for receiving withdrawing fee

    uint256 public balanceOfBet = 0; // Total balance of are not finished
    uint256 public lockBalanceForGame = 0; // Don't use share value
    uint256[4] public bonusReward;// [0, 5 , 4 , 3]

    bool public stopped = false;

    // Instance of MEEB token (collateral currency for bet)
    IERC20 public meeb;
    address public nft; // MEEBMASTER

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    bool public nftLockDisabled;

    mapping(address => uint256) public userStakedNft;
    uint256 public noStakeFee;

    struct Bet {
        uint256 index;
        uint256 number;
        bool isOver;
        uint256 amount;
        address player;
        uint256 round;
        uint256 luckyNumber;
        uint256 seed;
        bool isFinished;
    }

    struct PlayerAmount {
        uint256 totalBet;
        uint256 totalPayout;
    }

    // SETTING
    uint256 public HOUSE_EDGE = 20; // 2%
    uint256 public MINIMUM_BET_AMOUNT = 0.1 ether;
    uint256 public PRIZE_PER_BET_LEVEL = 10;
    uint256 public REWARD_FOR_REFERRAL = 2; // 0.2% of bet amount for referral. max 0.5%

    address public referralContract;

    // Just for display on app
    uint256 public totalBetOfGame = 0;
    uint256 public totalWinAmountOfGame = 0;

    // Properties for game
    uint256[] public commitments;
    Bet[] public bets; // All bets of player
    mapping(address => uint256[]) public betsOf; // Store all bet of player
    mapping(address => PlayerAmount) public amountOf; // Store all bet of player

    mapping(address => bool) public croupiers;

    event TransferWinner(address winner, uint256 betIndex, uint256 amount);
    event TransferLeaderBoard(address winner, uint256 round, uint256 amount);
    event NewBet(
        address player,
        uint256 round,
        uint256 index,
        uint256 number,
        bool isOver,
        uint256 amount,
        uint256 nftId
    );
    event DrawBet(
        address player,
        uint256 round,
        uint256 index,
        uint256 number,
        bool isOver,
        uint256 amount,
        bool isFinished,
        uint256 luckyNumber,
        uint256 nftId
    );

    function initialize(address _meeb, address _nft, uint256[4] memory _bonusReward) external initializer {
        meeb = IERC20(_meeb);
        nft = _nft;
        bonusReward = _bonusReward;
        croupiers[msg.sender] = true;
        __Ownable_init();

        bets.push(
            Bet({
        number: 0,
        isOver: false,
        amount: 0,
        player: address(0x0),
        round: 0,
        isFinished: true,
        luckyNumber: 0,
        index: 0,
        seed: 0
        })
        );
    }

    event NftLocked(address indexed user, uint256 tokenId);
    event NftUnlocked(address indexed user, uint256 tokenId);

    /**
    MODIFIER
     */

    modifier notStopped() {
        require(!stopped, "stopped");
        _;
    }

    modifier isStopped() {
        require(stopped, "not stopped");
        _;
    }

    modifier notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0);
        require(tx.origin == msg.sender);
        _;
    }

    modifier onlyCroupier() {
        require(croupiers[msg.sender], "not croupier");
        _;
    }

    modifier onlyNFT() {
        require(msg.sender == nft, "!nft");
        _;
    }

    /**
    GET FUNCTION
     */

    function getLastBetIndex(address add) public view returns (uint256) {
        if (betsOf[add].length == 0) return 0;
        return betsOf[add][betsOf[add].length - 1];
    }

    function totalNumberOfBets(address player) public view returns (uint256) {
        if (player != address(0x00)) return betsOf[player].length;
        else return bets.length;
    }

    function numberOfCommitment() public view returns (uint256) {
        return commitments.length;
    }


    /**
    NFT
     */
    function getBoostedIndex(uint256 _tokenId) public view returns (uint256 _index) {
        if (_tokenId > 0) {
            (,, uint16 productivityStat,) = IMeebMasterNFT(nft).getStats(_tokenId);
            // productivityStat range: (120, 392)
            // boosted range: (2%, 30%)
            if (productivityStat >= 400) _index = 1; // 30%
            else if (productivityStat <= 120) _index = 3; // 2%
            else _index = 2; // eg 392 -> 29.2%
        } else {
            _index = 0;
        }
    }

    function unlock(uint256 tokenId) external override nonReentrant {
        require(tokenId != 0 && userStakedNft[msg.sender] == tokenId, "!locked");
        IMeebMasterNFT(nft).unlock(tokenId);
    }

    function onERC721Locked(address, address from, uint256 tokenId, bytes calldata) external override onlyNFT returns (bytes4) {
        require(!nftLockDisabled, "NFT lock is disabled");
        address _owner = IMeebMasterNFT(nft).ownerOf(tokenId);
        require(from == _owner, "!tokenOwner");
        uint256 _oldLockedTokenId = userStakedNft[_owner];
        if (_oldLockedTokenId > 0) {
            IMeebMasterNFT(nft).unlock(_oldLockedTokenId);
        }
        userStakedNft[_owner] = tokenId;
        emit NftLocked(_owner, tokenId);
        return bytes4(keccak256("onERC721Locked(address,address,uint256,bytes)"));
    }

    function onERC721Unlocked(address operator, address from, uint256 tokenId, bytes calldata) external override onlyNFT returns (bytes4) {
        require(operator == owner()|| !nftLockDisabled, "NFT lock is disabled");
        address _owner = IMeebMasterNFT(nft).ownerOf(tokenId);
        require(from == _owner, "!tokenOwner");
        userStakedNft[_owner] = 0;
        emit NftUnlocked(_owner, tokenId);
        return bytes4(keccak256("onERC721Unlocked(address,address,uint256,bytes)"));
    }

    /**
    BET RANGE
     */

    function balanceForGame(uint256 subAmount)
    public
    view
    returns (uint256 _bal)
    {
        _bal = meeb.balanceOf(address(this)) - subAmount - balanceOfBet;
    }

    function calculatePrizeForBet(uint256 betAmount)
    public
    view
    returns (uint256)
    {
        uint256 bal = balanceForGame(betAmount);
        uint256 prize = 1 ether;
        if (bal >= 10000 ether) prize = 500 ether;
        else if (bal >= 5000 ether) prize = 200 ether;
        else if (bal >= 2000 ether) prize = 100 ether;
        else if (bal >= 1000 ether) prize = 50 ether;
        else if (bal >= 500 ether) prize = 20 ether;
        else if (bal >= 200 ether) prize = 10 ether;
        else prize = 5 ether;

        if (PRIZE_PER_BET_LEVEL < 10) return prize;
        else return (prize * PRIZE_PER_BET_LEVEL) / 10;
    }

    function betRange(
        uint256 number,
        bool isOver,
        uint256 amount
    ) public view returns (uint256 min, uint256 max) {
        uint256 currentWinChance = calculateWinChance(number, isOver);
        uint256 prize = calculatePrizeForBet(amount);
        min = MINIMUM_BET_AMOUNT;
        max = (prize * currentWinChance) / 100;
        if (max < MINIMUM_BET_AMOUNT) max = MINIMUM_BET_AMOUNT;
    }

    /**
    BET
     */

    function calculateWinChance(uint256 number, bool isOver)
    private
    pure
    returns (uint256)
    {
        return isOver ? 99 - number : number;
    }

    function calculateWinAmount(
        uint256 number,
        bool isOver,
        uint256 amount,
        uint256 indexBoosted
    ) private view returns (uint256) {
        uint256 winAmount = amount * (1000 - HOUSE_EDGE) / 10 / calculateWinChance(number, isOver);
        winAmount = winAmount + winAmount * bonusReward[indexBoosted] / 100;
        return winAmount;
    }

    /**
    DRAW WINNER
    */

    function checkWin(
        uint256 number,
        bool isOver,
        uint256 luckyNumber
    ) private pure returns (bool) {
        return
        (isOver && number < luckyNumber) ||
        (!isOver && number > luckyNumber);
    }

    function getLuckyNumber(uint256 betIndex, uint256 secret)
    private
    view
    returns (uint256)
    {
        Bet memory bet = bets[betIndex];

        if (bet.round >= block.number) return 0;
        if (secret == 0) {
            if (block.number - bet.round < 1000) return 0;
        } else {
            uint256 commitment = commitments[betIndex];
            if (uint256(keccak256(abi.encodePacked((secret)))) != commitment) {
                return 0;
            }
        }

        uint256 blockHash = uint256(blockhash(bet.round));
        if (blockHash == 0) {
            blockHash = uint256(blockhash(block.number - 1));
        }
        return 100 + ((secret ^ bet.seed ^ blockHash) % 100);
    }

    /**
    WRITE & PUBLIC FUNCTION
     */

    function _login(address ref) internal {
        if (referralContract != address(0x0)) {
            IReferral(referralContract).set(ref, msg.sender);
        }
    }

    function _newBet(uint256 betAmount, uint256 winAmount) internal {
        require(
            lockBalanceForGame + winAmount < balanceForGame(betAmount),
            "Balance is not enough for game"
        );
        lockBalanceForGame = lockBalanceForGame + winAmount;
        balanceOfBet = balanceOfBet + betAmount;
    }

    function _finishBet(uint256 betAmount, uint256 winAmount) internal {
        lockBalanceForGame = lockBalanceForGame - winAmount;
        balanceOfBet = balanceOfBet - betAmount;
    }

    function placeBet(
        uint256 number,
        bool isOver,
        uint256 seed,
        address ref,
        uint256 amountBet
    ) external notStopped notContract {
        if (ref != address(0)) {
            _login(ref);
        }
        (uint256 minAmount, uint256 maxAmount) =
        betRange(number, isOver, amountBet);
        uint256 index = bets.length;
        require(commitments.length > index);
        require(minAmount > 0 && maxAmount > 0);
        require(
            isOver ? number >= 4 && number <= 98 : number >= 1 && number <= 95,
            "bet number not in range"
        );
        require(
            minAmount <= amountBet && amountBet <= maxAmount,
            "bet amount not in range"
        );
        require(
            bets[getLastBetIndex(msg.sender)].isFinished,
            "last best not finished"
        );

        // Transfers the required meeb to this contract
        meeb.safeTransferFrom(msg.sender, address(this), amountBet);

        uint256 indexBoosted = getBoostedIndex(userStakedNft[msg.sender]);
        uint256 winAmount = calculateWinAmount(number, isOver, amountBet, indexBoosted);
        _newBet(amountBet, winAmount);

        totalBetOfGame += amountBet;

        betsOf[msg.sender].push(index);

        bets.push(
            Bet({
                index: index,
                number: number,
                isOver: isOver,
                amount: amountBet,
                player: msg.sender,
                round: block.number,
                isFinished: false,
                luckyNumber: 0,
                seed: seed
            })
        );
        emit NewBet(msg.sender, block.number, index, number, isOver, amountBet, userStakedNft[msg.sender]);
    }

    function refundBet(address add) external onlyOwner {
        uint256 betIndex = getLastBetIndex(add);
        Bet storage bet = bets[betIndex];
        require(
            !bet.isFinished &&
        bet.player == add &&
        block.number - bet.round > 10000
        );

        uint256 indexBoosted = getBoostedIndex(userStakedNft[add]);
        uint256 winAmount = calculateWinAmount(bet.number, bet.isOver, bet.amount, indexBoosted);

        meeb.safeTransfer(add, bet.amount);
        _finishBet(bet.amount, winAmount);

        bet.isFinished = true;
        bet.amount = 0;
    }

    /**
    FOR Owner
     */
    function settleBet(
        uint256 i,
        uint256 secret,
        uint256 newCommitment
    ) public onlyCroupier {
        require(i < bets.length);

        Bet storage bet = bets[i];

        require(bet.round < block.number);
        require(!bet.isFinished);

        commit(newCommitment);

        uint256 luckyNum = getLuckyNumber(bet.index, secret);
        require(luckyNum > 0);

        luckyNum -= 100;

        uint256 indexBoosted = getBoostedIndex(userStakedNft[bet.player]);
        uint256 winAmount = calculateWinAmount(bet.number, bet.isOver, bet.amount, indexBoosted);

        bet.luckyNumber = luckyNum;
        bet.isFinished = true;

        if (referralContract != address(0x0)) {
            address ref = IReferral(referralContract).refOf(bet.player);
            if (ref != address(0x0)) {
                uint256 commission =
                bet.amount * REWARD_FOR_REFERRAL / 1000;
                IReferral(referralContract).reward(ref, commission);
            }
        }

        if (checkWin(bet.number, bet.isOver, luckyNum)) {
            totalWinAmountOfGame += winAmount;
            meeb.safeTransfer(bet.player, winAmount);
            amountOf[bet.player].totalBet += bet.amount;
            amountOf[bet.player].totalPayout += winAmount;
            emit TransferWinner(bet.player, bet.index, winAmount);
        } else {
            amountOf[bet.player].totalBet += bet.amount;
        }

        _finishBet(bet.amount, winAmount);
        emit DrawBet(
            bet.player,
            bet.round,
            bet.index,
            bet.number,
            bet.isOver,
            bet.amount,
            bet.isFinished,
            bet.luckyNumber,
            userStakedNft[bet.player]
        );
    }

    function commit(uint256 _commitment) public onlyCroupier {
        require(
            0 != _commitment &&
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563 !=
            _commitment
        );
        commitments.push(_commitment);
    }

    function addCroupier(address add) external onlyOwner {
        croupiers[add] = true;
    }

    function removeCroupier(address add) external onlyOwner {
        croupiers[add] = false;
    }

    function setPrizeLevel(uint256 level) external onlyOwner {
        require(PRIZE_PER_BET_LEVEL <= 1000);
        PRIZE_PER_BET_LEVEL = level;
    }

    function setHouseEdge(uint256 value) external onlyOwner {
        require(value >= 5 && value <= 100); // [0.5%, 10%]
        HOUSE_EDGE = value;
    }

    function setMinBet(uint256 value) external onlyOwner {
        require(value >= 0.05 ether && value <= 10 ether);
        MINIMUM_BET_AMOUNT = value;
    }

    function setReferral(address _referral) external onlyOwner {
        referralContract = _referral;
    }

    function setMeeb(address _meeb) external onlyOwner {
        meeb = IERC20(_meeb);
    }

    function setReferralReward(uint256 value) external onlyOwner {
        require(value >= 10 && value <= 50); // [0.1%, 0.5%]
        REWARD_FOR_REFERRAL = value;
    }

    function setBonusReward(
        uint256[4] memory _bonusReward
    ) external onlyOwner {
        bonusReward = _bonusReward;
    }

    function toggleNftLockDisabled() external onlyOwner {
        nftLockDisabled = !nftLockDisabled;
    }

    function emergencyToken(IERC20 token, uint256 amount)
    external
    onlyOwner
    {
        token.safeTransfer(owner(), amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(
            amount + lockBalanceForGame <= meeb.balanceOf(address(this)),
            "over available balance"
        );
        meeb.safeTransfer(owner(), amount);
    }

    /** FOR EMERGENCY */

    function forceStopGame(uint256 confirm) external onlyOwner {
        require(confirm == 0x1, "Enter confirm code");
        stopped = true;
    }
}