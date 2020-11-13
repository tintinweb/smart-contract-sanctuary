pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./CatalystValue.sol";


contract CatalystDataBase is CatalystValue {
    event CatalystConfiguration(uint256 indexed id, uint16 minQuantity, uint16 maxQuantity, uint256 sandMintingFee, uint256 sandUpdateFee);

    function _setMintData(uint256 id, MintData memory data) internal {
        _data[id] = data;
        _emitConfiguration(id, data.minQuantity, data.maxQuantity, data.sandMintingFee, data.sandUpdateFee);
    }

    function _setValueOverride(uint256 id, CatalystValue valueOverride) internal {
        _valueOverrides[id] = valueOverride;
    }

    function _setConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) internal {
        _data[id].minQuantity = minQuantity;
        _data[id].maxQuantity = maxQuantity;
        _data[id].sandMintingFee = uint88(sandMintingFee);
        _data[id].sandUpdateFee = uint88(sandUpdateFee);
        _emitConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    function _emitConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) internal {
        emit CatalystConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    ///@dev compute a random value between min to 25.
    //. example: 1-25, 6-25, 11-25, 16-25
    function _computeValue(
        uint256 seed,
        uint256 gemId,
        bytes32 blockHash,
        uint256 slotIndex,
        uint32 min
    ) internal pure returns (uint32) {
        return min + uint16(uint256(keccak256(abi.encodePacked(gemId, seed, blockHash, slotIndex))) % (26 - min));
    }

    function getValues(
        uint256 catalystId,
        uint256 seed,
        GemEvent[] calldata events,
        uint32 totalNumberOfGemTypes
    ) external override view returns (uint32[] memory values) {
        CatalystValue valueOverride = _valueOverrides[catalystId];
        if (address(valueOverride) != address(0)) {
            return valueOverride.getValues(catalystId, seed, events, totalNumberOfGemTypes);
        }
        values = new uint32[](totalNumberOfGemTypes);

        uint32 numGems;
        for (uint256 i = 0; i < events.length; i++) {
            numGems += uint32(events[i].gemIds.length);
        }
        require(numGems <= MAX_UINT32, "TOO_MANY_GEMS");
        uint32 minValue = (numGems - 1) * 5 + 1;

        uint256 numGemsSoFar = 0;
        for (uint256 i = 0; i < events.length; i++) {
            numGemsSoFar += events[i].gemIds.length;
            for (uint256 j = 0; j < events[i].gemIds.length; j++) {
                uint256 gemId = events[i].gemIds[j];
                uint256 slotIndex = numGemsSoFar - events[i].gemIds.length + j;
                if (values[gemId] == 0) {
                    // first gem : value = roll between ((numGemsSoFar-1)*5+1) and 25
                    values[gemId] = _computeValue(seed, gemId, events[i].blockHash, slotIndex, (uint32(numGemsSoFar) - 1) * 5 + 1);
                    // bump previous values:
                    if (values[gemId] < minValue) {
                        values[gemId] = minValue;
                    }
                } else {
                    // further gem, previous roll are overriden with 25 and new roll between 1 and 25
                    uint32 newRoll = _computeValue(seed, gemId, events[i].blockHash, slotIndex, 1);
                    values[gemId] = (((values[gemId] - 1) / 25) + 1) * 25 + newRoll;
                }
            }
        }
    }

    function getMintData(uint256 catalystId)
        external
        view
        returns (
            uint16 maxGems,
            uint16 minQuantity,
            uint16 maxQuantity,
            uint256 sandMintingFee,
            uint256 sandUpdateFee
        )
    {
        maxGems = _data[catalystId].maxGems;
        minQuantity = _data[catalystId].minQuantity;
        maxQuantity = _data[catalystId].maxQuantity;
        sandMintingFee = _data[catalystId].sandMintingFee;
        sandUpdateFee = _data[catalystId].sandUpdateFee;
    }

    struct MintData {
        uint88 sandMintingFee;
        uint88 sandUpdateFee;
        uint16 minQuantity;
        uint16 maxQuantity;
        uint16 maxGems;
    }

    uint32 internal constant MAX_UINT32 = 2**32 - 1;

    mapping(uint256 => MintData) internal _data;
    mapping(uint256 => CatalystValue) internal _valueOverrides;
}
