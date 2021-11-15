//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../catalyst/interfaces/IAssetAttributesRegistry.sol";

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

