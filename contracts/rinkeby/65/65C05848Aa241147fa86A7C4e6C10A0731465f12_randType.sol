/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity 0.6.6;

contract randType {
    uint32[] typeWeight = [8580, 800, 300, 300, 10, 5, 5];
    bool[] availableType = [true, false, true, true, true, true, true];
    uint40[] probRange = new uint40[](7);
    uint256 maxUInt32 = 4294967296;

    uint32 public resindex;
    uint256 public rescard;
    uint32 public _seed;

    function rand() public returns (uint32) {
        _seed = _seed * 750090933 + 2835798513;
        // return (_seed >> 16) & 0x7fff;
        return _seed;
    }

    function setAvailableType(uint32 _index, bool _bool) external {
        availableType[_index] = _bool;
    }

    function getAvailableType() external view returns (bool[] memory) {
        return availableType;
    }

    function getProbRangee() external view returns (uint40[] memory) {
        return probRange;
    }

    function _randType() external {
        // Find the weights of the available card types
        uint32[] memory availableWeight = new uint32[](7);
        uint32 availableWeightIndex = 0; // Can also be used as length of availableWeight
        uint256 sumWeight = 0;
        for (uint32 i = 0; i < availableType.length; i++) {
            if (availableType[i]) {
                availableWeight[availableWeightIndex] = typeWeight[i];
                availableWeightIndex += 1;
                sumWeight += typeWeight[i];
            }
        }

        // Find int range of each card type
        // according to the weights and the sum of the weights
        uint40 probStep;
        // uint40[] memory probRange = new uint40[](availableWeightIndex);
        for (uint32 i = 0; i < availableWeightIndex - 1; i++) {
            probStep = uint40(
                ((maxUInt32 * uint256(availableWeight[i])) / uint256(sumWeight))
            );
            if (i == 0) {
                probRange[i] = probStep;
            } else {
                probRange[i] = probStep + probRange[i - 1];
            }
        }
        probRange[availableWeightIndex - 1] = uint40(maxUInt32);

        // Find the index of probRange where the randValue is in
        uint32 probRangeIndex = 0;
        uint32 typeIndex = 0;
        uint32 randValue = rand();
        for (uint32 i = 0; i < availableType.length; i++) {
            if (!availableType[i]) {
                typeIndex += 1;
                continue;
            } else {
                if (randValue < probRange[probRangeIndex]) {
                    break;
                }
                probRangeIndex += 1;
                typeIndex += 1;
            }
        }

        resindex = typeIndex;
    }

    function _randType(uint256 totalCard) external {
        uint256 randValue = uint256(rand());

        rescard = ((randValue * 10000) / ((maxUInt32 * 1 * 10000) / (totalCard))) + 1;
    }
}