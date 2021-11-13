// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Genes {
    uint256 constant sumOfGeneBits = 244;

    function geneBits() private pure returns (uint8[42] memory bits) {
        bits = [
            4,
            4,
            8, // FactionColor, Faction, Clothing
            10,
            2,
            10,
            2,
            10,
            2, // Eyes
            10,
            2,
            10,
            2,
            10,
            2, // Hair
            10,
            2,
            4,
            10,
            2,
            4,
            10,
            2,
            4, // Hand
            10,
            2,
            10,
            2,
            10,
            2, // Ears
            10,
            2,
            10,
            2,
            10,
            2, // Tail
            10,
            2,
            10,
            2,
            10,
            2 // Mouth
        ]; // 42;
    }

    function genePosList() private pure returns (uint8[42] memory list) {
        list = [
            240,
            236,
            228,
            218,
            216,
            206,
            204,
            194,
            192,
            182,
            180,
            170,
            168,
            158,
            156,
            146,
            144,
            140,
            130,
            128,
            124,
            114,
            112,
            108,
            98,
            96,
            86,
            84,
            74,
            72,
            62,
            60,
            50,
            48,
            38,
            36,
            26,
            24,
            14,
            12,
            2,
            0
        ];
    }

    function random(uint256 _modulus) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, msg.sender))) % _modulus;
    }

    function packGenes(uint256[42] memory _petProperty) private pure returns (uint256 genes) {
        uint8[42] memory _geneBits = geneBits();
        for (uint256 i = 0; i < _petProperty.length; i++) {
            uint256 item = _petProperty[i];
            uint256 size = _geneBits[i];
            genes = (genes << size) | item;
        }
    }

    function unPackGenes(uint256 _genes) private pure returns (uint256[42] memory petProperty) {
        uint8[42] memory _genePosList = genePosList();
        uint8[42] memory _geneBits = geneBits();
        for (uint256 i = 0; i < _genePosList.length; i++) {
            uint256 bits = _geneBits[i];
            uint256 shiftLeft = 256 - bits - _genePosList[i];
            uint256 shiftRight = 256 - bits;
            uint256 n = (_genes << shiftLeft) >> shiftRight;
            petProperty[i] = n;
        }
    }

    function mix(uint256 _genId1, uint256 _genId2) public view returns (uint256 childGenId) {
        uint256[42] memory pet1 = unPackGenes(_genId1);
        uint256[42] memory pet2 = unPackGenes(_genId2);
        uint256[42] memory child = [uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

        if (random(100) < 50) {
            //50/50
            child[1] = pet1[1];
        } else {
            child[1] = pet2[1];
        }

        uint256 r = random(100);
        if (r < 24) {
            //0-23
            child[0] = 1;
        } else if (r < 48) {
            // 24 -47
            child[0] = 2;
        } else if (r < 72) {
            // 48- 71
            child[0] = 3;
        } else if (r < 96) {
            //72-95
            child[0] = 4;
        } else if (r < 98) {
            //86, 97
            child[0] = 5;
        } else if (r < 100) {
            // 98-99
            child[0] = 6;
        }

        child[2] = random(5) + 1; //1-> 5
        child = mixGenes(pet1, pet2, child);
        return packGenes(child);
    }

    function pickNFromList(
        uint256 _number,
        uint256[6] memory _list,
        uint256[6] memory _ratio
    ) internal view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](_number);
        uint256 indexRes = 0;
        uint256 count = _list.length;

        uint256 sumRatio = 0;
        uint256[] memory thresholds = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            sumRatio += _ratio[j];
            thresholds[j] = sumRatio;
        }

        for (uint256 i = 0; i < _number; i++) {
            uint256 r = random(sumRatio);
            for (uint256 j = 0; j < count; j++) {
                if (_list[j] != 0) {
                    uint256 threshold = thresholds[j];
                    if (r < threshold) {
                        res[indexRes] = _list[j];
                        _list[j] = 0;
                        indexRes++;
                        break;
                    }
                }
            }
        }
        return res;
    }

    function inArray(uint256[] memory arr, uint256 n) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == n) {
                return true;
            }
        }
        return false;
    }

    function notInt(uint256[6] memory _list, uint256[] memory _exclude) internal pure returns (uint256[6] memory) {
        uint256[6] memory res = [uint256(0), 0, 0, 0, 0, 0];
        uint256 indexRes = 0;
        for (uint256 i = 0; i < _list.length; i++) {
            bool isIn = false;
            for (uint256 j = 0; j < _exclude.length; j++) {
                if (_list[i] == _exclude[j]) {
                    isIn = true;
                    break;
                }
            }

            if (!isIn) {
                res[indexRes] = _list[i];
                indexRes++;
            }
        }
        return res;
    }

    function getBeast(uint256[42] memory _pet1, uint256[42] memory _pet2) public pure returns (uint256[] memory) {
        uint256[] memory beastGenens = new uint256[](12);
        //pet 1
        if (_pet1[4] == 1) {
            beastGenens[0] = _pet1[3];
        }
        if (_pet1[10] == 1) {
            beastGenens[1] = _pet1[9];
        }
        if (_pet1[16] == 1) {
            beastGenens[2] = _pet1[15];
        }
        if (_pet1[25] == 1) {
            beastGenens[3] = _pet1[24];
        }
        if (_pet1[31] == 1) {
            beastGenens[4] = _pet1[30];
        }
        if (_pet1[37] == 1) {
            beastGenens[5] = _pet1[36];
        }

        //pet 2

        if (_pet2[4] == 1) {
            beastGenens[6] = _pet2[3];
        }
        if (_pet2[10] == 1) {
            beastGenens[7] = _pet2[9];
        }
        if (_pet2[16] == 1) {
            beastGenens[8] = _pet2[15];
        }
        if (_pet2[25] == 1) {
            beastGenens[9] = _pet2[24];
        }
        if (_pet2[31] == 1) {
            beastGenens[10] = _pet2[30];
        }
        if (_pet2[37] == 1) {
            beastGenens[11] = _pet2[36];
        }

        return beastGenens;
    }

    function mixGenes(
        uint256[42] memory _pet1,
        uint256[42] memory _pet2,
        uint256[42] memory child
    ) private view returns (uint256[42] memory) {
        uint256[] memory beastGenens = getBeast(_pet1, _pet2);

        for (uint256 i = 0; i < 6; i++) {
            if (i == 0) {
                //eyes
                uint256[6] memory genes = [_pet1[3], _pet1[5], _pet1[7], _pet2[3], _pet2[5], _pet2[7]];
                uint256[] memory res = remix(genes, beastGenens);
                child[3] = res[0];
                child[5] = res[1];
                child[7] = res[2];
                //
                if (inArray(beastGenens, child[3])) {
                    child[4] = 1;
                }

                if (inArray(beastGenens, child[5])) {
                    child[6] = 1;
                }

                if (inArray(beastGenens, child[7])) {
                    child[8] = 1;
                }
            } else if (i == 1) {
                //mouth
                uint256[6] memory genes = [_pet1[36], _pet1[38], _pet1[40], _pet2[36], _pet2[38], _pet2[40]];
                uint256[] memory res = remix(genes, beastGenens);
                child[36] = res[0];
                child[38] = res[1];
                child[40] = res[2];
                //
                if (inArray(beastGenens, child[36])) {
                    child[37] = 1;
                }

                if (inArray(beastGenens, child[38])) {
                    child[39] = 1;
                }

                if (inArray(beastGenens, child[40])) {
                    child[41] = 1;
                }
            } else if (i == 2) {
                //hair
                uint256[6] memory genes = [_pet1[9], _pet1[11], _pet1[13], _pet2[9], _pet2[11], _pet2[13]];
                uint256[] memory res = remix(genes, beastGenens);
                child[9] = res[0];
                child[11] = res[1];
                child[13] = res[2];

                if (inArray(beastGenens, child[9])) {
                    child[10] = 1;
                }

                if (inArray(beastGenens, child[11])) {
                    child[12] = 1;
                }

                if (inArray(beastGenens, child[13])) {
                    child[14] = 1;
                }
            } else if (i == 3) {
                //hand
                uint256[6] memory genes = [_pet1[15], _pet1[18], _pet1[21], _pet2[15], _pet2[18], _pet2[21]];
                uint256[] memory res = remix(genes, beastGenens);
                child[15] = res[0];
                child[18] = res[1];
                child[21] = res[2];

                if (inArray(beastGenens, child[15])) {
                    child[16] = 1;
                }

                if (inArray(beastGenens, child[18])) {
                    child[19] = 1;
                }

                if (inArray(beastGenens, child[21])) {
                    child[22] = 1;
                }
                //
                if (child[15] == _pet1[15]) {
                    child[17] = _pet1[17];
                } else {
                    child[17] = _pet2[17];
                }
                //
                if (child[18] == _pet1[18]) {
                    child[20] = _pet1[20];
                } else {
                    child[20] = _pet2[20];
                }
                //
                if (child[21] == _pet1[21]) {
                    child[23] = _pet1[23];
                } else {
                    child[23] = _pet2[23];
                }
            } else if (i == 4) {
                //ears
                uint256[6] memory genes = [_pet1[24], _pet1[26], _pet1[28], _pet2[24], _pet2[26], _pet2[28]];
                uint256[] memory res = remix(genes, beastGenens);
                child[24] = res[0];
                child[26] = res[1];
                child[28] = res[2];

                if (inArray(beastGenens, child[24])) {
                    child[25] = 1;
                }

                if (inArray(beastGenens, child[26])) {
                    child[27] = 1;
                }

                if (inArray(beastGenens, child[28])) {
                    child[29] = 1;
                }
            } else if (i == 5) {
                // tail
                uint256[6] memory genes = [_pet1[30], _pet1[32], _pet1[34], _pet2[30], _pet2[32], _pet2[34]];
                uint256[] memory res = remix(genes, beastGenens);
                child[30] = res[0];
                child[32] = res[1];
                child[34] = res[2];

                if (inArray(beastGenens, child[30])) {
                    child[31] = 1;
                }

                if (inArray(beastGenens, child[32])) {
                    child[33] = 1;
                }

                if (inArray(beastGenens, child[34])) {
                    child[35] = 1;
                }
            }
        }

        return child;
    }

    function remix(uint256[6] memory _genes, uint256[] memory _beastGenes) private view returns (uint256[] memory) {
        uint256[6] memory geneRatios = [uint256(36), 10, 4, 36, 10, 4];
        uint256[] memory chosen = pickNFromList(3, _genes, geneRatios);
        if (inArray(_beastGenes, chosen[0]) && random(100) < 98) {
            uint256[6] memory excludes = notInt(_genes, chosen);
            excludes = notInt(excludes, _beastGenes);
            uint256 n = excludes.length;
            if (n > 0) {
                uint256 r = random(n);
                chosen[0] = excludes[r];
            }
        }

        return chosen;
    }
}