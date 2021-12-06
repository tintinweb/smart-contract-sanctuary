/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// File: contracts/utils/SignatureUtils.sol


pragma solidity ^0.8.0;

contract SignatureUtils {
    function getMessageHash( 
        uint256 tokenId,
        uint256 price,
        uint256 salt,
        address owner,
        address signer
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, price, salt, owner, signer));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        uint256 tokenId,
        uint256 price,
        uint256 salt,
        address owner,
        address signer,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            tokenId,
            price,
            salt,
            owner,
            signer
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// File: contracts/handlers/Upgradable.sol


pragma solidity ^0.8.0;






contract Upgradable is ReentrancyGuard{
    /* GLOBAL VARIABLES */
    mapping(address => bool) adminList; // admin list for modifying pool
    mapping(address => bool) blackList; // blocked users
    mapping(address => bool) signers; // signers list
    uint256 constant ONE_YEAR_IN_SECONDS = 31536000;
    uint256 constant ONE_DAY_IN_SECONDS = 86400;
    IERC721 public nftCollection; // the collection of minted nfts
    IERC20 public rewardToken; // reward token 
    SignatureUtils public signatureUtils; // used for signature verification

    /* POOL VARIABLES */
    uint256 public totalAmountStaked;
    uint256 public totalRewardClaimed;
    uint256 public totalPoolCreated;
    uint256 public totalRewardFund;
    uint256 public totalUserStaked;
    
    mapping(string => PoolInfo) public poolInfo; // pools info
    mapping(address => uint256) public totalStakedBalancePerUser; // total value of nft users staked to the pool
    mapping(address => uint256) public totalRewardClaimedPerUser; // total reward users claimed
    mapping(string => mapping(address => StakingData)) public tokenStakingData; // owner => tokenId => data
    mapping(string => mapping(address => mapping(uint256 => StakingData))) public nftStaked; // owner => tokenId => data
    mapping(string => mapping(address => uint256)) public stakedBalancePerUser; // total value each user staked to the pool
    mapping(string => mapping(address => uint256)) public rewardClaimedPerUser; // reward each user has claimed
    mapping(string => mapping(address => uint256)) public totalNftStakedInPool; // totalNftStakedInPool by user
    mapping(string => uint256[]) public timeConfigs; // time configurations per pool, startDate(0), endDate(1), duration(2), endStakeDate(3)
    
    /*================================ MODIFIERS ================================*/
    
    modifier onlyAdmins() {
        require(adminList[msg.sender], "Only admins");
        _;
    }
    
    modifier poolExist(string memory poolId, uint256 poolType) {
        require(poolInfo[poolId].initialFund != 0, "Pool is not exist");
        require(poolInfo[poolId].poolType == poolType, "Pool type not supported");
        _;
    }
    
    /*================================ EVENTS ================================*/
    
    event StakingEvent( 
        uint256 indexed amount,
        address indexed account,
        string poolId,
        string internalTxID
    );
    
    event PoolUpdated(
        address indexed creator,
        string internalTxID
    );
    
    /*================================ STRUCTS ================================*/
     
    struct StakingData {
        uint256 balance; // staked value of nft
        uint256 stakedTime; // the time nft was staked
        uint256 unstakedTime; // the time nft was unstaked
        uint256 reward; // the total reward claimed by nft
        uint256 rewardPerTokenPaid; // reward per token paid
        uint256 finalReward; // reward at the time nft was unstaked, will not calculate after unstaked time
        address account;
    }
    
    struct PoolInfo {
        address stakingToken; // reward token of the pool
        uint256 stakedAmount; // amount of nft staked to the pool
        uint256 stakedBalance; // total value of nfts which were staked to the pool
        uint256 totalRewardClaimed; // total reward user has claimed
        uint256 rewardFund; // pool amount for reward token available
        uint256 initialFund; // initial reward fund
        uint256 lastUpdateTime; // last update time
        uint256 rewardPerTokenStored; // reward distributed
        uint256 totalUserStaked;
        uint256 poolType; // 0: nft, 1: token
        //uint256[] configs; // startDate(0), endDate(1), duration(2), endStakeDate(3)
    }
}
// File: contracts/handlers/StakingPool.sol


pragma solidity ^0.8.0;


