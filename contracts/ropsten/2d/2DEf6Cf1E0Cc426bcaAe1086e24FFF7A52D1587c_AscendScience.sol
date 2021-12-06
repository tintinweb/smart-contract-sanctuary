// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract AscendScience {
    bool public constant IS_ASCEND_SCIENCE = true;

    uint256 internal constant NUM_TRAITS = TRAIT_SIZE / 4;
    uint256 internal constant TRAIT_SIZE = 48;
    uint256 internal constant NUM_BITS_IN_MASKS = 20;
    /// @dev pre-generated bit masks
    uint256[] internal _bitMasks = [
        0x0000000000000000040002000400000802800408032000000000880000188110,
        0x0000000000000040001000000000110042000400a08101014000c09200000000,
        0x800000000000000400020000000401200000010800000000100080504080c0e0,
        0x0000001000000000000008100020000008000200100820008820820040040142,
        0x000000001000000000000000001000020014c8021140000010010400a01c0000,
        0x000002000100000080008000000000400246804100008002000002008080a100,
        0x0000000000000040400000020404008810001000010108104140410000040002,
        0x00000000800000100010020000800200400000008004c0004102000900441200,
        0x0000020000000000000000401000000091400301040000400804000021500024,
        0x0000000000000000000080000000000081000000906081021410012040000000,
        0x000000000000000000000004000450000088823202002020400a080000000100,
        0x0000000001040100000001004100040050200500200081040002002000000202,
        0x0000800000000000000200000000081082040002102080040840090030000300,
        0x0000000000040000000000400082000088002001000048000042400051006a00,
        0x0000000000000000440000000010000000500412022000003400014114000082,
        0x0000000000000000010000008000100000000350000001005008080201046010,
        0x0000000000000000000200020000100000812010810300104080001200200040,
        0x0000800000200000100000000000000280001000080202101040000280428500,
        0x0000020000000000000000100008000002204000010070000011100010008860,
        0x0000000000000000100000000098000004110304000020000040080012202030,
        0x00000000000000000000000000284000000000080c2080100000944020102120,
        0x8000000000002004004050002000040000004200000000111000001000880072,
        0x0000800080000000004040000000000000020000000020022008194000030026,
        0x0000000000240010000018100300080440200000000000c40002006004100000,
        0x0000000000200000000000104400000000404440900010c0020c080000280080,
        0x000000000000040010008002000000480002809000a404000400120800200000,
        0x000002000000000000000000040040401002000040008008242280000002808a,
        0x0000000000008040000008000000000001000600001000c80100000a10124408,
        0x000000000000000000000006000204000028410200000800000040c002210320,
        0x0000000000000004500000022000110011008000011000890080000000030440,
        0x00000000000000400000000040022000000020400388100000088004c4800002,
        0x80000000000000000140000000041000008801008004850008400064000000a0,
        0x0000000000000040000000000000004280002000800024100088900100008540,
        0x000000000020000000408000008000000100010000000820a061000224128000,
        0x000000000000000000000000030000008040507000002000108291000008000a,
        0x0000000000000000400001009000000002008000420001140040002001e40240,
        0x0000000000000000010000001080030000008180000000400040001880a26101,
        0x800080100000840080000000000008000000001020400000004802052200200a,
        0x000000000100200000008000000014008000040000000440200820210400a080,
        0x00000000000000040002005000200804a0000a00010000400408140000009000,
        0x0000020000000000800000000008000020000200802084000041024040084102,
        0x0000020000000000000000008280008000000000151030000002042000403009,
        0x000000000020004000000000300000000011000000040004112a200090540400,
        0x0000020000000000000008000000400040200040000021001010f50002000022,
        0x000000000000010000088000800a003000a01000000100000400420808200005,
        0x000000000000004000000040440040000000020001c000400000c00240910900,
        0x0000000000000040410080020000860204000008400000040102000000120200,
        0x00000000000000000008000000000810010002000400002004012a2080000172,
        0x0000001000000510004010000000000002000021020400104800000030800a00,
        0x0000000000000000000000000000400000000002082084808900820620100011,
        0x0000000000000400000800000000208008019800000000040401082404024002,
        0x0000000000200100040000000000080004000004022820408000501010440018,
        0x0000000000000000400200000000000402000001840210c00008880440200220,
        0x000000000000010040100000008000884004002200040004810000c026000400,
        0x00000000002001008400000004000000090000300004003000028000da010000,
        0x0000000000000040010000001000002000001202008020200018003a01a00400,
        0x000000000000a0000000000000002000100700020000600008090c4000080103,
        0x80000010800000400000000010000000d2200000004000004410120010000409,
        0x000000000000000000400000001040000008000001200100910a121840110000,
        0x80000000000000000000002022100108004208000a3400000400002020000400,
        0x000000000000000000000200000001000000a200013802040000100054200a10,
        0x00000200010000000000100000000240800800c0400100008020080200004840,
        0x0000000001040000000040040000200020000918004020088810000002000024,
        0x0000020080000000100000040010000004008008000080000300401400908008,
        0x0000000000000000040000000100404000040000840000008250060140018090,
        0x0000001000000000800000000000002001c12002000100048180000002809100,
        0x00000000000000000000100000020020100420000202000400820020348041a0,
        0x0000000000000000014000000204000400000800040221002003008061840008,
        0x000000000000001000080020040084000140000010000000c128004001004430,
        0x00000000802000000000502204000000000100000180080810000000000a6009,
        0x0000000000000100804a900000000080800000000000000081080010442c0001,
        0x000002000000200000004812200000000000001080002000008200040000092c,
        0x00000000000001000000801000800000000c0000009000200044030008203400,
        0x0000800000000000000200000080800000010000012045100030010040001004,
        0x000000000100000000004010010080a080800010000000080000002841001424,
        0x0000020000002000010000000004030090020400000001402048000000003005,
        0x0000800001000000040010048000000080000a48000000000400600202001902,
        0x00000000000020000002000000800000c0000018000012040000008182441080,
        0x0000000001000000000000004000002201080040100080040e00000080c08840,
        0x0000000000000000000080000080104000840000011021040000188001000600,
        0x000000000000000000000a00000800a08008000084008000050080044020040c,
        0x0000001080000000000000001000000019000044000800102001001406a00028,
        0x0000020000000000000000000000000000048100048806020000800043100318,
        0x800000000000000080000000000001008000020600000a200001926210000050,
        0x00000000000080000000000000a000404000a010000110222022000020800418,
        0x000000000000000000000000000012420000400280008c140032010000040003,
        0x000000100000040000000000020002008000000004888000c6100040c1050000,
        0x0000000000202000000002000200000000041200010004000c00046020440120,
        0x0000000000002000000000000200a00011000000000000200019824010290104,
        0x00000000002000000000000000000008002380000124001421100004100c0082,
        0x0000000000000450000040000008000001800000000214210340884000020000,
        0x000000000000a0101000000000001000000000100400000148008000c0224040,
        0x00000000000020000010110004a0000400000020000000000100108181301040,
        0x000000001000801000100a0204000000100004000000b400c000000022020020,
        0x0000000000002010800010400000000200000802110020400480020000000828,
        0x80000000000000000000411050004002400880100000280200000000000a9020,
        0x80000000000000049000000000041004000000041920a0000002004000008042,
        0x0000000000000000400000000200000004006001200005002080002212040040,
        0x00000000000020000012901000080000000000044040800000000b0406102000,
        0x0000800000000000000000200000400440000010000022010400084021030014
    ];

    constructor() {}

    function _ascend(
        uint8 trait1,
        uint8 trait2,
        uint256 rand
    ) internal pure returns (uint8 ascension) {
        ascension = 0;

        uint8 smallT = trait1;
        uint8 bigT = trait2;

        if (smallT > bigT) {
            bigT = trait1;
            smallT = trait2;
        }

        if ((bigT - smallT == 1) && smallT % 2 == 0) {
            // The rand argument is expected to be a random number 0-7.
            // 1st and 2nd tier: 1/4 chance (rand is 0 or 1)
            // 3rd and 4th tier: 1/8 chance (rand is 0)

            // must be at least this much to ascend
            uint256 maxRand;
            if (smallT < 23) maxRand = 1;
            else maxRand = 0;

            if (rand <= maxRand) {
                ascension = (smallT / 2) + 16;
            }
        }
    }

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

    function _get5Bits(uint256 _input, uint256 _slot)
        internal
        pure
        returns (uint8)
    {
        return uint8(_sliceNumber(_input, uint256(5), _slot * 5));
    }

    function decode(uint256 genes) public pure returns (uint8[] memory) {
        uint8[] memory traits = new uint8[](TRAIT_SIZE);
        uint256 i;
        for (i = 0; i < TRAIT_SIZE; i++) {
            traits[i] = _get5Bits(genes, i);
        }
        return traits;
    }

    function encode(uint8[] memory traits)
        public
        pure
        returns (uint256 _genes)
    {
        _genes = 0;
        for (uint256 i = 0; i < TRAIT_SIZE; i++) {
            _genes = _genes << 5;
            // bitwise OR trait with _genes
            _genes = _genes | traits[TRAIT_SIZE - 1 - i];
        }
        return _genes;
    }

    /// @dev create a "random" set of traits
    function getWeightedBitMask(uint256 numOneBits, uint256 nonce)
        internal
        view
        returns (uint256)
    {
        uint256 numIterations = numOneBits / NUM_BITS_IN_MASKS;

        uint256 mask = 0;

        for (uint256 i = 0; i < numIterations; i++) {
            uint256 r = uint256(keccak256(abi.encodePacked(i, nonce)));

            // Get a random item in the _bitMasks
            uint256 bits = _bitMasks[r % uint256(_bitMasks.length)];

            mask = mask | bits;
        }

        return mask;
    }

    /// @dev add a target set of bits to a set of traits
    function addBits(
        uint256 traits,
        uint256 boost,
        uint256 nonce
    ) internal view returns (uint256) {
        uint256 mask = getWeightedBitMask(boost, nonce);

        // Add the mask to the traits with an OR
        return traits | mask;
    }

    function mixTraits(
        uint256 genes1,
        uint256 genes2,
        uint256 nonce
    ) external view returns (uint256) {
        uint256 randomN = uint256(
            keccak256(abi.encodePacked(genes1, genes2, nonce))
        );
        uint256 randomIndex = 0;

        uint8[] memory genesArray1 = decode(genes1);
        uint8[] memory genesArray2 = decode(genes2);
        // All traits that will belong to baby
        uint8[] memory babyArray = new uint8[](TRAIT_SIZE);
        // A pointer to the trait we are dealing with currently
        uint256 traitPos;
        // Trait swap value holder
        uint8 swap;
        // iterate all NUM_TRAITS characteristics
        for (uint256 i = 0; i < NUM_TRAITS; i++) {
            // pick 4 traits for characteristic i
            uint256 j;
            // store the current random value
            uint256 rand;
            for (j = 3; j >= 1; j--) {
                traitPos = (i * 4) + j;

                rand = _sliceNumber(randomN, 2, randomIndex); // 0~3
                randomIndex += 2;

                // 1/4 of a chance of gene swapping forward towards expressing.
                if (rand == 0) {
                    // do it for parent 1
                    swap = genesArray1[traitPos];
                    genesArray1[traitPos] = genesArray1[traitPos - 1];
                    genesArray1[traitPos - 1] = swap;
                }

                rand = _sliceNumber(randomN, 2, randomIndex); // 0~3
                randomIndex += 2;

                if (rand == 0) {
                    // do it for parent 2
                    swap = genesArray2[traitPos];
                    genesArray2[traitPos] = genesArray2[traitPos - 1];
                    genesArray2[traitPos - 1] = swap;
                }
            }
        }

        for (traitPos = 0; traitPos < TRAIT_SIZE; traitPos++) {
            // See if this trait pair should ascend
            uint8 ascendedTrait = 0;
            uint256 rand;

            // There are two checks here. The first is straightforward, only the trait
            // in the first slot can ascend. The first slot is zero mod 4.
            //
            // The second check is more subtle: Only values that are one apart can ascend,
            // which is what we check inside the _ascend method. However, this simple mask
            // and compare is very cheap (9 gas) and will filter out about half of the
            // non-ascending pairs without a function call.
            //
            // The comparison itself just checks that one value is even, and the other
            // is odd.
            if (
                (traitPos % 4 == 0) &&
                (genesArray1[traitPos] & 1) != (genesArray2[traitPos] & 1)
            ) {
                rand = _sliceNumber(randomN, 3, randomIndex);
                randomIndex += 3;

                ascendedTrait = _ascend(
                    genesArray1[traitPos],
                    genesArray2[traitPos],
                    rand
                );
            }

            if (ascendedTrait > 0) {
                babyArray[traitPos] = uint8(ascendedTrait);
            } else {
                // did not ascend, pick one of the parent's traits for the baby
                // We use the top bit of rand for this (the bottom three bits were used
                // to check for the ascension itself).
                rand = _sliceNumber(randomN, 1, randomIndex);
                randomIndex += 1;

                if (rand == 0) {
                    babyArray[traitPos] = uint8(genesArray1[traitPos]);
                } else {
                    babyArray[traitPos] = uint8(genesArray2[traitPos]);
                }
            }
        }

        return addBits(encode(babyArray), 40, nonce);
    }

    function transmogrifyTraits(
        uint256 trait1,
        uint256 trait2,
        uint256 trait3,
        uint256 nonce
    ) external view returns (uint256) {
        return
            this.mixTraits(
                this.mixTraits(trait1, trait2, nonce),
                trait3,
                nonce
            );
    }

    function getRandomTraits(
        uint256 salt1,
        uint256 salt2,
        uint256 boost
    ) external view returns (uint256) {
        bytes32 x = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.number,
                msg.sender,
                salt1,
                salt2
            )
        );

        uint256 r = addBits(uint256(x), boost, salt1);
        return r;
    }
}