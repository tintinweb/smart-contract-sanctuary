//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-0.8/utils/Context.sol";
import "../catalyst/GemsCatalystsRegistry.sol";
import "../common/BaseWithStorage/WithAdmin.sol";
import "../common/BaseWithStorage/WithMinter.sol";
import "../common/BaseWithStorage/WithUpgrader.sol";

/// @notice Allows setting the gems and catalysts of an asset
contract AssetAttributesRegistry is WithMinter, WithUpgrader, IAssetAttributesRegistry, Context {
    uint256 internal constant MAX_NUM_GEMS = 15;
    uint256 private constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    uint256 private constant NOT_IS_NFT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;
    uint256 private constant NOT_NFT_INDEX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000007FFFFFFFFFFFFFFF;

    GemsCatalystsRegistry internal immutable _gemsCatalystsRegistry;
    mapping(uint256 => Record) internal _records;

    // used to allow migration to specify blockNumber when setting catalyst/gems
    address public migrationContract;
    // used to to set catalyst without burning actual ERC20 (cross layer deposit)
    address public overLayerDepositor;

    struct Record {
        uint16 catalystId; // start at 1
        uint16[MAX_NUM_GEMS] gemIds;
    }

    event CatalystApplied(uint256 indexed assetId, uint16 indexed catalystId, uint16[] gemIds, uint64 blockNumber);
    event GemsAdded(uint256 indexed assetId, uint16[] gemIds, uint64 blockNumber);

    /// @notice AssetAttributesRegistry depends on
    /// @param gemsCatalystsRegistry: GemsCatalystsRegistry for fetching attributes
    /// @param admin: for setting the migration contract address
    /// @param minter: allowed to set gems and catalysts for a given asset
    constructor(
        GemsCatalystsRegistry gemsCatalystsRegistry,
        address admin,
        address minter,
        address upgrader
    ) {
        _gemsCatalystsRegistry = gemsCatalystsRegistry;
        _admin = admin;
        _minter = minter;
        _upgrader = upgrader;
    }

    function getCatalystRegistry() external view override returns (address) {
        return address(_gemsCatalystsRegistry);
    }

    /// @notice get the record data (catalyst id, gems ids list) for an asset id
    /// @param assetId id of the asset
    function getRecord(uint256 assetId)
        external
        view
        override
        returns (
            bool exists,
            uint16 catalystId,
            uint16[] memory gemIds
        )
    {
        catalystId = _records[assetId].catalystId;
        if (catalystId == 0 && assetId & IS_NFT != 0) {
            // fallback on collection catalyst
            assetId = _getCollectionId(assetId);
            catalystId = _records[assetId].catalystId;
        }
        uint16[MAX_NUM_GEMS] memory fixedGemIds = _records[assetId].gemIds;
        exists = catalystId != 0;
        gemIds = new uint16[](MAX_NUM_GEMS);
        uint8 i = 0;
        while (fixedGemIds[i] != 0) {
            gemIds[i] = (fixedGemIds[i]);
            i++;
        }
    }

    /// @notice getAttributes
    /// @param assetId id of the asset
    /// @return values The array of values(256) requested.
    function getAttributes(uint256 assetId, GemEvent[] calldata events)
        external
        view
        override
        returns (uint32[] memory values)
    {
        return _gemsCatalystsRegistry.getAttributes(_records[assetId].catalystId, assetId, events);
    }

    /// @notice sets the catalyst and gems when an asset goes over layers
    /// @param assetId id of the asset
    /// @param catalystId id of the catalyst to set
    /// @param gemIds list of gems ids to set
    function setCatalystWhenDepositOnOtherLayer(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external override {
        require(
            _msgSender() == overLayerDepositor || _msgSender() == _admin,
            "AssetAttributesRegistry: not overLayerDepositor"
        );
        // We have to ignore all 0 gemid in case of L2 to L1 deposit
        // In this case we get gems data in a form of an array of MAX_NUM_GEMS padded with 0
        if (gemIds.length == MAX_NUM_GEMS) {
            uint256 firstZeroIndex;
            for (firstZeroIndex = 0; firstZeroIndex < gemIds.length; firstZeroIndex++) {
                if (gemIds[firstZeroIndex] == 0) {
                    break;
                }
            }
            uint16[] memory gemIdsWithoutZero = new uint16[](firstZeroIndex);
            // find first 0
            for (uint256 i = 0; i < firstZeroIndex; i++) {
                gemIdsWithoutZero[i] = gemIds[i];
            }
            _setCatalyst(assetId, catalystId, gemIdsWithoutZero, _getBlockNumber(), false);
        } else {
            _setCatalyst(assetId, catalystId, gemIds, _getBlockNumber(), false);
        }
    }

    /// @notice sets the catalyst and gems for an asset, minter only
    /// @param assetId id of the asset
    /// @param catalystId id of the catalyst to set
    /// @param gemIds list of gems ids to set
    function setCatalyst(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external virtual override {
        require(_msgSender() == _minter || _msgSender() == _upgrader, "NOT_AUTHORIZED_MINTER");
        _setCatalyst(assetId, catalystId, gemIds, _getBlockNumber(), true);
    }

    /// @notice sets the catalyst and gems for an asset for a given block number, migration contract only
    /// @param assetId id of the asset
    /// @param catalystId id of the catalyst to set
    /// @param gemIds list of gems ids to set
    /// @param blockNumber block number
    function setCatalystWithBlockNumber(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint64 blockNumber
    ) external override {
        require(_msgSender() == migrationContract, "NOT_AUTHORIZED_MIGRATION");
        _setCatalyst(assetId, catalystId, gemIds, blockNumber, true);
    }

    /// @notice adds gems to an existing list of gems of an asset, upgrader only
    /// @param assetId id of the asset
    /// @param gemIds list of gems ids to set
    function addGems(uint256 assetId, uint16[] calldata gemIds) external virtual override {
        require(_msgSender() == _upgrader, "NOT_AUTHORIZED_UPGRADER");
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT");
        require(gemIds.length != 0, "INVALID_GEMS_0");

        uint16 catalystId = _records[assetId].catalystId;
        uint16[MAX_NUM_GEMS] memory gemIdsToStore;
        if (catalystId == 0) {
            // fallback on collection catalyst
            uint256 collectionId = _getCollectionId(assetId);
            catalystId = _records[collectionId].catalystId;
            if (catalystId != 0) {
                _records[assetId].catalystId = catalystId;
                gemIdsToStore = _records[collectionId].gemIds;
            }
        } else {
            gemIdsToStore = _records[assetId].gemIds;
        }

        require(catalystId != 0, "NO_CATALYST_SET");
        uint8 j = 0;
        uint8 i = 0;
        for (i = 0; i < MAX_NUM_GEMS; i++) {
            if (j == gemIds.length) {
                break;
            }
            if (gemIdsToStore[i] == 0) {
                require(gemIds[j] != 0, "INVALID_GEM_ID");
                gemIdsToStore[i] = gemIds[j];
                j++;
            }
        }
        uint8 maxGems = _gemsCatalystsRegistry.getMaxGems(catalystId);
        require(i <= maxGems, "GEMS_TOO_MANY");
        _records[assetId].gemIds = gemIdsToStore;
        uint64 blockNumber = _getBlockNumber();
        emit GemsAdded(assetId, gemIds, blockNumber);
    }

    /// @notice set the migratcion contract address, admin or migration contract only
    /// @param _migrationContract address of the migration contract
    function setMigrationContract(address _migrationContract) external override {
        address currentMigrationContract = migrationContract;
        if (currentMigrationContract == address(0)) {
            require(_msgSender() == _admin, "NOT_AUTHORIZED");
            migrationContract = _migrationContract;
        } else {
            require(_msgSender() == currentMigrationContract, "NOT_AUTHORIZED_MIGRATION");
            migrationContract = _migrationContract;
        }
    }

    function setOverLayerDepositor(address overLayerDepositor_) external {
        require(_msgSender() == _admin, "NOT_AUTHORIZED");
        overLayerDepositor = overLayerDepositor_;
    }

    /// @dev Set a catalyst for the given asset.
    /// @param assetId The asset to set a catalyst on.
    /// @param catalystId The catalyst to set.
    /// @param gemIds The gems to embed in the catalyst.
    /// @param blockNumber The blocknumber to emit in the event.
    /// @param hasToEmitEvent boolean to indicate if we want to emit an event
    function _setCatalyst(
        uint256 assetId,
        uint16 catalystId,
        uint16[] memory gemIds,
        uint64 blockNumber,
        bool hasToEmitEvent
    ) internal virtual {
        require(gemIds.length <= MAX_NUM_GEMS, "GEMS_MAX_REACHED");
        uint8 maxGems = _gemsCatalystsRegistry.getMaxGems(catalystId);
        require(gemIds.length <= maxGems, "GEMS_TOO_MANY");
        uint16[MAX_NUM_GEMS] memory gemIdsToStore;
        for (uint8 i = 0; i < gemIds.length; i++) {
            require(gemIds[i] != 0, "INVALID_GEM_ID");
            gemIdsToStore[i] = gemIds[i];
        }
        _records[assetId] = Record(catalystId, gemIdsToStore);
        if (hasToEmitEvent) {
            emit CatalystApplied(assetId, catalystId, gemIds, blockNumber);
        }
    }

    /// @dev Get the collection Id for an asset.
    /// @param assetId The asset to get the collection id for.
    /// @return The id of the collection the asset belongs to.
    function _getCollectionId(uint256 assetId) internal pure returns (uint256) {
        return assetId & NOT_NFT_INDEX & NOT_IS_NFT; // compute the same as Asset to get collectionId
    }

    /// @dev Get a blocknumber for use when querying attributes.
    /// @return blockNumber The current blocknumber + 1.
    function _getBlockNumber() internal view returns (uint64 blockNumber) {
        blockNumber = uint64(block.number + 1);
    }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "./Gem.sol";
import "./Catalyst.sol";
import "./interfaces/IGemsCatalystsRegistry.sol";
import "../common/BaseWithStorage/WithSuperOperators.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";

/// @notice Contract managing the Gems and Catalysts
/// Each Gems and Catalyst must be registered here.
/// Each new Gem get assigned a new id (starting at 1)
/// Each new Catalyst get assigned a new id (starting at 1)
contract GemsCatalystsRegistry is WithSuperOperators, ERC2771Handler, IGemsCatalystsRegistry, Ownable {
    Gem[] internal _gems;
    Catalyst[] internal _catalysts;

    constructor(address admin, address trustedForwarder) {
        _admin = admin;
        __ERC2771Handler_initialize(trustedForwarder);
    }

    /// @notice Returns the values for each gem included in a given asset.
    /// @param catalystId The catalyst identifier.
    /// @param assetId The asset tokenId.
    /// @param events An array of GemEvents. Be aware that only gemEvents from the last CatalystApplied event onwards should be used to populate a query. If gemEvents from multiple CatalystApplied events are included the output values will be incorrect.
    /// @return values An array of values for each gem present in the asset.
    function getAttributes(
        uint16 catalystId,
        uint256 assetId,
        IAssetAttributesRegistry.GemEvent[] calldata events
    ) external view override returns (uint32[] memory values) {
        Catalyst catalyst = getCatalyst(catalystId);
        require(catalyst != Catalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        return catalyst.getAttributes(assetId, events);
    }

    /// @notice Returns the maximum number of gems for a given catalyst
    /// @param catalystId catalyst identifier
    function getMaxGems(uint16 catalystId) external view override returns (uint8) {
        Catalyst catalyst = getCatalyst(catalystId);
        require(catalyst != Catalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        return catalyst.getMaxGems();
    }

    /// @notice Burns one gem unit from each gem id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param gemIds list of gems to burn one gem from each
    /// @param amount amount units to burn
    function burnDifferentGems(
        address from,
        uint16[] calldata gemIds,
        uint256 amount
    ) external override {
        for (uint256 i = 0; i < gemIds.length; i++) {
            burnGem(from, gemIds[i], amount);
        }
    }

    /// @notice Burns one catalyst unit from each catalyst id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param catalystIds list of catalysts to burn one catalyst from each
    /// @param amount amount to burn
    function burnDifferentCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256 amount
    ) external override {
        for (uint256 i = 0; i < catalystIds.length; i++) {
            burnCatalyst(from, catalystIds[i], amount);
        }
    }

    /// @notice Burns few gem units from each gem id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param gemIds list of gems to burn gem units from each
    /// @param amounts list of amounts of units to burn
    function batchBurnGems(
        address from,
        uint16[] calldata gemIds,
        uint256[] calldata amounts
    ) public override {
        for (uint256 i = 0; i < gemIds.length; i++) {
            if (gemIds[i] != 0 && amounts[i] != 0) {
                burnGem(from, gemIds[i], amounts[i]);
            }
        }
    }

    /// @notice Burns few catalyst units from each catalyst id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param catalystIds list of catalysts to burn catalyst units from each
    /// @param amounts list of amounts of units to burn
    function batchBurnCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256[] calldata amounts
    ) public override {
        for (uint256 i = 0; i < catalystIds.length; i++) {
            if (catalystIds[i] != 0 && amounts[i] != 0) {
                burnCatalyst(from, catalystIds[i], amounts[i]);
            }
        }
    }

    /// @notice Adds both arrays of gems and catalysts to registry
    /// @param gems array of gems to be added
    /// @param catalysts array of catalysts to be added
    function addGemsAndCatalysts(Gem[] calldata gems, Catalyst[] calldata catalysts) external override {
        require(_msgSender() == _admin, "NOT_AUTHORIZED");
        for (uint256 i = 0; i < gems.length; i++) {
            Gem gem = gems[i];
            uint16 gemId = gem.gemId();
            require(gemId == _gems.length + 1, "GEM_ID_NOT_IN_ORDER");
            _gems.push(gem);
        }

        for (uint256 i = 0; i < catalysts.length; i++) {
            Catalyst catalyst = catalysts[i];
            uint16 catalystId = catalyst.catalystId();
            require(catalystId == _catalysts.length + 1, "CATALYST_ID_NOT_IN_ORDER");
            _catalysts.push(catalyst);
        }
    }

    /// @notice Query whether a given gem exists.
    /// @param gemId The gem being queried.
    /// @return Whether the gem exists.
    function doesGemExist(uint16 gemId) external view override returns (bool) {
        return getGem(gemId) != Gem(address(0));
    }

    /// @notice Query whether a giving catalyst exists.
    /// @param catalystId The catalyst being queried.
    /// @return Whether the catalyst exists.
    function doesCatalystExist(uint16 catalystId) external view returns (bool) {
        return getCatalyst(catalystId) != Catalyst(address(0));
    }

    /// @notice Burn a catalyst.
    /// @param from The signing address for the tx.
    /// @param catalystId The id of the catalyst to burn.
    /// @param amount The number of catalyst tokens to burn.
    function burnCatalyst(
        address from,
        uint16 catalystId,
        uint256 amount
    ) public override {
        _checkAuthorization(from);
        Catalyst catalyst = getCatalyst(catalystId);
        require(catalyst != Catalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        catalyst.burnFor(from, amount);
    }

    /// @notice Burn a gem.
    /// @param from The signing address for the tx.
    /// @param gemId The id of the gem to burn.
    /// @param amount The number of gem tokens to burn.
    function burnGem(
        address from,
        uint16 gemId,
        uint256 amount
    ) public override {
        _checkAuthorization(from);
        Gem gem = getGem(gemId);
        require(gem != Gem(address(0)), "GEM_DOES_NOT_EXIST");
        gem.burnFor(from, amount);
    }

    function getNumberOfCatalystContracts() external view returns (uint256 number) {
        number = _catalysts.length;
    }

    function getNumberOfGemContracts() external view returns (uint256 number) {
        number = _gems.length;
    }

    function setGemsandCatalystsMaxAllowance() external {
        for (uint256 i = 0; i < _gems.length; i++) {
            _gems[i].approveFor(_msgSender(), address(this), ~uint256(0));
        }

        for (uint256 i = 0; i < _catalysts.length; i++) {
            _catalysts[i].approveFor(_msgSender(), address(this), ~uint256(0));
        }
    }

    // //////////////////// INTERNALS ////////////////////

    /// @dev Get the catalyst contract corresponding to the id.
    /// @param catalystId The catalyst id to use to retrieve the contract.
    /// @return The requested Catalyst contract.
    function getCatalyst(uint16 catalystId) internal view returns (Catalyst) {
        if (catalystId > 0 && catalystId <= _catalysts.length) {
            return _catalysts[catalystId - 1];
        } else {
            return Catalyst(address(0));
        }
    }

    /// @dev Get the gem contract corresponding to the id.
    /// @param gemId The gem id to use to retrieve the contract.
    /// @return The requested Gem contract.
    function getGem(uint16 gemId) internal view returns (Gem) {
        if (gemId > 0 && gemId <= _gems.length) {
            return _gems[gemId - 1];
        } else {
            return Gem(address(0));
        }
    }

    /// @dev verify that the caller is authorized for this function call.
    /// @param from The original signer of the transaction.
    function _checkAuthorization(address from) internal view {
        require(_msgSender() == from || isSuperOperator(_msgSender()), "AUTH_ACCESS_DENIED");
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

contract WithAdmin {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract WithMinter is WithAdmin {
    address internal _minter;

    /// @dev Emits when the Minter address is changed
    /// @param oldMinter The previous Minter address
    /// @param newMinter The new Minter address
    event MinterChanged(address oldMinter, address newMinter);

    modifier onlyMinter() {
        require(msg.sender == _minter, "MINTER_ACCESS_DENIED");
        _;
    }

    /// @dev Get the current minter of this contract.
    /// @return The current minter of this contract.
    function getMinter() external view returns (address) {
        return _minter;
    }

    /// @dev Change the minter to be `newMinter`.
    /// @param newMinter The address of the new minter.
    function changeMinter(address newMinter) external onlyAdmin() {
        emit MinterChanged(_minter, newMinter);
        _minter = newMinter;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract WithUpgrader is WithAdmin {
    address internal _upgrader;

    /// @dev Emits when the Upgrader address is changed
    /// @param oldUpgrader The previous Upgrader address
    /// @param newUpgrader The new Upgrader address
    event UpgraderChanged(address oldUpgrader, address newUpgrader);

    modifier onlyUpgrader() {
        require(msg.sender == _upgrader, "UPGRADER_ACCESS_DENIED");
        _;
    }

    /// @dev Get the current upgrader of this contract.
    /// @return The current upgrader of this contract.
    function getUpgrader() external view returns (address) {
        return _upgrader;
    }

    /// @dev Change the upgrader to be `newUpgrader`.
    /// @param newUpgrader The address of the new upgrader.
    function changeUpgrader(address newUpgrader) external onlyAdmin() {
        emit UpgraderChanged(_upgrader, newUpgrader);
        _upgrader = newUpgrader;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/BaseWithStorage/ERC20/ERC20Token.sol";

contract Gem is ERC20Token {
    uint16 public immutable gemId;

    constructor(
        string memory name,
        string memory symbol,
        address admin,
        uint16 _gemId,
        address operator
    ) ERC20Token(name, symbol, admin, operator) {
        gemId = _gemId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "../common/interfaces/IAssetAttributesRegistry.sol";
import "../common/BaseWithStorage/ERC20/ERC20Token.sol";
import "../common/interfaces/IAttributes.sol";

contract Catalyst is ERC20Token, IAttributes {
    uint16 public immutable catalystId;
    uint8 internal immutable _maxGems;

    IAttributes internal _attributes;

    constructor(
        string memory name,
        string memory symbol,
        address admin,
        uint8 maxGems,
        uint16 _catalystId,
        IAttributes attributes,
        address operator
    ) ERC20Token(name, symbol, admin, operator) {
        _maxGems = maxGems;
        catalystId = _catalystId;
        _attributes = attributes;
    }

    /// @notice Used by Admin to update the attributes contract.
    /// @param attributes The new attributes contract.
    function changeAttributes(IAttributes attributes) external onlyAdmin {
        _attributes = attributes;
    }

    /// @notice Get the value of _maxGems(the max number of gems that can be embeded in this type of catalyst).
    /// @return The value of _maxGems.
    function getMaxGems() external view returns (uint8) {
        return _maxGems;
    }

    /// @notice Get the attributes for each gem in an asset.
    /// See DefaultAttributes.getAttributes for more.
    /// @return values An array of values representing the "level" of each gem. ie: Power=14, speed=45, etc...
    function getAttributes(uint256 assetId, IAssetAttributesRegistry.GemEvent[] calldata events)
        external
        view
        override
        returns (uint32[] memory values)
    {
        return _attributes.getAttributes(assetId, events);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "../../common/interfaces/IAssetAttributesRegistry.sol";
import "../Gem.sol";
import "../Catalyst.sol";

interface IGemsCatalystsRegistry {
    function getAttributes(
        uint16 catalystId,
        uint256 assetId,
        IAssetAttributesRegistry.GemEvent[] calldata events
    ) external view returns (uint32[] memory values);

    function getMaxGems(uint16 catalystId) external view returns (uint8);

    function burnDifferentGems(
        address from,
        uint16[] calldata gemIds,
        uint256 amount
    ) external;

    function burnDifferentCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256 amount
    ) external;

    function batchBurnGems(
        address from,
        uint16[] calldata gemIds,
        uint256[] calldata amounts
    ) external;

    function batchBurnCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256[] calldata amounts
    ) external;

    function addGemsAndCatalysts(Gem[] calldata gems, Catalyst[] calldata catalysts) external;

    function doesGemExist(uint16 gemId) external view returns (bool);

    function burnCatalyst(
        address from,
        uint16 catalystId,
        uint256 amount
    ) external;

    function burnGem(
        address from,
        uint16 gemId,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract WithSuperOperators is WithAdmin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(msg.sender == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/// @dev minimal ERC2771 handler to keep bytecode-size down.
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol

contract ERC2771Handler {
    address internal _trustedForwarder;

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20BaseToken.sol";
import "./extensions/ERC20BasicApproveExtension.sol";
import "../WithPermit.sol";
import "../ERC677/extensions/ERC677Extension.sol";
import "../../interfaces/IERC677Receiver.sol";

contract ERC20Token is ERC20BasicApproveExtension, ERC677Extension, WithPermit, ERC20BaseToken {
    // /////////////////// CONSTRUCTOR ////////////////////
    constructor(
        string memory name,
        string memory symbol,
        address admin,
        address operator
    )
        ERC20BaseToken(name, symbol, admin, operator) // solhint-disable-next-line no-empty-blocks
    {}

    function mint(address to, uint256 amount) external onlyAdmin {
        _mint(to, amount);
    }

    /// @notice Function to permit the expenditure of ERC20 token by a nominated spender
    /// @param owner The owner of the ERC20 tokens
    /// @param spender The nominated spender of the ERC20 tokens
    /// @param value The value (allowance) of the ERC20 tokens that the nominated spender will be allowed to spend
    /// @param deadline The deadline for granting permission to the spender
    /// @param v The final 1 byte of signature
    /// @param r The first 32 bytes of signature
    /// @param s The second 32 bytes of signature
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        checkApproveFor(owner, spender, value, deadline, v, r, s);
        _approveFor(owner, spender, value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Context.sol";
import "./extensions/ERC20Internal.sol";
import "../../interfaces/IERC20Extended.sol";
import "../WithSuperOperators.sol";

abstract contract ERC20BaseToken is WithSuperOperators, IERC20, IERC20Extended, ERC20Internal, Context {
    string internal _name;
    string internal _symbol;
    address internal immutable _operator;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address admin,
        address operator
    ) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _admin = admin;
        _operator = operator;
    }

    /// @notice Transfer `amount` tokens to `to`.
    /// @param to The recipient address of the tokens being transfered.
    /// @param amount The number of tokens being transfered.
    /// @return success Whether or not the transfer succeeded.
    function transfer(address to, uint256 amount) external override returns (bool success) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    /// @notice Transfer `amount` tokens from `from` to `to`.
    /// @param from The origin address  of the tokens being transferred.
    /// @param to The recipient address of the tokensbeing  transfered.
    /// @param amount The number of tokens transfered.
    /// @return success Whether or not the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool success) {
        if (_msgSender() != from && !_superOperators[_msgSender()] && _msgSender() != _operator) {
            uint256 currentAllowance = _allowances[from][_msgSender()];
            if (currentAllowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(currentAllowance >= amount, "NOT_AUTHORIZED_ALLOWANCE");
                _allowances[from][_msgSender()] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Burn `amount` tokens.
    /// @param amount The number of tokens to burn.
    function burn(uint256 amount) external override {
        _burn(_msgSender(), amount);
    }

    /// @notice Burn `amount` tokens from `owner`.
    /// @param from The address whose token to burn.
    /// @param amount The number of tokens to burn.
    function burnFor(address from, uint256 amount) external override {
        _burn(from, amount);
    }

    /// @notice Approve `spender` to transfer `amount` tokens.
    /// @param spender The address to be given rights to transfer.
    /// @param amount The number of tokens allowed.
    /// @return success Whether or not the call succeeded.
    function approve(address spender, uint256 amount) external override returns (bool success) {
        _approveFor(_msgSender(), spender, amount);
        return true;
    }

    /// @notice Get the name of the token collection.
    /// @return The name of the token collection.
    function name() external view virtual returns (string memory) {
        //added virtual
        return _name;
    }

    /// @notice Get the symbol for the token collection.
    /// @return The symbol of the token collection.
    function symbol() external view virtual returns (string memory) {
        //added virtual
        return _symbol;
    }

    /// @notice Get the total number of tokens in existence.
    /// @return The total number of tokens in existence.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get the balance of `owner`.
    /// @param owner The address to query the balance of.
    /// @return The amount owned by `owner`.
    function balanceOf(address owner) external view override returns (uint256) {
        return _balances[owner];
    }

    /// @notice Get the allowance of `spender` for `owner`'s tokens.
    /// @param owner The address whose token is allowed.
    /// @param spender The address allowed to transfer.
    /// @return remaining The amount of token `spender` is allowed to transfer on behalf of `owner`.
    function allowance(address owner, address spender) external view override returns (uint256 remaining) {
        return _allowances[owner][spender];
    }

    /// @notice Get the number of decimals for the token collection.
    /// @return The number of decimals.
    function decimals() external pure virtual returns (uint8) {
        return uint8(18);
    }

    /// @notice Approve `spender` to transfer `amount` tokens from `owner`.
    /// @param owner The address whose token is allowed.
    /// @param spender The address to be given rights to transfer.
    /// @param amount The number of tokens allowed.
    /// @return success Whether or not the call succeeded.
    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) public override returns (bool success) {
        require(_msgSender() == owner || _superOperators[_msgSender()] || _msgSender() == _operator, "NOT_AUTHORIZED");
        _approveFor(owner, spender, amount);
        return true;
    }

    /// @notice Increase the allowance for the spender if needed
    /// @param owner The address of the owner of the tokens
    /// @param spender The address wanting to spend tokens
    /// @param amountNeeded The amount requested to spend
    /// @return success Whether or not the call succeeded.
    function addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) public returns (bool success) {
        require(_msgSender() == owner || _superOperators[_msgSender()] || _msgSender() == _operator, "INVALID_SENDER");
        _addAllowanceIfNeeded(owner, spender, amountNeeded);
        return true;
    }

    /// @dev See addAllowanceIfNeeded.
    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded /*(ERC20Internal, ERC20ExecuteExtension, ERC20BasicApproveExtension)*/
    ) internal virtual override {
        if (amountNeeded > 0 && !isSuperOperator(spender) && spender != _operator) {
            uint256 currentAllowance = _allowances[owner][spender];
            if (currentAllowance < amountNeeded) {
                _approveFor(owner, spender, amountNeeded);
            }
        }
    }

    /// @dev See approveFor.
    function _approveFor(
        address owner,
        address spender,
        uint256 amount /*(ERC20BasicApproveExtension, ERC20Internal)*/
    ) internal virtual override {
        require(owner != address(0) && spender != address(0), "INVALID_OWNER_||_SPENDER");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev See transfer.
    function _transfer(
        address from,
        address to,
        uint256 amount /*(ERC20Internal, ERC20ExecuteExtension)*/
    ) internal virtual override {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "INSUFFICIENT_FUNDS");
        _balances[from] = currentBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /// @dev Mint tokens for a recipient.
    /// @param to The recipient address.
    /// @param amount The number of token to mint.
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(amount > 0, "MINT_O_TOKENS");
        uint256 currentTotalSupply = _totalSupply;
        uint256 newTotalSupply = currentTotalSupply + amount;
        require(newTotalSupply > currentTotalSupply, "OVERFLOW");
        _totalSupply = newTotalSupply;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @dev Burn tokens from an address.
    /// @param from The address whose tokens to burn.
    /// @param amount The number of token to burn.
    function _burn(address from, uint256 amount) internal {
        require(amount > 0, "BURN_O_TOKENS");
        if (_msgSender() != from && !_superOperators[_msgSender()] && _msgSender() != _operator) {
            uint256 currentAllowance = _allowances[from][_msgSender()];
            if (currentAllowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
                _allowances[from][_msgSender()] = currentAllowance - amount;
            }
        }

        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "INSUFFICIENT_FUNDS");
        _balances[from] = currentBalance - amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Context.sol";
import "./ERC20Internal.sol";
import "../../../Libraries/BytesUtil.sol";

abstract contract ERC20BasicApproveExtension is ERC20Internal, Context {
    /// @notice Approve `target` to spend `amount` and call it with data.
    /// @param target The address to be given rights to transfer and destination of the call.
    /// @param amount The number of tokens allowed.
    /// @param data The bytes for the call.
    /// @return The data of the call.
    function approveAndCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(BytesUtil.doFirstParamEqualsAddress(data, _msgSender()), "FIRST_PARAM_NOT_SENDER");

        _approveFor(_msgSender(), target, amount);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));
        return returnData;
    }

    /// @notice Temporarily approve `target` to spend `amount` and call it with data.
    /// Previous approvals remains unchanged.
    /// @param target The destination of the call, allowed to spend the amount specified
    /// @param amount The number of tokens allowed to spend.
    /// @param data The bytes for the call.
    /// @return The data of the call.
    function paidCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(BytesUtil.doFirstParamEqualsAddress(data, _msgSender()), "FIRST_PARAM_NOT_SENDER");

        if (amount > 0) {
            _addAllowanceIfNeeded(_msgSender(), target, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));

        return returnData;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../../common/interfaces/IERC20Extended.sol";
import "../../common/Base/TheSandbox712.sol";

/// @title Permit contract
/// @notice This contract manages approvals of SAND via signature
abstract contract WithPermit is TheSandbox712, IERC20Permit {
    mapping(address => uint256) public _nonces;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Function to permit the expenditure of ERC20 token by a nominated spender
    /// @param owner The owner of the ERC20 tokens
    /// @param spender The nominated spender of the ERC20 tokens
    /// @param value The value (allowance) of the ERC20 tokens that the nominated spender will be allowed to spend
    /// @param deadline The deadline for granting permission to the spender
    /// @param v The final 1 byte of signature
    /// @param r The first 32 bytes of signature
    /// @param s The second 32 bytes of signature
    function checkApproveFor(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(deadline >= block.timestamp, "PAST_DEADLINE");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _DOMAIN_SEPARATOR,
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _nonces[owner]++, deadline))
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNATURE");
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[owner];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../../interfaces/IERC677.sol";
import "../../../interfaces/IERC677Receiver.sol";
import "../../ERC20/extensions/ERC20Internal.sol";
import "@openzeppelin/contracts-0.8/utils/Address.sol";

abstract contract ERC677Extension is ERC20Internal, IERC677 {
    using Address for address;

    /// @notice Transfers tokens to an address with _data if the recipient is a contact.
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    /// @param _data The extra data to be passed to the receiving contract.
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bool success) {
        _transfer(msg.sender, _to, _value);
        if (_to.isContract()) {
            IERC677Receiver receiver = IERC677Receiver(_to);
            receiver.onTokenTransfer(msg.sender, _value, _data);
        }
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERC677Receiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes calldata _data
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

abstract contract ERC20Internal {
    function _approveFor(
        address owner,
        address target,
        uint256 amount
    ) internal virtual;

    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC20.sol";

interface IERC20Extended is IERC20 {
    function burnFor(address from, uint256 amount) external;

    function burn(uint256 amount) external;

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/// @dev see https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
    /// @notice emitted when tokens are transfered from one address to another.
    /// @param from address from which the token are transfered from (zero means tokens are minted).
    /// @param to destination address which the token are transfered to (zero means tokens are burnt).
    /// @param value amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice emitted when owner grant transfer rights to another address
    /// @param owner address allowing its token to be transferred.
    /// @param spender address allowed to spend on behalf of `owner`
    /// @param value amount of tokens allowed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice return the current total amount of tokens owned by all holders.
    /// @return supply total number of tokens held.
    function totalSupply() external view returns (uint256 supply);

    /// @notice return the number of tokens held by a particular address.
    /// @param who address being queried.
    /// @return balance number of token held by that address.
    function balanceOf(address who) external view returns (uint256 balance);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice approve an address to spend on your behalf.
    /// @param spender address entitled to transfer on your behalf.
    /// @param value amount allowed to be transfered.
    /// @param success whether the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice return the current allowance for a particular owner/spender pair.
    /// @param owner address allowing spender.
    /// @param spender address allowed to spend.
    /// @return amount number of tokens `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library BytesUtil {
    uint256 private constant DATA_MIN_LENGTH = 68;

    /// @dev Check if the data == _address.
    /// @param data The bytes passed to the function.
    /// @param _address The address to compare to.
    /// @return Whether the first param == _address.
    function doFirstParamEqualsAddress(bytes memory data, address _address) internal pure returns (bool) {
        if (data.length < DATA_MIN_LENGTH) {
            return false;
        }
        uint256 value;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := mload(add(data, 36))
        }
        return value == uint256(uint160(_address));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract TheSandbox712 {
    bytes32 internal constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable _DOMAIN_SEPARATOR;

    constructor() {
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712DOMAIN_TYPEHASH, keccak256("The Sandbox"), keccak256("1"), address(this))
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERC677 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);
    //TODO: decide whether we use that event, as it collides with ERC20 Transfer event
    //event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IAssetAttributesRegistry {
    struct GemEvent {
        uint16[] gemIds;
        bytes32 blockHash;
    }

    struct AssetGemsCatalystData {
        uint256 assetId;
        uint16 catalystContractId;
        uint16[] gemContractIds;
    }

    function getRecord(uint256 assetId)
        external
        view
        returns (
            bool exists,
            uint16 catalystId,
            uint16[] memory gemIds
        );

    function getAttributes(uint256 assetId, GemEvent[] calldata events) external view returns (uint32[] memory values);

    function setCatalyst(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external;

    function setCatalystWhenDepositOnOtherLayer(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external;

    function setCatalystWithBlockNumber(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint64 blockNumber
    ) external;

    function addGems(uint256 assetId, uint16[] calldata gemIds) external;

    function setMigrationContract(address _migrationContract) external;

    function getCatalystRegistry() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "../interfaces/IAssetAttributesRegistry.sol";

interface IAttributes {
    function getAttributes(uint256 assetId, IAssetAttributesRegistry.GemEvent[] calldata events)
        external
        view
        returns (uint32[] memory values);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "../asset/AssetAttributesRegistry.sol";

/// @notice Allows setting the gems and catalysts of an asset
contract MockAssetAttributesRegistry is AssetAttributesRegistry {
    uint256 private constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;

    constructor(
        GemsCatalystsRegistry gemsCatalystsRegistry,
        address admin,
        address minter,
        address upgrader
    )
        AssetAttributesRegistry(gemsCatalystsRegistry, admin, minter, upgrader)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function setCatalyst(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external override {
        // @note access control removed for testing
        _setCatalyst(assetId, catalystId, gemIds, _getBlockNumber(), true);
    }

    function _setCatalyst(
        uint256 assetId,
        uint16 catalystId,
        uint16[] memory gemIds,
        uint64 blockNumber,
        bool hasToEmitEvent
    ) internal override {
        // @note access control removed for testing
        require(gemIds.length <= MAX_NUM_GEMS, "GEMS_MAX_REACHED");
        uint8 maxGems = _gemsCatalystsRegistry.getMaxGems(catalystId);
        require(gemIds.length <= maxGems, "GEMS_TOO_MANY");
        uint16[MAX_NUM_GEMS] memory gemIdsToStore;
        for (uint8 i = 0; i < gemIds.length; i++) {
            require(gemIds[i] != 0, "INVALID_GEM_ID");
            gemIdsToStore[i] = gemIds[i];
        }
        _records[assetId] = Record(catalystId, gemIdsToStore);
        if (hasToEmitEvent) {
            emit CatalystApplied(assetId, catalystId, gemIds, blockNumber);
        }
    }

    function addGems(uint256 assetId, uint16[] calldata gemIds) external override {
        // @note removed access control for ease of testing.
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT");
        require(gemIds.length != 0, "INVALID_GEMS_0");

        uint16 catalystId = _records[assetId].catalystId;
        uint16[MAX_NUM_GEMS] memory gemIdsToStore;
        if (catalystId == 0) {
            // fallback on collection catalyst
            uint256 collectionId = _getCollectionId(assetId);
            catalystId = _records[collectionId].catalystId;
            if (catalystId != 0) {
                _records[assetId].catalystId = catalystId;
                gemIdsToStore = _records[collectionId].gemIds;
            }
        } else {
            gemIdsToStore = _records[assetId].gemIds;
        }

        require(catalystId != 0, "NO_CATALYST_SET");
        uint8 j = 0;
        uint8 i = 0;
        for (i = 0; i < MAX_NUM_GEMS; i++) {
            if (j == gemIds.length) {
                break;
            }
            if (gemIdsToStore[i] == 0) {
                require(gemIds[j] != 0, "INVALID_GEM_ID");
                gemIdsToStore[i] = gemIds[j];
                j++;
            }
        }
        uint8 maxGems = _gemsCatalystsRegistry.getMaxGems(catalystId);
        require(i <= maxGems, "GEMS_TOO_MANY");
        _records[assetId].gemIds = gemIdsToStore;
        uint64 blockNumber = _getBlockNumber();
        emit GemsAdded(assetId, gemIds, blockNumber);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ClaimERC1155ERC721ERC20.sol";
import "../../common/BaseWithStorage/WithAdmin.sol";

/// @title MultiGiveaway contract.
/// @notice This contract manages claims for multiple token types.
contract MultiGiveaway is WithAdmin, ClaimERC1155ERC721ERC20 {
    ///////////////////////////////  Data //////////////////////////////

    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant ERC721_BATCH_RECEIVED = 0x4b808c46;

    mapping(address => mapping(bytes32 => bool)) public claimed;
    mapping(bytes32 => uint256) internal _expiryTime;

    ///////////////////////////////  Events //////////////////////////////

    event NewGiveaway(bytes32 merkleRoot, uint256 expiryTime);

    ///////////////////////////////  Constructor /////////////////////////

    constructor(address admin) {
        _admin = admin;
    }

    ///////////////////////////////  Functions ///////////////////////////

    /// @notice Function to add a new giveaway.
    /// @param merkleRoot The merkle root hash of the claim data.
    /// @param expiryTime The expiry time for the giveaway.
    function addNewGiveaway(bytes32 merkleRoot, uint256 expiryTime) external onlyAdmin {
        _expiryTime[merkleRoot] = expiryTime;
        emit NewGiveaway(merkleRoot, expiryTime);
    }

    /// @notice Function to check which giveaways have been claimed by a particular user.
    /// @param user The user (intended token destination) address.
    /// @param rootHashes The array of giveaway root hashes to check.
    /// @return claimedGiveaways The array of bools confirming whether or not the giveaways relating to the root hashes provided have been claimed.
    function getClaimedStatus(address user, bytes32[] calldata rootHashes) external view returns (bool[] memory) {
        bool[] memory claimedGiveaways = new bool[](rootHashes.length);
        for (uint256 i = 0; i < rootHashes.length; i++) {
            claimedGiveaways[i] = claimed[user][rootHashes[i]];
        }
        return claimedGiveaways;
    }

    /// @notice Function to permit the claiming of multiple tokens from multiple giveaways to a reserved address.
    /// @param claims The array of claim structs, each containing a destination address, the giveaway items to be claimed and an optional salt param.
    /// @param proofs The proofs submitted for verification.
    function claimMultipleTokensFromMultipleMerkleTree(
        bytes32[] calldata rootHashes,
        Claim[] memory claims,
        bytes32[][] calldata proofs
    ) external {
        require(claims.length == rootHashes.length, "INVALID_INPUT");
        require(claims.length == proofs.length, "INVALID_INPUT");
        for (uint256 i = 0; i < rootHashes.length; i++) {
            claimMultipleTokens(rootHashes[i], claims[i], proofs[i]);
        }
    }

    /// @dev Public function used to perform validity checks and progress to claim multiple token types in one claim.
    /// @param merkleRoot The merkle root hash for the specific set of items being claimed.
    /// @param claim The claim struct containing the destination address, all items to be claimed and optional salt param.
    /// @param proof The proof provided by the user performing the claim function.
    function claimMultipleTokens(
        bytes32 merkleRoot,
        Claim memory claim,
        bytes32[] calldata proof
    ) public {
        uint256 giveawayExpiryTime = _expiryTime[merkleRoot];
        require(claim.to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(claim.to != address(this), "DESTINATION_MULTIGIVEAWAY_CONTRACT");
        require(giveawayExpiryTime != 0, "GIVEAWAY_DOES_NOT_EXIST");
        require(block.timestamp < giveawayExpiryTime, "CLAIM_PERIOD_IS_OVER");
        require(claimed[claim.to][merkleRoot] == false, "DESTINATION_ALREADY_CLAIMED");
        claimed[claim.to][merkleRoot] = true;
        _claimERC1155ERC721ERC20(merkleRoot, claim, proof);
    }

    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return ERC721_RECEIVED;
    }

    function onERC721BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return ERC721_BATCH_RECEIVED;
    }

    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return ERC1155_BATCH_RECEIVED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import "../../common/interfaces/IERC721Extended.sol";
import "../../common/Libraries/Verify.sol";

contract ClaimERC1155ERC721ERC20 {
    ///////////////////////////////  Libs //////////////////////////////

    using SafeERC20 for IERC20;

    ///////////////////////////////  Data //////////////////////////////

    struct Claim {
        address to;
        ERC1155Claim[] erc1155;
        ERC721Claim[] erc721;
        ERC20Claim erc20;
        bytes32 salt;
    }

    struct ERC1155Claim {
        uint256[] ids;
        uint256[] values;
        address contractAddress;
    }

    struct ERC721Claim {
        uint256[] ids;
        address contractAddress;
    }

    struct ERC20Claim {
        uint256[] amounts;
        address[] contractAddresses;
    }

    ///////////////////////////////  Events //////////////////////////////

    /// @dev Emits when a successful claim occurs.
    /// @param to The destination address for the claimed ERC1155, ERC721 and ERC20 tokens.
    /// @param erc1155 The array of ERC1155Claim structs containing the ids, values and ERC1155 contract address.
    /// @param erc721 The array of ERC721Claim structs containing the ids and ERC721 contract address.
    /// @param erc20 The ERC20Claim struct containing the amounts and ERC20 contract addresses.
    /// @param merkleRoot The merkle root hash for the specific set of items being claimed.
    event ClaimedMultipleTokens(
        address to,
        ERC1155Claim[] erc1155,
        ERC721Claim[] erc721,
        ERC20Claim erc20,
        bytes32 merkleRoot
    );

    ///////////////////////////////  Functions ///////////////////////////

    /// @dev Internal function used to claim multiple token types in one claim.
    /// @param merkleRoot The merkle root hash for the specific set of items being claimed.
    /// @param claim The claim struct containing the destination address, all items to be claimed and optional salt param.
    /// @param proof The proof provided by the user performing the claim function.
    function _claimERC1155ERC721ERC20(
        bytes32 merkleRoot,
        Claim memory claim,
        bytes32[] calldata proof
    ) internal {
        _checkValidity(merkleRoot, claim, proof);
        for (uint256 i = 0; i < claim.erc1155.length; i++) {
            require(claim.erc1155[i].ids.length == claim.erc1155[i].values.length, "INVALID_INPUT");
            _transferERC1155(claim.to, claim.erc1155[i].ids, claim.erc1155[i].values, claim.erc1155[i].contractAddress);
        }
        for (uint256 i = 0; i < claim.erc721.length; i++) {
            _transferERC721(claim.to, claim.erc721[i].ids, claim.erc721[i].contractAddress);
        }
        if (claim.erc20.amounts.length != 0) {
            require(claim.erc20.amounts.length == claim.erc20.contractAddresses.length, "INVALID_INPUT");
            _transferERC20(claim.to, claim.erc20.amounts, claim.erc20.contractAddresses);
        }
        emit ClaimedMultipleTokens(claim.to, claim.erc1155, claim.erc721, claim.erc20, merkleRoot);
    }

    /// @dev Private function used to check the validity of a specific claim.
    /// @param merkleRoot The merkle root hash for the specific set of items being claimed.
    /// @param claim The claim struct containing the destination address, all items to be claimed and optional salt param.
    /// @param proof The proof provided by the user performing the claim function.
    function _checkValidity(
        bytes32 merkleRoot,
        Claim memory claim,
        bytes32[] memory proof
    ) private pure {
        bytes32 leaf = _generateClaimHash(claim);
        require(Verify.doesComputedHashMatchMerkleRootHash(merkleRoot, proof, leaf), "INVALID_CLAIM");
    }

    /// @dev Private function used to generate a hash from an encoded claim.
    /// @param claim The claim struct.
    function _generateClaimHash(Claim memory claim) private pure returns (bytes32) {
        return keccak256(abi.encode(claim));
    }

    /// @dev Private function used to transfer the ERC1155 tokens specified in a specific claim.
    /// @param to The destination address for the claimed tokens.
    /// @param ids The array of ERC1155 ids.
    /// @param values The amount of ERC1155 tokens of each id to be transferred.
    /// @param contractAddress The ERC1155 token contract address.
    function _transferERC1155(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        address contractAddress
    ) private {
        require(contractAddress != address(0), "INVALID_CONTRACT_ZERO_ADDRESS");
        IERC1155(contractAddress).safeBatchTransferFrom(address(this), to, ids, values, "");
    }

    /// @dev Private function used to transfer the ERC721tokens specified in a specific claim.
    /// @param to The destination address for the claimed tokens.
    /// @param ids The array of ERC721 ids.
    /// @param contractAddress The ERC721 token contract address.
    function _transferERC721(
        address to,
        uint256[] memory ids,
        address contractAddress
    ) private {
        require(contractAddress != address(0), "INVALID_CONTRACT_ZERO_ADDRESS");
        IERC721Extended(contractAddress).safeBatchTransferFrom(address(this), to, ids, "");
    }

    /// @dev Private function used to transfer the ERC20 tokens specified in a specific claim.
    /// @param to The destination address for the claimed tokens.
    /// @param amounts The array of amounts of ERC20 tokens to be transferred.
    /// @param contractAddresses The array of ERC20 token contract addresses.
    function _transferERC20(
        address to,
        uint256[] memory amounts,
        address[] memory contractAddresses
    ) private {
        for (uint256 i = 0; i < amounts.length; i++) {
            address erc20ContractAddress = contractAddresses[i];
            uint256 erc20Amount = amounts[i];
            require(erc20ContractAddress != address(0), "INVALID_CONTRACT_ZERO_ADDRESS");
            IERC20(erc20ContractAddress).safeTransferFrom(address(this), to, erc20Amount);
        }
    }
}

// SPDX-License-Identifier: MIT

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC721/IERC721.sol";

interface IERC721Extended is IERC721 {
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external;

    function burn(uint256 id) external;

    function burnFrom(address from, uint256 id) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @title Verify
 * @dev Merkle root comparison function.
 */
library Verify {
    /// @dev Check if the computedHash == comparisonHash.
    /// @param comparisonHash The merkle root hash passed to the function.
    /// @param proof The proof provided by the user.
    /// @param leaf The generated hash.
    /// @return Whether the computedHash == comparisonHash.
    function doesComputedHashMatchMerkleRootHash(
        bytes32 comparisonHash,
        bytes32[] memory proof,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == comparisonHash;
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

//SPDX-License-Identifier: MIT
/* solhint-disable func-order, code-complexity */
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "@openzeppelin/contracts-0.8/token/ERC721/IERC721Receiver.sol";
import "./WithSuperOperators.sol";
import "../interfaces/IERC721MandatoryTokenReceiver.sol";
import "@openzeppelin/contracts-0.8/token/ERC721/IERC721.sol";
import "./ERC2771Handler.sol";

contract ERC721BaseToken is IERC721, WithSuperOperators, ERC2771Handler {
    using Address for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _ERC721_BATCH_RECEIVED = 0x4b808c46;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;
    bytes4 internal constant ERC721_MANDATORY_RECEIVER = 0x5e8bf644;

    uint256 internal constant NOT_ADDRESS = 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000;
    uint256 internal constant OPERATOR_FLAG = (2**255);
    uint256 internal constant NOT_OPERATOR_FLAG = OPERATOR_FLAG - 1;
    uint256 internal constant BURNED_FLAG = (2**160);

    mapping(address => uint256) internal _numNFTPerAddress;
    mapping(uint256 => uint256) internal _owners;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    mapping(uint256 => address) internal _operators;

    /// @notice Approve an operator to spend tokens on the senders behalf.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approve(address operator, uint256 id) external override {
        uint256 ownerData = _owners[_storageId(id)];
        address owner = address(uint160(ownerData));
        address msgSender = _msgSender();
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(
            owner == msgSender || _superOperators[msgSender] || _operatorsForAll[owner][msgSender],
            "UNAUTHORIZED_APPROVAL"
        );
        _approveFor(ownerData, operator, id);
    }

    /// @notice Approve an operator to spend tokens on the sender behalf.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external {
        uint256 ownerData = _owners[_storageId(id)];
        address msgSender = _msgSender();
        require(sender != address(0), "ZERO_ADDRESS_SENDER");
        require(
            msgSender == sender || _superOperators[msgSender] || _operatorsForAll[sender][msgSender],
            "UNAUTHORIZED_APPROVAL"
        );
        require(address(uint160(ownerData)) == sender, "OWNER_NOT_SENDER");
        _approveFor(ownerData, operator, id);
    }

    /// @notice Transfer a token between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            require(_checkOnERC721Received(_msgSender(), from, to, id, ""), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Transfer a token between 2 addresses letting the receiver know of the transfer.
    /// @param from The send of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Transfer many tokens between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, false);
    }

    /// @notice Transfer many tokens between 2 addresses, while
    /// ensuring the receiving contract has a receiver method.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, true);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender != address(0), "Invalid sender address");
        address msgSender = _msgSender();
        require(msgSender == sender || _superOperators[msgSender], "UNAUTHORIZED_APPROVE_FOR_ALL");

        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAll(address operator, bool approved) external override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Burns token `id`.
    /// @param id The token which will be burnt.
    function burn(uint256 id) external virtual {
        _burn(_msgSender(), _ownerOf(id), id);
    }

    /// @notice Burn token`id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id The token which will be burnt.
    function burnFrom(address from, uint256 id) external virtual {
        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        address msgSender = _msgSender();
        require(
            msgSender == from ||
                (operatorEnabled && _operators[id] == msgSender) ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender],
            "UNAUTHORIZED_BURN"
        );
        _burn(from, owner, id);
    }

    /// @notice Get the number of tokens owned by an address.
    /// @param owner The address to look for.
    /// @return The number of tokens owned by the address.
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS_OWNER");
        return _numNFTPerAddress[owner];
    }

    /// @notice Get the owner of a token.
    /// @param id The id of the token.
    /// @return owner The address of the token owner.
    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NONEXISTANT_TOKEN");
    }

    /// @notice Get the approved operator for a specific token.
    /// @param id The id of the token.
    /// @return The address of the operator.
    function getApproved(uint256 id) external view override returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    /// @notice Check if the sender approved the operator.
    /// @param owner The address of the owner.
    /// @param operator The address of the operator.
    /// @return isOperator The status of the approval.
    function isApprovedForAll(address owner, address operator) external view override returns (bool isOperator) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    /// @notice Transfer a token between 2 addresses letting the receiver knows of the transfer.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    /// @param data Additional data.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(_msgSender(), from, to, id, data), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Check if the contract supports an interface.
    /// 0x01ffc9a7 is ERC-165.
    /// 0x80ac58cd is ERC-721
    /// @param id The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 id) public pure virtual override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }

    /// @dev By overriding this function in an implementation which inherits this contract, you can enable versioned tokenIds without the extra overhead of writing to a new storage slot in _owners each time a version is incremented. See GameToken._storageId() for an example, where the storageId is the tokenId minus the version number.
    /// !!! Caution !!! Overriding this function without taking appropriate care could lead to
    /// ownerOf() returning an owner for non-existent tokens. Tests should be written to
    /// guard against introducing this bug.
    /// @param id The id of a token.
    /// @return The id used for storage mappings.
    function _storageId(uint256 id) internal view virtual returns (uint256) {
        return id;
    }

    function _updateOwnerData(
        uint256 id,
        uint256 oldData,
        address newOwner,
        bool hasOperator
    ) internal virtual {
        if (hasOperator) {
            _owners[_storageId(id)] = (oldData & NOT_ADDRESS) | OPERATOR_FLAG | uint256(uint160(newOwner));
        } else {
            _owners[_storageId(id)] = ((oldData & NOT_ADDRESS) & NOT_OPERATOR_FLAG) | uint256(uint160(newOwner));
        }
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _numNFTPerAddress[from]--;
        _numNFTPerAddress[to]++;
        _updateOwnerData(id, _owners[_storageId(id)], to, false);
        emit Transfer(from, to, id);
    }

    /// @dev See approveFor.
    function _approveFor(
        uint256 ownerData,
        address operator,
        uint256 id
    ) internal {
        address owner = address(uint160(ownerData));
        if (operator == address(0)) {
            _updateOwnerData(id, ownerData, owner, false);
        } else {
            _updateOwnerData(id, ownerData, owner, true);
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    /// @dev See batchTransferFrom.
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data,
        bool safe
    ) internal {
        address msgSender = _msgSender();
        bool authorized = msgSender == from || _superOperators[msgSender] || _operatorsForAll[from][msgSender];

        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        require(to != address(0), "NOT_TO_ZEROADDRESS");

        uint256 numTokens = ids.length;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 id = ids[i];
            (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
            require(owner == from, "BATCHTRANSFERFROM_NOT_OWNER");
            require(authorized || (operatorEnabled && _operators[id] == msgSender), "NOT_AUTHORIZED");
            _updateOwnerData(id, _owners[_storageId(id)], to, false);
            emit Transfer(from, to, id);
        }
        if (from != to) {
            _numNFTPerAddress[from] -= numTokens;
            _numNFTPerAddress[to] += numTokens;
        }

        if (to.isContract() && (safe || _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER))) {
            require(_checkOnERC721BatchReceived(msgSender, from, to, ids, data), "ERC721_BATCH_TRANSFER_REJECTED");
        }
    }

    /// @dev See setApprovalForAll.
    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "INVALID_APPROVAL_CHANGE");
        _operatorsForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    /// @dev See burn.
    function _burn(
        address from,
        address owner,
        uint256 id
    ) internal {
        require(from == owner, "NOT_OWNER");
        uint256 storageId = _storageId(id);
        _owners[storageId] = (_owners[storageId] & NOT_OPERATOR_FLAG) | BURNED_FLAG; // record as non owner but keep track of last owner
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
    }

    /// @dev Check if receiving contract accepts erc721 transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param tokenId The id of the token we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x150b7a02 is returned.
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721Receiver(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /// @dev Check if receiving contract accepts erc721 batch transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param ids The ids of the tokens we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x4b808c46 is returned.
    function _checkOnERC721BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721MandatoryTokenReceiver(to).onERC721BatchReceived(operator, from, ids, _data);
        return (retval == _ERC721_BATCH_RECEIVED);
    }

    /// @dev See ownerOf
    function _ownerOf(uint256 id) internal view virtual returns (address) {
        uint256 data = _owners[_storageId(id)];
        if ((data & BURNED_FLAG) == BURNED_FLAG) {
            return address(0);
        }
        return address(uint160(data));
    }

    /// @dev Get the owner and operatorEnabled status of a token.
    /// @param id The token to query.
    /// @return owner The owner of the token.
    /// @return operatorEnabled Whether or not operators are enabled for this token.
    function _ownerAndOperatorEnabledOf(uint256 id)
        internal
        view
        virtual
        returns (address owner, bool operatorEnabled)
    {
        uint256 data = _owners[_storageId(id)];
        if ((data & BURNED_FLAG) == BURNED_FLAG) {
            owner = address(0);
        } else {
            owner = address(uint160(data));
        }
        operatorEnabled = (data & OPERATOR_FLAG) == OPERATOR_FLAG;
    }

    /// @dev Check whether a transfer is a meta Transaction or not.
    /// @param from The address who initiated the transfer (may differ from msg.sender).
    /// @param to The address recieving the token.
    /// @param id The token being transferred.
    /// @return isMetaTx Whether or not the transaction is a MetaTx.
    function _checkTransfer(
        address from,
        address to,
        uint256 id
    ) internal view returns (bool isMetaTx) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        address msgSender = _msgSender();
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(owner == from, "CHECKTRANSFER_NOT_OWNER");
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(
            msgSender == owner ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender] ||
                (operatorEnabled && _operators[id] == msgSender),
            "UNAUTHORIZED_TRANSFER"
        );
        return true;
    }

    /// @dev Check if there was enough gas.
    /// @param _contract The address of the contract to check.
    /// @param interfaceId The id of the interface we want to test.
    /// @return Whether or not this check succeeded.
    function _checkInterfaceWith10000Gas(address _contract, bytes4 interfaceId) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory callData = abi.encodeWithSelector(ERC165ID, interfaceId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let call_ptr := add(0x20, callData)
            let call_size := mload(callData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @dev Note: The ERC-165 identifier for this interface is 0x5e8bf644.
interface IERC721MandatoryTokenReceiver {
    function onERC721BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x4b808c46

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x150b7a02

    // needs to implements EIP-165
    // function supportsInterface(bytes4 interfaceId)
    //     external
    //     view
    //     returns (bool);
}

// SPDX-License-Identifier: MIT
// solhint-disable code-complexity

pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "../../../common/BaseWithStorage/ERC721BaseToken.sol";

contract PolygonLandBaseToken is ERC721BaseToken {
    using Address for address;

    uint256 internal constant GRID_SIZE = 408;

    uint256 internal constant LAYER = 0xFF00000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_1x1 = 0x0000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_3x3 = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_6x6 = 0x0200000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_12x12 = 0x0300000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_24x24 = 0x0400000000000000000000000000000000000000000000000000000000000000;

    /**
     * @notice Return the name of the token contract
     * @return The name of the token contract
     */
    function name() public view returns (string memory) {
        return "Sandbox's LANDs";
    }

    /**
     * @notice Return the symbol of the token contract
     * @return The symbol of the token contract
     */
    function symbol() public view returns (string memory) {
        return "LAND";
    }

    /// @notice total width of the map
    /// @return width
    function width() public view returns (uint256) {
        return GRID_SIZE;
    }

    /// @notice total height of the map
    /// @return height
    function height() public view returns (uint256) {
        return GRID_SIZE;
    }

    /// @notice x coordinate of Land token
    /// @param id tokenId
    /// @return the x coordinates
    function x(uint256 id) public view returns (uint256) {
        require(_ownerOf(id) != address(0), "token does not exist");
        return id % GRID_SIZE;
    }

    /// @notice y coordinate of Land token
    /// @param id tokenId
    /// @return the y coordinates
    function y(uint256 id) public view returns (uint256) {
        require(_ownerOf(id) != address(0), "token does not exist");
        return id / GRID_SIZE;
    }

    // solium-disable-next-line security/no-assign-params
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @notice Return the URI of a specific token
     * @param id The id of the token
     * @return The URI of the token
     */
    function tokenURI(uint256 id) public view returns (string memory) {
        require(_ownerOf(id) != address(0), "Id does not exist");
        return string(abi.encodePacked("https://api.sandbox.game/lands/", uint2str(id), "/metadata.json"));
    }

    /**
     * @notice Check if the contract supports an interface
     * 0x01ffc9a7 is ERC-165
     * 0x80ac58cd is ERC-721
     * 0x5b5e139f is ERC-721 metadata
     * @param id The id of the interface
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 id) public pure override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
    }

    /**
     * @notice Mint a new quad (aligned to a quad tree with size 3, 6, 12 or 24 only)
     * @param to The recipient of the new quad
     * @param size The size of the new quad
     * @param x The top left x coordinate of the new quad
     * @param y The top left y coordinate of the new quad
     * @param data extra data to pass to the transfer
     */
    function _mintQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) internal {
        require(to != address(0), "to is zero address");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        require(x <= GRID_SIZE - size && y <= GRID_SIZE - size, "Out of bounds");

        uint256 quadId;
        uint256 id = x + y * GRID_SIZE;

        if (size == 1) {
            quadId = id;
        } else if (size == 3) {
            quadId = LAYER_3x3 + id;
        } else if (size == 6) {
            quadId = LAYER_6x6 + id;
        } else if (size == 12) {
            quadId = LAYER_12x12 + id;
        } else if (size == 24) {
            quadId = LAYER_24x24 + id;
        } else {
            require(false, "Invalid size");
        }

        require(_owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE] == 0, "Already minted as 24x24");

        uint256 toX = x + size;
        uint256 toY = y + size;
        if (size <= 12) {
            require(_owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE] == 0, "Already minted as 12x12");
        } else {
            for (uint256 x12i = x; x12i < toX; x12i += 12) {
                for (uint256 y12i = y; y12i < toY; y12i += 12) {
                    uint256 id12x12 = LAYER_12x12 + x12i + y12i * GRID_SIZE;
                    require(_owners[id12x12] == 0, "Already minted as 12x12");
                }
            }
        }

        if (size <= 6) {
            require(_owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE] == 0, "Already minted as 6x6");
        } else {
            for (uint256 x6i = x; x6i < toX; x6i += 6) {
                for (uint256 y6i = y; y6i < toY; y6i += 6) {
                    uint256 id6x6 = LAYER_6x6 + x6i + y6i * GRID_SIZE;
                    require(_owners[id6x6] == 0, "Already minted as 6x6");
                }
            }
        }

        if (size <= 3) {
            require(_owners[LAYER_3x3 + (x / 3) * 3 + ((y / 3) * 3) * GRID_SIZE] == 0, "Already minted as 3x3");
        } else {
            for (uint256 x3i = x; x3i < toX; x3i += 3) {
                for (uint256 y3i = y; y3i < toY; y3i += 3) {
                    uint256 id3x3 = LAYER_3x3 + x3i + y3i * GRID_SIZE;
                    require(_owners[id3x3] == 0, "Already minted as 3x3");
                }
            }
        }

        for (uint256 i = 0; i < size * size; i++) {
            uint256 idPath = _idInPath(i, size, x, y);
            require(_owners[id] == 0, "Already minted");
            emit Transfer(address(0), to, idPath);
        }

        _owners[quadId] = uint256(uint160(address(to)));
        _numNFTPerAddress[to] += size * size;

        _checkBatchReceiverAcceptQuad(_msgSender(), address(0), to, size, x, y, data);
    }

    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external {
        require(from != address(0), "from is zero address");
        require(to != address(0), "can't send to zero address");
        require(sizes.length == xs.length && xs.length == ys.length, "invalid data");
        if (_msgSender() != from) {
            require(
                _superOperators[_msgSender()] || _operatorsForAll[from][_msgSender()],
                "not authorized to transferMultiQuads"
            );
        }
        uint256 numTokensTransfered = 0;
        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 size = sizes[i];
            _transferQuad(from, to, size, xs[i], ys[i]);
            numTokensTransfered += size * size;
        }
        _numNFTPerAddress[from] -= numTokensTransfered;
        _numNFTPerAddress[to] += numTokensTransfered;

        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            uint256[] memory ids = new uint256[](numTokensTransfered);
            uint256 counter = 0;
            for (uint256 j = 0; j < sizes.length; j++) {
                uint256 size = sizes[j];
                for (uint256 i = 0; i < size * size; i++) {
                    ids[counter] = _idInPath(i, size, xs[j], ys[j]);
                    counter++;
                }
            }
            require(
                _checkOnERC721BatchReceived(_msgSender(), from, to, ids, data),
                "erc721 batch transfer rejected by to"
            );
        }
    }

    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external {
        require(from != address(0), "from is zero address");
        require(to != address(0), "can't send to zero address");
        if (_msgSender() != from) {
            require(
                _superOperators[_msgSender()] || _operatorsForAll[from][_msgSender()],
                "not authorized to transferQuad"
            );
        }
        _transferQuad(from, to, size, x, y);
        _numNFTPerAddress[from] -= size * size;
        _numNFTPerAddress[to] += size * size;

        _checkBatchReceiverAcceptQuad(_msgSender(), from, to, size, x, y, data);
    }

    function exists(
        uint256 size,
        uint256 x,
        uint256 y
    ) external view returns (bool) {
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        require(x <= GRID_SIZE - size && y <= GRID_SIZE - size, "Out of bounds");

        uint256 quadId;
        uint256 id = x + y * GRID_SIZE;

        if (size == 1) {
            quadId = id;
        } else if (size == 3) {
            quadId = LAYER_3x3 + id;
        } else if (size == 6) {
            quadId = LAYER_6x6 + id;
        } else if (size == 12) {
            quadId = LAYER_12x12 + id;
        } else if (size == 24) {
            quadId = LAYER_24x24 + id;
        } else {
            require(false, "Invalid size");
        }

        if (_owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE] != 0) return true;
        uint256 toX = x + size;
        uint256 toY = y + size;
        if (size <= 12) {
            if (_owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE] != 0) return true;
        } else {
            for (uint256 x12i = x; x12i < toX; x12i += 12) {
                for (uint256 y12i = y; y12i < toY; y12i += 12) {
                    uint256 id12x12 = LAYER_12x12 + x12i + y12i * GRID_SIZE;
                    if (_owners[id12x12] != 0) return true;
                }
            }
        }

        if (size <= 6) {
            if (_owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE] != 0) return true;
        } else {
            for (uint256 x6i = x; x6i < toX; x6i += 6) {
                for (uint256 y6i = y; y6i < toY; y6i += 6) {
                    uint256 id6x6 = LAYER_6x6 + x6i + y6i * GRID_SIZE;
                    if (_owners[id6x6] != 0) return true;
                }
            }
        }

        if (size <= 3) {
            if (_owners[LAYER_3x3 + (x / 3) * 3 + ((y / 3) * 3) * GRID_SIZE] != 0) return true;
        } else {
            for (uint256 x3i = x; x3i < toX; x3i += 3) {
                for (uint256 y3i = y; y3i < toY; y3i += 3) {
                    uint256 id3x3 = LAYER_3x3 + x3i + y3i * GRID_SIZE;
                    if (_owners[id3x3] != 0) return true;
                }
            }
        }

        for (uint256 i = 0; i < size * size; i++) {
            if (_owners[id] != 0) return true;
        }
        return false;
    }

    function _transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal {
        if (size == 1) {
            uint256 id1x1 = x + y * GRID_SIZE;
            address owner = _ownerOf(id1x1);
            require(owner != address(0), "token does not exist");
            require(owner == from, "not owner in _transferQuad");
            _owners[id1x1] = uint256(uint160(address(to)));
        } else {
            _regroup(from, to, size, x, y);
        }
        for (uint256 i = 0; i < size * size; i++) {
            emit Transfer(from, to, _idInPath(i, size, x, y));
        }
    }

    function _idInPath(
        uint256 i,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        uint256 row = i / size;
        if (row % 2 == 0) {
            // alow ids to follow a path in a quad
            return (x + (i % size)) + ((y + row) * GRID_SIZE);
        } else {
            return ((x + size) - (1 + (i % size))) + ((y + row) * GRID_SIZE);
        }
    }

    function _regroup(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal {
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        require(x <= GRID_SIZE - size && y <= GRID_SIZE - size, "Out of bounds");

        if (size == 3) {
            _regroup3x3(from, to, x, y, true);
        } else if (size == 6) {
            _regroup6x6(from, to, x, y, true);
        } else if (size == 12) {
            _regroup12x12(from, to, x, y, true);
        } else if (size == 24) {
            _regroup24x24(from, to, x, y, true);
        } else {
            require(false, "Invalid size");
        }
    }

    function _regroup3x3(
        address from,
        address to,
        uint256 x,
        uint256 y,
        bool set
    ) internal returns (bool) {
        uint256 id = x + y * GRID_SIZE;
        uint256 quadId = LAYER_3x3 + id;
        bool ownerOfAll = true;
        for (uint256 xi = x; xi < x + 3; xi++) {
            for (uint256 yi = y; yi < y + 3; yi++) {
                ownerOfAll = _checkAndClear(from, xi + yi * GRID_SIZE) && ownerOfAll;
            }
        }
        if (set) {
            if (!ownerOfAll) {
                require(
                    _owners[quadId] == uint256(uint160(address(from))) ||
                        _owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE] ==
                        uint256(uint160(address(from))) ||
                        _owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE] ==
                        uint256(uint160(address(from))) ||
                        _owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE] ==
                        uint256(uint160(address(from))),
                    "not owner of all sub quads nor parent quads"
                );
            }
            _owners[quadId] = uint256(uint160(address(to)));
            return true;
        }
        return ownerOfAll;
    }

    function _regroup6x6(
        address from,
        address to,
        uint256 x,
        uint256 y,
        bool set
    ) internal returns (bool) {
        uint256 id = x + y * GRID_SIZE;
        uint256 quadId = LAYER_6x6 + id;
        bool ownerOfAll = true;
        for (uint256 xi = x; xi < x + 6; xi += 3) {
            for (uint256 yi = y; yi < y + 6; yi += 3) {
                bool ownAllIndividual = _regroup3x3(from, to, xi, yi, false);
                uint256 id3x3 = LAYER_3x3 + xi + yi * GRID_SIZE;
                uint256 owner3x3 = _owners[id3x3];
                if (owner3x3 != 0) {
                    if (!ownAllIndividual) {
                        require(owner3x3 == uint256(uint160(address(from))), "not owner of 3x3 quad");
                    }
                    _owners[id3x3] = 0;
                }
                ownerOfAll = (ownAllIndividual || owner3x3 != 0) && ownerOfAll;
            }
        }
        if (set) {
            if (!ownerOfAll) {
                require(
                    _owners[quadId] == uint256(uint160(address(from))) ||
                        _owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE] ==
                        uint256(uint160(address(from))) ||
                        _owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE] ==
                        uint256(uint160(address(from))),
                    "not owner of all sub quads nor parent quads"
                );
            }
            _owners[quadId] = uint256(uint160(address(to)));
            return true;
        }
        return ownerOfAll;
    }

    function _regroup12x12(
        address from,
        address to,
        uint256 x,
        uint256 y,
        bool set
    ) internal returns (bool) {
        uint256 id = x + y * GRID_SIZE;
        uint256 quadId = LAYER_12x12 + id;
        bool ownerOfAll = true;
        for (uint256 xi = x; xi < x + 12; xi += 6) {
            for (uint256 yi = y; yi < y + 12; yi += 6) {
                bool ownAllIndividual = _regroup6x6(from, to, xi, yi, false);
                uint256 id6x6 = LAYER_6x6 + xi + yi * GRID_SIZE;
                uint256 owner6x6 = _owners[id6x6];
                if (owner6x6 != 0) {
                    if (!ownAllIndividual) {
                        require(owner6x6 == uint256(uint160(address(from))), "not owner of 6x6 quad");
                    }
                    _owners[id6x6] = 0;
                }
                ownerOfAll = (ownAllIndividual || owner6x6 != 0) && ownerOfAll;
            }
        }
        if (set) {
            if (!ownerOfAll) {
                require(
                    _owners[quadId] == uint256(uint160(address(from))) ||
                        _owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE] ==
                        uint256(uint160(address(from))),
                    "not owner of all sub quads nor parent quads"
                );
            }
            _owners[quadId] = uint256(uint160(address(to)));
            return true;
        }
        return ownerOfAll;
    }

    function _regroup24x24(
        address from,
        address to,
        uint256 x,
        uint256 y,
        bool set
    ) internal returns (bool) {
        uint256 id = x + y * GRID_SIZE;
        uint256 quadId = LAYER_24x24 + id;
        bool ownerOfAll = true;
        for (uint256 xi = x; xi < x + 24; xi += 12) {
            for (uint256 yi = y; yi < y + 24; yi += 12) {
                bool ownAllIndividual = _regroup12x12(from, to, xi, yi, false);
                uint256 id12x12 = LAYER_12x12 + xi + yi * GRID_SIZE;
                uint256 owner12x12 = _owners[id12x12];
                if (owner12x12 != 0) {
                    if (!ownAllIndividual) {
                        require(owner12x12 == uint256(uint160(address(from))), "not owner of 12x12 quad");
                    }
                    _owners[id12x12] = 0;
                }
                ownerOfAll = (ownAllIndividual || owner12x12 != 0) && ownerOfAll;
            }
        }
        if (set) {
            if (!ownerOfAll) {
                require(
                    _owners[quadId] == uint256(uint160(address(from))),
                    "not owner of all sub quads not parent quad"
                );
            }
            _owners[quadId] = uint256(uint160(address(to)));
            return true;
        }
        return ownerOfAll || _owners[quadId] == uint256(uint160(address(from)));
    }

    function _ownerOf(uint256 id) internal view override returns (address) {
        require(id & LAYER == 0, "Invalid token id");
        uint256 x = id % GRID_SIZE;
        uint256 y = id / GRID_SIZE;
        uint256 owner1x1 = _owners[id];

        if (owner1x1 != 0) {
            return address(uint160(owner1x1)); //we check if the quad exists as an 1x1 quad, then 3x3, and so on..
        } else {
            address owner3x3 = address(uint160(_owners[LAYER_3x3 + (x / 3) * 3 + ((y / 3) * 3) * GRID_SIZE]));
            if (owner3x3 != address(0)) {
                return owner3x3;
            } else {
                address owner6x6 = address(uint160(_owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE]));
                if (owner6x6 != address(0)) {
                    return owner6x6;
                } else {
                    address owner12x12 =
                        address(uint160(_owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE]));
                    if (owner12x12 != address(0)) {
                        return owner12x12;
                    } else {
                        return address(uint160(_owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE]));
                    }
                }
            }
        }
    }

    function _checkAndClear(address from, uint256 id) internal returns (bool) {
        uint256 owner = _owners[id];
        if (owner != 0) {
            require(address(uint160(owner)) == from, "not owner");
            _owners[id] = 0;
            return true;
        }
        return false;
    }

    function _checkBatchReceiverAcceptQuad(
        address operator,
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) internal {
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            uint256[] memory ids = new uint256[](size * size);
            for (uint256 i = 0; i < size * size; i++) {
                ids[i] = _idInPath(i, size, x, y);
            }
            require(_checkOnERC721BatchReceived(operator, from, to, ids, data), "erc721 batch transfer rejected by to");
        }
    }

    function _ownerAndOperatorEnabledOf(uint256 id)
        internal
        view
        override
        returns (address owner, bool operatorEnabled)
    {
        require(id & LAYER == 0, "Invalid token id");
        uint256 x = id % GRID_SIZE;
        uint256 y = id / GRID_SIZE;
        uint256 owner1x1 = _owners[id];

        if (owner1x1 != 0) {
            owner = address(uint160(owner1x1));
            operatorEnabled = (owner1x1 / 2**255) == 1;
        } else {
            address owner3x3 = address(uint160(_owners[LAYER_3x3 + (x / 3) * 3 + ((y / 3) * 3) * GRID_SIZE]));
            if (owner3x3 != address(uint160(0))) {
                owner = owner3x3;
                operatorEnabled = false;
            } else {
                address owner6x6 = address(uint160(_owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE]));
                if (owner6x6 != address(uint160(0))) {
                    owner = owner6x6;
                    operatorEnabled = false;
                } else {
                    address owner12x12 =
                        address(uint160(_owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE]));
                    if (owner12x12 != address(uint160(0))) {
                        owner = owner12x12;
                        operatorEnabled = false;
                    } else {
                        owner = address(uint160(_owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE]));
                        operatorEnabled = false;
                    }
                }
            }
        }
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable code-complexity
pragma solidity 0.8.2;

import "../polygon/child/land/PolygonLandBaseToken.sol";

contract MockLandWithMint is PolygonLandBaseToken {
    using Address for address;

    /***
     **
     * @notice Mint a new quad (aligned to a quad tree with size 3, 6, 12 or 24 only)
     * @param to The recipient of the new quad
     * @param size The size of the new quad
     * @param x The top left x coordinate of the new quad
     * @param y The top left y coordinate of the new quad
     * @param data extra data to pass to the transfer
     */
    function mintQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external {
        require(to != address(0), "to is zero address");
        //require(isMinter(msg.sender), "Only a minter can mint");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        require(x <= GRID_SIZE - size && y <= GRID_SIZE - size, "Out of bounds");

        uint256 quadId;
        uint256 id = x + y * GRID_SIZE;

        if (size == 1) {
            quadId = id;
        } else if (size == 3) {
            quadId = LAYER_3x3 + id;
        } else if (size == 6) {
            quadId = LAYER_6x6 + id;
        } else if (size == 12) {
            quadId = LAYER_12x12 + id;
        } else if (size == 24) {
            quadId = LAYER_24x24 + id;
        } else {
            require(false, "Invalid size");
        }

        require(_owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE] == 0, "Already minted as 24x24");

        uint256 toX = x + size;
        uint256 toY = y + size;
        if (size <= 12) {
            require(_owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE] == 0, "Already minted as 12x12");
        } else {
            for (uint256 x12i = x; x12i < toX; x12i += 12) {
                for (uint256 y12i = y; y12i < toY; y12i += 12) {
                    uint256 id12x12 = LAYER_12x12 + x12i + y12i * GRID_SIZE;
                    require(_owners[id12x12] == 0, "Already minted as 12x12");
                }
            }
        }

        if (size <= 6) {
            require(_owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE] == 0, "Already minted as 6x6");
        } else {
            for (uint256 x6i = x; x6i < toX; x6i += 6) {
                for (uint256 y6i = y; y6i < toY; y6i += 6) {
                    uint256 id6x6 = LAYER_6x6 + x6i + y6i * GRID_SIZE;
                    require(_owners[id6x6] == 0, "Already minted as 6x6");
                }
            }
        }

        if (size <= 3) {
            require(_owners[LAYER_3x3 + (x / 3) * 3 + ((y / 3) * 3) * GRID_SIZE] == 0, "Already minted as 3x3");
        } else {
            for (uint256 x3i = x; x3i < toX; x3i += 3) {
                for (uint256 y3i = y; y3i < toY; y3i += 3) {
                    uint256 id3x3 = LAYER_3x3 + x3i + y3i * GRID_SIZE;
                    require(_owners[id3x3] == 0, "Already minted as 3x3");
                }
            }
        }

        for (uint256 i = 0; i < size * size; i++) {
            uint256 idPath = _idInPath(i, size, x, y);
            require(_owners[id] == 0, "Already minted");
            emit Transfer(address(0), to, idPath);
        }

        _owners[quadId] = uint256(uint160(address(to)));
        _numNFTPerAddress[to] += size * size;

        _checkBatchReceiverAcceptQuad(msg.sender, address(0), to, size, x, y, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";

import "../../../common/interfaces/IPolygonLand.sol";
import "../../../common/interfaces/IERC721MandatoryTokenReceiver.sol";
import "../../../common/BaseWithStorage/ERC2771Handler.sol";
import "./PolygonLandBaseToken.sol";

// @todo - natspec comments

contract PolygonLandTunnel is FxBaseChildTunnel, IERC721MandatoryTokenReceiver, ERC2771Handler, Ownable {
    IPolygonLand public childToken;
    uint32 public maxGasLimitOnL1 = 500;
    uint256 public maxAllowedQuads = 144;
    mapping(uint8 => uint32) public gasLimits;

    event SetGasLimit(uint8 size, uint32 limit);
    event SetMaxGasLimit(uint32 maxGasLimit);
    event SetMaxAllowedQuads(uint256 maxQuads);

    function setMaxLimitOnL1(uint32 _maxGasLimit) external onlyOwner {
        maxGasLimitOnL1 = _maxGasLimit;
        emit SetMaxGasLimit(_maxGasLimit);
    }

    function setMaxAllowedQuads(uint256 _maxAllowedQuads) external onlyOwner {
        maxAllowedQuads = _maxAllowedQuads;
        emit SetMaxAllowedQuads(_maxAllowedQuads);
    }

    function _setLimit(uint8 size, uint32 limit) internal {
        gasLimits[size] = limit;
        emit SetGasLimit(size, limit);
    }

    function setLimit(uint8 size, uint32 limit) external onlyOwner {
        _setLimit(size, limit);
    }

    // setupLimits([5, 10, 20, 90, 340]);
    function setupLimits(uint32[5] calldata limits) external onlyOwner {
        _setLimit(1, limits[0]);
        _setLimit(3, limits[1]);
        _setLimit(6, limits[2]);
        _setLimit(12, limits[3]);
        _setLimit(24, limits[4]);
    }

    constructor(
        address _fxChild,
        IPolygonLand _childToken,
        address _trustedForwarder
    ) FxBaseChildTunnel(_fxChild) {
        childToken = _childToken;
        __ERC2771Handler_initialize(_trustedForwarder);
    }

    function batchTransferQuadToL1(
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes memory data
    ) external {
        require(sizes.length == xs.length && sizes.length == ys.length, "sizes, xs, ys must be same length");

        uint32 gasLimit = 0;
        uint256 quads = 0;
        for (uint256 i = 0; i < sizes.length; i++) {
            gasLimit += gasLimits[uint8(sizes[i])];
            quads += sizes[i] * sizes[i];
        }

        require(quads <= maxAllowedQuads, "Exceeds max allowed quads.");
        require(gasLimit < maxGasLimitOnL1, "Exceeds gas limit on L1.");
        for (uint256 i = 0; i < sizes.length; i++) {
            childToken.transferQuad(_msgSender(), address(this), sizes[i], xs[i], ys[i], data);
        }
        _sendMessageToRoot(abi.encode(to, sizes, xs, ys, data));
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        _syncDeposit(data);
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address to, uint256 size, uint256 x, uint256 y, bytes memory data) =
            abi.decode(syncData, (address, uint256, uint256, uint256, bytes));
        if (!childToken.exists(size, x, y)) childToken.mint(to, size, x, y, data);
        else childToken.transferQuad(address(this), to, size, x, y, data);
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC721BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == 0x5e8bf644 || interfaceId == 0x01ffc9a7;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ILandToken.sol";

interface IPolygonLand is LandToken {
    function mint(
        address user,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) external;

    // @temp - Will remove once locking mechanism has been tested
    // function exit(uint256 tokenId) external;

    function exists(
        uint256 size,
        uint256 x,
        uint256 y
    ) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface LandToken {
    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external;

    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
import "../../../common/interfaces/ILandToken.sol";
import "../../../common/interfaces/IERC721MandatoryTokenReceiver.sol";
import "../../../common/BaseWithStorage/ERC2771Handler.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";

// @todo - natspec comments

contract LandTunnel is FxBaseRootTunnel, IERC721MandatoryTokenReceiver, ERC2771Handler, Ownable {
    address public rootToken;

    event Deposit(address user, uint256 size, uint256 x, uint256 y, bytes data);
    event Withdraw(address user, uint256 size, uint256 x, uint256 y, bytes data);

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _rootToken,
        address _trustedForwarder
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        rootToken = _rootToken;
        __ERC2771Handler_initialize(_trustedForwarder);
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC721BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == 0x5e8bf644 || interfaceId == 0x01ffc9a7;
    }

    function batchTransferQuadToL2(
        address to,
        uint256[] memory sizes,
        uint256[] memory xs,
        uint256[] memory ys,
        bytes memory data
    ) public {
        require(sizes.length == xs.length && xs.length == ys.length, "l2: invalid data");
        LandToken(rootToken).batchTransferQuad(_msgSender(), address(this), sizes, xs, ys, data);

        for (uint256 index = 0; index < sizes.length; index++) {
            bytes memory message = abi.encode(to, sizes[index], xs[index], ys[index], data);
            _sendMessageToChild(message);
            emit Deposit(to, sizes[index], xs[index], ys[index], data);
        }
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function _processMessageFromChild(bytes memory message) internal override {
        (address to, uint256[] memory size, uint256[] memory x, uint256[] memory y, bytes memory data) =
            abi.decode(message, (address, uint256[], uint256[], uint256[], bytes));
        for (uint256 index = 0; index < x.length; index++) {
            LandToken(rootToken).transferQuad(address(this), to, size[index], x[index], y[index], data);
            emit Withdraw(to, size[index], x[index], y[index], data);
        }
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {RLPReader} from "../lib/RLPReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";
import {Merkle} from "../lib/Merkle.sol";
import "../lib/ExitPayloadReader.sol";


interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IFxStateSender public fxRoot;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages 
    address public fxChildTunnel;

    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    constructor(address _checkpointManager, address _fxRoot) {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
    }

    // set fxChildTunnel if not set already
    function setFxChildTunnel(address _fxChildTunnel) public {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }

    function _validateAndExtractMessage(bytes memory inputData) internal returns (bytes memory) {
        ExitPayloadReader.ExitPayload memory payload = inputData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );
        require(
            processedExits[exitHash] == false,
            "FxRootTunnel: EXIT_ALREADY_PROCESSED"
        );
        processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        require(fxChildTunnel == log.getEmitter(), "FxRootTunnel: INVALID_FX_CHILD_TUNNEL");

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(
                receipt.toBytes(), 
                branchMaskBytes, 
                payload.getReceiptProof(), 
                receiptRoot
            ),
            "FxRootTunnel: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            blockNumber,
            payload.getBlockTime(),
            payload.getTxRoot(),
            receiptRoot,
            payload.getHeaderNumber(),
            payload.getBlockProof()
        );

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        require(
            bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "FxRootTunnel: INVALID_SIGNATURE"
        );

        // received message data
        (bytes memory message) = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view returns (uint256) {
        (
            bytes32 headerRoot,
            uint256 startBlock,
            ,
            uint256 createdAt,

        ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(
                abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)
            )
                .checkMembership(
                blockNumber-startBlock,
                headerRoot,
                blockProof
            ),
            "FxRootTunnel: INVALID_HEADER"
        );
        return createdAt;
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param inputData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(bytes memory inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);
        _processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) virtual internal;
}

/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
pragma solidity ^0.8.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param item RLP encoded bytes
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    function payloadLocation(RLPItem memory item) internal pure returns (uint, uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint memPtr = item.memPtr + offset;
        uint len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint memPtr, uint len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;
        
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;

        uint result;
        uint memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;
        
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (
                        keccak256(RLPReader.toBytes(currentNodeList[16])) ==
                        keccak256(value)
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(
                    RLPReader.toUintStrict(currentNodeList[nextPathNibble])
                );
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(
                    RLPReader.toBytes(currentNodeList[0]),
                    path,
                    pathPtr
                );
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (
                        keccak256(RLPReader.toBytes(currentNodeList[1])) ==
                        keccak256(value)
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str)
        private
        pure
        returns (bytes1)
    {
        return
            bytes1(
                n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2 ** proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

pragma solidity ^0.8.0;

import { RLPReader } from "./RLPReader.sol";

library ExitPayloadReader {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;

  uint8 constant WORD_SIZE = 32;

  struct ExitPayload {
    RLPReader.RLPItem[] data;
  }

  struct Receipt {
    RLPReader.RLPItem[] data;
    bytes raw;
    uint256 logIndex;
  }

  struct Log {
    RLPReader.RLPItem data;
    RLPReader.RLPItem[] list;
  }

  struct LogTopics {
    RLPReader.RLPItem[] data;
  }

  // copy paste of private copy() from RLPReader to avoid changing of existing contracts
  function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

  function toExitPayload(bytes memory data)
        internal
        pure
        returns (ExitPayload memory)
    {
        RLPReader.RLPItem[] memory payloadData = data
            .toRlpItem()
            .toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns(bytes memory) {
      return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns(bytes32) {
      return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns(bytes32) {
      return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns(Receipt memory receipt) {
      receipt.raw = payload.data[6].toBytes();
      RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

      if (receiptItem.isList()) {
          // legacy tx
          receipt.data = receiptItem.toList();
      } else {
          // pop first byte before parsting receipt
          bytes memory typedBytes = receipt.raw;
          bytes memory result = new bytes(typedBytes.length - 1);
          uint256 srcPtr;
          uint256 destPtr;
          assembly {
              srcPtr := add(33, typedBytes)
              destPtr := add(0x20, result)
          }

          copy(srcPtr, destPtr, result.length);
          receipt.data = result.toRlpItem().toList();
      }

      receipt.logIndex = getReceiptLogIndex(payload);
      return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns(bytes memory) {
      return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns(bytes memory) {
      return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[9].toUint();
    }
    
    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns(bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns(Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns(address) {
      return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns(LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns(bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns(bytes memory) {
      return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns(RLPReader.RLPItem memory) {
      return topics.data[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./LandTunnel.sol";

contract MockLandTunnel is LandTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _rootToken,
        address _trustedForwarder
    ) LandTunnel(_checkpointManager, _fxRoot, _rootToken, _trustedForwarder) {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
    }

    function receiveMessage(bytes memory message) public virtual override {
        _processMessageFromChild(message);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";

abstract contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    modifier onlyRewardDistributionOrAccount(address account) {
        require(
            _msgSender() == rewardDistribution || _msgSender() == account,
            "Caller is not reward distribution or account"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution) external onlyOwner {
        rewardDistribution = _rewardDistribution;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/utils/math/Math.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import "./IRewardDistributionRecipient.sol";
import "../../common/interfaces/IERC721.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 internal _stakeToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 stakeToken) {
        _stakeToken = stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _stakeToken.safeTransfer(msg.sender, amount);
    }
}

contract PolygonSANDRewardPool is LPTokenWrapper, IRewardDistributionRecipient {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant DURATION = 30 days; // Reward period

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    IERC20 internal _rewardToken;

    constructor(IERC20 stakeToken, IERC20 rewardToken) LPTokenWrapper(stakeToken) {
        _rewardToken = rewardToken;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    // Add Setter functions for every external contract

    function SetRewardLPToken(address newRewardToken) external onlyOwner {
        require(newRewardToken != address(0), "Bad RewardToken address");

        _rewardToken = IERC20(newRewardToken);
    }

    function SetStakeLPToken(address newStakeLPToken) external onlyOwner {
        require(newStakeLPToken != address(0), "Bad StakeToken address");

        _stakeToken = IERC20(newStakeLPToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./IERC165.sol";
import "./IERC721Events.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
/*interface*/
interface IERC721 is IERC165, IERC721Events {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    //   function exists(uint256 tokenId) external view returns (bool exists);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
 * @title ERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements interface `interfaceId`
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Events {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    // Duplicate event, ERC1155 ApprovalForAll
    // event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/utils/math/Math.sol";
import "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

import "../../common/Libraries/SafeMathWithRequire.sol";
import "./IRewardDistributionRecipient.sol";
import "../../common/interfaces/IERC721.sol";

contract PolygonLPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant DECIMALS_18 = 1000000000000000000;

    IERC20 internal _stakeToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 stakeToken) {
        _stakeToken = stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _stakeToken.safeTransfer(msg.sender, amount);
    }
}

///@notice Reward Pool based on unipool contract : https://github.com/Synthetixio/Unipool/blob/master/contracts/Unipool.sol
//with the addition of NFT multiplier reward
contract PolygonLandWeightedSANDRewardPool is PolygonLPTokenWrapper, IRewardDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathWithRequire for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event MultiplierComputed(address indexed user, uint256 multiplier, uint256 contribution);

    uint256 public immutable duration;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 internal constant DECIMALS_9 = 1000000000;
    uint256 internal constant MIDPOINT_9 = 500000000;
    uint256 internal constant NFT_FACTOR_6 = 10000;
    uint256 internal constant NFT_CONSTANT_3 = 9000;
    uint256 internal constant ROOT3_FACTOR = 697;

    IERC20 internal _rewardToken;
    IERC721 internal _multiplierNFToken;

    uint256 internal _totalContributions;
    mapping(address => uint256) internal _multipliers;
    mapping(address => uint256) internal _contributions;

    constructor(
        IERC20 stakeToken,
        IERC20 rewardToken,
        IERC721 multiplierNFToken,
        uint256 rewardDuration
    ) PolygonLPTokenWrapper(stakeToken) {
        _rewardToken = rewardToken;
        _multiplierNFToken = multiplierNFToken;
        duration = rewardDuration;
    }

    function totalContributions() public view returns (uint256) {
        return _totalContributions;
    }

    function contributionOf(address account) public view returns (uint256) {
        return _contributions[account];
    }

    function multiplierOf(address account) public view returns (uint256) {
        return _multipliers[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();

        if (block.timestamp >= periodFinish || _totalContributions != 0) {
            // ensure reward past the first staker do not get lost
            lastUpdateTime = lastTimeRewardApplicable();
        }
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalContributions() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e24).div(totalContributions())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            contributionOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e24).add(
                rewards[account]
            );
    }

    function computeContribution(uint256 amountStaked, uint256 numLands) public pure returns (uint256) {
        if (numLands == 0) {
            return amountStaked;
        }
        uint256 nftContrib = NFT_FACTOR_6.mul(NFT_CONSTANT_3.add(numLands.sub(1).mul(ROOT3_FACTOR).add(1).cbrt3()));
        if (nftContrib > MIDPOINT_9) {
            nftContrib = MIDPOINT_9.add(nftContrib.sub(MIDPOINT_9).div(10));
        }
        return amountStaked.add(amountStaked.mul(nftContrib).div(DECIMALS_9));
    }

    function updateContribution(address account) internal {
        _totalContributions = _totalContributions.sub(contributionOf(account));
        _multipliers[account] = _multiplierNFToken.balanceOf(account);

        uint256 contribution = computeContribution(balanceOf(account), multiplierOf(account));

        _totalContributions = _totalContributions.add(contribution);
        _contributions[account] = contribution;
    }

    function computeMultiplier(address account) public onlyRewardDistributionOrAccount(account) updateReward(account) {
        updateContribution(account);

        emit MultiplierComputed(account, multiplierOf(account), contributionOf(account));
    }

    function stake(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        super.stake(amount);

        updateContribution(msg.sender);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        super.withdraw(amount);

        updateContribution(msg.sender);

        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    ///@notice to be called after the amount of reward tokens (specified by the reward parameter) has been sent to the contract
    // Note that the reward should be divisible by the duration to avoid reward token lost
    ///@param reward number of token to be distributed over the duration
    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    // Add Setter functions for every external contract

    function SetRewardToken(address newRewardToken) external onlyOwner {
        require(newRewardToken.isContract(), "Bad RewardToken address");

        _rewardToken = IERC20(newRewardToken);
    }

    function SetStakeLPToken(address newStakeLPToken) external onlyOwner {
        require(newStakeLPToken.isContract(), "Bad StakeToken address");

        _stakeToken = IERC20(newStakeLPToken);
    }

    function SetNFTMultiplierToken(address newNFTMultiplierToken) external onlyOwner {
        require(newNFTMultiplierToken.isContract(), "Bad NFTMultiplierToken address");

        _multiplierNFToken = IERC721(newNFTMultiplierToken);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert
 */
library SafeMathWithRequire {
    using SafeMath for uint256;

    uint256 private constant DECIMALS_18 = 1000000000000000000;
    uint256 private constant DECIMALS_12 = 1000000000000;
    uint256 private constant DECIMALS_9 = 1000000000;
    uint256 private constant DECIMALS_6 = 1000000;

    function sqrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_12);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function sqrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_6);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function cbrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    function cbrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_9);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../polygon/LiquidityMining/PolygonLandWeightedSANDRewardPool.sol";

contract PolygonLandWeightedSANDRewardPoolNFTTest is PolygonLandWeightedSANDRewardPool {
    constructor(
        address stakeTokenContract,
        address rewardTokenContract,
        address nftContract,
        uint256 rewardDuration
    )
        PolygonLandWeightedSANDRewardPool(
            IERC20(stakeTokenContract),
            IERC20(rewardTokenContract),
            IERC721(nftContract),
            rewardDuration
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/Libraries/SafeMathWithRequire.sol";

/**
 * @title SafeMathWithRequire
 * @dev Specific Mock to test SafeMathWithRequire
 */
contract MockSafeMathWithRequire {
    function sqrt6(uint256 a) external pure returns (uint256 c) {
        return SafeMathWithRequire.sqrt6(a);
    }

    function sqrt3(uint256 a) external pure returns (uint256 c) {
        return SafeMathWithRequire.sqrt3(a);
    }

    function cbrt6(uint256 a) external pure returns (uint256 c) {
        return SafeMathWithRequire.cbrt6(a);
    }

    function cbrt3(uint256 a) external pure returns (uint256 c) {
        return SafeMathWithRequire.cbrt3(a);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";
import "../common/interfaces/IAssetAttributesRegistry.sol";
import "../common/interfaces/IAssetUpgrader.sol";
import "../catalyst/GemsCatalystsRegistry.sol";
import "../common/interfaces/IERC20Extended.sol";
import "../common/interfaces/IAssetToken.sol";

/// @notice Allow to upgrade Asset with Catalyst, Gems and Sand, giving the assets attributes through AssetAttributeRegistry
contract AssetUpgrader is Ownable, ERC2771Handler, IAssetUpgrader {
    using SafeMath for uint256;

    address public immutable feeRecipient;
    uint256 public immutable upgradeFee;
    uint256 public immutable gemAdditionFee;
    uint256 private constant GEM_UNIT = 1000000000000000000;
    uint256 private constant CATALYST_UNIT = 1000000000000000000;
    uint256 private constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    address private constant BURN_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    IERC20Extended internal immutable _sand;
    IAssetAttributesRegistry internal immutable _registry;
    IAssetToken internal immutable _asset;
    GemsCatalystsRegistry internal immutable _gemsCatalystsRegistry;

    /// @notice AssetUpgrader depends on
    /// @param registry: AssetAttributesRegistry for recording catalyst and gems used
    /// @param sand: ERC20 for fee payment
    /// @param asset: Asset Token Contract (dual ERC1155/ERC721)
    /// @param gemsCatalystsRegistry: that track the canonical catalyst and gems and provide batch burning facility
    /// @param _upgradeFee: the fee in Sand paid for an upgrade (setting or replacing a catalyst)
    /// @param _gemAdditionFee: the fee in Sand paid for adding gems
    /// @param _feeRecipient: address receiving the Sand fee
    /// @param trustedForwarder: address of the trusted forwarder (used for metaTX)
    constructor(
        IAssetAttributesRegistry registry,
        IERC20Extended sand,
        IAssetToken asset,
        GemsCatalystsRegistry gemsCatalystsRegistry,
        uint256 _upgradeFee,
        uint256 _gemAdditionFee,
        address _feeRecipient,
        address trustedForwarder
    ) {
        _registry = registry;
        _sand = sand;
        _asset = asset;
        _gemsCatalystsRegistry = gemsCatalystsRegistry;
        upgradeFee = _upgradeFee;
        gemAdditionFee = _gemAdditionFee;
        feeRecipient = _feeRecipient;
        __ERC2771Handler_initialize(trustedForwarder);
    }

    /// @notice associate a catalyst to a fungible Asset token by extracting it as ERC721 first.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset being extracted.
    /// @param catalystId address of the catalyst token to use and burn.
    /// @param gemIds list of gems to socket into the catalyst (burned).
    /// @param to destination address receiving the extracted and upgraded ERC721 Asset token.
    /// @return tokenId The Id of the extracted token.
    function extractAndSetCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        address to
    ) external override returns (uint256 tokenId) {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == from, "AUTH_ACCESS_DENIED");
        tokenId = _asset.extractERC721From(from, assetId, from);
        _changeCatalyst(from, tokenId, catalystId, gemIds, to);
    }

    // TODO tests
    // function extractAndAddGems(
    //     address from,
    //     uint256 assetId,
    //     uint16[] calldata gemIds,
    //     address to
    // ) external override returns (uint256 tokenId) {
    //     require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
    //     require(_msgSender() == from, "AUTH_ACCESS_DENIED");
    //     tokenId = _asset.extractERC721From(from, assetId, from);
    //     _addGems(from, assetId, gemIds, to);
    // }

    /// @notice associate a new catalyst to a non-fungible Asset token.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset being updated.
    /// @param catalystId address of the catalyst token to use and burn.
    /// @param gemIds list of gems to socket into the catalyst (burned).
    /// @param to destination address receiving the Asset token.
    /// @return tokenId The id of the asset.
    function changeCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        address to
    ) external override returns (uint256 tokenId) {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == from, "AUTH_ACCESS_DENIED");
        _changeCatalyst(from, assetId, catalystId, gemIds, to);
        return assetId;
    }

    /// @notice add gems to a non-fungible Asset token.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset to which the gems will be added to.
    /// @param gemIds list of gems to socket into the existing catalyst (burned).
    /// @param to destination address receiving the extracted and upgraded ERC721 Asset token.
    function addGems(
        address from,
        uint256 assetId,
        uint16[] calldata gemIds,
        address to
    ) external override {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == from, "AUTH_ACCESS_DENIED");
        _addGems(from, assetId, gemIds, to);
    }

    /// @dev Collect a fee in SAND tokens
    /// @param from The address paying the fee.
    /// @param sandFee The fee amount.
    function _chargeSand(address from, uint256 sandFee) internal {
        if (feeRecipient != address(0) && sandFee != 0) {
            if (feeRecipient == address(BURN_ADDRESS)) {
                // special address for burn
                _sand.burnFor(from, sandFee);
            } else {
                _sand.transferFrom(from, feeRecipient, sandFee);
            }
        }
    }

    /// @dev Change the catalyst for an asset.
    /// @param from The current owner of the asset.
    /// @param assetId The id of the asset to change.
    /// @param catalystId The id of the new catalyst to set.
    /// @param gemIds An array of gemIds to embed.
    /// @param to The address to transfer the asset to after the catalyst is changed.
    function _changeCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] memory gemIds,
        address to
    ) internal {
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT"); // Asset (ERC1155ERC721.sol) ensure NFT will return true here and non-NFT will return false
        _burnCatalyst(from, catalystId);
        _burnGems(from, gemIds);
        _chargeSand(from, upgradeFee);
        _registry.setCatalyst(assetId, catalystId, gemIds);
        _transfer(from, to, assetId);
    }

    /// @dev Add gems to an existing asset.
    /// @param from The current owner of the asset.
    /// @param assetId The asset to add gems to.
    /// @param gemIds An array of gemIds to add to the asset.
    /// @param to The address to transfer the asset to after adding gems.
    function _addGems(
        address from,
        uint256 assetId,
        uint16[] memory gemIds,
        address to
    ) internal {
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT"); // Asset (ERC1155ERC721.sol) ensure NFT will return true here and non-NFT will return false
        _burnGems(from, gemIds);
        _chargeSand(from, gemAdditionFee);
        _registry.addGems(assetId, gemIds);
        _transfer(from, to, assetId);
    }

    /// @dev transfer an asset if from != to.
    /// @param from The address to transfer the asset from.
    /// @param to The address to transfer the asset to.
    /// @param assetId The asset to transfer.
    function _transfer(
        address from,
        address to,
        uint256 assetId
    ) internal {
        if (from != to) {
            _asset.safeTransferFrom(from, to, assetId);
        } else {
            require(_asset.balanceOf(from, assetId) > 0, "NOT_AUTHORIZED_ASSET_OWNER");
        }
    }

    /// @dev Burn gems.
    /// @param from The owner of the gems.
    /// @param gemIds The gem types to burn.
    function _burnGems(address from, uint16[] memory gemIds) internal {
        _gemsCatalystsRegistry.burnDifferentGems(from, gemIds, GEM_UNIT);
    }

    /// @dev Burn a catalyst.
    /// @param from The owner of the catalyst.
    /// @param catalystId The catalyst type to burn.
    function _burnCatalyst(address from, uint16 catalystId) internal {
        _gemsCatalystsRegistry.burnCatalyst(from, catalystId, CATALYST_UNIT);
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IAssetUpgrader {
    function extractAndSetCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        address to
    ) external returns (uint256 tokenId);

    function changeCatalyst(
        address from,
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        address to
    ) external returns (uint256 tokenId);

    function addGems(
        address from,
        uint256 assetId,
        uint16[] calldata gemIds,
        address to
    ) external;
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

interface IAssetToken {
    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address owner,
        bytes calldata data
    ) external returns (uint256 id);

    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids);

    // fails on non-NFT or nft who do not have collection (was a mistake)
    function collectionOf(uint256 id) external view returns (uint256);

    function balanceOf(address owner, uint256 id) external view returns (uint256);

    // return true for Non-NFT ERC1155 tokens which exists
    function isCollection(uint256 id) external view returns (bool);

    function collectionIndexOf(uint256 id) external view returns (uint256);

    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId);

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    function isSuperOperator(address who) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../asset/AssetUpgrader.sol";

/// @notice Allow to upgrade Asset with Catalyst, Gems and Sand, giving the assets attributes through AssetAttributeRegistry
contract AssetUpgraderFeeBurner is AssetUpgrader {
    constructor(
        IAssetAttributesRegistry registry,
        IERC20Extended sand,
        IAssetToken asset,
        GemsCatalystsRegistry gemsCatalystsRegistry,
        uint256 _upgradeFee,
        uint256 _gemAdditionFee,
        address _feeRecipient,
        address trustedForwarder
    )
        AssetUpgrader(
            registry,
            sand,
            asset,
            gemsCatalystsRegistry,
            _upgradeFee,
            _gemAdditionFee,
            _feeRecipient,
            trustedForwarder
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/BaseWithStorage/ImmutableERC721.sol";
import "../common/BaseWithStorage/WithMinter.sol";
import "../common/interfaces/IAssetToken.sol";
import "../common/interfaces/IGameToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GameBaseToken is ImmutableERC721, WithMinter, Initializable, IGameToken {
    ///////////////////////////////  Data //////////////////////////////

    IAssetToken internal _asset;

    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    mapping(uint256 => mapping(uint256 => uint256)) private _gameAssets;
    mapping(uint256 => address) private _creatorship; // creatorship transfer

    mapping(uint256 => bytes32) private _metaData;
    mapping(address => mapping(address => bool)) private _gameEditors;

    ///////////////////////////////  Events //////////////////////////////

    /// @dev Emits when a game is updated.
    /// @param oldId The id of the previous erc721 GAME token.
    /// @param newId The id of the newly minted token.
    /// @param update The changes made to the Game: new assets, removed assets, uri

    event GameTokenUpdated(uint256 indexed oldId, uint256 indexed newId, IGameToken.GameData update);

    /// @dev Emits when creatorship of a GAME token is transferred.
    /// @param original The original creator of the GAME token.
    /// @param from The current 'creator' of the token.
    /// @param to The new 'creator' of the token.
    event CreatorshipTransfer(address indexed original, address indexed from, address indexed to);

    /// @dev Emits when an address has its gameEditor status changed.
    /// @param gameOwner The owner of the GAME token.
    /// @param gameEditor The address whose editor rights to update.
    /// @param isEditor WHether the address 'gameEditor' should be an editor.
    event GameEditorSet(address indexed gameOwner, address gameEditor, bool isEditor);

    function initV1(
        address trustedForwarder,
        address admin,
        IAssetToken asset,
        uint8 chainIndex
    ) public initializer() {
        _admin = admin;
        _asset = asset;
        ImmutableERC721.__ImmutableERC721_initialize(chainIndex);
        ERC2771Handler.__ERC2771Handler_initialize(trustedForwarder);
    }

    ///////////////////////////////  Modifiers //////////////////////////////

    modifier notToZero(address to) {
        require(to != address(0), "DESTINATION_ZERO_ADDRESS");
        _;
    }

    modifier notToThis(address to) {
        require(to != address(this), "DESTINATION_GAME_CONTRACT");
        _;
    }

    ///////////////////////////////  Functions //////////////////////////////

    /// @notice Create a new GAME token.
    /// @param from The address of the one creating the game (may be different from msg.sender if metaTx).
    /// @param to The address who will be assigned ownership of this game.
    /// @param creation The struct containing ids & ammounts of assets to add to this game,
    /// along with the uri to set.
    /// @param editor The address to allow to edit (can also be set later).
    /// @param subId A random id created on the backend.
    /// @return id The id of the new GAME token (erc721).
    function createGame(
        address from,
        address to,
        GameData calldata creation,
        address editor,
        uint64 subId
    ) external override onlyMinter() notToZero(to) notToThis(to) returns (uint256 id) {
        (uint256 gameId, uint256 strgId) = _mintGame(from, to, subId, 0, true);

        if (editor != address(0)) {
            _setGameEditor(to, editor, true);
        }
        if (creation.assetIdsToAdd.length != 0) {
            _addAssets(from, strgId, creation.assetIdsToAdd, creation.assetAmountsToAdd);
        }

        _metaData[strgId] = creation.uri;
        emit GameTokenUpdated(0, gameId, creation);
        return gameId;
    }

    /// @notice Update an existing GAME token.This actually burns old token
    /// and mints new token with same basId & incremented version.
    /// @param from The one updating the GAME token.
    /// @param gameId The current id of the GAME token.
    /// @param update The values to use for the update.
    /// @return The new gameId.
    function updateGame(
        address from,
        uint256 gameId,
        IGameToken.GameData memory update
    ) external override onlyMinter() returns (uint256) {
        uint256 id = _storageId(gameId);
        _addAssets(from, id, update.assetIdsToAdd, update.assetAmountsToAdd);
        _removeAssets(id, update.assetIdsToRemove, update.assetAmountsToRemove, _ownerOf(gameId));
        _metaData[id] = update.uri;
        uint256 newId = _bumpGameVersion(from, gameId);
        emit GameTokenUpdated(gameId, newId, update);
        return newId;
    }

    /// @notice Allow token owner to set game editors.
    /// @param gameOwner The address of a GAME token creator.
    /// @param editor The address of the editor to set.
    /// @param isEditor Add or remove the ability to edit.
    function setGameEditor(
        address gameOwner,
        address editor,
        bool isEditor
    ) external override {
        require(_msgSender() == gameOwner, "EDITOR_ACCESS_DENIED");
        _setGameEditor(gameOwner, editor, isEditor);
    }

    /// @notice Transfers creatorship of `original` from `sender` to `to`.
    /// @param gameId The current id of the GAME token.
    /// @param sender The address of current registered creator.
    /// @param to The address which will be given creatorship for all tokens originally minted by `original`.
    function transferCreatorship(
        uint256 gameId,
        address sender,
        address to
    ) external override notToZero(to) {
        require(_ownerOf(gameId) != address(0), "NONEXISTENT_TOKEN");
        uint256 id = _storageId(gameId);
        address msgSender = _msgSender();
        require(msgSender == sender || _superOperators[msgSender], "TRANSFER_ACCESS_DENIED");
        require(sender != address(0), "NOT_FROM_ZEROADDRESS");
        address originalCreator = address(uint160(id / CREATOR_OFFSET_MULTIPLIER));
        address current = creatorOf(gameId);
        require(current != to, "CURRENT_=_TO");
        require(current == sender, "CURRENT_!=_SENDER");
        _creatorship[id] = to;
        emit CreatorshipTransfer(originalCreator, current, to);
    }

    /// @notice Burn a GAME token and recover assets.
    /// @param from The address of the one destroying the game.
    /// @param to The address to send all GAME assets to.
    /// @param gameId The id of the GAME to destroy.
    /// @param assetIds The assets to recover from the burnt GAME.
    function burnAndRecover(
        address from,
        address to,
        uint256 gameId,
        uint256[] calldata assetIds
    ) external override {
        _burnGame(from, gameId);
        _recoverAssets(from, to, gameId, assetIds);
    }

    /// @notice Burn a GAME token.
    /// @param gameId The id of the GAME to destroy.
    function burn(uint256 gameId) external override(ERC721BaseToken, IGameToken) {
        _burnGame(_msgSender(), gameId);
    }

    /// @notice Burn a GAME token on behalf of owner.
    /// @param from The address whose GAME is being burnt.
    /// @param gameId The id of the GAME to burn.
    function burnFrom(address from, uint256 gameId) external override(ERC721BaseToken, IGameToken) {
        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        _burnGame(from, gameId);
    }

    /// @notice Get the amount of each assetId in a GAME.
    /// @param gameId The game to query.
    /// @param assetIds The assets to get balances for.
    function getAssetBalances(uint256 gameId, uint256[] calldata assetIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 storageId = _storageId(gameId);
        require(_ownerOf(gameId) != address(0), "NONEXISTENT_TOKEN");
        uint256 length = assetIds.length;
        uint256[] memory assets;
        assets = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            assets[i] = _gameAssets[storageId][assetIds[i]];
        }
        return assets;
    }

    /// @notice Get game editor status.
    /// @param gameOwner The address of the owner of the GAME.
    /// @param editor The address of the editor to set.
    /// @return isEditor Editor status of editor for given tokenId.
    function isGameEditor(address gameOwner, address editor) external view override returns (bool isEditor) {
        return _gameEditors[gameOwner][editor];
    }

    /// @notice Called by other contracts to check if this can receive erc1155 batch.
    /// @param operator The address of the operator in the current tx.
    /// @return the bytes4 value 0xbc197c81.
    function onERC1155BatchReceived(
        address operator,
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external view override returns (bytes4) {
        if (operator == address(this)) {
            return ERC1155_BATCH_RECEIVED;
        }
        revert("ERC1155_BATCH_REJECTED");
    }

    /// @notice Called by other contracts to check if this can receive erc1155 tokens.
    /// @param operator The address of the operator in the current tx.
    /// @return the bytes4 value 0xf23a6e61.
    function onERC1155Received(
        address operator,
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external view override returns (bytes4) {
        if (operator == address(this)) {
            return ERC1155_RECEIVED;
        }
        revert("ERC1155_REJECTED");
    }

    /// @notice Return the name of the token contract.
    /// @return The name of the token contract.
    function name() external pure override returns (string memory) {
        return "The Sandbox: GAME token";
    }

    /// @notice Get the symbol of the token contract.
    /// @return the symbol of the token contract.
    function symbol() external pure override returns (string memory) {
        return "GAME";
    }

    /// @notice Get the creator of the token type `id`.
    /// @param gameId The id of the token to get the creator of.
    /// @return the creator of the token type `id`.
    function creatorOf(uint256 gameId) public view override returns (address) {
        require(gameId != uint256(0), "GAME_NEVER_MINTED");
        uint256 id = _storageId(gameId);
        address originalCreator = address(uint160(id / CREATOR_OFFSET_MULTIPLIER));
        address newCreator = _creatorship[id];
        if (newCreator != address(0)) {
            return newCreator;
        }
        return originalCreator;
    }

    /// @notice Return the URI of a specific token.
    /// @param gameId The id of the token.
    /// @return uri The URI of the token metadata.
    function tokenURI(uint256 gameId) public view override returns (string memory uri) {
        require(_ownerOf(gameId) != address(0), "BURNED_OR_NEVER_MINTED");
        uint256 id = _storageId(gameId);
        return _toFullURI(_metaData[id]);
    }

    /// @notice Transfer assets from a burnt GAME.
    /// @param from Previous owner of the burnt game.
    /// @param to Address that will receive the assets.
    /// @param gameId Id of the burnt GAME token.
    /// @param assetIds The assets to recover from the burnt GAME.
    function recoverAssets(
        address from,
        address to,
        uint256 gameId,
        uint256[] memory assetIds
    ) public override {
        _recoverAssets(from, to, gameId, assetIds);
    }

    /// @notice Check if the contract supports an interface.
    /// 0x01ffc9a7 is ERC-165.
    /// 0x80ac58cd is ERC-721.
    /// @param id The id of the interface.
    /// @return if the interface is supported.
    function supportsInterface(bytes4 id) public pure override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
    }

    /// @notice Add assets to an existing GAME.
    /// @param from The address of the current owner of assets.
    /// @param strgId The storageId of the GAME to add assets to.
    /// @param assetIds The id of the asset to add to GAME.
    /// @param amounts The amount of each asset to add to GAME.
    function _addAssets(
        address from,
        uint256 strgId,
        uint256[] memory assetIds,
        uint256[] memory amounts
    ) internal {
        if (assetIds.length == 0) {
            return;
        }
        require(assetIds.length == amounts.length, "INVALID_INPUT_LENGTHS");
        uint256 currentValue;
        for (uint256 i = 0; i < assetIds.length; i++) {
            currentValue = _gameAssets[strgId][assetIds[i]];
            require(amounts[i] != 0, "INVALID_ASSET_ADDITION");
            _gameAssets[strgId][assetIds[i]] = currentValue + amounts[i];
        }
        if (assetIds.length == 1) {
            _asset.safeTransferFrom(from, address(this), assetIds[0], amounts[0], "");
        } else {
            _asset.safeBatchTransferFrom(from, address(this), assetIds, amounts, "");
        }
    }

    /// @notice Remove assets from a GAME.
    /// @param id The storageId of the GAME to remove assets from.
    /// @param assetIds An array of asset Ids to remove.
    /// @param values An array of the number of each asset id to remove.
    /// @param to The address to send removed assets to.
    function _removeAssets(
        uint256 id,
        uint256[] memory assetIds,
        uint256[] memory values,
        address to
    ) internal {
        if (assetIds.length == 0) {
            return;
        }
        require(assetIds.length == values.length && assetIds.length != 0, "INVALID_INPUT_LENGTHS");
        uint256 currentValue;
        for (uint256 i = 0; i < assetIds.length; i++) {
            currentValue = _gameAssets[id][assetIds[i]];
            require(currentValue != 0 && values[i] != 0 && values[i] <= currentValue, "INVALID_ASSET_REMOVAL");
            _gameAssets[id][assetIds[i]] = currentValue - values[i];
        }

        if (assetIds.length == 1) {
            _asset.safeTransferFrom(address(this), to, assetIds[0], values[0], "");
        } else {
            _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
        }
    }

    /// @dev See burn / burnFrom.
    function _burnGame(address from, uint256 gameId) internal {
        uint256 storageId = _storageId(gameId);
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(storageId);
        address msgSender = _msgSender();
        require(
            msgSender == owner ||
                (operatorEnabled && _operators[storageId] == msgSender) ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender],
            "UNAUTHORIZED_BURN"
        );

        delete _metaData[storageId];
        _creatorship[storageId] = address(0);
        _burn(from, owner, gameId);
    }

    /// @dev See recoverAssets.
    function _recoverAssets(
        address from,
        address to,
        uint256 gameId,
        uint256[] memory assetIds
    ) internal notToZero(to) notToThis(to) {
        require(_ownerOf(gameId) == address(0), "ONLY_FROM_BURNED_TOKEN");
        uint256 storageId = _storageId(gameId);
        require(from == _msgSender(), "INVALID_RECOVERY");
        _check_withdrawal_authorized(from, gameId);
        require(assetIds.length > 0, "WITHDRAWAL_COMPLETE");
        uint256[] memory values;
        values = new uint256[](assetIds.length);
        for (uint256 i = 0; i < assetIds.length; i++) {
            values[i] = _gameAssets[storageId][assetIds[i]];
            delete _gameAssets[storageId][assetIds[i]];
        }
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");

        GameData memory recovery;
        recovery.assetIdsToRemove = assetIds;
        recovery.assetAmountsToRemove = values;
        emit GameTokenUpdated(gameId, 0, recovery);
    }

    /// @dev Create a new gameId and associate it with an owner.
    /// @param from The address of one creating the game.
    /// @param to The address of the Game owner.
    /// @param subId The id to use when generating the new GameId.
    /// @param version The version number part of the gameId.
    /// @param isCreation Whether this is a brand new GAME (as opposed to an update).
    /// @return id The newly created gameId.
    function _mintGame(
        address from,
        address to,
        uint64 subId,
        uint16 version,
        bool isCreation
    ) internal returns (uint256 id, uint256 storageId) {
        uint16 idVersion;
        uint256 gameId;
        uint256 strgId;
        if (isCreation) {
            idVersion = 1;
            gameId = _generateTokenId(from, subId, _chainIndex, idVersion);
            strgId = _storageId(gameId);
            require(_owners[strgId] == 0, "STORAGE_ID_REUSE_FORBIDDEN");
        } else {
            idVersion = version;
            gameId = _generateTokenId(from, subId, _chainIndex, idVersion);
            strgId = _storageId(gameId);
        }

        _owners[strgId] = (uint256(idVersion) << 200) + uint256(uint160(to));
        _numNFTPerAddress[to]++;
        emit Transfer(address(0), to, gameId);
        return (gameId, strgId);
    }

    /// @dev Allow token owner to set game editors.
    /// @param gameCreator The address of a GAME creator,
    /// @param editor The address of the editor to set.
    /// @param isEditor Add or remove the ability to edit.
    function _setGameEditor(
        address gameCreator,
        address editor,
        bool isEditor
    ) internal {
        emit GameEditorSet(gameCreator, editor, isEditor);
        _gameEditors[gameCreator][editor] = isEditor;
    }

    /// @dev Bumps the version number of a game token, buring the previous
    /// version and minting a new one.
    /// @param from The address of the GAME token owner.
    /// @param gameId The Game token to bump the version of.
    /// @return The new gameId.
    function _bumpGameVersion(address from, uint256 gameId) internal returns (uint256) {
        address originalCreator = address(uint160(gameId / CREATOR_OFFSET_MULTIPLIER));
        uint64 subId = uint64(gameId / SUBID_MULTIPLIER);
        uint16 version = uint16(gameId);
        version++;
        address owner = _ownerOf(gameId);
        if (from == owner) {
            // caller is owner or metaTx on owner's behalf
            _burn(from, owner, gameId);
        } else if (_gameEditors[owner][from]) {
            // caller is editor or metaTx on editor's behalf, so we need to pass owner
            // instead of from or _burn will fail
            _burn(owner, owner, gameId);
        }
        (uint256 newId, ) = _mintGame(originalCreator, owner, subId, version, false);
        address newOwner = _ownerOf(newId);
        assert(owner == newOwner);
        return newId;
    }

    /// @dev Get the a full URI string for a given hash + gameId.
    /// @param hash The 32 byte IPFS hash.
    /// @return The URI string.
    function _toFullURI(bytes32 hash) internal pure override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybei", hash2base32(hash), "/", "game.json"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseWithStorage/ERC721BaseToken.sol";

contract ImmutableERC721 is ERC721BaseToken {
    uint256 internal constant CREATOR_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 internal constant SUBID_MULTIPLIER = uint256(2)**(256 - 224);
    uint256 internal constant CHAIN_INDEX_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 64 - 16);
    uint256 internal constant STORAGE_ID_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000;
    uint256 internal constant VERSION_MASK = 0x000000FFFFFFFF00000000000000000000000000000000000000000000000000;
    uint256 internal constant CHAIN_INDEX_MASK = 0x0000000000000000000000000000000000000000000000000000000000FF0000;
    bytes32 internal constant base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;

    uint8 internal _chainIndex;

    function __ImmutableERC721_initialize(uint8 index) internal {
        _chainIndex = index;
    }

    /// @dev get the layer a token was minted on from its id.
    /// @param id The id of the token to query.
    /// @return The index of the original layer of minting.
    /// 0 = eth mainnet, 1 == Polygon, etc...
    function getChainIndex(uint256 id) public pure virtual returns (uint256) {
        return uint256((id & CHAIN_INDEX_MASK) >> 16);
    }

    /// @dev An implementation which handles versioned tokenIds.
    /// @param id The tokenId to get the owner of.
    /// @return The address of the owner.
    function _ownerOf(uint256 id) internal view virtual override returns (address) {
        uint256 packedData = _owners[_storageId(id)];
        uint16 idVersion = uint16(id);
        uint16 storageVersion = uint16((packedData & VERSION_MASK) >> 200);

        if (((packedData & BURNED_FLAG) == BURNED_FLAG) || idVersion != storageVersion) {
            return address(0);
        }
        return address(uint160(packedData));
    }

    /// @dev Check if a withdrawal is allowed.
    /// @param from The address requesting the withdrawal.
    /// @param gameId The id of the GAME token to withdraw assets from.
    function _check_withdrawal_authorized(address from, uint256 gameId) internal view virtual {
        require(from != address(0), "SENDER_ZERO_ADDRESS");
        require(from == _withdrawalOwnerOf(gameId), "LAST_OWNER_NOT_EQUAL_SENDER");
    }

    /// @dev Get the address allowed to withdraw associated tokens from the parent token.
    /// If too many associated tokens in TOKEN, block.gaslimit won't allow detroy and withdraw in 1 tx.
    /// An owner may destroy their token, then withdraw associated tokens in a later tx (even
    /// though ownerOf(id) would be address(0) after burning.)
    /// @param id The id of the token to query.
    /// @return the address of the owner before burning.
    function _withdrawalOwnerOf(uint256 id) internal view virtual returns (address) {
        uint256 packedData = _owners[_storageId(id)];
        return address(uint160(packedData));
    }

    /// @notice Get the storageID (no chainIndex or version data), which is constant for a given token.
    /// @param tokenId The tokenId for which to find the first token Id.
    /// @return The storage id for this token.
    function getStorageId(uint256 tokenId) external pure virtual returns (uint256) {
        return _storageId(tokenId);
    }

    /// @dev Get the storageId (full id without the version number) from the full tokenId.
    /// @param id The full tokenId for the GAME token.
    /// @return The storageId.
    function _storageId(uint256 id) internal pure virtual override returns (uint256) {
        return uint256(id & STORAGE_ID_MASK);
    }

    /// @dev Get the a full URI string for a given hash + gameId.
    /// @param hash The 32 byte IPFS hash.
    /// @return The URI string.
    function _toFullURI(bytes32 hash) internal pure virtual returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybei", hash2base32(hash), "/", "token.json"));
    }

    /// @dev Create a new tokenId and associate it with an owner.
    /// This is a packed id, consisting of 4 parts:
    /// the creator's address, a uint64 subId, a uint18 chainIndex and a uint16 version.
    /// @param creator The address of the Token creator.
    /// @param subId The id used to generate the id.
    /// @param version The publicversion used to generate the id.
    function _generateTokenId(
        address creator,
        uint64 subId,
        uint8 chainIndex,
        uint16 version
    ) internal pure returns (uint256) {
        return
            uint256(uint160(creator)) *
            CREATOR_OFFSET_MULTIPLIER +
            uint64(subId) *
            SUBID_MULTIPLIER +
            chainIndex *
            CHAIN_INDEX_OFFSET_MULTIPLIER +
            uint16(version);
    }

    /// @dev Convert a 32 byte hash to a base 32 string.
    /// @param hash A 32 byte (IPFS) hash.
    /// @return _uintAsString The hash as a base 32 string.
    // solhint-disable-next-line security/no-assign-params
    function hash2base32(bytes32 hash) internal pure returns (string memory _uintAsString) {
        uint256 _i = uint256(hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = base32Alphabet[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = base32Alphabet[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @title Interface for the Game token

interface IGameToken {
    struct GameData {
        uint256[] assetIdsToRemove;
        uint256[] assetAmountsToRemove;
        uint256[] assetIdsToAdd;
        uint256[] assetAmountsToAdd;
        bytes32 uri; // ipfs hash (without the prefix, assume cidv1 folder)
    }

    function createGame(
        address from,
        address to,
        GameData calldata creation,
        address editor,
        uint64 subId
    ) external returns (uint256 id);

    function burn(uint256 gameId) external;

    function burnFrom(address from, uint256 gameId) external;

    function recoverAssets(
        address from,
        address to,
        uint256 gameId,
        uint256[] calldata assetIds
    ) external;

    function burnAndRecover(
        address from,
        address to,
        uint256 gameId,
        uint256[] calldata assetIds
    ) external;

    function updateGame(
        address from,
        uint256 gameId,
        GameData calldata update
    ) external returns (uint256);

    function getAssetBalances(uint256 gameId, uint256[] calldata assetIds) external view returns (uint256[] calldata);

    function setGameEditor(
        address gameCreator,
        address editor,
        bool isEditor
    ) external;

    function isGameEditor(address gameOwner, address editor) external view returns (bool isEditor);

    function creatorOf(uint256 id) external view returns (address);

    function transferCreatorship(
        uint256 gameId,
        address sender,
        address to
    ) external;

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function tokenURI(uint256 gameId) external returns (string memory uri);

    function onERC1155Received(
        address operator,
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external view returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external view returns (bytes4);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../Game/GameBaseToken.sol";

// solhint-disable-next-line no-empty-blocks
contract ChildGameTokenV1 is GameBaseToken {

}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./GameBaseToken.sol";
import "../common/interfaces/IGameMinter.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";

contract GameMinter is ERC2771Handler, IGameMinter {
    ///////////////////////////////  Data //////////////////////////////

    GameBaseToken internal immutable _gameToken;
    // @todo confirm actual fees
    uint256 internal immutable _gameMintingFee;
    uint256 internal immutable _gameUpdateFee;
    address internal immutable _feeBeneficiary;
    IERC20 internal immutable _sand;

    ///////////////////////////////  Functions /////////////////////////

    constructor(
        GameBaseToken gameTokenContract,
        address trustedForwarder,
        uint256 gameMintingFee,
        uint256 gameUpdateFee,
        address feeBeneficiary,
        IERC20 sand
    ) {
        _gameToken = gameTokenContract;
        _gameMintingFee = gameMintingFee;
        _gameUpdateFee = gameUpdateFee;
        _feeBeneficiary = feeBeneficiary;
        _sand = sand;
        ERC2771Handler.__ERC2771Handler_initialize(trustedForwarder);
    }

    /// @notice Function to create a new GAME token
    /// @param to The address who will be assigned ownership of this game.
    /// @param creation The struct containing ids & ammounts of assets to add to this game,
    /// along with the uri to set.
    /// @param editor The address to allow to edit (can also be set later).
    /// @param subId A random id created on the backend.
    /// @return gameId The id of the new GAME token (erc721)
    function createGame(
        address to,
        GameBaseToken.GameData calldata creation,
        address editor,
        uint64 subId
    ) external override returns (uint256 gameId) {
        address msgSender = _msgSender();
        _chargeSand(msgSender, _gameMintingFee);
        return _gameToken.createGame(msgSender, to, creation, editor, subId);
    }

    /// @notice Update an existing GAME token.This actually burns old token
    /// and mints new token with same basId & incremented version.
    /// @param gameId The current id of the GAME token.
    /// @param update The values to use for the update.
    /// @return newId The new gameId.
    function updateGame(uint256 gameId, GameBaseToken.GameData memory update)
        external
        override
        returns (uint256 newId)
    {
        address gameOwner = _gameToken.ownerOf(gameId);
        address msgSender = _msgSender();
        require(msgSender == gameOwner || _gameToken.isGameEditor(gameOwner, msgSender), "AUTH_ACCESS_DENIED");
        _chargeSand(msgSender, _gameUpdateFee);
        return _gameToken.updateGame(msgSender, gameId, update);
    }

    /// @dev Charge a fee in Sand if conditions are met.
    /// @param from The address responsible for paying the fee.
    /// @param sandFee The fee that applies to the current operation (create || update).
    function _chargeSand(address from, uint256 sandFee) internal {
        if (_feeBeneficiary != address(0) && sandFee != 0) {
            _sand.transferFrom(from, _feeBeneficiary, sandFee);
        }
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./IGameToken.sol";

interface IGameMinter {
    function createGame(
        address to,
        IGameToken.GameData calldata creation,
        address editor,
        uint64 subId
    ) external returns (uint256 gameId);

    function updateGame(uint256 gameId, IGameToken.GameData memory update) external returns (uint256 newId);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

contract MockERC20BasicApprovalTarget {
    event LogOnCall(address);

    function logOnCall(address sender) external returns (address) {
        emit LogOnCall(sender);
        return sender;
    }

    function revertOnCall() external pure {
        revert("REVERT_ON_CALL");
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return IERC20(msg.sender).transferFrom(sender, recipient, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {SafeERC20} from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

/// @dev This is NOT a secure ERC20 Predicate contract implementation!
/// DO NOT USE in production.

contract FakeERC20Predicate {
    address private token;
    using SafeERC20 for IERC20;

    event LockedERC20(
        address indexed depositor,
        address indexed depositReceiver,
        address indexed rootToken,
        uint256 amount
    );

    function setToken(address _token) external {
        token = _token;
    }

    function lockTokens(
        address depositor,
        address depositReceiver,
        bytes calldata depositData
    ) external {
        uint256 amount = abi.decode(depositData, (uint256));
        emit LockedERC20(depositor, depositReceiver, token, amount);
        IERC20(token).safeTransferFrom(depositor, address(this), amount);
    }

    function exitTokens(address withdrawer, uint256 amount) public {
        IERC20(token).safeTransfer(withdrawer, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-0.8/utils/Address.sol";

contract Batch {
    using Address for address;

    struct Execution {
        address target;
        bytes callData;
    }

    struct ExecutionWithETH {
        address target;
        bytes callData;
        uint256 value;
    }

    struct SingleTargetExecutionWithETH {
        bytes callData;
        uint256 value;
    }

    address public immutable executor;

    constructor(address _executor) {
        executor = _executor;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "NOT_AUTHORIZED");
        _;
    }

    function atomicBatchWithETH(ExecutionWithETH[] calldata executions) external payable onlyExecutor {
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i].target.functionCallWithValue(executions[i].callData, executions[i].value);
        }
    }

    function nonAtomicBatchWithETH(ExecutionWithETH[] calldata executions) external payable onlyExecutor {
        for (uint256 i = 0; i < executions.length; i++) {
            _call(executions[i].target, executions[i].callData, executions[i].value);
        }
    }

    function atomicBatch(Execution[] calldata executions) external onlyExecutor {
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i].target.functionCall(executions[i].callData);
        }
    }

    function nonAtomicBatch(Execution[] calldata executions) external onlyExecutor {
        for (uint256 i = 0; i < executions.length; i++) {
            _call(executions[i].target, executions[i].callData, 0);
        }
    }

    function singleTargetAtomicBatchWithETH(address target, SingleTargetExecutionWithETH[] calldata executions)
        external
        payable
        onlyExecutor
    {
        for (uint256 i = 0; i < executions.length; i++) {
            target.functionCallWithValue(executions[i].callData, executions[i].value);
        }
    }

    function singleTargetNonAtomicBatchWithETH(address target, SingleTargetExecutionWithETH[] calldata executions)
        external
        payable
        onlyExecutor
    {
        for (uint256 i = 0; i < executions.length; i++) {
            _call(target, executions[i].callData, executions[i].value);
        }
    }

    function singleTargetAtomicBatch(address target, bytes[] calldata callDatas) external onlyExecutor {
        for (uint256 i = 0; i < callDatas.length; i++) {
            target.functionCall(callDatas[i]);
        }
    }

    function singleTargetNonAtomicBatch(address target, bytes[] calldata callDatas) external onlyExecutor {
        for (uint256 i = 0; i < callDatas.length; i++) {
            _call(target, callDatas[i], 0);
        }
    }

    function _call(
        address target,
        bytes calldata data,
        uint256 value
    ) internal returns (bool) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = target.call{value: value}(data);
        return success;
    }

    // ----------------------------------------------------------------------------------------------------
    // TOKEN RECEPTION
    // ----------------------------------------------------------------------------------------------------

    // ERC1155
    bytes4 private constant ERC1155_IS_RECEIVER = 0x4e2312e0;
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_BATCH_RECEIVED;
    }

    // ERC721

    bytes4 private constant ERC721_IS_RECEIVER = 0x150b7a02;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC721_RECEIVED;
    }

    // ERC165
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == 0x01ffc9a7 || _interfaceId == ERC1155_IS_RECEIVER || _interfaceId == ERC721_IS_RECEIVER;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../polygon/child/asset/PolygonAssetV2.sol";
import "../polygon/child/sand/PolygonSand.sol";

/// @dev This is NOT a secure ChildChainManager contract implementation!
/// DO NOT USE in production.

contract FakeChildChainManager {
    address public polygonAsset;

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    function setPolygonAsset(address _polygonAsset) external {
        polygonAsset = _polygonAsset;
    }

    function callDeposit(address user, bytes calldata depositData) external {
        PolygonAssetV2(polygonAsset).deposit(user, depositData);
    }

    function callSandDeposit(
        address polygonSand,
        address user,
        bytes calldata depositData
    ) external {
        PolygonSand(polygonSand).deposit(user, depositData);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "../../../asset/ERC1155ERC721.sol";
import "../../../common/interfaces/IAssetAttributesRegistry.sol";
import "../../../asset/libraries/AssetHelper.sol";

contract PolygonAssetV2 is ERC1155ERC721 {
    address private _childChainManager;
    AssetHelper.AssetRegistryData private assetRegistryData;

    event ChainExit(address indexed to, uint256[] tokenIds, uint256[] amounts, bytes data);

    /// @notice fulfills the purpose of a constructor in upgradeabale contracts
    function initialize(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        address childChainManager,
        uint8 chainIndex,
        address assetRegistry
    ) external {
        initV2(trustedForwarder, admin, bouncerAdmin, address(0), chainIndex);
        _childChainManager = childChainManager;
        assetRegistryData.assetRegistry = IAssetAttributesRegistry(assetRegistry);
    }

    /// @notice called when tokens are deposited on root chain
    /// @dev Should be callable only by ChildChainManager
    /// @dev Should handle deposit by minting the required tokens for user
    /// @dev Make sure minting is done only by this function
    /// @param user user address for whom deposit is being done
    /// @param depositData abi encoded ids array and amounts array
    function deposit(address user, bytes calldata depositData) external {
        require(_msgSender() == _childChainManager, "!DEPOSITOR");
        require(user != address(0), "INVALID_DEPOSIT_USER");
        (uint256[] memory ids, uint256[] memory amounts, bytes32[] memory hashes) =
            AssetHelper.decodeAndSetCatalystDataL1toL2(assetRegistryData, depositData);

        for (uint256 i = 0; i < ids.length; i++) {
            _metadataHash[ids[i] & ERC1155ERC721Helper.URI_ID] = hashes[i];
            _rarityPacks[ids[i] & ERC1155ERC721Helper.URI_ID] = "0x00";
            if ((ids[i] & ERC1155ERC721Helper.IS_NFT) > 0) {
                _mintNFTFromAnotherLayer(user, ids[i]);
            } else {
                _mintFTFromAnotherLayer(amounts[i], user, ids[i]);
            }
        }
        _completeMultiMint(_msgSender(), user, ids, amounts, depositData);
    }

    /// @notice called when user wants to withdraw tokens back to root chain
    /// @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
    /// @param ids ids to withdraw
    /// @param amounts amounts to withdraw
    function withdraw(uint256[] calldata ids, uint256[] calldata amounts) external {
        bytes32[] memory hashes = new bytes32[](ids.length);
        IAssetAttributesRegistry.AssetGemsCatalystData[] memory gemsCatalystDatas =
            AssetHelper.getGemsAndCatalystData(assetRegistryData, ids);

        for (uint256 i = 0; i < ids.length; i++) {
            hashes[i] = _metadataHash[ids[i] & ERC1155ERC721Helper.URI_ID];
        }

        if (ids.length == 1) {
            _burn(_msgSender(), ids[0], amounts[0]);
        } else {
            _burnBatch(_msgSender(), ids, amounts);
        }
        emit ChainExit(_msgSender(), ids, amounts, abi.encode(hashes, gemsCatalystDatas));
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "../../../common/BaseWithStorage/ERC2771Handler.sol";
import "../../../Sand/SandBaseToken.sol";

contract PolygonSand is SandBaseToken, Ownable, ERC2771Handler {
    address public childChainManagerProxy;

    constructor(
        address _childChainManagerProxy,
        address trustedForwarder,
        address sandAdmin,
        address executionAdmin
    ) SandBaseToken(sandAdmin, executionAdmin, address(0), 0) {
        require(_childChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = _childChainManagerProxy;
        __ERC2771Handler_initialize(trustedForwarder);
    }

    /// @notice update the ChildChainManager Proxy address
    /// @param newChildChainManagerProxy address of the new childChainManagerProxy
    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    /// @notice called when tokens are deposited on root chain
    /// @param user user address for whom deposit is being done
    /// @param depositData abi encoded amount
    function deposit(address user, bytes calldata depositData) external {
        require(_msgSender() == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /// @notice called when user wants to withdraw tokens back to root chain
    /// @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
    /// @param amount amount to withdraw
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "../common/interfaces/IERC1155.sol";
import "../common/interfaces/IERC1155TokenReceiver.sol";
import "../common/Libraries/ObjectLib32.sol";
import "../common/interfaces/IERC721.sol";
import "../common/interfaces/IERC721TokenReceiver.sol";
import "../common/BaseWithStorage/WithSuperOperators.sol";
import "./libraries/ERC1155ERC721Helper.sol";

// solhint-disable max-states-count
// !!! DO NOT ADD MORE INHERITED CLASS !!!
// This class is used by asset and is upgradable, if you add more INHERITED class, storage will be mixed up
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
contract ERC1155ERC721 is WithSuperOperators, IERC1155, IERC721 {
    using Address for address;
    using ObjectLib32 for ObjectLib32.Operations;
    using ObjectLib32 for uint256;

    bytes4 private constant ERC1155_IS_RECEIVER = 0x4e2312e0;
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    mapping(address => uint256) private _numNFTPerAddress; // erc721
    mapping(uint256 => uint256) private _owners; // erc721
    mapping(address => mapping(uint256 => uint256)) private _packedTokenBalance; // erc1155
    mapping(address => mapping(address => bool)) private _operatorsForAll; // erc721 and erc1155
    mapping(uint256 => address) private _erc721operators; // erc721
    mapping(uint256 => bytes32) internal _metadataHash; // erc721 and erc1155
    mapping(uint256 => bytes) internal _rarityPacks; // rarity configuration per packs (2 bits per Asset)
    mapping(uint256 => uint32) private _nextCollectionIndex; // extraction

    mapping(address => address) private _creatorship; // creatorship transfer

    mapping(address => bool) private _bouncers; // the contracts allowed to mint
    // @note : Deprecated.
    mapping(address => bool) private _metaTransactionContracts;

    address private _bouncerAdmin;

    bool internal _init;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;

    uint256 internal _initBits;
    address internal _predicate; // used in place of polygon's `PREDICATE_ROLE`

    uint8 internal _chainIndex; // modify this for l2
    uint256 private constant CHAIN_INDEX_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32);
    uint256 private constant CHAIN_INDEX_MASK = 0x00000000000000000000000000000000000000000000007F8000000000000000;

    address internal _trustedForwarder;

    uint256[20] private __gap;
    // solhint-enable max-states-count

    event BouncerAdminChanged(address oldBouncerAdmin, address newBouncerAdmin);
    event Bouncer(address bouncer, bool enabled);
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);
    event CreatorshipTransfer(address indexed original, address indexed from, address indexed to);
    event Extraction(uint256 indexed fromId, uint256 toId);
    event AssetUpdate(uint256 indexed fromId, uint256 toId);

    function initV2(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        address predicate,
        uint8 chainIndex
    ) public {
        // one-time init of bitfield's previous versions
        _checkInit(0);
        _admin = admin;
        _bouncerAdmin = bouncerAdmin;
        _predicate = predicate;
        __ERC2771Handler_initialize(trustedForwarder);
        _chainIndex = chainIndex;
    }

    /// @notice Change the minting administrator to be `newBouncerAdmin`.
    /// @param newBouncerAdmin address of the new minting administrator.
    function changeBouncerAdmin(address newBouncerAdmin) external {
        require(_msgSender() == _bouncerAdmin, "!BOUNCER_ADMIN");
        emit BouncerAdminChanged(_bouncerAdmin, newBouncerAdmin);
        _bouncerAdmin = newBouncerAdmin;
    }

    /// @notice Enable or disable the ability of `bouncer` to mint tokens (minting bouncer rights).
    /// @param bouncer address that will be given/removed minting bouncer rights.
    /// @param enabled set whether the address is enabled or disabled as a minting bouncer.
    function setBouncer(address bouncer, bool enabled) external {
        require(_msgSender() == _bouncerAdmin, "!BOUNCER_ADMIN");
        _bouncers[bouncer] = enabled;
        emit Bouncer(bouncer, enabled);
    }

    /// @notice Mint a token type for `creator` on slot `packId`.
    /// @param creator address of the creator of the token.
    /// @param packId unique packId for that token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the token type in the file 0.json.
    /// @param supply number of tokens minted for that token type.
    /// @param rarity rarity power of the token.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return id the id of the newly minted token type.
    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address owner,
        bytes calldata data
    ) external returns (uint256 id) {
        require(hash != 0, "HASH==0");
        require(_bouncers[_msgSender()], "!BOUNCER");
        require(owner != address(0), "TO==0");
        id = _generateTokenId(creator, supply, packId, supply == 1 ? 0 : 1, 0);
        _mint(hash, supply, rarity, _msgSender(), owner, id, data, false);
    }

    /// @notice Mint multiple token types for `creator` on slot `packId`.
    /// @param creator address of the creator of the tokens.
    /// @param packId unique packId for the tokens.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of each token type in the files: 0.json, 1.json, 2.json, etc...
    /// @param supplies number of tokens minted for each token type.
    /// @param rarityPack rarity power of each token types packed into 2 bits each.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return ids the ids of each newly minted token types.
    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids) {
        require(hash != 0, "HASH==0");
        require(_bouncers[_msgSender()], "!BOUNCER");
        require(owner != address(0), "TO==0");
        uint16 numNFTs;
        (ids, numNFTs) = _allocateIds(creator, supplies, rarityPack, packId, hash);
        _mintBatches(supplies, owner, ids, numNFTs);
        _completeMultiMint(_msgSender(), owner, ids, supplies, data);
    }

    /// @notice Transfers `value` tokens of type `id` from  `from` to `to`  (with safety call).
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param id the token type transfered.
    /// @param value amount of token transfered.
    /// @param data aditional data accompanying the transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        if (id & ERC1155ERC721Helper.IS_NFT > 0) {
            require(_ownerOf(id) == from, "OWNER!=FROM");
        }
        bool metaTx = _transferFrom(from, to, id, value);
        require(
            _checkERC1155AndCallSafeTransfer(metaTx ? from : msg.sender, from, to, id, value, data, false, false),
            "1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Transfers `values` tokens of type `ids` from  `from` to `to` (with safety call).
    /// @dev call data should be optimized to order ids so packedBalance can be used efficiently.
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param ids ids of each token type transfered.
    /// @param values amount of each token type transfered.
    /// @param data aditional data accompanying the transfer.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        // @review should we also check the length of data.URIs[] if we use something like that?
        // not sure if we want to try to set/update all URIs at once(both for newly-minted tokens & unlock tokens? Or do we rely on a second TX to update URIs for tokens that were locked in the predicate and may have new metaData from L2 to be set?)
        // metadataHash updates only applicable to erc721 tokens
        require(ids.length == values.length, "MISMATCHED_ARR_LEN");
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");
        bool metaTx = isTrustedForwarder(msg.sender);
        bool authorized = from == _msgSender() || isApprovedForAll(from, _msgSender());

        _batchTransferFrom(from, to, ids, values, authorized);
        emit TransferBatch(metaTx ? from : _msgSender(), from, to, ids, values);
        require(
            _checkERC1155AndCallSafeBatchTransfer(metaTx ? from : _msgSender(), from, to, ids, values, data),
            "1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Transfers creatorship of `original` from `sender` to `to`.
    /// @param sender address of current registered creator.
    /// @param original address of the original creator whose creation are saved in the ids themselves.
    /// @param to address which will be given creatorship for all tokens originally minted by `original`.
    function transferCreatorship(
        address sender,
        address original,
        address to
    ) external {
        require(sender == _msgSender() || _superOperators[_msgSender()], "!AUTHORIZED");
        require(sender != address(0), "SENDER==0");
        require(to != address(0), "TO==0");
        address current = _creatorship[original];
        if (current == address(0)) {
            current = original;
        }
        require(current != to, "CURRENT==TO");
        require(current == sender, "CURRENT!=SENDER");
        if (to == original) {
            _creatorship[original] = address(0);
        } else {
            _creatorship[original] = to;
        }
        emit CreatorshipTransfer(original, current, to);
    }

    /// @notice Enable or disable approval for `operator` to manage all `sender`'s tokens.
    /// @dev used for Meta Transaction (from metaTransactionContract).
    /// @param sender address which grant approval.
    /// @param operator address which will be granted rights to transfer all token owned by `sender`.
    /// @param approved whether to approve or revoke.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender == _msgSender() || _superOperators[_msgSender()], "!AUTHORIZED");
        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Enable or disable approval for `operator` to manage all of the caller's tokens.
    /// @param operator address which will be granted rights to transfer all tokens of the caller.
    /// @param approved whether to approve or revoke
    function setApprovalForAll(address operator, bool approved) external override(IERC1155, IERC721) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Change or reaffirm the approved address for an NFT.
    /// @param operator the address to approve as NFT controller.
    /// @param id the id of the NFT to approve.
    function approve(address operator, uint256 id) external override {
        require(_ownerOf(id) != address(0), "NFT_!EXIST");
        require(_ownerOf(id) == _msgSender() || isApprovedForAll(_ownerOf(id), _msgSender()), "!AUTHORIZED");
        _erc721operators[id] = operator;
        emit Approval(_ownerOf(id), operator, id);
    }

    /// @notice Transfers ownership of an NFT.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        require(_ownerOf(id) == from, "OWNER!=FROM");
        bool metaTx = _transferFrom(from, to, id, 1);
        require(
            _checkERC1155AndCallSafeTransfer(metaTx ? from : _msgSender(), from, to, id, 1, "", true, false),
            "1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Burns `amount` tokens of type `id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id token type which will be burnt.
    /// @param amount amount of token to burn.
    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "!AUTHORIZED");
        _burn(from, id, amount);
    }

    /// @notice Upgrades an NFT with new metadata and rarity.
    /// @param from address which own the NFT to be upgraded.
    /// @param id the NFT that will be burnt to be upgraded.
    /// @param packId unqiue packId for the token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the new token type in the file 0.json.
    /// @param newRarity rarity power of the new NFT.
    /// @param to address which will receive the NFT.
    /// @param data bytes to be transmitted as part of the minted token.
    /// @return the id of the newly minted NFT.
    function updateERC721(
        address from,
        uint256 id,
        uint40 packId,
        bytes32 hash,
        uint8 newRarity,
        address to,
        bytes calldata data
    ) external returns (uint256) {
        require(hash != 0, "HASH==0");
        require(_bouncers[_msgSender()], "!BOUNCER");
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");

        _burnERC721(_msgSender(), from, id);

        uint256 newId = _generateTokenId(from, 1, packId, 0, 0);
        _mint(hash, 1, newRarity, _msgSender(), to, newId, data, false);
        emit AssetUpdate(id, newId);
        return newId;
    }

    /// @notice Extracts an EIP-721 NFT from an EIP-1155 token.
    /// @param sender address which own the token to be extracted.
    /// @param id the token type to extract from.
    /// @param to address which will receive the token.
    /// @return newId the id of the newly minted NFT.
    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId) {
        bool metaTx = isTrustedForwarder(msg.sender);
        require(sender == _msgSender() || isApprovedForAll(sender, _msgSender()), "!AUTHORIZED");
        return _extractERC721From(metaTx ? sender : _msgSender(), sender, id, to);
    }

    /// @notice Returns the current administrator in charge of minting rights.
    /// @return the current minting administrator in charge of minting rights.
    function getBouncerAdmin() external view returns (address) {
        return _bouncerAdmin;
    }

    /// @notice check whether address `who` is given minting bouncer rights.
    /// @param who The address to query.
    /// @return whether the address has minting rights.
    function isBouncer(address who) external view returns (bool) {
        return _bouncers[who];
    }

    /// @notice Get the balance of `owners` for each token type `ids`.
    /// @param owners the addresses of the token holders queried.
    /// @param ids ids of each token type to query.
    /// @return the balance of each `owners` for each token type `ids`.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(owners.length == ids.length, "ARG_LENGTH_MISMATCH");
        uint256[] memory balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }
        return balances;
    }

    /// @notice Get the creator of the token type `id`.
    /// @param id the id of the token to get the creator of.
    /// @return the creator of the token type `id`.
    function creatorOf(uint256 id) external view returns (address) {
        require(wasEverMinted(id), "TOKEN_!MINTED");
        address newCreator = _creatorship[address(uint160(id / ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER))];
        if (newCreator != address(0)) {
            return newCreator;
        }
        return address(uint160(id / ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER));
    }

    /// @notice Count all NFTs assigned to `owner`.
    /// @param owner address for whom to query the balance.
    /// @return balance the number of NFTs owned by `owner`, possibly zero.
    function balanceOf(address owner) external view override returns (uint256 balance) {
        require(owner != address(0), "OWNER==0");
        return _numNFTPerAddress[owner];
    }

    /// @notice Find the owner of an NFT.
    /// @param id the identifier for an NFT.
    /// @return owner the address of the owner of the NFT.
    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NFT_!EXIST");
    }

    /// @notice Get the approved address for a single NFT.
    /// @param id the NFT to find the approved address for.
    /// @return operator the approved address for this NFT, or the zero address if there is none.
    function getApproved(uint256 id) external view override returns (address operator) {
        require(_ownerOf(id) != address(0), "NFT_!EXIST");
        return _erc721operators[id];
    }

    /// @notice check whether a packId/numFT tupple has been used
    /// @param creator for which creator
    /// @param packId the packId to check
    /// @param numFTs number of Fungible Token in that pack (can reuse packId if different)
    /// @return whether the pack has already been used
    function isPackIdUsed(
        address creator,
        uint40 packId,
        uint16 numFTs
    ) external view returns (bool) {
        return
            _metadataHash[
                uint256(uint160(creator)) *
                    ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER + // CREATOR
                    uint256(packId) *
                    ERC1155ERC721Helper.PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack) // ERC1155ERC721Helper.URI_ID
                    numFTs *
                    ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER
            ] != 0;
    }

    /// @notice A descriptive name for the collection of tokens in this contract.
    /// @return _name the name of the tokens.
    function name() external pure returns (string memory _name) {
        return "Sandbox's ASSETs";
    }

    /// @notice An abbreviated name for the collection of tokens in this contract.
    /// @return _symbol the symbol of the tokens.
    function symbol() external pure returns (string memory _symbol) {
        return "ASSET";
    }

    /// @notice Query if a contract implements interface `id`.
    /// @param id the interface identifier, as specified in ERC-165.
    /// @return `true` if the contract implements `id`.
    function supportsInterface(bytes4 id) external pure override returns (bool) {
        return
            id == 0x01ffc9a7 || //ERC165
            id == 0xd9b67a26 || // ERC1155
            id == 0x80ac58cd || // ERC721
            id == 0x5b5e139f || // ERC721 metadata
            id == 0x0e89341c; // ERC1155 metadata
    }

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    /// @param data additional data with no specified format, sent in call to `to`.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        require(_ownerOf(id) == from, "OWNER!=FROM");
        bool metaTx = _transferFrom(from, to, id, 1);
        require(
            _checkERC1155AndCallSafeTransfer(metaTx ? from : _msgSender(), from, to, id, 1, data, true, true),
            "721/1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Gives the collection a specific token belongs to.
    /// @param id the token to get the collection of.
    /// @return the collection the NFT is part of.
    function collectionOf(uint256 id) public view returns (uint256) {
        require(_ownerOf(id) != address(0), "NFT_!EXIST");
        uint256 collectionId = id & ERC1155ERC721Helper.NOT_NFT_INDEX & ERC1155ERC721Helper.NOT_IS_NFT;
        require(wasEverMinted(collectionId), "UNMINTED_COLLECTION");
        return collectionId;
    }

    /// @notice Return wether the id is a collection
    /// @param id collectionId to check.
    /// @return whether the id is a collection.
    function isCollection(uint256 id) public view returns (bool) {
        uint256 collectionId = id & ERC1155ERC721Helper.NOT_NFT_INDEX & ERC1155ERC721Helper.NOT_IS_NFT;
        return wasEverMinted(collectionId);
    }

    /// @notice Gives the index at which an NFT was minted in a collection : first of a collection get the zero index.
    /// @param id the token to get the index of.
    /// @return the index/order at which the token `id` was minted in a collection.
    function collectionIndexOf(uint256 id) public view returns (uint256) {
        collectionOf(id); // this check if id and collection indeed was ever minted
        return uint32((id & ERC1155ERC721Helper.NFT_INDEX) >> ERC1155ERC721Helper.NFT_INDEX_OFFSET);
    }

    function wasEverMinted(uint256 id) public view returns (bool) {
        if ((id & ERC1155ERC721Helper.IS_NFT) > 0) {
            return _owners[id] != 0;
        } else {
            return
                ((id & ERC1155ERC721Helper.PACK_INDEX) <
                    ((id & ERC1155ERC721Helper.PACK_NUM_FT_TYPES) /
                        ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER)) &&
                _metadataHash[id & ERC1155ERC721Helper.URI_ID] != 0;
        }
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// This supports both erc721 & erc1155 tokens.
    /// @param id token to get the uri of.
    /// @return URI string
    function tokenURI(uint256 id) public view returns (string memory) {
        require(_ownerOf(id) != address(0) || wasEverMinted(id), "NFT_!EXIST_||_FT_!MINTED");
        return ERC1155ERC721Helper.toFullURI(_metadataHash[id & ERC1155ERC721Helper.URI_ID], id);
    }

    /// @notice Get the balance of `owner` for the token type `id`.
    /// @param owner The address of the token holder.
    /// @param id the token type of which to get the balance of.
    /// @return the balance of `owner` for the token type `id`.
    function balanceOf(address owner, uint256 id) public view override returns (uint256) {
        // do not check for existence, balance is zero if never minted
        // require(wasEverMinted(id), "token was never minted");
        if (id & ERC1155ERC721Helper.IS_NFT > 0) {
            if (_ownerOf(id) == owner) {
                return 1;
            } else {
                return 0;
            }
        }
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedTokenBalance[owner][bin].getValueInBin(index);
    }

    /// @notice Queries the approval status of `operator` for owner `owner`.
    /// @param owner the owner of the tokens.
    /// @param operator address of authorized operator.
    /// @return isOperator true if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERC1155, IERC721)
        returns (bool isOperator)
    {
        require(owner != address(0), "OWNER==0");
        require(operator != address(0), "OPERATOR==0");
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(sender != address(0), "SENDER==0");
        require(sender != operator, "SENDER==OPERATOR");
        require(operator != address(0), "OPERATOR==0");
        require(!_superOperators[operator], "APPR_EXISTING_SUPEROPERATOR");
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /* solhint-disable code-complexity */
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bool authorized
    ) internal {
        uint256 numItems = ids.length;
        uint256 bin;
        uint256 index;
        uint256 balFrom;
        uint256 balTo;

        uint256 lastBin;
        uint256 numNFTs = 0;
        for (uint256 i = 0; i < numItems; i++) {
            if (ids[i] & ERC1155ERC721Helper.IS_NFT > 0) {
                require(authorized || _erc721operators[ids[i]] == _msgSender(), "OPERATOR_!AUTH");
                if (values[i] > 0) {
                    require(values[i] == 1, "NFT!=1");
                    require(_ownerOf(ids[i]) == from, "OWNER!=FROM");
                    numNFTs++;
                    _owners[ids[i]] = uint256(uint160(to));
                    if (_erc721operators[ids[i]] != address(0)) {
                        // TODO operatorEnabled flag optimization (like in ERC721BaseToken)
                        _erc721operators[ids[i]] = address(0);
                    }
                    emit Transfer(from, to, ids[i]);
                }
            } else {
                require(authorized, "OPERATOR_!AUTH");
                if (from == to) {
                    _checkEnoughBalance(from, ids[i], values[i]);
                } else if (values[i] > 0) {
                    (bin, index) = ids[i].getTokenBinIndex();
                    if (lastBin == 0) {
                        lastBin = bin;
                        balFrom = ObjectLib32.updateTokenBalance(
                            _packedTokenBalance[from][bin],
                            index,
                            values[i],
                            ObjectLib32.Operations.SUB
                        );
                        balTo = ObjectLib32.updateTokenBalance(
                            _packedTokenBalance[to][bin],
                            index,
                            values[i],
                            ObjectLib32.Operations.ADD
                        );
                    } else {
                        if (bin != lastBin) {
                            _packedTokenBalance[from][lastBin] = balFrom;
                            _packedTokenBalance[to][lastBin] = balTo;
                            balFrom = _packedTokenBalance[from][bin];
                            balTo = _packedTokenBalance[to][bin];
                            lastBin = bin;
                        }

                        balFrom = balFrom.updateTokenBalance(index, values[i], ObjectLib32.Operations.SUB);
                        balTo = balTo.updateTokenBalance(index, values[i], ObjectLib32.Operations.ADD);
                    }
                }
            }
        }
        if (numNFTs > 0 && from != to) {
            _numNFTPerAddress[from] -= numNFTs;
            _numNFTPerAddress[to] += numNFTs;
        }

        if (bin != 0 && from != to) {
            _packedTokenBalance[from][bin] = balFrom;
            _packedTokenBalance[to][bin] = balTo;
        }
    }

    /* solhint-enable code-complexity */

    function _checkERC1155AndCallSafeTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool erc721,
        bool erc721Safe
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        if (erc721) {
            if (!_checkIsERC1155Receiver(to)) {
                if (erc721Safe) {
                    return _checkERC721AndCallSafeTransfer(operator, from, to, id, data);
                } else {
                    return true;
                }
            }
        }
        return IERC1155TokenReceiver(to).onERC1155Received(operator, from, id, value, data) == ERC1155_RECEIVED;
    }

    function _checkERC1155AndCallSafeBatchTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, values, data);
        return (retval == ERC1155_BATCH_RECEIVED);
    }

    function _checkERC721AndCallSafeTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal returns (bool) {
        // following not required as this function is always called as part of ERC1155 checks that include such check already
        // if (!to.isContract()) {
        //     return true;
        // }
        return (IERC721TokenReceiver(to).onERC721Received(operator, from, id, data) == ERC721_RECEIVED);
    }

    function _burnERC1155(
        address operator,
        address from,
        uint256 id,
        uint32 amount
    ) internal {
        (uint256 bin, uint256 index) = (id).getTokenBinIndex();
        _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
            index,
            amount,
            ObjectLib32.Operations.SUB
        );
        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _burnERC721(
        address operator,
        address from,
        uint256 id
    ) internal {
        require(from == _ownerOf(id), "OWNER!=FROM");
        _owners[id] = 2**160; // equivalent to zero address when casted but ensure we track minted status
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
        emit TransferSingle(operator, from, address(0), id, 1);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        address sender = _msgSender();
        if ((id & ERC1155ERC721Helper.IS_NFT) > 0) {
            require(amount == 1, "AMOUNT!=1");
            _burnERC721(isTrustedForwarder(msg.sender) ? from : sender, from, id);
        } else {
            require(amount > 0 && amount <= ERC1155ERC721Helper.MAX_SUPPLY, "INVALID_AMOUNT");
            _burnERC1155(isTrustedForwarder(msg.sender) ? from : sender, from, id, uint32(amount));
        }
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        address operator = isTrustedForwarder(msg.sender) ? from : _msgSender();
        for (uint256 i = 0; i < ids.length; i++) {
            if ((ids[i] & ERC1155ERC721Helper.IS_NFT) > 0) {
                require(amounts[i] == 1, "amounts[i]!=1");
                require(from == _ownerOf(ids[i]), "OWNER!=FROM");
                _owners[ids[i]] = 2**160; // equivalent to zero address when casted but ensure we track minted status
                _numNFTPerAddress[from]--;
                emit Transfer(from, address(0), ids[i]);
            } else {
                require(amounts[i] > 0 && amounts[i] <= ERC1155ERC721Helper.MAX_SUPPLY, "INVALID_AMOUNT");
                (uint256 bin, uint256 index) = (ids[i]).getTokenBinIndex();
                _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
                    index,
                    amounts[i],
                    ObjectLib32.Operations.SUB
                );
            }
        }
        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _allocateIds(
        address creator,
        uint256[] memory supplies,
        bytes memory rarityPack,
        uint40 packId,
        bytes32 hash
    ) internal returns (uint256[] memory ids, uint16 numNFTs) {
        require(supplies.length > 0, "SUPPLIES<=0");
        require(supplies.length <= ERC1155ERC721Helper.MAX_PACK_SIZE, "BATCH_TOO_BIG");
        (ids, numNFTs) = _generateTokenIds(creator, supplies, packId);

        require(uint256(_metadataHash[ids[0] & ERC1155ERC721Helper.URI_ID]) == 0, "ID_TAKEN");
        _metadataHash[ids[0] & ERC1155ERC721Helper.URI_ID] = hash;
        _rarityPacks[ids[0] & ERC1155ERC721Helper.URI_ID] = rarityPack;
    }

    function _completeMultiMint(
        address operator,
        address owner,
        uint256[] memory ids,
        uint256[] memory supplies,
        bytes memory data
    ) internal {
        emit TransferBatch(operator, address(0), owner, ids, supplies);
        require(
            _checkERC1155AndCallSafeBatchTransfer(operator, address(0), owner, ids, supplies, data),
            "TRANSFER_REJECTED"
        );
    }

    function _mintBatches(
        uint256[] memory supplies,
        address owner,
        uint256[] memory ids,
        uint16 numNFTs
    ) internal {
        uint16 offset = 0;
        while (offset < supplies.length - numNFTs) {
            _mintBatch(offset, supplies, owner, ids);
            offset += 8;
        }
        // deal with NFT last. they do not care of balance packing
        if (numNFTs > 0) {
            _mintNFTs(uint16(supplies.length - numNFTs), numNFTs, owner, ids);
        }
    }

    function _mintNFTs(
        uint16 offset,
        uint16 numNFTs,
        address owner,
        uint256[] memory ids
    ) internal {
        for (uint256 i = 0; i < numNFTs; i++) {
            uint256 id = ids[i + offset];
            _owners[id] = uint256(uint160(owner));
            emit Transfer(address(0), owner, id);
        }
        _numNFTPerAddress[owner] += numNFTs;
    }

    function _mintBatch(
        uint16 offset,
        uint256[] memory supplies,
        address owner,
        uint256[] memory ids
    ) internal {
        (uint256 bin, uint256 index) = ids[offset].getTokenBinIndex();
        for (uint256 i = 0; i < 8 && offset + i < supplies.length; i++) {
            uint256 j = offset + i;
            if (supplies[j] > 1) {
                _packedTokenBalance[owner][bin] = _packedTokenBalance[owner][bin].updateTokenBalance(
                    index + i,
                    supplies[j],
                    ObjectLib32.Operations.ADD
                );
            } else {
                break;
            }
        }
    }

    /// @dev Use only when you mint from L1 to L2
    function _mintFTFromAnotherLayer(
        uint256 supply,
        address owner,
        uint256 id
    ) internal {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();

        _packedTokenBalance[owner][bin] = _packedTokenBalance[owner][bin].updateTokenBalance(
            index,
            supply,
            ObjectLib32.Operations.ADD
        );
    }

    function _mintNFTFromAnotherLayer(address owner, uint256 id) internal {
        _owners[id] = uint256(uint160(owner));
        _numNFTPerAddress[owner]++;
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal returns (bool metaTx) {
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");
        address sender = _msgSender();
        metaTx = isTrustedForwarder(msg.sender);
        bool authorized = from == sender || isApprovedForAll(from, sender);

        if (id & ERC1155ERC721Helper.IS_NFT > 0) {
            require(authorized || _erc721operators[id] == sender, "OPERATOR_!AUTH");
            if (value > 0) {
                require(value == 1, "NFT!=1");
                _numNFTPerAddress[from]--;
                _numNFTPerAddress[to]++;
                _owners[id] = uint256(uint160(to));
                if (_erc721operators[id] != address(0)) {
                    _erc721operators[id] = address(0);
                }
                emit Transfer(from, to, id);
            }
        } else {
            require(authorized, "OPERATOR_!AUTH");
            if (value > 0) {
                // if different owners it will fails
                (uint256 bin, uint256 index) = id.getTokenBinIndex();
                _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
                    index,
                    value,
                    ObjectLib32.Operations.SUB
                );
                _packedTokenBalance[to][bin] = _packedTokenBalance[to][bin].updateTokenBalance(
                    index,
                    value,
                    ObjectLib32.Operations.ADD
                );
            }
        }

        emit TransferSingle(metaTx ? from : sender, from, to, id, value);
    }

    function _extractERC721From(
        address operator,
        address sender,
        uint256 id,
        address to
    ) internal returns (uint256 newId) {
        require(to != address(0), "TO==0");
        require(id & ERC1155ERC721Helper.IS_NFT == 0, "!1155");
        uint32 tokenCollectionIndex = _nextCollectionIndex[id];
        newId = id + ERC1155ERC721Helper.IS_NFT + (tokenCollectionIndex) * 2**ERC1155ERC721Helper.NFT_INDEX_OFFSET;
        _nextCollectionIndex[id] = tokenCollectionIndex + 1;
        _burnERC1155(operator, sender, id, 1);
        _mint(_metadataHash[id & ERC1155ERC721Helper.URI_ID], 1, 0, operator, to, newId, "", true);
        emit Extraction(id, newId);
    }

    function _mint(
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address operator,
        address owner,
        uint256 id,
        bytes memory data,
        bool extraction
    ) internal {
        uint256 uriId = id & ERC1155ERC721Helper.URI_ID;
        if (!extraction) {
            require(uint256(_metadataHash[uriId]) == 0, "ID_TAKEN");
            _metadataHash[uriId] = hash;
            require(rarity < 4, "RARITY>=4");
            bytes memory pack = new bytes(1);
            pack[0] = bytes1(rarity * 64);
            _rarityPacks[uriId] = pack;
        }
        if (supply == 1) {
            // ERC721
            _numNFTPerAddress[owner]++;
            _owners[id] = uint256(uint160(owner));
            emit Transfer(address(0), owner, id);
        } else {
            (uint256 bin, uint256 index) = id.getTokenBinIndex();
            _packedTokenBalance[owner][bin] = _packedTokenBalance[owner][bin].updateTokenBalance(
                index,
                supply,
                ObjectLib32.Operations.REPLACE
            );
        }

        emit TransferSingle(operator, address(0), owner, id, supply);
        require(
            _checkERC1155AndCallSafeTransfer(operator, address(0), owner, id, supply, data, false, false),
            "TRANSFER_REJECTED"
        );
    }

    /// @dev Allows the use of a bitfield to track the initialized status of the version `v` passed in as an arg.
    /// If the bit at the index corresponding to the given version is already set, revert.
    /// Otherwise, set the bit and return.
    /// @param v The version of this contract.
    function _checkInit(uint256 v) internal {
        require((_initBits >> v) & uint256(1) != 1, "ALREADY_INITIALISED");
        _initBits = _initBits | (uint256(1) << v);
    }

    function _checkIsERC1155Receiver(address _contract) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory callData = abi.encodeWithSelector(ERC165ID, ERC1155_IS_RECEIVER);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let call_ptr := add(0x20, callData)
            let call_size := mload(callData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }

    function _checkEnoughBalance(
        address from,
        uint256 id,
        uint256 value
    ) internal view {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        require(_packedTokenBalance[from][bin].getValueInBin(index) >= value, "BALANCE_TOO_LOW");
    }

    function _ownerOf(uint256 id) internal view returns (address) {
        return address(uint160(_owners[id]));
    }

    function _generateTokenId(
        address creator,
        uint256 supply,
        uint40 packId,
        uint16 numFTs,
        uint16 packIndex
    ) internal view returns (uint256) {
        require(supply > 0 && supply <= ERC1155ERC721Helper.MAX_SUPPLY, "SUPPLY_OUT_OF_BOUNDS");
        return
            uint256(uint160(creator)) *
            ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER + // CREATOR
            (supply == 1 ? uint256(1) * ERC1155ERC721Helper.IS_NFT_OFFSET_MULTIPLIER : 0) + // minted as NFT(1)|FT(0) // ERC1155ERC721Helper.IS_NFT
            uint256(_chainIndex) *
            CHAIN_INDEX_OFFSET_MULTIPLIER + // mainnet = 0, polygon = 1
            uint256(packId) *
            ERC1155ERC721Helper.PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack) // ERC1155ERC721Helper.URI_ID
            numFTs *
            ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER + // number of fungible token in the pack // ERC1155ERC721Helper.URI_ID
            packIndex; // packIndex (position in the pack) // PACK_INDEX
    }

    function _generateTokenIds(
        address creator,
        uint256[] memory supplies,
        uint40 packId
    ) internal view returns (uint256[] memory, uint16) {
        uint16 numTokenTypes = uint16(supplies.length);
        uint256[] memory ids = new uint256[](numTokenTypes);
        uint16 numNFTs = 0;
        for (uint16 i = 0; i < numTokenTypes; i++) {
            if (numNFTs == 0) {
                if (supplies[i] == 1) {
                    numNFTs = uint16(numTokenTypes - i);
                }
            } else {
                require(supplies[i] == 1, "NFTS_MUST_BE_LAST");
            }
        }
        uint16 numFTs = numTokenTypes - numNFTs;
        for (uint16 i = 0; i < numTokenTypes; i++) {
            ids[i] = _generateTokenId(creator, supplies[i], packId, numFTs, i);
        }
        return (ids, numNFTs);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/IAssetAttributesRegistry.sol";

// used to reduce PolygonAssetV2 contract code size
library AssetHelper {
    struct AssetRegistryData {
        IAssetAttributesRegistry assetRegistry;
    }

    function setCatalystDatas(
        AssetRegistryData storage self,
        IAssetAttributesRegistry.AssetGemsCatalystData[] memory assetGemsCatalystData
    ) public {
        for (uint256 i = 0; i < assetGemsCatalystData.length; i++) {
            require(assetGemsCatalystData[i].catalystContractId > 0, "WRONG_catalystContractId");
            require(assetGemsCatalystData[i].assetId != 0, "WRONG_assetId");
            self.assetRegistry.setCatalystWhenDepositOnOtherLayer(
                assetGemsCatalystData[i].assetId,
                assetGemsCatalystData[i].catalystContractId,
                assetGemsCatalystData[i].gemContractIds
            );
        }
    }

    function decodeAndSetCatalystDataL1toL2(AssetRegistryData storage self, bytes calldata depositData)
        public
        returns (
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes32[] memory hashes
        )
    {
        bytes memory data;
        IAssetAttributesRegistry.AssetGemsCatalystData[] memory catalystDatas;
        (ids, amounts, data) = abi.decode(depositData, (uint256[], uint256[], bytes));
        (hashes, catalystDatas) = abi.decode(data, (bytes32[], IAssetAttributesRegistry.AssetGemsCatalystData[]));

        setCatalystDatas(self, catalystDatas);
    }

    function decodeAndSetCatalystDataL2toL1(AssetRegistryData storage self, bytes calldata data)
        public
        returns (bytes32[] memory hashes)
    {
        IAssetAttributesRegistry.AssetGemsCatalystData[] memory catalystDatas;

        (hashes, catalystDatas) = abi.decode(data, (bytes32[], IAssetAttributesRegistry.AssetGemsCatalystData[]));

        setCatalystDatas(self, catalystDatas);
    }

    function getGemsAndCatalystData(AssetRegistryData storage self, uint256[] calldata assetIds)
        public
        view
        returns (IAssetAttributesRegistry.AssetGemsCatalystData[] memory)
    {
        uint256 count = getGemsCatalystDataCount(self, assetIds);
        uint256 indexInCatalystArray;

        IAssetAttributesRegistry.AssetGemsCatalystData[] memory gemsCatalystDatas =
            new IAssetAttributesRegistry.AssetGemsCatalystData[](count);

        for (uint256 i = 0; i < assetIds.length; i++) {
            (bool isDataFound, uint16 catalystId, uint16[] memory gemIds) = self.assetRegistry.getRecord(assetIds[i]);
            if (isDataFound) {
                IAssetAttributesRegistry.AssetGemsCatalystData memory data;
                data.assetId = assetIds[i];
                data.catalystContractId = catalystId;
                data.gemContractIds = gemIds;
                require(indexInCatalystArray < count, "indexInCatalystArray out of bound");
                gemsCatalystDatas[indexInCatalystArray] = data;
                indexInCatalystArray++;
            }
        }

        return gemsCatalystDatas;
    }

    function getGemsCatalystDataCount(AssetRegistryData storage self, uint256[] calldata assetIds)
        internal
        view
        returns (uint256)
    {
        uint256 count;

        for (uint256 i = 0; i < assetIds.length; i++) {
            (bool isDataFound, , ) = self.assetRegistry.getRecord(assetIds[i]);
            if (isDataFound) {
                count++;
            }
        }
        return count;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /**
        @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if balance of holder for token `id` is lower than the `value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param id      ID of the token type
        @param value   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
        @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if length of `ids` is not the same as length of `values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param ids     IDs of each token type (order and length must match _values array)
        @param values  Transfer amounts per token type (order and length must match _ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param owner  The address of the token holder
        @param id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param id        The ID of the token being transferred
        @param value     The amount of tokens being transferred
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

library ObjectLib32 {
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 internal constant TYPES_BITS_SIZE = 32; // Max size of each object
    uint256 internal constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /// @dev Return the bin number and index within that bin where ID is
    /// @param tokenId Object type
    /// @return bin Bin number.
    /// @return index ID's index within that bin.
    function getTokenBinIndex(uint256 tokenId) internal pure returns (uint256 bin, uint256 index) {
        unchecked {bin = (tokenId * TYPES_BITS_SIZE) / 256;}
        index = tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in binBalances
     * @param binBalances Uint256 containing the balances of objects
     * @param index Index of the object in the provided bin
     * @param amount Value to update the type balance
     * @param operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with amount
     *     Operations.ADD     : ADD amount to type balance
     *     Operations.SUB     : Substract amount from type balance
     */
    function updateTokenBalance(
        uint256 binBalances,
        uint256 index,
        uint256 amount,
        Operations operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (operation == Operations.ADD) {
            objectBalance = getValueInBin(binBalances, index);
            newBinBalance = writeValueInBin(binBalances, index, objectBalance + amount);
        } else if (operation == Operations.SUB) {
            objectBalance = getValueInBin(binBalances, index);
            require(objectBalance >= amount, "can't substract more than there is");
            newBinBalance = writeValueInBin(binBalances, index, objectBalance - amount);
        } else if (operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(binBalances, index, amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in binValue at position index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index index at which to retrieve value
     * @return Value at given index in bin
     */
    function getValueInBin(uint256 binValue, uint256 index) internal pure returns (uint256) {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated binValue after writing amount at index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index Index at which to retrieve value
     * @param amount Value to store at index in bin
     * @return Value at given index in bin
     */
    function writeValueInBin(
        uint256 binValue,
        uint256 index,
        uint256 amount
    ) internal pure returns (uint256) {
        require(amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue & ~(mask << leftShift)) | (amount << leftShift);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

interface IERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library ERC1155ERC721Helper {
    bytes32 private constant base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;

    uint256 public constant CREATOR_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 public constant IS_NFT_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1);
    uint256 public constant PACK_ID_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40);
    uint256 public constant PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40 - 12);
    uint256 public constant NFT_INDEX_OFFSET = 63;

    uint256 public constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    uint256 public constant NOT_IS_NFT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant NFT_INDEX = 0x00000000000000000000000000000000000000007FFFFFFF8000000000000000;
    uint256 public constant NOT_NFT_INDEX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000007FFFFFFFFFFFFFFF;
    uint256 public constant URI_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFFFFF800;
    uint256 public constant PACK_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFF800000;
    uint256 public constant PACK_INDEX = 0x00000000000000000000000000000000000000000000000000000000000007FF;
    uint256 public constant PACK_NUM_FT_TYPES = 0x00000000000000000000000000000000000000000000000000000000007FF800;

    uint256 public constant MAX_SUPPLY = uint256(2)**32 - 1;
    uint256 public constant MAX_PACK_SIZE = uint256(2)**11;

    function toFullURI(bytes32 hash, uint256 id) public pure returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybei", hash2base32(hash), "/", uint2str(id & PACK_INDEX), ".json"));
    }

    // solium-disable-next-line security/no-assign-params
    function hash2base32(bytes32 hash) public pure returns (string memory _uintAsString) {
        uint256 _i = uint256(hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = base32Alphabet[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = base32Alphabet[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }

    // solium-disable-next-line security/no-assign-params
    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + uint8(_i % 10)));
            _i /= 10;
        }

        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "../common/BaseWithStorage/ERC20/extensions/ERC20BasicApproveExtension.sol";
import "../common/BaseWithStorage/ERC20/ERC20BaseToken.sol";

contract SandBaseToken is ERC20BaseToken, ERC20BasicApproveExtension {
    constructor(
        address sandAdmin,
        address executionAdmin,
        address beneficiary,
        uint256 amount
    ) ERC20BaseToken("SAND", "SAND", sandAdmin, executionAdmin) {
        _admin = sandAdmin;
        if (beneficiary != address(0)) {
            uint256 initialSupply = amount * (1 ether);
            _mint(beneficiary, initialSupply);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/BaseWithStorage/ERC20/ERC20BaseToken.sol";

contract FakePolygonSand is ERC20BaseToken {
    constructor() ERC20BaseToken("FakePolygonSand", "FPS", msg.sender, msg.sender) {
        _mint(msg.sender, 3000000000 * 10**18);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/BaseWithStorage/ERC20/ERC20BaseToken.sol";

contract FakePolygonLand is ERC20BaseToken {
    constructor() ERC20BaseToken("FakePolygonLand", "FPL", msg.sender, msg.sender) {
        _mint(msg.sender, 3000000000 * 10**18);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/BaseWithStorage/ERC20/ERC20BaseToken.sol";

contract FakeLPSandMatic is ERC20BaseToken {
    constructor() ERC20BaseToken("LPSandMatic", "LPSM", msg.sender, msg.sender) {
        _mint(msg.sender, 3000000000 * 10**18);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/interfaces/IERC20.sol";
import "../common/interfaces/Medianizer.sol";
import "../common/interfaces/IERC1155TokenReceiver.sol";
import "../common/BaseWithStorage/WithAdmin.sol";
import "../asset/ERC1155ERC721.sol";

/// @title PolygonBundleSandSale contract.
/// @notice This contract receives bundles of: Assets (ERC1155) + Sand.
/// @notice Then those bundles are sold to users. Users can pay BaseCoin (Ethers) or Dais for the bundles.
contract PolygonBundleSandSale is WithAdmin, IERC1155TokenReceiver {
    bytes4 public constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 public constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    event BundleSale(
        uint256 indexed saleId,
        uint256[] ids,
        uint256[] amounts,
        uint256 sandAmount,
        uint256 priceUSD,
        uint256 numPacks
    );

    event BundleSold(
        uint256 indexed saleId,
        address indexed buyer,
        uint256 numPacks,
        address token,
        uint256 tokenAmount
    );

    Medianizer public medianizer;
    IERC20 public dai;
    IERC20 public sand;
    ERC1155ERC721 public asset;
    address payable public receivingWallet;

    /*
        This is the main structure representing a pack to be sold.
        Each pack includes some Assets (NFTs or small collection of fungible tokens) plus Sand
    */
    struct Sale {
        uint256[] ids; // ids of the Assets in each pack
        uint256[] amounts; // Amount of each Asset  in each pack
        uint256 sandAmount; // Sands sold with each pack
        uint256 priceUSD; // Price in USD for each Pack u$s * 1e18 (aka: 1u$s == 1e18 wei)
        uint256 numPacksLeft; // Number of packs left, used for accounting
    }

    Sale[] private sales;

    constructor(
        IERC20 sandTokenContractAddress,
        ERC1155ERC721 assetTokenContractAddress,
        Medianizer medianizerContractAddress,
        IERC20 daiTokenContractAddress,
        address admin,
        address payable receivingWallet_
    ) {
        require(receivingWallet_ != address(0), "need a wallet to receive funds");
        medianizer = medianizerContractAddress;
        sand = sandTokenContractAddress;
        asset = assetTokenContractAddress;
        dai = daiTokenContractAddress;
        _admin = admin;
        receivingWallet = receivingWallet_;
    }

    /// @notice set the wallet receiving the proceeds
    /// @param newWallet address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external onlyAdmin {
        require(newWallet != address(0), "receiving wallet cannot be zero address");
        receivingWallet = newWallet;
    }

    /**
     * @notice Buys Sand Bundle with Ether
     * @param saleId id of the bundle
     * @param numPacks the amount of packs to buy
     * @param to The address that will receive the SAND
     */
    function buyBundleWithEther(
        uint256 saleId,
        uint256 numPacks,
        address to
    ) external payable {
        (uint256 saleIndex, uint256 usdRequired) = _getSaleAmount(saleId, numPacks);
        uint256 ethRequired = getEtherAmountWithUSD(usdRequired);
        require(msg.value >= ethRequired, "not enough ether sent");
        uint256 leftOver = msg.value - ethRequired;
        if (leftOver > 0) {
            payable(msg.sender).transfer(leftOver);
            // refund extra
        }
        payable(receivingWallet).transfer(ethRequired);
        _transferPack(saleIndex, numPacks, to);

        emit BundleSold(saleId, msg.sender, numPacks, address(0), ethRequired);
    }

    /**
     * @notice Buys Sand Bundle with DAI
     * @param saleId id of the bundle
     * @param numPacks the amount of packs to buy
     * @param to The address that will receive the SAND
     */
    function buyBundleWithDai(
        uint256 saleId,
        uint256 numPacks,
        address to
    ) external {
        (uint256 saleIndex, uint256 usdRequired) = _getSaleAmount(saleId, numPacks);
        require(dai.transferFrom(msg.sender, receivingWallet, usdRequired), "failed to transfer dai");
        _transferPack(saleIndex, numPacks, to);

        emit BundleSold(saleId, msg.sender, numPacks, address(dai), usdRequired);
    }

    /**
     * @notice get a specific sale information
     * @param saleId id of the bundle
     * @return priceUSD price in USD
     * @return numPacksLeft number of packs left
     */
    function getSaleInfo(uint256 saleId) external view returns (uint256 priceUSD, uint256 numPacksLeft) {
        require(saleId > 0, "invalid saleId");
        uint256 saleIndex = saleId - 1;
        priceUSD = sales[saleIndex].priceUSD;
        numPacksLeft = sales[saleIndex].numPacksLeft;
    }

    /**
     * @notice Remove a sale returning everything to some address
     * @param saleId id of the bundle
     * @param to The address that will receive the SAND
     */
    function withdrawSale(uint256 saleId, address to) external onlyAdmin {
        require(saleId > 0, "invalid saleId");
        uint256 saleIndex = saleId - 1;
        uint256 numPacksLeft = sales[saleIndex].numPacksLeft;
        sales[saleIndex].numPacksLeft = 0;

        uint256[] memory ids = sales[saleIndex].ids;
        uint256[] memory amounts = sales[saleIndex].amounts;
        uint256 numIds = ids.length;
        for (uint256 i = 0; i < numIds; i++) {
            amounts[i] = amounts[i] * numPacksLeft;
        }
        require(
            sand.transferFrom(address(this), to, numPacksLeft * sales[saleIndex].sandAmount),
            "transfer fo Sand failed"
        );
        asset.safeBatchTransferFrom(address(this), to, ids, amounts, "");
    }

    /**
     * @notice IERC1155TokenReceiver callback, creates a new Sale
     * @notice OBS: in the case of NFTs (one of a kind) value is one so numPacks must be 1 too to be divisible.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(address(asset) == msg.sender, "only accept asset as sender");
        require(from == operator, "only self executed transfer allowed");
        require(value > 0, "no Asset transfered");
        require(data.length > 0, "data need to contains the sale data");

        (uint256 numPacks, uint256 sandAmountPerPack, uint256 priceUSDPerPack) =
            abi.decode(data, (uint256, uint256, uint256));

        uint256 amount = value / numPacks;
        require(amount * numPacks == value, "invalid amounts, not divisible by numPacks");
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;
        _setupBundle(from, sandAmountPerPack, numPacks, ids, amounts, priceUSDPerPack);
        return ERC1155_RECEIVED;
    }

    /**
     * @notice IERC1155TokenReceiver callback, creates a new Sale
     * @notice OBS: in the case of NFTs (one of a kind) value is one so numPacks must be 1 too to be divisible.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        require(address(asset) == msg.sender, "only accept asset as sender");
        require(from == operator, "only self executed transfer allowed");
        require(ids.length > 0, "need to contains Asset");
        require(data.length > 0, "data need to contains the sale data");

        (uint256 numPacks, uint256 sandAmountPerPack, uint256 priceUSDPerPack) =
            abi.decode(data, (uint256, uint256, uint256));

        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            require(values[i] > 0, "asset transfer with zero values");
            uint256 amount = values[i] / numPacks;
            require(amount * numPacks == values[i], "invalid amounts, not divisible by numPacks");
            amounts[i] = amount;
        }

        _setupBundle(from, sandAmountPerPack, numPacks, ids, amounts, priceUSDPerPack);
        return ERC1155_BATCH_RECEIVED;
    }

    /**
     * @notice Returns the amount of ETH for a specific amount
     * @notice This rounds down with a precision of 1wei if usdAmount price is expressed in u$s * 10e18
     * @param usdAmount An amount of USD
     * @return The amount of ETH
     */
    function getEtherAmountWithUSD(uint256 usdAmount) public view returns (uint256) {
        uint256 ethUsdPair = getEthUsdPair();
        return (usdAmount * 1 ether) / ethUsdPair;
    }

    /**
     * @notice Gets the ETHUSD pair from the Medianizer contract
     * @return The pair as an uint256
     */
    function getEthUsdPair() internal view returns (uint256) {
        bytes32 pair = medianizer.read();
        return uint256(pair);
    }

    function _transferPack(
        uint256 saleIndex,
        uint256 numPacks,
        address to
    ) internal {
        uint256 sandAmountPerPack = sales[saleIndex].sandAmount;
        require(sand.transferFrom(address(this), to, sandAmountPerPack * numPacks), "Sand Transfer failed");
        uint256[] memory ids = sales[saleIndex].ids;
        uint256[] memory amounts = sales[saleIndex].amounts;
        uint256 numIds = ids.length;
        for (uint256 i = 0; i < numIds; i++) {
            amounts[i] = amounts[i] * numPacks;
        }
        asset.safeBatchTransferFrom(address(this), to, ids, amounts, "");
    }

    /**
     * @notice Create a Sale to be sold.
     * @param from seller address
     * @param sandAmountPerPack the sands that will be sell with the Sale
     * @param numPacks number of packs that this sale contains
     * @param ids list of ids to create bundle from
     * @param amounts the corresponding amounts of assets to be bundled for sale
     * @param priceUSDPerPack price in USD per pack
     */
    function _setupBundle(
        address from,
        uint256 sandAmountPerPack,
        uint256 numPacks,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 priceUSDPerPack
    ) internal {
        require(sand.transferFrom(from, address(this), sandAmountPerPack * numPacks), "failed to transfer Sand");
        sales.push(
            Sale({
                ids: ids,
                amounts: amounts,
                sandAmount: sandAmountPerPack,
                priceUSD: priceUSDPerPack,
                numPacksLeft: numPacks
            })
        );
        uint256 saleId = sales.length;
        emit BundleSale(saleId, ids, amounts, sandAmountPerPack, priceUSDPerPack, numPacks);
    }

    function _getSaleAmount(uint256 saleId, uint256 numPacks)
        internal
        returns (uint256 saleIndex, uint256 usdRequired)
    {
        require(saleId > 0, "PolygonBundleSandSale: invalid saleId");
        saleIndex = saleId - 1;
        uint256 numPacksLeft = sales[saleIndex].numPacksLeft;
        require(numPacksLeft >= numPacks, "PolygonBundleSandSale: not enough packs on sale");
        sales[saleIndex].numPacksLeft = numPacksLeft - numPacks;

        usdRequired = numPacks * sales[saleIndex].priceUSD;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @title Medianizer contract
 * @dev From MakerDAO (https://etherscan.io/address/0x729D19f657BD0614b4985Cf1D82531c67569197B#code)
 */
interface Medianizer {
    function read() external view returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "../../common/interfaces/IERC20Extended.sol";
import "./IRootChainManager.sol";

contract SandPolygonDepositor {
    IERC20Extended internal immutable _sand;
    address internal immutable _predicate;
    IRootChainManager internal immutable _rootChainManager;

    constructor(
        IERC20Extended sand,
        address predicate,
        IRootChainManager rootChainManager
    ) {
        _sand = sand;
        _predicate = predicate;
        _rootChainManager = rootChainManager;
    }

    function depositToPolygon(address beneficiary, uint256 amount) public {
        _sand.transferFrom(beneficiary, address(this), amount);
        _sand.approve(_predicate, amount);
        _rootChainManager.depositFor(beneficiary, address(_sand), abi.encode(amount));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IRootChainManager {
    event TokenMapped(address indexed rootToken, address indexed childToken, bytes32 indexed tokenType);

    event PredicateRegistered(bytes32 indexed tokenType, address indexed predicateAddress);

    function registerPredicate(bytes32 tokenType, address predicateAddress) external;

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function cleanMapToken(address rootToken, address childToken) external;

    function remapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/interfaces/IERC20Extended.sol";
import "../common/BaseWithStorage/WithPermit.sol";

/// @title Permit contract
/// @notice This contract manages approvals of SAND via signature
contract Permit is WithPermit {
    IERC20Extended internal immutable _sand;

    constructor(IERC20Extended sandContractAddress) {
        _sand = sandContractAddress;
    }

    /// @notice Permit the expenditure of SAND by a nominated spender.
    /// @param owner The owner of the ERC20 tokens.
    /// @param spender The nominated spender of the ERC20 tokens.
    /// @param value The value (allowance) of the ERC20 tokens that the nominated.
    /// spender will be allowed to spend.
    /// @param deadline The deadline for granting permission to the spender.
    /// @param v The final 1 byte of signature.
    /// @param r The first 32 bytes of signature.
    /// @param s The second 32 bytes of signature.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        checkApproveFor(owner, spender, value, deadline, v, r, s);
        _sand.approveFor(owner, spender, value);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "../common/Libraries/SigUtil.sol";
import "../common/Libraries/PriceUtil.sol";
import "../asset/AssetV2.sol";
import "../common/Base/TheSandbox712.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../common/interfaces/ERC1271.sol";
import "../common/interfaces/ERC1271Constants.sol";
import "../common/interfaces/ERC1654.sol";
import "../common/interfaces/ERC1654Constants.sol";

contract AssetSignedAuctionAuth is ERC1654Constants, ERC1271Constants, TheSandbox712, MetaTransactionReceiver {
    struct ClaimSellerOfferRequest {
        address buyer;
        address payable seller;
        address token;
        uint256[] purchase;
        uint256[] auctionData;
        uint256[] ids;
        uint256[] amounts;
        bytes signature;
    }

    enum SignatureType {DIRECT, EIP1654, EIP1271}

    bytes32 public constant AUCTION_TYPEHASH =
        keccak256(
            "Auction(address from,address token,uint256 offerId,uint256 startingPrice,uint256 endingPrice,uint256 startedAt,uint256 duration,uint256 packs,bytes ids,bytes amounts)"
        );

    event OfferClaimed(
        address indexed seller,
        address indexed buyer,
        uint256 indexed offerId,
        uint256 amount,
        uint256 pricePaid,
        uint256 feePaid
    );
    event OfferCancelled(address indexed seller, uint256 indexed offerId);

    uint256 public constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Stack too deep, grouping parameters
    // AuctionData:
    uint256 public constant AuctionData_OfferId = 0;
    uint256 public constant AuctionData_StartingPrice = 1;
    uint256 public constant AuctionData_EndingPrice = 2;
    uint256 public constant AuctionData_StartedAt = 3;
    uint256 public constant AuctionData_Duration = 4;
    uint256 public constant AuctionData_Packs = 5;

    mapping(address => mapping(uint256 => uint256)) public claimed;

    AssetV2 public _asset;
    uint256 public _fee10000th = 0;
    address payable public _feeCollector;

    event FeeSetup(address feeCollector, uint256 fee10000th);

    constructor(
        AssetV2 asset,
        address admin,
        address initialMetaTx,
        address payable feeCollector,
        uint256 fee10000th
    ) TheSandbox712() {
        _asset = asset;
        _feeCollector = feeCollector;
        _fee10000th = fee10000th;
        emit FeeSetup(feeCollector, fee10000th);
        _admin = admin;
        _setMetaTransactionProcessor(initialMetaTx, true);
    }

    /// @notice set fee parameters
    /// @param feeCollector address receiving the fee
    /// @param fee10000th fee in 10,000th
    function setFee(address payable feeCollector, uint256 fee10000th) external {
        require(msg.sender == _admin, "only admin can change fee");
        _feeCollector = feeCollector;
        _fee10000th = fee10000th;
        emit FeeSetup(feeCollector, fee10000th);
    }

    function _verifyParameters(
        address buyer,
        address payable seller,
        address token,
        uint256 buyAmount,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal view {
        require(ids.length == amounts.length, "ids and amounts length not matching");
        require(
            buyer == msg.sender || (token != address(0) && _metaTransactionContracts[msg.sender]),
            "not authorized"
        );
        uint256 amountAlreadyClaimed = claimed[seller][auctionData[AuctionData_OfferId]];
        require(amountAlreadyClaimed != MAX_UINT256, "Auction cancelled");

        uint256 total = amountAlreadyClaimed + buyAmount;
        require(total >= amountAlreadyClaimed, "overflow");
        require(total <= auctionData[AuctionData_Packs], "Buy amount exceeds sell amount");

        require(auctionData[AuctionData_StartedAt] <= block.timestamp, "Auction didn't start yet");
        require(
            auctionData[AuctionData_StartedAt] + auctionData[AuctionData_Duration] > block.timestamp,
            "Auction finished"
        );
    }

    /// @notice claim offer using EIP712
    /// @param input Claim Seller Offer Request
    function claimSellerOffer(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.DIRECT,
            true
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using EIP712 and EIP1271 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferViaEIP1271(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1271,
            true
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using EIP712 and EIP1654 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferViaEIP1654(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1654,
            true
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using Basic Signature
    /// @param input Claim Seller Offer Request
    function claimSellerOfferUsingBasicSig(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.DIRECT,
            false
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using Basic Signature and EIP1271 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferUsingBasicSigViaEIP1271(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1271,
            false
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using Basic Signature and EIP1654 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferUsingBasicSigViaEIP1654(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1654,
            false
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    function _executeDeal(
        address token,
        uint256[] memory purchase,
        address buyer,
        address payable seller,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 offer =
            PriceUtil.calculateCurrentPrice(
                auctionData[AuctionData_StartingPrice],
                auctionData[AuctionData_EndingPrice],
                auctionData[AuctionData_Duration],
                block.timestamp - auctionData[AuctionData_StartedAt]
            ) * purchase[0];
        claimed[seller][auctionData[AuctionData_OfferId]] =
            claimed[seller][auctionData[AuctionData_OfferId]] +
            purchase[0];

        uint256 fee = 0;
        if (_fee10000th > 0) {
            fee = PriceUtil.calculateFee(offer, _fee10000th);
        }

        uint256 total = offer + fee;
        require(total <= purchase[1], "offer exceeds max amount to spend");

        if (token != address(0)) {
            require(IERC20(token).transferFrom(buyer, seller, offer), "failed to transfer token price");
            if (fee > 0) {
                require(IERC20(token).transferFrom(buyer, _feeCollector, fee), "failed to collect fee");
            }
        } else {
            require(msg.value >= total, "ETH < total");
            if (msg.value > total) {
                payable(msg.sender).transfer(msg.value - total);
            }
            seller.transfer(offer);
            if (fee > 0) {
                _feeCollector.transfer(fee);
            }
        }

        uint256[] memory packAmounts = new uint256[](amounts.length);
        for (uint256 i = 0; i < packAmounts.length; i++) {
            packAmounts[i] = amounts[i] * purchase[0];
        }
        _asset.safeBatchTransferFrom(seller, buyer, ids, packAmounts, "");
        emit OfferClaimed(seller, buyer, auctionData[AuctionData_OfferId], purchase[0], offer, fee);
    }

    /// @notice cancel a offer previously signed, new offer need to use a id not used yet
    /// @param offerId offer to cancel
    function cancelSellerOffer(uint256 offerId) external {
        claimed[msg.sender][offerId] = MAX_UINT256;
        emit OfferCancelled(msg.sender, offerId);
    }

    function _ensureCorrectSigner(
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory signature,
        SignatureType signatureType,
        bool eip712
    ) internal view returns (address) {
        bytes memory dataToHash;
        address signer;

        if (eip712) {
            dataToHash = abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                _hashAuction(from, token, auctionData, ids, amounts)
            );
        } else {
            dataToHash = _encodeBasicSignatureHash(from, token, auctionData, ids, amounts);
        }

        if (signatureType == SignatureType.EIP1271) {
            require(
                ERC1271(from).isValidSignature(dataToHash, signature) == ERC1271_MAGICVALUE,
                "invalid 1271 signature"
            );
        } else if (signatureType == SignatureType.EIP1654) {
            require(
                ERC1654(from).isValidSignature(keccak256(dataToHash), signature) == ERC1654_MAGICVALUE,
                "invalid 1654 signature"
            );
        } else {
            signer = SigUtil.recover(keccak256(dataToHash), signature);
            require(signer == from, "signer != from");
        }

        return signer;
    }

    function _encodeBasicSignatureHash(
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal view returns (bytes memory) {
        return
            SigUtil.prefixed(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        AUCTION_TYPEHASH,
                        from,
                        token,
                        auctionData[AuctionData_OfferId],
                        auctionData[AuctionData_StartingPrice],
                        auctionData[AuctionData_EndingPrice],
                        auctionData[AuctionData_StartedAt],
                        auctionData[AuctionData_Duration],
                        auctionData[AuctionData_Packs],
                        keccak256(abi.encodePacked(ids)),
                        keccak256(abi.encodePacked(amounts))
                    )
                )
            );
    }

    function _hashAuction(
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    AUCTION_TYPEHASH,
                    from,
                    token,
                    auctionData[AuctionData_OfferId],
                    auctionData[AuctionData_StartingPrice],
                    auctionData[AuctionData_EndingPrice],
                    auctionData[AuctionData_StartedAt],
                    auctionData[AuctionData_Duration],
                    auctionData[AuctionData_Packs],
                    keccak256(abi.encodePacked(ids)),
                    keccak256(abi.encodePacked(amounts))
                )
            );
    }
}

pragma solidity 0.8.2;

library SigUtil {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address recovered) {
        require(sig.length == 65, "incorrect signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "version of signature should be 27 or 28");

        recovered = ecrecover(hash, v, r, s);
        require(recovered != address(0), "incorrect address");
    }

    function recoverWithZeroOnFailure(bytes32 hash, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes memory) {
        return abi.encodePacked("\x19Ethereum Signed Message:\n32", hash);
    }
}

pragma solidity 0.8.2;

import "./SafeMathWithRequire.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";

library PriceUtil {
    using SafeMathWithRequire for uint256;
    using SafeMath for uint256;

    function calculateCurrentPrice(
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 secondsPassed
    ) internal pure returns (uint256) {
        if (secondsPassed > duration) {
            return endingPrice;
        }
        if (endingPrice == startingPrice) {
            return endingPrice;
        } else if (endingPrice > startingPrice) {
            return startingPrice.add((endingPrice.sub(startingPrice)).mul(secondsPassed).div(duration));
        } else {
            return startingPrice.sub((startingPrice.sub(endingPrice)).mul(secondsPassed).div(duration));
        }
    }

    function calculateFee(uint256 price, uint256 fee10000th) internal pure returns (uint256) {
        // _fee < 10000, so the result will be <= price
        return (price.mul(fee10000th)) / 10000;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./ERC1155ERC721.sol";
import "../common/interfaces/IAssetAttributesRegistry.sol";
import "./libraries/AssetHelper.sol";

// solhint-disable-next-line no-empty-blocks
contract AssetV2 is ERC1155ERC721 {
    AssetHelper.AssetRegistryData private assetRegistryData;

    /// @notice fulfills the purpose of a constructor in upgradeable contracts
    function initialize(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        address predicate,
        uint8 chainIndex,
        address assetRegistry
    ) external {
        initV2(trustedForwarder, admin, bouncerAdmin, predicate, chainIndex);
        assetRegistryData.assetRegistry = IAssetAttributesRegistry(assetRegistry);
    }

    /// @notice called by predicate to mint tokens transferred from L2
    /// @param to address to mint to
    /// @param ids ids to mint
    /// @param amounts supply for each token type
    /// @param data extra data to accompany the minting call
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        require(_msgSender() == _predicate, "!PREDICATE");
        bytes32[] memory hashes = AssetHelper.decodeAndSetCatalystDataL2toL1(assetRegistryData, data);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 uriId = ids[i] & ERC1155ERC721Helper.URI_ID;
            _metadataHash[uriId] = hashes[i];
            _rarityPacks[uriId] = "0x00";
            uint16 numNFTs = 0;
            if ((ids[i] & ERC1155ERC721Helper.IS_NFT) > 0) {
                numNFTs = 1;
            }
            uint256[] memory singleId = new uint256[](1);
            singleId[0] = ids[i];
            uint256[] memory singleAmount = new uint256[](1);
            singleAmount[0] = amounts[i];
            _mintBatches(singleAmount, to, singleId, numNFTs);
        }
    }
}

pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract MetaTransactionReceiver is WithAdmin {
    mapping(address => bool) internal _metaTransactionContracts;
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);

    /// @notice Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) public {
        require(msg.sender == _admin, "only admin can setup metaTransactionProcessors");
        _setMetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    function _setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) internal {
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @notice check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who) external view returns (bool) {
        return _metaTransactionContracts[who];
    }
}

pragma solidity 0.8.2;

interface ERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param data Arbitrary length data signed on the behalf of address(this)
     * @param signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory data, bytes memory signature) external view returns (bytes4 magicValue);
}

pragma solidity 0.8.2;

contract ERC1271Constants {
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;
}

pragma solidity 0.8.2;

interface ERC1654 {
    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param hash 32 bytes hash to be signed
     * @param signature Signature byte array associated with hash
     * @return magicValue - 0x1626ba7e if valid else 0x00000000
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

pragma solidity 0.8.2;

contract ERC1654Constants {
    bytes4 internal constant ERC1654_MAGICVALUE = 0x1626ba7e;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "./interfaces/IOldCatalystRegistry.sol";
import "../common/interfaces/IAssetAttributesRegistry.sol";
import "./interfaces/ICollectionCatalystMigrations.sol";
import "../common/interfaces/IAssetToken.sol";
import "../common/BaseWithStorage/WithAdmin.sol";

/// @notice Contract performing migrations for collections, do not require owner approval
contract CollectionCatalystMigrations is WithAdmin, ICollectionCatalystMigrations {
    uint256 private constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;

    IOldCatalystRegistry internal immutable _oldRegistry;
    IAssetAttributesRegistry internal immutable _registry;
    IAssetToken internal immutable _asset;

    /// @notice CollectionCatalystMigrations depends on:
    /// @param asset: Asset Token Contract
    /// @param registry: New AssetAttributesRegistry
    /// @param oldRegistry: Old CatalystRegistry
    /// @param admin: Contract admin
    constructor(
        IAssetToken asset,
        IAssetAttributesRegistry registry,
        IOldCatalystRegistry oldRegistry,
        address admin
    ) {
        _oldRegistry = oldRegistry;
        _asset = asset;
        _registry = registry;
        _admin = admin;
    }

    /// @notice Migrate the catalyst for a collection of assets.
    /// @param assetId The id of the asset for which the catalyst is being migrated.
    /// @param oldGemIds The gems currently embedded in the catalyst (old gems count starts from 0)
    /// @param blockNumber The blocknumber to use when setting the catalyst.
    function migrate(
        uint256 assetId,
        uint16[] calldata oldGemIds,
        uint64 blockNumber
    ) external override {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _migrate(assetId, oldGemIds, blockNumber);
    }

    /// @notice Migrate the catalysts for a batch of assets.
    /// @param migrations The data to use for each migration in the batch.
    function batchMigrate(Migration[] calldata migrations) external override {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        for (uint256 i = 0; i < migrations.length; i++) {
            _migrate(migrations[i].assetId, migrations[i].gemIds, migrations[i].blockNumber);
        }
    }

    /// @notice Set the registry migration contract
    /// @param migrationContract The migration contract for AssetAttributesRegistry
    function setAssetAttributesRegistryMigrationContract(address migrationContract) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _registry.setMigrationContract(migrationContract);
    }

    /// @dev Perform the migration of the catalyst. See `migrate(...)`
    function _migrate(
        uint256 assetId,
        uint16[] memory oldGemIds,
        uint64 blockNumber
    ) internal {
        (bool oldExists, uint256 oldCatalystId) = _oldRegistry.getCatalyst(assetId);
        require(oldExists, "OLD_CATALYST_NOT_EXIST");
        (bool exists, , ) = _registry.getRecord(assetId);
        require(!exists, "ALREADY_MIGRATED");
        oldCatalystId += 1; // old catalyst start from 0 , new one start with common = 1
        if (assetId & IS_NFT != 0) {
            // ensure this NFT has no collection: original NFT
            // If it has, the collection itself need to be migrated
            try _asset.collectionOf(assetId) returns (uint256 collId) {
                require(collId == 0, "NOT_ORIGINAL_NFT");
                // solhint-disable-next-line no-empty-blocks
            } catch {}
        }
        // old gems started from 0, new gems starts with power = 1
        for (uint256 i = 0; i < oldGemIds.length; i++) {
            oldGemIds[i] += 1;
        }
        _registry.setCatalystWithBlockNumber(assetId, uint16(oldCatalystId), oldGemIds, blockNumber);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IOldCatalystRegistry {
    function getCatalyst(uint256 assetId) external view returns (bool exists, uint256 catalystId);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface ICollectionCatalystMigrations {
    struct Migration {
        uint256 assetId;
        uint16[] gemIds;
        uint64 blockNumber;
    }

    function migrate(
        uint256 assetId,
        uint16[] calldata gemIds,
        uint64 blockNumber
    ) external;

    function batchMigrate(Migration[] calldata migrations) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "../common/interfaces/IAttributes.sol";

contract DefaultAttributes is IAttributes {
    uint256 internal constant MAX_NUM_GEMS = 15;
    uint256 internal constant MAX_NUM_GEM_TYPES = 256;

    /// @notice Returns the values for each gem included in a given asset.
    /// @param assetId The asset tokenId.
    /// @param events An array of GemEvents. Be aware that only gemEvents from the last CatalystApplied event onwards should be used to populate a query. If gemEvents from multiple CatalystApplied events are included the output values will be incorrect.
    /// @return values An array of values for each gem present in the asset.
    function getAttributes(uint256 assetId, IAssetAttributesRegistry.GemEvent[] calldata events)
        external
        pure
        override
        returns (uint32[] memory values)
    {
        values = new uint32[](MAX_NUM_GEM_TYPES);

        uint256 numGems;
        for (uint256 i = 0; i < events.length; i++) {
            numGems += events[i].gemIds.length;
        }
        require(numGems <= MAX_NUM_GEMS, "TOO_MANY_GEMS");

        uint32 minValue = (uint32(numGems) - 1) * 5 + 1;

        uint256 numGemsSoFar = 0;
        for (uint256 i = 0; i < events.length; i++) {
            numGemsSoFar += events[i].gemIds.length;
            for (uint256 j = 0; j < events[i].gemIds.length; j++) {
                uint256 gemId = events[i].gemIds[j];
                uint256 slotIndex = numGemsSoFar - events[i].gemIds.length + j;
                if (values[gemId] == 0) {
                    // first gem : value = roll between ((numGemsSoFar-1)*5+1) and 25
                    values[gemId] = _computeValue(
                        assetId,
                        gemId,
                        events[i].blockHash,
                        slotIndex,
                        (uint32(numGemsSoFar) - 1) * 5 + 1
                    );
                    // bump previous values:
                    if (values[gemId] < minValue) {
                        values[gemId] = minValue;
                    }
                } else {
                    // further gem, previous roll are overriden with 25 and new roll between 1 and 25
                    uint32 newRoll = _computeValue(assetId, gemId, events[i].blockHash, slotIndex, 1);
                    values[gemId] = (((values[gemId] - 1) / 25) + 1) * 25 + newRoll;
                }
            }
        }
    }

    /// @dev compute a random value between min to 25.
    /// example: 1-25, 6-25, 11-25, 16-25
    /// @param assetId The id of the asset.
    /// @param gemId The id of the gem.
    /// @param blockHash The blockHash from the gemEvent.
    /// @param slotIndex Index of the current gem.
    /// @param min The minumum value this gem can have.
    /// @return The computed value for the given gem.
    function _computeValue(
        uint256 assetId,
        uint256 gemId,
        bytes32 blockHash,
        uint256 slotIndex,
        uint32 min
    ) internal pure returns (uint32) {
        return min + uint16(uint256(keccak256(abi.encodePacked(gemId, assetId, blockHash, slotIndex))) % (26 - min));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "../common/interfaces/IERC677Receiver.sol";

contract MockERC677Receiver is IERC677Receiver {
    event OnTokenTransferEvent(address indexed _sender, uint256 _value, bytes _data);

    /// @dev Emits the OnTokenTransferEvent.
    /// @param _sender The address of the sender.
    /// @param _value The value sent with the tx.
    /// @param _data The data sent with the tx.
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes calldata _data
    ) external override {
        emit OnTokenTransferEvent(_sender, _value, _data);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";
import "../common/interfaces/IAssetMinter.sol";
import "../catalyst/GemsCatalystsRegistry.sol";
import "../common/interfaces/IAssetToken.sol";

/// @notice Allow to mint Asset with Catalyst, Gems and Sand, giving the assets attributes through AssetAttributeRegistry
contract AssetMinter is ERC2771Handler, IAssetMinter, Ownable {
    uint256 private constant NFT_SUPPLY = 1;

    uint32 public numberOfGemsBurnPerAsset = 1;
    uint32 public numberOfCatalystBurnPerAsset = 1;
    uint256 public gemsFactor = 1000000000000000000;
    uint256 public catalystsFactor = 1000000000000000000;

    IAssetAttributesRegistry internal immutable _registry;
    IAssetToken internal immutable _asset;
    GemsCatalystsRegistry internal immutable _gemsCatalystsRegistry;

    mapping(uint16 => uint256) public quantitiesByCatalystId;
    mapping(uint16 => uint256) public quantitiesByAssetTypeId; // quantities for asset that don't use catalyst to burn (art, prop...)
    mapping(address => bool) public customMinterAllowance;

    /// @notice AssetMinter depends on
    /// @param registry: AssetAttributesRegistry for recording catalyst and gems used
    /// @param asset: Asset Token Contract (dual ERC1155/ERC721)
    /// @param gemsCatalystsRegistry: that track the canonical catalyst and gems and provide batch burning facility
    /// @param trustedForwarder: address of the trusted forwarder (used for metaTX)
    constructor(
        IAssetAttributesRegistry registry,
        IAssetToken asset,
        GemsCatalystsRegistry gemsCatalystsRegistry,
        address admin,
        address trustedForwarder,
        uint256[] memory quantitiesByCatalystId_,
        uint256[] memory quantitiesByAssetTypeId_
    ) {
        _registry = registry;
        _asset = asset;
        _gemsCatalystsRegistry = gemsCatalystsRegistry;
        transferOwnership(admin);
        __ERC2771Handler_initialize(trustedForwarder);

        require(quantitiesByCatalystId_.length > 0, "AssetMinter: quantitiesByCatalystID length cannot be 0");
        require(quantitiesByAssetTypeId_.length > 0, "AssetMinter: quantitiesByAssetTypeId length cannot be 0");

        for (uint16 i = 0; i < quantitiesByCatalystId_.length; i++) {
            quantitiesByCatalystId[i + 1] = quantitiesByCatalystId_[i];
        }

        for (uint16 i = 0; i < quantitiesByAssetTypeId_.length; i++) {
            quantitiesByAssetTypeId[i + 1] = quantitiesByAssetTypeId_[i];
        }
    }

    function addOrReplaceQuantitiyByCatalystId(uint16 catalystId, uint256 newQuantity) external override onlyOwner {
        quantitiesByCatalystId[catalystId] = newQuantity;
    }

    function addOrReplaceAssetTypeQuantity(uint16 index1Based, uint256 newQuantity) external override onlyOwner {
        quantitiesByAssetTypeId[index1Based] = newQuantity;
    }

    function setNumberOfGemsBurnPerAsset(uint32 newQuantity) external override onlyOwner {
        numberOfGemsBurnPerAsset = newQuantity;
    }

    function setNumberOfCatalystsBurnPerAsset(uint32 newQuantity) external override onlyOwner {
        numberOfCatalystBurnPerAsset = newQuantity;
    }

    function setGemsFactor(uint256 newQuantity) external override onlyOwner {
        gemsFactor = newQuantity;
    }

    function setCatalystsFactor(uint256 newQuantity) external override onlyOwner {
        catalystsFactor = newQuantity;
    }

    function setCustomMintingAllowance(address addressToModify, bool isAddressAllowed) external override onlyOwner {
        customMinterAllowance[addressToModify] = isAddressAllowed;
    }

    /// @notice mint "quantity" number of Asset token using one catalyst.
    /// @param mintData (-from address creating the Asset, need to be the tx sender or meta tx signer.
    ///  -packId unused packId that will let you predict the resulting tokenId.
    /// - metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// - to destination address receiving the minted tokens.
    /// - data extra data)
    /// @param catalystId Id of the Catalyst ERC20 token to burn (1, 2, 3 or 4).
    /// @param gemIds list of gem ids to burn in the catalyst.
    /// @param quantity number of token to mint
    /// @return assetId The new token Id.
    function mintCustomNumberWithCatalyst(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint256 quantity
    ) external override returns (uint256 assetId) {
        require(
            customMinterAllowance[_msgSender()] == true || _msgSender() == owner(),
            "AssetyMinter: custom minting unauthorized"
        );
        assetId = _burnAndMint(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            catalystId,
            gemIds,
            quantity,
            mintData.to,
            mintData.data
        );
    }

    /// @notice mint one Asset token with no catalyst.
    /// @param mintData : (-from address creating the Asset, need to be the tx sender or meta tx signer.
    ///  -packId unused packId that will let you predict the resulting tokenId.
    /// - metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// - to destination address receiving the minted tokens.
    /// - data extra data)
    /// @param typeAsset1Based (art, prop...) decide how many asset will be minted (start at 1)
    /// @return assetId The new token Id.
    function mintWithoutCatalyst(MintData calldata mintData, uint16 typeAsset1Based)
        external
        override
        returns (uint256 assetId)
    {
        uint256 quantity = quantitiesByAssetTypeId[typeAsset1Based];

        _mintRequirements(mintData.from, quantity, mintData.to);
        assetId = _asset.mint(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            quantity,
            0,
            mintData.to,
            mintData.data
        );
    }

    /// @notice mint multiple Asset tokens using one catalyst.
    /// @param mintData : (-from address creating the Asset, need to be the tx sender or meta tx signer.
    ///  -packId unused packId that will let you predict the resulting tokenId.
    /// - metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// - to destination address receiving the minted tokens.
    /// - data extra data)
    /// @param catalystId Id of the Catalyst ERC20 token to burn (1, 2, 3 or 4).
    /// @param gemIds list of gem ids to burn in the catalyst.
    /// @return assetId The new token Id.
    function mintWithCatalyst(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external override returns (uint256 assetId) {
        uint256 quantity = quantitiesByCatalystId[catalystId];

        assetId = _burnAndMint(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            catalystId,
            gemIds,
            quantity,
            mintData.to,
            mintData.data
        );
    }

    /// @notice mint multiple Asset tokens.
    /// @param mintData contains (-from address creating the Asset, need to be the tx sender or meta tx signer
    /// -packId unused packId that will let you predict the resulting tokenId
    /// -metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata)
    /// @param assets data (gems and catalyst data)
    function mintMultipleWithCatalyst(MintData calldata mintData, AssetData[] memory assets)
        external
        override
        returns (uint256[] memory assetIds)
    {
        require(assets.length != 0, "INVALID_0_ASSETS");
        require(mintData.to != address(0), "INVALID_TO_ZERO_ADDRESS");

        require(_msgSender() == mintData.from, "AUTH_ACCESS_DENIED");

        uint256[] memory supplies = _handleMultipleAssetRequirements(mintData.from, assets);
        assetIds = _asset.mintMultiple(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            supplies,
            "",
            mintData.to,
            mintData.data
        );
        for (uint256 i = 0; i < assetIds.length; i++) {
            require(assets[i].catalystId != 0, "AssetMinter: catalystID can't be 0");
            _registry.setCatalyst(assetIds[i], assets[i].catalystId, assets[i].gemIds);
        }
        return assetIds;
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    /// @dev Handler for dealing with assets when minting multiple at once.
    /// @param from The original address that signed the transaction.
    /// @param assets An array of AssetData structs to define how the total gems and catalysts are to be allocated.
    /// @return supplies An array of the quantities for each asset being minted.
    function _handleMultipleAssetRequirements(address from, AssetData[] memory assets)
        internal
        returns (uint256[] memory supplies)
    {
        supplies = new uint256[](assets.length);
        uint256[] memory catalystsToBurn = new uint256[](_gemsCatalystsRegistry.getNumberOfCatalystContracts());
        uint256[] memory gemsToBurn = new uint256[](_gemsCatalystsRegistry.getNumberOfGemContracts());

        for (uint256 i = 0; i < assets.length; i++) {
            require(
                assets[i].catalystId > 0 && assets[i].catalystId <= catalystsToBurn.length,
                "AssetMinter: catalystID out of bound"
            );
            catalystsToBurn[assets[i].catalystId - 1]++;
            for (uint256 j = 0; j < assets[i].gemIds.length; j++) {
                require(
                    assets[i].gemIds[j] > 0 && assets[i].gemIds[j] <= gemsToBurn.length,
                    "AssetMinter: gemId out of bound"
                );
                gemsToBurn[assets[i].gemIds[j] - 1]++;
            }

            uint16 maxGems = _gemsCatalystsRegistry.getMaxGems(assets[i].catalystId);
            require(assets[i].gemIds.length <= maxGems, "AssetMinter: too many gems");
            supplies[i] = quantitiesByCatalystId[assets[i].catalystId];
        }
        _batchBurnCatalysts(from, catalystsToBurn);
        _batchBurnGems(from, gemsToBurn);
    }

    /// @dev Burn a batch of catalysts in one tx.
    /// @param from The original address that signed the tx.
    /// @param catalystsQuantities An array of quantities for each type of catalyst to burn.
    function _batchBurnCatalysts(address from, uint256[] memory catalystsQuantities) internal {
        uint16[] memory ids = new uint16[](catalystsQuantities.length);
        for (uint16 i = 0; i < ids.length; i++) {
            ids[i] = i + 1;
        }
        _gemsCatalystsRegistry.batchBurnCatalysts(from, ids, _scaleCatalystQuantities(catalystsQuantities));
    }

    /// @dev Burn a batch of gems in one tx.
    /// @param from The original address that signed the tx.
    /// @param gemsQuantities An array of quantities for each type of gems to burn.
    function _batchBurnGems(address from, uint256[] memory gemsQuantities) internal {
        uint16[] memory ids = new uint16[](gemsQuantities.length);
        for (uint16 i = 0; i < ids.length; i++) {
            ids[i] = i + 1;
        }
        _gemsCatalystsRegistry.batchBurnGems(from, ids, _scaleGemQuantities(gemsQuantities));
    }

    /// @dev Burn an array of gems.
    /// @param from The original signer of the tx.
    /// @param gemIds The array of gems to burn.
    /// @param numTimes Amount of gems to burn.
    function _burnGems(
        address from,
        uint16[] memory gemIds,
        uint32 numTimes
    ) internal {
        _gemsCatalystsRegistry.burnDifferentGems(from, gemIds, numTimes * gemsFactor);
    }

    /// @dev Burn a single type of catalyst.
    /// @param from The original signer of the tx.
    /// @param catalystId The type of catalyst to burn.
    /// @param numTimes Amount of catalysts of this type to burn.
    function _burnCatalyst(
        address from,
        uint16 catalystId,
        uint32 numTimes
    ) internal {
        _gemsCatalystsRegistry.burnCatalyst(from, catalystId, numTimes * catalystsFactor);
    }

    /// @dev Scale up each number in an array of quantities by a factor of gemsUnits.
    /// @param quantities The array of numbers to scale.
    /// @return scaledQuantities The scaled-up values.
    function _scaleGemQuantities(uint256[] memory quantities)
        internal
        view
        returns (uint256[] memory scaledQuantities)
    {
        scaledQuantities = new uint256[](quantities.length);
        for (uint256 i = 0; i < quantities.length; i++) {
            scaledQuantities[i] = quantities[i] * gemsFactor * numberOfGemsBurnPerAsset;
        }
    }

    /// @dev Scale up each number in an array of quantities by a factor of gemsUnits.
    /// @param quantities The array of numbers to scale.
    /// @return scaledQuantities The scaled-up values.
    function _scaleCatalystQuantities(uint256[] memory quantities)
        internal
        view
        returns (uint256[] memory scaledQuantities)
    {
        scaledQuantities = new uint256[](quantities.length);
        for (uint256 i = 0; i < quantities.length; i++) {
            scaledQuantities[i] = quantities[i] * catalystsFactor * numberOfCatalystBurnPerAsset;
        }
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }

    function _mintRequirements(
        address from,
        uint256 quantity,
        address to
    ) internal view {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == from, "AUTH_ACCESS_DENIED");
        require(quantity != 0, "AssetMinter: quantity cannot be 0");
    }

    function _burnAndMint(
        address from,
        uint40 packId,
        bytes32 metadataHash,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint256 quantity,
        address to,
        bytes calldata data
    ) internal returns (uint256 assetId) {
        _mintRequirements(from, quantity, to);

        _burnCatalyst(from, catalystId, numberOfCatalystBurnPerAsset);
        _burnGems(from, gemIds, numberOfGemsBurnPerAsset);

        assetId = _asset.mint(from, packId, metadataHash, quantity, 0, to, data);
        _registry.setCatalyst(assetId, catalystId, gemIds);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IAssetMinter {
    struct AssetData {
        uint16[] gemIds;
        uint16 catalystId;
    }

    // use only to fix stack too deep
    struct MintData {
        address from;
        address to;
        uint40 packId;
        bytes32 metadataHash;
        bytes data;
    }

    function mintWithoutCatalyst(MintData calldata mintData, uint16 typeAsset1Based) external returns (uint256 assetId);

    function mintWithCatalyst(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external returns (uint256 assetId);

    function mintMultipleWithCatalyst(MintData calldata mintData, AssetData[] memory assets)
        external
        returns (uint256[] memory assetIds);

    function mintCustomNumberWithCatalyst(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint256 quantity
    ) external returns (uint256 assetId);

    function addOrReplaceQuantitiyByCatalystId(uint16 catalystId, uint256 newQuantity) external;

    function addOrReplaceAssetTypeQuantity(uint16 index1Based, uint256 newQuantity) external;

    function setNumberOfGemsBurnPerAsset(uint32 newQuantity) external;

    function setNumberOfCatalystsBurnPerAsset(uint32 newQuantity) external;

    function setGemsFactor(uint256 newQuantity) external;

    function setCatalystsFactor(uint256 newQuantity) external;

    function setCustomMintingAllowance(address addressToModify, bool isAddressAllowed) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "./interfaces/IPolygonSand.sol";

contract PolygonSandClaim is Ownable, ReentrancyGuard {
    IPolygonSand internal immutable _polygonSand;
    IERC20 internal immutable _fakePolygonSand;

    event SandClaimed(address indexed user, uint256 amount);

    constructor(IPolygonSand polygonSand, IERC20 fakePolygonSand) {
        _polygonSand = polygonSand;
        _fakePolygonSand = fakePolygonSand;
    }

    /**
     * @notice Swaps fake sand with the new polygonSand
     * @param amount the amount of tokens to be swapped
     */
    function claim(uint256 amount) external nonReentrant {
        require(unclaimedSand() >= amount, "Not enough sand for claim");
        bool success = _fakePolygonSand.transferFrom(msg.sender, address(this), amount);
        if (success) {
            _polygonSand.transfer(msg.sender, amount);
            emit SandClaimed(msg.sender, amount);
        }
    }

    // Getters

    /**
     * @notice Getter for amount of sand which is still locked in this contract
     */
    function unclaimedSand() public returns (uint256) {
        return _polygonSand.balanceOf(address(this));
    }

    /**
     * @notice Getter for amount of fake Sand swapped
     */
    function claimedSand() external view returns (uint256) {
        return _fakePolygonSand.balanceOf(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IPolygonSand {
    /// @notice update the ChildChainManager Proxy address
    /// @param newChildChainManagerProxy address of the new childChainManagerProxy
    function updateChildChainManager(address newChildChainManagerProxy) external;

    /// @notice called when tokens are deposited on root chain
    /// @param user user address for whom deposit is being done
    /// @param depositData abi encoded amount
    function deposit(address user, bytes calldata depositData) external;

    /// @notice called when user wants to withdraw tokens back to root chain
    /// @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
    /// @param amount amount to withdraw
    function withdraw(uint256 amount) external;

    /// @notice Get the balance of `owner`.
    /// @param owner The address to query the balance of.
    /// @return The amount owned by `owner`.
    function balanceOf(address owner) external returns (uint256);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param amount number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 amount) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param amount number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    function setTrustedForwarder(address trustedForwarder) external;
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/Strings.sol";

contract Faucet is Ownable {
    IERC20 internal immutable _ierc20;
    uint256 internal _period;
    uint256 internal _amountLimit;

    mapping(address => uint256) public _lastTimestamps;

    constructor(
        IERC20 ierc20,
        uint256 period,
        uint256 amountLimit
    ) {
        _ierc20 = ierc20;
        _period = period;
        _amountLimit = amountLimit;
    }

    event FaucetPeriod(uint256 period);
    event FaucetLimit(uint256 amountLimit);
    event FaucetSent(address _receiver, uint256 _amountSent);
    event FaucetRetrieved(address receiver, uint256 _amountSent);

    /// @notice set the minimum time delta between 2 calls to send() for an address.
    /// @param period time delta between 2 calls to send() for an address.
    function setPeriod(uint256 period) public onlyOwner {
        _period = period;
        emit FaucetPeriod(period);
    }

    /// @notice returns the minimum time delta between 2 calls to Send for an address.
    function getPeriod() public view returns (uint256) {
        return _period;
    }

    /// @notice return the maximum IERC20 token amount for an address.
    function setLimit(uint256 amountLimit) public onlyOwner {
        _amountLimit = amountLimit;
        emit FaucetLimit(amountLimit);
    }

    /// @notice return the maximum IERC20 token amount for an address.
    function getLimit() public view returns (uint256) {
        return _amountLimit;
    }

    /// @notice return the current IERC20 token balance for the contract.
    function balance() public view returns (uint256) {
        return _ierc20.balanceOf(address(this));
    }

    /// @notice retrieve all IERC20 token from contract to an address.
    /// @param receiver The address that will receive all IERC20 tokens.
    function retrieve(address receiver) public onlyOwner {
        uint256 accountBalance = balance();
        _ierc20.transferFrom(address(this), receiver, accountBalance);

        emit FaucetRetrieved(receiver, accountBalance);
    }

    /// @notice send amount of IERC20 to a receiver.
    /// @param amount The value of the IERC20 token that the receiver will received.
    function send(uint256 amount) public {
        require(
            amount <= _amountLimit,
            string(abi.encodePacked("Demand must not exceed ", Strings.toString(_amountLimit)))
        );

        uint256 accountBalance = balance();

        require(
            accountBalance > 0,
            string(abi.encodePacked("Insufficient balance on Faucet account: ", Strings.toString(accountBalance)))
        );
        require(
            _lastTimestamps[msg.sender] + _period < block.timestamp,
            string(abi.encodePacked("After each call you must wait ", Strings.toString(_period), " seconds."))
        );
        _lastTimestamps[msg.sender] = block.timestamp;

        if (accountBalance < amount) {
            amount = accountBalance;
        }
        _ierc20.transferFrom(address(this), msg.sender, amount);

        emit FaucetSent(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC2771Handler} from "../../common/BaseWithStorage/ERC2771Handler.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @title This contract pays Sand claims when the backend authorize it via message signing.
/// @dev can be extended to support NFTs, etc.
/// @dev This contract support meta transactions.
/// @dev This contract is final, don't inherit form it.
contract SignedERC20Giveaway is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    EIP712Upgradeable,
    ERC2771Handler,
    PausableUpgradeable
{
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address signer,uint256 claimId,address token,address to,uint256 amount)");
    string public constant name = "Sandbox SignedERC20Giveaway";
    string public constant version = "1.0";
    mapping(uint256 => bool) public claimed;

    function initialize(address trustedForwarder_, address defaultAdmin_) external initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __EIP712_init_unchained(name, version);
        __ERC2771Handler_initialize(trustedForwarder_);
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
    }

    /// @notice verifies a ERC712 signature for the Mint data type.
    /// @param v signature part
    /// @param r signature part
    /// @param s signature part
    /// @param signer the address of the signer, must be part of the signer role
    /// @param claimId unique claim id
    /// @param token token contract address
    /// @param to destination user
    /// @param amount of ERC20 to transfer
    /// @return true if the signature is valid
    function verify(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address signer,
        uint256 claimId,
        address token,
        address to,
        uint256 amount
    ) external view returns (bool) {
        return _verify(v, r, s, signer, claimId, token, to, amount);
    }

    /// @notice verifies a ERC712 signature and mint a new NFT for the buyer.
    /// @param v signature part
    /// @param r signature part
    /// @param s signature part
    /// @param signer the address of the signer, must be part of the signer role
    /// @param claimId unique claim id
    /// @param token token contract address
    /// @param to destination user
    /// @param amount of ERC20 to transfer
    function claim(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address signer,
        uint256 claimId,
        address token,
        address to,
        uint256 amount
    ) external whenNotPaused {
        require(_verify(v, r, s, signer, claimId, token, to, amount), "Invalid signature");
        require(hasRole(SIGNER_ROLE, signer), "Invalid signer");
        require(!claimed[claimId], "Already claimed");
        claimed[claimId] = true;
        require(IERC20Upgradeable(token).transfer(to, amount), "Transfer failed");
    }

    /// @notice let the admin revoke some claims so they cannot be used
    /// @param claimIds and array of claim Ids to revoke
    function revokeClaims(uint256[] calldata claimIds) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin");
        for (uint256 i = 0; i < claimIds.length; i++) {
            claimed[claimIds[i]] = true;
        }
    }

    // @dev Triggers stopped state.
    // The contract must not be paused.
    function pause() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin");
        _pause();
    }

    // @dev Returns to normal state.
    // The contract must be paused.
    function unpause() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin");
        _unpause();
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function _msgSender() internal view override(ContextUpgradeable, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }

    function _verify(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address signer,
        uint256 claimId,
        address token,
        address to,
        uint256 amount
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(CLAIM_TYPEHASH, signer, claimId, token, to, amount)));
        address recoveredSigner = ECDSAUpgradeable.recover(digest, v, r, s);
        return recoveredSigner == signer;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/interfaces/IPolygonLand.sol";

// solhint-disable

/// @dev This is NOT a secure FxRoot contract implementation!
/// DO NOT USE in production.

interface IFakeFxChild {
    function onStateReceive(
        uint256 stateId,
        address receiver,
        address rootMessageSender,
        bytes memory data
    ) external;
}

/**
 * @title FxRoot root contract for fx-portal
 */
contract FakeFxRoot {
    address fxChild;

    function setFxChild(address _fxChild) public {
        fxChild = _fxChild;
    }

    function sendMessageToChild(address _receiver, bytes calldata _data) public {
        IFakeFxChild(fxChild).onStateReceive(0, _receiver, msg.sender, _data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./PolygonLandBaseToken.sol";

// @todo - natspec comments

contract PolygonLand is PolygonLandBaseToken {
    address public polygonLandTunnel;

    bool internal _initialized;

    modifier initializer() {
        require(!_initialized, "ERC721BaseToken: Contract already initialized");
        _;
    }

    function initialize() external initializer {
        _admin = _msgSender();
        _initialized = true;
    }

    function setPolygonLandTunnel(address _polygonLandTunnel) external onlyAdmin {
        polygonLandTunnel = _polygonLandTunnel;
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyAdmin {
        _trustedForwarder = trustedForwarder;
    }

    function mint(
        address user,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) external {
        require(_msgSender() == polygonLandTunnel, "Invalid sender");
        _mintQuad(user, size, x, y, data);
    }

    // Empty storage space in contracts for future enhancements
    // ref: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/issues/13)
    uint256[49] private __gapu;
}

// SPDX-License-Identifier: MIT

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
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC1155} from "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import {ERC1155Receiver} from "@openzeppelin/contracts-0.8/token/ERC1155/utils/ERC1155Receiver.sol";

interface IMintableERC1155 is IERC1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/// @dev This is NOT a secure ChildChainManager contract implementation!
/// DO NOT USE in production.

contract FakeERC1155Predicate is ERC1155Receiver {
    address private asset;

    function setAsset(address _asset) external {
        asset = _asset;
    }

    function lockTokens(
        address depositor,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        IMintableERC1155(asset).safeBatchTransferFrom(depositor, address(this), ids, amounts, data);
    }

    function exitTokens(
        address withdrawer,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        IMintableERC1155 token = IMintableERC1155(asset);
        uint256[] memory balances = token.balanceOfBatch(makeArrayWithAddress(address(this), ids.length), ids);
        (uint256[] memory toBeMinted, bool needMintStep, bool needTransferStep) =
            calculateAmountsToBeMinted(balances, amounts);
        if (needMintStep) {
            token.mintBatch(
                withdrawer,
                ids,
                toBeMinted,
                data // passing data when minting to withdrawer
            );
        }
        if (needTransferStep) {
            token.safeBatchTransferFrom(
                address(this),
                withdrawer,
                ids,
                balances,
                data // passing data when transferring unlocked tokens to withdrawer
            );
        }
    }

    function calculateAmountsToBeMinted(uint256[] memory balances, uint256[] memory exitAmounts)
        internal
        pure
        returns (
            uint256[] memory,
            bool,
            bool
        )
    {
        uint256 count = balances.length;
        require(count == exitAmounts.length, "ChainExitERC1155Predicate: Array length mismatch found");
        uint256[] memory toBeMinted = new uint256[](count);
        bool needMintStep;
        bool needTransferStep;
        for (uint256 i = 0; i < count; i++) {
            if (balances[i] < exitAmounts[i]) {
                toBeMinted[i] = exitAmounts[i] - balances[i];
                needMintStep = true;
            }
            if (balances[i] != 0) {
                needTransferStep = true;
            }
        }
        return (toBeMinted, needMintStep, needTransferStep);
    }

    function makeArrayWithAddress(address addr, uint256 size) internal pure returns (address[] memory) {
        require(addr != address(0), "MintableERC1155Predicate: Invalid address");
        require(size > 0, "MintableERC1155Predicate: Invalid resulting array length");
        address[] memory addresses = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            addresses[i] = addr;
        }
        return addresses;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return ERC1155Receiver(address(0)).onERC1155BatchReceived.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";

contract ClaimERC1155 {
    bytes32 internal _merkleRoot;
    IERC1155 internal immutable _asset;
    address internal immutable _assetsHolder;
    event ClaimedAssets(address to, uint256[] assetIds, uint256[] assetValues);

    constructor(IERC1155 asset, address assetsHolder) {
        _asset = asset;
        if (assetsHolder == address(0)) {
            assetsHolder = address(this);
        }
        _assetsHolder = assetsHolder;
    }

    /// @dev See for example AssetGiveaway.sol claimAssets.
    function _claimERC1155(
        address to,
        uint256[] calldata assetIds,
        uint256[] calldata assetValues,
        bytes32[] calldata proof,
        bytes32 salt
    ) internal {
        _checkValidity(to, assetIds, assetValues, proof, salt);
        _sendAssets(to, assetIds, assetValues);
        emit ClaimedAssets(to, assetIds, assetValues);
    }

    function _checkValidity(
        address to,
        uint256[] memory assetIds,
        uint256[] memory assetValues,
        bytes32[] memory proof,
        bytes32 salt
    ) internal view {
        require(assetIds.length == assetValues.length, "INVALID_INPUT");
        bytes32 leaf = _generateClaimHash(to, assetIds, assetValues, salt);
        require(_verify(proof, leaf), "INVALID_CLAIM");
    }

    function _generateClaimHash(
        address to,
        uint256[] memory assetIds,
        uint256[] memory assetValues,
        bytes32 salt
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, assetIds, assetValues, salt));
    }

    function _verify(bytes32[] memory proof, bytes32 computedHash) internal view returns (bool) {
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == _merkleRoot;
    }

    function _sendAssets(
        address to,
        uint256[] memory assetIds,
        uint256[] memory assetValues
    ) internal {
        _asset.safeBatchTransferFrom(_assetsHolder, to, assetIds, assetValues, "");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import "./ClaimERC1155.sol";
import "../../common/BaseWithStorage/WithAdmin.sol";

/// @title AssetGiveaway contract.
/// @notice This contract manages ERC1155 claims.
contract AssetGiveaway is WithAdmin, ClaimERC1155 {
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;
    uint256 internal immutable _expiryTime;
    mapping(address => bool) public claimed;

    constructor(
        address asset,
        address admin,
        bytes32 merkleRoot,
        address assetsHolder,
        uint256 expiryTime
    ) ClaimERC1155(IERC1155(asset), assetsHolder) {
        _admin = admin;
        _merkleRoot = merkleRoot;
        _expiryTime = expiryTime;
    }

    /// @notice Function to set the merkle root hash for the asset data, if it is 0.
    /// @param merkleRoot The merkle root hash of the asset data.
    function setMerkleRoot(bytes32 merkleRoot) external onlyAdmin {
        require(_merkleRoot == 0, "MERKLE_ROOT_ALREADY_SET");
        _merkleRoot = merkleRoot;
    }

    /// @notice Function to permit the claiming of an asset to a reserved address.
    /// @param to The intended recipient (reserved address) of the ERC1155 tokens.
    /// @param assetIds The array of IDs of the asset tokens.
    /// @param assetValues The amounts of each token ID to transfer.
    /// @param proof The proof submitted for verification.
    /// @param salt The salt submitted for verification.
    function claimAssets(
        address to,
        uint256[] calldata assetIds,
        uint256[] calldata assetValues,
        bytes32[] calldata proof,
        bytes32 salt
    ) external {
        require(block.timestamp < _expiryTime, "CLAIM_PERIOD_IS_OVER");
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(claimed[to] == false, "DESTINATION_ALREADY_CLAIMED");
        claimed[to] = true;
        _claimERC1155(to, assetIds, assetValues, proof, salt);
    }

    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return ERC1155_BATCH_RECEIVED;
    }
}