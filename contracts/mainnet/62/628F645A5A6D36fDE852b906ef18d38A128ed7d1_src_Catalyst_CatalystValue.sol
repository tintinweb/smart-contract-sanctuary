pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface CatalystValue {
    struct GemEvent {
        uint256[] gemIds;
        bytes32 blockHash;
    }

    function getValues(
        uint256 catalystId,
        uint256 seed,
        GemEvent[] calldata events,
        uint32 totalNumberOfGemTypes
    ) external view returns (uint32[] memory values);
}
