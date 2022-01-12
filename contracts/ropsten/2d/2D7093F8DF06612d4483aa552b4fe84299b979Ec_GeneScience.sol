// SPDX-License-Identifier: MIT
// CryptoHero Contracts v1.0.0 (GeneScience.sol)

pragma solidity ^0.8.0;

import "./IGeneScience.sol";

contract GeneScience is IGeneScience {
    uint256 internal constant MASK_LAST_8_BITS = uint256(0xff);
    uint256 internal constant MASK_FIRST_248_BITS = uint256(~uint256(0xff));

    function isGeneScience() external pure override returns (bool) {
        return true;
    }

    /// @dev random generate hero gender
    function generateGender(uint256 _targetBlock) external view override returns (uint8) {
        uint256 randomN = uint256(keccak256(abi.encodePacked(blockhash(_targetBlock))));
        return uint8(randomN % 2);
    }

    /// @dev given a number get a slice of any bits, at certain offset
    /// @param _n a number to be sliced
    /// @param _nbits how many bits long is the new number
    /// @param _offset how many bits to skip
    function _sliceNumber(
        uint256 _n,
        uint256 _nbits,
        uint256 _offset
    ) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }

    /// @dev Parse a hero appearance genes and returns all of 12 "trait stack" that makes the appearance
    /// @param _genes hero appearance gene
    /// @return the 48 traits that composes the appearance genetic code, logically divided in stacks of 4,
    //  where only the first trait of each stack may express
    function decodeAppearanceGenes(uint256 _genes) public pure returns (uint8[] memory) {
        uint8[] memory traits = new uint8[](48);
        uint256 i;
        for (i = 0; i < 48; i++) {
            traits[i] = uint8(_sliceNumber(_genes, uint256(5), i * 5));
        }
        return traits;
    }

    /// @dev Given an array of traits return the number that appearance genes
    function encodeAppearanceGenes(uint8[] memory _traits) public pure returns (uint256 _genes) {
        _genes = 0;
        for (uint256 i = 0; i < 48; i++) {
            _genes = _genes << 5;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[47 - i];
        }
        return _genes;
    }

    /// @dev Random generate the mutation trait
    /// @param _trait1 any trait of that appearance
    /// @param _trait2 any trait of that appearance
    /// @param _gender baby hero gender
    /// @param _rand is expected to be a 3 bits number (0~7)
    /// @return mutationTrait a number from 16 to 31 for the mutation trait
    function _mutation(
        uint8 _trait1,
        uint8 _trait2,
        uint8 _gender,
        uint256 _rand
    ) internal pure returns (uint8 mutationTrait) {
        mutationTrait = 0;

        uint8 smallT = _trait1;
        uint8 bigT = _trait2;

        if (smallT > bigT) {
            bigT = _trait1;
            smallT = _trait2;
        }

        if ((bigT - smallT == 1) && smallT % 2 == 0) {
            uint256 maxRand;
            if (smallT > 15) {
                maxRand = 0;
            } else {
                maxRand = 1;
            }
            // The rand argument is expected to be a random number 0-7.
            // 1st and 2nd tier: 1/4 chance (rand is 0 or 1)
            // 3rd and 4th tier: 1/8 chance (rand is 0)
            if (_rand <= maxRand) {
                if (_gender == 0) {
                    mutationTrait = (smallT % 8) + 16;
                } else {
                    mutationTrait = (smallT % 8) + 24;
                }
            }
        }
    }

    /// @dev given appearance genes of hero mother & hero father, return a genetic combination
    /// @return the genes that are supposed to be passed down the baby hero
    function mixAppearanceGenes(
        uint8 _babyGender,
        uint256 _motherGenes,
        uint256 _fatherGenes,
        uint256 _targetBlock
    ) external view override returns (uint256) {
        require(block.number > _targetBlock, "target block number is invalid");

        // Try to grab the hash of the "target block". This should be available the vast
        // majority of the time (it will only fail if no-one calls giveBirth() within 256
        // blocks of the target block, which is about 40 minutes. Since anyone can call
        // giveBirth() and they are rewarded with ether if it succeeds, this is quite unlikely.)
        uint256 randomN = uint256(keccak256(abi.encodePacked(blockhash(_targetBlock))));

        if (randomN == 0) {
            // We don't want to completely bail if the target block is no-longer available,
            // nor do we want to just use the current block's hash (since it could allow a
            // caller to game the random result). Compute the most recent block that has the
            // the same value modulo 256 as the target block. The hash for this block will
            // still be available, and – while it can still change as time passes – it will
            // only change every 40 minutes. Again, someone is very likely to jump in with
            // the giveBirth() call before it can cycle too many times.
            _targetBlock = (block.number & MASK_FIRST_248_BITS) + (_targetBlock & MASK_LAST_8_BITS);

            // The computation above could result in a block LARGER than the current block,
            // if so, subtract 256.
            if (_targetBlock >= block.number) {
                _targetBlock -= 256;
            }

            randomN = uint256(keccak256(abi.encodePacked(blockhash(_targetBlock))));

            // DEBUG ONLY
            // assert(block.number != _targetBlock);
            // assert((block.number - _targetBlock) <= 256);
            // assert(randomN != 0);
        }

        // generate 256 bits of random, using as much entropy as we can from
        // sources that can't change between calls.
        randomN = uint256(keccak256(abi.encodePacked(randomN, _motherGenes, _fatherGenes, _targetBlock)));
        uint256 randomIndex = 0;

        uint8[] memory motherGenesArray = decodeAppearanceGenes(_motherGenes);
        uint8[] memory fatherGenesArray = decodeAppearanceGenes(_fatherGenes);
        // All traits that will belong to baby
        uint8[] memory babyGenesArray = new uint8[](48);

        // A pointer to the trait we are dealing with currently
        uint256 traitPos;
        // Trait swap value holder
        uint8 swap;
        // iterate all 12 appearance
        for (uint256 i = 0; i < 12; i++) {
            // pick 4 traits for appearance i
            uint256 j;
            // store the current random value
            uint256 rand;
            for (j = 3; j >= 1; j--) {
                traitPos = (i * 4) + j;

                rand = _sliceNumber(randomN, 2, randomIndex);
                // 0~3
                randomIndex += 2;

                // 1/4 of a chance of gene swapping forward towards expressing.
                if (rand == 0) {
                    // do it for mother hero
                    swap = motherGenesArray[traitPos];
                    motherGenesArray[traitPos] = motherGenesArray[traitPos - 1];
                    motherGenesArray[traitPos - 1] = swap;
                }

                rand = _sliceNumber(randomN, 2, randomIndex);
                // 0~3
                randomIndex += 2;

                if (rand == 0) {
                    // do it for father hero
                    swap = fatherGenesArray[traitPos];
                    fatherGenesArray[traitPos] = fatherGenesArray[traitPos - 1];
                    fatherGenesArray[traitPos - 1] = swap;
                }
            }
        }

        // DEBUG ONLY - We should have used 72 2-bit slices above for the swapping
        // which will have consumed 144 bits.
        // assert(randomIndex == 144);

        // We have 256 - 144 = 112 bits of randomness left at this point. We will use up to
        // four bits for the first slot of each trait (three for the possible mutation, one
        // to pick between mom and dad if the mutation fails, for a total of 48 bits. The other
        // traits use one bit to pick between parents (36 gene pairs, 36 genes), leaving us
        // well within our entropy budget.

        // done shuffling parent genes, now let's decide on choosing trait and if mutation.
        // NOTE: mutation ONLY happen in the "top slot" of each appearance. This saves
        //  gas and also ensures mutation only happen when they're visible.
        for (traitPos = 0; traitPos < 48; traitPos++) {
            // See if this trait pair should mutation
            uint8 mutationTrait = 0;
            // store the current random value
            uint256 rand;
            // There are two checks here. The first is straightforward, only the trait
            // in the first slot can mutation. The first slot is zero mod 4.
            //
            // The second check is more subtle: Only values that are one apart can mutation,
            // which is what we check inside the _mutation method. However, this simple mask
            // and compare is very cheap (9 gas) and will filter out about half of the
            // non-mutation pairs without a function call.
            //
            // The comparison itself just checks that one value is even, and the other is odd.
            if ((traitPos % 4 == 0) && (motherGenesArray[traitPos] & 1) != (fatherGenesArray[traitPos] & 1)) {
                rand = _sliceNumber(randomN, 3, randomIndex);
                randomIndex += 3;

                uint8 gender = _babyGender;
                mutationTrait = _mutation(motherGenesArray[traitPos], fatherGenesArray[traitPos], gender, rand);
            }

            if (mutationTrait > 0) {
                babyGenesArray[traitPos] = uint8(mutationTrait);
            } else {
                // did not mutation, pick one of the parent's traits for the baby
                // We use the top bit of rand for this (the bottom three bits were used to check for the mutation itself).
                rand = _sliceNumber(randomN, 1, randomIndex);
                randomIndex += 1;

                if (rand == 0) {
                    uint8 motherTrait = uint8(motherGenesArray[traitPos]);
                    if (_babyGender == 1 && (motherTrait > 23 && motherTrait <= 31)) {
                        babyGenesArray[traitPos] = uint8(fatherGenesArray[traitPos]);
                    } else {
                        babyGenesArray[traitPos] = motherTrait;
                    }
                } else {
                    uint8 fatherTrait = uint8(fatherGenesArray[traitPos]);
                    if (_babyGender == 0 && (fatherTrait > 15 && fatherTrait <= 23)) {
                        babyGenesArray[traitPos] = uint8(motherGenesArray[traitPos]);
                    } else {
                        babyGenesArray[traitPos] = fatherTrait;
                    }
                }
            }
        }

        return encodeAppearanceGenes(babyGenesArray);
    }

    /// @dev Parse a hero attribute genes and returns all of 16 "trait stack" that makes the attribute,
    /// 16 "trait stack" include 15 normal attribute and 1 hidden attribute
    /// @param _genes hero attribute gene
    /// @return The 32 traits that composes the attribute genetic code, logically divided in stacks of 2,
    //  the first trait of each stack is attribute genes code like AA, Aa, aa and the second trait of each stack is attribute value
    function decodeAttributeGenes(uint256 _genes) public pure returns (uint8[] memory) {
        uint8[] memory traits = new uint8[](32);
        uint256 i;
        for (i = 0; i < 32; i++) {
            traits[i] = uint8(_sliceNumber(_genes, uint256(8), i * 8));
        }
        return traits;
    }

    /// @dev Given an array of traits return the number that attribute genes
    function encodeAttributeGenes(uint8[] memory _traits) public pure returns (uint256 _genes) {
        _genes = 0;
        for (uint256 i = 0; i < 32; i++) {
            _genes = _genes << 8;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[31 - i];
        }
        return _genes;
    }

    /// @dev given attribute genes of hero mother & hero father, return a genetic combination
    /// @return the genes that are supposed to be passed down the baby hero
    function mixAttributeGenes(
        uint256 _motherGenes,
        uint256 _fatherGenes,
        uint256 _targetBlock
    ) external view override returns (uint256) {
        require(block.number > _targetBlock, "target block number is invalid");

        uint256 randomN = uint256(keccak256(abi.encodePacked(blockhash(_targetBlock))));

        if (randomN == 0) {
            _targetBlock = (block.number & MASK_FIRST_248_BITS) + (_targetBlock & MASK_LAST_8_BITS);

            if (_targetBlock >= block.number) {
                _targetBlock -= 256;
            }

            randomN = uint256(keccak256(abi.encodePacked(blockhash(_targetBlock))));
        }

        randomN = uint256(keccak256(abi.encodePacked(randomN, _motherGenes, _fatherGenes, _targetBlock)));
        uint256 randomIndex = 0;

        uint8[] memory motherGenesArray = decodeAttributeGenes(_motherGenes);
        uint8[] memory fatherGenesArray = decodeAttributeGenes(_fatherGenes);
        // All traits that will belong to baby
        uint8[] memory babyGenesArray = new uint8[](32);

        // A pointer to the trait we are dealing with currently
        uint256 traitPos;
        // store the current random value
        uint256 rand;

        // mix 15 normal attribute genes
        for (traitPos = 0; traitPos < 30; traitPos++) {
            if (traitPos % 2 == 0) {
                rand = _sliceNumber(randomN, 1, randomIndex);
                randomIndex += 1;

                //  Aa 00000010
                //  Aa ->  A or a, A is 00000001 and a is 00000000
                uint8 motherTraitCode = uint8(_sliceNumber(uint256(motherGenesArray[traitPos]), 1, rand));

                rand = _sliceNumber(randomN, 1, randomIndex);
                randomIndex += 1;

                //  AA 00000011
                //  AA ->  A or A, A is 00000001
                uint8 fatherTraitCode = uint8(_sliceNumber(uint256(fatherGenesArray[traitPos]), 1, rand));

                // motherTraitCode is a 00000000
                // fatherTraitCode is A 00000001
                // fatherTraitCode << 1 == 00000010
                if (motherTraitCode > fatherTraitCode) {
                    motherTraitCode = motherTraitCode << 1;
                } else {
                    fatherTraitCode = fatherTraitCode << 1;
                }

                // 00000010 | 00000000 == 00000010, babyTraitCode is Aa
                babyGenesArray[traitPos] = motherTraitCode | fatherTraitCode;
            }
        }

        // assert(randomIndex == 60);
        // 256 - 60 = 196, (5 + 4 + 2 + 1) * 15 = 180, randomIndex is enough
        for (traitPos = 0; traitPos < 30; traitPos++) {
            if (traitPos % 2 != 0) {
                uint8 traitValue = 0;

                // traitValue random from randomN,max value is 31 + 15 + 3 + 1 = 50,range is 0~50
                rand = _sliceNumber(randomN, 5, randomIndex);
                randomIndex += 5;
                traitValue += uint8(rand);

                rand = _sliceNumber(randomN, 4, randomIndex);
                randomIndex += 4;
                traitValue += uint8(rand);

                rand = _sliceNumber(randomN, 2, randomIndex);
                randomIndex += 2;
                traitValue += uint8(rand);

                rand = _sliceNumber(randomN, 1, randomIndex);
                randomIndex += 1;
                traitValue += uint8(rand);

                // traitCode only AA,Aa,aa
                // AA is 00000011 == 3,traitValue 50~100
                // Aa is 00000010 == 2,traitValue 50~100
                // aa is 00000000 == 0,traitValue 0~50
                uint8 traitCode = babyGenesArray[traitPos - 1];
                if (traitCode > 1) {
                    traitValue += 50;
                }

                babyGenesArray[traitPos] = traitValue;
            }
        }

        // assert(randomIndex == 240);
        // the last stack is hidden attributes, no trait code and only trait value 0~7
        // 256 - 60 - 180 = 16, 3 bit from randomN for trait value, randomIndex is enough
        rand = _sliceNumber(randomN, 3, randomIndex);
        // randomIndex += 3; no need, save gas
        babyGenesArray[31] = uint8(rand);

        return encodeAttributeGenes(babyGenesArray);
    }
}

/// SPDX-License-Identifier: MIT
/// CryptoHero Contracts v1.0.0 (IGeneScience.sol)

pragma solidity ^0.8.0;

interface IGeneScience {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isGeneScience() external pure returns (bool);

    /// @dev random generate hero gender
    function generateGender(uint256 targetBlock) external view returns (uint8);

    /// @dev given appearance genes of hero mother & hero father, return a genetic combination
    /// @return the genes that are supposed to be passed down the baby hero
    function mixAppearanceGenes(
        uint8 gender,
        uint256 motherGenes,
        uint256 fatherGenes,
        uint256 targetBlock
    ) external view returns (uint256);

    /// @dev given attribute genes of hero mother & hero father, return a genetic combination
    /// @return the genes that are supposed to be passed down the baby hero
    function mixAttributeGenes(
        uint256 motherGenes,
        uint256 fatherGenes,
        uint256 targetBlock
    ) external view returns (uint256);
}