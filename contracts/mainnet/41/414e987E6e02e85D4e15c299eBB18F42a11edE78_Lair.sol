// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../IVampireGameERC721.sol";
import "../traits/TokenTraits.sol";

import "./ILair.sol";

/// @notice holds info about a staked Vampire
struct VampireStake {
    /// @notice address of the token owner
    address owner;
    /// @notice id of the token. uint16 cuz max token id = 50k
    uint16 tokenId;
    /// @notice the bloodbagPerPredatorScore of the Lair when the vampire joined
    uint80 bloodbagPerPredatorScoreWhenStaked;
}

/// @title The Vampire Lair
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
contract Lair is ILair, IERC721Receiver, Ownable {
    /// @notice sum of "predator score" of all staked vampires
    uint24 public totalPredatorScoreStaked = 0;
    /// @notice amount of $BLOODBAG for each predator score
    uint256 public bloodbagPerPredatorScore = 0;
    /// @notice map a predator score to a list of VampireStake[] containing vampires with that score
    mapping(uint8 => VampireStake[]) public scoreStakingMap;
    /// @notice tracks the index of each Vampire in the stake list
    mapping(uint16 => uint256) public stakeIndices;
    /// @notice map of controllers that can control this contract
    mapping(address => bool) public controllers;

    /// @notice VampireGame ERC721 contract for quering info
    IVampireGame public vgame;

    /// ==== Events

    event VampireStaked(
        address indexed owner,
        uint16 indexed tokenId,
        uint256 bloodBagPerPredatorScoreWhenStaked
    );
    event VampireUnstaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount
    );
    event BloodBagClaimed(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount
    );
    event TaxUpdated(
        uint256 amount,
        uint256 unaccountedReward
    );

    /// ==== Constructor

    constructor(address _vgame) {
        vgame = IVampireGame(_vgame);
    }

    /// ==== Modifiers

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS_ALLOWED");
        _;
    }

    /// ==== Helpers

    /// @notice returns the predator score of a Vampire
    /// @param tokenId the Vampire's id
    /// @return the predator score of the Vampire (5-8)
    function _predatorScoreForVampire(uint16 tokenId)
        private
        view
        returns (uint8)
    {
        return 8 - vgame.getPredatorIndex(tokenId);
    }

    /// ==== ILairControls

    /// @dev See {ILairControls.stakeVampire}
    function stakeVampire(address sender, uint16 tokenId)
        external
        override
        onlyControllers
    {
        uint8 score = _predatorScoreForVampire(tokenId);

        // Update total predator score
        totalPredatorScoreStaked += score;

        // Store the location of the vampire in the VampireStake list
        stakeIndices[tokenId] = scoreStakingMap[score].length;

        // Push vampire to the VamprieStake list
        scoreStakingMap[score].push(
            VampireStake({
                owner: sender,
                tokenId: tokenId,
                bloodbagPerPredatorScoreWhenStaked: uint80(
                    bloodbagPerPredatorScore
                )
            })
        );

        emit VampireStaked(sender, tokenId, bloodbagPerPredatorScore);
    }

    /// @dev See {ILairControls.claimBloodBags}
    function claimBloodBags(address sender, uint16 tokenId)
        external
        override
        onlyControllers
        returns (uint256 owed)
    {
        uint8 score = _predatorScoreForVampire(tokenId);
        VampireStake memory stake = scoreStakingMap[score][
            stakeIndices[tokenId]
        ];
        require(sender == stake.owner, "NOT_OWNER_OR_NOT_STAKED");

        // Calculate and sets amount of bloodbags owed (this is returned by the fn)
        uint256 _bloodbagPerPredatorScore = bloodbagPerPredatorScore;
        owed =
            score *
            (_bloodbagPerPredatorScore -
                stake.bloodbagPerPredatorScoreWhenStaked);

        // Resets the vampire staking info
        scoreStakingMap[score][stakeIndices[tokenId]] = VampireStake({
            owner: sender,
            tokenId: tokenId,
            bloodbagPerPredatorScoreWhenStaked: uint80(_bloodbagPerPredatorScore)
        });

        // Logs an event with the blood claiming info
        emit BloodBagClaimed(sender, tokenId, owed);

        // <- Controller is supposed to transfer $BLOODBAGs
    }

    /// @dev See {ILairControls.unstakeVampire}
    function unstakeVampire(address sender, uint16 tokenId)
        external
        override
        onlyControllers
        returns (uint256 owed)
    {
        uint8 score = _predatorScoreForVampire(tokenId);
        VampireStake memory stake = scoreStakingMap[score][
            stakeIndices[tokenId]
        ];
        require(stake.owner == sender, "NOT_OWNER_OR_NOT_STAKED");

        // Calculate and sets amount of bloodbags owed (this is returned by the fn)
        owed =
            score *
            (bloodbagPerPredatorScore -
                stake.bloodbagPerPredatorScoreWhenStaked);

        // Sub vampire's score from total score staked
        totalPredatorScoreStaked -= score;

        // Gets the last vampire in the staking list for this score
        VampireStake memory lastStake = scoreStakingMap[score][
            scoreStakingMap[score].length - 1
        ];

        // Move the last staked vampire to the current position
        scoreStakingMap[score][stakeIndices[tokenId]] = lastStake;
        stakeIndices[lastStake.tokenId] = stakeIndices[tokenId];

        // Delete the last vampire from staking list, since it's duplicated now
        scoreStakingMap[score].pop();
        delete stakeIndices[tokenId];

        // Setting all state first, then controller will do the token transfer.
        // Doing that in this order will protects us against reentrancy.

        // Logs an event with the vampire unstaking and blood claiming info
        emit VampireUnstaked(sender, tokenId, owed);

        // <- Controller is supposed to transfer NFT
        // <- Controller is supposed to transfer $BLOODBAGs
    }

    function addTaxToVampires(uint256 amount, uint256 unaccountedRewards)
        external
        override
        onlyControllers
    {
        bloodbagPerPredatorScore +=
            (amount + unaccountedRewards) /
            totalPredatorScoreStaked;
        emit TaxUpdated(amount, unaccountedRewards);
    }

    /// ==== ILair

    /// @notice See {ILair.getTotalPredatorScoreStaked}
    function getTotalPredatorScoreStaked()
        external
        view
        override
        returns (uint24)
    {
        return totalPredatorScoreStaked;
    }

    /// @notice See {ILair.getBloodbagPerPredatorScore}
    function getBloodbagPerPredatorScore()
        external
        view
        override
        returns (uint256)
    {
        return bloodbagPerPredatorScore;
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

    /// ==== Only Owner

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

    /// ==== Frontend Helpers

    function ownerOf(uint16 tokenId, uint8 predatorIndex) public view override returns (address) {
        return scoreStakingMap[predatorIndex][stakeIndices[tokenId]].owner;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface ILair {
    /// @notice returns the totalPredatorScoreStaked property
    function getTotalPredatorScoreStaked() external view returns (uint24);

    /// @notice returns the totalPredatorScoreStaked property
    function getBloodbagPerPredatorScore() external view returns (uint256);

    function ownerOf(uint16 tokenId, uint8 predatorIndex) external view returns (address);

    /// @notice Stake one vampire
    ///
    /// What this does:
    ///
    /// - Update the state of the vault to contain the Vampire that the user wants to stake
    ///
    /// What the controller should do after this function returns:
    ///
    /// - Before calling this: Controller should check if the address implements onReceiveERC721.
    /// - Then call transferFrom(_msgSender(), LAIR_ADDRESS, tokenId)
    ///
    /// Note: This is only called by controller, and the sender should be `_msgSender()`
    ///
    /// @param sender address of who's making this request, should be the vampire owner
    /// @param tokenId ids of each vampire to stake
    function stakeVampire(address sender, uint16 tokenId) external;

    /// @notice update the vault state to as the owed amont fo the vampire was removed
    ///
    /// What this does:
    ///
    /// - Calculate and return the current amount owed to a vampire
    /// - Reset the vampire stake info to as if they were staked now
    ///
    /// What the controller should do after this function returns:
    ///
    /// - Transfer the `owed` amount of $BLOODBAGs to `sender`.
    ///
    /// Note: This is only called by controller, and the sender should be `_msgSender()`
    /// Note: We set all state first, and the do the transfers to avoid reentrancy
    ///
    /// @param sender address of who's making this request, should be the vampire owner
    /// @param tokenId id of the vampire
    /// @return owed amount of $BLOODBAGs owed to the vampire
    function claimBloodBags(address sender, uint16 tokenId)
        external
        returns (uint256 owed);

    /// @notice update the vault state to as the owed amont fo the vampire was removed
    /// and the vampire was unstaked.
    ///
    /// What this does:
    ///
    /// - Calculate and return the current amount owed to a vampire
    /// - Deletes the vampire info from staking structures
    /// - Moves the last vampire staked to the current position of this vampire
    ///
    /// What the controller should do after this function returns:
    ///
    /// - Transfer the `owed` amount of $BLOODBAGs to `sender`.
    /// - Transfer the NFT from this contract to `sender`
    ///
    /// Note: This is only called by controller, and the sender should be `_msgSender()`
    /// Note: We set all state first, and the do the transfers to avoid reentrancy
    ///
    /// @param sender address of who's making this request, should be the vampire owner
    /// @param tokenId id of the vampire
    /// @return owed amount of $BLOODBAGs owed to the vampire
    function unstakeVampire(address sender, uint16 tokenId)
        external
        returns (uint256 owed);

    function addTaxToVampires(uint256 amount, uint256 unaccountedRewards) external;
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