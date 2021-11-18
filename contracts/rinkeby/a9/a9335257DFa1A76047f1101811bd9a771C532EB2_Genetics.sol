// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../../openzeppelin/access/Ownable.sol';
import '../../libraries/geneticsPanel/GeneticsPanel.sol';
import '../../libraries/errors/Errors.sol';
import '../../libraries/houndExtractedStats/HoundExtractedStats.sol';



contract Genetics is Ownable {


    /**
     * DIIMIIM:
     * Used for both constructor() and setGlobalParameters()
     */
    GeneticsPanel.Default public parameters;
    
    /**
     * DIIMIIM:
     * Called on contract creation
     */
    constructor(GeneticsPanel.Default memory params) {
        parameters = params;
    }
    
    /**
     * DIIMIIM:
     * Admin only accessible
     */
    function setGlobalParameters(GeneticsPanel.Default memory params) external onlyOwner {
        parameters = params;
    }

    /**
     * DIIMIIM:
     * Performs the whole arithmetic recombination algorithm
     * Source: https://www.tutorialspoint.com/genetic_algorithms/genetic_algorithms_crossover.htm
     */
    function wholeArithmeticRecombination(uint32[13] memory geneticSequence1, uint32[13] memory geneticSequence2) public pure returns(uint32[13] memory geneticSequence) {
        for ( uint256 i = 1 ; i < 13 ; ++i ) {
            geneticSequence[i] = ( geneticSequence1[i] + geneticSequence2[i] ) / 2;
        }
    }
    

    /**
     * DIIMIIM:
     * Performs the swap mutation algorithm
     * Source: https://www.tutorialspoint.com/genetic_algorithms/genetic_algorithms_mutation.htm
     */
    function swapMutation(uint32[13] memory geneticSequence, uint256 randomness) public pure returns(uint32[13] memory) {
        uint256 pos1 = uint256(keccak256(abi.encodePacked(geneticSequence[0], randomness))) % 13;
        uint256 pos2 = uint256(keccak256(abi.encodePacked(randomness, geneticSequence[1]))) % 13;
        uint32 aux = geneticSequence[pos2];
        geneticSequence[pos2] = geneticSequence[pos1];
        geneticSequence[pos1] = aux;
        return geneticSequence;
    }


    /**
     * DIIMIIM:
     * Performs the inversion mutation algorithm
     * Source: https://www.tutorialspoint.com/genetic_algorithms/genetic_algorithms_mutation.htm
     */
    function inversionMutation(uint32[13] memory geneticSequence, uint256 randomness) public pure returns(uint32[13] memory) {
        uint256 start = uint256(keccak256(abi.encodePacked(geneticSequence[0],randomness))) % 13;
        uint256 nrOfGenes = uint256(keccak256(abi.encodePacked(geneticSequence[1],randomness))) % ( 13 - start );
        uint32 aux;
        for (uint i = start; i < start + nrOfGenes; ++i) {
            aux = geneticSequence[i];
            geneticSequence[i] = geneticSequence[start + nrOfGenes -i];
            geneticSequence[start + nrOfGenes -i] = geneticSequence[i];
        }
        return geneticSequence;
    }

    
    /**
     * DIIMIIM:
     * Performs the scramble mutation algorithm
     * Source: https://www.tutorialspoint.com/genetic_algorithms/genetic_algorithms_mutation.htm
     */
    function scrambleMutation(uint32[13] memory geneticSequence, uint256 randomness) public pure returns(uint32[13] memory) {
        uint256 start = uint256(keccak256(abi.encodePacked(randomness))) % 13;
        uint256 nrOfGenes = uint256(keccak256(abi.encodePacked(geneticSequence[1]))) % start;

        // To avoid the potentially overflow errors
        if ( start + nrOfGenes >= 13 ) 
            nrOfGenes = 0; 
        
        uint32 aux;
        uint256 pos;
        for (uint i = start; i < start + nrOfGenes; ++i) {
            pos = (uint256(keccak256(abi.encodePacked(i, randomness))) % start) + nrOfGenes;
            aux = geneticSequence[pos];
            geneticSequence[pos] = geneticSequence[i];
            geneticSequence[i] = aux;
        }
        
        return geneticSequence;
    }
    
    /**
     * DIIMIIM:
     * Performs the arithmetic mutation algorithm
     */
    function arithmeticMutation(uint32[13] memory geneticSequence, uint256 randomness) public pure returns(uint32[13] memory) {
        uint256 geneToMutate = uint256(keccak256(abi.encodePacked(randomness))) % 13;

        geneticSequence[geneToMutate] = uint32(geneToMutate % 10);

        return geneticSequence;
    }

    /**
     * DIIMIIM:
     * Uniform crossover
     */
    function uniformCrossover(uint32[13] calldata geneticSequence1, uint32[13] calldata geneticSequence2, uint256 randomness) public view returns(uint32[13] memory geneticSequence) {
        for ( uint256 i = 0 ; i < 13 ; ++i ) {
            uint256 dominantGene = uint256(keccak256(abi.encodePacked(i, randomness)));
            if ( dominantGene % 100 < parameters.maleGenesProbability ) {
                geneticSequence[i] = geneticSequence1[i];
            } else {
                geneticSequence[i] = geneticSequence2[i];
            }
        }
    }

    /**
     * DIIMIIM:
     * Combines 2 genes using a safely generated RNG in order to create a new hound
     */
    function mixGenes(uint32[13] calldata geneticSequence1, uint32[13] calldata geneticSequence2, uint256 randomness) public view returns(uint32[13] memory) {
        require(geneticSequence1[0] != geneticSequence2[0], Errors.BIOLOGICAL_REQUIREMENTS_NOT_MET);
        uint32[13] memory geneticSequence = uniformCrossover(geneticSequence1,geneticSequence2,randomness);

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

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library GeneticsPanel {
    
    struct Default {
        address randomNumberGenerator;
        string randomNumberGeneratorMethod;
        uint32[13] maleBoilerplate;
        uint32[13] femaleBoilerplate;
        uint32 mintRandomnessAccuracy;
        uint32 breedRandomnessAccuracy;
        uint32 maleGenesProbability;
        uint32 femaleGenesProbability;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

library Errors {

    string public constant NO_OWNER_ON_HOUND_CREATION = '1';
    string public constant NOT_ENOUGH_PAID_TO_MINT = '2';
    string public constant NOT_ENOUGH_PAID_TO_BREED = '3';
    string public constant CONSTRUCTOR_PARAMETER_MISSING = '4';
    string public constant SYNCED_ARRAY_LENGTH_INVALID = '5';
    
    /* @DIIMIIM: Used for almost every .call() code snippet */
    string public constant CALL_FAILED = '6';
    
    /* @DIIMIIM: Used for almost every .delegatecall() code snippet */
    string public constant DELEGATECALL_FAILED = '7';
    
    string public constant RNG_PROVIDER_NOT_ALLOWED = '8';
    string public constant INCOMPLETE_INCUBATOR_IMPLEMENTATION = '9';
    
    string public constant NOT_ENOUGH_LINK = '10';
    
    string public constant NOT_OWNER_OF_CONTRACT = '11';
    string public constant QUEUE_ID_NOT_VALID = '12';
    string public constant ONE_RUN_PER_HOUND = '13';
    string public constant ETH_TRANSFER_FAILED = '14';
    string public constant CURRENCY_TRANSFER_FAILED = '15';
    string public constant BIOLOGICAL_REQUIREMENTS_NOT_MET = '16';
    string public constant NOT_ENOUGH_PAID_TO_PLAY = '17';
    string public constant CLASSIC_RACE_PARTICIPANTS_RANGE_NOT_MATCHED = '18';
    string public constant RACE_HAS_FINISHED_ALREADY = '19';
    string public constant NOT_THE_OWNER_OF_HOUND = '20';
    string public constant HOUND_BREEDING_STILL_ON_COOLDOWN = '21';
    string public constant HOUND_NOT_AVAILABLE_TO_BREED = '22';
    string public constant CALLER_NOT_ALLOWED = '23';
    string public constant HOUND_DOES_NOT_EXIST = '23';
    string public constant NOT_ENOUGH_STAMINA = '24';
    string public constant NOT_VALID_GAME_MODE = '25';
    string public constant NOT_ENOUGH_PAID_TO_REFILL = '26';
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../aesthetics/Aesthetics.sol';


library HoundExtractedStats {
    
    struct Default {
        Aesthetics.Hound aesthetics;
        string gene;
        uint256 wildcard;
        uint256 endurance;
        uint256 surfacePreference;
        uint256 distancePreference;
        uint256 weatherPreference;
        bool female;
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Aesthetics {
    
    struct Hound {
        uint64 color;
        uint32 head;
        uint32 eye;
        uint32 paw;
        uint32 skin;
        uint32 armor;
        uint32 tail;
    }
    
}