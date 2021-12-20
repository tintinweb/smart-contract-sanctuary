// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title StellarInu NFT Staking
/// @dev Stake NFTs, earn ETH
/// @author crypt0s0nic
contract NFTStaking is Ownable, ReentrancyGuard {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // StellarInu NFT
    // CA: TBA
    IERC721 public nft;

    /// @notice Struct to track what user is staking which NFT
    /// @dev tokenIds are all the NFT staked by the staker
    /// @dev amount is the
    /// @dev rewardsEarned is the total reward for the staker till now
    /// @dev rewardsReleased is how much reward has been paid to the staker
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndex;
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    /// @notice mapping of a staker to its current properties
    mapping(address => Staker) public stakers;

    // @notice mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;

    /// @notice total shares, rewards, distributed rewards and reward per each staked nft
    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareMultiplier = 1e36;

    /// @notice sets the rewards to be claimable or not.
    /// Cannot claim if it set to false.
    bool public rewardsClaimable;
    bool initialized;

    /// @notice modifier to require initialized state
    /// Cannot take action if initialized is false
    modifier onlyInitialized() {
        require(initialized == true, "onlyInitialized: NOT_INIT_YET");
        _;
    }

    /// @notice event emitted when a user has staked a token
    event Staked(address indexed user, uint256 amount);

    /// @notice event emitted when a user has unstaked a token
    event Unstaked(address indexed user, uint256 amount);

    /// @notice event emitted when a user claims reward
    event Claimed(address indexed user, uint256 amount);

    constructor() {}

    /// @dev Single gateway to intialize the staking contract after deploying
    /// @dev Sets the contract with the NFT token
    /// @param _nft The ERC721 NFT
    function initStaking(IERC721 _nft) external onlyOwner {
        require(!initialized, "init: initialized");
        nft = _nft;
        initialized = true;
    }

    /// @notice Stake StellarInu NFTs and earn ETH
    /// @dev Rewards will be claimed when staking an additional NFT
    /// @param tokenId The ERC721 tokenId
    function stake(uint256 tokenId) external onlyInitialized nonReentrant {
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        Staker storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            _claim(msg.sender);
        }
        totalShares += 1;
        staker.amount += 1;
        staker.totalExcluded = getCumulativeRewards(staker.amount);
        staker.tokenIds.push(tokenId);
        staker.tokenIndex[staker.tokenIds.length - 1];
        tokenOwner[tokenId] = msg.sender;

        emit Staked(msg.sender, tokenId);
    }

    /// @notice Unstake StellarInu NFTs.
    /// @dev Rewards will be claimed when unstaking
    /// @param tokenId The ERC721 tokenId
    function unstake(uint256 tokenId) external onlyInitialized nonReentrant {
        require(msg.sender == tokenOwner[tokenId], "unstake: NOT_STAKED_NFT_OWNER");

        Staker storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            _claim(msg.sender);
        }

        uint256 lastIndex = staker.tokenIds.length - 1;
        uint256 lastIndexKey = staker.tokenIds[lastIndex];
        uint256 tokenIdIndex = staker.tokenIndex[tokenId];
        staker.tokenIds[tokenIdIndex] = lastIndexKey;
        staker.tokenIndex[lastIndexKey] = tokenIdIndex;
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
            delete staker.tokenIndex[tokenId];
        }

        totalShares -= 1;
        staker.amount -= 1;
        staker.totalExcluded = getCumulativeRewards(staker.amount);

        // delete staker
        delete tokenOwner[tokenId];
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Unstaked(msg.sender, tokenId);
    }

    /// @notice Claim the ETH rewards
    function claim() public onlyInitialized nonReentrant {
        require(rewardsClaimable == true, "claim: NOT_CLAIMABLE");
        _claim(msg.sender);
    }

    /// @notice Private function to implementing the ETH rewards claiming
    function _claim(address user) private {
        if (rewardsClaimable != true) return;

        uint256 amount = getUnpaidRewards(user);
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        if (amount == 0) return;

        stakers[user].totalRealised += amount;
        stakers[user].totalExcluded = getCumulativeRewards(stakers[user].amount);
        totalDistributed += amount;
        safeTransferETH(user, amount);
        emit Claimed(user, amount);
    }

    /// @notice View the unpaid rewards of a staker
    /// @param user The address of a user
    /// @return The amount of rewards in wei that `user` can withdraw
    function getUnpaidRewards(address user) public view returns (uint256) {
        if (stakers[user].amount == 0) return 0;

        uint256 stakerTotalRewards = getCumulativeRewards(stakers[user].amount);
        uint256 stakerTotalExcluded = stakers[user].totalExcluded;

        if (stakerTotalRewards <= stakerTotalExcluded) return 0;

        return stakerTotalRewards - stakerTotalExcluded;
    }

    /// @notice Private function to view the cumulative rewards of an amount of shares
    /// @param share the amount of shares
    /// @return The cumulative rewards in wei
    function getCumulativeRewards(uint256 share) private view returns (uint256) {
        return (share * rewardsPerShare) / rewardsPerShareMultiplier;
    }

    /// @notice Set the stakable NFT address
    /// @dev _nft must be IERC721
    /// @param _nft NFT address
    function setNFT(IERC721 _nft) external onlyOwner {
        nft = _nft;
    }

    /// @notice Set the rewards to be claimable
    /// @param _enabled is boolean. True means claimable and false means unclaimable
    function setRewardClaimable(bool _enabled) external onlyOwner {
        rewardsClaimable = _enabled;
    }

    /// @dev Getter functions for Staking contract
    /// @dev Get the tokens staked by a user
    function getStakedNFT(address user) external view returns (uint256[] memory) {
        return stakers[user].tokenIds;
    }

    /// @notice Deposit reward
    /// @dev Called by owner only
    function depositRewards() external payable onlyOwner {
        require(totalShares > 0, "depositRewards: NO_SHARES");
        totalRewards += msg.value;
        rewardsPerShare += ((rewardsPerShareMultiplier * msg.value) / totalShares);
    }

    /// @notice Rescue ETH from the contract
    /// @dev Called by owner only
    /// @param receiver The payable address to receive ETH
    /// @param amount The amount in wei
    function withdrawETH(address payable receiver, uint256 amount) external onlyOwner {
        require(receiver != address(0), "withdrawETH: BURN_ADDRESS");
        require(address(this).balance >= amount, "withdrawETH: INSUFFICIENT_BALANCE");
        safeTransferETH(receiver, amount);
    }

    /// @dev Private function that safely transfers ETH to an address
    /// It fails if to is 0x0 or the transfer isn't successful
    /// @param to The address to transfer to
    /// @param value The amount to be transferred
    function safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "FD::safeTransferETH: ETH_TRANSFER_FAILED");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public returns (bytes4) {
        return _ERC721_RECEIVED;
    }
}