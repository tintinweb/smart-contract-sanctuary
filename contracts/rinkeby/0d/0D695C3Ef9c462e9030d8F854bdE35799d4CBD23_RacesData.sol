// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../../utils/FilterForWinners.sol';
import '../../hounds/IData.sol';
import '../../arenas/Arena.sol';

import '../generator/IData.sol';

import './Race.sol';
import '../Constructor.sol';


contract RacesData is Ownable {
    
    event NewRace(uint256 indexed id, Race.Struct race);
    event NewFinishedRace(uint256 indexed id, Race.Finished race);
    event QueuesCreation(uint256 indexed idStart, uint256 indexed idStop, Race.Struct[] newQueues);
    event DeleteQueue(uint256 indexed id);
    event UploadRace(uint256 indexed id, Race.Finished race);
    event PlayerEnqueue(uint256 indexed id, uint256 indexed hound, address indexed player);
    uint256 public id = 1;
    Constructor.Struct public control;
    mapping(uint256 => Race.Struct) public queues;
    string error = "Failed to delegatecall";

    /**
     * DIIMIIM:
     * We'll save the races structure as bytes and we'll decode them into their specific tuple using their specific generator contract
     */
    mapping(uint256 => Race.Finished) public races;
    
    constructor(
        Constructor.Struct memory input
    ) {
        control = input;
    }

    function setGlobalParameters(
        Constructor.Struct memory input
    ) external onlyOwner {
        (bool success, ) = control.methods.delegatecall(msg.data);
        require(success,error);
    }

    function createQueues(Race.Struct[] memory theQueues) external onlyOwner {
        (bool success, ) = control.methods.delegatecall(msg.data);
        require(success,error);
    }

    function deleteQueue(uint256 theId) external onlyOwner {
        (bool success, ) = control.methods.delegatecall(msg.data);
        require(success,error);
    }

    function uploadRace(Race.Finished memory race) external onlyOwner {
        (bool success, ) = control.methods.delegatecall(msg.data);
        require(success,error);
    }

    function enqueue(uint256 theId, uint256 hound) external payable {
        (bool success, ) = control.methods.delegatecall(msg.data);
        require(success,error);
    }

    function queue(uint256 theId) external view returns(Race.Struct memory) {
        return queues[theId];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

import './GlobalVariables.sol';
import './Hound.sol';


interface IHoundsData {
    function setGlobalParameters(GlobalVariables.Struct memory input) external;
    function adminCreateHound(Hound.Struct memory theHounds) external;
    function breedHounds(uint256 hound1, uint256 hound2) external payable;
    function updateHoundStamina(uint256 theId) external;
    function updateHoundBreeding(uint256 theId, uint256 breedingCooldownToConsume) external;
    function putHoundForBreed(uint256 _hound, uint256 fee, bool status) external;
    function hound(uint256 theId) external view returns(Hound.Struct memory);
    function ownerOf(uint256 tokenId) external view returns(address);
    function handleHoundTransfer(uint256 theId, address from, address to) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 _tokenId) external view returns(string memory);
    function setTokenURI(uint256 _tokenId, string memory token_url) external;
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Arena {
    
    struct Struct {
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }

    struct Wrapped {
        uint256 id;
        Struct arena;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;
import '../races/Race.sol';
import '../../hounds/Hound.sol';


interface IRaceGeneratorData {
    function simulateClassicRace(Hound.Struct[] memory participants, uint256 terrain, uint256 theRandomness) external returns(bytes memory seed);
    function generate(Race.Struct memory queue) external payable returns(Race.Finished memory race);
    function sendRewards(address[3] memory winners, address currency, uint256[3] memory amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Race {
    
    /**
     * DIIMIIM:
     * Participants can pay with multiple currencies, ETH included
     */
    struct Struct {

        // address(0) for ETH
        address currency;

        // Participants
        // totalParticipants will be the array length here
        uint256[] participants;

        // arena of the race
        uint256 arena;

        // ETH based
        uint256 entryFee;

        // Start date
        uint256 startDate;

        // Total number of participants
        uint32 totalParticipants;

    }

    struct Finished {

        // address(0) for ETH
        address currency;

        // Race seed
        uint256[] participants;

        // arena of the race
        uint256 arena;

        // ETH based
        uint256 entryFee;

        // Race randomness
        uint256 seed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Constructor {
    
    struct Struct {

        address randomness;
        address terrains;
        address hounds;
        address allowed;
        address methods;
        address raceGenerator;

        /* Stater race fee */
        uint256 raceFee;

        /* False if race is uploaded by admin, true if it's blockchain generated */
        bool callable;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


library GlobalVariables {
    
    struct Struct {
        address[] allowedCallers;
        address incubator;
        address methods;
        uint256 breedCost;
        uint256 breedFee;
        uint256 refillCost;
        bool[] isAllowed;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;

import './Statistics.sol';
import './Stamina.sol';
import './Breeding.sol';
import './Identity.sol';


library Hound {
    
    struct Struct {
        Statistics.Struct statistics;
        Stamina.Struct stamina;
        Breeding.Struct breeding;
        Identity.Struct identity;
        string title;
        string token_url;
        bool custom;
        bool running;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Statistics {
    
    struct Struct {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Stamina {
    
    struct Struct {
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
    
    struct Struct {
        uint256 breedCooldown;
        uint256 breedingFee;
        uint256 lastUpdate;
        bool availableToBreed;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Identity {
    
    struct Struct {
        uint32[50] geneticSequence;
        uint256 generation;
        uint32[50] maleParent;
        uint32[50] femaleParent;
    }

}