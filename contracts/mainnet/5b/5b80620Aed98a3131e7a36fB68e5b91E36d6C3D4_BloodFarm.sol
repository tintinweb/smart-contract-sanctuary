// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../IVampireGameERC721.sol";

import "./IBloodFarm.sol";

import "../random/IRandom.sol";

/// @notice holds info about a staked Human
struct HumanStake {
    /// @notice address of the token owner
    address owner;
    /// @notice id of the token
    uint16 tokenId;
    /// @notice timestamp of when the human was staked
    uint80 stakedAt;
}

/// @notice holds info about a human unstake request
struct HumanUnstakeRequest {
    /// @notice id of the token to unstake
    uint16 tokenId;
    /// @notice block number of the unstake request
    uint240 blocknumber;
}

/// @title The Blood Farm
///
/// Note: A lot of the ideas in this contract are from wolf.game, some parts
/// were taken directly from their original contract. A lot of things were reorganized
///
/// ---
///
/// This contract holds all the state for staked humans and all the logic
/// for updating the state.
///
/// It doesn't transfer tokens or knows about other contracts.
contract BloodFarm is IBloodFarm, IERC721Receiver, Ownable {
    /// ==== Immutable Properties

    /// @notice how many bloodbags humans produce per day
    uint256 public constant DAILY_BLOODBAG_RATE = 5 ether;
    /// @notice blood farm guards won't let your human out for at least a few days.
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    /// @notice absolute total of bloodbags that can be produced
    uint256 public constant MAXIMUM_GLOBAL_BLOOD = 4500000 ether;

    /// ==== Mutable Properties

    /// @notice can't commit to risky action and reveal the outcome in the same block.
    /// This is the amount of blocks you need to wait to be able to reveal the outcome.
    uint256 public REVEAL_BLOCK_SPACE;

    /// @notice total amount of $BLOODBAGS
    uint256 public totalBloodDrained;
    /// @notice nubmer of humans staked in the blood farm
    uint256 public totalHumansStaked;
    /// @notice the last time totalBloodDrained was updated
    uint256 public lastBloodUpdate;

    /// @notice map tokenId to its staking info
    mapping(uint16 => HumanStake) public stakingMap;
    /// @notice map a tokenId to its unstake request
    mapping(uint16 => HumanUnstakeRequest) public unstakingRequestMap;

    /// @notice map of controllers that can control this contract
    mapping(address => bool) public controllers;

    /// ==== Constructor

    constructor(uint256 _REVEAL_BLOCK_SPACE) {
        REVEAL_BLOCK_SPACE = _REVEAL_BLOCK_SPACE;
    }

    /// ==== Modifiers

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS_ALLOWED");
        _;
    }

    modifier updateEarnings() {
        if (totalBloodDrained < MAXIMUM_GLOBAL_BLOOD) {
            totalBloodDrained +=
                ((block.timestamp - lastBloodUpdate) *
                    totalHumansStaked *
                    DAILY_BLOODBAG_RATE) /
                1 days;
            lastBloodUpdate = block.timestamp;
        }
        _;
    }

    /// ==== Events

    event StakedHuman(address indexed owner, uint16 indexed tokenId);
    /// @param owner who's claiming
    /// @param tokenId id of the token
    /// @param amount total amount to claim, tax included
    event BloodBagClaimed(
        address indexed owner,
        uint16 indexed tokenId,
        uint256 amount
    );
    event RequestedUnstake(address indexed owner, uint16 indexed tokenId);
    event UnstakedHuman(
        address indexed owner,
        uint16 indexed tokenId,
        uint256 amount
    );

    /// ==== Controls

    /// @notice Sends a human to the blood farm
    /// @param owner the address of the token owner
    /// @param tokenId the id of the token that will be staked
    function stakeHuman(address owner, uint16 tokenId)
        external
        override
        onlyControllers
    {
        stakingMap[tokenId] = HumanStake({
            owner: owner,
            tokenId: tokenId,
            stakedAt: uint80(block.timestamp)
        });
        totalHumansStaked += 1;

        emit StakedHuman(owner, tokenId);

        // <- Controller should transfer a Human to this contract
    }

    function claimBloodBags(address sender, uint16 tokenId)
        external
        override
        onlyControllers
        returns (uint256 owed)
    {
        HumanStake memory stake = stakingMap[tokenId];

        // Check if sender is the owner
        require(stake.owner == sender, "NOT_OWNER");
        // Do not allow to claim if there is a request to unstake
        require(
            unstakingRequestMap[tokenId].blocknumber == 0,
            "CANT_CLAIM_WITH_PENDING_UNSTAKE_REQUEST"
        );

        // Set total owed. Tax is calculated in controller.
        owed = _calculateOwedBloodBags(stake);

        // Reset staking info
        stakingMap[tokenId] = HumanStake({
            owner: sender,
            tokenId: tokenId,
            stakedAt: uint80(block.timestamp)
        });

        emit BloodBagClaimed(sender, tokenId, owed);

        // <- Controller should update the vampires bloodbags
        // <- Controller should transfer bloodbags to owner
    }

    function requestToUnstakeHuman(address sender, uint16 tokenId)
        external
        override
        onlyControllers
    {
        // Check token ownership
        require(stakingMap[tokenId].owner == sender, "NOT_YOURS");
        // Make sure it's staked
        require(stakingMap[tokenId].stakedAt != 0, "NOT_STAKED");
        // Make sure there is no request to unstake yer
        require(
            unstakingRequestMap[tokenId].blocknumber == 0,
            "ALREADY_REQUESTED"
        );
        // Make sure it got the minimum amount of blood bags
        require(
            block.timestamp - stakingMap[tokenId].stakedAt > MINIMUM_TO_EXIT,
            "NOT_ENOUGH_BLOOD"
        );
        _requestToUnstakeHuman(tokenId);
        emit RequestedUnstake(sender, tokenId);
    }

    function unstakeHuman(address sender, uint16 tokenId)
        external
        override
        onlyControllers
        returns (uint256 owed)
    {
        // Check token ownership
        require(stakingMap[tokenId].owner == sender, "NOT_YOURS");
        // Make sure it's staked
        require(stakingMap[tokenId].stakedAt != 0, "NOT_STAKED");
        // Make sure there is an unstake request
        require(unstakingRequestMap[tokenId].blocknumber != 0, "NOT_REQUESTED");

        owed = _unstakeHuman(tokenId);

        emit UnstakedHuman(sender, tokenId, owed);
    }

    /// ==== Helpers

    function _calculateOwedBloodBags(HumanStake memory stake)
        private
        view
        returns (uint256 owed)
    {
        if (totalBloodDrained < MAXIMUM_GLOBAL_BLOOD) {
            // still under the maxium limit, so normal logic here
            owed =
                ((block.timestamp - stake.stakedAt) * DAILY_BLOODBAG_RATE) /
                1 days;
        } else if (stake.stakedAt > lastBloodUpdate) {
            // when the player staked after the $BLOODBAG already hit the max amount
            owed = 0;
        } else {
            // if the total amount to claim will surpass the total limit, then some of the
            // blood won't get claimed
            owed =
                ((lastBloodUpdate - stake.stakedAt) * DAILY_BLOODBAG_RATE) /
                1 days;
        }
    }

    /// @dev Before calling this:
    /// - Check if there is NO unstake requests for this token
    function _requestToUnstakeHuman(uint16 tokenId) private {
        uint16 tid = uint16(tokenId);
        unstakingRequestMap[tokenId] = HumanUnstakeRequest({
            tokenId: tid,
            blocknumber: uint240(block.number)
        });
    }

    /// @dev Before calling this:
    /// - Check ownership of the token
    /// - Check if a unstake request exists
    function _unstakeHuman(uint16 tokenId) private returns (uint256 owed) {
        HumanStake memory stake = stakingMap[tokenId];
        // Check if this tx is at least REVEAL_BLOCK_SPACE older than the request block
        require(
            block.number - unstakingRequestMap[tokenId].blocknumber >=
                REVEAL_BLOCK_SPACE,
            "HUMAN_NOT_READY_FOR_CLAIM"
        );

        // Set total owed. Tax is calculated in controller.
        owed = _calculateOwedBloodBags(stake);

        // -- Update the BloodFarm state

        // remove unstaking request
        delete unstakingRequestMap[tokenId];
        // remove stake info
        delete stakingMap[tokenId];
        // decrement total humans staked
        totalHumansStaked -= 1;

        // <- Controller calculates the tax to vampires and update the vampires bloodbags
        // <- Controller transfer NFT to owner
        // <- Controller transfer bloodbags to owner
    }

    /// ==== Only Owner

    function setRevealBlockspace(uint256 space) external onlyOwner {
        require(REVEAL_BLOCK_SPACE != space, "NO_CHANGES");
        REVEAL_BLOCK_SPACE = space;
    }

    /// @notice add a controller that will be able to call functions in this contract
    /// @param controller the address that will be authorized
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /// @notice remove a controller so it won't be able to call functions in this contract anymore
    /// @param controller the address that will be unauthorized
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /// ==== IERC721Receiver

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "PLEASE_DONT");
        return IERC721Receiver.onERC721Received.selector;
    }

    /// ==== View

    function isStaked(uint16 tokenId) external view override returns (bool) {
        return stakingMap[tokenId].stakedAt != 0;
    }

    function hasRequestedToUnstake(uint16 tokenId)
        external
        view
        override
        returns (bool)
    {
        return unstakingRequestMap[tokenId].blocknumber != 0;
    }

    function ownerOf(uint16 tokenId) public view override returns (address) {
        return stakingMap[tokenId].owner;
    }
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

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IVampireGame.sol";

