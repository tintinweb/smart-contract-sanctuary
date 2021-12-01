// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../../openzeppelin/access/Ownable.sol';
import '../../libraries/race/Race.sol';
import '../../libraries/terrain/Terrain.sol';
import '../../libraries/hound/Hound.sol';
import '../../libraries/queue/Queue.sol';
import '../../libraries/raceConstructorParams/RaceConstructorParams.sol';
import '../../hounds/IData.sol';
import '../generator/IData.sol';
import '../../libraries/utils/FilterForWinners.sol';


contract RacesMethods is Ownable {
    
    event NewRace(Race.Default queue);
    uint256 public queueId = 1;
    uint256 public raceId = 1;
    RaceConstructorParams.Default public control;
    mapping(uint256 => Race.Default) public queues;

    /**
     * DIIMIIM:
     * We'll save the races structure as bytes and we'll decode them into their specific tuple using their specific generator contract
     */
    mapping(uint256 => Race.Finished) public races;    

    function setGlobalParameters(
        RaceConstructorParams.Default memory input
    ) external {
        control = input;
    }

    function createQueues(Queue.Default[] memory theQueues) external onlyOwner {
        for ( uint256 i = 0 ; i < theQueues.length ; ++i ) {
            queues[queueId].terrain = theQueues[i].terrain;
            queues[queueId].price = theQueues[i].price;
            queues[queueId].stamina = theQueues[i].stamina;
            queues[queueId].currency = theQueues[i].currency;
            queues[queueId].totalParticipants = theQueues[i].totalParticipants;
            ++queueId;
        }
    }

    function uploadRace(Race.Finished memory race) external {
        races[raceId] = race;

        // Decode the race seed into the participants array
        uint256[] memory participants = abi.decode(race.seed,(uint256[]));

        // Gets the first indexes of the best participants
        uint256[3] memory winners = FilterForWinners.filterForWinners(participants);

        IRaceGeneratorData(control.raceGenerator).sendRewards(
            [
                IHoundsData(control.hounds).ownerOf(participants[winners[0]]),
                IHoundsData(control.hounds).ownerOf(participants[winners[1]]),
                IHoundsData(control.hounds).ownerOf(participants[winners[2]])
            ], 
            race.currency, 
            [
                race.price * 5,
                race.price * 3,
                race.price * 2
            ]
        );

        ++raceId;
    }

    function enqueue(uint256 theQueueId, uint256 theHoundId) external payable {
    
        // Queue verifications
        require(msg.value >= queues[theQueueId].price, "17");

        // Hound verifications
        Hound.Default memory hound = IHoundsData(control.hounds).hound(theHoundId);

        require(!hound.running, "13");
        require(hound.stamina.stamina >= queues[theQueueId].stamina, "24");

        // Adds the participant in the queue
        queues[theQueueId].participants.push(hound);
        
        IHoundsData(control.hounds).updateHoundStamina(theHoundId,queues[theQueueId].stamina);

        // If last participant in the queue is calling this
        if ( queues[theQueueId].participants.length == queues[theQueueId].totalParticipants ) {

            if ( control.callable ) {
                races[raceId] = IRaceGeneratorData(control.raceGenerator).generate(queues[theQueueId]);
                ++raceId;
            } else {
                emit NewRace(queues[theQueueId]);
            }

            delete queues[theQueueId].participants;

        }

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

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../hound/Hound.sol';


library Race {
    
    /**
     * DIIMIIM:
     * Participants can pay with multiple currencies, ETH included
     */
    struct Default {

        // Terrain of the race
        uint256 terrain;

        // Participants
        // totalParticipants will be the array length here
        Hound.Default[] participants;

        // address(0) for ETH
        address currency;

        // ETH based
        uint256 price;

        // Required stamina
        uint32 stamina;

        // Total number of participants
        uint32 totalParticipants;

    }

    struct Finished {

        // Terrain of the race
        uint256 terrain;

        // Race seed
        bytes seed;

        // address(0) for ETH
        address currency;

        // ETH based
        uint256 price;

        // Race randomness
        uint256 randomness;

        // Required stamina
        uint32 stamina;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Arena {
    
    struct Default {
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }

    struct Wrapped {
        uint256 id;
        Default terrain;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../houndStatistics/HoundStatistics.sol';
import '../stamina/Stamina.sol';
import '../breeding/Breeding.sol';
import '../identity/Identity.sol';


library Hound {
    
    struct Default {
        HoundStatistics.Default statistics;
        Stamina.Default stamina;
        Breeding.Default breeding;
        Identity.Default identity;
        string title;
        string token_url;
        bool custom;
        bool running;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Queue {
    
    /**
     * DIIMIIM:
     * Params used to create a race
     */
    struct Default {

        // Terrain of the race
        uint256 terrain;

        // address(0) for ETH
        address currency;

        // Price of the race
        uint256 price;

        // Required stamina
        uint32 stamina;

        // Total number of participants
        uint32 totalParticipants;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library RaceConstructorParams {
    
    struct Default {
        address randomness;
        address terrains;
        address hounds;
        address allowed;
        address methods;
        address raceGenerator;
        bool callable;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../libraries/houndsParams/Updatable.sol';
import '../libraries/hound/Hound.sol';


interface IHoundsData {
    function setGlobalParameters(HoundsUpdatable.Struct memory input) external;
    function adminCreateHound(Hound.Default[] memory theHounds) external;
    function breedHounds(uint256 hound1, uint256 hound2) external payable;
    function updateHoundStamina(uint256 theHoundId, uint32 staminaToConsume) external payable;
    function updateHoundBreeding(bytes memory input) external payable;
    function putHoundForBreed(uint256 _hound, uint256 fee, bool status) external;
    function hound(uint256 theHoundId) external view returns(Hound.Default memory);
    function ownerOf(uint256 tokenId) external view returns(address);
    function handleHoundTransfer(uint256 theHoundId, address from, address to) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 _tokenId) external view returns(string memory);
    function setTokenURI(uint256 _tokenId, string memory token_url) external;
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../../libraries/race/Race.sol';
import '../../libraries/hound/Hound.sol';
import '../../libraries/generatorConstructorParams/GeneratorConstructorParams.sol';

interface IRaceGeneratorData {
    function decodeRace(bytes memory race) external pure returns(Race.Finished memory);
    function setGlobalParameters(GeneratorConstructorParams.Default memory input) external;
    function simulateClassicRace(Hound.Default[] memory participants, uint256 terrain, uint256 theRandomness) external returns(bytes memory seed);
    function generate(Race.Default memory queue) external payable returns(Race.Finished memory race);
    function sendRewards(address[3] memory winners, address currency, uint256[3] memory amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library FilterForWinners {

    function filterForWinners(uint256[] memory participants) internal pure returns(uint256[3] memory winners) {
        for ( uint256 i = 0 ; i < participants.length ; ++i ) {

            if (participants[i] > winners[0]) {
                winners[2] = winners[1];
                winners[1] = winners[0];
                winners[0] = i;
            } else if ( participants[i] > winners[1]) {
                winners[2] = winners[1];
                winners[1] = i;
            } else if (participants[i] > winners[2])
                winners[2] = i;

        }
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

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library HoundStatistics {
    
    struct Default {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

library Stamina {
    
    struct Default {
        uint256 lastUpdate;
        uint256 staminaRefill1x;
        uint32 stamina;
        uint32 staminaPerHour;
        uint32 staminaCap;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

library Breeding {
    
    struct Default {
        uint256 breedCooldown;
        uint256 breedingFee;
        uint256 lastUpdate;
        bool availableToBreed;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Identity {
    
    struct Default {
        uint32[78] geneticSequence;
        uint256 generation;
        uint32[78] maleParent;
        uint32[78] femaleParent;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library HoundsUpdatable {
    
    struct Struct {
        address[] allowedCallers;
        address incubator;
        address methods;
        address payments;
        uint256 breedCost;
        uint256 breedFee;
        uint256 refillCost;
        bool[] isAllowed;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library GeneratorConstructorParams {
    
    struct Default {
        address randomness;
        address terrains;
        address hounds;
        address allowed;
        address methods;
        address raceGenerator;
        bool callable;
    }

}