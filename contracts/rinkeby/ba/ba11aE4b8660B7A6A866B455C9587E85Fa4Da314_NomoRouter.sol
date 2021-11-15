//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/INomoRouter.sol";
import "./interfaces/INomoLeague.sol";

contract NomoRouter is Ownable, INomoRouter {
    /// @notice Nomo NFT contract
    INomoNFT public nft;

    /// @notice Token in form of which rewards are payed
    IERC20 public rewardToken;

    /// @notice Address that is authorized to update token points in leagues
    address public updater;

    /// @notice Mapping of tokenIds to their staker's addresses
    mapping(uint256 => address) public stakers;

    /// @notice Mapping of tokenIds to league contracts where they are staked
    mapping(uint256 => INomoLeague) public stakedAt;

    /// @notice Mapping of leagueIds to league contracts
    mapping(uint256 => INomoLeague) public leagues;

    /// @notice Mapping of addresses to lists of tokenIds that each address has staked
    mapping(address => uint256[]) public stakedTokenIds;

    /// @notice List of leagueIds
    uint256[] private _leagueIds;

    // CONSTRUCTOR

    constructor(
        INomoNFT nft_,
        IERC20 rewardToken_,
        address updater_
    ) Ownable() {
        nft = nft_;
        rewardToken = rewardToken_;
        updater = updater_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @notice Function to stake multiple tokens
     * @param tokenIds List of token IDs
     */
    function stakeTokens(uint256[] calldata tokenIds) external override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakeToken(tokenIds[i]);
        }
    }

    /**
     * @notice Function to unstake multiple tokens
     * @param tokenIds List of token IDs
     */
    function unstakeTokens(uint256[] calldata tokenIds) external override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            unstakeToken(tokenIds[i]);
        }
    }

    /**
     * @notice Function to stake single token
     * @param tokenId ID of the token to stake
     */
    function stakeToken(uint256 tokenId) public {
        nft.transferFrom(msg.sender, address(this), tokenId);

        stakers[tokenId] = msg.sender;
        uint256 leagueId = _getLeague(tokenId);
        require(address(leagues[leagueId]) != address(0), "NomoRouter::stakeToken: can't stake to non-existent league");
        stakedAt[tokenId] = leagues[leagueId];
        leagues[leagueId].stakeToken(msg.sender, tokenId);

        stakedTokenIds[msg.sender].push(tokenId);

        emit TokenStaked(msg.sender, tokenId, leagueId);
    }

    /**
     * @notice Function to unstake single token
     * @param tokenId ID of the token to unstake
     */
    function unstakeToken(uint256 tokenId) public {
        require(stakers[tokenId] == msg.sender, "NomoRouter::unstakeToken: sender doesn't have token in stake");

        stakedAt[tokenId].unstakeToken(msg.sender, tokenId);
        stakers[tokenId] = address(0);
        stakedAt[tokenId] = INomoLeague(address(0));

        for (uint256 i = 0; i < stakedTokenIds[msg.sender].length; i++) {
            if (stakedTokenIds[msg.sender][i] == tokenId) {
                stakedTokenIds[msg.sender][i] = stakedTokenIds[msg.sender][stakedTokenIds[msg.sender].length - 1];
                stakedTokenIds[msg.sender].pop();
                break;
            }
        }

        nft.transferFrom(address(this), msg.sender, tokenId);

        emit TokenUnstaked(msg.sender, tokenId, _getLeague(tokenId));
    }

    // RESTRICTED FUNCTIONS

    /**
     * @notice Function to add league, can only be called by owner
     * @param league Address of the league contract
     * @param leagueId ID that should be assigned to this league
     */
    function addLeague(INomoLeague league, uint256 leagueId) external onlyOwner {
        require(address(leagues[leagueId]) == address(0), "NomoRouter::addLeague: can't add league with the same id");
        leagues[leagueId] = league;
        _leagueIds.push(leagueId);

        emit LeagueAdded(address(league), leagueId);
    }

    /**
     * @notice Function to remove league, can only be called by owner
     * @param leagueId ID of the league to remove
     */
    function removeLeague(uint256 leagueId) external onlyOwner {
        for (uint256 i = 0; i < _leagueIds.length; i++) {
            if (_leagueIds[i] == leagueId) {
                emit LeagueRemoved(address(leagues[leagueId]), leagueId);

                _leagueIds[i] = _leagueIds[_leagueIds.length - 1];
                _leagueIds.pop();

                delete leagues[leagueId];

                return;
            }
        }
        revert("NomoRoute::removeLeague: no league with such leagueId exists");
    }

    /**
     * @notice Function to update token's points in league, can only be called by updater
     * @param tokenId ID of the token to update
     * @param oldPoints Old number of token's points
     * @param newPoints New number of token's points
     */
    function updatePoints(
        uint256 tokenId,
        uint256 oldPoints,
        uint256 newPoints
    ) external onlyUpdater {
        if (stakers[tokenId] != address(0)) {
            leagues[_getLeague(tokenId)].updatePoints(stakers[tokenId], tokenId, oldPoints, newPoints);
        }
    }

    /**
     * @notice Function to set new updater, can only be called by owner
     * @param updater_ New updater address
     */
    function setUpdater(address updater_) external onlyOwner {
        updater = updater_;
    }

    // VIEW FUNCTION

    /**
     * @notice Function to get total reward of some account in all leagues
     * @param account Address to get rewards for
     * @return Total reward
     */
    function totalRewardOf(address account) external view override returns (uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < _leagueIds.length; i++) {
            totalReward += leagues[_leagueIds[i]].totalRewardOf(account);
        }
        return totalReward;
    }

    /**
     * @notice Function to get all league IDs
     */
    function leagueIds() external view returns (uint256[] memory) {
        return _leagueIds;
    }

    /**
     * @notice Function to get NFT address
     */
    function getNft() external view override returns (address) {
        return address(nft);
    }

    /**
     * @notice Function to get reward token address
     */
    function getRewardToken() external view override returns (address) {
        return address(rewardToken);
    }

    // PRIVATE FUNCTIONS

    function _getLeague(uint256 tokenId) private view returns (uint256) {
        (, uint256 leagueId, , , , , , ) = nft.getCardImageDataByTokenId(tokenId);
        return leagueId;
    }

    // MODIFIERS

    modifier onlyUpdater() {
        require(msg.sender == updater, "NomoRouter: caller is not the updater");
        _;
    }
}

