// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../bloodbag/IBLOODBAG.sol";
import "../staking/ILair.sol";
import "../staking/IBloodFarm.sol";
import "../random/Random.sol";

import "../IVampireGameERC721.sol";

contract GameController is ReentrancyGuard, Ownable, Pausable {
    /// @notice the tax vampires charge in percentage (20%)
    uint256 public constant BLOOD_CLAIM_TAX_PERCENTAGE = 20;

    /// @notice amount of blood distributed when no vampires are staked
    uint256 public unaccountedRewards = 0;

    // Other contracts this caontract controls
    IVampireGameERC721 public vgame;
    IBLOODBAG public bloodbag;
    ILair public lair;
    IBloodFarm public bloodfarm;
    IRandom public random;

    /// ==== Constructor

    constructor(
        address _vgame,
        address _bloodbag,
        address _lair,
        address _bloodfarm,
        address _random
    ) {
        vgame = IVampireGameERC721(_vgame);
        bloodbag = IBLOODBAG(_bloodbag);
        lair = ILair(_lair);
        bloodfarm = IBloodFarm(_bloodfarm);
        random = IRandom(_random);
    }

    /// ==== Mixed Controls

    /// @notice stake many vampire and human tokens
    /// @param tokenIds the ids of tokens to be staked. The caller should own the tokens
    function stakeManyTokens(uint16[] calldata tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        IVampireGameERC721 vgameRef = vgame;
        IBloodFarm bloodfarmRef = bloodfarm;
        address sender = _msgSender();
        for (uint16 i = 0; i < tokenIds.length; i++) {
            uint16 tokenId = tokenIds[i];
            require(vgameRef.isTokenRevealed(tokenId), "NO_STAKING_COFFINS");
            if (_isVampire(vgameRef, tokenId)) {
                _stakeVampire(vgameRef, lair, sender, tokenId);
            } else {
                _stakeHuman(vgameRef, bloodfarmRef, sender, tokenId);
            }
        }
    }

    /// @notice unstake many tokens.
    /// - Vampires can be staked at any time
    /// - Humans need to have a unstake request first
    function unstakeManyTokens(
        uint16[] calldata requestToUnstakeIds,
        uint16[] calldata unstakeHumanIds,
        uint16[] calldata unstakeVampireIds
    ) external whenNotPaused nonReentrant {
        uint256 totalOwed = 0;
        uint256 totalTax = 0;
        IVampireGameERC721 vgameRef = vgame;
        IBloodFarm bloodfarmRef = bloodfarm;
        ILair lairRef = lair;
        address sender = _msgSender();

        for (uint16 i = 0; i < unstakeHumanIds.length; i++) {
            uint16 tokenId = unstakeHumanIds[i];
            (uint256 owed, uint256 tax) = _unstakeHuman(
                vgameRef,
                bloodfarmRef,
                sender,
                tokenId
            );
            totalOwed += owed;
            totalTax += tax;
        }

        for (uint16 i = 0; i < requestToUnstakeIds.length; i++) {
            _requestToUnstakeHuman(
                bloodfarmRef,
                sender,
                requestToUnstakeIds[i]
            );
        }

        if (totalTax != 0) {
            _addVampireTax(lairRef, totalTax);
        }

        for (uint16 i = 0; i < unstakeVampireIds.length; i++) {
            totalOwed += _unstakeVampire(
                vgameRef,
                lairRef,
                sender,
                unstakeVampireIds[i]
            );
        }

        if (totalOwed != 0) {
            bloodbag.mint(sender, totalOwed);
        }
    }

    /// @notice claim blood bags
    /// @dev checks of ownersgip performed in Lair and BloodFarm
    /// @param humans humans tokenIds
    /// @param vampires vampires tokenIds
    function claimBloodBags(
        uint16[] calldata humans,
        uint16[] calldata vampires
    )
        external
        whenNotPaused
        nonReentrant
    {
        uint256 owed = 0;
        uint256 tax = 0;
        address sender = _msgSender();
        ILair lairRef = lair;
        IBloodFarm bloodfarmRef = bloodfarm;

        for (uint16 i = 0; i < humans.length; i++) {
            uint256 _owed = bloodfarmRef.claimBloodBags(sender, humans[i]);
            uint256 _tax = (_owed * BLOOD_CLAIM_TAX_PERCENTAGE) / 100;
            tax += _tax;
            owed += _owed - _tax;
        }

        if (tax != 0) {
            _addVampireTax(lairRef, tax);
        }

        for (uint16 i = 0; i < vampires.length; i++) {
            owed += lairRef.claimBloodBags(sender, vampires[i]);
        }

        bloodbag.mint(sender, owed);
    }

    /// ==== Human Controls

    function _stakeHuman(
        IVampireGameERC721 vgameRef,
        IBloodFarm bloodfarmRef,
        address sender,
        uint16 tokenId
    ) private {
        bloodfarmRef.stakeHuman(sender, tokenId);
        vgameRef.transferFrom(sender, address(bloodfarmRef), tokenId);
    }

    function _requestToUnstakeHuman(
        IBloodFarm bloodfarmRef,
        address sender,
        uint16 tokenId
    ) private {
        bloodfarmRef.requestToUnstakeHuman(sender, tokenId);
        random.submitHash(sender, tokenId);
    }

    function _unstakeHuman(
        IVampireGameERC721 vgameRef,
        IBloodFarm bloodfarmRef,
        address sender,
        uint16 tokenId
    ) private returns (uint256 owed, uint256 tax) {
        require(!_isVampire(vgameRef, tokenId), "NOT_HUMAN");
        uint256 _owed = bloodfarmRef.unstakeHuman(sender, tokenId);

        // Check if stolen
        if (random.getRandomNumber(tokenId) & 1 == 1) {
            tax += _owed;
        } else {
            tax += (_owed * BLOOD_CLAIM_TAX_PERCENTAGE) / 100;
            owed += (_owed * (100 - BLOOD_CLAIM_TAX_PERCENTAGE)) / 100;
        }

        vgameRef.transferFrom(address(bloodfarmRef), sender, tokenId);
    }

    /// ==== Vampire Controls

    /// @dev Stake one vapmire
    /// - Calls Lair to update staking state (stake)
    /// - Transfer the NFT from sender to the Lair
    ///
    /// - Ownership only checked here
    function _stakeVampire(
        IVampireGameERC721 vgameRef,
        ILair lairRef,
        address sender,
        uint16 tokenId
    ) private {
        require(vgameRef.ownerOf(tokenId) == sender, "NOT_VAMPIRE_OWNER");
        lairRef.stakeVampire(sender, tokenId);
        vgameRef.transferFrom(sender, address(lairRef), tokenId);
    }

    /// @dev Unstake one vampire
    ///
    /// - Calls Lair to update staking state (unstake)
    /// - Transfer the NFT from Lair to sender
    ///
    /// - Ownership is checked in Lair
    function _unstakeVampire(
        IVampireGameERC721 vgameRef,
        ILair lairRef,
        address sender,
        uint16 tokenId
    ) private returns (uint256 owed) {
        require(_isVampire(vgameRef, tokenId), "NOT_VAMPIRE");
        owed += lairRef.unstakeVampire(sender, tokenId);
        vgameRef.transferFrom(address(lairRef), sender, tokenId);
    }

    /// ==== Helpers

    function _addVampireTax(ILair lairRef, uint256 amount) private {
        uint256 totalPredatorScoreStaked = lairRef
            .getTotalPredatorScoreStaked();
        uint256 _unaccountedRewards = unaccountedRewards;

        if (totalPredatorScoreStaked == 0) {
            _unaccountedRewards += amount;
            return;
        }

        lairRef.addTaxToVampires(amount, _unaccountedRewards);
        unaccountedRewards = 0;
    }

    function _isVampire(IVampireGameERC721 vgameRef, uint16 tokenId)
        private
        view
        returns (bool)
    {
        return vgameRef.isTokenVampire(tokenId);
    }

    /// ==== pause/unpause

    function upause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    /// ==== Update Parts

    function setVgame(address _vgame) external onlyOwner {
        vgame = IVampireGameERC721(_vgame);
    }

    function setBloodBag(address _bloodbag) external onlyOwner {
        bloodbag = IBLOODBAG(_bloodbag);
    }

    function setLair(address _lair) external onlyOwner {
        lair = ILair(_lair);
    }

    function setBloodFarm(address _bloodfarm) external onlyOwner {
        bloodfarm = IBloodFarm(_bloodfarm);
    }

    function setRandom(address _random) external onlyOwner {
        random = IRandom(_random);
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

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/// @notice functions that can be called by a game controller
interface IBLOODBAG {
    /// @notice make a $BLOODBAG transfusion from the gods to a specified address
    /// @param to the addres getting the $BLOODBAG
    /// @param amount the amount of $BLOODBAG to mint
    function mint(address to, uint256 amount) external;

    /// @notice flush some $BLOODBAG down the toilet (burn)
    /// @param from the holder of the $BLOODBAG
    /// @param amount the amount of $BLOODBAG to burn
    function burn(address from, uint256 amount) external;
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

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IRandom.sol";

contract Random is IRandom, Ownable {
    mapping(uint256 => bytes32) private hashes;
    mapping(uint256 => uint256) private nonces;

    mapping(address => bool) public controllers;

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS_ALLOWED");
        _;
    }

    constructor() {}

    function submitHash(address sender, uint256 tokenId)
        external
        override
        onlyControllers
    {
        require(hashes[tokenId].length == 0, "ALREADY_SUBMITED");
        bytes32 newHash = keccak256(
            abi.encodePacked(
                sender,
                tokenId,
                nonces[tokenId],
                "bb",
                gasleft(),
                blockhash(block.number - 1),
                block.timestamp
            )
        );
        hashes[tokenId] = newHash;
        nonces[tokenId] += 1;
    }

    function getRandomNumber(uint256 tokenId)
        external
        override
        onlyControllers
        returns (uint256)
    {
        bytes32 _hash = hashes[tokenId];
        require(_hash.length > 0, "NO_HASH");
        delete hashes[tokenId];
        return uint256(_hash);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IVampireGame.sol";

/// @notice Interface composed by IVampireGame + IERC721
interface IVampireGameERC721 is IVampireGame, IERC721 {}

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

interface IRandom {
  function submitHash(address sender, uint256 tokenId) external;
  function getRandomNumber(uint256 tokenId) external returns (uint256);
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