/// @notice Interface composed by IVampireGame + IERC721
interface IVampireGameERC721 is IVampireGame, IERC721 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/// @notice functions that can be called by a game controller
interface IBloodFarm {
    function stakeHuman(address owner, uint16 tokenId) external;

    function claimBloodBags(address sender, uint16 tokenId)
        external
        returns (uint256 owed);

    function requestToUnstakeHuman(address sender, uint16 tokenId) external;

    function unstakeHuman(
        address sender,
        uint16 tokenId
    ) external returns (uint256 owed);

    function isStaked(uint16 tokenId) external view returns (bool);

    function hasRequestedToUnstake(uint16 tokenId) external view returns (bool);

    function ownerOf(uint16 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IRandom {
  function submitHash(address sender, uint256 tokenId) external;
  function getRandomNumber(uint256 tokenId) external returns (uint256);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./traits/TokenTraits.sol";

/// @notice Interface to interact with the VampireGame contract
interface IVampireGame {
    /// @notice get the amount of tokens minted
    function getTotalSupply() external view returns (uint16);

    /// @notice get tthe amount of og supply
    function getOGSupply() external view returns (uint16);

    /// @notice get the total supply of gen-0
    function getGenZeroSupply() external view returns (uint16);

    /// @notice get the total supply of tokens
    function getMaxSupply() external view returns (uint16);

    /// @notice get the TokenTraits for a given tokenId
    function getTokenTraits(uint16 tokenId) external view returns (TokenTraits memory);

    /// @notice check if token id a vampire
    function isTokenVampire(uint16 tokenId) external view returns (bool);

    /// @notice get the Predator Index for a given tokenId
    function getPredatorIndex(uint16 tokenId) external view returns (uint8);

    /// @notice returns true if a token is aleady revealed
    function isTokenRevealed(uint16 tokenId) external view returns (bool);
}

/// @notice Interface to control parts of the VampireGame ERC 721
interface IVampireGameControls {
    /// @notice mint any amount of nft to any address
    /// Requirements:
    /// - message sender should be an allowed address (game contract)
    /// - amount + totalSupply() has to be smaller than MAX_SUPPLY
    function mintFromController(address receiver, uint16 amount) external;

    /// @notice reveal a list of tokens using specific seeds for each
    function controllerRevealTokens(uint16[] calldata tokenIds, uint256[] calldata seeds) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

struct TokenTraits {
    bool isVampire;
    // Shared Traits
    uint8 skin;
    uint8 face;
    uint8 clothes;
    // Human-only Traits
    uint8 pants;
    uint8 boots;
    uint8 accessory;
    uint8 hair;
    // Vampire-only Traits
    uint8 cape;
    uint8 predatorIndex;
}