interface INomoNFT is IERC721 {
    function getCardImageDataByTokenId(uint256 _tokenId)
        external
        view
        returns (
            string memory name,
            uint256 league,
            uint256 gen,
            uint256 points,
            uint256 pointsUpdateTime,
            string[] memory paramsNames,
            uint256[] memory paramsValues,
            uint256 paramsUpdateTime
        );
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface INomoRouter {
    event TokenStaked(address indexed account, uint256 indexed tokenId, uint256 leagueId);

    event TokenUnstaked(address indexed account, uint256 indexed tokenId, uint256 leagueId);

    event LeagueAdded(address indexed league, uint256 indexed leagueId);

    event LeagueRemoved(address indexed league, uint256 indexed leagueId);

    function stakeTokens(uint256[] calldata tokenIds) external;

    function unstakeTokens(uint256[] calldata tokenIds) external;

    function totalRewardOf(address account) external view returns (uint256);

    function getNft() external view returns (address);

    function getRewardToken() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface INomoLeague {
    event RewardWithdrawn(address indexed account, uint256 amount);

    event NewGameStarted(uint256 indexed index);

    event TokenStaked(address indexed account, uint256 indexed tokenId);

    event TokenUnstaked(address indexed account, uint256 indexed tokenId);

    function withdrawReward() external;

    function nextGame(uint256 totalReward) external;

    function stakeToken(address account, uint256 tokenId) external;

    function unstakeToken(address account, uint256 tokenId) external;

    function updatePoints(
        address account,
        uint256 tokenId,
        uint256 oldPoints,
        uint256 newPoints
    ) external;

    function totalRewardOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

