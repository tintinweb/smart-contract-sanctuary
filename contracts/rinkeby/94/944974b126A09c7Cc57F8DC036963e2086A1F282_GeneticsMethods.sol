// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import './Constructor.sol';


contract GeneticsMethods {

    Constructor.Struct public control;
    
    function setGlobalParameters(Constructor.Struct memory input) external {
        control = input;
    }

    function wholeArithmeticRecombination(uint32[50] memory geneticSequence1, uint32[50] memory geneticSequence2) public view returns(uint32[50] memory geneticSequence) {
        
        // Return the average of parents genetical sequences
        for ( uint256 i = 2 ; i < 50 ; ++i ) {

            // arithmetic recombination
            geneticSequence[i] = ( geneticSequence1[i] + geneticSequence2[i] ) / 2;

            // Checks for resource id valability
            if ( geneticSequence[i] > control.maxValues[i] )
                geneticSequence[i] = 0;

        }

    }

    function swapMutation(uint32[50] memory geneticSequence, uint256 randomness) public view returns(uint32[50] memory) {

        // Generate random gene index
        uint256 randomGene = generateRandomGeneIndex(geneticSequence[2], randomness);
        
        // Generate random positions inside the gene
        (uint256 pos1, uint256 pos2) = generateRandomAlleles(geneticSequence,randomness,randomGene);

        // Swap allele
        uint32 aux = geneticSequence[pos2];
        geneticSequence[pos2] = geneticSequence[pos1];
        geneticSequence[pos1] = aux;

        return geneticSequence;
    }

    function inversionMutation(uint32[50] memory geneticSequence, uint256 randomness) public view returns(uint32[50] memory) {
        
        // Generate random gene index
        uint256 randomGene = generateRandomGeneIndex(geneticSequence[2], randomness);

        // Generate random positions inside the gene
        (uint256 pos1, uint256 pos2) = generateRandomAlleles(geneticSequence,randomness,randomGene);

        // Auxiliary variable
        uint32 aux;

        // Parse from pos1 to pos2
        for (uint i = pos1; i < pos1 + pos2 && pos1 + pos2 < geneticSequence.length ; ++i) {

            // Save allele on current index
            aux = geneticSequence[i];

            // Move the allele from "the end of [pos1,...,pos2] subarray" - i to current position
            geneticSequence[i] = geneticSequence[pos1 + pos2 - i];

            // Move the previously saved position into "the end of [pos1,...,pos2] subarray" - i position 
            geneticSequence[pos1 + pos2 - i] = geneticSequence[i];

        }

        return geneticSequence;
    }

    function scrambleMutation(uint32[50] memory geneticSequence, uint256 randomness) public view returns(uint32[50] memory) {
        
        // Generate random gene index
        uint256 randomGene = generateRandomGeneIndex(geneticSequence[2], randomness);

        // Generate random positions inside the gene
        (uint256 pos1, uint256 pos2) = generateRandomAlleles(geneticSequence,randomness,randomGene);
        
        // Auxiliary variable used to store one allele
        uint32 aux;

        // Auxiliary variable used to store the random position index, inside a gene
        uint256 pos;
        for (uint i = pos1; i < pos1 + pos2 && pos1 + pos2 < geneticSequence.length ; ++i) {

            // Generate a random position inside the gene, where pos1 <= pos <= pos2
            pos = (uint256(keccak256(abi.encodePacked(i, randomness))) % pos1) + pos2;

            // Save the allele of the random generated position inside the auxiliary variable
            aux = geneticSequence[pos];

            // Save the current allele into the random generated position allele
            geneticSequence[pos] = geneticSequence[i];

            // Save the random genenrated position allele into the current allele
            geneticSequence[i] = aux;

        }
        
        return geneticSequence;
    }
    
    function arithmeticMutation(uint32[50] memory geneticSequence, uint256 randomness) public view returns(uint32[50] memory) {

        // Generate random gene index
        uint256 randomGene = generateRandomGeneIndex(geneticSequence[2], randomness);

        // Generate random positions inside the gene
        (uint256 pos1, ) = generateRandomAlleles(geneticSequence,randomness,randomGene);

        uint256 randomValueToAdd = uint256(keccak256(abi.encodePacked(geneticSequence[15], randomness))) % control.maxValues[pos1];
        // Perform a incrementation
        geneticSequence[pos1] += uint32(randomValueToAdd);

        // Checks for resource id valability
        if ( geneticSequence[pos1] > control.maxValues[pos1] )
            geneticSequence[pos1] = 0;

        return geneticSequence;

    }

    function uniformCrossover(uint32[50] calldata geneticSequence1, uint32[50] calldata geneticSequence2, uint256 randomness) public view returns(uint32[50] memory geneticSequence) {
        for ( uint256 i = 0 ; i < 50 ; ++i ) {
            uint256 dominantGene = uint256(keccak256(abi.encodePacked(i, randomness)));
            if ( dominantGene % 100 < control.maleGenesProbability ) {
                geneticSequence[i] = geneticSequence1[i];
            } else {
                geneticSequence[i] = geneticSequence2[i];
            }
        }
    }

    function mixGenes(uint32[50] calldata geneticSequence1, uint32[50] calldata geneticSequence2, uint256 randomness) external view returns(uint32[50] memory) {

        // Performs the default uniform crossover algorithm
        uint32[50] memory geneticSequence = uniformCrossover(geneticSequence1,geneticSequence2,randomness);

        uint256 chance = randomness % 1000;
        if ( chance >= 444 && chance <= 446 ) {
            geneticSequence = inversionMutation(
                geneticSequence,
                randomness
            );
        }
        
        if ( chance >= 771 && chance <= 773 ) {
            geneticSequence = scrambleMutation(
                geneticSequence,
                randomness
            );
        }
        
        if ( chance < 5 ) {
            
            geneticSequence = swapMutation(
                geneticSequence,
                randomness
            );
            
        }

        if ( chance == 999 ) {
            geneticSequence = wholeArithmeticRecombination(
                uint256(keccak256(abi.encodePacked(block.timestamp, randomness, msg.sender))) % 2 == 0 ? geneticSequence1 : geneticSequence2,
                geneticSequence
            );
        }

        if ( chance == 312 ) {
            geneticSequence = arithmeticMutation(
                geneticSequence,
                randomness
            );
        }

        return geneticSequence;
    }

    function generateRandomGeneIndex(uint32 pillar, uint256 randomness) internal pure returns(uint256) {
        // Generate random gene index
        return ( uint256(keccak256(abi.encodePacked(pillar, randomness))) % 9 ) + 2;
    }

    function generateRandomAlleles(uint32[50] memory geneticSequence, uint256 randomness, uint256 randomGene) internal view returns(uint256,uint256) {

        // Generate 2 random indexes within the gene
        return(
            control.geneticSequenceSignature[randomGene] + (uint256(keccak256(abi.encodePacked(geneticSequence[6], randomness))) % 4),
            control.geneticSequenceSignature[randomGene] + (uint256(keccak256(abi.encodePacked(randomness, geneticSequence[10]))) % 4)
        );

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Constructor {
    
    struct Struct {
        address randomness;
        address methods;
        address terrains;
        uint32[50] male;
        uint32[50] female;
        uint32 maleGenesProbability;
        uint32 femaleGenesProbability;
        uint32[12] geneticSequenceSignature;
        uint32[50] maxValues;
    }

}