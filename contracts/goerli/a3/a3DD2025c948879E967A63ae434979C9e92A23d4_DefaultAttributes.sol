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
pragma experimental ABIEncoderV2;

interface IAssetAttributesRegistry {
    struct GemEvent {
        uint16[] gemIds;
        bytes32 blockHash;
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

    function setCatalystWithBlockNumber(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint64 blockNumber
    ) external;

    function addGems(uint256 assetId, uint16[] calldata gemIds) external;

    function setMigrationContract(address _migrationContract) external;
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