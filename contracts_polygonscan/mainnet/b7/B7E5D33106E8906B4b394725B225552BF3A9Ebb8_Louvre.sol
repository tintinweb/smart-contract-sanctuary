/**
 *Submitted for verification at polygonscan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IRandomNumberGenerator {
    function getRandomNumber() 
        external 
        returns (bytes32 requestId);
}

interface ILockedLPStaking {
    function extendRewardDuration(
        uint256 _amount
    ) 
        external;
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    constructor() {
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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
     * by making the `nonReentrant` function external, and making it call a
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
* @title Louvre Finance's main contract, allows users to try and steal NFTs from the collection
* and offers rewards to users that choose to return stolen art pieces.
* Have fun reading it. Hopefully it's bug-free. God bless.
*/
contract Louvre is Ownable, Pausable, ReentrancyGuard, ERC721Holder {


    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public ticket_;
    IERC721 public lart_;
    IRandomNumberGenerator internal randomGenerator_;
    ILockedLPStaking public lockedLPStaking_;

    uint256[] public museum;

    struct RobberyInfo {
        uint256 multiplier;
        uint256 nftId;
        address recipientAddress;
    }

    address public lockedLPStaking;

    uint256 public userCooldown = 30 seconds;
    uint256 public ticketPrice = 1 ether;
    uint256 public louvrePot;
    uint256 public lastPotUpdate;
    uint256 public louvreRate = 0;
    uint256 public louvreRewardStoredFinish = 0;
    uint256 public initialLouvrePot;
    uint256 public louvreRewardsDuration = 180 days;
    uint256 internal constant BASIS = 1e6;

    // Mappings
    mapping(address => uint256) public lastUserAttempt;
    mapping(uint256 => uint256) public initialProbabilities;
    mapping(uint256 => address) public passes;
    mapping(uint256 => uint256) public numberOfAttempts;
    mapping(uint256 => uint256) public numberOfSucesses;
    mapping(uint256 => bool) public statusOf;
    mapping(bytes32 => RobberyInfo) public robberyInfoList;

    event RobberyFinalized(bool indexed _bool, address indexed _userAddress, bytes32 indexed requestId, uint256 _nftId);
    event RewardClaimed(address indexed _claimingAddress, uint256 indexed _nftId, uint256 _rewardGiven);
    event MuseumUpdated(uint256[] indexed _newIds, uint256[] indexed _newProbabilities);
    event RobberyInitialized(uint256 _nftId, uint256 _multiplier, address _recipientAddress, bytes32 requestId);

    modifier onlyRandomGenerator() {
        require(
            msg.sender == address(randomGenerator_),
            "ERR_ONLY_RNG"
        );
        _;
    }

    // Should initialize addresses
    constructor (
        address _lart,
        address _ticket,
        address _lockedLPStaking,
        address _randomGenerator
    ){
        lart_ = IERC721(_lart);
        ticket_ = IERC20(_ticket);
        lockedLPStaking_ = ILockedLPStaking(_lockedLPStaking);
        randomGenerator_ = IRandomNumberGenerator(_randomGenerator);
        lockedLPStaking = _lockedLPStaking;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    /// @notice This function gives the percentage of the louvrePot will be given as a reward for the return of a NFT
    /// @param _nftId ID of NFT
    /// @return Reward for a NFT in percentage of total tokens in louvrePot
    function viewReward(
        uint256 _nftId
    )
        public
        view
        returns(uint256)
    {
        // 95% of ticketPrice * (BASIS/probability)
        return (95 * BASIS * BASIS * ticketPrice) / (100 * viewProbability(_nftId));
    }

    /// @notice This function gives the probability of stealing a given nft
    /// @dev Should be divided by BASIS to return probability between 0 and 1
    /// @return Probability percentage
    /// @param _nftId ID of NFT
    function viewProbability(
        uint256 _nftId
    )
        public
        view
        returns(uint256)
    {
        return initialProbabilities[_nftId] * probabilityMultiplier();
    }

    /// @dev Updates probabilities and reward percentages based on LouvrePot value
    function probabilityMultiplier() public view returns(uint256) {
        // precision of 6 decimal places trough storing in BASIS
        return initialLouvrePot * BASIS / louvrePot;
    }

    /// @notice This function returns true if the given NFT is in the posession of the contract and false otherwise
    /// @param _nftId ID of NFT
    /// @return Bool value that will be true if the contract posesses the NFT
    function viewNFTStatus(
        uint256 _nftId
    )
        public
        view
        returns(bool)
    {
        return statusOf[_nftId];
    }

    /// @notice This function returns an array containing IDs of user owned NFTs
    /// @return Array of IDs
    function viewUserCollection(address _user)
        public
        view
        returns(uint256[] memory)
    {
        if (lart_.balanceOf(_user) == 0) {
            uint256[] memory result = new uint256[](0);
            return result;
        } else {
            uint256 size = lart_.balanceOf(_user);
            uint256 counter = 0;
            uint256[] memory result = new uint256[](size);

            for (uint256 i = 0; i < museum.length; i++) {
                if (lart_.ownerOf(museum[i]) == _user) {
                    result[counter] = museum[i];
                    counter++;
                }
            }
            return result;
        }
    }

    /// @notice This function returns the number of attempts made to steal a given NFT.
    /// @param _nftId ID of NFT
    /// @return Number of attempts
    function viewNumberOfAttempts(
        uint256 _nftId
    )
        public
        view
        returns(uint256)
    {
        return numberOfAttempts[_nftId];
    }

    /// @notice This function returns the number of times a given NFT was stolen.
    /// @param _nftId ID of NFT
    /// @return Number of sucessess
    function viewNumberOfSucesses(
        uint256 _nftId
    )
        public
        view
        returns(uint256)
    {
        return numberOfSucesses[_nftId];
    }

    /// @dev Calculates fee to be paid when attempting robbery with multiplier
    /// @param _multiplier Multiplier
    /// @return Fee 
    function multiplierFee(uint256 _multiplier) public view returns(uint256) {
        if(_multiplier == 1) {
            return 0;
        } else {
            return (_multiplier ** 2) * ticketPrice / 100;
        }
    }

    /// @dev Calculates probability based on initial probability and multiplier
    /// based on 1 - (1-probability)**multiplier, calculated trough for loop to avoid overflow
    /// @param _nftId ID of NFT
    /// @param _multiplier Multiplier
    /// @return Final probability of stealin
    function finalProbability(uint256 _nftId, uint256 _multiplier) public view returns(uint256) {
        uint256 _probability = BASIS;
        for(uint i =0; i < _multiplier; i++){
            _probability = _probability * (BASIS * BASIS - viewProbability(_nftId)) / (BASIS * BASIS);
        }
        _probability = BASIS - _probability;
        return _probability;
    }

    /// @notice User cooldown
    /// @param _user Address of user
    /// @return User cooldown
    function viewLastUserAttempt(address _user) public view returns(uint256) {
        return lastUserAttempt[_user];
    }

    //-------------------------------------------------------------------------
    // EXTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    /// @notice This function will initialize the robbery attempt of a given NFT
    /// @dev Called by external functions with the relevant multiplier
    /// @param _nftId ID of NFT
    /// @param _multiplier Multiplier
    function initializeAttempt(uint256 _nftId, uint256 _multiplier) external nonReentrant() whenNotPaused() {
        require(lastUserAttempt[msg.sender] + userCooldown < block.timestamp, "ERR_COOLDOWN_IN_PLACE");
        require(statusOf[_nftId], "ERR_NFT_UNAVAILABLE");
        require(_multiplier > 0 && _multiplier <= 1000, "ERR_MUL_CAP_IS_1000");

        if (passes[_nftId] != address(0)){
            IERC721 pass = IERC721(passes[_nftId]);
            require(pass.balanceOf(msg.sender) >= _multiplier, "ERR_NOT_ENOUGH_PASSES");
        }

        lastUserAttempt[msg.sender] = block.timestamp;

        numberOfAttempts[_nftId] += _multiplier;

        uint256 _ticketAmount = (ticketPrice * _multiplier) + multiplierFee(_multiplier);
        louvrePot = louvrePot + _ticketAmount + _louvreRewardStored();

        ticket_.safeTransferFrom(msg.sender, address(this), _ticketAmount);

        // Requests a random number from the generator
        bytes32 requestId_ = randomGenerator_.getRandomNumber();

        RobberyInfo storage robbery = robberyInfoList[requestId_];
        robbery.recipientAddress = msg.sender;
        robbery.multiplier = _multiplier;
        robbery.nftId = _nftId;

        emit RobberyInitialized( _nftId, _multiplier, msg.sender, requestId_);
    }

    /// @notice Concludes robbery attempt, transfers NFT in case of success
    /// @dev For the requestId_ == _requestId bit see https://docs.chain.link/docs/vrf-security-considerations/
    /// @param _requestId Chainlink sorcery
    /// @param _randomNumber Random number generated by chainlink oracle
    function concludeAttempt(
        bytes32 _requestId,
        uint256 _randomNumber
    )
        external
        onlyRandomGenerator()
    {
        RobberyInfo storage robbery = robberyInfoList[_requestId];
        uint256 _nftId = robbery.nftId;
        uint256 _multiplier = robbery.multiplier;
        uint256 _probability = finalProbability(_nftId, _multiplier);
        uint256 _random = _randomNumber % BASIS;
        address _recipientAddress = robbery.recipientAddress;
        if(_random < _probability) {
            if(statusOf[_nftId] == true) {
                statusOf[_nftId] = false;
                numberOfSucesses[_nftId]++;
                lart_.safeTransferFrom(address(this), _recipientAddress, _nftId);
                emit RobberyFinalized(true, _recipientAddress, _requestId, _nftId);
            } else {
                emit RobberyFinalized(false, _recipientAddress, _requestId, _nftId);
            }
        } else {
            emit RobberyFinalized(false, _recipientAddress, _requestId, _nftId);
        }
    }

    /// @notice Gives reward for the devolution of a stolen NFT
    /// @dev Transfers fees to LP staking reward pool
    /// @param _nftId ID of NFT
    function claimReward(uint256 _nftId) external nonReentrant() whenNotPaused() {

        require(lart_.ownerOf(_nftId) == msg.sender, "ERR_USER_NOT_OWNER");

        // 2% of ticketPrice * (BASIS/probability)
        uint256 feeLPStaking = 2 * BASIS * BASIS * ticketPrice / (100 * viewProbability(_nftId));
        uint256 _userReward = viewReward(_nftId);
        louvrePot = louvrePot + _louvreRewardStored() - _userReward - feeLPStaking;
        statusOf[_nftId] = true;

        lart_.safeTransferFrom(msg.sender, address(this), _nftId);
        ticket_.safeTransfer(msg.sender, _userReward);
        ticket_.safeTransfer(lockedLPStaking, feeLPStaking);

        lockedLPStaking_.extendRewardDuration(feeLPStaking);

        emit RewardClaimed(msg.sender, _nftId, _userReward);
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    /// @dev Calculates the amount of tokens to be added to the louvrePot given the rate
    /// @dev Rate based on time of operation, and 20000 tokens to be added
    /// @return Value to be added
    function _louvreRewardStored() internal returns(uint256) {
        uint256 value = (lastTimeRewardApplicable() - lastPotUpdate) * louvreRate;
        lastPotUpdate = lastTimeRewardApplicable();
        return value;
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, louvreRewardStoredFinish);
    }

    //-------------------------------------------------------------------------
    // RESTRICTED FUNCTIONS
    //-------------------------------------------------------------------------

    /// @notice Sets LouvrePot and initialLouvrePot
    /// @param _louvrePot LouvrePot
    function SetLouvrePot(uint256 _louvrePot) external onlyOwner() {
        require(_louvrePot > 0, "ERR_SHOULDNT_BE_ZERO");
        require(initialLouvrePot == 0, "ERR_LOUVRE_NOT_INITIATED");
        louvrePot = _louvrePot;
        initialLouvrePot = _louvrePot;
    }

    /// @notice Initializes new NFTs, their reward percentages and their probabilities of being stolen in an attempt
    /// @dev See if it's best to use memory instead of calldata
    /// @param _newIds NFT IDs being transfered to contract
    /// @param _newProbabilities Probability of these NFTs being stolen
    function updateMuseum(
        uint256[] calldata _newIds,
        uint256[] calldata _newProbabilities,
        address[] calldata _pass
    )
        external
        onlyOwner()
    {
        require(ticket_.balanceOf(address(this)) > 0);
        require(
            _newIds.length == _newProbabilities.length &&
           _newProbabilities.length == _pass.length,
            "ERR_ARRAYS_DIF_LENGTH"
        );
        for(uint256 i = 0; i < _newIds.length; i++){
            uint256 newId = _newIds[i];
            uint256 newProbability = _newProbabilities[i];
            address pass = _pass[i];
            lart_.safeTransferFrom(msg.sender, address(this), newId);
            museum.push(newId);
            initialProbabilities[newId] = newProbability;
            passes[newId] = pass;
            statusOf[newId] = true;
        }
        emit MuseumUpdated(_newIds, _newProbabilities);
    }

    /// @dev Initiates Louvre's retro-feeding of tokens system, copied from Synthetix's StakingRewards contract
    /// @param reward Amount of tokens to be added
    function notifyRewardStored(uint256 reward) external onlyOwner() {
        if (block.timestamp >= louvreRewardStoredFinish) {
            louvreRate = reward / louvreRewardsDuration;
        } else {
            uint256 remaining = louvreRewardStoredFinish - block.timestamp;
            uint256 leftover = remaining * louvreRate;
            louvreRate = (reward + leftover) / louvreRewardsDuration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of louvreRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = ticket_.balanceOf(address(this));
        require(louvreRate <= balance / louvreRewardsDuration, "ERR_REWRD_TOO_HIGH");

        lastPotUpdate = block.timestamp;
        louvreRewardStoredFinish = block.timestamp + louvreRewardsDuration;
    }

    /// @dev Sets Louvre's reward duration
    /// @param _louvreRewardsDuration Reward duration
    function setRewardStoredDuration(uint256 _louvreRewardsDuration) external onlyOwner() {
        require(louvreRewardsDuration == 0, "ERR_REWARDS_IN_PROCESS");
        louvreRewardsDuration = _louvreRewardsDuration;
    }
}