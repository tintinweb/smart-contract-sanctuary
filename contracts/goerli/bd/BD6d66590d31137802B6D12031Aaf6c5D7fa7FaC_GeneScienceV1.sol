// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;


/// @title defined the interface that will be referenced in main Defish contract
interface GeneScienceInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isGeneScience() external pure returns (bool);

    /// @dev given genes of fish 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of sire
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint256 genes1, uint256 genes2) external returns (uint256);

    /// @dev random gene for fish
    function randomeGene(uint256 seed) external view returns (uint256 genes);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./ExternalInterfaces/GeneScienceInterface.sol";


/// @title GeneScience implements the trait calculation for new fish, inherit from CryptoKitties
/// @author CauTa  <[email protected]> (https://github.com/cauta)
contract GeneScienceV1 is GeneScienceInterface {

    uint256 internal constant maskLast8Bits = uint256(0xff);
    uint256 internal constant maskFirst248Bits = ~uint256(0xff);
    uint32 constant totalPart = 9;
    uint32 totalTrail = totalPart*4;

    constructor() {}

    function isGeneScience() external pure override returns (bool){return true;}

    function randomeGene(uint256 seed) public view override returns (uint256 genes){
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), seed)));
        uint8[] memory var1 = decode(random);
        genes = encode(var1);
        return genes;
    }

    /// @dev given a number get a slice of any bits, at certain offset
    /// @param _n a number to be sliced
    /// @param _nbits how many bits long is the new number
    /// @param _offset how many bits to skip
    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }

    /// @dev Get a 5 bit slice from an input as a number
    /// @param _input bits, encoded as uint
    /// @param _slot from 0 to 50
    function _get5Bits(uint256 _input, uint256 _slot) internal pure returns(uint8) {
        return uint8(_sliceNumber(_input, uint256(5), _slot * 5));
    }

    /// @dev Parse a kitten gene and returns all of totalPart "trait stack" that makes the characteristics
    /// @param _genes kitten gene
    /// @return the totalTrail traits that composes the genetic code, logically divided in stacks of 4, where only the first trait of each stack may express
    function decode(uint256 _genes) public view returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](totalTrail);
        uint8 i;
        /// we decode class of fish with first 4 trails fit into 5 class
        for(i = 0; i < 4; i++) {
            traits[i] = _get5Bits(_genes, i) % 5;
            traits[i] = traits[i] % 5;
        }
        for(i = 4; i < totalTrail; i++) {
            traits[i] = _get5Bits(_genes, i) % 16;
        }
        return traits;
    }

    /// @dev Given an array of traits return the number that represent genes
    function encode(uint8[] memory _traits) public view returns (uint256 _genes) {
        _genes = 0;
        for(uint256 i = 0; i < totalTrail; i++) {
            _genes = _genes << 5;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[((totalTrail-1)) - i];
        }
        return _genes;
    }

    /// @dev return the expressing traits
    /// @param _genes the long number expressing fish genes
    function expressingTraits(uint256 _genes) public pure returns(uint8[totalPart] memory) {
        uint8[totalPart] memory express;
        for(uint256 i = 0; i < totalPart; i++) {
            express[i] = _get5Bits(_genes, i * 4);
        }
        return express;
    }

    function mixGenes(uint256 _genes1, uint256 _genes2) public view override returns (uint256) {
        return mixGenes(_genes1, _genes2, block.number - 1);
    }

    /// @dev the function as defined in the breeding contract - as defined in CK bible
    function mixGenes(uint256 _genes1, uint256 _genes2, uint256 _targetBlock) public view returns (uint256) {
        require(block.number > _targetBlock);

        // Try to grab the hash of the "target block". This should be available the vast
        // majority of the time (it will only fail if no-one calls giveBirth() within 256
        // blocks of the target block, which is about 40 minutes. Since anyone can call
        // giveBirth() and they are rewarded with ether if it succeeds, this is quite unlikely.)
        uint256 randomN = uint256(blockhash(_targetBlock));

        if (randomN == 0) {
            // We don't want to completely bail if the target block is no-longer available,
            // nor do we want to just use the current block's hash (since it could allow a
            // caller to game the random result). Compute the most recent block that has the
            // the same value modulo 256 as the target block. The hash for this block will
            // still be available, and – while it can still change as time passes – it will
            // only change every 40 minutes. Again, someone is very likely to jump in with
            // the giveBirth() call before it can cycle too many times.
            _targetBlock = (block.number & maskFirst248Bits) + (_targetBlock & maskLast8Bits);

            // The computation above could result in a block LARGER than the current block,
            // if so, subtract 256.
            if (_targetBlock >= block.number) _targetBlock -= 256;

            randomN = uint256(blockhash(_targetBlock));

            // DEBUG ONLY
            // assert(block.number != _targetBlock);
            // assert((block.number - _targetBlock) <= 256);
            // assert(randomN != 0);
        }

        // generate 256 bits of random, using as much entropy as we can from
        // sources that can't change between calls.
        randomN = uint256(keccak256(abi.encodePacked(randomN, _genes1, _genes2, _targetBlock)));
        uint256 randomIndex = 0;

        uint8[] memory genes1Array = decode(_genes1);
        uint8[] memory genes2Array = decode(_genes2);
        // All traits that will belong to baby
        uint8[] memory babyArray = new uint8[](totalTrail);
        // A pointer to the trait we are dealing with currently
        uint256 traitPos;
        // Trait swap value holder
        uint8 swap;
        // store the current random value
        uint256 rand;
        // iterate all totalPart characteristics
        for(uint256 i = 0; i < totalPart; i++) {
            // pick 4 traits for characteristic i
            uint256 j;

            for(j = 3; j >= 1; j--) {
                traitPos = (i * 4) + j;

                rand = _sliceNumber(randomN, 2, randomIndex); // 0~3
                randomIndex += 2;

                // 1/4 of a chance of gene swapping forward towards expressing.
                if (rand == 0) {
                    // do it for parent 1
                    swap = genes1Array[traitPos];
                    genes1Array[traitPos] = genes1Array[traitPos - 1];
                    genes1Array[traitPos - 1] = swap;

                }

                rand = _sliceNumber(randomN, 2, randomIndex); // 0~3
                randomIndex += 2;

                if (rand == 0) {
                    // do it for parent 2
                    swap = genes2Array[traitPos];
                    genes2Array[traitPos] = genes2Array[traitPos - 1];
                    genes2Array[traitPos - 1] = swap;
                }
            }

        }

        for(traitPos = 0; traitPos < totalTrail; traitPos++) {
            rand = _sliceNumber(randomN, 1, randomIndex);
            randomIndex += 1;

            if (rand == 0) {
                babyArray[traitPos] = uint8(genes1Array[traitPos]);
            } else {
                babyArray[traitPos] = uint8(genes2Array[traitPos]);
            }
        }

        return encode(babyArray);
    }
}

