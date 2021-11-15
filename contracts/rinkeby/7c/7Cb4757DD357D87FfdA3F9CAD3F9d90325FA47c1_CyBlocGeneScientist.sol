// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract CyBlocGeneScientist {
    uint256 constant public HASH_MASK = uint256(keccak256("CYBALL"));
    uint256 constant public GENE_VERSION = 0; // TODO: change to 1

    uint256 constant public BRONZE = 1;
    uint256 constant public SILVER = 2;
    uint256 constant public GOLD = 3;
    uint256 constant public PLATINUM = 4;
    uint256 constant public LEGENDARY = 5;

    uint256 constant public TRAIT_NONE = 0;
    uint256 constant public TRAIT_COMMON = 1;
    uint256 constant public TRAIT_RARE = 2;
    uint256 constant public TRAIT_SUPER_RARE = 3;


    uint256 constant private RNG_SHIFT_CLASS = 1; // must be less than 100
    uint256 constant private RNG_SHIFT_TRAIT = 10; // must be less than 100
    uint256 constant private RNG_SHIFT_PASS_TRAIT = 12; // must be less than 100

    function generateGene(uint256 class, uint256[3] memory traits, uint256 seed) public pure returns (uint256 gene) {
        require(BRONZE <= class && class <= LEGENDARY);

        require(TRAIT_NONE <= traits[0] && traits[0] <= TRAIT_SUPER_RARE);
        require(TRAIT_NONE <= traits[1] && traits[1] <= TRAIT_SUPER_RARE);
        require(TRAIT_NONE <= traits[2] && traits[2] <= TRAIT_SUPER_RARE);

        require(!(
            traits[0] == TRAIT_NONE
            && traits[1] == TRAIT_NONE
            && traits[2] == TRAIT_NONE
        ));

        require(seed != 0);

        gene = GENE_VERSION * 10 ** 12
             + class * 10 ** 9
             + traits[0] * 10 ** 6
             + traits[1] * 10 ** 3
             + traits[2];

        gene = gene * 10**50 + seed % 10 ** 40;
        gene = gene ^ HASH_MASK;

        (uint256 c, uint256[3] memory t, uint256 s, uint256 v) = parseGene(gene);
        
        require(v == GENE_VERSION
            && c == class
            && t[0] == traits[0]
            && t[1] == traits[1]
            && t[2] == traits[2]
            && s == seed % 10**40);
    }
    
    function parseGene(uint gene) public pure returns (uint256 class, uint256[3] memory traits, uint256 seed, uint version) {
        gene = gene ^ HASH_MASK;
        seed = gene % 10 ** 50;
        gene = gene / 10 ** 50;
        
        version     =  gene           / 10**12;
        class       = (gene % 10**12) / 10**9;
        traits[0]   = (gene % 10**9 ) / 10**6;
        traits[1]   = (gene % 10**6 ) / 10**3;
        traits[2]   = (gene % 10**3 );
    }
    
    function RNG(uint256 seed, uint256 shift, uint256 xor) public pure returns (uint256) {
        if (GENE_VERSION == 0) {
            return seed;
        }
        else {
            return uint(keccak256(abi.encode(seed >> shift))) ^ uint(keccak256(abi.encode(xor)));
        }
    }

    function random(uint256 seed, uint16[5] memory probalities) public pure returns (uint256 index) {
        require(probalities.length > 0, "Wrong data");

        uint range = 0;
        for (uint i = 0; i < probalities.length; i++) {
            range += probalities[i];
        }

        uint number = (seed % range) + 1;

        range = 0;
        for (index = 0; index < probalities.length; index++) {
            range += probalities[index];
            if (number <= range) {
                break;
            }
        }
    }

    function randomClass(bool isDualMentor, uint256 mentorClass, uint256 seed) public pure returns (uint256 class) {
        uint16[5][5] memory MentorClassProbality = isDualMentor ? 
        [ // 2 mentors
            [7400, 2400,  200,    0,    0],
            [   0, 8470, 1500,   30,    0],
            [   0, 3070, 6000,  900,   30],
            [   0,    0, 3850, 6000,  150],
            [   0,    0, 1000, 6000, 3000]
        ]:
        [ // 1 mentor
            [8900, 1000,  100,    0,    0],
            [5490, 4000,  500,   10,    0],
            [2695, 5000, 2000,  300,    5],
            [   0, 4950, 3000, 2000,   50],
            [   0, 2000, 5000, 2000, 1000]
        ];

        return 1 + random(
            RNG(seed, RNG_SHIFT_CLASS, RNG_SHIFT_CLASS), 
            MentorClassProbality[mentorClass - 1]
        );
    }

    function sort(uint256[3] memory traits) public pure returns (uint256[3] memory) {
        if (traits[0] < traits[1]) {
            (traits[0], traits[1]) = (traits[1], traits[0]);
        }

        if (traits[0] < traits[2]) {
            (traits[0], traits[2]) = (traits[2], traits[0]);
        }

        if (traits[1] < traits[2]) {
            (traits[1], traits[2]) = (traits[2], traits[1]);
        }

        return traits;
    }

    function fillTraits(uint256[3] memory traits, uint256 seed) public pure returns (uint256[3] memory) {
        uint16[5] memory normalProblity =   [7400, 2000,  500, 100, 0];
        uint16[5] memory mustHaveProblity = [   0, 7700, 2000, 300, 0];

        traits = sort(traits);
        
        if (traits[0] == 0) {
            traits[0] = random(RNG(seed, RNG_SHIFT_TRAIT, 0), normalProblity);
        }

        if (traits[1] == 0) {
            traits[1] = random(RNG(seed, RNG_SHIFT_TRAIT, 1), normalProblity);
        }

        if (traits[2] == 0) {
            if (traits[0] == 0 && traits[1] == 0) {
                traits[2] = random(RNG(seed, RNG_SHIFT_TRAIT, 2), mustHaveProblity);
            }
            else {
                traits[2] = random(RNG(seed, RNG_SHIFT_TRAIT, 2), normalProblity);
            }
        }

        return sort(traits);
    }

    function randomOneTraits(uint256[3] memory traits, uint256 seed) public pure returns (uint256[3] memory newTraits) {
        traits = sort(traits);
        uint16[5][3] memory probality = [
            [0, 7500, 2500, 0, 0],
            [0, 5000, 5000, 0, 0],
            [0, 2500, 7500, 0, 0]
        ];

        for (uint i = 0; i < 3; i++) {
            if (traits[i] != 0) {
                uint pass = random(
                    RNG(seed, RNG_SHIFT_PASS_TRAIT, i), 
                    probality[traits[i] - 1]
                );

                if (pass == 1) {
                    newTraits[i] = traits[i];
                }
            }
        }
        newTraits = fillTraits(newTraits, seed);
        newTraits = sort(newTraits); 
    }

    function randomTwoTraits(uint256[3] memory traits1, uint256[3] memory traits2, uint256 seed) public pure returns (uint256[3] memory newTraits) {
        // TODO: Check probality
        uint16[5][3] memory probality = [
            [0, 7500, 2500, 0, 0],
            [0, 5000, 5000, 0, 0],
            [0, 2500, 7500, 0, 0]
        ];
        traits1 = sort(traits1);
        traits2 = sort(traits2);

        uint i = 0;
        uint j = 0;
        uint count = 0;

        for (; i + j < 6 && count < 3;) {
            if (j == 3 || traits1[i] > traits2[j]) {
                newTraits[count] = traits1[i++];
            }
            else if (i == 3 || traits1[i] <= traits2[j]) {
                newTraits[count] = traits2[j++];
            }

            if (newTraits[count] != 0) {
                uint pass = random(
                    RNG(seed, RNG_SHIFT_PASS_TRAIT, i + j), 
                    probality[newTraits[count] - 1]
                );
                
                if (pass == 1) {
                    count++;
                }
            }
            else {
                newTraits[count] = 0;
            }
        }

        newTraits = fillTraits(newTraits, seed);
        newTraits = sort(newTraits); 
    }

    function mixGenes(uint256 gene, uint256 gene2, uint256 seed) public pure returns (uint256) {
        require (gene != 0, "Invalid gene");


        (uint256 class, uint256[3] memory traits,, ) = parseGene(gene);

        if (gene2 == 0) {
            return generateGene(
                randomClass(false, class, seed), 
                randomOneTraits(traits, seed),
                seed
            );
        }
        else {
            (uint256 class2, uint256[3] memory traits2,, ) = parseGene(gene2);
            return generateGene(
                randomClass(
                    class == class2, 
                    class > class2 ? class : class2, 
                    seed
                ), 
                randomTwoTraits(traits, traits2, seed),
                seed
            );
        }
    }
}

