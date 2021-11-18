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

interface IOldCatalystRegistry {
    function getCatalyst(uint256 assetId) external view returns (bool exists, uint256 catalystId);
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