contract StakingPool is Upgradable {
    using SafeERC20 for IERC20;

    function initPool(address _signatureUtils, address _nftCollection, address _rewardToken) external {
        rewardToken = IERC20(_rewardToken);
        signatureUtils = SignatureUtils(_signatureUtils);
        nftCollection = IERC721(_nftCollection);
    }

    /*================================ MAIN FUNCTIONS ================================*/
    
    // strs: poolId(0), internalTxID(1)
    // data: tokenId(0), price(1), salt(2)
    // addr: signer(0)
    function stakeNft(
        string[] memory strs,
        uint256[] memory data, 
        address[] memory addr,
        bytes memory signature
    ) external nonReentrant poolExist(strs[0], 0) {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        uint256[] memory configs = timeConfigs[poolId];
        
        // check if staking time is valid
        require(block.timestamp >= configs[0], "Pool is not activated");
        require(block.timestamp <= configs[3], "Staking time is ended"); 
        require(signers[addr[0]], "Only signers");
        require(!blackList[msg.sender], "In blacklist");

        // verify signature for nft price
        require(
            signatureUtils.verify(
                data[0],
                data[1],
                data[2],
                msg.sender,
                addr[0],
                signature
            ),
            "NFT is invalid"
        );

        // Update info
        pool.rewardPerTokenStored = rewardPerToken(poolId);
        pool.lastUpdateTime = block.timestamp;
        
        StakingData memory nft = StakingData(
            data[1],
            block.timestamp,
            0,
            0,
            pool.rewardPerTokenStored,
            0,
            msg.sender
        );

        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked += 1;
        }
        totalStakedBalancePerUser[msg.sender] += data[1];
        
        if (totalNftStakedInPool[poolId][msg.sender] == 0) {
            pool.totalUserStaked += 1;
        }
        totalNftStakedInPool[poolId][msg.sender] += 1;
    
        nftStaked[poolId][msg.sender][data[0]] = nft;
        pool.stakedAmount += 1;
        pool.stakedBalance += data[1];
        totalAmountStaked += data[1];
        stakedBalancePerUser[poolId][msg.sender] += data[1];
        
        nftCollection.transferFrom(msg.sender, address(this), data[0]);
        
        emit StakingEvent(data[1], msg.sender, poolId, strs[1]);
    }
    
    // strs: poolId(0), internalTxID(1)
    function stakeToken(
        string[] memory strs,
        uint256 amount
    ) external nonReentrant poolExist(strs[0], 1) {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage data = tokenStakingData[poolId][msg.sender];
        uint256[] memory configs = timeConfigs[poolId];
        
        // check if staking time is valid
        require(block.timestamp >= configs[0], "Pool is not activated");
        require(block.timestamp <= configs[3], "Staking time is ended"); 
        require(!blackList[msg.sender], "In blacklist");

        // Update info
        pool.rewardPerTokenStored = rewardPerToken(poolId);
        pool.lastUpdateTime = block.timestamp;
        data.reward = earned(poolId, msg.sender, 0, 1);   
        data.rewardPerTokenPaid = pool.rewardPerTokenStored;
        
        data.balance += amount;
        data.stakedTime = block.timestamp;

        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked += 1;
        }
        totalStakedBalancePerUser[msg.sender] += amount;
        
        if (stakedBalancePerUser[poolId][msg.sender] == 0) {
            pool.totalUserStaked += 1;
        }
        stakedBalancePerUser[poolId][msg.sender] += amount;
        
        pool.stakedBalance += amount;
        totalAmountStaked += amount;
        
        IERC20(pool.stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        
        emit StakingEvent(amount, msg.sender, poolId, strs[1]);
    }

    // strs: poolId(0), internalTxID(1)
    function unstakeNft(string[] memory strs, uint256 tokenId)
        external
        nonReentrant
        poolExist(strs[0], 0)
    {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        
        StakingData storage nft = nftStaked[poolId][msg.sender][tokenId];
        
        // Update info
        pool.rewardPerTokenStored = rewardPerToken(poolId);
        pool.lastUpdateTime = block.timestamp;
        nft.reward = earned(poolId, msg.sender, tokenId, 0);  
        nft.rewardPerTokenPaid = pool.rewardPerTokenStored;

        require(nft.unstakedTime == 0, "NFT was unstaked");
        require(nft.account == msg.sender, "Caller is not NFT owner");
        
        totalStakedBalancePerUser[msg.sender] -= nft.balance;
        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked -= 1;
        }
        
        totalNftStakedInPool[poolId][msg.sender] -= 1;
        if (totalNftStakedInPool[poolId][msg.sender] == 0) {
            pool.totalUserStaked -= 1;
        }
        
        pool.stakedAmount -= 1;
        pool.stakedBalance -= nft.balance; 
        totalAmountStaked -= nft.balance;
        nft.finalReward = nft.reward;
        nft.unstakedTime = block.timestamp;
        stakedBalancePerUser[poolId][msg.sender] -= nft.balance;
        
        nftCollection.transferFrom(address(this), msg.sender, tokenId);

        emit StakingEvent(nft.finalReward, msg.sender, poolId, strs[1]);
    }
    
    // strs: poolId(0), internalTxID(1) 
    function unstakeToken(string[] memory strs, uint256 amount)
        external
        nonReentrant
        poolExist(strs[0], 1)
    {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage data = tokenStakingData[poolId][msg.sender];
        
        // Update info
        pool.rewardPerTokenStored = rewardPerToken(poolId); 
        pool.lastUpdateTime = block.timestamp;
        data.reward = earned(poolId, msg.sender, 0, 1);   
        data.rewardPerTokenPaid = pool.rewardPerTokenStored;
        
        require(data.balance >= amount, "Not enough staking balance");

        totalStakedBalancePerUser[msg.sender] -= data.balance;
        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked -= 1;
        }

        totalNftStakedInPool[poolId][msg.sender] -= 1;
        if (totalNftStakedInPool[poolId][msg.sender] == 0) {
            pool.totalUserStaked -= 1;
        }
        
        stakedBalancePerUser[poolId][msg.sender] -= amount;
        if (stakedBalancePerUser[poolId][msg.sender] == 0) {
            pool.totalUserStaked -= 1;
        }
        
        data.balance -= amount;
        pool.stakedBalance -= data.balance; 
        totalAmountStaked -= data.balance;
        
        IERC20(rewardToken).safeTransfer(msg.sender, amount);

        emit StakingEvent(amount, msg.sender, poolId, strs[1]);
    } 
    
    // strs: poolId(0), internalTxID(1)
    // data: poolType(0), tokenId(1)
    function claimReward(string[] memory strs, uint256[] memory data)
        external
        nonReentrant
        poolExist(strs[0], data[0]) 
    { 
        string memory poolId = strs[0];
        uint256 tokenId = 0;
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage item = tokenStakingData[poolId][msg.sender]; 
        
        if (data[0] == 0) {
            tokenId = data[1];
            item = nftStaked[poolId][msg.sender][data[1]];
        }
        
        // Update info
        pool.rewardPerTokenStored = rewardPerToken(poolId);
        pool.lastUpdateTime = block.timestamp;
        item.reward = earned(poolId, msg.sender, tokenId, data[0]);
        item.rewardPerTokenPaid = pool.rewardPerTokenStored;
         
        uint256 availableAmount = item.reward;
        require(availableAmount > 0, "Reward is 0");
        require(
            IERC20(pool.stakingToken).balanceOf(address(this)) >= availableAmount,
            "Pool balance is not enough"
        );

        item.reward = 0;
        pool.totalRewardClaimed += availableAmount;
        totalRewardClaimed += availableAmount;
        rewardClaimedPerUser[poolId][msg.sender] += availableAmount;
        totalRewardClaimedPerUser[msg.sender] += availableAmount;
        
        if (data[0] == 0) {
            require(canGetReward(poolId, data[1], data[0]), "Not enough staking time");
            IERC20(pool.stakingToken).safeTransfer(msg.sender, availableAmount);
            item.finalReward = 0;
        } else if (data[0] == 1) {
            IERC20(rewardToken).safeTransfer(msg.sender, availableAmount);
        }

        emit StakingEvent(availableAmount, msg.sender, poolId, strs[1]); 
    }
    
    function canGetReward(string memory poolId, uint256 tokenId, uint256 poolType) public view returns (bool) {
        uint256[] memory configs = timeConfigs[poolId];
        
        if (configs[2] == 0) return true;
        
        StakingData memory data;
        if (poolType == 0) {
            data = nftStaked[poolId][msg.sender][tokenId];
        } else if (poolType == 1) {
            data = tokenStakingData[poolId][msg.sender];
        }
        
        return data.stakedTime + configs[2] * ONE_DAY_IN_SECONDS >= block.timestamp;
    }

    // data: poolType(0), tokenId(1)
    function earned(string memory poolId, address account, uint256 tokenId, uint256 poolType) 
        public
        view
        returns (uint256)
    {
        StakingData memory item = tokenStakingData[poolId][account]; 
        
        if (poolType == 0) {
            item = nftStaked[poolId][account][tokenId];
        }
        
        PoolInfo memory pool = poolInfo[poolId];
        uint256 amount = item.balance * (rewardPerToken(poolId) - item.rewardPerTokenPaid) / 1e8 + item.reward;
         
        return pool.rewardFund > amount ? amount : pool.rewardFund;
    }
    
    function rewardPerToken(string memory poolId) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[poolId];
        uint256[] memory configs = timeConfigs[poolId];
        uint256 poolDuration = configs[1] - configs[0];
        if (pool.stakedBalance == 0 || poolDuration == 0) return 0;
        uint256 currentTimestamp = block.timestamp < configs[1] ? block.timestamp : configs[1];
        uint256 rewardPool = pool.rewardFund * (currentTimestamp - pool.lastUpdateTime) * 1e8;
          
        return rewardPool / (poolDuration * pool.stakedBalance) + pool.rewardPerTokenStored;
    }
    
    function apr(string memory poolId) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[poolId];
        uint256[] memory configs = timeConfigs[poolId];
        uint256 poolDuration = configs[1] - configs[0];
        if (pool.stakedBalance == 0 || poolDuration == 0) return 0;
        
        return (ONE_YEAR_IN_SECONDS * pool.rewardFund / poolDuration - pool.totalRewardClaimed) * 100 / pool.stakedBalance; 
    }

    /*================================ ADMINISTRATOR FUNCTIONS ================================*/
      
    function createPool(string[] memory strs, address _stakingToken, uint256[] memory _configs, uint256 poolType) external onlyAdmins {
        require(poolInfo[strs[0]].initialFund == 0, "Pool already exists");
        require(_configs[0] > 0, "Reward fund must be greater than 0");

        // rewardFund, startDate, endDate, duration, endStakedTime
        PoolInfo memory pool = PoolInfo(_stakingToken, 0, 0, 0, _configs[0], _configs[0], 0, 0, 0, poolType);
        timeConfigs[strs[0]] = [_configs[1], _configs[2], _configs[3], _configs[4]];
        poolInfo[strs[0]] = pool;
        totalPoolCreated += 1;
        totalRewardFund += _configs[0];
        
        emit PoolUpdated(msg.sender, strs[1]);
    }

    function updatePool(string[] memory strs, uint256[] memory _newConfigs, uint256 poolType)
        external
        onlyAdmins
        poolExist(strs[0], poolType)
    {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        uint256[] memory configs = timeConfigs[poolId];
        
        if (_newConfigs[0] != 0) {
            require(configs[0] > block.timestamp, "Pool is already published");
            timeConfigs[poolId][0] = _newConfigs[0];
        }
        if (_newConfigs[1] != 0) {
            require(_newConfigs[1] > configs[0], "End date must be greater than start date");
            require(_newConfigs[1] >= block.timestamp, "End date must not be the past");
            timeConfigs[poolId][1] = _newConfigs[1];
        }
        if (_newConfigs[2] != 0) {
            require(
                _newConfigs[2] >= pool.initialFund,
                "New reward fund must be greater than or equals to existing reward fund"
            );
            
            totalRewardFund = totalRewardFund - pool.initialFund + _newConfigs[2];
            pool.rewardFund = _newConfigs[2];
            pool.initialFund = _newConfigs[2];
        }
        if (_newConfigs[3] != 0) {
            require(_newConfigs[3] > configs[0], "End staking date must be greater than start date");
            timeConfigs[poolId][3] = _newConfigs[3];
        }
        
        emit PoolUpdated(msg.sender, strs[1]);
    }
    
    function withdraw(address tokenId, address _to, uint256 _amount) external onlyAdmins {
        IERC20(tokenId).safeTransfer(_to, _amount); 
    }
    
    function setAdmin(address _address, bool _value) external { 
        adminList[_address] = _value;
    } 

    function isAdmin(address _address) external view returns (bool) {
        return adminList[_address];
    }

    function setBlacklist(address _address, bool _value) external onlyAdmins {
        blackList[_address] = _value;
    }

    function isBlackList(address _address) external view returns (bool) {
        return blackList[_address];
    }
    
    function isSigner(address _address) external view returns (bool) {
        return signers[_address];
    }
    
    function setSigner(address _address, bool _value) external { 
        signers[_address] = _value;
    }
    
    function setSignatureUtilsAddress(address _signatureUtils) external {
        signatureUtils = SignatureUtils(_signatureUtils);
    }
    
    function setNftCollection(address _nftCollection) external {
        nftCollection = IERC721(_nftCollection); 
    }
    
    function setRewardToken(address _rewardToken) external {
        rewardToken = IERC20(_rewardToken);
    }
}