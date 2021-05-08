/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity 0.6.6;

contract randType {
    uint32[] typeWeight = [8580, 800, 300, 300, 10, 5, 5];
    bool[] availableType = [true, true, true, true, true, true, true];
    uint32[][] setCard = [[16,5], [3,2], [1,4], [1,6], [1,1], [1,10], [1,1]];
    uint40[] probRange = new uint40[](7);
    uint256 maxUInt32 = 4294967296;

    uint32 public resindex;
    uint256 public rescard;
    uint256 public tmpseed1;
    uint256 public tmpseed2;
    uint256 public _seed;
    uint256 public cardTypee;

    function rand() public returns (uint256) {
        _seed = _seed * 750090933 + 2835798513;
        return _seed % 0x100000000;
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

        uint32 typeIndex = 0;  
        {
            // Find the weights of the available card types
            uint32[] memory availableTypeWeight = new uint32[](7);
            uint32 availableWeightIndex = 0; // Can also be used as length of availableTypeWeight
            uint256 sumWeight = 0;
            for (uint32 i = 0; i < availableType.length; i++) {
                if (availableType[i]) {
                    availableTypeWeight[availableWeightIndex] = typeWeight[i];
                    availableWeightIndex += 1;
                    sumWeight += typeWeight[i];
                }
            }

            // Find int range of each card type
            // according to the weights and the sum of the weights
            uint40 probStep;
            // uint40[] memory probRange = new uint40[](availableWeightIndex);
            for (uint32 i = 0; i < availableWeightIndex - 1; i++) {
                probStep = uint40(((maxUInt32 * uint256(availableTypeWeight[i])) / uint256(sumWeight)));
                if (i == 0) {
                    probRange[i] = probStep;
                } else {
                    probRange[i] = probStep + probRange[i - 1];
                }
            }
            probRange[availableWeightIndex - 1] = uint40(maxUInt32);

            // Find the index of probRange where the randValue is in
            uint32 probRangeIndex = 0;
            typeIndex = 0;
            uint256 randValue = rand();
            tmpseed1 = randValue;
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

        {   
            uint256 totalCard = setCard[typeIndex][0] * setCard[typeIndex][1];
            uint256 cardInType;
            uint256 numSetCard;
            uint256 numCard;
            uint256 cardType;
            bool[] memory availableCardWeight = new bool[](totalCard);

            for (cardInType = 0; cardInType < totalCard; cardInType++) {
                numSetCard = cardInType / setCard[typeIndex][1];
                numCard = cardInType - (setCard[typeIndex][1] *  numSetCard);
                cardType = (typeIndex * (2**8)) + (numSetCard * (2**4)) + numCard;

                // เช็คว่าการ์ด type supply หมดยัง
                if (true) {
                    availableCardWeight[cardInType] = true;
                }
                else {
                    availableCardWeight[cardInType] = false;
                    totalCard = totalCard - 1;
                }
                uint256 randValue = rand();
                tmpseed2 = randValue;
                rescard = ((randValue * 10000) / ((maxUInt32 * 1 * 10000) / (totalCard))) + 1;
                numSetCard = rescard / setCard[typeIndex][1];
                numCard = rescard - (setCard[typeIndex][1] *  numSetCard);
                cardType = (typeIndex * (2**8)) + (numSetCard * (2**4)) + numCard;
                cardTypee = cardType;
            }
        }
    }

    function _randType(uint256 totalCard) external {
        uint256 randValue = rand();
        tmpseed1 = randValue;
        randValue = rand();
        tmpseed2 = randValue;
    }
}