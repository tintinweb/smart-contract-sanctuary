//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/DPSStructs.sol";
import "./interfaces/DPSInterfaces.sol";

contract DPSDocks is ERC721Holder, ERC1155Holder, ReentrancyGuard, Ownable {
    DPSVoyageI public voyage;
    DPSRandomI public causality;
    IERC721 public dps;
    DPSPirateFeaturesI public dpsFeatures;
    DPSFlagshipI public flagship;
    DPSSupportShipI public supportShip;
    IERC1155 public artifact;
    DPSCartographerI public cartographer;
    DPSGameSettingsI public gameSettings;
    MintableBurnableIERC1155 public chest;

    /**
     * @notice list of voyages started by wallet
     */
    mapping(address => mapping(uint256 => LockedVoyage)) private lockedVoyages;

    /**
     * @notice list of voyages finished by wallet
     */
    mapping(address => mapping(uint256 => LockedVoyage)) private finishedVoyages;

    /**
     * @notice list of voyages ids started by wallet
     */
    mapping(address => uint256[]) private lockedVoyagesIds;

    /**
     * @notice list of voyages ids finished by wallet
     */
    mapping(address => uint256[]) private finishedVoyagesIds;

    /**
     * @notice finished voyages results voyageId=>results
     */
    mapping(uint256 => VoyageResult) public voyageResults;

    /**
     * @notice list of locked voyages and their owners id => wallet
     */
    mapping(uint256 => address) public ownerOfLockedVoyages;

    event LockVoyage(
        uint256 indexed _voyageId,
        uint256 indexed _dpsId,
        uint256 indexed _flagshipId,
        uint8[9] _supportShipIds,
        ARTIFACT_TYPE _artifactId,
        uint256 _lockedAt
    );

    event ClaimVoyageRewards(
        uint256 indexed _voyageId,
        uint16 _noOfChests,
        uint8[9] _destroyedSupportships,
        uint16 _healthDamage,
        uint16[] _interactionRNGs,
        uint8[] _interactionResults,
        uint256 _claimedAt
    );

    event SetContract(uint256 _target, address _contract);

    event TokenRecovered(address indexed _token, bytes _data);

    error Unhealthy();

    constructor() {}

    /**
     * @notice Locking a voyage
     * @param _causalityParams causality parameters
     * @param _lockedVoyages array of objects that contains:
     * - voyageId
     * - dpsId (Pirate)
     * - flagshipId
     * - supportShips - list of support ships ids, an array of 9 corresponding with the support ship types, 
                        a value at a certain position means a support ship sent to sail
     * - totalSupportShips
     * - artifactId
     * the rest of the params are ignored
     */
    function lockVoyageItems(LockedVoyage[] calldata _lockedVoyages, CausalityParams[] calldata _causalityParams)
        external
        nonReentrant
    {
        if (gameSettings.isPaused(4) == 1) revert Paused();

        // wrong causality params
        if (_lockedVoyages.length != _causalityParams.length) revert WrongParams(1);

        for (uint256 index; index < _lockedVoyages.length; index++) {
            LockedVoyage memory lockedVoyage = _lockedVoyages[index];
            CausalityParams memory params = _causalityParams[index];

            // if flagship is unhealthy
            if (flagship.getPartsLevel(lockedVoyage.flagshipId)[uint256(FLAGSHIP_PART.HEALTH)] != 100) revert Unhealthy();

            // if it is already started
            if (lockedVoyages[msg.sender][lockedVoyage.voyageId].voyageId != 0) revert WrongState(1);

            // if it is already finished
            if (finishedVoyages[msg.sender][lockedVoyage.voyageId].voyageId != 0) revert WrongState(2);

            VoyageConfig memory voyageConfig = cartographer.viewVoyageConfiguration(params, lockedVoyage.voyageId);

            uint256 totalSupportShips;
            for (uint256 i; i < lockedVoyage.supportShips.length; i++) {
                totalSupportShips += lockedVoyage.supportShips[i];
            }

            // too many support ships
            if (
                totalSupportShips > gameSettings.getMaxSupportShipsPerVoyageType(voyageConfig.typeOfVoyage) ||
                totalSupportShips != lockedVoyage.totalSupportShips
            ) revert WrongState(3);

            // causality params are wrong based on the block number
            if (block.number <= voyageConfig.boughtAt + voyageConfig.noOfBlockJumps) revert WrongState(4);

            lockedVoyage.lockedBlock = block.number;
            lockedVoyage.lockedTimestamp = block.timestamp;
            lockedVoyage.claimedTime = 0;
            lockedVoyage.navigation = 0;
            lockedVoyage.luck = 0;
            lockedVoyage.strength = 0;
            lockedVoyage.sequence = voyageConfig.sequence;
            lockedVoyage.totalSupportShips = uint8(totalSupportShips);
            lockedVoyage.voyageType = voyageConfig.typeOfVoyage;
            lockedVoyages[msg.sender][lockedVoyage.voyageId] = lockedVoyage;
            lockedVoyagesIds[msg.sender].push(lockedVoyage.voyageId);
            ownerOfLockedVoyages[lockedVoyage.voyageId] = msg.sender;

            dps.safeTransferFrom(msg.sender, address(this), lockedVoyage.dpsId);
            flagship.safeTransferFrom(msg.sender, address(this), lockedVoyage.flagshipId);

            unchecked {
                for (uint256 i; i < lockedVoyage.supportShips.length; i++) {
                    if (lockedVoyage.supportShips[i] > 0) {
                        supportShip.safeTransferFrom(msg.sender, address(this), i, lockedVoyage.supportShips[i], "");
                    }
                }
            }
            if (lockedVoyage.artifactId != ARTIFACT_TYPE.NONE) {
                artifact.safeTransferFrom(msg.sender, address(this), uint256(lockedVoyage.artifactId), 1, "");
            }

            voyage.safeTransferFrom(msg.sender, address(this), lockedVoyage.voyageId);

            emit LockVoyage(
                lockedVoyage.voyageId,
                lockedVoyage.dpsId,
                lockedVoyage.flagshipId,
                lockedVoyage.supportShips,
                lockedVoyage.artifactId,
                block.timestamp
            );
        }
    }

    /**
     * @notice Claiming rewards with params retrieved from the random future blocks
     * @param _voyageIds - ids of the voyages
     * @param _causalityParams - list of parameters used to generated random outcomes
     */
    function claimRewards(uint256[] calldata _voyageIds, CausalityParams[] calldata _causalityParams) external nonReentrant {
        if (gameSettings.isPaused(5) == 1) revert Paused();

        // params not ok
        if (_voyageIds.length != _causalityParams.length) revert WrongParams(2);

        for (uint256 i; i < _voyageIds.length; i++) {
            uint256 voyageId = _voyageIds[i];

            // we get the owner of the voyage it be different than buyer in case nft sold on marketplaces
            address owner = ownerOfLockedVoyages[voyageId];

            LockedVoyage storage lockedVoyage = lockedVoyages[owner][voyageId];
            VoyageConfig memory voyageConfig = voyage.getVoyageConfig(voyageId);
            voyageConfig.sequence = lockedVoyage.sequence;

            // not the owner
            if (owner == address(0)) revert AddressZero();

            // if causality params are wrong, like no of interactions * gap between interactions + locked timestamp > current timestamp
            if (
                lockedVoyage.lockedTimestamp + voyageConfig.noOfInteractions * voyageConfig.gapBetweenInteractions >
                block.timestamp
            ) revert WrongState(4);

            // blocks not passed correctly
            if (block.number <= lockedVoyage.lockedBlock + voyageConfig.noOfInteractions * voyageConfig.noOfBlockJumps)
                revert WrongState(5);

            causality.checkCausalityParams(_causalityParams[i], voyageConfig, lockedVoyage);

            VoyageResult memory voyageResult = computeVoyageState(
                lockedVoyage,
                voyageConfig.sequence,
                voyageConfig.buyer,
                _causalityParams[i]
            );
            lockedVoyage.claimedTime = block.timestamp;
            finishedVoyages[owner][lockedVoyage.voyageId] = lockedVoyage;
            finishedVoyagesIds[owner].push(lockedVoyage.voyageId);
            voyageResults[voyageId] = voyageResult;

            LockedVoyage memory cached = lockedVoyage;

            //TODO not sure if this should be afterwards. need to check
            cleanLockedVoyage(lockedVoyage.voyageId, owner);

            awardRewards(voyageResult, voyageConfig.typeOfVoyage, cached, owner);

            emit ClaimVoyageRewards(
                voyageId,
                voyageResult.awardedChests,
                voyageResult.destroyedSupportShips,
                voyageResult.healthDamage,
                voyageResult.interactionRNGs,
                voyageResult.interactionResults,
                block.timestamp
            );
        }
    }

    /**
     * @notice checking voyage state between start start and finish sail, it uses causality parameters to determine the outcome of interactions
     * @param _voyageId - id of the voyage
     * @param _causalityParams - list of parameters used to generated random outcomes, it can be an incomplete list, meaning that you can check mid-sail to determine outcomes
     */
    function checkVoyageState(uint256 _voyageId, CausalityParams calldata _causalityParams)
        external
        view
        returns (VoyageResult memory voyageResult)
    {
        LockedVoyage storage lockedVoyage = lockedVoyages[ownerOfLockedVoyages[_voyageId]][_voyageId];

        // not started
        if (voyage.ownerOf(_voyageId) != address(this) || lockedVoyage.voyageId == 0) revert WrongState(1);

        VoyageConfig memory voyageConfig = voyage.getVoyageConfig(_voyageId);
        voyageConfig.sequence = lockedVoyage.sequence;

        // not started
        if ((block.timestamp - lockedVoyage.lockedTimestamp) <= voyageConfig.gapBetweenInteractions) revert WrongState(1);

        uint256 interactions = (block.timestamp - lockedVoyage.lockedTimestamp) / voyageConfig.gapBetweenInteractions;
        if (interactions > voyageConfig.sequence.length) interactions = voyageConfig.sequence.length;
        uint256 length = voyageConfig.sequence.length;
        for (uint256 i; i < length - interactions; i++) {
            voyageConfig.sequence[length - i - 1] = 0;
        }
        return computeVoyageState(lockedVoyage, voyageConfig.sequence, voyageConfig.buyer, _causalityParams);
    }

    /**
     * @notice computing voyage state based on the locked voyage skills and config and causality params
     * @param _lockedVoyage - locked voyage items
     * @param _sequence - sequence of interactions
     * @param _buyer - initial buyer used for randomenss
     * @param _causalityParams - list of parameters used to generated random outcomes, it can be an incomplete list, meaning that you can check mid-sail to determine outcomes
     * @return VoyageResult - containing the results of a voyage based on interactions
     */
    function computeVoyageState(
        LockedVoyage storage _lockedVoyage,
        uint8[] memory _sequence,
        address _buyer,
        CausalityParams calldata _causalityParams
    ) internal view returns (VoyageResult memory) {
        VoyageStatusCache memory claimingRewardsCache;
        (, uint16[3] memory features) = dpsFeatures.getTraitsAndSkills(uint16(_lockedVoyage.dpsId));

        // traits not set
        if (features[0] == 0 || features[1] == 0 || features[2] == 0) revert WrongState(6);

        unchecked {
            claimingRewardsCache.luck += features[0];
            claimingRewardsCache.navigation += features[1];
            claimingRewardsCache.strength += features[2];
            claimingRewardsCache = gameSettings.computeFlagShipSkills(
                flagship.getPartsLevel(_lockedVoyage.flagshipId),
                claimingRewardsCache
            );
            claimingRewardsCache = gameSettings.computeSupportSkills(
                _lockedVoyage.supportShips,
                _lockedVoyage.artifactId,
                claimingRewardsCache
            );

            VoyageResult memory voyageResult;
            uint256 maxRollCap = gameSettings.maxRollCap();
            voyageResult.interactionResults = new uint8[](_sequence.length);
            voyageResult.interactionRNGs = new uint16[](_sequence.length);

            claimingRewardsCache = gameSettings.debuffVoyage(_lockedVoyage.voyageType, claimingRewardsCache);

            for (uint256 i; i < _sequence.length; i++) {
                INTERACTION interaction = INTERACTION(_sequence[i]);
                if (interaction == INTERACTION.NONE || voyageResult.healthDamage == 100) {
                    voyageResult.skippedInteractions++;
                    continue;
                }
                // string memory entropy = string(abi.encodePacked());
                claimingRewardsCache.entropy = string(
                    abi.encodePacked("INTERACTION_RESULT_", i, "_", _lockedVoyage.voyageId)
                );
                uint256 result = causality.getRandom(
                    _buyer,
                    _causalityParams.blockNumber[i],
                    _causalityParams.hash1[i],
                    _causalityParams.hash2[i],
                    _causalityParams.timestamp[i],
                    _causalityParams.signature[i],
                    claimingRewardsCache.entropy,
                    0,
                    maxRollCap
                );
                (voyageResult, claimingRewardsCache) = gameSettings.interpretResults(
                    result,
                    voyageResult,
                    _lockedVoyage,
                    claimingRewardsCache,
                    interaction,
                    _causalityParams,
                    i
                );
                voyageResult.interactionRNGs[i] = uint16(result);
            }
            return voyageResult;
        }
    }

    /**
     * @notice awards the voyage (if any) and transfers back the assets that were locked into the voyage
     *         to the owners, also if support ship destroyed, it burns them, if healh damage taken then apply effect on flagship
     * @param _voyageResult - the result of the voyage that is used to award and apply effects
     * @param _typeOfVoyage - used to mint the chests types accordingly with the voyage type
     * @param _lockedVoyage - locked voyage object used to get the locked items that needs to be transferred back
     * @param _owner - the owner of the voyage that will receive rewards + items back
     *
     */
    function awardRewards(
        VoyageResult memory _voyageResult,
        VOYAGE_TYPE _typeOfVoyage,
        LockedVoyage memory _lockedVoyage,
        address _owner
    ) internal {
        chest.mint(_owner, uint256(_typeOfVoyage), _voyageResult.awardedChests);
        dps.safeTransferFrom(address(this), _owner, _lockedVoyage.dpsId);

        if (_voyageResult.healthDamage > 0)
            flagship.upgradePart(FLAGSHIP_PART.HEALTH, _lockedVoyage.flagshipId, 100 - _voyageResult.healthDamage);
        flagship.safeTransferFrom(address(this), _owner, _lockedVoyage.flagshipId);
        for (uint256 i; i < 9; i++) {
            if (_voyageResult.destroyedSupportShips[i] > 0) {
                supportShip.burn(address(this), i, _voyageResult.destroyedSupportShips[i]);
            }
            if (_lockedVoyage.supportShips[i] > _voyageResult.destroyedSupportShips[i])
                supportShip.safeTransferFrom(
                    address(this),
                    _owner,
                    i,
                    _lockedVoyage.supportShips[i] - _voyageResult.destroyedSupportShips[i],
                    ""
                );
        }
        if (_lockedVoyage.artifactId != ARTIFACT_TYPE.NONE)
            artifact.safeTransferFrom(address(this), _owner, uint256(_lockedVoyage.artifactId), 1, "");
        voyage.burn(_lockedVoyage.voyageId);
    }

    /**
     * @notice cleans a locked voyage, usually once it's finished
     * @param _voyageId - voyage id
     * @param _owner  - owner of the voyage
     */
    function cleanLockedVoyage(uint256 _voyageId, address _owner) internal {
        uint256[] storage voyagesForOwner = lockedVoyagesIds[_owner];
        for (uint256 i; i < voyagesForOwner.length; i++) {
            if (voyagesForOwner[i] == _voyageId) {
                voyagesForOwner[i] = voyagesForOwner[voyagesForOwner.length - 1];
                voyagesForOwner.pop();
            }
        }
        delete ownerOfLockedVoyages[_voyageId];
        delete lockedVoyages[_owner][_voyageId];
    }

    function onERC721Received(
        address _operator,
        address,
        uint256,
        bytes calldata
    ) public view override returns (bytes4) {
        if (_operator != address(this)) revert Unauthorized();
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address _operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public view override returns (bytes4) {
        if (_operator != address(this)) revert Unauthorized();
        return this.onERC1155Received.selector;
    }

    /**
     * @notice used to recover tokens using call. This will be used so we can save some contract sizes
     * @param _token the token address
     * @param _data encoded with abi.encodeWithSignature(signatureString, arg); of transferFrom, transfer methods
     */
    function recoverToken(address _token, bytes calldata _data) external onlyOwner {
        (bool success, ) = _token.call{value: 0}(_data);
        if (!success) revert NotEnoughTokens();
        emit TokenRecovered(_token, _data);
    }

    function cleanVoyageResults(uint256 _voyageId) external onlyOwner {
        delete voyageResults[_voyageId];
    }

    /**
     * SETTERS & GETTERS
     */
    function setContract(address _contract, uint8 _target) external onlyOwner {
        if (_contract == address(0)) revert AddressZero();
        if (_target == 1) voyage = DPSVoyageI(_contract);
        else if (_target == 2) causality = DPSRandomI(_contract);
        else if (_target == 3) dps = IERC721(_contract);
        else if (_target == 4) flagship = DPSFlagshipI(_contract);
        else if (_target == 5) supportShip = DPSSupportShipI(_contract);
        else if (_target == 6) artifact = IERC1155(_contract);
        else if (_target == 7) gameSettings = DPSGameSettingsI(_contract);
        else if (_target == 8) dpsFeatures = DPSPirateFeaturesI(_contract);
        else if (_target == 9) cartographer = DPSCartographerI(_contract);
        else if (_target == 10) chest = MintableBurnableIERC1155(_contract);
        emit SetContract(_target, _contract);
    }

    function getLockedVoyagesForOwner(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) external view returns (LockedVoyage[] memory locked) {
        unchecked {
            uint256 length = lockedVoyagesIds[_owner].length;
            if (_stop > length) _stop = length;
            locked = new LockedVoyage[](length);
            for (uint256 i = _start; i < _stop; i++) {
                locked[i - _start] = lockedVoyages[_owner][lockedVoyagesIds[_owner][i]];
            }
        }
    }

    function getLockedVoyageByOwnerAndId(address _owner, uint256 _voyageId)
        external
        view
        returns (LockedVoyage memory locked)
    {
        for (uint256 i; i < lockedVoyagesIds[_owner].length; i++) {
            uint256 tempId = lockedVoyagesIds[_owner][i];
            if (tempId == _voyageId) return lockedVoyages[_owner][tempId];
        }
    }

    function getFinishedVoyagesForOwner(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) external view returns (LockedVoyage[] memory finished) {
        unchecked {
            uint256 length = finishedVoyagesIds[_owner].length;
            if (_stop > length) _stop = length;
            finished = new LockedVoyage[](length);
            for (uint256 i = _start; i < _stop; i++) {
                finished[i - _start] = finishedVoyages[_owner][finishedVoyagesIds[_owner][i]];
            }
        }
    }

    function getFinishedVoyageByOwnerAndId(address _owner, uint256 _voyageId)
        external
        view
        returns (LockedVoyage memory finished)
    {
        for (uint256 i; i < finishedVoyagesIds[_owner].length; i++) {
            uint256 tempId = finishedVoyagesIds[_owner][i];
            if (tempId == _voyageId) return finishedVoyages[_owner][tempId];
        }
    }

    function voyagesLength(address _owner, bool _locked) external view returns (uint256) {
        if (_locked) return lockedVoyagesIds[_owner].length;
        return finishedVoyagesIds[_owner].length;
    }

    function getLastComputedState(uint256 _voyageId) external view returns (VoyageResult memory) {
        return voyageResults[_voyageId];
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum VOYAGE_TYPE {
    EASY,
    MEDIUM,
    HARD,
    LEGENDARY
}

enum SUPPORT_SHIP_TYPE {
    SLOOP_STRENGTH,
    SLOOP_LUCK,
    SLOOP_NAVIGATION,
    CARAVEL_STRENGTH,
    CARAVEL_LUCK,
    CARAVEL_NAVIGATION,
    GALLEON_STRENGTH,
    GALLEON_LUCK,
    GALLEON_NAVIGATION
}

enum ARTIFACT_TYPE {
    NONE,
    COMMON_STRENGTH,
    COMMON_LUCK,
    COMMON_NAVIGATION,
    RARE_STRENGTH,
    RARE_LUCK,
    RARE_NAVIGATION,
    EPIC_STRENGTH,
    EPIC_LUCK,
    EPIC_NAVIGATION,
    LEGENDARY_STRENGTH,
    LEGENDARY_LUCK,
    LEGENDARY_NAVIGATION
}

enum INTERACTION {
    NONE,
    CHEST,
    STORM,
    ENEMY
}

enum FLAGSHIP_PART {
    HEALTH,
    CANNON,
    HULL,
    SAILS,
    HELM,
    FLAG,
    FIGUREHEAD
}

enum SKILL_TYPE {
    LUCK,
    STRENGTH,
    NAVIGATION
}

struct VoyageConfig {
    VOYAGE_TYPE typeOfVoyage;
    uint8 noOfInteractions;
    uint16 noOfBlockJumps;
    // 1 - Chest 2 - Storm 3 - Enemy
    uint8[] sequence;
    uint256 boughtAt;
    uint256 gapBetweenInteractions;
    address buyer;
}

struct CartographerConfig {
    uint8 minNoOfChests;
    uint8 maxNoOfChests;
    uint8 minNoOfStorms;
    uint8 maxNoOfStorms;
    uint8 minNoOfEnemies;
    uint8 maxNoOfEnemies;
    uint8 totalInteractions;
    uint256 gapBetweenInteractions;
}

struct RandomInteractions {
    uint256 randomNoOfChests;
    uint256 randomNoOfStorms;
    uint256 randomNoOfEnemies;
    uint8 generatedChests;
    uint8 generatedStorms;
    uint8 generatedEnemies;
    uint256[] positionsForGeneratingInteractions;
}

struct CausalityParams {
    uint256[] blockNumber;
    bytes32[] hash1;
    bytes32[] hash2;
    uint256[] timestamp;
    bytes[] signature;
}

struct LockedVoyage {
    uint8 totalSupportShips;
    VOYAGE_TYPE voyageType;
    ARTIFACT_TYPE artifactId;
    uint8[9] supportShips; //this should be an array for each type, expressing the quantities he took on a trip
    uint8[] sequence;
    uint16 navigation;
    uint16 luck;
    uint16 strength;
    uint256 voyageId;
    uint256 dpsId;
    uint256 flagshipId;
    uint256 lockedBlock;
    uint256 lockedTimestamp;
    uint256 claimedTime;
}

struct VoyageResult {
    uint16 awardedChests;
    uint8[9] destroyedSupportShips;
    uint8 totalSupportShipsDestroyed;
    uint8 healthDamage;
    uint16 skippedInteractions;
    uint16[] interactionRNGs;
    uint8[] interactionResults;
}

struct VoyageStatusCache {
    uint256 strength;
    uint256 luck;
    uint256 navigation;
    string entropy;
}

error AddressZero();
error Paused();
error WrongParams(uint256 _location);
error WrongState(uint256 _state);
error Unauthorized();
error NotEnoughTokens();

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./DPSStructs.sol";

interface DPSVoyageI is IERC721Enumerable {
    function mint(
        address _owner,
        uint256 _tokenId,
        VoyageConfig calldata config
    ) external;

    function burn(uint256 _tokenId) external;

    function getVoyageConfig(uint256 _voyageId) external view returns (VoyageConfig memory config);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function maxMintedId() external view returns (uint256);
}

interface DPSRandomI {
    function getRandomBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        bytes[] calldata _signature,
        string[] calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256[] memory randoms);

    function getRandomUnverifiedBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        string[] calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256[] memory randoms);

    function getRandom(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        bytes calldata _signature,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256 randoms);

    function getRandomUnverified(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256 randoms);

    function checkCausalityParams(
        CausalityParams calldata _causalityParams,
        VoyageConfig calldata _voyageConfig,
        LockedVoyage calldata _lockedVoyage
    ) external pure;
}

interface DPSGameSettingsI {
    function getVoyageConfig(VOYAGE_TYPE _type) external view returns (CartographerConfig memory);

    function maxSkillsCap() external view returns (uint16);

    function maxRollCap() external view returns (uint16);

    function flagshipBaseSkills() external view returns (uint16);

    function maxOpenLockBoxes() external view returns (uint256);

    function blockJumps() external view returns (uint16);

    function getSkillsPerFlagshipParts() external view returns (uint16[7] memory skills);

    function getSkillTypeOfEachFlagshipPart() external view returns (uint8[7] memory skillTypes);

    function getTMAPPerVoyageType(VOYAGE_TYPE _type) external view returns (uint256);

    function gapBetweenVoyagesCreation() external view returns (uint256);

    function isPaused(uint8 _component) external view returns (uint8);

    function tmapPerDoubloon() external view returns (uint256);

    function repairFlagshipCost() external view returns (uint256);

    function doubloonPerUpgradePart() external view returns (uint256);

    function getChestDoubloonRewards(VOYAGE_TYPE _type) external view returns (uint256);

    function computeFlagShipSkills(uint8[7] calldata levels, VoyageStatusCache memory _claimingRewardsCache)
        external
        view
        returns (VoyageStatusCache memory);

    function computeSupportSkills(
        uint8[9] calldata _supportShips,
        ARTIFACT_TYPE _type,
        VoyageStatusCache memory _claimingRewardsCache
    ) external view returns (VoyageStatusCache memory);

    function getDoubloonsPerSupportShipType(SUPPORT_SHIP_TYPE _type) external view returns (uint256);

    function getSupportShipsSkillBoosts(SUPPORT_SHIP_TYPE _type) external view returns (uint16);

    function getMaxSupportShipsPerVoyageType(VOYAGE_TYPE _type) external view returns (uint8);

    function getMaxRollPerChest(VOYAGE_TYPE _type) external view returns (uint256);

    function maxRollCapLockBoxes() external view returns (uint16);

    function getLockBoxesDistribution(ARTIFACT_TYPE _type) external view returns (uint16[2] memory);

    function getVoyageDebuffs(VOYAGE_TYPE _type) external view returns (uint16);

    function debuffVoyage(VOYAGE_TYPE _voyageType, VoyageStatusCache memory _claimingRewardsCache)
        external
        view
        returns (VoyageStatusCache memory);

    function interpretResults(
        uint256 _result,
        VoyageResult memory _voyageResult,
        LockedVoyage calldata _lockedVoyage,
        VoyageStatusCache memory _claimingRewardsCache,
        INTERACTION _interaction,
        CausalityParams calldata _causalityParams,
        uint256 _index
    ) external view returns (VoyageResult memory, VoyageStatusCache memory);

    function getArtifactSkillBoosts(ARTIFACT_TYPE _type) external view returns (uint16);
}

interface DPSPirateFeaturesI {
    function getTraitsAndSkills(uint16 _dpsId) external view returns (string[8] memory, uint16[3] memory);
}

interface DPSSupportShipI is IERC1155 {
    function burn(
        address _from,
        uint256 _type,
        uint256 _amount
    ) external;

    function mint(
        address _owner,
        uint256 _type,
        uint256 _amount
    ) external;
}

interface DPSFlagshipI is IERC721 {
    function mint(address _owner, uint256 _id) external;

    function burn(uint256 _id) external;

    function upgradePart(
        FLAGSHIP_PART _trait,
        uint256 _tokenId,
        uint8 _level
    ) external;

    function getPartsLevel(uint256 _flagshipId) external view returns (uint8[7] memory);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);
}

interface DPSCartographerI {
    function viewVoyageConfiguration(CausalityParams calldata causalityParams, uint256 _voyageId)
        external
        view
        returns (VoyageConfig memory voyageConfig);
}

interface MintableBurnableIERC1155 is IERC1155 {
    function mint(
        address _to,
        uint256 _type,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _type,
        uint256 _amount
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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